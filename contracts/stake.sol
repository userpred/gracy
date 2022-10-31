// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "contracts/gracy-staking-v1/struct.sol";
import "contracts/gracy-staking-v1/initialize.sol";

// import utils
import "contracts/gracy-staking-v1/utils.sol";

contract Stake is Pausable, Ownable, ReentrancyGuard, Initialize, Utils {
    // staking token 
    Token gracyToken;
    // The period (days) for staking
    // After expiring "planExpired", can be staked anymore.
    uint256 internal planExpired;

    // ID for identifing staking info
    using Counters for Counters.Counter;
    Counters.Counter private _stakeIds;

    // total volume counting (current total staked amount)
    uint256 private totalStaked;
    uint256 private totalStakedOriginAmount; // origin amount

    struct stakingCount {
        uint256 total;
        uint256 finished;
        uint256 staking_time_lack;
        uint256 staking_time_over;
    }

    mapping(uint => stakeInfo) private stakeInfos;
    mapping(address => uint256 []) stakeIdsByAccount;
    mapping(string => communityInfo) communityInfos;
    
    event stakeId(uint256 stake_id);
    event Staked(address indexed from, uint256 amount);
    event Claimed(address indexed from, uint256 amount);

    function getMainBoardInfo() public view returns (uint256, uint256, uint256) {
        _DateTime memory dt = DateTime.parseTimestamp(block.timestamp);
        dailyStakeInfo storage dailyStaking = dailyStakeInfos[dt.year][dt.month][dt.day];
        uint256 currentAPR;
        if (totalStaked>0) {
            // 365 = 1year, 100 = percent
            currentAPR = (dailyStaking.allocatedVolume * 365 * 100) / totalStaked;
            } 
        else {currentAPR=0;}
        return (currentAPR, dailyStaking.allocatedVolume, totalStakedOriginAmount);
    }

    function getCurrentStakingCount(address account) public view returns (stakingCount memory){
        stakingCount memory sc;
        for (uint8 i=0; i<stakeIdsByAccount[account].length; i++) {
            // 현재 staking인 stake_id인 경우
            sc.total += 1;
            if (keccak256(bytes(stakeInfos[stakeIdsByAccount[account][i]].status)) == keccak256(bytes("staked")) ) {
                // 아직 스테이킹 중인 경우 
                if (stakeInfos[stakeIdsByAccount[account][i]].endTS > block.timestamp) {
                    // count += 1;
                    sc.staking_time_lack += 1;
                } else {
                    sc.staking_time_over += 1;
                }
            } else {
                sc.finished += 1;
            }
        }
        return sc;
    }

    function claimRewardAll(address account) external returns (bool) {
        stakingCount memory sc = getCurrentStakingCount(account);
        require(_msgSender() != address(0));
        require(sc.staking_time_lack == 0, "Not enought for claimRewardAll condition");
        require(sc.staking_time_over >= 0, "At least 1 staking is required");
        
        // stakingCount memory sc;
        uint256 totalRewardVolume;
        for (uint i=0; i<stakeIdsByAccount[account].length; i++) {
            // 현재 staking인 stake_id인 경우
            // stake_id 가져오기
            // uint256 stake_id = stakeIdsByAccount[account][i];
            if (keccak256(bytes(stakeInfos[stakeIdsByAccount[account][i]].status)) == keccak256(bytes("staked")) ) {
                // 아직 스테이킹 중인 경우 
                if (stakeInfos[stakeIdsByAccount[account][i]].endTS <= block.timestamp) {
                    // count += 1;
                    // uint256 stakeAmount = stakeInfos[stake_id].amount;
                    _DateTime memory dt = DateTime.parseTimestamp(stakeInfos[stakeIdsByAccount[account][i]].startTS);
                    dailyStakeInfo memory dailyStaking = dailyStakeInfos[dt.year][dt.month][dt.day];
                    
                    // Total staked amount
                    uint256 weightedAmount = getStakeAmountPlusWeight(stakeInfos[stakeIdsByAccount[account][i]].amount,
                                                stakeInfos[stakeIdsByAccount[account][i]].stakingDays);
                    totalStaked -= weightedAmount;
                    totalStakedOriginAmount -= stakeInfos[stakeIdsByAccount[account][i]].amount;

                    // Set a community info
                    communityInfos[stakeInfos[stakeIdsByAccount[account][i]].communityId].amount -= stakeInfos[stakeIdsByAccount[account][i]].amount;

                    // Calculate a reward volume
                    uint256 _rewardVolume = weightedAmount * dailyStaking.allocatedVolume;
                    uint256 rewardVolume = (_rewardVolume/ dailyStaking.currentVolume) + stakeInfos[stakeIdsByAccount[account][i]].amount;
                    totalRewardVolume += rewardVolume;
                    stakeInfos[stakeIdsByAccount[account][i]].claimTS = block.timestamp;
                    stakeInfos[stakeIdsByAccount[account][i]].claimed = rewardVolume;
                    stakeInfos[stakeIdsByAccount[account][i]].status = "claimed";
                }
            }
        }

        gracyToken.transfer(_msgSender(), totalRewardVolume);

        emit Claimed(_msgSender(), totalRewardVolume);

        return true;
    }

    function claimReward(uint256 stake_id) external returns (bool){
        // Requiring conditions
        require(keccak256(bytes(stakeInfos[stake_id].status)) == keccak256(bytes("staked")), "Invalid Name");
        // require(stakeInfos[stake_id].status == "stake", "This stake_id is not participated");
        require(stakeInfos[stake_id].endTS <= block.timestamp, "Stake Time is not over yet");
        require(stakeInfos[stake_id].claimed == 0, "Already claimed");
        require(stakeInfos[stake_id].account == _msgSender(), "Already claimed");

        // Check a stake amount
        uint256 stakeAmount = stakeInfos[stake_id].amount;
        uint256 weightedAmount = getStakeAmountPlusWeight(stakeInfos[stake_id].amount, stakeInfos[stake_id].stakingDays);
        // stakeInfos[stake_id].weightedAmount;

        // Get a dailyStaking Info
        _DateTime memory dt = DateTime.parseTimestamp(stakeInfos[stake_id].startTS);
        dailyStakeInfo storage dailyStaking = dailyStakeInfos[dt.year][dt.month][dt.day];

        // Total staked amount
        totalStaked -= weightedAmount;
        totalStakedOriginAmount -= stakeAmount;

        // Set a community info
        string memory communityId = stakeInfos[stake_id].communityId;
        communityInfos[communityId].amount -= stakeAmount;

        // Calculate a reward volume
        uint256 _rewardVolume = weightedAmount * dailyStaking.allocatedVolume;
        uint256 claimVolume = (_rewardVolume/ dailyStaking.currentVolume) + stakeAmount;

        // Change a status of stakeinfo and send a reward token to user
        stakeInfos[stake_id].claimTS = block.timestamp;
        stakeInfos[stake_id].claimed = claimVolume;
        stakeInfos[stake_id].status = "claimed";
        gracyToken.transfer(_msgSender(), claimVolume);
        
        emit stakeId(stake_id);

        return true;
    }

    function cancelStake(uint256 stake_id) public returns (bool) {
        require(keccak256(bytes(stakeInfos[stake_id].status)) == keccak256(bytes("staked")), "This stake_id is not participated");
        // require(stakeInfos[stake_id].endTS > block.timestamp, "Stake Time isn't enough");
        require(stakeInfos[stake_id].claimed == 0, "Already claimed");
        require(stakeInfos[stake_id].account == _msgSender(), "Account isn't matched");

        // Check a stake amount
        uint256 stakeAmount = stakeInfos[stake_id].amount;
        uint256 weightedAmount = getStakeAmountPlusWeight(stakeAmount, stakeInfos[stake_id].stakingDays);
        // stakeInfos[stake_id].weightedAmount;

        // Get a dailyStaking Info
        _DateTime memory dt = DateTime.parseTimestamp(stakeInfos[stake_id].startTS);
        dailyStakeInfo storage dailyStaking = dailyStakeInfos[dt.year][dt.month][dt.day];

        // Reset a totalStaked
        totalStaked -= weightedAmount;
        totalStakedOriginAmount -= stakeAmount;
        dailyStaking.currentVolume -= weightedAmount;
        dailyStaking.stakers -= 1;

        // Set a community info
        string memory communityId = stakeInfos[stake_id].communityId;
        communityInfos[communityId].amount -= stakeAmount;

        // Change a status of stakeinfo and send a reward token to user
        stakeInfos[stake_id].claimed = stakeAmount;
        stakeInfos[stake_id].status = "cancelled";
        gracyToken.transfer(_msgSender(), stakeAmount);
        
        // emit Claimed(_msgSender(), stakeAmount);
        emit stakeId(stake_id);

        return true;
    }

    function stakeToken(string memory communityId, uint256 stakeAmount, uint8 stakingDays) 
    external 
    payable 
    whenNotPaused 
    returns (uint256) {
        // Requiring conditions
        require(stakeAmount >0, "Stake amount should be correct");
        require(block.timestamp < planExpired , "Plan Expired");
        require(gracyToken.balanceOf(_msgSender()) >= stakeAmount, "Insufficient Balance");
        require(
            gracyToken.allowance(_msgSender(), address(this)) >= stakeAmount,
            "gracyToken allowance too low"
        );
        require(stakingDays==30 || stakingDays==60 || stakingDays==90 || stakingDays==120,
                                                "Staking days should be 30, 60, 90, 120 days");
        
        // Calculate a amount with stakingDays
        uint256 weightedAmount = getStakeAmountPlusWeight(stakeAmount, stakingDays);
 
        // transferFrom: msgSender -> contract
        gracyToken.transferFrom(_msgSender(), address(this), stakeAmount);

        communityInfos[communityId].amount += stakeAmount;
        

        // Set a stake_id
        _stakeIds.increment();
        uint256 newStakeId = _stakeIds.current();


        stakeInfos[newStakeId] = stakeInfo(
            newStakeId,
            communityId, 
            _msgSender(),
            block.timestamp , // for testing
            // block.timestamp + (stakingDays * 86400),
            block.timestamp + (stakingDays*2),
            0, // claimTS
            stakeAmount, // amount
            0,
            stakingDays,
            "staked"
        );

        // account에 따른 stake_id 
        stakeIdsByAccount[_msgSender()].push(newStakeId);

        // Set a daily staking info
        _DateTime memory dt = DateTime.parseTimestamp(block.timestamp);
        dailyStakeInfo storage dailyStaking = dailyStakeInfos[dt.year][dt.month][dt.day];

        dailyStaking.currentVolume += weightedAmount;
        dailyStaking.stakers += 1;

        // Set a total staked 
        totalStaked += weightedAmount;
        totalStakedOriginAmount += stakeAmount;
    
        emit stakeId(newStakeId);
        return newStakeId;
    }

    function getCurrentBlockTime() public view returns (uint256) {
        return block.timestamp;
    }

    function _getEstimatedAPR(uint256 fixedStakeAmount, uint8 stakingDays) private view returns (uint256) {
        
        _DateTime memory dt1 = DateTime.parseTimestamp(block.timestamp);
        _DateTime memory dt2 = DateTime.parseTimestamp(block.timestamp + 2592000);
        _DateTime memory dt3 = DateTime.parseTimestamp(block.timestamp + 5184000);
        _DateTime memory dt4 = DateTime.parseTimestamp(block.timestamp + 5184000+ 2592000);

        dailyStakeInfo memory dailyStaking1 = dailyStakeInfos[dt1.year][dt1.month][dt1.day];
        dailyStakeInfo memory dailyStaking2 = dailyStakeInfos[dt2.year][dt2.month][dt2.day];
        dailyStakeInfo memory dailyStaking3 = dailyStakeInfos[dt3.year][dt3.month][dt3.day];
        dailyStakeInfo memory dailyStaking4 = dailyStakeInfos[dt4.year][dt4.month][dt4.day];

        poolReward memory PR;
        
        if (stakingDays == 30) {
            PR.d30 = dailyStaking1.allocatedVolume * 30;
            PR.estimatedAPR = ((fixedStakeAmount * PR.d30) / totalStaked) * 12;
        } else if (stakingDays == 60) {            
            PR.d30 = fixedStakeAmount * (dailyStaking1.allocatedVolume * 30);
            PR.d60 = fixedStakeAmount * (dailyStaking2.allocatedVolume * 30);
            PR.estimatedAPR = ((PR.d30 / totalStaked) + (PR.d60 / totalStaked)) * 6;
        } else if (stakingDays == 90) {
            PR.d30 = fixedStakeAmount * (dailyStaking1.allocatedVolume * 30);
            PR.d60 = fixedStakeAmount * (dailyStaking2.allocatedVolume * 30);
            PR.d90 = fixedStakeAmount * (dailyStaking3.allocatedVolume * 30);
            PR.estimatedAPR = ((PR.d30 / totalStaked) + (PR.d60 / totalStaked) + (PR.d90 / totalStaked)) * 4;
        } else {
            PR.d30 = fixedStakeAmount * (dailyStaking1.allocatedVolume * 30);
            PR.d60 = fixedStakeAmount * (dailyStaking2.allocatedVolume * 30);
            PR.d90 = fixedStakeAmount * (dailyStaking3.allocatedVolume * 30);
            PR.d120 = fixedStakeAmount * (dailyStaking4.allocatedVolume * 30);
            PR.estimatedAPR = ((PR.d30 / totalStaked) + (PR.d60 / totalStaked) + (PR.d90 / totalStaked) + (PR.d120 / totalStaked)) * 3;
        }
        return PR.estimatedAPR;
    }

    function getEstimatedAPR(uint256 stakeAmount, uint8 stakingDays) public view returns (estimatedStakeInfo memory) {
        require(stakingDays==30 || stakingDays==60 || stakingDays==90 || stakingDays==120,
                                                "Staking days should be 30, 60, 90, 120 days");
        _DateTime memory dt = DateTime.parseTimestamp(block.timestamp);
        dailyStakeInfo memory dailyStaking = dailyStakeInfos[dt.year][dt.month][dt.day];
        estimatedStakeInfo memory eInfo;
    
        // uint256 estimatedAPR;

        uint256 fixedStakeAmount = getStakeAmountPlusWeight(stakeAmount, stakingDays);

        // eInfo.amount = fixedStakeAmount;
        eInfo.startTS = block.timestamp;
        // 1d = 86400
        eInfo.endTS = block.timestamp + (stakingDays * 86400);
        eInfo.stakingDays = stakingDays;
        eInfo.estimatedReward = (dailyStaking.allocatedVolume * fixedStakeAmount) / (dailyStaking.currentVolume + fixedStakeAmount);
        eInfo.estimatedAPR = _getEstimatedAPR(fixedStakeAmount, stakingDays);
        return eInfo;
    }

    function getEstimatedAPRByStakeId(uint256 stake_id) public view returns (estimatedStakeInfo memory) {
        stakeInfo memory info = stakeInfos[stake_id];
        _DateTime memory dt = DateTime.parseTimestamp(info.startTS);
        dailyStakeInfo storage dailyStaking = dailyStakeInfos[dt.year][dt.month][dt.day];
        estimatedStakeInfo memory eInfo;

        eInfo.startTS = info.startTS;
        eInfo.endTS = info.endTS;
        eInfo.stakingDays = info.stakingDays;

        uint weightedAmount = getStakeAmountPlusWeight(info.amount, info.stakingDays);
        uint256 estimatedReward = (weightedAmount * dailyStaking.allocatedVolume) / dailyStaking.currentVolume;

        // eInfo.estimatedReward = (dailyStaking.allocatedVolume * info.amount) / (dailyStaking.currentVolume + info.amount);
        eInfo.estimatedReward = estimatedReward;
        eInfo.estimatedAPR = _getEstimatedAPR(info.amount, info.stakingDays);
        return eInfo;


    }

    function getStakeIds(address account) public view returns (uint256 [] memory){
        return stakeIdsByAccount[account];
    }

    function getStakeInfo(uint256 stake_id) public view returns (stakeInfo memory) {
        return stakeInfos[stake_id];
    }

    function getStakeInfoByIds(uint256 [] memory stakeIds) public view returns (stakeInfo [] memory) {
        stakeInfo[] memory selectedStakeInfos = new stakeInfo[](stakeIds.length);
        for (uint i=0; i<stakeIds.length; i++) {
            selectedStakeInfos[i] = stakeInfos[stakeIds[i]];
        }
        return selectedStakeInfos;
    }

    function getAllStakeInfo(address account) public view returns (stakeInfo [] memory){
        stakeInfo[] memory allStakeInfo = new stakeInfo[](stakeIdsByAccount[account].length);
        for (uint i=0; i<stakeIdsByAccount[account].length; i++) {
            allStakeInfo[i] = stakeInfos[stakeIdsByAccount[account][i]];
        }
        return allStakeInfo;
    }
    
    function getTotalStakedByCommunityId(string memory communityId) public view returns (uint256) {
        return communityInfos[communityId].amount;
    }

    function getTotalStakedByCommunityIds(string [] memory communityIds) public view returns (uint256 [] memory){
        uint256[] memory communityAmounts= new uint256[](communityIds.length);
        for (uint x=0; x<communityIds.length; x++){
            communityAmounts[x] = communityInfos[communityIds[x]].amount;
        }
        return communityAmounts;
    }

    function getCommunityCountByCommunityId(address account, string memory communityId) public view returns (uint256) {
        uint256 communityCount;
        for (uint i=0; i<stakeIdsByAccount[account].length; i++) {
            stakeInfo memory tInfo = stakeInfos[stakeIdsByAccount[account][i]];
            if (keccak256(bytes(tInfo.communityId)) == keccak256(bytes(communityId))){communityCount+=1;}
        }
        return communityCount;
    }

    function getStakeIdsByCommunityId(address account, string memory communityId) public view returns (uint256 [] memory){
        uint communityCount = getCommunityCountByCommunityId(account, communityId);
        uint _count;
        uint256[] memory customStakeIds= new uint256[](communityCount);
        for (uint i=0; i<stakeIdsByAccount[account].length; i++) {
            stakeInfo memory tInfo = stakeInfos[stakeIdsByAccount[account][i]];
            if (keccak256(bytes(tInfo.communityId)) == keccak256(bytes(communityId))){
                customStakeIds[_count]=stakeInfos[stakeIdsByAccount[account][i]].stakeId;
                _count+=1;
            }
        }
        return customStakeIds;
    }

    function getStakeInfoByCommunityId(address account, string memory communityId) public view returns (stakeInfo [] memory){
        uint communityCount = getCommunityCountByCommunityId(account, communityId);
        uint _count;
        stakeInfo[] memory customStakeInfo = new stakeInfo[](communityCount);
        for (uint i=0; i<stakeIdsByAccount[account].length; i++) {
            stakeInfo memory tInfo = stakeInfos[stakeIdsByAccount[account][i]];
            if (keccak256(bytes(tInfo.communityId)) == keccak256(bytes(communityId))){
                customStakeInfo[_count]=stakeInfos[stakeIdsByAccount[account][i]];
                _count+=1;
            }
        }
        return customStakeInfo;
    }

    function getAmountStakeInfoByCommunityId(address account, string memory communityId) public view returns (uint256){
        uint256 amount;
        for (uint i=0; i<stakeIdsByAccount[account].length; i++) {
            stakeInfo memory tInfo = stakeInfos[stakeIdsByAccount[account][i]];
            if (keccak256(bytes(tInfo.status)) == keccak256(bytes("staked")) ) {
                if (keccak256(bytes(tInfo.communityId)) == keccak256(bytes(communityId))){
                amount += stakeInfos[stakeIdsByAccount[account][i]].amount;
                }
            }
        }
        return amount;
    }

    function getDailyStakeInfo(uint year, uint month, uint day) public view returns (dailyStakeInfo memory) {
        return dailyStakeInfos[year][month][day];
    }

    // function getTotalStaked() public view returns (uint256) {
    //     return totalStaked;
    // }

}


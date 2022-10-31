 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface Token {
    // function transfer(address recipient, uint256 amount) external returns (bool);
    // function balanceOf(address account) external view returns (uint256);
    // function transferFrom(address sender, address recipient, uint256 amount) external returns (uint256); 
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

struct monthlyStakeInfo {
        uint256 stakers;
        uint256 currentVolume;
        uint256 allocatedVolume;
    }

struct dailyStakeInfo {
        uint256 stakers;
        uint256 currentVolume;
        uint256 allocatedVolume;
    }

struct stakeInfo { 
    uint256 stakeId;
    string communityId;
    address account;
    uint256 startTS;
    uint256 endTS;
    uint256 claimTS; // claim 시간 
    uint256 amount;
    uint256 claimed;
    uint8 stakingDays; // staking days -> 30, 60, 90, 120 days
    string status; // status => "staked" or "claimed" or "cancelled"
    // uint256 weightedAmount;
}

struct estimatedStakeInfo { 
    uint256 startTS;
    uint256 endTS;
    // uint256 amount;
    uint8 stakingDays; // staking days -> 30, 60, 90, 120 days
    uint256 estimatedReward;
    uint256 estimatedAPR;
}

struct communityInfo {
    string communityId;
    uint256 amount;
}

struct poolReward {
    uint256 d30;
    uint256 d60;
    uint256 d90;
    uint256 d120;
    uint256 estimatedAPR;
}

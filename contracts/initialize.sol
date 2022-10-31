// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "contracts/gracy-staking-v1/datetime.sol";
import "contracts/gracy-staking-v1/struct.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Initialize is DateTime, Ownable{

    constructor() {
        setMonthlyVolume();
    }

    mapping(uint16 => mapping(uint8 => monthlyStakeInfo)) internal monthlyStakeInfos;
    mapping(uint => mapping(uint  => mapping(uint => dailyStakeInfo))) internal dailyStakeInfos;

    function setMonthlyVolume() private {
        // set monthly volumes 
    }

    function setDailyVolume(uint16 year) public {
        require(_msgSender() == owner(), "only owner set a volume");
        
        uint8 endDay;
        for (uint8 month=1; month<13; month++) {
            endDay = getDaysInMonth(month,year);
            // console.log('endDay', endDay);
            if (monthlyStakeInfos[year][month].allocatedVolume > 0) {
                for (uint i=1 ; i<endDay+1; ) {
                    dailyStakeInfos[year][month][i].allocatedVolume = monthlyStakeInfos[year][month].allocatedVolume/endDay;
                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Utils {

    function getStakeAmountPlusWeight(uint256 stakeAmount, uint8 stakingDays) internal pure returns (uint256) {
        uint fixedStakeAmount;
        if (stakingDays==30) {
            fixedStakeAmount=stakeAmount;
        } else if (stakingDays==60) {
            fixedStakeAmount = ((stakeAmount * y) / 100);
        } else if (stakingDays==90) {
            fixedStakeAmount = ((stakeAmount * y) / 100);
        } else if (stakingDays==120) {
            fixedStakeAmount = ((stakeAmount * y) / 100);
        }
        return fixedStakeAmount;
    }

    function getStakeAmountMinusWeight(uint256 stakeAmount, uint8 stakingDays) internal pure returns (uint256) {
        uint fixedStakeAmount;
        if (stakingDays==30) {
            fixedStakeAmount = stakeAmount;
        } else if (stakingDays==60) {
            fixedStakeAmount = ((stakeAmount / y) * 100);
        } else if (stakingDays==90) {
            fixedStakeAmount = ((stakeAmount / y) * 100);
        } else if (stakingDays==120) {
            fixedStakeAmount = ((stakeAmount / y) * 100);
        }
        return fixedStakeAmount;
    }
}

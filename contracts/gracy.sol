// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "contracts/gracy-staking-v1/stake.sol";

contract StakeGRACY is Stake {

    constructor(Token _tokenAddress, uint256 _planExpiredDays) {
        require(address(_tokenAddress) != address(0),"Token Address cannot be address 0");                
        gracyToken = _tokenAddress;        
        planExpired = block.timestamp + (_planExpiredDays * 24 * 60 * 60);
    }
}

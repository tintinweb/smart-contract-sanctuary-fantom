/**
 *Submitted for verification at FtmScan.com on 2022-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IxShadeRewardsDistributor {
    function claim(address account) external;
}

contract xShadeRDClaimer {
    
    function claim(IxShadeRewardsDistributor[] memory _distributors) public {
        for (uint256 i = 0; i < _distributors.length; i++) {
          _distributors[i].claim(msg.sender);
        }
    }
}
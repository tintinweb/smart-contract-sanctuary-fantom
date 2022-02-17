/**
 *Submitted for verification at FtmScan.com on 2022-02-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract selfDestruct {

    function kill() external {
        selfdestruct(payable(msg.sender));
    }

    function call() external pure returns (uint) {
        return 69;
    }
}
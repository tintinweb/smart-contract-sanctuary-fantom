/**
 *Submitted for verification at FtmScan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Setter {
    uint256 public testVar;

    function setTestVar(uint256 _testVar) external {
        testVar = _testVar;
    }
}
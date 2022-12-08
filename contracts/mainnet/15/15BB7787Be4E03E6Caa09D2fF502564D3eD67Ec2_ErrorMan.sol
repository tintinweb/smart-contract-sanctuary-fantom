/**
 *Submitted for verification at FtmScan.com on 2022-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ErrorMan {
    function getNum(uint256 num) external pure returns (uint256)  {
        require(num % 5 != 0, "Bad number!");
        return num + 1;
    }
}
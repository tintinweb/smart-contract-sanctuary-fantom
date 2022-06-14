/**
 *Submitted for verification at FtmScan.com on 2022-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Checker {
    function isContract(address account) public view returns (bool) {
        return account.code.length > 0;
    }
}
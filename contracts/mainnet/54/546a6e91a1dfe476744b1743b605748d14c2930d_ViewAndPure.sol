/**
 *Submitted for verification at FtmScan.com on 2022-10-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ViewAndPure {
    uint public x = 1;

    function addToX(uint y) public view returns (uint) {
        return x+y;
    }

    function add(uint i,uint j) public pure returns (uint) {
        return i+j;
    }
}
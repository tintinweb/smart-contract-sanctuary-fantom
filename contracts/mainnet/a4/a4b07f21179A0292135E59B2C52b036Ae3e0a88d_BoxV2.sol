/**
 *Submitted for verification at FtmScan.com on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract BoxV2 {
    uint public counter;

    //This function only called in Box.sol
    /*function initialize(uint _counter) external {
        counter = _counter;
    }*/

    function increment() external {
        counter += 914;
    }
}
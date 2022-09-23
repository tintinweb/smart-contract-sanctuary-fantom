/**
 *Submitted for verification at FtmScan.com on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Box {
    uint public counter;
    
    //In upgradeable contracts, state variables inside implementation contracts aren't used
    //No constructors for upgradeable contracts
    // constructor(uint _val) {
    //      val = _val;
    // }

    function initialize(uint _counter) external {
        counter = _counter;
    }
}
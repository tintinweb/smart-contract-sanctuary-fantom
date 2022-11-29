/**
 *Submitted for verification at FtmScan.com on 2022-11-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Greeter {
    
    string public greeting = "This verified on FTMScan";

    // update a new greeting

    function write(string memory newGreeting) public {
        greeting = newGreeting;
    }
}
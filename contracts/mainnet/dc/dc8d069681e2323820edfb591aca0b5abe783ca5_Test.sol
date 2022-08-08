/**
 *Submitted for verification at FtmScan.com on 2022-08-08
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

contract Test {
    event TestEvent(address, uint);
    
    uint public index;

    function test() external {
        emit TestEvent(msg.sender, index);
        index += 1;
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TetnTest {
    address public someSender;
    uint256 public argument;
    constructor(){
    }
    function testSome(uint256 _argument) external
    {
        someSender = msg.sender;
        argument = _argument;
    }
}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Eventy {
    uint256 public value;

    event BeforeAdd(uint256 value);
    event AfterAdd(uint256 value);

    function emitEvent() public {
        emit BeforeAdd(value);
        value += 1;
        emit AfterAdd(value);
    }
}
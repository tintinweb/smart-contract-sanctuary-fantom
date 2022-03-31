//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

contract Refinery {
    address public operator;

    constructor(
        address _operator
    ) {
        operator = _operator;
    }
}
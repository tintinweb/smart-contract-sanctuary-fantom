// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract SomeImplementation {
    bool public stateChanged;

    function test() external {
        stateChanged = true;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DynamicArrays {
    uint256[] public array;

    function push(uint256 value) public {
        array.push(value);
    }

    function pop() public {
        array.pop();
    }

    function delet() public {
        delete array[array.length - 1];
    }

    function get(uint256 index) public view returns (uint256) {
        return array[index];
    }

    function length() public view returns (uint256) {
        return array.length;
    }
}
//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract news {
    uint256 public pool;

    constructor() {
        pool = 2;
    }

    function setPool(uint256 _pool) external {
        pool = _pool;
    }
}
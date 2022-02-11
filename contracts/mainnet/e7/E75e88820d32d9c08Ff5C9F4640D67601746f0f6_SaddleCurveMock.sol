// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "../interfaces/swaps/ICurvePool.sol";

contract SaddleCurveMock {

    address public curvePool;

    constructor(address _pool) {
        curvePool = _pool;
    }

    function getVirtualPrice() public view returns (uint256) {
        return ICurvePool(curvePool).get_virtual_price();
    }

    function swap() public view returns (address) {
        return address(this);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);
}
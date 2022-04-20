// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./IUniswapV2Callee.sol";
import "./IUniswapV2Pair.sol";

contract flashswap is IUniswapV2Callee {
    address lp;
    uint token0;
    uint token1;

    function _flashswap(address _lp, uint amount0, uint amount1) external {
        lp = _lp;
        (token0, token1, ) = IUniswapV2Pair(_lp).getReserves();
        IUniswapV2Pair(lp).swap(amount0, amount1, address(this), new bytes(11));
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override{
        payable(lp).transfer(amount1 * 1000 / 997);
    }

}
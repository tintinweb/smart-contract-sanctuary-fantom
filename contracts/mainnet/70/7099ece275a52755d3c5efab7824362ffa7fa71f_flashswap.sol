// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./IUniswapV2Callee.sol";
import "./IUniswapV2Pair.sol";
import "./Withdrawable.sol";

contract flashswap is IUniswapV2Callee, Withdrawable {
    address lp;
    address token0;
    address token1;

    function _flashswap(address _lp, uint amount0, uint amount1) external {
        lp = _lp;
        token0 = IUniswapV2Pair(lp).token0();
        IUniswapV2Pair(lp).swap(amount0, amount1, address(this), new bytes(11));
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override{
        IERC20(token0).transfer(lp, amount0 * 1000 / 997);
    }

}
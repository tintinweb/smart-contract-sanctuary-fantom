// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IUniswapV2Callee.sol";
import "./IUniswapV2Pair.sol";
import "./Withdrawable.sol";
import "./UniswapV2Library.sol";
import "./IUniswapV2Factory.sol";
import "./SafeMath.sol";
import "./Math.sol";

contract flashswap is IUniswapV2Callee, Withdrawable {
    using SafeMath for uint256;

    address lp0;
    address lp1;

    address factory0;
    address factory1;

    address tokenX;
    address tokenY;

    uint reserveX0;
    uint reserveY0;
    uint reserveX1;
    uint reserveY1;

    uint fee0;
    uint fee1;

    function trigger(address _lpBuy, address _lpSell, uint _feeBuy, uint _feeSell, address _tokenX, address _tokenY) external{
        lp0 = _lpBuy;
        lp1 = _lpSell;

        tokenX = _tokenX;
        tokenY = _tokenY;

        if(_tokenX == IUniswapV2Pair(_lpBuy).token0()){
            (reserveX0, reserveY0, ) = IUniswapV2Pair(_lpBuy).getReserves();
            (reserveX1, reserveY1, ) = IUniswapV2Pair(_lpSell).getReserves();
        }else{
            (reserveY0, reserveX0, ) = IUniswapV2Pair(_lpBuy).getReserves();
            (reserveY1, reserveX1, ) = IUniswapV2Pair(_lpSell).getReserves();
        }

        factory0 = IUniswapV2Pair(_lpBuy).factory();
        factory1 = IUniswapV2Pair(_lpSell).factory();

        fee0 = 1000 - _feeBuy;
        fee1 = 1000 - _feeSell;

        assert(check());
        _flashswap(_lpBuy, 0, UniswapV2Library.getAmountOut(factory0, _getAmount(), reserveX0, reserveY0));
    }

    function _flashswap(address _lp, uint amount0, uint amount1) internal {
        IUniswapV2Pair(_lp).swap(amount0, amount1, address(this), new bytes(1));
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override{
            uint amount = UniswapV2Library.getAmountOut(factory1, amount1, reserveY1, reserveX1);
            uint amountRepay = UniswapV2Library.getAmountIn(factory0, amount1, reserveX0, reserveY0);
            require(amount > amountRepay, "arbitrage failure!");
            IERC20(tokenY).transfer(lp1, amount1);
            IUniswapV2Pair(lp1).swap(amount, 0, address(this), new bytes(0));
            IERC20(tokenX).transfer(lp0, amountRepay);
  //        withdraw(tokenX);
    }

    function check() public view returns(bool success){ 
        uint temp1 = reserveX1.mul(reserveY0).mul(fee0).mul(fee1);
        uint temp2 = reserveX0.mul(reserveY1).mul(1000000);
        require(temp1 > temp2, "cannnot execute!");
        success = true;
        return success;
    }

    function _getAmount() public view returns(uint amount){
        uint temp1 = Math.sqrt(reserveX0.mul(reserveY0).mul(fee0));
        uint temp2 = Math.sqrt(reserveX1.mul(reserveY1).mul(fee1));
        uint numerator = temp1.mul(temp2).sub(reserveX0.mul(reserveY1).mul(1000));
        require(numerator > 0, "cannot get positive amount!");
        uint temp3 = reserveY0.mul(fee0).mul(fee1).div(1000);
        uint temp4 = reserveY1.mul(fee0);
        uint denominator = temp3.add(temp4);
        amount = numerator.div(denominator);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Pair.sol";
import "./Ownable.sol";
import "./Withdrawable.sol";
import "./Math.sol";

contract arbitrage is Withdrawable{

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes4 private constant FUNC_SELECTOR_SWAP_EXACT_TOKENS_FOR_TOKENS = bytes4(keccak256("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"));

    function trigger(address buy, address sell, address buyLP, address sellLP, address tokenIn, address tokenOut, uint _feeBuy, uint _feeSell) public {
//      uint amount = _getAmount(buyLP, sellLP, _feeBuy, _feeSell);
        uint amount = 1000000000000000000;
        _trigger(amount, buy, sell, buyLP, sellLP, tokenIn, tokenOut, _feeBuy, _feeSell);
    }
    function _trigger(uint amount, address buy, address sell, address buyLP, address sellLP, address tokenIn, address tokenOut, uint _feeBuy, uint _feeSell) public  returns(bool isComplete){
 //      require(check(buyLP, sellLP, _feeBuy, _feeSell) == true, "call failure!");
        IERC20(tokenIn).safeIncreaseAllowance(buy, amount);
		IERC20(tokenOut).safeIncreaseAllowance(buy, amount);
		IERC20(tokenIn).safeIncreaseAllowance(sell, amount);
        IERC20(tokenOut).safeIncreaseAllowance(sell, amount); 
        uint start_amount = amount;
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), start_amount);
        uint amountA = _buy(start_amount, buy, tokenIn, tokenOut);
        uint last_amount = _sell(amountA, sell, tokenOut, tokenIn);
        assert(last_amount > start_amount / 2);
        isComplete = true;
        return isComplete;
    }


    function _buy(uint amount, address addr, address token0, address token1) internal returns(uint amountA){
        _swapExactTokensForTokens(amount, 0, _getPath(token0, token1), address(this), block.timestamp.add(60), addr);
        amountA = IERC20(token1).balanceOf(address(this));
    }

    function _sell(uint amount, address addr, address token0, address token1) internal returns(uint amountB){
        _swapExactTokensForTokens(amount, 0, _getPath(token0, token1), address(this), block.timestamp.add(60), addr);
        amountB = IERC20(token1).balanceOf(address(this));
    }

    function _swapExactTokensForTokens(uint256 amountIn, 
        uint256 amountOutMin, 
        address[] memory path, 
        address to, 
        uint256 deadline,
        address addr
        ) internal  returns (bytes memory){

		bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_SWAP_EXACT_TOKENS_FOR_TOKENS,
        amountIn,
        amountOutMin,
        path,
        to,
        deadline
        );

		(bool success, bytes memory returnData) = addr.call(data);
		require(success == true, "call failure");
		return returnData;
    }

    function _getPath(address token0, address token1) private pure returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        return path;
    }

 /*   function check(address buyLP, address sellLP, uint _feeBuy, uint _feeSell) public view returns(bool success){
        (uint256 _reserveX0, uint256 _reserveY0, ) = IUniswapV2Pair(buyLP).getReserves();
        (uint256 _reserveX1, uint256 _reserveY1, ) = IUniswapV2Pair(sellLP).getReserves();
        uint _feeIn = 1000 - _feeBuy;
        uint _feeOut = 1000 - _feeSell;
        uint temp1 = _reserveX1.mul(_reserveY0).mul(_feeIn).mul(_feeOut).div(1000000);
        uint temp2 = _reserveX0.mul(_reserveY1);
        require(temp1 > temp2, "cannnot execute!");
        success = true;
    }
*/
    function _getAmount(address buyLP, address sellLP, uint _feeBuy, uint _feeSell) public view returns(uint amount){
        (uint256 _reserveX0, uint256 _reserveY0, ) = IUniswapV2Pair(buyLP).getReserves();
        (uint256 _reserveX1, uint256 _reserveY1, ) = IUniswapV2Pair(sellLP).getReserves();
        _feeBuy = 1000 - _feeBuy;
        _feeSell = 1000 - _feeSell;
        uint temp1 = Math.sqrt(_reserveX0.mul(_reserveY0).mul(_feeBuy).div(1000));
        uint temp2 = Math.sqrt(_reserveX1.mul(_reserveY1).mul(_feeSell).div(1000));
        uint numerator = temp1.mul(temp2).sub(_reserveX0.mul(_reserveY1));
        require(numerator > 0, "cannot get positive amount!");
        uint temp3 = _reserveY0.mul(_feeBuy).mul(_feeSell).div(1000000);
        uint temp4 = _reserveY1.mul(_feeBuy).div(1000);
        uint denominator = temp3.add(temp4);
        amount = numerator.div(denominator);
    }
}
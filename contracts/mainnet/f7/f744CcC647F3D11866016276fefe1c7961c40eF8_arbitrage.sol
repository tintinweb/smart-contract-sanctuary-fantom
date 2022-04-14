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

 //   address private constant TOMB_FINANCE_ROUTER = 0x6D0176C5ea1e44b08D3dd001b0784cE42F47a3A7; 
//    address private constant SpookySwap_Router = 0xF491e7B69E4244ad4002BC14e878a34207E38c29; 
//	address private constant TOMB = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7;
 //   address private constant BASED = 0x8D7d3409881b51466B483B11Ea1B8A03cdEd89ae;
    

    bytes4 private constant FUNC_SELECTOR_SWAP_EXACT_TOKENS_FOR_TOKENS = bytes4(keccak256("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"));

    function trigger(address buy, address sell, address buyLP, address sellLP, address tokenIn, address tokenOut, uint _feeBuy, uint _feeSell) public  returns(bool isComplete){
  //      require(check(buyLP, sellLP, _feeBuy, _feeSell) == true, "call failure!");
        IERC20(tokenIn).safeApprove(buy, type(uint256).max);
		IERC20(tokenOut).safeApprove(buy, type(uint256).max);
		IERC20(tokenIn).safeApprove(sell, type(uint256).max);
        IERC20(tokenOut).safeApprove(sell, type(uint256).max);
        uint start_amount = _getAmount(buyLP, sellLP, _feeBuy, _feeSell);
        IERC20(tokenIn).safeTransfer(address(this), start_amount);
 //       payable(address(this)).transfer(msg.value);
 //       uint start_amount = address(this).balance;   
        uint amountA = _buy(start_amount, buy, tokenIn, tokenOut);
        uint last_amount = _sell(amountA, sell, tokenOut, tokenIn);
        assert(last_amount > start_amount.mul(90).div(100));
        withdraw(tokenIn);
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
        ) internal returns (bytes memory){

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
        uint _feeIn = 1000 - _feeBuy;
        uint _feeOut = 1000 - _feeSell;
        uint temp1 = _reserveX0.mul(_reserveY0).mul(_feeIn).div(1000);
        uint temp2 = _reserveX1.mul(_reserveY1).mul(_feeOut).div(1000);
        uint temp3 = _reserveX0.mul(_reserveY1);
        uint numerator = Math.sqrt(temp1).mul(Math.sqrt(temp2));
        uint temp5 = _reserveY0.mul(_feeIn).mul(_feeOut).div(1000000);
        uint temp6 = _reserveY1.mul(_feeIn).div(1000);
        uint denominator = temp5.add(temp6);
        amount = numerator.div(denominator);
    }
}
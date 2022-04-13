// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Withdrawable.sol";

contract arbitrage is Withdrawable{

    bytes4 private constant FUNC_SELECTOR_SWAP_EXACT_TOKENS_FOR_TOKENS = bytes4(keccak256("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"));

    function trigger(address addr0, address addr1, address token0, address token1) public  returns(bool isComplete){
 //       payable(address(this)).transfer(msg.value);
 //       uint start_amount = address(this).balance;
        uint start_amount = IERC20(token0).balanceOf(address(this));
        uint amountA = buy(start_amount, addr0, token0, token1);
        uint last_amount = sell(amountA, addr1, token1, token0);
        assert(last_amount > (start_amount / 2));
  //      withdraw(token0);
        isComplete = true;
        return isComplete;
    }


    function buy(uint amount, address addr, address token0, address token1) public returns(uint amountA){
        _swapExactTokensForTokens(amount, 0, _getPath(token0, token1), address(this), 60, addr);
        amountA = IERC20(token1).balanceOf(address(this));
    }

    function sell(uint amount, address addr, address token0, address token1) public returns(uint amountB){
        _swapExactTokensForTokens(amount, 0, _getPath(token0, token1), address(this), 60, addr);
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
        amountOutMin,
        path,
        to,
        deadline
        );

		(bool success, bytes memory returnData) = addr.call{value: amountIn}(data);
		require(success == true, "call failure");
		return returnData;
    }

    function _getPath(address token0, address token1) private pure returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        return path;
    }
}
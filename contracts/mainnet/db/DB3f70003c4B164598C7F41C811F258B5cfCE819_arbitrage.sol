// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Withdrawable.sol";

contract arbitrage is Withdrawable{

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private constant TOMB_FINANCE_ROUTER = 0x6D0176C5ea1e44b08D3dd001b0784cE42F47a3A7; 
    address private constant SpookySwap_Router = 0xF491e7B69E4244ad4002BC14e878a34207E38c29; 
	address private constant TOMB = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7;
    address private constant BASED = 0x8D7d3409881b51466B483B11Ea1B8A03cdEd89ae;
    

    bytes4 private constant FUNC_SELECTOR_SWAP_EXACT_TOKENS_FOR_TOKENS = bytes4(keccak256("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"));

    function trigger(address addr0, address addr1, address token0, address token1) public  returns(bool isComplete){
        IERC20(TOMB).safeApprove(address(TOMB_FINANCE_ROUTER), type(uint256).max);
		IERC20(BASED).safeApprove(address(TOMB_FINANCE_ROUTER), type(uint256).max);
		IERC20(TOMB).safeApprove(address(SpookySwap_Router), type(uint256).max);
        IERC20(BASED).safeApprove(address(SpookySwap_Router), type(uint256).max);
 //       payable(address(this)).transfer(msg.value);
 //       uint start_amount = address(this).balance;
        uint start_amount = IERC20(token0).balanceOf(address(this));
        uint amountA = buy(start_amount, addr0, token0, token1);
        uint last_amount = sell(amountA, addr1, token1, token0);
        assert(last_amount > start_amount.div(2));
  //      withdraw(token0);
        isComplete = true;
        return isComplete;
    }


    function buy(uint amount, address addr, address token0, address token1) public returns(uint amountA){
        _swapExactTokensForTokens(amount, 0, _getPath(token0, token1), address(this), block.timestamp.add(60), addr);
        amountA = IERC20(token1).balanceOf(address(this));
    }

    function sell(uint amount, address addr, address token0, address token1) public returns(uint amountB){
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
}
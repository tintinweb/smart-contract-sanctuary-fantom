// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./UniswapV2Library.sol";
import "./Withdrawable.sol";
import "./Math.sol";

/**
 * @dev Implementation of the aggregated transection on TOMB FINANCE.
 */

contract AggregationTransection_FTM_TOMB_BASED is Withdrawable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // address needed
    address private constant BSHARE_Rewards_Pool = 0xAc0fa95058616D7539b6Eecb6418A68e7c18A746; 
	address private constant Spookyswap_ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29; 
    address private constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
	address private constant BASED = 0x8D7d3409881b51466B483B11Ea1B8A03cdEd89ae;
	address private constant TOMB = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7;
	address private constant LP_BASED_TOMB = 0xaB2ddCBB346327bBDF97120b0dD5eE172a9c8f9E;
    address private constant BSHARE = 0x49C290Ff692149A4E16611c694fdED42C954ab7a;

    //function selector needed
	bytes4 private constant FUNC_SELECTOR_DEPOSIT = bytes4(keccak256("deposit(uint256,uint256)"));
	bytes4 private constant FUNC_SELECTOR_WITHDRAW = bytes4(keccak256("withdraw(uint256,uint256)"));
	bytes4 private constant FUNC_SELECTOR_ADD_LIQUIDITY = bytes4(keccak256("addLiquidity(address,address,uint,uint,uint,uint,address,uint)"));
	bytes4 private constant FUNC_SELECTOR_REMOVE_LIQUIDITY = bytes4(keccak256("removeLiquidity(address,addresss,uint,uint,uint,address,uint)"));
    bytes4 private constant FUNC_SELECTOR_SWAP_EXACT_TOKENS_FOR_TOKENS = bytes4(keccak256("swapExactTokensForETH(uint,uint,address[],address,uint)"));
    bytes4 private constant FUNC_SELECTOR_SWAP_EXACT_TOKENS_FOR_ETH = bytes4(keccak256("swapExactTokensForETH(uint256,uint256,address[],address,uint256)"));
    bytes4 private constant FUNC_SELECTOR_SWAP_EXACT_ETH_FOR_TOKENS = bytes4(keccak256("swapExactETHForTokens(uint256,address[],address,uint256)"));

    uint liquidity;
    uint amountOfETH;
    address current_address;

	receive() payable external {}

	constructor() public {
		IERC20(WFTM).safeApprove(address(Spookyswap_ROUTER), type(uint256).max);
		IERC20(TOMB).safeApprove(address(Spookyswap_ROUTER), type(uint256).max);
        IERC20(BASED).safeApprove(address(Spookyswap_ROUTER), type(uint256).max);
        IERC20(LP_BASED_TOMB).safeApprove(address(Spookyswap_ROUTER), type(uint256).max);
        IERC20(LP_BASED_TOMB).safeApprove(address(BSHARE_Rewards_Pool), type(uint256).max);
   }

    //swap function for deposit 
    function _swapExactETHForTokens(uint256 amountTokenDesired, 
        uint256 amountOutMin, 
        address[] memory path, 
        address to, 
        uint256 deadline
        ) public onlyWhitelisted returns (bytes memory){

		bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_SWAP_EXACT_ETH_FOR_TOKENS, 
        amountOutMin,
        path,
        to,
        deadline
        );

		(bool success, bytes memory returnData) = Spookyswap_ROUTER.call{value: amountTokenDesired}(data);
		require(success == true, "call failure");
		return returnData;
    }

    function _swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) public onlyWhitelisted returns (bytes memory){

		bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_SWAP_EXACT_TOKENS_FOR_TOKENS,
        amountIn, 
        amountOutMin,
        path,
        to,
        deadline
        );

		(bool success, bytes memory returnData) = Spookyswap_ROUTER.call(data);
		require(success == true, "call failure");
		return returnData;
    }

    //add liquidity
	function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public onlyWhitelisted returns (bytes memory) {
			bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_ADD_LIQUIDITY,
			tokenA, 
            tokenB,
			amountADesired,
			amountBDesired,
			amountAMin,
            amountBMin,
			to,
			deadline
            );

			(bool success, bytes memory returnData) = Spookyswap_ROUTER.call(data);
			require(success == true, "call failure");
			liquidity = IERC20(LP_BASED_TOMB).balanceOf(address(this));
			return returnData;
	}

    //remove liquidity
	function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidityAmount,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public onlyWhitelisted returns (bytes memory) {
			bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_REMOVE_LIQUIDITY,
			tokenA, 
            tokenB,
			liquidityAmount,
			amountAMin,
			amountBMin,
			to,
			deadline
            );

			(bool success, bytes memory returnData) = Spookyswap_ROUTER.call(data);
			require(success == true, "call failure");
			liquidity = 0;
			return returnData;
	}

    //deposit
    function _deposit(uint256 _pid, uint256 _amount) public onlyWhitelisted returns (bytes memory) {
		bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_DEPOSIT, _pid, _amount);
		(bool success, bytes memory returnData) = BSHARE_Rewards_Pool.call(data);
		require(success == true, "call failure");
        liquidity = 0;
        whitelist[current_address].liquidityDeposited += _amount;
		return returnData;
	}

    //withdraw
	function _withdrawLiquidity(uint256 _pid, uint256 _amount) public onlyWhitelisted returns (bytes memory) {
        require(_amount <= whitelist[current_address].liquidityDeposited, "not enough liquidity! Please check for the whitelist.");
		bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_WITHDRAW, _pid, _amount);
		(bool success, bytes memory returnData) = BSHARE_Rewards_Pool.call(data);
		require(success == true, "call failure");
        whitelist[current_address].liquidityDeposited -= _amount;
        liquidity = IERC20(LP_BASED_TOMB).balanceOf(address(this));
		return returnData;
	}

    function AggregationExecutor_deposit_FTM(
        uint amountTombOutMin,
        uint amountBasedOutMin,  
        uint amountAMin_addLiquidity, 
        uint amountBMin_addLiquidity,
        uint deadline
    ) external payable onlyWhitelisted{
        amountOfETH = address(this).balance;
        current_address = msg.sender;
        uint amountIn = amountOfETH;
        address to = address(this);
        uint amountTomb;

        _swapExactETHForTokens(amountIn, amountTombOutMin, _getPathForETHSwap(), to, deadline);
        amountTomb = IERC20(TOMB).balanceOf(address(this));

        AggregationExecutor_deposit(amountTomb, amountBasedOutMin, amountAMin_addLiquidity, amountBMin_addLiquidity, deadline);
    }
    
    //Aggregation for deposit
    function AggregationExecutor_deposit(
        uint amount,
        uint amountOutMin,  
        uint amountAMin_addLiquidity, 
        uint amountBMin_addLiquidity,
        uint deadline
        )  public  onlyWhitelisted {
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 _pid = 0;
        address tokenA = TOMB;
        address tokenB = BASED;
        address to = address(this);
        uint256 amountIn = _getAmountIn(amount);

        _swapExactTokensForTokens(amountIn, amountOutMin, _getPathForDeposit(), to, deadline);

        amountADesired = IERC20(TOMB).balanceOf(address(this));
        amountBDesired = IERC20(BASED).balanceOf(address(this));
        _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin_addLiquidity, amountBMin_addLiquidity, to, deadline);

        _deposit(_pid, liquidity);  

        withdraw(TOMB);
        withdraw(BASED);
    }

    //Aggregation for withdraw
    function AggregationExecutor_withdraw(
        uint256 _amount, 
        uint amountAMin_addLiquidity, 
        uint amountBMin_addLiquidity,
        uint amountOutMin,
        uint deadline
        ) public onlyWhitelisted {
        uint amountIn; 
        uint256 _pid = 0;
		address tokenA = TOMB;
        address tokenB = BASED;
        address to = address(this);
        current_address = msg.sender;
        
        _withdrawLiquidity(_pid, _amount); 

        _removeLiquidity(tokenA, tokenB, _amount, amountAMin_addLiquidity, amountBMin_addLiquidity, to, deadline);

        amountIn = IERC20(BASED).balanceOf(address(this));      
        _swapExactTokensForTokens(amountIn, amountOutMin, _getPathForWithdraw(), to, deadline);

        withdraw(ETHER);

        withdraw(BSHARE);
    }

    function withdrawRewards() external onlyWhitelisted {
        uint _pid = 0;
        uint amount = 0;
        _withdrawLiquidity(_pid, amount);
        withdraw(BSHARE);
    }

    //read diposited liquidity for certain address
    function getDepositedLiquidity(address addr) public view returns (uint){
        return whitelist[addr].liquidityDeposited;
    }
    
/*
    function getLiquidityETHDesired(uint amountADesired) public view returns(uint amountBOptimal){
        (uint112 _reserveWFTM, uint112 _reserveTomb, ) = IUniswapV2Pair(LP_BASED_TOMB).getReserves();
        amountBOptimal = UniswapV2Library.quote(amountADesired, _reserveTomb, _reserveWFTM);
        return amountBOptimal;
    }
*/

    function _getPathForETHSwap() private pure returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = WFTM;
        path[1] = TOMB;
        return path;
    }

    function _getPathForDeposit() private pure returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = TOMB;
        path[1] = BASED;
        return path;
    }

    function _getPathForWithdraw() private pure returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = BASED;
        path[1] = TOMB;
        return path;
    }

    /*calculate the amount of eth for swap with a certain number of eth received
    * make ture that the error range is below 0.01%
    */
    function _getAmountIn(uint amountIn) public view returns(uint amountOut){
        (uint256 _reserveTOMB, uint256 _reserveBASED, ) = IUniswapV2Pair(LP_BASED_TOMB).getReserves();
        uint temp1 = amountIn.mul(_reserveTOMB).mul(998000).mul(4);
        uint temp2 = _reserveTOMB.mul(_reserveTOMB).mul(3992004);
        uint temp3 = Math.sqrt(temp1.add(temp2));
        uint temp4 = _reserveTOMB.mul(1998);
        uint temp5 = temp3 - temp4;
        amountOut = temp5.div(1996);
    }

}
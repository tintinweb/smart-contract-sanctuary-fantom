// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./UniswapV2Library.sol";
import "./Withdrawable.sol";
import "./Math.sol";
import "./IUniswapV2Router01.sol";

/**
 * @dev Implementation of the aggregated transection on TOMB FINANCE.
 */

contract AggregationTransection_FTM_TOMB_BASED is Withdrawable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // address needed
    address private constant BSHARE_Rewards_Pool = 0xAc0fa95058616D7539b6Eecb6418A68e7c18A746; 
	address private constant Spookyswap_ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29; 
    address private constant TOMB_FINANCE_ROUTER = 0x6D0176C5ea1e44b08D3dd001b0784cE42F47a3A7;
    address private constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
	address private constant BASED = 0x8D7d3409881b51466B483B11Ea1B8A03cdEd89ae;
	address private constant TOMB = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7;
	address private constant LP_BASED_TOMB = 0xaB2ddCBB346327bBDF97120b0dD5eE172a9c8f9E;
    address private constant BSHARE = 0x49C290Ff692149A4E16611c694fdED42C954ab7a;

    //function selector needed
	bytes4 private constant FUNC_SELECTOR_DEPOSIT = bytes4(keccak256("deposit(uint256,uint256)"));
	bytes4 private constant FUNC_SELECTOR_WITHDRAW = bytes4(keccak256("withdraw(uint256,uint256)"));
    bytes4 private constant FUNC_SELECTOR_SWAP_EXACT_ETH_FOR_TOKENS = bytes4(keccak256("swapExactETHForTokens(uint256,address[],address,uint256)"));

	receive() payable external {}

	constructor() public {
		IERC20(WFTM).safeApprove(address(Spookyswap_ROUTER), type(uint256).max);
		IERC20(TOMB).safeApprove(address(Spookyswap_ROUTER), type(uint256).max);
        IERC20(BASED).safeApprove(address(Spookyswap_ROUTER), type(uint256).max);
        IERC20(LP_BASED_TOMB).safeApprove(address(Spookyswap_ROUTER), type(uint256).max);
        IERC20(LP_BASED_TOMB).safeApprove(address(BSHARE_Rewards_Pool), type(uint256).max);
   }

    function AggregationExecutor_deposit_FTM(
        uint amountTombOutMin,
        uint amountBasedOutMin,  
        uint amountAMin_addLiquidity, 
        uint amountBMin_addLiquidity,
        uint deadline
    ) external payable onlyWhitelisted{
        _swapExactETHForTokens(address(this).balance, amountTombOutMin, _getPathForETHSwap(), address(this), deadline);
        uint amountTomb = IERC20(TOMB).balanceOf(address(this));
        AggregationExecutor_deposit(amountTomb, amountBasedOutMin, amountAMin_addLiquidity, amountBMin_addLiquidity, deadline);
    }
    
    function AggregationExecutor_deposit_TOMB(
        uint amountTomb,
        uint amountBasedOutMin,  
        uint amountAMin_addLiquidity, 
        uint amountBMin_addLiquidity,
        uint deadline
    ) external onlyWhitelisted{
        IERC20(TOMB).safeTransferFrom(msg.sender, address(this), amountTomb);
        AggregationExecutor_deposit(amountTomb, amountBasedOutMin, amountAMin_addLiquidity, amountBMin_addLiquidity, deadline);
    }

    //Aggregation for deposit
    function AggregationExecutor_deposit(
        uint amount,
        uint amountOutMin,  
        uint amountAMin_addLiquidity, 
        uint amountBMin_addLiquidity,
        uint deadline
    ) internal onlyWhitelisted {
        uint256 _pid = 0;
        address tokenA = TOMB;
        address tokenB = BASED;

        _swapExactTokensForTokens(_getAmountIn(amount), amountOutMin, _getPathForDeposit(), address(this), deadline);
        uint amountADesired = IERC20(TOMB).balanceOf(address(this));
        uint amountBDesired = IERC20(BASED).balanceOf(address(this));
        _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin_addLiquidity, amountBMin_addLiquidity, address(this), deadline);
        _deposit(_pid, IERC20(LP_BASED_TOMB).balanceOf(address(this)));  
        withdraw(TOMB);
        withdraw(BASED);
    }

    function depositOnly(uint _pid, uint _amount) external onlyWhitelisted{
        IERC20(LP_BASED_TOMB).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(_pid, _amount);  
    }

    //Aggregation for withdraw
    function AggregationExecutor_withdraw(
        uint256 _amount, 
        uint amountAMin_addLiquidity, 
        uint amountBMin_addLiquidity,
        uint amountOutMin,
        uint deadline
    ) public onlyWhitelisted {
        uint256 _pid = 0;
		address tokenA = TOMB;
        address tokenB = BASED;
   
        _withdrawLiquidity(_pid, _amount); 
        _removeLiquidity(tokenA, tokenB, _amount, amountAMin_addLiquidity, amountBMin_addLiquidity, address(this), deadline);
        uint amountIn = IERC20(BASED).balanceOf(address(this));      
        _swapExactTokensForTokens(amountIn, amountOutMin, _getPathForWithdraw(), address(this), deadline);
        withdraw(TOMB);
        withdraw(BSHARE);
    }

    function withdrawOnly(uint _pid, uint _amount) external onlyWhitelisted{
        _withdrawLiquidity(_pid, _amount); 
        withdraw(LP_BASED_TOMB);
        withdraw(BSHARE); 
    }

    //swap function for deposit 
    function _swapExactETHForTokens(uint256 amountTokenDesired, 
        uint256 amountOutMin, 
        address[] memory path, 
        address to, 
        uint256 deadline
    ) public onlyWhitelisted {
		bytes memory data = abi.encodeWithSelector(
            FUNC_SELECTOR_SWAP_EXACT_ETH_FOR_TOKENS, amountOutMin, path, to, deadline
        );
		(bool success, bytes memory returnData) = Spookyswap_ROUTER.call{value: amountTokenDesired}(data);
		require(success == true, "call failure");
    }

    function _swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) public onlyWhitelisted {
        IUniswapV2Router01(Spookyswap_ROUTER).swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
    }

    //add liquidity
	function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public onlyWhitelisted {
        IUniswapV2Router01(Spookyswap_ROUTER).addLiquidity(
            tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline
        );
	}

    //remove liquidity
	function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidityAmount,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public onlyWhitelisted  {
        IUniswapV2Router01(Spookyswap_ROUTER).removeLiquidity(
            tokenA, tokenB, liquidityAmount, amountAMin, amountBMin, to, deadline
        );
	}

    //deposit
    function _deposit(uint256 _pid, uint256 _amount) public onlyWhitelisted {
		bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_DEPOSIT, _pid, _amount);
		(bool success, bytes memory returnData) = BSHARE_Rewards_Pool.call(data);
		require(success == true, "call failure");
        whitelist[msg.sender].liquidityDeposited += _amount;
	}

    //withdraw
	function _withdrawLiquidity(uint256 _pid, uint256 _amount) public onlyWhitelisted {
        require(_amount <= whitelist[msg.sender].liquidityDeposited, "not enough liquidity! Please check for the whitelist.");
		bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_WITHDRAW, _pid, _amount);
		(bool success, bytes memory returnData) = BSHARE_Rewards_Pool.call(data);
		require(success == true, "call failure");
        whitelist[msg.sender].liquidityDeposited -= _amount;
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

    /*calculate the amount of Based for swap with a fixed number of tomb received
    * make ture that the error range is below 0.01%
    */
    function _getAmountIn(uint amountIn) public view returns(uint amountOut){
        (uint256 _reserveTOMB, , ) = IUniswapV2Pair(LP_BASED_TOMB).getReserves();
        uint temp1 = amountIn.mul(_reserveTOMB).mul(998000).mul(4);
        uint temp2 = _reserveTOMB.mul(_reserveTOMB).mul(3992004);
        uint temp3 = Math.sqrt(temp1.add(temp2));
        uint temp4 = _reserveTOMB.mul(1998);
        uint temp5 = temp3 - temp4;
        amountOut = temp5.div(1996);
    }

}
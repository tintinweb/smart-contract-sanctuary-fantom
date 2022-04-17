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

contract AggregationTransection is Withdrawable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // address needed
    address private constant TOMB_FINANCE_TSHARE_REWARDS_POOL = 0xcc0a87F7e7c693042a9Cc703661F5060c80ACb43; 
	address private constant TOMB_FINANCE_ROUTER = 0x6D0176C5ea1e44b08D3dd001b0784cE42F47a3A7; 
    address private constant Spookyswap_ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address private constant TOMB_FACTOTY = 0xE236f6890F1824fa0a7ffc39b1597A5A6077Cfe9;
	address private constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
	address private constant TOMB = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7;
	address private constant LP_FTM_TOMB = 0xfca12A13ac324C09e9F43B5e5cfC9262f3Ab3223;
    address private constant TSHARE = 0x4cdF39285D7Ca8eB3f090fDA0C069ba5F4145B37;

    //function selector needed
	bytes4 private constant FUNC_SELECTOR_DEPOSIT = bytes4(keccak256("deposit(uint256,uint256)"));
	bytes4 private constant FUNC_SELECTOR_WITHDRAW = bytes4(keccak256("withdraw(uint256,uint256)"));
	bytes4 private constant FUNC_SELECTOR_ADD_LIQUIDITY_ETH = bytes4(keccak256("addLiquidityETH(address,uint256,uint256,uint256,address,uint256)"));
	bytes4 private constant FUNC_SELECTOR_REMOVE_LIQUIDITY_ETH = bytes4(keccak256("removeLiquidityETH(address,uint256,uint256,uint256,address,uint256)"));
    bytes4 private constant FUNC_SELECTOR_SWAP_EXACT_TOKENS_FOR_ETH = bytes4(keccak256("swapExactTokensForETH(uint256,uint256,address[],address,uint256)"));
    bytes4 private constant FUNC_SELECTOR_SWAP_EXACT_ETH_FOR_TOKENS = bytes4(keccak256("swapExactETHForTokens(uint256,address[],address,uint256)"));

    uint liquidity;
    uint amountOfETH;
    address current_address;

	receive() payable external {}

	constructor() public {
        IERC20(LP_FTM_TOMB).safeApprove(address(TOMB_FINANCE_TSHARE_REWARDS_POOL), type(uint256).max);
		IERC20(WFTM).safeApprove(address(TOMB_FINANCE_ROUTER), type(uint256).max);
		IERC20(TOMB).safeApprove(address(TOMB_FINANCE_ROUTER), type(uint256).max);
        IERC20(WFTM).safeApprove(address(Spookyswap_ROUTER), type(uint256).max);
        IERC20(TOMB).safeApprove(address(Spookyswap_ROUTER), type(uint256).max);
        IERC20(LP_FTM_TOMB).safeApprove(address(TOMB_FINANCE_ROUTER), type(uint256).max);
   }

    //swap function for deposit 
    function _swapExactETHForTokens(uint256 amountTokenDesired, 
        uint256 amountOutMin, 
        address[] memory path, 
        address to, 
        uint256 deadline
        ) internal onlyWhitelisted returns (bytes memory){

		bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_SWAP_EXACT_ETH_FOR_TOKENS, 
        amountOutMin,
        path,
        to,
        deadline
        );

		(bool success, bytes memory returnData) = TOMB_FINANCE_ROUTER.call{value: amountTokenDesired}(data);
		require(success == true, "call failure");
		return returnData;
    }
    
    //swap function for remove 
    function _swapExactTokensForETH(
        address addr,
        uint amountIn, 
        uint amountOutMin, 
        address[] memory path, 
        address to, 
        uint deadline
        ) internal onlyWhitelisted returns (bytes memory){

        bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_SWAP_EXACT_TOKENS_FOR_ETH,
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

    //add liquidity
	function _addLiquidityETH(
		address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
		) internal onlyWhitelisted returns (bytes memory) {
			bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_ADD_LIQUIDITY_ETH,
			token, 
			amountTokenDesired,
			amountTokenMin,
			amountETHMin,
			to,
			deadline
            );

			(bool success, bytes memory returnData) = TOMB_FINANCE_ROUTER.call{
                value: amountOfETH}(data);
			require(success == true, "call failure");
			liquidity = IERC20(LP_FTM_TOMB).balanceOf(address(this));
			return returnData;
	}

    //remove liquidity
	function _removeLiquidityETH(
		address token,
        uint256 amount,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
		) internal onlyWhitelisted returns (bytes memory) {
			bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_REMOVE_LIQUIDITY_ETH,
			token, 
			amount,
			amountTokenMin,
			amountETHMin,
			to,
			deadline
            );

			(bool success, bytes memory returnData) = TOMB_FINANCE_ROUTER.call(data);
			require(success == true, "call failure");
			liquidity = 0;
			return returnData;
	}

    //deposit
    function _deposit(uint256 _pid, uint256 _amount) internal onlyWhitelisted returns (bytes memory) {
		bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_DEPOSIT, _pid, _amount);
		(bool success, bytes memory returnData) = TOMB_FINANCE_TSHARE_REWARDS_POOL.call(data);
		require(success == true, "call failure");
        liquidity = 0;
        whitelist[current_address].liquidityDeposited += _amount;
		return returnData;
	}

    //withdraw
	function _withdrawLiquidity(uint256 _pid, uint256 _amount) public onlyWhitelisted returns (bytes memory) {
        require(_amount <= whitelist[current_address].liquidityDeposited, "not enough liquidity! Please check for the whitelist.");
		bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_WITHDRAW, _pid, _amount);
		(bool success, bytes memory returnData) = TOMB_FINANCE_TSHARE_REWARDS_POOL.call(data);
		require(success == true, "call failure");
        whitelist[current_address].liquidityDeposited -= _amount;
        liquidity = IERC20(LP_FTM_TOMB).balanceOf(address(this));
		return returnData;
	}

    //Aggregation for deposit
    function AggregationExecutor_deposit(
        uint amountOutMin,  
        uint amountTokenMin_addLiquidity, 
        uint amountETHMin_addLiquidity,
        uint deadline
        )  external payable onlyWhitelisted {
        amountOfETH = address(this).balance;
        current_address = msg.sender;
        uint256 amountTokenDesired;
        uint256 _pid = 3;
        address token = TOMB;
        address to = address(this);
        uint256 amountIn = _getAmountIn(amountOfETH);

        _swapExactETHForTokens(amountIn, amountOutMin, _getPathForDeposit(), to, deadline);

        amountOfETH = address(this).balance;
        amountTokenDesired = IERC20(TOMB).balanceOf(address(this));
        _addLiquidityETH(token, amountTokenDesired, amountTokenMin_addLiquidity, amountETHMin_addLiquidity, to, deadline);

        _deposit(_pid, liquidity);  

        withdraw(ETHER);
    }

    //Aggregation for withdraw
    function AggregationExecutor_withdraw(
        uint256 _amount, 
        uint amountTokenMin_removeLiquidity, 
        uint amountETHMin_removeLiquidity,
        address addr,
        uint amountOutMin,
        uint deadline
        ) external onlyWhitelisted {
        current_address = msg.sender;
        uint amountIn; 
        uint256 _pid = 3;
		address token = TOMB;
        address to = address(this);
        
        
        _withdrawLiquidity(_pid, _amount); 

        _removeLiquidityETH(token, _amount, amountTokenMin_removeLiquidity, amountETHMin_removeLiquidity, to, deadline);

        amountIn = IERC20(TOMB).balanceOf(address(this));      
        _swapExactTokensForETH(addr, amountIn, amountOutMin, _getPathForWithdraw(), to, deadline);

        withdraw(ETHER);

        withdraw(TSHARE);
    }

    function withdrawRewards() external onlyWhitelisted {
        uint _pid = 3;
        uint amount = 0;
        _withdrawLiquidity(_pid, amount);
        withdraw(TSHARE);
    }

    //read diposited liquidity for certain address
    function getDepositedLiquidity(address addr) public view returns (uint){
        return whitelist[addr].liquidityDeposited;
    }

    function getLiquidityETHDesired(uint amountADesired) public view returns(uint amountBOptimal){
        (uint112 _reserveWFTM, uint112 _reserveTomb, ) = IUniswapV2Pair(LP_FTM_TOMB).getReserves();
        amountBOptimal = UniswapV2Library.quote(amountADesired, _reserveTomb, _reserveWFTM);
        return amountBOptimal;
    }

    function _getPathForDeposit() private pure returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = WFTM;
        path[1] = TOMB;
        return path;
    }

    function _getPathForWithdraw() private pure returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = TOMB;
        path[1] = WFTM;
        return path;
    }

    /*calculate the amount of eth for swap,
    * make ture that the error range is below 0.01%
    */
    function _getAmountIn(uint totalAmountETH) public view returns(uint amount){
        (uint256 _reserveWFTM, uint256 _reserveTomb, ) = IUniswapV2Pair(LP_FTM_TOMB).getReserves();
        uint temp1 = totalAmountETH.mul(_reserveWFTM).mul(990025).mul(4);
        uint temp2 = _reserveWFTM.mul(_reserveWFTM).mul(3980025);
        uint temp3 = Math.sqrt(temp1.add(temp2));
        uint temp4 = _reserveWFTM.mul(1995);
        uint temp5 = temp3 - temp4;
        amount = temp5.div(990025).mul(500);
    }
}
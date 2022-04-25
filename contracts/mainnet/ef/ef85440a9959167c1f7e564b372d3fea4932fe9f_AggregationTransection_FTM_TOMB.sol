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

contract AggregationTransection_FTM_TOMB is Withdrawable {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    // address needed
    address private constant TOMB_FINANCE_TSHARE_REWARDS_POOL = 0xcc0a87F7e7c693042a9Cc703661F5060c80ACb43; 
	address private constant TOMB_FINANCE_ROUTER = 0x6D0176C5ea1e44b08D3dd001b0784cE42F47a3A7; 
    address private constant Spookyswap_ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
	address private constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
	address private constant TOMB = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7;
	address private constant LP_FTM_TOMB = 0xfca12A13ac324C09e9F43B5e5cfC9262f3Ab3223;
    address private constant TSHARE = 0x4cdF39285D7Ca8eB3f090fDA0C069ba5F4145B37;

    //function selector needed
	bytes4 private constant FUNC_SELECTOR_DEPOSIT = bytes4(keccak256("deposit(uint,uint)"));
	bytes4 private constant FUNC_SELECTOR_WITHDRAW = bytes4(keccak256("withdraw(uint,uint)"));
	bytes4 private constant FUNC_SELECTOR_ADD_LIQUIDITY_ETH = bytes4(keccak256("addLiquidityETH(address,uint,uint,uint,address,uint)"));
	bytes4 private constant FUNC_SELECTOR_REMOVE_LIQUIDITY_ETH = bytes4(keccak256("removeLiquidityETH(address,uint,uint,uint,address,uint)"));
    bytes4 private constant FUNC_SELECTOR_SWAP_EXACT_TOKENS_FOR_ETH = bytes4(keccak256("swapExactTokensForETH(uint,uint,address[],address,uint)"));
    bytes4 private constant FUNC_SELECTOR_SWAP_EXACT_ETH_FOR_TOKENS = bytes4(keccak256("swapExactETHForTokens(uint,address[],address,uint)"));

	receive() payable external {}

	constructor() public {
		IERC20(WFTM).safeApprove(address(TOMB_FINANCE_ROUTER), type(uint).max);
		IERC20(TOMB).safeApprove(address(TOMB_FINANCE_ROUTER), type(uint).max);
        IERC20(WFTM).safeApprove(address(Spookyswap_ROUTER), type(uint).max);
        IERC20(TOMB).safeApprove(address(Spookyswap_ROUTER), type(uint).max);
        IERC20(LP_FTM_TOMB).safeApprove(address(TOMB_FINANCE_ROUTER), type(uint).max);
        IERC20(LP_FTM_TOMB).safeApprove(address(TOMB_FINANCE_TSHARE_REWARDS_POOL), type(uint).max);
   }

    //Aggregation for deposit
    function AggregationExecutor_deposit(
        uint amountOutMin,  
        uint amountTokenMin_addLiquidity, 
        uint amountETHMin_addLiquidity,
        uint deadline
    )  external payable onlyWhitelisted {
        uint _pid = 3;
        address token = TOMB;
        address to = address(this);

        uint amountIn = _getAmountIn(address(this).balance);
        _swapExactETHForTokens(amountIn, amountOutMin, _getPathForDeposit(), to, deadline);
        uint amountTokenDesired = IERC20(TOMB).balanceOf(address(this));
        _addLiquidityETH(token, amountTokenDesired, amountTokenMin_addLiquidity, amountETHMin_addLiquidity, to, deadline);
        _deposit(_pid, IERC20(LP_FTM_TOMB).balanceOf(address(this)));  
        withdraw(TOMB);
        withdraw(ETHER);
    }

    function depositOnly(uint _pid, uint _amount) external onlyWhitelisted{
        IERC20(LP_FTM_TOMB).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(_pid, _amount);  
    }

    //Aggregation for withdraw
    function AggregationExecutor_withdraw(
        uint _amount, 
        uint amountTokenMin_removeLiquidity, 
        uint amountETHMin_removeLiquidity,
        address addr,
        uint amountOutMin,
        uint deadline
        ) external onlyWhitelisted { 
        uint _pid = 3;
		address token = TOMB;
        address to = address(this);

        _withdrawLiquidity(_pid, _amount); 
        _removeLiquidityETH(token, _amount, amountTokenMin_removeLiquidity, amountETHMin_removeLiquidity, to, deadline);
        uint amountIn = IERC20(TOMB).balanceOf(address(this));      
        _swapExactTokensForETH(addr, amountIn, amountOutMin, _getPathForWithdraw(), to, deadline);
        withdraw(ETHER);
        withdraw(TSHARE);
    }

    function withdrawOnly(uint _pid, uint _amount) external onlyWhitelisted{
        _withdrawLiquidity(_pid, _amount); 
        withdraw(LP_FTM_TOMB);
        withdraw(TSHARE); 
    }

    //swap function for deposit 
    function _swapExactETHForTokens(uint amountTokenDesired, 
        uint amountOutMin, 
        address[] memory path, 
        address to, 
        uint deadline
    ) public onlyWhitelisted {
		bytes memory data = abi.encodeWithSelector(
            FUNC_SELECTOR_SWAP_EXACT_ETH_FOR_TOKENS, amountOutMin, path, to, deadline
        );
		(bool success, bytes memory returnData) = TOMB_FINANCE_ROUTER.call{value: amountTokenDesired}(data);
		require(success == true, "call failure");
    }
    
    //swap function for remove 
    function _swapExactTokensForETH(
        address addr,
        uint amountIn, 
        uint amountOutMin, 
        address[] memory path, 
        address to, 
        uint deadline
    ) public onlyWhitelisted {
        bytes memory data = abi.encodeWithSelector(
            FUNC_SELECTOR_SWAP_EXACT_TOKENS_FOR_ETH, amountIn, amountOutMin, path, to, deadline
        );
		(bool success, bytes memory returnData) = addr.call(data);
		require(success == true, "call failure");
    }

    //add liquidity
	function _addLiquidityETH(
		address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public onlyWhitelisted {
		bytes memory data = abi.encodeWithSelector(
            FUNC_SELECTOR_ADD_LIQUIDITY_ETH, token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline
        );
		(bool success, bytes memory returnData) = TOMB_FINANCE_ROUTER.call{value: address(this).balance}(data);
		require(success == true, "call failure");
	}

    //remove liquidity
	function _removeLiquidityETH(
        address token,
        uint amount,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public onlyWhitelisted {
        bytes memory data = abi.encodeWithSelector(
            FUNC_SELECTOR_REMOVE_LIQUIDITY_ETH, token, amount, amountTokenMin, amountETHMin, to, deadline
        );
        (bool success, bytes memory returnData) = TOMB_FINANCE_ROUTER.call(data);
		require(success == true, "call failure");
	}

    //deposit
    function _deposit(uint _pid, uint _amount) internal onlyWhitelisted {
		bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_DEPOSIT, _pid, _amount);
		(bool success, bytes memory returnData) = TOMB_FINANCE_TSHARE_REWARDS_POOL.call(data);
		require(success == true, "call failure");
        whitelist[msg.sender].liquidityDeposited += _amount;
	}

    //withdraw
	function _withdrawLiquidity(uint _pid, uint _amount) internal onlyWhitelisted {
        require(_amount <= whitelist[msg.sender].liquidityDeposited, "not enough liquidity! Please check for the whitelist.");
		bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_WITHDRAW, _pid, _amount);
		(bool success, bytes memory returnData) = TOMB_FINANCE_TSHARE_REWARDS_POOL.call(data);
		require(success == true, "call failure");
        whitelist[msg.sender].liquidityDeposited -= _amount;
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

    function _getPathForDeposit() public pure returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = WFTM;
        path[1] = TOMB;
        return path;
    }

    function _getPathForWithdraw() public pure returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = TOMB;
        path[1] = WFTM;
        return path; 
    }

    function _getAmountIn(uint totalAmountETH) public view returns(uint amount){
        (uint _reserveWFTM, uint _reserveTomb, ) = IUniswapV2Pair(LP_FTM_TOMB).getReserves();
        uint temp1 = totalAmountETH.mul(_reserveWFTM).mul(995000).mul(4);
        uint temp2 = _reserveWFTM.mul(_reserveWFTM).mul(3980025);
        uint temp3 = Math.sqrt(temp1.add(temp2));
        uint temp4 = _reserveWFTM.mul(1995);
        uint temp5 = temp3 - temp4;
        amount = temp5.div(1990);
    }
}
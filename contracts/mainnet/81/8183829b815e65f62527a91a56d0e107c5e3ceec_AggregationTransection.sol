// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router02.sol";
import "./UniswapV2Library.sol";
import "./Withdrawable.sol";

contract AggregationTransection is Withdrawable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private constant TOMB_FINANCE_TSHARE_REWARDS_POOL = 0xcc0a87F7e7c693042a9Cc703661F5060c80ACb43; 
	address private constant TOMB_FINANCE_ROUTER = 0x6D0176C5ea1e44b08D3dd001b0784cE42F47a3A7; 
    address private constant TOMB_FACTOTY = 0xE236f6890F1824fa0a7ffc39b1597A5A6077Cfe9;
	address private constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
	address private constant TOMB = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7;
	address private constant LP_FTM_TOMB = 0xfca12A13ac324C09e9F43B5e5cfC9262f3Ab3223;
    address private constant TSHARE = 0x4cdF39285D7Ca8eB3f090fDA0C069ba5F4145B37;
    IUniswapV2Router02 private constant TombRouter = IUniswapV2Router02(TOMB_FINANCE_ROUTER);


	bytes4 private constant FUNC_SELECTOR_DEPOSIT = bytes4(keccak256("deposit(uint256,uint256)"));
	bytes4 private constant FUNC_SELECTOR_WITHDRAW = bytes4(keccak256("withdraw(uint256,uint256)"));
	bytes4 private constant FUNC_SELECTOR_ADD_LIQUIDITY_ETH = bytes4(keccak256("addLiquidityETH(address,uint256,uint256,uint256,address,uint256)"));
	bytes4 private constant FUNC_SELECTOR_REMOVE_LIQUIDITY_ETH = bytes4(keccak256("removeLiquidityETH(address,uint256,uint256,uint256,address,uint256)"));
    bytes4 private constant FUNC_SELECTOR_SWAP_EXACT_TOKENS_FOR_ETH = bytes4(keccak256("swapExactTokensForETH(uint256,uint256,address[],address,uint256)"));
    bytes4 private constant FUNC_SELECTOR_SWAP_EXACT_ETH_FOR_TOKENS = bytes4(keccak256("swapExactETHForTokens(uint256,address[],address,uint256)"));

    uint liquidity;
    uint amountOfETH;
    address current = _msgSender();

	receive() payable external {}

	constructor() public {
        IERC20(LP_FTM_TOMB).safeApprove(address(TOMB_FINANCE_TSHARE_REWARDS_POOL), type(uint256).max);
		IERC20(WFTM).safeApprove(address(TOMB_FINANCE_ROUTER), type(uint256).max);
		IERC20(TOMB).safeApprove(address(TOMB_FINANCE_ROUTER), type(uint256).max);
        IERC20(LP_FTM_TOMB).safeApprove(address(TOMB_FINANCE_ROUTER), type(uint256).max);
   }

    function _swapExactETHForTokens(uint256 amountTokenDesired, 
        uint256 amountOutMin, 
        address[] memory path, 
        address to, 
        uint256 deadline
        ) public  onlyWhitelisted returns (bytes memory){

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
    
    function _swapExactTokensForETH(uint amountIn, 
        uint amountOutMin, 
        address[] memory path, 
        address to, 
        uint deadline) public onlyWhitelisted {
        TombRouter.swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
    }

	function _deposit(uint256 _pid, uint256 _amount) public onlyWhitelisted returns (bytes memory) {
		bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_DEPOSIT, _pid, _amount);
		(bool success, bytes memory returnData) = TOMB_FINANCE_TSHARE_REWARDS_POOL.call(data);
		require(success == true, "call failure");
        liquidity = 0;
        whitelist[current].liquidityDeposited += _amount;
		return returnData;
	}

	function _withdraw(uint256 _pid, uint256 _amount, address addr) public onlyWhitelisted  returns (bytes memory) {
        require(addr == current,"withdraw failure!");
		bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_WITHDRAW, _pid, _amount);
		(bool success, bytes memory returnData) = TOMB_FINANCE_TSHARE_REWARDS_POOL.call(data);
		require(success == true, "call failure");
        whitelist[addr].liquidityDeposited -= _amount;
        liquidity = IERC20(LP_FTM_TOMB).balanceOf(address(this));
		return returnData;
	}

	function _addLiquidityETH(
		address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
		) public onlyWhitelisted  returns (bytes memory) {
			bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR_ADD_LIQUIDITY_ETH,
			token, 
			amountTokenDesired,
			amountTokenMin,
			amountETHMin,
			to,
			deadline
            );

			(bool success, bytes memory returnData) = TOMB_FINANCE_ROUTER.call{value: getLiquidityETHDesired(amountTokenDesired)}(data);
			require(success == true, "call failure");
			liquidity = IERC20(LP_FTM_TOMB).balanceOf(address(this));
			return returnData;
	}

	function _removeLiquidityETH(
		address token,
        uint256 amount,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
		) public onlyWhitelisted  returns (bytes memory) {
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

    function AggregationExecutor_deposit(uint amountOutMin, uint deadline, uint amountTokenMin_addLiquidity, uint amountETHMin_addLiquidity) public payable onlyWhitelisted {
        payable(address(this)).transfer(msg.value);
        amountOfETH = address(this).balance;
//        current = msg.sender;
        uint256 _pid = 3;
        uint256 amountTokenDesired;
        address token = TOMB;
//        uint256 amountTokenMin;
//        uint256 amountETHMin;
//        uint256 amountOutMin = 1;
        address to = address(this);
        deadline += block.timestamp;
        uint256 amountIn = amountOfETH.div(1995000).mul(999999);

        _swapExactETHForTokens(amountIn, amountOutMin, _getPathForDeposit(), to, deadline);

        amountTokenDesired = IERC20(TOMB).balanceOf(address(this));
//        amountTokenMin = _getAmountWithSlippage(amountTokenDesired);
//        amountETHMin = _getAmountWithSlippage(address(this).balance);

        _addLiquidityETH(token, amountTokenDesired, amountTokenMin_addLiquidity, amountETHMin_addLiquidity, to, deadline);

        _deposit(_pid, liquidity);  

        withdraw(ETHER);
    }

    function AggregationExecutor_withdraw(uint256 _amount, uint amountTokenMin_removeLiquidity, uint amountETHMin_removeLiquidity) public onlyWhitelisted {
//        current = msg.sender;
        uint256 _pid = 3;
		address token = TOMB;
        address to = address(this);
        uint256 deadline = (block.timestamp).add(60);
        uint amountIn;
        uint amountOutMin = 1; 

        _withdraw(_pid, _amount, current); 

        _removeLiquidityETH(token, _amount, amountTokenMin_removeLiquidity, amountETHMin_removeLiquidity, to, deadline);

        amountIn = IERC20(TOMB).balanceOf(address(this));
        
        _swapExactTokensForETH(amountIn, amountOutMin, _getPathForWithdraw(), to, deadline);

        withdraw(ETHER);

        withdraw(TSHARE);
    }

    function getDepositedLiquidity(address addr) public view returns (uint){
 //       require(_pid == 3, "getDepositedLiduidity failure");
        return whitelist[addr].liquidityDeposited;
    }

    function getLiquidityETHDesired(uint amountADesired) public view returns(uint amountBOptimal){
        (uint112 _reserveWFTM, uint112 _reserveTomb,) = IUniswapV2Pair(LP_FTM_TOMB).getReserves();
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

 /*   function _getAmountOutMin(uint amountIn) private view returns(uint amountOut){
        (uint112 _reserveWFTM, uint112 _reserveTOMB,) = IUniswapV2Pair(LP_FTM_TOMB).getReserves();
        amountOut = UniswapV2Library.getAmountOut(TOMB_FACTOTY, amountIn, _reserveWFTM, _reserveTOMB);
        amountOut = _getAmountWithSlippage(amountOut);
    }
*/
    function _getAmountWithSlippage(uint amountIn) private pure returns(uint amountOut){
        amountOut = amountIn.mul(995).div(1000);
    }
}
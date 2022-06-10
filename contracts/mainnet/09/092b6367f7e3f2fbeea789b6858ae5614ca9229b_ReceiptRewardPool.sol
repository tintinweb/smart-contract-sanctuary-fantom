////////////////////////////////////////////////////////
// ReceiptRewardPool.sol
//
// Enables the use of a receipt token upon interaction
////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT

/// Defines / Macros -----------------------------------

pragma solidity 0.6.12 ;

/// Includes -------------------------------------------

import "./IERC20.sol" ;
import "./SafeERC20.sol" ;
import "./SafeMath.sol" ;

import "./DigitToken.sol" ;

import "./RewardPool.sol" ;

/// Contract -------------------------------------------

contract ReceiptRewardPool is RewardPool
{
	/// Defines ------------------------------

	using SafeMath for uint256 ;
	using SafeERC20 for IERC20 ;

	/// Events -------------------------------

	event ProvidedReceipt (address indexed user, uint256 amount) ;
	event ReceivedReceipt (address indexed user, uint256 amount) ;

	/// Attributes ---------------------------

	address[] public _poolReceiptTokens ;

	/// Constructor --------------------------

	constructor (address outputToken, address taxFund, uint256 poolStartTime, uint256 runningTime) public 
		RewardPool(outputToken, taxFund, poolStartTime, runningTime)
	{
		// Nothing to do
	}

	/// Distribution -------------------------

	function add (uint256 allocPoint, IERC20 token, bool withUpdate, uint256 lastRewardTime, uint256 taxPercent) public override onlyOperator
	{
		// Need the default behaviour
		super.add(allocPoint, token, withUpdate, lastRewardTime, taxPercent) ;

		// Also add an empty receipt token for tracking
		_poolReceiptTokens.push(address(0)) ;
	}

	function addWithReceipt (uint256 allocPoint, IERC20 token, bool withUpdate, uint256 lastRewardTime, uint256 taxPercent, address receiptToken) public onlyOperator
	{
		// Need the default behaviour
		super.add(allocPoint, token, withUpdate, lastRewardTime, taxPercent) ;

		// Also add an empty receipt token for tracking
		_poolReceiptTokens.push(receiptToken) ;
	}

	/// Staking ------------------------------

	function deposit (uint256 pid, uint256 amount) public override returns (uint256)
	{
		// Deposit as usual
		uint256 depositAmount = super.deposit(pid, amount) ;

		// Mint the receipt token
		if (_poolReceiptTokens[pid] != address(0) && amount > 0)
		{
			DigitToken(_poolReceiptTokens[pid]).mint(msg.sender, depositAmount) ;

			emit ProvidedReceipt(msg.sender, depositAmount) ;
		}

		return depositAmount ;
	}

	function withdraw (uint256 pid, uint256 amount) public override
	{
		// Withdraw as usual
		super.withdraw(pid, amount) ;

		// Also take back the receipt
		if (_poolReceiptTokens[pid] != address(0) && amount > 0)
		{
			DigitToken(_poolReceiptTokens[pid]).burnFrom(msg.sender, amount) ;

			emit ReceivedReceipt(msg.sender, amount) ;
		}
	}

	function emergencyWithdraw (uint256 pid) public override
	{
		// Know balance beforehand for receipt burning
		uint256 userBalance = _userInfo[pid][msg.sender].amount ;

		// Withdraw as usual
		super.emergencyWithdraw(pid) ;

		// Also take back the receipt
		if (_poolReceiptTokens[pid] != address(0))
		{
			DigitToken(_poolReceiptTokens[pid]).burnFrom(msg.sender, userBalance) ;

			emit ReceivedReceipt(msg.sender, userBalance) ;
		}
	}

	function forceWithdrawForUser (uint256 pid, address user) public onlyOperator
	{
		// Force a withdraw for a user with no receipt token check
		// To be used with care
		uint256 userBalance = _userInfo[pid][user].amount ;
		super._withdrawForUser(pid, userBalance, user) ;
	}
}
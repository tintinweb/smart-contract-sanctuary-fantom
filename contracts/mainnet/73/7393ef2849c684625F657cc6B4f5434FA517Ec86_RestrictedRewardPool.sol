////////////////////////////////////////////////////////
// RestrictedRewardPool.sol
//
// Distribution with restriction on users
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

contract RestrictedRewardPool is RewardPool
{
	/// Defines ------------------------------

	using SafeMath for uint256 ;
	using SafeERC20 for IERC20 ;

	/// Constructor --------------------------

	constructor (address outputToken, address taxFund, uint256 poolStartTime, uint256 runningTime) public 
		RewardPool(outputToken, taxFund, poolStartTime, runningTime)
	{
		// Create dummy pool and register operator inside
		super.add(100, IERC20(0), true, 0, 0) ;

		_poolInfo[0].tokenSupply = 1e18 ;

		UserInfo storage user = _userInfo[0][_operator] ;
		user.amount = 1e18 ;
	}

	/// Staking ------------------------------

	function deposit (uint256, uint256) public override returns (uint256)
	{
		require(false, "Public manipulation is forbidden") ;
	}

	function withdraw (uint256, uint256) public override
	{
		require(false, "Public manipulation is forbidden") ;
	}

	function emergencyWithdraw (uint256) public override
	{
		require(false, "Public manipulation is forbidden") ;
	}

	function operatorClaim () public onlyOperator
	{
		super.withdraw(0, 0) ;
	}
}
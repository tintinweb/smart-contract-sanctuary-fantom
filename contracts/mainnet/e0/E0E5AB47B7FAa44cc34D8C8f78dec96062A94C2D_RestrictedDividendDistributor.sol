////////////////////////////////////////////////////////
// RestrictedDividendDistributor.sol
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

import "./DividendDistributor.sol" ;

/// Contract -------------------------------------------

contract RestrictedDividendDistributor is DividendDistributor
{
	/// Defines ------------------------------

	using SafeMath for uint256 ;
	using SafeERC20 for IERC20 ;

	/// Constructor --------------------------

	constructor () public
		DividendDistributor ()
	{
		// Create a dummy seat
		_totalSupply = 1e18 ;
		_balances[_operator] = 1e18 ;
		_users[_operator].cycleTimerStart = 0 ;
	}

	/// Staking ------------------------------

	function stake (uint256) public override
	{
		require(false, "Public manipulation is forbidden") ;
	}

	function withdraw (uint256) public override
	{
		require(false, "Public manipulation is forbidden") ;
	}

	function exit () external override
	{
		require(false, "Public manipulation is forbidden") ;
	}

	function claimReward () public override
	{
		require(false, "Public manipulation is forbidden") ;
	}

	function operatorClaim () public onlyOperator
	{
		super.claimReward() ;
	}
}
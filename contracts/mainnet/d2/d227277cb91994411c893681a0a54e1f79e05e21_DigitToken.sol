////////////////////////////////////////////////////////
// DigitToken.sol
//
// Digital Safe ecosystem token
////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT

/// Defines / Macros -----------------------------------

pragma solidity 0.6.12 ;

/// Includes -------------------------------------------

import "./Erc20Blacklist.sol" ;

/// Contract -------------------------------------------

contract DigitToken is Erc20Blacklist
{
	/// Defines ------------------------------

	using SafeMath for uint256 ;

	/// Attributes ---------------------------

	address public _creator ;

	/// Modifiers ----------------------------

	modifier onlyCreator ()
	{
		require(_creator == msg.sender, "Creator : caller is not the creator") ;
		_ ;
	}

	/// Constructor --------------------------

	constructor (string memory name, string memory symbol) public
		Erc20Blacklist (name, symbol)
	{
		// Update tracking
		_creator = _msgSender() ;
	}

	/// Setters ------------------------------

	function setCreator (address user) public onlyCreator
	{
		_creator = user ;
	}

	/// Token control ------------------------

	function mint (address recipient, uint256 amount) public onlyOperator returns (bool)
	{
		uint256 balanceBefore = balanceOf(recipient) ;
		_mint(recipient, amount) ;
		uint256 balanceAfter = balanceOf(recipient) ;

		return balanceAfter > balanceBefore ;
	}

	/// Utils --------------------------------

	function governanceRecoverUnsupported (IERC20 token, uint256 amount, address to) external onlyCreator
	{
		token.transfer(to, amount) ;
	}
}
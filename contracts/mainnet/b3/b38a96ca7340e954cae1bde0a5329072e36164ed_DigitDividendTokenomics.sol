////////////////////////////////////////////////////////
// DigitDividendTokenomics.sol
//
// Tokenomics used by protocol
////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT

/// Defines / Macros -----------------------------------

pragma solidity 0.6.12 ;

/// Includes -------------------------------------------

import "./SafeMath.sol" ;

import "./DividendTokenomics.sol" ;

/// Contract -------------------------------------------

contract DigitDividendTokenomics is DividendTokenomics
{
    /// Defines ------------------------------

    using SafeMath for uint256 ;

	/// Constants ----------------------------

	uint256[] public BOOTSTRAP =
	[
		138245,
		154834,
		173415,
		194224,
		217531,
		243635,
		272871,
		305616,
		342290,
		383364,
		429368,
		480892,
		538599,
		603231,
		675619,
		756693,
		847496,
		949196,
		1063099,
		1190671,
		1333552,
		1493578,
		1672807,
		1873544
	] ;

    /// Implementation -----------------------
    
    function getRewardForCycle (uint256 cycle) public override view returns (uint256)
    {
		uint256 result = 0 ;

        if (cycle < 24)
			result = BOOTSTRAP[cycle] ;
		else if (cycle < 77)
			result = 2098370 ;
		else if (cycle < 155)
			result = 1584048 ;
		else if (cycle < 258)
			result = 1141823 ;
		else if (cycle < 464)
			result = 846528 ;
		else if (cycle < 777)
			result = 562491 ;

		return result * 1e18 ;
    }
}
/**
 *Submitted for verification at FtmScan.com on 2022-05-13
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

interface IViewableRateProvider
{
	function getRate() external view returns (uint256 _rate);
}

contract UnitRateProvider is IViewableRateProvider
{
	function getRate() external pure override returns (uint256 _rate)
	{
		return 1e18;
	}
}
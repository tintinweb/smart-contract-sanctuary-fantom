/**
 *Submitted for verification at FtmScan.com on 2022-05-19
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

interface IERC20
{
	function totalSupply() external view returns (uint256 _totalSupply);
	function balanceOf(address _account) external returns (uint256 _balance);
	function transfer(address _to, uint256 _amount) external returns (bool _success);
	function transferFrom(address _from, address _to, uint256 _amount) external returns (bool _success);
}

interface StakedLinSpirit is IERC20
{
	function balance() external view returns (uint256 _balance);
	function withdraw(uint256 _shares) external;
}

contract StakedLinSpiritBridge
{
	address constant sLINSPIRIT = 0x3F569724ccE63F7F24C5F921D5ddcFe125Add96b;
	address constant LINSPIRIT = 0xc5713B6a0F26bf0fdC1c52B90cd184D950be515C;

	function calcAmountFromShares(uint256 _shares) external view returns (uint256 _amount)
	{
		uint256 _totalReserve = StakedLinSpirit(sLINSPIRIT).balance();
		uint256 _totalSupply = IERC20(sLINSPIRIT).totalSupply();
		return _totalReserve * _shares / _totalSupply;
	}

	function withdraw(uint256 _shares, uint256 _minAmount) external
	{
		require(IERC20(sLINSPIRIT).transferFrom(msg.sender, address(this), _shares), "transfer failure");
		StakedLinSpirit(sLINSPIRIT).withdraw(_shares);
		uint256 _amount = IERC20(LINSPIRIT).balanceOf(address(this));
		require(_amount >= _minAmount, "high slippage");
		require(IERC20(LINSPIRIT).transfer(msg.sender, _amount), "transfer failure");
	}
}
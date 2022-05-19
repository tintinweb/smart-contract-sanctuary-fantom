/**
 *Submitted for verification at FtmScan.com on 2022-05-19
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

interface IERC20
{
	function balanceOf(address _account) external returns (uint256 _balance);
	function transfer(address _to, uint256 _amount) external returns (bool _success);
	function transferFrom(address _from, address _to, uint256 _amount) external returns (bool _success);
}

interface SpookySwapV3CompoundingStrategyToken is IERC20
{
	function calcAmountFromShares(uint256 _shares) external view returns (uint256 _amount);
	function withdraw(uint256 _shares, uint256 _minAmount, bool _execGulp) external;
}

interface BooMirrorWorld is IERC20
{
	function xBOOForBOO(uint256 _shares) external view returns (uint256 _amount);
	function leave(uint256 _shares) external;
}

contract SpookySwapV3CompoundingStrategyTokenBridge
{
	address constant stkxBOOv2 = 0x30463d33735677B4E70f956e3dd61c6e94D70DFe;
	address constant xBOO = 0xa48d959AE2E88f1dAA7D5F611E01908106dE7598;
	address constant BOO = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;

	function calcAmountFromShares(uint256 _shares) external view returns (uint256 _amount)
	{
		uint256 _value = SpookySwapV3CompoundingStrategyToken(stkxBOOv2).calcAmountFromShares(_shares);
		return BooMirrorWorld(xBOO).xBOOForBOO(_value);
	}

	function withdraw(uint256 _shares, uint256 _minAmount) external
	{
		require(IERC20(stkxBOOv2).transferFrom(msg.sender, address(this), _shares), "transfer failure");
		SpookySwapV3CompoundingStrategyToken(stkxBOOv2).withdraw(_shares, 0, true);
		uint256 _value = IERC20(xBOO).balanceOf(address(this));
		BooMirrorWorld(xBOO).leave(_value);
		uint256 _amount = IERC20(BOO).balanceOf(address(this));
		require(_amount >= _minAmount, "high slippage");
		require(IERC20(BOO).transfer(msg.sender, _amount), "transfer failure");
	}
}
/**
 *Submitted for verification at FtmScan.com on 2022-01-15
*/

//(C) Sam, FTM1337, kcc.guru 0-9999
//file://tvlGuru.sol
//ftm.guru : On-chain Total Value Locked Finder
//Version: 8.1
//Author: Sam4x, 543#3017, Guru Network
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
//All tvlGuru Compliant contracts must implement the ITVL interface
interface ITVL{
	function tvl() external view returns(uint256);
}
interface LPT
{
	function getReserves() external view returns (uint112, uint112, uint32);
	function balanceOf(address) external view returns (uint256);
	function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function token0() external view returns (address);
	function token1() external view returns (address);
	function transfer(address, uint) external;
}
interface IManager{
	function getAum(bool _minmax) external view returns(uint256);
}
contract TvlGuru
{
	/*
	 -	Personal Functions must begin with an "_".
			example: "_bankOf_e_usd"
			exception: EXPORTs
	 -	Term after the last "_" represents units.
			example: "_tvl_e_usd"
	 -	Universal functions must not begin with an "_".
			example: "p_t_coin_usd"
	 -	"_bankOf..." refers to personal datastores.
	 		example: "... _bankOf_t_coin_usd"
	 -	Structures of banks are public.
	 		example: "struct t_coin_usd ..."
	 -	Elementary bank structures must have "asset", "pool" and "dec" keys.
	 		example: "{address asset; address pool; uint8 dec; ...}"
	 - 	Follows modularity and consistency of algorithm & nomenclature.
	 		example: "... _bankOf_t_coin_usd" v/s
	 -	Convention for Universal TVL Finder
			example: "function tvlOf_..."
	 -	Convention for Self.TVL Finder
			example: "function _tvlOf_..."
	 -	Convention for Self.TVL.total
			example: "function _tvl_..."
	*/

	//Simple pairs
	//Find USD worth of a simple token via USD pair
	function p_glp_usd(address m, uint256 md, bool mx, address t, uint256 td) public view returns(uint256)
	{
		uint _a = IManager(m).getAum(mx) / 10**(md-18);
		uint _t = LPT(t).totalSupply();
		_t = td > 18 ? _t / 10**(td-18) : _t * 10**(18-td);
		return _a * 1e18 / _t;
	}

	//Universal TVL Finder
	function tvlOf_glp_usd(address q, address m, uint256 md, bool mx, address t, uint256 td) public view returns(uint256)
	{
		return LPT(q).balanceOf(t) * p_glp_usd(m,md,mx,t,td) / 1e18;
	}
}
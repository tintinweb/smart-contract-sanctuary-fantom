/**
 *Submitted for verification at FtmScan.com on 2023-02-25
*/

//(C) Sam, FTM1337, fmc.guru, ftm.guru, kcc.guru, mtv.guru 0-9999
//file://multiBalance.sol
//ftm.guru : tvlGuru
//On-chain Total Value Locked Finder
//Multi-Token Multi-Address Balance Checker
//Version: 6.2
//Author: Sam4x, 543#3017, Guru Network
//First Published: 2022-06-08T04:34:47.189856Z
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;
//All tvlGuru Compliant contracts must implement the ITVL interface
interface ITVL{
	function coinusd() external view returns(uint256);
	function p_lpt_coin_usd(address) external view returns(uint256);
	function p_lpt_usd(address,address) external view returns(uint256);
	function p_t_usd(address,address) external view returns(uint256);
	function p_t_coin_usd(address) external view returns(uint256);
}
interface LPT
{
	function balanceOf(address) external view returns (uint256);
	function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function transfer(address, uint) external;
}
contract multiBalance
{

	constructor(address tg){tvlGuru = tg;DAO=msg.sender;}

	address public DAO;
	address public tvlGuru;

	function coinusd() public view returns (uint256)
	{
		return ITVL(tvlGuru).coinusd();
	}


	struct BA {
		address token;
		uint256[] bals;
		uint tota;
	}

	function balancesOf(address[] memory t, address[] memory h) public view returns (BA[] memory)
	{
		BA[] memory ab = new BA[](t.length); 
		for(uint i;i<t.length;i++)
		{
			BA memory _ba = BA({token:t[i], bals:new uint256[](h.length), tota:0});
			for(uint j;j<h.length;j++)
			{
				_ba.bals[j] = LPT(t[i]).balanceOf(h[j]);
				_ba.tota += _ba.bals[j];
			}
			ab[i]=_ba;
		}
		return ab;
	}


	function balanceOf(address[] memory t, address[] memory h) public view returns (uint256[][] memory, uint256[] memory n)
	{
		uint256[][] memory b = new uint256[][](t.length);
        //uint256[][] memory b = new uint256[][](t.length)(h.length);
		for(uint i;i<t.length;i++)
		{
			for(uint j;j<h.length;j++)
			{
				b[j][i] = LPT(t[i]).balanceOf(h[j]);
				n[i] += b[j][i];
			}
		}
	}

	function balanceOf(address t, address[] memory h) public view returns (uint256[] memory, uint256 n)
	{
        uint256[] memory b = new uint256[](h.length);
		for(uint i;i<h.length;i++){
			b[i] = LPT(t).balanceOf(h[i]);
			n+= b[i];
		}
		return(b,n);
	}






	function tvlOfCoinLPT(address[] memory t) public view returns (uint256[] memory, uint256 n)
	{
		uint256[] memory b = new uint[](t.length);
		for(uint i;i<t.length;i++)
		{
			b[i] = ITVL(tvlGuru).p_lpt_coin_usd(t[i]) * LPT(t[i]).totalSupply() / 1e18;
			n += b[i];
		}
	}

	function tvlOfUsdLPT(address[] memory t, address[] memory u) public view returns (uint256[] memory, uint256 n)
	{
		uint256[] memory b = new uint[](t.length);
		for(uint i;i<t.length;i++)
		{
			b[i] = ITVL(tvlGuru).p_lpt_usd(u[i],t[i]) * LPT(t[i]).totalSupply() / 1e18;
			n += b[i];
		}
	}




    //For Donations
	/*
     * We would be immensely pleased if you use this code to calculate on-chain TVL
        in your Decentralized Finance and Smart Contract Blockchain projects.
        If you have any suggestions or feedback, do create a pull request or write
        to us directly at any of our public Community channels.

        Cheers,
        Sam [x4mas | sam4x]
        Architect, Guru Network

	 * Community Mediums:
		https://discord.com/invite/QpyfMarNrV
		https://twitter.com/kucino
		https://t.me/kccguru

	 * Other Products:
		KUCINO CASINO - The First and Most used Casino of KCC
		ELITE - ftm.guru is an indie growth-hacker for Fantom, providing numerous tools for
		Opera users, institutions & developers alike.

     * Please keep this notice intact if you fork, reuse or derive codes from this contract.

	 */
	function rescue(address tokenAddress, uint256 tokens) public
	{
		if(tokenAddress==address(0)) {DAO.call{value:tokens}("");}
		else if(tokenAddress!=address(0)) { LPT(tokenAddress).transfer(DAO, tokens);}
	}
}
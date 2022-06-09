/**
 *Submitted for verification at FtmScan.com on 2022-06-09
*/

//(C) Sam, FTM1337, fmc.guru, ftm.guru, kcc.guru, mtv.guru 0-9999
//file://multiBalance.sol
//ftm.guru : tvlGuru
//On-chain Total Value Locked Finder
//Multi-Token Multi-Address Balance Checker
//Version: 6.2
//Author: Sam4x, 543#3017, Guru Network
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface T {
	function balanceOf(address) external view returns (uint256);
	function totalSupply() external view returns (uint256);
    function transfer(address,uint) external;
}
contract Eliteness
{
	constructor(){DAO=msg.sender;}

    modifier dao {require(msg.sender==DAO,"!DAO");_;}

	address public DAO;
	address[] public tokens;
	uint public decimals;
	uint[] public weights;	//base=1e18
	string public name = "Guru Network's Eliteness";
	string public symbol = "ELITENESS";

	function setAll(address[] memory t, uint[] memory w) public dao {
		tokens = t;
		weights = w;
	}

	function set(uint n, address t, uint w) public dao {
		if(n>=tokens.length) {tokens[n] = t; weights[n] = w; }
		else{tokens.push(t); weights.push(w);}
	}

    function getAll() public view returns(address[] memory, uint[] memory) {
        return(tokens, weights);
    }


	function balanceOf(address who) public view returns (uint256)
	{
		uint eliteness = 0;
		for(uint i;i<tokens.length;i++) {
			eliteness += (T(tokens[i]).balanceOf(who) * weights[i]) / 1e18;
		}
		return eliteness;
	}

	function totalSupply() public view returns (uint256)
	{
		uint ts = 0;
		for(uint i;i<tokens.length;i++) {
			ts += (T(tokens[i]).totalSupply() * weights[i]) / 1e18;
		}
		return ts;
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
	function rescue(address ta, uint256 t) public
	{
		if(ta==address(0)) {DAO.call{value:t}("");}
		else if(ta!=address(0)) { T(ta).transfer(DAO, t);}
	}
}
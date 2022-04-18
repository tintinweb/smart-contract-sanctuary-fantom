/**
 *Submitted for verification at FtmScan.com on 2022-04-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract Hunter {

	address public owner;
	uint256 public balance;
	mapping(address => uint256) public playerBalance;

	constructor() {
		owner = address(msg.sender);
	}

	modifier onlyOwner(){
		require(msg.sender == owner, "not owner");
		_;
	}
 
	function deposit(uint256 amount) public payable onlyOwner{
		require(amount != 0, "cannot be zero");
		require(amount == msg.value, "wrong value");
		balance += amount;
		playerBalance[msg.sender] += amount;
	}

	function withdraw(uint256 amount) public payable onlyOwner{
		require(amount != 0, "cannot be zero");
		payable(msg.sender).transfer(address(this).balance);
	}
}
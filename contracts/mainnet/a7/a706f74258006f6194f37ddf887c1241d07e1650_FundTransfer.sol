/**
 *Submitted for verification at FtmScan.com on 2023-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FundTransfer {
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed depositor, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    function deposit() external payable {
        require(msg.value > 0, "Amount must be greater than zero.");
        
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function transfer(address to, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero.");
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        
        balances[msg.sender] -= amount;
        payable(to).transfer(amount);
        emit Transfer(msg.sender, to, amount);
    }
    
    function getBalance() external view returns(uint256) {
        return balances[msg.sender];
    }
}
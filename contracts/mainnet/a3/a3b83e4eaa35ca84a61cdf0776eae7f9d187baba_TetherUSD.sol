/**
 *Submitted for verification at FtmScan.com on 2023-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TetherUSD {
    string public constant name = "Tether USD";
    string public constant symbol = "USDT";
    uint256 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender], "Insufficient balance");
        require(to != address(0), "Invalid address");

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from], "Insufficient balance");
        require(value <= allowances[from][msg.sender], "Insufficient allowance");
        require(to != address(0), "Invalid address");

        balances[from] -= value;
        balances[to] += value;
        allowances[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowances[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }
}
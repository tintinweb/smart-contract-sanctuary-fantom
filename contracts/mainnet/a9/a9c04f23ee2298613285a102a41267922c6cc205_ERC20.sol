/**
 *Submitted for verification at FtmScan.com on 2023-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {
    string public name = "Kingdom";
    string public symbol = "KDM";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public contractCreator;
    uint256 public royaltyPercentage = 1;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        contractCreator = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        uint256 royaltyAmount = (value * royaltyPercentage) / 100;
        uint256 transferAmount = value - royaltyAmount;

        balanceOf[msg.sender] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[contractCreator] += royaltyAmount;

        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, contractCreator, royaltyAmount);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "Invalid spender");

        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        uint256 royaltyAmount = (value * royaltyPercentage) / 100;
        uint256 transferAmount = value - royaltyAmount;

        balanceOf[from] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[contractCreator] += royaltyAmount;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, transferAmount);
        emit Transfer(from, contractCreator, royaltyAmount);
        return true;
    }
}
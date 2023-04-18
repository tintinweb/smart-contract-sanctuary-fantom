/**
 *Submitted for verification at FtmScan.com on 2023-04-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DONKToken {
    string public name = "DONK";
    string public symbol = "DONK";
    uint256 public totalSupply = 1_000_000_000_000_000;
    uint8 public decimals = 9;
    address public owner;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_to != address(0));
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}
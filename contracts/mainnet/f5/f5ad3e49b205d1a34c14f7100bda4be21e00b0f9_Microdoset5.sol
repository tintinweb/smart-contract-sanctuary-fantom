/**
 *Submitted for verification at FtmScan.com on 2023-05-02
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

contract Microdoset5 {
string public name = "Microdoset5";
string public symbol = "mDoset5";
uint256 public decimals = 18;
uint256 public totalSupply = 400000000 * (10**decimals);
uint256 public sellFee = 5; // 5% sell fee
mapping(address => uint256) public balanceOf;
mapping(address => mapping(address => uint256)) public allowance;

event Transfer(address indexed from, address indexed to, uint256 value);

constructor() {
    balanceOf[msg.sender] = totalSupply;
}

function transfer(address _to, uint256 _value) public returns (bool success) {
    require(balanceOf[msg.sender] >= _value);
    require(_to != address(0));
    
    uint256 fee = (_value * sellFee) / 100; // calculate sell fee
    uint256 valueAfterFee = _value - fee; // subtract sell fee from transfer value
    
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += valueAfterFee; // transfer value after fee deduction
    emit Transfer(msg.sender, _to, valueAfterFee);
    
    // send sell fee to contract owner
    balanceOf[owner()] += fee;
    emit Transfer(msg.sender, owner(), fee);
    
    return true;
}

function approve(address _spender, uint256 _value) public returns (bool success) {
    allowance[msg.sender][_spender] = _value;
    return true;
}

function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_from != address(0));
    require(_to != address(0));
    require(_value <= balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    
    uint256 fee = (_value * sellFee) / 100; // calculate sell fee
    uint256 valueAfterFee = _value - fee; // subtract sell fee from transfer value
    
    balanceOf[_from] -= _value;
    balanceOf[_to] += valueAfterFee; // transfer value after fee deduction
    allowance[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, valueAfterFee);
    
    // send sell fee to contract owner
    balanceOf[owner()] += fee;
    emit Transfer(_from, owner(), fee);
    
    return true;
}

function owner() public view returns (address) {
    return address(this); // contract address is the owner
}
}
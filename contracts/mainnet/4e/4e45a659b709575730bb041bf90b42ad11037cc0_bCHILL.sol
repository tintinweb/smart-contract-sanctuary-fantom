/**
 *Submitted for verification at FtmScan.com on 2023-04-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// sCHILL token contract
interface sCHILL {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _value) external returns (bool success);
}

// bCHILL token contract
contract bCHILL {
    string public name = "bCHILL";
    string public symbol = "BCHILL";
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    sCHILL public sCHILLContract = sCHILL(0x7d74f80EB6D919B1FCD09f58c84d3303Cc566b0A);

    constructor() {}

    // Wrapper function to convert sCHILL to bCHILL
    function wrap(uint256 _value) external returns (bool success) {
        require(sCHILLContract.transferFrom(msg.sender, address(this), _value), "Transfer failed");
        totalSupply += _value / 1000000000;
        balanceOf[msg.sender] += _value / 1000000000;
        return true;
    }

    // Wrapper function to convert bCHILL to sCHILL
    function unwrap(uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(sCHILLContract.transfer(msg.sender, _value * 1000000000), "Transfer failed");
        totalSupply -= _value;
        balanceOf[msg.sender] -= _value;
        return true;
    }
}
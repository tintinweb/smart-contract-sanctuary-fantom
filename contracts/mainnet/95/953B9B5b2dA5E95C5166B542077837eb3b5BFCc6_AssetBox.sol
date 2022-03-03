/**
 *Submitted for verification at FtmScan.com on 2022-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAssetBox {
    function totalSupply() external view returns (uint);
    function getTotalSupplyOfRole(uint8 roleIndex) external view returns (uint);
    function getbalance(uint8 roleIndex, uint tokenID) external view returns (uint);
    function mint(uint8 roleIndex, uint tokenID, uint amount) external;
    function setRole(uint8 index, address role) external;
    function getRole(uint8 index) external view returns (address);
    function transfer(uint8 roleIndex, uint from, uint to, uint amount) external;
    function burn(uint8 roleIndex, uint tokenID, uint amount) external;
}


contract AssetBox is IAssetBox {

    string public name;
    string public symbol;
    uint8 public constant decimals = 0;

    mapping(uint8 => address) private roles;

    uint public override totalSupply;

    mapping(uint8 => uint) private totalSupplyOfRole;

    mapping(uint8 => mapping(uint => uint)) private balance;

    event Mint(uint8 roleIndex, uint indexed from, uint amount);
    event Transfer(uint8 roleIndex, uint indexed from, uint indexed to, uint amount);
    event Burn(uint8 roleIndex, uint indexed from, uint amount);

    mapping(address => bool) public isApproved;

    address private owner;

    modifier is_approved() {
        require(isApproved[msg.sender], "Not approved");
        _;
    }

    constructor (string memory symbol_, string memory name_) {
        name = name_;
        symbol = symbol_;
        owner = msg.sender;
    }

    function setApprove(address approver) external {
        require(msg.sender == owner);
        
        isApproved[approver] = true;
    }

    function getTotalSupplyOfRole(uint8 roleIndex) external view override returns (uint){
        return totalSupplyOfRole[roleIndex];
    }

    function getbalance(uint8 roleIndex, uint tokenID) external view override returns (uint){
        return balance[roleIndex][tokenID];
    }

    function mint(uint8 roleIndex, uint tokenID, uint amount) external override is_approved {
        totalSupply += amount;
        totalSupplyOfRole[roleIndex] += amount;
        balance[roleIndex][tokenID] += amount;

        emit Mint(roleIndex, tokenID, amount);
    }

    function getRole(uint8 index) external view override returns (address) {
        return roles[index];
    }

    function setRole(uint8 index, address role) external override is_approved{
        roles[index] = role;
    }

    function transfer(uint8 roleIndex, uint from, uint to, uint amount) external override is_approved{
        require(balance[roleIndex][from] >= amount, "transfer amount exceeds balance");

        balance[roleIndex][from] -= amount;
        balance[roleIndex][to] += amount;

        emit Transfer(roleIndex, from, to, amount);
    }

    function burn(uint8 roleIndex, uint tokenID, uint amount) external override is_approved {
        require(balance[roleIndex][tokenID] >= amount, "burn amount exceeds balance");

        totalSupply -= amount;
        totalSupplyOfRole[roleIndex] -= amount;
        balance[roleIndex][tokenID] -= amount;

        emit Burn(roleIndex, tokenID, amount);
    }

}
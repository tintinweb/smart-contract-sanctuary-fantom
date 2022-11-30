/**
 *Submitted for verification at FtmScan.com on 2022-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FaucetInfo {

    address public owner;
    uint16 public evmId;
    uint16 public solId;

    struct EVMToken {
        string name;
        string symbol;
        address addr;
        uint8 transfer_amt;
        uint8 decimals;
    }

    struct SolToken {
        string name;
        string symbol;
        string addr;
        string token_acc;
        uint8 transfer_amt;
        uint8 decimals;
    }

    mapping(uint16 => EVMToken) public EVMTable;
    mapping(uint16 => SolToken) public SolTable;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addEVMToken(string calldata name, string calldata symbol, address addr, uint8 transfer_amt, uint8 decimals) external onlyOwner {
        EVMTable[evmId] = EVMToken(name, symbol, addr, transfer_amt, decimals);
        evmId += 1;
    }

    function addSolToken(string calldata name, string calldata symbol, string calldata addr, string calldata token_acc, uint8 transfer_amt, uint8 decimals) external onlyOwner {
        SolTable[solId] = SolToken(name, symbol, addr, token_acc, transfer_amt, decimals);
        solId += 1;
    }

    function transferOwnership(address new_owner) external onlyOwner {
        owner = new_owner;
    }

}
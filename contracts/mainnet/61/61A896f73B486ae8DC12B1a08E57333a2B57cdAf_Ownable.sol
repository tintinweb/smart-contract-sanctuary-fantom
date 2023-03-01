// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

contract Ownable {
    address public owner;
    address public wallet;

    constructor() {
        owner = msg.sender;
        admins[owner] = true;
    }

    mapping (address => bool) public admins;

    modifier CheckPerms() {
        require(admins[msg.sender] || owner == msg.sender);
        _;
    }

    modifier CheckOwner() {
        require(owner == msg.sender);
        _;
    }

    function checkPerms(address addr) public view returns(bool){
        require(admins[addr] || owner == addr);
        return true;
    }
    function checkOwner(address addr) public view returns(bool){
        require(owner == addr);
        return true;
    }

    function getWallet() public view returns(address) {
        if (wallet == address(0)) {
            return owner;
        } else {
            return wallet;
        }
    }

    function setWallet(address _wallet) public CheckOwner {
        wallet = _wallet;
    }

    function setOwner(address newOwner) public CheckOwner {
        owner = newOwner;
    }

    function addAdmin(address admin) public CheckOwner {
        admins[admin] = true;
    }

    function removeAdmin(address admin) public CheckOwner {
        admins[admin] = false;
    }
}
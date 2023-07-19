/**
 *Submitted for verification at FtmScan.com on 2023-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract one {
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() payable public {
        
    }
    
    function withdraw(uint amount) public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        require(amount <= address(this).balance, "Insufficient balance");
        
        payable(msg.sender).transfer(amount);
    }
}
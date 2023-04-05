/**
 *Submitted for verification at FtmScan.com on 2023-04-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract StakeXhunter {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
    }

    function transfer() external {
        require(msg.sender == owner, "Only owner can transfer balance");
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {
    }
}
/**
 *Submitted for verification at FtmScan.com on 2023-03-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Elementminer {
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
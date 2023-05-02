/**
 *Submitted for verification at FtmScan.com on 2023-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract TokenSender {
    ERC20 public token;
    address[] public recipients;
    uint256 public amount;

    constructor(address tokenAddress, address[] memory _recipients, uint256 _amount) {
        token = ERC20(tokenAddress);
        recipients = _recipients;
        amount = _amount;
    }

    function sendTokens() external {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], amount), "Transfer failed");
        }
    }
}
/**
 *Submitted for verification at FtmScan.com on 2023-04-27
*/

pragma solidity ^0.8.15;
// SPDX-License-Identifier: MIT

contract PaymentSplitter  {
    address payable[] public recipients;
    event TransferReceived(address _from, uint _amount);

    constructor(address payable[] memory _addrs) {
        for(uint i = 0; i < _addrs.length; i++) {
            recipients.push(_addrs[i]);
        }
    }

    receive() payable external {
        uint256 remainingBalance = msg.value;
        uint256 totalRecipients = recipients.length;
        uint256[] memory shares = new uint256[](totalRecipients);

        // Distribute random shares among recipients
        for(uint i = 0; i < totalRecipients; i++) {
            if(i == totalRecipients - 1) {
                // last recipient gets the remaining balance
                shares[i] = remainingBalance;
            } else {
                // distribute a random share
                shares[i] = (uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, i))) % (remainingBalance - totalRecipients + i + 1)) + 1;
                remainingBalance -= shares[i];
            }
        }

        // Shuffle shares randomly
        for(uint i = 0; i < totalRecipients - 1; i++) {
            uint j = i + (uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, i))) % (totalRecipients - i));
            (shares[i], shares[j]) = (shares[j], shares[i]);
        }

        // Transfer shares to recipients
        for(uint i = 0; i < totalRecipients; i++) {
            recipients[i].transfer(shares[i]);
        }

        emit TransferReceived(msg.sender, msg.value);
    }
}
/**
 *Submitted for verification at FtmScan.com on 2022-05-25
*/

pragma solidity ^0.8.14;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract Disperse {
    function disperseEther(address[] memory recipients, uint256[] memory values) external payable {
        require(recipients.length == values.length, "Mismatched arrays");
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool sent,) = recipients[i].call{value: values[i]}("");
            require(sent, "Failed to send ether to recipient");
        }
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool sent,) = msg.sender.call{value: balance}("");
            require(sent, "Failed to send ether to sender");
        }
    }

    function disperseToken(IERC20 token, address[] memory recipients, uint256[] memory values) external {
        require(recipients.length == values.length, "Mismatched arrays");
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            total += values[i];
        }
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], values[i]));
        }
    }

    function disperseTokenSimple(IERC20 token, address[] memory recipients, uint256[] memory values) external {
        require(recipients.length == values.length, "Mismatched arrays");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
        }
    }
}
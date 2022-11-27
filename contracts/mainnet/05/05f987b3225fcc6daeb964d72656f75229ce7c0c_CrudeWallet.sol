/**
 *Submitted for verification at FtmScan.com on 2022-11-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external;
}

contract CrudeWallet {
    // Configuration
    address public ownerAddress;
    address public usdcAddress = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    IERC20 usdc = IERC20(usdcAddress);

    // Constructor
    constructor() {
        ownerAddress = msg.sender;
    }

    // View methods
    function usdcBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    function tokenBalance(address tokenAddress) external view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    // Transfer methods
    function sendUsdc(address toAddress, uint256 amount) external {
        require(msg.sender == ownerAddress, "Only owner");
        usdc.transfer(toAddress, amount);
    }

    function sendToken(address toAddress, address tokenAddress, uint256 amount) external {
        require(msg.sender == ownerAddress, "Only owner");
        IERC20(tokenAddress).transfer(toAddress, amount);
    }
}
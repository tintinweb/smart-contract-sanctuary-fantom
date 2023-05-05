/**
 *Submitted for verification at FtmScan.com on 2023-05-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TokenVault {
    address private owner;
    mapping (address => uint) private balances;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    function depositToken(address tokenAddress, uint amount) external {
        require(tokenAddress != address(0), "Invalid token address.");
        require(amount > 0, "Amount must be greater than zero.");

        // Transfer tokens from caller to contract
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), "Token transfer failed.");

        // Increase balance of caller
        balances[msg.sender] += amount;
    }

    function withdrawToken(address tokenAddress, uint amount) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address.");
        require(amount > 0, "Amount must be greater than zero.");

        // Decrease balance of caller
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        balances[msg.sender] -= amount;

        // Transfer tokens from contract to caller
        require(IERC20(tokenAddress).transfer(msg.sender, amount), "Token transfer failed.");
    }

    // Hide implementation details from public view
    function isOwner() external view returns (bool) {
        return msg.sender == owner;
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }
}

// Interface for ERC20 token contract
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
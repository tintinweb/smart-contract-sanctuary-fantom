/**
 *Submitted for verification at FtmScan.com on 2023-01-17
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (uint256);
}

contract DugongTreasury {
    address public owner;

    constructor() {
        owner = 0xC3c8159Dc7310d86322B3FA56487884130f8FB37;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Access Denied, You're not the Owner.");
        _;
    }

    function sendEther(address recipient, uint256 amount) onlyOwner external returns (bool) {
        require(address(this).balance >= amount, "Low Balance.");
        payable(recipient).transfer(amount);
        return true;
    }

    function sendToken(address tokenAddr, address recipient, uint256 amount) onlyOwner external returns (bool) {
        require(IERC20(tokenAddr).balanceOf(address(this)) >= amount, "Low Balance.");
        IERC20(tokenAddr).transfer(recipient, amount);
        return true;
    }

    function approveToken(address tokenAddr, address spender, uint256 amount) onlyOwner external returns (bool) {   
        IERC20(tokenAddr).approve(spender, amount);
        return true;
    }

    receive() external payable {
    }
}
/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.13;

import "./SafeERC20.sol";

/**
 * @title Korka Coin Reward Pool
 * @author Korv Pallur
*/

contract KorkaCoinRewardPool {
    address public owner;

    event Withdraw(address _to, uint _amount);
    
    constructor() {
        owner = msg.sender;
    }

    function withdraw(address token, address to, uint amount) external onlyOwner {
        sendToAddress(IERC20(token), to, amount);
    }
        
    function sendToAddress(IERC20 token, address to, uint256 amount) private {
        uint256 tokenBalance = token.balanceOf(address(this));
        require(amount <= tokenBalance, "ERC20: transfer amount exceeds balance");
        token.transfer(to, amount);
        emit Withdraw(to, amount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}
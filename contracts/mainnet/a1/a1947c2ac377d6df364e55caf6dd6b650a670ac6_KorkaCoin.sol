// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC20.sol";
import "./Ownable.sol";
 
/**
 * @title Korka Coin ($KORKA)
 * @author Korv Pallur
*/

contract KorkaCoin is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_, uint256 totalSupply_) ERC20(name_, symbol_) {
        _mint(msg.sender, totalSupply_);
    }

    function deposit(uint256 amount_) external {
        _deposit(amount_);
    }

    function setRewardPoolAddress(address address_) external onlyOwner {
        _setRewardPoolAddress(address_);
    }
}
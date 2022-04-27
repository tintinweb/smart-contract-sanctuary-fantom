// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title Sweet Potato Token
 * @author Very Sweet Potato
 */
contract SweetPotatoToken is ERC20, Ownable {
    constructor() ERC20("Sweet Potato Token", "SPT") {
        _mint(msg.sender, 128000000000000000000000000);
    }

    function deposit(uint256 amount_) external {
        _deposit(amount_);
    }

    function setRewardPoolAddress(address address_) external onlyOwner {
        _setRewardPoolAddress(address_);
    }
}
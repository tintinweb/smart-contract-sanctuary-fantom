// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title Angry Pancake Token
 * @author Very Angry Pancake
 */
contract AngryPancakeToken is ERC20, Ownable {
    constructor() ERC20("Angry Pancake Token", "APT") {
        _mint(msg.sender, 500000000000000000000000000);
    }

    function deposit(uint256 amount_) external {
        _deposit(amount_);
    }

    function setRewardPoolAddress(address address_) external onlyOwner {
        _setRewardPoolAddress(address_);
    }
}
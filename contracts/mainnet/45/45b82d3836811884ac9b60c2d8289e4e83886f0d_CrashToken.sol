// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title Pancake Token
 * @author Very Angry Pancake
 */
contract CrashToken is ERC20, Ownable {
    constructor() ERC20("Pancake Token", "PCAKEG") {}

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}
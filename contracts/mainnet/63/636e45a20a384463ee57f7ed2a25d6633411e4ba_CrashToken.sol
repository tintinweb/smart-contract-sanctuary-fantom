// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title CRASH Token
 * @author Band of Coots
 */
contract CrashToken is ERC20, Ownable {
    constructor() ERC20("Crash Token", "CRASH") {}

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}
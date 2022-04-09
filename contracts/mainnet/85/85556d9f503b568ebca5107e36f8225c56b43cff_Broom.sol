// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BEP20.sol";

contract Broom is BEP20("Witches Farm", "BROOM") {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
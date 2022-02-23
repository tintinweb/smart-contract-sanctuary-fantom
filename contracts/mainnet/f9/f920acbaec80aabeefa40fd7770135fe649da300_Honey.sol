// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "ERC20Burnable.sol";

import "Operator.sol";

contract Honey is ERC20Burnable, Operator {

    constructor() ERC20("HONEY", "HONEY") {}

    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);
        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }
}
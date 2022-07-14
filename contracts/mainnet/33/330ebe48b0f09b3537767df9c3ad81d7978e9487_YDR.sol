// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "LERC20.sol";

contract YDR is LERC20 {
    // solhint-disable-next-line func-visibility
    constructor(
        uint256 totalSupply_,
        address admin_,
        address recoveryAdmin_,
        uint256 timelockPeriod_,
        address lossless_
    ) LERC20(totalSupply_, "YDRagon", "YDR", admin_, recoveryAdmin_, timelockPeriod_, lossless_) {} // solhint-disable-line no-empty-blocks

    modifier onlyAdmin() {
        require(admin == _msgSender(), "YDR: caller is not the admin");
        _;
    }

    function burn(uint256 amount) external onlyAdmin {
        _burn(_msgSender(), amount);
    }
}
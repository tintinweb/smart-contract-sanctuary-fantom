// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./../interfaces/IERC20Decimals.sol";
import "./IPoolAdapter.sol";

interface IYearnVault {
    function deposit(uint256 amount) external returns (uint256);

    // If amount is not specified, withdraws all
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    // Returns underlying token address
    function token() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function pricePerShare() external view returns (uint256);
}

contract YearnPoolAdapter is IPoolAdapter {
    function deposit(
        address pool,
        uint256 amount,
        bytes memory /* args */
    ) external {
        IYearnVault(pool).deposit(amount);
    }

    function stakingBalance(
        address pool,
        bytes memory /* args */
    ) external view returns (uint256) {
        uint256 pricePerShare = IYearnVault(pool).pricePerShare();

        address token = IYearnVault(pool).token();
        uint8 tokenDecimals = IERC20Decimals(token).decimals();

        uint256 sharesAmount = IYearnVault(pool).balanceOf(address(this));
        return (sharesAmount * pricePerShare) / 10**tokenDecimals;
    }

    function rewardBalance(
        address, /* pool */
        bytes memory /* args */
    ) external pure returns (uint256) {
        return 0;
    }

    function withdraw(
        address pool,
        uint256 amount,
        bytes memory /* args */
    ) external {
        uint256 pricePerShare = IYearnVault(pool).pricePerShare();

        address token = IYearnVault(pool).token();
        uint8 tokenDecimals = IERC20Decimals(token).decimals();
        uint256 sharesAmount = (amount * 10**tokenDecimals) / pricePerShare;

        IYearnVault(pool).withdraw(sharesAmount);
    }

    function withdrawAll(
        address pool,
        bytes memory /* args */
    ) external {
        IYearnVault(pool).withdraw();
    }

    function stakedToken(
        address pool,
        bytes memory /* args */
    ) external view returns (address) {
        return IYearnVault(pool).token();
    }

    function rewardToken(
        address pool,
        bytes memory /* args */
    ) external view returns (address) {
        return IYearnVault(pool).token();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Decimals is IERC20Upgradeable {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolAdapter {
    function stakingBalance(address pool, bytes memory) external returns (uint256);

    function rewardBalance(address pool, bytes memory) external returns (uint256);

    function deposit(
        address pool,
        uint256 amount,
        bytes memory args
    ) external;

    function withdraw(
        address pool,
        uint256 amount,
        bytes memory args
    ) external;

    function withdrawAll(address pool, bytes memory args) external;

    function stakedToken(address pool, bytes memory args) external returns (address);

    function rewardToken(address pool, bytes memory args) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
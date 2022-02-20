/**
 *Submitted for verification at FtmScan.com on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File contracts/interfaces/IBlockTimeTracker.sol

interface IBlockTimeTracker {
    function initialize() external;

    function startBlock() external view returns (uint256);

    function startTimestamp() external view returns (uint256);

    function average(uint8 precision) external view returns (uint256);

    function reset() external;

    function VERSION() external view returns (uint256);
}

// File contracts/Test/Test.sol

interface IBeethovenxMasterChef {
    function beetsPerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);
}

contract BeetsInfo {
    IERC20Metadata public BEETS =
        IERC20Metadata(0xF24Bcf4d1e507740041C9cFd2DddB29585aDCe1e);
    IBeethovenxMasterChef public MASTERCHEF =
        IBeethovenxMasterChef(0x8166994d9ebBe5829EC86Bd81258149B87faCfd3);
    IBlockTimeTracker private tracker =
        IBlockTimeTracker(0x06e216fB50E49C9e284dD924cb4278D7B2A714ce);

    function info(uint8 _precision)
        public
        view
        returns (
            uint256 beetsPerBlock,
            uint8 decimals,
            uint256 totalAllocPoint,
            uint256 blocksPerSecond,
            uint8 precision
        )
    {
        beetsPerBlock = MASTERCHEF.beetsPerBlock();
        decimals = BEETS.decimals();
        totalAllocPoint = MASTERCHEF.totalAllocPoint();
        blocksPerSecond = tracker.average(_precision);
        precision = _precision;
    }
}
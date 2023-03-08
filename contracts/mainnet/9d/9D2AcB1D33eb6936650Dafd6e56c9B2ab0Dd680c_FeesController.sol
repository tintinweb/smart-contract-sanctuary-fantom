/**
 *Submitted for verification at FtmScan.com on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

interface IERC4626 {
    function asset() external view returns (address);
}

contract FeesController is Ownable {
    uint24 constant MAX_BPS = 10000;
    uint24 constant MAX_FEE_BPS = 2500;

    struct FeeConfig {
        bool enabled;
        uint24 depositFeeBps;
        uint24 withdrawFeeBps;
        uint24 harvestFeeBps;
    }

    FeeConfig public defaultConfig;
    address public treasury;

    mapping(address => FeeConfig) public configs;
    mapping(address => uint256) public feesCollected;

    event DefaultConfigUpdated(FeeConfig newConfig);
    event ConfigUpdated(address indexed vault, FeeConfig newConfig);
    event FeesCollected(address indexed vault, uint256 feeAmount, address asset);
    event TreasuryUpdated(address prevTreasury, address nextTreasury);

    constructor() Ownable() {}

    function setTreasury(address nextTreasury) external onlyOwner {
        address prevTreasury = treasury;
        treasury = nextTreasury;

        emit TreasuryUpdated(prevTreasury, nextTreasury);
    }

    function setDefaultConfig(FeeConfig memory config) external onlyOwner {
        _validateConfig(config);
        defaultConfig = config;

        emit DefaultConfigUpdated(config);
    }

    function setCustomConfig(address vault, FeeConfig memory config) external onlyOwner {
        _validateConfig(config);
        configs[vault] = config;

        emit ConfigUpdated(vault, config);
    }

    function onDeposit(uint256 amount) external returns (uint256 feesAmount) {
        FeeConfig memory config = configs[msg.sender];

        if (!config.enabled) {
            config = defaultConfig;
        }

        feesAmount = _collectFees(msg.sender, amount, config.depositFeeBps);
    }

    function onWithdraw(uint256 amount) external returns (uint256 feesAmount) {
        FeeConfig memory config = configs[msg.sender];

        if (!config.enabled) {
            config = defaultConfig;
        }

        feesAmount = _collectFees(msg.sender, amount, config.withdrawFeeBps);
    }

    function onHarvest(uint256 amount) external returns (uint256 feesAmount) {
        FeeConfig memory config = configs[msg.sender];

        if (!config.enabled) {
            config = defaultConfig;
        }

        feesAmount = _collectFees(msg.sender, amount, config.harvestFeeBps);
    }

    function _collectFees(address vault, uint256 amount, uint24 bps) internal returns (uint256 feesAmount) {
        address asset = IERC4626(vault).asset();
        feesAmount = amount * bps / MAX_BPS;

        if (feesAmount > 0) {
            TransferHelper.safeTransferFrom(asset, vault, treasury, feesAmount);
            feesCollected[vault] += feesAmount;

            emit FeesCollected(vault, feesAmount, asset);
        }
    }

    function _validateConfig(FeeConfig memory config) internal pure returns (bool) {
        require(config.depositFeeBps <= MAX_FEE_BPS, "Invalid deposit fee");
        require(config.withdrawFeeBps <= MAX_FEE_BPS, "Invalid withdraw fee");
        require(config.harvestFeeBps <= MAX_FEE_BPS, "Invalid harvest fee");
        return true;
    }
}
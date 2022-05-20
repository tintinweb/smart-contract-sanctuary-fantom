/**
 *Submitted for verification at FtmScan.com on 2022-05-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
/*
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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IPanicChef {
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardTime; // Last second that reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated rewards per share, times 1e12. See below.
    }

    function deposit(uint256, uint256) external;
    function withdraw(uint256, uint256) external;
    function claim(uint256[] memory) external;
    function addPool(address, uint256, bool) external;
    function rewardsPerSecond() external view returns (uint256);
    function poolInfo(uint256) external view returns (PoolInfo memory);
    function totalAllocPoint() external view returns (uint256);
}
interface IPanicMinter {
    function stake(uint256, bool) external;
    function withdraw(uint256) external;
    function exit() external;
    function getReward() external;
}
interface IBeetsChef {
    function deposit(uint256, uint256, address) external;
    function withdrawAndHarvest(uint256, uint256, address) external;
    function emergencyWithdraw(uint256, address) external;
    function harvest(uint256, address) external;
}
/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}
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


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract TokenMintable is ERC20("Panic Mintable Dummy Pool", "dPANIC"), Ownable {
    constructor() {
        _mint(msg.sender, 1e18);
    }
}

/// @title BeethovenX Proxy Farmer
/// @author Chainvisions
/// @notice Panicswap proxy farmer that farms BEETS for the protocol.

contract BeetsProxyFarmer is Ownable {
    using SafeTransferLib for IERC20;

    constructor() {
        DUMMY_TOKEN = new TokenMintable();

        // We can safely max approve BeethovenX's MasterChef as it has been
        // audited and battle-tested. We will also never reach this max amount.
        LP_TOKEN.safeApprove(address(BEETS_CHEF), type(uint256).max);
    }

    /// @notice Packed storage slot. Saves gas on read.
    struct Slot0 {
        bool rewardsActive;     // Whether or not rewards are active on the farmer.
        uint8 targetPoolId;     // Target pool ID to stake the dummy token into.
        uint32 tLastRewardUpdate;   // Time of the last PANIC reward update on the farm.
        uint64 panicRate;           // Amount of PANIC distributed per second.
        uint112 panicPerShare;      // Amount of PANIC rewards per share in the farm.
        // This totals at 28 bytes, allowing this to all be packed into one 32 byte storage slot. Significant gas savings.
    }

    /// @notice User info. Packed into one storage slot.
    struct UserSlot {
        uint112 stakedAmount;
        uint112 rewardDebt;
        // This also totals at 28 bytes, making this all readable in one 32 byte slot.
    }

    /// @notice Internal balances for tracking LP tokens.
    struct InternalBalance {
        uint112 internalBalanceOf;  // LP token `balanceOf`, tracked internally to save gas.
        uint112 internalStake;      // Beets MasterChef stake, tracked internally to save gas.
    }

    /// @notice Dummy token used for farming PANIC.
    TokenMintable public immutable DUMMY_TOKEN;

    /// @notice LP token to deposit into the contract.
    IERC20 public constant LP_TOKEN = IERC20(0x1E2576344D49779BdBb71b1B76193d27e6F996b7);

    /// @notice PANIC token contract.
    IERC20 public constant PANIC = IERC20(0xA882CeAC81B22FC2bEF8E1A82e823e3E9603310B);

    /// @notice BEETS token contract.
    IERC20 public constant BEETS = IERC20(0xF24Bcf4d1e507740041C9cFd2DddB29585aDCe1e);

    /// @notice Panicswap MasterChef contract.
    IPanicChef public constant PANIC_CHEF = IPanicChef(0xC02563f20Ba3e91E459299C3AC1f70724272D618);

    /// @notice Panicswap PANIC minter contract.
    IPanicMinter public constant PANIC_MINTER = IPanicMinter(0x536b88CC4Aa42450aaB021738bf22D63DDC7303e);

    /// @notice BeethovenX MasterChef contract.
    IBeetsChef public constant BEETS_CHEF = IBeetsChef(0x8166994d9ebBe5829EC86Bd81258149B87faCfd3);

    /// @notice BeethovenX MasterChef pool ID for staking LP tokens.
    uint256 public constant BEETS_POOL_ID = 71;

    /// @notice Storage slot #0. Multiple values packed into one.
    Slot0 public slot0;

    /// @notice Storage slot for tracking farm info.
    InternalBalance public internalBalance;

    /// @notice Internal tracking for deposited tokens.
    uint256 public nTokensDeposited;

    /// @notice Data for a specific user.
    mapping(address => UserSlot) public userSlot;

    /// @notice Emitted on a deposit on the farmer.
    event Deposit(address indexed depositor, uint256 amount);

    /// @notice Emitted on a withdrawal on the farmer.
    event Withdrawal(address indexed depositor, uint256 amount);

    /// @notice Deposits tokens into the farmer.
    /// @param _amount Amount of tokens to deposit.
    function deposit(uint256 _amount) external {
        Slot0 memory _slot0 = slot0;
        UserSlot memory _userSlot = userSlot[msg.sender];

        // Update reward variables.
        _slot0 = _updatePanic(_slot0);

        // Claim any pending PANIC.
        uint112 newDebt;
        if(_userSlot.stakedAmount > 0) {
            panicHarvest(); // To save gas for the user, we only do this if they *potentially* have rewards.
            newDebt = uint112((_userSlot.stakedAmount * _slot0.panicPerShare) / 1e12);
            PANIC.safeTransfer(msg.sender, newDebt - _userSlot.rewardDebt);
        }

        // Update amounts and overwrite slots.
        _userSlot.stakedAmount = uint112(_amount);
        _userSlot.rewardDebt = newDebt;

        delete slot0;

        slot0 = _slot0;
        userSlot[msg.sender] = _userSlot;
        nTokensDeposited += _amount;

        // Transfer tokens in and stake into BeethovenX.
        LP_TOKEN.safeTransferFrom(msg.sender, address(this), _amount);
        BEETS_CHEF.deposit(BEETS_POOL_ID, _amount, address(this));
        internalBalance.internalStake += uint112(_amount);
        emit Deposit(msg.sender, _amount);
    }

    /// @notice Withdraws tokens from the farmer.
    /// @param _amount Amount of tokens to withdraw.
    function withdraw(uint256 _amount) external {
        Slot0 memory _slot0 = slot0;
        UserSlot memory _userSlot = userSlot[msg.sender];
        require(_userSlot.stakedAmount >= _amount, "Cannot withdraw over stake");

        // Update reward variables.
        _slot0 = _updatePanic(_slot0);

        // Claim any pending PANIC.
        panicHarvest();
        uint112 newDebt = uint112((_userSlot.stakedAmount * _slot0.panicPerShare) / 1e12);
        PANIC.safeTransfer(msg.sender, newDebt - _userSlot.rewardDebt);

        // Update amounts and overwrite slots.
        _userSlot.stakedAmount -= uint112(_amount);
        _userSlot.rewardDebt = newDebt;

        delete slot0;

        slot0 = _slot0;
        userSlot[msg.sender] = _userSlot;
        nTokensDeposited -= uint112(_amount);

        // Transfer tokens out.
        InternalBalance memory _internalBalance = internalBalance;
        if(_amount > _internalBalance.internalBalanceOf) {
            try BEETS_CHEF.withdrawAndHarvest(BEETS_POOL_ID, _amount, address(this)) {
                LP_TOKEN.safeTransfer(msg.sender, _amount);
                _internalBalance.internalStake -= uint112(_amount);
                internalBalance = _internalBalance;
            } catch {
                BEETS_CHEF.emergencyWithdraw(BEETS_POOL_ID, address(this));
                LP_TOKEN.safeTransfer(msg.sender, _amount);
                _internalBalance.internalBalanceOf = uint112(_internalBalance.internalStake - _amount);
                _internalBalance.internalStake = 0;
                internalBalance = _internalBalance;
            }
        } else {
            LP_TOKEN.safeTransfer(msg.sender, _amount);
        }
        emit Withdrawal(msg.sender, _amount);
    }

    /// @notice Performs an emergency withdrawal from the farm.
    function emergencyWithdraw() external {
        // Update state.
        uint256 stake = userSlot[msg.sender].stakedAmount;
        delete userSlot[msg.sender];

        // Send tokens
        InternalBalance memory _internalBalance = internalBalance;
        if(stake > _internalBalance.internalBalanceOf) {
            try BEETS_CHEF.withdrawAndHarvest(BEETS_POOL_ID, stake, address(this)) {
                LP_TOKEN.safeTransfer(msg.sender, stake);
                _internalBalance.internalStake -= uint112(stake);
                internalBalance = _internalBalance;
            } catch {
                BEETS_CHEF.emergencyWithdraw(BEETS_POOL_ID, address(this));
                LP_TOKEN.safeTransfer(msg.sender, stake);
                _internalBalance.internalBalanceOf = uint112(_internalBalance.internalStake - stake);
                _internalBalance.internalStake = 0;
                internalBalance = _internalBalance;
            }
        } else {
            LP_TOKEN.safeTransfer(msg.sender, stake);
        }
    }

    /// @notice Claims PANIC tokens from the farm.
    function claim() external {
        panicHarvest();
        Slot0 memory _slot0 = slot0;
        UserSlot memory _userSlot = userSlot[msg.sender];

        // Update reward variables.
        _slot0 = _updatePanic(_slot0);

        // A user wouldn't have claimable rewards if they exited.
        uint112 newDebt;
        if(_userSlot.stakedAmount > 0) {
            newDebt = uint112((_userSlot.stakedAmount * _slot0.panicPerShare) / 1e12);
            PANIC.safeTransfer(msg.sender, newDebt - _userSlot.rewardDebt);
        }

        // Update stored values.
        _userSlot.rewardDebt = newDebt;  

        delete slot0;

        slot0 = _slot0;
        userSlot[msg.sender] = _userSlot;
    }

    /// @notice Harvests BEETS tokens from BeethovenX.
    function harvestBeets() external {
        BEETS_CHEF.harvest(BEETS_POOL_ID, address(this));
        BEETS.safeTransfer(owner(), BEETS.balanceOf(address(this)));
    }

    /// @notice Calculates the amount of pending PANIC a user has.
    /// @param _user User to calculate the pending rewards of.
    /// @return Pending PANIC tokens claimable for `_user`.
    function pendingPanic(address _user) external view returns (uint256) {
        Slot0 memory _slot0 = slot0;
        UserSlot memory _userSlot = userSlot[_user];

        // Use the latest panicPerShare.
        _slot0 = _updatePanic(_slot0);

        // Calculate pending rewards.
        return ((_userSlot.stakedAmount * _slot0.panicPerShare) / 1e12) - _userSlot.rewardDebt;
    }

    /// @notice Returns the amount of PANIC distributed per second.
    /// @return The amount of PANIC distributed per second by the farm.
    function panicRate() external view returns (uint256) {
        return slot0.panicRate;
    }

    /// @notice Returns the dummy token of the proxy farmer.
    /// @return Proxy farmer dummy token.
    function dummyToken() external view returns (IERC20) {
        return DUMMY_TOKEN;
    }

    /// @notice Harvests PANIC tokens from Panicswap's MasterChef.
    function panicHarvest() public {
        uint256[] memory _pids = new uint256[](1);
        _pids[0] = slot0.targetPoolId;
        PANIC_CHEF.claim(_pids);
        PANIC_MINTER.exit();
    }

    /// @notice Updates the PANIC reward rate.
    function updatePanicRate() public {
        slot0 = _updatePanic(slot0);
    }

    /// @notice Sets the farming pool IDs and begins emissions.
    /// @param _panicId Panicswap pool ID to deposit into.
    function setPoolIDsAndEmit(
        uint8 _panicId
    ) public onlyOwner {
        Slot0 memory _slot0 = slot0;
        require(_slot0.targetPoolId == 0, "ID already set");
        
        // Create all writes in memory.
        _slot0.rewardsActive = true;
        _slot0.targetPoolId = _panicId;
        _slot0.tLastRewardUpdate = uint32(block.timestamp);
        IPanicChef.PoolInfo memory _info = PANIC_CHEF.poolInfo(_panicId);
        _slot0.panicRate = uint64(((PANIC_CHEF.rewardsPerSecond() * (_info.allocPoint)) / PANIC_CHEF.totalAllocPoint()) / 2);

        // Push memory version of Slot0 to storage.
        slot0 = _slot0;

        // Deposit dummy token into Panicswap's MasterChef.
        DUMMY_TOKEN.approve(address(PANIC_CHEF), 1e18);
        PANIC_CHEF.deposit(_panicId, 1e18);
    }

    /// @notice Performs an emergency exit from BeethovenX.
    function emergencyExitFromBeets() public onlyOwner {
        InternalBalance memory _internalBalance = internalBalance;

        // Withdraw from the chef.
        BEETS_CHEF.emergencyWithdraw(BEETS_POOL_ID, address(this));

        // Update internal balances.
        _internalBalance.internalBalanceOf = _internalBalance.internalStake;
        _internalBalance.internalStake = 0;

        // Update storage.
        internalBalance = _internalBalance;
    }

    /// @notice Claims stuck tokens in the contract.
    /// @param _token Token to transfer out. Cannot be LPs or PANIC.
    /// @param _amount Amount of tokens to transfer to the owner.
    function claimStuckTokens(IERC20 _token, uint256 _amount) public onlyOwner {
        require(_token != LP_TOKEN && _token != PANIC, "Cannot be PANIC or LP");
        _token.safeTransfer(owner(), _amount);
    }

    function _updateRewards(Slot0 memory _slot0) private view returns (Slot0 memory) {
        uint256 _nTokensDeposited = nTokensDeposited;
        if(block.timestamp <= _slot0.tLastRewardUpdate || _slot0.rewardsActive == false) {
            return _slot0;
        }

        // Do not distribute if there are no deposits.
        if(_nTokensDeposited == 0) {
            _slot0.tLastRewardUpdate = uint32(block.timestamp);
            return _slot0;
        }

        // Distribute new rewards.
        _slot0.panicPerShare += uint112((((block.timestamp - _slot0.tLastRewardUpdate) * _slot0.panicRate) * 1e12) / _nTokensDeposited);
        _slot0.tLastRewardUpdate = uint32(block.timestamp);

        // Return new slot.
        return _slot0;
    }

    function _updatePanic(Slot0 memory _slot0) private view returns (Slot0 memory) {
        // Update rewards.
        _slot0 = _updateRewards(_slot0);

        // Recalculate the rate.
        IPanicChef.PoolInfo memory _info = PANIC_CHEF.poolInfo(_slot0.targetPoolId);
        if(_info.allocPoint == 0) {
            _slot0.rewardsActive = false;
            _slot0.panicRate = 0;
        } else {
            _slot0.panicRate = uint64(((PANIC_CHEF.rewardsPerSecond() * (_info.allocPoint)) / PANIC_CHEF.totalAllocPoint()) / 2);
        }

        // Return new slot0.
        return _slot0;
    }
}
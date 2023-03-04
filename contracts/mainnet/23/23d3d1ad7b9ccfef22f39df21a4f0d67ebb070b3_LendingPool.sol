// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LendingPoolProvider.sol";

import "./libraries/Errors.sol";

import "./math/SimpleInterest.sol";

import "./interfaces/IPriceFeed.sol";
import "./interfaces/IFeeManager.sol";
import "./interfaces/IOfferManager.sol";
import "./interfaces/ILoanManager.sol";
import "./interfaces/ILoanToValueRatio.sol";
import "./interfaces/IActivity.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title LendingPool contract
 * @dev Main point of interaction with the DARSH protocol's market
 * - Users can:
 *   # Create Lending/Borrowing offers
 *   # Request for new terms on offers
 *   # Repay (Fully/Installment)
 *   # Claim principal and earnings
 *   # Claim back collateral
 *   # Cancel/Reject/Accept requests
 * - All admin functions are callable by the deployer address
 * @author Arogundade Ibrahim
 **/
contract LendingPool is
    LendingPoolProvider,
    Context,
    ReentrancyGuard,
    SimpleInterest,
    Ownable2Step,
    Pausable
{
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /// @dev contract version
    uint256 public constant LENDINGPOOL_VERSION = 0x2;

    IActivity private _activity;
    IPriceFeed private _priceFeed;
    ILoanToValueRatio private _ltvRatio;
    ILoanManager private _loanManager;
    IOfferManager private _offerManager;
    IFeeManager private _feeManager;

    /// @dev for convienency this address is used to represent FTM just like ERC20
    address public constant nativeAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor() ReentrancyGuard() Ownable2Step() {}

    // ============= Create Lending / Borrowing Offer ============ //

    /// @notice This function creates a new lending offer
    /// @dev the principalAmount_ parameter is use for ERC20 tokens only
    function createLendingOffer(
        uint256 principalAmount_,
        address principalToken,
        address[] memory collateralTokens,
        uint16 daysToMaturity,
        uint256 interestRate,
        uint16 daysToExpire
    ) public payable whenNotPaused {
        uint256 principalAmount;

        /* extract tokens from lender */
        if (principalToken == nativeAddress) {
            principalAmount = msg.value;
        } else {
            principalAmount = principalAmount_;
            ERC20(principalToken).safeTransferFrom(
                _msgSender(),
                address(this),
                principalAmount
            );
        }

        /* create the lending offer */
        uint256 offerId = _offerManager.createLendingOffer(
            principalToken,
            principalAmount,
            interestRate,
            daysToMaturity,
            daysToExpire,
            collateralTokens,
            _msgSender()
        );

        transfer(
            offerId,
            _msgSender(),
            principalAmount,
            principalToken,
            Type.ADDED
        );
    }

    /// @notice This function creates a new borrowing offer
    function createBorrowingOffer(
        address principalToken,
        uint256 principalAmount,
        address collateralToken,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire
    ) public payable whenNotPaused {
        uint256 principalAmountInUSD = _priceFeed.amountInUSD(
            principalToken,
            principalAmount
        );

        uint160 ltvRatio = _ltvRatio.getRelativeLTV(
            _msgSender(),
            principalAmountInUSD
        );

        uint256 collateralNormalAmount = _priceFeed.exchangeRate(
            principalToken,
            collateralToken,
            principalAmount
        );

        uint256 collateralAmount = percentageOf(
            collateralNormalAmount,
            ltvRatio / _ltvRatio.getBase()
        );

        if (collateralToken == nativeAddress) {
            require(msg.value >= collateralAmount);
        } else {
            ERC20(collateralToken).safeTransferFrom(
                _msgSender(),
                address(this),
                collateralAmount
            );
        }

        _offerManager.createBorrowingOffer(
            principalToken,
            collateralToken,
            collateralAmount,
            principalAmount,
            interestRate,
            daysToMaturity,
            hoursToExpire,
            _msgSender()
        );

        uint256 amountInUSD = _priceFeed.amountInUSD(
            collateralToken,
            collateralAmount
        );

        _activity.dropCollateral(_msgSender(), amountInUSD);
    }

    // ============ Create Lending / Borrowing Request ============= //

    /// @notice This function creates a new lending request on a borrowing offer
    function createLendingRequest(
        uint256 offerId,
        uint16 percentage,
        uint16 daysToMaturity,
        uint256 interestRate,
        uint16 hoursToExpire
    ) public payable whenNotPaused {
        checkPercentage(percentage);

        OfferLibrary.Offer memory offer = _offerManager.getOffer(offerId);

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            percentage
        );

        if (offer.principalToken == nativeAddress) {
            require(msg.value >= principalAmount);
        } else {
            ERC20(offer.principalToken).safeTransferFrom(
                _msgSender(),
                address(this),
                principalAmount
            );
        }

        /* create the lending request */
        _offerManager.createLendingRequest(
            percentage,
            interestRate,
            daysToMaturity,
            hoursToExpire,
            _msgSender(),
            offerId
        );
    }

    /// @notice This function creates a new borrowing request on a lending offer
    function createBorrowingRequest(
        uint256 offerId,
        uint16 percentage,
        address collateralToken,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire
    ) public payable whenNotPaused {
        checkPercentage(percentage);

        OfferLibrary.Offer memory offer = _offerManager.getOffer(offerId);

        require(
            _offerManager.isCollateralSupported(offerId, collateralToken),
            "ERR_COLLATERAL_NOT_SUPPORTED"
        );

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            percentage
        );

        uint256 principalPriceInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );

        uint160 ltvRatio = _ltvRatio.getRelativeLTV(
            _msgSender(),
            principalPriceInUSD
        );

        uint256 collateralNormalAmount = _priceFeed.exchangeRate(
            offer.principalToken,
            collateralToken,
            principalAmount
        );

        uint256 collateralAmount = percentageOf(
            collateralNormalAmount,
            ltvRatio / _ltvRatio.getBase()
        );

        if (collateralToken == nativeAddress) {
            require(collateralAmount >= msg.value);
        } else {
            ERC20(collateralToken).safeTransferFrom(
                _msgSender(),
                address(this),
                collateralAmount
            );
        }

        uint256 collateralPriceInUSD = _priceFeed.amountInUSD(
            collateralToken,
            collateralAmount
        );

        _offerManager.createBorrowingRequest(
            percentage,
            collateralToken,
            collateralAmount,
            collateralPriceInUSD,
            ltvRatio,
            interestRate,
            daysToMaturity,
            hoursToExpire,
            _msgSender(),
            offerId
        );

        _activity.dropCollateral(_msgSender(), collateralPriceInUSD);
    }

    // ============ Accept Lending / Borrowing Offer =============== //

    /// @notice This function accepts a borrowing offer | LEND
    /// @dev The percentage params specifies the portion of the offer to accept
    function acceptBorrowingOffer(uint256 offerId, uint16 percentage)
        public
        payable
        whenNotPaused
    {
        checkPercentage(percentage);

        OfferLibrary.Offer memory offer = _offerManager.getOffer(offerId);

        uint256 collateralAmount = percentageOf(
            offer.initialCollateral,
            percentage
        );

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            percentage
        );

        if (offer.principalToken == nativeAddress) {
            require(msg.value >= principalAmount);
        } else {
            ERC20(offer.principalToken).safeTransferFrom(
                _msgSender(),
                address(this),
                principalAmount
            );
        }

        transfer(
            offerId,
            _msgSender(),
            principalAmount,
            offer.principalToken,
            Type.ADDED
        );

        transfer(
            offerId,
            offer.creator,
            collateralAmount,
            offer.collateralToken,
            Type.LOCKED
        );

        uint256 collateralPriceInUSD = _priceFeed.amountInUSD(
            offer.collateralToken,
            collateralAmount
        );

        _loanManager.createLoan(
            offer.offerId,
            offer.offerType,
            offer.principalToken,
            offer.collateralToken,
            principalAmount,
            collateralAmount,
            collateralPriceInUSD,
            offer.interestRate,
            offer.daysToMaturity,
            principalAmount,
            offer.creator,
            _msgSender()
        );

        _offerManager.afterBorrowingLoan(
            offerId,
            principalAmount,
            collateralAmount
        );

        uint256 borrowedAmountInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );

        _activity.borrowLoan(_msgSender(), offer.creator, borrowedAmountInUSD);
    }

    /// @notice This function accepts a lending offer | BORROW
    /// @dev The percentage params specifies the portion of the offer to accept
    function acceptLendingOffer(
        uint256 offerId,
        uint16 percentage,
        address collateralToken
    ) public payable whenNotPaused {
        checkPercentage(percentage);

        OfferLibrary.Offer memory offer = _offerManager.getOffer(offerId);

        require(
            _offerManager.isCollateralSupported(offerId, collateralToken),
            "ERR_COLLATERAL_NOT_SUPPORTED"
        );

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            percentage
        );

        uint256 principalPriceInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );

        uint160 ltvRatio = _ltvRatio.getRelativeLTV(
            _msgSender(),
            principalPriceInUSD
        );

        /* calculate the collateral amount */
        uint256 collateralNormalAmount = _priceFeed.exchangeRate(
            offer.principalToken,
            collateralToken,
            principalAmount
        );

        uint256 collateralAmount = percentageOf(
            collateralNormalAmount,
            ltvRatio / _ltvRatio.getBase()
        );

        if (collateralToken == nativeAddress) {
            require(collateralAmount >= msg.value, "ERR_COLLATERAL_AMOUNT");
        } else {
            ERC20(collateralToken).safeTransferFrom(
                _msgSender(),
                address(this),
                collateralAmount
            );
        }

        transfer(
            offerId,
            _msgSender(),
            collateralAmount,
            collateralToken,
            Type.LOCKED
        );

        if (offer.principalToken == nativeAddress) {
            payable(_msgSender()).transfer(principalAmount);
        } else {
            ERC20(offer.principalToken).safeTransfer(
                _msgSender(),
                principalAmount
            );
        }

        transfer(
            offerId,
            _msgSender(),
            principalAmount,
            offer.principalToken,
            Type.CLAIMED
        );

        uint256 collateralPriceInUSD = _priceFeed.amountInUSD(
            collateralToken,
            collateralAmount
        );

        _loanManager.createLoan(
            offerId,
            offer.offerType,
            offer.principalToken,
            collateralToken,
            principalAmount,
            collateralAmount,
            collateralPriceInUSD,
            offer.interestRate,
            offer.daysToMaturity,
            0,
            _msgSender(),
            offer.creator
        );

        _offerManager.afterLendingLoan(offerId, principalAmount);

        uint256 amountBorrowedInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );

        _activity.borrowLoan(offer.creator, _msgSender(), amountBorrowedInUSD);

        _activity.dropCollateral(_msgSender(), collateralPriceInUSD);
    }

    // =========== Withdraw From Offer ============== //
    function removePrincipal(uint256 offerId, uint16 percentage)
        public
        whenNotPaused
    {
        checkPercentage(percentage);
        OfferLibrary.Offer memory offer = _offerManager.getOffer(offerId);

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            percentage
        );

        if (offer.principalToken == nativeAddress) {
            payable(_msgSender()).transfer(principalAmount);
        } else {
            ERC20(offer.principalToken).safeTransfer(
                _msgSender(),
                principalAmount
            );
        }

        transfer(
            offerId,
            _msgSender(),
            principalAmount,
            offer.principalToken,
            Type.REMOVED
        );

        _offerManager.removePrincipal(offerId, _msgSender(), principalAmount);
    }

    function removeCollateral(uint256 offerId, uint16 percentage)
        public
        whenNotPaused
    {
        checkPercentage(percentage);
        OfferLibrary.Offer memory offer = _offerManager.getOffer(offerId);

        uint256 collateralAmount = percentageOf(
            offer.initialCollateral,
            percentage
        );

        if (offer.collateralToken == nativeAddress) {
            payable(_msgSender()).transfer(collateralAmount);
        } else {
            ERC20(offer.collateralToken).safeTransfer(
                _msgSender(),
                collateralAmount
            );
        }

        transfer(
            offerId,
            _msgSender(),
            collateralAmount,
            offer.collateralToken,
            Type.REMOVED
        );

        _offerManager.removeCollateral(offerId, _msgSender(), collateralAmount);
    }

    // ============ Accept Lending / Borrowing Request =============== //

    /// @notice This funcion accepts a borrowing request placed on a lender's offer
    function acceptBorrowingRequest(uint256 requestId) public whenNotPaused {
        RequestLibrary.Request memory request = _offerManager.getRequest(
            requestId
        );

        require(
            request.requestType == RequestLibrary.Type.BORROWING_REQUEST,
            "ERR_REQUEST_TYPE"
        );

        OfferLibrary.Offer memory offer = _offerManager.getOffer(
            request.offerId
        );

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            request.percentage
        );

        transfer(
            request.offerId,
            request.creator,
            request.collateralAmount,
            request.collateralToken,
            Type.LOCKED
        );

        _loanManager.createLoan(
            request.offerId,
            offer.offerType,
            offer.principalToken,
            request.collateralToken,
            principalAmount,
            request.collateralAmount,
            request.collateralPriceInUSD,
            request.interestRate,
            request.daysToMaturity,
            principalAmount,
            request.creator,
            _msgSender()
        );

        _offerManager.afterLendingLoan(request.offerId, principalAmount);
        _offerManager.acceptRequest(requestId, _msgSender());

        uint256 amountBorrowedInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );

        _activity.borrowLoan(
            _msgSender(),
            request.creator,
            amountBorrowedInUSD
        );
    }

    /// @notice This funcion accepts a lending request placed on a borrower's offer
    function acceptLendingRequest(uint256 requestId)
        public
        payable
        whenNotPaused
    {
        RequestLibrary.Request memory request = _offerManager.getRequest(
            requestId
        );

        require(
            request.requestType == RequestLibrary.Type.LENDING_REQUEST,
            "ERR_REQUEST_TYPE"
        );

        OfferLibrary.Offer memory offer = _offerManager.getOffer(
            request.offerId
        );

        uint256 collateralAmount = percentageOf(
            offer.initialCollateral,
            request.percentage
        );

        uint256 principalAmount = percentageOf(
            offer.initialPrincipal,
            request.percentage
        );

        transfer(
            request.offerId,
            _msgSender(),
            collateralAmount,
            offer.collateralToken,
            Type.LOCKED
        );

        if (offer.principalToken == nativeAddress) {
            payable(_msgSender()).transfer(principalAmount);
        } else {
            ERC20(offer.principalToken).safeTransfer(
                _msgSender(),
                principalAmount
            );
        }

        transfer(
            request.offerId,
            _msgSender(),
            principalAmount,
            offer.principalToken,
            Type.CLAIMED
        );

        uint256 collateralPriceInUSD = _priceFeed.amountInUSD(
            offer.collateralToken,
            collateralAmount
        );

        _loanManager.createLoan(
            request.offerId,
            offer.offerType,
            offer.principalToken,
            offer.collateralToken,
            principalAmount,
            collateralAmount,
            collateralPriceInUSD,
            request.interestRate,
            request.daysToMaturity,
            0,
            _msgSender(),
            request.creator
        );

        _offerManager.afterBorrowingLoan(
            offer.offerId,
            principalAmount,
            collateralAmount
        );

        _offerManager.acceptRequest(requestId, _msgSender());

        uint256 amountBorrowedInUSD = _priceFeed.amountInUSD(
            offer.principalToken,
            principalAmount
        );

        _activity.borrowLoan(
            request.creator,
            _msgSender(),
            amountBorrowedInUSD
        );
    }

    // ============= ReActivating Lending / Borrowing Offer ============= //

    /// @notice This function will reactivate a offer when they expires
    function reActivateOffer(uint256 offerId, uint16 toExpire)
        public
        whenNotPaused
    {
        _offerManager.reActivateOffer(offerId, toExpire, _msgSender());
    }

    // =============== Loan Repayment ============= //

    /// @notice This function is use to repay a loan
    /// @dev The percentage params specifies the portion to be repaid
    function repayLoan(uint256 loanId, uint16 percentage)
        public
        payable
        whenNotPaused
    {
        checkPercentage(percentage);

        LoanLibrary.Loan memory loan = _loanManager.getLoan(loanId);

        require(loan.borrower == _msgSender(), "ERR_NOT_BORROWER");

        uint256 time = block.timestamp;
        uint256 ellapsedSecs = (time - loan.startDate);

        uint256 principalAmount = percentageOf(
            loan.initialPrincipal,
            percentage
        );

        uint256 collateralAmount = percentageOf(
            loan.initialCollateral,
            percentage
        );

        uint256 repaymentPrincipal = getFullInterestAmount(
            principalAmount,
            ellapsedSecs,
            loan.interestRate
        );

        uint256 interestPaid = (repaymentPrincipal - principalAmount);
        uint256 fee = percentageOf(interestPaid, _feeManager.feePercentage());

        uint256 unClaimedInterest = (interestPaid - fee);

        _feeManager.credit(loan.principalToken, fee);

        bool completed = _loanManager.repayLoan(
            loanId,
            unClaimedInterest,
            principalAmount,
            collateralAmount
        );

        if (loan.principalToken == nativeAddress) {
            require(msg.value >= repaymentPrincipal);
        } else {
            ERC20(loan.principalToken).safeTransferFrom(
                _msgSender(),
                address(this),
                repaymentPrincipal
            );
        }

        transfer(
            loan.offerId,
            _msgSender(),
            principalAmount.add(unClaimedInterest),
            loan.principalToken,
            Type.ADDED
        );

        uint256 interestPaidInUSD = _priceFeed.amountInUSD(
            loan.principalToken,
            (repaymentPrincipal - principalAmount)
        );

        _activity.repayLoan(
            loan.lender,
            _msgSender(),
            interestPaidInUSD,
            completed
        );
    }

    /// @notice This function is use to repay a liquidated loan
    /// @dev Liquidated loans cannot be repaid by percentage
    function repayLiquidatedLoan(uint256 loanId) public payable whenNotPaused {}

    // =========== Cancel / Reject Request Functions =========== //

    /// @notice This function will reject a request
    /// @dev Request can only be rejected by the offer creator
    function rejectRequest(uint256 requestId) public whenNotPaused {
        _offerManager.rejectRequest(requestId, _msgSender());
    }

    /// @notice This function will cancel a request
    /// @dev Request can only be calncelled by the request creator
    function cancelRequest(uint256 requestId) public whenNotPaused {
        RequestLibrary.Request memory request = _offerManager.getRequest(
            requestId
        );

        OfferLibrary.Offer memory offer = _offerManager.getOffer(
            request.offerId
        );

        if (request.requestType == RequestLibrary.Type.LENDING_REQUEST) {
            uint256 principalAmount = percentageOf(
                offer.initialPrincipal,
                request.percentage
            );

            if (offer.principalToken == nativeAddress) {
                payable(_msgSender()).transfer(principalAmount);
            } else {
                ERC20(offer.principalToken).safeTransfer(
                    _msgSender(),
                    principalAmount
                );
            }
        } else {
            if (request.collateralToken == nativeAddress) {
                payable(_msgSender()).transfer(request.collateralAmount);
            } else {
                ERC20(request.collateralToken).safeTransfer(
                    _msgSender(),
                    request.collateralAmount
                );
            }
        }

        _offerManager.cancelRequest(requestId, _msgSender());
    }

    // =========== Claim Functions =========== //

    /// @notice This function is use to claim back unlocked collateral from a loan
    /// @dev Can only be called by the borrower
    function claimCollateral(uint256 loanId) public nonReentrant whenNotPaused {
        (uint256 amount, uint256 offerId, address token) = _loanManager
            .claimCollateral(loanId, _msgSender());

        if (token == nativeAddress) {
            payable(_msgSender()).transfer(amount);
        } else {
            ERC20(token).safeTransfer(_msgSender(), amount);
        }

        transfer(offerId, _msgSender(), amount, token, Type.CLAIMED);
    }

    /// @notice This function is use to claim borrowed loan principal
    /// @dev Can only be called by the borrower
    function claimBorrowedPrincipal(uint256 loanId)
        public
        nonReentrant
        whenNotPaused
    {
        (uint256 amount, uint256 offerId, address token) = _loanManager
            .claimBorrowedPrincipal(loanId, _msgSender());

        if (token == nativeAddress) {
            payable(_msgSender()).transfer(amount);
        } else {
            ERC20(token).safeTransfer(_msgSender(), amount);
        }

        transfer(offerId, _msgSender(), amount, token, Type.CLAIMED);
    }

    /// @notice This function is use to claim back repaid principal + interests from a loan
    /// @dev Can only be called by the lender
    function claimPrincipal(uint256 loanId) public nonReentrant whenNotPaused {
        (uint256 amount, uint256 offerId, address token) = _loanManager
            .claimPrincipal(loanId, _msgSender());

        if (token == nativeAddress) {
            payable(_msgSender()).transfer(amount);
        } else {
            ERC20(token).safeTransfer(_msgSender(), amount);
        }

        transfer(offerId, _msgSender(), amount, token, Type.CLAIMED);
    }

    /// @notice This function is use to claim defaulted loan collateral
    /// @dev Can only be called by the lender
    function claimDefaultCollateral(uint256 loanId)
        public
        nonReentrant
        whenNotPaused
    {
        (uint256 amount, uint256 offerId, address token) = _loanManager
            .claimDefaultCollateral(loanId, _msgSender());

        if (token == nativeAddress) {
            payable(_msgSender()).transfer(amount);
        } else {
            ERC20(token).safeTransfer(_msgSender(), amount);
        }

        transfer(offerId, _msgSender(), amount, token, Type.CLAIMED);
    }

    // =========== Loan Liquidation ============= //

    /// @dev this function will liquidate a loan when it has pass
    /// maturity date + grace days.
    /// It can be call by anyone
    function liquidateLoan(uint256 loanId) public nonReentrant {
        LoanLibrary.Loan memory loan = _loanManager.getLoan(loanId);

        // calculate the duration of the loan
        uint256 time = block.timestamp;
        uint256 ellapsedSecs = (time - loan.startDate);

        uint256 repaymentPrincipal = getFullInterestAmount(
            loan.currentPrincipal,
            ellapsedSecs,
            loan.interestRate
        );

        uint256 repaymentCollateral = _priceFeed.exchangeRate(
            loan.principalToken,
            loan.collateralToken,
            repaymentPrincipal
        );

        uint256 interestInCollateral = _priceFeed.exchangeRate(
            loan.principalToken,
            loan.collateralToken,
            (repaymentPrincipal - loan.currentPrincipal)
        );

        uint256 principalPaid;
        uint256 collateralRetrieved;
        uint256 collateralFee;

        uint256 fee = percentageOf(
            interestInCollateral,
            _feeManager.feePercentage()
        );

        if (loan.currentCollateral >= (repaymentCollateral - fee)) {
            collateralRetrieved = (repaymentCollateral - fee);
            principalPaid = loan.currentPrincipal;

            if (loan.currentCollateral >= repaymentCollateral) {
                collateralFee = fee;
            } else {
                collateralRetrieved = loan.currentCollateral;
                collateralFee = (loan.currentCollateral -
                    (repaymentCollateral - fee));
            }
        } else {
            collateralRetrieved = loan.currentCollateral;

            uint256 collateralInPrincipal = _priceFeed.exchangeRate(
                loan.collateralToken,
                loan.principalToken,
                collateralRetrieved
            );

            principalPaid = collateralInPrincipal;
            collateralFee = 0;
        }

        _feeManager.credit(loan.collateralToken, collateralFee);

        _loanManager.liquidateLoan(
            loanId,
            principalPaid,
            collateralRetrieved,
            (collateralRetrieved - collateralFee)
        );
    }

    // ============= ABOUT ============ //

    function getVersion() public pure returns (uint256) {
        return LENDINGPOOL_VERSION;
    }

    // ============= ADMIN FUNCTIONS =============== //

    function setFeeds(
        address ltv_,
        address activity_,
        address priceFeed_
    ) public onlyOwner nonReentrant {
        _ltvRatio = ILoanToValueRatio(ltv_);
        _activity = IActivity(activity_);
        _priceFeed = IPriceFeed(priceFeed_);
    }

    function setManagers(
        address loanManager_,
        address offerManager_,
        address feeManager_
    ) public onlyOwner nonReentrant {
        _loanManager = ILoanManager(loanManager_);
        _offerManager = IOfferManager(offerManager_);
        _feeManager = IFeeManager(feeManager_);
    }

    /// @dev to claim developer revenue
    function claim(
        address token,
        address payable receiver,
        uint256 amount
    ) public onlyOwner nonReentrant {
        require(amount > 0, "ERR_ZERO_AMOUNT");
        _feeManager.debit(token, amount);
        if (token == nativeAddress) {
            receiver.transfer(amount);
        } else {
            ERC20(token).safeTransfer(receiver, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract LendingPoolProvider {
    using Counters for Counters.Counter;
    Counters.Counter private transferIdTracker;

    enum Type {
        ADDED,
        CLAIMED,
        LOCKED,
        REMOVED
    }

    event Transfer(
        uint256 transferId,
        uint256 offerId,
        address from,
        uint256 amount,
        address token,
        Type transferType,
        uint256 timestamp
    );

    function transfer(
        uint256 offerId,
        address from,
        uint256 amount,
        address token,
        Type transferType
    ) public virtual {
        transferIdTracker.increment();
        emit Transfer(
            transferIdTracker.current(),
            offerId,
            from,
            amount,
            token,
            transferType,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/ActivityLibrary.sol";

interface IActivity {
    function borrowLoan(
        address lender,
        address borrower,
        uint256 amountBorrowedInUSD
    ) external;

    function repayLoan(
        address lender,
        address borrower,
        uint256 interestPaidInUSD,
        bool completed
    ) external;

    function activeLoansCount(address user) external view returns (uint16);

    function dropCollateral(address borrower, uint256 amountInUSD) external;

    function isDefaulter(address user) external returns (bool);

    function getActivity(address user)
        external view
        returns (ActivityLibrary.Model memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFeeManager {
    function credit(address token, uint256 amount) external;

    function debit(address token, uint256 amount) external;

    function feePercentage() external returns (uint160);

    function balanceOf(address token) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/LoanLibrary.sol";
import "../libraries/OfferLibrary.sol";
import "../interfaces/ILoanManager.sol";

interface ILoanManager {
    function createLoan(
        uint256 offerId,
        OfferLibrary.Type offerType,
        address principalToken,
        address collateralToken,
        uint256 principalAmount,
        uint256 collateralAmount,
        uint256 collateralPriceInUSD,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint256 unClaimedBorrowedPrincipal,
        address borrower,
        address lender
    ) external returns (uint256);

    function getLoan(uint256 loanId) external returns (LoanLibrary.Loan memory);

    function repayLoan(
        uint256 loanId,
        uint256 interestPaid,
        uint256 principalPaid,
        uint256 collateralRetrieved
    ) external returns (bool);

    function claimPrincipal(uint256 loanId, address user)
        external
        returns (uint256, uint256, address);

    function claimDefaultCollateral(uint256 loanId, address user)
        external
        returns (uint256, uint256, address);

    function claimCollateral(uint256 loanId, address user)
        external
        returns (uint256, uint256, address);

    function claimBorrowedPrincipal(uint256 loanId, address user)
        external
        returns (uint256, uint256, address);

    function liquidateLoan(
        uint256 loanId,
        uint256 principalPaid,
        uint256 collateralRetrieved,
        uint256 collateralPaid
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILoanToValueRatio {
    function getBase() external view returns (uint8);

    function getLTV(address user) external view returns (uint160);

    function getRelativeLTV(address user, uint256 amount)
        external
        view
        returns (uint160);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/OfferLibrary.sol";
import "../libraries/RequestLibrary.sol";

interface IOfferManager {
    function createLendingOffer(
        address principalToken,
        uint256 principalAmount,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 daysToExpire,
        address[] memory collateralTokens,
        address lender
    ) external returns (uint256);

    function createLendingRequest(
        uint16 percentage,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address lender,
        uint256 offerId
    ) external returns (uint256);

    function createBorrowingOffer(
        address principalToken,
        address collateralToken,
        uint256 collateralAmount,
        uint256 principalAmount,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address borrower
    ) external returns (uint256);

    function createBorrowingRequest(
        uint16 percentage,
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralPriceInUSD,
        uint160 ltvUsed,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint16 hoursToExpire,
        address borrower,
        uint256 offerId
    ) external returns (uint256);

    function reActivateOffer(
        uint256 offerId,
        uint16 toExpire,
        address user
    ) external;

    function rejectRequest(uint256 requestId, address user) external;

    function acceptRequest(uint256 requestId, address user) external;

    function cancelRequest(uint256 requestId, address user) external;

    function removePrincipal(
        uint256 offerId,
        address user,
        uint256 amount
    ) external;

    function removeCollateral(
        uint256 offerId,
        address user,
        uint256 amount
    ) external;

    function isCollateralSupported(uint256 offerId, address token)
        external
        returns (bool);

    function afterBorrowingLoan(
        uint256 offerId,
        uint256 principalAmount,
        uint256 collateralAmount
    ) external;

    function afterLendingLoan(uint256 offerId, uint256 principalAmount)
        external;

    function getOffer(uint256 offerId)
        external
        view
        returns (OfferLibrary.Offer memory);

    function getRequest(uint256 requestId)
        external
        view
        returns (RequestLibrary.Request memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPriceFeed {
    function getLatestPriceUSD(address) external returns (uint256, uint8);

    function amountInUSD(address token, uint256 amount)
        external
        returns (uint256);

    function exchangeRate(
        address base,
        address quote,
        uint256 amount
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library ActivityLibrary {
    event ActivityChanged(
        address user,
        uint16 borrowedTimes,
        uint16 lentTimes,
        uint256 borrowedVolume,
        uint256 lentVolume,
        uint256 lastActive,
        uint256 collateralVolume,
        uint256 interestPaidVolume,
        uint16 defaultedTimes,
        uint256 defaultedVolume,
        uint256 firstBorrowAt,
        uint16 activeLoans
    );

    struct Model {
        // frequency
        uint16 borrowedTimes;
        uint16 lentTimes;
        // volume
        uint256 borrowedVolume;
        uint256 lentVolume;
        // last active
        uint256 lastActive;
        // collateral volume
        uint256 collateralVolume;
        // interestRate
        uint256 interestPaidVolume;
        // defaulting
        uint16 defaultedTimes;
        uint256 defaultedVolume;
        // first borrow date
        uint256 firstBorrowAt;
        // active loans
        uint16 activeLoans;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

library Errors {
    string public constant PRICE_FEED_TOKEN_NOT_SUPPORTED = "100"; // Token is not supported
    string public constant PRICE_FEED_TOKEN_BELOW_ZERO = "101"; // Token below zero price
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LoanLibrary {
    enum State {
        ACTIVE,
        REPAID,
        ACTIVE_DEFAULTED,
        REPAID_DEFAULTED
    }

    event LoanCreated(
        uint256 loanId,
        uint256 offerId,
        LoanLibrary.State state,
        address principalToken,
        address collateralToken,
        uint256 initialPrincipal,
        uint256 currentPrincipal,
        uint256 initialCollateral,
        uint256 currentCollateral,
        uint256 interestRate,
        uint256 startDate,
        uint256 maturityDate,
        uint16 graceDays,
        address borrower,
        address lender
    );

    event LoanCreatedProperty(
        uint256 loanId,
        uint256 collateralPriceInUSD,
        uint8 numInstallmentsPaid,
        uint256 unClaimedPrincipal,
        uint256 unClaimedCollateral,
        uint256 unClaimedDefaultCollateral,
        uint256 unClaimedBorrowedPrincipal,
        uint256 totalInterestPaid,
        uint256 repaidOn
    );

    struct Loan {
        uint256 offerId;
        /// @dev enum loan state
        State state;
        /// @dev tokens address
        address principalToken;
        address collateralToken;
        /// @dev initial principal that was borrowed
        uint256 initialPrincipal;
        /// @dev current principal that is being borrowed
        uint256 currentPrincipal;
        /// @dev initial collateral that was dropped
        uint256 initialCollateral;
        /// @dev current collateral that is being dropped
        uint256 currentCollateral;
        /// @dev worth of collateral in USD at the time of loan
        uint256 collateralPriceInUSD;
        /// @dev loan interestRate rate per seconds
        uint256 interestRate;
        /// @dev loan start in seconds
        uint256 startDate;
        /// @dev loan maturity in seconds
        uint256 maturityDate;
        /// @dev loan grace days in days
        uint16 graceDays;
        /// @dev number of times that a borrower
        /// split to payback a loan
        uint8 numInstallmentsPaid;
        /// @dev this represents principal + interestRate
        /// that was paid payback by the borrower that
        /// the lender as not claimed
        uint256 unClaimedPrincipal;
        /// @dev this represents collateral amount
        /// that was unlock that the borrower has not
        /// claimed
        uint256 unClaimedCollateral;
        /// @dev this represents collateral amount
        /// retrieve from a borrower when default
        /// that the lender has not claimed
        uint256 unClaimedDefaultCollateral;
        /// @dev this represents principal amount
        /// that the borrower has not claimed
        uint256 unClaimedBorrowedPrincipal;
        /// @dev this represents total interestRate paid by
        /// the borrower
        uint256 totalInterestPaid;
        /// @dev seconds of full/installment repaid loan
        uint256 repaidOn;
        /// @dev actors address
        address borrower;
        address lender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library OfferLibrary {
    enum Type {
        LENDING_OFFER,
        BORROWING_OFFER
    }

    enum State {
        DEFAULT,
        CANCELLED
    }

    event OfferCreated(
        uint256 offerId,
        State state,
        address principalToken,
        uint256 currentPrincipal,
        uint256 initialPrincipal,
        uint256 interestRate,
        uint16 daysToMaturity,
        uint expiresAt,
        uint createdAt,
        address creator,
        address[] collateralTokens,
        address collateralToken,
        uint256 currentCollateral,
        uint256 initialCollateral,
        OfferLibrary.Type offerType
    );

    struct Offer {
        // shared attributes
        uint256 offerId;
        State state;
        address principalToken;
        uint256 currentPrincipal;
        uint256 initialPrincipal;
        uint256 interestRate;
        uint16 daysToMaturity;
        uint expiresAt;
        uint createdAt;
        address creator;
        // related to lending offers only
        address[] collateralTokens;
        // related to borrowing offers only
        address collateralToken;
        uint256 currentCollateral;
        uint256 initialCollateral;
        // type
        Type offerType;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library RequestLibrary {
    enum Type {
        LENDING_REQUEST,
        BORROWING_REQUEST
    }

    enum State {
        PENDING,
        ACCEPTED,
        REJECTED,
        CANCELLED
    }

    event RequestCreated(
        uint256 requestId,
        State state,
        uint16 percentage,
        uint16 daysToMaturity,
        uint256 interestRate,
        uint expiresAt,
        uint createdAt,
        address creator,
        uint256 offerId,
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralPriceInUSD,
        uint160 ltvUsed,
        RequestLibrary.Type requestType
    );

    struct Request {
        // shared
        uint256 requestId;
        State state;
        uint16 percentage;
        uint16 daysToMaturity;
        uint256 interestRate;
        uint expiresAt;
        uint createdAt;
        address creator;
        uint256 offerId;
        // related to borrowing request only
        address collateralToken;
        uint256 collateralAmount;
        uint256 collateralPriceInUSD;
        uint160 ltvUsed;
        // type
        Type requestType;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract SimpleInterest {
    /// @dev The units of precision equal to the minimum interestRate.
    uint256 public constant INTEREST_RATE_DENOMINATOR = 1e18;
    uint16 public constant PERCENT = 100;

    function getFullInterestAmount(
        uint256 principal,
        uint256 durationSecs,
        uint256 interestRate
    ) public pure virtual returns (uint256) {
        uint256 accrued = (principal * interestRate * durationSecs) /
            INTEREST_RATE_DENOMINATOR /
            PERCENT;

        return principal + accrued;
    }

    function percentageOf(uint256 total, uint160 percent)
        public
        pure
        virtual
        returns (uint256)
    {
        if (percent == 0) return total;
        return (total * percent) / PERCENT;
    }

    function checkPercentage(uint16 percentage) public pure virtual {
        // percentage must be 25, 50, 75 or 100
        require(percentage <= 100, "OVER_PERCENTAGE");
        require(percentage % 25 == 0, "ERR_PERCENTAGE");
    }
}
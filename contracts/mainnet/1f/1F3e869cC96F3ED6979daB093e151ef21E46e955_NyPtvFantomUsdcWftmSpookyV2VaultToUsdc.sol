/**
 *Submitted for verification at FtmScan.com on 2022-11-16
*/

// SPDX-License-Identifier: No License (None)
// No permissions granted before Thursday, 16 May 2024, then MIT after this date.
pragma solidity ^0.8.0;

//
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

//
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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

//
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
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
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }
}

//
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
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

//
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

//
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)
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
    }
    _balances[to] += amount;

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

//
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)
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

//
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
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
    return functionCall(target, data, "Address: low-level call failed");
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
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
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
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
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
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
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
}

//
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)
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
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

//
// No permissions granted before Sunday, 5 May 2024, then MIT after this date.
/*
 * ███╗   ██╗██╗███╗   ██╗     ██╗ █████╗   ██╗   ██╗██╗███████╗██╗     ██████╗ ███████╗██████╗
 * ████╗  ██║██║████╗  ██║     ██║██╔══██╗  ╚██╗ ██╔╝██║██╔════╝██║     ██╔══██╗██╔════╝██╔══██╗
 * ██╔██╗ ██║██║██╔██╗ ██║     ██║███████║   ╚████╔╝ ██║█████╗  ██║     ██║  ██║█████╗  ██████╔╝
 * ██║╚██╗██║██║██║╚██╗██║██   ██║██╔══██║    ╚██╔╝  ██║██╔══╝  ██║     ██║  ██║██╔══╝  ██╔══██╗
 * ██║ ╚████║██║██║ ╚████║╚█████╔╝██║  ██║     ██║   ██║███████╗███████╗██████╔╝███████╗██║  ██║
 * ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚════╝ ╚═╝  ╚═╝     ╚═╝   ╚═╝╚══════╝╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═╝
 *                                   Yield like a Ninja!
 *
 * We are committed to working with Black/White hats. If you find an issue then please reach
 * out to us:
 *
 * Twitter: https://twitter.com/NinjaYielder
 */
// Minimized version of Strategy interface (from vault perspective)
interface IStrategy {
  function deposit() external;

  function withdraw(uint256 _amount) external;

  function balanceOf() external view returns (uint256);
}

error NYProfitTakingVault__AlreadyInitialized();

error NYProfitTakingVault__CannotWithdrawRewardToken();

error NYProfitTakingVault__CannotWithdrawUnderlying();

error NYProfitTakingVault__InitializationPeriodPassed();

error NYProfitTakingVault__OnlyStrategy();

error NYProfitTakingVault__RewardTimeOutOfBounds();

error NYProfitTakingVault__TermsAlreadyAccepted();

error NYProfitTakingVault__UnderlyingCapReached(uint256 underlyingCap);

error NYProfitTakingVault__ZeroAmount();

/**
 * @notice Based on the ReaperVaultv1_4.sol MIT contract at
 * https://github.com/Byte-Masons/spooky-farmer/blob/ftm-deus/contracts/ReaperVaultv1_4.sol
 *
 * @dev Implementation of a vault to deposit funds for yield extraction.
 * This is the contract that receives funds and that users interface with.
 * The yield strategy itself is implemented in a separate 'Strategy.sol' contract.
 */
contract NYProfitTakingVaultBaseV1 is ERC20, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  // The strategy in use by the vault.
  address public strategy;

  uint256 public constant PERCENT_DIVISOR = 10000;
  uint256 public constant REWARD_PER_SHARE_PRECISION = 1e24; // USDC is 6 decimals, so 1e12 math doesn't work.
  uint256 public constant INITIALIZATION_WINDOW = 1200; // 20 minutes
  uint256 public underlyingCap;

  // Masterchef accounting vars
  uint256 public lastRewardTime; // Last block time that reward token distribution occurs.
  uint256 public accRewardTokenPerShare; // Accumulated Reward token per share, times 1e12. See below.

  /**
   * @dev The strategies initialization status. Gives deployer 20 minutes after contract
   * construction (constructionTime) to set the strategy implementation.
   */
  uint256 public constructionTime;

  // One time initialization
  bool public initialized = false;

  // The underlying token the vault accepts and uses for yield income.
  IERC20 public underlying;

  // the Reward token the vault accepts from the strategy and pays out to users
  IERC20 public rewardToken;

  // The Vault handles the reward token payouts like a MasterChef
  // Except the rewards are sent in for distribution by the Strategy
  // instead of being generated mathematiaclly by the MasterChef formula.

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of reward token
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * accRewardTokenPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The `accRewardTokenPerShare` (and `lastRewardTime`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each user that stakes LP tokens.
  mapping(address => UserInfo) public userInfo;

  /**
   * + WEBSITE DISCLAIMER +
   * While we have taken precautionary measures to protect our users,
   * it is imperative that you read, understand and agree to the disclaimer below:
   *
   * Using our platform may involve financial risk of loss.
   * Never invest more than what you can afford to lose.
   * Never invest in a NinjaYielder Vault with tokens you don't trust.
   * Never invest in a NinjaYielder Vault with tokens whose rules for minting you don’t agree with.
   * Ensure the accuracy of the contracts for the tokens in the NinjaYielder Vault.
   * Ensure the accuracy of the contracts for the NinjaYielder Vault and Strategy you are depositing in.
   * Check our documentation regularly for additional disclaimers and security assessments.
   * ...and of course: DO YOUR OWN RESEARCH!!!
   *
   * By accepting these terms, you agree that Ninja Yielder, or any parties
   * affiliated with the deployment and management of these vaults or their attached strategies
   * are not liable for any financial losses you might incur as a direct or indirect
   * result of investing in any of the pools on the platform.
   */
  mapping(address => bool) public hasReadAndAcceptedTerms;

  event Deposit(address indexed user, uint256 amount);
  event DepositFeeUpdated(uint256 newFee);
  event RewardReceivedFromStrategy(uint256 rewardAmount);
  event TermsAccepted(address user);
  event UnderlyingCapUpdated(uint256 newUnderlyingCap);
  event Withdraw(address indexed user, uint256 shares, uint256 rewardAmount);
  event WithdrawProfit(address indexed user, uint256 amount);

  /**
   * @dev Initializes the vault's own 'NY' token.
   * This token is minted when someone deposits and is burned in order
   * to withdraw the corresponding portion of the underlying assets.
   * @param _underlying the underlying that provides yield.
   * @param _name the name of the vault token.
   * @param _symbol the symbol of the vault token.
   * @param _underlyingCap initial deposit cap for scaling Number of Underlying tokens safely
   */
  constructor(
    address _underlying,
    address _rewardToken,
    string memory _name,
    string memory _symbol,
    uint256 _underlyingCap
  ) ERC20(string(_name), string(_symbol)) {
    underlying = IERC20(_underlying);
    rewardToken = IERC20(_rewardToken);
    constructionTime = block.timestamp;
    underlyingCap = _underlyingCap;
  }

  /**
   * @dev Connects the vault to its initial strategy. One use only.
   * @notice deployer has only 20 minutes after construction to connect the initial strategy.
   * @param _strategy the vault's initial strategy
   */
  function initialize(address _strategy) public onlyOwner returns (bool) {
    if (initialized) {
      revert NYProfitTakingVault__AlreadyInitialized();
    }
    if (block.timestamp > constructionTime + INITIALIZATION_WINDOW) {
      revert NYProfitTakingVault__InitializationPeriodPassed();
    }
    strategy = _strategy;
    initialized = true;
    return true;
  }

  /**
   * @dev Gives user access to the client
   * @notice this does not affect vault permissions, and is read from client-side
   */
  function agreeToTerms() public returns (bool) {
    if (hasReadAndAcceptedTerms[msg.sender]) {
      revert NYProfitTakingVault__TermsAlreadyAccepted();
    }
    hasReadAndAcceptedTerms[msg.sender] = true;
    emit TermsAccepted(msg.sender);
    return true;
  }

  /**
   * @dev It calculates the total underlying value of {underlying} held by the system.
   * It takes into account the vault contract balance, the strategy contract balance
   * and the balance deployed in other contracts as part of the strategy.
   */
  function balance() public view returns (uint256) {
    return underlying.balanceOf(address(this)) + IStrategy(strategy).balanceOf();
  }

  /**
   * @dev Custom logic in here for how much the vault allows to be borrowed.
   * We return 100% of tokens for now. Under certain conditions we might
   * want to keep some of the system funds at hand in the vault, instead
   * of putting them to work.
   */
  function available() public view returns (uint256) {
    return underlying.balanceOf(address(this));
  }

  /**
   * @dev Function for various UIs to display the current value of one of our vault tokens.
   * Returns an uint256 with 18 decimals of how much underlying asset one vault share represents.
   *
   * This is not an auto-compounder, but we do charge a small security fee on withdraw, so over time
   * The price of the vault token will go up.
   */
  function getPricePerFullShare() public view returns (uint256) {
    return totalSupply() == 0 ? 1e18 : (balance() * 1e18) / totalSupply();
  }

  /**
   * @dev A helper function to call deposit() with all the sender's funds.
   */
  function depositAll() external {
    deposit(underlying.balanceOf(msg.sender));
  }

  /**
   * @dev The entrypoint of funds into the system. People deposit with this function
   * into the vault. The vault is then in charge of sending funds into the strategy.
   * @notice the _before and _after variables are used to account properly for
   * 'burn-on-transaction' tokens.
   * @notice to ensure 'owner' can't sneak an implementation past the timelock,
   * it's set to true
   */
  function deposit(uint256 _amount) public nonReentrant {
    if (_amount == 0) {
      revert NYProfitTakingVault__ZeroAmount();
    }

    uint256 _pool = balance();
    if (_pool + _amount > underlyingCap) {
      revert NYProfitTakingVault__UnderlyingCapReached(underlyingCap);
    }

    uint256 _before = underlying.balanceOf(address(this));
    underlying.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _after = underlying.balanceOf(address(this));
    _amount = _after - _before;

    uint256 shares = 0;
    if (totalSupply() == 0) {
      shares = _amount;
    } else {
      shares = (_amount * totalSupply()) / _pool;
    }

    uint256 pending = getUserPendingEarnings(msg.sender);

    _mint(msg.sender, shares);

    UserInfo storage user = userInfo[msg.sender];
    user.amount = user.amount + _amount;
    user.rewardDebt = (user.amount * accRewardTokenPerShare) / REWARD_PER_SHARE_PRECISION;

    if (pending > 0) {
      rewardToken.safeTransfer(msg.sender, pending);
    }

    earn();

    emit Deposit(msg.sender, _amount);
  }

  /**
   * @dev The strategy will use this function to send reward tokens to the vault.
   */
  function depositOutputTokenForUsers(uint256 _amount) external {
    if (_amount == 0) {
      revert NYProfitTakingVault__ZeroAmount();
    }
    if (block.timestamp <= lastRewardTime) {
      revert NYProfitTakingVault__RewardTimeOutOfBounds();
    }
    if (msg.sender != strategy) {
      revert NYProfitTakingVault__OnlyStrategy();
    }

    uint256 totalShares = totalSupply();
    if (totalShares == 0) {
      lastRewardTime = block.timestamp;
      return;
    }

    accRewardTokenPerShare += ((_amount * REWARD_PER_SHARE_PRECISION) / totalShares);
    lastRewardTime = block.timestamp;

    // Now pull in the tokens (Should have permission)
    // We only want to pull the tokens with accounting
    rewardToken.transferFrom(strategy, address(this), _amount);

    emit RewardReceivedFromStrategy(_amount);
  }

  /**
   * @dev Users can withdraw profits by withdrawing their output tokens.
   */
  function withdrawProfit() external {
    if (block.timestamp <= lastRewardTime) {
      revert NYProfitTakingVault__RewardTimeOutOfBounds();
    }

    UserInfo storage user = userInfo[msg.sender];

    if (user.amount == 0) {
      revert NYProfitTakingVault__ZeroAmount();
    }

    uint256 pending = getUserPendingEarnings(msg.sender);

    if (pending > 0) {
      user.rewardDebt = (user.amount * accRewardTokenPerShare) / REWARD_PER_SHARE_PRECISION;

      rewardToken.safeTransfer(msg.sender, pending);

      emit WithdrawProfit(msg.sender, pending);
    }
  }

  /**
   * @dev View function to see pending Reward tokens on frontend.
   */
  function pendingEarnings(address _user) external view returns (uint256) {
    return getUserPendingEarnings(_user);
  }

  /**
   * @dev Function to send funds into the strategy and put them to work. It's primarily called
   * by the vault's deposit() function.
   */
  function earn() public {
    uint256 _bal = available();
    underlying.safeTransfer(strategy, _bal);
    IStrategy(strategy).deposit();
  }

  /**
   * @dev A helper function to call withdraw() with all the sender's funds.
   */
  function withdrawAll() external {
    withdraw(balanceOf(msg.sender));
  }

  /**
   * @dev Function to exit the system. The vault will withdraw the required tokens
   * from the strategy and pay up the token holder. A proportional number of vault
   * tokens are burned in the process.
   */
  function withdraw(uint256 _shares) public nonReentrant {
    if (_shares == 0) {
      revert NYProfitTakingVault__ZeroAmount();
    }

    uint256 r = (balance() * _shares) / totalSupply(); // (22.0026004 * 1) / 21.98830580239786115 = 1.0006501
    UserInfo storage user = userInfo[msg.sender];

    _burn(msg.sender, _shares);

    // Withdraw underlying from strategy if not enough in vault
    uint256 b = underlying.balanceOf(address(this));
    if (b < r) {
      uint256 _withdraw = r - b;
      IStrategy(strategy).withdraw(_withdraw);
      uint256 _after = underlying.balanceOf(address(this));
      uint256 _diff = _after - b;
      if (_diff < _withdraw) {
        r = b + _diff;
      }
    }

    uint256 pending = getUserPendingEarnings(msg.sender);

    // Update user accounting
    user.amount = user.amount - _shares;
    user.rewardDebt = (user.amount * accRewardTokenPerShare) / REWARD_PER_SHARE_PRECISION;

    // Transfer out the reward tokens
    if (pending > 0) {
      rewardToken.safeTransfer(msg.sender, pending);
    }

    // Transfer out the underlying tokens
    underlying.safeTransfer(msg.sender, r);

    emit Withdraw(msg.sender, _shares, pending);
  }

  /**
   * @dev pass in max value of uint to effectively remove Underlying cap
   */
  function updateUnderlyingCap(uint256 _newUnderlyingCap) public onlyOwner {
    underlyingCap = _newUnderlyingCap;
    emit UnderlyingCapUpdated(underlyingCap);
  }

  /**
   * @dev helper function to remove Underlying cap
   */
  function removeUnderlyingCap() external onlyOwner {
    updateUnderlyingCap(type(uint256).max);
    emit UnderlyingCapUpdated(type(uint256).max);
  }

  /**
   * @dev Rescues random funds stuck that the strat can't handle.
   * @param _token address of the token to rescue.
   */
  function inCaseTokensGetStuck(address _token) external onlyOwner {
    if (_token == address(underlying)) {
      revert NYProfitTakingVault__CannotWithdrawUnderlying();
    }
    if (_token == address(rewardToken)) {
      revert NYProfitTakingVault__CannotWithdrawRewardToken();
    }

    uint256 amount = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransfer(msg.sender, amount);
  }

  /**
   * @dev Internal function to calculate users pending earnings
   */
  function getUserPendingEarnings(address _user) internal view returns (uint256) {
    UserInfo storage user = userInfo[_user];
    uint256 pending = (user.amount * accRewardTokenPerShare) / REWARD_PER_SHARE_PRECISION - user.rewardDebt;

    return pending;
  }
}

//
// No permissions granted before Thursday, 16 May 2024, then MIT after this date.
/*
 * ███╗   ██╗██╗███╗   ██╗     ██╗ █████╗   ██╗   ██╗██╗███████╗██╗     ██████╗ ███████╗██████╗
 * ████╗  ██║██║████╗  ██║     ██║██╔══██╗  ╚██╗ ██╔╝██║██╔════╝██║     ██╔══██╗██╔════╝██╔══██╗
 * ██╔██╗ ██║██║██╔██╗ ██║     ██║███████║   ╚████╔╝ ██║█████╗  ██║     ██║  ██║█████╗  ██████╔╝
 * ██║╚██╗██║██║██║╚██╗██║██   ██║██╔══██║    ╚██╔╝  ██║██╔══╝  ██║     ██║  ██║██╔══╝  ██╔══██╗
 * ██║ ╚████║██║██║ ╚████║╚█████╔╝██║  ██║     ██║   ██║███████╗███████╗██████╔╝███████╗██║  ██║
 * ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚════╝ ╚═╝  ╚═╝     ╚═╝   ╚═╝╚══════╝╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═╝
 *                                   Yield like a Ninja!
 *
 *
 * We are committed to working with Black/White hats. If you find an issue then please reach
 * out quoting reference 'NyPtvFantomUsdcWftmSpookyV2VaultToUsdc'
 *
 * Twitter: https://twitter.com/NinjaYielder
 */
contract NyPtvFantomUsdcWftmSpookyV2VaultToUsdc is NYProfitTakingVaultBaseV1 {
  constructor(
    address _token,
    address _outputToken,
    string memory _name,
    string memory _symbol,
    uint256 _underlyingCap
  ) NYProfitTakingVaultBaseV1(_token, _outputToken, _name, _symbol, _underlyingCap) {}
}
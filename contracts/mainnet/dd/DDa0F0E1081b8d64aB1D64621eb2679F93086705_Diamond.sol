/**
 *Submitted for verification at FtmScan.com on 2022-03-03
*/

/**

* The smart contracts that run MMR implement the latest trend in BSC tokens, 
* AUTO DIVIDEND YIELDING with an AUTO-DEPOSIT feature. 
* By simply buying and holding MMR you are rewarded!
*
* 
* 
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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
     * by making the `nonReentrant` function external, and make it call a
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
    using SafeMath for uint256;

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * will be to transferred to `to`.
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
}

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}


/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}


/// @title Dividend-Paying Token Interface
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);


  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
  function withdrawDividend() external;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}


/// @title Dividend-Paying Token Optional Interface
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/// @title Dividend-Paying Token
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;
  uint256 public lockedUp;

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
  }

  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  function distributeDividends(uint256 amount) public onlyOwner{
    // require(totalSupply() > 0);
    if (totalSupply() == 0) {
        lockedUp = lockedUp.add(amount);
        return;
    }

    if (amount > 0) {
        if (lockedUp > 0) {
            amount = amount.add(lockedUp);
            lockedUp = 0;
        }
        magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
        );
        emit DividendsDistributed(msg.sender, amount);

        totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender), true);
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
 function _withdrawDividendOfUser(address payable user, bool transferCake) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);

      if (transferCake) {
          (bool success,) = address(user).call{value: _withdrawableDividend}("");

          if(!success) {
            withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
            return 0;
          }
      }

      return _withdrawableDividend;
    }

    return 0;
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

//======================================Diamond=========================================//
contract Diamond is ERC20, ReentrancyGuard, Ownable {
    using SafeMath for uint;

    DiamondDividendTracker public dividendTracker;          // dividendTracker from jackpot
    DiamondDividendTracker public dividendNFTTracker;       // dividendTracker from NFT contracts

    bool private swapping;

    mapping(address=>bool) public operators;

    address public developer;

    // Public Parameters
    uint public initialSupply;
    
    uint public currentDay;
    uint public lockedPeriod;

    uint public nextDay;
    address public burnAddress;

    uint public totalBurnt;
    uint public totalEmitted;
    uint public totalWithdrawed;

    // emission rate for LP tokens.
    uint[] public emissionRates;
    bool private startEmission = false;

    // Public Mappings
    address[] public arrLpTokens;
    mapping(address=>mapping(uint=>uint)) public mapTokenDay_MemberCount;
    mapping(address=>mapping(uint=>address[])) public mapTokenDay_Members;
    mapping(address=>mapping(uint=>uint)) public mapTokenDay_Units;
    mapping(address=>mapping(uint=>uint)) public mapTokenDay_Emission;
    mapping(address=>mapping(uint=>mapping(address=>uint))) public mapTokenDay_MemberUnits;
    mapping(address=>mapping(address=>uint[])) public mapMemberToken_Days;

    mapping(address => uint) mapTokenBurntAmount;

    // Events
    event OperatorSet(address indexed newOperator, bool enabled);
    event NewDay(uint day, uint time);
    event Burn(address indexed member, address token, uint day, uint units, uint dailyTotal);
    event Withdrawal(address indexed member, address token, uint day, uint value);
    event SendDividends(uint256 tokensamount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    modifier onlyOperator() {
        require(operators[ msg.sender] == true, "operator: caller is not the operator");
        _;
    }

    //=====================================CREATION=========================================//
    // Constructor
    constructor() ERC20("Diamond", "DIAMOND") {
        developer = msg.sender;

        currentDay = 0;
        lockedPeriod = 1 days;
        
        burnAddress = address(0x000000000000000000000000000000000000dEaD);
        
        initialSupply = 100000 * 10 ** 18;                          // 100K diamond

        _mint(developer, initialSupply);
        _mint(address(this), 1000000 * 10 ** 18 - initialSupply);   // 900K diamond, total supply = 100K + 900K = 1M Diamond
        
        arrLpTokens = new address[](2);
        arrLpTokens[0] = address(0);
        arrLpTokens[1] = address(0);

        emissionRates = new uint[](2);
        emissionRates[0] = 10;
        emissionRates[1] = 5;

        dividendTracker = new DiamondDividendTracker();
        dividendTracker.setMinimumTokenBalanceForDividends(100 * 10 ** 18);     // 100 diamonds
        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(developer);

        dividendNFTTracker = new DiamondDividendTracker();
        dividendNFTTracker.setMinimumTokenBalanceForDividends(10 * 10 ** 18);   // 10 diamonds

        // exclude from receiving dividends
        dividendNFTTracker.excludeFromDividends(address(dividendNFTTracker));
        dividendNFTTracker.excludeFromDividends(address(this));
        dividendNFTTracker.excludeFromDividends(developer);
        
        emit Transfer(burnAddress, address(this), totalSupply());
    }

    receive() external payable {
    }

    // destroy developer
    function destroyDeveloper() public onlyOwner{
        developer = address(0);
    }

    // set developer
    function setDeveloper(address _account) public onlyOwner{
        require(_account != address(0), "Wrong address");

        developer = _account;
        dividendTracker.excludeFromDividends(developer);
        dividendNFTTracker.excludeFromDividends(developer);
    }

    /**
     * @dev Check the operator .
     */
    function isOperator() public view returns (bool) {
        return operators[ msg.sender];
    }

    /**
     * @dev Set operator of the contract.
     * Can only be called by the current operator.
     */
    function setOperator(address _newOperator, bool _enable) public onlyOwner {
        require(_newOperator != address(0), "Diamond::setOperator: new operator is the zero address");
        operators[_newOperator] = _enable;

        emit OperatorSet(_newOperator, _enable);
    }

    function setLPToken(uint8 index, address _lpToken) public onlyOwner {
        require(_lpToken != address(0), "LP token is the zero address");
        require(index >= 0 && index < 2, "Index is wrong");

        arrLpTokens[index] = _lpToken;

        if (!startEmission) {   // start process
            currentDay = 1;
            nextDay = block.timestamp.add(lockedPeriod);       

            uint remains = totalSupply().sub(initialSupply);
            uint emission = remains.mul(emissionRates[index]).div(10000);

            mapTokenDay_Emission[_lpToken][currentDay] = emission;
            totalEmitted = totalEmitted.add(emission);

            startEmission = true;
           
            emit NewDay(currentDay, nextDay); 
        }
    }

    function setEmissionRate(uint[] memory rates) public onlyOwner {
        require(rates.length == emissionRates.length, "Rate value is wrong");
                
        emissionRates = rates;
    }

    function setLockedPeriod(uint _period) public onlyOwner {
        lockedPeriod = _period;
    }
    
    function isRegisteredLPToken(address _lpToken) public view returns (bool)
    {
        require(_lpToken != address(0), "LP token can not be the zero address");

        for (uint8 i=0; i<arrLpTokens.length; i++)
        {
            if (arrLpTokens[i] == _lpToken)
                return true;
        }

        return false;
    }

    function startNewEmission() public onlyOwner {
        _updateEmission();
    }

    //==================================PROOF-OF-VALUE======================================//

    // Burn ether for nominated member
    function sendLPtoken(address _lpToken, uint _burnAmount) external {  
        require(currentDay > 0, "Buring LP Tokens is not started.");
        require(isRegisteredLPToken(_lpToken) == true, "LP token address is wrong");
        require(block.timestamp < nextDay, "Current emission ended");

        ERC20(_lpToken).transferFrom(msg.sender, address(this), _burnAmount);
        _recordBurn(msg.sender, _lpToken, currentDay, _burnAmount);

        _updateEmission();
    }

    // burn LP token by the owner
    function burnLPtoken(address _lpToken, uint _burnAmount) external onlyOwner {  
        require(isRegisteredLPToken(_lpToken) == true, "LP token address is wrong");
        require(ERC20(_lpToken).balanceOf(address(this)) > _burnAmount, "Token balance not sufficient");

        ERC20(_lpToken).transfer(burnAddress, _burnAmount);
    }

    // burn LP token by the owner
    function transferLPtoken(address _lpToken, uint _amount, address _recipient) external onlyOwner {  
        require(isRegisteredLPToken(_lpToken) == true, "LP token address is wrong");
        require(ERC20(_lpToken).balanceOf(address(this)) > _amount, "Token balance not sufficient");

        ERC20(_lpToken).transfer(_recipient, _amount);
    }

    // Internal - Records burn
    function _recordBurn(address _account, address _lpToken, uint _day, uint _amount) private {
        require(_account != address(0), "Account is the zero address");
        require(isRegisteredLPToken(_lpToken) == true, "LP token address is wrong");

        if (mapTokenDay_MemberUnits[_lpToken][_day][_account] == 0){
            mapMemberToken_Days[_account][_lpToken].push(_day);
            mapTokenDay_MemberCount[_lpToken][_day] = mapTokenDay_MemberCount[_lpToken][_day].add(1);
            mapTokenDay_Members[_lpToken][_day].push(_account);
        }

        mapTokenDay_MemberUnits[_lpToken][_day][_account] = 
                            mapTokenDay_MemberUnits[_lpToken][_day][_account].add(_amount);
        mapTokenDay_Units[_lpToken][_day] = mapTokenDay_Units[_lpToken][_day].add(_amount);
        totalBurnt = totalBurnt.add(_amount);
        
        emit Burn(_account, _lpToken, _day, _amount, mapTokenDay_Units[_lpToken][_day]);
    }
    
    //======================================WITHDRAWAL======================================//
    // Used to efficiently track participation in each era
    function getDaysContributedForToken(address _account, address _lpToken) public view returns(uint){
        require(currentDay > 0, "Buring LP Tokens is not started.");
        require(_account != address(0), "Account is the zero address");
        require(isRegisteredLPToken(_lpToken) == true, "LP token address is wrong");

        return mapMemberToken_Days[_account][_lpToken].length;
    }
    
    function pendingRewards(address _account, address _lpToken) public view returns(uint){
        require(currentDay > 0, "Buring LP Tokens is not started.");
        require(_account != address(0), "Account is the zero address");
        require(isRegisteredLPToken(_lpToken) == true, "LP token address is wrong");
        
        uint length = mapMemberToken_Days[_account][_lpToken].length;
        
        uint _day;
        uint totalUnits;
        uint memberUnits;
        uint currentEmission;
        uint value;
        for (uint i=0; i<length; i++){
            _day = mapMemberToken_Days[_account][_lpToken][i];
            
            if (_day == currentDay && block.timestamp < nextDay)
                continue;
            
            memberUnits = mapTokenDay_MemberUnits[_lpToken][_day][_account];
            if (memberUnits == 0)
                continue;
            
            totalUnits = mapTokenDay_Units[_lpToken][_day];
                
            currentEmission = mapTokenDay_Emission[_lpToken][_day];
            
            value = value.add(currentEmission.mul(memberUnits).div(totalUnits));
        }

        return value;
    }
    
    function getMembersAtCurrentDay() public view returns(uint){
        require(currentDay > 0, "Buring LP Tokens is not started.");
       
        uint length = arrLpTokens.length;
        uint totalCount;
        for (uint8 i=0; i<length; i++)
        {
            totalCount = totalCount.add(mapTokenDay_MemberCount[arrLpTokens[i]][currentDay]);
        }

        return totalCount;
    }
    
    function getEmissionsAtCurrentDay() public view returns(uint){
        require(currentDay > 0, "Buring LP Tokens is not started.");
       
        uint length = arrLpTokens.length;
        uint totalEmission;
        for (uint8 i=0; i<length; i++)
        {
            totalEmission = totalEmission.add(mapTokenDay_Emission[arrLpTokens[i]][currentDay]);
        }

        return totalEmission;
    }
    
    function getLPTokensBurntAtCurrentDay() public view returns(uint){
        require(currentDay > 0, "Buring LP Tokens is not started.");
       
        uint length = arrLpTokens.length;
        uint totalTokens;
        for (uint8 i=0; i<length; i++)
        {
            totalTokens = totalTokens.add(mapTokenDay_Units[arrLpTokens[i]][currentDay]);
        }

        return totalTokens;
    }
    
    // Call to withdraw a claim
    function withdrawShare(address _lpToken) external nonReentrant returns (uint) {
        require(currentDay > 0, "Buring LP Tokens is not started.");
        require(isRegisteredLPToken(_lpToken) == true, "LP token address is wrong");
        
        uint value;
        uint _day;
        uint length = mapMemberToken_Days[msg.sender][_lpToken].length;
        require(length > 0, "No LP deposits.");

        for (uint i=0; i<length; i++){
            _day = mapMemberToken_Days[msg.sender][_lpToken][i];
            
            value = value.add(_withdrawShare(_lpToken, _day, msg.sender)); 
        }

        _updateEmission(); 
        
        return value;
    }
    
    function withdrawShare(address _lpToken, uint _day) external nonReentrant returns (uint value) {
        require(currentDay > 0, "Buring LP Tokens is not started.");
        require(isRegisteredLPToken(_lpToken) == true, "LP token address is wrong");

        uint memberUnits = mapTokenDay_MemberUnits[_lpToken][_day][msg.sender];
        require(memberUnits > 0, "No LP deposits.");

        value = _withdrawShare(_lpToken, _day, msg.sender);  

        _updateEmission();                         
    }

    // Internal - withdraw function
    function _withdrawShare (address _lpToken, uint _day, address _account) private returns (uint value) {
        if (_day < currentDay || (_day == currentDay && block.timestamp > nextDay)) 
        {
            value = _processWithdrawal(_lpToken, _day, _account);
        }
        
        return value;
    }

    // Internal - Withdrawal function
    function _processWithdrawal (address _lpToken, uint _day, address _account) private returns (uint value) {
        uint memberUnits = mapTokenDay_MemberUnits[_lpToken][_day][_account];
        if (memberUnits == 0) { 
            value = 0;
        } else {
            value = getEmissionShare(_lpToken, _day, _account);
            mapTokenDay_MemberUnits[_lpToken][_day][_account] = 0;

            totalWithdrawed = totalWithdrawed.add(value);

            ERC20(address(this)).transfer(_account, value);

            emit Withdrawal(_account, _lpToken, _day, value);
        }
        return value;
    }

    // Get emission Share function
    function getEmissionShare(address _lpToken, uint _day, address _account) public view returns (uint value) {
        require(currentDay > 0, "Buring LP Tokens is not started.");
        require(_account != address(0), "Account is the zero address");
        require(isRegisteredLPToken(_lpToken) == true, "LP token address is wrong");

        uint memberUnits = mapTokenDay_MemberUnits[_lpToken][_day][_account];
        if (memberUnits == 0) {
            return 0;
        } else {
            uint totalUnits = mapTokenDay_Units[_lpToken][_day];
            uint currentEmission = mapTokenDay_Emission[_lpToken][_day];
            uint balance = balanceOf(address(this));

            if (currentEmission > balance)
            {
                currentEmission = balance; 
            }

            value = currentEmission.mul(memberUnits).div(totalUnits);
            return  value;                            
        }
    }

    //======================================EMISSION========================================//
    // Internal - Update emission function
    function _updateEmission() private {
        if (block.timestamp >= nextDay) {
            // if no user burnt LP tokens at the current day, emission will go back.
            uint length = arrLpTokens.length;
            for (uint8 i=0; i<length; i++) {
                if (arrLpTokens[i] == address(0)) {
                    continue;
                }

                uint totalUnits = mapTokenDay_Units[arrLpTokens[i]][currentDay];
                if (totalUnits == 0)
                    totalEmitted = totalEmitted.sub(mapTokenDay_Emission[arrLpTokens[i]][currentDay]);
            }

            currentDay = currentDay.add(1);
            nextDay = block.timestamp.add(lockedPeriod);       
            
            uint[] memory emmisions = getCurrentDayEmission();

            for (uint8 i=0; i<emmisions.length; i++)
            {
                mapTokenDay_Emission[arrLpTokens[i]][currentDay] = emmisions[i];
                totalEmitted = totalEmitted.add(emmisions[i]);
            }
           
            emit NewDay(currentDay, nextDay); 
        }
    }

    // Calculate Next Day emission
    function getCurrentDayEmission() public view returns (uint[] memory emissions) {
        require(currentDay > 0, "Buring LP Tokens is not started.");

        uint remains = totalSupply().sub(initialSupply.add(totalEmitted));
        
        uint length = arrLpTokens.length;
        
        emissions = new uint[](length);
        for (uint8 i=0; i<length; i++) {
            if (arrLpTokens[i] == address(0)) {
                emissions[i] = 0;
                continue;
            }
                
            emissions[i] = remains.mul(emissionRates[i]).div(10000);
        }

        return emissions;
    }

    //====================================== Dividend Distribute ========================================//

    /**
     * @notice Get the total amount of dividend distributed
     */ 
    function getTotalDividendsDistributed(bool nftContract) external view returns (uint256) {
        if (nftContract)
            return dividendNFTTracker.totalDividendsDistributed();
        else 
            return dividendTracker.totalDividendsDistributed();
    }

    /**
     * @notice View the amount of dividend in wei that an address can withdraw.
     */ 
    function withdrawableDividendOf(address account, bool nftContract) public view returns(uint256) {
        if (nftContract)
            return dividendNFTTracker.withdrawableDividendOf(account);
        else 
            return dividendTracker.withdrawableDividendOf(account);
    }

    /**
     * @notice View the amount of dividend in wei that an address has earned in total.
     */ 
    function withdrawnDividendOf(address account, bool nftContract) public view returns(uint256) {
        if (nftContract)
            return dividendNFTTracker.withdrawnDividendOf(account);
        else 
            return dividendTracker.withdrawnDividendOf(account);
    }

    /**
     * @notice Get the dividend token balancer in account
     */ 
    function dividendTokenBalanceOf(address account, bool nftContract) public view returns (uint256) {
        if (nftContract)
            return dividendNFTTracker.balanceOf(account);
        else 
            return dividendTracker.balanceOf(account);
    }

    /**
     * @notice Exclude from receiving dividends
     */ 
    function excludeFromDividends(address account, bool nftContract) external onlyOwner{
        if (nftContract)
            dividendNFTTracker.excludeFromDividends(account);
        else 
            dividendTracker.excludeFromDividends(account);
    }

    /**
     * @notice Get the dividend infor for account
     */ 
    function getAccountDividendsInfo(address account, bool nftContract)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if (nftContract)
            return dividendNFTTracker.getAccount(account);
        else 
            return dividendTracker.getAccount(account);
    }

    /**
     * @notice Get the indexed dividend infor
     */ 
    function getAccountDividendsInfoAtIndex(uint256 index, bool nftContract)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if (nftContract)
            return dividendNFTTracker.getAccountAtIndex(index);
        else 
            return dividendTracker.getAccountAtIndex(index);
    }

    /**
     * @notice Withdraws the token distributed to all token holders
     */
    function processDividendTracker(bool nftContract) external {
        if (nftContract) {
            (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendNFTTracker.process();
            emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, 0, tx.origin);
        }
        else {
            (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process();
            emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, 0, tx.origin);
        }
    }

    /**
     * @notice Withdraws the token distributed to the sender.
     */
    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false, true);
    }

    /**
     * @notice Withdraws the token distributed to the sender.
     */
    function claimFromFantoonNFT(address account) external onlyOperator{
        dividendNFTTracker.processAccount(payable(account), false, false);
    }

    /**
     * @notice Get the last processed info in dividend tracker
     */
    function getLastProcessedIndex(bool nftContract) external view returns(uint256) {
        if (nftContract)
            return dividendNFTTracker.getLastProcessedIndex();
        else 
            return dividendTracker.getLastProcessedIndex();
    }

    /**
     * @notice Get the number of dividend token holders
     */
    function getNumberOfDividendTokenHolders(bool nftContract) external view returns(uint256) {
        if (nftContract)
            return dividendNFTTracker.getNumberOfTokenHolders();
        else 
            return dividendTracker.getNumberOfTokenHolders();
    }


    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        try dividendNFTTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendNFTTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
            try dividendTracker.process() returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, 0, tx.origin);
            }
            catch {
            }

            try dividendNFTTracker.process() returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, 0, tx.origin);
            }
            catch {
            }
        }
    }

    /**
     * @notice Send transaction fee to dividend trancer.
     */
    function sendDividends(uint256 _amount, bool nftContract) public onlyOperator {
        if (nftContract)
            dividendNFTTracker.distributeDividends(_amount);
        else 
            dividendTracker.distributeDividends(_amount);

        emit SendDividends(_amount);
    }
}

contract DiamondDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("Diamond_Dividend_Tracker", "DDT") {
        claimWait = 1 hours;
        minimumTokenBalanceForDividends = 1_000 * (10**18);
    }

    function setMinimumTokenBalanceForDividends(uint256 _minimumTokenBalanceForDividends) 
        public onlyOwner {
        minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends;
    }

    receive() external payable {
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "Diamond_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "Diamond_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main MMR contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "Diamond_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Diamond_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;

                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(_isContract(account)) {
            return;
        }

        if(excludedFromDividends[account]) {
            return;
        }

        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }
    }

    function process() public pure returns (uint256, uint256, uint256) {

        return (0, 0, 0);
/*
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);*/
    }

    function processAccount(address payable account, bool automatic, bool transferRewards) 
        public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account, transferRewards);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

import "./owner/Operator.sol";

contract Bond is ERC20Burnable, Operator {

    constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) {}

    /**
     * @notice Operator mints bonds to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of bonds to mint to
     * @return whether the process has been done
     */
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

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
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() internal {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
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
     * - `to` cannot be the zero address.
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./lib/Babylonian.sol";
import "./owner/Operator.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IMasonry.sol";

contract Treasury is ContractGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========= CONSTANT VARIABLES ======== */

    uint256 public constant PERIOD = 6 hours;

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;

    // flags
    bool public initialized = false;

    // epoch
    uint256 public startTime;
    uint256 public epoch = 0;
    uint256 public epochSupplyContractionLeft = 0;

    // exclusions from total supply
    address[] public excludedFromTotalSupply;

    // core components
    address public pToken;
    address public bond;
    address public pae;

    address public masonry;
    address public oracle;

    // price
    uint256 public pTokenPriceOne;
    uint256 public pTokenPriceCeiling;

    uint256 public seigniorageSaved;

    uint256[] public supplyTiers;
    uint256[] public maxExpansionTiers;

    uint256 public maxSupplyExpansionPercent;
    uint256 public bondDepletionFloorPercent;
    uint256 public seigniorageExpansionFloorPercent;
    uint256 public maxSupplyContractionPercent;
    uint256 public maxDebtRatioPercent;

    // 28 first epochs (1 week) with 4.5% expansion regardless of PEG price
    uint256 public bootstrapEpochs;
    uint256 public bootstrapSupplyExpansionPercent;

    /* =================== Added variables =================== */
    uint256 public previousEpochPegPrice;
    uint256 public maxDiscountRate; // when purchasing bond
    uint256 public maxPremiumRate; // when redeeming bond
    uint256 public discountPercent;
    uint256 public premiumThreshold;
    uint256 public premiumPercent;
    uint256 public mintingFactorForPayingDebt; // print extra PEG during debt phase

    address public daoFund;
    uint256 public daoFundSharedPercent;

    address public devFund;
    uint256 public devFundSharedPercent;

    /* =================== Events =================== */

    event Initialized(address indexed executor, uint256 at);
    event BurnedBonds(address indexed from, uint256 bondAmount);
    event RedeemedBonds(address indexed from, uint256 pegAmount, uint256 bondAmount);
    event BoughtBonds(address indexed from, uint256 pegAmount, uint256 bondAmount);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event MasonryFunded(uint256 timestamp, uint256 seigniorage);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
    event DevFundFunded(uint256 timestamp, uint256 seigniorage);

    /* =================== Modifier =================== */

    modifier onlyOperator() {
        require(operator == msg.sender, "Treasury: caller is not the operator");
        _;
    }

    modifier checkCondition {
        require(now >= startTime, "Treasury: not started yet");

        _;
    }

    modifier checkEpoch {
        require(now >= nextEpochPoint(), "Treasury: not opened yet");

        _;

        epoch = epoch.add(1);
        epochSupplyContractionLeft = (getPegPrice() > pTokenPriceCeiling) ? 0 : getPegCirculatingSupply().mul(maxSupplyContractionPercent).div(10000);
    }

    modifier checkOperator {
        require(
            IBasisAsset(pToken).operator() == address(this) &&
                IBasisAsset(bond).operator() == address(this) &&
                Operator(masonry).operator() == address(this),
            "Treasury: need more permission"
        );

        _;
    }

    modifier notInitialized {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    // oracle
    function getPegPrice() public view returns (uint256 pegPrice) {
        try IOracle(oracle).consult(pToken, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult Peg price from the oracle");
        }
    }

    function getPegUpdatedPrice() public view returns (uint256 _pegPrice) {
        try IOracle(oracle).twap(pToken, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult Peg price from the oracle");
        }
    }

    // budget
    function getReserve() public view returns (uint256) {
        return seigniorageSaved;
    }

    function getBurnablePegLeft() public view returns (uint256 _burnablePegLeft) {
        uint256 _pegPrice = getPegPrice();
        if (_pegPrice <= pTokenPriceOne) {
            uint256 _pegSupply = getPegCirculatingSupply();
            uint256 _bondMaxSupply = _pegSupply.mul(maxDebtRatioPercent).div(10000);
            uint256 _bondSupply = IERC20(bond).totalSupply();
            if (_bondMaxSupply > _bondSupply) {
                uint256 _maxMintableBond = _bondMaxSupply.sub(_bondSupply);
                uint256 _maxBurnablePeg = _maxMintableBond.mul(_pegPrice).div(1e18);
                _burnablePegLeft = Math.min(epochSupplyContractionLeft, _maxBurnablePeg);
            }
        }
    }

    function getRedeemableBonds() public view returns (uint256 _redeemableBonds) {
        uint256 _pegPrice = getPegPrice();
        if (_pegPrice > pTokenPriceCeiling) {
            uint256 _totalPeg = IERC20(pToken).balanceOf(address(this));
            uint256 _rate = getBondPremiumRate();
            if (_rate > 0) {
                _redeemableBonds = _totalPeg.mul(1e18).div(_rate);
            }
        }
    }

    function getBondDiscountRate() public view returns (uint256 _rate) {
        uint256 _pegPrice = getPegPrice();
        if (_pegPrice <= pTokenPriceOne) {
            if (discountPercent == 0) {
                // no discount
                _rate = pTokenPriceOne;
            } else {
                uint256 _bondAmount = pTokenPriceOne.mul(1e18).div(_pegPrice); // to burn 1 PEG
                uint256 _discountAmount = _bondAmount.sub(pTokenPriceOne).mul(discountPercent).div(10000);
                _rate = pTokenPriceOne.add(_discountAmount);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    function getBondPremiumRate() public view returns (uint256 _rate) {
        uint256 _pegPrice = getPegPrice();
        if (_pegPrice > pTokenPriceCeiling) {
            uint256 _pegPricePremiumThreshold = pTokenPriceOne.mul(premiumThreshold).div(100);
            if (_pegPrice >= _pegPricePremiumThreshold) {
                //Price > 1.10
                uint256 _premiumAmount = _pegPrice.sub(pTokenPriceOne).mul(premiumPercent).div(10000);
                _rate = pTokenPriceOne.add(_premiumAmount);
                if (maxPremiumRate > 0 && _rate > maxPremiumRate) {
                    _rate = maxPremiumRate;
                }
            } else {
                // no premium bonus
                _rate = pTokenPriceOne;
            }
        }
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        address _peg,
        address _bond,
        address _pae,
        address _oracle,
        address _masonry,
        address _genesisPool,
        uint256 _startTime
    ) public notInitialized {
        pToken = _peg;
        bond = _bond;
        pae = _pae;
        oracle = _oracle;
        masonry = _masonry;
        startTime = _startTime;

        pTokenPriceOne = 10**18;
        pTokenPriceCeiling = pTokenPriceOne.mul(101).div(100);

        // exclude contracts from total supply
        excludedFromTotalSupply.push(_genesisPool);

        // Dynamic max expansion percent
        supplyTiers = [0 ether, 500000 ether, 1000000 ether, 1500000 ether, 2000000 ether, 5000000 ether, 10000000 ether, 20000000 ether, 50000000 ether];
        maxExpansionTiers = [450, 400, 350, 300, 250, 200, 150, 125, 100];

        maxSupplyExpansionPercent = 400; // Upto 4.0% supply for expansion

        bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor
        seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for masonry
        maxSupplyContractionPercent = 300; // Upto 3.0% supply for contraction (to burn PEG and mint Bond)
        maxDebtRatioPercent = 3500; // Upto 35% supply of Bond to purchase

        premiumThreshold = 110;
        premiumPercent = 7000;

        // First 28 epochs with 4.5% expansion
        bootstrapEpochs = 28;
        bootstrapSupplyExpansionPercent = 450;

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20(pToken).balanceOf(address(this));

        initialized = true;
        operator = msg.sender;
        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setMasonry(address _masonry) external onlyOperator {
        masonry = _masonry;
    }

    function setPegOracle(address _oracle) external onlyOperator {
        oracle = _oracle;
    }

    function setPegPriceCeiling(uint256 _pegPriceCeiling) external onlyOperator {
        require(_pegPriceCeiling >= pTokenPriceOne && _pegPriceCeiling <= pTokenPriceOne.mul(120).div(100), "out of range"); // [$1.0, $1.2]
        pTokenPriceCeiling = _pegPriceCeiling;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent) external onlyOperator {
        require(_maxSupplyExpansionPercent >= 10 && _maxSupplyExpansionPercent <= 1000, "_maxSupplyExpansionPercent: out of range"); // [0.1%, 10%]
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }

    function setSupplyTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 9, "Index has to be lower than count of tiers");
        if (_index > 0) {
            require(_value > supplyTiers[_index - 1]);
        }
        if (_index < 8) {
            require(_value < supplyTiers[_index + 1]);
        }
        supplyTiers[_index] = _value;
        return true;
    }

    function setMaxExpansionTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 9, "Index has to be lower than count of tiers");
        require(_value >= 10 && _value <= 1000, "_value: out of range"); // [0.1%, 10%]
        maxExpansionTiers[_index] = _value;
        return true;
    }

    function setBondDepletionFloorPercent(uint256 _bondDepletionFloorPercent) external onlyOperator {
        require(_bondDepletionFloorPercent >= 500 && _bondDepletionFloorPercent <= 10000, "out of range"); // [5%, 100%]
        bondDepletionFloorPercent = _bondDepletionFloorPercent;
    }

    function setMaxSupplyContractionPercent(uint256 _maxSupplyContractionPercent) external onlyOperator {
        require(_maxSupplyContractionPercent >= 100 && _maxSupplyContractionPercent <= 1500, "out of range"); // [0.1%, 15%]
        maxSupplyContractionPercent = _maxSupplyContractionPercent;
    }

    function setMaxDebtRatioPercent(uint256 _maxDebtRatioPercent) external onlyOperator {
        require(_maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= 10000, "out of range"); // [10%, 100%]
        maxDebtRatioPercent = _maxDebtRatioPercent;
    }

    function setBootstrap(uint256 _bootstrapEpochs, uint256 _bootstrapSupplyExpansionPercent) external onlyOperator {
        require(_bootstrapEpochs <= 120, "_bootstrapEpochs: out of range"); // <= 1 month
        require(_bootstrapSupplyExpansionPercent >= 100 && _bootstrapSupplyExpansionPercent <= 1000, "_bootstrapSupplyExpansionPercent: out of range"); // [1%, 10%]
        bootstrapEpochs = _bootstrapEpochs;
        bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
    }

    function setExtraFunds(
        address _daoFund,
        uint256 _daoFundSharedPercent,
        address _devFund,
        uint256 _devFundSharedPercent
    ) external onlyOperator {
        require(_daoFund != address(0), "zero");
        require(_daoFundSharedPercent <= 3000, "out of range"); // <= 30%
        require(_devFund != address(0), "zero");
        require(_devFundSharedPercent <= 1000, "out of range"); // <= 10%
        daoFund = _daoFund;
        daoFundSharedPercent = _daoFundSharedPercent;
        devFund = _devFund;
        devFundSharedPercent = _devFundSharedPercent;
    }

    function setMaxDiscountRate(uint256 _maxDiscountRate) external onlyOperator {
        maxDiscountRate = _maxDiscountRate;
    }

    function setMaxPremiumRate(uint256 _maxPremiumRate) external onlyOperator {
        maxPremiumRate = _maxPremiumRate;
    }

    function setDiscountPercent(uint256 _discountPercent) external onlyOperator {
        require(_discountPercent <= 20000, "_discountPercent is over 200%");
        discountPercent = _discountPercent;
    }

    function setPremiumThreshold(uint256 _premiumThreshold) external onlyOperator {
        require(_premiumThreshold >= pTokenPriceCeiling, "_premiumThreshold exceeds pegPriceCeiling");
        require(_premiumThreshold <= 150, "_premiumThreshold is higher than 1.5");
        premiumThreshold = _premiumThreshold;
    }

    function setPremiumPercent(uint256 _premiumPercent) external onlyOperator {
        require(_premiumPercent <= 20000, "_premiumPercent is over 200%");
        premiumPercent = _premiumPercent;
    }

    function setMintingFactorForPayingDebt(uint256 _mintingFactorForPayingDebt) external onlyOperator {
        require(_mintingFactorForPayingDebt >= 10000 && _mintingFactorForPayingDebt <= 20000, "_mintingFactorForPayingDebt: out of range"); // [100%, 200%]
        mintingFactorForPayingDebt = _mintingFactorForPayingDebt;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updatePegPrice() internal {
        try IOracle(oracle).update() {} catch {}
    }

    function getPegCirculatingSupply() public view returns (uint256) {
        IERC20 pegErc20 = IERC20(pToken);
        uint256 totalSupply = pegErc20.totalSupply();
        uint256 balanceExcluded = 0;
        for (uint8 entryId = 0; entryId < excludedFromTotalSupply.length; ++entryId) {
            balanceExcluded = balanceExcluded.add(pegErc20.balanceOf(excludedFromTotalSupply[entryId]));
        }
        return totalSupply.sub(balanceExcluded);
    }

    function buyBonds(uint256 _pegAmount, uint256 targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_pegAmount > 0, "Treasury: cannot purchase bonds with zero amount");

        uint256 pegPrice = getPegPrice();
        require(pegPrice == targetPrice, "Treasury: Peg price moved");
        require(
            pegPrice < pTokenPriceOne, // price < $1
            "Treasury: pegPrice not eligible for bond purchase"
        );

        require(_pegAmount <= epochSupplyContractionLeft, "Treasury: not enough bond left to purchase");

        uint256 _rate = getBondDiscountRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _bondAmount = _pegAmount.mul(_rate).div(1e18);
        uint256 pegSupply = getPegCirculatingSupply();
        uint256 newBondSupply = IERC20(bond).totalSupply().add(_bondAmount);
        require(newBondSupply <= pegSupply.mul(maxDebtRatioPercent).div(10000), "over max debt ratio");

        IBasisAsset(pToken).burnFrom(msg.sender, _pegAmount);
        IBasisAsset(bond).mint(msg.sender, _bondAmount);

        epochSupplyContractionLeft = epochSupplyContractionLeft.sub(_pegAmount);
        _updatePegPrice();

        emit BoughtBonds(msg.sender, _pegAmount, _bondAmount);
    }

    function redeemBonds(uint256 _bondAmount, uint256 targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_bondAmount > 0, "Treasury: cannot redeem bonds with zero amount");

        uint256 pegPrice = getPegPrice();
        require(pegPrice == targetPrice, "Treasury: Peg price moved");
        require(
            pegPrice > pTokenPriceCeiling, // price > $1.01
            "Treasury: pegPrice not eligible for bond purchase"
        );

        uint256 _rate = getBondPremiumRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _pegAmount = _bondAmount.mul(_rate).div(1e18);
        require(IERC20(pToken).balanceOf(address(this)) >= _pegAmount, "Treasury: treasury has no more budget");

        seigniorageSaved = seigniorageSaved.sub(Math.min(seigniorageSaved, _pegAmount));

        IBasisAsset(bond).burnFrom(msg.sender, _bondAmount);
        IERC20(pToken).safeTransfer(msg.sender, _pegAmount);

        _updatePegPrice();

        emit RedeemedBonds(msg.sender, _pegAmount, _bondAmount);
    }

    function _sendToMasonry(uint256 _amount) internal {
        IBasisAsset(pToken).mint(address(this), _amount);

        uint256 _daoFundSharedAmount = 0;
        if (daoFundSharedPercent > 0) {
            _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(10000);
            IERC20(pToken).transfer(daoFund, _daoFundSharedAmount);
            emit DaoFundFunded(now, _daoFundSharedAmount);
        }

        uint256 _devFundSharedAmount = 0;
        if (devFundSharedPercent > 0) {
            _devFundSharedAmount = _amount.mul(devFundSharedPercent).div(10000);
            IERC20(pToken).transfer(devFund, _devFundSharedAmount);
            emit DevFundFunded(now, _devFundSharedAmount);
        }

        _amount = _amount.sub(_daoFundSharedAmount).sub(_devFundSharedAmount);

        IERC20(pToken).safeApprove(masonry, 0);
        IERC20(pToken).safeApprove(masonry, _amount);
        IMasonry(masonry).allocateSeigniorage(_amount);
        emit MasonryFunded(now, _amount);
    }

    function _calculateMaxSupplyExpansionPercent(uint256 _pegSupply) internal returns (uint256) {
        for (uint8 tierId = 8; tierId >= 0; --tierId) {
            if (_pegSupply >= supplyTiers[tierId]) {
                maxSupplyExpansionPercent = maxExpansionTiers[tierId];
                break;
            }
        }
        return maxSupplyExpansionPercent;
    }

    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
        _updatePegPrice();
        previousEpochPegPrice = getPegPrice();
        uint256 pegSupply = getPegCirculatingSupply().sub(seigniorageSaved);
        if (epoch < bootstrapEpochs) {
            // 28 first epochs with 4.5% expansion
            _sendToMasonry(pegSupply.mul(bootstrapSupplyExpansionPercent).div(10000));
        } else {
            if (previousEpochPegPrice > pTokenPriceCeiling) {
                // Expansion ($Peg Price > 1 $ETH): there is some seigniorage to be allocated
                uint256 bondSupply = IERC20(bond).totalSupply();
                uint256 _percentage = previousEpochPegPrice.sub(pTokenPriceOne);
                uint256 _savedForBond;
                uint256 _savedForMasonry;
                uint256 _mse = _calculateMaxSupplyExpansionPercent(pegSupply).mul(1e14);
                if (_percentage > _mse) {
                    _percentage = _mse;
                }
                if (seigniorageSaved >= bondSupply.mul(bondDepletionFloorPercent).div(10000)) {
                    // saved enough to pay debt, mint as usual rate
                    _savedForMasonry = pegSupply.mul(_percentage).div(1e18);
                } else {
                    // have not saved enough to pay debt, mint more
                    uint256 _seigniorage = pegSupply.mul(_percentage).div(1e18);
                    _savedForMasonry = _seigniorage.mul(seigniorageExpansionFloorPercent).div(10000);
                    _savedForBond = _seigniorage.sub(_savedForMasonry);
                    if (mintingFactorForPayingDebt > 0) {
                        _savedForBond = _savedForBond.mul(mintingFactorForPayingDebt).div(10000);
                    }
                }
                if (_savedForMasonry > 0) {
                    _sendToMasonry(_savedForMasonry);
                }
                if (_savedForBond > 0) {
                    seigniorageSaved = seigniorageSaved.add(_savedForBond);
                    IBasisAsset(pToken).mint(address(this), _savedForBond);
                    emit TreasuryFunded(now, _savedForBond);
                }
            }
        }
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(pToken), "pToken");
        require(address(_token) != address(bond), "bond");
        require(address(_token) != address(pae), "pae");
        _token.safeTransfer(_to, _amount);
    }

    function masonrySetOperator(address _operator) external onlyOperator {
        IMasonry(masonry).setOperator(_operator);
    }

    function masonrySetLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external onlyOperator {
        IMasonry(masonry).setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs);
    }

    function masonryAllocateSeigniorage(uint256 amount) external onlyOperator {
        IMasonry(masonry).allocateSeigniorage(amount);
    }

    function masonryGovernanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        IMasonry(masonry).governanceRecoverUnsupported(_token, _amount, _to);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(!checkSameOriginReentranted(), "ContractGuard: one block, one function");
        require(!checkSameSenderReentranted(), "ContractGuard: one block, one function");

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IOracle {
    function update() external;

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMasonry {
    function balanceOf(address _mason) external view returns (uint256);

    function earned(address _mason) external view returns (uint256);

    function canWithdraw(address _mason) external view returns (bool);

    function canClaimReward(address _mason) external view returns (bool);

    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getPegPrice() external view returns (uint256);

    function setOperator(address _operator) external;

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    function claimReward() external;

    function allocateSeigniorage(uint256 _amount) external;

    function governanceRecoverUnsupported(address _token, uint256 _amount, address _to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/IVaultBeefy.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IVaultYieldWolf.sol";
import "./interfaces/IMasonry.sol";

contract PaeBalances is Ownable {

  IMasonry[] public banks;
  IERC20 public pae;
  IUniswapV2Pair public paeLp;
  IRewardPool public paeRewardPool;
  IVaultBeefy public paeBeefyVault;
  IVaultYieldWolf public wolfVault;
  uint256[] public wolfBankPids;
  uint256 public wolfLpPid;
  uint256 public rewardPoolIndex = 1;
  bool public isToken0;

  constructor (
    IMasonry[] memory _banks,
    IRewardPool _paeRewardPool,
    IVaultBeefy _beefyVault,
    IVaultYieldWolf _wolfLpVault,
    uint256 _wolfLpPid,
    uint256[] memory _wolfBankPids
  ) public {
    banks = _banks;
    (address _paeLp,) = _paeRewardPool.poolInfo(rewardPoolIndex);
    paeLp = IUniswapV2Pair(_paeLp);
    paeRewardPool = _paeRewardPool;
    paeBeefyVault = _beefyVault;
    wolfVault = _wolfLpVault;
    wolfLpPid = _wolfLpPid;
    wolfBankPids = _wolfBankPids;

    pae = IERC20(_paeRewardPool.pae());
    if (paeLp.token0() == address(pae)) isToken0 = true;
    else if (paeLp.token1() == address(pae)) isToken0 = false;
    else revert("not PAE LP");
  }

  function balanceOf(address account) external view returns (uint256) {
    uint256 lpBalance = paeLp.balanceOf(account);
    (uint256 poolBalance,) = paeRewardPool.userInfo(rewardPoolIndex, account);
    lpBalance = lpBalance + poolBalance + balanceBeefyLP(account) + balanceWolfLP(account);
    uint balanceInLps = lpBalance * paePerLP() / 1e18;

    return balanceInLps + pae.balanceOf(account) + balanceOfBanks(account) + balanceWolfBank(account);
  }

  function balanceOfBanks(address account) public view returns (uint256) {
    uint256 bal;
    for (uint256 i; i < banks.length; i++) {
      bal += banks[i].balanceOf(account);
    }
    return bal;
  }

  function balanceBeefyLP(address account) public view returns (uint256) {
    if (address(paeBeefyVault) == address(0)) return 0;
    return paeBeefyVault.balanceOf(account) * paeBeefyVault.getPricePerFullShare() / 1e18;
  }

  function balanceWolfLP(address account) public view returns (uint256) {
    if (address(wolfVault) == address(0)) return 0;
    return wolfVault.stakedTokens(wolfLpPid, account);
  }

  function balanceWolfBank(address account) public view returns (uint256) {
    if (address(wolfVault) == address(0)) return 0;
    uint256 bal;
    for (uint256 i; i < wolfBankPids.length; i++) {
      bal += wolfVault.stakedTokens(wolfBankPids[i], account);
    }
    return bal;
  }

  function paePerLP() public view returns (uint256) {
    (uint256 reserveA, uint256 reserveB,) = paeLp.getReserves();
    uint256 paeBalance = isToken0 ? reserveA : reserveB;
    return paeBalance * 1e18 / paeLp.totalSupply();
  }

  function setBanks(IMasonry[] memory _banks) external onlyOwner {
    banks = _banks;
  }

  function setBeefyVault(IVaultBeefy _beefyVault) external onlyOwner {
    paeBeefyVault = _beefyVault;
  }

  function setYieldWolfVault(IVaultYieldWolf _wolfVault, uint256 _lpPid, uint256[] memory _bankPids) external onlyOwner {
    wolfVault = _wolfVault;
    wolfLpPid = _lpPid;
    wolfBankPids = _bankPids;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardPool {
  function pae() external view returns (address);
  function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
  function poolInfo(uint256 _pid) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVaultBeefy {
  function want() external view returns (address);
  function getPricePerFullShare() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVaultYieldWolf {
  function stakedTokens(uint256 _pid, address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IWETH.sol";

import './lib/Babylonian.sol';

contract Zap is Ownable {
  using SafeMath for uint;
  using SafeERC20 for IERC20;

  address public native;
  uint256 public constant minimumAmount = 1000;
  mapping(address => mapping(address => address)) private tokenBridgeForRouter;
  mapping(address => bool) public useNativeRouter;

  constructor(address _native) public {
    native = _native;
  }

  receive() external payable {}

  function zapInToken(address token, uint amount, IUniswapV2Pair pair, IUniswapV2Router router, address recipient) external {
    require(amount >= minimumAmount, 'Insignificant input amount');
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    _swapAndStake(router, pair, token, 0);
  }

  function zapIn(IUniswapV2Pair pair, IUniswapV2Router router, address recipient) external payable {
    require(msg.value >= minimumAmount, 'Insignificant input amount');
    IWETH(native).deposit{value: msg.value}();
    _swapAndStake(router, pair, native, 0);
  }

  function _swapAndStake(IUniswapV2Router router, IUniswapV2Pair pair, address tokenIn, uint256 tokenAmountOutMin) private {
    (uint256 reserveA, uint256 reserveB,) = pair.getReserves();
    require(reserveA > minimumAmount && reserveB > minimumAmount, 'Liquidity pair reserves too low');

    bool isInputA = pair.token0() == tokenIn;
    require(isInputA || pair.token1() == tokenIn, 'Input token not present in liquidity pair');

    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = isInputA ? pair.token1() : pair.token0();

    uint256 fullInvestment = IERC20(tokenIn).balanceOf(address(this));
    uint256 swapAmountIn;
    if (isInputA) {
      swapAmountIn = _getSwapAmount(router, fullInvestment, reserveA, reserveB);
    } else {
      swapAmountIn = _getSwapAmount(router, fullInvestment, reserveB, reserveA);
    }

    _approveTokenIfNeeded(path[0], address(router));
    uint256[] memory swapedAmounts = router.swapExactTokensForTokens(swapAmountIn, tokenAmountOutMin, path, address(this), block.timestamp);

    _approveTokenIfNeeded(path[1], address(router));
    (,, uint256 amountLiquidity) = router.addLiquidity(path[0], path[1], fullInvestment.sub(swapedAmounts[0]), swapedAmounts[1], 1, 1, address(this), block.timestamp);

    IERC20(address(pair)).safeTransfer(msg.sender, amountLiquidity);
    _returnAssets(path);
  }

  function _returnAssets(address[] memory tokens) private {
    uint256 balance;
    for (uint256 i; i < tokens.length; i++) {
      balance = IERC20(tokens[i]).balanceOf(address(this));
      if (balance > 0) {
        if (tokens[i] == native) {
          IWETH(native).withdraw(balance);
          (bool success,) = msg.sender.call{value: balance}(new bytes(0));
          require(success, 'ETH transfer failed');
        } else {
          IERC20(tokens[i]).safeTransfer(msg.sender, balance);
        }
      }
    }
  }

  function _getSwapAmount(IUniswapV2Router router, uint256 investmentA, uint256 reserveA, uint256 reserveB) private pure returns (uint256 swapAmount) {
    uint256 halfInvestment = investmentA / 2;
    uint256 nominator = router.getAmountOut(halfInvestment, reserveA, reserveB);
    uint256 denominator = router.quote(halfInvestment, reserveA.add(halfInvestment), reserveB.sub(nominator));
    swapAmount = investmentA.sub(Babylonian.sqrt(halfInvestment * halfInvestment * nominator / denominator));
  }

  function estimateZapInToken(address token, IUniswapV2Pair pair, IUniswapV2Router router, uint amt) public view returns (uint256, uint256) {
    return estimateSwap(router, pair, token, amt);
  }

  function estimateZapIn(IUniswapV2Pair pair, IUniswapV2Router router, uint amt) public view returns (uint256, uint256) {
    return estimateSwap(router, pair, native, amt);
  }

  function estimateSwap(IUniswapV2Router router, IUniswapV2Pair pair, address tokenIn, uint256 fullInvestmentIn) public view returns (uint256 sellAmount, uint256 otherAmount) {
    bool isInputA = pair.token0() == tokenIn;
    require(isInputA || pair.token1() == tokenIn, 'Input token not present in liquidity pair');

    (uint256 reserveA, uint256 reserveB,) = pair.getReserves();
    (reserveA, reserveB) = isInputA ? (reserveA, reserveB) : (reserveB, reserveA);

    if (isInputA) {
      sellAmount = _getSwapAmount(router, fullInvestmentIn, reserveA, reserveB);
      otherAmount = router.getAmountOut(sellAmount, reserveA, reserveB);
    } else {
      otherAmount = _getSwapAmount(router, fullInvestmentIn, reserveA, reserveB);
      sellAmount = router.getAmountOut(otherAmount, reserveA, reserveB);
    }
  }

  function _approveTokenIfNeeded(address token, address spender) private {
    if (IERC20(token).allowance(address(this), spender) == 0) {
      IERC20(token).safeApprove(spender, type(uint256).max);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForAVAX(uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to,uint256 deadline)
    external
    returns (uint256[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWETH {
  function deposit() external payable;
  function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./lib/Babylonian.sol";
import "./lib/FixedPoint.sol";
import "./lib/UniswapV2OracleLibrary.sol";
import "./utils/Epoch.sol";
import "./interfaces/IUniswapV2Pair.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract Oracle is Epoch {
    using FixedPoint for *;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // uniswap
    address public token0;
    address public token1;
    IUniswapV2Pair public pair;

    // oracle
    uint32 public blockTimestampLast;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IUniswapV2Pair _pair,
        uint256 _period,
        uint256 _startTime
    ) public Epoch(_period, _startTime, 0) {
        pair = _pair;
        token0 = pair.token0();
        token1 = pair.token1();
        price0CumulativeLast = pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "Oracle: NO_RESERVES"); // ensure that there's liquidity in the pair
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    /** @dev Updates 1-day EMA price from Uniswap.  */
    function update() external checkEpoch {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        if (timeElapsed == 0) {
            // prevent divided by zero
            return;
        }

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;

        emit Updated(price0Cumulative, price1Cumulative);
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut) {
        if (_token == token0) {
            amountOut = price0Average.mul(_amountIn).decode144();
        } else {
            require(_token == token1, "Oracle: INVALID_TOKEN");
            amountOut = price1Average.mul(_amountIn).decode144();
        }
    }

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut) {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (_token == token0) {
            _amountOut = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)).mul(_amountIn).decode144();
        } else if (_token == token1) {
            _amountOut = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)).mul(_amountIn).decode144();
        }
    }

    event Updated(uint256 price0CumulativeLast, uint256 price1CumulativeLast);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Babylonian.sol";

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = uint256(1) << RESOLUTION;
    uint256 private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z;
        require(y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./FixedPoint.sol";
import "../interfaces/IUniswapV2Pair.sol";

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

import '../owner/Operator.sol';

contract Epoch is Operator {
    using SafeMath for uint256;

    uint256 private period;
    uint256 private startTime;
    uint256 private lastEpochTime;
    uint256 private epoch;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        uint256 _period,
        uint256 _startTime,
        uint256 _startEpoch
    ) public {
        period = _period;
        startTime = _startTime;
        epoch = _startEpoch;
        lastEpochTime = startTime.sub(period);
    }

    /* ========== Modifier ========== */

    modifier checkStartTime {
        require(now >= startTime, 'Epoch: not started yet');

        _;
    }

    modifier checkEpoch {
        uint256 _nextEpochPoint = nextEpochPoint();
        if (now < _nextEpochPoint) {
            require(msg.sender == operator(), 'Epoch: only operator allowed for pre-epoch');
            _;
        } else {
            _;

            for (;;) {
                lastEpochTime = _nextEpochPoint;
                ++epoch;
                _nextEpochPoint = nextEpochPoint();
                if (now < _nextEpochPoint) break;
            }
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getCurrentEpoch() public view returns (uint256) {
        return epoch;
    }

    function getPeriod() public view returns (uint256) {
        return period;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function getLastEpochTime() public view returns (uint256) {
        return lastEpochTime;
    }

    function nextEpochPoint() public view returns (uint256) {
        return lastEpochTime.add(period);
    }

    /* ========== GOVERNANCE ========== */

    function setPeriod(uint256 _period) external onlyOperator {
        require(_period >= 1 hours && _period <= 48 hours, '_period: out of range');
        period = _period;
    }

    function setEpoch(uint256 _epoch) external onlyOperator {
        epoch = _epoch;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./utils/Epoch.sol";
import "./interfaces/ISolidlyV1Pair.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract OracleSolidlyOld is Epoch {

    // solidly
    address public token0;
    address public token1;
    ISolidlyV1Pair public pair;

    // oracle
    uint256 public blockTimestampLast;
    uint256 public reserve0CumulativeLast;
    uint256 public reserve1CumulativeLast;
    uint256 public reserve0Average;
    uint256 public reserve1Average;

    constructor(
        ISolidlyV1Pair _pair,
        uint256 _period,
        uint256 _startTime
    ) public Epoch(_period, _startTime, 0) {
        pair = _pair;
        token0 = pair.token0();
        token1 = pair.token1();
        reserve0CumulativeLast = pair.reserve0CumulativeLast();
        reserve1CumulativeLast = pair.reserve1CumulativeLast();
        uint256 reserve0;
        uint256 reserve1;
        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "Oracle: NO_RESERVES"); // ensure that there's liquidity in the pair
    }

    function update() external checkEpoch {
        (uint reserve0Cumulative, uint reserve1Cumulative, uint blockTimestamp) = pair.currentCumulativePrices();
        uint timeElapsed = blockTimestamp - blockTimestampLast;

        if (timeElapsed == 0) {
            // prevent divided by zero
            return;
        }

        reserve0Average = (reserve0Cumulative - reserve0CumulativeLast) / timeElapsed;
        reserve1Average = (reserve1Cumulative - reserve1CumulativeLast) / timeElapsed;

        reserve0CumulativeLast = reserve0Cumulative;
        reserve1CumulativeLast = reserve1Cumulative;
        blockTimestampLast = blockTimestamp;

        emit Updated(reserve0CumulativeLast, reserve1CumulativeLast);
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut) {
        if (_token == token0) {
            amountOut = uint144(_amountIn * reserve1Average / reserve0Average);
        } else {
            require(_token == token1, "Oracle: INVALID_TOKEN");
            amountOut = uint144(_amountIn * reserve0Average / reserve1Average);
        }
    }

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut) {
        (uint reserve0Cumulative, uint reserve1Cumulative, uint blockTimestamp) = pair.currentCumulativePrices();
        uint timeElapsed = blockTimestamp - blockTimestampLast;
        uint reserve0 = (reserve0Cumulative - reserve0CumulativeLast) / timeElapsed;
        uint reserve1 = (reserve1Cumulative - reserve1CumulativeLast) / timeElapsed;
        if (_token == token0) {
            _amountOut = uint144(_amountIn * reserve1 / reserve0);
        } else if (_token == token1) {
            _amountOut = uint144(_amountIn * reserve0 / reserve1);
        }
    }

    event Updated(uint256 reserve0CumulativeLast, uint256 reserve1CumulativeLast);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ISolidlyV1Pair {

  function token0() external view returns (address);
  function token1() external view returns (address);

  function reserve0CumulativeLast() external view returns (uint256);
  function reserve1CumulativeLast() external view returns (uint256);

  function currentCumulativePrices() external view returns (uint reserve0Cumulative, uint reserve1Cumulative, uint blockTimestamp);
  function getReserves() external view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);

  function current(address tokenIn, uint amountIn) external view returns (uint amountOut);

  // as per `current`, however allows user configured granularity, up to the full window size
  function quote(address tokenIn, uint amountIn, uint granularity) external view returns (uint amountOut);

  // returns a memory set of twap prices
  function prices(address tokenIn, uint amountIn, uint points) external view returns (uint[] memory);
  function sample(address tokenIn, uint amountIn, uint points, uint window) external view returns (uint[] memory);

  function observationLength() external view returns (uint);
  function lastObservation() external view returns (uint timestamp, uint reserve0Cumulative, uint reserve1Cumulative);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./utils/Epoch.sol";
import "./interfaces/ISolidlyV1Pair.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract OracleSolidly is Epoch {

    // solidly
    address public token0;
    address public token1;
    ISolidlyV1Pair public pair;

    // oracle
    uint256 public points;
    uint256 public price0;
    uint256 public price1;

    constructor(
        ISolidlyV1Pair _pair,
        uint256 _period,
        uint256 _startTime
    ) public Epoch(_period, _startTime, 0) {
        pair = _pair;
        token0 = pair.token0();
        token1 = pair.token1();
        points = _period / 1800;
        uint256 reserve0;
        uint256 reserve1;
        (reserve0, reserve1,) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "Oracle: NO_RESERVES"); // ensure that there's liquidity in the pair
    }

    function setPoints(uint _points) external onlyOperator {
        points = _points;
    }

    function update() external checkEpoch {
        uint granularity = pair.observationLength() - 1;
        if (granularity > points) granularity = points;
        price0 = pair.quote(token0, 1e18, granularity);
        price1 = pair.quote(token1, 1e18, granularity);
        emit Updated(price0, price1);
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut) {
        if (_token == token0) {
            amountOut = uint144(price0 * _amountIn / 1e18);
        } else {
            require(_token == token1, "Oracle: INVALID_TOKEN");
            amountOut = uint144(price1 * _amountIn / 1e18);
        }
    }

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut) {
        uint granularity = pair.observationLength() - 1;
        if (granularity > points) granularity = points;
        return uint144(pair.quote(_token, _amountIn, granularity));
    }

    event Updated(uint256 price0, uint256 price1);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract Timelock {
  using SafeMath for uint;

  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint indexed newDelay);
  event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
  event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
  event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

  uint public constant GRACE_PERIOD = 14 days;
  uint public constant MINIMUM_DELAY = 6 hours;
  uint public constant MAXIMUM_DELAY = 30 days;

  address public admin;
  address public pendingAdmin;
  uint public delay;

  mapping (bytes32 => bool) public queuedTransactions;


  constructor(address admin_, uint delay_) public {
    require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
    require(delay_ <= MAXIMUM_DELAY, "Timelock::constructor: Delay must not exceed maximum delay.");

    admin = admin_;
    delay = delay_;
  }

  receive() external payable { }

  function setDelay(uint delay_) public {
    require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
    require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
    require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
    delay = delay_;

    emit NewDelay(delay);
  }

  function acceptAdmin() public {
    require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
    admin = msg.sender;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address pendingAdmin_) public {
    require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
    pendingAdmin = pendingAdmin_;

    emit NewPendingAdmin(pendingAdmin);
  }

  function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
    require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
    require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = true;

    emit QueueTransaction(txHash, target, value, signature, data, eta);
    return txHash;
  }

  function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
    require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = false;

    emit CancelTransaction(txHash, target, value, signature, data, eta);
  }

  function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
    require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
    require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
    require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

    queuedTransactions[txHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) = target.call.value(value)(callData);
    require(success, "Timelock::executeTransaction: Transaction execution reverted.");

    emit ExecuteTransaction(txHash, target, value, signature, data, eta);

    return returnData;
  }

  function getBlockTimestamp() internal view returns (uint) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

import "./interfaces/IDistributor.sol";
import "./owner/Operator.sol";

contract Pae is ERC20Burnable, Operator {
    using SafeMath for uint256;

    uint256 public constant FARMING_POOL_REWARD_ALLOCATION = 850000 ether;
    uint256 public constant INIT_TREASURY_FUND_POOL_ALLOCATION = 10000 ether; // for initial marketing
    uint256 public constant TREASURY_FUND_POOL_ALLOCATION = 45000 ether;
    uint256 public constant DEV_FUND_POOL_ALLOCATION = 95000 ether;

    uint256 public constant VESTING_DURATION = 125 days;
    uint256 public startTime;
    uint256 public endTime;

    uint256 public treasuryFundRewardRate;
    uint256 public devFundRewardRate;

    address public treasuryFund;
    address public devFund;

    uint256 public treasuryFundLastClaimed;
    uint256 public devFundLastClaimed;
    bool public notifyDefFund = true;

    uint256 public farmingDistributed;

    constructor(uint256 _startTime, address _treasuryFund, address _devFund) public ERC20("Ripae", "PAE") {
        _mint(_treasuryFund, INIT_TREASURY_FUND_POOL_ALLOCATION);

        startTime = _startTime;
        endTime = startTime + VESTING_DURATION;

        treasuryFundLastClaimed = startTime;
        devFundLastClaimed = startTime;

        treasuryFundRewardRate = TREASURY_FUND_POOL_ALLOCATION.div(VESTING_DURATION);
        devFundRewardRate = DEV_FUND_POOL_ALLOCATION.div(VESTING_DURATION);

        require(_devFund != address(0), "Address cannot be 0");
        devFund = _devFund;

        require(_treasuryFund != address(0), "Address cannot be 0");
        treasuryFund = _treasuryFund;
    }

    function setTreasuryFund(address _treasuryFund) external {
        require(msg.sender == treasuryFund, "!treasury");
        treasuryFund = _treasuryFund;
    }

    function setDevFund(address _devFund) external {
        require(msg.sender == devFund, "!dev");
        require(_devFund != address(0), "zero");
        devFund = _devFund;
    }

    function setNotifyDevFund(bool _notifyDefFund) external onlyOperator {
        notifyDefFund = _notifyDefFund;
    }

    function unclaimedTreasuryFund() public view returns (uint256 _pending) {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (treasuryFundLastClaimed >= _now) return 0;
        _pending = _now.sub(treasuryFundLastClaimed).mul(treasuryFundRewardRate);
    }

    function unclaimedDevFund() public view returns (uint256 _pending) {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (devFundLastClaimed >= _now) return 0;
        _pending = _now.sub(devFundLastClaimed).mul(devFundRewardRate);
    }

    /**
     * @dev Claim pending rewards to treasury and dev fund
     */
    function claimRewards() external {
        uint256 _pending = unclaimedTreasuryFund();
        if (_pending > 0 && treasuryFund != address(0)) {
            _mint(treasuryFund, _pending);
            treasuryFundLastClaimed = block.timestamp;
        }
        _pending = unclaimedDevFund();
        if (_pending > 0 && devFund != address(0)) {
            _mint(devFund, _pending);
            devFundLastClaimed = block.timestamp;
            if (notifyDefFund) {
                IDistributor(devFund).distribute();
            }
        }
    }

    function distributeReward(address _farmingFund, uint256 _amount) external onlyOperator {
        farmingDistributed = farmingDistributed.add(_amount);
        require(farmingDistributed <= FARMING_POOL_REWARD_ALLOCATION, "!supply");
        require(_farmingFund != address(0), "!farmingFund");
        _mint(_farmingFund, _amount);
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        _token.transfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IDistributor {
    function distribute() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/ISolidlyRouter.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IDistributor.sol";

contract Sell is Ownable {

  IDistributor public devFund;
  address public source;
  IERC20 public pae;
  IERC20 public peg;
  IERC20 public native;
  IERC20 public usdc;
  IUniswapV2Router public router;
  ISolidlyRouter public solidRouter;
  IERC20 public psolid;
  IERC20 public solid;
  address[] public paeRoute;
  address[] public pegRoute;
  uint public pegAmount;
  uint public paeAmount;
  uint public psolidAmount;
  uint public minAmount = 1e17;

  mapping(address => bool) public admins;

  constructor(
    IDistributor _devFund, address _source,
    address _pae, address _peg, address _native, address _usdc, address _router,
    IERC20 _psolid, IERC20 _solid, ISolidlyRouter _solidRouter,
    uint256 _pegAmount, uint256 _paeAmount
  ) public {
    devFund = _devFund;
    source = _source;
    pae = IERC20(_pae);
    peg = IERC20(_peg);
    psolid = _psolid;
    solid = _solid;
    native = IERC20(_native);
    router = IUniswapV2Router(_router);
    solidRouter = _solidRouter;
    paeRoute = [_pae, _native, _usdc];
    pegRoute = [_peg, _native];
    pegAmount = _pegAmount;
    paeAmount = _paeAmount;
    psolidAmount = _pegAmount;

    pae.approve(_router, type(uint256).max);
    peg.approve(_router, type(uint256).max);
    native.approve(_router, type(uint256).max);
  }

  modifier onlyAdmin() {
    require(msg.sender == owner() || admins[msg.sender], "Must be admin or owner");
    _;
  }

  function updateAdmins(address[] memory _admins, bool[] memory isAdmin) external onlyOwner {
    for (uint i; i < _admins.length; i++) {
      admins[_admins[i]] = isAdmin[i];
    }
  }

  function amounts(uint256 _peg, uint256 _pae, uint256 _psolid) external onlyOwner {
    pegAmount = _peg;
    paeAmount = _pae;
    psolidAmount = _psolid;
  }

  function pf(uint256 _amount) external onlyAdmin {
    _sellPeg(_amount * 1e18);
  }

  function ps(uint256 _amount) external onlyAdmin {
    _sellSolid(_amount * 1e18);
  }

  function pa(uint256 _amount) external onlyAdmin {
    _sellPae(_amount * 1e18);
  }

  function pf() external {
    if (peg.balanceOf(address(devFund)) > minAmount || (address(psolid) != address(0) && psolid.balanceOf(address(devFund)) > minAmount)) {
      devFund.distribute();
    }
    bool sold;

    uint amount = peg.balanceOf(source) < pegAmount ? peg.balanceOf(source) : pegAmount;
    if (amount > 0) {
      _sellPeg(amount);
      sold = true;
    }

    if (address(psolid) != address(0)) {
      amount = psolid.balanceOf(source) < psolidAmount ? psolid.balanceOf(source) : psolidAmount;
      if (amount > 0) {
        _sellSolid(amount);
        sold = true;
      }
    }

    require(sold, "nothing");
  }

  function pa() external {
    uint256 amount = paeAmount;
    if (pae.balanceOf(source) < amount) {
      amount = pae.balanceOf(source);
    }
    if (amount > 0) {
      _sellPae(amount);
    }
  }

  function _sellPeg(uint256 _amount) internal {
    peg.transferFrom(source, address(this), _amount);
    router.swapExactTokensForTokens(peg.balanceOf(address(this)), 0, pegRoute, owner(), block.timestamp);
  }

  function _sellSolid(uint256 _amount) internal {
    psolid.transferFrom(source, address(this), _amount);
    ISolidlyRouter.route[] memory route = new ISolidlyRouter.route[](2);
    route[0] = ISolidlyRouter.route(address(psolid), address(solid), false);
    route[1] = ISolidlyRouter.route(address(solid), address(native), false);
    solidRouter.swapExactTokensForFTM(psolid.balanceOf(address(this)), 0, route, owner(), block.timestamp);
  }

  function _sellPae(uint256 _amount) internal {
    pae.transferFrom(source, address(this), _amount);
    router.swapExactTokensForTokens(pae.balanceOf(address(this)), 0, paeRoute, owner(), block.timestamp);
  }

  function setPf(address[] memory _pfRoute) external onlyOwner {
    pegRoute = _pfRoute;
  }

  function setPa(address[] memory _paRoute) external onlyOwner {
    paeRoute = _paRoute;
  }

  function reset(bool approve) external onlyOwner {
    if (approve) {
      pae.approve(address(router), type(uint256).max);
      peg.approve(address(router), type(uint256).max);
      if (address(psolid) != address(0)) {
        psolid.approve(address(solidRouter), type(uint256).max);
      }
      native.approve(address(router), type(uint256).max);
    } else {
      pae.approve(address(router), 0);
      peg.approve(address(router), 0);
      if (address(psolid) != address(0)) {
        psolid.approve(address(solidRouter), 0);
      }
      native.approve(address(router), 0);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ISolidlyRouter {

  struct route {
    address from;
    address to;
    bool stable;
  }

  function swapExactTokensForFTM(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline)
  external returns (uint[] memory amounts);

  function swapExactTokensForTokens(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline)
  external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IERC20.sol";

contract TreasuryBuyBacks is Ownable {

  address public treasuryFund;
  IERC20 public pae;
  IERC20 public peg;
  IERC20 public native;
  IERC20 public usdc;
  IUniswapV2Router public router;
  address[] public paeToUSD;
  address[] public paeToNative_;
  address[] public toNative;
  address[] public toUsdc;
  address[] public toPeg;

  mapping(address => bool) public admins;

  constructor(address _treasuryFund, address _pae, address _peg, address _native, address _usdc, address _router) public {
    treasuryFund = _treasuryFund;
    pae = IERC20(_pae);
    peg = IERC20(_peg);
    native = IERC20(_native);
    router = IUniswapV2Router(_router);
    paeToUSD = [_pae, _native, _usdc];
    paeToNative_ = [_pae, _native];
    toNative = [_peg, _native];
    toUsdc = [_peg, _native, _usdc];
    toPeg = [_native, _peg];

    pae.approve(_router, type(uint256).max);
    peg.approve(_router, type(uint256).max);
    native.approve(_router, type(uint256).max);
  }

  modifier onlyAdmin() {
    require(msg.sender == owner() || admins[msg.sender], "Must be admin or owner");
    _;
  }

  function updateAdmins(address[] memory _admins, bool[] memory isAdmin) external onlyOwner {
    for (uint i; i < _admins.length; i++) {
      admins[_admins[i]] = isAdmin[i];
    }
  }

  function sellToNative(uint256 _amount) external onlyAdmin {
    peg.transferFrom(treasuryFund, address(this), _amount * 1e18);
    router.swapExactTokensForTokens(peg.balanceOf(address(this)), 0, toNative, treasuryFund, block.timestamp);
  }

  function sellToUsdc(uint256 _amount) external onlyAdmin {
    peg.transferFrom(treasuryFund, address(this), _amount * 1e18);
    router.swapExactTokensForTokens(peg.balanceOf(address(this)), 0, toUsdc, treasuryFund, block.timestamp);
  }

  function nativeToPeg(uint256 _amount) external onlyAdmin {
    native.transferFrom(treasuryFund, address(this), _amount * 1e18);
    router.swapExactTokensForTokens(native.balanceOf(address(this)), 0, toPeg, treasuryFund, block.timestamp);
  }

  function paeToUsdc(uint256 _amount) external onlyAdmin {
    pae.transferFrom(treasuryFund, address(this), _amount * 1e18);
    router.swapExactTokensForTokens(pae.balanceOf(address(this)), 0, paeToUSD, treasuryFund, block.timestamp);
  }

  function paeToNative(uint256 _amount) external onlyAdmin {
    pae.transferFrom(treasuryFund, address(this), _amount * 1e18);
    router.swapExactTokensForTokens(pae.balanceOf(address(this)), 0, paeToNative_, treasuryFund, block.timestamp);
  }

  function reset(bool approve) external onlyOwner {
    if (approve) {
      pae.approve(address(router), type(uint256).max);
      peg.approve(address(router), type(uint256).max);
      native.approve(address(router), type(uint256).max);
    } else {
      pae.approve(address(router), 0);
      peg.approve(address(router), 0);
      native.approve(address(router), 0);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/ISolidlyRouter.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IDistributor.sol";

interface IPaeDevFund {
  function allocate(uint256 amount) external;
}

contract Sell_fantom is OwnableUpgradeable {

  address public source;
  address public devFund;
  IERC20 public pae;
  IERC20 public peg;
  IERC20 public native;
  IUniswapV2Router public router;
  ISolidlyRouter public solidRouter;
  IERC20 public psolid;
  address[] public paeRoute;
  address[] public pegRoute;
  uint public pegAmount;
  uint public paeAmount;
  uint public psolidAmount;
  uint public minAmount;

  function initialize() public initializer {
    source = 0x70D53D07fD8906a54f213d76c114b2A5C2Aa1e80;
    devFund = 0x9Fb5Ee9D3ACebCCa39F69d6A2aa60fd8eAfA88B6;
    pae = IERC20(0x8a41f13a4FaE75ca88B1ee726ee9D52B148b0498);
    peg = IERC20(0x112dF7E3b4B7Ab424F07319D4E92F41e6608c48B);
    native = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

    router = IUniswapV2Router(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    solidRouter = ISolidlyRouter(0xa38cd27185a464914D3046f0AB9d43356B34829D);

    psolid = IERC20(0xaEd2f586856567c532cd778F45133990bD570ca2);

    address _usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    paeRoute = [address(pae), address(native), _usdc];
    pegRoute = [address(peg), address(native)];

    pae.approve(address(router), type(uint256).max);
    peg.approve(address(router), type(uint256).max);
    native.approve(address(router), type(uint256).max);
    psolid.approve(address(solidRouter), type(uint256).max);

    pegAmount = 286 ether;
    paeAmount = 3.418890 ether;
    psolidAmount = 277 ether;
    minAmount = 1e17;

    __Ownable_init();
  }

  function upgrade() public {
    psolid = IERC20(0xaEd2f586856567c532cd778F45133990bD570ca2);
    psolid.approve(address(solidRouter), type(uint256).max);
  }

  function amounts(uint256 _peg, uint256 _pae, uint256 _psolid) external onlyOwner {
    pegAmount = _peg;
    paeAmount = _pae;
    psolidAmount = _psolid;
  }

  function pf(uint256 _amount) external onlyOwner {
    _sellPeg(_amount * 1e18);
  }

  function ps(uint256 _amount) external onlyOwner {
    _sellSolid(_amount * 1e18);
  }

  function pa(uint256 _amount) external onlyOwner {
    _sellPae(_amount * 1e18);
  }

  function pf() external {
    if (peg.balanceOf(devFund) > minAmount || psolid.balanceOf(devFund) > minAmount) {
      IDistributor(devFund).distribute();
    }
    bool sold;

    uint amount = peg.balanceOf(source) < pegAmount ? peg.balanceOf(source) : pegAmount;
    if (amount > minAmount) {
      _sellPeg(amount);
      sold = true;
    }

    amount = psolid.balanceOf(source) < psolidAmount ? psolid.balanceOf(source) : psolidAmount;
    if (amount > minAmount) {
      _sellSolid(amount);
      sold = true;
    }

    require(sold, "nothing");
  }

  function pa() external {
    if (pae.balanceOf(source) < paeAmount) {
      IPaeDevFund paeFund = IPaeDevFund(0x0087677FcCb6d1Ed0AF3d929ABe6E19d2e4B431B);
      paeFund.allocate(paeAmount * 50 / 1e18);
    }
    _sellPae(paeAmount);
  }

  function _sellPeg(uint256 _amount) internal {
    peg.transferFrom(source, address(this), _amount);
    router.swapExactTokensForETH(peg.balanceOf(address(this)), 0, pegRoute, owner(), block.timestamp);
  }

  function _sellSolid(uint256 _amount) internal {
    address solid = 0x888EF71766ca594DED1F0FA3AE64eD2941740A20;
    psolid.transferFrom(source, address(this), _amount);
    ISolidlyRouter.route[] memory route = new ISolidlyRouter.route[](2);
    route[0] = ISolidlyRouter.route(address(psolid), solid, false);
    route[1] = ISolidlyRouter.route(solid, address(native), false);
    solidRouter.swapExactTokensForFTM(psolid.balanceOf(address(this)), 0, route, owner(), block.timestamp);
  }

  function _sellPae(uint256 _amount) internal {
    pae.transferFrom(source, address(this), _amount);
    router.swapExactTokensForTokens(pae.balanceOf(address(this)), 0, paeRoute, owner(), block.timestamp);
  }

  function setPf(address[] memory _pfRoute) external onlyOwner {
    pegRoute = _pfRoute;
  }

  function setPa(address[] memory _paRoute) external onlyOwner {
    paeRoute = _paRoute;
  }

  function reset(bool approve) external onlyOwner {
    if (approve) {
      pae.approve(address(router), type(uint256).max);
      peg.approve(address(router), type(uint256).max);
      if (address(psolid) != address(0)) {
        psolid.approve(address(solidRouter), type(uint256).max);
      }
      native.approve(address(router), type(uint256).max);
    } else {
      pae.approve(address(router), 0);
      peg.approve(address(router), 0);
      if (address(psolid) != address(0)) {
        psolid.approve(address(solidRouter), 0);
      }
      native.approve(address(router), 0);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/ISolidlyRouter.sol";
import "./TestERC20.sol";

contract SolidlyRouter is ISolidlyRouter {

  function swapExactTokensForFTM(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline)
  external override returns (uint[] memory amounts) {

  }

  function swapExactTokensForTokens(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline)
  external override returns (uint[] memory amounts) {
    amountIn;
    amountOutMin;
    routes;
    deadline;

    tokenOut.transfer(to, amountOut);
    amounts = new uint[](2);
    amounts[0] = amountIn;
    amounts[1] = amountOut;
  }

  IERC20 tokenOut;
  uint amountOut;

  function setSwap(TestERC20 _tokenOut, uint _amountOut) external {
    _tokenOut.mint(address(this), _amountOut);
    tokenOut = _tokenOut;
    amountOut = _amountOut;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

contract TestERC20 is ERC20Burnable {
  constructor() public ERC20("Test", "TEST") {}

  function mint(address _to, uint _amount) external {
    _mint(_to, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "./owner/Operator.sol";

contract PegToken is ERC20Burnable, Operator {

    constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) {}

    /**
     * @notice Operator mints pToken to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of pToken to mint to
     * @return whether the process has been done
     */
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

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        _token.transfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract PaeRewardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // governance
    address public operator;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. PAEs to distribute per block.
        uint256 lastRewardTime; // Last time that PAEs distribution occurs.
        uint256 accPaePerShare; // Accumulated PAEs per share, times 1e18. See below.
        bool isStarted; // if lastRewardTime has passed
        uint256 depositFee; // deposit fee, x / 10000, 2% max
    }

    IERC20 public pae;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when PAE mining starts.
    uint256 public poolStartTime;

    // The time when PAE mining ends.
    uint256 public poolEndTime;

    uint256 public paePerSecond = 0.00028125 ether; // 4371 / (180 days * 24h * 60min * 60s)
    uint256 public runningTime = 180 days;
    uint256 public constant TOTAL_REWARDS = 4374 ether;

    uint256 constant MAX_DEPOSIT_FEE = 200; // 2%

    address public treasuryFund;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    constructor(
        address _pae,
        uint256 _poolStartTime,
        address _treasuryFund
    ) public {
        require(block.timestamp < _poolStartTime, "late");
        if (_pae != address(0)) pae = IERC20(_pae);
        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
        operator = msg.sender;
        treasuryFund = _treasuryFund;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "PaeRewardPool: caller is not the operator");
        _;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "PaeRewardPool: existing pool?");
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        uint256 _depositFee
    ) public onlyOperator {
        require(_depositFee <= MAX_DEPOSIT_FEE, "deposit fee too high");
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
        if (block.timestamp < poolStartTime) {
            // chef is sleeping
            if (_lastRewardTime == 0) {
                _lastRewardTime = poolStartTime;
            } else {
                if (_lastRewardTime < poolStartTime) {
                    _lastRewardTime = poolStartTime;
                }
            }
        } else {
            // chef is cooking
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted =
        (_lastRewardTime <= poolStartTime) ||
        (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
            token : _token,
            allocPoint : _allocPoint,
            lastRewardTime : _lastRewardTime,
            accPaePerShare : 0,
            isStarted : _isStarted,
            depositFee: _depositFee
            }));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's PAE allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint256 _depositFee) public onlyOperator {
        require(_depositFee <= MAX_DEPOSIT_FEE, "deposit fee too high");
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        pool.allocPoint = _allocPoint;
        pool.depositFee = _depositFee;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(paePerSecond);
            return poolEndTime.sub(_fromTime).mul(paePerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(paePerSecond);
            return _toTime.sub(_fromTime).mul(paePerSecond);
        }
    }

    // View function to see pending PAEs on frontend.
    function pendingPAE(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPaePerShare = pool.accPaePerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _paeReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accPaePerShare = accPaePerShare.add(_paeReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accPaePerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _paeReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accPaePerShare = pool.accPaePerShare.add(_paeReward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) public {
        deposit(msg.sender, _pid, _amount);
    }

    function deposit(address _to, uint256 _pid, uint256 _amount) public {
        address _from = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_to];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accPaePerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safePaeTransfer(_to, _pending);
                emit RewardPaid(_to, _pending);
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_from, address(this), _amount);
            uint256 depositFee = _amount.mul(pool.depositFee).div(10000);
            user.amount = user.amount.add(_amount.sub(depositFee));
            if (depositFee > 0) {
                pool.token.safeTransfer(treasuryFund, depositFee);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accPaePerShare).div(1e18);
        emit Deposit(_to, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accPaePerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safePaeTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accPaePerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe PAE transfer function, just in case if rounding error causes pool to not have enough PAEs.
    function safePaeTransfer(address _to, uint256 _amount) internal {
        uint256 _paeBal = pae.balanceOf(address(this));
        if (_paeBal > 0) {
            if (_amount > _paeBal) {
                pae.safeTransfer(_to, _paeBal);
            } else {
                pae.safeTransfer(_to, _amount);
            }
        }
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setTreasuryFund(address _treasuryFund) external {
        require(msg.sender == treasuryFund, "!treasury");
        treasuryFund = _treasuryFund;
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external onlyOperator {
        // do not allow to drain core token (PAE or lps)
        require(_token != pae, "pae");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            require(_token != pool.token, "pool.token");
        }
        _token.safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface IERC20Burnable is IERC20 {
  function burn(uint256 amount) external;
}

contract MigratePeg is Ownable {
  using SafeERC20 for IERC20Burnable;

  IERC20Burnable public oldPeg;
  IERC20Burnable public newPeg;
  uint256 public percent = 100;

  constructor (IERC20Burnable _oldPeg, IERC20Burnable _newPeg) public {
    oldPeg = _oldPeg;
    newPeg = _newPeg;
  }

  function swap() external {
    uint256 bal = oldPeg.balanceOf(msg.sender);
    swap(bal);
  }

  function swap(uint amount) public {
    oldPeg.safeTransferFrom(msg.sender, address(this), amount);
    oldPeg.burn(amount);
    newPeg.safeTransfer(msg.sender, amount * percent / 100);
  }

  function setPercent(uint256 _percent) external onlyOwner {
    require(percent >= 100, "!percent");
    percent = _percent;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IDistributor.sol";
import "./interfaces/IPae.sol";

contract DevFundPae is Ownable, IDistributor {

  struct Allocation {
    address account;
    uint256 points;
  }

  Allocation[] public allocations;
  uint256 public totalPoints;

  IPae public pae;
  address public treasuryFund;
  bool public lockDistribute = true;

  constructor(IPae _pae, address _treasuryFund, address[] memory accounts, uint256[] memory points) public {
    pae = _pae;
    treasuryFund = _treasuryFund;
    for (uint256 a = 0; a < accounts.length; a++) {
      allocations.push(Allocation({
      account : accounts[a],
      points : points[a]
      }));
      totalPoints += points[a];
    }
  }

  function distribute() override external {
    require(!lockDistribute, "lock");
  }

  function _setLock(bool _lock) internal {
    lockDistribute = _lock;
  }

  function setTreasuryFund(address _treasuryFund) external onlyOwner {
    treasuryFund = _treasuryFund;
  }

  function claim() external onlyOwner {
    _setLock(false);
    uint256 treasuryAmount = pae.unclaimedTreasuryFund();
    pae.setTreasuryFund(address(this));
    pae.claimRewards();
    pae.transfer(treasuryFund, treasuryAmount);
    _setLock(true);
  }

  function allocate(uint256 amount) external {
    if (msg.sender != owner()) {
      bool isAdmin;
      for (uint256 a; a < allocations.length; a++) {
        if (allocations[a].account == msg.sender) {
          isAdmin = true;
          break;
        }
      }
      require(isAdmin, "Must be admin or owner");
    }

    for (uint256 a; a < allocations.length; a++) {
      pae.transfer(allocations[a].account, amount * 1e18 * allocations[a].points / totalPoints);
    }
  }

  function addAllocation(address account, uint256 points) external onlyOwner {
    allocations.push(Allocation({
    account: account,
    points: points
    }));
    totalPoints += points;
  }

  function removeAllocation(address account) external onlyOwner {
    for (uint256 a = 0; a < allocations.length; a++) {
      if (allocations[a].account == account) {
        totalPoints -= allocations[a].points;
        allocations[a] = allocations[allocations.length - 1];
        allocations.pop();
        break;
      }
    }
  }

  function setAllocationPoints(address account, uint256 points) external onlyOwner {
    for (uint256 a = 0; a < allocations.length; a++) {
      if (allocations[a].account == account) {
        totalPoints = totalPoints - allocations[a].points + points;
        allocations[a].points = points;
      }
    }
  }

  function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
    (bool success, bytes memory result) = _to.call{value: _value}(_data);
    require(success, "external call failed");
    return result;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";

interface IPae is IERC20 {

  function setTreasuryFund(address _treasuryFund) external;
  function claimRewards() external;
  function unclaimedTreasuryFund() external view returns (uint256 _pending);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IDistributor.sol";
import "./interfaces/IERC20.sol";

contract DevFund is Ownable, IDistributor {

  struct Allocation {
    address account;
    uint256 points;
  }

  Allocation[] public allocations;
  uint256 public totalPoints;

  IERC20[] public tokens;

  constructor(address[] memory accounts, uint256[] memory points) public {
    for (uint256 a = 0; a < accounts.length; a++) {
      allocations.push(Allocation({
      account : accounts[a],
      points : points[a]
      }));
      totalPoints += points[a];
    }
  }

  function addToken(IERC20 token) external onlyOwner {
    tokens.push(token);
  }

  function distribute() override external {
    for (uint256 t; t < tokens.length; t++) {
      IERC20 token = tokens[t];
      uint256 balance = token.balanceOf(address(this));
      if (balance > 0) {
        for (uint256 a; a < allocations.length; a++) {
          token.transfer(allocations[a].account, balance * allocations[a].points / totalPoints);
        }
      }
    }
  }

  function addAllocation(address account, uint256 points) external onlyOwner {
    allocations.push(Allocation({
    account: account,
    points: points
    }));
    totalPoints += points;
  }

  function removeAllocation(address account) external onlyOwner {
    for (uint256 a = 0; a < allocations.length; a++) {
      if (allocations[a].account == account) {
        totalPoints -= allocations[a].points;
        allocations[a] = allocations[allocations.length - 1];
        allocations.pop();
        break;
      }
    }
  }

  function setAllocationPoints(address account, uint256 points) external onlyOwner {
    for (uint256 a = 0; a < allocations.length; a++) {
      if (allocations[a].account == account) {
        totalPoints = totalPoints - allocations[a].points + points;
        allocations[a].points = points;
      }
    }
  }

  function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
    (bool success, bytes memory result) = _to.call{value: _value}(_data);
    require(success, "external call failed");
    return result;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IERC20.sol";

contract DelegatedPae is Ownable {

  IERC20 public pae;
  address public devFund;
  uint256 public percent;

  constructor (IERC20 _pae, address _devFund, uint256 _percent) public {
    pae = _pae;
    devFund = _devFund;
    percent = _percent;
  }

  function balanceOf(address account) external view returns (uint256) {
    if (account != owner()) return 0;
    uint256 bal = IERC20(pae).balanceOf(devFund);
    return bal * percent / 100;
  }

  function setPercent(uint256 _percent) external onlyOwner {
    require(percent <= 100, "!percent");
    percent = _percent;
  }

  function setDevFund(address _devFund) external onlyOwner {
    devFund = _devFund;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/ITreasury.sol";

contract ShareWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public pae;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        pae.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        uint256 masonShare = _balances[msg.sender];
        require(masonShare >= amount, "Masonry: withdraw request greater than staked amount");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = masonShare.sub(amount);
        pae.safeTransfer(msg.sender, amount);
    }
}

contract Masonry is ShareWrapper, ContractGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== DATA STRUCTURES ========== */

    struct Masonseat {
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
        uint256 epochTimerStart;
    }

    struct MasonrySnapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;

    // flags
    bool public initialized = false;

    IERC20 public pToken;
    ITreasury public treasury;

    mapping(address => Masonseat) public masons;
    MasonrySnapshot[] public masonryHistory;

    uint256 public withdrawLockupEpochs;
    uint256 public rewardLockupEpochs;

    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(address indexed user, uint256 reward);

    /* ========== Modifiers =============== */

    modifier onlyOperator() {
        require(operator == msg.sender, "Masonry: caller is not the operator");
        _;
    }

    modifier masonExists {
        require(balanceOf(msg.sender) > 0, "Masonry: The mason does not exist");
        _;
    }

    modifier updateReward(address mason) {
        if (mason != address(0)) {
            Masonseat memory seat = masons[mason];
            seat.rewardEarned = earned(mason);
            seat.lastSnapshotIndex = latestSnapshotIndex();
            masons[mason] = seat;
        }
        _;
    }

    modifier notInitialized {
        require(!initialized, "Masonry: already initialized");
        _;
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        IERC20 _pToken,
        IERC20 _pae,
        ITreasury _treasury
    ) public notInitialized {
        pToken = _pToken;
        pae = _pae;
        treasury = _treasury;

        MasonrySnapshot memory genesisSnapshot = MasonrySnapshot({time : block.number, rewardReceived : 0, rewardPerShare : 0});
        masonryHistory.push(genesisSnapshot);

        withdrawLockupEpochs = 6; // Lock for 6 epochs (36h) before release withdraw
        rewardLockupEpochs = 3; // Lock for 3 epochs (18h) before release claimReward

        initialized = true;
        operator = msg.sender;
        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external onlyOperator {
        require(_withdrawLockupEpochs >= _rewardLockupEpochs && _withdrawLockupEpochs <= 56, "_withdrawLockupEpochs: out of range"); // <= 2 week
        withdrawLockupEpochs = _withdrawLockupEpochs;
        rewardLockupEpochs = _rewardLockupEpochs;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // =========== Snapshot getters

    function latestSnapshotIndex() public view returns (uint256) {
        return masonryHistory.length.sub(1);
    }

    function getLatestSnapshot() internal view returns (MasonrySnapshot memory) {
        return masonryHistory[latestSnapshotIndex()];
    }

    function getLastSnapshotIndexOf(address mason) public view returns (uint256) {
        return masons[mason].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address mason) internal view returns (MasonrySnapshot memory) {
        return masonryHistory[getLastSnapshotIndexOf(mason)];
    }

    function canWithdraw(address mason) external view returns (bool) {
        return masons[mason].epochTimerStart.add(withdrawLockupEpochs) <= treasury.epoch();
    }

    function canClaimReward(address mason) external view returns (bool) {
        return masons[mason].epochTimerStart.add(rewardLockupEpochs) <= treasury.epoch();
    }

    function epoch() external view returns (uint256) {
        return treasury.epoch();
    }

    function nextEpochPoint() external view returns (uint256) {
        return treasury.nextEpochPoint();
    }

    function getPegPrice() external view returns (uint256) {
        return treasury.getPegPrice();
    }

    // =========== Mason getters

    function rewardPerShare() public view returns (uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    function earned(address mason) public view returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(mason).rewardPerShare;

        return balanceOf(mason).mul(latestRPS.sub(storedRPS)).div(1e18).add(masons[mason].rewardEarned);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) public override onlyOneBlock updateReward(msg.sender) {
        require(amount > 0, "Masonry: Cannot stake 0");
        super.stake(amount);
        masons[msg.sender].epochTimerStart = treasury.epoch(); // reset timer
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override onlyOneBlock masonExists updateReward(msg.sender) {
        require(amount > 0, "Masonry: Cannot withdraw 0");
        require(masons[msg.sender].epochTimerStart.add(withdrawLockupEpochs) <= treasury.epoch(), "Masonry: still in withdraw lockup");
        claimReward();
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function emergencyWithdraw() external onlyOneBlock masonExists updateReward(msg.sender) {
        uint256 amount = balanceOf(msg.sender);
        require(amount > 0, "Masonry: Cannot withdraw 0");
        require(masons[msg.sender].epochTimerStart.add(withdrawLockupEpochs) <= treasury.epoch(), "Masonry: still in withdraw lockup");
        super.withdraw(amount);
        masons[msg.sender].epochTimerStart = treasury.epoch(); // reset timer
        masons[msg.sender].rewardEarned = 0; // reset rewards
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function claimReward() public updateReward(msg.sender) {
        uint256 reward = masons[msg.sender].rewardEarned;
        if (reward > 0) {
            require(masons[msg.sender].epochTimerStart.add(rewardLockupEpochs) <= treasury.epoch(), "Masonry: still in reward lockup");
            masons[msg.sender].epochTimerStart = treasury.epoch(); // reset timer
            masons[msg.sender].rewardEarned = 0;
            pToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function allocateSeigniorage(uint256 amount) external onlyOneBlock onlyOperator {
        require(amount > 0, "Masonry: Cannot allocate 0");
        require(totalSupply() > 0, "Masonry: Cannot allocate when totalSupply is 0");

        // Create & add new snapshot
        uint256 prevRPS = getLatestSnapshot().rewardPerShare;
        uint256 nextRPS = prevRPS.add(amount.mul(1e18).div(totalSupply()));

        MasonrySnapshot memory newSnapshot = MasonrySnapshot({
            time: block.number,
            rewardReceived: amount,
            rewardPerShare: nextRPS
        });
        masonryHistory.push(newSnapshot);

        pToken.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardAdded(msg.sender, amount);
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 _amount, address _to) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(pToken), "pToken");
        require(address(_token) != address(pae), "pae");
        _token.safeTransfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITreasury {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getPegPrice() external view returns (uint256);

    function buyBonds(uint256 amount, uint256 targetPrice) external;

    function redeemBonds(uint256 amount, uint256 targetPrice) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract GenesisRewardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // governance
    address public operator;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Reward to distribute.
        uint256 lastRewardTime; // Last time that Reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated Reward per share, times 1e18. See below.
        bool isStarted; // if lastRewardBlock has passed
        uint256 depositFee; // deposit fee, x / 10000, 2% max
    }

    IERC20 public reward;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when Reward mining starts.
    uint256 public poolStartTime;

    // The time when Reward mining ends.
    uint256 public poolEndTime;

    uint256 public rewardPerSecond = 0.0225 ether;
    uint256 public runningTime = 3 days;

    uint256 constant MAX_DEPOSIT_FEE = 200; // 2%

    address public treasuryFund;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    constructor(
        address _reward,
        uint256 _poolStartTime,
        address _treasuryFund
    ) public {
        require(block.timestamp < _poolStartTime, "late");
        if (_reward != address(0)) reward = IERC20(_reward);
        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
        operator = msg.sender;
        treasuryFund = _treasuryFund;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "GenesisPool: caller is not the operator");
        _;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "GenesisPool: existing pool?");
        }
    }

    // Add a new token to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        uint256 _depositFee
    ) public onlyOperator {
        require(_depositFee <= MAX_DEPOSIT_FEE, "deposit fee too high");
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
        if (block.timestamp < poolStartTime) {
            // chef is sleeping
            if (_lastRewardTime == 0) {
                _lastRewardTime = poolStartTime;
            } else {
                if (_lastRewardTime < poolStartTime) {
                    _lastRewardTime = poolStartTime;
                }
            }
        } else {
            // chef is cooking
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted =
        (_lastRewardTime <= poolStartTime) ||
        (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
            token : _token,
            allocPoint : _allocPoint,
            lastRewardTime : _lastRewardTime,
            accRewardPerShare : 0,
            isStarted : _isStarted,
            depositFee: _depositFee
            }));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's Reward allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint256 _depositFee) public onlyOperator {
        require(_depositFee <= MAX_DEPOSIT_FEE, "deposit fee too high");
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        pool.allocPoint = _allocPoint;
        pool.depositFee = _depositFee;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(rewardPerSecond);
            return poolEndTime.sub(_fromTime).mul(rewardPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(rewardPerSecond);
            return _toTime.sub(_fromTime).mul(rewardPerSecond);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _reward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
          accRewardPerShare = accRewardPerShare.add(_reward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accRewardPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _reward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accRewardPerShare = pool.accRewardPerShare.add(_reward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accRewardPerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeRewardTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            uint256 depositFee = _amount.mul(pool.depositFee).div(10000);
            user.amount = user.amount.add(_amount.sub(depositFee));
            if (depositFee > 0) {
                pool.token.safeTransfer(treasuryFund, depositFee);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accRewardPerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safeRewardTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe Reward transfer function, just in case if rounding error causes pool to not have enough Rewards.
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 _rewardBalance = reward.balanceOf(address(this));
        if (_rewardBalance > 0) {
            if (_amount > _rewardBalance) {
                reward.safeTransfer(_to, _rewardBalance);
            } else {
                reward.safeTransfer(_to, _amount);
            }
        }
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setTreasuryFund(address _treasuryFund) external {
        require(msg.sender == treasuryFund, "!treasury");
        treasuryFund = _treasuryFund;
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external onlyOperator {
        // do not allow to drain core token (Reward or lps)
        require(_token != reward, "reward");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            require(_token != pool.token, "pool.token");
        }
        _token.safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/OXDao.sol";
import "./TestERC20.sol";

contract VlOxd is IvlOXD {

  function lockedBalanceOf(address _user) external override view returns (uint256 amount) {
    return _balances[_user];
  }

  function balances(address _user) external override view returns (uint112 locked, uint112 boosted, uint32 nextUnlockIndex) {
    uint112 bal = _balances[_user];
    return (bal, bal, 0);
  }

  function userLocks(address _user, uint _index) external override view
  returns (uint112 amount, uint112 boosted, uint32 unlockTime) {
    _user;
    _index;
    return (0, 0, 0);
  }

  function claimableRewards(address _account) external override view returns (EarnedData[] memory userRewards) {
    _account;
    userRewards = new EarnedData[](1);
    userRewards[0] = EarnedData(address(oxSolid), _claimableRewards);
  }

  TestERC20 oxd;
  TestERC20 oxSolid;
  uint _claimableRewards;
  mapping(address => uint112) _balances;

  function init(TestERC20 _oxd, TestERC20 _oxSolid) external {
    oxd = _oxd;
    oxSolid = _oxSolid;
  }

  function voteLockOxd(address _user, uint _amount, uint _spendRatio) external {
    _spendRatio;
    require(_amount > 0, "> 0");
    oxd.transferFrom(msg.sender, address(this), _amount);
    _balances[_user] += uint112(_amount);
  }

  function setClaimableRewards(uint _rewards) external {
    _claimableRewards = _rewards;
  }

  function claimRewards(address _to) external {
    oxSolid.mint(_to, _claimableRewards);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IOxDao {
  function voteLockOxd(uint256 amount, uint256 spendRatio) external;
  function vote(address poolAddress, int256 weight) external;
  function resetVotes() external;
  function claimVlOxdStakingRewards() external;
  function withdrawVoteLockedOxd(uint256 spendRatio) external;
}

interface IvlOXD {
  struct EarnedData {
    address token;
    uint256 amount;
  }
  // total token balance of an account, including unlocked but not withdrawn tokens
  function lockedBalanceOf(address _user) external view returns (uint256 amount);
  function balances(address _user) external view returns (uint112 locked, uint112 boosted, uint32 nextUnlockIndex);
  function userLocks(address _user, uint _index) external view returns (uint112 amount, uint112 boosted, uint32 unlockTime);
  function claimableRewards(address _account) external view returns (EarnedData[] memory userRewards);
}

interface IVotingSnapshot {
  struct Vote {
    address poolAddress;
    int256 weight;
  }
  function voteWeightTotalByAccount(address accountAddress) external view returns (uint256);
  function voteWeightUsedByAccount(address accountAddress) external view returns (uint256);
  function votesByAccount(address accountAddress) external view returns (Vote[] memory);
}

interface IUserProxy {
  function userProxyByAccount(address _user) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../interfaces/OXDao.sol";

contract UserProxyFactory is IUserProxy {

  function userProxyByAccount(address _user) external override view returns (address) {
    return _user;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/OXDao.sol";
import "./VlOxd.sol";

contract Oxdao is IOxDao {

  IERC20 oxd;
  VlOxd vlOxd;

  function init(IERC20 _oxd, VlOxd _vlOxd) external {
    oxd = _oxd;
    vlOxd = _vlOxd;
    oxd.approve(address(vlOxd), type(uint).max);
  }

  function voteLockOxd(uint256 amount, uint256 spendRatio) external override {
    oxd.transferFrom(msg.sender, address(this), amount);
    vlOxd.voteLockOxd(msg.sender, amount, spendRatio);
  }

  function vote(address poolAddress, int256 weight) external override {

  }

  function resetVotes() external override {

  }

  function claimVlOxdStakingRewards() external override {
    vlOxd.claimRewards(msg.sender);
  }

  function withdrawVoteLockedOxd(uint256 spendRatio) external override {

  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import "./interfaces/ISolidlyRouter.sol";
import "./interfaces/OXDao.sol";

contract ripOXD is ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  IOxDao public oxDAO;
  IvlOXD public vlOXD;
  IVotingSnapshot public voting;
  IUserProxy public userProxyFactory;
  IERC20Upgradeable public oxd;
  IERC20Upgradeable public oxSOLID;
  ISolidlyRouter public router;
  ISolidlyRouter.route[] public routes;
  uint public minHarvestAmount;
  uint public withdrawalWindow;
  uint public withdrawalOpenUntil;

  event Deposit(address indexed user, uint amount, uint shares);
  event Withdraw(address indexed user, uint amount, uint shares);
  event Harvest(uint oxSolid, uint oxd);
  event WithdrawalOpened(uint amount, uint until);
  event Locked(uint amount);

  function initialize(
    IOxDao _oxdao,
    IvlOXD _vloxd,
    IVotingSnapshot _voting,
    IUserProxy _userProxy,
    IERC20Upgradeable _oxd,
    IERC20Upgradeable _oxSolid,
    ISolidlyRouter _router,
    ISolidlyRouter.route[] memory _routes
  ) public initializer {
    oxDAO = _oxdao;
    vlOXD = _vloxd;
    voting = _voting;
    userProxyFactory = _userProxy;
    oxd = _oxd;
    oxSOLID = _oxSolid;
    router = _router;
    minHarvestAmount = 1e17;
    withdrawalWindow = 1 days;

    _setRoutes(_routes);

    oxd.approve(address(oxDAO), type(uint).max);
    oxSOLID.approve(address(router), type(uint).max);

    __ERC20_init("Ripae OXD", "ripOXD");
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
  }

  function _setRoutes(ISolidlyRouter.route[] memory _routes) internal {
    delete routes;
    require(_routes[0].from == address(oxSOLID), "!swap from oxSOLID");
    require(_routes[_routes.length - 1].to == address(oxd), "!swap to OXD");
    for (uint i; i < _routes.length; i++) {
      routes.push(_routes[i]);
    }
  }

  // Oxdao UserProxy contract, needed for getting vlOXD stats and pending oxSOLID
  function userProxy() public view returns (address) {
    return userProxyFactory.userProxyByAccount(address(this));
  }

  // balance of OXD + locked as vlOXD (including unlocked not withdrawn)
  function balance() public view returns (uint) {
    return oxd.balanceOf(address(this)).add(vlOXD.lockedBalanceOf(userProxy()));
  }

  // OXD amount per 1 ripOXD
  function pricePerShare() public view returns (uint256) {
    return totalSupply() == 0 ? 1e18 : balance().mul(1e18).div(totalSupply());
  }

  function depositAll() external {
    deposit(oxd.balanceOf(msg.sender));
  }

  // harvest pending oxSOLID, deposit OXD, lock to vlOXD, receive ripOXD
  function deposit(uint _amount) public nonReentrant whenNotPaused {
    require(_amount > 0, "Cant deposit 0");
    harvestIfEnoughOxSolid();

    uint _pool = balance();
    uint256 _before = oxd.balanceOf(address(this));
    oxd.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _after = oxd.balanceOf(address(this));
    _amount = _after.sub(_before);
    uint256 shares = 0;
    if (totalSupply() == 0) {
      shares = _amount;
    } else {
      shares = (_amount.mul(totalSupply())).div(_pool);
    }
    _mint(msg.sender, shares);
    emit Deposit(msg.sender, _amount, shares);

    uint lockAmount = _amount;
    // lock all OXD (deposited + harvested) if not in withdrawal mode
    if (block.timestamp > withdrawalOpenUntil) {
      lockAmount = oxd.balanceOf(address(this));
    }
    oxDAO.voteLockOxd(lockAmount, 0);
    emit Locked(lockAmount);
  }

  function withdrawAll() external {
    withdraw(balanceOf(msg.sender));
  }

  // withdraw OXD, burn ripOXD
  function withdraw(uint256 _shares) public {
    uint256 amount = (balance().mul(_shares)).div(totalSupply());
    uint bal = oxd.balanceOf(address(this));
    require(bal >= amount, "not enough OXD");

    _burn(msg.sender, _shares);
    oxd.safeTransfer(msg.sender, amount);

    emit Withdraw(msg.sender, amount, _shares);
  }

  function claimableOxSolid() public view returns (uint) {
    IvlOXD.EarnedData[] memory rewards = vlOXD.claimableRewards(userProxy());
    for (uint i; i < rewards.length; i++) {
      if (rewards[i].token == address(oxSOLID)) {
        return rewards[i].amount;
      }
    }
    return 0;
  }

  // claim oxSolid if > 0.1 pending, swap to OXD
  function harvestIfEnoughOxSolid() public {
    if (claimableOxSolid() >= minHarvestAmount) {
      oxDAO.claimVlOxdStakingRewards();
      uint amountIn = oxSOLID.balanceOf(address(this));
      uint[] memory amounts = router.swapExactTokensForTokens(amountIn, 0, routes, address(this), block.timestamp);
      emit Harvest(amountIn, amounts[amounts.length - 1]);
    }
  }

  function nextWithdrawal() external view returns (uint amount, uint unlockTime) {
    (,,uint32 nextUnlockIndex) = vlOXD.balances(userProxy());
    (amount,,unlockTime) = vlOXD.userLocks(userProxy(), nextUnlockIndex);
    return (amount, unlockTime);
  }

  // withdraw any unlocked OXD and open withdrawal window
  function withdrawVoteLockedOxd() external {
    oxDAO.withdrawVoteLockedOxd(0);
    withdrawalOpenUntil = block.timestamp.add(withdrawalWindow);
    emit WithdrawalOpened(oxd.balanceOf(address(this)), withdrawalOpenUntil);
  }

  // lock all idle OXD if not in withdrawal mode
  function voteLockOxd() external {
    require(block.timestamp > withdrawalOpenUntil, "in withdrawal mode");
    uint amount = oxd.balanceOf(address(this));
    require(amount > 0, "Cant lock 0");
    oxDAO.voteLockOxd(amount, 0);
    emit Locked(amount);
  }

  // vote weights by pool
  function votes() external view returns (IVotingSnapshot.Vote[] memory voteWeights) {
    return voting.votesByAccount(userProxy());
  }

  function votesAvailable() external view returns (uint total, uint used, uint available) {
    total = voting.voteWeightTotalByAccount(userProxy());
    used = voting.voteWeightUsedByAccount(userProxy());
    available = total - used;
  }

  function vote(address _pool, int128 _weight) external onlyOwner {
    oxDAO.vote(_pool, _weight);
  }

  function resetVotes() external onlyOwner {
    oxDAO.resetVotes();
  }

  function setRoutes(ISolidlyRouter.route[] memory _routes) external onlyOwner {
    _setRoutes(_routes);
  }

  function setMinHarvestAmount(uint _amount) external onlyOwner {
    minHarvestAmount = _amount;
  }

  function setWithdrawalWindow(uint _window) external onlyOwner {
    withdrawalWindow = _window;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
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
     * - `to` cannot be the zero address.
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IDistributor.sol";

contract Sell_avax is OwnableUpgradeable {

  address public source;
  address public devFund;
  IERC20 public peg;
  IERC20 public native;
  IUniswapV2Router public router;
  address[] public pegRoute;
  uint public pegAmount;
  uint public minAmount;

  function initialize() public initializer {
    source = 0x70D53D07fD8906a54f213d76c114b2A5C2Aa1e80;
    devFund = 0xa7A1c40B94FDF630c1CfFA15e39714400a46F1d9;
    peg = IERC20(0x6ca558bd3eaB53DA1B25aB97916dd14bf6CFEe4E);
    native = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    router = IUniswapV2Router(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

//    address _usdc = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    pegRoute = [address(peg), address(native)];

    peg.approve(address(router), type(uint256).max);
    native.approve(address(router), type(uint256).max);

    pegAmount = 28 ether;
    minAmount = 1e17;

    __Ownable_init();
  }

  function upgrade() public {
  }

  function amounts(uint256 _peg) external onlyOwner {
    pegAmount = _peg;
  }

  function pf(uint256 _amount) external onlyOwner {
    _sellPeg(_amount * 1e18);
  }

  function pf() external {
    if (peg.balanceOf(devFund) > minAmount) {
      IDistributor(devFund).distribute();
    }
    bool sold;

    uint amount = peg.balanceOf(source) < pegAmount ? peg.balanceOf(source) : pegAmount;
    if (amount > minAmount) {
      _sellPeg(amount);
      sold = true;
    }

    require(sold, "nothing");
  }

  function _sellPeg(uint256 _amount) internal {
    peg.transferFrom(source, address(this), _amount);
    router.swapExactTokensForAVAX(peg.balanceOf(address(this)), 0, pegRoute, owner(), block.timestamp);
  }

  function setPf(address[] memory _pfRoute) external onlyOwner {
    pegRoute = _pfRoute;
  }

  function reset(bool approve) external onlyOwner {
    if (approve) {
      peg.approve(address(router), type(uint256).max);
      native.approve(address(router), type(uint256).max);
    } else {
      peg.approve(address(router), 0);
      native.approve(address(router), 0);
    }
  }
}
/**
 *Submitted for verification at FtmScan.com on 2022-10-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


library AddressUpgradeable {
    
    function isContract(address account) internal view returns (bool) {

        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

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
        if (returndata.length > 0) {
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}








// 2
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}






// 3
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
interface IERC20Upgradeable {
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





// 4
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}




// 5
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
library SafeMathUpgradeable {
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




// 6
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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



// 7
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}





// 8
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
interface IERC20PermitUpgradeable {
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





// 9
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}




// 10
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}




//11
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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





// 12
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

interface IVault {
    function rewards() external view returns (address);

    function reportHarvest(
        uint256 _harvestedAmount
    ) external;

    function reportAdditionalToken(address _token) external;

    // Fees
    function performanceFeeGovernance() external view returns (uint256);

    function performanceFeeStrategist() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function managementFee() external view returns (uint256);

    // Actors
    function governance() external view returns (address);

    function keeper() external view returns (address);

    function guardian() external view returns (address);

    function strategist() external view returns (address);

    // External
    function deposit(uint256 _amount) external;
}





//13
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
contract SettAccessControl is Initializable {
    address public governance;
    address public strategist;
    address public keeper;

    // ===== MODIFIERS =====
    function _onlyGovernance() internal view {
        require(msg.sender == governance, "onlyGovernance");
    }

    function _onlyGovernanceOrStrategist() internal view {
        require(msg.sender == strategist || msg.sender == governance, "onlyGovernanceOrStrategist");
    }

    function _onlyAuthorizedActors() internal view {
        require(msg.sender == keeper || msg.sender == governance, "onlyAuthorizedActors");
    }

    // ===== PERMISSIONED ACTIONS =====

    /// @notice Change strategist address
    /// @notice Can only be changed by governance itself
    function setStrategist(address _strategist) external {
        _onlyGovernance();
        strategist = _strategist;
    }

    /// @notice Change keeper address
    /// @notice Can only be changed by governance itself
    function setKeeper(address _keeper) external {
        _onlyGovernance();
        keeper = _keeper;
    }

    /// @notice Change governance address
    /// @notice Can only be changed by governance itself
    function setGovernance(address _governance) public {
        _onlyGovernance();
        governance = _governance;
    }

    uint256[50] private __gap;
}





// 14
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
interface IStrategy {
    // Return value for harvest, tend and balanceOfRewards
    struct TokenAmount {
        address token;
        uint256 amount;
    }

    function balanceOf() external view returns (uint256 balance);

    function balanceOfPool() external view returns (uint256 balance);

    function balanceOfWant() external view returns (uint256 balance);

    function earn() external;

    function withdraw(uint256 amount) external;

    function withdrawToVault() external;

    function withdrawOther(address _asset) external;

    function harvest() external returns (TokenAmount[] memory harvested);
    function tend() external returns (TokenAmount[] memory tended);
    function balanceOfRewards() external view returns (TokenAmount[] memory rewards);

    function emitNonProtectedToken(address _token) external;
}




//15
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
interface IERC20Detailed {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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






// 16
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
interface BadgerGuestListAPI {
    function authorized(
        address guest,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool);

    function setGuests(address[] calldata _guests, bool[] calldata _invited) external;
}









// 17
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

contract Vault is ERC20Upgradeable, SettAccessControl, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    uint256 constant ONE_ETH = 1e18;

    /// ===== Storage Variables ====

    IERC20Upgradeable public token; // Token used for deposits
    BadgerGuestListAPI public guestList; // guestlist when vault is in experiment/ guarded state

    bool public pausedDeposit; // false by default Allows to only block deposits, use pause for the normal pause state

    address public strategy; // address of the strategy connected to the vault
    address public guardian; // guardian of vault and strategy
    address public treasury; // set by governance ... any fees go there

    address public badgerTree; // Address we send tokens too via reportAdditionalTokens

    /// @dev name and symbol prefixes for lpcomponent token of vault
    string internal constant _defaultNamePrefix = "Badger Sett ";
    string internal constant _symbolSymbolPrefix = "b";

    /// Params to track autocompounded rewards
    uint256 public lifeTimeEarned; // keeps track of total earnings
    uint256 public lastHarvestedAt; // timestamp of the last harvest
    uint256 public lastHarvestAmount; // amount harvested during last harvest
    uint256 public assetsAtLastHarvest; // assets for which the harvest took place.

    mapping (address => uint256) public additionalTokensEarned;
    mapping (address => uint256) public lastAdditionalTokenAmount;

    /// Fees ///
    /// @notice all fees will be in bps
    uint256 public performanceFeeGovernance; // Perf fee sent to `treasury`
    uint256 public performanceFeeStrategist; // Perf fee sent to `strategist`
    uint256 public withdrawalFee; // fee issued to `treasury` on withdrawal 
    uint256 public managementFee; // fee issued to `treasury` on report (typically on harvest, but only if strat is autocompounding)

    uint256 public maxPerformanceFee; // maximum allowed performance fees
    uint256 public maxWithdrawalFee; // maximum allowed withdrawal fees
    uint256 public maxManagementFee; // maximum allowed management fees

    uint256 public toEarnBps; // NOTE: in BPS, minimum amount of token to deposit into strategy when earn is called

    /// ===== Constants ====

    uint256 public constant MAX_BPS = 10_000;
    uint256 public constant SECS_PER_YEAR = 31_556_952; // 365.2425 days

    uint256 public constant WITHDRAWAL_FEE_HARD_CAP = 200; // Never higher than 2%
    uint256 public constant PERFORMANCE_FEE_HARD_CAP = 3_000; // Never higher than 30% // 30% maximum performance fee // We usually do 20, so this is insanely high already
    uint256 public constant MANAGEMENT_FEE_HARD_CAP = 200; // Never higher than 2%

    /// ===== Events ====

    // Emitted when a token is sent to the badgerTree for emissions
    event TreeDistribution(
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    );

    // Emitted during a report, when there has been an increase in pricePerFullShare (ppfs)
    event Harvested(address indexed token, uint256 amount, uint256 indexed blockNumber, uint256 timestamp);
    event PerformanceFeeGovernance(
        address indexed destination,
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    );
    event PerformanceFeeStrategist(
        address indexed destination,
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    );
    event WithdrawalFee(
        address indexed destination,
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    );

    event SetTreasury(address indexed newTreasury);
    event SetStrategy(address indexed newStrategy);
    event SetToEarnBps(uint256 newEarnToBps);
    event SetMaxWithdrawalFee(uint256 newMaxWithdrawalFee);
    event SetMaxPerformanceFee(uint256 newMaxPerformanceFee);
    event SetMaxManagementFee(uint256 newMaxManagementFee);
    event SetGuardian(address indexed newGuardian);
    event SetGuestList(address indexed newGuestList);
    event SetWithdrawalFee(uint256 newWithdrawalFee);
    event SetPerformanceFeeStrategist(uint256 newPerformanceFeeStrategist);
    event SetPerformanceFeeGovernance(uint256 newPerformanceFeeGovernance);
    event SetManagementFee(uint256 newManagementFee);

    event PauseDeposits(address indexed pausedBy);
    event UnpauseDeposits(address indexed pausedBy);

    /// @notice Initializes the Sett. Can only be called once, ideally when the contract is deployed.
    /// @param _token Address of the token that can be deposited into the sett.
    /// @param _governance Address authorized as governance.
    /// @param _keeper Address authorized as keeper.
    /// @param _guardian Address authorized as guardian.
    /// @param _treasury Address to distribute governance fees/rewards to.
    /// @param _strategist Address authorized as strategist.
    /// @param _badgerTree Address of badgerTree used for emissions.
    /// @param _name Specify a custom sett name. Leave empty for default value.
    /// @param _symbol Specify a custom sett symbol. Leave empty for default value.
    /// @param _feeConfig Values for the 4 different types of fees charges by the sett
    ///         [performanceFeeGovernance, performanceFeeStrategist, withdrawToVault, managementFee]
    ///         Each fee should be less than the constant hard-caps defined above. 
    function initialize(
        address _token,
        address _governance,
        address _keeper,
        address _guardian,
        address _treasury,
        address _strategist,
        address _badgerTree,
        string memory _name,
        string memory _symbol,
        uint256[4] memory _feeConfig
    ) public initializer whenNotPaused {
        require(_token != address(0)); // dev: _token address should not be zero
        require(_governance != address(0)); // dev: _governance address should not be zero
        require(_keeper != address(0)); // dev: _keeper address should not be zero
        require(_guardian != address(0)); // dev: _guardian address should not be zero
        require(_treasury != address(0)); // dev: _treasury address should not be zero
        require(_strategist != address(0)); // dev: _strategist address should not be zero
        require(_badgerTree != address(0)); // dev: _badgerTree address should not be zero

        // Check for fees being reasonable (see below for interpretation)
        require(_feeConfig[0] <= PERFORMANCE_FEE_HARD_CAP, "performanceFeeGovernance too high");
        require(_feeConfig[1] <= PERFORMANCE_FEE_HARD_CAP, "performanceFeeStrategist too high");
        require(_feeConfig[2] <= WITHDRAWAL_FEE_HARD_CAP, "withdrawalFee too high");
        require(_feeConfig[3] <= MANAGEMENT_FEE_HARD_CAP, "managementFee too high");

        string memory name;
        string memory symbol;


        // If they are non empty string we'll use the custom names
        // Else just add the default prefix
        IERC20Detailed namedToken = IERC20Detailed(_token);

        if(keccak256(abi.encodePacked(_name)) != keccak256("")) {
            name = _name;
        } else {
            name = string(abi.encodePacked(_defaultNamePrefix, namedToken.name()));
        }

        if (keccak256(abi.encodePacked(_symbol)) != keccak256("")) {
            symbol = _symbol;
        } else {
            symbol = string(abi.encodePacked(_symbolSymbolPrefix, namedToken.symbol()));
        }

        // Initializing the lpcomponent token
        __ERC20_init(name, symbol);
        // Initialize the other contracts
        __Pausable_init();
        __ReentrancyGuard_init();

        token = IERC20Upgradeable(_token);
        governance = _governance;
        treasury = _treasury;
        strategist = _strategist;
        keeper = _keeper;
        guardian = _guardian;
        badgerTree = _badgerTree;

        lastHarvestedAt = block.timestamp; // setting initial value to the time when the vault was deployed

        performanceFeeGovernance = _feeConfig[0];
        performanceFeeStrategist = _feeConfig[1];
        withdrawalFee = _feeConfig[2];
        managementFee = _feeConfig[3];
        maxPerformanceFee = PERFORMANCE_FEE_HARD_CAP; // 30% max performance fee
        maxWithdrawalFee = WITHDRAWAL_FEE_HARD_CAP; // 2% maximum withdrawal fee
        maxManagementFee = MANAGEMENT_FEE_HARD_CAP; // 2% maximum management fee

        toEarnBps = 9_500; // initial value of toEarnBps // 95% is invested to the strategy, 5% for cheap withdrawals
    }

    /// ===== Modifiers ====

    /// @notice Checks whether a call is from guardian or governance. 
    function _onlyAuthorizedPausers() internal view {
        require(msg.sender == guardian || msg.sender == governance, "onlyPausers");
    }

    /// @notice Checks whether a call is from the strategy.
    function _onlyStrategy() internal view {
        require(msg.sender == strategy, "onlyStrategy");
    }

    /// ===== View Functions =====
    
    /// @notice Used to track the deployed version of the contract.
    /// @return Current version of the contract.
    function version() external pure returns (string memory) {
        return "1.5";
    }

    /// @notice Gives the price for a single Sett share.
    /// @dev Sett starts with a price per share of 1.
    /// @return Value of a single share.
    function getPricePerFullShare() public view returns (uint256) {
        if (totalSupply() == 0) {
            return ONE_ETH;
        }
        return balance().mul(ONE_ETH).div(totalSupply());
    }

    /// @notice Gives the total balance of the underlying token within the sett and strategy system.
    /// @return Balance of token handled by the sett.
    function balance() public view returns (uint256) {
        return token.balanceOf(address(this)).add(IStrategy(strategy).balanceOf());
    }

    /// @notice Defines how much of the Setts' underlying is available for strategy to borrow.
    /// @return Amount of tokens that the sett can provide to the strategy.
    function available() public view returns (uint256) {
        return token.balanceOf(address(this)).mul(toEarnBps).div(MAX_BPS);
    }

    /// ===== Public Actions =====

    /// @notice Deposits `_amount` tokens, issuing shares. 
    ///         Note that deposits are not accepted when the Sett is paused or when `pausedDeposit` is true. 
    /// @dev See `_depositFor` for details on how deposit is implemented. 
    /// @param _amount Quantity of tokens to deposit. 
    function deposit(uint256 _amount) external whenNotPaused {
        _depositWithAuthorization(_amount, new bytes32[](0));
    }

    /// @notice Deposits `_amount` tokens, issuing shares. 
    ///         Checks the guestlist to verify that the calling account is authorized to make a deposit for the specified `_amount`.
    ///         Note that deposits are not accepted when the Sett is paused or when `pausedDeposit` is true. 
    /// @dev See `_depositForWithAuthorization` for details on guestlist authorization.
    /// @param _amount Quantity of tokens to deposit. 
    /// @param proof Merkle proof to validate in the guestlist.
    function deposit(uint256 _amount, bytes32[] memory proof) external whenNotPaused {
        _depositWithAuthorization(_amount, proof);
    }

    /// @notice Deposits all tokens, issuing shares. 
    ///         Note that deposits are not accepted when the Sett is paused or when `pausedDeposit` is true. 
    /// @dev See `_depositFor` for details on how deposit is implemented. 
    function depositAll() external whenNotPaused {
        _depositWithAuthorization(token.balanceOf(msg.sender), new bytes32[](0));
    }

    /// @notice Deposits all tokens, issuing shares. 
    ///         Checks the guestlist to verify that the calling is authorized to make a full deposit.
    ///         Note that deposits are not accepted when the Sett is paused or when `pausedDeposit` is true. 
    /// @dev See `_depositForWithAuthorization` for details on guestlist authorization.
    /// @param proof Merkle proof to validate in the guestlist.
    function depositAll(bytes32[] memory proof) external whenNotPaused {
        _depositWithAuthorization(token.balanceOf(msg.sender), proof);
    }

    /// @notice Deposits `_amount` tokens, issuing shares to `recipient`. 
    ///         Note that deposits are not accepted when the Sett is paused or when `pausedDeposit` is true. 
    /// @dev See `_depositFor` for details on how deposit is implemented. 
    /// @param _recipient Address to issue the Sett shares to.
    /// @param _amount Quantity of tokens to deposit. 
    function depositFor(address _recipient, uint256 _amount) external whenNotPaused {
        _depositForWithAuthorization(_recipient, _amount, new bytes32[](0));
    }

    /// @notice Deposits `_amount` tokens, issuing shares to `recipient`. 
    ///         Checks the guestlist to verify that `recipient` is authorized to make a deposit for the specified `_amount`.
    ///         Note that deposits are not accepted when the Sett is paused or when `pausedDeposit` is true. 
    /// @dev See `_depositForWithAuthorization` for details on guestlist authorization.
    /// @param _recipient Address to issue the Sett shares to.
    /// @param _amount Quantity of tokens to deposit. 
    function depositFor(
        address _recipient,
        uint256 _amount,
        bytes32[] memory proof
    ) external whenNotPaused {
        _depositForWithAuthorization(_recipient, _amount, proof);
    }

    /// @notice Redeems `_shares` for an appropriate amount of tokens.
    ///         Note that withdrawals are not processed when the Sett is paused. 
    /// @dev See `_withdraw` for details on how withdrawals are processed.
    /// @param _shares Quantity of shares to redeem. 
    function withdraw(uint256 _shares) external whenNotPaused {
        _withdraw(_shares);
    }

    /// @notice Redeems all shares, issuing an appropriate amount of tokens. 
    ///         Note that withdrawals are not processed when the Sett is paused. 
    /// @dev See `_withdraw` for details on how withdrawals are processed.
    function withdrawAll() external whenNotPaused {
        _withdraw(balanceOf(msg.sender));
    }

    /// ===== Permissioned Actions: Strategy =====

    /// @notice Used by the strategy to report a harvest to the sett.
    ///         Issues shares for the strategist and treasury based on the performance fees and harvested amount. 
    ///         Issues shares for the treasury based on the management fee and the time elapsed since last harvest. 
    ///         Updates harvest variables for on-chain APR tracking.
    ///         This can only be called by the strategy.
    /// @dev This implicitly trusts that the strategy reports the correct amount.
    ///      Pausing on this function happens at the strategy level.
    /// @param _harvestedAmount Amount of underlying token harvested by the strategy.
    function reportHarvest(
        uint256 _harvestedAmount
    ) external nonReentrant {
        _onlyStrategy();

        uint256 harvestTime = block.timestamp;
        uint256 assetsAtHarvest = balance().sub(_harvestedAmount); // Must be less than or equal or revert

        _handleFees(_harvestedAmount, harvestTime);

        // Updated lastHarvestAmount
        lastHarvestAmount = _harvestedAmount;

        // if we withdrawAll
        // we will have some yield left
        // having 0 for assets will inflate APY
        // Instead, have the last harvest report with the previous assets
        // And if you end up harvesting again, that report will have both 0s
        if (assetsAtHarvest != 0) {
            assetsAtLastHarvest = assetsAtHarvest;
        } else if (_harvestedAmount == 0) {
            // If zero
            assetsAtLastHarvest = 0;
        }

        lifeTimeEarned = lifeTimeEarned.add(_harvestedAmount);
        // Update time either way
        lastHarvestedAt = harvestTime;

        emit Harvested(address(token), _harvestedAmount, block.number, block.timestamp);
    }

    /// @notice Used by the strategy to report harvest of additional tokens to the sett.
    ///         Charges performance fees on the additional tokens and transfers fees to treasury and strategist. 
    ///         The remaining amount is sent to badgerTree for emissions.
    ///         Updates harvest variables for on-chain APR tracking.
    ///         This can only be called by the strategy.
    /// @dev This function is called after the strategy sends the additional tokens to the sett.
    ///      Pausing on this function happens at the strategy level.
    /// @param _token Address of additional token harvested by the strategy.
    function reportAdditionalToken(address _token) external nonReentrant {
        _onlyStrategy();
        require(address(token) != _token, "No want");
        uint256 tokenBalance = IERC20Upgradeable(_token).balanceOf(address(this));

        additionalTokensEarned[_token] = additionalTokensEarned[_token].add(tokenBalance);
        lastAdditionalTokenAmount[_token] = tokenBalance;

        // We may have more, but we still report only what the strat sent
        uint256 governanceRewardsFee = _calculateFee(tokenBalance, performanceFeeGovernance);
        uint256 strategistRewardsFee = _calculateFee(tokenBalance, performanceFeeStrategist);

        if(governanceRewardsFee != 0) {
            address cachedTreasury = treasury;
            IERC20Upgradeable(_token).safeTransfer(cachedTreasury, governanceRewardsFee);
            emit PerformanceFeeGovernance(cachedTreasury, _token, governanceRewardsFee, block.number, block.timestamp);
        }

        if(strategistRewardsFee != 0) {
            address cachedStrategist = strategist;
            IERC20Upgradeable(_token).safeTransfer(cachedStrategist, strategistRewardsFee);
            emit PerformanceFeeStrategist(cachedStrategist, _token, strategistRewardsFee, block.number, block.timestamp);
        }

        // Send rest to tree
        uint256 newBalance = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(badgerTree, newBalance);
        emit TreeDistribution(_token, newBalance, block.number, block.timestamp);
    }

    /// ===== Permissioned Actions: Governance =====

    /// @notice Changes the treasury address.
    ///         Treasury is recipient of management and governance performance fees.
    ///         This can only be called by governance.
    ///         Note that this can only be called when sett is not paused.
    /// @param _treasury Address of the new treasury.
    function setTreasury(address _treasury) external whenNotPaused {
        _onlyGovernance();
        require(_treasury != address(0), "Address 0");

        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    /// @notice Changes the strategy address.
    ///         This can only be called by governance.
    ///         Note that this can only be called when sett is not paused.
    /// @dev This is a rug vector, pay extremely close attention to the next strategy being set.
    ///      Changing the strategy should happen only via timelock.
    ///      This function must not be callable when the sett is paused as this would force depositors into a strategy they may not want to use.
    /// @param _strategy Address of new strategy.
    function setStrategy(address _strategy) external whenNotPaused {
        _onlyGovernance();
        require(_strategy != address(0), "Address 0");


        // NOTE: Migrate funds if settings strategy when already existing one
        if (strategy != address(0)) {
            require(IStrategy(strategy).balanceOf() == 0, "Please withdrawToVault before changing strat");
        }
        strategy = _strategy;
        emit SetStrategy(_strategy);
    }

    // === Setters that can be called by governance even when paused ===

    /// @notice Sets the max withdrawal fee that can be charged by the Sett.
    ///         This can only be called by governance.
    /// @dev The input `_fees` should be less than the `WITHDRAWAL_FEE_HARD_CAP` hard-cap.
    /// @param _fees The new maximum cap for withdrawal fee.
    function setMaxWithdrawalFee(uint256 _fees) external {
        _onlyGovernance();
        require(_fees <= WITHDRAWAL_FEE_HARD_CAP, "withdrawalFee too high");

        maxWithdrawalFee = _fees;
        emit SetMaxWithdrawalFee(_fees);
    }

    /// @notice Sets the max performance fee that can be charged by the Sett.
    ///         This can only be called by governance.
    /// @dev The input `_fees` should be less than the `PERFORMANCE_FEE_HARD_CAP` hard-cap.
    /// @param _fees The new maximum cap for performance fee.
    function setMaxPerformanceFee(uint256 _fees) external {
        _onlyGovernance();
        require(_fees <= PERFORMANCE_FEE_HARD_CAP, "performanceFeeStrategist too high");

        maxPerformanceFee = _fees;
        emit SetMaxPerformanceFee(_fees);
    }

    /// @notice Sets the max management fee that can be charged by the Sett.
    ///         This can only be called by governance.
    /// @dev The input `_fees` should be less than the `MANAGEMENT_FEE_HARD_CAP` hard-cap.
    /// @param _fees The new maximum cap for management fee.
    function setMaxManagementFee(uint256 _fees) external {
        _onlyGovernance();
        require(_fees <= MANAGEMENT_FEE_HARD_CAP, "managementFee too high");

        maxManagementFee = _fees;
        emit SetMaxManagementFee(_fees);
    }

    /// @notice Changes the guardian address.
    ///         Guardian is an authorized actor that can pause the sett in case of an emergency.
    ///         This can only be called by governance.
    /// @param _guardian Address of the new guardian.
    function setGuardian(address _guardian) external {
        _onlyGovernance();
        require(_guardian != address(0), "Address cannot be 0x0");

        guardian = _guardian;
        emit SetGuardian(_guardian);
    }

    /// ===== Permissioned Functions: Trusted Actors =====

    /// @notice Sets the fraction of sett balance (in basis points) that the strategy can borrow.
    ///         This can be called by either governance or strategist.
    ///         Note that this can only be called when the sett is not paused.
    /// @param _newToEarnBps The new maximum cap for management fee.
    function setToEarnBps(uint256 _newToEarnBps) external whenNotPaused {
        _onlyGovernanceOrStrategist();
        require(_newToEarnBps <= MAX_BPS, "toEarnBps should be <= MAX_BPS");

        toEarnBps = _newToEarnBps;
        emit SetToEarnBps(_newToEarnBps);
    } 

    /// @notice Changes the guestlist address.
    ///         The guestList is used to gate or limit deposits. If no guestlist is set then anyone can deposit any amount.
    ///         This can be called by either governance or strategist.
    ///         Note that this can only be called when the sett is not paused.
    /// @param _guestList Address of the new guestlist.
    function setGuestList(address _guestList) external whenNotPaused {
        _onlyGovernanceOrStrategist();
        guestList = BadgerGuestListAPI(_guestList);
        emit SetGuestList(_guestList);
    }

    /// @notice Sets the withdrawal fee charged by the Sett.
    ///         The fee is taken at the time of withdrawals in the underlying token which is then used to issue new shares for the treasury.
    ///         The new withdrawal fee should be less than `maxWithdrawalFee`.
    ///         This can be called by either governance or strategist.
    /// @dev See `_withdraw` to see how withdrawal fee is charged.
    /// @param _withdrawalFee The new withdrawal fee.
    function setWithdrawalFee(uint256 _withdrawalFee) external whenNotPaused {
        _onlyGovernanceOrStrategist();
        require(_withdrawalFee <= maxWithdrawalFee, "Excessive withdrawal fee");
        withdrawalFee = _withdrawalFee;
        emit SetWithdrawalFee(_withdrawalFee);
    }

    /// @notice Sets the performance fee taken by the strategist on the harvests.
    ///         The fee is taken at the time of harvest reporting for both the underlying token and additional tokens.
    ///         For the underlying token, the fee is used to issue new shares for the strategist.
    ///         The new performance fee should be less than `maxPerformanceFee`.
    ///         This can be called by either governance or strategist.
    /// @dev See `reportHarvest` and `reportAdditionalToken` to see how performance fees are charged.
    /// @param _performanceFeeStrategist The new performance fee.
    function setPerformanceFeeStrategist(uint256 _performanceFeeStrategist) external whenNotPaused {
        _onlyGovernanceOrStrategist();
        require(_performanceFeeStrategist <= maxPerformanceFee, "Excessive strategist performance fee");
        performanceFeeStrategist = _performanceFeeStrategist;
        emit SetPerformanceFeeStrategist(_performanceFeeStrategist);
    }

    /// @notice Sets the performance fee taken by the treasury on the harvests.
    ///         The fee is taken at the time of harvest reporting for both the underlying token and additional tokens.
    ///         For the underlying token, the fee is used to issue new shares for the treasury.
    ///         The new performance fee should be less than `maxPerformanceFee`.
    ///         This can be called by either governance or strategist.
    /// @dev See `reportHarvest` and `reportAdditionalToken` to see how performance fees are charged.
    /// @param _performanceFeeGovernance The new performance fee.
    function setPerformanceFeeGovernance(uint256 _performanceFeeGovernance) external whenNotPaused {
        _onlyGovernanceOrStrategist();
        require(_performanceFeeGovernance <= maxPerformanceFee, "Excessive governance performance fee");
        performanceFeeGovernance = _performanceFeeGovernance;
        emit SetPerformanceFeeGovernance(_performanceFeeGovernance);
    }

    /// @notice Sets the management fee taken by the treasury on the AUM in the sett.
    ///         The fee is calculated at the time of `reportHarvest` and is used to issue new shares for the treasury.
    ///         The new management fee should be less than `maxManagementFee`.
    ///         This can be called by either governance or strategist.
    /// @dev See `_handleFees` to see how the management fee is calculated.
    /// @param _fees The new management fee.
    function setManagementFee(uint256 _fees) external whenNotPaused {
        _onlyGovernanceOrStrategist();
        require(_fees <= maxManagementFee, "Excessive management fee");
        managementFee = _fees;
        emit SetManagementFee(_fees);
    }

    /// === Strategist level operations that can be done even when paused ==

    /// @notice Withdraws all funds from the strategy back to the sett.
    ///         This can be called by either governance or strategist.
    /// @dev This calls `_withdrawAll` on the strategy and transfers the balance to the sett.
    function withdrawToVault() external {
        _onlyGovernanceOrStrategist();
        IStrategy(strategy).withdrawToVault();
    }

    /// @notice Sends balance of any extra token earned by the strategy (from airdrops, donations etc.) 
    ///         to the badgerTree for emissions.
    ///         The `_token` should be different from any tokens managed by the strategy.
    ///         This can only be called by either strategist or governance.
    /// @dev See `BaseStrategy.emitNonProtectedToken` for details.
    /// @param _token Address of the token to be emitted.
    function emitNonProtectedToken(address _token) external {
        _onlyGovernanceOrStrategist();

        IStrategy(strategy).emitNonProtectedToken(_token);
    }

    /// @notice Sweeps the balance of an extra token from the vault and strategy and sends it to governance.
    ///         The `_token` should be different from any tokens managed by the strategy.
    ///         This can only be called by either strategist or governance.
    /// @dev Sweeping doesn't take any fee.
    /// @param _token Address of the token to be swept.
    function sweepExtraToken(address _token) external {
        _onlyGovernanceOrStrategist();
        require(address(token) != _token, "No want");

        IStrategy(strategy).withdrawOther(_token);
        // Send all `_token` we have
        // Safe because `withdrawOther` will revert on protected tokens  
        // Done this way works for both a donation to strategy or to vault
        IERC20Upgradeable(_token).safeTransfer(governance, IERC20Upgradeable(_token).balanceOf(address(this)));
    }

    /// @notice Deposits the available balance of the underlying token into the strategy.
    ///         The strategy then uses the amount for yield-generating activities.
    ///         This can be called by either the keeper or governance.
    ///         Note that earn cannot be called when deposits are paused.
    /// @dev Pause is enforced at the Strategy level (this allows to still earn yield when the Vault is paused)
    function earn() external {
        require(!pausedDeposit, "pausedDeposit"); // dev: deposits are paused, we don't earn as well
        _onlyAuthorizedActors();

        uint256 _bal = available();
        token.safeTransfer(strategy, _bal);
        IStrategy(strategy).earn();
    }

    /// @notice Pauses only deposits.
    ///         This can be called by either guardian or governance.
    function pauseDeposits() external {
        _onlyAuthorizedPausers();
        pausedDeposit = true;
        emit PauseDeposits(msg.sender);
    }
    
    /// @notice Unpauses deposits.
    ///         This can only be called by governance.
    function unpauseDeposits() external {
        _onlyGovernance();
        pausedDeposit = false;
        emit UnpauseDeposits(msg.sender);
    }

    /// @notice Pauses everything.
    ///         This can be called by either guardian or governance.
    function pause() external {
        _onlyAuthorizedPausers();
        _pause();
    }

    /// @notice Unpauses everything
    ///         This can only be called by governance.
    function unpause() external {
        _onlyGovernance();
        _unpause();
    }

    /// ===== Internal Implementations =====

    /// @notice Deposits `_amount` tokens, issuing shares to `recipient`. 
    ///         Note that deposits are not accepted when `pausedDeposit` is true. 
    /// @dev This is the actual deposit operation.
    ///      Deposits are based on the realized value of underlying assets between Sett & associated Strategy
    /// @param _recipient Address to issue the Sett shares to.
    /// @param _amount Quantity of tokens to deposit. 
    function _depositFor(address _recipient, uint256 _amount) internal nonReentrant {
        require(_recipient != address(0), "Address 0");
        require(_amount != 0, "Amount 0");
        require(!pausedDeposit, "pausedDeposit"); // dev: deposits are paused

        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _mintSharesFor(_recipient, _after.sub(_before), _pool);
    }

    /// @dev See `_depositWithAuthorization`
    function _depositWithAuthorization(uint256 _amount, bytes32[] memory proof) internal {
        _depositForWithAuthorization(msg.sender, _amount, proof);
    }

    /// @dev Verifies that `_recipient` is authorized to deposit `_amount` based on the guestlist.
    ///      See `_depositFor` for deposit details.
    function _depositForWithAuthorization(
        address _recipient,
        uint256 _amount,
        bytes32[] memory proof
    ) internal {
        if (address(guestList) != address(0)) {
            require(guestList.authorized(_recipient, _amount, proof), "GuestList: Not Authorized");
        }
        _depositFor(_recipient, _amount);
    }


    /// @notice Redeems `_shares` for an appropriate amount of tokens.
    /// @dev This is the actual withdraw operation.
    ///      Withdraws from strategy positions if sett doesn't contain enough tokens to process the withdrawal. 
    ///      Calculates withdrawal fees and issues corresponding shares to treasury.
    ///      No rebalance implementation for lower fees and faster swaps
    /// @param _shares Quantity of shares to redeem. 
    function _withdraw(uint256 _shares) internal nonReentrant {
        require(_shares != 0, "0 Shares");

        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _toWithdraw = r.sub(b);
            IStrategy(strategy).withdraw(_toWithdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _toWithdraw) {
                r = b.add(_diff);
            }
        }
        uint256 _fee = _calculateFee(r, withdrawalFee);

        // Send funds to user
        token.safeTransfer(msg.sender, r.sub(_fee));

        // After you burned the shares, and you have sent the funds, adding here is equivalent to depositing
        // Process withdrawal fee
        if(_fee > 0) {
            address cachedTreasury = treasury;
            uint256 feeInShares = _mintSharesFor(cachedTreasury, _fee, balance().sub(_fee));
            emit WithdrawalFee(cachedTreasury, address(this), feeInShares, block.number, block.timestamp);
        }
    }

    /// @dev Helper function to calculate fees.
    /// @param amount Amount to calculate fee on.
    /// @param feeBps The fee to be charged in basis points.
    /// @return Amount of fees to take.
    function _calculateFee(uint256 amount, uint256 feeBps) internal pure returns (uint256) {
        if (feeBps == 0) {
            return 0;
        }
        uint256 fee = amount.mul(feeBps).div(MAX_BPS);
        return fee;
    }

    /// @dev Helper function to calculate governance and strategist performance fees. Make sure to use it to get paid!
    /// @param _amount Amount to calculate fee on.
    /// @return Tuple containing amount of (governance, strategist) fees to take.
    function _calculatePerformanceFee(uint256 _amount)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 governancePerformanceFee = _calculateFee(_amount, performanceFeeGovernance);

        uint256 strategistPerformanceFee = _calculateFee(_amount, performanceFeeStrategist);

        return (governancePerformanceFee, strategistPerformanceFee);
    }

    /// @dev Helper function to issue shares to `recipient` based on an input `_amount` and `_pool` size.
    /// @param recipient Address to issue shares to.
    /// @param _amount Amount to issue shares on.
    /// @param _pool Pool size to use while calculating amount of shares to mint.
    /// @return shares Amount of shares minted
    function _mintSharesFor(
        address recipient,
        uint256 _amount,
        uint256 _pool
    ) internal returns (uint256 shares) {
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }

        if(shares != 0) {
            _mint(recipient, shares);
        }
    }

    /// @dev Helper function that issues shares based on performance and management fee when a harvest is reported.
    /// @param _harvestedAmount The harvested amount to take fee on.
    /// @param harvestTime Time of harvest (block.timestamp).
    function _handleFees(uint256 _harvestedAmount, uint256 harvestTime) internal {
        (uint256 feeGovernance, uint256 feeStrategist) = _calculatePerformanceFee(_harvestedAmount);
        uint256 duration = harvestTime.sub(lastHarvestedAt);

        // Management fee is calculated against the assets before harvest, to make it fair to depositors
        uint256 management_fee = managementFee > 0 ? managementFee.mul(balance().sub(_harvestedAmount)).mul(duration).div(SECS_PER_YEAR).div(MAX_BPS) : 0;
        uint256 totalGovernanceFee = feeGovernance.add(management_fee);

        // Pool size is the size of the pool minus the fees, this way 
        // it's equivalent to sending the tokens as rewards after the harvest
        // and depositing them again
        uint256 _pool = balance().sub(totalGovernanceFee).sub(feeStrategist);

        // Minted fee shares for accounting events 
        uint256 feeInShares;

        // uint != is cheaper and equivalent to >
        if (totalGovernanceFee != 0) {
            address cachedTreasury = treasury;
            feeInShares = _mintSharesFor(cachedTreasury, totalGovernanceFee, _pool);
            emit PerformanceFeeGovernance(cachedTreasury, address(this), feeInShares, block.number, block.timestamp);
        }

        if (feeStrategist != 0 && strategist != address(0)) {
            // NOTE: adding feeGovernance backed to _pool as shares would have been issued for it.
            address cachedStrategist = strategist;
            feeInShares = _mintSharesFor(cachedStrategist, feeStrategist, _pool.add(totalGovernanceFee));
            emit PerformanceFeeStrategist(cachedStrategist, address(this), feeInShares, block.number, block.timestamp);
        }
    }
}
/**
 *Submitted for verification at FtmScan.com on 2022-04-09
*/

pragma experimental ABIEncoderV2;

// File: Address.sol

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: Context.sol

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

// File: IERC20.sol

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

// File: Math.sol

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

// File: SafeMath.sol

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

// File: ipriceoracle.sol

interface IPriceOracle {
    function getPrice() external view returns (uint256);
}

// File: uniswap.sol

// Feel free to change the license, but this is what we use

// Feel free to change this version of Solidity. We support >=0.6.0 <0.7.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

// File: ERC20.sol

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
    using Address for address;

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    function _setupDecimals(uint8 decimals_) internal {
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

// File: Ownable.sol

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
contract Ownable is Context {
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

// File: lpHolderUniV2.sol

// Feel free to change the license, but this is what we use

// Feel free to change this version of Solidity. We support >=0.6.0 <0.7.0;

interface IMasterChefv2 {
    function harvest(uint256 pid, address to) external;

    function emergencyWithdraw(uint256 _pid) external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function lqdrPerBlock() external view returns (uint256);

    function lpToken(uint256 pid) external view returns (address);

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (uint256, uint256);

}

interface ERC20Decimals {
    function decimals() external view returns (uint256);
}


interface IStrat {
    function strategist() external view returns (address);
    function keeper() external view returns (address);
    function want() external view returns (address);
    function wantAvailable() external view returns(uint256);
    function provideWant(uint256 _wantAmount) external; 
    function totalDebt() external view returns (uint256);
    function debtJoint() external view returns (uint256);
    function adjustJointDebtOnWithdraw(uint256 _debtProportion) external;
    function getOraclePrice() external view returns (uint256);
    function isInProfit() external view returns(bool);
    function estimatedTotalAssets() external view returns(uint256); 
}

/// @title Manages LP from two provider strats
/// @author Robovault
/// @notice This contract takes tokens from two provider strats creates LP and manages the position 
/// @dev Design to interact with two strategies from single asset vaults 


contract jointLPHolderUniV2 is Ownable {

    using Address for address;
    using SafeMath for uint256;
    
    /// @notice Do we check oracle price vs lp price when rebalancing / withdrawing
    // helps avoid sandwhich attacks
    bool public doPriceCheck = true;
    uint256 internal numTokens = 2;
    uint256 public slippageAdj = 9900; // 99%
    uint256 constant BASIS_PRECISION = 10000;
    uint256 constant STD_PRECISION = 1e8;
    uint256 public rebalancePercent = 10000;
    /// @notice to make sure we don't try to do tiny rebalances with insufficient swap amount when withdrawing have some buffer 
    uint256 bpsRebalanceDiff = 50;
    // @we rebalance if debt ratio for either assets goes above this ratio 
    uint256 debtUpper = 10250;
    // @max difference between LP & oracle prices to complete rebalance / withdraw 
    uint256 public priceSourceDiff = 500; // 5% Default
    bool public initialisedStrategies = false; 

    address keeper; 
    address strategist;

    // this relative to STD_PRECISION so 1e14 is 1 / 1e4 
    uint256 lpDust = 1e4; 

    IUniswapV2Pair public lp;
    IERC20[] public tokens;
    IERC20[] public rewardTokens;

    IMasterChefv2 farm;
    IUniswapV2Router01 router;
    address weth;
    uint256 farmPid;

    mapping (IERC20 => address) public strategies; 

    constructor (
        address _lp, 
        address _farm,
        uint256 _pid,
        address _router,
        address _rewardToken

    ) public {
        lp = IUniswapV2Pair(_lp);
        IERC20(address(lp)).approve(_router, uint256(-1));

        farmPid = _pid;
        IERC20 newToken0 = IERC20(lp.token0());
        newToken0.approve(_router, uint256(-1));
        tokens.push(newToken0);

        IERC20 newToken1 = IERC20(lp.token1());
        newToken1.approve(_router, uint256(-1));
        tokens.push(newToken1);

        farm = IMasterChefv2(_farm);
        router = IUniswapV2Router01(_router);
        weth = router.WETH();
        rewardTokens.push(IERC20(_rewardToken));

        IERC20(_rewardToken).approve(_router, uint256(-1));
        lp.approve(_farm, uint256(-1));


    }

    function setStrategist(address _strategist) external onlyAuthorized {
        require(_strategist != address(0));
        strategist = _strategist;
    }

    function setKeeper(address _keeper) external onlyAuthorized {
        require(_keeper != address(0));
        keeper = _keeper;
    }

    function setLpDust(uint256 _lpDust) external onlyAuthorized {
        lpDust = _lpDust;
    }


    function initaliseStrategies(address[] memory _strategies) external onlyAuthorized {
        require(initialisedStrategies == false);
        initialisedStrategies = true;

        for (uint i = 0; i < numTokens; i++){
            IStrat strategy = IStrat(_strategies[i]);
            strategies[IERC20(strategy.want())] = address(strategy);
        }
    }

    function _isStrategy(address _strategy) internal view returns(bool) {
        bool isStrategy = false;
        for (uint256 i = 0; i < numTokens; i++){
            if (_strategy == strategies[tokens[i]]){
                isStrategy = true;
            }
        }
        return (isStrategy);
    } 

    // modifiers
    modifier onlyStrategies() {
        require(_isStrategy(msg.sender));
        _;
    }

    modifier onlyAuthorized() {
        _onlyAuthorized();
        _;
    }

    function _onlyStrategist() internal {
        require(msg.sender == strategist);
    }


    modifier onlyKeepers() {
        _onlyKeepers();
        _;
    }

    function _onlyAuthorized() internal {
        require(msg.sender == strategist || msg.sender == owner());
    }

    function _onlyKeepers() internal {
        require(
            msg.sender == keeper ||
            msg.sender == strategist ||
            msg.sender == owner()

        );
    }

    /// @notice for doing price check against oracle price + setting max difference 
    function setPriceSource(bool _doPriceCheck, uint256 _priceSourceDiff) external onlyAuthorized {
        doPriceCheck = _doPriceCheck;
        priceSourceDiff = _priceSourceDiff;

    }

    /// @notice set other paramaters used by jointLP 
    function setParamaters(uint256 _slippageAdj, uint256 _bpsRebalanceDiff, uint256 _rebalancePercent, uint256 _debtUpper) external onlyAuthorized {
        slippageAdj = _slippageAdj;
        bpsRebalanceDiff = _bpsRebalanceDiff;
        rebalancePercent = _rebalancePercent;
        debtUpper = _debtUpper;
    }

    /// @notice here we withdraw from farm 
    function removeFromFarmAuth() external onlyAuthorized {
        farm.emergencyWithdraw(farmPid);
    }

    /// @notice called in emergency to pull all funds from LP and send tokens back to provider strats
    function withdrawAllFromJoint() external onlyAuthorized {
        uint256 _debtProportion = BASIS_PRECISION;
        _rebalanceDebtInternal(_debtProportion);
        _withdrawLp(_debtProportion);
        for (uint256 i = 0; i < numTokens; i++){
            address strategy = strategies[tokens[i]];
            tokens[i].transfer(strategy, tokens[i].balanceOf(address(this)));
            IStrat(strategy).adjustJointDebtOnWithdraw(_debtProportion);
        }
    }

    /// @notice called in emergency to pull all funds from LP and send tokens back to provider strats while not rebalancing
    function withdrawAllFromJointNoRebalance() external onlyAuthorized {

        _withdrawLp(BASIS_PRECISION);
        for (uint256 i = 0; i < numTokens; i++){
            address strategy = strategies[tokens[i]];
            tokens[i].transfer(strategy, tokens[i].balanceOf(address(this)));
            IStrat(strategy).adjustJointDebtOnWithdraw(BASIS_PRECISION);
        }
    }


    /// @notice called by either of the provider strategies 
    /// pulls in want from both provider strategies to create LP and deposit to farm 
    function addToJoint() external onlyStrategies {
        // proportion of want in LP that is pulled as when we add we do so prporitionally from each strategy 
        // initialise to uint(-1) so we can take min while looping through tokens 
        uint256 lpBalancePull = uint256(-1);
        uint256 amountInLp;
        uint256 wantAmount; 
        for (uint256 i = 0; i < numTokens; i++){
            amountInLp = getLpReserves(i);
            wantAmount = IStrat(strategies[tokens[i]]).wantAvailable();
            lpBalancePull = Math.min(lpBalancePull, wantAmount.mul(STD_PRECISION).div(amountInLp));
        }
        
        bool providerPercentLargerThanDust = lpBalancePull > lpDust;

        // here we make sure the % of want added from both strats is more than lpDust 
        if (providerPercentLargerThanDust) {
            _processWantFromProviders(lpBalancePull);
        }

        
    


    }

    function _processWantFromProviders(uint256 _lpBalancePull) internal {
        uint256 amountInLp;
        uint256 wantAmount; 

        for (uint256 i = 0; i < numTokens; i++){
            amountInLp = getLpReserves(i);
            wantAmount = Math.min(IStrat(strategies[tokens[i]]).wantAvailable(), amountInLp.mul(_lpBalancePull).div(STD_PRECISION));
            IStrat(strategies[tokens[i]]).provideWant(wantAmount);
        }

        _depositLp();
        _depositToFarm();

    }

    /// @notice here we rebalance if prices have moved and pushed one of the debt ratios above debt upper 
    // we first check price difference of LP vs oracles to make sure no price maniupation
    // we then check debt ratio for one of the tokens is > debt upper 
    // we then call rebalance Debt Internal 
    // finally we send the rebalanced tokens back to the associated strategy & adjust it's JointDebt 
    function rebalanceDebt() external onlyKeepers {
        require(_testPriceSource());
        require(calcDebtRatioToken(0) > debtUpper || calcDebtRatioToken(1) > debtUpper);
        _rebalanceDebtInternal(rebalancePercent);
        _adjustDebtOnRebalance();

    }

    /// @notice checks LP price against oracle prices 
    function _testPriceSource() internal view returns (bool) {
        if (doPriceCheck){
            uint256 _amountIn = tokens[0].totalSupply();
            uint256 lpPrice = convertAtoB(address(tokens[0]), address(tokens[1]), _amountIn);
            uint256 oraclePrice = convertAtoBOracle(address(tokens[0]), address(tokens[1]), _amountIn);
            uint256 priceSourceRatio = lpPrice.mul(BASIS_PRECISION).div(oraclePrice);

            return (priceSourceRatio > BASIS_PRECISION.sub(priceSourceDiff) &&
                priceSourceRatio < BASIS_PRECISION.add(priceSourceDiff));


        }
        return true;
    }

    /// @notice rebalances the position to bring back to delta neutral position 
    // we first find the difference between the debt ratios 
    // we remove a portion of the LP equal to half of the difference of the debt ratios in LP (adjusted by rebalcne percent)
    // we then swap the asset which has the lower debt ratio for the asset with higher debt ratio 
    function _rebalanceDebtInternal(uint256 _rebalancePercent) internal {
        // this will be the % of balance for either short A or short B swapped 
        uint256 swapAmt;
        uint256 lpRemovePercent;
        uint256 debtRatio0 = calcDebtRatioToken(0);
        uint256 debtRatio1 = calcDebtRatioToken(1);


        //. @notice we add some noise to check there is big enough difference between the debt ratios (0.5%) as we also call this during liquidate Position All
        if (debtRatio0 > debtRatio1.add(bpsRebalanceDiff)) {
            lpRemovePercent = (debtRatio0.sub(debtRatio1)).div(2).mul(_rebalancePercent).div(BASIS_PRECISION);
            _withdrawLp(lpRemovePercent);
            swapExactFromTo(address(tokens[1]), address(tokens[0]), tokens[1].balanceOf(address(this)));
        }

        if (debtRatio1 > debtRatio0.add(bpsRebalanceDiff)) {
            lpRemovePercent = (debtRatio1.sub(debtRatio0)).div(2).mul(_rebalancePercent).div(BASIS_PRECISION);
            _withdrawLp(lpRemovePercent);
            swapExactFromTo(address(tokens[0]), address(tokens[1]), tokens[0].balanceOf(address(this)));
        }

    }

    /// @notice after a rebalance, tokens in excess of LP are returned to the provider strategies 
    // we also adjust the jointDebt paramater which is essentially the debt from the provider strat to the joint LP holder 
    function _adjustDebtOnRebalance() internal {
        uint256 bal0 = tokens[0].balanceOf(address(this));
        uint256 bal1 = tokens[1].balanceOf(address(this));
        address strategy0 = strategies[tokens[0]];
        address strategy1 = strategies[tokens[1]];

        tokens[0].transfer(strategy0, bal0);
        tokens[1].transfer(strategy0, bal1);

        IStrat(strategy0).adjustJointDebtOnWithdraw(bal0.mul(BASIS_PRECISION).div(debtOutstanding(address(tokens[0]))));
        IStrat(strategy1).adjustJointDebtOnWithdraw(bal1.mul(BASIS_PRECISION).div(debtOutstanding(address(tokens[1]))));

    }

    /// @notice debt from provider strat to joint LP holder 
    function debtOutstanding(address _token) public view returns(uint256) {
        address strategy = strategies[IERC20(_token)];
        return(IStrat(strategy).debtJoint());
    }

    /// @notice calculates the Profit / Loss by comparing balances of each token vs amount of Debt 
    function calculateProfit(address _token) public view returns(uint256 _loss, uint256 _profit) {

        uint256 debt = debtOutstanding(_token);
        uint256 tokenIndex;

        if (lp.token0() == _token) {
            tokenIndex = 0;
        } else {
            tokenIndex = 1;
        }


        uint256 balance = balanceTokenWithRebalance(tokenIndex);

        if (balance >= debt) {
            _profit = balance.sub(debt);
            _loss = 0;
        } else {
            _profit = 0;
            _loss = debt.sub(balance);
        }

    }

    function calcDebtRatioToken(uint256 _tokenIndex) public view returns(uint256) {
        return(debtOutstanding(address(tokens[_tokenIndex])).mul(BASIS_PRECISION).div(balanceToken(_tokenIndex))); 
    }

    function calcDebtRatio() public view returns(uint256, uint256) {
        return(calcDebtRatioToken(0), calcDebtRatioToken(1));
    }

    /// @notice checks that both provider strategies are in profit 
    function allStratsInProfit() public view returns(bool) {
        return(IStrat(strategies[tokens[0]]).isInProfit() && IStrat(strategies[tokens[1]]).isInProfit());


    }

    function balanceToken(uint256 _tokenIndex) public view returns(uint256) {
        uint256 lpAmount = getLpReserves(_tokenIndex);
        uint256 tokenBalance = lpBalance().mul(lpAmount).div(lp.totalSupply());
        return(tokenBalance);
    }

    /// @notice here we calculate the balances of token if we rebalance 
    // this is because as prices in LP move one of the provider strat will be in profit while the other will be in loss
    // here we calculate if we rebalance what will the balances of each token be 
    function balanceTokenWithRebalance(uint256 _tokenIndex) public view returns(uint256) {

        uint256 tokenBalance0 = balanceToken(0);
        uint256 tokenBalance1 = balanceToken(1);
        uint256 debtRatio0 = calcDebtRatioToken(0);
        uint256 debtRatio1 = calcDebtRatioToken(1);

        uint256 swapPct;

        if (debtRatio0 > debtRatio1) {
            swapPct = (debtRatio0.sub(debtRatio1)).div(2);
            uint256 swapAmount = tokenBalance1.mul(swapPct).div(BASIS_PRECISION); 
            uint256 amountIn = convertAtoB(address(tokens[1]), address(tokens[0]), swapAmount);
            tokenBalance0 = tokenBalance0.add(amountIn);
            tokenBalance1 = tokenBalance1.sub(swapAmount);

        } else {
            swapPct = (debtRatio1.sub(debtRatio0)).div(2);
            uint256 swapAmount = tokenBalance0.mul(swapPct).div(BASIS_PRECISION); 
            uint256 amountIn = convertAtoB(address(tokens[0]), address(tokens[1]), swapAmount);
            tokenBalance0 = tokenBalance0.sub(swapAmount);
            tokenBalance1 = tokenBalance1.add(amountIn);
        }

        if (_tokenIndex == 0) {
            return(tokenBalance0);
        } else {
            return(tokenBalance1);
        }

    }

    // how much of the lP token do we hold 
    function lpBalance() public view returns(uint256){
        return(lp.balanceOf(address(this)).add(countLpPooled()));
    }

    /// @notice simple helper function to convert tokens based on LP price 
    function convertAtoB(address _tokenA, address _tokenB, uint256 _amountIn) 
        public
        view
        returns (uint256 _amountOut)
    {
        uint256 token0Amt = getLpReserves(0);
        uint256 token1Amt = getLpReserves(1);

        if (_tokenA == address(tokens[0])) { 
            return(_amountIn.mul(token1Amt).div(token0Amt));
        } else {
            return(_amountIn.mul(token0Amt).div(token1Amt));
        }
    }
    // @notice simple helper function to convert tokens based on oracle prices 
    function convertAtoBOracle(address _tokenA, address _tokenB, uint256 _amountIn) 
        public
        view
        returns (uint256 _amountOut)
    {
        address StratA = strategies[IERC20(_tokenA)];
        address StratB = strategies[IERC20(_tokenB)];

        uint256 priceA = IStrat(StratA).getOraclePrice();
        uint256 priceB = IStrat(StratB).getOraclePrice();

        return(priceA.mul(_amountIn).div(priceB));
    }


    function getLpReserves(uint256 _index)
        public
        view
        returns (uint256 _balance)
    {
        (uint112 reserves0, uint112 reserves1, ) = lp.getReserves();
        if (_index == 0) { 
            return(uint256(reserves0));
        } else {
            return(uint256(reserves1));
        }
    }

    function countLpPooled() public view returns (uint256) {
        (uint256 _amount, ) = farm.userInfo(farmPid, address(this));
        return _amount;
    }

    function _depositLp() internal {

        uint256 _amount0 = tokens[0].balanceOf(address(this));
        uint256 _amount1 = tokens[1].balanceOf(address(this));
        if (_amount0 >0 && _amount1 >0){

            router.addLiquidity(
                address(tokens[0]),
                address(tokens[1]),
                _amount0,
                _amount1,
                _amount0.mul(slippageAdj).div(BASIS_PRECISION),
                _amount1.mul(slippageAdj).div(BASIS_PRECISION),
                address(this),
                now
            );

        }


    }

    function _depositToFarm() internal {
        uint256 lpAmt = lp.balanceOf(address(this));
        if(lpAmt > 0) { 
            farm.deposit(farmPid, lpAmt, address(this)); /// deposit LP tokens to farm
        }

    }

    function _withdrawFromFarm(uint256 _amount) internal {
        if (_amount > 0){
            uint256 _lpUnpooled = lp.balanceOf(address(this));
            if (_amount > _lpUnpooled){
                farm.withdraw(farmPid, _amount.sub(_lpUnpooled), address(this));
            }
            
        }
        
    }

    /// @notice each of the provider strategies can withdraw a proportion of the tokens they've provided 
    // here we first check prices for manipulation 
    // then we rebalance based on the portion being withdrawn this means each provider strat takes roughly the same P&L 
    // we then withdraw the required LP and return the required tokens to each provider strat & adjust the jointDebt paramater
    function withdraw(uint256 _debtProportion) external onlyStrategies {
        // when withdrawing small amounts transaction will potentially fail
        _debtProportion = Math.max(_debtProportion, 50);

        require(_testPriceSource());
        _rebalanceDebtInternal(_debtProportion);
        _withdrawLp(_debtProportion);
        for (uint256 i = 0; i < numTokens; i++){
            address strategy = strategies[tokens[i]];
            tokens[i].transfer(strategy, tokens[i].balanceOf(address(this)));
            IStrat(strategy).adjustJointDebtOnWithdraw(_debtProportion);
        }

    }

    function _withdrawLp(uint256 _debtProportion) internal {
        
        uint256 lpOut = lpBalance().mul(_debtProportion).div(BASIS_PRECISION);
        _withdrawFromFarm(lpOut);
        _removeAllLp(lpOut);
    }

    function _removeAllLp(uint256 _amount) internal {
        uint256 amount0 = getLpReserves(0);
        uint256 amount1 = getLpReserves(1);

        uint256 lpIssued = lp.totalSupply();

        uint256 amount0Min =
            _amount.mul(amount0).mul(slippageAdj).div(BASIS_PRECISION).div(
                lpIssued
            );
        uint256 amount1Min =
            _amount.mul(amount1).mul(slippageAdj).div(BASIS_PRECISION).div(
                lpIssued
            );
        router.removeLiquidity(
            address(tokens[0]),
            address(tokens[1]),
            _amount,
            amount0Min,
            amount1Min,
            address(this),
            now
        );
    }

    function harvestRewards() external onlyKeepers {
        _harvestInternal();
    }

    function _harvestInternal() internal {
        //gauge.claim_rewards();
        farm.harvest(farmPid, address(this));
        
        for (uint256 i = 0; i < rewardTokens.length; i++){
            uint256 farmAmount = rewardTokens[i].balanceOf(address(this));
            _sellRewardTokens(rewardTokens[i],farmAmount);
        }

    }

    function swapExactFromTo(
        address _swapFrom,
        address _swapTo,
        uint256 _amountIn
    )   internal 
        returns (uint256 _slippage)
    {
        IERC20 fromToken = IERC20(_swapFrom);
        uint256 fromBalance = fromToken.balanceOf(address(this));
        uint256 expectedAmountOut = convertAtoB(_swapFrom, _swapTo, _amountIn);
        // do this to avoid small swaps that will fail
        if (fromBalance < 1 || expectedAmountOut < 1) return (0);
        uint256 minOut = 0;
        uint256[] memory amounts =
            router.swapExactTokensForTokens(
                _amountIn,
                minOut,
                getTokenOutPath(address(_swapFrom), address(_swapTo)),
                address(this),
                now
            );
        uint256 _slippage = expectedAmountOut.sub(amounts[amounts.length - 1]);        
    }

    // this sells reward tokenss in proportion to their debt & automatically sends proceeds to relevant strategy 
    function _sellRewardTokens(IERC20 rewardToken, uint256 farmAmount) internal {

        //uint256 farmAmount = rewardToken.balanceOf(address(this));
        

        for (uint256 i = 0; i < numTokens; i++){
            uint256 balance = rewardToken.balanceOf(address(this));
            address strategyTo = strategies[tokens[i]];
            uint256 saleAmount = farmAmount.mul(getDebtProportion(address(tokens[i]))).div(BASIS_PRECISION);
            router.swapExactTokensForTokens(
                Math.min(saleAmount,balance),
                0,
                getTokenOutPath(address(rewardToken), address(tokens[i])),
                address(this),
                now
            );
            
            tokens[i].transfer(strategyTo, tokens[i].balanceOf(address(this)));
        }
    }

    function getDebtProportion(address _token) public view returns(uint256) {
        return((BASIS_PRECISION).div(2));
    }

    function getTokenOutPath(address _token_in, address _token_out)
        internal
        view
        returns (address[] memory _path)
    {
        bool is_weth =
            _token_in == address(weth) || _token_out == address(weth);
        _path = new address[](is_weth ? 2 : 3);
        _path[0] = _token_in;
        if (is_weth) {
            _path[1] = _token_out;
        } else {
            _path[1] = address(weth);
            _path[2] = _token_out;
        }
    }


}
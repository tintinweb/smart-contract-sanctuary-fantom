/**
 *Submitted for verification at FtmScan.com on 2022-03-04
*/

pragma solidity 0.6.12;
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

// File: IMasterChef.sol

interface IMasterchef {
    // Info of each pool.
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Tokenss to distribute per block.
        uint256 lastRewardBlock; // Last block number that Tokens distribution occurs.
        uint256 acctokenPerShare; // Accumulated Tokens per share, times 1e12. See below.
    }

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
    }

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256, address) external view returns (UserInfo memory);

    function poolInfo(uint256) external view returns (PoolInfo memory);
}

// File: ISolidRouter.sol

interface ISolidFactory {
    function getPair(address token0, address token1, bool stable) external view returns (address);
}

interface ISolidRouter {
    struct route {
        address from;
        address to;
        bool stable;
    }

    function factory() external view returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint amountIn, route[] memory routes) external view returns (uint[] memory amounts);

}

// File: ISolidex.sol

interface ISolidex {
    struct Amounts {
        uint256 solid;
        uint256 sex;
    }

    function deposit(address _pair, uint256 _amount) external; 
    function withdraw(address _pair, uint256 _amount) external; 
    function getReward(address[] calldata _pairs) external; 
    function pendingRewards(address _account, address[] calldata pairs) external view returns (Amounts[] memory);
    function userBalances(address _account, address _pair) external view returns (uint256);
}

// File: IUniswapV2Factory.sol

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: IUniswapV2Pair.sol

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

// File: IUniswapV2Router01.sol

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

// File: ySwapper.sol

interface ITradeFactory {
    function enable(address, address) external;
}

abstract contract ySwapper {
    using SafeERC20 for IERC20;
    // TODO: not working for clonables ! 
    address public tradeFactory =
        address(0xD3f89C21719Ec5961a3E6B0f9bBf9F9b4180E9e9);

    bool public tradesEnabled;
   
    // Implement in contract using ySwaps. 
    // should return the list of tokens to be swapped and a list of tokens to be swapped to
    function getYSwapTokens() internal view virtual returns (address[] memory, address[] memory);

    // WARNING this is a manual permissioned function
    // should call internalFunction and use onlyROLEs
    // if you don't want this function, just override with empty function
    function removeTradeFactoryPermissions() external virtual;
    
    // WARNING this is a manual permissioned function
    // should call internalFunction and use onlyROLEs
    // if you don't want this function, just override with empty function
    function updateTradeFactoryPermissions(address _tradeFactory) external virtual;

    function _setUpTradeFactory() internal {
        //approve and set up trade factory
        tradesEnabled = true;
        (address[] memory tokensToEnable, address[] memory toTokens) = getYSwapTokens();

        for(uint i; i < tokensToEnable.length; i++) {
            _enableTradeFactoryForToken(tokensToEnable[i], toTokens[i]);
        }
    }
 
    function _enableTradeFactoryForToken(address fromToken, address toToken) internal {
        ITradeFactory tf = ITradeFactory(tradeFactory);
        IERC20(fromToken).safeApprove(address(tf), type(uint256).max);
        tf.enable(fromToken, toToken);
    }

    function _updateTradeFactory(address _newTradeFactory)
       internal 
    {
        if (tradeFactory != address(0)) {
            _removeTradeFactory();
        }

        tradeFactory = _newTradeFactory;
        _setUpTradeFactory();
    }

    function _removeTradeFactory() internal {
        address _tradeFactory = tradeFactory;
 
        (address[] memory tokens, ) = getYSwapTokens();

        for(uint i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeApprove(_tradeFactory, 0);
        }

        tradeFactory = address(0);
        tradesEnabled = false;
    }
}

// File: IUniswapV2Router02.sol

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

// File: SafeERC20.sol

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

// File: UniswapV2Library.sol

library SafeMathUniswap {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

library UniswapV2Library {
    using SafeMathUniswap for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) =
            IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) =
                getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) =
                getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: BaseStrategy.sol

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient) external returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy) external view returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}

/**
 * This interface is here for the keeper bot to use.
 */
interface StrategyAPI {
    function name() external view returns (string memory);

    function vault() external view returns (address);

    function want() external view returns (address);

    function apiVersion() external pure returns (string memory);

    function keeper() external view returns (address);

    function isActive() external view returns (bool);

    function delegatedAssets() external view returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
}

interface HealthCheck {
    function check(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding,
        uint256 totalDebt
    ) external view returns (bool);
}

/**
 * @title Yearn Base Strategy
 * @author yearn.finance
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy's performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */

abstract contract BaseStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    string public metadataURI;

    // health checks
    bool public doHealthCheck;
    address public healthCheck;

    /**
     * @notice
     *  Used to track which version of `StrategyAPI` this Strategy
     *  implements.
     * @dev The Strategy's version must match the Vault's `API_VERSION`.
     * @return A string which holds the current API version of this contract.
     */
    function apiVersion() public pure returns (string memory) {
        return "0.4.3";
    }

    /**
     * @notice This Strategy's name.
     * @dev
     *  You can use this field to manage the "version" of this Strategy, e.g.
     *  `StrategySomethingOrOtherV1`. However, "API Version" is managed by
     *  `apiVersion()` function above.
     * @return This Strategy's name.
     */
    function name() external view virtual returns (string memory);

    /**
     * @notice
     *  The amount (priced in want) of the total assets managed by this strategy should not count
     *  towards Yearn's TVL calculations.
     * @dev
     *  You can override this field to set it to a non-zero value if some of the assets of this
     *  Strategy is somehow delegated inside another part of of Yearn's ecosystem e.g. another Vault.
     *  Note that this value must be strictly less than or equal to the amount provided by
     *  `estimatedTotalAssets()` below, as the TVL calc will be total assets minus delegated assets.
     *  Also note that this value is used to determine the total assets under management by this
     *  strategy, for the purposes of computing the management fee in `Vault`
     * @return
     *  The amount of assets this strategy manages that should not be included in Yearn's Total Value
     *  Locked (TVL) calculation across it's ecosystem.
     */
    function delegatedAssets() external view virtual returns (uint256) {
        return 0;
    }

    VaultAPI public vault;
    address public strategist;
    address public rewards;
    address public keeper;

    IERC20 public want;

    // So indexers can keep track of this
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);

    event UpdatedStrategist(address newStrategist);

    event UpdatedKeeper(address newKeeper);

    event UpdatedRewards(address rewards);

    event UpdatedMinReportDelay(uint256 delay);

    event UpdatedMaxReportDelay(uint256 delay);

    event UpdatedProfitFactor(uint256 profitFactor);

    event UpdatedDebtThreshold(uint256 debtThreshold);

    event EmergencyExitEnabled();

    event UpdatedMetadataURI(string metadataURI);

    // The minimum number of seconds between harvest calls. See
    // `setMinReportDelay()` for more details.
    uint256 public minReportDelay;

    // The maximum number of seconds between harvest calls. See
    // `setMaxReportDelay()` for more details.
    uint256 public maxReportDelay;

    // The minimum multiple that `callCost` must be above the credit/profit to
    // be "justifiable". See `setProfitFactor()` for more details.
    uint256 public profitFactor;

    // Use this to adjust the threshold at which running a debt causes a
    // harvest trigger. See `setDebtThreshold()` for more details.
    uint256 public debtThreshold;

    // See note on `setEmergencyExit()`.
    bool public emergencyExit;

    // modifiers
    modifier onlyAuthorized() {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        _;
    }

    modifier onlyEmergencyAuthorized() {
        require(
            msg.sender == strategist || msg.sender == governance() || msg.sender == vault.guardian() || msg.sender == vault.management(),
            "!authorized"
        );
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == strategist, "!strategist");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance(), "!authorized");
        _;
    }

    modifier onlyKeepers() {
        require(
            msg.sender == keeper ||
                msg.sender == strategist ||
                msg.sender == governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management(),
            "!authorized"
        );
        _;
    }

    modifier onlyVaultManagers() {
        require(msg.sender == vault.management() || msg.sender == governance(), "!authorized");
        _;
    }

    constructor(address _vault) public {
        _initialize(_vault, msg.sender, msg.sender, msg.sender);
    }

    /**
     * @notice
     *  Initializes the Strategy, this is called only once, when the
     *  contract is deployed.
     * @dev `_vault` should implement `VaultAPI`.
     * @param _vault The address of the Vault responsible for this Strategy.
     * @param _strategist The address to assign as `strategist`.
     * The strategist is able to change the reward address
     * @param _rewards  The address to use for pulling rewards.
     * @param _keeper The adddress of the _keeper. _keeper
     * can harvest and tend a strategy.
     */
    function _initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) internal {
        require(address(want) == address(0), "Strategy already initialized");

        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        want.safeApprove(_vault, uint256(-1)); // Give Vault unlimited access (might save gas)
        strategist = _strategist;
        rewards = _rewards;
        keeper = _keeper;

        // initialize variables
        minReportDelay = 0;
        maxReportDelay = 86400;
        profitFactor = 100;
        debtThreshold = 0;

        vault.approve(rewards, uint256(-1)); // Allow rewards to be pulled
    }

    function setHealthCheck(address _healthCheck) external onlyVaultManagers {
        healthCheck = _healthCheck;
    }

    function setDoHealthCheck(bool _doHealthCheck) external onlyVaultManagers {
        doHealthCheck = _doHealthCheck;
    }

    /**
     * @notice
     *  Used to change `strategist`.
     *
     *  This may only be called by governance or the existing strategist.
     * @param _strategist The new address to assign as `strategist`.
     */
    function setStrategist(address _strategist) external onlyAuthorized {
        require(_strategist != address(0));
        strategist = _strategist;
        emit UpdatedStrategist(_strategist);
    }

    /**
     * @notice
     *  Used to change `keeper`.
     *
     *  `keeper` is the only address that may call `tend()` or `harvest()`,
     *  other than `governance()` or `strategist`. However, unlike
     *  `governance()` or `strategist`, `keeper` may *only* call `tend()`
     *  and `harvest()`, and no other authorized functions, following the
     *  principle of least privilege.
     *
     *  This may only be called by governance or the strategist.
     * @param _keeper The new address to assign as `keeper`.
     */
    function setKeeper(address _keeper) external onlyAuthorized {
        require(_keeper != address(0));
        keeper = _keeper;
        emit UpdatedKeeper(_keeper);
    }

    /**
     * @notice
     *  Used to change `rewards`. EOA or smart contract which has the permission
     *  to pull rewards from the vault.
     *
     *  This may only be called by the strategist.
     * @param _rewards The address to use for pulling rewards.
     */
    function setRewards(address _rewards) external onlyStrategist {
        require(_rewards != address(0));
        vault.approve(rewards, 0);
        rewards = _rewards;
        vault.approve(rewards, uint256(-1));
        emit UpdatedRewards(_rewards);
    }

    /**
     * @notice
     *  Used to change `minReportDelay`. `minReportDelay` is the minimum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the minimum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The minimum number of seconds to wait between harvests.
     */
    function setMinReportDelay(uint256 _delay) external onlyAuthorized {
        minReportDelay = _delay;
        emit UpdatedMinReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the maximum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The maximum number of seconds to wait between harvests.
     */
    function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
        maxReportDelay = _delay;
        emit UpdatedMaxReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `profitFactor`. `profitFactor` is used to determine
     *  if it's worthwhile to harvest, given gas costs. (See `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _profitFactor A ratio to multiply anticipated
     * `harvest()` gas cost against.
     */
    function setProfitFactor(uint256 _profitFactor) external onlyAuthorized {
        profitFactor = _profitFactor;
        emit UpdatedProfitFactor(_profitFactor);
    }

    /**
     * @notice
     *  Sets how far the Strategy can go into loss without a harvest and report
     *  being required.
     *
     *  By default this is 0, meaning any losses would cause a harvest which
     *  will subsequently report the loss to the Vault for tracking. (See
     *  `harvestTrigger()` for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _debtThreshold How big of a loss this Strategy may carry without
     * being required to report to the Vault.
     */
    function setDebtThreshold(uint256 _debtThreshold) external onlyAuthorized {
        debtThreshold = _debtThreshold;
        emit UpdatedDebtThreshold(_debtThreshold);
    }

    /**
     * @notice
     *  Used to change `metadataURI`. `metadataURI` is used to store the URI
     * of the file describing the strategy.
     *
     *  This may only be called by governance or the strategist.
     * @param _metadataURI The URI that describe the strategy.
     */
    function setMetadataURI(string calldata _metadataURI) external onlyAuthorized {
        metadataURI = _metadataURI;
        emit UpdatedMetadataURI(_metadataURI);
    }

    /**
     * Resolve governance address from Vault contract, used to make assertions
     * on protected functions in the Strategy.
     */
    function governance() internal view returns (address) {
        return vault.governance();
    }

    /**
     * @notice
     *  Provide an accurate conversion from `_amtInWei` (denominated in wei)
     *  to `want` (using the native decimal characteristics of `want`).
     * @dev
     *  Care must be taken when working with decimals to assure that the conversion
     *  is compatible. As an example:
     *
     *      given 1e17 wei (0.1 ETH) as input, and want is USDC (6 decimals),
     *      with USDC/ETH = 1800, this should give back 1800000000 (180 USDC)
     *
     * @param _amtInWei The amount (in wei/1e-18 ETH) to convert to `want`
     * @return The amount in `want` of `_amtInEth` converted to `want`
     **/
    function ethToWant(uint256 _amtInWei) public view virtual returns (uint256);

    /**
     * @notice
     *  Provide an accurate estimate for the total amount of assets
     *  (principle + return) that this Strategy is currently managing,
     *  denominated in terms of `want` tokens.
     *
     *  This total should be "realizable" e.g. the total value that could
     *  *actually* be obtained from this Strategy if it were to divest its
     *  entire position based on current on-chain conditions.
     * @dev
     *  Care must be taken in using this function, since it relies on external
     *  systems, which could be manipulated by the attacker to give an inflated
     *  (or reduced) value produced by this function, based on current on-chain
     *  conditions (e.g. this function is possible to influence through
     *  flashloan attacks, oracle manipulations, or other DeFi attack
     *  mechanisms).
     *
     *  It is up to governance to use this function to correctly order this
     *  Strategy relative to its peers in the withdrawal queue to minimize
     *  losses for the Vault based on sudden withdrawals. This value should be
     *  higher than the total debt of the Strategy and higher than its expected
     *  value to be "safe".
     * @return The estimated total assets in this Strategy.
     */
    function estimatedTotalAssets() public view virtual returns (uint256);

    /*
     * @notice
     *  Provide an indication of whether this strategy is currently "active"
     *  in that it is managing an active position, or will manage a position in
     *  the future. This should correlate to `harvest()` activity, so that Harvest
     *  events can be tracked externally by indexing agents.
     * @return True if the strategy is actively managing a position.
     */
    function isActive() public view returns (bool) {
        return vault.strategies(address(this)).debtRatio > 0 || estimatedTotalAssets() > 0;
    }

    /**
     * Perform any Strategy unwinding or other calls necessary to capture the
     * "free return" this Strategy has generated since the last time its core
     * position(s) were adjusted. Examples include unwrapping extra rewards.
     * This call is only used during "normal operation" of a Strategy, and
     * should be optimized to minimize losses as much as possible.
     *
     * This method returns any realized profits and/or realized losses
     * incurred, and should return the total amounts of profits/losses/debt
     * payments (in `want` tokens) for the Vault's accounting (e.g.
     * `want.balanceOf(this) >= _debtPayment + _profit`).
     *
     * `_debtOutstanding` will be 0 if the Strategy is not past the configured
     * debt limit, otherwise its value will be how far past the debt limit
     * the Strategy is. The Strategy's debt limit is configured in the Vault.
     *
     * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
     *       It is okay for it to be less than `_debtOutstanding`, as that
     *       should only used as a guide for how much is left to pay back.
     *       Payments should be made to minimize loss from slippage, debt,
     *       withdrawal fees, etc.
     *
     * See `vault.debtOutstanding()`.
     */
    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        );

    /**
     * Perform any adjustments to the core position(s) of this Strategy given
     * what change the Vault made in the "investable capital" available to the
     * Strategy. Note that all "free capital" in the Strategy after the report
     * was made is available for reinvestment. Also note that this number
     * could be 0, and you should handle that scenario accordingly.
     *
     * See comments regarding `_debtOutstanding` on `prepareReturn()`.
     */
    function adjustPosition(uint256 _debtOutstanding) internal virtual;

    /**
     * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
     * irregardless of slippage. Any excess will be re-invested with `adjustPosition()`.
     * This function should return the amount of `want` tokens made available by the
     * liquidation. If there is a difference between them, `_loss` indicates whether the
     * difference is due to a realized loss, or if there is some other sitution at play
     * (e.g. locked funds) where the amount made available is less than what is needed.
     *
     * NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
     */
    function liquidatePosition(uint256 _amountNeeded) internal virtual returns (uint256 _liquidatedAmount, uint256 _loss);

    /**
     * Liquidate everything and returns the amount that got freed.
     * This function is used during emergency exit instead of `prepareReturn()` to
     * liquidate all of the Strategy's positions back to the Vault.
     */

    function liquidateAllPositions() internal virtual returns (uint256 _amountFreed);

    /**
     * @notice
     *  Provide a signal to the keeper that `tend()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `tend()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `tend()` is not called
     *  shortly, then this can return `true` even if the keeper might be
     *  "at a loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
     *
     *  This call and `harvestTrigger()` should never return `true` at the same
     *  time.
     * @param callCostInWei The keeper's estimated gas cost to call `tend()` (in wei).
     * @return `true` if `tend()` should be called, `false` otherwise.
     */
    function tendTrigger(uint256 callCostInWei) public view virtual returns (bool) {
        // We usually don't need tend, but if there are positions that need
        // active maintainence, overriding this function is how you would
        // signal for that.
        // If your implementation uses the cost of the call in want, you can
        // use uint256 callCost = ethToWant(callCostInWei);

        return false;
    }

    /**
     * @notice
     *  Adjust the Strategy's position. The purpose of tending isn't to
     *  realize gains, but to maximize yield by reinvesting any returns.
     *
     *  See comments on `adjustPosition()`.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     */
    function tend() external onlyKeepers {
        // Don't take profits with this call, but adjust for better gains
        adjustPosition(vault.debtOutstanding());
    }

    /**
     * @notice
     *  Provide a signal to the keeper that `harvest()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `harvest()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `harvest()` is not called
     *  shortly, then this can return `true` even if the keeper might be "at a
     *  loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
     *
     *  This call and `tendTrigger` should never return `true` at the
     *  same time.
     *
     *  See `min/maxReportDelay`, `profitFactor`, `debtThreshold` to adjust the
     *  strategist-controlled parameters that will influence whether this call
     *  returns `true` or not. These parameters will be used in conjunction
     *  with the parameters reported to the Vault (see `params`) to determine
     *  if calling `harvest()` is merited.
     *
     *  It is expected that an external system will check `harvestTrigger()`.
     *  This could be a script run off a desktop or cloud bot (e.g.
     *  https://github.com/iearn-finance/yearn-vaults/blob/main/scripts/keep.py),
     *  or via an integration with the Keep3r network (e.g.
     *  https://github.com/Macarse/GenericKeep3rV2/blob/master/contracts/keep3r/GenericKeep3rV2.sol).
     * @param callCostInWei The keeper's estimated gas cost to call `harvest()` (in wei).
     * @return `true` if `harvest()` should be called, `false` otherwise.
     */
    function harvestTrigger(uint256 callCostInWei) public view virtual returns (bool) {
        uint256 callCost = ethToWant(callCostInWei);
        StrategyParams memory params = vault.strategies(address(this));

        // Should not trigger if Strategy is not activated
        if (params.activation == 0) return false;

        // Should not trigger if we haven't waited long enough since previous harvest
        if (block.timestamp.sub(params.lastReport) < minReportDelay) return false;

        // Should trigger if hasn't been called in a while
        if (block.timestamp.sub(params.lastReport) >= maxReportDelay) return true;

        // If some amount is owed, pay it back
        // NOTE: Since debt is based on deposits, it makes sense to guard against large
        //       changes to the value from triggering a harvest directly through user
        //       behavior. This should ensure reasonable resistance to manipulation
        //       from user-initiated withdrawals as the outstanding debt fluctuates.
        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > debtThreshold) return true;

        // Check for profits and losses
        uint256 total = estimatedTotalAssets();
        // Trigger if we have a loss to report
        if (total.add(debtThreshold) < params.totalDebt) return true;

        uint256 profit = 0;
        if (total > params.totalDebt) profit = total.sub(params.totalDebt); // We've earned a profit!

        // Otherwise, only trigger if it "makes sense" economically (gas cost
        // is <N% of value moved)
        uint256 credit = vault.creditAvailable();
        return (profitFactor.mul(callCost) < credit.add(profit));
    }

    /**
     * @notice
     *  Harvests the Strategy, recognizing any profits or losses and adjusting
     *  the Strategy's position.
     *
     *  In the rare case the Strategy is in emergency shutdown, this will exit
     *  the Strategy's position.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     * @dev
     *  When `harvest()` is called, the Strategy reports to the Vault (via
     *  `vault.report()`), so in some cases `harvest()` must be called in order
     *  to take in profits, to borrow newly available funds from the Vault, or
     *  otherwise adjust its position. In other cases `harvest()` must be
     *  called to report to the Vault on the Strategy's position, especially if
     *  any losses have occurred.
     */
    function harvest() external onlyKeepers {
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = vault.debtOutstanding();
        uint256 debtPayment = 0;
        if (emergencyExit) {
            // Free up as much capital as possible
            uint256 amountFreed = liquidateAllPositions();
            if (amountFreed < debtOutstanding) {
                loss = debtOutstanding.sub(amountFreed);
            } else if (amountFreed > debtOutstanding) {
                profit = amountFreed.sub(debtOutstanding);
            }
            debtPayment = debtOutstanding.sub(loss);
        } else {
            // Free up returns for Vault to pull
            (profit, loss, debtPayment) = prepareReturn(debtOutstanding);
        }

        // Allow Vault to take up to the "harvested" balance of this contract,
        // which is the amount it has earned since the last time it reported to
        // the Vault.
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        debtOutstanding = vault.report(profit, loss, debtPayment);

        // Check if free returns are left, and re-invest them
        adjustPosition(debtOutstanding);

        // call healthCheck contract
        if (doHealthCheck && healthCheck != address(0)) {
            require(HealthCheck(healthCheck).check(profit, loss, debtPayment, debtOutstanding, totalDebt), "!healthcheck");
        } else {
            doHealthCheck = true;
        }

        emit Harvested(profit, loss, debtPayment, debtOutstanding);
    }

    /**
     * @notice
     *  Withdraws `_amountNeeded` to `vault`.
     *
     *  This may only be called by the Vault.
     * @param _amountNeeded How much `want` to withdraw.
     * @return _loss Any realized losses
     */
    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `want`, up to `_amountNeeded`
        uint256 amountFreed;
        (amountFreed, _loss) = liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        want.safeTransfer(msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }

    /**
     * Do anything necessary to prepare this Strategy for migration, such as
     * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
     * value.
     */
    function prepareMigration(address _newStrategy) internal virtual;

    /**
     * @notice
     *  Transfers all `want` from this Strategy to `_newStrategy`.
     *
     *  This may only be called by the Vault.
     * @dev
     * The new Strategy's Vault must be the same as this Strategy's Vault.
     *  The migration process should be carefully performed to make sure all
     * the assets are migrated to the new address, which should have never
     * interacted with the vault before.
     * @param _newStrategy The Strategy to migrate to.
     */
    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault));
        require(BaseStrategy(_newStrategy).vault() == vault);
        prepareMigration(_newStrategy);
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }

    /**
     * @notice
     *  Activates emergency exit. Once activated, the Strategy will exit its
     *  position upon the next harvest, depositing all funds into the Vault as
     *  quickly as is reasonable given on-chain conditions.
     *
     *  This may only be called by governance or the strategist.
     * @dev
     *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
     */
    function setEmergencyExit() external onlyEmergencyAuthorized {
        emergencyExit = true;
        vault.revokeStrategy();

        emit EmergencyExitEnabled();
    }

    /**
     * Override this to add all tokens/tokenized positions this contract
     * manages on a *persistent* basis (e.g. not just for swapping back to
     * want ephemerally).
     *
     * NOTE: Do *not* include `want`, already included in `sweep` below.
     *
     * Example:
     * ```
     *    function protectedTokens() internal override view returns (address[] memory) {
     *      address[] memory protected = new address[](3);
     *      protected[0] = tokenA;
     *      protected[1] = tokenB;
     *      protected[2] = tokenC;
     *      return protected;
     *    }
     * ```
     */
    function protectedTokens() internal view virtual returns (address[] memory);

    /**
     * @notice
     *  Removes tokens from this Strategy that are not the type of tokens
     *  managed by this Strategy. This may be used in case of accidentally
     *  sending the wrong kind of token to this Strategy.
     *
     *  Tokens will be sent to `governance()`.
     *
     *  This will fail if an attempt is made to sweep `want`, or any tokens
     *  that are protected by this Strategy.
     *
     *  This may only be called by governance.
     * @dev
     *  Implement `protectedTokens()` to specify any additional tokens that
     *  should be protected from sweeping in addition to `want`.
     * @param _token The token to transfer out of this vault.
     */
    function sweep(address _token) external onlyGovernance {
        require(_token != address(want), "!want");
        require(_token != address(vault), "!shares");

        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], "!protected");

        IERC20(_token).safeTransfer(governance(), IERC20(_token).balanceOf(address(this)));
    }
}

abstract contract BaseStrategyInitializable is BaseStrategy {
    bool public isOriginal = true;
    event Cloned(address indexed clone);

    constructor(address _vault) public BaseStrategy(_vault) {}

    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external virtual {
        _initialize(_vault, _strategist, _rewards, _keeper);
    }

    function clone(address _vault) external returns (address) {
        require(isOriginal, "!clone");
        return this.clone(_vault, msg.sender, msg.sender, msg.sender);
    }

    function clone(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external returns (address newStrategy) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStrategy := create(0, clone_code, 0x37)
        }

        BaseStrategyInitializable(newStrategy).initialize(_vault, _strategist, _rewards, _keeper);

        emit Cloned(newStrategy);
    }
}

// File: IERC20Extended.sol

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

// File: Joint.sol

interface ProviderStrategy {
    function vault() external view returns (VaultAPI);

    function strategist() external view returns (address);

    function keeper() external view returns (address);

    function want() external view returns (address);

    function totalDebt() external view returns (uint256);
}

abstract contract Joint is ySwapper {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 internal constant RATIO_PRECISION = 1e4;

    ProviderStrategy public providerA;
    ProviderStrategy public providerB;

    address public tokenA;
    address public tokenB;

    address public WETH;
    address public reward;
    address public router;

    IUniswapV2Pair public pair;

    uint256 public investedA;
    uint256 public investedB;

    bool public dontInvestWant;
    bool public autoProtectionDisabled;

    uint256 public minAmountToSell;
    uint256 public maxPercentageLoss;
    uint256 public minRewardToHarvest;

    modifier onlyGovernance() {
        checkGovernance();
        _;
    }

    modifier onlyVaultManagers() {
        checkVaultManagers();
        _;
    }

    modifier onlyProviders() {
        checkProvider();
        _;
    }

    modifier onlyKeepers() {
        checkKeepers();
        _;
    }

    function checkKeepers() internal {
        require(isKeeper() || isGovernance() || isVaultManager());
    }

    function checkGovernance() internal {
        require(isGovernance());
    }

    function checkVaultManagers() internal {
        require(isGovernance() || isVaultManager());
    }

    function checkProvider() internal {
        require(isProvider());
    }

    function isGovernance() internal returns (bool) {
        return
            msg.sender == providerA.vault().governance() ||
            msg.sender == providerB.vault().governance();
    }

    function isVaultManager() internal returns (bool) {
        return
            msg.sender == providerA.vault().management() ||
            msg.sender == providerB.vault().management();
    }

    function isKeeper() internal returns (bool) {
        return
            (msg.sender == providerA.keeper()) ||
            (msg.sender == providerB.keeper());
    }

    function isProvider() internal returns (bool) {
        return
            msg.sender == address(providerA) ||
            msg.sender == address(providerB);
    }

    constructor(
        address _providerA,
        address _providerB,
        address _router,
        address _weth,
        address _reward
    ) public {
        _initialize(_providerA, _providerB, _router, _weth, _reward);
    }

    function _initialize(
        address _providerA,
        address _providerB,
        address _router,
        address _weth,
        address _reward
    ) internal virtual {
        require(address(providerA) == address(0), "Joint already initialized");
        providerA = ProviderStrategy(_providerA);
        providerB = ProviderStrategy(_providerB);
        router = _router;
        WETH = _weth;
        reward = _reward;

        tradeFactory = address(0xD3f89C21719Ec5961a3E6B0f9bBf9F9b4180E9e9);

        // NOTE: we let some loss to avoid getting locked in the position if something goes slightly wrong
        maxPercentageLoss = 10; // 0.10%

        tokenA = address(providerA.want());
        tokenB = address(providerB.want());
        require(tokenA != tokenB, "!same-want");
        pair = IUniswapV2Pair(getPair());

        IERC20(tokenA).approve(address(_router), type(uint256).max);
        IERC20(tokenB).approve(address(_router), type(uint256).max);
        IERC20(_reward).approve(address(_router), type(uint256).max);
        IERC20(address(pair)).approve(address(_router), type(uint256).max);
    }

    function name() external view virtual returns (string memory);

    function shouldEndEpoch() public view virtual returns (bool);

    function _autoProtect() internal view virtual returns (bool);

    function shouldStartEpoch() public view returns (bool) {
        // return true if we have balance of A or balance of B while the position is closed
        return
            (balanceOfA() > 0 || balanceOfB() > 0) &&
            investedA == 0 &&
            investedB == 0;
    }

    function setDontInvestWant(bool _dontInvestWant)
        external
        onlyVaultManagers
    {
        dontInvestWant = _dontInvestWant;
    }

    function setMinRewardToHarvest(uint256 _minRewardToHarvest)
        external
        onlyVaultManagers
    {
        minRewardToHarvest = _minRewardToHarvest;
    }

    function setMinAmountToSell(uint256 _minAmountToSell)
        external
        onlyVaultManagers
    {
        minAmountToSell = _minAmountToSell;
    }

    function setAutoProtectionDisabled(bool _autoProtectionDisabled)
        external
        onlyVaultManagers
    {
        autoProtectionDisabled = _autoProtectionDisabled;
    }

    function setMaxPercentageLoss(uint256 _maxPercentageLoss)
        external
        onlyVaultManagers
    {
        require(_maxPercentageLoss <= RATIO_PRECISION);
        maxPercentageLoss = _maxPercentageLoss;
    }

    function closePositionReturnFunds() external onlyProviders {
        // Check if it needs to stop starting new epochs after finishing this one. _autoProtect is implemented in children
        if (_autoProtect() && !autoProtectionDisabled) {
            dontInvestWant = true;
        }

        // Check that we have a position to close
        if (investedA == 0 || investedB == 0) {
            return;
        }

        // 1. CLOSE LIQUIDITY POSITION
        // Closing the position will:
        // - Remove liquidity from DEX
        // - Claim pending rewards
        // - Close Hedge and receive payoff
        // and returns current balance of tokenA and tokenB
        (uint256 currentBalanceA, uint256 currentBalanceB) = _closePosition();

        // 2. SELL REWARDS FOR WANT
        (address rewardSwappedTo, uint256 rewardSwapOutAmount) =
            swapReward(balanceOfReward());
        if (rewardSwappedTo == tokenA) {
            currentBalanceA = currentBalanceA.add(rewardSwapOutAmount);
        } else if (rewardSwappedTo == tokenB) {
            currentBalanceB = currentBalanceB.add(rewardSwapOutAmount);
        }

        // 3. REBALANCE PORTFOLIO
        // Calculate rebalance operation
        // It will return which of the tokens (A or B) we need to sell and how much of it to leave the position with the initial proportions
        (address sellToken, uint256 sellAmount) =
            calculateSellToBalance(
                currentBalanceA,
                currentBalanceB,
                investedA,
                investedB
            );

        if (sellToken != address(0) && sellAmount > minAmountToSell) {
            uint256 buyAmount =
                sellCapital(
                    sellToken,
                    sellToken == tokenA ? tokenB : tokenA,
                    sellAmount
                );
        }

        // reset invested balances
        investedA = investedB = 0;

        _returnLooseToProviders();
        // Check that we have returned with no losses
        //
        require(
            IERC20(tokenA).balanceOf(address(providerA)) >=
                providerA
                    .totalDebt()
                    .mul(RATIO_PRECISION.sub(maxPercentageLoss))
                    .div(RATIO_PRECISION),
            "!wrong-balanceA"
        );
        require(
            IERC20(tokenB).balanceOf(address(providerB)) >=
                providerB
                    .totalDebt()
                    .mul(RATIO_PRECISION.sub(maxPercentageLoss))
                    .div(RATIO_PRECISION),
            "!wrong-balanceB"
        );
    }

    function openPosition() external onlyProviders {
        // No capital, nothing to do
        if (balanceOfA() == 0 || balanceOfB() == 0) {
            return;
        }

        require(
            balanceOfStake() == 0 &&
                balanceOfPair() == 0 &&
                investedA == 0 &&
                investedB == 0
        ); // don't create LP if we are already invested

        (uint256 amountA, uint256 amountB, ) = createLP();
        (uint256 costHedgeA, uint256 costHedgeB) = hedgeLP();

        investedA = amountA.add(costHedgeA);
        investedB = amountB.add(costHedgeB);

        depositLP();

        if (tradesEnabled == false && tradeFactory != address(0)) {
            _setUpTradeFactory();
        }

        if (balanceOfStake() != 0 || balanceOfPair() != 0) {
            _returnLooseToProviders();
        }
    }

    function getYSwapTokens()
        internal
        view
        virtual
        override
        returns (address[] memory, address[] memory)
    {}

    function removeTradeFactoryPermissions()
        external
        virtual
        override
        onlyVaultManagers
    {}

    function updateTradeFactoryPermissions(address _newTradeFactory)
        external
        virtual
        override
        onlyGovernance
    {}

    // Keepers will claim and sell rewards mid-epoch (otherwise we sell only in the end)
    function harvest() external onlyKeepers {
        getReward();
    }

    function harvestTrigger() external view returns (bool) {
        return balanceOfReward() > minRewardToHarvest;
    }

    function getHedgeProfit() public view virtual returns (uint256, uint256);

    function estimatedTotalAssetsAfterBalance()
        public
        view
        virtual
        returns (uint256 _aBalance, uint256 _bBalance)
    {
        uint256 rewardsPending = pendingReward().add(balanceOfReward());

        (_aBalance, _bBalance) = balanceOfTokensInLP();

        _aBalance = _aBalance.add(balanceOfA());
        _bBalance = _bBalance.add(balanceOfB());

        (uint256 callProfit, uint256 putProfit) = getHedgeProfit();
        _aBalance = _aBalance.add(callProfit);
        _bBalance = _bBalance.add(putProfit);

        if (reward == tokenA) {
            _aBalance = _aBalance.add(rewardsPending);
        } else if (reward == tokenB) {
            _bBalance = _bBalance.add(rewardsPending);
        } else if (rewardsPending != 0) {
            address swapTo = findSwapTo(reward);
            uint256[] memory outAmounts =
                IUniswapV2Router02(router).getAmountsOut(
                    rewardsPending,
                    getTokenOutPath(reward, swapTo)
                );
            if (swapTo == tokenA) {
                _aBalance = _aBalance.add(outAmounts[outAmounts.length - 1]);
            } else if (swapTo == tokenB) {
                _bBalance = _bBalance.add(outAmounts[outAmounts.length - 1]);
            }
        }

        (address sellToken, uint256 sellAmount) =
            calculateSellToBalance(_aBalance, _bBalance, investedA, investedB);

        (uint256 reserveA, uint256 reserveB) = getReserves();

        if (sellToken == tokenA) {
            uint256 buyAmount =
                UniswapV2Library.getAmountOut(sellAmount, reserveA, reserveB);
            _aBalance = _aBalance.sub(sellAmount);
            _bBalance = _bBalance.add(buyAmount);
        } else if (sellToken == tokenB) {
            uint256 buyAmount =
                UniswapV2Library.getAmountOut(sellAmount, reserveB, reserveA);
            _bBalance = _bBalance.sub(sellAmount);
            _aBalance = _aBalance.add(buyAmount);
        }
    }

    function estimatedTotalAssetsInToken(address token)
        public
        view
        returns (uint256 _balance)
    {
        if (token == tokenA) {
            (_balance, ) = estimatedTotalAssetsAfterBalance();
        } else if (token == tokenB) {
            (, _balance) = estimatedTotalAssetsAfterBalance();
        }
    }

    function getHedgeBudget(address token)
        public
        view
        virtual
        returns (uint256);

    function hedgeLP() internal virtual returns (uint256, uint256);

    function closeHedge() internal virtual;

    function calculateSellToBalance(
        uint256 currentA,
        uint256 currentB,
        uint256 startingA,
        uint256 startingB
    ) internal view virtual returns (address _sellToken, uint256 _sellAmount) {
        if (startingA == 0 || startingB == 0) return (address(0), 0);

        (uint256 ratioA, uint256 ratioB) =
            getRatios(currentA, currentB, startingA, startingB);

        if (ratioA == ratioB) return (address(0), 0);

        (uint256 reserveA, uint256 reserveB) = getReserves();

        if (ratioA > ratioB) {
            _sellToken = tokenA;
            _sellAmount = _calculateSellToBalance(
                currentA,
                currentB,
                startingA,
                startingB,
                reserveA,
                reserveB,
                10**uint256(IERC20Extended(tokenA).decimals())
            );
        } else {
            _sellToken = tokenB;
            _sellAmount = _calculateSellToBalance(
                currentB,
                currentA,
                startingB,
                startingA,
                reserveB,
                reserveA,
                10**uint256(IERC20Extended(tokenB).decimals())
            );
        }
    }

    function _calculateSellToBalance(
        uint256 current0,
        uint256 current1,
        uint256 starting0,
        uint256 starting1,
        uint256 reserve0,
        uint256 reserve1,
        uint256 precision
    ) internal pure returns (uint256 _sellAmount) {
        uint256 numerator =
            current0.sub(starting0.mul(current1).div(starting1)).mul(precision);
        uint256 denominator;
        uint256 exchangeRate;

        // First time to approximate
        exchangeRate = UniswapV2Library.getAmountOut(
            precision,
            reserve0,
            reserve1
        );
        denominator = precision + starting0.mul(exchangeRate).div(starting1);
        _sellAmount = numerator.div(denominator);
        // Shortcut to avoid Uniswap amountIn == 0 revert
        if (_sellAmount == 0) {
            return 0;
        }

        // Second time to account for price impact
        exchangeRate = UniswapV2Library
            .getAmountOut(_sellAmount, reserve0, reserve1)
            .mul(precision)
            .div(_sellAmount);
        denominator = precision + starting0.mul(exchangeRate).div(starting1);
        _sellAmount = numerator.div(denominator);
    }

    function getRatios(
        uint256 currentA,
        uint256 currentB,
        uint256 startingA,
        uint256 startingB
    ) internal pure returns (uint256 _a, uint256 _b) {
        _a = currentA.mul(RATIO_PRECISION).div(startingA);
        _b = currentB.mul(RATIO_PRECISION).div(startingB);
    }

    function getReserves()
        public
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        if (tokenA == pair.token0()) {
            (reserveA, reserveB, ) = pair.getReserves();
        } else {
            (reserveB, reserveA, ) = pair.getReserves();
        }
    }

    function createLP()
        internal
        virtual
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // **WARNING**: This call is sandwichable, care should be taken
        //              to always execute with a private relay
        return
            IUniswapV2Router02(router).addLiquidity(
                tokenA,
                tokenB,
                balanceOfA()
                    .mul(RATIO_PRECISION.sub(getHedgeBudget(tokenA)))
                    .div(RATIO_PRECISION),
                balanceOfB()
                    .mul(RATIO_PRECISION.sub(getHedgeBudget(tokenB)))
                    .div(RATIO_PRECISION),
                0,
                0,
                address(this),
                now
            );
    }

    function findSwapTo(address token) internal view returns (address) {
        if (tokenA == token) {
            return tokenB;
        } else if (tokenB == token) {
            return tokenA;
        } else if (reward == token) {
            if (tokenA == WETH || tokenB == WETH) {
                return WETH;
            }
            return tokenA;
        } else {
            revert("!swapTo");
        }
    }

    function getTokenOutPath(address _token_in, address _token_out)
        internal
        view
        returns (address[] memory _path)
    {
        bool is_weth =
            _token_in == address(WETH) || _token_out == address(WETH);
        bool is_internal =
            (_token_in == tokenA && _token_out == tokenB) ||
                (_token_in == tokenB && _token_out == tokenA);
        _path = new address[](is_weth || is_internal ? 2 : 3);
        _path[0] = _token_in;
        if (is_weth || is_internal) {
            _path[1] = _token_out;
        } else {
            _path[1] = address(WETH);
            _path[2] = _token_out;
        }
    }

    function getReward() internal virtual;

    function depositLP() internal virtual;

    function withdrawLP() internal virtual;

    function swapReward(uint256 _rewardBal)
        internal
        virtual
        returns (address, uint256)
    {
        if (reward == tokenA || reward == tokenB || _rewardBal == 0) {
            return (reward, 0);
        }

        if (tokenA == WETH || tokenB == WETH) {
            return (WETH, sellCapital(reward, WETH, _rewardBal));
        }

        // Assume that position has already been liquidated
        (uint256 ratioA, uint256 ratioB) =
            getRatios(balanceOfA(), balanceOfB(), investedA, investedB);
        if (ratioA >= ratioB) {
            return (tokenB, sellCapital(reward, tokenB, _rewardBal));
        }
        return (tokenA, sellCapital(reward, tokenA, _rewardBal));
    }

    // If there is a lot of impermanent loss, some capital will need to be sold
    // To make both sides even
    function sellCapital(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountIn
    ) internal virtual returns (uint256 _amountOut) {
        uint256[] memory amounts =
            IUniswapV2Router02(router).swapExactTokensForTokens(
                _amountIn,
                0,
                getTokenOutPath(_tokenFrom, _tokenTo),
                address(this),
                now
            );
        _amountOut = amounts[amounts.length - 1];
    }

    function _closePosition() internal virtual returns (uint256, uint256) {
        // Unstake LP from staking contract
        withdrawLP();

        // Close the hedge
        closeHedge();

        if (balanceOfPair() == 0) {
            return (0, 0);
        }

        // **WARNING**: This call is sandwichable, care should be taken
        //              to always execute with a private relay
        IUniswapV2Router02(router).removeLiquidity(
            tokenA,
            tokenB,
            balanceOfPair(),
            0,
            0,
            address(this),
            now
        );

        return (balanceOfA(), balanceOfB());
    }

    function _returnLooseToProviders()
        internal
        returns (uint256 balanceA, uint256 balanceB)
    {
        balanceA = balanceOfA();
        if (balanceA > 0) {
            IERC20(tokenA).safeTransfer(address(providerA), balanceA);
        }

        balanceB = balanceOfB();
        if (balanceB > 0) {
            IERC20(tokenB).safeTransfer(address(providerB), balanceB);
        }
    }

    function getPair() internal view virtual returns (address) {
        address factory = IUniswapV2Router02(router).factory();
        return IUniswapV2Factory(factory).getPair(tokenA, tokenB);
    }

    function balanceOfPair() public view returns (uint256) {
        return IERC20(getPair()).balanceOf(address(this));
    }

    function balanceOfA() public view returns (uint256) {
        return IERC20(tokenA).balanceOf(address(this));
    }

    function balanceOfB() public view returns (uint256) {
        return IERC20(tokenB).balanceOf(address(this));
    }

    function balanceOfReward() public view returns (uint256) {
        return IERC20(reward).balanceOf(address(this));
    }

    function balanceOfStake() public view virtual returns (uint256);

    function balanceOfTokensInLP()
        public
        view
        returns (uint256 _balanceA, uint256 _balanceB)
    {
        (uint256 reserveA, uint256 reserveB) = getReserves();
        uint256 lpBal = balanceOfStake().add(balanceOfPair());
        uint256 pairPrecision = 10**uint256(pair.decimals());
        uint256 percentTotal = lpBal.mul(pairPrecision).div(pair.totalSupply());
        _balanceA = reserveA.mul(percentTotal).div(pairPrecision);
        _balanceB = reserveB.mul(percentTotal).div(pairPrecision);
    }

    function pendingReward() public view virtual returns (uint256);

    // --- MANAGEMENT FUNCTIONS ---
    function liquidatePositionManually(
        uint256 expectedBalanceA,
        uint256 expectedBalanceB
    ) external onlyVaultManagers {
        (uint256 balanceA, uint256 balanceB) = _closePosition();
        require(expectedBalanceA <= balanceA, "!sandwidched");
        require(expectedBalanceB <= balanceB, "!sandwidched");
    }

    function returnLooseToProvidersManually() external onlyVaultManagers {
        _returnLooseToProviders();
    }

    function removeLiquidityManually(
        uint256 amount,
        uint256 expectedBalanceA,
        uint256 expectedBalanceB
    ) external virtual onlyVaultManagers {
        IUniswapV2Router02(router).removeLiquidity(
            tokenA,
            tokenB,
            amount,
            0,
            0,
            address(this),
            now
        );
        require(expectedBalanceA <= balanceOfA(), "!sandwidched");
        require(expectedBalanceB <= balanceOfB(), "!sandwidched");
    }

    function swapTokenForTokenManually(
        address[] memory swapPath,
        uint256 swapInAmount,
        uint256 minOutAmount
    ) external onlyGovernance returns (uint256) {
        address swapTo = swapPath[swapPath.length - 1];
        require(swapTo == tokenA || swapTo == tokenB); // swapTo must be tokenA or tokenB
        uint256[] memory amounts =
            IUniswapV2Router02(router).swapExactTokensForTokens(
                swapInAmount,
                minOutAmount,
                swapPath,
                address(this),
                now
            );
        return amounts[amounts.length - 1];
    }

    function sweep(address _token) external onlyGovernance {
        require(_token != address(tokenA));
        require(_token != address(tokenB));

        SafeERC20.safeTransfer(
            IERC20(_token),
            providerA.vault().governance(),
            IERC20(_token).balanceOf(address(this))
        );
    }

    function migrateProvider(address _newProvider) external onlyProviders {
        ProviderStrategy newProvider = ProviderStrategy(_newProvider);
        if (address(newProvider.want()) == tokenA) {
            providerA = newProvider;
        } else if (address(newProvider.want()) == tokenB) {
            providerB = newProvider;
        } else {
            revert("Unsupported token");
        }
    }
}

// File: NoHedgeJoint.sol

abstract contract NoHedgeJoint is Joint {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    constructor(
        address _providerA,
        address _providerB,
        address _router,
        address _weth, 
        address _reward
    ) public Joint(_providerA, _providerB, _router, _weth, _reward) {
    }

    function getHedgeBudget(address token)
        public
        view
        override
        returns (uint256)
    {
        return 0;
    }

    function getTimeToMaturity() public view returns (uint256) {
        return 0;
    }

    function getHedgeProfit() public view override returns (uint256, uint256) {
        return (0, 0);
    }

    function hedgeLP()
        internal
        override
        returns (uint256 costA, uint256 costB)
    {
        // NO HEDGE
        return (0,0);
    }

    function closeHedge() internal override {
        // NO HEDGE
        return;
    }

    function shouldEndEpoch() public view override returns (bool) {
        return false;
    }

    // this function is called by Joint to see if it needs to stop initiating new epochs due to too high volatility
    function _autoProtect() internal view override returns (bool) {
        return false;
    }
}

// File: SolidexJoint.sol

interface ISolidlyPair is IUniswapV2Pair {
    function getAmountOut(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256);
}

contract SolidexJoint is NoHedgeJoint {
    ISolidex public solidex;
    bool public stable;
    bool public dontWithdraw;

    bool public isOriginal = true;

    address public constant SEX = 0xD31Fcd1f7Ba190dBc75354046F6024A9b86014d7;
    address public constant SOLID_SEX =
        0x888EF71766ca594DED1F0FA3AE64eD2941740A20;

    constructor(
        address _providerA,
        address _providerB,
        address _router,
        address _weth,
        address _reward,
        address _solidex,
        bool _stable
    ) public NoHedgeJoint(_providerA, _providerB, _router, _weth, _reward) {
        _initalizeSolidexJoint(_solidex, _stable);
    }

    function initialize(
        address _providerA,
        address _providerB,
        address _router,
        address _weth,
        address _reward,
        address _solidex,
        bool _stable
    ) external {
        _initialize(_providerA, _providerB, _router, _weth, _reward);
        _initalizeSolidexJoint(_solidex, _stable);
    }

    function _initalizeSolidexJoint(address _solidex, bool _stable) internal {
        solidex = ISolidex(_solidex);
        stable = _stable;
        pair = IUniswapV2Pair(getPair());
        IERC20(address(pair)).approve(_solidex, type(uint256).max);
        IERC20(address(pair)).approve(address(router), type(uint256).max);
    }

    event Cloned(address indexed clone);

    function cloneSolidexJoint(
        address _providerA,
        address _providerB,
        address _router,
        address _weth,
        address _reward,
        address _solidex,
        bool _stable
    ) external returns (address newJoint) {
        require(isOriginal, "!original");
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            newJoint := create(0, clone_code, 0x37)
        }

        SolidexJoint(newJoint).initialize(
            _providerA,
            _providerB,
            _router,
            _weth,
            _reward,
            _solidex,
            _stable
        );

        emit Cloned(newJoint);
    }

    function name() external view override returns (string memory) {
        string memory ab =
            string(
                abi.encodePacked(
                    IERC20Extended(address(tokenA)).symbol(),
                    "-",
                    IERC20Extended(address(tokenB)).symbol()
                )
            );

        return string(abi.encodePacked("NoHedgeSolidexJoint(", ab, ")"));
    }

    function balanceOfStake() public view override returns (uint256) {
        return solidex.userBalances(address(this), address(pair));
    }

    function pendingReward() public view override returns (uint256) {
        address[] memory pairs = new address[](1);
        pairs[0] = address(pair);
        ISolidex.Amounts[] memory pendings =
            solidex.pendingRewards(address(this), pairs);

        uint256 pendingSEX = pendings[0].sex;
        uint256 pendingSOLID = pendings[0].solid;

        if (pendingSEX > 0) {
            ISolidRouter.route[] memory path = getTokenOutPathSolid(SEX, SOLID_SEX);
            pendingSOLID = pendingSOLID.add(
                ISolidRouter(router).getAmountsOut(pendingSEX, path)[1]
            );
        }

        return pendingSOLID;
    }

    function getReward() internal override {
        address[] memory pairs = new address[](1);
        pairs[0] = address(pair);
        solidex.getReward(pairs);
    }

    function setDontWithdraw(bool _dontWithdraw) external onlyVaultManagers {
        dontWithdraw = _dontWithdraw;
    }

    function depositLP() internal override {
        if (balanceOfPair() > 0) {
            solidex.deposit(address(pair), balanceOfPair());
        }
    }

    function withdrawLP() internal override {
        uint256 stakeBalance = balanceOfStake();
        if (stakeBalance > 0 && !dontWithdraw) {
            getReward();
            solidex.withdraw(address(pair), stakeBalance);
        }
    }

    function claimRewardManually() external onlyVaultManagers {
        getReward();
    }

    function withdrawLPManually(uint256 amount) external onlyVaultManagers {
        solidex.withdraw(address(pair), amount);
    }

    // OVERRIDE to incorporate stableswap or volatileswap
    function createLP()
        internal
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // **WARNING**: This call is sandwichable, care should be taken
        //              to always execute with a private relay
        return
            ISolidRouter(router).addLiquidity(
                tokenA,
                tokenB,
                stable,
                balanceOfA()
                    .mul(RATIO_PRECISION.sub(getHedgeBudget(tokenA)))
                    .div(RATIO_PRECISION),
                balanceOfB()
                    .mul(RATIO_PRECISION.sub(getHedgeBudget(tokenB)))
                    .div(RATIO_PRECISION),
                0,
                0,
                address(this),
                now
            );
    }

    function _closePosition() internal override returns (uint256, uint256) {
        // Unstake LP from staking contract
        withdrawLP();

        // Close the hedge
        closeHedge();

        if (balanceOfPair() == 0) {
            return (0, 0);
        }

        // **WARNING**: This call is sandwichable, care should be taken
        //              to always execute with a private relay
        ISolidRouter(router).removeLiquidity(
            tokenA,
            tokenB,
            stable,
            balanceOfPair(),
            0,
            0,
            address(this),
            now
        );

        return (balanceOfA(), balanceOfB());
    }

    function removeLiquidityManually(
        uint256 amount,
        uint256 expectedBalanceA,
        uint256 expectedBalanceB
    ) external override onlyVaultManagers {
        ISolidRouter(router).removeLiquidity(
            tokenA,
            tokenB,
            stable,
            amount,
            0,
            0,
            address(this),
            now
        );
        require(expectedBalanceA <= balanceOfA(), "!sandwidched");
        require(expectedBalanceB <= balanceOfB(), "!sandwidched");
    }

    function sellCapital(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountIn
    ) internal override returns (uint256 _amountOut) {
        uint256[] memory amounts =
            ISolidRouter(router).swapExactTokensForTokens(
                _amountIn,
                0,
                getTokenOutPathSolid(_tokenFrom, _tokenTo),
                address(this),
                now
            );
        _amountOut = amounts[amounts.length - 1];
    }

    function getTokenOutPathSolid(address _token_in, address _token_out)
        internal
        view
        returns (ISolidRouter.route[] memory _routes)
    {
        address[] memory _path;
        bool is_weth =
            _token_in == address(WETH) || _token_out == address(WETH);
        bool is_internal =
            (_token_in == tokenA && _token_out == tokenB) ||
                (_token_in == tokenB && _token_out == tokenA);
        _path = new address[](is_weth || is_internal ? 2 : 3);
        _path[0] = _token_in;
        if (is_weth || is_internal) {
            _path[1] = _token_out;
        } else {
            _path[1] = address(WETH);
            _path[2] = _token_out;
        }

        uint256 pathLength = _path.length > 1 ? _path.length - 1 : 1;
        _routes = new ISolidRouter.route[](pathLength);
        for (uint256 i = 0; i < pathLength; i++) {
            bool isStable = is_internal ? stable : false;
            _routes[i] = ISolidRouter.route(_path[i], _path[i + 1], isStable);
        }
    }

    function swapReward(uint256 _rewardBal)
        internal
        override
        returns (address, uint256)
    {
        // WARNING: NOT SELLING REWARDS! !!!
        if (reward == tokenA || reward == tokenB || _rewardBal == 0) {
            return (reward, 0);
        }

        if (tokenA == WETH || tokenB == WETH) {
            return (WETH, 0);
        }

        // Assume that position has already been liquidated
        (uint256 ratioA, uint256 ratioB) =
            getRatios(balanceOfA(), balanceOfB(), investedA, investedB);
        if (ratioA >= ratioB) {
            return (tokenB, 0);
        }
        return (tokenA, 0);
    }

    function getPair() internal view override returns (address) {
        address factory = ISolidRouter(router).factory();
        return ISolidFactory(factory).getPair(tokenA, tokenB, stable);
    }

    function estimatedTotalAssetsAfterBalance()
        public
        view
        override
        returns (uint256 _aBalance, uint256 _bBalance)
    {
        uint256 rewardsPending = pendingReward().add(balanceOfReward());

        (_aBalance, _bBalance) = balanceOfTokensInLP();

        _aBalance = _aBalance.add(balanceOfA());
        _bBalance = _bBalance.add(balanceOfB());

        (uint256 callProfit, uint256 putProfit) = getHedgeProfit();
        _aBalance = _aBalance.add(callProfit);
        _bBalance = _bBalance.add(putProfit);

        if (reward == tokenA) {
            _aBalance = _aBalance.add(rewardsPending);
        } else if (reward == tokenB) {
            _bBalance = _bBalance.add(rewardsPending);
        } else if (rewardsPending != 0) {
            address swapTo = findSwapTo(reward);
            uint256[] memory outAmounts =
                ISolidRouter(router).getAmountsOut(
                    rewardsPending,
                    getTokenOutPathSolid(reward, swapTo)
                );
            if (swapTo == tokenA) {
                _aBalance = _aBalance.add(outAmounts[outAmounts.length - 1]);
            } else if (swapTo == tokenB) {
                _bBalance = _bBalance.add(outAmounts[outAmounts.length - 1]);
            }
        }

        (address sellToken, uint256 sellAmount) =
            calculateSellToBalance(_aBalance, _bBalance, investedA, investedB);

        (uint256 reserveA, uint256 reserveB) = getReserves();

        if (sellToken == tokenA) {
            uint256 buyAmount =
                ISolidlyPair(address(pair)).getAmountOut(sellAmount, sellToken);
            _aBalance = _aBalance.sub(sellAmount);
            _bBalance = _bBalance.add(buyAmount);
        } else if (sellToken == tokenB) {
            uint256 buyAmount =
                ISolidlyPair(address(pair)).getAmountOut(sellAmount, sellToken);
            _bBalance = _bBalance.sub(sellAmount);
            _aBalance = _aBalance.add(buyAmount);
        }
    }

    function calculateSellToBalance(
        uint256 currentA,
        uint256 currentB,
        uint256 startingA,
        uint256 startingB
    ) internal view override returns (address _sellToken, uint256 _sellAmount) {
        if (startingA == 0 || startingB == 0) return (address(0), 0);

        (uint256 ratioA, uint256 ratioB) =
            getRatios(currentA, currentB, startingA, startingB);

        if (ratioA == ratioB) return (address(0), 0);

        (uint256 reserveA, uint256 reserveB) = getReserves();

        if (ratioA > ratioB) {
            _sellToken = tokenA;
            _sellAmount = _calculateSellToBalance(
                _sellToken,
                currentA,
                currentB,
                startingA,
                startingB,
                10**uint256(IERC20Extended(tokenA).decimals())
            );
        } else {
            _sellToken = tokenB;
            _sellAmount = _calculateSellToBalance(
                _sellToken,
                currentB,
                currentA,
                startingB,
                startingA,
                10**uint256(IERC20Extended(tokenB).decimals())
            );
        }
    }

    function _calculateSellToBalance(
        address sellToken,
        uint256 current0,
        uint256 current1,
        uint256 starting0,
        uint256 starting1,
        uint256 precision
    ) internal view returns (uint256 _sellAmount) {
        uint256 numerator =
            current0.sub(starting0.mul(current1).div(starting1)).mul(precision);
        uint256 exchangeRate =
            ISolidlyPair(address(pair)).getAmountOut(precision, sellToken);

        // First time to approximate
        _sellAmount = numerator.div(
            precision + starting0.mul(exchangeRate).div(starting1)
        );
        // Shortcut to avoid Uniswap amountIn == 0 revert
        if (_sellAmount == 0) {
            return 0;
        }

        // Second time to account for price impact
        exchangeRate = ISolidlyPair(address(pair))
            .getAmountOut(_sellAmount, sellToken)
            .mul(precision)
            .div(_sellAmount);
        _sellAmount = numerator.div(
            precision + starting0.mul(exchangeRate).div(starting1)
        );
    }

    function getYSwapTokens()
        internal
        view
        override
        returns (address[] memory, address[] memory)
    {
        address[] memory tokens = new address[](2);
        address[] memory toTokens = new address[](2);

        tokens[0] = SEX;
        toTokens[0] = address(tokenA); // swap to tokenA

        tokens[1] = SOLID_SEX;
        toTokens[1] = address(tokenA); // swap to tokenA

        return (tokens, toTokens);
    }

    function removeTradeFactoryPermissions()
        external
        override
        onlyVaultManagers
    {
        _removeTradeFactory();
    }

    function updateTradeFactoryPermissions(address _newTradeFactory)
        external
        override
        onlyGovernance
    {
        _updateTradeFactory(_newTradeFactory);
    }
}
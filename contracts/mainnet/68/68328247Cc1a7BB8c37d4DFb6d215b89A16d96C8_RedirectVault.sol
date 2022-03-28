/**
 *Submitted for verification at FtmScan.com on 2022-03-28
*/

pragma experimental ABIEncoderV2;

// File: Address.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: IERC20.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: IRedirectVault.sol

interface IRedirectVault {
    function isAuthorized(address _addr) external view returns (bool);

    function governance() external view returns (address);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);
}

// File: ISolidlyRouter01.sol

interface IBaseV1Pair {
    function metadata()
        external
        view
        returns (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            bool st,
            address t0,
            address t1
        );

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function mint(address to) external returns (uint256 liquidity);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function getAmountOut(uint256, address) external view returns (uint256);
}

struct Route {
    address from;
    address to;
    bool stable;
}

interface ISolidlyRouter01 {
    function factory() external view returns (address);

    function wftm() external view returns (address);

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

    function swapExactTokensForTokensSimple(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint256 deadline
    ) external returns (uint256[] calldata amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] calldata amounts);

    // function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
    //     require(tokenA != tokenB, 'BaseV1Router: IDENTICAL_ADDRESSES');
    //     (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    //     require(token0 != address(0), 'BaseV1Router: ZERO_ADDRESS');
    // }

    // // calculates the CREATE2 address for a pair without making any external calls
    // function pairFor(address tokenA, address tokenB, bool stable) public view returns (address pair) {
    //     (address token0, address token1) = sortTokens(tokenA, tokenB);
    //     pair = address(uint160(uint256(keccak256(abi.encodePacked(
    //         hex'ff',
    //         factory,
    //         keccak256(abi.encodePacked(token0, token1, stable)),
    //         pairCodeHash // init code hash
    //     )))));
    // }

    // // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    // function quoteLiquidity(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
    //     require(amountA > 0, 'BaseV1Router: INSUFFICIENT_AMOUNT');
    //     require(reserveA > 0 && reserveB > 0, 'BaseV1Router: INSUFFICIENT_LIQUIDITY');
    //     amountB = amountA * reserveB / reserveA;
    // }

    // // fetches and sorts the reserves for a pair
    // function getReserves(address tokenA, address tokenB, bool stable) public view returns (uint reserveA, uint reserveB) {
    //     (address token0,) = sortTokens(tokenA, tokenB);
    //     (uint reserve0, uint reserve1,) = IBaseV1Pair(pairFor(tokenA, tokenB, stable)).getReserves();
    //     (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    // }

    // // performs chained getAmountOut calculations on any number of pairs
    // function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable) {
    //     address pair = pairFor(tokenIn, tokenOut, true);
    //     uint amountStable;
    //     uint amountVolatile;
    //     if (IBaseV1Factory(factory).isPair(pair)) {
    //         amountStable = IBaseV1Pair(pair).getAmountOut(amountIn, tokenIn);
    //     }
    //     pair = pairFor(tokenIn, tokenOut, false);
    //     if (IBaseV1Factory(factory).isPair(pair)) {
    //         amountVolatile = IBaseV1Pair(pair).getAmountOut(amountIn, tokenIn);
    //     }
    //     return amountStable > amountVolatile ? (amountStable, true) : (amountVolatile, false);
    // }

    // // performs chained getAmountOut calculations on any number of pairs
    // function getAmountsOut(uint amountIn, route[] memory routes) public view returns (uint[] memory amounts) {
    //     require(routes.length >= 1, 'BaseV1Router: INVALID_PATH');
    //     amounts = new uint[](routes.length+1);
    //     amounts[0] = amountIn;
    //     for (uint i = 0; i < routes.length; i++) {
    //         address pair = pairFor(routes[i].from, routes[i].to, routes[i].stable);
    //         if (IBaseV1Factory(factory).isPair(pair)) {
    //             amounts[i+1] = IBaseV1Pair(pair).getAmountOut(amounts[i], routes[i].from);
    //         }
    //     }
    // }

    // function isPair(address pair) external view returns (bool) {
    //     return IBaseV1Factory(factory).isPair(pair);
    // }

    // function quoteAddLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     bool stable,
    //     uint amountADesired,
    //     uint amountBDesired
    // ) external view returns (uint amountA, uint amountB, uint liquidity) {
    //     // create the pair if it doesn't exist yet
    //     address _pair = IBaseV1Factory(factory).getPair(tokenA, tokenB, stable);
    //     (uint reserveA, uint reserveB) = (0,0);
    //     uint _totalSupply = 0;
    //     if (_pair != address(0)) {
    //         _totalSupply = erc20(_pair).totalSupply();
    //         (reserveA, reserveB) = getReserves(tokenA, tokenB, stable);
    //     }
    //     if (reserveA == 0 && reserveB == 0) {
    //         (amountA, amountB) = (amountADesired, amountBDesired);
    //         liquidity = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
    //     } else {

    //         uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
    //         if (amountBOptimal <= amountBDesired) {
    //             (amountA, amountB) = (amountADesired, amountBOptimal);
    //             liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
    //         } else {
    //             uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
    //             (amountA, amountB) = (amountAOptimal, amountBDesired);
    //             liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
    //         }
    //     }
    // }

    // function quoteRemoveLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     bool stable,
    //     uint liquidity
    // ) external view returns (uint amountA, uint amountB) {
    //     // create the pair if it doesn't exist yet
    //     address _pair = IBaseV1Factory(factory).getPair(tokenA, tokenB, stable);

    //     if (_pair == address(0)) {
    //         return (0,0);
    //     }

    //     (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB, stable);
    //     uint _totalSupply = erc20(_pair).totalSupply();

    //     amountA = liquidity * reserveA / _totalSupply; // using balances ensures pro-rata distribution
    //     amountB = liquidity * reserveB / _totalSupply; // using balances ensures pro-rata distribution

    // }

    // function _addLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     bool stable,
    //     uint amountADesired,
    //     uint amountBDesired,
    //     uint amountAMin,
    //     uint amountBMin
    // ) internal returns (uint amountA, uint amountB) {
    //     require(amountADesired >= amountAMin);
    //     require(amountBDesired >= amountBMin);
    //     // create the pair if it doesn't exist yet
    //     address _pair = IBaseV1Factory(factory).getPair(tokenA, tokenB, stable);
    //     if (_pair == address(0)) {
    //         _pair = IBaseV1Factory(factory).createPair(tokenA, tokenB, stable);
    //     }
    //     (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB, stable);
    //     if (reserveA == 0 && reserveB == 0) {
    //         (amountA, amountB) = (amountADesired, amountBDesired);
    //     } else {
    //         uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
    //         if (amountBOptimal <= amountBDesired) {
    //             require(amountBOptimal >= amountBMin, 'BaseV1Router: INSUFFICIENT_B_AMOUNT');
    //             (amountA, amountB) = (amountADesired, amountBOptimal);
    //         } else {
    //             uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
    //             assert(amountAOptimal <= amountADesired);
    //             require(amountAOptimal >= amountAMin, 'BaseV1Router: INSUFFICIENT_A_AMOUNT');
    //             (amountA, amountB) = (amountAOptimal, amountBDesired);
    //         }
    //     }
    // }

    // function addLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     bool stable,
    //     uint amountADesired,
    //     uint amountBDesired,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline
    // ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
    //     (amountA, amountB) = _addLiquidity(tokenA, tokenB, stable, amountADesired, amountBDesired, amountAMin, amountBMin);
    //     address pair = pairFor(tokenA, tokenB, stable);
    //     _safeTransferFrom(tokenA, msg.sender, pair, amountA);
    //     _safeTransferFrom(tokenB, msg.sender, pair, amountB);
    //     liquidity = IBaseV1Pair(pair).mint(to);
    // }

    // function addLiquidityFTM(
    //     address token,
    //     bool stable,
    //     uint amountTokenDesired,
    //     uint amountTokenMin,
    //     uint amountFTMMin,
    //     address to,
    //     uint deadline
    // ) external payable ensure(deadline) returns (uint amountToken, uint amountFTM, uint liquidity) {
    //     (amountToken, amountFTM) = _addLiquidity(
    //         token,
    //         address(wftm),
    //         stable,
    //         amountTokenDesired,
    //         msg.value,
    //         amountTokenMin,
    //         amountFTMMin
    //     );
    //     address pair = pairFor(token, address(wftm), stable);
    //     _safeTransferFrom(token, msg.sender, pair, amountToken);
    //     wftm.deposit{value: amountFTM}();
    //     assert(wftm.transfer(pair, amountFTM));
    //     liquidity = IBaseV1Pair(pair).mint(to);
    //     // refund dust eth, if any
    //     if (msg.value > amountFTM) _safeTransferFTM(msg.sender, msg.value - amountFTM);
    // }

    // // **** REMOVE LIQUIDITY ****
    // function removeLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     bool stable,
    //     uint liquidity,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline
    // ) public ensure(deadline) returns (uint amountA, uint amountB) {
    //     address pair = pairFor(tokenA, tokenB, stable);
    //     require(IBaseV1Pair(pair).transferFrom(msg.sender, pair, liquidity)); // send liquidity to pair
    //     (uint amount0, uint amount1) = IBaseV1Pair(pair).burn(to);
    //     (address token0,) = sortTokens(tokenA, tokenB);
    //     (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    //     require(amountA >= amountAMin, 'BaseV1Router: INSUFFICIENT_A_AMOUNT');
    //     require(amountB >= amountBMin, 'BaseV1Router: INSUFFICIENT_B_AMOUNT');
    // }

    // function removeLiquidityFTM(
    //     address token,
    //     bool stable,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountFTMMin,
    //     address to,
    //     uint deadline
    // ) public ensure(deadline) returns (uint amountToken, uint amountFTM) {
    //     (amountToken, amountFTM) = removeLiquidity(
    //         token,
    //         address(wftm),
    //         stable,
    //         liquidity,
    //         amountTokenMin,
    //         amountFTMMin,
    //         address(this),
    //         deadline
    //     );
    //     _safeTransfer(token, to, amountToken);
    //     wftm.withdraw(amountFTM);
    //     _safeTransferFTM(to, amountFTM);
    // }

    // function removeLiquidityWithPermit(
    //     address tokenA,
    //     address tokenB,
    //     bool stable,
    //     uint liquidity,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountA, uint amountB) {
    //     address pair = pairFor(tokenA, tokenB, stable);
    //     {
    //         uint value = approveMax ? type(uint).max : liquidity;
    //         IBaseV1Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    //     }

    //     (amountA, amountB) = removeLiquidity(tokenA, tokenB, stable, liquidity, amountAMin, amountBMin, to, deadline);
    // }

    // function removeLiquidityFTMWithPermit(
    //     address token,
    //     bool stable,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountFTMMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountToken, uint amountFTM) {
    //     address pair = pairFor(token, address(wftm), stable);
    //     uint value = approveMax ? type(uint).max : liquidity;
    //     IBaseV1Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    //     (amountToken, amountFTM) = removeLiquidityFTM(token, stable, liquidity, amountTokenMin, amountFTMMin, to, deadline);
    // }

    // // **** SWAP ****
    // // requires the initial amount to have already been sent to the first pair
    // function _swap(uint[] memory amounts, route[] memory routes, address _to) internal virtual {
    //     for (uint i = 0; i < routes.length; i++) {
    //         (address token0,) = sortTokens(routes[i].from, routes[i].to);
    //         uint amountOut = amounts[i + 1];
    //         (uint amount0Out, uint amount1Out) = routes[i].from == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
    //         address to = i < routes.length - 1 ? pairFor(routes[i+1].from, routes[i+1].to, routes[i+1].stable) : _to;
    //         IBaseV1Pair(pairFor(routes[i].from, routes[i].to, routes[i].stable)).swap(
    //             amount0Out, amount1Out, to, new bytes(0)
    //         );
    //     }
    // }

    // function swapExactFTMForTokens(uint amountOutMin, route[] calldata routes, address to, uint deadline)
    // external
    // payable
    // ensure(deadline)
    // returns (uint[] memory amounts)
    // {
    //     require(routes[0].from == address(wftm), 'BaseV1Router: INVALID_PATH');
    //     amounts = getAmountsOut(msg.value, routes);
    //     require(amounts[amounts.length - 1] >= amountOutMin, 'BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
    //     wftm.deposit{value: amounts[0]}();
    //     assert(wftm.transfer(pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]));
    //     _swap(amounts, routes, to);
    // }

    // function swapExactTokensForFTM(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline)
    // external
    // ensure(deadline)
    // returns (uint[] memory amounts)
    // {
    //     require(routes[routes.length - 1].to == address(wftm), 'BaseV1Router: INVALID_PATH');
    //     amounts = getAmountsOut(amountIn, routes);
    //     require(amounts[amounts.length - 1] >= amountOutMin, 'BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
    //     _safeTransferFrom(
    //         routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]
    //     );
    //     _swap(amounts, routes, address(this));
    //     wftm.withdraw(amounts[amounts.length - 1]);
    //     _safeTransferFTM(to, amounts[amounts.length - 1]);
    // }

    // function UNSAFE_swapExactTokensForTokens(
    //     uint[] memory amounts,
    //     route[] calldata routes,
    //     address to,
    //     uint deadline
    // ) external ensure(deadline) returns (uint[] memory) {
    //     _safeTransferFrom(routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]);
    //     _swap(amounts, routes, to);
    //     return amounts;
    // }

    // function _safeTransferFTM(address to, uint value) internal {
    //     (bool success,) = to.call{value:value}(new bytes(0));
    //     require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    // }

    // function _safeTransfer(address token, address to, uint256 value) internal {
    //     require(token.code.length > 0);
    //     (bool success, bytes memory data) =
    //     token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
    //     require(success && (data.length == 0 || abi.decode(data, (bool))));
    // }

    // function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
    //     require(token.code.length > 0);
    //     (bool success, bytes memory data) =
    //     token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
    //     require(success && (data.length == 0 || abi.decode(data, (bool))));
    // }
}

// File: IVault.sol

interface IVault {
    function deposit(uint256 amount) external;

    function withdraw() external;

    function withdraw(uint256 maxShares) external;

    function pricePerShare() external view returns (uint256);

    function balanceOf(address _address) external view returns (uint256);

    function token() external view returns (address);

    function decimals() external view returns (uint256);
}

// File: Math.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// File: MultiRewards.sol

struct MultiRewards {
    address token;
    uint256 amount;
}

// File: ReentrancyGuard.sol

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

// File: SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: Authorized.sol

contract Authorized is Context {
    address private _governance;
    address private _management;
    address private _keeper;
    address private _pendingGovernance;

    event UpdateGovernance(address indexed governance);
    event UpdateManagement(address indexed management);
    event UpdateKeeper(address indexed keeper);

    constructor() {
        _governance = _msgSender();
        _management = _msgSender();
        _keeper = _msgSender();
    }

    modifier onlyGovernance() {
        require(
            governance() == _msgSender(),
            "Authorized: caller is not the governance"
        );
        _;
    }

    modifier onlyAuthorized() {
        require(
            governance() == _msgSender() || management() == _msgSender(),
            "Authorized: caller is not the authorized"
        );
        _;
    }

    modifier onlyKeeper() {
        require(
            governance() == _msgSender() ||
                management() == _msgSender() ||
                keeper() == _msgSender(),
            "Authorized: caller is not the a keeper"
        );
        _;
    }

    function governance() public view returns (address) {
        return _governance;
    }

    function management() public view returns (address) {
        return _management;
    }

    function keeper() public view returns (address) {
        return _keeper;
    }

    function isAuthorized(address _addr) public view returns (bool) {
        return governance() == _addr || management() == _addr;
    }

    function setGoveranance(address newGovernance) external onlyGovernance {
        _pendingGovernance = newGovernance;
    }

    function setManagement(address newManagement) external onlyAuthorized {
        _management = newManagement;
        emit UpdateManagement(_management);
    }

    function setKeeper(address newKeeper) external onlyAuthorized {
        _keeper = newKeeper;
        emit UpdateKeeper(_keeper);
    }

    function acceptGovernance() external onlyGovernance {
        require(_msgSender() == _pendingGovernance);
        _governance = _pendingGovernance;
        emit UpdateGovernance(_governance);
    }
}

// File: IERC20Extended.sol

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

// File: IERC20Metadata.sol

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

// File: IStrategy.sol

interface IStrategy {
    // deposits all funds into the farm
    function deposit() external;

    // vault only - withdraws funds from the strategy
    function withdraw(uint256 _amount) external;

    // returns the balance of all tokens managed by the strategy
    function balanceOf() external view returns (uint256);

    // Claims farmed tokens and sends them to _to (Reward Distributor). Only callable from
    // the vault
    function claim(address _to)
        external
        returns (MultiRewards[] memory _rewards);

    // withdraws all tokens and sends them back to the vault
    function retireStrat() external;

    // pauses deposits, resets allowances, and withdraws all funds from farm
    function panic() external;

    // pauses deposits and resets allowances
    function pause() external;

    // unpauses deposits and maxes out allowances again
    function unpause() external;
}

// File: Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: SafeERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: ERC20.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

// File: uniswap.sol

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

interface IUniswapV2Pair is IERC20Extended {
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
}

// File: ERC20NoTransfer.sol

contract ERC20NoTransfer is ERC20 {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        revert("Transfer Not Supported");
    }
}

// File: RewardDistributor.sol

struct UserInfo {
    uint256 amount; // How many tokens the user has provided.
    uint256 epochStart; // at what Epoch will rewards start
    uint256 depositTime; // when did the user deposit
}

interface IRewardDistributor {
    function isEpochFinished() external view returns (bool);

    function processEpoch(MultiRewards[] calldata _rewards) external;

    function onDeposit(address _user, uint256 _beforeBalance) external;

    function onWithdraw(address _user, uint256 _amount) external;

    function onEmergencyWithdraw(address _user, uint256 _amount) external;

    function permitRewardToken(address _token) external;

    function unpermitRewardToken(address _token) external;
}

/// @title Manages reward distribution for a RedirectVault
/// @author Robovault
/// @notice You can use this contract to tract and distribut rewards
/// for RedirectVault users
/// @dev Design to isolate the reward distribution from the vault and
/// strategy so as to minimise impact if there are issues with the
/// RewardDistributor
contract RewardDistributor is ReentrancyGuard, IRewardDistributor {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice Underlying target token, eg USDC. This is what the rewards will be converted to,
    /// afterwhich the rewards may be deposited to a vault if one is configured
    IERC20 public immutable targetToken;

    /// @notice the target vault for pending rewards to be deposited into.
    IVault public immutable targetVault;

    /// @notice if a vault is configured this is set to targetVault, otherwise this will be targetToken. This
    /// is the token users will withdraw when harvesting. If there is an issue with the vault, authorized roles
    /// can call emergencyDisableVault() which will change tokenOut to targetToken.
    IERC20 public tokenOut;

    /// @notice contract address for the parent redurect vault.
    address public immutable redirectVault;

    /// @notice univ2 router used for swaps
    address public immutable router;

    /// @notice solidly router used for swapping only OXD when it is a reward token
    ISolidlyRouter01 public constant solidlyRouter =
        ISolidlyRouter01(0xa38cd27185a464914D3046f0AB9d43356B34829D);

    /// @notice weth (wftm address) for determining univ2 swap paths
    address public constant weth = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    /// @notice oxd v2 contract address
    address public constant oxd = 0xc5A9848b9d145965d821AaeC8fA32aaEE026492d;

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice tracks total balance of base that is eligible for rewards in given epoch.
    /// New deposits won't receive rewards until next epoch.
    uint256 public eligibleEpochRewards;

    /// @notice Tracks the epoch number. This is incremented each time processEpoch is called
    uint256 public epoch = 0;

    /// @notice timestamp of the previous epoch
    uint256 public lastEpoch;

    /// @notice BIPS Scalar
    uint256 constant BPS_ADJ = 10000;

    /// @notice mapping user info to user addresses
    mapping(address => UserInfo) public userInfo;

    /// @notice tracks rewards of traget token for given Epoch
    mapping(uint256 => uint256) public epochRewards;

    /// @notice tracks the total balance eligible for rewards for given epoch
    mapping(uint256 => uint256) public epochBalance;

    /// @notice tracks total tokens claimed by user
    mapping(address => uint256) public totalClaimed;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice User Harvrest Event
    event UserHarvested(
        address indexed user,
        uint256 indexed rewards,
        address indexed token
    );

    /// @notice Epoch Processed Event
    event EpochProcessed(
        uint256 indexed epoch,
        uint256 indexed amountOut,
        uint256 indexed eligibleEpochRewards
    );

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice The Reward Distributor constructor initialises the immutables
    /// and validates the configuration of the contract.
    /// @param _redirectVault RedirectVault contract
    /// @param _router univ2 router (Spooky or Spirit)
    /// @param _targetToken Target token - eg USDC
    /// @param _targetVault Target vault - wg yvUSDC. Set this to the zero address if no vault is needed
    /// @param _feeAddress Address for which the fees are sent
    constructor(
        address _redirectVault,
        address _router,
        address _targetToken,
        address _targetVault,
        address _feeAddress
    ) {
        router = _router;
        redirectVault = _redirectVault;
        targetToken = IERC20(_targetToken);
        targetVault = IVault(_targetVault);
        feeAddress = _feeAddress;
        require(
            _targetToken == IVault(targetVault).token(),
            "Vault.token() miss-match"
        );

        IERC20(oxd).approve(address(solidlyRouter), type(uint256).max);
        IERC20(weth).approve(address(router), type(uint256).max);

        if (_targetVault == address(0)) {
            useTargetVault = false;
            tokenOut = targetToken;
        } else {
            useTargetVault = true;
            // Approve allowance for the vault
            tokenOut = IERC20(_targetVault);
            targetToken.safeApprove(_targetVault, type(uint256).max);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        USE TARGET VAULT CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice flags if a vault is configured and that it's not in
    /// emergency exit.
    bool public useTargetVault = true;

    /// @notice flags a vault is in emergency exit and will no longer be used.
    bool public emergencyExitVault = false;

    /// @notice state and accounting values to track rewards before and after
    /// an emergency exit
    uint256 public emergencyExitEpoch;
    uint256 public emergencyTargetOut;
    uint256 public emergencyVaultBalance;

    /// @notice if there is an issue with the vault deposits, authorized users
    /// can call this function to perminantly remove the user of the vault. After
    /// this function is called, all rewards will be swapped into targetToken
    /// and remain there until harvested.
    function emergencyDisableVault() external onlyAuthorized {
        require(useTargetVault);

        // Disable use of the vault
        useTargetVault = false;
        emergencyExitVault = true;

        // Flag the epoch and current vault balance so rewards for epochs
        // prior to the emergency exit are calculated properly
        emergencyExitEpoch = epoch;
        emergencyVaultBalance = targetVault.balanceOf(address(this));

        // Update token out to the underlying.
        tokenOut = targetToken;

        // Withdraw from the vault and capture the withdraw amount
        uint256 targetBalanceBefore = targetToken.balanceOf(address(this));
        targetVault.withdraw();
        uint256 targetBalanceAfter = targetToken.balanceOf(address(this));
        emergencyTargetOut = targetBalanceAfter.sub(targetBalanceBefore);

        // Revoke vault approvals
        targetToken.safeApprove(address(targetVault), 0);
    }

    /*///////////////////////////////////////////////////////////////
                        FEE ADDRESS CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice address which fees are sent each epoch
    address public feeAddress;

    /// @notice set feeAddress
    /// @param _feeAddress The new feeAddress setting
    function setFeeAddress(address _feeAddress) external onlyAuthorized {
        feeAddress = _feeAddress;
    }

    /*///////////////////////////////////////////////////////////////
                        SET EPOCH TIME CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice timePerEpoch sets the minimum time that must elapsed betweem
    /// harvests. During harvests the rewards tokens are swapped into the
    /// targetToken and user reward balances are updated.
    uint256 public timePerEpoch = 60 * 60 * 3; // 3 Hours
    uint256 constant timePerEpochLimit = 259200;

    /// @notice set timePerEpoch
    /// @param _epochTime todo
    function setEpochDuration(uint256 _epochTime) external onlyAuthorized {
        require(_epochTime <= timePerEpochLimit);
        timePerEpoch = _epochTime;
    }

    // amount of profit converted each Epoch (don't convert everything to smooth returns)
    uint256 public profitConversionPercent = 10000; // 100% default
    uint256 public minProfitThreshold; // minimum amount of profit in order to conver to target token
    uint256 public profitFee = 500; // 5% default
    uint256 constant profitFeeMax = 2000; // 20% max

    function setParamaters(
        uint256 _profitConversionPercent,
        uint256 _profitFee,
        uint256 _minProfitThreshold
    ) external onlyAuthorized {
        require(_profitConversionPercent <= BPS_ADJ);
        require(_profitFee <= profitFeeMax);

        profitConversionPercent = _profitConversionPercent;
        minProfitThreshold = _minProfitThreshold;
        profitFee = _profitFee;
    }

    /// @notice Returns true if the epoch is complete and un processsed.
    /// @dev epoch is processed by processEpoch()
    function isEpochFinished() public view returns (bool) {
        return ((block.timestamp >= lastEpoch.add(timePerEpoch)));
    }

    /// @notice Throws if called by any account other than the vault.
    modifier onlyVault() {
        require(redirectVault == msg.sender, "!redirectVault");
        _;
    }

    /// @notice Throws if called by any account other than the managment or governance
    /// of the redirect vault
    modifier onlyAuthorized() {
        require(
            IRedirectVault(redirectVault).isAuthorized(msg.sender),
            "!authorized"
        );
        _;
    }

    /// @notice Throws if called by any account other than the governance
    /// of the redirect vault
    modifier onlyGovernance() {
        require(
            IRedirectVault(redirectVault).governance() == msg.sender,
            "!governance"
        );
        _;
    }

    /// @notice Only called by the vault. The vault sends harvest rewards to the
    /// reward distributor, and processEpoch() redirects the rewards to the targetToken
    /// @dev epoch is processed by processEpoch()
    /// @param _rewards and array of the rewards that have been sent to this contract
    /// that need to be converted to tokenOut
    function processEpoch(MultiRewards[] calldata _rewards) external onlyVault {
        uint256 preSwapBalance = targetBalance();

        // only convert profits if there is sufficient profit & users are eligible to start receiving rewards this epoch
        if (eligibleEpochRewards > 0) {
            _redirectProfits(_rewards);
            _deposit();
        }
        _updateRewardData(preSwapBalance);
        _incrementEpoch();
    }

    /// @notice returns the targetOut balance
    /// @return targetOut balance of this contract
    function targetBalance() public view returns (uint256) {
        return tokenOut.balanceOf(address(this));
    }

    /// @notice swaps the rewards tokens to the targetToken
    /// @param _rewards and array of the rewards
    function _redirectProfits(MultiRewards[] calldata _rewards) internal {
        for (uint256 i = 0; i < _rewards.length; i++) {
            _sellRewards(_rewards[i].token);
        }
    }

    /// @notice Manual call to sell rewards incase there are some that aren't captured
    /// @param _token token to sell
    function manualRedirect(address _token) external onlyAuthorized {
        require(_token != address(targetToken));
        _sellRewards(_token);
    }

    /// @notice swaps rewards depending on whether the token is oxd or not.
    /// @param _token token to swaps
    function _sellRewards(address _token) internal {
        if (_token == oxd) {
            _convert0xd();
        } else {
            _swapTokenToTargetUniV2(_token);
        }
    }

    /// @notice swaps any oxd in this contract into the targetToken
    function _convert0xd() internal {
        uint256 swapAmount = IERC20(oxd).balanceOf(address(this));
        solidlyRouter.swapExactTokensForTokensSimple(
            swapAmount,
            uint256(0),
            oxd,
            weth,
            true,
            address(this),
            block.timestamp
        );

        if (address(targetToken) != weth) {
            _swapTokenToTargetUniV2(weth);
        }
    }

    /// @notice swaps any _token in this contract into the targetToken
    /// @param _token ERC20 token to be swapped into targetToken
    function _swapTokenToTargetUniV2(address _token) internal {
        IERC20 rewardToken = IERC20(_token);
        uint256 swapAmt = rewardToken
            .balanceOf(address(this))
            .mul(profitConversionPercent)
            .div(BPS_ADJ);
        uint256 fee = swapAmt.mul(profitFee).div(BPS_ADJ);
        rewardToken.transfer(feeAddress, fee);
        if (swapAmt > 0) {
            IUniswapV2Router01(router).swapExactTokensForTokens(
                swapAmt.sub(fee),
                0,
                _getTokenOutPath(_token, address(targetToken), weth),
                address(this),
                block.timestamp
            );
        }
    }

    /// @notice This must be called by the Redirect Vault anytime a user deposits
    /// @dev This will disperse any pending rewards and update the user accounting varaibles
    /// @param _user address of the user depositing
    /// @param _beforeBalance the balance of the user before depositing. Measured in the vault.token()
    function onDeposit(address _user, uint256 _beforeBalance)
        external
        onlyVault
    {
        uint256 rewards = getUserRewards(_user);

        if (rewards > 0) {
            // claims all rewards
            _disburseRewards(_user, rewards);
        }

        /// @dev a caviat of the account approach is that anytime a user deposits the are withdrawing
        /// their claim in the current epoch. This is necessary to ensure the rewards accounting is sound.
        if (userInfo[_user].epochStart < epoch) {
            _updateEligibleEpochRewards(_beforeBalance);
        }

        // To prevent users leaching i.e. deposit just before epoch rewards distributed user will start to be eligible for rewards following epoch
        _updateUserInfo(_user, epoch + 1);
    }

    /// @notice This must be called by the Redirect Vault anytime a user withdraws
    /// @dev This will disperse any pending rewards and update the user accounting varaibles
    /// @param _user address of the user depositing
    /// @param _amount the amount the user withdrew
    function onWithdraw(address _user, uint256 _amount) external onlyVault {
        uint256 rewards = getUserRewards(_user);

        if (rewards > 0) {
            // claims all rewards
            _disburseRewards(_user, rewards);
        }

        if (userInfo[_user].epochStart < epoch) {
            _updateEligibleEpochRewards(_amount);
        }

        _updateUserInfo(_user, epoch);
    }

    function onEmergencyWithdraw(address _user, uint256 _amount)
        external
        onlyVault
    {
        // here we just make sure they don't continue earning rewards in future epochs
        _updateUserInfo(_user, epoch);
    }

    /// @notice users call this to claim their pending rewards. They will be redeemed in targetToken or targetVault
    function harvest() public nonReentrant {
        address user = msg.sender;
        uint256 rewards = getUserRewards(user);
        require(rewards > 0, "user must have balance to claim");
        _disburseRewards(user, rewards);
        /// updates reward information so user rewards start from current EPOCH
        _updateUserInfo(user, epoch);
        emit UserHarvested(user, rewards, address(tokenOut));
    }

    /// @notice transfers the _rewards to the _user and updates their reward balance
    /// @param _rewards amount of the tokenOut needs to be sent to the user
    /// @param _user the user calling harvest()
    function _disburseRewards(address _user, uint256 _rewards) internal {
        tokenOut.transfer(_user, _rewards);
        _updateAmountClaimed(_user, _rewards);
    }

    /// @notice returns the sum of a users pending rewards in the tokenOut units
    /// @param _user the user calling harvest()
    function getUserRewards(address _user) public view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        uint256 rewardStart = user.epochStart;
        if (rewardStart == 0) {
            return 0;
        }

        uint256 rewards = 0;
        uint256 userEpochRewards;
        if (epoch > rewardStart) {
            for (uint256 i = rewardStart; i < epoch; i++) {
                userEpochRewards = _calcUserEpochRewards(i, user.amount);
                if (emergencyExitVault && i < emergencyExitEpoch) {
                    userEpochRewards = userEpochRewards
                        .mul(emergencyTargetOut)
                        .div(emergencyVaultBalance);
                }
                rewards = rewards.add(userEpochRewards);
            }
        }
        return (rewards);
    }

    /// @notice helper function to calculate a users reward for a give epoch
    /// @param _epoch epoch number to calculate the rewards for
    /// @param _amt the users vault.token() balance for that epoch
    function _calcUserEpochRewards(uint256 _epoch, uint256 _amt)
        internal
        view
        returns (uint256)
    {
        uint256 rewards = epochRewards[_epoch].mul(_amt).div(
            epochBalance[_epoch]
        );
        return (rewards);
    }

    /// @notice Updates the total amount claimed by a user
    /// @param _user user address
    /// @param _rewardsPaid amount the totalClaimed amount needs to be incremented by for _user
    function _updateAmountClaimed(address _user, uint256 _rewardsPaid)
        internal
    {
        totalClaimed[_user] = totalClaimed[_user] + _rewardsPaid;
    }

    /// @notice updates the eligible rewards for this epoch
    /// @dev eligibleEpochRewards = token.balanceOf(vault) - SUM{ Balance of users deposited this epoch (and have remained in the vault) }
    /// @param _amount amount the user deposited
    function _updateEligibleEpochRewards(uint256 _amount) internal {
        eligibleEpochRewards = eligibleEpochRewards.sub(_amount);
    }

    /// @notice update the userInfo state for a user. This is uses to maintain accounting for the users rewards
    /// @param _user user address
    /// @param _epoch epoch the user joined the accounting records
    function _updateUserInfo(address _user, uint256 _epoch) internal {
        userInfo[_user] = UserInfo(
            IRedirectVault(redirectVault).balanceOf(_user),
            _epoch,
            block.timestamp
        );
    }

    /// @notice Increments the epoch by 1
    function _incrementEpoch() internal {
        epoch = epoch.add(1);
        lastEpoch = block.timestamp;
    }

    /// @notice Updates the rewards and eligible balance for the epoch just passed.
    /// @dev Only called when an epoch is being processed
    /// @param _preSwapBalance targetToken balance prior to the swap
    function _updateRewardData(uint256 _preSwapBalance) internal {
        uint256 amountOut = targetBalance().sub(_preSwapBalance);

        epochRewards[epoch] = amountOut;
        /// we use this instead of total Supply as users that just deposited in current epoch are not eligible for rewards
        epochBalance[epoch] = eligibleEpochRewards;
        /// set to equal total Supply as all current users with deposits are eligible for next epoch rewards
        eligibleEpochRewards = IRedirectVault(redirectVault).totalSupply();

        emit EpochProcessed(epoch, amountOut, eligibleEpochRewards);
    }

    /// @notice deposits targetToken into the targetVault if a vault is configured and enabled
    function _deposit() internal {
        if (useTargetVault) {
            uint256 bal = targetToken.balanceOf(address(this));
            IVault(address(targetVault)).deposit(bal);
        }
    }

    /// @notice helper function to get the univ2 token path
    /// @param _token_in input token (token being swapped)
    /// @param _token_out out token (desired token)
    /// @param _weth wftm
    function _getTokenOutPath(
        address _token_in,
        address _token_out,
        address _weth
    ) internal view returns (address[] memory _path) {
        bool is_weth = _token_in == _weth || _token_out == _weth;
        _path = new address[](is_weth ? 2 : 3);
        _path[0] = _token_in;
        if (is_weth) {
            _path[1] = _token_out;
        } else {
            _path[1] = _weth;
            _path[2] = _token_out;
        }
    }

    /// @notice approves the router to transfer _token
    /// @param _token token to be approved
    function permitRewardToken(address _token) external onlyAuthorized {
        IERC20(_token).safeApprove(router, type(uint256).max);
    }

    /// @notice revokes the routers approval to transfer _token
    /// @param _token token to be revoked
    function unpermitRewardToken(address _token) external onlyAuthorized {
        IERC20(_token).safeApprove(router, 0);
    }

    /// @notice emergancy function to recover funds from the contract. Worst-case scenario.
    /// **** RUG RISK ****
    /// governance must be a trusted party!!!
    /// @dev todo - remove this function in future releases once there is more confidence in RewardDistributor
    /// @param _token token to be revoked
    function emergencySweep(address _token, address _to)
        external
        onlyGovernance
    {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, balance);
    }
}

// File: RedirectVault.sol

/// @notice Implementation of a vault to deposit funds for yield optimizing.
/// This is the contract that receives funds and that users interface with.
/// The yield optimizing strategy itself is implemented in a separate 'Strategy.sol' contract.
contract RedirectVault is ERC20NoTransfer, Authorized, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct StratCandidate {
        address implementation;
        uint256 proposedTime;
    }

    /*///////////////////////////////////////////////////////////////
                            IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Percentage scalar
    uint256 public constant PERCENT_DIVISOR = 10000;

    /// @notice The token the vault accepts and looks to maximize.
    IERC20 public token;

    /// @notice Timelock delay needed for a new strategy to be accepted (seconds)
    uint256 public immutable approvalDelay;

    /// @notice The reward distributor contract. All rewards are sent to this contract
    /// and users interact with it to harvest their rewards
    IRewardDistributor public distributor;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The last proposed strategy to switch to.
    StratCandidate public stratCandidate;

    /// @notice The active strategy
    address public strategy;

    /// @notice TVL limit for the vault
    uint256 public tvlCap;

    /// @notice The stretegy's initialization status.
    bool public initialized = false;

    /// @notice simple mappings used to determine PnL denominated in LP tokens,
    /// as well as keep a generalized history of a user's protocol usage.
    mapping(address => uint256) public cumulativeDeposits;
    mapping(address => uint256) public cumulativeWithdrawals;

    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event TvlCapUpdated(uint256 newTvlCap);
    event NewStratCandidate(address implementation);
    event UpgradeStrat(address implementation);
    event DepositsIncremented(address user, uint256 amount, uint256 total);
    event WithdrawalsIncremented(address user, uint256 amount, uint256 total);
    event RewardsClaimed(address distributor, MultiRewards[] rewards);

    /// @notice Sets the value of {token} to the token that the vault will
    /// hold as underlying value. It initializes the vault's own 'moo' token.
    /// This token is minted when someone does a deposit. It is burned in order
    /// to withdraw the corresponding portion of the underlying assets.
    /// @param _token the token to maximize.
    /// @param _name the name of the vault token.
    /// @param _symbol the symbol of the vault token.
    /// @param _tvlCap initial deposit cap for scaling TVL safely
    /// @param _targetToken All rewards are converted to this token, eg USDC, and deposited to a vault if one is configured.
    /// @param _targetVault vault address, eg yvUSDC. Set to address(0) if a vault is not required
    /// @param _feeAddress address fees are sent
    /// @param _approvalDelay new strategy timelock period in seconds
    constructor(
        address _token,
        string memory _name,
        string memory _symbol,
        uint256 _tvlCap,
        address _router,
        address _targetToken,
        address _targetVault,
        address _feeAddress,
        uint256 _approvalDelay
    ) ERC20NoTransfer(string(_name), string(_symbol)) {
        token = IERC20(_token);
        tvlCap = _tvlCap;
        approvalDelay = _approvalDelay;

        /// @dev deploys the distributor, this is immutable in the current version
        distributor = new RewardDistributor(
            address(this),
            _router,
            _targetToken,
            _targetVault,
            _feeAddress
        );
    }

    /// @notice Connects the vault to its initial strategy. One use only.
    /// @param _strategy the vault's initial strategy
    function initialize(address _strategy)
        public
        onlyGovernance
        returns (bool)
    {
        require(!initialized, "Contract is already initialized.");
        strategy = _strategy;
        initialized = true;
        return true;
    }

    /// @notice It calculates the total underlying value of {token} held by the system.
    /// It takes into account the vault contract balance, the strategy contract balance
    ///  and the balance deployed in other contracts as part of the strategy.
    function balance() public view returns (uint256) {
        return
            token.balanceOf(address(this)).add(IStrategy(strategy).balanceOf());
    }

    /// @notice Custom logic in here for how much the vault allows to be borrowed.
    /// We return 100% of tokens for now. Under certain conditions we might
    /// want to keep some of the system funds at hand in the vault, instead
    /// of putting them to work.
    function available() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice Function for various UIs to display the current value of one of our yield tokens.
    /// Returns an uint256 with 18 decimals of how much underlying asset one vault share represents.
    function getPricePerFullShare() public view returns (uint256) {
        return
            totalSupply() == 0 ? 1e18 : balance().mul(1e18).div(totalSupply());
    }

    /// @notice Function for various UIs to display the current value of one of our yield tokens.
    /// Returns an uint256 with 18 decimals of how much underlying asset one vault share represents.
    function totalAssets() public view returns (uint256) {
        return
            totalSupply() == 0 ? 1e18 : balance().mul(1e18).div(totalSupply());
    }

    /// @notice A helper function to call deposit() with all the sender's funds.
    function depositAll() external {
        deposit(token.balanceOf(msg.sender));
    }

    /// @notice The entrypoint of funds into the system. People deposit with this function
    /// into the vault. The vault is then in charge of sending funds into the strategy.
    /// @notice the _before and _after variables are used to account properly for
    /// 'burn-on-transaction' tokens.
    function deposit(uint256 _amount) public nonReentrant {
        require(_amount != 0, "please provide amount");
        uint256 _pool = balance();
        require(_pool.add(_amount) <= tvlCap, "vault is full!");
        uint256 _sharesBefore = balanceOf(msg.sender);

        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before);
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
        distributor.onDeposit(msg.sender, _sharesBefore);
        earn();
        incrementDeposits(_amount);
    }

    /// @notice Function to send funds into the strategy and put them to work. It's primarily called
    /// by the vault's deposit() function.
    /// TODO - Can this be internal, why is it public? What's the benefit
    function earn() public {
        uint256 _bal = available();
        token.safeTransfer(strategy, _bal);
        IStrategy(strategy).deposit();
    }

    /// @notice A helper function to call withdraw() with all the sender's funds.
    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    /// @notice Function to exit the system. The vault will withdraw the required tokens
    /// from the strategy and pay up the token holder. A proportional number of IOU
    /// tokens are burned in the process.
    function withdraw(uint256 _shares) public nonReentrant {
        require(_shares > 0, "please provide amount");
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            IStrategy(strategy).withdraw(_withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }
        token.safeTransfer(msg.sender, r);
        distributor.onWithdraw(msg.sender, _shares);
        incrementWithdrawals(r);
    }

    /// @notice Emergency function to withdraw a users funds and
    /// discard their rewards. This should only be called if there
    /// is an issue with the Reward Distributor contract
    function emergencyWithdrawAll() public nonReentrant {
        uint256 _shares = balanceOf(msg.sender);
        require(_shares > 0, "please provide amount");
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            IStrategy(strategy).withdraw(_withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }
        token.safeTransfer(msg.sender, r);
        distributor.onEmergencyWithdraw(msg.sender, _shares);
        incrementWithdrawals(r);
    }

    /// @notice pass in max value of uint to effectively remove TVL cap
    function updateTvlCap(uint256 _newTvlCap) public onlyAuthorized {
        tvlCap = _newTvlCap;
        emit TvlCapUpdated(tvlCap);
    }

    /// @notice Helper function to remove TVL cap
    function removeTvlCap() external onlyAuthorized {
        updateTvlCap(type(uint256).max);
    }

    /// @notice Returns true if an epoch is complete harvest can be called
    function harvestTrigger() public view returns (bool) {
        return distributor.isEpochFinished();
    }

    /// @notice Harvests rewards and send them to the reward distributor
    function harvest() public onlyKeeper {
        /// @dev Must wait for the epoch to complete before harvesting
        require(distributor.isEpochFinished(), "Epoch not finished");

        MultiRewards[] memory rewards = IStrategy(strategy).claim(
            address(distributor)
        );

        // Test the strategy is being honest
        for (uint256 i = 0; i < rewards.length; i++) {
            uint256 rewardBalance = IERC20(rewards[i].token).balanceOf(
                address(distributor)
            );
            require(rewardBalance >= rewards[i].amount, "Dishonest Strategy");
        }
        emit RewardsClaimed(address(distributor), rewards);

        // send profit to reward distributor
        distributor.processEpoch(rewards);
    }

    /// @notice function to increase user's cumulative deposits
    /// @param _amount number of LP tokens being deposited/withdrawn
    function incrementDeposits(uint256 _amount) internal returns (bool) {
        uint256 initial = cumulativeDeposits[tx.origin];
        uint256 newTotal = initial + _amount;
        cumulativeDeposits[tx.origin] = newTotal;
        emit DepositsIncremented(tx.origin, _amount, newTotal);
        return true;
    }

    /// @notice function to increase user's cumulative withdrawals
    /// @param _amount number of LP tokens being deposited/withdrawn
    function incrementWithdrawals(uint256 _amount) internal returns (bool) {
        uint256 initial = cumulativeWithdrawals[tx.origin];
        uint256 newTotal = initial + _amount;
        cumulativeWithdrawals[tx.origin] = newTotal;
        emit WithdrawalsIncremented(tx.origin, _amount, newTotal);
        return true;
    }

    /// @notice Rescues random funds stuck that the strat can't handle.
    /// @param _token address of the token to rescue.
    function inCaseTokensGetStuck(address _token) external onlyGovernance {
        require(_token != address(token), "!token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    /// @notice Sets the candidate for the new strat to use with this vault.
    /// @param _implementation The address of the candidate strategy.
    function proposeStrat(address _implementation) external onlyGovernance {
        stratCandidate = StratCandidate({
            implementation: _implementation,
            proposedTime: block.timestamp
        });
        emit NewStratCandidate(_implementation);
    }

    /// @notice It switches the active strat for the strat candidate. After upgrading, the
    /// candidate implementation is set to the 0x00 address, and proposedTime to a time
    /// happening in +100 years for safety.
    function upgradeStrat() external onlyGovernance {
        require(
            stratCandidate.implementation != address(0),
            "There is no candidate"
        );
        require(
            stratCandidate.proposedTime.add(approvalDelay) < block.timestamp,
            "Delay has not passed"
        );

        emit UpgradeStrat(stratCandidate.implementation);

        IStrategy(strategy).retireStrat();

        // TODO - Add loss arg and check there hasn't been more than
        // "loss" lost when retiring the strat
        strategy = stratCandidate.implementation;
        stratCandidate.implementation = address(0);
        stratCandidate.proposedTime = 5000000000;

        earn();
    }
}
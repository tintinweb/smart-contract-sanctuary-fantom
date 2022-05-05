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

// File: comppriceoracle.sol

interface ICompPriceOracle {
    function isPriceOracle() external view returns (bool);

    /**
     * @notice Get the underlying price of a cToken asset
     * @param cToken The cToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

// File: comptroller.sol

interface IComptroller {
    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    function claimComp(address holder) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);
}

interface UnitrollerAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    // address external admin;
    function admin() external view returns (address);

    /**
     * @notice Pending administrator for this contract
     */
    // address external pendingAdmin;
    function pendingAdmin() external view returns (address);

    /**
     * @notice Active brains of Unitroller
     */
    // address external comptrollerImplementation;
    function comptrollerImplementation() external view returns (address);

    /**
     * @notice Pending brains of Unitroller
     */
    // address external pendingComptrollerImplementation;
    function pendingComptrollerImplementation() external view returns (address);
}

interface ComptrollerV1Storage is UnitrollerAdminStorage {
    /**
     * @notice Oracle which gives the price of any given asset
     */
    // PriceOracle external oracle;
    function oracle() external view returns (address);

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    // uint external closeFactorMantissa;
    function closeFactorMantissa() external view returns (uint256);

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    // uint external liquidationIncentiveMantissa;
    function liquidationIncentiveMantissa() external view returns (uint256);

    /**
     * @notice Max number of assets a single account can participate in (borrow or use as collateral)
     */
    // uint external maxAssets;
    function maxAssets() external view returns (uint256);

    /**
     * @notice Per-account mapping of "assets you are in", capped by maxAssets
     */
    // mapping(address => CToken[]) external accountAssets;
    // function accountAssets(address) external view returns (CToken[]);
}

interface ComptrollerV2Storage is ComptrollerV1Storage {
    enum Version {VANILLA, COLLATERALCAP, WRAPPEDNATIVE}

    struct Market {
        bool isListed;
        uint256 collateralFactorMantissa;
        mapping(address => bool) accountMembership;
        bool isComped;
        Version version;
    }

    /**
     * @notice Official mapping of cTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    // mapping(address => Market) external markets;
    // function markets(address) external view returns (Market);

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    // address external pauseGuardian;
    // bool external _mintGuardianPaused;
    // bool external _borrowGuardianPaused;
    // bool external transferGuardianPaused;
    // bool external seizeGuardianPaused;
    // mapping(address => bool) external mintGuardianPaused;
    // mapping(address => bool) external borrowGuardianPaused;
}

interface ComptrollerV3Storage is ComptrollerV2Storage {
    // struct CompMarketState {
    //     /// @notice The market's last updated compBorrowIndex or compSupplyIndex
    //     uint224 index;
    //     /// @notice The block number the index was last updated at
    //     uint32 block;
    // }
    // /// @notice A list of all markets
    // CToken[] external allMarkets;
    // /// @notice The rate at which the flywheel distributes COMP, per block
    // uint external compRate;
    // /// @notice The portion of compRate that each market currently receives
    // mapping(address => uint) external compSpeeds;
    // /// @notice The COMP market supply state for each market
    // mapping(address => CompMarketState) external compSupplyState;
    // /// @notice The COMP market borrow state for each market
    // mapping(address => CompMarketState) external compBorrowState;
    // /// @notice The COMP borrow index for each market for each supplier as of the last time they accrued COMP
    // mapping(address => mapping(address => uint)) external compSupplierIndex;
    // /// @notice The COMP borrow index for each market for each borrower as of the last time they accrued COMP
    // mapping(address => mapping(address => uint)) external compBorrowerIndex;
    // /// @notice The COMP accrued but not yet transferred to each user
    // mapping(address => uint) external compAccrued;
}

interface ComptrollerV4Storage is ComptrollerV3Storage {
    // @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    // address external borrowCapGuardian;
    function borrowCapGuardian() external view returns (address);

    // @notice Borrow caps enforced by borrowAllowed for each cToken address. Defaults to zero which corresponds to unlimited borrowing.
    // mapping(address => uint) external borrowCaps;
    function borrowCaps(address) external view returns (uint256);
}

interface ComptrollerV5Storage is ComptrollerV4Storage {
    // @notice The supplyCapGuardian can set supplyCaps to any number for any market. Lowering the supply cap could disable supplying to the given market.
    // address external supplyCapGuardian;
    function supplyCapGuardian() external view returns (address);

    // @notice Supply caps enforced by mintAllowed for each cToken address. Defaults to zero which corresponds to unlimited supplying.
    // mapping(address => uint) external supplyCaps;
    function supplyCaps(address) external view returns (uint256);

    function _setPriceOracle(address newOracle) external returns (uint);
    function getAllMarkets() external view returns (address[] calldata cTokens);
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

// File: ctoken.sol

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
interface InterestRateModel {
    /**
     * @dev Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amnount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @dev Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amnount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

interface ICTokenStorage {
    /**
     * @dev Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }
}

interface ICToken is ICTokenStorage {
    /*** Market Events ***/

    /**
     * @dev Event emitted when interest is accrued
     */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows
    );

    /**
     * @dev Event emitted when tokens are minted
     */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

    /**
     * @dev Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     * @dev Event emitted when underlying is borrowed
     */
    event Borrow(
        address borrower,
        uint256 borrowAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @dev Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @dev Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral,
        uint256 seizeTokens
    );

    /*** Admin Events ***/

    /**
     * @dev Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @dev Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @dev Event emitted when comptroller is changed
     */
    event NewComptroller(
        IComptroller oldComptroller,
        IComptroller newComptroller
    );

    /**
     * @dev Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(
        InterestRateModel oldInterestRateModel,
        InterestRateModel newInterestRateModel
    );

    /**
     * @dev Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(
        uint256 oldReserveFactorMantissa,
        uint256 newReserveFactorMantissa
    );

    /**
     * @dev Event emitted when the reserves are added
     */
    event ReservesAdded(
        address benefactor,
        uint256 addAmount,
        uint256 newTotalReserves
    );

    /**
     * @dev Event emitted when the reserves are reduced
     */
    event ReservesReduced(
        address admin,
        uint256 reduceAmount,
        uint256 newTotalReserves
    );

    /**
     * @dev EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev EIP20 Approval event
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /**
     * @dev Failure event
     */
    event Failure(uint256 error, uint256 info, uint256 detail);

    /*** User Interface ***/
    function totalBorrows() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    /*** CCap Interface ***/

    function totalCollateralTokens() external view returns (uint256);

    function accountCollateralTokens(address account)
        external
        view
        returns (uint256);

    function isCollateralTokenInit(address account)
        external
        view
        returns (bool);

    function collateralCap() external view returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin)
        external
        returns (uint256);

    function _acceptAdmin() external returns (uint256);

    function _setComptroller(IComptroller newComptroller)
        external
        returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa)
        external
        returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setInterestRateModel(InterestRateModel newInterestRateModel)
        external
        returns (uint256);
}

interface ICTokenErc20 is ICToken {
    /*** User Interface ***/

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        ICToken cTokenCollateral
    ) external returns (uint256);

    /*** Admin Functions ***/

    function _addReserves(uint256 addAmount) external returns (uint256);
}

interface ICCapableErc20 {
    /*** User Interface ***/

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        ICToken cTokenCollateral
    ) external returns (uint256);

    function gulp() external;

    /*** Admin Functions ***/

    function _addReserves(uint256 addAmount) external returns (uint256);
}

interface CCollateralCapStorage {
    /**
     * @notice Total number of tokens used as collateral in circulation.
     */
    // uint256 public totalCollateralTokens;
    function totalCollateralTokens() external view returns (uint256);

    /**
     * @notice Record of token balances which could be treated as collateral for each account.
     *         If collateral cap is not set, the value should be equal to accountTokens.
     */
    // mapping(address => uint256) public accountCollateralTokens;
    function accountCollateralTokens(address account)
        external
        view
        returns (uint256);

    /**
     * @notice Check if accountCollateralTokens have been initialized.
     */
    // mapping(address => bool) public isCollateralTokenInit;
    function isCollateralTokenInit(address account)
        external
        view
        returns (bool);

    /**
     * @notice Collateral cap for this CToken, zero for no cap.
     */
    // uint256 public collateralCap;
    function collateralCap() external view returns (uint256);
}

// File: screampriceoracle.sol

contract ScreamPriceOracle is IPriceOracle {
    using SafeMath for uint256;

    address cTokenQuote;
    address cTokenBase;
    ComptrollerV5Storage comptroller;

    constructor(
        address _comptroller,
        address _cTokenBase
    ) public {
        cTokenBase = _cTokenBase;
        comptroller = ComptrollerV5Storage(_comptroller);
    }

    function getPrice() external view override returns (uint256) {
        ICompPriceOracle oracle = ICompPriceOracle(comptroller.oracle());
        uint256 basePrice = oracle.getUnderlyingPrice(cTokenBase);
        require(basePrice != 0);
        return basePrice;
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

// File: StrategyInsurance.sol

// Feel free to change the license, but this is what we use

interface StrategyAPIExt is StrategyAPI {
    function strategist() external view returns (address);

    function insurance() external view returns (address);
}

interface IStrategyInsurance {
    function reportProfit(uint256 _totalDebt, uint256 _profit)
        external
        returns (uint256 _wantNeeded);

    function reportLoss(uint256 _totalDebt, uint256 _loss)
        external
        returns (uint256 _compensation);

    function migrateInsurance(address newInsurance) external;
}

/**
 * @title Strategy Generic Insurrance
 * @author Robovault
 * @notice
 *  StrategyInsurance provides an issurrance fund for strategy losses
 *  A portion of all profits are sent to the insurrance fund untill
 *  it reaches its target insurrance percentage. When a loss is realised
 *  by the strategy the inssurance fund will return the funds to the
 *  strategy to fully compensate or soften the loss.
 */
contract StrategyInsurance {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    StrategyAPIExt public strategy;
    IERC20 want;
    uint256 constant BPS_MAX = 10000;
    uint256 public lossSum = 0;

    event InsurancePayment(
        uint256 indexed strategyDebt,
        uint256 indexed harvestProfit,
        uint256 indexed wantPayment
    );
    event InsurancePayout(uint256 indexed wantPayout);

    // Bips - Proportion of totalDebt the inssurance fund is targeting to grow
    uint256 public targetFundSize = 50; // 0.5% default

    // Rate of the profits that go to insurrance while it's below target
    uint256 public profitTakeRate = 1000; // 10% default

    // The maximum compensation rate the insurrance fund will return funds to the strategy
    // proportional to the TotalDebt of the strategy
    uint256 public maximumCompenstionRate = 5; // 5 bips per harvest default

    function _onlyAuthorized() internal {
        require(
            msg.sender == strategy.strategist() || msg.sender == governance()
        );
    }

    function _onlyGovernance() internal {
        require(msg.sender == governance());
    }

    function _onlyStrategy() internal {
        require(msg.sender == address(strategy));
    }

    constructor(address _strategy) public {
        strategy = StrategyAPIExt(_strategy);
        want = IERC20(strategy.want());
    }

    function setTargetFundSize(uint256 _targetFundSize) external {
        _onlyAuthorized();
        require(_targetFundSize < 500); // Must be less than 5%
        targetFundSize = _targetFundSize;
    }

    function setProfitTakeRate(uint256 _profitTakeRate) external {
        _onlyAuthorized();
        require(_profitTakeRate < 4000); // Must be less than 40%
        profitTakeRate = _profitTakeRate;
    }

    function setmaximumCompenstionRate(uint256 _maximumCompenstionRate)
        external
    {
        _onlyAuthorized();
        require(_maximumCompenstionRate < 50); // Must be less than 0.5%
        maximumCompenstionRate = _maximumCompenstionRate;
    }

    /**
     * @notice
     *  Strategy reports profits to the insurrance find and informs the strategy
     *  of how much want is requested for insurrance.
     * @param _totalDebt Debt the strategy has with the vault.
     * @param _profit The profit the strategy is reporting this harvest
     * @return want amount requested for insurrance
     */
    function reportProfit(uint256 _totalDebt, uint256 _profit)
        external
        returns (uint256)
    {
        _onlyStrategy();

        // if there has been a loss that is yet to be paid fully compensated, continue
        // to compensate
        if (lossSum > _profit) {
            lossSum = lossSum.sub(_profit);
            compensate(_totalDebt);
            return 0;
        }

        // no pending losses to pay out
        lossSum = 0;

        // Have the insurrance hit the insurrance target
        uint256 balance = want.balanceOf(address(this));
        uint256 targetBalance = _totalDebt.mul(targetFundSize).div(BPS_MAX);
        if (balance >= targetBalance) {
            return 0;
        }

        uint256 payment = _profit.mul(profitTakeRate).div(BPS_MAX);
        emit InsurancePayment(_totalDebt, _profit, payment);
        return payment;
    }

    /**
     * @notice
     *  Strategy reports loss. The insurrance fund will decide weather or not to
     *  send want back to the strategy to soften the loss
     * @param _totalDebt Debt the strategy has with the vault.
     * @param _loss The loss realised by the this harvest
     * @return _compensation amount sent back to the strategy.
     */
    function reportLoss(uint256 _totalDebt, uint256 _loss)
        external
        returns (uint256 _compensation)
    {
        _onlyStrategy();

        lossSum = lossSum.add(_loss);
        _compensation = compensate(_totalDebt);
    }

    /**
     * @notice
     *  Processes insurance payouot
     * @param _totalDebt Debt the strategy has with the vault.
     * @return _compensation amount sent back to the strategy.
     */
    function compensate(uint256 _totalDebt)
        internal
        returns (uint256 _compensation)
    {
        uint256 balance = want.balanceOf(address(this));

        // Reserves are empties, we cannot compensate
        if (balance == 0) {
            lossSum = 0;
            return 0;
        }

        // Calculat what the payout will be
        uint256 maxComp = maximumCompenstionRate.mul(_totalDebt).div(BPS_MAX);
        _compensation = Math.min(Math.min(balance, lossSum), maxComp);

        if (_compensation > 0) {
            SafeERC20.safeTransfer(want, address(strategy), _compensation);
            emit InsurancePayout(_compensation);
        }
    }

    function governance() public view returns (address) {
        return VaultAPI(strategy.vault()).governance();
    }

    /**
     * @notice
     *  Sends balance to gov for the purpose of migrating to a new strategy at the
     *  disgression of governance.
     */
    function withdraw() external {
        _onlyGovernance();
        SafeERC20.safeTransfer(
            want,
            governance(),
            want.balanceOf(address(this))
        );
    }

    /**
     * @notice
     *  Sets the lossSum. Adds some flexibility with payouts to cover edge-case
     *  scenarios
     */
    function setLossSum(uint256 newLossSum) external {
        _onlyGovernance();
        lossSum = newLossSum;
    }

    /**
     * @notice
     *  called by the strategy when updating the insurance contract
     */
    function migrateInsurance(address newInsurance) external {
        _onlyStrategy();
        SafeERC20.safeTransfer(
            want,
            newInsurance,
            want.balanceOf(address(this))
        );
    }

    /**
     * @notice
     * Called by goverannace when updating the strategy
     */
    function migrateStrategy(address newStrategy) external {
        _onlyGovernance();
        SafeERC20.safeTransfer(
            want,
            StrategyAPIExt(newStrategy).insurance(),
            want.balanceOf(address(this))
        );
    }
}

// File: strategy.sol

// Feel free to change the license, but this is what we use

// Feel free to change this version of Solidity. We support >=0.6.0 <0.7.0;

// These are the core Yearn libraries

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

// Import interfaces for many popular DeFi projects, or add your own!

interface IJointVault {
    function addToJoint() external;
    function calculateProfit(address _token) external view returns(uint256 _loss, uint256 _profit);
    function withdraw(uint256 _debtProportion) external;
    function allStratsInProfit() external view returns(bool);
    function harvestFromProvider() external;
    function canHarvestJoint() external view returns(bool);
    function name() external view returns (string memory);
}

contract Strategy is BaseStrategy {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IJointVault public jointVault; 
    ICTokenErc20 public cTokenLend;
    IPriceOracle oracle;
    IUniswapV2Router01 router;
    IComptroller comptroller;
    IERC20 compToken;
    IStrategyInsurance public insurance;

    modifier onlyJoint() {
        _onlyJoint();
        _;
    }

    function _onlyJoint() internal {
        require(msg.sender == address(jointVault));
    }

    uint256 public jointTokenIndex;
    uint256 public otherJointTokenIndex;
    uint256 constant STD_PRECISION = 1e18;
    uint256 constant BASIS_PRECISION = 10000;
    address weth;
    // amount of Debt to Joint Strategy 
    uint256 public debtJoint; 
    // this % of want must be available before adding to Joint 
    uint256 public debtJointMin = 500; 
    // max amount of want that can be provided to Joint 
    uint256 public debtJointMax = 9500;    
    // this % of want must be in lend before calling redeemWant (avoids issue with tiny amounts blocking withdrawals)
    uint256 public lendDustPercent = 10; 
    bool public forceHarvestTriggerOnce;
    bool public sellJointRewardsAtHarvest = true; 
    bool public sellCompAtHarvest = false; 

    constructor(
        address _vault,
        address _jointVault,
        address _cTokenLend,
        address _comptroller,
        address _router,
        address _compToken

        ) public BaseStrategy(_vault) {

        jointVault = IJointVault(_jointVault);
        cTokenLend = ICTokenErc20(_cTokenLend);
        comptroller = IComptroller(_comptroller);
        router = IUniswapV2Router01(_router);
        weth = router.WETH();
        compToken = IERC20(_compToken);

        want.approve(_jointVault, uint256(-1));
        want.approve(_cTokenLend, uint256(-1));
        compToken.approve(_router, uint256(-1));

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cTokenLend);
        comptroller.enterMarkets(cTokens);

        oracle = new ScreamPriceOracle(
            address(comptroller),
            address(cTokenLend)
        );

        maxReportDelay = 43200; // 12 hours
        minReportDelay = 28800; // 8 hours 
        profitFactor = 1500;
        
    }

    // ******** OVERRIDE THESE METHODS FROM BASE CONTRACT ************

    function name() external view override returns (string memory) {
        return "StrategyJointLpProvider";
    }

    function jointLPName() external view returns (string memory) {
        return (jointVault.name());
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        return (balanceLend().add(balanceJoint()).add(balanceOfWant()));
    }

    function balanceLend() public view returns (uint256) {
        return (
            cTokenLend
                .balanceOf(address(this))
                .mul(cTokenLend.exchangeRateStored())
                .div(1e18)
        );
    }

    function balanceJoint() public view returns(uint256) {

        if (debtJoint ==0) {
            return(0);
        } else {
            (uint256 loss, uint256 profit) = jointVault.calculateProfit(address(want));
            return(debtJoint.add(profit).sub(loss));
        }
    }

    function balanceOfWant() public view returns(uint256) {
        return(want.balanceOf(address(this)));
    }

    // how much want is available to move to join LP provider 
    function wantAvailable() public view returns(uint256) {
        uint256 wantFree = balanceOfWant().add(balanceLend());
        uint256 assets = estimatedTotalAssets();
        uint256 jointMin = debtJointMin.mul(assets).div(BASIS_PRECISION);
        // we check that free want is enough to cover existing jointMin held in strat & bigger than jointMin required to add to Joint  
        if (wantFree > jointMin.mul(2)){ 
            return(wantFree.sub(jointMin));
        } else {
            return(0);
        }
    }

    function getOraclePrice() public view returns(uint256) {
        return(oracle.getPrice());
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        _harvestRewards();
        
        uint256 totalAssets = estimatedTotalAssets();
        uint256 totalDebt = _getTotalDebt();
        
        if (totalAssets > totalDebt) {
            _profit = totalAssets.sub(totalDebt);
            (uint256 amountFreed, uint256 _slippage) = _withdraw(_debtOutstanding.add(_profit));
            uint256 balanceWant = balanceOfWant();
            if (_debtOutstanding > balanceWant) {
                _debtPayment = balanceWant;
                _profit = 0;
            } else {
                _debtPayment = _debtOutstanding;
                _profit = Math.min(_profit, balanceWant.sub(_debtPayment));
            }
            
        } else {
            _withdraw(_debtOutstanding);
            _loss = totalDebt.sub(totalAssets);
            _debtPayment = balanceOfWant();
        }

        debtJoint = balanceJoint();

        // Check if we're net loss or net profit
        if (_loss >= _profit) {
            _profit = 0;
            _loss = _loss.sub(_profit);
            insurance.reportLoss(totalDebt, _loss);
        } else {
            _profit = _profit.sub(_loss);
            _loss = 0;
            uint256 insurancePayment =
                insurance.reportProfit(totalDebt, _profit);
            _profit = _profit.sub(insurancePayment);

            // double check insurance isn't asking for too much or zero
            if (insurancePayment > 0 && insurancePayment < _profit) {
                want.transfer(address(insurance), insurancePayment);
            }
        }
    }

    function _harvestRewards() internal {
        if (sellCompAtHarvest){
            _harvestComp();
        }
        if (sellJointRewardsAtHarvest && jointVault.canHarvestJoint()){
            jointVault.harvestFromProvider();
        }
    }

    function _withdraw(uint256 _amountNeeded)
        internal
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        /// 1) check how much want is available 
        uint256 balanceWant = balanceOfWant();
        if (_amountNeeded <= balanceWant) {
            return (_amountNeeded, 0);
        }

        // 2) first get want from lend 
        uint256 balanceInLend = balanceLend();
        _redeemWant(balanceInLend);
        balanceWant = balanceOfWant();

        if (_amountNeeded <= balanceWant) {
            // if enough we add back to collateral 
            _lendWant(balanceWant.sub(_amountNeeded));
            return (_amountNeeded, 0);
        } else {
            // if not enough after removing from lend we pull from joint 
            if (debtJoint > 0) {
                uint256 amountFromJoint = _amountNeeded.sub(balanceWant);
                uint256 debtProportion = Math.min(amountFromJoint.mul(BASIS_PRECISION).div(debtJoint), BASIS_PRECISION);
                if (debtProportion > 9500){
                    debtProportion = BASIS_PRECISION;
                }
                jointVault.withdraw(debtProportion);
            }
        }

        /// 3) then get want from joint vault
        _liquidatedAmount = balanceOfWant();
        if (_liquidatedAmount < _amountNeeded) { 
            _loss = _amountNeeded.sub(_liquidatedAmount);
        }

    }

    function setInsurance(address _insurance) external onlyAuthorized {
        require(address(insurance) == address(0));
        insurance = IStrategyInsurance(_insurance);
    }

    function migrateInsurance(address _newInsurance) external onlyGovernance {
        require(address(_newInsurance) == address(0));
        insurance.migrateInsurance(_newInsurance);
        insurance = IStrategyInsurance(_newInsurance);
    }

    ///@notice This allows us to manually harvest with our keeper as needed
    function setForceHarvestTriggerOnce(bool _forceHarvestTriggerOnce) external onlyAuthorized {
        forceHarvestTriggerOnce = _forceHarvestTriggerOnce;
    }

    function setLendDustPercent(uint256 _lendDustPercent) external onlyAuthorized {
        lendDustPercent = _lendDustPercent;
    }

    function setdebtJointThresholds(uint256 _debtJointMin, uint256 _debtJointMax) external onlyAuthorized {
        debtJointMin = _debtJointMin;
        debtJointMax = _debtJointMax;
    }

    function setJointTokenIndex(uint256 _jointTokenIndex) external onlyJoint {
        jointTokenIndex = _jointTokenIndex;
    }

    function setOtherJointTokenIndex(uint256 _otherJointTokenIndex) external onlyJoint {
        otherJointTokenIndex = _otherJointTokenIndex;
    }

    function isInProfit() public view returns(bool) {
        uint256 totalAssets = estimatedTotalAssets();
        uint256 totalDebt = _getTotalDebt();
        return(totalAssets > totalDebt);
    }

    function harvestTrigger(uint256 callCostInWei) public view virtual override returns (bool) {
        StrategyParams memory params = vault.strategies(address(this));

        // trigger if we want to manually harvest
        if (forceHarvestTriggerOnce) {
            return true;
        }

        // harvest no matter what once we reach our maxDelay
        if (block.timestamp.sub(params.lastReport) > maxReportDelay) {
            return jointVault.allStratsInProfit();
        }

        // otherwise, we don't harvest
        return false;
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        
        uint256 wantBefore = balanceOfWant();

        if (_debtOutstanding >= wantBefore) {
            return;
        }

        uint256 stratPercentFree = wantAvailable().mul(BASIS_PRECISION).div(estimatedTotalAssets());

        if (stratPercentFree > debtJointMin){
            jointVault.addToJoint();
        }

        uint256 wantAfter = balanceOfWant();

        if (wantAfter > 0) { 
            _lendWant(wantAfter);
        }

        // TODO: Do something to invest excess `want` tokens (from the Vault) into your positions
        // NOTE: Try to adjust positions so that `_debtOutstanding` can be freed up on *next* harvest (not immediately)
    }

    // this is called by LpVault 
    function provideWant(uint256 _wantAmount) external onlyJoint {
        uint256 balanceWant = balanceOfWant();

        if (balanceWant < _wantAmount) {
            uint256 redeemAmount = _wantAmount.sub(balanceWant);
            _redeemWant(redeemAmount);
        }

        uint256 transferAmount = Math.min(_wantAmount, want.balanceOf(address(this)));

        want.transfer(address(jointVault), transferAmount);
        debtJoint = debtJoint.add(transferAmount);

    }

    function adjustJointDebtOnWithdraw(uint256 _debtProportion) external onlyJoint {
        debtJoint = debtJoint.mul(BASIS_PRECISION.sub(_debtProportion)).div(BASIS_PRECISION);
    }

    function liquidatePositionAuth(uint256 _amount) external onlyAuthorized {
        liquidatePosition(_amount);
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 balanceWant = balanceOfWant();
        uint256 totalAssets = estimatedTotalAssets();

        // if estimatedTotalAssets is less than params.debtRatio it means there's
        // been a loss (ignores pending harvests). This type of loss is calculated
        // proportionally
        // This stops a run-on-the-bank if there's IL between harvests.
        uint256 newAmount = _amountNeeded;
        uint256 totalDebt = _getTotalDebt();
        if (totalDebt > totalAssets) {
            uint256 ratio = totalAssets.mul(STD_PRECISION).div(totalDebt);
            newAmount = _amountNeeded.mul(ratio).div(STD_PRECISION);
            _loss = _amountNeeded.sub(newAmount);
        }

        // Liquidate the amount needed
        (, uint256 _slippage) = _withdraw(newAmount);
        _loss = _loss.add(_slippage);

        // NOTE: Maintain invariant `want.balanceOf(this) >= _liquidatedAmount`
        // NOTE: Maintain invariant `_liquidatedAmount + _loss <= _amountNeeded`
        _liquidatedAmount = balanceOfWant();
        if (_liquidatedAmount.add(_loss) > _amountNeeded) {
            _liquidatedAmount = _amountNeeded.sub(_loss);
        } else {
            _loss = _amountNeeded.sub(_liquidatedAmount);
        }
    }

    function liquidateJointAuth() external onlyAuthorized {
        if (debtJoint > 0){
            jointVault.withdraw(BASIS_PRECISION);
        }
    }

    function liquidateLendAuth() external onlyAuthorized {
        _redeemWant(balanceLend());
    }

    function liquidateAllPositionsAuth() external onlyAuthorized {
        liquidateAllPositions();
    }

    function liquidateAllPositions() internal override returns (uint256) {
        
        _redeemWant(balanceLend());
        if (debtJoint > 0){
            jointVault.withdraw(BASIS_PRECISION);
        }

        return (want.balanceOf(address(this)));
    }

    function _getTotalDebt() internal view returns (uint256) {
        return vault.strategies(address(this)).totalDebt;
    }

    function _lendWant(uint256 amount) internal {
        if (amount > 0){
            cTokenLend.mint(amount);
        }
        
    }

    function _redeemWant(uint256 _redeem_amount) internal {
        // we add this in as can get some weird errors when tiny amount of lend left blocking withdrawals
        uint256 redeemDust = _getTotalDebt().mul(lendDustPercent).div(BASIS_PRECISION);
        
        if (_redeem_amount > redeemDust){
            cTokenLend.redeemUnderlying(_redeem_amount);
        }
    }

    function _harvestComp() internal {
        comptroller.claimComp(address(this));
        _sellCompWant();
    }

    function _sellCompWant() internal {
        uint256 compBalance = compToken.balanceOf(address(this));
        if (compBalance == 0) return;
        router.swapExactTokensForTokens(
            compBalance,
            0,
            getTokenOutPath(address(compToken), address(want)),
            address(this),
            now
        );
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

    function prepareMigration(address _newStrategy) internal override {
        liquidateAllPositions();
    }

    // Override this to add all tokens/tokenized positions this contract manages
    // on a *persistent* basis (e.g. not just for swapping back to want ephemerally)
    // NOTE: Do *not* include `want`, already included in `sweep` below
    //
    // Example:
    //
    //    function protectedTokens() internal override view returns (address[] memory) {
    //      address[] memory protected = new address[](3);
    //      protected[0] = tokenA;
    //      protected[1] = tokenB;
    //      protected[2] = tokenC;
    //      return protected;
    //    }
    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}

    function ethToWant(uint256 _amtInWei)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _amtInWei;
    }
}
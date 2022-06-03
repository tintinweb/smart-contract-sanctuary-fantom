// SPDX-License-Identifier: No License

pragma solidity ^0.8.13;

import "./interfaces/ISingularityRouter.sol";
import "./interfaces/ISingularityFactory.sol";
import "./interfaces/ISingularityPool.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./utils/SafeERC20.sol";
import "./utils/FixedPointMathLib.sol";

/**
 * @title Singularity Router
 * @author Revenant Labs
 */
contract SingularityRouter is ISingularityRouter {
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;

    address public immutable override factory;
    address public immutable override WETH;
    bytes32 public immutable override poolCodeHash;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "SingularityRouter: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) {
        require(_factory != address(0), "SingularityRouter: FACTORY_IS_0");
        require(_WETH != address(0), "SingularityRouter: WETH_IS_0");
        factory = _factory;
        WETH = _WETH;
        poolCodeHash = ISingularityFactory(_factory).poolCodeHash();
    }

    receive() external payable {
        assert(msg.sender == WETH);
    }

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 amountOut) {
        (amountOut, , , , ) = getAmountOut(amountIn, tokenIn, tokenOut);
        require(amountOut >= minAmountOut, "SingularityRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        _swap(amountIn, tokenIn, tokenOut, to);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut, to);
    }

    function swapExactETHForTokens(
        address tokenIn,
        address tokenOut,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external payable override ensure(deadline) returns (uint256 amountOut) {
        require(tokenIn == WETH, "SingularityRouter: INVALID_IN_TOKEN");
        (amountOut, , , , ) = getAmountOut(msg.value, tokenIn, tokenOut);
        require(amountOut >= minAmountOut, "SingularityRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{value: msg.value}();
        _swap(msg.value, tokenIn, tokenOut, to);

        emit Swap(msg.sender, tokenIn, tokenOut, msg.value, amountOut, to);
    }

    function swapExactTokensForETH(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 amountOut) {
        require(tokenOut == WETH, "SingularityRouter: INVALID_OUT_TOKEN");
        (amountOut, , , , ) = getAmountOut(amountIn, tokenIn, tokenOut);
        require(amountOut >= minAmountOut, "SingularityRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        _swap(amountIn, tokenIn, tokenOut, address(this));
        IWETH(WETH).withdraw(amountOut);
        _safeTransferETH(to, amountOut);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut, to);
    }

    function _swap(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address to
    ) internal virtual {
        require(tokenIn != tokenOut, "SingularityRouter: SAME_TOKEN");
        address poolIn = poolFor(tokenIn);
        IERC20(tokenIn).safeIncreaseAllowance(poolIn, amountIn);
        uint256 amountOut = ISingularityPool(poolIn).swapIn(amountIn);
        address poolOut = poolFor(tokenOut);
        ISingularityPool(poolOut).swapOut(amountOut, to);
    }

    function addLiquidity(
        address token,
        uint256 amount,
        uint256 minLiquidity,
        address to,
        uint256 deadline
    ) public override ensure(deadline) returns (uint256 liquidity) {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        liquidity = _addLiquidity(token, amount, minLiquidity, to);
    }

    function addLiquidityETH(
        uint256 minLiquidity,
        address to,
        uint256 deadline
    ) external payable override ensure(deadline) returns (uint256 liquidity) {
        IWETH(WETH).deposit{value: msg.value}();
        liquidity = _addLiquidity(WETH, msg.value, minLiquidity, to);
    }

    function _addLiquidity(
        address token,
        uint256 amount,
        uint256 minLiquidity,
        address to
    ) internal returns (uint256 liquidity) {
        address pool = poolFor(token);
        IERC20(token).safeIncreaseAllowance(pool, amount);
        liquidity = ISingularityPool(pool).deposit(amount, to);
        require(liquidity >= minLiquidity, "SingularityRouter: INSUFFICIENT_LIQUIDITY_AMOUNT");
    }

    function removeLiquidity(
        address token,
        uint256 liquidity,
        uint256 amountMin,
        address to,
        uint256 deadline
    ) public override ensure(deadline) returns (uint256 amount) {
        address pool = poolFor(token);
        IERC20(pool).safeTransferFrom(msg.sender, address(this), liquidity);
        amount = ISingularityPool(pool).withdraw(liquidity, to);
        require(amount >= amountMin, "SingularityRouter: INSUFFICIENT_TOKEN_AMOUNT");
    }

    function removeLiquidityETH(
        uint256 liquidity,
        uint256 amountMin,
        address to,
        uint256 deadline
    ) public payable override ensure(deadline) returns (uint256 amount) {
        amount = removeLiquidity(WETH, liquidity, amountMin, address(this), deadline);
        IWETH(WETH).withdraw(amount);
        _safeTransferETH(to, amount);
    }

    function removeLiquidityWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 amount) {
        address pool = poolFor(token);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        ISingularityPool(pool).permit(msg.sender, address(this), value, deadline, v, r, s);
        amount = removeLiquidity(token, liquidity, amountMin, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        uint256 liquidity,
        uint256 amountMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 amount) {
        address pool = poolFor(WETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        ISingularityPool(pool).permit(msg.sender, address(this), value, deadline, v, r, s);
        amount = removeLiquidityETH(liquidity, amountMin, to, deadline);
    }

    function poolFor(address token) public view override returns (address pool) {
        pool = address(
            uint160(
                uint256(keccak256(abi.encodePacked(hex"ff", factory, keccak256(abi.encodePacked(token)), poolCodeHash)))
            )
        );
    }

    function getAddLiquidityAmount(address token, uint256 amount) external view override returns (uint256 mintAmount) {
        address pool = poolFor(token);

        if (ISingularityPool(pool).liabilities() == 0) {
            mintAmount = amount;
        } else {
            uint256 depositFee = ISingularityPool(pool).getDepositFee(amount);
            uint256 amountPostFee = amount - depositFee;
            uint256 pricePerShare = ISingularityPool(pool).getPricePerShare();
            mintAmount = amountPostFee.divWadDown(pricePerShare);
        }
    }

    function getRemoveLiquidityAmount(address token, uint256 lpAmount)
        external
        view
        override
        returns (uint256 withdrawalAmount)
    {
        address pool = poolFor(token);
        uint256 pricePerShare = ISingularityPool(pool).getPricePerShare();
        uint256 amount = lpAmount.mulWadDown(pricePerShare);
        uint256 withdrawalFee = ISingularityPool(pool).getWithdrawalFee(amount);
        withdrawalAmount = amount - withdrawalFee;
    }

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    )
        public
        view
        override
        returns (
            uint256 amountOut,
            uint256 tradingFeeIn,
            uint256 slippageIn,
            uint256 slippageOut,
            uint256 tradingFeeOut
        )
    {
        if (amountIn == 0) {
            return (0, 0, 0, 0, 0);
        }

        address poolIn = poolFor(tokenIn);

        slippageIn = ISingularityPool(poolIn).getSlippageIn(amountIn);
        amountIn += slippageIn;

        (tradingFeeIn, , ) = ISingularityPool(poolIn).getTradingFees(amountIn);
        require(tradingFeeIn != type(uint256).max, "SingularityRouter: STALE_ORACLE_IN");
        amountIn -= tradingFeeIn;

        uint256 swapInAmountOut = ISingularityPool(poolIn).getAmountToUSD(amountIn);

        address poolOut = poolFor(tokenOut);
        amountOut = ISingularityPool(poolOut).getUSDToAmount(swapInAmountOut);

        slippageOut = ISingularityPool(poolOut).getSlippageOut(amountOut);
        require(amountOut > slippageOut, "SingularityRouter: SLIPPAGE_EXCEEDS_AMOUNT");
        amountOut -= slippageOut;

        (tradingFeeOut, , ) = ISingularityPool(poolOut).getTradingFees(amountOut);
        require(tradingFeeOut != type(uint256).max, "SingularityRouter: STALE_ORACLE_OUT");
        amountOut -= tradingFeeOut;
    }

    function _safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "SingularityRouter: ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.13;

interface ISingularityRouter {
    event Swap(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address indexed to
    );

    function factory() external returns (address);

    function WETH() external returns (address);

    function poolCodeHash() external returns (bytes32);

    function poolFor(address token) external view returns (address pool);

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactETHForTokens(
        address tokenIn,
        address tokenOut,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function swapExactTokensForETH(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function addLiquidity(
        address token,
        uint256 amount,
        uint256 minLiquidity,
        address to,
        uint256 deadline
    ) external returns (uint256 liquidity);

    function addLiquidityETH(
        uint256 minLiquidity,
        address to,
        uint256 deadline
    ) external payable returns (uint256 liquidity);

    function removeLiquidity(
        address token,
        uint256 liquidity,
        uint256 amountMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function removeLiquidityETH(
        uint256 liquidity,
        uint256 amountMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amount);

    function removeLiquidityWithPermit(
        address token,
        uint256 liquidity,
        uint256 minLiquidity,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount);

    function removeLiquidityETHWithPermit(
        uint256 liquidity,
        uint256 amountMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount);

    function getAddLiquidityAmount(address token, uint256 amount) external view returns (uint256 mintAmount);

    function getRemoveLiquidityAmount(address token, uint256 lpAmount) external view returns (uint256 withdrawalAmount);

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    )
        external
        view
        returns (
            uint256 amountOut,
            uint256 tradingFeeIn,
            uint256 slippageIn,
            uint256 slippageOut,
            uint256 tradingFeeOut
        );
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.13;

interface ISingularityFactory {
    struct PoolParams {
        address token;
        bool isStablecoin;
        uint256 baseFee;
    }

    event PoolCreated(address indexed token, bool isStablecoin, uint256 baseFee, address pool, uint256 index);

    function tranche() external view returns (string memory);

    function admin() external view returns (address);

    function oracle() external view returns (address);

    function feeTo() external view returns (address);

    function router() external view returns (address);

    function protocolFeeShare() external view returns (uint256);

    function oracleSens() external view returns (uint256);

    function poolParams()
        external
        view
        returns (
            address token,
            bool isStablecoin,
            uint256 baseFee
        );

    function getPool(address token) external view returns (address pool);

    function allPools(uint256) external view returns (address pool);

    function allPoolsLength() external view returns (uint256);

    function poolCodeHash() external pure returns (bytes32);

    function createPool(
        address token,
        bool isStablecoin,
        uint256 baseFee
    ) external returns (address pool);

    function setAdmin(address _admin) external;

    function setOracle(address _oracle) external;

    function setFeeTo(address _feeTo) external;

    function setRouter(address _router) external;

    function setProtocolFeeShare(uint256 _protocolFeeShare) external;

    function setOracleSens(uint256 _oracleSens) external;

    function collectFees() external;

    function setDepositCaps(address[] calldata tokens, uint256[] calldata caps) external;

    function setBaseFees(address[] calldata tokens, uint256[] calldata baseFees) external;

    function setPaused(address[] calldata tokens, bool[] calldata states) external;

    function setPausedForAll(bool state) external;
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.13;

import "./ISingularityPoolToken.sol";

interface ISingularityPool is ISingularityPoolToken {
    event Deposit(address indexed sender, uint256 indexed amountDeposited, uint256 mintAmount, address indexed to);
    event Withdraw(address indexed sender, uint256 indexed amountBurned, uint256 withdrawalAmount, address indexed to);
    event SwapIn(address indexed sender, uint256 amountIn, uint256 amountOut);
    event SwapOut(address indexed sender, uint256 amountIn, uint256 amountOut, address indexed to);

    function paused() external view returns (bool);

    function isStablecoin() external view returns (bool);

    function factory() external view returns (address);

    function token() external view returns (address);

    function depositCap() external view returns (uint256);

    function assets() external view returns (uint256);

    function liabilities() external view returns (uint256);

    function protocolFees() external view returns (uint256);

    function baseFee() external view returns (uint256);

    function deposit(uint256 amount, address to) external returns (uint256);

    function withdraw(uint256 lpAmount, address to) external returns (uint256);

    function swapIn(uint256 amountIn) external returns (uint256);

    function swapOut(uint256 amountIn, address to) external returns (uint256);

    function getPricePerShare() external view returns (uint256);

    function getAssetsAndLiabilities() external view returns (uint256, uint256);

    function getCollateralizationRatio() external view returns (uint256);

    function getOracleData() external view returns (uint256, uint256);

    function getAmountToUSD(uint256 amount) external view returns (uint256);

    function getUSDToAmount(uint256 value) external view returns (uint256);

    function getDepositFee(uint256 amount) external view returns (uint256);

    function getWithdrawalFee(uint256 amount) external view returns (uint256);

    function getSlippageIn(uint256 amount) external view returns (uint256);

    function getSlippageOut(uint256 amount) external view returns (uint256);

    function getTradingFeeRate() external view returns (uint256 tradingFeeRate);

    function getTradingFees(uint256 amount)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function collectFees() external;

    function setDepositCap(uint256 newDepositCap) external;

    function setBaseFee(uint256 newBaseFee) external;

    function setPaused(bool state) external;
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.13;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.13;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*///////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.13;

interface ISingularityPoolToken {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function nonces(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
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

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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
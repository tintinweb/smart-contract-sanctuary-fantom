// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../../swap/interfaces/IPool.sol";
import "../interfaces/ICurve.sol";
import "../../assets/interfaces/IWETH.sol";
import "../../crossChain/interfaces/IWrapper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract O3FantomCurveAggregator is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event LOG_AGG_SWAP (
        uint256 amountOut,
        uint256 fee
    );

    address public WETH = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address public O3Wrapper = 0x12682669700109AE1F3B326D74f2A5bDB63549E3;
    address public feeCollector;

    uint256 public aggregatorFee = 1 * 10**6;
    uint256 public constant FEE_DENOMINATOR = 10 ** 10;
    uint256 private constant MAX_AGGREGATOR_FEE = 5 * 10**8;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'O3Aggregator: EXPIRED');
        _;
    }

    constructor (address _feeCollector) {
        feeCollector = _feeCollector;
    }

    receive() external payable { }

    function setWETH(address _weth) external onlyOwner {
        WETH = _weth;
    }

    function setO3Wrapper(address _wrapper) external onlyOwner {
        O3Wrapper = _wrapper;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
    }

    function setAggregatorFee(uint256 _fee) external onlyOwner {
        require(_fee < MAX_AGGREGATOR_FEE, "aggregator fee exceeds maximum");
        aggregatorFee = _fee;
    }

    function rescueFund(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        if (tokenAddress == WETH && address(this).balance > 0) {
            (bool success,) = _msgSender().call{value: address(this).balance}(new bytes(0));
            require(success, 'ETH_TRANSFER_FAILED');
        }
        token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    }

    function exchangePTokensForTokens(
        uint256 amountIn, address ptokenAddr, address ptokenPoolAddr, uint256 ptokenPoolMinDy,
        address curvePoolAddr, address[] calldata path, uint256 curvePoolMinDy,
        address toAddress, uint256 deadline, bool unwrapETH
    ) external virtual ensure(deadline) {
        uint256 amountOut = _exchangePTokensForTokens(
            amountIn, deadline, ptokenAddr, ptokenPoolAddr, ptokenPoolMinDy,
            curvePoolAddr, path, curvePoolMinDy
        );

        uint256 feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        if (unwrapETH) {
            require(path[1] == WETH, "O3Aggregator: INVALID_TO_TOKEN");
            IWETH(WETH).withdraw(amountOut);
            _sendETH(feeCollector, feeAmount);
            _sendETH(toAddress, amountOut.sub(feeAmount));
        } else {
            IERC20(path[1]).safeTransfer(feeCollector, feeAmount);
            IERC20(path[1]).safeTransfer(toAddress, amountOut.sub(feeAmount));
        }
    }

    function _exchangePTokensForTokens(
        uint256 amountIn, uint256 deadline,
        address ptokenAddr, address ptokenPoolAddr, uint256 ptokenPoolMinDy,
        address curvePoolAddr, address[] calldata path, uint256 curvePoolMinDy
    ) internal returns (uint256) {
        if (amountIn == 0) {
            amountIn = IERC20(ptokenAddr).allowance(_msgSender(), address(this));
        }

        IERC20(ptokenAddr).safeTransferFrom(_msgSender(), address(this), amountIn);

        (address underlyingToken, uint256 curveAmountIn) = _ptokenSwap(
            amountIn, ptokenAddr, ptokenPoolAddr, ptokenPoolMinDy, deadline
        );

        require(underlyingToken == path[0], "O3Aggregator: INVALID_PATH");
        return _curveSwap(curvePoolAddr, curveAmountIn, path, curvePoolMinDy);
    }

    function _ptokenSwap(
        uint256 amountIn,
        address ptokenAddr,
        address ptokenPoolAddr,
        uint256 minDy,
        uint256 deadline
    ) internal returns (address, uint256) {
        require(amountIn != 0, "O3Aggregator: amountIn cannot be zero");

        address underlyingToken = address(IPool(ptokenPoolAddr).coins(0));
        uint256 balanceBefore = IERC20(underlyingToken).balanceOf(address(this));
        IERC20(ptokenAddr).safeApprove(ptokenPoolAddr, amountIn);
        IPool(ptokenPoolAddr).swap(1, 0, amountIn, minDy, deadline);

        return (underlyingToken, IERC20(underlyingToken).balanceOf(address(this)) - balanceBefore);
    }

    function _curveSwap(
        address curvePoolAddr,
        uint256 amountIn,
        address[] calldata path,
        uint256 minDy
    ) internal returns (uint256) {
        require(amountIn != 0, "O3Aggregator: amountIn cannot be zero");
        require(path.length == 2, "O3Aggregator: INVALID_PATH");

        IERC20(path[0]).safeApprove(curvePoolAddr, amountIn);
        (int128 i, int128 j) = _getPoolTokenIndex(curvePoolAddr, path[0], path[1]);

        address toToken = ICurve(curvePoolAddr).coins(uint256(int256(j)));
        uint256 balanceBefore = IERC20(toToken).balanceOf(address(this));
        ICurve(curvePoolAddr).exchange(i, j, amountIn, minDy);

        return IERC20(toToken).balanceOf(address(this)) - balanceBefore;
    }

    function exchangeTokensForTokens(
        uint256 amountIn,
        address curvePoolAddr,
        uint256 curvePoolMinDy,
        address[] calldata path,
        address toAddress,
        uint256 deadline
    ) external virtual ensure(deadline) {
        IERC20(path[0]).safeTransferFrom(_msgSender(), address(this), amountIn);

        (uint256 amountOut, uint256 feeAmount) = _exchangeTokensForTokens(
            amountIn, curvePoolAddr, curvePoolMinDy, path
        );

        IERC20(path[1]).safeTransfer(feeCollector, feeAmount);
        IERC20(path[1]).safeTransfer(toAddress, amountOut.sub(feeAmount));
    }

    function _exchangeTokensForTokens(
        uint256 amountIn,
        address curvePoolAddr,
        uint256 curvePoolMinDy,
        address[] calldata path
    ) internal returns (uint256, uint256) {
        uint256 amountOut = _curveSwap(curvePoolAddr, amountIn, path, curvePoolMinDy);
        uint256 feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        return (amountOut, feeAmount);
    }

    function exchangeTokensForTokensCrossChain(
        uint256 amountIn, address curvePoolAddr, uint256 curvePoolMinDy, address[] calldata path,
        address ptokenPoolAddr, address ptokenAddr, uint256 ptokenPoolMinDy,
        uint64 toChainId, bytes memory toAddress, bytes memory callData, uint256 deadline
    ) external virtual payable ensure(deadline) {
        IERC20(path[0]).safeTransferFrom(_msgSender(), address(this), amountIn);

        uint256 crossChainAmount = _exchangeTokensForTokensCrossChain(
            amountIn, curvePoolAddr, curvePoolMinDy, path
        );

        IERC20(path[1]).safeApprove(O3Wrapper, crossChainAmount);

        IWrapper(O3Wrapper).swapAndBridgeOut{value: msg.value}(
            ptokenPoolAddr, path[1], ptokenAddr, crossChainAmount, ptokenPoolMinDy, deadline,
            toChainId, toAddress, callData
        );
    }

    function _exchangeTokensForTokensCrossChain(
        uint256 amountIn,
        address curvePoolAddr,
        uint256 curvePoolMinDy,
        address[] calldata path
    ) internal returns (uint256) {
        (uint256 amountOut, uint256 feeAmount) = _exchangeTokensForTokens(
            amountIn, curvePoolAddr, curvePoolMinDy, path
        );

        IERC20(path[1]).safeTransfer(feeCollector, feeAmount);

        return amountOut.sub(feeAmount);
    }

    function exchangeETHForTokens(
        address curvePoolAddr,
        address[] calldata path,
        uint256 minDy,
        address toAddress,
        uint256 deadline
    ) external payable ensure(deadline) {
        uint256 amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();

        require(path[0] == WETH, 'O3Aggregator: INVALID_PATH');
        uint256 amountOut = _curveSwap(curvePoolAddr, amountIn, path, minDy);
        uint256 feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        IERC20(path[1]).safeTransfer(feeCollector, feeAmount);
        IERC20(path[1]).safeTransfer(toAddress, amountOut.sub(feeAmount));
    }

    function exchangeETHForTokensCrossChain(
        address curvePoolAddr, uint256 curvePoolMinDy, address[] calldata path,
        address ptokenPoolAddr, address ptokenAddr, uint256 ptokenPoolMinDy,
        uint256 fee, uint64 toChainId, bytes memory toAddress, bytes memory callData, uint256 deadline
    ) external payable ensure(deadline) {
        IWETH(WETH).deposit{value: msg.value.sub(fee)}();

        require(path[0] == WETH, 'O3Aggregator: INVALID_PATH');
        uint256 crossChainAmount = _exchangeTokensForTokensCrossChain(
            msg.value.sub(fee), curvePoolAddr, curvePoolMinDy, path
        );

        IERC20(path[1]).safeApprove(O3Wrapper, crossChainAmount);

        IWrapper(O3Wrapper).swapAndBridgeOut{value: fee}(
            ptokenPoolAddr, path[1], ptokenAddr, crossChainAmount, ptokenPoolMinDy, deadline,
            toChainId, toAddress, callData
        );
    }

    function exchangeTokensForETH(
        uint256 amountIn,
        uint256 curvePoolMinDy,
        address curvePoolAddr,
        address[] calldata path,
        address toAddress,
        uint256 deadline
    ) external ensure(deadline) {
        require(path[1] == WETH, 'O3Aggregator: INVALID_PATH');

        IERC20(path[0]).safeTransferFrom(_msgSender(), address(this), amountIn);

        uint256 amountOut = _curveSwap(curvePoolAddr, amountIn, path, curvePoolMinDy);
        uint256 feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        IWETH(WETH).withdraw(amountOut);

        _sendETH(feeCollector, feeAmount);
        _sendETH(toAddress, amountOut.sub(feeAmount));
    }

    function _sendETH(address to, uint256 amount) internal {
        (bool success,) = to.call{value:amount}(new bytes(0));
        require(success, 'O3Aggregator: ETH_TRANSFER_FAILED');
    }

    function _getPoolTokenIndex(
        address curvePoolAddr,
        address fromToken,
        address toToken
    ) internal returns (int128, int128) {
        int128 i;
        int128 j;
        bytes1 found = 0x00;

        for (uint256 idx = 0; idx < 8; idx++) {
            address coin = ICurve(curvePoolAddr).coins(idx);
            if (coin == fromToken) {
                i = int128(int256(idx));
                found |= bytes1(uint8(0x1));
            } else if (coin == toToken) {
                j = int128(int256(idx));
                found |= bytes1(uint8(0x2));
            }

            if (found == 0x03) {
                return (i, j);
            }
        }

        revert("token not pooled");
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function coins(uint256 index) external view returns(IERC20);
    function getA() external view returns (uint256);
    function getTokenIndex(address token) external view returns (uint8);

    function getVirtualPrice() external view returns (uint256);

    function calculateSwap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx) external view returns (uint256 dy);
    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory);
    function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256);
    function calculateWithdrawOneToken(uint256 tokenAmount, uint8 tokenIndex) external view returns (uint256 amount);

    function swap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline) external returns (uint256);
    function addLiquidity(uint256[] memory amounts, uint256 minToMint, uint256 deadline) external returns (uint256);
    function removeLiquidity(uint256 amount, uint256[] calldata minAmounts, uint256 deadline) external returns (uint256[] memory);
    function removeLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex, uint256 minAmount, uint256 deadline) external returns (uint256);
    function removeLiquidityImbalance(uint256[] calldata amounts, uint256 maxBurnAmount, uint256 deadline) external returns (uint256);

    function applySwapFee(uint256 newSwapFee) external;
    function applyAdminFee(uint256 newAdminFee) external;
    function getAdminBalance(uint256 index) external view returns (uint256);
    function withdrawAdminFee(address receiver) external;
    function rampA(uint256 _futureA, uint256 _futureTime) external;
    function stopRampA() external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IWrapper {
    function bridgeOut(
        address pTokenAddress,
        uint256 amount,
        uint64 toChainId,
        bytes memory toAddress,
        bytes memory callData
    ) external payable returns(bool);

    function swapAndBridgeOut(
        address poolAddress, address tokenFrom, address tokenTo, uint256 dx, uint256 minDy, uint256 deadline, // args for swap
        uint64 toChainId, bytes memory toAddress, bytes memory callData                                       // args for bridge
    ) external payable returns(bool);

    function swapAndBridgeOutNativeToken(
        address poolAddress, address tokenTo, uint256 dx, uint256 minDy, uint256 deadline, // args for swap
        uint64 toChainId, bytes memory toAddress, bytes memory callData                    // args for bridge
    ) external payable returns(bool);

    function depositAndBridgeOut(
        address originalToken,
        address pTokenAddress,
        uint256 amount,
        uint64 toChainId,
        bytes memory toAddress,
        bytes memory callData
    ) external payable returns(bool);

    function depositAndBridgeOutNativeToken(
        address pTokenAddress,
        uint256 amount,
        uint64 toChainId,
        bytes memory toAddress,
        bytes memory callData
    ) external payable returns(bool);

    function bridgeOutAndWithdraw(
        address pTokenAddress,
        uint64 toChainId,
        bytes memory toAddress,
        uint256 amount
    ) external payable returns(bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;

    function transfer(address dst, uint wad) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0;

interface ICurve {
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external returns (uint256 dy);
    function coins(uint256 index) external returns (address);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
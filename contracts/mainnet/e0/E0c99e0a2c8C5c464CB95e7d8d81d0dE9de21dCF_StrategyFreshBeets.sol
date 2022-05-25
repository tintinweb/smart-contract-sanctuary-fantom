// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IBalancer.sol";
import "./interfaces/IBar.sol";
import "./interfaces/IZap.sol";

contract FeeHandler is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;

    // Reward token to swap
    struct TokenInfo {
        address token;
    }

    // DAO
    uint256 public DAOShare; // 0 ... 10000 = 0 ... 100 %
    address public DAORewardToken;
    address public DAO;

    // Treasury and gov
    address public treasury;

    // routers
    address public spiritZapper; //0xF0ff07d19f310abab54724a8876Eee71E338c82F
    address public spiritRouter;
    address public spookyRouter;
    address public beethovenxRouter; //0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce

    // tokens, need for swap
    address public wFtmLqdrLP;
    address public spirit;
    address public linSpirit;
    address public boo;
    address public xBoo;
    address public freshBeets;
    address public freshBeetsVestingToken;
    address public wFtm;
    address public beets;

    TokenInfo[] public tokens;

    constructor() public {}

    // init
    function initialize(
        address _treasury,
        address _spiritRouter,
        address _spiritZapper,
        address _spookyRouter,
        address _beethovenxRouter
    ) public initializer {
        // init vault
        __Ownable_init();
        treasury = _treasury;

        spiritRouter = _spiritRouter;
        spiritZapper = _spiritZapper;

        spookyRouter = _spookyRouter;

        beethovenxRouter = _beethovenxRouter;

        wFtmLqdrLP = 0x4Fe6f19031239F105F753D1DF8A0d24857D0cAA2;
        spirit = 0x5Cc61A78F164885776AA610fb0FE1257df78E59B;
        linSpirit = 0xc5713B6a0F26bf0fdC1c52B90cd184D950be515C;
        boo = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
        xBoo = 0xa48d959AE2E88f1dAA7D5F611E01908106dE7598;
        freshBeets = 0xfcef8a994209d6916EB2C86cDD2AFD60Aa6F54b1;
        freshBeetsVestingToken = 0xcdE5a11a4ACB4eE4c805352Cec57E236bdBC3837;
        wFtm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
        beets = 0xF24Bcf4d1e507740041C9cFd2DddB29585aDCe1e;
    }

    // add reward token to handle
    function addToken(address _token) external onlyOwner {
        require(_token != address(0), "Token cannot be zero address");

        tokens.push(TokenInfo({token: _token}));
    }

    // set where to send funds
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "zero address");
        treasury = _treasury;
    }

    function setDAORewardToken(address _DAORewardToken) external onlyOwner {
        require(_DAORewardToken != address(0), "zero address");
        DAORewardToken = _DAORewardToken;
    }

    function setDAOShare(uint256 _DAOShare) external onlyOwner {
        require(_DAOShare <= 10000 || _DAOShare >= 0, "not in range");
        DAOShare = _DAOShare;
    }

    function setDAOAddress(address _DAO) external onlyOwner {
        require(_DAO != address(0), "zero address");
        DAO = _DAO;
    }

    // @notice  called by authorized addresses
    //          Scan every token, read balance, split to treasury and DAO.
    //          Treasury funds are swapped to LQDR-wFTM, DAO funds to _DAORewardToken
    function distributeFees() external onlyOwner {
        uint256 i;
        uint256 balance;

        // swap every token for wFTM
        for (i = 0; i < tokens.length; i++) {
            TokenInfo memory tokenInfo = tokens[i];
            balance = balanceOfToken(tokenInfo.token);
            if (balance > 0) {
                // swap the token
                swap(balance, tokenInfo.token);
            }
        }

        // total balance
        uint256 wFtmBalance = IERC20Upgradeable(wFtm).balanceOf(address(this));
        //split
        uint256 toDAO = wFtmBalance.mul(DAOShare).div(10000);

        // approve wFtmBalance
        IERC20Upgradeable(wFtm).approve(spiritZapper, 0);
        IERC20Upgradeable(wFtm).approve(spiritZapper, wFtmBalance);

        //swap toDAO to DAORewardToken if different from wFTM
        if (DAORewardToken != wFtm && toDAO > 0) {
            IZap(spiritZapper).swapToken(wFtm, toDAO, DAORewardToken, spiritRouter, address(this));
        }

        // create wFTM-LQDR LP on spiritswap
        IZap(spiritZapper).zapInToken(wFtm, wFtmBalance.sub(toDAO), wFtmLqdrLP, spiritRouter, address(this));
        // send to treasury
        uint256 toTreasury = IERC20Upgradeable(wFtmLqdrLP).balanceOf(address(this));
        IERC20Upgradeable(wFtmLqdrLP).safeTransfer(treasury, toTreasury);

        // upgrade 'toDAO' to DAORewardTokenBalance and send to DAO
        toDAO = IERC20Upgradeable(DAORewardToken).balanceOf(address(this));
        IERC20Upgradeable(DAORewardToken).safeTransfer(DAO, toDAO);
    }

    function swap(uint256 _amount, address _token) internal {
        //spirit
        if (_token == linSpirit) {
            uint256 swapAmount = _swapLinSpiritSpirit(_amount, linSpirit, spirit);
            IERC20Upgradeable(spirit).approve(spiritZapper, 0);
            IERC20Upgradeable(spirit).approve(spiritZapper, swapAmount);
            IZap(spiritZapper).swapToken(spirit, swapAmount, wFtm, spiritRouter, address(this));
        }
        //spooky
        else if (_token == xBoo) {
            // same function for xBOO as fBeets
            IBar(xBoo).leave(_amount);
            uint256 booAmount = IERC20Upgradeable(boo).balanceOf(address(this));
            IERC20Upgradeable(boo).approve(spiritZapper, 0);
            IERC20Upgradeable(boo).approve(spiritZapper, booAmount);
            IZap(spiritZapper).swapToken(boo, booAmount, wFtm, spookyRouter, address(this));
        }
        //beethovenx
        else if (_token == freshBeets) {
            // we exit with wFTM
            balancerExitFreshBeets(_amount);
        } else {
            // any token available on spiritswap
            IERC20Upgradeable(_token).approve(spiritZapper, 0);
            IERC20Upgradeable(_token).approve(spiritZapper, _amount);
            IZap(spiritZapper).swapToken(_token, _amount, wFtm, spiritRouter, address(this));
        }
    }

    function balancerExitFreshBeets(uint256 amount) internal {
        //leave bar
        IBar(freshBeets).leave(amount);

        // set poolId and read freshBeetsVestingToken balance
        bytes32 poolId = 0xcde5a11a4acb4ee4c805352cec57e236bdbc3837000200000000000000000019;
        uint256 balance = IERC20Upgradeable(freshBeetsVestingToken).balanceOf(address(this));

        // prepare assets and minAmountsOut for exitRequest struct
        address[] memory assets = new address[](2);
        assets[0] = wFtm;
        assets[1] = beets;

        uint256[] memory minAmountsOut = new uint256[](2);
        uint256[] memory balances = new uint256[](2);
        // compute minamountOuts
        (, balances, ) = IBalancer(beethovenxRouter).getPoolTokens(poolId);
        uint256 totalSupply = IERC20Upgradeable(freshBeetsVestingToken).totalSupply();
        uint256 share = balance.div(totalSupply);
        minAmountsOut[0] = share.mul(balances[0]).mul(9950).div(10000);
        minAmountsOut[1] = share.mul(balances[1]).mul(9950).div(10000);

        // set request struct for exiting pool
        IBalancer.ExitPoolRequest memory request;
        request.assets = assets;
        request.minAmountsOut = minAmountsOut;
        request.userData = abi.encode(IBalancer.ExitKind(0), balance, 0); //exit in wftm only
        request.toInternalBalance = false;

        // exit the pool in wFTM ONLY
        IERC20Upgradeable(freshBeetsVestingToken).approve(beethovenxRouter, 0);
        IERC20Upgradeable(freshBeetsVestingToken).approve(beethovenxRouter, balance);
        IBalancer(beethovenxRouter).exitPool(poolId, address(this), address(this), request);
    }

    function _swapLinSpiritSpirit(
        uint256 _amount,
        address assetIn,
        address assetOut
    ) private returns (uint256 swapAmount) {
        uint256 limit;
        uint256 deadline;

        IBalancer.SingleSwap memory singleSwap;
        singleSwap.poolId = 0x30a92a4eeca857445f41e4bb836e64d66920f1c0000200000000000000000071;
        singleSwap.kind = IBalancer.SwapKind(0);

        singleSwap.assetIn = assetIn;
        singleSwap.assetOut = assetOut;
        singleSwap.amount = _amount;

        // data for the funds
        IBalancer.FundManagement memory funds;
        funds.sender = address(this);
        funds.recipient = address(this);
        funds.toInternalBalance = false;

        // set limit and deadline
        limit = _amount.mul(9900).div(10000); //1% slippage
        deadline = block.timestamp;

        IERC20Upgradeable(linSpirit).approve(beethovenxRouter, 0);
        IERC20Upgradeable(linSpirit).approve(beethovenxRouter, _amount);
        swapAmount = IBalancer(beethovenxRouter).swap(singleSwap, funds, limit, deadline);
    }

    /*
        @notice withdraw any asset. Called if distributeFee() fail or token not supported 
    */
    function withdraw(
        uint256 amount,
        address token,
        address to
    ) external onlyOwner {
        require(amount > 0 && token != address(0), "check input");

        uint256 actualBalance = IERC20Upgradeable(token).balanceOf(address(this));

        // if amount is lower than actualBalance sends amount else send actualBalance
        if (amount <= actualBalance) {
            IERC20Upgradeable(token).safeTransfer(to, amount);
        } else {
            IERC20Upgradeable(token).safeTransfer(to, actualBalance);
        }
    }

    function balanceOfToken(address _token) public view returns (uint256) {
        return _token == address(0) ? 0 : IERC20(_token).balanceOf(address(this));
    }
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
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
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interface to beeth vault
interface IBalancer {
    // struct to interact with beeth pools
    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }
    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address recipient;
        bool toInternalBalance;
    }

    struct SwapRequest {
        SwapKind kind;
        address tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }

    // enum to interact with beeth structs
    enum SwapKind { GIVEN_IN, GIVEN_OUT }
    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT, MANAGEMENT_FEE_TOKENS_OUT }

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external;
    function exitPool(bytes32 poolId, address sender, address recipient, ExitPoolRequest memory request) external;
    function getPoolTokens(bytes32 poolId) external view returns(IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;



interface IBar{

    function enter(uint256 _amount) external;
    function leave(uint256 _shareOfFreshBeets) external;


}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IZap {
    function estimateZapInToken(address _from, address _to, address _router, uint _amt) external view returns (uint256, uint256);
    function swapToken(address _from, uint amount, address _to, address routerAddr, address _recipient) external;
    function swapToNative(address _from, uint amount, address routerAddr, address _recipient) external;
    function zapIn(address _to, address routerAddr, address _recipient) external payable;
    function zapInToken(address _from, uint amount, address _to, address routerAddr, address _recipient) external;
    function zapAcross(address _from, uint amount, address _toRouter, address _recipient) external;
    function zapOut(address _from, uint amount, address routerAddr, address _recipient) external;
    function zapOutToken(address _from, uint amount, address _to, address routerAddr, address _recipient) external;
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
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interface to beeth vault
interface IBalancer {
    // struct to interact with beeth pools
    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }
    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address recipient;
        bool toInternalBalance;
    }

    struct SwapRequest {
        SwapKind kind;
        address tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }

    // enum to interact with beeth structs
    enum SwapKind { GIVEN_IN, GIVEN_OUT }
    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT, MANAGEMENT_FEE_TOKENS_OUT }

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external;
    function exitPool(bytes32 poolId, address sender, address recipient, ExitPoolRequest memory request) external;
    function getPoolTokens(bytes32 poolId) external view returns(IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "./StrategySpiritBase.sol";
import "./interfaces/ISpiritGauge.sol";
import "./interfaces/ILinSpiritStrategy.sol";
import "./interfaces/ILinSpiritChef.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IBalancer.sol";
import "./interfaces/IMasterChef.sol";

contract StrategyLinSpirit is StrategySpiritBase {
    // Token addresses
    address public gauge;
    address public linSpiritStrategy;

    // token addresses for Beethovenx
    address public beethovenxRouter;

    // token addresses for LinSpirit
    address public spirit;
    address public linSpirit;
    address public linSpiritChef;

    constructor() public {}

    function initialize(
        address _gauge,
        address _lp,
        address _depositor,
        address _feeHandler,
        uint256 _feePerformance,
        uint256 _feeHarvest,
        uint256 _feeMax
    ) public initializer {
        initializeStrategyBase(_lp, _depositor, _feeHandler, _feePerformance, _feeHarvest, _feeMax);
        gauge = _gauge;
        linSpiritStrategy = address(0xbBf62f98D2F15F4D92a71a676a9baAC84eaB37d8);
        spirit = address(0x5Cc61A78F164885776AA610fb0FE1257df78E59B);
        linSpirit = address(0xc5713B6a0F26bf0fdC1c52B90cd184D950be515C);
        linSpiritChef = address(0x1CC765cD7baDf46A215bD142846595594AD4ffe3);
        beethovenxRouter = address(0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce);
    }

    function balanceOfPool() public view override returns (uint256) {
        //ISpiritGauge(gauge).balanceOf(linSpiritStrategy);
        return balanceOfPoolTracker;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 _pendingReward = ISpiritGauge(gauge).rewards(linSpiritStrategy);
        return _pendingReward;
    }

    // **** Setters ****

    function deposit() public override onlyBenevolent {
        uint256 _want = IERC20Upgradeable(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20Upgradeable(want).safeTransfer(linSpiritStrategy, _want);
            ILinSpiritStrategy(linSpiritStrategy).deposit(gauge, want);
        }
        balanceOfPoolTracker = balanceOfPoolTracker.add(_want);
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        if (balanceOfPoolTracker < _amount) {
            _amount = balanceOfPoolTracker;
        }
        // balanceOfPoolTracker = balanceOfPoolTracker.sub(_amount);
        ILinSpiritStrategy(linSpiritStrategy).withdraw(gauge, want, _amount);
        return _amount;
    }

    // **** State Mutations ****

    function harvest(address _harvester) public onlyBenevolent returns (uint256) {
        // harvest from Spirit Boosted Gauge
        ILinSpiritStrategy(linSpiritStrategy).claimGaugeReward(gauge);

        // harvest from linSpiritChef
        ILinSpiritChef(linSpiritChef).harvest(0, address(this));

        // get spirit balance
        uint256 spiritBalance = IERC20Upgradeable(spirit).balanceOf(address(this));

        // swap to linSpirit
        _swapLinSpiritSpirit(spiritBalance, spirit, linSpirit);

        // get linSpirit balance
        uint256 linSpiritBalance = IERC20Upgradeable(linSpirit).balanceOf(address(this));
        uint256 _feePerformance = linSpiritBalance.mul(feePerformance).div(feeMax);
        uint256 _feeHarvest = linSpiritBalance.mul(feeHarvest).div(feeMax);
        linSpiritBalance = linSpiritBalance.sub(_feePerformance).sub(_feeHarvest);

        IERC20Upgradeable(linSpirit).safeTransfer(feeHandler, _feePerformance);
        IERC20Upgradeable(linSpirit).safeTransfer(_harvester, _feeHarvest);

        // stake in masterchef
        _approveToken(linSpiritChef, linSpirit, linSpiritBalance);
        ILinSpiritChef(linSpiritChef).deposit(0, linSpiritBalance, address(this));

        return linSpiritBalance;
    }

    function claim(uint256 pendingLinSpirit) external onlyBenevolent {
        ILinSpiritChef(linSpiritChef).withdraw(0, pendingLinSpirit, address(this));
        IERC20Upgradeable(linSpirit).safeTransfer(msg.sender, pendingLinSpirit);
    }

    function _swapLinSpiritSpirit(
        uint256 _amount,
        address assetIn,
        address assetOut
    ) private returns (uint256 swapAmount) {
        uint256 limit;
        uint256 deadline;

        IBalancer.SingleSwap memory singleSwap;
        singleSwap.poolId = 0x30a92a4eeca857445f41e4bb836e64d66920f1c0000200000000000000000071;
        singleSwap.kind = IBalancer.SwapKind(0);

        singleSwap.assetIn = assetIn;
        singleSwap.assetOut = assetOut;
        singleSwap.amount = _amount;

        // data for the funds
        IBalancer.FundManagement memory funds;
        funds.sender = address(this);
        funds.recipient = address(this);
        funds.toInternalBalance = false;

        // set limit and deadline
        limit = _amount.mul(9900).div(10000); //slippage 1%
        deadline = block.timestamp;

        _approveToken(beethovenxRouter, spirit, _amount);
        swapAmount = IBalancer(beethovenxRouter).swap(singleSwap, funds, limit, deadline);
    }

    function _approveToken(
        address _spender,
        address _token,
        uint256 _amount
    ) internal {
        require(_token != address(0) && _spender != address(0), "_approveToken address(0)");
        uint256 allowances = IERC20Upgradeable(_token).allowance(address(this), _spender);
        // if allowances are too low and we have _amount then increase, if _amount is zero then no need on this tx
        if (allowances < _amount && _amount > 0) {
            IERC20Upgradeable(_token).safeApprove(_spender, 0);
            IERC20Upgradeable(_token).safeApprove(_spender, uint256(-1));
        }
    }

    function getBalance() public view returns (uint256) {
        // retrieve the balance of LinSpirit
        (uint256 amount, ) = IMasterChef(linSpiritChef).userInfo(0, address(this));
        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract StrategySpiritBase is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;
    using AddressUpgradeable for address;

    uint256 public balanceOfPoolTracker;

    // Tokens
    address public want;

    // User accounts
    address public depositor;

    address public feeHandler;
    uint256 public feePerformance;
    uint256 public feeHarvest;
    uint256 public feeMax;

    mapping(address => bool) public harvesters;

    constructor() public {}

    function initializeStrategyBase(
        address _want,
        address _depositor,
        address _feeHandler,
        uint256 _feePerformance,
        uint256 _feeHarvest,
        uint256 _feeMax
    ) public initializer {
        __Ownable_init();
        require(_want != address(0), "!zero address");
        require(_depositor != address(0), "!zero address");
        require(_feeMax != 0, "!feeMax");

        want = _want;
        depositor = _depositor;
        balanceOfPoolTracker = 0;
        feeHandler = _feeHandler;
        feePerformance = _feePerformance;
        feeHarvest = _feeHarvest;
        feeMax = _feeMax;
    }

    // **** Modifiers **** //

    modifier onlyBenevolent() {
        require(harvesters[msg.sender] || msg.sender == owner() || msg.sender == depositor);
        _;
    }

    // **** Views **** //

    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    function balanceOfPool() public view virtual returns (uint256);

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function setFees(
        uint256 _feePerformance,
        uint256 _feeHarvest,
        uint256 _feeMax
    ) external onlyOwner {
        require(_feePerformance + _feeHarvest < _feeMax, "!fee values");
        feePerformance = _feePerformance;
        feeHarvest = _feeHarvest;
        feeMax = _feeMax;
    }

    function setFeeHandler(address _feeHandler) external onlyOwner {
        require(_feeHandler != address(0), "!Null Address");
        feeHandler = _feeHandler;
    }

    // **** Setters **** //

    function whitelistHarvesters(address[] calldata _harvesters) external {
        require(msg.sender == owner() || harvesters[msg.sender], "not authorized");

        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = true;
        }
    }

    function revokeHarvesters(address[] calldata _harvesters) external onlyOwner {
        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = false;
        }
    }

    function setDepositor(address _depositor) external onlyOwner {
        depositor = _depositor;
    }

    // **** State mutations **** //
    function deposit() public virtual;

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20Upgradeable _asset) external onlyOwner returns (uint256 balance) {
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(depositor, balance);
    }

    // Withdraw partial funds
    function withdraw(uint256 _amount) external returns (uint256) {
        require(msg.sender == depositor, "!depositor");
        uint256 _balance = IERC20Upgradeable(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20Upgradeable(want).safeTransfer(depositor, _amount);
        uint256 temp = balanceOfPoolTracker;
        balanceOfPoolTracker = temp.sub(_amount);
        return _amount;
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == owner() || msg.sender == depositor, "!owner");
        _withdrawAll();

        balance = IERC20Upgradeable(want).balanceOf(address(this));

        IERC20Upgradeable(want).safeTransfer(depositor, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
        balanceOfPoolTracker = 0;
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ISpiritGauge{
  function deposit(uint256) external;
  function depositAll() external;
  function withdraw(uint256) external;
  function withdrawAll() external;
  function getReward() external;
  function balanceOf(address) external view returns(uint256);
  function rewards(address) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ILinSpiritStrategy {
    function balanceOfInSpirit() external view returns (uint256);

    function deposit(address, address) external;

    function withdraw(address) external;

    function withdraw(
        address,
        address,
        uint256
    ) external;

    function withdrawAll(address, address) external;

    function createLock(uint256, uint256) external;

    function increaseAmount(uint256) external;

    function increaseTime(uint256) external;

    function release() external;

    function claimGaugeReward(address _gauge) external;

    function claimSpirit(address) external returns (uint256);

    function claimRewards(address) external;

    function claimFees(address, address) external;

    function setStashAccess(address, bool) external;

    function vote(
        uint256,
        address,
        bool
    ) external;

    function voteGaugeWeight(address, uint256) external;

    function balanceOfPool(address) external view returns (uint256);

    function operator() external view returns (address);

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory);
}

// SPDX-License-Identifier: MIT


// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
interface ILinSpiritChef {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    function userInfo(uint256 pid, address user) external view returns (ILinSpiritChef.UserInfo memory);

    function harvest(uint256 pid, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function deposit(uint256 pid, uint256 amount, address to) external;
    function pendingSpirit(uint256 _pid, address _user) external view returns (uint256 pending);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IVault {

    function updateEpoch(uint256 amount, uint256 pid) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMasterChef {
    function BONUS_MULTIPLIER() external view returns (uint256);

    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate
    ) external;

    function bonusEndBlock() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function dev(address _devaddr) external;

    function devFundDivRate() external view returns (uint256);

    function devaddr() external view returns (address);

    function emergencyWithdraw(uint256 _pid) external;

    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    function massUpdatePools() external;

    function owner() external view returns (address);

    function pendingPickle(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function pending(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function pickle() external view returns (address);

    function picklePerBlock() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accPicklePerShare
        );

    function poolLength() external view returns (uint256);

    function renounceOwnership() external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setBonusEndBlock(uint256 _bonusEndBlock) external;

    function setDevFundDivRate(uint256 _devFundDivRate) external;

    function setPicklePerBlock(uint256 _picklePerBlock) external;

    function startBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;
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
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "./StrategySpookyBase.sol";
import "../SpiritBoostedFarms/interfaces/IMasterChef.sol";
import "../SpiritBoostedFarms/interfaces/IBar.sol";
import "../SpiritBoostedFarms/interfaces/IUniswapV2Router02.sol";


contract StrategySpookyXBoo is StrategySpookyBase {
    // Token addresses
    address public masterChef;
    uint256 public pid;

    // token addresses for spooky
    address public spookyRouter;
    address public boo;
    address public xBoo;
    address public aceLab;
    uint256 public aceLabPid;
    address public aceLabReward;
    address[] public aceLabRewardPath;
    uint256 public aceLabRewardSellLimit;

    address public secondReward;
    uint256 public secondRewardSellLimit;
    address[] public secondRewardPath;

    constructor() public {}

    function initialize(
        address _lp,
        address _masterChef,
        uint256 _pid,
        uint256 _aceLabPid,
        address _aceLabReward,
        uint256 _aceLabRewardSellLimit,
        address[] memory _route,
        address _depositor,
        address _feeHandler,
        uint256 _feePerformance,
        uint256 _feeHarvest,
        uint256 _feeMax
    ) public initializer {
        initializeStrategyBase(_lp, _depositor, _feeHandler, _feePerformance, _feeHarvest, _feeMax);
        masterChef = _masterChef;
        pid = _pid;
        spookyRouter = address(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        boo = address(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE);
        xBoo = address(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598);
        aceLab = address(0x2352b745561e7e6FCD03c093cE7220e3e126ace0);
        aceLabPid = _aceLabPid;
        aceLabReward = _aceLabReward;
        aceLabRewardPath = _route;
        aceLabRewardSellLimit = _aceLabRewardSellLimit;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMasterChef(masterChef).userInfo(pid, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 _pendingReward = IMasterChef(masterChef).pendingReward(pid, address(this));
        return _pendingReward;
    }

    // **** Setters ****

    function setAceLab(
        uint256 _aceLabPid,
        address _aceLabReward,
        uint256 _aceLabRewardSellLimit,
        address[] memory _route
    ) external onlyOwner {
        uint256 _xBooBalance = xBooBalanceInAceLab();
        IMasterChef(aceLab).withdraw(aceLabPid, _xBooBalance);
        aceLabPid = _aceLabPid;
        aceLabReward = _aceLabReward;
        aceLabRewardSellLimit = _aceLabRewardSellLimit;
        aceLabRewardPath = _route;
        IMasterChef(aceLab).deposit(_aceLabPid, _xBooBalance);
    }

    function setSecondReward(
        address _secondReward,
        uint256 _secondRewardSellLimit,
        address[] memory _route
    ) external onlyOwner {
        secondReward = _secondReward;
        secondRewardSellLimit = _secondRewardSellLimit;
        secondRewardPath = _route;
    }

    function deposit() public override onlyBenevolent {
        uint256 _want = IERC20Upgradeable(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20Upgradeable(want).safeApprove(masterChef, 0);
            IERC20Upgradeable(want).safeApprove(masterChef, _want);
            IMasterChef(masterChef).deposit(pid, _want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        IMasterChef(masterChef).withdraw(pid, _amount);
        return _amount;
    }

    // **** State Mutations ****

    function harvest(address _harvester) public onlyBenevolent returns (uint256) {
        // harvest from Spooky MasterChef
        IMasterChef(masterChef).withdraw(pid, 0);

        // harvest from aceLab
        IMasterChef(aceLab).withdraw(aceLabPid, 0);
        uint256 aceLabRewardAmount = IERC20Upgradeable(aceLabReward).balanceOf(address(this));

        if (aceLabRewardAmount > aceLabRewardSellLimit) {
            _swapWithPath(aceLabRewardPath, aceLabRewardAmount);
        }

        if (secondReward != address(0)) {
            uint256 secondRewardAmount = IERC20Upgradeable(secondReward).balanceOf(address(this));
            if (secondRewardAmount > secondRewardSellLimit) {
                _swapWithPath(secondRewardPath, secondRewardAmount);
            }
        }

        // get boo balance
        uint256 booBalance = IERC20Upgradeable(boo).balanceOf(address(this));

        // enter to xBoo
        _enterXBoo(booBalance);

        // get xBoo balance
        uint256 xBooBalance = IERC20Upgradeable(xBoo).balanceOf(address(this));
        uint256 _feePerformance = xBooBalance.mul(feePerformance).div(feeMax);
        uint256 _feeHarvest = xBooBalance.mul(feeHarvest).div(feeMax);
        xBooBalance = xBooBalance.sub(_feePerformance).sub(_feeHarvest);

        IERC20Upgradeable(xBoo).safeTransfer(feeHandler, _feePerformance);
        IERC20Upgradeable(xBoo).safeTransfer(_harvester, _feeHarvest);

        // stake in aceLab
        _approveToken(aceLab, xBoo, xBooBalance);
        IMasterChef(aceLab).deposit(aceLabPid, xBooBalance);

        return xBooBalance;
    }

    function xBooBalanceInAceLab() public view returns (uint256 _xBooBalance) {
        (_xBooBalance, ) = IMasterChef(aceLab).userInfo(aceLabPid, address(this));
    }

    function claim(uint256 pendingXBoo) external onlyBenevolent {
        IMasterChef(aceLab).withdraw(aceLabPid, pendingXBoo);
        IERC20Upgradeable(xBoo).safeTransfer(msg.sender, pendingXBoo);
    }

    function _enterXBoo(uint256 _amount) private returns (uint256 enterAmount) {
        _approveToken(xBoo, boo, _amount);
        IBar(xBoo).enter(_amount);
        enterAmount = IERC20Upgradeable(xBoo).balanceOf(address(this));
    }

    function _approveToken(
        address _spender,
        address _token,
        uint256 _amount
    ) internal {
        require(_token != address(0) && _spender != address(0), "_approveToken address(0)");
        uint256 allowances = IERC20Upgradeable(_token).allowance(address(this), _spender);
        // if allowances are too low and we have _amount then increase, if _amount is zero then no need on this tx
        if (allowances < _amount && _amount > 0) {
            IERC20Upgradeable(_token).safeApprove(_spender, 0);
            IERC20Upgradeable(_token).safeApprove(_spender, uint256(-1));
        }
    }

    function _swapWithPath(address[] memory _path, uint256 _amount) internal {
        require(_path[1] != address(0));
        _approveToken(spookyRouter, _path[0], _amount);
        IUniswapV2Router02(spookyRouter).swapExactTokensForTokens(_amount, 1, _path, address(this), now.add(60));
    }

    function getBalance() public view returns (uint256) {
        // retrieve the balance of xBoo
        (uint256 amount, ) = IMasterChef(aceLab).userInfo(aceLabPid, address(this));
        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract StrategySpookyBase is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;
    using AddressUpgradeable for address;

    // Tokens
    address public want;

    // User accounts
    address public depositor;

    address public feeHandler;
    uint256 public feePerformance;
    uint256 public feeHarvest;
    uint256 public feeMax;

    mapping(address => bool) public harvesters;

    constructor() public {}

    function initializeStrategyBase(
        address _want,
        address _depositor,
        address _feeHandler,
        uint256 _feePerformance,
        uint256 _feeHarvest,
        uint256 _feeMax
    ) public initializer {
        __Ownable_init();
        require(_want != address(0), "!zero address");
        require(_depositor != address(0), "!zero address");
        require(_feeMax != 0, "!feeMax");

        want = _want;
        depositor = _depositor;
        feeHandler = _feeHandler;
        feePerformance = _feePerformance;
        feeHarvest = _feeHarvest;
        feeMax = _feeMax;
    }

    // **** Modifiers **** //

    modifier onlyBenevolent() {
        require(harvesters[msg.sender] || msg.sender == owner() || msg.sender == depositor);
        _;
    }

    // **** Views **** //

    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    function balanceOfPool() public view virtual returns (uint256);

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function setFees(
        uint256 _feePerformance,
        uint256 _feeHarvest,
        uint256 _feeMax
    ) external onlyOwner {
        require(_feePerformance + _feeHarvest < _feeMax, "!fee values");
        feePerformance = _feePerformance;
        feeHarvest = _feeHarvest;
        feeMax = _feeMax;
    }

    function setFeeHandler(address _feeHandler) external onlyOwner {
        require(_feeHandler != address(0), "!Null Address");
        feeHandler = _feeHandler;
    }

    // **** Setters **** //

    function whitelistHarvesters(address[] calldata _harvesters) external {
        require(msg.sender == owner() || harvesters[msg.sender], "not authorized");

        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = true;
        }
    }

    function revokeHarvesters(address[] calldata _harvesters) external onlyOwner {
        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = false;
        }
    }

    function setDepositor(address _depositor) external onlyOwner {
        depositor = _depositor;
    }

    // **** State mutations **** //
    function deposit() public virtual;

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20Upgradeable _asset) external onlyOwner returns (uint256 balance) {
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(depositor, balance);
    }

    // Withdraw partial funds
    function withdraw(uint256 _amount) external returns (uint256) {
        require(msg.sender == depositor, "!depositor");
        uint256 _balance = IERC20Upgradeable(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20Upgradeable(want).safeTransfer(depositor, _amount);
        return _amount;
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == owner() || msg.sender == depositor, "!owner");
        _withdrawAll();

        balance = IERC20Upgradeable(want).balanceOf(address(this));

        IERC20Upgradeable(want).safeTransfer(depositor, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;



interface IBar{

    function enter(uint256 _amount) external;
    function leave(uint256 _shareOfFreshBeets) external;


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Router02 {
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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./StrategyBeetsBase.sol";
import "../SpiritBoostedFarms/interfaces/IMasterChef.sol";
import "../SpiritBoostedFarms/interfaces/IBar.sol";
import "../SpiritBoostedFarms/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IBeetsMasterChef.sol";
import "./interfaces/IBalancer.sol";


contract StrategyFreshBeets is StrategyBeetsBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;
    using AddressUpgradeable for address;

    // Token addresses
    address public masterChef;
    uint256 public pid;

    // token addresses for beets
    address public beets;
    address public fBeets;
    address public lpFBeets;
    bytes32 public lpFBeetsPid;
    uint256 public fBeetsPid;
    address public wFtm;
    address public beetsVault;

    address public secondReward;
    uint256 public secondRewardSellLimit;
    bytes32 public secondRewardPathPid;

    constructor() public {}

    function initialize(
        address _lp,
        uint256 _pid,
        address _depositor,
        address _feeHandler,
        uint256 _feePerformance,
        uint256 _feeHarvest,
        uint256 _feeMax
    ) public initializer {
        initializeStrategyBase(_lp, _depositor, _feeHandler, _feePerformance, _feeHarvest, _feeMax);
        masterChef = address(0x8166994d9ebBe5829EC86Bd81258149B87faCfd3);
        pid = _pid;
        beets = address(0xF24Bcf4d1e507740041C9cFd2DddB29585aDCe1e);
        fBeets = address(0xfcef8a994209d6916EB2C86cDD2AFD60Aa6F54b1);
        lpFBeetsPid = bytes32(0xcde5a11a4acb4ee4c805352cec57e236bdbc3837000200000000000000000019);
        fBeetsPid = 22;
        wFtm = address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
        beetsVault = address(0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce);
        lpFBeets = address(0xcdE5a11a4ACB4eE4c805352Cec57E236bdBC3837);
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMasterChef(masterChef).userInfo(pid, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        uint256 _pendingReward = IMasterChef(masterChef).pendingReward(pid, address(this));
        return _pendingReward;
    }

    // **** Setters ****

    function setSecondReward(
        address _secondReward,
        uint256 _secondRewardSellLimit,
        bytes32 _secondRewardPathPid
    ) external onlyOwner {
        secondReward = _secondReward;
        secondRewardSellLimit = _secondRewardSellLimit;
        secondRewardPathPid = _secondRewardPathPid;
    }

    function deposit() public override onlyBenevolent {
        uint256 _want = IERC20Upgradeable(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20Upgradeable(want).safeApprove(masterChef, 0);
            IERC20Upgradeable(want).safeApprove(masterChef, _want);
            IMasterChef(masterChef).deposit(pid, _want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        IMasterChef(masterChef).withdraw(pid, _amount);
        return _amount;
    }

    // **** State Mutations ****

    function harvest(address _harvester) public onlyBenevolent returns (uint256) {
        // harvest from Beets MasterChef
        IBeetsMasterChef(masterChef).harvest(pid, address(this));

        uint256 fBeetsAmount = getBalance();
        if (fBeetsAmount > 0) {
            IBeetsMasterChef(masterChef).harvest(fBeetsPid, address(this));
        }

        // join BPT fBeets pool
        uint256 _beetsBalance = IERC20Upgradeable(beets).balanceOf(address(this));

        // if (secondReward != address(0)) {
        //     uint256 secondRewardAmount = IERC20Upgradeable(secondReward).balanceOf(address(this));
        //     if (secondRewardAmount > secondRewardSellLimit) {
        //         _swapWithPath(secondRewardPath, secondRewardAmount);
        //     }
        // }

        uint256 _feePerformance = _beetsBalance.mul(feePerformance).div(feeMax);
        uint256 _feeHarvest = _beetsBalance.mul(feeHarvest).div(feeMax);
        _beetsBalance = _beetsBalance.sub(_feePerformance).sub(_feeHarvest);

        IERC20Upgradeable(beets).safeTransfer(feeHandler, _feePerformance);
        IERC20Upgradeable(beets).safeTransfer(_harvester, _feeHarvest);

        // stake in aceLab
        uint256 stakedAmount = 0;
        if (_beetsBalance > 0) {
            joinPool(_beetsBalance); //enter single token, let balancer swaps

            // enter bar and stake in masterChef
            uint256 _lpAmount = IERC20Upgradeable(lpFBeets).balanceOf(address(this));
            stakedAmount = stakeFBeets(_lpAmount);
        }

        return stakedAmount;
    }

    function claim(uint256 pendingFBeets) external onlyBenevolent {
        IBeetsMasterChef(masterChef).withdrawAndHarvest(fBeetsPid, pendingFBeets, address(this));

        IERC20Upgradeable(fBeets).safeTransfer(msg.sender, pendingFBeets);
    }

    function _approveToken(
        address _spender,
        address _token,
        uint256 _amount
    ) internal {
        require(_token != address(0) && _spender != address(0), "_approveToken address(0)");
        uint256 allowances = IERC20Upgradeable(_token).allowance(address(this), _spender);
        // if allowances are too low and we have _amount then increase, if _amount is zero then no need on this tx
        if (allowances < _amount && _amount > 0) {
            IERC20Upgradeable(_token).safeApprove(_spender, 0);
            IERC20Upgradeable(_token).safeApprove(_spender, uint256(-1));
        }
    }

    function joinPool(uint256 _amount) private {
        // join beethovenx BTP FBeets pool (wftm-beet)

        // prepare request
        address[] memory assets = new address[](2);
        assets[0] = wFtm;
        assets[1] = beets;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 0;
        amounts[1] = _amount;

        IBalancer.JoinPoolRequest memory request;
        request.assets = assets;
        request.maxAmountsIn = amounts;
        request.userData = abi.encode(1, amounts, 1); //https://dev.balancer.fi/resources/joins-and-exits/pool-joins
        request.fromInternalBalance = false;

        // Join
        IERC20Upgradeable(beets).safeApprove(beetsVault, 0);
        IERC20Upgradeable(beets).safeApprove(beetsVault, _amount);
        IERC20Upgradeable(wFtm).safeApprove(beetsVault, 0);
        IERC20Upgradeable(wFtm).safeApprove(beetsVault, _amount);

        IBalancer(beetsVault).joinPool(lpFBeetsPid, address(this), address(this), request);
    }

    function stakeFBeets(uint256 _lpAmount) private returns (uint256 _want) {
        // stake wftm-beets bpt

        // get fbeets
        IERC20Upgradeable(lpFBeets).safeApprove(fBeets, 0);
        IERC20Upgradeable(lpFBeets).safeApprove(fBeets, _lpAmount);
        IBar(fBeets).enter(_lpAmount);

        // read balance and deposit in the masterChef pool
        _want = IERC20Upgradeable(fBeets).balanceOf(address(this));
        if (_want > 0) {
            IERC20Upgradeable(fBeets).safeApprove(masterChef, 0);
            IERC20Upgradeable(fBeets).safeApprove(masterChef, _want);
            IBeetsMasterChef(masterChef).deposit(fBeetsPid, _want, address(this));
        }
    }

    function getBalance() public view returns (uint256) {
        // retrieve the balance of FBEETS
        (uint256 amount, ) = IMasterChef(masterChef).userInfo(fBeetsPid, address(this));
        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract StrategyBeetsBase is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;
    using AddressUpgradeable for address;

    // Tokens
    address public want;

    // User accounts
    address public depositor;

    address public feeHandler;
    uint256 public feePerformance;
    uint256 public feeHarvest;
    uint256 public feeMax;

    mapping(address => bool) public harvesters;

    constructor() public {}

    function initializeStrategyBase(
        address _want,
        address _depositor,
        address _feeHandler,
        uint256 _feePerformance,
        uint256 _feeHarvest,
        uint256 _feeMax
    ) public initializer {
        __Ownable_init();
        require(_want != address(0), "!zero address");
        require(_depositor != address(0), "!zero address");
        require(_feeMax != 0, "!feeMax");

        want = _want;
        depositor = _depositor;
        feeHandler = _feeHandler;
        feePerformance = _feePerformance;
        feeHarvest = _feeHarvest;
        feeMax = _feeMax;
    }

    // **** Modifiers **** //

    modifier onlyBenevolent() {
        require(harvesters[msg.sender] || msg.sender == owner() || msg.sender == depositor);
        _;
    }

    // **** Views **** //

    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    function balanceOfPool() public view virtual returns (uint256);

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function setFees(
        uint256 _feePerformance,
        uint256 _feeHarvest,
        uint256 _feeMax
    ) external onlyOwner {
        require(_feePerformance + _feeHarvest < _feeMax, "!fee values");
        feePerformance = _feePerformance;
        feeHarvest = _feeHarvest;
        feeMax = _feeMax;
    }

    function setFeeHandler(address _feeHandler) external onlyOwner {
        require(_feeHandler != address(0), "!Null Address");
        feeHandler = _feeHandler;
    }

    // **** Setters **** //

    function whitelistHarvesters(address[] calldata _harvesters) external {
        require(msg.sender == owner() || harvesters[msg.sender], "not authorized");

        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = true;
        }
    }

    function revokeHarvesters(address[] calldata _harvesters) external onlyOwner {
        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = false;
        }
    }

    function setDepositor(address _depositor) external onlyOwner {
        depositor = _depositor;
    }

    // **** State mutations **** //
    function deposit() public virtual;

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20Upgradeable _asset) external onlyOwner returns (uint256 balance) {
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(depositor, balance);
    }

    // Withdraw partial funds
    function withdraw(uint256 _amount) external returns (uint256) {
        require(msg.sender == depositor, "!depositor");
        uint256 _balance = IERC20Upgradeable(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20Upgradeable(want).safeTransfer(depositor, _amount);
        return _amount;
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == owner() || msg.sender == depositor, "!owner");
        _withdrawAll();

        balance = IERC20Upgradeable(want).balanceOf(address(this));

        IERC20Upgradeable(want).safeTransfer(depositor, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// it calls Ice but it farms Spell
interface IBeetsMasterChef {
    function pendingBeets(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 _pid,uint256 _amount,address _to) external;

    function harvest(uint256 _pid, address _to) external;

    function withdrawAndHarvest(uint256 _pid, uint256 _amount, address _to) external;


}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interface to beeth vault
interface IBalancer {
    // struct to interact with beeth pools
    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }
    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address recipient;
        bool toInternalBalance;
    }

    struct SwapRequest {
        SwapKind kind;
        address tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }

    // enum to interact with beeth structs
    enum SwapKind { GIVEN_IN, GIVEN_OUT }
    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT, MANAGEMENT_FEE_TOKENS_OUT }

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external;
    function exitPool(bytes32 poolId, address sender, address recipient, ExitPoolRequest memory request) external;
    function getPoolTokens(bytes32 poolId) external view returns(IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./StrategyBase.sol";
import "./interfaces/IMasterChef.sol";
import "./IBeetsMasterChef.sol";
import "./interfaces/ILiquidDepositor.sol";
import "./interfaces/IBalancer.sol";
import "./interfaces/IBar.sol";
import "./interfaces/IVault.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract StrategyGeneralMasterChefBase is StrategyBase {
    // Token addresses
    address public masterchef;
    address public rewardToken;

    address public wFtm;
    address public beetsVault;
    address public freshBeets;
    address public lpFreshBeets;
    bytes32 public poolIdFreshBeets; //  poolID to join lpFBeets Pool
    uint256 public pidFreshBeets; //  pid lpFBeets masterchef
    uint256 public poolId; //  pid _lp masterchef

    using SafeERC20 for IERC20;

    constructor() public {}

    function initializeStrategyGeneralMasterChefBase(
        address _rewardToken,
        address _masterchef,
        uint256 _poolId,
        address _lp,
        address _depositor,
        address _lpFreshBeets,
        bytes32 _poolIdFreshBeets,
        uint256 _pidFreshBeets,
        address _WFTM,
        address _freshBeets,
        address _beetsVault
    ) public initializer {
        initializeStrategyBase(_lp, _depositor);
        poolId = _poolId;
        rewardToken = _rewardToken;
        masterchef = _masterchef;
        lpFreshBeets = _lpFreshBeets;
        poolIdFreshBeets = _poolIdFreshBeets;
        pidFreshBeets = _pidFreshBeets;
        wFtm = _WFTM;
        freshBeets = _freshBeets;
        beetsVault = _beetsVault;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMasterChef(masterchef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view virtual returns (uint256) {
        uint256 _pendingReward = IMasterChef(masterchef).pendingReward(poolId, address(this));
        return _pendingReward;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterchef, 0);
            IERC20(want).safeApprove(masterchef, _want);

            //IMasterChef(masterchef).deposit(poolId, _want);
            IBeetsMasterChef(masterchef).deposit(poolId, _want, address(this));
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        //IMasterChef(masterchef).withdraw(poolId, _amount);
        IBeetsMasterChef(masterchef).withdrawAndHarvest(poolId, _amount, address(this));
        return _amount;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // called by onlyBenevolent to compound lp+stake rewards

        //harvest from lp pool
        IBeetsMasterChef(masterchef).harvest(poolId, address(this));

        // harvest from fbeets pool
        uint256 fBeetsAmount = getBalance();
        if (fBeetsAmount > 0) {
            IBeetsMasterChef(masterchef).harvest(pidFreshBeets, address(this));
        }

        // join BPT fBeets pool
        uint256 _beetsBalance = IERC20(rewardToken).balanceOf(address(this));
        uint256 stakedAmount = 0;
        if (_beetsBalance > 0) {
            joinPool(_beetsBalance); //enter single token, let balancer swaps

            // enter bar and stake in masterchef
            uint256 _lpAmount = IERC20(lpFreshBeets).balanceOf(address(this));
            stakedAmount = stakeFBeets(_lpAmount);
        }

        // once staked update epoch of depositor (vault) with the staked amount in the current epoch
        IVault(depositor).updateEpoch(stakedAmount, strategyVaultPid);
    }

    function claim(uint256 amount) public override onlyBenevolent {
        //called by user to get his rewards

        // -- withdraw fBEETS and send to user
        IBeetsMasterChef(masterchef).withdrawAndHarvest(pidFreshBeets, amount, address(this));

        IERC20(freshBeets).safeTransfer(msg.sender, amount);
    }

    // **** PRIVATE ****
    function joinPool(uint256 _amount) private {
        // join beethovenx BTP FBeets pool (wftm-beet)

        // prepare request
        address[] memory assets = new address[](2);
        assets[0] = wFtm;
        assets[1] = rewardToken;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 0;
        amounts[1] = _amount;

        IBalancer.JoinPoolRequest memory request;
        request.assets = assets;
        request.maxAmountsIn = amounts;
        request.userData = abi.encode(1, amounts, 1); //https://dev.balancer.fi/resources/joins-and-exits/pool-joins
        request.fromInternalBalance = false;

        // Join
        IERC20(rewardToken).safeApprove(beetsVault, 0);
        IERC20(rewardToken).safeApprove(beetsVault, _amount);
        IERC20(wFtm).safeApprove(beetsVault, 0);
        IERC20(wFtm).safeApprove(beetsVault, _amount);

        IBalancer(beetsVault).joinPool(poolIdFreshBeets, address(this), address(this), request);
    }

    function stakeFBeets(uint256 _lpAmount) private returns (uint256 _want) {
        // stake wftm-beets bpt

        // get fbeets
        IERC20(lpFreshBeets).safeApprove(freshBeets, 0);
        IERC20(lpFreshBeets).safeApprove(freshBeets, _lpAmount);
        IBar(freshBeets).enter(_lpAmount);

        // read balance and deposit in the masterchef pool
        _want = IERC20(freshBeets).balanceOf(address(this));
        if (_want > 0) {
            IERC20(freshBeets).safeApprove(masterchef, 0);
            IERC20(freshBeets).safeApprove(masterchef, _want);
            IBeetsMasterChef(masterchef).deposit(pidFreshBeets, _want, address(this));
        }
    }

    function getBalance() public view returns (uint256) {
        // retrieve the balance of FBEETS
        (uint256 amount, ) = IMasterChef(masterchef).userInfo(pidFreshBeets, address(this));
        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Strategy Contract Basics

abstract contract StrategyBase is OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Tokens
    address public want;

    // User accounts
    address public governance;
    address public depositor;

    // strategy vault pid
    uint256 strategyVaultPid;

    mapping(address => bool) public harvesters;

    constructor() public {}

    function initializeStrategyBase(address _want, address _depositor) public initializer {
        __Ownable_init();
        require(_want != address(0), "!zero address");
        require(_depositor != address(0), "!zero address");

        want = _want;
        depositor = _depositor;
        governance = msg.sender;
    }

    // **** Modifiers **** //

    modifier onlyBenevolent() {
        require(harvesters[msg.sender] || msg.sender == governance || msg.sender == depositor);
        _;
    }

    // **** Views **** //

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view virtual returns (uint256);

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // **** Setters **** //

    function whitelistHarvesters(address[] calldata _harvesters) external {
        require(msg.sender == governance || harvesters[msg.sender], "not authorized");

        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = true;
        }
    }

    function revokeHarvesters(address[] calldata _harvesters) external {
        require(msg.sender == governance, "not authorized");

        for (uint256 i = 0; i < _harvesters.length; i++) {
            harvesters[_harvesters[i]] = false;
        }
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setDepositor(address _depositor) external {
        require(msg.sender == governance, "!governance");
        depositor = _depositor;
    }

    function setStrategyVaultPid(uint256 _strategyVaultPid) external onlyBenevolent {
        strategyVaultPid = _strategyVaultPid;
    }

    // **** State mutations **** //
    function deposit() public virtual;

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == governance, "!governance");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(depositor, balance);
    }

    // Withdraw partial funds
    function withdraw(uint256 _amount) external returns (uint256) {
        require(msg.sender == depositor, "!depositor");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20(want).safeTransfer(depositor, _amount);

        return _amount;
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == governance, "!governance");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        IERC20(want).safeTransfer(depositor, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    // called to compound lp+stake rewards
    function harvest() public virtual;

    // called from users to harvest their rewards
    function claim(uint256 amount) public virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMasterChef {
    function BONUS_MULTIPLIER() external view returns (uint256);

    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate
    ) external;

    function bonusEndBlock() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function dev(address _devaddr) external;

    function devFundDivRate() external view returns (uint256);

    function devaddr() external view returns (address);

    function emergencyWithdraw(uint256 _pid) external;

    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    function massUpdatePools() external;

    function owner() external view returns (address);

    function pendingPickle(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function pending(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function pickle() external view returns (address);

    function picklePerBlock() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accPicklePerShare
        );

    function poolLength() external view returns (uint256);

    function renounceOwnership() external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setBonusEndBlock(uint256 _bonusEndBlock) external;

    function setDevFundDivRate(uint256 _devFundDivRate) external;

    function setPicklePerBlock(uint256 _picklePerBlock) external;

    function startBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// it calls Ice but it farms Spell
interface IBeetsMasterChef {
    function pendingBeets(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 _pid,uint256 _amount,address _to) external;

    function harvest(uint256 _pid, address _to) external;

    function withdrawAndHarvest(uint256 _pid, uint256 _amount, address _to) external;


}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;



interface ILiquidDepositor {
  function treasury() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;



interface IBar{

    function enter(uint256 _amount) external;
    function leave(uint256 _shareOfFreshBeets) external;


}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IVault {

    function updateEpoch(uint256, uint256) external;

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

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./libraries/SignedSafeMath.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IShadowStrategy.sol";
import "./interfaces/ISmartWalletWhitelist.sol";
import "./interfaces/ISecondRewarder.sol";


contract ShadowChef is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;
    using SignedSafeMath for int256;

    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    uint256 public accRewardPerShare;
    uint256 public lastRewardTime;

    /// @notice Address of rewardToken contract.
    IERC20 public rewardToken;

    /// @notice Address of the LP token for each MCV2 pool.
    IERC20 public lpToken;

    /// @notice Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    uint256 public rewardPerSecond;
    uint256 private ACC_REWARD_PRECISION;

    address public strategy;

    uint256 public distributionPeriod;
    uint256 public lastDistributedTime;

    uint256 public overDistributed;

    address public smartWalletChecker;

    ISecondRewarder public rewarder;
    uint256 public rewarderPid;

    event Deposit(address indexed user, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 amount);
    event LogUpdatePool(uint256 lastRewardTime, uint256 lpSupply, uint256 accRewardPerShare);
    event LogRewardPerSecond(uint256 rewardPerSecond);

    constructor() public {}

    function initialize(
        IERC20 _rewardToken,
        IERC20 _lpToken,
        address _strategy,
        uint256 _distributionPeriod,
        address _smartWalletChecker
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        rewardToken = _rewardToken;
        distributionPeriod = _distributionPeriod;
        ACC_REWARD_PRECISION = 1e12;
        lpToken = _lpToken;
        lastRewardTime = block.timestamp;
        strategy = _strategy;
        smartWalletChecker = _smartWalletChecker;
    }

    modifier onlyWhitelisted() {
        if (tx.origin != msg.sender) {
            require(address(smartWalletChecker) != address(0), "Not whitelisted");
            require(ISmartWalletWhitelist(smartWalletChecker).check(msg.sender), "Not whitelisted");
        }
        _;
    }

    function setDistributionPeriod(uint256 _distributionPeriod) public onlyOwner {
        distributionPeriod = _distributionPeriod;
    }

    function setSmartWalletChecker(address _checker) public onlyOwner {
        smartWalletChecker = _checker;
    }

    function setStrategy(address _strategy) public onlyOwner {
        if (strategy != address(0)) {
            IShadowStrategy(strategy).withdrawAll();
        }

        if (_strategy != address(0)) {
            uint256 _lpBalance = lpToken.balanceOf(address(this));
            lpToken.safeTransfer(_strategy, _lpBalance);
            IShadowStrategy(_strategy).deposit();
            strategy = _strategy;
        }
    }

    function setSecondRewarder(ISecondRewarder _rewarder, uint256 _pid) public onlyOwner {
        rewarder = _rewarder;
        rewarderPid = _pid;
    }

    /// @notice Sets the reward per second to be distributed. Can only be called by the owner.
    /// @param _rewardPerSecond The amount of Reward to be distributed per second.
    function setRewardPerSecond(uint256 _rewardPerSecond) public onlyOwner {
        rewardPerSecond = _rewardPerSecond;
        emit LogRewardPerSecond(_rewardPerSecond);
    }

    function _setDistributionRate(uint256 amount) internal {
        updatePool();
        uint256 _notDistributed;
        if (lastDistributedTime > 0 && block.timestamp < lastDistributedTime) {
            uint256 timeLeft = lastDistributedTime.sub(block.timestamp);
            _notDistributed = rewardPerSecond.mul(timeLeft);
        }

        amount = amount.add(_notDistributed);

        uint256 _moreDistributed = overDistributed;
        overDistributed = 0;

        if (lastDistributedTime > 0 && block.timestamp > lastDistributedTime) {
            uint256 timeOver = block.timestamp.sub(lastDistributedTime);
            _moreDistributed = _moreDistributed.add(rewardPerSecond.mul(timeOver));
        }

        if (amount < _moreDistributed) {
            overDistributed = _moreDistributed.sub(amount);
            rewardPerSecond = 0;
            lastDistributedTime = block.timestamp.add(distributionPeriod);
            updatePool();
            emit LogRewardPerSecond(rewardPerSecond);
        } else {
            amount = amount.sub(_moreDistributed);
            rewardPerSecond = amount.div(distributionPeriod);
            lastDistributedTime = block.timestamp.add(distributionPeriod);
            updatePool();
            emit LogRewardPerSecond(rewardPerSecond);
        }
    }

    function setOverDistributed(uint256 _overDistributed) public onlyOwner {
        overDistributed = _overDistributed;
    }

    function harvestRewardsFromStrategy() public {
        uint256 _rewardAmount = IShadowStrategy(strategy).harvest(msg.sender);
        _setDistributionRate(_rewardAmount);
    }

    function pendingReward(address _user) external view returns (uint256 pending) {
        UserInfo storage user = userInfo[_user];
        uint256 lpSupply = lpToken.balanceOf(address(this));
        lpSupply = lpSupply.add(IShadowStrategy(strategy).balanceOf());
        uint256 _accRewardPerShare = accRewardPerShare;
        if (block.timestamp > lastRewardTime && lpSupply != 0) {
            uint256 time = block.timestamp.sub(lastRewardTime);
            uint256 rewardAmount = time.mul(rewardPerSecond);
            _accRewardPerShare = _accRewardPerShare.add(rewardAmount.mul(ACC_REWARD_PRECISION) / lpSupply);
        }
        pending = int256(user.amount.mul(_accRewardPerShare) / ACC_REWARD_PRECISION).sub(user.rewardDebt).toUInt256();
    }

    function updatePool() public returns (uint256) {
        if (block.timestamp > lastRewardTime) {
            uint256 lpSupply = lpToken.balanceOf(address(this));
            lpSupply = lpSupply.add(IShadowStrategy(strategy).balanceOf());
            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(lastRewardTime);
                uint256 rewardAmount = time.mul(rewardPerSecond);
                accRewardPerShare = accRewardPerShare.add(rewardAmount.mul(ACC_REWARD_PRECISION).div(lpSupply));
            }
            lastRewardTime = block.timestamp;
            emit LogUpdatePool(lastRewardTime, lpSupply, accRewardPerShare);
            return accRewardPerShare;
        }
    }

    function deposit(uint256 amount, address to) public onlyWhitelisted nonReentrant {
        updatePool();
        UserInfo storage user = userInfo[to];

        // Effects
        user.amount = user.amount.add(amount);
        user.rewardDebt = user.rewardDebt.add(int256(amount.mul(accRewardPerShare) / ACC_REWARD_PRECISION));

        if (address(rewarder) != address(0)) {
            rewarder.onReward(rewarderPid, to, to, 0, user.amount);
        }

        lpToken.safeTransferFrom(msg.sender, address(this), amount);

        if (strategy != address(0)) {
            uint256 _lpBalance = lpToken.balanceOf(address(this));
            lpToken.safeTransfer(strategy, _lpBalance);
            IShadowStrategy(strategy).deposit();
        }

        emit Deposit(msg.sender, amount, to);
    }

    function withdraw(uint256 amount, address to) public onlyWhitelisted nonReentrant {
        updatePool();
        UserInfo storage user = userInfo[msg.sender];

        // Effects
        user.rewardDebt = user.rewardDebt.sub(int256(amount.mul(accRewardPerShare) / ACC_REWARD_PRECISION));
        user.amount = user.amount.sub(amount);

        if (address(rewarder) != address(0)) {
            rewarder.onReward(rewarderPid, to, to, 0, user.amount);
        }

        uint256 _lpBalance = lpToken.balanceOf(address(this));
        if (_lpBalance < amount) {
            uint256 _missing = amount.sub(_lpBalance);
            IShadowStrategy(strategy).withdraw(_missing);
        }

        lpToken.safeTransfer(to, amount);

        emit Withdraw(msg.sender, amount, to);
    }

    function harvest(address to) public {
        updatePool();
        UserInfo storage user = userInfo[msg.sender];
        int256 accumulatedReward = int256(user.amount.mul(accRewardPerShare) / ACC_REWARD_PRECISION);
        uint256 _pendingReward = accumulatedReward.sub(user.rewardDebt).toUInt256();

        // Effects
        user.rewardDebt = accumulatedReward;

        // Interactions
        if (_pendingReward != 0) {
            IShadowStrategy(strategy).claim(_pendingReward);
            rewardToken.safeTransfer(to, _pendingReward);
        }

        if (address(rewarder) != address(0)) {
            rewarder.onReward(rewarderPid, msg.sender, to, _pendingReward, user.amount);
        }

        emit Harvest(msg.sender, _pendingReward);
    }

    function withdrawAndHarvest(uint256 amount, address to) public onlyWhitelisted nonReentrant {
        updatePool();
        UserInfo storage user = userInfo[msg.sender];
        require(amount <= user.amount, "Withdraw amount exceeds the deposited amount.");
        int256 accumulatedReward = int256(user.amount.mul(accRewardPerShare) / ACC_REWARD_PRECISION);
        uint256 _pendingReward = accumulatedReward.sub(user.rewardDebt).toUInt256();

        // Effects
        user.rewardDebt = accumulatedReward.sub(int256(amount.mul(accRewardPerShare) / ACC_REWARD_PRECISION));
        user.amount = user.amount.sub(amount);

        // Interactions
        IShadowStrategy(strategy).claim(_pendingReward);
        rewardToken.safeTransfer(to, _pendingReward);

        uint256 _lpBalance = lpToken.balanceOf(address(this));
        if (_lpBalance < amount) {
            uint256 _missing = amount.sub(_lpBalance);
            IShadowStrategy(strategy).withdraw(_missing);
        }

        if (address(rewarder) != address(0)) {
            rewarder.onReward(rewarderPid, msg.sender, to, _pendingReward, user.amount);
        }

        lpToken.safeTransfer(to, amount);

        emit Withdraw(msg.sender, amount, to);
        emit Harvest(msg.sender, _pendingReward);
    }

    function emergencyWithdraw(address to) public onlyWhitelisted nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        uint256 _lpBalance = lpToken.balanceOf(address(this));
        if (_lpBalance < user.amount) {
            uint256 _missing = user.amount.sub(_lpBalance);
            IShadowStrategy(strategy).withdraw(_missing);
        }

        if (address(rewarder) != address(0)) {
            rewarder.onReward(rewarderPid, msg.sender, to, 0, 0);
        }

        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken.safeTransfer(to, amount);
        emit EmergencyWithdraw(msg.sender, amount, to);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }
    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }
    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

// SPDX-License-Identifier: UNLICENSED
// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
// solhint-disable avoid-low-level-calls

import "./libraries/BoringERC20.sol";

// T1 - T4: OK
contract BaseBoringBatchable {
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }    
    
    // F3 - F9: OK
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C1 - C21: OK
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns(bool[] memory successes, bytes[] memory results) {
        // Interactions
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = result;
        }
    }
}

// T1 - T4: OK
contract BoringBatchable is BaseBoringBatchable {
    // F1 - F9: OK
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    // C1 - C21: OK
    function permitToken(IERC20 token, address from, address to, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        // Interactions
        // X1 - X5
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract BoringOwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract BoringOwnable is BoringOwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;
        
        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }

    function toUInt256(int256 a) internal pure returns (uint256) {
        require(a >= 0, "Integer < 0");
        return uint256(a);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMasterChef {
    function BONUS_MULTIPLIER() external view returns (uint256);

    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate
    ) external;

    function bonusEndBlock() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function dev(address _devaddr) external;

    function devFundDivRate() external view returns (uint256);

    function devaddr() external view returns (address);

    function emergencyWithdraw(uint256 _pid) external;

    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    function massUpdatePools() external;

    function owner() external view returns (address);

    function pendingPickle(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function pending(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function pickle() external view returns (address);

    function picklePerBlock() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accPicklePerShare
        );

    function poolLength() external view returns (uint256);

    function renounceOwnership() external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setBonusEndBlock(uint256 _bonusEndBlock) external;

    function setDevFundDivRate(uint256 _devFundDivRate) external;

    function setPicklePerBlock(uint256 _picklePerBlock) external;

    function startBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface IShadowStrategy {
    function withdrawAll() external returns (uint256);

    function withdraw(uint256 _amount) external returns (uint256);

    function deposit() external;

    function harvest(address) external returns (uint256);

    function claim(uint256 pendingLinSpirit) external;

    function balanceOf() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ISmartWalletWhitelist {
    function check(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

interface ISecondRewarder {
    using BoringERC20 for IERC20;

    function onReward(
        uint256 pid,
        address user,
        address recipient,
        uint256 amount,
        uint256 newLpAmount
    ) external;

    function pendingTokens(
        uint256 pid,
        address user,
        uint256 amount
    ) external view returns (IERC20[] memory, uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "../interfaces/IERC20.sol";

library BoringERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IShadowChef.sol";
import "./interfaces/IShadowStrategy.sol";

contract SecondRewarderTime is OwnableUpgradeable {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;

    IERC20 public rewardToken;

    /// @notice Info of each MCV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of REWARD entitled to the user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 unpaidRewards;
    }

    /// @notice Info of each MCV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of REWARD to distribute per block.
    struct PoolInfo {
        uint128 accRewardPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    /// @notice Info of each pool.
    mapping(uint256 => PoolInfo) public poolInfo;

    /// @notice Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public rewardPerSecond;
    uint256 public ACC_TOKEN_PRECISION;

    address[] public shadowChefs;

    mapping(address => bool) public whitelistedSC;

    uint256 internal unlocked;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 2;
        _;
        unlocked = 1;
    }

    event LogOnReward(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardTime, uint256 lpSupply, uint256 accRewardPerShare);
    event LogRewardPerSecond(uint256 rewardPerSecond);
    event LogInit();

    constructor() public {}

    function initialize(IERC20 _rewardToken, uint256 _rewardPerSecond) public initializer {
        __Ownable_init();
        rewardToken = _rewardToken;
        rewardPerSecond = _rewardPerSecond;
        unlocked = 1;
        ACC_TOKEN_PRECISION = 1e36;
    }

    function onReward(
        uint256 pid,
        address _user,
        address to,
        uint256,
        uint256 lpToken
    ) external onlyShadowChef lock {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][_user];
        uint256 pending;
        if (user.amount > 0) {
            pending = (user.amount.mul(pool.accRewardPerShare) / ACC_TOKEN_PRECISION).sub(user.rewardDebt).add(user.unpaidRewards);
            uint256 balance = rewardToken.balanceOf(address(this));
            if (pending > balance) {
                rewardToken.safeTransfer(to, balance);
                user.unpaidRewards = pending - balance;
            } else {
                rewardToken.safeTransfer(to, pending);
                user.unpaidRewards = 0;
            }
        }
        user.amount = lpToken;
        user.rewardDebt = lpToken.mul(pool.accRewardPerShare) / ACC_TOKEN_PRECISION;
        emit LogOnReward(_user, pid, pending - user.unpaidRewards, to);
    }

    function pendingTokens(
        uint256 pid,
        address user,
        uint256
    ) external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) {
        IERC20[] memory _rewardTokens = new IERC20[](1);
        _rewardTokens[0] = (rewardToken);
        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = pendingToken(pid, user);
        return (_rewardTokens, _rewardAmounts);
    }

    /// @notice Sets the reward per second to be distributed. Can only be called by the owner.
    /// @param _rewardPerSecond The amount of Ring to be distributed per second.
    function setRewardPerSecond(uint256 _rewardPerSecond) public onlyOwner {
        rewardPerSecond = _rewardPerSecond;
        emit LogRewardPerSecond(_rewardPerSecond);
    }

    modifier onlyShadowChef() {
        require(whitelistedSC[msg.sender], "Only ShadowChef can call this function.");
        _;
    }

    /// @notice Returns the number of MCV2 pools.
    function poolLength() public view returns (uint256 pools) {
        pools = shadowChefs.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param allocPoint AP of the new pool.
    function add(address _shadowChef, uint256 allocPoint) public onlyOwner {
        require(!whitelistedSC[_shadowChef], "Pool already exists");
        uint256 lastRewardTime = block.timestamp;
        totalAllocPoint = totalAllocPoint.add(allocPoint);

        uint256 _pid = poolLength();
        shadowChefs.push(_shadowChef);

        whitelistedSC[_shadowChef] = true;

        poolInfo[_pid] = PoolInfo({allocPoint: allocPoint.to64(), lastRewardTime: lastRewardTime.to64(), accRewardPerShare: 0});
        emit LogPoolAddition(_pid, allocPoint);
    }

    /// @notice Update the given pool.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint.to64();
        emit LogSetPool(_pid, _allocPoint);
    }

    /// @notice Allows owner to reclaim/withdraw any tokens (including reward tokens) held by this contract
    /// @param token Token to reclaim, use 0x00 for Ethereum
    /// @param amount Amount of tokens to reclaim
    /// @param to Receiver of the tokens, first of his name, rightful heir to the lost tokens,
    /// reightful owner of the extra tokens, and ether, protector of mistaken transfers, mother of token reclaimers,
    /// the Khaleesi of the Great Token Sea, the Unburnt, the Breaker of blockchains.
    function reclaimTokens(
        address token,
        uint256 amount,
        address payable to
    ) public onlyOwner {
        if (token == address(0)) {
            to.transfer(amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /// @notice View function to see pending Token
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending REWARD reward for a given user.
    function pendingToken(uint256 _pid, address _user) public view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;

        address _shadowChef = shadowChefs[_pid];
        uint256 lpSupply = IShadowChef(_shadowChef).lpToken().balanceOf(_shadowChef);
        address _shadowStrategy = IShadowChef(_shadowChef).strategy();
        lpSupply = lpSupply.add(IShadowStrategy(_shadowStrategy).balanceOf());
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 time = block.timestamp.sub(pool.lastRewardTime);
            uint256 _reward = time.mul(rewardPerSecond).mul(pool.allocPoint) / totalAllocPoint;
            accRewardPerShare = accRewardPerShare.add(_reward.mul(ACC_TOKEN_PRECISION) / lpSupply);
        }
        pending = (user.amount.mul(accRewardPerShare) / ACC_TOKEN_PRECISION).sub(user.rewardDebt).add(user.unpaidRewards);
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        if (block.timestamp > pool.lastRewardTime) {
            address _shadowChef = shadowChefs[pid];
            uint256 lpSupply = IShadowChef(_shadowChef).lpToken().balanceOf(_shadowChef);
            address _shadowStrategy = IShadowChef(_shadowChef).strategy();
            lpSupply = lpSupply.add(IShadowStrategy(_shadowStrategy).balanceOf());

            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(pool.lastRewardTime);
                uint256 _reward = time.mul(rewardPerSecond).mul(pool.allocPoint) / totalAllocPoint;
                pool.accRewardPerShare = pool.accRewardPerShare.add((_reward.mul(ACC_TOKEN_PRECISION) / lpSupply).to128());
            }
            pool.lastRewardTime = block.timestamp.to64();
            poolInfo[pid] = pool;
            emit LogUpdatePool(pid, pool.lastRewardTime, lpSupply, pool.accRewardPerShare);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

interface IShadowChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint128 accLqdrPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    function lpToken() external view returns (IERC20);

    function strategy() external view returns (address);

    function poolLength() external view returns (uint256);

    function updatePool(uint256 pid) external returns (IShadowChef.PoolInfo memory);

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function harvest(uint256 pid, address to) external;

    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function emergencyWithdraw(uint256 pid, address to) external;

    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./StrategyGeneralMasterChefBase.sol";
import "./IBeetsMasterChef.sol";

contract StrategyBeetsFarm is StrategyGeneralMasterChefBase {
    // Token addresses

    constructor() public {}

    function initialize(
        address depositor,
        address lp,
        uint256 pid,
        address lpFBeets,
        bytes32 poolIdFBeets,
        uint256 pidFBeets
    ) public initializer {
        initializeStrategyGeneralMasterChefBase(
            address(0xF24Bcf4d1e507740041C9cFd2DddB29585aDCe1e), // beets token
            address(0x8166994d9ebBe5829EC86Bd81258149B87faCfd3), // beets masterChef
            pid,
            lp,
            depositor,
            lpFBeets,
            poolIdFBeets,
            pidFBeets,
            address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83), // WFTM
            address(0xfcef8a994209d6916EB2C86cDD2AFD60Aa6F54b1), // fBeets
            address(0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce) // beethovenxVault
        );
    }

    function getHarvestable() external view override returns (uint256) {
        uint256 _pendingReward = IBeetsMasterChef(masterchef).pendingBeets(poolId, address(this));
        return _pendingReward;
    }
}

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
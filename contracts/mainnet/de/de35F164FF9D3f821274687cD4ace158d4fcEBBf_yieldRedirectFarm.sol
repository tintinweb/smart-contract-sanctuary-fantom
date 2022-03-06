/**
 *Submitted for verification at FtmScan.com on 2022-03-06
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Global Enums and Structs



struct UserInfo {
    uint256 amount;     // How many tokens the user has provided.
    uint256 epochStart; // at what Epoch will rewards start 
    uint256 depositTime; // when did the user deposit 
}

// Part: IFarm

interface IFarm {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address user)
        external
        view
        returns (uint256);

}

// Part: IFarmPain

interface IFarmPain {
    function deposit(uint256 _pid, uint256 _amount, address _to) external;
    function withdraw(uint256 _pid, uint256 _amount, address _to) external;
    function userInfo(uint256 _pid, address user)
        external
        view
        returns (uint256);  
    function withdrawAndHarvest(uint256 _pid, uint256 _amount, address _to) external;
    function harvest(uint256 _pid, address _to) external;

}

// Part: IGauge

interface IGauge {
    function deposit(uint256 _amount) external;
    function depositAll() external;
    function getReward() external;
    function withdraw(uint256 _amount) external;
    function withdrawAll() external;

}

// Part: IUniswapV2Router01

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

// Part: Ivault

interface Ivault {
    function deposit(uint256 amount) external;
    //function withdraw() external; 
    function withdraw(uint256 maxShares) external;
    function withdrawAll() external; 
    function pricePerShare() external view returns (uint256);  
    function balanceOf(address _address) external view returns (uint256);
    function want() external view returns(address);
    function decimals() external view returns (uint256);  
}

// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/Math

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

// Part: OpenZeppelin/[email protected]/ReentrancyGuard

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
contract ReentrancyGuard {
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

// Part: OpenZeppelin/[email protected]/SafeMath

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

// Part: OpenZeppelin/[email protected]/Ownable

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

// Part: OpenZeppelin/[email protected]/SafeERC20

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

// Part: helpers

abstract contract helpers is Ownable {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    bool public isActive;
    uint256 public tvlLimit = uint(-1);

    address public keeper;
    address public strategist; 
    uint256 constant BPS_adj = 10000;

    // have stripped out basic ERC20 functionality for tracking balances upon deposits 
    // have removed transfer as this will complicate tracking of rewards i.e. edge cases whne transferring to user that has just deposited 

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        //emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        //emit Transfer(account, address(0), amount);

    }

    // modifiers
    modifier onlyAuthorized() {
        require(
            msg.sender == strategist || msg.sender == owner(),
            "!authorized"
        );
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == strategist, "!strategist");
        _;
    }

    modifier onlyKeepers() {
        require(
            msg.sender == keeper ||
                msg.sender == strategist ||
                msg.sender == owner(),
            "!authorized"
        );
        _;
    }

    function setStrategist(address _strategist) external onlyAuthorized {
        require(_strategist != address(0));
        strategist = _strategist;
    }

    function setKeeper(address _keeper) external onlyAuthorized {
        require(_keeper != address(0));
        keeper = _keeper;
    }

    // this is used when completing the swap redirecting yield from base asset or farming reward to target asset 

    function _getTokenOutPath(address _token_in, address _token_out, address _weth)
        internal
        view
        returns (address[] memory _path)
    {
        bool is_weth =
            _token_in == _weth || _token_out == _weth;
        _path = new address[](is_weth ? 2 : 3);
        _path[0] = _token_in;
        if (is_weth) {
            _path[1] = _token_out;
        } else {
            _path[1] = _weth;
            _path[2] = _token_out;
        }
    }

}

// Part: rewardDistributor

abstract contract rewardDistributor is ReentrancyGuard {
    
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    IERC20 public targetToken;
    address public router;
    address public weth; 
    
    // tracks total balance of base that is eligible for rewards in given epoch (as new deposits won't receive rewards until next epoch)
    uint256 eligibleEpochRewards;
    uint256 public epoch = 0;
    uint256 public lastEpoch;
    uint256 public timePerEpoch = 1; // 
    uint256 constant timePerEpochLimit = 259200;
    //uint256 public timePerEpoch = 86400;
    uint256 public timeForKeeperToConvert = 3600;

    
    mapping (address => UserInfo) public userInfo;
    // tracks rewards of traget token for given Epoch
    mapping (uint256 => uint256) public epochRewards; 
    /// tracks the total balance eligible for rewards for given epoch
    mapping (uint256 => uint256) public epochBalance; 
    /// tracks total tokens claimed by user 
    mapping (address => uint256) public totalClaimed;


   

    function _disburseRewards(address _user) internal {
        uint256 rewards = getUserRewards(_user);
        targetToken.transfer(_user, rewards);
        _updateAmountClaimed(_user, rewards);
    }


    function getUserRewards(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 rewardStart = user.epochStart;
        uint256 rewards = 0;
        uint256 userEpochRewards;
        if(epoch > rewardStart){
            for (uint i=rewardStart; i<epoch; i++) {
                userEpochRewards = _calcUserEpochRewards(i, user.amount);
                rewards = rewards.add(userEpochRewards);
            }
        }
        return(rewards);      
    }

    function _calcUserEpochRewards(uint256 _epoch, uint256 _amt) internal view returns(uint256) {
        uint256 rewards = epochRewards[_epoch].mul(_amt).div(epochBalance[_epoch]);
        return(rewards);
    }

    function _updateAmountClaimed(address _user, uint256 _rewardsPaid) internal {
        totalClaimed[_user] = totalClaimed[_user] + _rewardsPaid;
    }


}

// Part: farmHelpers

// Helpers for vault management 

/*
farmType
0 = standard masterchef i.e. SpookyFarm
1 = gauge i.e. Spirit Farm
2 = LQDR farm
3 = Beets farm  
*/


abstract contract farmHelpers is helpers {

    address public farmAddress;
    uint256 pid;
    uint256 farmType;

    function farmBalance() public view returns(uint256){
        return IFarm(farmAddress).userInfo(pid, address(this));
    }

    // deposits underlying asset to VAULT 
    function _depositAsset(uint256 amt) internal {
        if (farmType == 0){IFarm(farmAddress).deposit(pid, amt);}
        if (farmType == 1){IGauge(farmAddress).deposit(amt);}
        if (farmType == 2){IFarmPain(farmAddress).deposit(pid, amt, address(this));}
        if (farmType == 3){IFarmPain(farmAddress).deposit(pid, amt, address(this));}
    }

    function _withdrawAmountBase(uint256 amt) internal {
        if (farmType == 0){IFarm(farmAddress).withdraw(pid, amt);}
        if (farmType == 1){IGauge(farmAddress).withdrawAll();}
        if (farmType == 2){IFarmPain(farmAddress).withdrawAndHarvest(pid, amt, address(this));}
        if (farmType == 3){IFarmPain(farmAddress).withdrawAndHarvest(pid, amt,address(this));}   
    }

    function _harvest() internal {
        if (farmType == 0){IFarm(farmAddress).withdraw(pid, 0);}
        if (farmType == 1){IGauge(farmAddress).getReward();}
        if (farmType == 2){IFarmPain(farmAddress).harvest(pid, address(this));}
        if (farmType == 3){IFarmPain(farmAddress).withdrawAndHarvest(pid, 0,address(this));}   
    }


    function _approveNewEarner(address _underlying, address _deployAddress) internal {
        IERC20 underlying = IERC20(_underlying);
        underlying.approve(_deployAddress, uint(-1));
    }

    function _removeApprovals(address _underlying, address _deployAddress) internal {
        IERC20 underlying = IERC20(_underlying);
        underlying.approve(_deployAddress, uint(0));
    }

}

// File: yieldRedirectFarm.sol

/*
The vault container allows users to deposit funds which are then deployed to a single asset vault i.e YEARN / ROBOVAULT 
at each EPOCH any yield / profit generate from the strategy is then used to purchase the TARGET Token of the users choice 
For example this would give users the ability to deposit into a USDC vault while their USDC balance will remain the same extra USDC could be used to buy 
a target token such as OHM 
Additionally some mechanics on vesting of the target tokens are built in encouraging users to keep their assets in the vault container over a longer period
*/
    

contract yieldRedirectFarm is farmHelpers, rewardDistributor {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public base;
    IERC20[] public farmTokens;
    IERC20 public swapToken;

    uint256 public profitFee = 300; // 3% default
    uint256 constant profitFeeMax = 500; // 50%
    
    // amount of profit converted each Epoch (don't convert everything to smooth returns)
    uint256 public profitConversionPercent = 5000; // 50% default 
    uint256 public minProfitThreshold; // minimum amount of profit in order to conver to target token
    address public feeToAddress; 
    bool public useTargetVault;

    constructor(
        address _base,
        address _targetToken,
        address _swapToken,
        address _farmAddress,
        address _farmToken,
        address _router,
        address _weth,
        uint256 _pid,
        uint256 _farmType

    ) public {
        base = IERC20(_base);
        targetToken = IERC20(_targetToken);
        IERC20 farmToken = IERC20(_farmToken);
        farmToken.approve(_router, uint(-1));
        farmTokens.push(farmToken);
        swapToken = IERC20(_swapToken);
        useTargetVault = _targetToken != _swapToken;
        if (useTargetVault){
            // approve Vault 
            swapToken.approve(_targetToken, uint(-1));
        }
        farmAddress = _farmAddress;
        router = _router;
        base.approve(_farmAddress, uint(-1));
        weth = _weth;
        feeToAddress = owner();
        farmType = _farmType;

    }

    // emergency function to turn off everything i.e. withdraw everything from farm & set TVL limit to 0
    function deactivate() external onlyAuthorized {
        _withdrawAmountBase(farmBalance());
        isActive = false;
        tvlLimit = 0;
    }

    // if there are multiple reward tokens we can call this 
    function addFarmToken(address _token) external onlyAuthorized {
        IERC20 newFarmToken = IERC20(_token);
        newFarmToken.approve(router, uint(-1));
        farmTokens.push(newFarmToken);
    }

    function _findToken(address _token) internal view returns (uint256) {
        for (uint256 i = 0; i < farmTokens.length; i++){
            if (_token == address(farmTokens[i])){
                return i;
            }
        } 
        return uint256(-1);
    }


    function removeFarmToken(address _token) external onlyAuthorized {
        //require(!paused(), "PAUSED");
        uint256 tokenIndex = _findToken(_token);
        require(tokenIndex != uint256(-1), "NO SUCH TOKEN");

        uint256 i = tokenIndex;
        while(i < farmTokens.length - 1) {
            farmTokens[i] = farmTokens[i + 1];
            i++;
        }
        delete farmTokens[farmTokens.length - 1];
        farmTokens.pop();
    }


    // user deposits token to yield redirector in exchange for pool shares which can later be redeemed for assets + accumulated yield
    function deposit(uint256 _amount) public nonReentrant
    {
        require(_amount > 0, "deposit must be greater than 0");
        bool withinTvlLimit = _amount.add(estimatedTotalAssets()) <= tvlLimit;
        require(withinTvlLimit, "deposit greater than TVL Limit");
        uint256 currrentBalance = balanceOf(msg.sender);

        if (currrentBalance > 0) {
            // claims all rewards 
            _disburseRewards(msg.sender);
            // to make accounting work in tracking rewards for target asset this user isn't eligible for next epoch 
            _updateEligibleEpochRewards(currrentBalance);
        }
        base.transferFrom(msg.sender, address(this), _amount);    
        uint256 shares = _amount;
        _mint(msg.sender, shares);

        // to prevent users leaching i.e. deposit just before epoch rewards distributed user will start to be eligible for rewards following epoch
        _updateUserInfo(msg.sender, epoch + 1);
        /// we automatically deploy token to farm 
        _depositAsset(_amount);

    }

    function depositAll() public {
        uint256 balance = base.balanceOf(msg.sender); 
        deposit(balance); 
    }
    
    // for simplicity in tracking Epoch positions when withdrawing user must withdraw ALl 
    function withdraw(uint256 _amt) public nonReentrant
    {
        uint256 ibalance = balanceOf(msg.sender);
        require(ibalance >= _amt, "must have sufficient balance");
        require(_amt > 0);
        _burn(msg.sender, _amt);

        uint256 withdrawAmt = _amt;
        // check if vault is in loss i.e. due to losses within vault
        if (isVaultInLoss()){
            withdrawAmt = _amt.mul(estimatedTotalAssets()).div(totalSupply());
        }

        // Check balance
        uint256 b = base.balanceOf(address(this));
        if (b < withdrawAmt) {
            // remove required funds from underlying vault 
            uint256 vaultWithdrawAmt = withdrawAmt.sub(b);
            _withdrawAmountBase(vaultWithdrawAmt);
        }

        base.safeTransfer(msg.sender, withdrawAmt);
        _disburseRewards(msg.sender);
        _updateUserInfo(msg.sender, epoch);
        if (userInfo[msg.sender].epochStart < epoch){
            _updateEligibleEpochRewards(_amt);
        }
    }

    function harvest() public nonReentrant {
        uint256 pendingRewards = getUserRewards(msg.sender);
        require(pendingRewards > 0, "user must have balance to claim"); 
        _disburseRewards(msg.sender);
        /// updates reward information so user rewards start from current EPOCH 
        _updateUserInfo(msg.sender, epoch);
    }

    function _updateEligibleEpochRewards(uint256 amt) internal {
      eligibleEpochRewards = eligibleEpochRewards.sub(amt);

    }

    function isVaultInLoss() public view returns(bool) {
        return(estimatedTotalAssets() < totalSupply());
    }

    function setFeeToAddress(address _feeToAddress) external onlyAuthorized {
        require(_feeToAddress != address(0));
        feeToAddress = _feeToAddress;
    }

    function setParamaters(
        uint256 _profitConversionPercent,
        uint256 _profitFee,
        uint256 _minProfitThreshold
    ) external onlyAuthorized {
        require(_profitConversionPercent <= BPS_adj);
        require(_profitFee <= profitFeeMax);

        profitFee = _profitFee;
        profitConversionPercent = _profitConversionPercent;
        minProfitThreshold = _minProfitThreshold;
    }

    function setEpochDuration(uint256 _epochTime) external onlyAuthorized{
        require(_epochTime <= timePerEpochLimit);
        timePerEpoch = _epochTime;
    }

    function setTvlLimit(uint256 _tvlLimit) external onlyAuthorized {
        tvlLimit = _tvlLimit;
    }

    function _updateUserInfo(address _user, uint256 _epoch) internal {
        userInfo[_user] = UserInfo(balanceOf(_user), _epoch, block.timestamp);
    }

    function deployStrat() external onlyKeepers {
        uint256 bal = base.balanceOf(address(this));
        _deployCapital(bal.sub(bal));
    }

    function _deployCapital(uint256 _amount) internal {
        _depositAsset(_amount);
    }

    function estimatedTotalAssets() public view returns(uint256) {
        uint256 bal = base.balanceOf(address(this));
        bal = bal.add(farmBalance());
        return(bal);
    }

    function convertProfits() external onlyKeepers nonReentrant {
        require(isEpochFinished()); 
        _convertProfitsInternal();

    }

    function _convertProfitsInternal() internal {
        _harvest();

        uint256 preSwapBalance = targetToken.balanceOf(address(this));
        bool depositorsEligible = eligibleEpochRewards > 0;

        // only convert profits if there is sufficient profit & users are eligible to start receiving rewards this epoch
        if (depositorsEligible){
            _redirectProfits();
            if (useTargetVault){
                _depositSwapToTargetVault();
            }
        }
        _updateRewardData(preSwapBalance);
        _updateEpoch();
    }

    function isEpochFinished() public view returns (bool){
        return((block.timestamp >= lastEpoch.add(timePerEpoch)));
    }

    function _redirectProfits() internal {
        for (uint i=0; i<farmTokens.length; i++) {
            IERC20 farmToken = farmTokens[i];
            uint256 profitConverted = farmToken.balanceOf(address(this)).mul(profitConversionPercent).div(BPS_adj);
            uint256 swapAmt = Math.min(profitConverted, farmToken.balanceOf(address(this)));
            uint256 fee = swapAmt.mul(profitFee).div(BPS_adj);
            uint256 amountOutMin = 0;
            farmToken.transfer(feeToAddress, fee);
            address[] memory path = _getTokenOutPath(address(farmToken), address(swapToken), weth);
            if (profitConverted > 0){
                IUniswapV2Router01(router).swapExactTokensForTokens(swapAmt.sub(fee), amountOutMin, path, address(this), now);
            }
        }
    }

    function _depositSwapToTargetVault() internal {
        if (useTargetVault){
            uint256 bal = swapToken.balanceOf(address(this));
            if (bal > 0){
                Ivault(address(targetToken)).deposit(bal);
            }
        }
    }

    function _updateRewardData(uint256 _preSwapBalance) internal {
        uint256 amountOut = (targetToken.balanceOf(address(this)).sub(_preSwapBalance));
        epochRewards[epoch] = amountOut; 
        /// we use this instead of total Supply as users that just deposited in current epoch are not eligible for rewards 
        epochBalance[epoch] = eligibleEpochRewards;
        /// set to equal total Supply as all current users with deposits are eligible for next epoch rewards 
        eligibleEpochRewards = totalSupply();
    }

    function _updateEpoch() internal {
        epoch = epoch.add(1);
        lastEpoch = block.timestamp;
    }

    function _calcFee(uint256 _amount) internal view returns (uint256) {
        uint256 _fee = _amount.mul(profitFee).div(BPS_adj);
        return(_fee);
    }

    function _calcEpochProfits() public view returns(uint256) {
        uint256 profit = estimatedTotalAssets().sub(totalSupply()); 
        return(profit);
    }

}
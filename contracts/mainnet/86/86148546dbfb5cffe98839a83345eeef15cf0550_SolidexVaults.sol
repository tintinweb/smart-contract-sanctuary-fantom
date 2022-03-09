/**
 *Submitted for verification at FtmScan.com on 2022-03-09
*/

// File @openzeppelin/contracts/token/ERC20/[email protected]

// -Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]

// -Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// -Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


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


// File contracts/SolidexVaults.sol

//-Identifier: Unlicense
pragma solidity ^0.8.0;


contract SolidexVaults {
    using SafeERC20 for IERC20;
    
    address public owner;
    address public operator;
    bool public stop;
    
    mapping(address => mapping(address => uint256)) public poolShares;
    mapping(address => uint256) public poolBalances;

    mapping(address => uint256) public poolScoreStored;
    mapping(address => uint256) public poolLastUpdateTime;
    mapping(address => mapping(address => uint256)) public poolUserScoreStored;
    mapping(address => mapping(address => uint256)) public poolUserLastUpdateTime;

    mapping(address => mapping(address => uint256)) public poolEarningAmounts;

    address public constant solidexLpDepositor = 0x26E1A0d851CF28E697870e1b7F053B605C8b060F;
    address public constant solidlyRouter = 0xa38cd27185a464914D3046f0AB9d43356B34829D;

    address public constant sexToken = 0xD31Fcd1f7Ba190dBc75354046F6024A9b86014d7;
    address public constant solidToken = 0x888EF71766ca594DED1F0FA3AE64eD2941740A20;
    address public constant solidSexToken = 0x41adAc6C1Ff52C5e27568f27998d747F7b69795B;
    address public constant wftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    address public constant solidSexSolidLp = 0x62E2819Dd417F3b430B6fa5Fd34a49A377A02ac8;
    address public constant wftmSexLp = 0xFCEC86aF8774d69e2e4412B8De3f4aBf1f671ecC;

    function init() public {
        require(owner == address(0), "already init");
        owner = msg.sender;
        operator = msg.sender;

        IERC20(solidSexSolidLp).approve(solidexLpDepositor, type(uint256).max);
        IERC20(wftmSexLp).approve(solidexLpDepositor, type(uint256).max);

        IERC20(wftm).approve(solidlyRouter, type(uint256).max);
        IERC20(sexToken).approve(solidlyRouter, type(uint256).max);
        IERC20(solidToken).approve(solidlyRouter, type(uint256).max);
        IERC20(solidSexToken).approve(solidlyRouter, type(uint256).max);

    }

    modifier onlyOperator() {
        require(msg.sender == operator, "no operator");

        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "no owner");

        _;
    }

    function setOperator(address _op) public onlyOwner {
        operator = _op;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setStop(bool _set) public onlyOperator {
        stop = _set;
    }


    function reinvest(address stakeToken) public {
        address[] memory pools_ = new address[](3);
        pools_[0] = stakeToken;
        pools_[1] = solidSexSolidLp;
        pools_[2] = wftmSexLp;
        ISolidexDepositor(solidexLpDepositor).getReward(pools_);

        uint256 solidTokenAmount_ = IERC20(solidToken).balanceOf(address(this));
        uint256 sexTokenAmount_ = IERC20(sexToken).balanceOf(address(this));

        if (solidTokenAmount_ > 0) {
            route[] memory routes_ = new route[](1);
            routes_[0] = route(solidToken, solidSexToken, true);
            ISolidlyRouter(solidlyRouter).swapExactTokensForTokens(
                solidTokenAmount_ / 2, 1, routes_, address(this), block.timestamp);
            (uint256 a, uint256 b, uint256 lpAmount_) = ISolidlyRouter(solidlyRouter).addLiquidity(
                solidToken, solidSexToken, true, 
                IERC20(solidToken).balanceOf(address(this)),
                IERC20(solidSexToken).balanceOf(address(this)), 
                1, 1, address(this), block.timestamp);
            ISolidexDepositor(solidexLpDepositor).deposit(
                solidSexSolidLp, lpAmount_);
            
            poolEarningAmounts[stakeToken][solidSexSolidLp] += lpAmount_;
        }
        
        if (sexTokenAmount_ > 0) {
            route[] memory routes_ = new route[](1);
            routes_[0] = route(sexToken, wftm, false);
            ISolidlyRouter(solidlyRouter).swapExactTokensForTokens(
                sexTokenAmount_ / 2, 1, routes_, address(this), block.timestamp);
            (uint256 a, uint256 b, uint256 lpAmount_) = ISolidlyRouter(solidlyRouter).addLiquidity(
                sexToken, wftm, false, 
                IERC20(sexToken).balanceOf(address(this)),
                IERC20(wftm).balanceOf(address(this)), 
                1, 1, address(this), block.timestamp);
            ISolidexDepositor(solidexLpDepositor).deposit(
                wftmSexLp, lpAmount_);
            
            poolEarningAmounts[stakeToken][wftmSexLp] += lpAmount_;
        }
       
    }

    modifier updateScore(address pool, address user) {
        poolScoreStored[pool] = getTotalScore(pool);
        poolLastUpdateTime[pool] = block.timestamp;
        poolUserScoreStored[pool][user] = getUserScore(pool, user);
        poolUserLastUpdateTime[pool][user] = block.timestamp;
       
        _;
    }

    function getUserScore(address pool, address user) public view returns (uint256) {
        return (block.timestamp - poolUserLastUpdateTime[pool][user]) 
                * poolShares[pool][user] + poolUserScoreStored[pool][user]; 
    }

    function getTotalScore(address pool) public view returns (uint256) {
        return (block.timestamp - poolLastUpdateTime[pool])
            * poolBalances[pool] + poolScoreStored[pool];
    }

    function getEarningTokens() public pure returns(address[] memory) {
        address[] memory earnTokens = new address[](2);
        (earnTokens[0], earnTokens[1]) = (solidSexSolidLp, wftmSexLp);
        return earnTokens;
    }

    function getUserEarnings(address pool, address user) public view returns(uint256, uint256) {
        uint256 ratio = getUserScore(pool, user) * 1e18 / getTotalScore(pool);
        return (poolEarningAmounts[pool][solidSexSolidLp] * ratio / 1e18, 
            poolEarningAmounts[pool][wftmSexLp] * ratio / 1e18);
    }

    function claimEarnings(address pool) public {
        (uint256 solidLpAmount, uint256 sexLpAmount) = getUserEarnings(pool, msg.sender);
        if (solidLpAmount > 0) {
            ISolidexDepositor(solidexLpDepositor).withdraw(solidSexSolidLp, solidLpAmount);
            ISolidlyRouter(solidlyRouter).removeLiquidity(solidToken, solidSexToken, true, 
                solidLpAmount, 1, 1, msg.sender, block.timestamp);
            poolEarningAmounts[pool][solidSexSolidLp] -= solidLpAmount;
        }
        if (sexLpAmount > 0) {
            ISolidexDepositor(solidexLpDepositor).withdraw(wftmSexLp, sexLpAmount);
            ISolidlyRouter(solidlyRouter).removeLiquidity(wftm, sexToken, false, 
                sexLpAmount, 1, 1, msg.sender, block.timestamp);
            poolEarningAmounts[pool][wftmSexLp] -= sexLpAmount;
        }

        poolUserScoreStored[pool][msg.sender] = 0;
        poolUserLastUpdateTime[pool][msg.sender] = block.timestamp;
    }

    function deposit(address pool, uint256 amount) public updateScore(pool, msg.sender) {
        require(!stop, "stop");
        if (poolBalances[pool] == 0) {
            IERC20(pool).approve(solidexLpDepositor, type(uint256).max);
        }
        IERC20(pool).safeTransferFrom(msg.sender, address(this), amount);
        poolShares[pool][msg.sender] += amount;
        poolBalances[pool] += amount;
        ISolidexDepositor(solidexLpDepositor).deposit(pool, amount);
    }

    function withdraw(address pool, uint256 amount) public updateScore(pool, msg.sender) {
        require(amount <= poolShares[pool][msg.sender], "invalid");
        
        uint256 stakeTokenBalance = IERC20(pool).balanceOf(address(this));
        if (stakeTokenBalance < amount) {
            // withdraw stake token
            ISolidexDepositor(solidexLpDepositor).withdraw(pool, amount - stakeTokenBalance);
        }

        IERC20(pool).safeTransfer(msg.sender, amount);
        poolShares[pool][msg.sender] -= amount;
        poolBalances[pool] -= amount;
    }

}

interface ISolidexDepositor {
    function deposit(address pool, uint256 amount) external;
    function withdraw(address pool, uint256 amount) external;
    function getReward(address[] calldata pools) external;
}

struct route {
    address from;
    address to;
    bool stable;
}

interface ISolidlyPair {
    function token0() external returns(address);
    function token1() external returns(address);
    function stable() external returns(bool);
}

interface ISolidlyRouter {

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactFTMForTokens(
        uint amountOutMin, 
        route[] calldata routes, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);


}
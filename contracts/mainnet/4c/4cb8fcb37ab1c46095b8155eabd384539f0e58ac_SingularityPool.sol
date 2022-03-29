/**
 *Submitted for verification at FtmScan.com on 2022-03-29
*/

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
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

pragma solidity ^0.8.13;
/**
 * @title Singularity Pool Token
 * @author Revenant Labs
 * @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
 */
abstract contract SingularityPoolToken is ISingularityPoolToken {
    string public override name;
    string public override symbol;
    uint8 public override decimals;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 internal INITIAL_CHAIN_ID;
    bytes32 internal INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public override nonces;

    function _initialize() internal {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        balanceOf[msg.sender] -= value;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - value;

        balanceOf[from] -= value;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);

        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public override {
        require(deadline >= block.timestamp, "SingularityPoolToken: EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0) && recoveredAddress == owner, "SingularityPoolToken: INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply += value;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= value;
        }

        emit Transfer(from, address(0), value);
    }
}

pragma solidity ^0.8.13;
interface ISingularityPool is ISingularityPoolToken {
    event Deposit(address indexed sender, uint256 indexed amountDeposited, uint256 mintAmount, address indexed to);
    event Withdraw(address indexed sender, uint256 indexed amountBurned, uint256 withdrawAmount, address indexed to);
    event SwapIn(
        address indexed sender,
        uint256 indexed amountIn,
        uint256 amountOut
    );
    event SwapOut(
        address indexed sender,
        uint256 indexed amountIn,
        uint256 amountOut,
        address indexed to
    );

    function paused() external view returns (bool);
    function isStablecoin() external view returns (bool);

    function factory() external view returns (address);
    function token() external view returns (address);

    function depositCap() external view returns (uint256);
    function assets() external view returns (uint256);
    function liabilities() external view returns (uint256);
    function adminFees() external view returns (uint256);
    function lockedFees() external view returns (uint256);
    function baseFee() external view returns (uint256);

    function getCollateralizationRatio() external view returns (uint256);
    function getPricePerShare() external view returns (uint256);
    function getOracleData() external view returns (uint256, uint256);
    function getAmountToUSD(uint256 amount) external view returns (uint256);
    function getUSDToAmount(uint256 value) external view returns (uint256);
    
    function getLpFeeRate(uint256 collateralizationRatio) external pure returns (uint256);
    function getDepositFee(uint256 amount) external view returns (uint256);
    function getWithdrawFee(uint256 amount) external view returns (uint256);
    function getSlippageIn(uint256 amount) external view returns (uint256);
    function getSlippageOut(uint256 amount) external view returns (uint256);
    function getG(uint256 collateralizationRatio) external pure returns (uint256);
    function getTradingFeeRate() external view returns (uint256 tradingFeeRate);
    function getTradingFees(uint256 amount) external view returns (uint256, uint256, uint256, uint256);

    function deposit(uint256 amount, address to) external returns (uint256);
    function withdraw(uint256 amount, address to) external returns (uint256);
    function swapIn(uint256 amountIn) external returns (uint256);
    function swapOut(uint256 amountIn, address to) external returns (uint256);

    function collectFees() external;
    function setDepositCap(uint256 newDepositCap) external;
    function setBaseFee(uint256 newBaseFee) external;
    function setPaused(bool state) external;
}

pragma solidity ^0.8.13;

interface ISingularityFactory {
    function tranche() external view returns (string memory);
    function admin() external view returns (address);
    function oracle() external view returns (address);
    function feeTo() external view returns (address);
    function router() external view returns (address);

    function poolParams() external view returns(address token, bool isStablecoin, uint256 baseFee);
    
    function getPool(address token) external view returns (address pool);
    function allPools(uint256) external view returns (address pool);
    function allPoolsLength() external view returns (uint256);
    function poolCodeHash() external pure returns (bytes32);

    function createPool(address token, bool isStablecoin, uint256 baseFee) external returns (address pool);

    function setAdmin(address _admin) external;
    function setOracle(address _oracle) external;
    function setFeeTo(address _feeTo) external;
    function setRouter(address _router) external;
    
    function collectFees() external;
    function setDepositCaps(address[] calldata tokens, uint256[] calldata caps) external;
    function setBaseFees(address[] calldata tokens, uint256[] calldata baseFees) external;
    function setPaused(address[] calldata tokens, bool[] calldata states) external;
    function setPausedForAll(bool state) external;
}

pragma solidity ^0.8.13;

interface ISingularityOracle {
    function getLatestRound(address token) external view returns (uint256, uint256);
    function getLatestRounds(address[] calldata tokens) external view returns (uint256[] memory prices, uint256[] memory updatedAts);
}

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
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

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

pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

pragma solidity ^0.8.13;
/**
 * @title Singularity Pool
 * @author Revenant Labs
 */
contract SingularityPool is ISingularityPool, SingularityPoolToken, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;

    bool public override paused;
    bool public immutable override isStablecoin;

    address public immutable override factory;
    address public immutable override token;

    uint256 public override depositCap;
    uint256 public override assets;
    uint256 public override liabilities;

    uint256 public override baseFee;
    uint256 public override adminFees;
    uint256 public override lockedFees;

    modifier notPaused() {
        require(paused == false, "SingularityPool: PAUSED");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "SingularityPool: NOT_FACTORY");
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == ISingularityFactory(factory).router(), "SingularityPool: NOT_ROUTER");
        _;
    }

    constructor() {
        factory = msg.sender;
        (token, isStablecoin, baseFee) = ISingularityFactory(msg.sender).poolParams();
        string memory tranche = ISingularityFactory(msg.sender).tranche();
        string memory tokenSymbol = IERC20(token).symbol();
        name = string(
            abi.encodePacked(
                "Singularity ", tokenSymbol, " Pool (", tranche, ")"
            )
        );
        symbol = string(
            abi.encodePacked(
                "SPT-", tokenSymbol, " (", tranche, ")"
            )
        );
        decimals = IERC20(token).decimals();
        _initialize();
    }

    function getCollateralizationRatio() external view override returns (uint256 collateralizationRatio) {
        if (liabilities == 0) {
            collateralizationRatio = type(uint256).max;
        } else {
            collateralizationRatio = assets.divWadDown(liabilities);
        }
    }

    function getPricePerShare() public view override returns (uint256 pricePerShare) {
        if (totalSupply == 0) {
            pricePerShare = 1e18;
        } else {
            pricePerShare = liabilities.divWadDown(totalSupply);
        }
    }

    function getOracleData() public view override returns (uint256 tokenPrice, uint256 updatedAt) {
        (tokenPrice, updatedAt) = ISingularityOracle(ISingularityFactory(factory).oracle()).getLatestRound(token);
        require(tokenPrice != 0, "SingularityPool: INVALID_ORACLE_PRICE");
    }

    /// @notice Calculates the equivalent USD value of given the number of tokens
    /// @dev USD value is in 1e18
    /// @param amount The amount of tokens to calculate the value of
    /// @return value The USD value equivalent to the number of tokens
    function getAmountToUSD(uint256 amount) public override view returns (uint256 value) {
        (uint256 tokenPrice, ) = getOracleData();
        value = amount.mulWadDown(tokenPrice);
        if (decimals <= 18) {
            value *= 10**(18 - decimals);
        } else {
            value /= 10**(decimals - 18);
        }
    }

    /// @notice Calculates the equivalent number of tokens given the USD value
    /// @dev USD value is in 1e18
    /// @param value The USD value of tokens to calculate the amount of
    /// @return amount The number of tokens equivalent to the USD value
    function getUSDToAmount(uint256 value) public override view returns (uint256 amount) {
        (uint256 tokenPrice, ) = getOracleData();
        amount = value.divWadDown(tokenPrice);
        if (decimals <= 18) {
            amount /= 10**(18 - decimals);
        } else {
            amount *= 10**(decimals - 18);
        }
    }

    function getLpFeeRate(uint256 collateralizationRatio) public pure override returns (uint256 lpFeeRate) {
        if (collateralizationRatio == 0) {
            return 0;
        }
        uint256 truncatedCRatio = collateralizationRatio / 10**15; // truncate collateralization ratio precision to 3
        uint256 numerator = 50 ether;
        uint256 denominator = truncatedCRatio.rpow(8, 1);
        lpFeeRate = numerator.divWadUp(denominator);
    }

    function getDepositFee(uint256 amount) public view override returns (uint256 fee) {
        uint256 currentCollateralizationRatio = _calcCollatalizationRatio(assets, liabilities);
        if (currentCollateralizationRatio >= 1 ether) {
            return 0;
        }

        uint256 gCurrent = getG(currentCollateralizationRatio);
        uint256 afterCollateralizationRatio = _calcCollatalizationRatio(assets + amount, liabilities + amount);
        uint256 gAfter = getG(afterCollateralizationRatio);
        fee = (liabilities + amount).mulWadUp(gAfter) - liabilities.mulWadDown(gCurrent);
    }

    function getWithdrawFee(uint256 amount) public view override returns (uint256 fee) {
        uint256 currentCollateralizationRatio = _calcCollatalizationRatio(assets, liabilities);
        if (currentCollateralizationRatio >= 1 ether) {
            return 0;
        }

        uint256 gCurrent = getG(currentCollateralizationRatio);
        uint256 afterCollateralizationRatio = _calcCollatalizationRatio(assets - amount, liabilities - amount);
        uint256 gAfter = getG(afterCollateralizationRatio);
        fee = gAfter.mulWadUp(liabilities - amount) + getG(1 ether).mulWadUp(amount) - gCurrent.mulWadDown(liabilities);
    }

    function getSlippageIn(uint256 amount) public view override returns (uint256 slippageIn) {
        if (amount == 0) {
            return 0;
        }

        uint256 currentCollateralizationRatio = _calcCollatalizationRatio(assets + lockedFees, liabilities);
        uint256 gCurrent = getG(currentCollateralizationRatio);
        uint256 afterCollateralizationRatio = _calcCollatalizationRatio(assets + lockedFees + amount, liabilities);
        uint256 gAfter = getG(afterCollateralizationRatio);
        uint256 gDiff = gCurrent - gAfter;
        if (gDiff == 0) {
            return 0;
        } else {
            slippageIn = gDiff.divWadDown(afterCollateralizationRatio - currentCollateralizationRatio);
        }
        slippageIn = amount.mulWadDown(slippageIn);
    }

    function getSlippageOut(uint256 amount) public view override returns (uint256 slippageOut) {
        if (amount == 0) {
            return 0;
        }
        if (amount >= assets + lockedFees) {
            return amount;
        }

        uint256 currentCollateralizationRatio = _calcCollatalizationRatio(assets + lockedFees, liabilities);
        uint256 afterCollateralizationRatio = _calcCollatalizationRatio(assets + lockedFees - amount, liabilities);
        uint256 gCurrent = getG(currentCollateralizationRatio);
        uint256 gAfter = getG(afterCollateralizationRatio);
        uint256 gDiff = gAfter - gCurrent;
        if (gDiff == 0) {
            return 0;
        } else {
            slippageOut = gDiff.divWadUp(currentCollateralizationRatio - afterCollateralizationRatio);
        }
        slippageOut = amount.mulWadUp(slippageOut);
    }

    function getG(uint256 collateralizationRatio) public pure override returns (uint256 slippageRate) {
        if (collateralizationRatio >= 1 ether) {
            slippageRate = 0.00002 ether;
        } else {
            uint256 truncatedCRatio = collateralizationRatio / 10**15; // truncate collateralization ratio precision to 3
            uint256 numerator = 0.02 ether;
            uint256 denominator = truncatedCRatio.rpow(7, 1);
            slippageRate = numerator.divWadUp(denominator);
        }
    }

    function getTradingFeeRate() public view override returns (uint256 tradingFeeRate) {
        if (isStablecoin) {
            tradingFeeRate = baseFee;
        } else {
            (, uint256 updatedAt) = getOracleData();
            uint256 timeDiff = block.timestamp - updatedAt;
            if (timeDiff > 70) {
                tradingFeeRate = type(uint256).max; // Revert later to allow viewability
            } else if (timeDiff >= 60) {
                tradingFeeRate = baseFee * 2;
            } else {
                tradingFeeRate = baseFee + baseFee * timeDiff / 60;
            }
        }
    }

    function getTradingFees(uint256 amount) public view override returns (uint256 totalFee, uint256 lockedFee, uint256 adminFee, uint256 lpFee) {
        uint256 tradingFeeRate = getTradingFeeRate();
        if (tradingFeeRate == type(uint256).max) {
            return (type(uint256).max, type(uint256).max, type(uint256).max, type(uint256).max);
        }
        totalFee = amount.mulWadUp(tradingFeeRate);
        lockedFee = totalFee * 45 / 100;
        lpFee = totalFee * 45 / 100;
        adminFee = totalFee - lockedFee - lpFee;
    }

    function deposit(uint256 amount, address to) external override onlyRouter notPaused nonReentrant returns (uint256 mintAmount) {
        require(amount != 0, "SingularityPool: AMOUNT_IS_0");
        require(amount + liabilities <= depositCap, "SingularityPool: DEPOSIT_EXCEEDS_CAP");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        if (liabilities == 0) {
            mintAmount = amount;
        } else {
            mintAmount = amount.divWadDown(getPricePerShare());
        }
        uint256 depositFee = getDepositFee(amount);
        amount -= depositFee;
        adminFees += depositFee;
        liabilities += amount;
        assets += amount;
        _mint(to, mintAmount);
        emit Deposit(msg.sender, amount, mintAmount, to);
    }

    function withdraw(uint256 amount, address to) external override onlyRouter notPaused nonReentrant returns (uint256 withdrawAmount) {
        require(amount != 0, "SingularityPool: AMOUNT_IS_0");
        _burn(msg.sender, amount);
        uint256 liquidityValue = amount.mulWadDown(getPricePerShare());
        uint256 withdrawFee = getWithdrawFee(amount);
        withdrawAmount = liquidityValue - withdrawFee;
        adminFees += withdrawFee;
        liabilities -= withdrawAmount;
        assets -= withdrawAmount;
        IERC20(token).safeTransfer(to, withdrawAmount);
        emit Withdraw(msg.sender, amount, withdrawAmount, to);
    }

    function swapIn(uint256 amountIn) external override onlyRouter notPaused nonReentrant returns (uint256 amountOut) {
        require(amountIn != 0, "SingularityPool: AMOUNT_IS_0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amountIn);

        // Apply trading fees
        (uint256 totalFee, uint256 lockedFee, uint256 adminFee, uint256 lpFee) = getTradingFees(amountIn);
        require(totalFee != type(uint256).max, "SingularityPool: STALE_ORACLE");
        lockedFees += lockedFee;
        adminFees += adminFee;
        liabilities += lpFee;
        amountIn -= totalFee;

        // Apply slippage (+)
        uint256 slippage = getSlippageIn(amountIn);
        amountIn += slippage;
        assets -= slippage;
        liabilities -= slippage;

        assets += amountIn;
        amountOut = getAmountToUSD(amountIn);
        emit SwapIn(msg.sender, amountIn, amountOut);
    }

    function swapOut(uint256 amountIn, address to) external override onlyRouter notPaused nonReentrant returns (uint256 amountOut) {
        require(amountIn != 0, "SingularityPool: AMOUNT_IS_0");
        amountOut = getUSDToAmount(amountIn);

        // Apply slippage (-)
        uint256 slippage = getSlippageOut(amountOut);
        amountOut -= slippage;
        assets += slippage;
        liabilities += slippage;

        // Apply trading fees
        (uint256 totalFee, uint256 lockedFee, uint256 adminFee, uint256 lpFee) = getTradingFees(amountOut);
        require(totalFee != type(uint256).max, "SingularityPool: STALE_ORACLE");
        lockedFees += lockedFee;
        adminFees += adminFee;
        liabilities += lpFee;

        assets -= amountOut;
        amountOut -= totalFee;

        IERC20(token).safeTransfer(to, amountOut);
        emit SwapOut(msg.sender, amountIn, amountOut, to);
    }

    function _calcCollatalizationRatio(uint256 _assets, uint256 _liabilities) internal pure returns (uint256 afterCollateralizationRatio) {
        if (_liabilities == 0) {
            afterCollateralizationRatio = type(uint256).max;
        } else {
            afterCollateralizationRatio = _assets.divWadDown(_liabilities);
        }
    }

    /* ========== FACTORY FUNCTIONS ========== */

    function collectFees() external override onlyFactory {
        if (adminFees != 0) {
            address feeTo = ISingularityFactory(factory).feeTo();
            IERC20(token).safeTransfer(feeTo, adminFees);
            adminFees = 0;
        }
    }

    function setDepositCap(uint256 newDepositCap) external override onlyFactory {
        depositCap = newDepositCap;
    }

    function setBaseFee(uint256 newBaseFee) external override onlyFactory {
        baseFee = newBaseFee;
    }

    function setPaused(bool state) external override onlyFactory {
        paused = state;
    }
}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ManagerRole } from './ManagerRole.sol';
import { NativeTokenAddress } from './NativeTokenAddress.sol';
import { SafeTransfer } from './SafeTransfer.sol';


abstract contract BalanceManagement is ManagerRole, NativeTokenAddress, SafeTransfer {
    error ReservedTokenError();

    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (isReservedToken(_tokenAddress)) {
            revert ReservedTokenError();
        }

        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            safeTransferNative(msg.sender, _tokenAmount);
        } else {
            safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return IERC20(_tokenAddress).balanceOf(address(this));
        }
    }

    function isReservedToken(address /*_tokenAddress*/) public view virtual returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract DataStructures {
    struct OptionalValue {
        bool isSet;
        uint256 value;
    }

    function uniqueAddressListAdd(
        address[] storage _list,
        mapping(address => OptionalValue) storage _indexMap,
        address _value
    ) internal returns (bool isChanged) {
        isChanged = !_indexMap[_value].isSet;

        if (isChanged) {
            _indexMap[_value] = OptionalValue(true, _list.length);
            _list.push(_value);
        }
    }

    function uniqueAddressListRemove(
        address[] storage _list,
        mapping(address => OptionalValue) storage _indexMap,
        address _value
    ) internal returns (bool isChanged) {
        OptionalValue storage indexItem = _indexMap[_value];

        isChanged = indexItem.isSet;

        if (isChanged) {
            uint256 itemIndex = indexItem.value;
            uint256 lastIndex = _list.length - 1;

            if (itemIndex != lastIndex) {
                address lastValue = _list[lastIndex];
                _list[itemIndex] = lastValue;
                _indexMap[lastValue].value = itemIndex;
            }

            _list.pop();
            delete _indexMap[_value];
        }
    }

    function uniqueAddressListUpdate(
        address[] storage _list,
        mapping(address => OptionalValue) storage _indexMap,
        address _value,
        bool _flag
    ) internal returns (bool isChanged) {
        return
            _flag
                ? uniqueAddressListAdd(_list, _indexMap, _value)
                : uniqueAddressListRemove(_list, _indexMap, _value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IRevenueShare {
    function rewardsFromPenalties(uint256 _amount) external;

    function lock(uint256 _amount, address _user) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { Ownable } from './Ownable.sol';
import { DataStructures } from './DataStructures.sol';

abstract contract ManagerRole is Ownable, DataStructures {
    error OnlyManagerError();

    address[] public managerList;
    mapping(address => OptionalValue) public managerIndexMap;

    event SetManager(address indexed account, bool indexed value);

    modifier onlyManager() {
        if (!isManager(msg.sender)) {
            revert OnlyManagerError();
        }

        _;
    }

    function setManager(address _account, bool _value) public virtual onlyOwner {
        uniqueAddressListUpdate(managerList, managerIndexMap, _account, _value);

        emit SetManager(_account, _value);
    }

    function isManager(address _account) public view virtual returns (bool) {
        return managerIndexMap[_account].isSet;
    }

    function managerCount() public view virtual returns (uint256) {
        return managerList.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract NativeTokenAddress {
    address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract Ownable {
    error OnlyOwnerError();
    error ZeroAddressError();

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwnerError();
        }

        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddressError();
        }

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { ManagerRole } from './ManagerRole.sol';

abstract contract Pausable is ManagerRole {
    error WhenNotPausedError();
    error WhenPausedError();

    bool public paused = false;

    event Pause();
    event Unpause();

    modifier whenNotPaused() {
        if (paused) {
            revert WhenNotPausedError();
        }

        _;
    }

    modifier whenPaused() {
        if (!paused) {
            revert WhenPausedError();
        }

        _;
    }

    function pause() public onlyManager whenNotPaused {
        paused = true;

        emit Pause();
    }

    function unpause() public onlyManager whenPaused {
        paused = false;

        emit Unpause();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


abstract contract SafeTransfer {

    error SafeApproveError();
    error SafeTransferError();
    error SafeTransferFromError();
    error SafeTransferNativeError();

    function safeApprove(address _token, address _to, uint256 _value) internal {
        // 0x095ea7b3 is the selector for "approve(address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x095ea7b3, _to, _value));

        bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

        if (!condition) {
            revert SafeApproveError();
        }
    }

    function safeTransfer(address _token, address _to, uint256 _value) internal {
        // 0xa9059cbb is the selector for "transfer(address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0xa9059cbb, _to, _value));

        bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

        if (!condition) {
            revert SafeTransferError();
        }
    }

    function safeTransferFrom(address _token, address _from, address _to, uint256 _value) internal {
        // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd, _from, _to, _value));

        bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

        if (!condition) {
            revert SafeTransferFromError();
        }
    }

    function safeTransferNative(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));

        if (!success) {
            revert SafeTransferNativeError();
        }
    }

    function safeTransferNativeUnchecked(address _to, uint256 _value) internal {
        (bool ignore, ) = _to.call{value: _value}(new bytes(0));

        ignore;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Pausable } from './Pausable.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { IRevenueShare } from './interfaces/IRevenueShare.sol';

contract StablecoinFarm is Pausable, BalanceManagement {
    using SafeERC20 for IERC20;

    struct VestedBalance {
        uint256 amount;
        uint256 unlockTime;
    }

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 remainingRewardTokenAmount; // Tokens that weren't distributed for user per pool.

        // Any point in time, the amount of reward tokens entitled to a user but is pending to be distributed is:
        // pending reward = (user.amount * pool.accumulatedRewardTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws Staked tokens to a pool. Here's what happens:
        //   1. The pool's `accumulatedRewardTokenPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    mapping(uint256 => mapping(address => uint256)) public totalVesting;

    // Info of each pool.

    struct PoolInfo {
        address stakingToken; // Contract address of staked token
        uint256 stakingTokenTotalAmount; //Total amount of deposited tokens
        uint256 accumulatedRewardTokenPerShare; // Accumulated reward token per share, times 1e12. See below.
        uint32 lastRewardTime; // Last timestamp number that reward token distribution occurs.
        uint16 allocationPoint; // How many allocation points assigned to this pool.
    }

    address public immutable rewardToken; // The reward token.

    address public ITPRevenueShare; // The penalty address of the fee ITPRevenueShare contract.
    address public LPRevenueShare; // The penalty address of the fee LPRevenueShare contract.

    uint256 public rewardTokenPerSecond; // Reward tokens vested per second.
    PoolInfo[] public poolInfo; // Info of each pool.

    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => VestedBalance[])) public userVested; // vested tokens
    mapping(uint256 => mapping(address => uint256)) public totalPaid; // total paid by the User
    mapping(uint256 => mapping(address => uint256)) public totalLocked; // total locked in distribution by the User

    uint256 public totalAllocationPoint = 0; // Total allocation points = the sum of all allocation points in all pools.
    uint32 public immutable startTime; // The timestamp when reward token farming starts.
    uint32 public endTime; // Time on which the reward calculation should end.
    uint256 public vestingDuration = 28 days;
    uint256 public exitEarlyUserShare = 500; // 50%
    uint256 public exitEarlyITPShare = 200; // 20%
    uint256 public exitEarlyLPShare = 300; // 30%

    uint256 private constant SHARE_PRECISION = 1e12; // Factor to perform multiplication and division operations.

    event Staked(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawVesting(address indexed user, uint256 amount);
    event Vested(address indexed user, uint256 indexed pid, uint256 amount);
    event Locked(address indexed user, uint256 indexed pid, uint256 amount);
    event ExitEarly(address indexed user, uint256 amount);

    constructor(
        address _rewardToken, // ITP
        uint256 _rewardTokenPerSecond,
        uint32 _startTime
    ) {
        rewardToken = _rewardToken;
        rewardTokenPerSecond = _rewardTokenPerSecond;
        startTime = _startTime;
        endTime = startTime + 90 days;
    }

    function setITPRevenueShare(address _ITPRevenueShare) external onlyOwner {
        require(_ITPRevenueShare != address(0), 'Zero address error');
        ITPRevenueShare = _ITPRevenueShare;
    }

    function setLPRevenueShare(address _LPRevenueShare) external onlyOwner {
        require(_LPRevenueShare != address(0), 'Zero address error');
        LPRevenueShare = _LPRevenueShare;
    }

    /*
     * @dev Sets portions for exit early. If it needs to set 33.3%, just provide 333 value
     * PAy attention, the sum of all values must be 1000, that means 100%
     */
    function setPercentsShare(
        uint256 _userPercent,
        uint256 _itpPercent,
        uint256 _lpPercent
    ) external onlyOwner {
        require(
            _userPercent + _itpPercent + _lpPercent == 1000,
            'Total percentage should be 100% in total'
        );
        exitEarlyUserShare = _userPercent;
        exitEarlyITPShare = _itpPercent;
        exitEarlyLPShare = _lpPercent;
    }

    /*
     * @dev Sets a new farm when it needs by the owner
     */
    function setVestingDuration(uint256 _vestingDuration) external onlyOwner {
        vestingDuration = _vestingDuration;
    }

    // Deposit staking tokens for reward token allocation.
    // staking iusdc/iusdt, itp rewards
    function stake(uint256 _pid, uint256 _amount) external whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        _updatePool(_pid);
        safeTransferFrom(pool.stakingToken, address(msg.sender), address(this), _amount);

        user.amount += _amount;
        pool.stakingTokenTotalAmount += _amount;
        user.rewardDebt = (user.amount * pool.accumulatedRewardTokenPerShare) / SHARE_PRECISION;

        emit Staked(msg.sender, _pid, _amount);
    }

    // Withdraw only staked iUSDC/iUSDT tokens
    function withdraw(uint256 _pid, uint256 _amount) external whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.amount < _amount) {
            revert('Can not withdraw this amount of');
        }

        _updatePool(_pid);

        user.remainingRewardTokenAmount = _pendingRewardTokenForUser(_pid, msg.sender);
        user.amount -= _amount;
        pool.stakingTokenTotalAmount -= _amount;
        user.rewardDebt = (user.amount * pool.accumulatedRewardTokenPerShare) / SHARE_PRECISION;

        safeTransfer(pool.stakingToken, msg.sender, _amount);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 userAmount = user.amount;

        pool.stakingTokenTotalAmount -= userAmount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.remainingRewardTokenAmount = 0;

        safeTransfer(pool.stakingToken, msg.sender, userAmount);

        emit EmergencyWithdraw(msg.sender, _pid, userAmount);
    }

    function changeEndTime(uint32 addSeconds) external onlyManager {
        endTime += addSeconds;
    }

    // Changes reward token amount per second. Use this function to moderate the `lockup amount`.
    // Essentially this function changes the amount of the reward which is entitled to the user
    // for his token staking by the time the `endTime` is passed.
    // Good practice to update pools without messing up the contract.
    function setRewardTokenPerSecond(
        uint256 _rewardTokenPerSecond,
        bool _withUpdate
    ) external onlyManager {
        if (_withUpdate) {
            _massUpdatePools();
        }

        rewardTokenPerSecond = _rewardTokenPerSecond;
    }

    // Add a new staking token to the pool. Can only be called by the owner.
    // VERY IMPORTANT NOTICE
    // ----------- DO NOT add the same staking token more than once. Rewards will be messed up if you do. -------------
    // Good practice to update pools without messing up the contract.
    function add(uint16 _allocPoint, address _stakingToken, bool _withUpdate) external onlyManager {
        if (_withUpdate) {
            _massUpdatePools();
        }

        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocationPoint += _allocPoint;
        poolInfo.push(
            PoolInfo({
                stakingToken: _stakingToken,
                stakingTokenTotalAmount: 0,
                allocationPoint: _allocPoint,
                lastRewardTime: uint32(lastRewardTime),
                accumulatedRewardTokenPerShare: 0
            })
        );
    }

    // Update the given pool's reward token allocation point. Can only be called by the owner.
    // Good practice to update pools without messing up the contract.
    function set(uint256 _pid, uint16 _allocPoint, bool _withUpdate) external onlyManager {
        if (_withUpdate) {
            _massUpdatePools();
        }
        totalAllocationPoint = totalAllocationPoint - poolInfo[_pid].allocationPoint + _allocPoint;
        poolInfo[_pid].allocationPoint = _allocPoint;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() external whenNotPaused {
        _massUpdatePools();
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) external whenNotPaused {
        _updatePool(_pid);
    }

    // How many pools are in the contract
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function vest(uint256 _pid) public whenNotPaused {
        _updatePool(_pid);
        uint256 pending = _pendingRewardTokenForUser(_pid, msg.sender);
        require(pending > 0, 'Amount of tokens can not be zero value');
        uint256 unlockTime = block.timestamp + vestingDuration;
        VestedBalance[] storage vestings = userVested[_pid][msg.sender];
        uint idx = vestings.length;
        if (idx == 0 || vestings[idx - 1].unlockTime < unlockTime) {
            vestings.push(VestedBalance({ amount: pending, unlockTime: unlockTime }));
        } else {
            vestings[idx - 1].amount = vestings[idx - 1].amount + pending;
        }
        totalVesting[_pid][msg.sender] += pending; // add amount that excludes from reqular ITP rewards
        emit Vested(msg.sender, _pid, pending);
    }

    // user can get his ITP rewards for staked iUSDC/iusct if locked time is already occurred
    function withdrawVestedRewards(uint256 _pid) public {
        _updatePool(_pid);
        uint256 vested = totalVesting[_pid][msg.sender];

        uint256 amount;
        if (vested > 0) {
            uint256 length = userVested[_pid][msg.sender].length;
            for (uint256 i = 0; i < length; i++) {
                uint256 earnedAmount = userVested[_pid][msg.sender][i].amount;
                if (earnedAmount == 0) continue;
                if (userVested[_pid][msg.sender][i].unlockTime > block.timestamp) {
                    break;
                }
                amount = amount + earnedAmount;
                delete userVested[_pid][msg.sender][i];
            }
            if (userVested[_pid][msg.sender].length == 0) {
                delete userVested[_pid][msg.sender];
            }
        }
        if (amount > 0) {
            uint256 result = safeRewardTransfer(msg.sender, amount); // ITP
            require(result == 0, 'ITP tokens are not available right now');
            // decrease amount that excludes from reqular ITP rewards
            totalVesting[_pid][msg.sender] -= amount;
            // add amount that excludes from reqular ITP rewards as paid for vesting
            totalPaid[_pid][msg.sender] += amount;
        } else {
            revert('Tokens are not available for now');
        }

        emit WithdrawVesting(msg.sender, amount);
    }

    // The user receives only `exitEarlyUserShare` - 50% ITP tokens by default
    // `exitEarlyITPShare` - 20% ITP tokens by default transfers to the ITP revenue share contract
    // `exitEarlyLPShare` - 30% ITP tokens by default transfers to the ITP-LP revenue share contract
    function exitEarly(uint256 _pid) public {
        _updatePool(_pid);
        // can withdraw 50% immideatelly
        require(totalVesting[_pid][msg.sender] > 0, 'Total vesting tokens can not be zero');
        uint256 amountTotal = totalVesting[_pid][msg.sender];
        uint256 amountUser = (amountTotal * exitEarlyUserShare) / 1000;
        uint256 amountITP = (amountTotal * exitEarlyITPShare) / 1000;
        uint256 amountLP = (amountTotal * exitEarlyLPShare) / 1000;
        uint256 result = safeRewardTransfer(msg.sender, amountUser); // ITP
        require(result == 0, 'ITP tokens are not available right now');
        // distribution will have access to rewards tokens
        IERC20(rewardToken).safeIncreaseAllowance(ITPRevenueShare, amountITP);
        IERC20(rewardToken).safeIncreaseAllowance(LPRevenueShare, amountLP);

        IRevenueShare(ITPRevenueShare).rewardsFromPenalties(amountITP);
        IRevenueShare(LPRevenueShare).rewardsFromPenalties(amountLP);
        totalPaid[_pid][msg.sender] += amountUser;
        totalLocked[_pid][msg.sender] += amountUser;
        totalVesting[_pid][msg.sender] = 0;
        delete userVested[_pid][msg.sender];
        emit ExitEarly(msg.sender, amountUser);
    }

    // lock vesting tokens to distributors
    function lockVesting(uint256 _pid) public {
        _updatePool(_pid);
        require(totalVesting[_pid][msg.sender] > 0, 'Total vesting tokens can not be zero');
        uint256 _amount = totalVesting[_pid][msg.sender];
        IERC20(rewardToken).safeIncreaseAllowance(ITPRevenueShare, _amount);
        IRevenueShare(ITPRevenueShare).lock(_amount, msg.sender);
        totalLocked[_pid][msg.sender] += _amount;
        totalVesting[_pid][msg.sender] = 0;

        emit Locked(msg.sender, _pid, _amount);
    }

    // stake iusdc tokens using stake(), ITP gets as reward
    // all ITP transfer to the fee distribution contract
    function lockPending(uint256 _pid) public {
        _updatePool(_pid);
        uint256 pending = _pendingRewardTokenForUser(_pid, msg.sender);

        // check that user have any pendings
        require(pending > 0, 'Amount of tokens can not be zero value');
        uint256 currentBalance = IERC20(rewardToken).balanceOf(address(this));
        if (pending > currentBalance) {
            pending = currentBalance;
        }
        if (pending > 0) {
            IERC20(rewardToken).safeIncreaseAllowance(ITPRevenueShare, pending);
            IRevenueShare(ITPRevenueShare).lock(pending, msg.sender);
            totalLocked[_pid][msg.sender] += pending;
        }
        emit Locked(msg.sender, _pid, pending);
    }

    // Return reward multiplier over the given _from to _to time.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        // console.log(_from, _to);
        _from = _from > startTime ? _from : startTime;

        if (_from > endTime || _to < startTime) {
            return 0;
        } else if (_to > endTime) {
            return endTime - _from;
        } else return _to - _from;
    }

    function isReservedToken(address _tokenAddress) public view override returns (bool) {
        uint256 length = poolInfo.length;

        for (uint256 pid; pid < length; ++pid) {
            if (_tokenAddress == poolInfo[pid].stakingToken) {
                return true;
            }
        }

        return false;
    }

    // View function to see pending reward token on frontend.
    function pendingRewardToken(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accumulatedRewardTokenPerShare = pool.accumulatedRewardTokenPerShare;
        if (block.timestamp > pool.lastRewardTime && pool.stakingTokenTotalAmount != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);

            uint256 rewardTokenReward = (multiplier * rewardTokenPerSecond * pool.allocationPoint) /
                totalAllocationPoint;

            accumulatedRewardTokenPerShare +=
                (rewardTokenReward * SHARE_PRECISION) /
                pool.stakingTokenTotalAmount;
        }
        uint256 _total = totalVesting[_pid][_user];
        uint256 pending = (user.amount * accumulatedRewardTokenPerShare) /
            SHARE_PRECISION -
            user.rewardDebt +
            user.remainingRewardTokenAmount;
        if (pending >= _total) {
            pending = pending - _total;
        }
        _total = totalPaid[_pid][_user];
        if (pending >= _total) {
            pending = pending - _total;
        }

        _total = totalLocked[_pid][_user];
        if (pending >= _total) {
            pending = pending - _total;
        }
        return pending;
    }

    function _pendingRewardTokenForUser(
        uint256 _pid,
        address _user
    ) internal view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 _total = totalVesting[_pid][_user];
        uint256 pending = (user.amount * pool.accumulatedRewardTokenPerShare) /
            SHARE_PRECISION -
            user.rewardDebt +
            user.remainingRewardTokenAmount;
        if (pending >= _total) {
            pending = pending - _total;
        }
        _total = totalPaid[_pid][_user];
        if (pending >= _total) {
            pending = pending - _total;
        }
        _total = totalLocked[_pid][_user];
        if (pending >= _total) {
            pending = pending - _total;
        }
        return pending;
    }

    // Safe reward token transfer function. Just in case if the pool does not have enough reward token.
    // The function returns the amount which is owed to the user.
    function safeRewardTransfer(address _to, uint256 _amount) private returns (uint256) {
        uint256 rewardTokenBalance = IERC20(rewardToken).balanceOf(address(this));

        if (_amount > rewardTokenBalance) {
            safeTransfer(rewardToken, _to, rewardTokenBalance);

            return _amount - rewardTokenBalance;
        } else {
            safeTransfer(rewardToken, _to, _amount);
            return 0;
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function _massUpdatePools() private {
        uint256 length = poolInfo.length;

        for (uint256 pid; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid) private {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        if (pool.stakingTokenTotalAmount == 0) {
            pool.lastRewardTime = uint32(block.timestamp);
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 rewardTokenAmount = (multiplier * rewardTokenPerSecond * pool.allocationPoint) /
            totalAllocationPoint;

        pool.accumulatedRewardTokenPerShare +=
            (rewardTokenAmount * SHARE_PRECISION) /
            pool.stakingTokenTotalAmount;
        pool.lastRewardTime = uint32(block.timestamp);
    }
}
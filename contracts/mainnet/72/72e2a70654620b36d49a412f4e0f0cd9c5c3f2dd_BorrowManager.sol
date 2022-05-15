/**
 *Submitted for verification at FtmScan.com on 2022-05-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;


enum Status { Active, Repaid, Defaulted }


struct Debt
{
  uint16 interestRate;
  uint24 durationInSecs;
  uint32 startTimestamp;
  address borrower;
  address token;
  address collateralToken;
  uint128 amount;
  uint128 collateral;
}

struct DebtMetadata
{
  Status status;
  uint32 extensionTimestamp;
  uint32 weightedAvgRepayTimestamp;
  uint128 initialAmount;
}

struct DebtInfo
{
  address borrower;
  address token;
  uint256 amount;
  uint256 initialAmount;
  address collateralToken;
  uint256 collateral;
  uint256 interestRate;
  uint256 durationInSecs;
  Status status;
  uint256 startTimestamp;
  uint256 weightedAvgRepayTimestamp;
  uint256 extensionTimestamp;
}


interface IBorrowManager
{
  function getDebt (bytes32 debtID) external view returns (Debt memory);

  function getDebtInfo (bytes32 debtID) external view returns (DebtInfo memory);

  function getDebtMetadata (bytes32 debtID) external view returns (DebtMetadata memory);
}




pragma solidity 0.8.6;


struct Vault
{
  address deposit;
  address interest;
  address collateral;
}

struct Asset
{
  Vault vaults;
  uint256 totalBorrowed;
  uint256 cumulativeInterestPaid;
}


interface ICoordinator
{
  function getAsset (address token) external view returns (Asset memory);


  function getPairVault (address debtToken, address collateralToken) external view returns (Vault memory);

  function increaseTotalBorrowedAndGetPairVault (address debtToken, address collateralToken, uint256 amount) external returns (Vault memory);

  function increaseCumulativeInterestPaid (address token, uint256 amount) external;

  function decreaseTotalBorrowed (address debtToken, uint256 amount) external;
}




pragma solidity 0.8.6;


struct Ratio
{
  uint256 init;
  uint256 liquidation;
}

interface ICollateralizationManager
{
  function getRatio (address token) external view returns (Ratio memory);

  function isSufficientInitialCollateral (address tokenRegistry, address debtToken, address collateralToken, uint256 debtInCollateralToken, uint256 collateral) external view returns (bool);

  function isSufficientCollateral (address borrower, address debtToken, uint256 debt, address collateralToken, uint256 collateral) external view returns (bool, uint256);
}




pragma solidity 0.8.6;


interface IFeeManager
{
  function getBurner () external view returns (address);

  function getDefaultFee (uint256 collateral) external view returns (uint256, address);

  function getDepositFeeOnInterest (uint256 deposit, uint256 depositInUSD, uint256 interest, bool isDiscountedForDeposits) external view returns (uint256, address);

  function getBorrowFeeOnDebt (uint256 debtInCollateralToken, bool isDiscountedForDebts) external view returns (uint256, address);
}




pragma solidity 0.8.6;


interface IRewardManager
{
  function registerDebt (bytes32 debtID, uint256 debtInUSD, uint256 interestRate, uint256 durationInSecs, bool isDiscountedForDebts) external;
}




pragma solidity 0.8.6;


interface IStakingManager
{
  function isStakingForDeposits (address account) external view returns (bool);

  function isDiscountedForDeposits (address account) external view returns (bool);


  function isStakingForDebts (address account) external view returns (bool);

  function isDiscountedForDebts (address account) external view returns (bool);


  function increaseExpectedForDeposits (address depositor, uint256 depositInUSD, uint256 interestRate) external;

  function decreaseExpectedForDeposits (address depositor, address depositToken, uint256 deposit, uint256 interestRate) external;


  function increaseExpectedForDebts (address borrower, uint256 debtInUSD, uint256 dueTimestamp) external;

  function decreaseExpectedForDebts (address borrower, address debtToken, uint256 debt) external;
}




pragma solidity 0.8.6;


interface IVault
{
  function __Vault_init (address token) external;


  function getToken () external view returns (address);

  function getBalance () external view returns (uint256);

  function updateAllowances () external;
}




pragma solidity 0.8.6;


interface IOracle
{
  function getConversionRate (address fromToken, address toToken) external view returns (uint256);

  function convertFromUSD (address toToken, uint256 amount) external view returns (uint256);

  function convertToUSD (address fromToken, uint256 amount) external view returns (uint256);

  function convert (address fromToken, address toToken, uint256 amount) external view returns (uint256);
}




pragma solidity 0.8.6;


struct Contracts
{
  address oracle;
  address tokenRegistry;
  address coordinator;
  address stakingManager;
  address feeManager;
  address collateralizationManager;
  address rewardManager;
}


interface IContractRegistry
{
  function getContract (bytes32 key) external view returns (address);


  function borrowContracts () external view returns (Contracts memory);


  function oracle () external view returns (address);

  function tokenRegistry () external view returns (address);

  function vault () external view returns (address);

  function coordinator () external view returns (address);

  function depositManager () external view returns (address);

  function borrowManager () external view returns (address);

  function stakingManager () external view returns (address);

  function feeManager () external view returns (address);

  function collateralizationManager () external view returns (address);

  function rewardManager () external view returns (address);
}




pragma solidity 0.8.6;


contract Pausable
{
  bool private _paused;


  event Pause(address pauser);
  event Unpause(address pauser);


  constructor ()
  {
    _paused = false;
  }

  function paused () public view returns (bool)
  {
    return _paused;
  }

  function _isNotPaused () internal view
  {
    require(!_paused, "paused");
  }

  function _pause () internal
  {
    _isNotPaused();


    _paused = true;


    emit Pause(msg.sender);
  }

  function _unpause () internal
  {
    require(_paused, "!paused");


    _paused = false;


    emit Unpause(msg.sender);
  }
}




// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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




// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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




// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}




// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}




// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}




// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}




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




// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}




// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}




// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;


/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// File: @openzeppelin/contracts/access/AccessControlEnumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;




/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}




// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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




pragma solidity 0.8.6;

















contract BorrowManager is IBorrowManager, AccessControlEnumerable, ReentrancyGuard, Pausable
{
  using SafeERC20 for IERC20;


  IContractRegistry private constant _REGISTRY = IContractRegistry(0x06Eeb1B35361687f10909902AD4704AC7d09e0E7);

  uint256 private constant _BASIS_POINT = 10000;
  uint256 private constant _MIN_VALUE = 1000e18;
  uint256 private constant _MIN_INTEREST = 200;
  uint256 private constant _MAX_INTEREST = 1000;
  uint256 private constant _MIN_DURATION = 10 days;
  uint256 private constant _MAX_DURATION = 30 days;
  uint256 private constant _EXT_DURATION = 15 days;
  uint256 private constant _MAX_COMP_RATIO = 10550;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");


  struct Liquidation
  {
    address burner;
    uint256 amount;
    uint256 interest;
    uint256 collateral;
    uint256 compensation;
    uint256 fee;
  }

  struct Metadata
  {
    bool isDiscounted;
    uint256 debtInUSD;
    uint256 debtInCollateralToken;
  }

  bytes32[] private _debtIDs;
  uint40 private _totalDebtCount;

  mapping(bytes32 => Debt) private _debt;
  mapping(address => bytes32[]) private _debtsOf;
  mapping(bytes32 => DebtMetadata) private _debtMetadata;


  event NewBorrow(bytes32 indexed debtID, address indexed borrower, address debtToken, uint256 amount);
  event Extension(bytes32 indexed debtID, address indexed borrower, address debtToken, uint256 interest);

  event Repay(bytes32 indexed debtID, address indexed borrower, address debtToken, uint256 amount);

  event Liquidate(bytes32 indexed debtID, address liquidator, address debtToken, uint256 amount);
  event Default(bytes32 indexed debtID, address indexed borrower, address debtToken, uint256 amount);


  constructor ()
  {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(PAUSER_ROLE, msg.sender);
  }

  function preload (bytes32[] calldata ids, Debt[] calldata debts, DebtMetadata[] calldata metadata, uint256 count) external
  {
    require(_totalDebtCount == 0, "loaded");
    require(hasRole(ADMIN_ROLE, msg.sender), "!admin");
    require(debts.length == metadata.length && metadata.length == ids.length, "!=");


    if (count > 0)
    {
      _totalDebtCount = uint40(count);
    }


    for (uint256 i = 0; i < ids.length; i++)
    {
      bytes32 id = ids[i];
      Debt memory debt = debts[i];
      DebtMetadata memory meta = metadata[i];


      _debtIDs.push(id);

      _debt[id] = debt;
      _debtMetadata[id] = meta;
      _debtsOf[debt.borrower].push(id);
    }
  }

  function pause () public
  {
    require(hasRole(PAUSER_ROLE, msg.sender), "!pauser");


    _pause();
  }

  function unpause () public
  {
    require(hasRole(PAUSER_ROLE, msg.sender), "!pauser");


    _unpause();
  }


  function _getAsset (address token) private view returns (Asset memory)
  {
    return ICoordinator(_REGISTRY.coordinator()).getAsset(token);
  }


  function _calcPercentOf (uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return (amount * percent) / _BASIS_POINT;
  }


  function getTotalDebtCount () external view returns (uint256)
  {
    return uint256(_totalDebtCount);
  }

  function getDebtIDs () external view returns (bytes32[] memory)
  {
    return _debtIDs;
  }

  function getDebt (bytes32 debtID) external view override returns (Debt memory)
  {
    return _debt[debtID];
  }

  function getDebtMetadata (bytes32 debtID) external view override returns (DebtMetadata memory)
  {
    return _debtMetadata[debtID];
  }

  function getDebtInfo (bytes32 debtID) public view override returns (DebtInfo memory)
  {
    Debt memory debt = _debt[debtID];
    DebtMetadata memory debtMetadata = _debtMetadata[debtID];


    return DebtInfo
    ({
      borrower: debt.borrower,
      token: debt.token,
      amount: uint256(debt.amount),
      initialAmount: uint256(debtMetadata.initialAmount),
      collateralToken: debt.collateralToken,
      collateral: uint256(debt.collateral),
      interestRate: uint256(debt.interestRate),
      durationInSecs: uint256(debt.durationInSecs),
      status: debtMetadata.status,
      startTimestamp: uint256(debt.startTimestamp),
      extensionTimestamp: uint256(debtMetadata.extensionTimestamp),
      weightedAvgRepayTimestamp: uint256(debtMetadata.weightedAvgRepayTimestamp)
    });
  }

  function getDebtsOf (address borrower) external view returns (bytes32[] memory)
  {
    return _debtsOf[borrower];
  }


  // merge into borrow to remove quirk
  function _getMetadata (Contracts memory contracts, address debtToken, uint256 amount, uint256 durationInSecs, address collateralToken) private returns (Metadata memory metadata)
  {
    uint256 debtInUSD = IOracle(contracts.oracle).convertToUSD(debtToken, amount);


    IStakingManager(contracts.stakingManager).increaseExpectedForDebts(msg.sender, debtInUSD, block.timestamp + durationInSecs);


    return Metadata({ isDiscounted: IStakingManager(contracts.stakingManager).isDiscountedForDebts(msg.sender), debtInUSD: debtInUSD, debtInCollateralToken: IOracle(contracts.oracle).convert(debtToken, collateralToken, amount) });
  }

  function _isValidBorrow (uint256 debtInUSD, uint256 interestRate, uint256 durationInSecs) private pure returns (bool)
  {
    return debtInUSD >= _MIN_VALUE && interestRate >= _MIN_INTEREST && interestRate <= _MAX_INTEREST && durationInSecs >= _MIN_DURATION && durationInSecs <= _MAX_DURATION;
  }

  function borrow (address debtToken, uint256 amount, address collateralToken, uint256 collateral, uint256 interestRate, uint256 durationInSecs) external nonReentrant
  {
    _isNotPaused();


    Contracts memory contracts = _REGISTRY.borrowContracts();
    Metadata memory metadata = _getMetadata(contracts, debtToken, amount, durationInSecs, collateralToken);
    Vault memory vaults = ICoordinator(contracts.coordinator).increaseTotalBorrowedAndGetPairVault(debtToken, collateralToken, amount);

    require(IERC20(debtToken).balanceOf(vaults.deposit) >= amount, "!enough liq");
    require(_isValidBorrow(metadata.debtInUSD, interestRate, durationInSecs), "!valid terms");
    require(ICollateralizationManager(contracts.collateralizationManager).isSufficientInitialCollateral(contracts.tokenRegistry, debtToken, collateralToken, metadata.debtInCollateralToken, collateral), "!enough collateral");


    _totalDebtCount += 1;

    bytes32 id = keccak256(abi.encodePacked(_totalDebtCount, block.timestamp, msg.sender, debtToken, amount, collateralToken, collateral));


    _debtIDs.push(id);
    _debtsOf[msg.sender].push(id);

    _debt[id] = Debt
    ({
      borrower: msg.sender,
      token: debtToken,
      amount: uint128(amount),
      collateralToken: collateralToken,
      collateral: uint128(collateral),
      interestRate: uint16(interestRate),
      durationInSecs: uint24(durationInSecs),
      startTimestamp: uint32(block.timestamp)
    });


    IRewardManager(contracts.rewardManager).registerDebt(id, metadata.debtInUSD, interestRate, durationInSecs, metadata.isDiscounted);


    (uint256 debtFee, address burner) = IFeeManager(contracts.feeManager).getBorrowFeeOnDebt(metadata.debtInCollateralToken, metadata.isDiscounted);


    IERC20(collateralToken).safeTransferFrom(msg.sender, burner, debtFee);
    IERC20(collateralToken).safeTransferFrom(msg.sender, vaults.collateral, collateral);
    IERC20(debtToken).safeTransferFrom(vaults.deposit, msg.sender, amount);


    emit NewBorrow(id, msg.sender, debtToken, amount);
  }



  function _isUndercollateralized (Debt memory debt) private view returns (bool)
  {
    (bool sufficient,) = ICollateralizationManager(_REGISTRY.collateralizationManager()).isSufficientCollateral(debt.borrower, debt.token, debt.amount, debt.collateralToken, debt.collateral);


    return !sufficient;
  }

  function isUndercollateralized (bytes32 debtID) public view returns (bool)
  {
    return _isUndercollateralized(_debt[debtID]);
  }

  function _isOverdue (Debt memory debt, DebtMetadata memory debtMetadata) private view returns (bool)
  {
    uint256 dueTimestamp = debtMetadata.extensionTimestamp > 0 ? (debtMetadata.extensionTimestamp + _EXT_DURATION) : (debt.startTimestamp + debt.durationInSecs);


    return block.timestamp > dueTimestamp;
  }

  function isOverdue (bytes32 debtID) public view returns (bool)
  {
    DebtInfo memory debt = getDebtInfo(debtID);

    uint256 dueTimestamp = debt.extensionTimestamp > 0 ? (debt.extensionTimestamp + _EXT_DURATION) : (debt.startTimestamp + debt.durationInSecs);


    return block.timestamp > dueTimestamp;
  }

  function _isDefaulted (Debt memory debt, DebtMetadata memory debtMetadata) private view returns (bool)
  {
    return _isUndercollateralized(debt) || _isOverdue(debt, debtMetadata);
  }

  function isDefaulted (bytes32 debtID) external view returns (bool)
  {
    return isUndercollateralized(debtID) || isOverdue(debtID);
  }

  function _isActive (uint256 startTimestamp, Status status) private pure
  {
    require(startTimestamp > 0 && status == Status.Active, "!active");
  }

  function _hasDefaulted (Debt memory debt, DebtMetadata memory debtMetadata) private view
  {
    _isActive(debt.startTimestamp, debtMetadata.status);
    require(_isDefaulted(debt, debtMetadata), "!defaulted");
  }

  function _hasNotDefaulted (Debt memory debt, DebtMetadata memory debtMetadata) private view
  {
    _isActive(debt.startTimestamp, debtMetadata.status);
    require(!_isDefaulted(debt, debtMetadata), "defaulted");
  }


  function _metadataIsSet (DebtMetadata memory metadata) private pure returns (bool)
  {
    return metadata.initialAmount > 0 || metadata.extensionTimestamp > 0;
  }

  function _setMetadata (bytes32 id, Status status, uint256 initial, uint256 extensionTimestamp, uint256 repayTimestamp) private
  {
    _debtMetadata[id] = DebtMetadata({ status: status, initialAmount: uint128(initial), extensionTimestamp: uint32(extensionTimestamp), weightedAvgRepayTimestamp: uint32(repayTimestamp) });
  }


  function _isBorrower (address borrower) private view
  {
    require(msg.sender == borrower, "!borrower");
  }


  function extend (bytes32 debtID) external nonReentrant
  {
    _isNotPaused();


    Debt memory debt = _debt[debtID];
    Asset memory asset = _getAsset(debt.token);
    DebtMetadata memory debtMetadata = _debtMetadata[debtID];

    _isBorrower(debt.borrower);
    _isActive(debt.startTimestamp, debtMetadata.status);
    require(debtMetadata.extensionTimestamp == 0, "extended");
    require(IStakingManager(_REGISTRY.stakingManager()).isDiscountedForDebts(msg.sender), "!enough stake");
    require(block.timestamp >= debt.startTimestamp + _calcPercentOf(debt.durationInSecs, 8500), "too soon");
    require(IERC20(debt.token).balanceOf(asset.vaults.deposit) >= _calcPercentOf(debt.amount, 15000), "!enough liq");


    if (_metadataIsSet(debtMetadata))
    {
      _debtMetadata[debtID].extensionTimestamp = uint32(block.timestamp);
    }
    else
    {
      _setMetadata(debtID, Status.Active, debt.amount, block.timestamp, 0);
    }


    uint256 interest = _calcPercentOf(debt.amount, debt.interestRate);


    ICoordinator(_REGISTRY.coordinator()).increaseCumulativeInterestPaid(debt.token, interest);


    IERC20(debt.token).safeTransferFrom(msg.sender, IFeeManager(_REGISTRY.feeManager()).getBurner(), _calcPercentOf(debt.amount, 75));
    IERC20(debt.token).safeTransferFrom(msg.sender, asset.vaults.interest, interest);


    emit Extension(debtID, msg.sender, debt.token, interest);
  }



  function _repay (Debt memory debt, bytes32 debtID, uint256 debtRepaid, uint256 collateral) private
  {
    Asset memory asset = _getAsset(debt.token);
    ICoordinator coordinator = ICoordinator(_REGISTRY.coordinator());

    uint256 interest = _calcPercentOf(debtRepaid, debt.interestRate);


    IStakingManager(_REGISTRY.stakingManager()).decreaseExpectedForDebts(msg.sender, debt.token, debtRepaid - interest);

    coordinator.increaseCumulativeInterestPaid(debt.token, interest);
    coordinator.decreaseTotalBorrowed(debt.token, debtRepaid);


    IERC20(debt.token).safeTransferFrom(msg.sender, asset.vaults.interest, interest);
    IERC20(debt.token).safeTransferFrom(msg.sender, asset.vaults.deposit, debtRepaid);


    if (collateral > 0)
    {
      IERC20(debt.collateralToken).safeTransferFrom(_getAsset(debt.collateralToken).vaults.collateral, msg.sender, collateral);
    }


    emit Repay(debtID, msg.sender, debt.token, debtRepaid);
  }


  function _calcWeightedAvgRepayTimestamp (uint256 debtAlreadyPaid, uint256 debtToRepay, uint256 currentWeightedAvgRepayTimestamp) private view returns (uint256)
  {
    if (debtAlreadyPaid == 0)
    {
      return block.timestamp;
    }


    return ((debtAlreadyPaid * currentWeightedAvgRepayTimestamp) + (debtToRepay * block.timestamp)) / (debtAlreadyPaid + debtToRepay);
  }

  function _canRepay (Debt memory debt, DebtMetadata memory debtMetadata) private view
  {
    _isBorrower(debt.borrower);
    _hasNotDefaulted(debt, debtMetadata);
    require(block.timestamp > debt.startTimestamp + 9 days, "recent");
  }

  function repay (bytes32 debtID) external nonReentrant
  {
    Debt memory debt = _debt[debtID];
    DebtMetadata memory debtMetadata = _debtMetadata[debtID];

    _canRepay(debt, debtMetadata);


    if (_metadataIsSet(debtMetadata))
    {
      _debtMetadata[debtID].status = Status.Repaid;
      _debtMetadata[debtID].weightedAvgRepayTimestamp = uint32(_calcWeightedAvgRepayTimestamp(debtMetadata.initialAmount - debt.amount, debt.amount, debtMetadata.weightedAvgRepayTimestamp));
    }
    else
    {
      _setMetadata(debtID, Status.Repaid, debt.amount, 0, block.timestamp);
    }


    _repay(debt, debtID, debt.amount, debt.collateral);
  }


  function _proportionalCollateral (uint256 amount, uint256 debt, uint256 collateral) private pure returns (uint256)
  {
    uint256 proportion = (amount * _BASIS_POINT) / debt;


    return _calcPercentOf(collateral, proportion);
  }

  function _calcProportionallyWithdrawableCollateral (Debt memory debt, uint256 debtToRepay) private view returns (uint256)
  {
    ICollateralizationManager manager = ICollateralizationManager(_REGISTRY.collateralizationManager());

    (, uint256 ratio) = manager.isSufficientCollateral(debt.borrower, debt.token, debt.amount, debt.collateralToken, debt.collateral);


    return ratio <= manager.getRatio(debt.collateralToken).init ? 0 : _proportionalCollateral(debtToRepay, debt.amount, debt.collateral);
  }

  function _isSufficientMinValue (address token, uint256 amount) private view returns (bool)
  {
    return IOracle(_REGISTRY.oracle()).convertToUSD(token, amount) >= _MIN_VALUE;
  }

  function repayPartial (bytes32 debtID, uint256 amount, bool withdrawCollateral) external nonReentrant
  {
    Debt memory debt = _debt[debtID];
    DebtMetadata memory debtMetadata = _debtMetadata[debtID];

    _canRepay(debt, debtMetadata);
    require(amount > 0 && amount < debt.amount, "!valid amt");
    require(_isSufficientMinValue(debt.token, debt.amount - amount), "repay all");


    if (_metadataIsSet(debtMetadata))
    {
      _debtMetadata[debtID].weightedAvgRepayTimestamp = uint32(_calcWeightedAvgRepayTimestamp(debtMetadata.initialAmount - debt.amount, amount, debtMetadata.weightedAvgRepayTimestamp));
    }
    else
    {
      _setMetadata(debtID, Status.Active, debt.amount, 0, block.timestamp);
    }


    _debt[debtID].amount = debt.amount - uint128(amount);


    uint256 collateral;

    if (withdrawCollateral)
    {
      collateral = _calcProportionallyWithdrawableCollateral(debt, amount);

      _debt[debtID].collateral = debt.collateral - uint128(collateral);
    }


    _repay(debt, debtID, amount, collateral);
  }


  function topUpCollateral (bytes32 debtID, uint256 amount) external nonReentrant
  {
    Debt memory debt = _debt[debtID];

    _isBorrower(debt.borrower);
    _hasNotDefaulted(debt, _debtMetadata[debtID]);
    require(amount > 0 && amount < type(uint128).max, "!valid amt");


    _debt[debtID].collateral = debt.collateral + uint128(amount);


    IERC20(debt.collateralToken).safeTransferFrom(debt.borrower, _getAsset(debt.collateralToken).vaults.collateral, amount);
  }


  function _liquidate (Liquidation memory liquidation, Debt memory debt, bytes32 debtID) private
  {
    ICoordinator coordinator = ICoordinator(_REGISTRY.coordinator());
    Vault memory vaults = coordinator.getPairVault(debt.token, debt.collateralToken);


    coordinator.increaseCumulativeInterestPaid(debt.token, liquidation.interest);
    coordinator.decreaseTotalBorrowed(debt.token, liquidation.amount);


    IERC20(debt.token).safeTransferFrom(msg.sender, vaults.deposit, liquidation.amount);
    IERC20(debt.token).safeTransferFrom(msg.sender, vaults.interest, liquidation.interest);
    IERC20(debt.collateralToken).safeTransferFrom(vaults.collateral, liquidation.burner, liquidation.fee);
    IERC20(debt.collateralToken).safeTransferFrom(vaults.collateral, msg.sender, liquidation.compensation);


    emit Liquidate(debtID, msg.sender, debt.token, liquidation.amount);
  }

  function _getLiquidationMetadata (Debt memory debt, uint256 amount, uint256 collateral, bool isPartial) private view returns (Liquidation memory)
  {
    uint256 interest = _calcPercentOf(amount, debt.interestRate);

    (uint256 defaultFee, address burner) = IFeeManager(_REGISTRY.feeManager()).getDefaultFee(collateral);

    uint256 compensation = Math.min(IOracle(_REGISTRY.oracle()).convert(debt.token, debt.collateralToken, _calcPercentOf(amount + interest, _MAX_COMP_RATIO)), collateral - defaultFee);

    uint256 fee = (collateral - defaultFee - compensation) > 0 ? (collateral - compensation) : defaultFee;


    return Liquidation({ burner: burner, amount: amount, interest: interest, collateral: collateral, compensation: compensation, fee: isPartial ? defaultFee : fee });
  }

  function liquidate (bytes32 debtID) external nonReentrant
  {
    Debt memory debt = _debt[debtID];
    DebtMetadata memory debtMetadata = _debtMetadata[debtID];

    _hasDefaulted(debt, debtMetadata);


    if (_metadataIsSet(debtMetadata))
    {
      _debtMetadata[debtID].status = Status.Defaulted;
      _debtMetadata[debtID].weightedAvgRepayTimestamp = 0;
    }
    else
    {
      _setMetadata(debtID, Status.Defaulted, debt.amount, 0, 0);
    }


    _liquidate(_getLiquidationMetadata(debt, debt.amount, debt.collateral, false), debt, debtID);


    emit Default(debtID, debt.borrower, debt.token, debt.amount);
  }

  function liquidatePartial (bytes32 debtID, uint256 amount) external nonReentrant
  {
    Debt memory debt = _debt[debtID];

    _hasDefaulted(debt, _debtMetadata[debtID]);
    require(amount > 0 && amount < debt.amount, "!valid amt");
    require(_isSufficientMinValue(debt.token, debt.amount - amount), "liq all");


    if (!_metadataIsSet(_debtMetadata[debtID]))
    {
      _setMetadata(debtID, Status.Active, debt.amount, 0, 0);
    }


    Liquidation memory liquidation = _getLiquidationMetadata(debt, amount, _proportionalCollateral(amount, debt.amount, debt.collateral), true);


    _debt[debtID].amount = debt.amount - uint128(amount);
    _debt[debtID].collateral = debt.collateral - uint128(liquidation.fee + liquidation.compensation);


    _liquidate(liquidation, debt, debtID);
  }

  function forceLiquidate (bytes32 debtID) external
  {
    require(hasRole(ADMIN_ROLE, msg.sender), "!admin");


    Debt memory debt = _debt[debtID];
    DebtMetadata memory debtMetadata = _debtMetadata[debtID];

    _hasDefaulted(debt, debtMetadata);


    if (_metadataIsSet(debtMetadata))
    {
      _debtMetadata[debtID].status = Status.Defaulted;
      _debtMetadata[debtID].weightedAvgRepayTimestamp = 0;
    }
    else
    {
      _setMetadata(debtID, Status.Defaulted, debt.amount, 0, 0);
    }


    IERC20(debt.collateralToken).safeTransferFrom(_getAsset(debt.collateralToken).vaults.collateral, IFeeManager(_REGISTRY.feeManager()).getBurner(), debt.collateral);


    emit Liquidate(debtID, msg.sender, debt.token, debt.amount);
    emit Default(debtID, debt.borrower, debt.token, debt.amount);
  }
}
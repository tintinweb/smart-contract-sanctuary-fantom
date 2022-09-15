// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Sender.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * {IERC777} Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 * their own implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Sender {
    /**
     * @dev Called by an {IERC777} token contract whenever a registered holder's
     * (`from`) tokens are about to be moved or destroyed. The type of operation
     * is conveyed by `to` being the zero address or not.
     *
     * This call occurs _before_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the pre-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.9;

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
library LibContext {
    function msgSender() internal view returns (address) {
        return msg.sender;
    }

    function msgData() internal view returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\____vbranden___/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {LibContext} from "@solarprotocol/libraries/contracts/utils/LibContext.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @dev Collection of helpers for parameter validation.
 */
library LibUtils {
    using Address for address;

    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    error NotOwner(address address_);
    error NotContract(address address_);
    error NotERC20(address address_);

    function validateERC20(address token) internal view {
        if (!token.isContract()) {
            revert NotContract(token);
        }

        (bool successName, ) = token.staticcall(
            abi.encodeWithSignature("name()")
        );
        if (!successName) {
            revert NotERC20(token);
        }

        (bool successBalanceOf, ) = token.staticcall(
            abi.encodeWithSignature("balanceOf(address)", address(1))
        );
        if (!successBalanceOf) {
            revert NotERC20(token);
        }
    }

    function enforceIsContractOwner() internal view {
        address address_ = LibContext.msgSender();

        if (address_ != getOwner()) {
            revert NotOwner(address_);
        }
    }

    function getOwner() internal view returns (address adminAddress) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.9;

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
library LibContext {
    function msgSender() internal view returns (address) {
        return msg.sender;
    }

    function msgData() internal view returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {LibDiamond} from "contracts-starter/contracts/libraries/LibDiamond.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

library LibDiamondExtras {
    function setERC165(bytes4 interfaceId) internal {
        bytes4[] memory interfaceIds = new bytes4[](1);

        interfaceIds[0] = interfaceId;
        setERC165(interfaceIds, new bytes4[](0));
    }

    function setERC165(bytes4[] memory interfaceIds) internal {
        setERC165(interfaceIds, new bytes4[](0));
    }

    function setERC165(
        bytes4[] memory interfaceIds,
        bytes4[] memory interfaceIdsToRemove
    ) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.supportedInterfaces[type(IERC165).interfaceId] = true;

        for (uint256 i = 0; i < interfaceIds.length; i++) {
            ds.supportedInterfaces[interfaceIds[i]] = true;
        }

        for (uint256 i = 0; i < interfaceIdsToRemove.length; i++) {
            ds.supportedInterfaces[interfaceIdsToRemove[i]] = false;
        }
    }

    /**
     * @dev Returns the address of the facet that implements `selector`.
     */
    function getFacetBySelector(bytes4 selector)
        internal
        view
        returns (address facet)
    {
        // get diamond storage
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // get facet from function selector
        facet = ds.selectorToFacetAndPosition[selector].facetAddress;
    }

    /**
     * @dev Delegates the call to the facet implementing `selector`.
     */
    function delegate(bytes4 selector) internal {
        address facet = getFacetBySelector(selector);

        require(facet != address(0), "Diamond: Function does not exist");

        delegate(facet);
    }

    /**
     * @dev Delegates the call to the `facet`.
     */
    function delegate(address facet) internal {
        // Execute external function from facet using delegatecall and return any value.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

interface INodeTypes {
    struct NodeType {
        // Unique node type id
        uint256 id;
        // Machine readable name. (Can be used as a string id to map l18n)
        string name;
        // Purchase price nominated in solo-token.
        uint256 price;
        // Price in stable coin. (price*39/100)*tokenPrice/10**18.
        uint256 stablePrice;
    }

    /**
     * @dev Emitted when a new node type was created.
     */
    event NodeTypeCreated(uint256 indexed id, string name, uint256 price);

    /**
     * @dev Emitted when node type `id` was updated.
     */
    event NodeTypeUpdated(uint256 indexed id, string name, uint256 price);

    error NodeTypeNotFound(uint256 typeId);

    /**
     * @dev Creates a Node Type.
     */
    function createNodeType(INodeTypes.NodeType memory nodeType)
        external
        returns (uint256);

    /**
     * @dev Updates an existing node type.
     */
    function updateNodeType(INodeTypes.NodeType memory nodeType) external;

    /**
     * @dev Returns a list of all node types.
     */
    function getNodeTypes() external view returns (NodeType[] memory);

    /**
     * @dev Returns the node type with `id`.
     */
    function getNodeType(uint256 id) external view returns (NodeType memory);

    /**
     * Returns the total count of Node Types
     */
    function getNodeTypeIds() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {INodeTypes} from "../interfaces/INodeTypes.sol";

/**
 * @dev Library for managing node types.
 */
library LibNodeTypes {
    struct Storage {
        mapping(uint256 => INodeTypes.NodeType) nodeTypes;
        uint256[] nodeTypeIds;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.nodes.LibNodeTypes");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Emitted when a new node type was created.
     */
    event NodeTypeCreated(uint256 indexed id, string name, uint256 price);

    /**
     * @dev Emitted when node type `id` was updated.
     */
    event NodeTypeUpdated(uint256 indexed id, string name, uint256 price);

    function enforceNodeTypeExists(uint256 id) internal view {
        if (_storage().nodeTypes[id].id != id) {
            revert INodeTypes.NodeTypeNotFound(id);
        }
    }

    /**
     * @dev Creates a new node type.
     */
    function createNodeType(INodeTypes.NodeType memory nodeType)
        internal
        returns (uint256 typeId)
    {
        typeId = _storage().nodeTypeIds.length + 1;

        nodeType.id = typeId;

        _storage().nodeTypes[typeId] = nodeType;
        _storage().nodeTypeIds.push(typeId);

        emit NodeTypeCreated(nodeType.id, nodeType.name, nodeType.price);
    }

    /**
     * @dev Updates an existing node type
     */
    function updateNodeType(INodeTypes.NodeType memory nodeType) internal {
        enforceNodeTypeExists(nodeType.id);

        _storage().nodeTypes[nodeType.id] = nodeType;
    }

    /**
     * @dev Update the `stablePrice` for node type with `id`.
     */
    function updateStablePrice(uint256 id, uint256 stablePrice) internal {
        enforceNodeTypeExists(id);

        _storage().nodeTypes[id].stablePrice = stablePrice;
    }

    /**
     * @dev Returns a list of all node types.
     * @return nodeTypes array of Node Types
     */
    function getNodeTypes()
        internal
        view
        returns (INodeTypes.NodeType[] memory)
    {
        require(_storage().nodeTypeIds.length >= 1, "No Node types");

        INodeTypes.NodeType[] memory nodeTypes = new INodeTypes.NodeType[](
            _storage().nodeTypeIds.length
        );
        for (uint256 i = 1; i <= _storage().nodeTypeIds.length; i++) {
            INodeTypes.NodeType storage nodeType = _storage().nodeTypes[i];
            nodeTypes[i - 1] = nodeType;
        }
        return nodeTypes;
    }

    /**
     * @dev Returns the node type with `id`.
     * @return nodeType Node Type
     */
    function getNodeType(uint256 id)
        internal
        view
        returns (INodeTypes.NodeType storage nodeType)
    {
        nodeType = _storage().nodeTypes[id];

        if (nodeType.id < 1 || nodeType.id != id) {
            revert INodeTypes.NodeTypeNotFound(id);
        }
    }

    /**
     * @dev nodeTypeIds the total count of Node Types.
     * @return nodeTypeIds
     */
    function getNodeTypeIds()
        internal
        view
        returns (uint256[] memory nodeTypeIds)
    {
        nodeTypeIds = _storage().nodeTypeIds;
    }

    /**
     * @dev Returns the price of a node type.
     */
    function getPrice(uint256 id) internal view returns (uint256 price) {
        price = getNodeType(id).price;
    }

    /**
     * @dev Returns the price of a node type.
     */
    function getStablesPrice(uint256 id) internal view returns (uint256 price) {
        price = getNodeType(id).stablePrice;
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {LibContext} from "../../libraries/LibContext.sol";
import {LibDiamondExtras} from "../diamond/LibDiamondExtras.sol";
import {LibTokenTaxes} from "../token-taxes/LibTokenTaxes.sol";
import {LibTokenReflections} from "../token-reflections/LibTokenReflections.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC1820Registry} from "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC777} from "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import {IERC777Recipient} from "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import {IERC777Sender} from "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";

/**
 * @dev Library based on the OpenZeppelin ERC777.
 *
 * Support for ERC20 is included in this contract, as specified by the EIP.
 * If the token should be only a ERC20, then the ERC20Facet should be used
 * instead of the ERC777Facet.
 *
 * See: https://docs.openzeppelin.com/contracts/4.x/api/token/erc777
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC777/ERC777.sol
 */
library LibSoloToken {
    using Address for address;

    IERC1820Registry internal constant ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    bytes32 private constant TOKENS_SENDER_INTERFACE_HASH =
        keccak256("ERC777TokensSender");
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    struct Storage {
        mapping(address => uint256) balances;
        uint256 totalSupply;
        string name;
        string symbol;
        // This isn't ever read from - it's only used to respond to the defaultOperators query.
        address[] defaultOperatorsArray;
        // Immutable, but accounts may revoke them (tracked in revokedDefaultOperators).
        mapping(address => bool) defaultOperators;
        // For each account, a mapping of its operators and revoked default operators.
        mapping(address => mapping(address => bool)) operators;
        mapping(address => mapping(address => bool)) revokedDefaultOperators;
        // ERC20-allowances
        mapping(address => mapping(address => uint256)) allowances;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.solo-token.LibSoloToken");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(
        address indexed operator,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(
        address indexed operator,
        address indexed from,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(
        address indexed operator,
        address indexed tokenHolder
    );

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(
        address indexed operator,
        address indexed tokenHolder
    );

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    function init(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_,
        bool onlyERC20
    ) internal {
        _storage().name = name_;
        _storage().symbol = symbol_;

        if (defaultOperators_.length > 0) {
            setDefaultOperators(defaultOperators_);
        }

        LibDiamondExtras.setERC165(type(IERC20).interfaceId);

        if (!onlyERC20) {
            LibDiamondExtras.setERC165(type(IERC777).interfaceId);
            register1820();
        }
    }

    function setDefaultOperators(address[] memory defaultOperators_) internal {
        _storage().defaultOperatorsArray = defaultOperators_;

        for (uint256 i = 0; i < defaultOperators_.length; i++) {
            _storage().defaultOperators[defaultOperators_[i]] = true;
        }
    }

    function register1820() internal {
        ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            keccak256("ERC777Token"),
            address(this)
        );
        ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            keccak256("ERC20Token"),
            address(this)
        );
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() internal view returns (string memory) {
        return _storage().name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() internal view returns (string memory) {
        return _storage().symbol;
    }

    /**
     * @dev See {IERC777-totalSupply}.
     */
    function totalSupply() internal view returns (uint256) {
        return _storage().totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by an `account`.
     */
    function balanceOf(address account) internal view returns (uint256) {
        return _storage().balances[account];
    }

    /**
     * @dev See {IERC777-isOperatorFor}.
     */
    function isOperatorFor(address operator, address tokenHolder)
        internal
        view
        returns (bool)
    {
        return
            operator == tokenHolder ||
            (_storage().defaultOperators[operator] &&
                !_storage().revokedDefaultOperators[tokenHolder][operator]) ||
            _storage().operators[tokenHolder][operator];
    }

    /**
     * @dev See {IERC777-authorizeOperator}.
     */
    function authorizeOperator(address operator) internal {
        // solhint-disable-next-line reason-string
        require(
            LibContext.msgSender() != operator,
            "ERC777: authorizing self as operator"
        );

        if (_storage().defaultOperators[operator]) {
            delete _storage().revokedDefaultOperators[LibContext.msgSender()][
                operator
            ];
        } else {
            _storage().operators[LibContext.msgSender()][operator] = true;
        }

        emit AuthorizedOperator(operator, LibContext.msgSender());
    }

    /**
     * @dev See {IERC777-revokeOperator}.
     */
    function revokeOperator(address operator) internal {
        // solhint-disable-next-line reason-string
        require(
            operator != LibContext.msgSender(),
            "ERC777: revoking self as operator"
        );

        if (_storage().defaultOperators[operator]) {
            _storage().revokedDefaultOperators[LibContext.msgSender()][
                operator
            ] = true;
        } else {
            delete _storage().operators[LibContext.msgSender()][operator];
        }

        emit RevokedOperator(operator, LibContext.msgSender());
    }

    /**
     * @dev See {IERC777-defaultOperators}.
     */
    function defaultOperators() internal view returns (address[] memory) {
        return _storage().defaultOperatorsArray;
    }

    /**
     * @dev See {IERC777-operatorSend}.
     *
     * Emits {Sent} and {IERC20-Transfer} events.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) internal {
        // solhint-disable-next-line reason-string
        require(
            isOperatorFor(LibContext.msgSender(), sender),
            "ERC777: caller is not an operator for holder"
        );
        send(sender, recipient, amount, data, operatorData, true);
    }

    /**
     * @dev See {IERC777-operatorBurn}.
     *
     * Emits {Burned} and {IERC20-Transfer} events.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) internal {
        // solhint-disable-next-line reason-string
        require(
            isOperatorFor(LibContext.msgSender(), account),
            "ERC777: caller is not an operator for holder"
        );
        burn(account, amount, data, operatorData, true);
    }

    /**
     * @dev See {IERC20-allowance}.
     *
     * Note that operator and allowance concepts are orthogonal: operators may
     * not have allowance, and accounts with allowance may not be operators
     * themselves.
     */
    function allowance(address holder, address spender)
        internal
        view
        returns (uint256)
    {
        if (holder == spender) {
            return type(uint256).max;
        }

        return _storage().allowances[holder][spender];
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `operator`, `data` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {IERC20-Transfer} events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal {
        mint(account, amount, userData, operatorData, true);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If `requireReceptionAck` is set to true, and if a send hook is
     * registered for `account`, the corresponding function will be called with
     * `operator`, `data` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {IERC20-Transfer} events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal {
        require(account != address(0), "ERC777: mint to the zero address");

        address operator = LibContext.msgSender();

        beforeTokenTransfer(operator, address(0), account, amount);

        // Update state variables
        _storage().totalSupply += amount;
        _storage().balances[account] += amount;

        // Notify token-reflections module abou the increased balance.
        LibTokenReflections.accountBalanceUpdated(account);

        _callTokensReceived(
            operator,
            address(0),
            account,
            amount,
            userData,
            operatorData,
            requireReceptionAck
        );

        emit Minted(operator, account, amount, userData, operatorData);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Send tokens
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function send(
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal {
        // solhint-disable-next-line reason-string
        require(from != address(0), "ERC777: transfer from the zero address");
        // solhint-disable-next-line reason-string
        require(to != address(0), "ERC777: transfer to the zero address");

        address operator = LibContext.msgSender();

        // TODO: Get rid of the hardcoded calls to LibTokenReflections, in favor of the hook system.
        // Pay token taxes if needed.
        amount = LibTokenTaxes.payTaxes(from, to, amount);

        _callTokensToSend(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            requireReceptionAck
        );

        _move(operator, from, to, amount, userData, operatorData);

        _callTokensReceived(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            requireReceptionAck
        );
    }

    /**
     * @dev Burn tokens
     * @param from address token holder address
     * @param amount uint256 amount of tokens to burn
     * @param data bytes extra information provided by the token holder
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function burn(
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal {
        // solhint-disable-next-line reason-string
        require(from != address(0), "ERC777: burn from the zero address");

        address operator = LibContext.msgSender();

        _callTokensToSend(
            operator,
            from,
            address(0),
            amount,
            data,
            operatorData,
            requireReceptionAck
        );

        beforeTokenTransfer(operator, from, address(0), amount);

        // Update state variables
        uint256 fromBalance = _storage().balances[from];
        // solhint-disable-next-line reason-string
        require(fromBalance >= amount, "ERC777: burn amount exceeds balance");
        unchecked {
            _storage().balances[from] = fromBalance - amount;
        }
        _storage().totalSupply -= amount;

        // Notify token-reflections module abou the decreased balance.
        LibTokenReflections.accountBalanceUpdated(from);

        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }

    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        beforeTokenTransfer(operator, from, to, amount);

        uint256 fromBalance = _storage().balances[from];
        // solhint-disable-next-line reason-string
        require(
            fromBalance >= amount,
            "ERC777: transfer amount exceeds balance"
        );
        unchecked {
            _storage().balances[from] = fromBalance - amount;
        }
        _storage().balances[to] += amount;

        // TODO: Get rid of the hardcoded calls to LibTokenReflections, in favor of the hook system.

        // Notify token-reflections module about the decreased balance.
        LibTokenReflections.accountBalanceUpdated(from);
        // Notify token-reflections module about the increased balance.
        LibTokenReflections.accountBalanceUpdated(to);

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    /**
     * @dev See {ERC20-_approve}.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function approve(
        address holder,
        address spender,
        uint256 value
    ) internal {
        // solhint-disable-next-line reason-string
        require(holder != address(0), "ERC777: approve from the zero address");
        // solhint-disable-next-line reason-string
        require(spender != address(0), "ERC777: approve to the zero address");

        _storage().allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    /**
     * @dev Call from.tokensToSend() if the interface is registered
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) private {
        if (!requireReceptionAck) {
            return;
        }
        address implementer = ERC1820_REGISTRY.getInterfaceImplementer(
            from,
            TOKENS_SENDER_INTERFACE_HASH
        );
        if (implementer != address(0)) {
            IERC777Sender(implementer).tokensToSend(
                operator,
                from,
                to,
                amount,
                userData,
                operatorData
            );
        }
    }

    /**
     * @dev Call to.tokensReceived() if the interface is registered. Reverts if the recipient is a contract but
     * tokensReceived() was not registered for the recipient
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) private {
        if (!requireReceptionAck) {
            return;
        }

        address implementer = ERC1820_REGISTRY.getInterfaceImplementer(
            to,
            TOKENS_RECIPIENT_INTERFACE_HASH
        );
        if (implementer != address(0)) {
            IERC777Recipient(implementer).tokensReceived(
                operator,
                from,
                to,
                amount,
                userData,
                operatorData
            );
        } else if (requireReceptionAck) {
            // solhint-disable-next-line reason-string
            require(
                !to.isContract(),
                "ERC777: token recipient contract has no implementer for ERC777TokensRecipient"
            );
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC777: insufficient allowance"
            );
            unchecked {
                approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes
     * calls to {send}, {transfer}, {operatorSend}, minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount // solhint-disable-next-line no-empty-blocks
    ) internal {
        // TODO: Call tax module
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenDitributor {
    struct Distribution {
        // Receiver of the distribution
        address destination;
        // If set, the distributed token should be swapped to to this token before sending.
        address swapTo;
        // Proportion of the total amount of the strategy.
        // Must be a multiple of 100.
        // Sum from all proportions of a strategy must be equal 100% (10000).
        uint16 proportion;
        // If set, the distributed and `swapTo` tokens should be added to liquidity.
        // The minted LP token will be sent to the `destination`.
        bool addLiquidity;
    }

    struct Strategy {
        // Token to be distributed
        address token;
        // If set, `token` should be swapped to this token before disributing.
        address swapTo;
        Distribution[] distributions;
    }

    /**
     * @dev Returns the strategy with `strategyId`.
     *
     * @param strategyId Id of the distribution strategy.
     *
     * @return strategy The stored strategy.
     */
    function getTokenDistributionStrategy(bytes32 strategyId)
        external
        view
        returns (Strategy memory);
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {ITokenDitributor} from "./ITokenDitributor.sol";
import {LibContext} from "../../libraries/LibContext.sol";
import {LibNodeTypes} from "../nodes/libraries/LibNodeTypes.sol";
import {LibSoloToken} from "../solo-token/LibSoloToken.sol";
import {LibUniswap} from "../uniswap/LibUniswap.sol";
import {LibTokenReflections} from "../token-reflections/LibTokenReflections.sol";
import {LibUtils} from "@solarprotocol/presale/contracts/LibUtils.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Library that implements a universally configurable token distributer.
 */
library LibTokenDistributor {
    using SafeERC20 for IERC20;

    struct Storage {
        mapping(bytes32 => ITokenDitributor.Strategy) strategyMap;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256(
            "solarprotocol.contracts.token-distributor.LibTokenDistributor.V2"
        );

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    error StrategyAlreadyExists(bytes32 id);
    error StrategyHasNoDistributions();
    error StrategyDistributionPortionsNot100();
    error StrategyDistributionsLengthMissmatch();
    error StrategyNotFound(bytes32 id);

    /**
     * @dev Takes `amount` of `strategy.token` from `from` and distributes it among `strategy.distributions`.
     * Based on configuration, allows for automatic swapping and/or adding LP on Uniswap V2 based DEXes
     * @notice Because of Uniswap limitations, Swaps of `address(this)` (solo-token) will not work during buys.
     * And for swaps of `address(this)` in general the `intermediateWallet` must be configured in LibUniswap.
     *
     * @param strategyId Id of the distribution strategy.
     * @param from Source of tokens for the disribution.
     * @param amount The amount of tokens to distribute.
     */
    function distribute(
        bytes32 strategyId,
        address from,
        uint256 amount
    ) internal {
        ITokenDitributor.Strategy memory strategy = get(strategyId);

        address token = strategy.token;

        // First transfer the amount of token to the contract,
        // to make all other operations easier and comprehensible on the block scanner.
        if (from != address(this)) {
            sendToken(token, from, address(this), amount, address(0), false);
        }

        // Swap the token to `strategy.swapTo` if configured.
        if (strategy.swapTo != address(0)) {
            amount = LibUniswap.swap(
                amount,
                address(token),
                strategy.swapTo,
                address(this)
            );
            token = strategy.swapTo;
        }

        uint256 strategyDistributionsLength = strategy.distributions.length;
        for (uint256 index = 0; index < strategyDistributionsLength; ) {
            ITokenDitributor.Distribution memory distribution = strategy
                .distributions[index];

            // TODO: Get rid of the hardcoded calls to LibTokenReflections, in favor of the hook system.

            bool isReflectionVault = LibTokenReflections.isRewardsTokenVault(
                distribution.destination
            );

            if (isReflectionVault) {
                // Snapshot the current token balance in the reflections vault for later calculation of added amount.
                LibTokenReflections.updateRewardsTokenVaultBalance();
            }

            sendToken(
                token,
                address(this),
                distribution.destination,
                (amount * distribution.proportion) / 10000,
                distribution.swapTo,
                distribution.addLiquidity
            );

            if (isReflectionVault) {
                // Calculate the amount of rewards tokens added to the reflection vault and can be added to the pool.
                LibTokenReflections.updateRewardsAmountPendingInVault();

                // Add pending amount of new reward tokens in vault, to the pool if needed.
                LibTokenReflections.addRewardsAmountPending();
            }

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @dev Sends the provided `amount` of `token` from `from` to `to`.
     * Integrates with LibUniswap to allow for swapping to another token before sending.
     * Additionally it can zapIn liquidity to the token/swapTo pair. In this case it will send the LP token to the destination.
     * If the provided token is `address(this)` and `swapTo` is not set, it will use LibSoloToken for sending.
     *
     * @param token Token to be transfered.
     * @param from Address to transfer `token` from.
     * @param to Recepient of the tokens.
     * @param amount The amount to transfer.
     * @param swapTo If set, will be used as tokenB to swap `token` directly to `to`.
     * @param addLiquidity If set, will zapIn to `token`/`swapTo` pair and mint LP token to `to`.
     *
     * @return amountOut Amount of tokens sent to `to`.
     */
    function sendToken(
        address token,
        address from,
        address to,
        uint256 amount,
        address swapTo,
        bool addLiquidity
    ) internal returns (uint256 amountOut) {
        if (swapTo == address(0)) {
            amountOut = amount;

            if (address(token) == address(this)) {
                // solhint-disable-next-line check-send-result
                LibSoloToken.send(from, to, amount, "", "", false);
            } else {
                IERC20(token).safeTransferFrom(from, to, amount);
            }
        } else {
            if (addLiquidity) {
                (, , amountOut) = LibUniswap.zapInLiquidity(
                    address(token),
                    swapTo,
                    amount,
                    to
                );
            } else {
                amountOut = LibUniswap.swap(amount, address(token), swapTo, to);
            }
        }
    }

    /**
     * @dev Returns the strategy with `strategyId`.
     *
     * @param strategyId Id of the distribution strategy.
     *
     * @return strategy The stored strategy.
     */
    function get(bytes32 strategyId)
        internal
        view
        returns (ITokenDitributor.Strategy memory strategy)
    {
        strategy = _storage().strategyMap[strategyId];

        if (strategy.distributions.length == 0) {
            revert StrategyNotFound(strategyId);
        }
    }

    /**
     * @dev Adds new `strategy`with `strategyId`.
     *
     * @param strategyId Id of the distribution strategy.
     * @param strategy The strategy struct to be stored.
     */
    function add(bytes32 strategyId, ITokenDitributor.Strategy memory strategy)
        internal
    {
        Storage storage s = _storage();

        if (address(s.strategyMap[strategyId].token) != address(0)) {
            revert StrategyAlreadyExists(strategyId);
        }

        if (strategy.distributions.length == 0) {
            revert StrategyHasNoDistributions();
        }

        setStrategyToken(strategyId, strategy.token);
        setStrategySwapTo(strategyId, strategy.swapTo);

        uint256 sum = 0;
        for (
            uint256 index = 0;
            index < strategy.distributions.length;
            ++index
        ) {
            ITokenDitributor.Distribution memory distribution = strategy
                .distributions[index];

            if (
                distribution.swapTo != address(0) &&
                distribution.swapTo != address(this)
            ) {
                LibUtils.validateERC20(distribution.swapTo);
            }

            sum += distribution.proportion;
            s.strategyMap[strategyId].distributions.push(distribution);
        }

        if (sum != 10000) {
            revert StrategyDistributionPortionsNot100();
        }
    }

    function setStrategyToken(bytes32 strategyId, address token) internal {
        if (token != address(this)) {
            LibUtils.validateERC20(token);
        }

        _storage().strategyMap[strategyId].token = token;
    }

    function setStrategySwapTo(bytes32 strategyId, address swapTo) internal {
        if (swapTo != address(0) && swapTo != address(this)) {
            LibUtils.validateERC20(swapTo);
        }

        _storage().strategyMap[strategyId].swapTo = swapTo;
    }

    /**
     * @dev Update the distributions of the existing strategy with `strategyId`.
     *
     * @param strategyId Id of the distribution strategy.
     * @param distributions The destinations struct to be stored.
     */
    function updateDistributions(
        bytes32 strategyId,
        ITokenDitributor.Distribution[] memory distributions
    ) internal {
        ITokenDitributor.Strategy memory strategy = _storage().strategyMap[
            strategyId
        ];

        if (address(strategy.token) == address(0)) {
            revert StrategyNotFound(strategyId);
        }

        if (distributions.length == 0) {
            revert StrategyHasNoDistributions();
        }

        if (strategy.distributions.length != distributions.length) {
            revert StrategyDistributionsLengthMissmatch();
        }

        uint256 sum = 0;
        for (uint256 index = 0; index < distributions.length; ++index) {
            ITokenDitributor.Distribution memory distribution = strategy
                .distributions[index];

            if (
                distribution.swapTo != address(0) &&
                distribution.swapTo != address(this)
            ) {
                LibUtils.validateERC20(distribution.swapTo);
            }

            sum += distribution.proportion;
            _storage().strategyMap[strategyId].distributions[
                index
            ] = distribution;
        }

        if (sum != 10000) {
            revert StrategyDistributionPortionsNot100();
        }
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

interface ITokenReflections {
    struct ReflectionsInfoResponse {
        address rewardsTokenVault;
        // Kill switch to enable/disable the module
        bool enabled;
        // If set, will prevent the rewards from being added more often than the set duration
        bool enforceDuration;
        // Timestamp of when the rewards finish
        uint32 finishedAt;
        // Minimum of last updated time and reward finish time
        uint32 updatedAt;
        // Duration of rewards to be paid out (in seconds)
        uint32 duration;
        // Reward to be paid out per second
        uint256 rewardRate;
        // Sum of (reward rate * dt * 1e18 / total supply)
        uint256 rewardsPerTokenStored;
        // Total staked
        uint256 totalSupply;
        // Temporary storage for the `rewardsToken` balance of the `rewardsTokenVault`
        uint256 rewardsTokenVaultBalance;
        // Amount of rewards pending in the `rewardsTokenVault` to be added to distribution
        uint256 rewardsAmountPendingInVault;
        // Total amount of rewards ever added
        uint256 totalRewardsAdded;
        // Total amount of rewards ever claimed
        uint256 totalRewardsClaimed;
    }

    error TokenReflectionsRewardDurationNotFinished();
    error TokenReflectionsRewardRewardRateIsZero();
    error TokenReflectionsRewardsBalanceTooLow();

    /**
     * @dev Emitted when the token-taxes module is enabled.
     */
    event TokenReflectionsEnabled();

    /**
     * @dev Emitted when the token-taxes module is disabled.
     */
    event TokenReflectionsDisabled();

    /**
     * @dev Emitted when the `rewardsToken` is updated.
     */
    event TokenReflectionsRewardsTokenUpdated(address rewardsToken);

    /**
     * @dev Emitted when the `rewardsTokenVault` is updated.
     */
    event TokenReflectionsRewardsTokenVaultUpdated(address rewardsTokenVault);

    /**
     * @dev Emitted when new rewards are added to the rewards pool.
     */
    event TokenReflectionsRewardsAdded(uint256 amount);

    /**
     * @dev Emitted when the duration is updated.
     */
    event TokenReflectionsDurationUpdated(uint256 duration);

    /**
     * @dev Emitted when the exempt from reflection flag of `account` is set.
     */
    event TokenReflectionsSetExemptFlag(address account, bool flag);

    /**
     * @dev Emitted when the `enforceDuration` flag is set.
     */
    event TokenReflectionsSetEnforceDuration(bool flag);

    /**
     * @dev Claims the caller's pending rewards from the `rewardsTokenVault`.
     */
    function tokenReflectionsClaimRewards() external;

    /**
     * @dev Returns the amount of rewards the `account` can claim.
     *
     * @param account Address of the account.
     *
     * @return rewards Amount of rewards the `account` can claim.
     */
    function tokenReflectionsRewardsOf(address account)
        external
        view
        returns (uint256 rewards);

    /**
     * @dev Returns the total amount of tokens added as rewards.
     *
     * @return totalRewardsAdded Total amount of tokens added as rewards.
     */
    function tokenReflectionsGetTotalRewardsAdded()
        external
        view
        returns (uint256 totalRewardsAdded);

    /**
     * @dev Returns the total amount of rewards claimed by all users.
     *
     * @return totalRewardsClaimed Total amount of rewards claimed by all users.
     */
    function tokenReflectionsGetTotalRewardsClaimed()
        external
        view
        returns (uint256 totalRewardsClaimed);

    /**
     * @dev Returns the total amount of rewards `account` has claimed.
     *
     * @param account The account to get the claimed amount for.
     *
     * @return userRewardsClaimed Total amount of rewards `account` has ever claimed.
     */
    function tokenReflectionsGetUserRewardsClaimed(address account)
        external
        view
        returns (uint256 userRewardsClaimed);

    /**
     * @dev Returns true if the token-reflections module is enabled.
     */
    function tokenReflectionsIsEnabled() external view returns (bool enabled);

    /**
     * @dev Enables the token-reflections module.
     * Emits an {TokenTaxesEnabled} event.
     */
    function tokenReflectionsEnable() external;

    /**
     * @dev Disables the token-reflections module
     * Emits an {TokenTaxesDisabled} event.
     */
    function tokenReflectionsDisable() external;

    /**
     * @dev Checks if `account` is exempt from reflections.
     *
     * @return True if `account` is exempt from reflections.
     */
    function tokenReflectionsIsExemptFromReflections(address account)
        external
        view
        returns (bool);

    /**
     * @dev Sets the `account`'s exempt from reflection status to `flag`.
     * Emits an {TokenReflectionsSetExemptFlag} event.
     *
     * @param account The account to set the `flag` for.
     * @param flag The status flag.
     */
    function tokenReflectionsSetExemptFromReflections(
        address account,
        bool flag
    ) external;

    /**
     * @dev Returns the current `rewardsToken`.
     *
     * @return rewardsToken Address of the currently stored rewardsToken.
     */
    function tokenReflectionsGetRewardsToken()
        external
        view
        returns (address rewardsToken);

    /**
     * @dev Returns the current `rewardsTokenVault`.
     *
     * @return rewardsTokenVault Address of the currently stored rewardsTokenVault.
     */
    function tokenReflectionsGetRewardsTokenVault()
        external
        view
        returns (address rewardsTokenVault);

    /**
     * @dev Returns an info response. Mainly for testing and debuggind.
     *
     * @return reflectionsInfoResponse An instance of the ITokenReflections.ReflectionsInfoResponse struct, with data from the storage.
     */
    function tokenReflectionsGetInfoResponse()
        external
        view
        returns (ITokenReflections.ReflectionsInfoResponse memory);

    /**
     * @dev Used by the manager to add rewards to the staking contract manualy.
     *
     * @param amount THe amount of reward token to add from the msg.sender balance to the rewards vault.
     */
    function tokenReflectionsAddRewards(uint256 amount) external;

    /**
     * @dev Returns the tracked staking balance of a user.
     *
     * @param account The address of the user account.
     *
     * @return balance The tracked staking balance of `account`.
     */
    function tokenReflectionsBalanceOf(address account)
        external
        view
        returns (uint256 balance);
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {ITokenReflections} from "./ITokenReflections.sol";
import {LibSoloToken} from "../solo-token/LibSoloToken.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev Library for the token-reflection module. It works like a virtual staking contract.
 * On each transaction the solo-token module notifies the `accountBalanceUpdated()` function
 * about the changed balances of each account, which will work like automatic staking/unstaking
 * if the account is not exempt from reflections, to update the account's rewards and the totalSupply.
 *
 * The library is based of Synthetix staking contract's simplified version (by https://twitter.com/ProgrammerSmart)
 * See: https://solidity-by-example.org/defi/staking-rewards/
 */
library LibTokenReflections {
    using SafeERC20 for IERC20;
    using Address for address;

    struct Storage {
        IERC20 rewardsToken;
        address rewardsTokenVault;
        // Kill switch to enable/disable the module
        bool enabled;
        // If set, will prevent the rewards from being added more often than the set duration
        bool enforceDuration;
        // Timestamp of when the rewards finish
        uint32 finishedAt;
        // Minimum of last updated time and reward finish time
        uint32 updatedAt;
        // Duration of rewards to be paid out (in seconds)
        uint32 duration;
        // Reward to be paid out per second
        uint256 rewardRate;
        // Sum of (reward rate * dt * 1e18 / total supply)
        uint256 rewardsPerTokenStored;
        // Total staked
        uint256 totalSupply;
        // Temporary storage for the `rewardsToken` balance of the `rewardsTokenVault`
        uint256 rewardsTokenVaultBalance;
        // Amount of rewards pending in the `rewardsTokenVault` to be added to distribution
        uint256 rewardsAmountPendingInVault;
        // Total amount of rewards ever added
        uint256 totalRewardsAdded;
        // Total amount of rewards ever claimed
        uint256 totalRewardsClaimed;
        // Amount of staked tokens by a user
        mapping(address => uint256) balanceOf;
        // User address => rewardsPerTokenStored
        mapping(address => uint256) userRewardsPerTokenPaid; // User address => rewardsPerTokenStored
        // Total amount of rewards claimed by user
        mapping(address => uint256) userRewardsClaimed;
        // User address => rewards to be claimed
        mapping(address => uint256) rewards;
        // Mapping of addresses exempt from reflections.
        mapping(address => bool) exemptFromReflections;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.token-taxes.LibTokenReflections");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    error TokenReflectionsRewardDurationNotFinished();
    error TokenReflectionsRewardRewardRateIsZero();
    error TokenReflectionsRewardsBalanceTooLow();

    /**
     * @dev Emitted when the token-taxes module is enabled.
     */
    event TokenReflectionsEnabled();

    /**
     * @dev Emitted when the token-taxes module is disabled.
     */
    event TokenReflectionsDisabled();

    /**
     * @dev Emitted when the `rewardsToken` is updated.
     */
    event TokenReflectionsRewardsTokenUpdated(address rewardsToken);

    /**
     * @dev Emitted when the `rewardsTokenVault` is updated.
     */
    event TokenReflectionsRewardsTokenVaultUpdated(address rewardsTokenVault);

    /**
     * @dev Emitted when new rewards are added to the rewards pool.
     */
    event TokenReflectionsRewardsAdded(uint256 amount);

    /**
     * @dev Emitted when the duration is updated.
     */
    event TokenReflectionsDurationUpdated(uint256 duration);

    /**
     * @dev Emitted when the exempt from reflection flag of `account` is set.
     */
    event TokenReflectionsSetExemptFlag(address account, bool flag);

    /**
     * @dev Emitted when the `enforceDuration` flag is set.
     */
    event TokenReflectionsSetEnforceDuration(bool flag);

    /**
     * @dev Replacement of stake/unstake functions.
     * Called during token transfers to stake or unstake automatically.
     *
     * @param account Address of the account.
     */
    function accountBalanceUpdated(address account) internal {
        Storage storage s = _storage();

        if (!s.enabled) {
            return;
        }

        if (isExemptFromReflections(account)) {
            return;
        }

        uint256 stakedBalance = s.balanceOf[account];
        uint256 tokenBalance = LibSoloToken.balanceOf(account);

        if (tokenBalance > stakedBalance) {
            stake(account, tokenBalance - stakedBalance);
        } else if (stakedBalance > tokenBalance) {
            unstake(account, stakedBalance - tokenBalance);
        }
    }

    /**
     * @dev Stakes `amount` for `account`.
     *
     * @param account Address of the user account
     * @param amount The amount to stake
     */
    function stake(address account, uint256 amount) internal {
        Storage storage s = _storage();

        _updateRewards(account);

        s.balanceOf[account] += amount;
        s.totalSupply += amount;
    }

    /**
     * @dev Unstakes `amount` for `account`.
     *
     * @param account Address of the user account
     * @param amount The amount to unstake
     */
    function unstake(address account, uint256 amount) internal {
        Storage storage s = _storage();

        _updateRewards(account);

        s.balanceOf[account] -= amount;
        s.totalSupply -= amount;
    }

    /**
     * @dev Claims the `account`'s pending rewards from the `rewardsTokenVault` to the `account`.
     *
     * @param account Address of the account.
     */
    function claimRewards(address account) internal {
        Storage storage s = _storage();

        if (!s.enabled) {
            return;
        }

        _updateRewards(account);

        uint256 rewards = s.rewards[account];
        if (rewards > 0) {
            s.rewards[account] = 0;
            s.totalRewardsClaimed += rewards;
            s.userRewardsClaimed[account] += rewards;
            s.rewardsToken.safeTransferFrom(
                s.rewardsTokenVault,
                account,
                rewards
            );
        }
    }

    /**
     * @dev Returns the amount of rewards the `account` can claim.
     *
     * @param account Address of the account.
     *
     * @return rewards Amount of rewards the `account` can claim.
     */
    function rewardsOf(address account)
        internal
        view
        returns (uint256 rewards)
    {
        Storage storage s = _storage();

        rewards =
            ((s.balanceOf[account] *
                (rewardPerToken() - s.userRewardsPerTokenPaid[account])) /
                1e18) +
            s.rewards[account];
    }

    /**
     * @dev Returns the tracked staking balance of a user.
     *
     * @param account The address of the user account.
     *
     * @return balance The tracked staking balance of `account`.
     */
    function balanceOf(address account)
        internal
        view
        returns (uint256 balance)
    {
        balance = _storage().balanceOf[account];
    }

    /**
     * @dev Returns the last timestamp when rewards where applicable.
     * Current timestamp if the reward duration is not finished yet, `finishedAt` otherwise.
     *
     * @return timestamp The smaller of the 2 timestamps.
     */
    function lastTimeRewardApplicable()
        internal
        view
        returns (uint32 timestamp)
    {
        // solhint-disable-next-line not-rely-on-time
        timestamp = uint32(block.timestamp % 2**32);
        uint32 finishedAt = _storage().finishedAt;

        if (finishedAt < timestamp) {
            timestamp = finishedAt;
        }
    }

    /**
     * @dev Calculates the reward amount per token.
     *
     * @return rewardPerToken The calculated rewardPerToken amount.
     */
    function rewardPerToken() internal view returns (uint256) {
        Storage storage s = _storage();

        if (s.totalSupply == 0) {
            return s.rewardsPerTokenStored;
        }

        return
            s.rewardsPerTokenStored +
            (s.rewardRate * (lastTimeRewardApplicable() - s.updatedAt) * 1e18) /
            s.totalSupply;
    }

    /**
     * @dev Stores the current `rewardsToken` balance of the `rewardsTokenVault` in `rewardsTokenVaultBalance`.
     * Should be called before tokens are sent to the `rewardsTokenVault`.
     */
    function updateRewardsTokenVaultBalance() internal {
        Storage storage s = _storage();

        if (!s.enabled) {
            return;
        }

        s.rewardsTokenVaultBalance = s.rewardsToken.balanceOf(
            s.rewardsTokenVault
        );
    }

    /**
     * @dev Calculates the `rewardsAmountPendingInVault` by subtracting `rewardsTokenVaultBalance`
     * from the current `rewardsToken` balance of the `rewardsTokenVault`.
     * Should be called after tokens are sent to the `rewardsTokenVault`.
     */
    function updateRewardsAmountPendingInVault() internal {
        Storage storage s = _storage();

        if (!s.enabled) {
            return;
        }

        s.rewardsAmountPendingInVault +=
            s.rewardsToken.balanceOf(s.rewardsTokenVault) -
            s.rewardsTokenVaultBalance;

        s.rewardsTokenVaultBalance = 0;
    }

    /**
     * @dev Adds the `rewardsAmountPendingInVault` to the rewards pool.
     * Better to call after `updateRewardsAmountPendingInVault()`, but not mandatory.
     */
    function addRewardsAmountPending() internal {
        Storage storage s = _storage();

        uint256 amount = s.rewardsAmountPendingInVault;
        // solhint-disable-next-line not-rely-on-time
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);

        // Ensure that there is an amount to be added and last duration period expired (if configured so).
        if (
            !s.enabled ||
            amount == 0 ||
            (s.enforceDuration && blockTimestamp < s.finishedAt)
        ) {
            return;
        }

        _updateRewards(address(0));

        if (blockTimestamp >= s.finishedAt) {
            s.rewardRate = amount / s.duration;
        } else {
            uint256 remainingRewards = (s.finishedAt - blockTimestamp) *
                s.rewardRate;
            s.rewardRate = (amount + remainingRewards) / s.duration;
        }

        if (s.rewardRate == 0) {
            revert TokenReflectionsRewardRewardRateIsZero();
        }

        if (
            s.rewardRate * s.duration >
            s.rewardsToken.balanceOf(s.rewardsTokenVault)
        ) {
            revert TokenReflectionsRewardsBalanceTooLow();
        }

        s.totalRewardsAdded += amount;
        s.rewardsAmountPendingInVault = 0;
        s.finishedAt = blockTimestamp + s.duration;
        s.updatedAt = blockTimestamp;

        emit TokenReflectionsRewardsAdded(amount);
    }

    /**
     * @dev Returns true if the token-reflections module is enabled.
     */
    function isEnabled() internal view returns (bool enabled) {
        enabled = _storage().enabled;
    }

    /**
     * @dev Enables the token-reflections module.
     * Emits an {TokenTaxesEnabled} event.
     */
    function enable() internal {
        _storage().enabled = true;

        emit TokenReflectionsEnabled();
    }

    /**
     * @dev Disables the token-reflections module
     * Emits an {TokenTaxesDisabled} event.
     */
    function disable() internal {
        _storage().enabled = false;

        emit TokenReflectionsDisabled();
    }

    /**
     * Updates the duration of rewards distribution.
     * Emits an {TokenReflectionsDurationUpdated} event.
     *
     * @param duration The new duration.
     */
    function setRewardsDuration(uint32 duration) internal {
        Storage storage s = _storage();

        // solhint-disable-next-line not-rely-on-time
        if (s.finishedAt >= block.timestamp) {
            revert TokenReflectionsRewardDurationNotFinished();
        }

        s.duration = duration;

        emit TokenReflectionsDurationUpdated(duration);
    }

    /**
     * @dev Checks if `account` is exempt from reflections.
     *
     * @return True if `account` is exempt from reflections.
     */
    function isExemptFromReflections(address account)
        internal
        view
        returns (bool)
    {
        return
            account == address(this) ||
            _storage().exemptFromReflections[account] ||
            account.isContract();
    }

    /**
     * @dev Sets the `account`'s exempt from reflection status to `flag`.
     * Emits an {TokenReflectionsSetExemptFlag} event.
     *
     * @param account The account to set the `flag` for.
     * @param flag The status flag.
     */
    function setExemptFromReflections(address account, bool flag) internal {
        Storage storage s = _storage();

        if (flag) {
            unstake(account, s.balanceOf[account]);
        } else {
            accountBalanceUpdated(account);
        }

        s.exemptFromReflections[account] = flag;

        emit TokenReflectionsSetExemptFlag(account, flag);
    }

    /**
     * @dev Updates the stored `rewardsToken`.
     * Emits an {TokenReflectionsRewardsTokenUpdated} event.
     *
     * @param rewardsToken Address of the rewardsToken.
     */
    function setRewardsToken(address rewardsToken) internal {
        _storage().rewardsToken = IERC20(rewardsToken);

        emit TokenReflectionsRewardsTokenUpdated(rewardsToken);
    }

    /**
     * @dev Returns the current `rewardsToken`.
     *
     * @return rewardsToken Address of the currently stored rewardsToken.
     */
    function getRewardsToken() internal view returns (address rewardsToken) {
        rewardsToken = address(_storage().rewardsToken);
    }

    /**
     * @dev Updates the stored `rewardsTokenVault`.
     * Emits an {TokenReflectionsRewardsTokenVaultUpdated} event.
     *
     * @param rewardsTokenVault Address of the rewardsTokenVault.
     */
    function setRewardsTokenVault(address rewardsTokenVault) internal {
        _storage().rewardsTokenVault = rewardsTokenVault;

        emit TokenReflectionsRewardsTokenVaultUpdated(rewardsTokenVault);
    }

    /**
     * @dev Returns true if `account` is the `rewardsTokenVault`.
     */
    function isRewardsTokenVault(address account) internal view returns (bool) {
        return account == _storage().rewardsTokenVault;
    }

    /**
     * @dev Returns the current `rewardsTokenVault`.
     *
     * @return rewardsTokenVault Address of the currently stored rewardsTokenVault.
     */
    function getRewardsTokenVault()
        internal
        view
        returns (address rewardsTokenVault)
    {
        rewardsTokenVault = _storage().rewardsTokenVault;
    }

    /**
     * @dev Sets the `enforceDuration` status to `flag`.
     * Emits an {TokenReflectionsSetEnforceDuration} event.
     *
     * @param flag The status flag.
     */
    function setEnforceDuration(bool flag) internal {
        _storage().enforceDuration = flag;

        emit TokenReflectionsSetEnforceDuration(flag);
    }

    /**
     * @dev Returns the total amount of tokens added as rewards.
     *
     * @return totalRewardsAdded Total amount of tokens added as rewards.
     */
    function getTotalRewardsAdded()
        internal
        view
        returns (uint256 totalRewardsAdded)
    {
        totalRewardsAdded = _storage().totalRewardsAdded;
    }

    /**
     * @dev Returns the total amount of rewards claimed by all users.
     *
     * @return totalRewardsClaimed Total amount of rewards claimed by all users.
     */
    function getTotalRewardsClaimed()
        internal
        view
        returns (uint256 totalRewardsClaimed)
    {
        totalRewardsClaimed = _storage().totalRewardsClaimed;
    }

    /**
     * @dev Returns the total amount of rewards `account` has claimed.
     *
     * @param account The account to get the claimed amount for.
     *
     * @return userRewardsClaimed Total amount of rewards `account` has ever claimed.
     */
    function getUserRewardsClaimed(address account)
        internal
        view
        returns (uint256 userRewardsClaimed)
    {
        userRewardsClaimed = _storage().userRewardsClaimed[account];
    }

    /**
     * @dev Returns an info response. Mainly for testing and debuggind.
     *
     * @return reflectionsInfoResponse An instance of the ITokenReflections.ReflectionsInfoResponse struct, with data from the storage.
     */
    function getReflectionsInfoResponse()
        internal
        view
        returns (ITokenReflections.ReflectionsInfoResponse memory)
    {
        Storage storage s = _storage();

        return
            ITokenReflections.ReflectionsInfoResponse({
                rewardsTokenVault: s.rewardsTokenVault,
                enabled: s.enabled,
                enforceDuration: s.enforceDuration,
                finishedAt: s.finishedAt,
                updatedAt: s.updatedAt,
                duration: s.duration,
                rewardRate: s.rewardRate,
                rewardsPerTokenStored: s.rewardsPerTokenStored,
                totalSupply: s.totalSupply,
                rewardsTokenVaultBalance: s.rewardsTokenVaultBalance,
                rewardsAmountPendingInVault: s.rewardsAmountPendingInVault,
                totalRewardsAdded: s.totalRewardsAdded,
                totalRewardsClaimed: s.totalRewardsClaimed
            });
    }

    /**
     * Updates the `account`'s rewards and `rewardsPerTokenStored`.
     *
     * @param account Address of the account.
     */
    function _updateRewards(address account) private {
        Storage storage s = _storage();

        s.rewardsPerTokenStored = rewardPerToken();
        s.updatedAt = lastTimeRewardApplicable();

        if (account != address(0)) {
            s.rewards[account] = rewardsOf(account);
            s.userRewardsPerTokenPaid[account] = s.rewardsPerTokenStored;
        }
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

interface ITokenTaxes {
    enum TaxType {
        Buy,
        Sell
    }

    // The taxes must be a multiple of 100
    struct Tax {
        string name;
        bytes32 tokenDitributorStrategyId;
        uint16 buy;
        uint16 sell;
    }

    struct TaxesInfoResponse {
        // Kill switch to enable/disable the token-tax module.
        bool enabled;
        // If enabled, the tax distribution will be triggered during sell transactions.
        bool distributeOnSell;
        // Last time the collected taxes have been distributed.
        uint32 distributedAt;
        // Amount of seconds between distributions.
        uint32 distributionPeriod;
        // Array with all tax names, to allow iteration.
        bytes32[] taxNames;
    }

    error TokenTaxNotFound(bytes32 taxName);
    error TokenTaxAlreadyExists(bytes32 taxName);

    /**
     * @dev Emitted when the token-taxes module is enabled.
     */
    event TokenTaxesEnabled();

    /**
     * @dev Emitted when the token-taxes module is disabled.
     */
    event TokenTaxesDisabled();

    /**
     * @dev Emitted when a token tax with `name` is set.
     */
    event TokenTaxSet(string name);

    /**
     * @dev Emitted when token tax with `taxName` is added to a `taxedAddress`.
     */
    event TokenTaxAdded(address taxedAddress, bytes32 taxName);

    /**
     * @dev Emitted when token tax with `taxName` is removed from a `taxedAddress`.
     */
    event TokenTaxRemoved(address taxedAddress, bytes32 taxName);

    /**
     * @dev Emitted when the exempt from taxes flag of `account` is set.
     */
    event TokenTaxSetExemptFlag(address account, bool flag);

    /**
     * @dev Returns a tax by it's string name.
     *
     * @dev name Tax name as a string.
     *
     * @return tax The found tax.
     */
    function getTokenTax(string memory name)
        external
        view
        returns (Tax memory tax);

    /**
     * @dev Returns a tax by it's bytes32 name.
     *
     * @dev name Tax name as bytes32.
     *
     * @return tax The found tax.
     */
    function getTokenTax(bytes32 name)
        external
        view
        returns (ITokenTaxes.Tax memory tax);

    /**
     * @dev Returns the `taxNames` stored for `taxedAddress`.
     *
     * @param taxedAddress The taxed address.
     *
     * @return taxNames Array with tax names stored for `taxedAddress`.
     */
    function getAddressTokenTaxNames(address taxedAddress)
        external
        view
        returns (bytes32[] memory taxNames);

    /**
     * @dev Checks if `taxName` (string) is assigned to `taxedAddress`.
     *
     * @param taxedAddress The taxed address.
     * @param taxName String name of the tax.
     */
    function doesAddressHaveTokenTax(address taxedAddress, bytes32 taxName)
        external
        view
        returns (bool);

    /**
     * @dev Checks if `account` is exempt from taxes.
     *
     * @return True if `account` is exempt from taxes.
     */
    function isExemptFromTokenTaxes(address account)
        external
        view
        returns (bool);

    /**
     * @dev Sets the `account`'s exempt from tax status to `flag`.
     * Emits an {TokenTaxSetExemptFlag} event.
     *
     * @param account The account to set the `flag` for.
     * @param flag The status flag.
     */
    function setExemptFromTokenTaxes(address account, bool flag) external;

    /**
     * @dev Returns the current enabled state.
     */
    function tokenTaxesIsEnabled() external view returns (bool enabled);

    /**
     * @dev Enables the token-taxes module.
     * Emits an {TokenTaxesEnabled} event.
     */
    function tokenTaxesEnable() external;

    /**
     * @dev Disables the token-taxes module
     * Emits an {TokenTaxesDisabled} event.
     */
    function tokenTaxesDisable() external;

    /**
     * @dev Sets the `distributionPeriod`.
     *
     * @param distributionPeriod The period to set.
     */
    function tokenTaxesSetDistributionPeriod(uint32 distributionPeriod)
        external;

    /**
     * @dev Returns the `distributionPeriod`.
     *
     * @return distributionPeriod The configured period.
     */
    function tokenTaxesGetDistributionPeriod() external view returns (uint32);

    /**
     * @dev Returns the timestamp of the last token tax distribution.
     *
     * @return distributedAt The timestamp of the last tax distribution.
     */
    function tokenTaxesGetDistributedAt() external view returns (uint32);

    /**
     * @dev Returns an info response. Mainly for testing and debuggind.
     *
     * @return taxesInfoResponse An instance of the ITokenTaxes.TaxesInfoResponse struct, with data from the storage.
     */
    function tokenTaxesGetInfoResponse()
        external
        view
        returns (ITokenTaxes.TaxesInfoResponse memory);
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {ITokenTaxes} from "./ITokenTaxes.sol";
import {LibTokenDistributor} from "../token-distributor/LibTokenDistributor.sol";
import {LibSoloToken} from "../solo-token/LibSoloToken.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @dev Library to manage and apply token taxes.
 * Multiple Tax groups can be defined and multiple of them can be assigned to multiple addresses (pairs).
 * All taxes are distributed by token distributor strategies.
 */
library LibTokenTaxes {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Storage {
        // Kill switch to enable/disable the token-tax module.
        bool enabled;
        // If enabled, the tax distribution will be triggered during sell transactions.
        bool distributeOnSell;
        // Last time the collected taxes have been distributed.
        uint32 distributedAt;
        // Amount of seconds between distributions.
        uint32 distributionPeriod;
        // Array with all tax names, to allow iteration.
        bytes32[] taxNames;
        // Mapping of tax names to tax structs.
        mapping(bytes32 => ITokenTaxes.Tax) taxes;
        // Mapping of addresses (lp pairs) to a set of applicable tax structs.
        mapping(address => EnumerableSet.Bytes32Set) addressTaxes;
        // Mapping of addresses exempt from taxes.
        // All transfers from or to those addresses will be tax exempt.
        mapping(address => bool) exemptFromTaxes;
        // Amounts of taxes collected for each tax so far.
        mapping(bytes32 => uint256) collectedTaxes;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.token-taxes.LibTokenTaxes");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    error TokenTaxNotFound(bytes32 taxName);
    error TokenTaxAlreadyExists(bytes32 taxName);

    /**
     * @dev Emitted when the token-taxes module is enabled.
     */
    event TokenTaxesEnabled();

    /**
     * @dev Emitted when the token-taxes module is disabled.
     */
    event TokenTaxesDisabled();

    /**
     * @dev Emitted when a token tax with `name` is set.
     */
    event TokenTaxSet(string name);

    /**
     * @dev Emitted when token tax with `taxName` is added to a `taxedAddress`.
     */
    event TokenTaxAddedToAddress(address taxedAddress, bytes32 taxName);

    /**
     * @dev Emitted when token tax with `taxName` is removed from a `taxedAddress`.
     */
    event TokenTaxRemovedFromAddress(address taxedAddress, bytes32 taxName);

    /**
     * @dev Emitted when the exempt from taxes flag of `account` is set.
     */
    event TokenTaxSetExemptFlag(address account, bool flag);

    /**
     * @dev Does pay any taxes applicable to the `bruttoAmount` transferred `from` to `to`.
     * Returns the nettoAmount after all paid taxes.
     *
     * @param from The sender of the transfer.
     * @param to The recepient of the transfer.
     * @param bruttoAmount The transfered amount.
     *
     * @return nettoAmount The amount after applied taxes.
     */
    function payTaxes(
        address from,
        address to,
        uint256 bruttoAmount
    ) internal returns (uint256 nettoAmount) {
        Storage storage s = _storage();

        if (!s.enabled) {
            return bruttoAmount;
        }

        nettoAmount = bruttoAmount;

        if (isExemptFromTaxes(from) || isExemptFromTaxes(to)) {
            return nettoAmount;
        }

        EnumerableSet.Bytes32Set storage fromTaxNames = s.addressTaxes[from];
        EnumerableSet.Bytes32Set storage toTaxNames = s.addressTaxes[to];

        if (fromTaxNames.length() > 0) {
            nettoAmount = preccessTaxes(
                from,
                nettoAmount,
                fromTaxNames,
                ITokenTaxes.TaxType.Buy
            );
        } else if (toTaxNames.length() > 0) {
            nettoAmount = preccessTaxes(
                from,
                nettoAmount,
                toTaxNames,
                ITokenTaxes.TaxType.Sell
            );

            if (s.distributeOnSell) {
                distributeCollectedTaxes();
            }
        } else {
            distributeCollectedTaxes();
        }
    }

    /**
     * @dev Processes specific list of `taxNames` of type `taxType` and applies them to `bruttoAmount`.
     * The taxes are paid by `from`.
     *
     * @param from Tax payer.
     * @param bruttoAmount The taxed amount.
     * @param taxNames List of tax names that should be applied.
     * @param taxType The type of the aplied tax.
     *
     * @return nettoAmount The amount after applied taxes.
     */
    function preccessTaxes(
        address from,
        uint256 bruttoAmount,
        EnumerableSet.Bytes32Set storage taxNames,
        ITokenTaxes.TaxType taxType
    ) internal returns (uint256 nettoAmount) {
        Storage storage s = _storage();

        nettoAmount = bruttoAmount;

        uint256 length = taxNames.length();

        for (uint256 index = 0; index < length; ) {
            ITokenTaxes.Tax memory tax = getTax(taxNames.at(index));

            uint256 taxAmount = getTaxAmount(bruttoAmount, tax, taxType);

            if (taxAmount == 0) {
                unchecked {
                    ++index;
                }
                continue;
            }

            nettoAmount -= taxAmount;

            s.collectedTaxes[
                keccak256(abi.encodePacked(tax.name))
            ] += taxAmount;

            // solhint-disable-next-line multiple-sends, check-send-result
            LibSoloToken.send(from, address(this), taxAmount, "", "", false);

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @dev Calculates the `taxAmount` from the `bruttoAmount` for provided `tax`of type `taxType`.
     *
     * @param bruttoAmount The taxed amount.
     * @param tax The struct of the tax.
     * @param taxType The type of the tax.
     *
     * @return taxAmount The calculated amount of tax to take from the user.
     */
    function getTaxAmount(
        uint256 bruttoAmount,
        ITokenTaxes.Tax memory tax,
        ITokenTaxes.TaxType taxType
    ) internal pure returns (uint256 taxAmount) {
        if (taxType == ITokenTaxes.TaxType.Buy && tax.buy > 0) {
            taxAmount = (bruttoAmount * tax.buy) / 10000;
        } else if (taxType == ITokenTaxes.TaxType.Sell && tax.sell > 0) {
            taxAmount = (bruttoAmount * tax.sell) / 10000;
        }
    }

    /**
     * @dev Distributes previously collected taxes.
     * If `distributionPeriod` is configured, will ensure it's time to distribute.
     */
    function distributeCollectedTaxes() internal {
        Storage storage s = _storage();

        if (
            s.distributionPeriod > 0 &&
            // solhint-disable-next-line not-rely-on-time
            s.distributedAt + s.distributionPeriod >= block.timestamp
        ) {
            return;
        }

        bytes32[] memory taxNames = s.taxNames;

        for (uint256 index = 0; index < taxNames.length; ) {
            distributeCollectedTax(taxNames[index], getTax(taxNames[index]));

            unchecked {
                ++index;
            }
        }

        // solhint-disable-next-line not-rely-on-time
        s.distributedAt = uint32(block.timestamp % 2**32);
    }

    /**
     * @dev Distributes collected taxes for `taxName`.
     *
     * @param taxName Name of the tax.
     * @param tax Struct with the tax.
     */
    function distributeCollectedTax(bytes32 taxName, ITokenTaxes.Tax memory tax)
        internal
    {
        Storage storage s = _storage();

        uint256 taxAmount = s.collectedTaxes[taxName];

        if (taxAmount == 0) {
            return;
        }

        s.collectedTaxes[taxName] = 0;

        LibTokenDistributor.distribute(
            tax.tokenDitributorStrategyId,
            address(this),
            taxAmount
        );
    }

    /**
     * @dev Returns the current enabled state.
     */
    function isEnabled() internal view returns (bool enabled) {
        enabled = _storage().enabled;
    }

    /**
     * @dev Enables the token-taxes module.
     * Emits an {TokenTaxesEnabled} event.
     */
    function enable() internal {
        _storage().enabled = true;

        emit TokenTaxesEnabled();
    }

    /**
     * @dev Disables the token-taxes module
     * Emits an {TokenTaxesDisabled} event.
     */
    function disable() internal {
        _storage().enabled = false;

        emit TokenTaxesDisabled();
    }

    /**
     * @dev Adds a new token Tax.
     * Emits an {TokenTaxAdded} event.
     *
     * @param tax The Tax to be added.
     */
    function addTax(ITokenTaxes.Tax memory tax) internal {
        Storage storage s = _storage();

        bytes32 taxName = keccak256(abi.encodePacked(tax.name));

        if (
            keccak256(abi.encodePacked(s.taxes[taxName].name)) !=
            keccak256(abi.encodePacked(""))
        ) {
            revert TokenTaxAlreadyExists(taxName);
        }

        s.taxes[taxName] = tax;
        s.taxNames.push(taxName);

        emit TokenTaxSet(tax.name);
    }

    /**
     * @dev Update a token Tax.
     * Emits an {TokenTaxUpdated} event.
     *
     * @param tax The Tax to be updated.
     */
    function updateTax(ITokenTaxes.Tax memory tax) internal {
        Storage storage s = _storage();

        bytes32 taxName = keccak256(abi.encodePacked(tax.name));

        if (
            keccak256(abi.encodePacked(s.taxes[taxName].name)) ==
            keccak256(abi.encodePacked(""))
        ) {
            revert TokenTaxNotFound(taxName);
        }

        s.taxes[taxName] = tax;

        emit TokenTaxSet(tax.name);
    }

    /**
     * @dev Returns a tax by it's string name.
     *
     * @dev name Tax name as a string.
     *
     * @return tax The found tax.
     */
    function getTax(string memory name)
        internal
        view
        returns (ITokenTaxes.Tax memory tax)
    {
        tax = _storage().taxes[keccak256(abi.encodePacked(name))];
    }

    /**
     * @dev Returns a tax by it's bytes32 name.
     *
     * @dev name Tax name as bytes32.
     *
     * @return tax The found tax.
     */
    function getTax(bytes32 name)
        internal
        view
        returns (ITokenTaxes.Tax memory tax)
    {
        tax = _storage().taxes[name];
    }

    /**
     * @dev Adds `taxName` to `taxedAddress`.
     * Emits an {TokenTaxAddedToAddress} event.
     *
     * @param taxedAddress The taxed address.
     * @param taxName Bytes32 name of the tax.
     */
    function addAddressTax(address taxedAddress, bytes32 taxName) internal {
        _storage().addressTaxes[taxedAddress].add(taxName);

        emit TokenTaxAddedToAddress(taxedAddress, taxName);
    }

    /**
     * @dev Removes `taxName` from `taxedAddress`.
     * Emits an {TokenTaxRemovedFromAddress} event.
     *
     * @param taxedAddress The taxed address.
     * @param taxName Bytes32 name of the tax.
     */
    function removeAddressTax(address taxedAddress, bytes32 taxName) internal {
        _storage().addressTaxes[taxedAddress].remove(taxName);

        emit TokenTaxRemovedFromAddress(taxedAddress, taxName);
    }

    /**
     * @dev Returns the `taxNames` stored for `taxedAddress`.
     *
     * @param taxedAddress The taxed address.
     *
     * @return taxNames Array with tax names stored for `taxedAddress`.
     */
    function getAddressTaxNames(address taxedAddress)
        internal
        view
        returns (bytes32[] memory taxNames)
    {
        taxNames = _storage().addressTaxes[taxedAddress].values();
    }

    /**
     * @dev Checks if `taxName` (string) is assigned to `taxedAddress`.
     *
     * @param taxedAddress The taxed address.
     * @param taxName String name of the tax.
     */
    function doesAddressHaveTax(address taxedAddress, string memory taxName)
        internal
        view
        returns (bool)
    {
        return
            doesAddressHaveTax(
                taxedAddress,
                keccak256(abi.encodePacked(taxName))
            );
    }

    /**
     * @dev Checks if `taxName` (bytes32) is assigned to `taxedAddress`.
     *
     * @param taxedAddress The taxed address.
     * @param taxName Bytes32 name of the tax.
     */
    function doesAddressHaveTax(address taxedAddress, bytes32 taxName)
        internal
        view
        returns (bool)
    {
        return _storage().addressTaxes[taxedAddress].contains(taxName);
    }

    /**
     * @dev Sets the `account`'s exempt from tax status to `flag`.
     * Emits an {TokenTaxSetExemptFlag} event.
     *
     * @param account The account to set the `flag` for.
     * @param flag The status flag.
     */
    function setExemptFromTaxes(address account, bool flag) internal {
        _storage().exemptFromTaxes[account] = flag;

        emit TokenTaxSetExemptFlag(account, flag);
    }

    /**
     * @dev Checks if `account` is exempt from taxes.
     *
     * @return True if `account` is exempt from taxes.
     */
    function isExemptFromTaxes(address account) internal view returns (bool) {
        return account == address(this) || _storage().exemptFromTaxes[account];
    }

    /**
     * @dev Sets the `distributionPeriod`.
     *
     * @param distributionPeriod The period to set.
     */
    function setDistributionPeriod(uint32 distributionPeriod) internal {
        _storage().distributionPeriod = distributionPeriod;
    }

    /**
     * @dev Returns the `distributionPeriod`.
     *
     * @return distributionPeriod The configured period.
     */
    function getDistributionPeriod() internal view returns (uint32) {
        return _storage().distributionPeriod;
    }

    /**
     * @dev Returns the timestamp of the last token tax distribution.
     *
     * @return distributedAt The timestamp of the last tax distribution.
     */
    function getDistributedAt() internal view returns (uint32) {
        return _storage().distributedAt;
    }

    /**
     * @dev Sets the `distributeOnSell`.
     */
    function setDistributeOnSell(bool distributeOnSell) internal {
        _storage().distributeOnSell = distributeOnSell;
    }

    /**
     * @dev Sets the `distributeOnSell`.
     */
    function getDistributeOnSell()
        internal
        view
        returns (bool distributeOnSell)
    {
        distributeOnSell = _storage().distributeOnSell;
    }

    /**
     * @dev Returns an info response. Mainly for testing and debuggind.
     *
     * @return taxesInfoResponse An instance of the ITokenTaxes.TaxesInfoResponse struct, with data from the storage.
     */
    function getTaxesInfoResponse()
        internal
        view
        returns (ITokenTaxes.TaxesInfoResponse memory)
    {
        Storage storage s = _storage();

        return
            ITokenTaxes.TaxesInfoResponse({
                enabled: s.enabled,
                distributeOnSell: s.distributeOnSell,
                distributedAt: s.distributedAt,
                distributionPeriod: s.distributionPeriod,
                taxNames: s.taxNames
            });
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {LibSoloToken} from "../solo-token/LibSoloToken.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibUniswap {
    struct Storage {
        IUniswapV2Factory factory;
        IUniswapV2Router02 router;
        address tokenB;
        address intermediateWallet;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.uniswap.LibUniswap");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Swaps `amountIn` of `tokenA` for `tokenB` and sends the amountOut to `amountOutReceiver`
     * using `router`.
     * @notice Uses swapExactTokensForTokensSupportingFeeOnTransferTokens()
     * @notice In case either `tokenA` or `tokenB` is same as `amountOutReceiver`,
     * The `intermediateWallet` will be used to swap to it and then transfer the `amountOut` back to the `amountOutReceiver`.
     * For this to work, `address(this)` must have an allowance from `intermediateWallet` to spend `tokenB`.
     *
     * @param router The router to use.
     * @param amountIn The amount of `tokenA` to send.
     * @param tokenA The input token.
     * @param tokenB The output token.
     * @param amountOutReceiver Recipient of the amountOut.
     *
     * @return amountOut The amount of `tokenB` sent to the `amountOutReceiver`.
     */
    function swap(
        IUniswapV2Router02 router,
        uint256 amountIn,
        address tokenA,
        address tokenB,
        address amountOutReceiver,
        bool skipApproval
    ) internal returns (uint256 amountOut) {
        Storage storage s = _storage();

        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        // Approve `tokenA` if needed
        if (
            !skipApproval &&
            IERC20(tokenA).allowance(address(this), address(router)) < amountIn
        ) {
            IERC20(tokenA).approve(address(router), amountIn);
        }

        address to = amountOutReceiver;

        // Swap to an intermediateWallet, to work around uniswap's limitation.
        // Uniswap does not allow the receiver of the swapped token to be any of the tokens that are swapped.
        if (to == tokenA || to == tokenB) {
            to = s.intermediateWallet;
        }

        uint256 initialBalance = IERC20(tokenB).balanceOf(to);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            to,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        amountOut = IERC20(tokenB).balanceOf(to) - initialBalance;

        // If we swapped to the intermediateWallet, we need to send the swapped amount back to the amountOutReceiver.
        if (to != amountOutReceiver) {
            IERC20(tokenB).transferFrom(to, amountOutReceiver, amountOut);
        }
    }

    /**
     * @dev Swaps `amountIn` of `tokenA` for `tokenB` and sends the amountOut to `amountOutReceiver`
     * using `router`.
     * @notice Uses swapExactTokensForTokensSupportingFeeOnTransferTokens()
     *
     * @param amountIn The amount of `tokenA` to send.
     * @param tokenA The input token.
     * @param tokenB The output token.
     * @param amountOutReceiver Recipient of the amountOut.
     *
     * @return amountB The amount of `tokenB` sent to the `amountOutReceiver`.
     */
    function swap(
        uint256 amountIn,
        address tokenA,
        address tokenB,
        address amountOutReceiver
    ) internal returns (uint256 amountB) {
        return
            swap(
                _storage().router,
                amountIn,
                tokenA,
                tokenB,
                amountOutReceiver,
                false
            );
    }

    struct AddLiquidityParameters {
        IUniswapV2Router02 router;
        address lpTokenReceiver;
        address tokenA;
        address tokenB;
        uint256 amountADesired;
        uint256 amountBDesired;
        bool skipApproval;
    }

    /**
     * @dev Adds `amountADesired` and `amountBDesired` as liquidity to pair of `tokenA` and `tokenB`
     * using `router` and sends the minted LP token to `lpTokenReceiver`.
     * @notice AddLiquidityParameters struct is used to overcome the "Stack too deep" compilation error.
     *
     * @param parameters.router The router to use.
     * @param parameters.lpTokenReceiver Recipient of the liquidity tokens.
     * @param parameters.tokenA First pool token.
     * @param parameters.tokenB Second pool token.
     * @param parameters.amountADesired The amount of tokenA to add as liquidity if the B/A price is <= amountBDesired/amountADesired (A depreciates).
     * @param parameters.amountBDesired The amount of tokenB to add as liquidity if the A/B price is <= amountADesired/amountBDesired (B depreciates).
     *
     * @return amountA The amount of tokenA sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidity(AddLiquidityParameters memory parameters)
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        // Approve `tokenA` if needed
        if (
            !parameters.skipApproval &&
            IERC20(parameters.tokenA).allowance(
                address(this),
                address(parameters.router)
            ) <
            parameters.amountADesired
        ) {
            IERC20(parameters.tokenA).approve(
                address(parameters.router),
                parameters.amountADesired
            );
        }

        // Approve `tokenB` if needed
        if (
            !parameters.skipApproval &&
            IERC20(parameters.tokenB).allowance(
                address(this),
                address(parameters.router)
            ) <
            parameters.amountBDesired
        ) {
            IERC20(parameters.tokenB).approve(
                address(parameters.router),
                parameters.amountBDesired
            );
        }

        return
            parameters.router.addLiquidity(
                parameters.tokenA,
                parameters.tokenB,
                parameters.amountADesired,
                parameters.amountBDesired,
                0,
                0,
                parameters.lpTokenReceiver,
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            );
    }

    /**
     * @dev Adds `amountADesired` and `amountBDesired` as liquidity to pair of `tokenA` and `tokenB`
     * using stored `router` and sends the minted LP token to `lpTokenReceiver`.
     *
     * @param lpTokenReceiver Recipient of the liquidity tokens.
     * @param tokenA First pool token.
     * @param tokenB Second pool token.
     * @param amountADesired The amount of tokenA to add as liquidity if the B/A price is <= amountBDesired/amountADesired (A depreciates).
     * @param amountBDesired The amount of tokenB to add as liquidity if the A/B price is <= amountADesired/amountBDesired (B depreciates).
     *
     * @return amountA The amount of tokenA sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidity(
        address lpTokenReceiver,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        return
            addLiquidity(
                AddLiquidityParameters({
                    router: _storage().router,
                    lpTokenReceiver: lpTokenReceiver,
                    tokenA: tokenA,
                    tokenB: tokenB,
                    amountADesired: amountADesired,
                    amountBDesired: amountBDesired,
                    skipApproval: false
                })
            );
    }

    /**
     * @dev Adds `amountADesired` and `amountBDesired` as liquidity to pair of `address(this)` (solo-token) and stored `tokenB`
     * using stored `router` and sends the minted LP token to `lpTokenReceiver`.
     *
     * @param lpTokenReceiver Recipient of the liquidity tokens.
     * @param amountADesired The amount of tokenA to add as liquidity if the B/A price is <= amountBDesired/amountADesired (A depreciates).
     * @param amountBDesired The amount of tokenB to add as liquidity if the A/B price is <= amountADesired/amountBDesired (B depreciates).
     *
     * @return amountA The amount of tokenA sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        address lpTokenReceiver
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        Storage storage s = _storage();

        return
            addLiquidity(
                AddLiquidityParameters({
                    router: s.router,
                    lpTokenReceiver: lpTokenReceiver,
                    tokenA: address(this),
                    tokenB: s.tokenB,
                    amountADesired: amountADesired,
                    amountBDesired: amountBDesired,
                    skipApproval: false
                })
            );
    }

    /**
     * @dev Swaps half `amount` of `tokenA` to `tokenB`, adds to their liquidity
     * using `router` and sends the minted LP to `lpTokenReceiver`.
     * @notice The swap will be performed with 100% slipage!
     *
     * @param router The router to use.
     * @param tokenA First pool token.
     * @param tokenB Second pool token.
     * @param amount The amount of `tokenA` to be swaped.
     * @param lpTokenReceiver Recipient of the liquidity tokens.
     *
     * @return amountA The amount of tokenA sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function zapInLiquidity(
        IUniswapV2Router02 router,
        address tokenA,
        address tokenB,
        uint256 amount,
        address lpTokenReceiver
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        uint256 half = amount / 2;

        // Approve `tokenA` if needed
        if (IERC20(tokenA).allowance(address(this), address(router)) < half) {
            IERC20(tokenA).approve(address(router), half);
        }

        // Approve `tokenB` if needed
        if (IERC20(tokenB).allowance(address(this), address(router)) < half) {
            IERC20(tokenB).approve(address(router), half);
        }

        uint256 swapedAmount = swap(
            router,
            half,
            tokenA,
            tokenB,
            address(this),
            true
        );

        return
            addLiquidity(
                AddLiquidityParameters({
                    router: router,
                    lpTokenReceiver: lpTokenReceiver,
                    tokenA: tokenA,
                    tokenB: tokenB,
                    amountADesired: half,
                    amountBDesired: swapedAmount,
                    skipApproval: true
                })
            );
    }

    /**
     * @dev Swaps half `amount` of `tokenA` to `tokenB`, adds to their liquidity
     * using stored `router` and sends the minted LP to `lpTokenReceiver`.
     * @notice The swap will be performed with 100% slipage!
     *
     * @param tokenA First pool token.
     * @param tokenB Second pool token.
     * @param amount The amount of `tokenA` to be swaped.
     * @param lpTokenReceiver Recipient of the liquidity tokens.
     *
     * @return amountA The amount of tokenA sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function zapInLiquidity(
        address tokenA,
        address tokenB,
        uint256 amount,
        address lpTokenReceiver
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        return
            zapInLiquidity(
                _storage().router,
                tokenA,
                tokenB,
                amount,
                lpTokenReceiver
            );
    }

    /**
     * @dev Swaps half `amount` of `address(this)` (solo-token) to `tokenB`, adds to their liquidity
     * using stored `router` and sends the minted LP to `lpTokenReceiver`.
     * @notice The swap will be performed with 100% slipage!
     *
     * @param tokenB Second pool token.
     * @param amount The amount of `address(this)` (solo-token) to be swaped.
     * @param lpTokenReceiver Recipient of the liquidity tokens.
     *
     * @return amountA The amount of `address(this)` (solo-token) sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function zapInLiquidity(
        address tokenB,
        uint256 amount,
        address lpTokenReceiver
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        return
            zapInLiquidity(
                _storage().router,
                address(this),
                tokenB,
                amount,
                lpTokenReceiver
            );
    }

    /**
     * @dev Swaps half `amount` of `address(this)` (solo-token) to stored `tokenB`, adds to their liquidity
     * using stored `router` and sends the minted LP to `lpTokenReceiver`.
     * @notice The swap will be performed with 100% slipage!
     *
     * @param amount The amount of `address(this)` (solo-token) to be swaped.
     * @param lpTokenReceiver Recipient of the liquidity tokens.
     *
     * @return amountA The amount of `address(this)` (solo-token) sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function zapInLiquidity(uint256 amount, address lpTokenReceiver)
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        Storage storage s = _storage();

        return
            zapInLiquidity(
                s.router,
                address(this),
                s.tokenB,
                amount,
                lpTokenReceiver
            );
    }

    /**
     * @dev Creates a pair of `address(this)` (solo-token) and `tokenB`, using `factory`.
     * Returns the created `pair`.
     *
     * @param factory The factory to use.
     * @param tokenB Second pool token.
     *
     * @return pair Address of the created LP.
     */
    function createPair(IUniswapV2Factory factory, address tokenB)
        internal
        returns (address pair)
    {
        pair = factory.createPair(address(this), tokenB);
    }

    /**
     * @dev Creates a pair of `address(this)` (solo-token) and `tokenB`, using the factory from the storage.
     * Returns the created `pair`.
     *
     * @param tokenB Second pool token.
     *
     * @return pair Address of the created LP.
     */
    function createPair(address tokenB) internal returns (address pair) {
        pair = _storage().factory.createPair(address(this), tokenB);
    }

    /**
     * @dev Creates a pair of `address(this)` (solo-token) and stored `tokenB`, using the factory from the storage.
     * Returns the created `pair`.
     *
     * @return pair Address of the created LP.
     */
    function createPair() internal returns (address pair) {
        Storage storage s = _storage();

        pair = s.factory.createPair(address(this), s.tokenB);
    }

    function setFactory(IUniswapV2Factory factory) internal {
        _storage().factory = factory;
    }

    function getFactory() internal view returns (IUniswapV2Factory factory) {
        factory = _storage().factory;
    }

    function setRouter(IUniswapV2Router02 router) internal {
        _storage().router = router;
    }

    function getRouter() internal view returns (IUniswapV2Router02 router) {
        router = _storage().router;
    }

    function setTokenB(address tokenB) internal {
        _storage().tokenB = tokenB;
    }

    function getTokenB() internal view returns (address tokenB) {
        tokenB = _storage().tokenB;
    }

    function setIntermediateWallet(address intermediateWallet) internal {
        _storage().intermediateWallet = intermediateWallet;
    }

    function getIntermediateWallet()
        internal
        view
        returns (address intermediateWallet)
    {
        intermediateWallet = _storage().intermediateWallet;
    }
}

// SPDX-License-Identifier: GPL
// Copyright: Uniswap V2 (https://github.com/Uniswap/v2-core)

pragma solidity ^0.8.9;

/* solhint-disable */
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GPL
// Copyright: Uniswap V2 (https://github.com/Uniswap/v2-core)

pragma solidity ^0.8.9;

/* solhint-disable */
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

// SPDX-License-Identifier: GPL
// Copyright: Uniswap V2 (https://github.com/Uniswap/v2-periphery)

pragma solidity ^0.8.9;

/* solhint-disable */
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

// SPDX-License-Identifier: GPL
// Copyright: Uniswap V2 (https://github.com/Uniswap/v2-periphery)

pragma solidity ^0.8.9;

import "./IUniswapV2Router01.sol";

/* solhint-disable */
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {ITokenTaxes} from "@solarprotocol/solar-diamond/contracts/modules/token-taxes/ITokenTaxes.sol";
import {LibTokenTaxes} from "@solarprotocol/solar-diamond/contracts/modules/token-taxes/LibTokenTaxes.sol";
import {LibUniswap} from "@solarprotocol/solar-diamond/contracts/modules/uniswap/LibUniswap.sol";
import {LibTokenReflections} from "@solarprotocol/solar-diamond/contracts/modules/token-reflections/LibTokenReflections.sol";
import {LibDiamond} from "contracts-starter/contracts/libraries/LibDiamond.sol";

// solhint-disable-next-line contract-name-camelcase
contract DecayLaunchTaxes_to_5_0011 {
    function migrate() external {
        ITokenTaxes.Tax memory tax = LibTokenTaxes.getTax(
            keccak256("LAUNCH_TAX")
        );

        tax.buy = 0;
        tax.sell = 500;

        LibTokenTaxes.updateTax(tax);
    }
}
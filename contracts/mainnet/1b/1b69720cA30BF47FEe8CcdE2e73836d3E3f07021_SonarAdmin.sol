/***
 * ███████╗ ██████╗ ███╗   ██╗ █████╗ ██████╗ 
 * ██╔════╝██╔═══██╗████╗  ██║██╔══██╗██╔══██╗
 * ███████╗██║   ██║██╔██╗ ██║███████║██████╔╝
 * ╚════██║██║   ██║██║╚██╗██║██╔══██║██╔══██╗
 * ███████║╚██████╔╝██║ ╚████║██║  ██║██║  ██║
 * ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝
 *                                           
 *  █████╗ ██████╗ ███╗   ███╗██╗███╗   ██╗   
 * ██╔══██╗██╔══██╗████╗ ████║██║████╗  ██║   
 * ███████║██║  ██║██╔████╔██║██║██╔██╗ ██║   
 * ██╔══██║██║  ██║██║╚██╔╝██║██║██║╚██╗██║   
 * ██║  ██║██████╔╝██║ ╚═╝ ██║██║██║ ╚████║   
 * ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   
 * This is a re-write of @openzeppelin/contracts/finance/PaymentSplitter.sol
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "./utils/ContextV2.sol";
import "./access/DeveloperV2.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */

contract SonarAdmin is ContextV2, DeveloperV2 {

  event PayeeAdded(address account, uint256 shares);
  event PaymentReleased(address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  uint256 private _totalShares;
  uint256 private _totalReleased;
  mapping(address => uint256) private _shares;
  mapping(address => uint256) private _released;
  address[] private _payees;

  /**
   * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
   * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
   * reliability of the events, and not the actual splitting of Ether.
   *
   * To learn more about this see the Solidity documentation for
   * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
   * functions].
   */
  receive() external payable virtual {
    emit PaymentReceived(_msgSender(), _msgValue());
  }

  // Fallback function is called when msg.data is not empty
  // Added to PaymentSplitter.sol
  fallback() external payable {
    emit PaymentReceived(_msgSender(), _msgValue());
  }

  /**
   * @dev Getter for the total shares held by payees.
   */
  // totalShares() => 0x3a98ef39
  function totalShares() public view returns (uint256) {
    return _totalShares;
  }

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  // totalReleased() => 0xe33b7de3
  function totalReleased() public view returns (uint256) {
    return _totalReleased;
  }

  /**
   * @dev Getter for the amount of shares held by an account.
   */
  // shares(address) => 0xce7c2ac2
  function shares(address account) public view returns (uint256) {
    return _shares[account];
  }

  /**
   * @dev Getter for the amount of Ether already released to a payee.
   */
  // released(address) => 0x9852595c
  function released(address account) public view returns (uint256) {
    return _released[account];
  }

  /**
   * @dev Getter for the address of the payee number `index`.
   */
  // payee(uint256) => 0x8b83209b
  function payee(uint256 index) public view returns (address) {
    return _payees[index];
  }

  /**
   * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
   * total shares and their previous withdrawals.
   */
  // This function was updated from "account" to _msgSender()
  // claim() => 0x4e71d92d
  function claim() public virtual {
    require(_shares[_msgSender()] > 0, "PaymentSplitter: _msgSender() has no shares");

    uint256 totalReceived = address(this).balance + _totalReleased;
    uint256 payment = (totalReceived * _shares[_msgSender()]) / _totalShares - _released[_msgSender()];

    require(payment != 0, "PaymentSplitter: _msgSender() is not due payment");

    _released[_msgSender()] = _released[_msgSender()] + payment;
    _totalReleased = _totalReleased + payment;

    Address.sendValue(payable(_msgSender()), payment);
    emit PaymentReleased(_msgSender(), payment);
  }

  function addPayee(address account, uint256 totalShares_) public onlyDev {
    _addPayee(account, totalShares_);
  }

  /**
   * @dev Add a new payee to the contract.
   * @param account The address of the payee to add.
   * @param shares_ The number of shares owned by the payee.
   */
  // This function was updated to internal
  function _addPayee(address account, uint256 shares_) internal {
    require(account != address(0), "PaymentSplitter: account is the zero address");
    require(shares_ > 0, "PaymentSplitter: shares are 0");
    require(_shares[account] == 0, "PaymentSplitter: account already has shares");

    _payees.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares + shares_;

    emit PayeeAdded(account, shares_);
  }
}

/***
 *     ██████╗ ██████╗ ███╗   ██╗████████╗███████╗██╗  ██╗████████╗
 *    ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔════╝╚██╗██╔╝╚══██╔══╝
 *    ██║     ██║   ██║██╔██╗ ██║   ██║   █████╗   ╚███╔╝    ██║   
 *    ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══╝   ██╔██╗    ██║   
 *    ╚██████╗╚██████╔╝██║ ╚████║   ██║   ███████╗██╔╝ ██╗   ██║   
 *     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝   
 * This is a re-write of @openzeppelin/contracts/utils/Context.sol
 * Rewritten by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Upgraded with _msgValue() and _txOrigin() as ContextV2 on 31 Dec 2021
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
abstract contract ContextV2 {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint) {
        return msg.value;
    }

    function _txOrigin() internal view virtual returns (address) {
        return tx.origin;
    }
}

/***
 *    ██████╗ ███████╗██╗   ██╗███████╗██╗      ██████╗ ██████╗ ███████╗██████╗ 
 *    ██╔══██╗██╔════╝██║   ██║██╔════╝██║     ██╔═══██╗██╔══██╗██╔════╝██╔══██╗
 *    ██║  ██║█████╗  ██║   ██║█████╗  ██║     ██║   ██║██████╔╝█████╗  ██████╔╝
 *    ██║  ██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║     ██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗
 *    ██████╔╝███████╗ ╚████╔╝ ███████╗███████╗╚██████╔╝██║     ███████╗██║  ██║
 *    ╚═════╝ ╚══════╝  ╚═══╝  ╚══════╝╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝
 * This is a re-write of @openzeppelin/contracts/access/Ownable.sol
 * Rewritten by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Upgraded to push/pull and decline by @MaxFlowO2 on 29 Dec 2021
 * Updated to ContextV2, and removed ERC165 calculations on 31 Dec 2021
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2
// Rewritten for onlyDev modifier

pragma solidity >=0.8.0 <0.9.0;

import "../utils/ContextV2.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a developer) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the developer account will be the one that deploys the contract. This
 * can later be changed with {transferDeveloper}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyDev`, which can be applied to your functions to restrict their use to
 * the developer.
 */

abstract contract DeveloperV2 is ContextV2 {

    address private _developer;
    address private _newDeveloper;

    event DeveloperTransferred(address indexed previousDeveloper, address indexed newDeveloper);

    /**
     * @dev Initializes the contract setting the deployer as the initial developer.
     */
    constructor() {
        _transferDeveloper(_msgSender());
    }

    /**
     * @dev Returns the address of the current developer.
     */
    function developer() public view virtual returns (address) {
        return _developer;
    }

    /**
     * @dev Throws if called by any account other than the developer.
     */
    modifier onlyDev() {
        require(developer() == _msgSender(), "Developer: caller is not the developer");
        _;
    }

    /**
     * @dev Leaves the contract without developer. It will not be possible to call
     * `onlyDev` functions anymore. Can only be called by the current developer.
     *
     * NOTE: Renouncing developership will leave the contract without an developer,
     * thereby removing any functionality that is only available to the developer.
     */
    function renounceDeveloper() public virtual onlyDev {
        _transferDeveloper(address(0));
    }

    /**
     * @dev Transfers Developer of the contract to a new account (`newDeveloper`).
     * Can only be called by the current developer. Now push/pull.
     */
    function transferDeveloper(address newDeveloper) public virtual onlyDev {
        require(newDeveloper != address(0), "Developer: new developer is the zero address");
        _newDeveloper = newDeveloper;
    }

    /**
     * @dev Accepts Transfer Developer of the contract to a new account (`newDeveloper`).
     * Can only be called by the new developer. Pull Accepted.
     */
    function acceptDeveloper() public virtual {
        require(_newDeveloper == _msgSender(), "New Developer: new developer is the only caller");
        _transferDeveloper(_newDeveloper);
    }

    /**
     * @dev Declines Transfer Developer of the contract to a new account (`newDeveloper`).
     * Can only be called by the new developer. Pull Declined
     */
    function declineDeveloper() public virtual {
        require(_newDeveloper == _msgSender(), "New Developer: new developer is the only caller");
        _newDeveloper = address(0);
    }

    /**
     * @dev Transfers Developer of the contract to a new account (`newDeveloper`).
     * Can only be called by the current developer. Now push only. Orginal V1 style
     */
    function pushDeveloper(address newDeveloper) public virtual onlyDev {
        require(newDeveloper != address(0), "Developer: new developer is the zero address");
        _transferDeveloper(newDeveloper);
    }

    /**
     * @dev Transfers Developer of the contract to a new account (`newDeveloper`).
     * Internal function without access restriction.
     */
    function _transferDeveloper(address newDeveloper) internal virtual {
        address oldDeveloper = _developer;
        _developer = newDeveloper;
        emit DeveloperTransferred(oldDeveloper, newDeveloper);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
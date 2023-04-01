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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import './interfaces/IVestingNFT.sol';
import './libraries/TransferHelper.sol';

contract BatchVester {
  event BatchCreated(uint256 mintType);

  /// @notice craeate a batch of vesting NFTs with the same token and same vesting Admin to various recipients, amounts, start dates, cliffs and rates
  /// @param vester is the address of the StreamVestingNFT contrac this points to, either the StreamingHedgeys or the StreamingBoundHedgeys
  /// @param recipients is the array of addresses for those wallets receiving the streams
  /// @param token is the address of the token to be locked inside the NFTs and linearly unlocked to the recipients
  /// @param amounts is the array of the amount of tokens to be locked in each NFT, each directly related in sequence to the recipient and other arrays
  /// @param starts is the array of start dates that define when each NFT will begin linearly unlocking
  /// @param cliffs is the array of cliff dates that define each cliff date for the NFT stream
  /// @param rates is the array of per second rates that each NFT will unlock at the rate of
  /// @param vestingAdmin is the address of the administrator for the vesting plan for the batch of recipients. The vesting admin can revoke tokens at any time.

  function createBatch(
    address vester,
    address[] memory recipients,
    address token,
    uint256[] memory amounts,
    uint256[] memory starts,
    uint256[] memory cliffs,
    uint256[] memory rates,
    address vestingAdmin
  ) external {
    uint256 totalAmount;
    for (uint256 i; i < amounts.length; i++) {
      require(amounts[i] > 0, 'SV04');
      totalAmount += amounts[i];
    }
    _createBatch(vester, recipients, token, amounts, totalAmount, starts, cliffs, rates, vestingAdmin);
  }

  /// @notice craeate a batch of vesting NFTs with the same token and same vesting Admin to various recipients, amounts, start dates, cliffs and rates
  /// this contract emits a special BatchCreated event with the mintType param for internal analytics and tagging
  /// @param vester is the address of the StreamVestingNFT contrac this points to, either the StreamingHedgeys or the StreamingBoundHedgeys
  /// @param recipients is the array of addresses for those wallets receiving the streams
  /// @param token is the address of the token to be locked inside the NFTs and linearly unlocked to the recipients
  /// @param amounts is the array of the amount of tokens to be locked in each NFT, each directly related in sequence to the recipient and other arrays
  /// @param starts is the array of start dates that define when each NFT will begin linearly unlocking
  /// @param cliffs is the array of cliff dates that define each cliff date for the NFT stream
  /// @param rates is the array of per second rates that each NFT will unlock at the rate of
  /// @param vestingAdmin is the address of the administrator for the vesting plan for the batch of recipients. The vesting admin can revoke tokens at any time.
  /// @param mintType is an internal identifier used by Hedgey Applications to record special identifiers for special metadata creation and internal analytics tagging

  function createBatch(
    address vester,
    address[] memory recipients,
    address token,
    uint256[] memory amounts,
    uint256[] memory starts,
    uint256[] memory cliffs,
    uint256[] memory rates,
    address vestingAdmin,
    uint256 mintType
  ) external {
    uint256 totalAmount;
    for (uint256 i; i < amounts.length; i++) {
      require(amounts[i] > 0, 'SV04');
      totalAmount += amounts[i];
    }
    emit BatchCreated(mintType);
    _createBatch(vester, recipients, token, amounts, totalAmount, starts, cliffs, rates, vestingAdmin);
  }

  /// @notice craeate a batch of vesting NFTs with the same token and same vesting Admin to various recipients, amounts, start dates, cliffs and rates
  /// this call has the additional field for creating vesting tokens with an additional unlockDate parameter and the transferableNFTLocker
  /// @param vester is the address of the StreamVestingNFT contrac this points to, either the StreamingHedgeys or the StreamingBoundHedgeys
  /// @param recipients is the array of addresses for those wallets receiving the streams
  /// @param token is the address of the token to be locked inside the NFTs and linearly unlocked to the recipients
  /// @param amounts is the array of the amount of tokens to be locked in each NFT, each directly related in sequence to the recipient and other arrays
  /// @param starts is the array of start dates that define when each NFT will begin linearly unlocking
  /// @param cliffs is the array of cliff dates that define each cliff date for the NFT stream
  /// @param rates is the array of per second rates that each NFT will unlock at the rate of
  /// @param vestingAdmin is the address of the administrator for the vesting plan for the batch of recipients. The vesting admin can revoke tokens at any time.
  /// @param unlocks is an array of unlockDates. The unlock dates are an additional vesting plan modifier,
  /// whereby vested tokens are subject to a lockup period that may be in excess of the cliff date and vesting end date
  /// the unlock date is used typically by teams who are just deploying their tokens for the first time, and have a vesting period with a universal unlock date
  /// where the recipients cannot sell or unlock their tokens before, even if their tokens are vested.
  /// @param transferableNFTLocker is a boolean that describes the transferability of tokens that are vested and locked. This is a special circumstance where
  /// a recipient has vested some tokens and the remaining amount are revoked, but the vested amount are subject to a lockup period in the future.
  /// When the remaining tokens are revoked, the vested amount will be transferred and mint a StreamingNFT that will lock the tokens until the unlock date
  /// there are two versions of the StreamingNFT, transferable and non-transferable. This boolean defines whether the locked tokens are locked in the transferable or non-transferable StreamingNFT contract

  function createLockedBatch(
    address vester,
    address[] memory recipients,
    address token,
    uint256[] memory amounts,
    uint256[] memory starts,
    uint256[] memory cliffs,
    uint256[] memory rates,
    address vestingAdmin,
    uint256[] memory unlocks,
    bool transferableNFTLocker
  ) external {
    uint256 totalAmount;
    for (uint256 i; i < amounts.length; i++) {
      require(amounts[i] > 0, 'SV04');
      totalAmount += amounts[i];
    }
    _createLockedBatch(
      vester,
      recipients,
      token,
      amounts,
      totalAmount,
      starts,
      cliffs,
      rates,
      vestingAdmin,
      unlocks,
      transferableNFTLocker
    );
  }

  /// @notice craeate a batch of vesting NFTs with the same token and same vesting Admin to various recipients, amounts, start dates, cliffs and rates
  /// this call has the additional field for creating vesting tokens with an additional unlockDate parameter and the transferableNFTLocker
  /// @param vester is the address of the StreamVestingNFT contrac this points to, either the StreamingHedgeys or the StreamingBoundHedgeys
  /// @param recipients is the array of addresses for those wallets receiving the streams
  /// @param token is the address of the token to be locked inside the NFTs and linearly unlocked to the recipients
  /// @param amounts is the array of the amount of tokens to be locked in each NFT, each directly related in sequence to the recipient and other arrays
  /// @param starts is the array of start dates that define when each NFT will begin linearly unlocking
  /// @param cliffs is the array of cliff dates that define each cliff date for the NFT stream
  /// @param rates is the array of per second rates that each NFT will unlock at the rate of
  /// @param vestingAdmin is the address of the administrator for the vesting plan for the batch of recipients. The vesting admin can revoke tokens at any time.
  /// @param unlocks is an array of unlockDates. The unlock dates are an additional vesting plan modifier,
  /// whereby vested tokens are subject to a lockup period that may be in excess of the cliff date and vesting end date
  /// the unlock date is used typically by teams who are just deploying their tokens for the first time, and have a vesting period with a universal unlock date
  /// where the recipients cannot sell or unlock their tokens before, even if their tokens are vested.
  /// @param transferableNFTLocker is a boolean that describes the transferability of tokens that are vested and locked. This is a special circumstance where
  /// a recipient has vested some tokens and the remaining amount are revoked, but the vested amount are subject to a lockup period in the future.
  /// When the remaining tokens are revoked, the vested amount will be transferred and mint a StreamingNFT that will lock the tokens until the unlock date
  /// there are two versions of the StreamingNFT, transferable and non-transferable. This boolean defines whether the locked tokens are locked in the transferable or non-transferable StreamingNFT contract
  /// @param mintType is an internal identifier used by Hedgey Applications to record special identifiers for special metadata creation and internal analytics tagging

  function createLockedBatch(
    address vester,
    address[] memory recipients,
    address token,
    uint256[] memory amounts,
    uint256[] memory starts,
    uint256[] memory cliffs,
    uint256[] memory rates,
    address vestingAdmin,
    uint256[] memory unlocks,
    bool transferableNFTLocker,
    uint256 mintType
  ) external {
    uint256 totalAmount;
    for (uint256 i; i < amounts.length; i++) {
      require(amounts[i] > 0, 'SV04');
      totalAmount += amounts[i];
    }
    emit BatchCreated(mintType);
    _createLockedBatch(
      vester,
      recipients,
      token,
      amounts,
      totalAmount,
      starts,
      cliffs,
      rates,
      vestingAdmin,
      unlocks,
      transferableNFTLocker
    );
  }

  /// @notice this is the internal function that is called by the external createBatch function, with all of its parameters
  /// the only new parameter is the totalAmount, which this function takes from the createBatch function to pull all of the tokens into this contract first
  /// and then iterate an array to begin minting vesting NFTs
  function _createBatch(
    address vester,
    address[] memory recipients,
    address token,
    uint256[] memory amounts,
    uint256 totalAmount,
    uint256[] memory starts,
    uint256[] memory cliffs,
    uint256[] memory rates,
    address vestingAdmin
  ) internal {
    require(
      recipients.length == amounts.length &&
        amounts.length == starts.length &&
        starts.length == cliffs.length &&
        cliffs.length == rates.length,
      'array length error'
    );
    TransferHelper.transferTokens(token, msg.sender, address(this), totalAmount);
    SafeERC20.safeIncreaseAllowance(IERC20(token), vester, totalAmount);
    for (uint256 i; i < recipients.length; i++) {
      IVestingNFT(vester).createNFT(recipients[i], token, amounts[i], starts[i], cliffs[i], rates[i], vestingAdmin);
    }
  }

  /// @notice this is the internal function that is called by the external createLockedBatch function, with all of its parameters
  /// the only new parameter is the totalAmount, which this function takes from the createLockedBatch function to pull all of the tokens into this contract first
  /// and then iterate an array to begin minting vesting NFTs
  function _createLockedBatch(
    address vester,
    address[] memory recipients,
    address token,
    uint256[] memory amounts,
    uint256 totalAmount,
    uint256[] memory starts,
    uint256[] memory cliffs,
    uint256[] memory rates,
    address vestingAdmin,
    uint256[] memory unlocks,
    bool transferableNFTLocker
  ) internal {
    require(
      recipients.length == amounts.length &&
        amounts.length == starts.length &&
        starts.length == cliffs.length &&
        cliffs.length == rates.length &&
        unlocks.length == cliffs.length,
      'array length error'
    );
    TransferHelper.transferTokens(token, msg.sender, address(this), totalAmount);
    SafeERC20.safeIncreaseAllowance(IERC20(token), vester, totalAmount);
    for (uint256 i; i < recipients.length; i++) {
      IVestingNFT(vester).createLockedNFT(
        recipients[i],
        token,
        amounts[i],
        starts[i],
        cliffs[i],
        rates[i],
        vestingAdmin,
        unlocks[i],
        transferableNFTLocker
      );
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IVestingNFT {
  function updateBaseURI(string memory _uri) external;

  function createNFT(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliffDate,
    uint256 rate,
    address vestingAdmin
  ) external;

  function createLockedNFT(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliffDate,
    uint256 rate,
    address vestingAdmin,
    uint256 unlockDate,
    bool transferableNFTLockers
  ) external;

  function revokeNFTs(uint256[] memory tokenId) external;

  function redeemNFTs(uint256[] memory tokenId) external;

  function delegateTokens(address delegate, uint256[] memory tokenIds) external;

  function delegateAllNFTs(address delegate) external;

  function redeemAllNFTs() external;

  function streamBalanceOf(uint256 tokenId) external view returns (uint256 balance, uint256 remainder);

  function getStreamEnd(uint256 tokenId) external view returns (uint256 end);

  function streams(uint256 tokenId)
    external
    view
    returns (
      address token,
      uint256 amount,
      uint256 start,
      uint256 cliffDate,
      uint256 rate,
      address vestingAdmin,
      uint256 unlockDate,
      bool transferableNFTLockers
    );

  function balanceOf(address holder) external view returns (uint256 balance);

  function ownerOf(uint tokenId) external view returns (address);

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  function tokenByIndex(uint256 index) external view returns (uint256);

  function balanceOfDelegate(address delegate) external view returns (uint256);

  function delegatedTo(uint256 tokenId) external view returns (address);

  function tokenOfDelegateByIndex(address delegate, uint256 index) external view returns (uint256);

  function lockedBalances(address holder, address token) external view returns (uint256);

  function delegatedBalances(address delegate, address token) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';


/// @notice Library to help safely transfer tokens and handle ETH wrapping and unwrapping of WETH
library TransferHelper {
  using SafeERC20 for IERC20;

  /// @notice Internal function used for standard ERC20 transferFrom method
  /// @notice it contains a pre and post balance check
  /// @notice as well as a check on the msg.senders balance
  /// @param token is the address of the ERC20 being transferred
  /// @param from is the remitting address
  /// @param to is the location where they are being delivered
  function transferTokens(
    address token,
    address from,
    address to,
    uint256 amount
  ) internal {
    uint256 priorBalance = IERC20(token).balanceOf(address(to));
    require(IERC20(token).balanceOf(msg.sender) >= amount, 'THL01');
    SafeERC20.safeTransferFrom(IERC20(token), from, to, amount);
    uint256 postBalance = IERC20(token).balanceOf(address(to));
    require(postBalance - priorBalance == amount, 'THL02');
  }

  /// @notice Internal function is used with standard ERC20 transfer method
  /// @notice this function ensures that the amount received is the amount sent with pre and post balance checking
  /// @param token is the ERC20 contract address that is being transferred
  /// @param to is the address of the recipient
  /// @param amount is the amount of tokens that are being transferred
  function withdrawTokens(
    address token,
    address to,
    uint256 amount
  ) internal {
    uint256 priorBalance = IERC20(token).balanceOf(address(to));
    SafeERC20.safeTransfer(IERC20(token), to, amount);
    uint256 postBalance = IERC20(token).balanceOf(address(to));
    require(postBalance - priorBalance == amount, 'THL02');
  }

}
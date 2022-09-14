/**
 *Submitted for verification at FtmScan.com on 2022-09-13
*/

//SPDX-License-Identifier: Unlicense
// File: contracts/interfaces/ITakepileFactory.sol


pragma solidity >=0.8.0;

interface ITakepileFactory {
    function createTakepile(
        address driver,
        address _xTakeFactory,
        address underlying,
        string calldata name,
        string calldata symbol,
        uint256 maxLeverage
    ) external returns (address);
}

// File: contracts/interfaces/IxTakeFactory.sol


pragma solidity >=0.8.0;

interface IxTakeFactory {
    
    function createDistributor(address _TAKE, address _pile, string calldata _symbol) external returns(address);

}

// File: contracts/interfaces/IxTake.sol


pragma solidity >=0.8.0;

interface IxTake {
    
    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function claimable(address account) external view returns (uint256);

    function claim(uint256 amount) external returns (uint256);
    
    function distribute(uint256 amount) external;
    
}

// File: contracts/interfaces/ITakepileToken.sol


pragma solidity >=0.8.0;

interface ITakepileToken {
    function getConversion(uint256 _underlying, uint256 _shares) external view returns (uint256);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function placeMarketIncrease(
        string memory symbol,
        uint256 amount,
        uint256 collateral,
        bool isLong
    ) external;

    function placeMarketDecrease(
        string memory symbol,
        uint256 amount,
        uint256 collateral
    ) external;

    function placeLimitIncrease(
        string memory symbol,
        uint256 amount,
        uint256 collateral,
        bool isLong,
        uint256 limitPrice,
        uint256 deadline
    ) external;

    function placeLimitDecrease(
        string calldata symbol,
        uint256 amount,
        uint256 collateral,
        uint256 stopLoss,
        uint256 takeProfit,
        uint256 deadline
    ) external;

    function cancelLimitOrder(string calldata symbol, uint256 index) external;

    function triggerLimitOrder(
        address who,
        string calldata symbol,
        uint256 index
    ) external;

    function getHealthFactor(address who, string calldata symbol) external view returns (int256);

    function liquidate(address who, string calldata symbol) external;
}

// File: contracts/interfaces/ITakepileMarketManager.sol


pragma solidity >=0.8.0;

interface ITakepileMarketManager {
    function addMarket(
        string memory symbol,
        address priceConsumer,
        address priceFeed
    ) external;

    function removeMarket(string memory symbol) external;

    function getLatestPrice(string memory symbol) external view returns (int256);
}

// File: contracts/interfaces/IPriceConsumer.sol


pragma solidity >=0.8.0;

interface IPriceConsumer {
    function getValue(string memory key) external view returns(uint128 value, uint128 timestamp);
}
// File: contracts/interfaces/ITakepileDriver.sol


pragma solidity >=0.8.0;

interface ITakepileDriver {
    function createTakepile(
        address underlying,
        string calldata name,
        string calldata symbol,
        uint256 maxLeverage
    ) external;

    function createVault(string memory name, address token) external;

    function updateTakepileFactory(address _takepileFactory) external;

    function updateDistributorFactory(address _distributorFactory) external;

    function setTakepileDistributionRate(address takepile, uint256 rate) external;

    function setTakepileFeeDivisors(
        address takepile,
        uint256 burnFeeDivisor,
        uint256 treasuryFeeDivisor,
        uint256 distributionFeeDivisor,
        uint256 limitFeeDivisor
    ) external;

    function getTakepileFeeDivisors(address takepile)
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function setTakepileLiquidationRewardDivisor(address takepile, uint256 liquidationRewardDivisor)
        external;

    function getTakepileLiquidationRewardDivisor(address takepile) external view returns (uint256);

    function setTakepileAmountParameters(
        address takepile,
        uint256 maximumAmountDivisor,
        uint256 minimumAmount
    ) external;

    function setTakepileMinimumDuration(address takepile, uint256 minimumDuration) external;

    function setTakepileMinimumDepositDuration(address takepile, uint256 minimumDuration) external;

    function setTakepileTakeRequirement(address takepile, uint256 takeRequirement) external;

    function setVaultDistributionRates(
        address takepile,
        uint256 baseRate,
        uint256 boost1,
        uint256 boost2,
        uint256 boost3
    ) external;

    function getVaultDistributionRate(address vault, uint256 lockup) external returns (uint256);

    function distributeTakeFromTakepile(
        address participant,
        uint256 positionAmount,
        uint256 periods
    ) external;

    function distributeTakeFromVault(
        address participant,
        uint256 positionAmount,
        uint256 periods,
        uint256 lockup
    ) external;

    function calculateDistribution(
        uint256 distributionRate,
        uint256 positionAmount,
        uint256 periods
    ) external view returns (uint256);

    function calculateSimpleInterest(
        uint256 p,
        uint256 r, // r scaled by 1e27
        uint256 t
    ) external pure returns (uint256);

    function calculateReward(
        uint256 amount,
        int256 entryPrice,
        int256 currentPrice,
        bool isLong
    ) external pure returns (int256);

    function getConversion(
        uint256 _underlying,
        uint256 _shares,
        uint256 _underlyingSupply,
        uint256 _totalShares
    ) external pure returns (uint256);

    function validatePositionAmount(
        address _takepile,
        address who,
        uint256 amount
    ) external view;

    function validatePositionDuration(address _takepile, uint256 entryTime)
        external
        view
        returns (bool);

    function validateDepositDuration(address _takepile, uint256 depositTime) external view;

    function validateLiquidator(address liquidator) external view;
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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

// File: contracts/TakepileMarketManager.sol


pragma solidity >=0.8.4;




/// @title TakepileMarketManager
/// @notice responsible for adding/removing markets, and fetching prices from market
contract TakepileMarketManager is Ownable, ITakepileMarketManager {
    struct Market {
        string symbol;
        address priceConsumer;
        address priceFeed;
    }

    mapping(string => Market) public markets; // symbol -> market

    event AddMarket(string symbol, address priceConsumer, address priceFeed);
    event RemoveMarket(string symbol);

    /// @dev Add (or update) market on a Takepile
    /// @dev Currently limited to owner, eventually will be limited to governance contract
    /// @param symbol the symbol of the market to add
    /// @param priceConsumer the address of the priceConsumer contract this market should use
    /// @param priceFeed the address the priceConsumer will get the latest price from
    function addMarket(
        string memory symbol,
        address priceConsumer,
        address priceFeed
    ) public override onlyOwner {
        Market memory market = Market(symbol, priceConsumer, priceFeed);
        markets[symbol] = market;
        emit AddMarket(symbol, priceConsumer, priceFeed);
    }

    /// @dev remove market from a Takepile
    /// @dev Currently limited to owner, eventually will be limited to governance contract
    /// @param symbol the symbol of the market to remove
    function removeMarket(string memory symbol) public override onlyOwner {
        require(markets[symbol].priceConsumer != address(0), "Takepile: market does not exist");
        delete markets[symbol];
        emit RemoveMarket(symbol);
    }

    /// @dev get latest price for market; will revert if market does not exist
    /// @param symbol the symbol to fetch price for
    /// @return the latest price for the market
    function getLatestPrice(string memory symbol) external view override returns (int256) {
        Market memory market = markets[symbol];
        require(market.priceConsumer != address(0), "Takepile: market does not exist");
        (uint128 value, ) = IPriceConsumer(market.priceConsumer).getValue(market.symbol);
        return int256(uint256(value));
    }

}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: contracts/Vault.sol

pragma solidity ^0.8.4;




contract Vault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    string public name;
    address public driver;
    address public token;

    struct Stake {
        uint256 timestamp;
        uint256 lockup; // the original lockup time
        uint256 amount; // the amount of ERC20 tokens that are locked
        uint256 unlock; // when the locked ERC20 tokens can be unstaked
        uint256 nextClaim; // the next time the distribution rewards can be claimed
        uint256 lastUpdated; // updated on distribution
    }

    mapping(address => Stake[]) public stakes; // address -> Stake;

    constructor(
        string memory _name,
        address _driver,
        address _token
    ) {
        name = _name;
        driver = _driver;
        token = _token;
    }

    /// @notice Stake amount for a specific amount of lockup
    /// @param amount the amount of token to stake
    /// @param lockup the lockup period for this staking position
    function stake(uint256 amount, uint256 lockup) external nonReentrant {
        require(
            IERC20(token).balanceOf(msg.sender) >= amount,
            "Vault: insufficient amount to stake"
        );
        stakes[msg.sender].push(
            Stake(
                block.timestamp,
                lockup,
                amount,
                block.timestamp + lockup,
                block.timestamp + 7 days,
                block.timestamp
            )
        );
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Unstake a position at a specific index, for a specific amount
    /// @notice Next claim and unlock period should remain the same
    /// @dev will autoclaim rewards if reward is claimable
    /// @param index the index of msg.sender's staking position to withdraw tokens from
    /// @param amount the amount of token to unstake
    function unstake(uint256 index, uint256 amount) external nonReentrant {
        Stake storage s = stakes[msg.sender][index];
        require(block.timestamp >= s.unlock, "Vault: unlock period not reached");
        require(amount <= s.amount, "Vault: insufficient amount to unstake");
        if (block.timestamp >= s.nextClaim) {
            autoclaim(s);
        }
        s.amount = s.amount - amount;
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    /// @notice Claim rewards for staking position at a given index
    /// @param index the index of msg.sender's staking position to claim rewards on
    function claim(uint256 index) public nonReentrant {
        Stake storage s = stakes[msg.sender][index];
        require(block.timestamp >= s.nextClaim, "Vault: next claim period not reached");

        uint256 elapsed = block.timestamp - s.lastUpdated;
        s.lastUpdated = block.timestamp;
        s.nextClaim = block.timestamp + 7 days;

        ITakepileDriver(driver).distributeTakeFromVault(msg.sender, s.amount, elapsed, s.lockup);
    }

    /// @notice internal autoclaim function
    /// @param s Stake struct
    function autoclaim(Stake storage s) internal {
        uint256 elapsed = block.timestamp - s.lastUpdated;
        s.lastUpdated = block.timestamp;
        s.nextClaim = block.timestamp + 7 days;
        ITakepileDriver(driver).distributeTakeFromVault(msg.sender, s.amount, elapsed, s.lockup);
    }

    /// @notice get the maximum number of staking positions a user has
    /// @param user the address of the user to check
    function getStakeCount(address user) public view returns (uint256) {
        return stakes[user].length;
    }

    /// @notice get the amount available to claim for a given stake
    /// @param index the index of msg.sender's staking position to get available claims for
    function getAvailableClaim(uint256 index) public returns (uint256) {
        Stake storage s = stakes[msg.sender][index];
        if (block.timestamp <= s.nextClaim) return 0;
        uint256 elapsed = block.timestamp - s.lastUpdated;

        uint256 rate = ITakepileDriver(driver).getVaultDistributionRate(address(this), s.lockup);
        return ITakepileDriver(driver).calculateDistribution(rate, s.amount, elapsed);
    }
}

// File: contracts/TakepileDriver.sol

pragma solidity >=0.8.4;




/// @title TakepileDriver Contract
/// @notice Responsible for creation of new Takepiles and Vaults,
/// @notice as well as management of their configurations
contract TakepileToken is ERC20, TakepileMarketManager, ITakepileToken {
    using Address for address;
    using SafeERC20 for ERC20;

    /// @notice Takepile V1
    uint256 public version = 1;

    /// @notice the Takepile's underlying ERC-20 token
    address public underlying;

    /// @notice the Takepile's driver contract
    address public driver;

    /// @notice the Takepile's distribution contract
    address public distributor;

    /// @notice the max leverage someone can use on a position
    /// @notice leverage is determined by calculating the ratio between position amount and collateral
    uint256 public maxLeverage; // The max leverage someone can use on a position

    /// @notice the address that last triggered a liquidation
    address public lastLiquidator;

    struct Position {
        string symbol; // the market symbol
        uint256 amount; // the total position size
        uint256 collateral; // the amount of collateral staked on the trade
        int256 price; // the position's entry price
        bool isLong; // true if long, false if short
        uint256 timestamp; // position creation time
        uint256 lastUpdated; // the last time this position was updated
    }

    struct LimitOrder {
        string symbol; // the market symbol
        uint256 amount; // the total position size for the order
        uint256 collateral; // the collateral staked on the order
        bool isLong; // true if long order, false if short order
        bool isIncrease; // true if increase, false if decrease
        bool isActive; // true if untriggered, false if triggered or cancelled
        uint256 limitPrice; // (increase only) the price at which the order should trigger
        uint256 stopLoss; // (decrease only) the price below current price at which decrease should
        uint256 takeProfit; // (decrease only) the price above current price at which decrease should
        uint256 timestamp; // the time order was submitted
        uint256 deadline; // the date at which this order becomes invalid (untriggerable)
        uint256 lastUpdated; // the last time this order was updated
    }

    /// @notice address -> market --> position
    /// @notice address can only have one position in each market at a time
    mapping(address => mapping(string => Position)) public positions;

    /// @notice address -> market --> limit orders
    /// @notice address can have multiple limit orders in each market at a time
    mapping(address => mapping(string => LimitOrder[])) public limitOrders;

    /// @notice address -> amount of pileToken already transferred to contract waiting for position
    mapping(address => uint256) private tempBalances;

    /// @notice track last deposit per address
    mapping(address => uint256) private lastDeposit;

    event Deposit(address indexed who, uint256 _underlying, uint256 _shares);
    event Withdraw(address indexed who, uint256 _underlying, uint256 _shares);
    event SupplyUpdate(uint256 _underlying, uint256 _shares);
    event IncreasePosition(
        address indexed who,
        string symbol,
        uint256 amount,
        uint256 newAmount,
        bool isLong,
        int256 price,
        uint256 fees
    );
    event DecreasePosition(
        address indexed who,
        string symbol,
        uint256 amount,
        uint256 newAmount,
        bool isLong,
        int256 price,
        int256 reward,
        uint256 fees
    );
    // TODO Bug: decrease limit orders have no way of specifying stop loss and take profit here
    // limitPrice is takeProfit for decreasePositions
    // stopLoss is 0 for increasePositions
    event LimitOrderSubmitted(
        address indexed who,
        string symbol,
        uint256 amount,
        uint256 collateral,
        bool isLong,
        uint256 limitPrice,
        uint256 stopLoss,
        uint256 index,
        uint256 deadline
    );
    event LimitOrderCancelled(address indexed who, string symbol, uint256 index);
    event LimitOrderTriggered(address indexed who, string symbol, uint256 index, address by);

    constructor(
        address _driver,
        address _xTakeFactory,
        address _underlying,
        string memory _name,
        string memory _symbol,
        uint256 _maxLeverage
    ) ERC20(_name, _symbol) {
        driver = _driver;
        underlying = _underlying;
        maxLeverage = _maxLeverage;

        // Initialize xTake fee distributor
        distributor = IxTakeFactory(_xTakeFactory).createDistributor(
            TakepileDriver(_driver).TAKE(),
            address(this),
            _symbol
        );
    }

    /// @dev get conversion between underlying and shares (one parameter must be non-zero)
    /// @param _underlying the amount of underlying to convert to shares
    /// @param _shares the amount of shares to convert to underlying
    function getConversion(uint256 _underlying, uint256 _shares)
        public
        view
        override
        returns (uint256)
    {
        return
            TakepileDriver(driver).getConversion(
                _underlying,
                _shares,
                ERC20(underlying).balanceOf(address(this)),
                this.totalSupply()
            );
    }

    /// @dev supply underlying in exchange for shares
    /// @dev shares will be minted according to the current exchange rate
    /// @param amount the amount of underlying to deposit into the Takepile
    function deposit(uint256 amount) external override {
        require(amount > 0, "Takepile: amount cannot be zero");

        // Track last deposit time
        lastDeposit[msg.sender] = block.timestamp;

        // Get amount to mint by calculating exchange for underlying
        uint256 mintAmount = getConversion(amount, 0);
        ERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, mintAmount);

        emit Deposit(msg.sender, amount, mintAmount);
    }

    /// @dev withdraw shares in exchange for underlying (shares will be burned)
    /// @param amount the amount of shares to withdraw from the Takepile in exchange for underlying
    function withdraw(uint256 amount) external override {
        require(amount > 0, "Takepile: amount cannot be zero");

        uint256 shares = balanceOf(msg.sender);
        require(shares >= amount, "Takepile: insufficient balance");

        // Ensure last deposit was greater than minimum deposit duration
        TakepileDriver(driver).validateDepositDuration(address(this), lastDeposit[msg.sender]);

        // Get amount to transfer by calculating underying exchange for shares
        uint256 transferAmount = getConversion(0, amount);
        _burn(msg.sender, amount);
        ERC20(underlying).safeTransfer(msg.sender, transferAmount);

        emit Withdraw(msg.sender, transferAmount, amount);
    }

    /// @notice take fees from amount
    /// @param amount the order amount to take fees from
    /// @param isLimitOrder true if limit order, false otherwise
    /// @param triggerer the address that triggered the limit order; only applies when isLimitOrder is true
    function takeFees(
        uint256 amount,
        bool isLimitOrder,
        address triggerer
    ) internal returns (uint256) {
        (
            uint256 burnFeeDivisor,
            uint256 treasuryFeeDivisor,
            uint256 distributionFeeDivisor,
            uint256 limitFeeDivisor
        ) = TakepileDriver(driver).getTakepileFeeDivisors(address(this));

        uint256 burnFee = burnFeeDivisor > 0 ? amount / burnFeeDivisor : 0;
        uint256 treasuryFee = treasuryFeeDivisor > 0 ? amount / treasuryFeeDivisor : 0;
        uint256 distributionFee = distributionFeeDivisor > 0 ? amount / distributionFeeDivisor : 0;
        uint256 limitFee;

        _burn(address(this), burnFee);

        // Transfer treasuryFee to treasury
        this.transfer(TakepileDriver(driver).treasury(), treasuryFee);

        if (distributionFee > 0) {
            IERC20(address(this)).approve(distributor, distributionFee);
            IxTake(distributor).distribute(distributionFee);
        }

        if (isLimitOrder) {
            limitFee = limitFeeDivisor > 0 ? amount / limitFeeDivisor : 0;
            uint256 triggererFee = limitFee / 2;

            this.transfer(address(triggerer), triggererFee);
            this.transfer(TakepileDriver(driver).treasury(), limitFee - triggererFee);
        }

        return amount - burnFee - treasuryFee - distributionFee - limitFee;
    }

    /// @notice increase an existing position
    /// @notice assumes transfer has already taken place!
    /// @param who the address to increase position for
    /// @param symbol the market symbol to increase position for
    /// @param amount the pile token amount to increase position by
    /// @param collateral the amount of collateral to add to position
    /// @param isLong true if long, false otherwise
    /// @param isLimitOrder true if limit order, false otherwise
    /// @param triggerer the address that triggered the limit order
    function increasePosition(
        address who,
        string memory symbol,
        uint256 amount,
        uint256 collateral,
        bool isLong,
        bool isLimitOrder,
        address triggerer
    ) internal {
        int256 currentPrice = this.getLatestPrice(symbol);
        Position storage position = positions[who][symbol];

        // Take from user's balance
        tempBalances[who] -= amount;

        uint256 amountMinusFees = takeFees(amount, isLimitOrder, triggerer);
        uint256 fees = amount - amountMinusFees;
        uint256 collateralMinusFees = collateral - fees;

        if (position.amount > 0) {
            require(position.isLong == isLong, "Takepile: conflicting directions");

            // Distribute TAKE here on original collateral amount before position.lastUpdated is set
            bool isRewardable = TakepileDriver(driver).validatePositionDuration(
                address(this),
                position.timestamp
            );
            if (isRewardable) {
                TakepileDriver(driver).distributeTakeFromTakepile(
                    who,
                    collateral,
                    block.timestamp - position.lastUpdated
                );
            }

            // update entry price and amount
            position.price =
                ((currentPrice * int256(amountMinusFees)) +
                    (position.price * int256(position.amount))) /
                int256(amountMinusFees + position.amount);
            position.amount += amountMinusFees;
            position.collateral += collateralMinusFees;
            position.lastUpdated = block.timestamp;
        } else {
            // create the position
            positions[who][symbol] = Position(
                symbol,
                amountMinusFees,
                collateralMinusFees,
                currentPrice,
                isLong,
                block.timestamp,
                block.timestamp
            );
        }

        require(
            (position.amount * 1e18) / position.collateral <= maxLeverage * 1e18,
            "Takepile: maximum leverage exceeded"
        );

        TakepileDriver(driver).validatePositionAmount(address(this), who, position.amount);

        emit IncreasePosition(who, symbol, amount, position.amount, isLong, currentPrice, fees);
    }

    /// @notice decrease an existing position
    /// @param who the address to decrease position for
    /// @param symbol the market symbol to decrease position for
    /// @param amount the pile token amount to decrease position by
    /// @param isLimitOrder true if order is a limit order, false otherwise
    /// @param triggerer the address that triggered the limit order
    function decreasePosition(
        address who,
        string memory symbol,
        uint256 amount,
        uint256 collateral,
        bool isLimitOrder,
        address triggerer
    ) internal {
        Position storage position = positions[who][symbol];
        require(position.amount > 0, "Takepile: position does not exist");

        // If decrease by more than position/collateral amount, set to max amount
        if (amount > position.amount) {
            amount = position.amount;
        }
        if (collateral > position.collateral) {
            collateral = position.collateral;
        }

        int256 price = this.getLatestPrice(symbol);
        int256 reward = TakepileDriver(driver).calculateReward(
            amount,
            position.price,
            price,
            position.isLong
        );

        // Check if position has been opened for sufficient duration to receive rewards
        bool isRewardable = TakepileDriver(driver).validatePositionDuration(
            address(this),
            position.timestamp
        );

        // If position has a positive reward but not rewardable, set to 0
        if (!isRewardable && reward > 0) {
            reward = 0;
        }

        // NOTE: cannot safely cast negative int to uint
        uint256 exitAmount = reward >= 0 ? amount + uint256(reward) : amount - uint256(-reward);
        uint256 exitAmountAfterFees = takeFees(exitAmount, isLimitOrder, triggerer);
        uint256 fees = exitAmount - exitAmountAfterFees;

        position.amount -= amount;
        position.collateral -= collateral;

        if (position.amount > 0) {
            require(position.collateral > 0, "Takepile: no collateral left");
            require(
                (position.amount * 1e18) / position.collateral <= maxLeverage * 1e18,
                "Takepile: maximum leverage exceeded"
            );
        } else {
            require(position.collateral == 0, "Takepile: collateral leftover");
        }

        // Call Driver for TAKE distribution
        if (isRewardable) {
            TakepileDriver(driver).distributeTakeFromTakepile(
                who,
                collateral,
                block.timestamp - position.lastUpdated
            );
        }
        position.lastUpdated = block.timestamp;

        // Transfer before burning to ensure there's enough to burn
        this.transfer(who, collateral - fees);

        if (reward > 0) {
            _mint(who, uint256(reward));
        } else {
            uint256 burnAmount = uint256(-reward);
            // If loss is greater than exit collateral, burn all transferred collateral
            // This should happen rarely, since the position has to be liquidatable for this to occur
            if (burnAmount > collateral - fees) {
                _burn(who, collateral - fees);
            } else {
                _burn(who, burnAmount);
            }
        }

        if (position.amount == 0) {
            delete positions[msg.sender][symbol];
        } else {
            TakepileDriver(driver).validatePositionAmount(address(this), who, position.amount);
        }

        emit DecreasePosition(
            who,
            symbol,
            amount,
            position.amount,
            position.isLong,
            price,
            reward,
            fees
        );
        emit SupplyUpdate(ERC20(underlying).balanceOf(address(this)), this.totalSupply());
    }

    /// @notice enter a position
    /// @notice can only one position per market
    /// @param symbol the market symbol to enter position on
    /// @param amount the amount of pileToken to stake on the position
    /// @param isLong true for long, false for short
    function placeMarketIncrease(
        string memory symbol,
        uint256 amount,
        uint256 collateral,
        bool isLong
    ) external override {
        require(this.balanceOf(msg.sender) >= collateral, "Takepile: insufficient balance");
        require(collateral > 0, "Takepile: collateral cannot be zero");

        this.transferFrom(msg.sender, address(this), collateral);
        tempBalances[msg.sender] += amount;

        return increasePosition(msg.sender, symbol, amount, collateral, isLong, false, address(0));
    }

    /// @notice exit a position
    /// @notice calls driver function to distribute TAKE based (if Takepile distribution rate set)
    /// @param symbol the symbol of the position to close
    function placeMarketDecrease(
        string memory symbol,
        uint256 amount,
        uint256 collateral
    ) external override {
        return decreasePosition(msg.sender, symbol, amount, collateral, false, address(0));
    }

    /// @notice place limit entry order
    /// @param symbol the market symbol
    /// @param amount the amount of pileTokens to stake on trade
    /// @param isLong true if long, false if short
    /// @param limitPrice the entry threshold
    /// @param deadline the timestamp at wich this order is no longer considered valid
    function placeLimitIncrease(
        string memory symbol,
        uint256 amount,
        uint256 collateral,
        bool isLong,
        uint256 limitPrice,
        uint256 deadline
    ) external override {
        require(amount > 0, "Takepile: amount cannot be zero");
        require(deadline > block.timestamp, "Takepile: order expired");
        require(this.balanceOf(msg.sender) >= collateral, "Takepile: insufficient balance");

        this.transferFrom(msg.sender, address(this), collateral);

        tempBalances[msg.sender] += amount;

        int256 price = this.getLatestPrice(symbol);
        if (isLong) {
            require(price > int256(limitPrice), "Takepile: long order would trigger immediately");
        } else {
            require(price < int256(limitPrice), "Takepile: short order would trigger immediately");
        }

        LimitOrder[] storage orders = limitOrders[msg.sender][symbol];

        orders.push(
            LimitOrder(
                symbol,
                amount,
                collateral,
                isLong,
                true,
                true,
                limitPrice,
                0,
                0,
                block.timestamp,
                deadline,
                block.timestamp
            )
        );

        emit LimitOrderSubmitted(
            msg.sender,
            symbol,
            amount,
            collateral,
            isLong,
            limitPrice,
            0,
            orders.length - 1,
            deadline
        );
    }

    /// @notice place limit order to decrease existing position
    /// @param symbol the market symbol
    /// @param amount the amount of pileTokens to stake on trade
    /// @param stopLoss the low exit threshold
    /// @param takeProfit the high exit threshold
    /// @param deadline the timestamp at wich this order is no longer considered valid
    function placeLimitDecrease(
        string calldata symbol,
        uint256 amount,
        uint256 collateral,
        uint256 stopLoss,
        uint256 takeProfit,
        uint256 deadline
    ) external override {
        require(deadline > block.timestamp, "Takepile: order expired");
        Position memory position = positions[msg.sender][symbol];
        require(position.amount > 0, "Takepile: position does not exist");

        uint256 price = uint256(this.getLatestPrice(symbol));
        if (position.isLong) {
            require(
                price > stopLoss && price < takeProfit,
                "Takepile: order would trigger immediately"
            );
        } else {
            require(
                price < stopLoss && price > takeProfit,
                "Takepile: order would trigger immediately"
            );
        }

        LimitOrder[] storage orders = limitOrders[msg.sender][symbol];

        orders.push(
            LimitOrder(
                symbol,
                amount,
                collateral,
                position.isLong,
                false,
                true,
                0,
                stopLoss,
                takeProfit,
                block.timestamp,
                deadline,
                block.timestamp
            )
        );

        emit LimitOrderSubmitted(
            msg.sender,
            symbol,
            amount,
            collateral,
            position.isLong,
            takeProfit,
            stopLoss,
            orders.length - 1,
            deadline
        );
    }

    /// @notice cancel limit order
    /// @notice fees are not taken on cancelled limit orders
    /// @param symbol the limit order to cancel
    function cancelLimitOrder(string calldata symbol, uint256 index) external override {
        LimitOrder storage limitOrder = limitOrders[msg.sender][symbol][index];
        require(limitOrder.amount > 0, "Takepile: order does not exist");
        require(limitOrder.isActive, "Takepile: order inactive");
        limitOrder.isActive = false;
        limitOrder.lastUpdated = block.timestamp;
        if (limitOrder.isIncrease) {
            tempBalances[msg.sender] -= limitOrder.amount;
            this.transfer(msg.sender, limitOrder.collateral);
        }
        emit LimitOrderCancelled(msg.sender, symbol, index);
    }

    /// @notice trigger a limit order
    /// @param who the address to trigger limit order for
    /// @param symbol the symbol to trigger limit order for
    function triggerLimitOrder(
        address who,
        string calldata symbol,
        uint256 index
    ) external override {
        require(limitOrders[who][symbol].length > 0, "Takepile: order does not exist");
        LimitOrder storage limitOrder = limitOrders[who][symbol][index];
        require(limitOrder.amount > 0, "Takepile: order does not exist");
        require(limitOrder.isActive, "Takepile: order inactive");
        int256 price = this.getLatestPrice(limitOrder.symbol);

        limitOrder.isActive = false;
        limitOrder.lastUpdated = block.timestamp;

        if (limitOrder.isIncrease) {
            if (limitOrder.isLong) {
                require(
                    uint256(price) <= limitOrder.limitPrice,
                    "Takepile: conditions not satisfied"
                );
            } else {
                require(
                    uint256(price) >= limitOrder.limitPrice,
                    "Takepile: conditions not satisfied"
                );
            }
            increasePosition(
                who,
                symbol,
                limitOrder.amount,
                limitOrder.collateral,
                limitOrder.isLong,
                true,
                msg.sender
            );
        } else {
            if (limitOrder.isLong) {
                require(
                    uint256(price) <= limitOrder.stopLoss ||
                        uint256(price) >= limitOrder.takeProfit,
                    "Takepile: conditions not satisfied"
                );
            } else {
                require(
                    uint256(price) >= limitOrder.stopLoss ||
                        uint256(price) <= limitOrder.takeProfit,
                    "Takepile: conditions not satisfied"
                );
            }
            decreasePosition(
                who,
                symbol,
                limitOrder.amount,
                limitOrder.collateral,
                true,
                msg.sender
            );
        }
        emit LimitOrderTriggered(who, symbol, index, msg.sender);
    }

    /// @notice Get health factor for a position
    /// @param who the address to check
    /// @param symbol the position symbol to check
    /// @return factor the position health factor; if greater than 1e18, position is at risk of liquidation
    function getHealthFactor(address who, string calldata symbol)
        external
        view
        override
        returns (int256)
    {
        Position memory position = positions[who][symbol];
        if (position.amount == 0) return 0;
        int256 leverage = (int256(position.amount) * 1e18) / int256(position.collateral);
        int256 price = this.getLatestPrice(symbol);
        int256 factor = ((position.price - price) * leverage) / position.price;
        return position.isLong ? factor : -factor;
    }

    /// @notice liquidate an unhealthy position
    /// @notice liquidator and treasury will receive the same reward (taken from config in driver)
    /// @notice any amount not rewarded is burned
    /// @param who the address with position to liquidate
    /// @param symbol the symbol to liquidate
    function liquidate(address who, string calldata symbol) external override {
        Position storage position = positions[who][symbol];
        require(position.amount > 0, "Takepile: position does not exist");
        require(this.getHealthFactor(who, symbol) > 1e18, "Takepile: position is not liquidatable");

        // Ensure liquidator has a liquidation pass
        TakepileDriver(driver).validateLiquidator(msg.sender);

        // Ensure same liquidator does not trigger back-to-back liquidations
        require(lastLiquidator != msg.sender, "Takepile: cannot trigger back-to-back liquidations");

        uint256 divisor = TakepileDriver(driver).getTakepileLiquidationRewardDivisor(address(this));
        uint256 rewardAmount = divisor > 0 ? position.collateral / divisor : 0;
        uint256 remainder = position.collateral - rewardAmount;
        uint256 amount = position.amount;

        position.amount = 0;
        position.collateral = 0;
        position.lastUpdated = block.timestamp;

        // Set last liquidator
        lastLiquidator = msg.sender;

        // Transfer reward to liquidator
        this.transfer(msg.sender, rewardAmount);

        // Transfer treasuryAmount to treasury
        this.transfer(TakepileDriver(driver).treasury(), remainder);

        emit SupplyUpdate(ERC20(underlying).balanceOf(address(this)), this.totalSupply());
        emit DecreasePosition(
            who,
            symbol,
            amount,
            0,
            position.isLong,
            this.getLatestPrice(symbol),
            -int256(amount),
            amount
        );
    }
}


/// @title TakepileFactory Contract
/// @notice responsible for creation of new takepiles
contract TakepileFactory is ITakepileFactory, Ownable {
    /// @notice Create a new Takepile and transfer ownership to sender
    function createTakepile(
        address driver,
        address _xTakeFactory,
        address underlying,
        string calldata name,
        string calldata symbol,
        uint256 maxLeverage
    ) external override onlyOwner returns (address) {
        TakepileToken takepile = new TakepileToken(
            driver,
            _xTakeFactory,
            underlying,
            name,
            symbol,
            maxLeverage
        );
        takepile.transferOwnership(msg.sender);
        return address(takepile);
    }
}


contract TakepileDriver is ITakepileDriver, Ownable {
    using Address for address;
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    /// @notice Emitted when a Takepile is created
    event TakepileCreated(address takepile, string name, string symbol);

    /// @notice Emitted when a Vault is created
    event VaultCreated(address vault);

    /// @notice Emitted when the Takepile Factory contract is updated
    event TakepileFactoryUpdated(address takepileFactory);

    /// @notice Emitted when the Takepile Treasury contract is updated
    event TakepileTreasuryUpdated(address takepileTreasury);

    /// @notice Emitted when the Distributor Factory contract is updated
    event DistributorFactoryUpdated(address distributorFactory);

    /// @notice Emitted when a Takepile's configuration is updated
    event TakepileConfigUpdated(
        address takepile,
        uint256 distributionRate,
        uint256 burnFeeDivisor,
        uint256 treasuryFeeDivisor,
        uint256 distributionFeeDivisor,
        uint256 limitFeeDivisor,
        uint256 liquidationRewardDivisor,
        uint256 maximumAmountDivisor,
        uint256 minimumAmount,
        uint256 minimumDuration,
        uint256 minimumDepositDuration,
        uint256 takeRequirement
    );

    /// @notice Emitted when a Vault's distribution rate is updated
    event VaultConfigUpdated(
        address vault,
        uint256 rate0,
        uint256 rate1,
        uint256 rate2,
        uint256 rate3
    );

    /// @notice Takepile Distribution Configurations
    /// @dev For fees: position.amount / divisor = fee
    /// @dev manipulatable Takepile configuration elements are defined here; static ones on Takepile
    struct TakepileConfig {
        uint256 timestamp;
        uint256 distributionRate; // distribution rate per second, scaled by 1e27
        uint256 burnFeeDivisor;
        uint256 treasuryFeeDivisor;
        uint256 distributionFeeDivisor;
        uint256 limitFeeDivisor;
        uint256 liquidationRewardDivisor;
        uint256 maximumAmountDivisor; // position.amount must be < position.amount / maximumAmountDivisor
        uint256 minimumAmount; // position.amount must be > minimumAmount
        uint256 minimumDuration; // the minimum position duration for rewards
        uint256 minimumDepositDuration; // the minimum amount of time to wait after deposit before withdrawal permitted
        uint256 takeRequirement; // the minimum amount of TAKE needed by a user to place a trade
    }

    /// @notice Vault Distribution Configurations
    struct VaultConfig {
        uint256 timestamp;
        uint256 rate0; // base rate for no unlock period
        uint256 rate1; // rate for lockups >= 30 days
        uint256 rate2; // rate for lockups >= 180 days
        uint256 rate3; // rate for lockups >= 365 days
    }

    /// @notice the Takepile Governance token address
    address public TAKE;

    /// @notice the Takepile takepileFactory contract address
    address public takepileFactory;

    /// @notice the Takepile Fee Distributor contract address
    address public distributorFactory;

    /// @notice the Takepile treasury address
    address public treasury;

    /// @notice the Takepile Liquidation Pass NFT address
    address public liquidationPass;

    /// @notice official takepiles
    address[] public takepiles;

    /// @notice offical ERC20 token vaults
    address[] public vaults;

    /// @notice Takepile configurations
    mapping(address => TakepileConfig) public takepileConfig;

    /// @notice Vault configurations
    mapping(address => VaultConfig) public vaultConfig;

    /// @notice only registered takepiles
    modifier onlyTakepile() {
        require(takepileConfig[msg.sender].timestamp > 0, "Takepile: Takepile does not exist");
        _;
    }

    /// @notice only registered vaults
    modifier onlyVault() {
        require(vaultConfig[msg.sender].timestamp > 0, "Takepile: Vault does not exist");
        _;
    }

    /// @notice TakepileDriver constructor
    /// @param _TAKE the TAKE governance token address
    constructor(
        address _TAKE,
        address _takepileFactory,
        address _xTakeFactory,
        address _treasury,
        address _liquidationPass
    ) {
        transferOwnership(msg.sender);
        TAKE = _TAKE;
        takepileFactory = _takepileFactory;
        distributorFactory = _xTakeFactory;
        treasury = _treasury;
        liquidationPass = _liquidationPass;
        emit TakepileFactoryUpdated(takepileFactory);
        emit DistributorFactoryUpdated(distributorFactory);
    }

    /// @notice create a new Takepile
    /// @param underlying the Takepile's underlying ERC-20 token address
    function createTakepile(
        address underlying,
        string calldata name,
        string calldata symbol,
        uint256 maxLeverage
    ) external override onlyOwner {
        address takepile = TakepileFactory(takepileFactory).createTakepile(
            address(this),
            distributorFactory,
            underlying,
            name,
            symbol,
            maxLeverage
        );
        TakepileConfig memory _config = TakepileConfig(
            block.timestamp,
            0,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0
        );
        takepileConfig[address(takepile)] = _config;
        takepiles.push(address(takepile));
        TakepileToken(takepile).transferOwnership(msg.sender);
        emit TakepileCreated(address(takepile), name, symbol);
        emit TakepileConfigUpdated(address(takepile), 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0);
    }

    /// @notice create a new ERC20 token vault
    /// @param token the Vault's lpToken
    function createVault(string memory name, address token) external override onlyOwner {
        Vault vault = new Vault(name, address(this), token);
        VaultConfig memory _config = VaultConfig(block.timestamp, 0, 0, 0, 0);
        vaultConfig[address(vault)] = _config;
        vaults.push(address(vault));
        emit VaultCreated(address(vault));
        emit VaultConfigUpdated(address(vault), 0, 0, 0, 0);
    }

    /// @notice update the Takepile Factory contract
    /// @param _takepileFactory the new takepile factory address to use
    function updateTakepileFactory(address _takepileFactory) external override onlyOwner {
        takepileFactory = _takepileFactory;
        emit TakepileFactoryUpdated(_takepileFactory);
    }

    /// @notice update the Takepile Treasury contract
    /// @param _treasury the new takepile treasury address to use
    function updateTakepileTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        //emit TakepileTreasuryUpdated(_treasury);
    }

    /// @notice update the Distributor Factory contract
    /// @param _distributorFactory the new distributor factory address to use
    function updateDistributorFactory(address _distributorFactory) external override onlyOwner {
        distributorFactory = _distributorFactory;
        emit DistributorFactoryUpdated(_distributorFactory);
    }

    /// @notice set a Takepile's distribution rate
    /// @param takepile the Takepile address
    /// @param rate the distribution rate (per second, per pile token) to set
    function setTakepileDistributionRate(address takepile, uint256 rate)
        external
        override
        onlyOwner
    {
        TakepileConfig storage config = takepileConfig[takepile];
        require(config.timestamp > 0, "Takepile: takepile does not exist");
        config.distributionRate = rate;
        emit TakepileConfigUpdated(
            takepile,
            rate,
            config.burnFeeDivisor,
            config.treasuryFeeDivisor,
            config.distributionFeeDivisor,
            config.limitFeeDivisor,
            config.liquidationRewardDivisor,
            config.maximumAmountDivisor,
            config.minimumAmount,
            config.minimumDuration,
            config.minimumDepositDuration,
            config.takeRequirement
        );
    }

    /// @notice set a Takepile's fee divisors
    /// @dev will divide position amount by each divisor to determine fee
    /// @param takepile the address of the takepile to update
    /// @param burnFeeDivisor the burn fee divisor
    /// @param treasuryFeeDivisor the treasury fee divisor
    /// @param distributionFeeDivisor the distribution fee divisor
    /// @param limitFeeDivisor the limit fee divisor
    function setTakepileFeeDivisors(
        address takepile,
        uint256 burnFeeDivisor,
        uint256 treasuryFeeDivisor,
        uint256 distributionFeeDivisor,
        uint256 limitFeeDivisor
    ) external override onlyOwner {
        TakepileConfig storage config = takepileConfig[takepile];
        require(config.timestamp > 0, "Takepile: configuration not found");
        config.burnFeeDivisor = burnFeeDivisor;
        config.treasuryFeeDivisor = treasuryFeeDivisor;
        config.distributionFeeDivisor = distributionFeeDivisor;
        config.limitFeeDivisor = limitFeeDivisor;
        emit TakepileConfigUpdated(
            takepile,
            config.distributionRate,
            config.burnFeeDivisor,
            config.treasuryFeeDivisor,
            config.distributionFeeDivisor,
            config.limitFeeDivisor,
            config.liquidationRewardDivisor,
            config.maximumAmountDivisor,
            config.minimumAmount,
            config.minimumDuration,
            config.minimumDepositDuration,
            config.takeRequirement
        );
    }

    /// @notice get Takepile fee divisors
    /// @param takepile the address of the takepile to get fee divisors for
    function getTakepileFeeDivisors(address takepile)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        TakepileConfig memory config = takepileConfig[takepile];
        return (
            config.burnFeeDivisor,
            config.treasuryFeeDivisor,
            config.distributionFeeDivisor,
            config.limitFeeDivisor
        );
    }

    /// @notice set a Takepile's liquidation reward divisor
    /// @param takepile the address of the takepile to update
    /// @param liquidationRewardDivisor the liquidation reward divisor
    function setTakepileLiquidationRewardDivisor(address takepile, uint256 liquidationRewardDivisor)
        external
        override
        onlyOwner
    {
        TakepileConfig storage config = takepileConfig[takepile];
        require(config.timestamp > 0, "Takepile: configuration not found");
        config.liquidationRewardDivisor = liquidationRewardDivisor;
        emit TakepileConfigUpdated(
            takepile,
            config.distributionRate,
            config.burnFeeDivisor,
            config.treasuryFeeDivisor,
            config.distributionFeeDivisor,
            config.limitFeeDivisor,
            config.liquidationRewardDivisor,
            config.maximumAmountDivisor,
            config.minimumAmount,
            config.minimumDuration,
            config.minimumDepositDuration,
            config.takeRequirement
        );
    }

    /// @notice get a Takepile's liquidation reward divisor
    /// @param takepile the address of the takepile to get liquidation reward divisor for
    function getTakepileLiquidationRewardDivisor(address takepile)
        external
        view
        override
        returns (uint256)
    {
        TakepileConfig memory config = takepileConfig[takepile];
        return config.liquidationRewardDivisor;
    }

    /// @notice set a Takepile's maximum amount divisor (relative) and minimum amount (absolute)
    function setTakepileAmountParameters(
        address takepile,
        uint256 maximumAmountDivisor,
        uint256 minimumAmount
    ) external override onlyOwner {
        TakepileConfig storage config = takepileConfig[takepile];
        require(config.timestamp > 0, "Takepile: configuration not found");
        config.maximumAmountDivisor = maximumAmountDivisor;
        config.minimumAmount = minimumAmount;
        emit TakepileConfigUpdated(
            takepile,
            config.distributionRate,
            config.burnFeeDivisor,
            config.treasuryFeeDivisor,
            config.distributionFeeDivisor,
            config.limitFeeDivisor,
            config.liquidationRewardDivisor,
            config.maximumAmountDivisor,
            config.minimumAmount,
            config.minimumDuration,
            config.minimumDepositDuration,
            config.takeRequirement
        );
    }

    /// @notice set a Takepile's minimum position duration for rewards
    /// @param takepile the address of the takpile
    /// @param minimumDuration the minimum duration (in seconds) a position needs to be open for before being applicable for rewards
    function setTakepileMinimumDuration(address takepile, uint256 minimumDuration)
        external
        override
        onlyOwner
    {
        TakepileConfig storage config = takepileConfig[takepile];
        require(config.timestamp > 0, "Takepile: configuration not found");
        config.minimumDuration = minimumDuration;
        emit TakepileConfigUpdated(
            takepile,
            config.distributionRate,
            config.burnFeeDivisor,
            config.treasuryFeeDivisor,
            config.distributionFeeDivisor,
            config.limitFeeDivisor,
            config.liquidationRewardDivisor,
            config.maximumAmountDivisor,
            config.minimumAmount,
            config.minimumDuration,
            config.minimumDepositDuration,
            config.takeRequirement
        );
    }

    /// @notice set a Takepile's minimum depsoit duration before withdrawals permitted
    /// @param takepile the address of the takpile
    /// @param minimumDuration the minimum duration (in seconds) after a deposit before withdrawal allowed
    function setTakepileMinimumDepositDuration(address takepile, uint256 minimumDuration)
        external
        override
        onlyOwner
    {
        TakepileConfig storage config = takepileConfig[takepile];
        require(config.timestamp > 0, "Takepile: configuration not found");
        config.minimumDepositDuration = minimumDuration;
        emit TakepileConfigUpdated(
            takepile,
            config.distributionRate,
            config.burnFeeDivisor,
            config.treasuryFeeDivisor,
            config.distributionFeeDivisor,
            config.limitFeeDivisor,
            config.liquidationRewardDivisor,
            config.maximumAmountDivisor,
            config.minimumAmount,
            config.minimumDuration,
            config.minimumDepositDuration,
            config.takeRequirement
        );
    }

    /// @notice set a Takepile's minimum TAKE requirement
    /// @notice users will need a balance of at least takeRequirement TAKE to enter a position
    function setTakepileTakeRequirement(address takepile, uint256 takeRequirement)
        external
        override
        onlyOwner
    {
        TakepileConfig storage config = takepileConfig[takepile];
        require(config.timestamp > 0, "Takepile: configuration not found");
        config.takeRequirement = takeRequirement;
        emit TakepileConfigUpdated(
            takepile,
            config.distributionRate,
            config.burnFeeDivisor,
            config.treasuryFeeDivisor,
            config.distributionFeeDivisor,
            config.limitFeeDivisor,
            config.liquidationRewardDivisor,
            config.maximumAmountDivisor,
            config.minimumAmount,
            config.minimumDuration,
            config.minimumDepositDuration,
            config.takeRequirement
        );
    }

    /// @notice set a Vault's  distribution rate
    /// @param vault the Takepile address
    /// @param rate0 the distribution rate (per second, per pile token) for no lock period
    /// @param rate1 the distribution rate for 1 month lockup
    /// @param rate2 the distribution rate for 6 month lockup
    /// @param rate3 the distribution rate for 12 month lockup
    function setVaultDistributionRates(
        address vault,
        uint256 rate0,
        uint256 rate1,
        uint256 rate2,
        uint256 rate3
    ) external override onlyOwner {
        VaultConfig storage config = vaultConfig[vault];
        require(config.timestamp > 0, "Takepile: vault does not exist");
        config.rate0 = rate0;
        config.rate1 = rate1;
        config.rate2 = rate2;
        config.rate3 = rate3;
        emit VaultConfigUpdated(vault, rate0, rate1, rate2, rate3);
    }

    /// @notice Calculate distribution rate for vault with a specific lockup period
    /// @param vault the vault address
    /// @param lockup the lockup period (seconds)
    function getVaultDistributionRate(address vault, uint256 lockup)
        public
        view
        override
        returns (uint256)
    {
        VaultConfig memory config = vaultConfig[vault];
        if (lockup >= 365 days) {
            return config.rate3;
        } else if (lockup >= 180 days) {
            return config.rate2;
        } else if (lockup >= 30 days) {
            return config.rate1;
        }
        return config.rate0;
    }

    /// @notice distribute TAKE token to partipant according to Takepile distribution rate (if distribution enabled)
    /// @notice this will be called by all TakeToken contracts on position exit
    /// @notice will distribute until contract balance is exhausted
    /// @notice if distribution amount greater than contract balance, will transfer remaining balance
    /// @param participant the participant to distribute for
    /// @param positionAmount the amount of pile token staked on the position
    /// @param periods the number of periods (seconds) to distribute on
    function distributeTakeFromTakepile(
        address participant,
        uint256 positionAmount,
        uint256 periods
    ) external override onlyTakepile {
        TakepileConfig memory _config = takepileConfig[msg.sender];
        uint256 balance = ERC20(TAKE).balanceOf(address(this));
        if (balance > 0 && _config.distributionRate > 0) {
            uint256 distribution = this.calculateDistribution(
                _config.distributionRate,
                positionAmount,
                periods
            );
            ERC20(address(TAKE)).safeTransfer(
                participant,
                distribution <= balance ? distribution : balance
            );
        }
    }

    /// @notice distribute TAKE token to partipant according to vault distribution rate
    /// @notice this will be called when claiming rewards for a staked vault position
    /// @notice will distribute until contract balance is exhausted
    /// @notice if distribution amount greater than contract balance, will transfer remaining balance
    /// @param participant the participant to distribute for
    /// @param positionAmount the amount of pile token staked on the position
    /// @param periods the number of periods (seconds) to distribute on
    function distributeTakeFromVault(
        address participant,
        uint256 positionAmount,
        uint256 periods,
        uint256 lockup
    ) external override onlyVault {
        uint256 balance = ERC20(TAKE).balanceOf(address(this));
        uint256 rate = getVaultDistributionRate(msg.sender, lockup);
        if (balance > 0 && rate > 0) {
            uint256 distribution = calculateDistribution(rate, positionAmount, periods);
            ERC20(address(TAKE)).safeTransfer(
                participant,
                distribution <= balance ? distribution : balance
            );
        }
    }

    /// @notice calculate the amount of TAKE that should be distributed since last distribution
    /// @param distributionRate the distribution rate of the takepile, scaled by 1e27
    /// @param positionAmount the size of the position to distribute on
    /// @param periods the number of periods (seconds) to distribute on
    function calculateDistribution(
        uint256 distributionRate,
        uint256 positionAmount,
        uint256 periods
    ) public view override returns (uint256) {
        require(positionAmount > 0, "Takepile: amount cannot be zero");
        return this.calculateSimpleInterest(positionAmount, distributionRate, periods);
    }

    /// @notice calculate simple interest
    /// @param p the principal
    /// @param r the rate per time period (scaled by 1e27)
    /// @param t the number of time periods
    /// @return the simple interest
    function calculateSimpleInterest(
        uint256 p,
        uint256 r, // r scaled by 1e27
        uint256 t
    ) external pure override returns (uint256) {
        return p.mul(r.mul(t)).div(1e27);
    }

    /// @notice calculate the reward of a position closing
    /// @param amount the position size, i.e. the amount of pileTokens staked on trade
    /// @param entryPrice the position's entry price
    /// @param currentPrice the position's current market price
    /// @param isLong true if long position, false if short position
    function calculateReward(
        uint256 amount,
        int256 entryPrice,
        int256 currentPrice,
        bool isLong
    ) external pure override returns (int256) {
        if (amount == 0) {
            return 0;
        }
        int256 diff = currentPrice - entryPrice;
        int256 reward = (int256(amount) * (diff)) / entryPrice;
        reward = isLong ? reward : -reward;
        return reward;
    }

    /// @dev get conversion between underlying and shares (one parameter must be non-zero)
    /// @param _underlying the amount of underlying to convert to shares
    /// @param _shares the amount of shares to convert to underlying
    function getConversion(
        uint256 _underlying,
        uint256 _shares,
        uint256 _underlyingSupply,
        uint256 _totalShares
    ) public pure override returns (uint256) {
        require(_underlying == 0 || _shares == 0, "Takepile: one value should be zero");
        require(_underlying > 0 || _shares > 0, "Takepile: one value should be non-zero");
        // Converting underlying to shares
        if (_underlying > 0) {
            if (_totalShares == 0 || _underlyingSupply == 0) {
                return _underlying;
            }
            return (_totalShares * _underlying) / _underlyingSupply;
            // Converting shares to underlying
        } else {
            if (_totalShares == 0 || _underlyingSupply == 0) {
                return _shares;
            }
            return (_underlyingSupply * _shares) / _totalShares;
        }
    }

    /// @notice validate position amount; revert if amount exceeds takepile maximum amount (relative),
    ///         or is below minimum amount (absolute)
    function validatePositionAmount(
        address _takepile,
        address who,
        uint256 amount
    ) external view override {
        TakepileConfig memory config = takepileConfig[_takepile];
        require(config.maximumAmountDivisor > 0, "Takepile: takepile does not exist");
        require(
            ERC20(TAKE).balanceOf(who) >= config.takeRequirement,
            "Takepile: TAKE requirement not met"
        );
        TakepileToken takepile = TakepileToken(_takepile);
        require(
            amount < takepile.totalSupply() / config.maximumAmountDivisor,
            "Takepile: position amount exceeds maximum"
        );
        require(amount >= config.minimumAmount, "Takepile: position amount below minimum");
    }

    /// @notice validate if position has been open long enough to be applicable for rewards
    /// @param _takepile the address of the takpile
    /// @param entryTime the time the position was opened
    /// @return bool true if position should be rewarded, false otherwise
    function validatePositionDuration(address _takepile, uint256 entryTime)
        external
        view
        override
        returns (bool)
    {
        TakepileConfig memory config = takepileConfig[_takepile];
        if (block.timestamp >= entryTime + config.minimumDuration) {
            return true;
        }
        return false;
    }

    /// @notice revert if minimum deposit duration not met
    function validateDepositDuration(address _takepile, uint256 depositTime)
        external
        view
        override
    {
        TakepileConfig memory config = takepileConfig[_takepile];
        require(
            block.timestamp >= depositTime + config.minimumDepositDuration,
            "Takepile: minimum deposit time not met"
        );
    }

    /// @notice revert if address does not have at least one liquidation pass
    /// @param liquidator the address to check
    function validateLiquidator(address liquidator) external view override {
        require(
            IERC721(liquidationPass).balanceOf(liquidator) > 0,
            "Takepile: liquidation blocked"
        );
    }

    function getSelfAddress() public view returns(address) {
        return address(this);
    }

}
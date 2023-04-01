// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ContextUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import {ReentrancyGuardUpgradeable} from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import {BoringBatchable} from './libraries/BoringBatchable.sol';

interface Factory {
    function parameter() external view returns (address);

    function subscription() external view returns (address);

    function isSubscriptionActive(address) external view returns (bool);
}

interface Subscription {
    function getSubscription(
        address from
    )
        external
        view
        returns (
            uint256 planId,
            uint48 expiredAt,
            bool isCancelled,
            bool isActiveForNow,
            uint256 chargeAmount
        );
}

error INVALID_ADDRESS();
error INVALID_TIME();
error INVALID_AMOUNT();
error INACTIVE_SUBSCRIPTION();
error ACTIVE_SUBSCRIPTION();
error INSUFFICIENT_FUND();
error INACTIVE_STREAM();
error ACTIVE_STREAM();
error STREAM_PAUSED();
error STREAM_ENDED();

contract HectorPay is
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    BoringBatchable
{
    using SafeERC20 for IERC20;

    /* ======== STORAGE ======== */

    struct Payer {
        uint256 totalDeposited;
        uint256 totalCommitted;
        uint256 totalWithdrawn;
    }

    struct Stream {
        address from;
        address to;
        uint256 amountPerSec;
        uint48 starts;
        uint48 ends;
        uint48 lastPaid;
        uint48 lastPaused;
    }

    /// @notice pay factory
    Factory public factory;

    /// @notice payer info
    mapping(address => Payer) public payers;

    /// @notice stream info
    mapping(bytes32 => Stream) public streams;

    /// @notice paused stream by subscription
    mapping(bytes32 => bool) public isPausedBySubscription;

    /// @notice stream token
    IERC20 public token;

    /// @notice decimals divisor for 20
    uint256 public DECIMALS_DIVISOR;

    /// @notice version
    string public constant VERSION = 'v1.0';

    /* ======== EVENTS ======== */

    event StreamCreated(
        address indexed from,
        address indexed to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends,
        bytes32 streamId
    );
    event StreamCreatedWithReason(
        address indexed from,
        address indexed to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends,
        bytes32 streamId,
        string reason
    );
    event StreamCancelled(
        address indexed from,
        address indexed to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends,
        bytes32 streamId
    );
    event StreamPaused(
        address indexed from,
        address indexed to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends,
        bytes32 streamId
    );
    event StreamResumed(
        address indexed from,
        address indexed to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends,
        bytes32 streamId
    );
    event StreamModified(
        address indexed from,
        address indexed oldTo,
        uint256 oldAmountPerSec,
        uint48 oldEnds,
        bytes32 oldStreamId,
        address indexed to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends,
        bytes32 newStreamId
    );
    event Withdraw(
        address indexed from,
        address indexed to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends,
        uint48 lastPaid,
        bytes32 streamId,
        uint256 amount
    );
    event PayerDeposit(address indexed from, uint256 amount);
    event PayerWithdraw(address indexed from, uint256 amount);

    /* ======== INITIALIZATION ======== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        factory = Factory(msg.sender);

        token = IERC20(factory.parameter());

        uint8 tokenDecimals = IERC20Metadata(address(token)).decimals();
        DECIMALS_DIVISOR = 10 ** (20 - tokenDecimals);

        __Context_init();
        __ReentrancyGuard_init();
    }

    /* ======== MODIFIER ======== */

    modifier onlyActiveSubscription(address from) {
        // if (!isActiveSubscriptionForNow(from)) revert INACTIVE_SUBSCRIPTION();

        _;
    }

    /* ======== VIEW FUNCTIONS ======== */

    function getStreamId(
        address from,
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(from, to, amountPerSec, starts, ends));
    }

    function withdrawable(
        address from,
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    )
        external
        view
        returns (bytes32 streamId, uint48 lastPaid, uint256 withdrawableAmount)
    {
        streamId = getStreamId(from, to, amountPerSec, starts, ends);
        Stream storage stream = streams[streamId];

        if (stream.lastPaid == 0) revert INACTIVE_STREAM();

        lastPaid = stream.lastPaid;

        uint256 stop = min(ends, block.timestamp);
        if (stop > lastPaid) {
            withdrawableAmount =
                ((stop - lastPaid) * amountPerSec) /
                DECIMALS_DIVISOR;
        }
    }

    function isActiveSubscriptionForNow(
        address from
    ) public view returns (bool isActiveForNow) {
        address subscription = factory.subscription();

        if (subscription == address(0)) {
            isActiveForNow = factory.isSubscriptionActive(from);
        } else {
            (, , , isActiveForNow, ) = Subscription(factory.subscription())
                .getSubscription(from);
        }
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _createStream(
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends,
        uint48 lastPaid
    ) internal returns (bytes32 streamId) {
        if (starts >= ends) revert INVALID_TIME();
        if (ends <= block.timestamp) revert INVALID_TIME();
        if (to == address(0)) revert INVALID_ADDRESS();
        if (amountPerSec == 0) revert INVALID_AMOUNT();

        // stream active
        streamId = getStreamId(msg.sender, to, amountPerSec, starts, ends);
        if (streams[streamId].lastPaid > 0) revert ACTIVE_STREAM();
        if (streams[streamId].lastPaused > 0) revert STREAM_PAUSED();

        /// calculate total committed amount of a stream
        Payer storage payer = payers[msg.sender];
        payer.totalCommitted += (ends - lastPaid) * amountPerSec;
        if (payer.totalDeposited < payer.totalCommitted)
            revert INSUFFICIENT_FUND();

        streams[streamId] = Stream({
            from: msg.sender,
            to: to,
            amountPerSec: amountPerSec,
            starts: starts,
            ends: ends,
            lastPaid: lastPaid,
            lastPaused: 0
        });
    }

    function _withdraw(
        address from,
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    )
        private
        returns (
            bytes32 streamId,
            Stream storage stream,
            uint256 amountToTransfer
        )
    {
        streamId = getStreamId(from, to, amountPerSec, starts, ends);
        stream = streams[streamId];

        if (stream.lastPaid == 0) revert INACTIVE_STREAM();

        uint256 stop = min(ends, block.timestamp);
        if (stop > stream.lastPaid) {
            uint256 decimalAmount = (stop - stream.lastPaid) *
                stream.amountPerSec;
            amountToTransfer = decimalAmount / DECIMALS_DIVISOR;

            Payer storage payer = payers[from];
            payer.totalWithdrawn += decimalAmount;

            stream.lastPaid = uint48(stop);

            emit Withdraw(
                from,
                to,
                amountPerSec,
                starts,
                ends,
                stream.lastPaid,
                streamId,
                decimalAmount
            );
        }
    }

    function _cancelStream(
        address from,
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    ) internal returns (bytes32 streamId) {
        Stream storage stream;
        uint256 amountToTransfer;
        (streamId, stream, amountToTransfer) = _withdraw(
            from,
            to,
            amountPerSec,
            starts,
            ends
        );

        stream.lastPaid = 0;

        token.safeTransfer(to, amountToTransfer);
    }

    function _resumeStream(
        address from,
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    ) internal returns (bytes32 streamId) {
        streamId = getStreamId(from, to, amountPerSec, starts, ends);
        Stream storage stream = streams[streamId];
        Payer storage payer = payers[from];

        if (stream.lastPaid > 0) revert ACTIVE_STREAM();
        if (stream.lastPaused == 0) revert STREAM_ENDED();

        /// calculate total committed amount of a stream
        uint256 start = max(starts, stream.lastPaused);
        uint256 stop = min(ends, block.timestamp);
        if (stop > start) {
            payer.totalCommitted -= amountPerSec * (stop - start);
        }

        stream.lastPaid = uint48(stop);
        stream.lastPaused = 0;
        isPausedBySubscription[streamId] = false;
    }

    /* ======== SUBSCRIPTION POLICY FUNCTIONS ======== */

    function pauseStreamBySubscription(
        address from,
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    ) external {
        // Only inactive subscription
        if (!isActiveSubscriptionForNow(from)) {
            bytes32 streamId = _cancelStream(
                from,
                to,
                amountPerSec,
                starts,
                ends
            );

            streams[streamId].lastPaused = uint48(block.timestamp);
            isPausedBySubscription[streamId] = true;

            emit StreamPaused(from, to, amountPerSec, starts, ends, streamId);
        }
    }

    function resumeStreamBySubscription(
        address from,
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    ) external {
        // Only active subscription
        if (isActiveSubscriptionForNow(from)) {
            bytes32 streamId = getStreamId(
                from,
                to,
                amountPerSec,
                starts,
                ends
            );

            if (!isPausedBySubscription[streamId]) revert STREAM_PAUSED();

            _resumeStream(from, to, amountPerSec, starts, ends);

            emit StreamResumed(from, to, amountPerSec, starts, ends, streamId);
        }
    }

    /* ======== USER FUNCTIONS ======== */

    function createStream(
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    ) public onlyActiveSubscription(msg.sender) {
        bytes32 streamId = _createStream(
            to,
            amountPerSec,
            starts,
            ends,
            starts
        );
        emit StreamCreated(
            msg.sender,
            to,
            amountPerSec,
            starts,
            ends,
            streamId
        );
    }

    function createStreamWithReason(
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends,
        string calldata reason
    ) public onlyActiveSubscription(msg.sender) {
        bytes32 streamId = _createStream(
            to,
            amountPerSec,
            starts,
            ends,
            starts
        );
        emit StreamCreatedWithReason(
            msg.sender,
            to,
            amountPerSec,
            starts,
            ends,
            streamId,
            reason
        );
    }

    function deposit(uint256 amount) public nonReentrant {
        uint256 decimalAmount = amount * DECIMALS_DIVISOR;

        payers[msg.sender].totalDeposited += decimalAmount;

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit PayerDeposit(msg.sender, decimalAmount);
    }

    function depositAndCreate(
        uint256 amountToDeposit,
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    ) external {
        deposit(amountToDeposit);
        createStream(to, amountPerSec, starts, ends);
    }

    function depositAndCreateWithReason(
        uint256 amountToDeposit,
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends,
        string calldata reason
    ) external {
        deposit(amountToDeposit);
        createStreamWithReason(to, amountPerSec, starts, ends, reason);
    }

    function withdraw(
        address from,
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    ) external {
        (, , uint256 amountToTransfer) = _withdraw(
            from,
            to,
            amountPerSec,
            starts,
            ends
        );
        token.safeTransfer(to, amountToTransfer);
    }

    function cancelStream(
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    ) external {
        bytes32 streamId = getStreamId(
            msg.sender,
            to,
            amountPerSec,
            starts,
            ends
        );

        /// resume stream if it's paused in order to cancel it
        if (
            streams[streamId].lastPaid == 0 && streams[streamId].lastPaused > 0
        ) {
            _resumeStream(msg.sender, to, amountPerSec, starts, ends);
        }

        /// calculate total committed amount of a stream
        uint256 start = max(starts, block.timestamp);
        if (ends > start) {
            payers[msg.sender].totalCommitted -= amountPerSec * (ends - start);
        }

        /// cancel stream
        _cancelStream(msg.sender, to, amountPerSec, starts, ends);

        emit StreamCancelled(
            msg.sender,
            to,
            amountPerSec,
            starts,
            ends,
            streamId
        );
    }

    function pauseStream(
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    ) external {
        bytes32 streamId = _cancelStream(
            msg.sender,
            to,
            amountPerSec,
            starts,
            ends
        );
        streams[streamId].lastPaused = uint48(block.timestamp);

        emit StreamPaused(msg.sender, to, amountPerSec, starts, ends, streamId);
    }

    function resumeStream(
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    ) public onlyActiveSubscription(msg.sender) {
        bytes32 streamId = _resumeStream(
            msg.sender,
            to,
            amountPerSec,
            starts,
            ends
        );

        emit StreamResumed(
            msg.sender,
            to,
            amountPerSec,
            starts,
            ends,
            streamId
        );
    }

    function modifyStream(
        address oldTo,
        uint256 oldAmountPerSec,
        uint48 starts,
        uint48 oldEnds,
        address to,
        uint256 amountPerSec,
        uint48 ends
    ) external onlyActiveSubscription(msg.sender) {
        /// cancel old stream
        bytes32 oldStreamId = _cancelStream(
            msg.sender,
            oldTo,
            oldAmountPerSec,
            starts,
            oldEnds
        );
        bytes32 newStreamId;

        {
            uint256 lastPaid = min(oldEnds, max(starts, block.timestamp));

            /// calculate total committed amount of an old stream
            payers[msg.sender].totalCommitted -=
                oldAmountPerSec *
                (oldEnds - lastPaid);

            /// create new stream
            newStreamId = _createStream(
                to,
                amountPerSec,
                starts,
                ends,
                uint48(lastPaid)
            );
        }

        emit StreamModified(
            msg.sender,
            oldTo,
            oldAmountPerSec,
            oldEnds,
            oldStreamId,
            to,
            amountPerSec,
            starts,
            ends,
            newStreamId
        );
    }

    function withdrawablePayer(
        address from
    ) external view returns (uint256 amount) {
        Payer memory payer = payers[from];
        amount =
            (payer.totalDeposited - payer.totalCommitted) /
            DECIMALS_DIVISOR;
    }

    function withdrawPayerAll() external {
        Payer storage payer = payers[msg.sender];

        uint256 decimalAmount = payer.totalDeposited - payer.totalCommitted;
        uint256 toSend = decimalAmount / DECIMALS_DIVISOR;

        payer.totalDeposited = payer.totalCommitted;

        if (toSend > 0) token.safeTransfer(msg.sender, toSend);

        emit PayerWithdraw(msg.sender, decimalAmount);
    }

    function withdrawPayer(uint256 amount) external {
        if (amount == 0) revert INVALID_AMOUNT();

        Payer storage payer = payers[msg.sender];

        uint256 decimalAmount = amount * DECIMALS_DIVISOR;
        payer.totalDeposited -= decimalAmount;

        if (payer.totalDeposited < payer.totalCommitted)
            revert INVALID_AMOUNT();

        token.safeTransfer(msg.sender, amount);

        emit PayerWithdraw(msg.sender, decimalAmount);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

interface IERC20Permit {
    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                calls[i]
            );
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20Permit token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
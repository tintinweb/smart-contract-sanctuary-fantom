// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {IERC20} from "../lib/IERC20.sol";
import {Address} from "../lib/Address.sol";

import {TokenHelper} from "../core/asset/TokenHelper.sol";
import {NativeClaimer} from "../core/asset/NativeClaimer.sol";
import {NativeReceiver} from "../core/asset/NativeReceiver.sol";
import {NativeReturnMods} from "../core/asset/NativeReturnMods.sol";

import {WhitelistWithdrawable} from "../core/withdraw/WhitelistWithdrawable.sol";

struct OperationOut {
    uint256 outIndex;
    uint256 amount; // Amount value or '_OUT_AMOUNT_REMAINING'
}

struct CallOperation {
    address inToken;
    uint256 inAmount;
    address outToken;
    OperationOut[] outs;
    address target;
    bytes data;
}

struct GenericCallConstructorParams {
    address withdrawWhitelist;
}

contract GenericCall is NativeReceiver, NativeReturnMods, WhitelistWithdrawable {
    // prettier-ignore
    // bytes32 private constant _WITHDRAW_WHITELIST_SLOT = bytes32(uint256(keccak256("xSwap.v2.GenericCall._withdrawWhitelist")) - 1);
    bytes32 private constant _WITHDRAW_WHITELIST_SLOT = 0xdca732a4493846cdcd0a0d8f9da398dbdc665ffcea4402e8e8a83cd5ddde1789;

    uint256 private constant _OUT_AMOUNT_REMAINING = type(uint256).max;

    // prettier-ignore
    constructor(GenericCallConstructorParams memory params_)
        WhitelistWithdrawable(_WITHDRAW_WHITELIST_SLOT, params_.withdrawWhitelist)
    {} // solhint-disable-line no-empty-blocks

    function call(CallOperation[] calldata operations_) external payable returns (uint256[] memory outAmounts) {
        NativeClaimer.State memory nativeClaimer;
        outAmounts = _call(operations_, nativeClaimer);
    }

    function _call(
        CallOperation[] calldata operations_,
        NativeClaimer.State memory nativeClaimer_
    ) private returnUnclaimedNative(nativeClaimer_) returns (uint256[] memory outAmounts) {
        uint256 totalOuts = 0;
        for (uint256 i = 0; i < operations_.length; i++) {
            for (uint256 j = 0; j < operations_[i].outs.length; j++) {
                uint256 totalFromIndex = operations_[i].outs[j].outIndex + 1;
                if (totalFromIndex > totalOuts) {
                    totalOuts = totalFromIndex;
                }
            }
        }
        outAmounts = new uint256[](totalOuts);

        for (uint256 i = 0; i < operations_.length; i++) {
            _op(operations_[i], outAmounts, nativeClaimer_);
        }
    }

    function _op(
        CallOperation calldata operation_,
        uint256[] memory outAmounts_,
        NativeClaimer.State memory nativeClaimer_
    ) private {
        // No call needed. Tokens remain as-is on the caller's balance.
        // Also logic below works correctly only when inToken != outToken
        if (operation_.inToken == operation_.outToken) {
            _distribute(operation_.outs, outAmounts_, operation_.inAmount);
            return;
        }

        // Claim full input amount
        TokenHelper.transferToThis(operation_.inToken, msg.sender, operation_.inAmount, nativeClaimer_);

        uint256 inTokenBalanceBefore = TokenHelper.balanceOfThis(operation_.inToken, nativeClaimer_);
        uint256 outTokenBalanceBefore = TokenHelper.balanceOfThis(operation_.outToken, nativeClaimer_);

        {
            uint256 sendValue = 0;
            if (TokenHelper.isNative(operation_.inToken)) {
                sendValue = operation_.inAmount;
            } else {
                uint256 allowed = IERC20(operation_.inToken).allowance(address(this), operation_.target);
                if (allowed < operation_.inAmount) {
                    IERC20(operation_.inToken).approve(operation_.target, type(uint256).max);
                }
            }
            Address.functionCallWithValue(operation_.target, operation_.data, sendValue);
        }

        {
            uint256 inTokenBalanceAfter = TokenHelper.balanceOfThis(operation_.inToken, nativeClaimer_);
            uint256 inTokenSpent = inTokenBalanceBefore - inTokenBalanceAfter;
            TokenHelper.transferFromThis(operation_.inToken, msg.sender, operation_.inAmount - inTokenSpent);
        }

        {
            uint256 outTokenBalanceAfter = TokenHelper.balanceOfThis(operation_.outToken, nativeClaimer_);
            uint256 outTokenReceived = outTokenBalanceAfter - outTokenBalanceBefore;
            TokenHelper.transferFromThis(operation_.outToken, msg.sender, outTokenReceived);

            _distribute(operation_.outs, outAmounts_, outTokenReceived);
        }
    }

    function _distribute(
        OperationOut[] calldata outs_,
        uint256[] memory outAmounts_,
        uint256 totalAmount_
    ) private pure {
        // Assign fixed amounts
        uint256 remainingAmount = totalAmount_;
        uint256 remainingOutIndex = type(uint256).max;
        for (uint256 i = 0; i < outs_.length; i++) {
            uint256 amount = outs_[i].amount;
            uint256 outIndex = outs_[i].outIndex;
            if (amount == _OUT_AMOUNT_REMAINING) {
                require(remainingOutIndex == type(uint256).max, "GC: multiple remaining outs");
                remainingOutIndex = outIndex;
            } else {
                outAmounts_[outIndex] += amount;
                remainingAmount -= amount;
            }
        }

        // Assign remaining amount
        if (remainingOutIndex == type(uint256).max) {
            require(remainingAmount == 0, "GC: amount must be distributed");
        } else {
            outAmounts_[remainingOutIndex] += remainingAmount;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

library NativeClaimer {
    struct State {
        uint256 _valueClaimed;
    }

    function claimed(NativeClaimer.State memory claimer_) internal pure returns (uint256) {
        return claimer_._valueClaimed;
    }

    function unclaimed(NativeClaimer.State memory claimer_) internal view returns (uint256) {
        return msg.value - claimer_._valueClaimed;
    }

    function claim(NativeClaimer.State memory claimer_, uint256 value_) internal view {
        require(unclaimed(claimer_) >= value_, "NC: insufficient msg value");
        claimer_._valueClaimed += value_;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

abstract contract NativeReceiver {
    receive() external payable {} // solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {NativeClaimer} from "./NativeClaimer.sol";
import {TokenHelper} from "./TokenHelper.sol";

abstract contract NativeReturnMods {
    using NativeClaimer for NativeClaimer.State;

    modifier returnUnclaimedNative(NativeClaimer.State memory claimer_) {
        require(claimer_.claimed() == 0, "NR: claimer already in use");
        _;
        TokenHelper.transferFromThis(TokenHelper.NATIVE_TOKEN, msg.sender, claimer_.unclaimed());
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Math} from "../../lib/Math.sol";

import {TokenCheck} from "../swap/Swap.sol";

library TokenChecker {
    function checkMin(TokenCheck calldata check_, uint256 amount_) internal pure returns (uint256) {
        orderMinMax(check_);
        limitMin(check_, amount_);
        return capByMax(check_, amount_);
    }

    function checkMinMax(TokenCheck calldata check_, uint256 amount_) internal pure {
        orderMinMax(check_);
        limitMin(check_, amount_);
        limitMax(check_, amount_);
    }

    function checkMinMaxToken(TokenCheck calldata check_, uint256 amount_, address token_) internal pure {
        orderMinMax(check_);
        limitMin(check_, amount_);
        limitMax(check_, amount_);
        limitToken(check_, token_);
    }

    function orderMinMax(TokenCheck calldata check_) private pure {
        require(check_.minAmount <= check_.maxAmount, "TC: unordered min/max amounts");
    }

    function limitMin(TokenCheck calldata check_, uint256 amount_) private pure {
        require(amount_ >= check_.minAmount, "TC: insufficient token amount");
    }

    function limitMax(TokenCheck calldata check_, uint256 amount_) private pure {
        require(amount_ <= check_.maxAmount, "TC: excessive token amount");
    }

    function limitToken(TokenCheck calldata check_, address token_) private pure {
        require(token_ == check_.token, "TC: wrong token address");
    }

    function capByMax(TokenCheck calldata check_, uint256 amount_) private pure returns (uint256) {
        return Math.min(amount_, check_.maxAmount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {IERC20} from "../../lib/IERC20.sol";
import {IERC20Permit} from "../../lib/draft-IERC20Permit.sol";
import {SafeERC20} from "../../lib/SafeERC20.sol";
import {Address} from "../../lib/Address.sol";
import {ECDSA} from "../../lib/ECDSA.sol";

import {NativeClaimer} from "./NativeClaimer.sol";

library TokenHelper {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;
    using Address for address;
    using Address for address payable;
    using NativeClaimer for NativeClaimer.State;

    /**
     * @dev xSwap's native coin representation.
     */
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier whenNonZero(uint256 amount_) {
        if (amount_ == 0) {
            return;
        }
        _;
    }

    function isNative(address token_) internal pure returns (bool) {
        return token_ == NATIVE_TOKEN;
    }

    function balanceOf(
        address token_,
        address owner_,
        NativeClaimer.State memory claimer_
    ) internal view returns (uint256 balance) {
        if (isNative(token_)) {
            balance = _nativeBalanceOf(owner_, claimer_);
        } else {
            balance = IERC20(token_).balanceOf(owner_);
        }
    }

    function balanceOfThis(
        address token_,
        NativeClaimer.State memory claimer_
    ) internal view returns (uint256 balance) {
        balance = balanceOf(token_, _this(), claimer_);
    }

    function transferToThis(
        address token_,
        address from_,
        uint256 amount_,
        NativeClaimer.State memory claimer_
    ) internal whenNonZero(amount_) {
        if (isNative(token_)) {
            // We cannot claim native coins of an arbitrary "from_" address
            // like we do with ERC-20 allowance. So the only way to use native
            // is to pass via "value" with the contract call. The "from_" address
            // does not participate in such a scenario. The only thing we can do
            // is to restrict caller to be "from_" address only.
            require(from_ == _sender(), "TH: native allows sender only");
            claimer_.claim(amount_);
        } else {
            IERC20(token_).safeTransferFrom(from_, _this(), amount_);
        }
    }

    function transferFromThis(address token_, address to_, uint256 amount_) internal whenNonZero(amount_) {
        if (isNative(token_)) {
            _nativeTransferFromThis(to_, amount_);
        } else {
            IERC20(token_).safeTransfer(to_, amount_);
        }
    }

    function approveOfThis(
        address token_,
        address spender_,
        uint256 amount_
    ) internal whenNonZero(amount_) returns (uint256 sendValue) {
        if (isNative(token_)) {
            sendValue = amount_;
        } else {
            sendValue = 0;
            IERC20(token_).safeApprove(spender_, amount_);
        }
    }

    function revokeOfThis(address token_, address spender_) internal {
        if (!isNative(token_)) {
            IERC20(token_).safeApprove(spender_, 0);
        }
    }

    function _nativeBalanceOf(
        address owner_,
        NativeClaimer.State memory claimer_
    ) private view returns (uint256 balance) {
        if (owner_ == _sender()) {
            balance = claimer_.unclaimed();
        } else {
            balance = owner_.balance;
            if (owner_ == _this()) {
                balance -= claimer_.unclaimed();
            }
        }
    }

    function _nativeTransferFromThis(address to_, uint256 amount_) private whenNonZero(amount_) {
        payable(to_).sendValue(amount_);
    }

    function _this() private view returns (address) {
        return address(this);
    }

    function _sender() private view returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Ownable} from "../../lib/Ownable.sol";

import {TokenHelper} from "../asset/TokenHelper.sol";
import {NativeReceiver} from "../asset/NativeReceiver.sol";

import {SimpleInitializable} from "../init/SimpleInitializable.sol";

import {IWithdrawable} from "../withdraw/IWithdrawable.sol";
import {Withdrawable, Withdraw} from "../withdraw/Withdrawable.sol";

import {IDelegate} from "./IDelegate.sol";

contract Delegate is IDelegate, SimpleInitializable, Ownable, Withdrawable, NativeReceiver {
    constructor() {
        _initializeWithSender();
    }

    function _initialize() internal override {
        _transferOwnership(initializer());
    }

    function setOwner(address newOwner_) external whenInitialized onlyInitializer {
        _transferOwnership(newOwner_);
    }

    function _checkWithdraw() internal view override {
        _ensureInitialized();
        _checkOwner();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Clones} from "../../lib/Clones.sol";
import {Address} from "../../lib/Address.sol";

import {IDelegate} from "./IDelegate.sol";
import {IDelegateDeployer} from "./IDelegateDeployer.sol";

contract DelegateDeployer is IDelegateDeployer {
    address private immutable _delegatePrototype;

    constructor(address delegatePrototype_) {
        require(delegatePrototype_ != address(0), "DF: zero delegate proto");
        _delegatePrototype = delegatePrototype_;
    }

    function predictDelegateDeploy(address account_) public view returns (address) {
        return Clones.predictDeterministicAddress(_delegatePrototype, _calcSalt(account_));
    }

    function deployDelegate(address account_) public returns (address) {
        address delegate = Clones.cloneDeterministic(_delegatePrototype, _calcSalt(account_));
        IDelegate(delegate).initialize();
        IDelegate(delegate).transferOwnership(account_);
        return delegate;
    }

    function isDelegateDeployed(address account_) public view returns (bool) {
        address delegate = predictDelegateDeploy(account_);
        return Address.isContract(delegate);
    }

    function _calcSalt(address account_) private pure returns (bytes32) {
        return bytes20(account_);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {IAccountWhitelist} from "../whitelist/IAccountWhitelist.sol";

import {Withdraw} from "../withdraw/IWithdrawable.sol";

import {IDelegate} from "./IDelegate.sol";
import {IDelegateManager} from "./IDelegateManager.sol";
import {DelegateDeployer} from "./DelegateDeployer.sol";

struct DelegateManagerConstructorParams {
    /**
     * @dev {IDelegate}-compatible contract address
     */
    address delegatePrototype;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address withdrawWhitelist;
}

/**
 * @dev Inherits {DelegateDeployer} to have access to delegates as their initializer
 */
contract DelegateManager is IDelegateManager, DelegateDeployer {
    address private immutable _withdrawWhitelist;

    // prettier-ignore
    constructor(DelegateManagerConstructorParams memory params_)
        DelegateDeployer(params_.delegatePrototype)
    {
        require(params_.withdrawWhitelist != address(0), "DF: zero withdraw whitelist");
        _withdrawWhitelist = params_.withdrawWhitelist;
    }

    modifier onlyWhitelistedWithdrawer() {
        require(
            IAccountWhitelist(_withdrawWhitelist).isAccountWhitelisted(msg.sender),
            "DF: withdrawer not whitelisted"
        );
        _;
    }

    modifier asDelegateOwner(address delegate_) {
        address savedOwner = IDelegate(delegate_).owner();
        IDelegate(delegate_).setOwner(address(this));
        _;
        IDelegate(delegate_).setOwner(savedOwner);
    }

    function withdraw(address account_, Withdraw[] calldata withdraws_) external onlyWhitelistedWithdrawer {
        address delegate = predictDelegateDeploy(account_);
        _withdraw(delegate, withdraws_);
    }

    function _withdraw(address delegate_, Withdraw[] calldata withdraws_) private asDelegateOwner(delegate_) {
        IDelegate(delegate_).withdraw(withdraws_);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {IOwnable} from "../../lib/IOwnable.sol";

import {ISimpleInitializable} from "../init/ISimpleInitializable.sol";

import {IWithdrawable} from "../withdraw/IWithdrawable.sol";

import {IOwnershipManageable} from "./IOwnershipManageable.sol";

// solhint-disable-next-line no-empty-blocks
interface IDelegate is ISimpleInitializable, IOwnable, IWithdrawable, IOwnershipManageable {

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IDelegateDeployer {
    function predictDelegateDeploy(address account) external view returns (address);

    function deployDelegate(address account) external returns (address);

    function isDelegateDeployed(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {Withdraw} from "../withdraw/IWithdrawable.sol";

import {IDelegateDeployer} from "./IDelegateDeployer.sol";

interface IDelegateManager is IDelegateDeployer {
    function withdraw(address account, Withdraw[] calldata withdraws) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IOwnershipManageable {
    function setOwner(address newOwner) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IInitializable {
    function initialized() external view returns (bool);

    function initializer() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {IInitializable} from "./IInitializable.sol";
import {InitializableStorage} from "./InitializableStorage.sol";

abstract contract Initializable is IInitializable, InitializableStorage {
    // prettier-ignore
    constructor(bytes32 initializerSlot_)
        InitializableStorage(initializerSlot_)
    {} // solhint-disable-line no-empty-blocks

    modifier whenInitialized() {
        _ensureInitialized();
        _;
    }

    modifier whenNotInitialized() {
        _ensureNotInitialized();
        _;
    }

    modifier init() {
        _ensureNotInitialized();
        _initializeWithSender();
        _;
    }

    modifier onlyInitializer() {
        require(msg.sender == initializer(), "IN: sender not initializer");
        _;
    }

    function initialized() public view returns (bool) {
        return initializer() != address(0);
    }

    function initializer() public view returns (address) {
        return _initializer();
    }

    function _ensureInitialized() internal view {
        require(initialized(), "IN: not initialized");
    }

    function _ensureNotInitialized() internal view {
        require(!initialized(), "IN: already initialized");
    }

    function _initializeWithSender() internal {
        _setInitializer(msg.sender);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {StorageSlot} from "../../lib/StorageSlot.sol";

abstract contract InitializableStorage {
    bytes32 private immutable _initializerSlot;

    constructor(bytes32 initializerSlot_) {
        _initializerSlot = initializerSlot_;
    }

    function _initializerStorage() private view returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_initializerSlot);
    }

    function _initializer() internal view returns (address) {
        return _initializerStorage().value;
    }

    function _setInitializer(address initializer_) internal {
        _initializerStorage().value = initializer_;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {IInitializable} from "./IInitializable.sol";

interface ISimpleInitializable is IInitializable {
    function initialize() external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {ISimpleInitializable} from "./ISimpleInitializable.sol";
import {Initializable} from "./Initializable.sol";

abstract contract SimpleInitializable is ISimpleInitializable, Initializable {
    // bytes32 private constant _INITIALIZER_SLOT = bytes32(uint256(keccak256("xSwap.v2.SimpleInitializable._initializer")) - 1);
    bytes32 private constant _INITIALIZER_SLOT = 0x4c943a984a6327bfee4b36cd148236ae13d07c9a3fe7f9857f4809df3e826db1;

    // prettier-ignore
    constructor()
        Initializable(_INITIALIZER_SLOT)
    {} // solhint-disable-line no-empty-blocks

    function initialize() public init {
        _initialize();
    }

    function _initialize() internal virtual;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {IPausable} from "../../lib/IPausable.sol";

/**
 * @dev Contract logic responsible for xSwap protocol live control.
 */
interface ILifeControl is IPausable {
    /**
     * @dev Emitted when the termination is triggered by `account`.
     */
    event Terminated(address account);

    /**
     * @dev Pauses xSwap protocol.
     *
     * Requirements:
     * - called by contract owner
     * - must not be in paused state
     */
    function pause() external;

    /**
     * @dev Unpauses xSwap protocol.
     *
     * Requirements:
     * - called by contract owner
     * - must be in paused state
     * - must not be in terminated state
     */
    function unpause() external;

    /**
     * @dev Terminates xSwap protocol.
     *
     * Puts xSwap protocol into the paused state with no further ability to unpause.
     * This action essentially stops protocol so is expected to be called in
     * extraordinary scenarios only.
     *
     * Requires contract to be put into the paused state prior the call.
     *
     * Requirements:
     * - called by contract owner
     * - must be in paused state
     * - must not be in terminated state
     */
    function terminate() external;

    /**
     * @dev Returns whether protocol is terminated ot not.
     *
     * Terminated protocol is guaranteed to be in paused state forever.
     *
     * @return _ `true` if protocol is terminated, `false` otherwise.
     */
    function terminated() external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Pausable} from "../../lib/Pausable.sol";
import {Ownable} from "../../lib/Ownable.sol";

import {ILifeControl} from "./ILifeControl.sol";

/**
 * @dev See {ILifeControl}.
 */
contract LifeControl is ILifeControl, Ownable, Pausable {
    bool private _terminated;

    /**
     * @dev See {ILifeControl-pause}.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev See {ILifeControl-unpause}.
     */
    function unpause() public onlyOwner {
        _requireNotTerminated();
        _unpause();
    }

    /**
     * @dev See {ILifeControl-terminate}.
     */
    function terminate() public onlyOwner whenPaused {
        _requireNotTerminated();
        _terminated = true;
        emit Terminated(_msgSender());
    }

    /**
     * @dev See {ILifeControl-terminated}.
     */
    function terminated() public view returns (bool) {
        return _terminated;
    }

    /**
     * @dev Throws if contract is in the terminated state.
     */
    function _requireNotTerminated() private view {
        require(!_terminated, "LC: terminated");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

/**
 * @dev In-memory implementation of 'mapping(address => uint256)'.
 *
 * The implementation is based on two once-allocated arrays and has sequential lookups.
 * Thus the worst case complexity must be expected to be O(N). The best case is O(1) though,
 * the operations required depend on number of unique elements, when an element was inserted, etc.
 */
library AccountCounter {
    uint256 private constant _ACCOUNT_MIXIN = 0xacc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0;
    uint256 private constant _NULL_INDEX = type(uint256).max;

    struct State {
        uint256[] _accounts;
        uint256[] _counts;
        uint256 _size;
    }

    using AccountCounter for State;

    function create(uint256 maxSize_) internal pure returns (AccountCounter.State memory accountCounter) {
        accountCounter._accounts = new uint256[](maxSize_);
        accountCounter._counts = new uint256[](maxSize_);
    }

    function size(AccountCounter.State memory accountCounter_) internal pure returns (uint256) {
        return accountCounter_._size;
    }

    function indexOf(
        AccountCounter.State memory accountCounter_,
        address account_,
        bool insert_
    ) internal pure returns (uint256) {
        uint256 targetAccount = uint160(account_) ^ _ACCOUNT_MIXIN;
        for (uint256 i = 0; i < accountCounter_._accounts.length; i++) {
            uint256 iAccount = accountCounter_._accounts[i];
            if (iAccount == targetAccount) {
                return i;
            }
            if (iAccount == 0) {
                if (!insert_) {
                    return _NULL_INDEX;
                }
                accountCounter_._accounts[i] = targetAccount;
                accountCounter_._size = i + 1;
                return i;
            }
        }
        if (!insert_) {
            return _NULL_INDEX;
        }
        revert("AC: insufficient size");
    }

    function indexOf(AccountCounter.State memory accountCounter_, address account_) internal pure returns (uint256) {
        return indexOf(accountCounter_, account_, true);
    }

    function isNullIndex(uint256 index_) internal pure returns (bool) {
        return index_ == _NULL_INDEX;
    }

    function accountAt(AccountCounter.State memory accountCounter_, uint256 index_) internal pure returns (address) {
        return address(uint160(accountCounter_._accounts[index_] ^ _ACCOUNT_MIXIN));
    }

    function get(AccountCounter.State memory accountCounter_, address account_) internal pure returns (uint256) {
        return getAt(accountCounter_, indexOf(accountCounter_, account_));
    }

    function getAt(AccountCounter.State memory accountCounter_, uint256 index_) internal pure returns (uint256) {
        return accountCounter_._counts[index_];
    }

    function set(AccountCounter.State memory accountCounter_, address account_, uint256 count_) internal pure {
        setAt(accountCounter_, indexOf(accountCounter_, account_), count_);
    }

    function setAt(AccountCounter.State memory accountCounter_, uint256 index_, uint256 count_) internal pure {
        accountCounter_._counts[index_] = count_;
    }

    function add(
        AccountCounter.State memory accountCounter_,
        address account_,
        uint256 count_
    ) internal pure returns (uint256 newCount) {
        return addAt(accountCounter_, indexOf(accountCounter_, account_), count_);
    }

    function addAt(
        AccountCounter.State memory accountCounter_,
        uint256 index_,
        uint256 count_
    ) internal pure returns (uint256 newCount) {
        newCount = getAt(accountCounter_, index_) + count_;
        setAt(accountCounter_, index_, newCount);
    }

    function sub(
        AccountCounter.State memory accountCounter_,
        address account_,
        uint256 count_
    ) internal pure returns (uint256 newCount) {
        return subAt(accountCounter_, indexOf(accountCounter_, account_), count_);
    }

    function subAt(
        AccountCounter.State memory accountCounter_,
        uint256 index_,
        uint256 count_
    ) internal pure returns (uint256 newCount) {
        newCount = getAt(accountCounter_, index_) - count_;
        setAt(accountCounter_, index_, newCount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {IPermitResolver} from "./IPermitResolver.sol";
import {Signature, SignatureHelper} from "./SignatureHelper.sol";

interface IDaiPermit {
    function nonces(address holder) external returns (uint256);

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/**
 * @dev Permit resolver according to the Dai token implementation.
 */
contract DaiPermitResolver is IPermitResolver {
    function resolvePermit(
        address token_,
        address from_,
        uint256 amount_,
        uint256 deadline_,
        bytes calldata signature_
    ) external {
        require(amount_ == 0 || amount_ == type(uint256).max, "DP: amount should be zero or max");

        uint256 nonce = IDaiPermit(token_).nonces(from_);
        Signature memory s = SignatureHelper.decomposeSignature(signature_);
        IDaiPermit(token_).permit(from_, msg.sender, nonce, deadline_, amount_ != 0, s.v, s.r, s.s);

        // Copies {SafeERC20-safePermit} check
        uint256 nonceAfter = IDaiPermit(token_).nonces(from_);
        require(nonceAfter == nonce + 1, "DP: permit did not succeed");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IPermitResolver {
    /**
     * @dev Converts specified permit into allowance for the caller.
     */
    function resolvePermit(
        address token,
        address from,
        uint256 amount,
        uint256 deadline,
        bytes calldata signature
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {IERC20Permit} from "../../lib/draft-IERC20Permit.sol";
import {SafeERC20} from "../../lib/SafeERC20.sol";

import {IPermitResolver} from "./IPermitResolver.sol";
import {Signature, SignatureHelper} from "./SignatureHelper.sol";

/**
 * @dev Permit resolver according to the EIP-2612 spec.
 */
contract PermitResolver is IPermitResolver {
    using SafeERC20 for IERC20Permit;

    function resolvePermit(
        address token_,
        address from_,
        uint256 amount_,
        uint256 deadline_,
        bytes calldata signature_
    ) external {
        Signature memory s = SignatureHelper.decomposeSignature(signature_);
        IERC20Permit(token_).safePermit(from_, msg.sender, amount_, deadline_, s.v, s.r, s.s);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {ECDSA} from "../../lib/ECDSA.sol";

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

library SignatureHelper {
    function decomposeSignature(bytes calldata signature_) internal pure returns (Signature memory s) {
        ECDSA.RecoverError err;
        (s.r, s.s, s.v, err) = ECDSA.tryDecompose(signature_);
        require(err == ECDSA.RecoverError.NoError, "SH: signature decompose fail");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {Swap, StealthSwap, SwapStep} from "./Swap.sol";

/**
 * @dev Correlation with EIP-2612 permit:
 *
 * > address token -> Permit.token
 * > address owner -> SwapStep.account
 * > address spender -> xSwap contract
 * > uint256 value -> Permit.amount
 * > uint256 deadline -> Permit.deadline
 * > uint8 v -> Permit.signature
 * > bytes32 r -> Permit.signature
 * > bytes32 s -> Permit.signature
 *
 * The Permit.resolver is address of a contract responsible
 * for applying permit ({IPermitResolver}-compatible)
 */
struct Permit {
    address resolver;
    address token;
    uint256 amount;
    uint256 deadline;
    bytes signature;
}

struct Call {
    address target;
    bytes data;
}

struct SwapParams {
    Swap swap;
    bytes swapSignature;
    uint256 stepIndex;
    Permit[] permits;
    uint256[] inAmounts;
    Call call;
    bytes[] useArgs;
}

struct StealthSwapParams {
    StealthSwap swap;
    bytes swapSignature;
    SwapStep step;
    Permit[] permits;
    uint256[] inAmounts;
    Call call;
    bytes[] useArgs;
}

interface ISwapper {
    function swap(SwapParams calldata params) external payable;

    function swapStealth(StealthSwapParams calldata params) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {Swap, SwapStep, StealthSwap} from "./Swap.sol";

interface ISwapSignatureValidator {
    function validateSwapSignature(Swap calldata swap, bytes calldata swapSignature) external view;

    function validateStealthSwapStepSignature(
        SwapStep calldata swapStep,
        StealthSwap calldata stealthSwap,
        bytes calldata stealthSwapSignature
    ) external view returns (uint256 stepIndex);

    function findStealthSwapStepIndex(
        SwapStep calldata swapStep,
        StealthSwap calldata stealthSwap
    ) external view returns (uint256 stepIndex);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

struct TokenCheck {
    address token;
    uint256 minAmount;
    uint256 maxAmount;
}

struct TokenUse {
    address protocol;
    uint256 chain;
    address account;
    uint256[] inIndices;
    TokenCheck[] outs;
    bytes args; // Example of reserved value: 0x44796E616D6963 ("Dynamic")
}

struct SwapStep {
    uint256 chain;
    address swapper;
    address account;
    bool useDelegate;
    uint256 nonce;
    uint256 deadline;
    TokenCheck[] ins;
    TokenCheck[] outs;
    TokenUse[] uses;
}

struct Swap {
    SwapStep[] steps;
}

struct StealthSwap {
    uint256 chain;
    address swapper;
    address account;
    bytes32[] stepHashes;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Address} from "../../lib/Address.sol";
import {Math} from "../../lib/Math.sol";

import {NativeClaimer} from "../asset/NativeClaimer.sol";
import {NativeReceiver} from "../asset/NativeReceiver.sol";
import {NativeReturnMods} from "../asset/NativeReturnMods.sol";
import {TokenChecker} from "../asset/TokenChecker.sol";
import {TokenHelper} from "../asset/TokenHelper.sol";

import {IDelegateManager} from "../delegate/IDelegateManager.sol";

import {AccountCounter} from "../misc/AccountCounter.sol";

import {IPermitResolver} from "../permit/IPermitResolver.sol";

import {IUseProtocol, UseParams} from "../use/IUseProtocol.sol";

import {Withdraw} from "../withdraw/IWithdrawable.sol";

import {ISwapper, SwapParams, StealthSwapParams, Permit, Call} from "./ISwapper.sol";
import {Swap, SwapStep, TokenUse, StealthSwap, TokenCheck} from "./Swap.sol";
import {SwapperStorage} from "./SwapperStorage.sol";

struct SwapperConstructorParams {
    /**
     * @dev {ISwapSignatureValidator}-compatible contract address
     */
    address swapSignatureValidator;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address permitResolverWhitelist;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address useProtocolWhitelist;
    /**
     * @dev {IDelegateManager}-compatible contract address
     */
    address delegateManager;
}

contract Swapper is ISwapper, NativeReceiver, NativeReturnMods, SwapperStorage {
    using AccountCounter for AccountCounter.State;

    constructor(SwapperConstructorParams memory params_) {
        _initialize(params_);
    }

    function initializeSwapper(SwapperConstructorParams memory params_) internal {
        _initialize(params_);
    }

    function _initialize(SwapperConstructorParams memory params_) private {
        require(params_.swapSignatureValidator != address(0), "SW: zero swap sign validator");
        _setSwapSignatureValidator(params_.swapSignatureValidator);

        require(params_.permitResolverWhitelist != address(0), "SW: zero permit resolver list");
        _setPermitResolverWhitelist(params_.permitResolverWhitelist);

        require(params_.useProtocolWhitelist != address(0), "SW: zero use protocol list");
        _setUseProtocolWhitelist(params_.useProtocolWhitelist);

        require(params_.delegateManager != address(0), "SW: zero delegate manager");
        _setDelegateManager(params_.delegateManager);
    }

    function swap(SwapParams calldata params_) external payable {
        _checkSwapEnabled();
        require(params_.stepIndex < params_.swap.steps.length, "SW: no step with provided index");
        SwapStep calldata step = params_.swap.steps[params_.stepIndex];
        _validateSwapSignature(params_.swap, params_.swapSignature, step);
        _performSwapStep(step, params_.permits, params_.inAmounts, params_.call, params_.useArgs);
    }

    function swapStealth(StealthSwapParams calldata params_) external payable {
        _checkSwapEnabled();
        _validateStealthSwapSignature(params_.swap, params_.swapSignature, params_.step);
        _performSwapStep(params_.step, params_.permits, params_.inAmounts, params_.call, params_.useArgs);
    }

    function _checkSwapEnabled() internal view virtual {
        return; // Nothing is hindering by default
    }

    function _validateSwapSignature(
        Swap calldata swap_,
        bytes calldata swapSignature_,
        SwapStep calldata step_
    ) private view {
        if (_isSignaturePresented(swapSignature_)) {
            _swapSignatureValidator().validateSwapSignature(swap_, swapSignature_);
        } else {
            _validateStepManualCaller(step_);
        }
    }

    function _validateStealthSwapSignature(
        StealthSwap calldata stealthSwap_,
        bytes calldata stealthSwapSignature_,
        SwapStep calldata step_
    ) private view {
        if (_isSignaturePresented(stealthSwapSignature_)) {
            _swapSignatureValidator().validateStealthSwapStepSignature(step_, stealthSwap_, stealthSwapSignature_);
        } else {
            _validateStepManualCaller(step_);
            _swapSignatureValidator().findStealthSwapStepIndex(step_, stealthSwap_); // Ensure presented
        }
    }

    function _isSignaturePresented(bytes calldata signature_) private pure returns (bool) {
        return signature_.length > 0;
    }

    function _validateStepManualCaller(SwapStep calldata step_) private view {
        require(msg.sender == step_.account, "SW: caller must be step account");
    }

    function _performSwapStep(
        SwapStep calldata step_,
        Permit[] calldata permits_,
        uint256[] calldata inAmounts_,
        Call calldata call_,
        bytes[] calldata useArgs_
    ) private {
        // solhint-disable-next-line not-rely-on-time
        require(step_.deadline > block.timestamp, "SW: swap step expired");
        require(step_.chain == block.chainid, "SW: wrong swap step chain");
        require(step_.swapper == address(this), "SW: wrong swap step swapper");
        require(step_.ins.length == inAmounts_.length, "SW: in amounts length mismatch");

        _useNonce(step_.account, step_.nonce);
        _usePermits(step_.account, permits_);

        uint256[] memory outAmounts = _performCall(
            step_.account,
            step_.useDelegate,
            step_.ins,
            inAmounts_,
            step_.outs,
            call_
        );
        _performUses(step_.uses, useArgs_, step_.outs, outAmounts);
    }

    function _useNonce(address account_, uint256 nonce_) private {
        require(!_nonceUsed(account_, nonce_), "SW: invalid nonce");
        _setNonceUsed(account_, nonce_, true);
    }

    function _usePermits(address account_, Permit[] calldata permits_) private {
        for (uint256 i = 0; i < permits_.length; i++) {
            _usePermit(account_, permits_[i]);
        }
    }

    function _usePermit(address account_, Permit calldata permit_) private {
        require(_permitResolverWhitelist().isAccountWhitelisted(permit_.resolver), "SW: permitter not whitelisted");
        IPermitResolver(permit_.resolver).resolvePermit(
            permit_.token,
            account_,
            permit_.amount,
            permit_.deadline,
            permit_.signature
        );
    }

    function _performCall(
        address account_,
        bool useDelegate_,
        TokenCheck[] calldata ins_,
        uint256[] calldata inAmounts_,
        TokenCheck[] calldata outs_,
        Call calldata call_
    ) private returns (uint256[] memory outAmounts) {
        NativeClaimer.State memory nativeClaimer;
        // prettier-ignore
        return _performCallWithReturn(
            account_,
            useDelegate_,
            ins_,
            inAmounts_,
            outs_,
            call_,
            nativeClaimer
        );
    }

    function _performCallWithReturn(
        address account_,
        bool useDelegate_,
        TokenCheck[] calldata ins_,
        uint256[] calldata inAmounts_,
        TokenCheck[] calldata outs_,
        Call calldata call_,
        NativeClaimer.State memory nativeClaimer_
    ) private returnUnclaimedNative(nativeClaimer_) returns (uint256[] memory outAmounts) {
        // Ensure input amounts are within the min-max range
        for (uint256 i = 0; i < ins_.length; i++) {
            TokenChecker.checkMinMax(ins_[i], inAmounts_[i]);
        }

        // Calc input amounts to claim (per token)
        AccountCounter.State memory inAmountsByToken = AccountCounter.create(ins_.length);
        for (uint256 i = 0; i < ins_.length; i++) {
            inAmountsByToken.add(ins_[i].token, inAmounts_[i]);
        }

        // Claim inputs
        if (useDelegate_) {
            _claimAccountDelegateCallIns(account_, inAmountsByToken);
        } else {
            _claimAccountCallIns(account_, inAmountsByToken, nativeClaimer_);
        }

        // Snapshot output balances before call
        AccountCounter.State memory outBalances = AccountCounter.create(outs_.length);
        for (uint256 i = 0; i < outs_.length; i++) {
            address token = outs_[i].token;
            uint256 sizeBefore = outBalances.size();
            uint256 tokenIndex = outBalances.indexOf(token);
            if (sizeBefore != outBalances.size()) {
                outBalances.setAt(tokenIndex, TokenHelper.balanceOfThis(token, nativeClaimer_));
            }
        }
        uint256 totalOutTokens = outBalances.size();

        // Approve call assets
        uint256 sendValue = _approveAssets(inAmountsByToken, call_.target);

        // Do the call
        bytes memory result = Address.functionCallWithValue(call_.target, call_.data, sendValue);

        // Revoke call assets
        _revokeAssets(inAmountsByToken, call_.target);

        // Decrease output balances by (presumably) spent inputs
        for (uint256 i = 0; i < totalOutTokens; i++) {
            address token = outBalances.accountAt(i);
            uint256 tokenInIndex = inAmountsByToken.indexOf(token, false);
            if (!AccountCounter.isNullIndex(tokenInIndex)) {
                uint256 inAmount = inAmountsByToken.getAt(tokenInIndex);
                outBalances.subAt(i, inAmount);
            }
        }

        // Replace balances before with remaining balances to "spend" on amount checks
        for (uint256 i = 0; i < totalOutTokens; i++) {
            address token = outBalances.accountAt(i);
            uint256 balanceNow = TokenHelper.balanceOfThis(token, nativeClaimer_);
            outBalances.setAt(i, balanceNow - outBalances.getAt(i));
        }

        // Parse outputs from result
        outAmounts = abi.decode(result, (uint256[]));
        require(outAmounts.length == outs_.length, "SW: out amounts length mismatch");

        // Validate output amounts
        for (uint256 i = 0; i < outs_.length; i++) {
            uint256 amount = TokenChecker.checkMin(outs_[i], outAmounts[i]);
            outAmounts[i] = amount;
            uint256 tokenIndex = outBalances.indexOf(outs_[i].token, false);
            require(outBalances.getAt(tokenIndex) >= amount, "SW: insufficient out amount");
            outBalances.subAt(tokenIndex, amount);
        }
    }

    function _claimAccountDelegateCallIns(address account_, AccountCounter.State memory inAmountsByToken_) private {
        uint256 totalInTokens = inAmountsByToken_.size();
        Withdraw[] memory withdraws = new Withdraw[](totalInTokens);
        for (uint256 i = 0; i < totalInTokens; i++) {
            address token = inAmountsByToken_.accountAt(i);
            uint256 amount = inAmountsByToken_.getAt(i);
            withdraws[i] = Withdraw({token: token, amount: amount, to: address(this)});
        }

        IDelegateManager delegateManager = _delegateManager();
        if (!delegateManager.isDelegateDeployed(account_)) {
            delegateManager.deployDelegate(account_);
        }
        delegateManager.withdraw(account_, withdraws);
    }

    function _claimAccountCallIns(
        address account_,
        AccountCounter.State memory inAmountsByToken_,
        NativeClaimer.State memory nativeClaimer_
    ) private {
        uint256 totalInTokens = inAmountsByToken_.size();
        for (uint256 i = 0; i < totalInTokens; i++) {
            address token = inAmountsByToken_.accountAt(i);
            uint256 amount = inAmountsByToken_.getAt(i);
            TokenHelper.transferToThis(token, account_, amount, nativeClaimer_);
        }
    }

    function _approveAssets(
        AccountCounter.State memory amountsByToken_,
        address spender_
    ) private returns (uint256 sendValue) {
        uint256 totalTokens = amountsByToken_.size();
        for (uint256 i = 0; i < totalTokens; i++) {
            address token = amountsByToken_.accountAt(i);
            uint256 amount = amountsByToken_.getAt(i);
            sendValue += TokenHelper.approveOfThis(token, spender_, amount);
        }
    }

    function _revokeAssets(AccountCounter.State memory amountsByToken_, address spender_) private {
        uint256 totalTokens = amountsByToken_.size();
        for (uint256 i = 0; i < totalTokens; i++) {
            address token = amountsByToken_.accountAt(i);
            TokenHelper.revokeOfThis(token, spender_);
        }
    }

    function _performUses(
        TokenUse[] calldata uses_,
        bytes[] calldata useArgs_,
        TokenCheck[] calldata useIns_,
        uint256[] memory useInAmounts_
    ) private {
        uint256 dynamicArgsCursor = 0;
        for (uint256 i = 0; i < uses_.length; i++) {
            bytes calldata args = uses_[i].args;
            if (_shouldUseDynamicArgs(args)) {
                require(dynamicArgsCursor < useArgs_.length, "SW: not enough dynamic use args");
                args = useArgs_[dynamicArgsCursor];
                dynamicArgsCursor++;
            }
            _performUse(uses_[i], args, useIns_, useInAmounts_);
        }
        require(dynamicArgsCursor == useArgs_.length, "SW: too many dynamic use args");
    }

    function _shouldUseDynamicArgs(bytes calldata args_) private pure returns (bool) {
        if (args_.length != 7) {
            return false;
        }
        return bytes7(args_) == 0x44796E616D6963; // "Dynamic" in ASCII
    }

    function _performUse(
        TokenUse calldata use_,
        bytes calldata args_,
        TokenCheck[] calldata useIns_,
        uint256[] memory useInAmounts_
    ) private {
        require(_useProtocolWhitelist().isAccountWhitelisted(use_.protocol), "SW: use protocol not whitelisted");

        TokenCheck[] memory ins = new TokenCheck[](use_.inIndices.length);
        uint256[] memory inAmounts = new uint256[](use_.inIndices.length);
        for (uint256 i = 0; i < use_.inIndices.length; i++) {
            uint256 inIndex = use_.inIndices[i];
            _ensureUseInputUnspent(useInAmounts_, inIndex);
            ins[i] = useIns_[inIndex];
            inAmounts[i] = useInAmounts_[inIndex];
            _spendUseInput(useInAmounts_, inIndex);
        }

        AccountCounter.State memory useInAmounts = AccountCounter.create(use_.inIndices.length);
        for (uint256 i = 0; i < use_.inIndices.length; i++) {
            useInAmounts.add(ins[i].token, inAmounts[i]);
        }

        uint256 sendValue = _approveAssets(useInAmounts, use_.protocol);
        IUseProtocol(use_.protocol).use{value: sendValue}(
            UseParams({
                chain: use_.chain,
                account: use_.account,
                ins: ins,
                inAmounts: inAmounts,
                outs: use_.outs,
                args: args_,
                msgSender: msg.sender,
                msgData: msg.data
            })
        );
        _revokeAssets(useInAmounts, use_.protocol);
    }

    uint256 private constant _SPENT_USE_INPUT = type(uint256).max;

    function _spendUseInput(uint256[] memory inAmounts_, uint256 index_) private pure {
        inAmounts_[index_] = _SPENT_USE_INPUT;
    }

    function _ensureUseInputUnspent(uint256[] memory inAmounts_, uint256 index_) private pure {
        require(inAmounts_[index_] != _SPENT_USE_INPUT, "SW: input already spent");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {StorageSlot} from "../../lib/StorageSlot.sol";

import {IDelegateManager} from "../delegate/IDelegateManager.sol";

import {IAccountWhitelist} from "../whitelist/IAccountWhitelist.sol";

import {ISwapSignatureValidator} from "./ISwapSignatureValidator.sol";

abstract contract SwapperStorage {
    // prettier-ignore
    // bytes32 private constant _SWAP_SIGNATURE_VALIDATOR_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._swapSignatureValidator")) - 1);
    bytes32 private constant _SWAP_SIGNATURE_VALIDATOR_SLOT = 0x572889db8ac91f4b1f7f11b2b1ed6b16c6eeea367a78b3975c5d6ec0ae5187b4;

    function _swapSignatureValidatorStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_SWAP_SIGNATURE_VALIDATOR_SLOT);
    }

    function _swapSignatureValidator() internal view returns (ISwapSignatureValidator) {
        return ISwapSignatureValidator(_swapSignatureValidatorStorage().value);
    }

    function _setSwapSignatureValidator(address swapSignatureValidator_) internal {
        _swapSignatureValidatorStorage().value = swapSignatureValidator_;
    }

    // prettier-ignore
    // bytes32 private constant _PERMIT_RESOLVER_WHITELIST_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._permitResolverWhitelist")) - 1);
    bytes32 private constant _PERMIT_RESOLVER_WHITELIST_SLOT = 0x927ff1d8cfc45c529c885de54239c33280cdded1681dc287ec13e0c279fab4fd;

    function _permitResolverWhitelistStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_PERMIT_RESOLVER_WHITELIST_SLOT);
    }

    function _permitResolverWhitelist() internal view returns (IAccountWhitelist) {
        return IAccountWhitelist(_permitResolverWhitelistStorage().value);
    }

    function _setPermitResolverWhitelist(address permitResolverWhitelist_) internal {
        _permitResolverWhitelistStorage().value = permitResolverWhitelist_;
    }

    // prettier-ignore
    // bytes32 private constant _USE_PROTOCOL_WHITELIST_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._useProtocolWhitelist")) - 1);
    bytes32 private constant _USE_PROTOCOL_WHITELIST_SLOT = 0xd4123124af6bd6de635253002be397fccc55549d14ec64e12254e1dc473a8989;

    function _useProtocolWhitelistStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_USE_PROTOCOL_WHITELIST_SLOT);
    }

    function _useProtocolWhitelist() internal view returns (IAccountWhitelist) {
        return IAccountWhitelist(_useProtocolWhitelistStorage().value);
    }

    function _setUseProtocolWhitelist(address useProtocolWhitelist_) internal {
        _useProtocolWhitelistStorage().value = useProtocolWhitelist_;
    }

    // prettier-ignore
    // bytes32 private constant _DELEGATE_MANAGER_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._delegateManager")) - 1);
    bytes32 private constant _DELEGATE_MANAGER_SLOT = 0xb9ce0614dc8c6b0ba4f1c391d809ad23817a3153e0effd15d0c78e880ecdbbb2;

    function _delegateManagerStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_DELEGATE_MANAGER_SLOT);
    }

    function _delegateManager() internal view returns (IDelegateManager) {
        return IDelegateManager(_delegateManagerStorage().value);
    }

    function _setDelegateManager(address delegateManager_) internal {
        _delegateManagerStorage().value = delegateManager_;
    }

    // bytes32 private constant _NONCES_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._nonces")) - 1);
    bytes32 private constant _NONCES_SLOT = 0x791d4fc0c3c60e2f2f4fc8a10cb89d9841dbac52dccccc663ba39d8dccd7113e;

    function _nonceUsedStorage(
        address account_,
        uint256 nonce_
    ) private pure returns (StorageSlot.BooleanSlot storage) {
        bytes32 slot = _NONCES_SLOT ^ keccak256(abi.encode(nonce_, account_));
        return StorageSlot.getBooleanSlot(slot);
    }

    function _nonceUsed(address account_, uint256 nonce_) internal view returns (bool) {
        return _nonceUsedStorage(account_, nonce_).value;
    }

    function _setNonceUsed(address account_, uint256 nonce_, bool used_) internal {
        _nonceUsedStorage(account_, nonce_).value = used_;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {EIP712D} from "../../lib/draft-EIP712D.sol";
import {ECDSA} from "../../lib/ECDSA.sol";

import {ISwapSignatureValidator} from "./ISwapSignatureValidator.sol";
// prettier-ignore
import {
    TokenCheck,
    TokenUse,
    SwapStep,
    Swap,
    StealthSwap
} from "./Swap.sol";
// prettier-ignore
import {
    TOKEN_CHECK_TYPE_HASH,
    TOKEN_USE_TYPE_HASH,
    SWAP_STEP_TYPE_HASH,
    SWAP_TYPE_HASH,
    STEALTH_SWAP_TYPE_HASH
} from "./SwapTypeHash.sol";

contract SwapSignatureValidator is ISwapSignatureValidator, EIP712D {
    // prettier-ignore
    constructor()
        EIP712D("xSwap", "1")
    {} // solhint-disable-line no-empty-blocks

    /**
     * @dev Validates swap signature
     *
     * The function fails if swap signature is not valid for any reason
     */
    function validateSwapSignature(Swap calldata swap_, bytes calldata swapSignature_) public view {
        require(swap_.steps.length > 0, "SV: swap has no steps");

        bytes32 swapHash = _hashSwap(swap_);
        bytes32 hash = _hashTypedDataV4D(swapHash, swap_.steps[0].chain, swap_.steps[0].swapper);
        address signer = ECDSA.recover(hash, swapSignature_);
        require(signer == swap_.steps[0].account, "SV: invalid swap signature");
    }

    function validateStealthSwapStepSignature(
        SwapStep calldata swapStep_,
        StealthSwap calldata stealthSwap_,
        bytes calldata stealthSwapSignature_
    ) public view returns (uint256 stepIndex) {
        bytes32 swapHash = _hashStealthSwap(stealthSwap_);
        bytes32 hash = _hashTypedDataV4D(swapHash, stealthSwap_.chain, stealthSwap_.swapper);
        address signer = ECDSA.recover(hash, stealthSwapSignature_);
        require(signer == stealthSwap_.account, "SV: invalid s-swap signature");

        return findStealthSwapStepIndex(swapStep_, stealthSwap_);
    }

    function findStealthSwapStepIndex(
        SwapStep calldata swapStep_,
        StealthSwap calldata stealthSwap_
    ) public pure returns (uint256 stepIndex) {
        bytes32 stepHash = _hashSwapStep(swapStep_);
        for (uint256 i = 0; i < stealthSwap_.stepHashes.length; i++) {
            if (stealthSwap_.stepHashes[i] == stepHash) {
                return i;
            }
        }
        revert("SV: no step hash match in s-swap");
    }

    function _hashSwap(Swap calldata swap_) private pure returns (bytes32 swapHash) {
        // prettier-ignore
        swapHash = keccak256(abi.encode(
            SWAP_TYPE_HASH,
            _hashSwapSteps(swap_.steps)
        ));
    }

    function _hashSwapSteps(SwapStep[] calldata swapSteps_) private pure returns (bytes32 swapStepsHash) {
        bytes memory bytesToHash = new bytes(swapSteps_.length << 5); // * 0x20
        uint256 offset;
        assembly {
            offset := add(bytesToHash, 0x20)
        }
        for (uint256 i = 0; i < swapSteps_.length; i++) {
            bytes32 hash = _hashSwapStep(swapSteps_[i]);
            assembly {
                mstore(offset, hash)
                offset := add(offset, 0x20)
            }
        }
        swapStepsHash = keccak256(bytesToHash);
    }

    function _hashSwapStep(SwapStep calldata swapStep_) private pure returns (bytes32 swapStepHash) {
        // prettier-ignore
        swapStepHash = keccak256(abi.encode(
            SWAP_STEP_TYPE_HASH,
            swapStep_.chain,
            swapStep_.swapper,
            swapStep_.account,
            swapStep_.useDelegate,
            swapStep_.nonce,
            swapStep_.deadline,
            _hashTokenChecks(swapStep_.ins),
            _hashTokenChecks(swapStep_.outs),
            _hashTokenUses(swapStep_.uses)
        ));
    }

    function _hashTokenChecks(TokenCheck[] calldata tokenChecks_) private pure returns (bytes32 tokenChecksHash) {
        bytes memory bytesToHash = new bytes(tokenChecks_.length << 5); // * 0x20
        uint256 offset;
        assembly {
            offset := add(bytesToHash, 0x20)
        }
        for (uint256 i = 0; i < tokenChecks_.length; i++) {
            bytes32 hash = _hashTokenCheck(tokenChecks_[i]);
            assembly {
                mstore(offset, hash)
                offset := add(offset, 0x20)
            }
        }
        tokenChecksHash = keccak256(bytesToHash);
    }

    function _hashTokenCheck(TokenCheck calldata tokenCheck_) private pure returns (bytes32 tokenCheckHash) {
        // prettier-ignore
        tokenCheckHash = keccak256(abi.encode(
            TOKEN_CHECK_TYPE_HASH,
            tokenCheck_.token,
            tokenCheck_.minAmount,
            tokenCheck_.maxAmount
        ));
    }

    function _hashTokenUses(TokenUse[] calldata tokenUses_) private pure returns (bytes32 tokenUsesHash) {
        bytes memory bytesToHash = new bytes(tokenUses_.length << 5); // * 0x20
        uint256 offset;
        assembly {
            offset := add(bytesToHash, 0x20)
        }
        for (uint256 i = 0; i < tokenUses_.length; i++) {
            bytes32 hash = _hashTokenUse(tokenUses_[i]);
            assembly {
                mstore(offset, hash)
                offset := add(offset, 0x20)
            }
        }
        tokenUsesHash = keccak256(bytesToHash);
    }

    function _hashTokenUse(TokenUse calldata tokenUse_) private pure returns (bytes32 tokenUseHash) {
        // prettier-ignore
        tokenUseHash = keccak256(abi.encode(
            TOKEN_USE_TYPE_HASH,
            tokenUse_.protocol,
            tokenUse_.chain,
            tokenUse_.account,
            _hashUint256Array(tokenUse_.inIndices),
            _hashTokenChecks(tokenUse_.outs),
            _hashBytes(tokenUse_.args)
        ));
    }

    function _hashStealthSwap(StealthSwap calldata stealthSwap_) private pure returns (bytes32 stealthSwapHash) {
        bytes32 stepsHash = _hashBytes32Array(stealthSwap_.stepHashes);

        stealthSwapHash = keccak256(
            abi.encode(
                STEALTH_SWAP_TYPE_HASH,
                stealthSwap_.chain,
                stealthSwap_.swapper,
                stealthSwap_.account,
                stepsHash
            )
        );
    }

    function _hashBytes(bytes calldata bytes_) private pure returns (bytes32 bytesHash) {
        bytesHash = keccak256(bytes_);
    }

    function _hashBytes32Array(bytes32[] calldata array_) private pure returns (bytes32 arrayHash) {
        arrayHash = keccak256(abi.encodePacked(array_));
    }

    function _hashUint256Array(uint256[] calldata array_) private pure returns (bytes32 arrayHash) {
        arrayHash = keccak256(abi.encodePacked(array_));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

/**
 * @dev Reflects types from "./Swap.sol"
 */

// prettier-ignore
string constant _TOKEN_CHECK_TYPE =
    "TokenCheck("
        "address token,"
        "uint256 minAmount,"
        "uint256 maxAmount"
    ")";

// prettier-ignore
string constant _TOKEN_USE_TYPE =
    "TokenUse("
        "address protocol,"
        "uint256 chain,"
        "address account,"
        "uint256[] inIndices,"
        "TokenCheck[] outs,"
        "bytes args"
    ")";

// prettier-ignore
string constant _SWAP_STEP_TYPE =
    "SwapStep("
        "uint256 chain,"
        "address swapper,"
        "address account,"
        "bool useDelegate,"
        "uint256 nonce,"
        "uint256 deadline,"
        "TokenCheck[] ins,"
        "TokenCheck[] outs,"
        "TokenUse[] uses"
    ")";

// prettier-ignore
string constant _SWAP_TYPE =
    "Swap("
        "SwapStep[] steps"
    ")";

// prettier-ignore
string constant _STEALTH_SWAP_TYPE =
    "StealthSwap("
        "uint256 chain,"
        "address swapper,"
        "address account,"
        "bytes32[] stepHashes"
    ")";

/**
 * @dev Hashes of the types above
 *
 * Remember that:
 * - Main hashed type goes first
 * - Subtypes go next in alphabetical order (specified in EIP-712)
 */

// prettier-ignore
bytes32 constant _TOKEN_CHECK_TYPE_HASH = keccak256(abi.encodePacked(
    _TOKEN_CHECK_TYPE
));

// prettier-ignore
bytes32 constant _TOKEN_USE_TYPE_HASH = keccak256(abi.encodePacked(
    _TOKEN_USE_TYPE,
    _TOKEN_CHECK_TYPE
));

// prettier-ignore
bytes32 constant _SWAP_STEP_TYPE_HASH = keccak256(abi.encodePacked(
    _SWAP_STEP_TYPE,
    _TOKEN_CHECK_TYPE,
    _TOKEN_USE_TYPE
));

// prettier-ignore
bytes32 constant _SWAP_TYPE_HASH = keccak256(abi.encodePacked(
    _SWAP_TYPE,
    _SWAP_STEP_TYPE,
    _TOKEN_CHECK_TYPE,
    _TOKEN_USE_TYPE
));

// prettier-ignore
bytes32 constant _STEALTH_SWAP_TYPE_HASH = keccak256(abi.encodePacked(
    _STEALTH_SWAP_TYPE
));

/**
 * @dev Hash values pre-calculated w/ `tools/hash` to reduce contract size
 */

// bytes32 constant TOKEN_CHECK_TYPE_HASH = _TOKEN_CHECK_TYPE_HASH;
bytes32 constant TOKEN_CHECK_TYPE_HASH = 0x382391664c9ae06333b02668b6d763ab547bd70c71636e236fdafaacf1e55bdd;

// bytes32 constant TOKEN_USE_TYPE_HASH = _TOKEN_USE_TYPE_HASH;
bytes32 constant TOKEN_USE_TYPE_HASH = 0x192f17c5e66907915b200bca0d866184770ff7faf25a0b4ccd2ef26ebd21725a;

// bytes32 constant SWAP_STEP_TYPE_HASH = _SWAP_STEP_TYPE_HASH;
bytes32 constant SWAP_STEP_TYPE_HASH = 0x973db6284d4ead3ce5e0ee0d446a483b1b5ff8cd93a2b86dbd0a9f03a6cefc8a;

// bytes32 constant SWAP_TYPE_HASH = _SWAP_TYPE_HASH;
bytes32 constant SWAP_TYPE_HASH = 0xba1e9d0b1bee57631ad5f99eac149c1229822508d3dfc4f8fa2c5089bb99c874;

// bytes32 constant STEALTH_SWAP_TYPE_HASH = _STEALTH_SWAP_TYPE_HASH;
bytes32 constant STEALTH_SWAP_TYPE_HASH = 0x0f2b1c8dae54aa1b96d626d678ec60a7c6d113b80ccaf635737a6f003d1cbaf5;

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {TokenCheck} from "../swap/Swap.sol";

struct UseParams {
    uint256 chain;
    address account;
    TokenCheck[] ins;
    uint256[] inAmounts;
    TokenCheck[] outs;
    bytes args;
    address msgSender;
    bytes msgData;
}

interface IUseProtocol {
    function use(UseParams calldata params) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IAccountWhitelist {
    event AccountAdded(address account);
    event AccountRemoved(address account);

    function getWhitelistedAccounts() external view returns (address[] memory);

    function isAccountWhitelisted(address account) external view returns (bool);

    function addAccountToWhitelist(address account) external;

    function removeAccountFromWhitelist(address account) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {IOwnable} from "../../lib/IOwnable.sol";

import {ISimpleInitializable} from "../init/ISimpleInitializable.sol";

import {IAccountWhitelist} from "./IAccountWhitelist.sol";

// solhint-disable-next-line no-empty-blocks
interface IOwnableAccountWhitelist is IAccountWhitelist, IOwnable, ISimpleInitializable {

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Ownable} from "../../lib/Ownable.sol";
import {EnumerableSet} from "../../lib/EnumerableSet.sol";

import {SimpleInitializable} from "../init/SimpleInitializable.sol";

import {IOwnableAccountWhitelist} from "./IOwnableAccountWhitelist.sol";

contract OwnableAccountWhitelist is IOwnableAccountWhitelist, Ownable, SimpleInitializable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _accounts;

    constructor() {
        _initializeWithSender();
    }

    function getWhitelistedAccounts() external view returns (address[] memory) {
        return _accounts.values();
    }

    function isAccountWhitelisted(address account_) external view returns (bool) {
        return _accounts.contains(account_);
    }

    function addAccountToWhitelist(address account_) external whenInitialized onlyOwner {
        require(_accounts.add(account_), "WL: account already included");
        emit AccountAdded(account_);
    }

    function removeAccountFromWhitelist(address account_) external whenInitialized onlyOwner {
        require(_accounts.remove(account_), "WL: account already excluded");
        emit AccountRemoved(account_);
    }

    function _initialize() internal override {
        _transferOwnership(initializer());
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Clones} from "../../lib/Clones.sol";

import {IOwnableAccountWhitelist} from "./IOwnableAccountWhitelist.sol";

/**
 * Factory that deploys `OwnableAccountWhitelist` contract clones by making use of minimal proxy
 *
 * Meant to be utility class for internal usage only
 */
contract OwnableAccountWhitelistFactory {
    address private immutable _ownableAccountWhitelistPrototype;

    constructor(address ownableAccountWhitelistPrototype_) {
        _ownableAccountWhitelistPrototype = ownableAccountWhitelistPrototype_;
    }

    function deployClone() external returns (address ownableAccountWhitelist) {
        ownableAccountWhitelist = Clones.clone(_ownableAccountWhitelistPrototype);
        IOwnableAccountWhitelist(ownableAccountWhitelist).initialize();
        IOwnableAccountWhitelist(ownableAccountWhitelist).transferOwnership(msg.sender);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

struct Withdraw {
    address token;
    uint256 amount;
    address to;
}

interface IWithdrawable {
    event Withdrawn(address token, uint256 amount, address to);

    function withdraw(Withdraw[] calldata withdraws) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Withdrawable} from "./Withdrawable.sol";

import {WhitelistWithdrawableStorage} from "./WhitelistWithdrawableStorage.sol";

abstract contract WhitelistWithdrawable is Withdrawable, WhitelistWithdrawableStorage {
    constructor(
        bytes32 withdrawWhitelistSlot_,
        address withdrawWhitelist_
    ) WhitelistWithdrawableStorage(withdrawWhitelistSlot_) {
        _initialize(withdrawWhitelist_);
    }

    function initializeWhitelistWithdrawable(address withdrawWhitelist_) internal {
        _initialize(withdrawWhitelist_);
    }

    function _initialize(address withdrawWhitelist_) private {
        require(withdrawWhitelist_ != address(0), "WW: zero withdraw whitelist");
        _setWithdrawWhitelist(withdrawWhitelist_);
    }

    function _checkWithdraw() internal view override {
        _checkWithdrawerWhitelisted();
    }

    function _checkWithdrawerWhitelisted() private view {
        require(_withdrawWhitelist().isAccountWhitelisted(msg.sender), "WW: withdrawer not whitelisted");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {StorageSlot} from "../../lib/StorageSlot.sol";

import {TokenHelper} from "../asset/TokenHelper.sol";

import {IAccountWhitelist} from "../whitelist/IAccountWhitelist.sol";

import {Withdrawable} from "./Withdrawable.sol";

abstract contract WhitelistWithdrawableStorage {
    bytes32 private immutable _withdrawWhitelistSlot;

    constructor(bytes32 withdrawWhitelistSlot_) {
        _withdrawWhitelistSlot = withdrawWhitelistSlot_;
    }

    function _withdrawWhitelistStorage() private view returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_withdrawWhitelistSlot);
    }

    function _withdrawWhitelist() internal view returns (IAccountWhitelist) {
        return IAccountWhitelist(_withdrawWhitelistStorage().value);
    }

    function _setWithdrawWhitelist(address withdrawWhitelist_) internal {
        _withdrawWhitelistStorage().value = withdrawWhitelist_;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {TokenHelper} from "../asset/TokenHelper.sol";

import {IWithdrawable, Withdraw} from "./IWithdrawable.sol";

abstract contract Withdrawable is IWithdrawable {
    function withdraw(Withdraw[] calldata withdraws_) external virtual {
        _checkWithdraw();

        for (uint256 i = 0; i < withdraws_.length; i++) {
            Withdraw calldata w = withdraws_[i];
            TokenHelper.transferFromThis(w.token, w.to, w.amount);
            emit Withdrawn(w.token, w.amount, w.to);
        }
    }

    function _checkWithdraw() internal view virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Address} implementation:
 * - bump `pragma solidity` (`^0.8.1` -> `^0.8.16`)
 * - shortify `require` messages (`Address:` -> `AD:` + others to avoid length warnings)
 * - disable some `solhint` rules for the file
 */

/* solhint-disable avoid-low-level-calls */

pragma solidity ^0.8.16;

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
        require(address(this).balance >= amount, "AD: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "AD: unable to send value");
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
        return functionCallWithValue(target, data, 0, "AD: low-level call fail");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "AD: low-level value call fail");
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
        require(address(this).balance >= value, "AD: not enough balance for call");
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
        return functionStaticCall(target, data, "AD: low-level static call fail");
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
        return functionDelegateCall(target, data, "AD: low-level delegate call fail");
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
                require(isContract(target), "AD: call to non-contract");
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Clones} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - shortify `require` messages (`ERC1167:` -> `CL:`)
 */

pragma solidity ^0.8.16;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "CL: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "CL: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Context} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Counters} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - shortify `require` messages (`Counters:` -> `CN:`)
 */

pragma solidity ^0.8.16;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "CN: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {EIP712} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

/**
 * @dev xSwap fork of the original OpenZeppelin's {EIP712} implementation
 *
 * The fork allows typed data hashing with arbitrary chainId & verifyingContract for domain separator
 */

pragma solidity ^0.8.16;

import "./ECDSA.sol";

abstract contract EIP712D {
    /* solhint-disable var-name-mixedcase */

    // bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant _TYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private immutable _NAME_HASH;
    bytes32 private immutable _VERSION_HASH;

    /* solhint-enable var-name-mixedcase */

    constructor(string memory name, string memory version) {
        _NAME_HASH = keccak256(bytes(name));
        _VERSION_HASH = keccak256(bytes(version));
    }

    function _domainSeparatorV4D(uint256 chainId, address verifyingContract) internal view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _NAME_HASH, _VERSION_HASH, chainId, verifyingContract));
    }

    function _hashTypedDataV4D(
        bytes32 structHash,
        uint256 chainId,
        address verifyingContract
    ) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4D(chainId, verifyingContract), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {ERC20Permit} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - adjust OpenZeppelin's imports (use `library` implementation)
 */

pragma solidity ^0.8.16;

import "./draft-IERC20Permit.sol";
import "./ERC20.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {IERC20Permit} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {ECDSA} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - adjust OpenZeppelin's {Strings} import (use `library` implementation)
 * - shortify `require` messages (`ECDSA:` -> `EC:`)
 * - extract `decompress(bytes32 vs)` private function from `tryRecover(bytes32 hash, bytes32 r, bytes32 vs)`
 * - extract `tryDecompose(bytes memory signature)` private function from `tryRecover(bytes32 hash, bytes memory signature)`
 */

pragma solidity ^0.8.16;

import "./Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("EC: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("EC: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("EC: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("EC: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address signer, RecoverError err) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        (r, s, v, err) = tryDecompose(signature);
        if (err == RecoverError.NoError) {
            (signer, err) = tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Extracted from {ECDSA-tryRecover} (bytes32 hash, bytes memory signature) for xSwap needs
     */
    function tryDecompose(
        bytes memory signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v, RecoverError err) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            (s, v) = decompress(vs);
        } else {
            err = RecoverError.InvalidSignatureLength;
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        (bytes32 s, uint8 v) = decompress(vs);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Extracted from {ECDSA-tryRecover} (bytes32 hash, bytes32 r, bytes32 vs) for xSwap needs
     */
    function decompress(bytes32 vs) private pure returns (bytes32 s, uint8 v) {
        s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        v = uint8((uint256(vs) >> 255) + 27);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {EnumerableSet} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {ERC20} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - adjust OpenZeppelin's imports (use `library` implementations)
 */

pragma solidity ^0.8.16;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./IERC20Metadata.sol";
import {Context} from "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {IERC20} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {IERC20Metadata} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - adjust OpenZeppelin's {IERC20} import (use `library` implementation)
 */

pragma solidity ^0.8.16;

import {IERC20} from "./IERC20.sol";

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

pragma solidity ^0.8.16;

interface IOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

/**
 * @dev Public interface of OpenZeppelin's {Pausable}.
 */
interface IPausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Math} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb computation, we are able to compute `result = 2**(k/2)` which is a
        // good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Ownable} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - adjust OpenZeppelin's {Context} import (use `library` implementation)
 * - shortify `require` messages (`Ownable:` -> `OW:` + others to avoid length warnings)
 * - extract {IOwnable} interface
 */

pragma solidity ^0.8.16;

import {IOwnable} from "./IOwnable.sol";
import {Context} from "./Context.sol";

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
abstract contract Ownable is IOwnable, Context {
    address private _owner;

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
     * @dev See {IOwnable-owner}
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "OW: caller is not the owner");
    }

    /**
     * @dev See {IOwnable-renounceOwnership}
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev See {IOwnable-transferOwnership}
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "OW: new owner is zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Pausable} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - adjust OpenZeppelin's {Context} import (use `library` implementation)
 * - inherit from {IPausable}
 * - remove IPausable-duplicated events
 * - shortify `require` messages (`Pausable:` -> `PA:`)
 */

pragma solidity ^0.8.16;

import {IPausable} from "./IPausable.sol";
import {Context} from "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is IPausable, Context {
    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "PA: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "PA: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {SafeERC20} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - adjust OpenZeppelin's {IERC20}, {IERC20Permit}, {Address} imports (use `library` implementation)
 * - shortify `require` messages (`SafeERC20:` -> `SE:` + others to avoid length warnings)
 */

pragma solidity ^0.8.16;

import {IERC20} from "./IERC20.sol";
import {IERC20Permit} from "./draft-IERC20Permit.sol";
import {Address} from "./Address.sol";

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
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SE: approve from non-0 to non-0");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SE: decreased allowance below 0");
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
        require(nonceAfter == nonceBefore + 1, "SE: permit did not succeed");
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

        bytes memory returndata = address(token).functionCall(data, "SE: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SE: ERC20 operation failed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {StorageSlot} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Strings} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {NativeClaimer} from "../../core/asset/NativeClaimer.sol";
import {NativeReturnMods} from "../../core/asset/NativeReturnMods.sol";
import {TokenHelper} from "../../core/asset/TokenHelper.sol";

import {TokenCheck} from "../../core/swap/Swap.sol";

import {IUseProtocol, UseParams} from "../../core/use/IUseProtocol.sol";

import {WhitelistWithdrawable} from "../../core/withdraw/WhitelistWithdrawable.sol";

interface ICBridge {
    function send(
        address receiver,
        address token,
        uint256 amount,
        uint64 dstChainId,
        uint64 nonce,
        uint32 maxSlippage
    ) external;

    function sendNative(
        address receiver,
        uint256 amount,
        uint64 dstChainId,
        uint64 nonce,
        uint32 maxSlippage
    ) external payable;
}

struct CBridgeProtocolConstructorParams {
    /**
     * @dev {ICBridge}-compatible contract address
     */
    address cBridge;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address withdrawWhitelist;
}

/**
 * @dev Bridge hop wrapper for cBridge:
 *
 * - Exactly one input & one output
 * - The slippage value is calculated from output min/max
 * - The account serves as receiver in destination network specified by the chain
 * - No extra args
 */
contract CBridgeProtocol is IUseProtocol, WhitelistWithdrawable, NativeReturnMods {
    address private immutable _cBridge;

    // prettier-ignore
    // bytes32 private constant _WITHDRAW_WHITELIST_SLOT = bytes32(uint256(keccak256("xSwap.v2.CBridge._withdrawWhitelist")) - 1);
    bytes32 private constant _WITHDRAW_WHITELIST_SLOT = 0x3cb777f3329ec057e429c7d75d1671dca3eac2ab9f72462f6bb784b8a67066c8;

    uint256 private constant _C_BRIDGE_SLIPPAGE_UNITS_IN_PERCENT = 10_000; // From cBridge slippage implementation

    constructor(
        CBridgeProtocolConstructorParams memory params_
    ) WhitelistWithdrawable(_WITHDRAW_WHITELIST_SLOT, params_.withdrawWhitelist) {
        require(params_.cBridge != address(0), "CB: zero cBridge contract");
        _cBridge = params_.cBridge;
    }

    function cBridge() external view returns (address) {
        return _cBridge;
    }

    function use(UseParams calldata params_) external payable {
        require(params_.chain != block.chainid, "CB: wrong chain id");
        require(params_.account != address(0), "CB: zero receiver");
        require(params_.args.length == 0, "CB: unexpected args");

        require(params_.ins.length == 1, "CB: wrong number of ins");
        require(params_.inAmounts.length == 1, "CB: wrong number of in amounts");
        require(params_.outs.length == 1, "CB: wrong number of outs");

        NativeClaimer.State memory nativeClaimer;
        _hop(params_.ins[0], params_.inAmounts[0], params_.outs[0], params_.chain, params_.account, nativeClaimer);
    }

    function _hop(
        TokenCheck calldata in_,
        uint256 inAmount_,
        TokenCheck calldata out_,
        uint256 chain_,
        address account_,
        NativeClaimer.State memory nativeClaimer_
    ) private returnUnclaimedNative(nativeClaimer_) {
        TokenHelper.transferToThis(in_.token, msg.sender, inAmount_, nativeClaimer_);

        if (TokenHelper.isNative(in_.token)) {
            ICBridge(_cBridge).sendNative{value: inAmount_}(
                account_,
                inAmount_,
                _dstChainId(chain_),
                _nonce(),
                _maxSlippage(out_)
            );
        } else {
            TokenHelper.approveOfThis(in_.token, _cBridge, inAmount_);
            // prettier-ignore
            ICBridge(_cBridge).send(
                account_,
                in_.token,
                inAmount_,
                _dstChainId(chain_),
                _nonce(),
                _maxSlippage(out_)
            );
            TokenHelper.revokeOfThis(in_.token, _cBridge);
        }
    }

    function _dstChainId(uint256 chain_) private pure returns (uint64) {
        return uint64(chain_);
    }

    function _nonce() private view returns (uint64) {
        return uint64(block.timestamp); // solhint-disable not-rely-on-time
    }

    function _maxSlippage(TokenCheck calldata out_) private pure returns (uint32) {
        uint256 slippage = ((out_.maxAmount - out_.minAmount) * _C_BRIDGE_SLIPPAGE_UNITS_IN_PERCENT) / out_.maxAmount;
        return uint32(slippage);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {NativeClaimer} from "../../core/asset/NativeClaimer.sol";
import {NativeReturnMods} from "../../core/asset/NativeReturnMods.sol";
import {TokenHelper} from "../../core/asset/TokenHelper.sol";

import {TokenCheck} from "../../core/swap/Swap.sol";

import {IUseProtocol, UseParams} from "../../core/use/IUseProtocol.sol";

import {WhitelistWithdrawable} from "../../core/withdraw/WhitelistWithdrawable.sol";

interface IHyphen {
    function depositErc20(
        uint256 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        string calldata tag
    ) external;

    function depositNative(address receiver, uint256 toChainId, string calldata tag) external payable;
}

struct HyphenProtocolConstructorParams {
    /**
     * @dev {IHyphen}-compatible contract address
     */
    address hyphen;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address withdrawWhitelist;
}

/**
 * @dev Bridge hop wrapper for Hyphen:
 *
 * - Exactly one input & one output
 * - The slippage value is calculated from output min/max
 * - The account serves as receiver in destination network specified by the chain
 * - No extra args
 */
contract HyphenProtocol is IUseProtocol, WhitelistWithdrawable, NativeReturnMods {
    using TokenHelper for address;
    using NativeClaimer for NativeClaimer.State;

    // prettier-ignore
    // bytes32 private constant _WITHDRAW_WHITELIST_SLOT = bytes32(uint256(keccak256("xSwap.v2.Hyphen._withdrawWhitelist")) - 1);
    bytes32 private constant _WITHDRAW_WHITELIST_SLOT = 0x8a8b56bb36a8e9b6e477b249781cbd9aa3ad921c548a329326e43db21adec85d;

    address private immutable _hyphen;

    // prettier-ignore
    constructor(HyphenProtocolConstructorParams memory params_)
        WhitelistWithdrawable(_WITHDRAW_WHITELIST_SLOT, params_.withdrawWhitelist)
    {
        _hyphen = params_.hyphen;
    }

    function hyphen() external view returns (address) {
        return _hyphen;
    }

    function use(UseParams calldata params_) external payable {
        require(params_.chain != block.chainid, "HB: wrong chain id");
        require(params_.account != address(0), "HB: zero receiver");
        require(params_.args.length == 0, "HB: unexpected args");

        require(params_.ins.length == 1, "HB: wrong number of ins");
        require(params_.inAmounts.length == 1, "HB: wrong number of in amounts");
        require(params_.outs.length == 1, "HB: wrong number of outs");

        NativeClaimer.State memory nativeClaimer;
        _hop(params_.ins[0], params_.inAmounts[0], params_.chain, params_.account, nativeClaimer);
    }

    function _hop(
        TokenCheck calldata in_,
        uint256 inAmount_,
        uint256 chain_,
        address account_,
        NativeClaimer.State memory nativeClaimer_
    ) private returnUnclaimedNative(nativeClaimer_) {
        TokenHelper.transferToThis(in_.token, msg.sender, inAmount_, nativeClaimer_);

        if (TokenHelper.isNative(in_.token)) {
            // prettier-ignore
            IHyphen(_hyphen).depositNative{value: inAmount_}(
                account_,
                _toChainId(chain_),
                "xSwap"
            );
        } else {
            TokenHelper.approveOfThis(in_.token, _hyphen, inAmount_);
            // prettier-ignore
            IHyphen(_hyphen).depositErc20(
                _toChainId(chain_),
                in_.token,
                account_,
                inAmount_,
                "xSwap"
            );
            TokenHelper.revokeOfThis(in_.token, _hyphen);
        }
    }

    function _toChainId(uint256 chain_) private pure returns (uint64) {
        return uint64(chain_);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {TokenHelper} from "../../core/asset/TokenHelper.sol";
import {TokenChecker} from "../../core/asset/TokenChecker.sol";
import {NativeClaimer} from "../../core/asset/NativeClaimer.sol";
import {NativeReturnMods} from "../../core/asset/NativeReturnMods.sol";

import {TokenCheck} from "../../core/swap/Swap.sol";

import {IUseProtocol, UseParams} from "../../core/use/IUseProtocol.sol";

import {IGasVendor, GasFee} from "./IGasVendor.sol";

/**
 * @dev Vendor-based gas payment protocol
 *
 * - Bound to one {IGasVendor}-compatible contract
 * - Gets fee details from the vendor, validates amount, and sends it to the fee collector
 * - Accepts one input and zero outputs
 * - The caller must match specified account
 * - Chain ID must match current chain
 * - No extra args
 */
contract GasVendorProtocol is IUseProtocol, NativeReturnMods {
    address private immutable _vendor;

    constructor(address vendor_) {
        require(vendor_ != address(0), "GP: zero vendor");
        _vendor = vendor_;
    }

    function use(UseParams calldata params_) external payable {
        require(params_.chain == block.chainid, "GP: wrong chain id");
        require(params_.account == msg.sender, "GP: wrong sender account");
        require(params_.args.length == 0, "GP: unexpected args");

        require(params_.ins.length == 1, "GP: wrong number of ins");
        require(params_.inAmounts.length == 1, "GP: wrong number of in amounts");
        require(params_.outs.length == 0, "GP: wrong number of outs");

        NativeClaimer.State memory nativeClaimer;
        _maybePayGas(params_.ins[0], params_.inAmounts[0], params_.msgSender, params_.msgData, nativeClaimer);
    }

    function _maybePayGas(
        TokenCheck calldata input_,
        uint256 inputAmount_,
        address msgSender,
        bytes calldata msgData,
        NativeClaimer.State memory nativeClaimer_
    ) private returnUnclaimedNative(nativeClaimer_) {
        if (!_gasFeeEnabled(input_)) {
            return;
        }

        GasFee memory gasFee = IGasVendor(_vendor).getGasFee(msgSender, msgData);
        if (!_shouldPayGasFee(gasFee)) {
            return;
        }

        require(gasFee.amount <= inputAmount_, "GP: gas amount exceeds available");
        TokenChecker.checkMinMaxToken(input_, gasFee.amount, gasFee.token);

        TokenHelper.transferToThis(gasFee.token, msg.sender, gasFee.amount, nativeClaimer_);
        TokenHelper.transferFromThis(gasFee.token, gasFee.collector, gasFee.amount);
    }

    function _gasFeeEnabled(TokenCheck calldata gasOut_) private pure returns (bool) {
        return gasOut_.maxAmount > 0;
    }

    function _shouldPayGasFee(GasFee memory gasFee_) private pure returns (bool) {
        return gasFee_.collector != address(0);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {TokenHelper} from "../../core/asset/TokenHelper.sol";
import {TokenChecker} from "../../core/asset/TokenChecker.sol";
import {NativeClaimer} from "../../core/asset/NativeClaimer.sol";
import {NativeReturnMods} from "../../core/asset/NativeReturnMods.sol";

import {TokenCheck} from "../../core/swap/Swap.sol";

import {IUseProtocol, UseParams} from "../../core/use/IUseProtocol.sol";

import {IGasVendor, GasFee} from "./IGasVendor.sol";

/**
 * @dev Vendor-based gas payment protocol
 *
 * - Bound to one {IGasVendor}-compatible contract
 * - Gets fee details from the vendor, validates amount, and sends it to the fee collector
 * - Accepts one input and one dummy output (see explanation below)
 * - The caller must match specified account
 * - Chain ID must match current chain
 * - No extra args
 *
 * @dev The 'V2' introduction:
 *
 * There is an issue w/ Trust wallet that makes typed data sign fail if a value
 * that is being signed contains an empty array of structures. So happened that
 * the only case for us is the 'GasVendorProtocol' with its empty 'outs'. This
 * issues makes all swaps via Trust wallet pretty much impossible since gas
 * protocol is presented in each of them.
 *
 * While we are waiting for Trust wallet team to fix the reported issue, we
 * introduce 'GasVendorProtocolV2'. It requires exactly one dummy output with
 * no meaning other than mitigate the issue.
 */
contract GasVendorProtocolV2 is IUseProtocol, NativeReturnMods {
    address private immutable _vendor;

    constructor(address vendor_) {
        require(vendor_ != address(0), "GP: zero vendor");
        _vendor = vendor_;
    }

    function use(UseParams calldata params_) external payable {
        require(params_.chain == block.chainid, "GP: wrong chain id");
        require(params_.account == msg.sender, "GP: wrong sender account");
        require(params_.args.length == 0, "GP: unexpected args");

        require(params_.ins.length == 1, "GP: wrong number of ins");
        require(params_.inAmounts.length == 1, "GP: wrong number of in amounts");
        require(params_.outs.length == 1, "GP: wrong number of outs");
        require(params_.outs[0].token == address(0), "GP: wrong dummy out token");
        require(params_.outs[0].minAmount == 0, "GP: wrong dummy out min amount");
        require(params_.outs[0].maxAmount == 0, "GP: wrong dummy out max amount");

        NativeClaimer.State memory nativeClaimer;
        _maybePayGas(params_.ins[0], params_.inAmounts[0], params_.msgSender, params_.msgData, nativeClaimer);
    }

    function _maybePayGas(
        TokenCheck calldata input_,
        uint256 inputAmount_,
        address msgSender,
        bytes calldata msgData,
        NativeClaimer.State memory nativeClaimer_
    ) private returnUnclaimedNative(nativeClaimer_) {
        if (!_gasFeeEnabled(input_)) {
            return;
        }

        GasFee memory gasFee = IGasVendor(_vendor).getGasFee(msgSender, msgData);
        if (!_shouldPayGasFee(gasFee)) {
            return;
        }

        require(gasFee.amount <= inputAmount_, "GP: gas amount exceeds available");
        TokenChecker.checkMinMaxToken(input_, gasFee.amount, gasFee.token);

        TokenHelper.transferToThis(gasFee.token, msg.sender, gasFee.amount, nativeClaimer_);
        TokenHelper.transferFromThis(gasFee.token, gasFee.collector, gasFee.amount);
    }

    function _gasFeeEnabled(TokenCheck calldata gasOut_) private pure returns (bool) {
        return gasOut_.maxAmount > 0;
    }

    function _shouldPayGasFee(GasFee memory gasFee_) private pure returns (bool) {
        return gasFee_.collector != address(0);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

struct GasFee {
    uint256 amount;
    address token;
    address collector;
}

/**
 * @dev Interface that must be implemented by an automation gas vendor.
 */
interface IGasVendor {
    /**
     * @dev Checks for gas fee to pay and returns its details: amount, token,
     * and collector address to send the amount of the token to.
     *
     * When no fee payment required, the function returns all of these fields set
     * to '0'. The caller must check this before sending payment since an attempt
     * to perform a transfer with such parameters will fail contract execution.
     */
    function getGasFee(address msgSender, bytes calldata msgData) external returns (GasFee memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Context} from "../../../lib/Context.sol";

import {TokenHelper} from "../../../core/asset/TokenHelper.sol";

import {IGasVendor, GasFee} from "../IGasVendor.sol";

/**
 * @dev Gelato Ops contract interface.
 *
 * See https://github.com/gelatodigital/ops/blob/master/contracts/Ops.sol.
 */
interface IGelatoOps {
    function gelato() external view returns (address payable);

    function getFeeDetails() external view returns (uint256 fee, address feeToken);
}

struct GelatoGasVendorConstructorParams {
    /**
     * @dev Gelato Ops contract address. Depends on network contract is deployed to, see:
     * https://docs.gelato.network/developer-products/gelato-ops-smart-contract-automation-hub/contract-addresses.
     * Zero address disables Gelato Ops support by the contract.
     */
    address ops;
    /**
     * @dev Gelato Relay contract address. 0xaBcC9b596420A9E9172FD5938620E265a0f9Df92 for all main networks.
     * Zero address disables Gelato Relay support by the contract.
     */
    address relay;
}

/**
 * @dev Contract logic responsible for Gelato-based contract execution automation.
 * Currently two automation scenarios are supported by the implementation:
 * - via Gelato Ops (https://docs.gelato.network/developer-products/gelato-ops-smart-contract-automation-hub)
 * - via Gelato Relay (https://docs.gelato.network/developer-products/gelato-relay-sdk)
 *
 * The relay implementation is based on original Gelato contracts adapted to xSwap specific.
 * Related files (https://github.com/gelatodigital/relay-context-contracts/blob/e39a479f3ca75dc707a29c827c26230c8d1a2f2f):
 * - contracts/GelatoRelayContext.sol
 * - contracts/lib/TokenUtils.sol
 * - contracts/constants/GelatoRelay.sol
 * - contracts/constants/Tokens.sol
 */
contract GelatoGasVendor is IGasVendor {
    address private immutable _ops;
    address private immutable _relay;
    address payable private _opsGelato;

    address private constant GELATO_NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant RELAY_DATA_FEE_COLLECTOR_START = 3 * 32;
    uint256 private constant RELAY_DATA_FEE_TOKEN_START = 2 * 32;
    uint256 private constant RELAY_DATA_FEE_START = 32;

    constructor(GelatoGasVendorConstructorParams memory params_) {
        _ops = params_.ops;
        if (params_.ops != address(0)) {
            try IGelatoOps(params_.ops).gelato() returns (address payable opsGelato_) {
                require(opsGelato_ != address(0), "GV: zero gelato address from ops");
                _opsGelato = opsGelato_;
            } catch {
                revert("GV: gelato from ops fail");
            }
        }
        _relay = params_.relay;
    }

    /**
     * @dev See {IGasVendor-getGasFee}.
     */
    function getGasFee(address msgSender_, bytes calldata msgData_) external view returns (GasFee memory fee) {
        if (_isInOps()) {
            return _getOpsGasFee();
        }

        if (_isInRelay(msgSender_)) {
            return _getRelayGasFee(msgData_);
        }
    }

    /**
     * @dev Ops region
     */

    function _isInOps() private view returns (bool) {
        if (!_isOpsSupported()) {
            return false;
        }

        if (!_opsFeePresented()) {
            return false;
        }

        return true;
    }

    function _isOpsSupported() private view returns (bool) {
        return _ops != address(0);
    }

    function _getOpsGasFee() private view returns (GasFee memory fee) {
        (uint256 opsFee, address opsFeeToken) = _getOpsFeeDetails();
        fee.amount = opsFee;
        fee.token = _convertGelatoToken(opsFeeToken);
        fee.collector = _opsGelato;
    }

    function _getOpsFeeDetails() private view returns (uint256 fee, address feeToken) {
        (fee, feeToken) = IGelatoOps(_ops).getFeeDetails();
    }

    function _opsFeePresented() private view returns (bool) {
        (uint256 fee, address feeToken) = _getOpsFeeDetails();
        return feeToken != address(0) && fee > 0;
    }

    /**
     * @dev Relay region
     */

    function _isInRelay(address msgSender_) private view returns (bool) {
        if (!_isRelaySupported()) {
            return false;
        }

        if (msgSender_ != _relay) {
            return false;
        }

        return true;
    }

    function _isRelaySupported() private view returns (bool) {
        return _relay != address(0);
    }

    function _getRelayGasFee(bytes calldata msgData_) private pure returns (GasFee memory fee) {
        fee.amount = _getRelayFee(msgData_);
        fee.token = _convertGelatoToken(_getRelayFeeToken(msgData_));
        fee.collector = _getRelayFeeCollector(msgData_);
    }

    function _getRelayFeeCollector(bytes calldata msgData_) private pure returns (address feeCollector) {
        feeCollector = abi.decode(msgData_[msgData_.length - RELAY_DATA_FEE_COLLECTOR_START:], (address));
    }

    function _getRelayFeeToken(bytes calldata msgData_) private pure returns (address feeToken) {
        feeToken = abi.decode(msgData_[msgData_.length - RELAY_DATA_FEE_TOKEN_START:], (address));
    }

    function _getRelayFee(bytes calldata msgData_) private pure returns (uint256 fee) {
        fee = abi.decode(msgData_[msgData_.length - RELAY_DATA_FEE_START:], (uint256));
    }

    /**
     * @dev Misc region
     */

    function _convertGelatoToken(address gelatoToken_) private pure returns (address) {
        return gelatoToken_ == GELATO_NATIVE_TOKEN ? TokenHelper.NATIVE_TOKEN : gelatoToken_;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {TokenChecker} from "../core/asset/TokenChecker.sol";
import {TokenHelper} from "../core/asset/TokenHelper.sol";
import {NativeClaimer} from "../core/asset/NativeClaimer.sol";
import {NativeReturnMods} from "../core/asset/NativeReturnMods.sol";

import {TokenCheck} from "../core/swap/Swap.sol";

import {IUseProtocol, UseParams} from "../core/use/IUseProtocol.sol";

/**
 * @dev Simple asset transfer protocol:
 *
 * - Transfers specified asset to the account in the current network
 * - Exactly one input & one output with all field content matching
 * - No extra args
 */
contract TransferProtocol is IUseProtocol, NativeReturnMods {
    function use(UseParams calldata params_) external payable {
        require(params_.chain == block.chainid, "TP: wrong chain id");
        require(params_.account != msg.sender, "TP: destination equals source");
        require(params_.args.length == 0, "TP: unexpected args");

        require(params_.ins.length == 1, "TP: wrong number of ins");
        require(params_.inAmounts.length == 1, "TP: wrong number of in amounts");
        require(params_.outs.length == 1, "TP: wrong number of outs");

        TokenCheck calldata input = params_.ins[0];
        uint256 inputAmount = params_.inAmounts[0];
        TokenCheck calldata o = params_.outs[0];

        require(input.token == o.token, "TP: in/out token mismatch");
        require(input.minAmount == o.minAmount, "TP: in/out min amount mismatch");
        require(input.maxAmount == o.maxAmount, "TP: in/out max amount mismatch");

        TokenChecker.checkMinMax(input, inputAmount);

        NativeClaimer.State memory nativeClaimer;
        _resend(input.token, params_.account, inputAmount, nativeClaimer);
    }

    function _resend(
        address token_,
        address account_,
        uint256 amount_,
        NativeClaimer.State memory nativeClaimer_
    ) private returnUnclaimedNative(nativeClaimer_) {
        TokenHelper.transferToThis(token_, msg.sender, amount_, nativeClaimer_);
        TokenHelper.transferFromThis(token_, account_, amount_);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {AccountCounter} from "../core/misc/AccountCounter.sol";

contract AccountCounterTest {
    using AccountCounter for AccountCounter.State;

    function testAccountCounter(
        address[] calldata accounts_,
        uint256 firstIndex_,
        uint256 secondIndex_
    ) external view returns (uint256 gasUsed) {
        require(accounts_.length >= 2, "AT: not enough accounts");

        gasUsed = gasleft();

        AccountCounter.State memory counter = AccountCounter.create(accounts_.length);

        require(counter.get(accounts_[firstIndex_]) == 0, "AT: bad value #00");
        require(counter.get(accounts_[secondIndex_]) == 0, "AT: bad value #01");

        counter.set(accounts_[firstIndex_], 0x42424242);

        require(counter.get(accounts_[firstIndex_]) == 0x42424242, "AT: bad value #10");
        require(counter.get(accounts_[secondIndex_]) == 0, "AT: bad value #11");

        counter.set(accounts_[secondIndex_], 0x336699);

        require(counter.get(accounts_[firstIndex_]) == 0x42424242, "AT: bad value #20");
        require(counter.get(accounts_[secondIndex_]) == 0x336699, "AT: bad value #21");

        require(counter.add(accounts_[firstIndex_], 0x10101010) == 0x52525252, "AT: bad value #30");

        require(counter.get(accounts_[firstIndex_]) == 0x52525252, "AT: bad value #40");
        require(counter.get(accounts_[secondIndex_]) == 0x336699, "AT: bad value #41");

        require(counter.add(accounts_[secondIndex_], 0x777777) == 0xaade10, "AT: bad value #50");

        require(counter.get(accounts_[firstIndex_]) == 0x52525252, "AT: bad value #60");
        require(counter.get(accounts_[secondIndex_]) == 0xaade10, "AT: bad value #61");

        counter.set(accounts_[secondIndex_], 0);

        require(counter.get(accounts_[firstIndex_]) == 0x52525252, "AT: bad value #70");
        require(counter.get(accounts_[secondIndex_]) == 0, "AT: bad value #71");

        counter.set(accounts_[firstIndex_], 0);

        require(counter.get(accounts_[firstIndex_]) == 0, "AT: bad value #80");
        require(counter.get(accounts_[secondIndex_]) == 0, "AT: bad value #81");

        gasUsed -= gasleft();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

contract BytesConcatTest {
    bytes32 public lastDefaultConcatHash;
    bytes32 public lastPreAllocConcatHash;

    function concatHashesDefault(uint256 total_) public {
        lastDefaultConcatHash = _concatHashesDefault(total_);
    }

    function concatHashesPreAlloc(uint256 total_) public {
        lastPreAllocConcatHash = _concatHashesPreAlloc(total_);
    }

    function _concatHashesDefault(uint256 total_) public pure returns (bytes32 totalHash) {
        bytes memory bytesToHash = new bytes(0);
        for (uint256 i = 0; i < total_; i++) {
            bytesToHash = bytes.concat(bytesToHash, _dataSource(i));
        }
        totalHash = keccak256(bytesToHash);
    }

    function _concatHashesPreAlloc(uint256 total_) public pure returns (bytes32 totalHash) {
        bytes memory bytesToHash = new bytes(total_ << 5); // * 0x20
        uint256 offset;
        assembly {
            offset := add(bytesToHash, 0x20)
        }
        for (uint256 i = 0; i < total_; i++) {
            bytes32 data = _dataSource(i);
            assembly {
                mstore(offset, data)
                offset := add(offset, 0x20)
            }
        }
        totalHash = keccak256(bytesToHash);
    }

    function _dataSource(uint256 index_) private pure returns (bytes32 data) {
        data = keccak256(abi.encode(index_));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Delegate} from "../core/delegate/Delegate.sol";
import {DelegateDeployer} from "../core/delegate/DelegateDeployer.sol";

contract DelegateDeployerTest {
    address private immutable _delegatePrototype;
    address private immutable _delegateDeployer;

    constructor() {
        _delegatePrototype = address(new Delegate());
        _delegateDeployer = address(new DelegateDeployer(_delegatePrototype));
    }

    function delegatePrototype() public view returns (address) {
        return _delegatePrototype;
    }

    function delegateDeployer() public view returns (address) {
        return _delegateDeployer;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Delegate} from "../core/delegate/Delegate.sol";
import {DelegateManager, DelegateManagerConstructorParams} from "../core/delegate/DelegateManager.sol";

import {OwnableAccountWhitelist} from "../core/whitelist/OwnableAccountWhitelist.sol";
import {IAccountWhitelist} from "../core/whitelist/IAccountWhitelist.sol";

contract DelegateManagerTest {
    address private immutable _delegatePrototype;
    address private immutable _withdrawWhitelist;
    address private immutable _delegateManager;

    constructor() {
        _delegatePrototype = address(new Delegate());
        _withdrawWhitelist = address(new OwnableAccountWhitelist());
        _delegateManager = address(
            new DelegateManager(
                DelegateManagerConstructorParams({
                    delegatePrototype: _delegatePrototype,
                    withdrawWhitelist: _withdrawWhitelist
                })
            )
        );
    }

    function delegatePrototype() public view returns (address) {
        return _delegatePrototype;
    }

    function withdrawWhitelist() public view returns (address) {
        return _withdrawWhitelist;
    }

    function addToWithdrawWhitelist(address account_) public {
        IAccountWhitelist(_withdrawWhitelist).addAccountToWhitelist(account_);
    }

    function delegateManager() public view returns (address) {
        return _delegateManager;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {TokenHelper} from "../../core/asset/TokenHelper.sol";
import {NativeReceiver} from "../../core/asset/NativeReceiver.sol";
import {NativeReturnMods} from "../../core/asset/NativeReturnMods.sol";
import {NativeClaimer} from "../../core/asset/NativeClaimer.sol";

import {ITokenMock} from "./ITokenMock.sol";

struct CallMockIO {
    address token;
    uint256 amount;
}

struct CallMockLie {
    uint256 outputIndex;
    uint256 amount;
}

contract CallMock is NativeReceiver, NativeReturnMods {
    uint256 public constant AMOUNT = 1000 ether;

    function mint(address[] calldata tokens_) external payable {
        require(msg.value == AMOUNT, "CM: insufficient msg value");
        for (uint256 i = 0; i < tokens_.length; i++) {
            ITokenMock(tokens_[i]).mint(address(this), AMOUNT);
        }
    }

    function call(
        CallMockIO[] calldata inputs_,
        CallMockIO[] calldata outputs_,
        CallMockLie[] calldata lies_
    ) external payable returns (uint256[] memory outAmounts) {
        NativeClaimer.State memory nativeClaimer;
        return _call(inputs_, outputs_, lies_, nativeClaimer);
    }

    function _call(
        CallMockIO[] calldata inputs_,
        CallMockIO[] calldata outputs_,
        CallMockLie[] calldata lies_,
        NativeClaimer.State memory nativeClaimer_
    ) private returnUnclaimedNative(nativeClaimer_) returns (uint256[] memory outAmounts) {
        // Consume inputs
        for (uint256 i = 0; i < inputs_.length; i++) {
            TokenHelper.transferToThis(inputs_[i].token, msg.sender, inputs_[i].amount, nativeClaimer_);
        }

        // Produce outputs
        outAmounts = new uint256[](outputs_.length);
        for (uint256 i = 0; i < outputs_.length; i++) {
            TokenHelper.transferFromThis(outputs_[i].token, msg.sender, outputs_[i].amount);
            outAmounts[i] = outputs_[i].amount;
        }

        // Lie about output amounts
        for (uint256 i = 0; i < lies_.length; i++) {
            outAmounts[lies_[i].outputIndex] += lies_[i].amount;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {ITokenMock} from "./ITokenMock.sol";

interface IDai is ITokenMock {
    function name() external view returns (string memory);

    function rely(address guy) external;

    function deny(address guy) external;
}

contract DaiTokenMock {
    /**
     * Dai creation code for Ethereum mainnet (constructor 'chainId_' is 1) copied from the Etherscan explorer
     * (https://etherscan.io/token/0x6b175474e89094c44da98b954eedeac495271d0f#code).
     */
    bytes public constant DAI_CREATION_CODE =
        hex"608060405234801561001057600080fd5b506040516120d33803806120d38339818101604052602081101561003357600080fd5b810190808051906020019092919050505060016000803373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002081905550604051808061208160529139605201905060405180910390206040518060400160405280600e81526020017f44616920537461626c65636f696e000000000000000000000000000000000000815250805190602001206040518060400160405280600181526020017f3100000000000000000000000000000000000000000000000000000000000000815250805190602001208330604051602001808681526020018581526020018481526020018381526020018273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001955050505050506040516020818303038152906040528051906020012060058190555050611ee0806101a16000396000f3fe608060405234801561001057600080fd5b50600436106101425760003560e01c80637ecebe00116100b8578063a9059cbb1161007c578063a9059cbb146106b4578063b753a98c1461071a578063bb35783b14610768578063bf353dbb146107d6578063dd62ed3e1461082e578063f2d5d56b146108a657610142565b80637ecebe00146104a15780638fcbaf0c146104f957806395d89b411461059f5780639c52a7f1146106225780639dc29fac1461066657610142565b8063313ce5671161010a578063313ce567146102f25780633644e5151461031657806340c10f191461033457806354fd4d501461038257806365fae35e1461040557806370a082311461044957610142565b806306fdde0314610147578063095ea7b3146101ca57806318160ddd1461023057806323b872dd1461024e57806330adf81f146102d4575b600080fd5b61014f6108f4565b6040518080602001828103825283818151815260200191508051906020019080838360005b8381101561018f578082015181840152602081019050610174565b50505050905090810190601f1680156101bc5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b610216600480360360408110156101e057600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019092919050505061092d565b604051808215151515815260200191505060405180910390f35b610238610a1f565b6040518082815260200191505060405180910390f35b6102ba6004803603606081101561026457600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190505050610a25565b604051808215151515815260200191505060405180910390f35b6102dc610f3a565b6040518082815260200191505060405180910390f35b6102fa610f61565b604051808260ff1660ff16815260200191505060405180910390f35b61031e610f66565b6040518082815260200191505060405180910390f35b6103806004803603604081101561034a57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190505050610f6c565b005b61038a611128565b6040518080602001828103825283818151815260200191508051906020019080838360005b838110156103ca5780820151818401526020810190506103af565b50505050905090810190601f1680156103f75780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6104476004803603602081101561041b57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050611161565b005b61048b6004803603602081101561045f57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919050505061128f565b6040518082815260200191505060405180910390f35b6104e3600480360360208110156104b757600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291905050506112a7565b6040518082815260200191505060405180910390f35b61059d600480360361010081101561051057600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019092919080359060200190929190803515159060200190929190803560ff16906020019092919080359060200190929190803590602001909291905050506112bf565b005b6105a76117fa565b6040518080602001828103825283818151815260200191508051906020019080838360005b838110156105e75780820151818401526020810190506105cc565b50505050905090810190601f1680156106145780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6106646004803603602081101561063857600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050611833565b005b6106b26004803603604081101561067c57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190505050611961565b005b610700600480360360408110156106ca57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190505050611df4565b604051808215151515815260200191505060405180910390f35b6107666004803603604081101561073057600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190505050611e09565b005b6107d46004803603606081101561077e57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190505050611e19565b005b610818600480360360208110156107ec57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050611e2a565b6040518082815260200191505060405180910390f35b6108906004803603604081101561084457600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050611e42565b6040518082815260200191505060405180910390f35b6108f2600480360360408110156108bc57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190505050611e67565b005b6040518060400160405280600e81526020017f44616920537461626c65636f696e00000000000000000000000000000000000081525081565b600081600360003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508273ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925846040518082815260200191505060405180910390a36001905092915050565b60015481565b600081600260008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020541015610adc576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260188152602001807f4461692f696e73756666696369656e742d62616c616e6365000000000000000081525060200191505060405180910390fd5b3373ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff1614158015610bb457507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff600360008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205414155b15610db25781600360008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020541015610cab576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252601a8152602001807f4461692f696e73756666696369656e742d616c6c6f77616e636500000000000081525060200191505060405180910390fd5b610d31600360008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205483611e77565b600360008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055505b610dfb600260008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205483611e77565b600260008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002081905550610e87600260008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205483611e91565b600260008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508273ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef846040518082815260200191505060405180910390a3600190509392505050565b7fea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb60001b81565b601281565b60055481565b60016000803373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205414611020576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260128152602001807f4461692f6e6f742d617574686f72697a6564000000000000000000000000000081525060200191505060405180910390fd5b611069600260008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205482611e91565b600260008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055506110b860015482611e91565b6001819055508173ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef836040518082815260200191505060405180910390a35050565b6040518060400160405280600181526020017f310000000000000000000000000000000000000000000000000000000000000081525081565b60016000803373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205414611215576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260128152602001807f4461692f6e6f742d617574686f72697a6564000000000000000000000000000081525060200191505060405180910390fd5b60016000808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055505961012081016040526020815260e0602082015260e0600060408301376024356004353360003560e01c60e01b61012085a45050565b60026020528060005260406000206000915090505481565b60046020528060005260406000206000915090505481565b60006005547fea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb60001b8a8a8a8a8a604051602001808781526020018673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018481526020018381526020018215151515815260200196505050505050506040516020818303038152906040528051906020012060405160200180807f190100000000000000000000000000000000000000000000000000000000000081525060020183815260200182815260200192505050604051602081830303815290604052805190602001209050600073ffffffffffffffffffffffffffffffffffffffff168973ffffffffffffffffffffffffffffffffffffffff16141561148c576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260158152602001807f4461692f696e76616c69642d616464726573732d30000000000000000000000081525060200191505060405180910390fd5b60018185858560405160008152602001604052604051808581526020018460ff1660ff1681526020018381526020018281526020019450505050506020604051602081039080840390855afa1580156114e9573d6000803e3d6000fd5b5050506020604051035173ffffffffffffffffffffffffffffffffffffffff168973ffffffffffffffffffffffffffffffffffffffff1614611593576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260128152602001807f4461692f696e76616c69642d7065726d6974000000000000000000000000000081525060200191505060405180910390fd5b60008614806115a25750854211155b611614576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260128152602001807f4461692f7065726d69742d65787069726564000000000000000000000000000081525060200191505060405180910390fd5b600460008a73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008154809291906001019190505587146116d6576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260118152602001807f4461692f696e76616c69642d6e6f6e636500000000000000000000000000000081525060200191505060405180910390fd5b6000856116e4576000611706565b7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5b905080600360008c73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508873ffffffffffffffffffffffffffffffffffffffff168a73ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925836040518082815260200191505060405180910390a350505050505050505050565b6040518060400160405280600381526020017f444149000000000000000000000000000000000000000000000000000000000081525081565b60016000803373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054146118e7576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260128152602001807f4461692f6e6f742d617574686f72697a6564000000000000000000000000000081525060200191505060405180910390fd5b60008060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055505961012081016040526020815260e0602082015260e0600060408301376024356004353360003560e01c60e01b61012085a45050565b80600260008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020541015611a16576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260188152602001807f4461692f696e73756666696369656e742d62616c616e6365000000000000000081525060200191505060405180910390fd5b3373ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff1614158015611aee57507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205414155b15611cec5780600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020541015611be5576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252601a8152602001807f4461692f696e73756666696369656e742d616c6c6f77616e636500000000000081525060200191505060405180910390fd5b611c6b600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205482611e77565b600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055505b611d35600260008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205482611e77565b600260008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002081905550611d8460015482611e77565b600181905550600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef836040518082815260200191505060405180910390a35050565b6000611e01338484610a25565b905092915050565b611e14338383610a25565b505050565b611e24838383610a25565b50505050565b60006020528060005260406000206000915090505481565b6003602052816000526040600020602052806000526040600020600091509150505481565b611e72823383610a25565b505050565b6000828284039150811115611e8b57600080fd5b92915050565b6000828284019150811015611ea557600080fd5b9291505056fea265627a7a72315820c0ae2c29860c0a59d5586a579abbcddfe4bcef0524a87301425cbc58c3e94e3164736f6c634300050c0032454950373132446f6d61696e28737472696e67206e616d652c737472696e672076657273696f6e2c75696e7432353620636861696e49642c6164647265737320766572696679696e67436f6e7472616374290000000000000000000000000000000000000000000000000000000000000001";
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {IGasVendor, GasFee} from "../../protocols/gas/IGasVendor.sol";

contract GasVendorMock is IGasVendor {
    bool private _gasFeeSet;
    GasFee private _gasFee;

    function setGasFee(GasFee memory gasFee_) external {
        _gasFee = gasFee_;
        _gasFeeSet = true;
    }

    function getGasFee(address msgSender_, bytes calldata msgData_) external view returns (GasFee memory) {
        require(msgSender_ != address(0), "GM: zero msg sender");
        require(msgData_.length != 0, "GM: empty msg data");
        require(_gasFeeSet, "GM: gas fee mock not set");

        return _gasFee;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {IERC20} from "../../lib/IERC20.sol";

interface ITokenMock is IERC20 {
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {ERC20} from "../../lib/ERC20.sol";
import {ERC20Permit} from "../../lib/draft-ERC20Permit.sol";

import {ITokenMock} from "./ITokenMock.sol";

contract PermitTokenMock is ERC20Permit, ITokenMock {
    // prettier-ignore
    constructor()
        ERC20("Test Token", "ttkn")
        ERC20Permit("Test Token Domain")
    {} // solhint-disable-line no-empty-blocks

    function mint(address account_, uint256 amount_) external {
        _mint(account_, amount_);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {ISwapper, SwapParams, StealthSwapParams} from "../../core/swap/ISwapper.sol";

contract SwapperMock is ISwapper {
    function swap(SwapParams calldata params_) public payable {} // solhint-disable-line no-empty-blocks

    function swapStealth(StealthSwapParams calldata params_) external payable {} // solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {StorageSlot} from "../lib/StorageSlot.sol";

contract NonceTypeTest {
    // bytes32 constant private _NONCES_SLOT = bytes32(uint256(keccak256("xSwap.v2.NonceTypeTest._noncesHashSlot")) - 1);
    bytes32 private constant _NONCES_SLOT = 0x7ea51bbc48d474ed9a0f173f1831f699562b5d553eaca7361d107841c9bf37f6;

    mapping(address => mapping(uint256 => bool)) private _noncesDoubleMap;
    mapping(bytes32 => bool) private _noncesSingleHashMap;

    function useDoubleMapNonces(uint256[] calldata nonces_) public {
        for (uint256 i = 0; i < nonces_.length; i++) {
            useDoubleMapNonce(nonces_[i]);
        }
    }

    function useDoubleMapNonce(uint256 nonce_) private {
        require(!_noncesDoubleMap[msg.sender][nonce_], "NT: nonce already used");
        _noncesDoubleMap[msg.sender][nonce_] = true;
    }

    function useSingleHashNonces(uint256[] calldata nonces_) public {
        for (uint256 i = 0; i < nonces_.length; i++) {
            useSingleHashNonce(nonces_[i]);
        }
    }

    function useSingleHashNonce(uint256 nonce_) private {
        bytes32 key = keccak256(abi.encodePacked(nonce_, msg.sender));
        require(!_noncesSingleHashMap[key], "NT: nonce already used");
        _noncesSingleHashMap[key] = true;
    }

    function useSlotHashNonces(uint256[] calldata nonces_) public {
        for (uint256 i = 0; i < nonces_.length; i++) {
            useSlotHashNonce(nonces_[i]);
        }
    }

    function useSlotHashNonce(uint256 nonce_) private {
        bytes32 slot = _NONCES_SLOT ^ keccak256(abi.encode(nonce_, msg.sender));
        StorageSlot.BooleanSlot storage nonceSlot = StorageSlot.getBooleanSlot(slot);
        require(!nonceSlot.value, "NT: nonce already used");
        nonceSlot.value = true;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {IPermitResolver} from "../core/permit/IPermitResolver.sol";

contract PermitResolverTest {
    function resolvePermit(
        address resolver_,
        address token_,
        address from_,
        uint256 amount_,
        uint256 deadline_,
        bytes calldata signature_
    ) public {
        IPermitResolver(resolver_).resolvePermit(token_, from_, amount_, deadline_, signature_);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Clones} from "../lib/Clones.sol";

contract Shared {
    mapping(address => uint256) private _counts;

    function getCount() public view returns (uint256) {
        return _counts[msg.sender];
    }

    function setCount(uint256 count_) public {
        _counts[msg.sender] = count_;
    }
}

contract Specific {
    address private immutable _shared;

    constructor(address shared_) {
        _shared = shared_;
    }

    function shared() public view returns (address) {
        return _shared;
    }

    function getCount() public view returns (uint256) {
        return Shared(_shared).getCount();
    }

    function setCount(uint256 count_) public {
        Shared(_shared).setCount(count_);
    }
}

contract SpecificCloner {
    address private immutable _specificTemplate;

    constructor(address specificTemplate_) {
        _specificTemplate = specificTemplate_;
    }

    function predict(bytes32 salt_) public view returns (address) {
        return Clones.predictDeterministicAddress(_specificTemplate, salt_);
    }

    function clone(bytes32 salt_) public returns (address) {
        return Clones.cloneDeterministic(_specificTemplate, salt_);
    }
}

contract SharedCloneTest {
    address private immutable _shared;
    address private immutable _factory;

    constructor() {
        _shared = address(new Shared());
        address specificTemplate = address(new Specific(_shared));
        _factory = address(new SpecificCloner(specificTemplate));
    }

    function shared() public view returns (address) {
        return _shared;
    }

    function factory() public view returns (address) {
        return _factory;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Initializable} from "./core/init/Initializable.sol";

import {Swapper, SwapperConstructorParams} from "./core/swap/Swapper.sol";

import {WhitelistWithdrawable} from "./core/withdraw/WhitelistWithdrawable.sol";

import {XSwapStorage} from "./XSwapStorage.sol";

struct XSwapConstructorParams {
    /**
     * @dev {ISwapSignatureValidator}-compatible contract address
     */
    address swapSignatureValidator;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address permitResolverWhitelist;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address useProtocolWhitelist;
    /**
     * @dev {IDelegateManager}-compatible contract address
     */
    address delegateManager;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address withdrawWhitelist;
    /**
     * @dev {ILifeControl}-compatible contract address
     */
    address lifeControl;
}

contract XSwap is Initializable, Swapper, WhitelistWithdrawable, XSwapStorage {
    // prettier-ignore
    constructor(XSwapConstructorParams memory params_)
        Initializable(INITIALIZER_SLOT)
        WhitelistWithdrawable(WITHDRAW_WHITELIST_SLOT, _whitelistWithdrawableParams(params_))
        Swapper(_swapperParams(params_))
    {
        _initialize(params_, false);
    }

    function initialize(XSwapConstructorParams memory params_) external {
        _initialize(params_, true);
    }

    function _initialize(XSwapConstructorParams memory params_, bool initBase_) private init {
        if (initBase_) {
            initializeSwapper(_swapperParams(params_));
            initializeWhitelistWithdrawable(_whitelistWithdrawableParams(params_));
        }

        require(params_.lifeControl != address(0), "XS: zero life control");
        _setLifeControl(params_.lifeControl);
    }

    function _swapperParams(
        XSwapConstructorParams memory params_
    ) private pure returns (SwapperConstructorParams memory) {
        // prettier-ignore
        return SwapperConstructorParams({
            swapSignatureValidator: params_.swapSignatureValidator,
            permitResolverWhitelist: params_.permitResolverWhitelist,
            useProtocolWhitelist: params_.useProtocolWhitelist,
            delegateManager: params_.delegateManager
        });
    }

    function _whitelistWithdrawableParams(XSwapConstructorParams memory params_) private pure returns (address) {
        return params_.withdrawWhitelist;
    }

    function _checkSwapEnabled() internal view override {
        require(!_lifeControl().paused(), "XS: swapping paused");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {StorageSlot} from "./lib/StorageSlot.sol";

import {ILifeControl} from "./core/life/ILifeControl.sol";

abstract contract XSwapStorage {
    // bytes32 internal constant INITIALIZER_SLOT = bytes32(uint256(keccak256("xSwap.v2.XSwap._initializer")) - 1);
    bytes32 internal constant INITIALIZER_SLOT = 0x3623293b0ffb92d90ed57651d3642673495a0188d7e022c09c543c9969626c44;

    // prettier-ignore
    // bytes32 internal constant WITHDRAW_WHITELIST_SLOT = bytes32(uint256(keccak256("xSwap.v2.XSwap._withdrawWhitelist")) - 1);
    bytes32 internal constant WITHDRAW_WHITELIST_SLOT = 0x4bd3e4129f347789784c66e779a32160b856695506e147fcaa130ce576c4cb1b;

    // bytes32 internal constant _LIFE_CONTROL_SLOT = bytes32(uint256(keccak256("xSwap.v2.XSwap._lifeControl")) - 1);
    bytes32 private constant _LIFE_CONTROL_SLOT = 0x871cbad836638a5df48f5f4cd4da62b7497b7b8a763c0aa30ded7ca399e95121;

    function _lifeControlStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_LIFE_CONTROL_SLOT);
    }

    function _lifeControl() internal view returns (ILifeControl) {
        return ILifeControl(_lifeControlStorage().value);
    }

    function _setLifeControl(address lifeControl_) internal {
        _lifeControlStorage().value = lifeControl_;
    }
}
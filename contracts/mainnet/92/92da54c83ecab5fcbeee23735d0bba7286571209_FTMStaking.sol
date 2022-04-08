/**
 *Submitted for verification at FtmScan.com on 2022-04-08
*/

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts/interfaces/IValidatorPicker.sol


pragma solidity ^0.8.7;

interface IValidatorPicker {
    function getNextValidatorInfo(uint256 amount)
        external
        returns (uint256 toValidatorID, uint256 lockupDuration);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: contracts/interfaces/IERC20Burnable.sol


pragma solidity ^0.8.7;


interface IERC20Burnable is IERC20 {
    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// File: contracts/interfaces/ISFC.sol


pragma solidity ^0.8.7;

interface ISFC {
    function currentEpoch() external view returns (uint256);

    function currentSealedEpoch() external view returns (uint256);

    function getValidator(uint256 toValidatorID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address
        );

    function getEpochSnapshot(uint256 epoch)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getLockupInfo(address delegator, uint256 toValidatorID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getWithdrawalRequest(
        address delegator,
        uint256 toValidatorID,
        uint256 wrID
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getStake(address delegator, uint256 toValidatorID)
        external
        view
        returns (uint256);

    function getStashedLockupRewards(address delegator, uint256 toValidatorID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getLockedStake(address delegator, uint256 toValidatorID)
        external
        view
        returns (uint256);

    function pendingRewards(address delegator, uint256 toValidatorID)
        external
        view
        returns (uint256);

    function isSlashed(uint256 toValidatorID) external view returns (bool);

    function slashingRefundRatio(uint256 toValidatorID)
        external
        view
        returns (uint256);

    function getEpochAccumulatedRewardPerToken(
        uint256 epoch,
        uint256 validatorID
    ) external view returns (uint256);

    function stashedRewardsUntilEpoch(address delegator, uint256 toValidatorID)
        external
        view
        returns (uint256);

    function isLockedUp(address delegator, uint256 toValidatorID)
        external
        view
        returns (bool);

    function delegate(uint256 toValidatorID) external payable;

    function lockStake(
        uint256 toValidatorID,
        uint256 lockupDuration,
        uint256 amount
    ) external;

    function claimRewards(uint256 toValidatorID) external;

    function undelegate(
        uint256 toValidatorID,
        uint256 wrID,
        uint256 amount
    ) external;

    function unlockStake(uint256 toValidatorID, uint256 amount)
        external
        returns (uint256);

    function withdraw(uint256 toValidatorID, uint256 wrID) external;
}

// File: contracts/Vault.sol


pragma solidity ^0.8.7;


/**
 * @title Vault Contract
 * @author Stader Labs
 * @notice Vault contract is created by the Main Staking contract everytime FTM is delegated to a validator
 */
contract Vault {
    uint256 public constant DECIMAL_UNIT = 1e18;
    ISFC public immutable SFC;
    address public owner;
    address public immutable toValidator;
    uint256 public immutable toValidatorID;

    /**
     * @notice Constructor
     * @param _sfc the address of the SFC contract
     * @param _toValidatorID the ID of the validator, as stored in the SFC contract
     */
    constructor(ISFC _sfc, uint256 _toValidatorID) {
        owner = msg.sender;
        SFC = _sfc;
        toValidatorID = _toValidatorID;

        (, , , , , , address auth) = _sfc.getValidator(_toValidatorID);

        toValidator = auth;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ERR_UNAUTHORIZED");
        _;
    }

    /**
     * @notice Returns the current value of the staked FTM, including rewards and slashing (if any)
     */
    function currentStakeValue() external view returns (uint256) {
        uint256 stake = SFC.getStake(address(this), toValidatorID);
        uint256 rewards = SFC.pendingRewards(address(this), toValidatorID);
        (, , uint256 matured) = SFC.getWithdrawalRequest(
            address(this),
            toValidatorID,
            0
        );
        uint256 penalty;
        bool isSlashed = SFC.isSlashed(toValidatorID);
        if (isSlashed) {
            penalty = _getSlashingPenalty(stake + matured);
        }
        return stake + rewards + matured - penalty;
    }

    /**
     * @notice Returns the amount of FTM locked via this vault
     */
    function getLockedStake() external view returns (uint256) {
        return SFC.getLockedStake(address(this), toValidatorID);
    }

    /**
     * @notice Delegate FTM to the validator
     */
    function delegate() external payable onlyOwner {
        SFC.delegate{value: msg.value}(toValidatorID);
    }

    /**
     * @notice Lock the delegated stake
     * @param lockupDuration the duration for which to lock the stake
     * @param amount the amount of stake to lock
     */
    function lockStake(uint256 lockupDuration, uint256 amount)
        external
        onlyOwner
    {
        SFC.lockStake(toValidatorID, lockupDuration, amount);
    }

    /**
     * @notice Claim all rewards accrued so far
     */
    function claimRewards() external onlyOwner {
        SFC.claimRewards(toValidatorID);
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @notice Unlock the locked stake
     * @param amount the amount of stake to unlock
     *
     * Assumption:
     *  - is locked up
     */
    function unlock(uint256 amount) external onlyOwner {
        SFC.unlockStake(toValidatorID, amount);
    }

    /**
     * @notice Undelegate the unlocked stake
     * @param wrID a unique withdrawal ID
     * @param amount the amount of stake to undelegate
     *
     * Assumption:
     *  - amount <= unlocked balance
     */
    function undelegate(uint256 wrID, uint256 amount) external onlyOwner {
        SFC.undelegate(toValidatorID, wrID, amount);
    }

    /**
     * @notice Withdraw the undelegated stake
     * @param wrID the withdrawal ID for the withdrawal request
     * @param sendAll bool to determine whether to send entire contract balance to owner
     *
     * Assumption:
     *  -  enough time has passed after the undelegation
     *  -  stake is NOT slashed
     */
    function withdraw(uint256 wrID, bool sendAll) external onlyOwner {
        uint256 initialBal = address(this).balance;
        SFC.withdraw(toValidatorID, wrID);
        uint256 toSend = address(this).balance;
        if (!sendAll) {
            toSend -= initialBal;
        }
        payable(owner).transfer(toSend);
    }

    /**
     * @notice Update the owner of the vault
     * @param newOwner the new owner of the vault
     */
    function updateOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function _getSlashingPenalty(uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint256 refundRatio = SFC.slashingRefundRatio(toValidatorID);
        if (refundRatio >= DECIMAL_UNIT) {
            return 0;
        }
        // round penalty upwards (ceiling) to prevent dust amount attacks
        uint256 penalty = ((amount * (DECIMAL_UNIT - refundRatio)) /
            DECIMAL_UNIT) + 1;
        if (penalty > amount) {
            return amount;
        }
        return penalty;
    }

    /**
     * @notice To receive Eth from SFC
     */
    receive() external payable {}
}

// File: contracts/FTMStaking.sol


pragma solidity ^0.8.7;







// TODO : add proxy pattern

/**
 * @title FTM Staking Contract
 * @author Stader Labs
 * @notice Main point of interaction with Stader protocol's v1 liquid staking
 */
contract FTMStaking is Ownable, Pausable {
    // These constants have been taken from the SFC contract
    uint256 public constant DECIMAL_UNIT = 1e18;
    uint256 public constant UNLOCKED_REWARD_RATIO = (30 * DECIMAL_UNIT) / 100;
    uint256 public constant MAX_LOCKUP_DURATION = 86400 * 365;

    struct WithdrawalRequest {
        address payable[] vaultsToUndelegate;
        uint256[] amountsToUndelegate;
        uint256 requestTime;
        uint256 poolAmount;
        uint256 undelegateAmount;
        uint256 penalty;
        address user;
        bool isWithdrawn;
    }

    struct Rewards {
        uint256 lockupExtraReward;
        uint256 lockupBaseReward;
        uint256 unlockedReward;
    }

    /**
     * @dev An immutable reference to the FTMX ERC20 token contract
     */
    IERC20Burnable public immutable FTMX;

    /**
     * @dev An immutable reference to the SFC contract
     */
    ISFC public immutable SFC;

    IValidatorPicker public validatorPicker;
    uint256 public lastKnownEpoch;

    uint256 private immutable _maxVaultCount;

    // These params are modifiable by the admin
    uint256 private _epochDuration;
    uint256 private _withdrawalDelay;

    // These params are maintained automatically
    uint256 private _currentVaultPtr;
    uint256 private _currentVaultCount;
    uint256 private _nextEligibleTimestamp;
    uint256 private _ftmPendingWithdrawal;

    mapping(uint256 => address payable) private _allVaults;

    address payable[] private _maturedVaults;

    mapping(uint256 => WithdrawalRequest) public allWithdrawalRequests;

    event LogValidatorPickerSet(address indexed owner, address validatorPicker);
    event LogEpochDurationSet(address indexed owner, uint256 duration);
    event LogWithdrawalDelaySet(address indexed owner, uint256 delay);
    event LogVaultOwnerUpdated(
        address indexed owner,
        address vault,
        address newOwner
    );
    event LogDeposited(
        address indexed user,
        uint256 amount,
        uint256 ftmxAmount
    );
    event LogUndelegated(
        address indexed user,
        uint256 wrID,
        uint256 amountFTMx
    );
    event LogWithdrawn(address indexed user, uint256 wrID, uint256 totalAmount);
    event LogLocked(
        address indexed vault,
        uint256 lockupDuration,
        uint256 amount
    );
    event LogVaultHarvested(address indexed vault, uint256 maturedIndex);
    event LogVaultWithdrawn(address indexed vault);

    /**
     * @notice Constructor
     * @param _ftmx_ the address of the FTM token contract (is NOT modifiable)
     * @param _sfc_ the address of the SFC contract (is NOT modifiable)
     * @param _maxVaultCount_ the maximum number of vaults to be created (is NOT modifiable)
     * @param _epochDuration_ the duration of a locking epoch (is modifiable)
     * @param _withdrawalDelay_ the delay between undelegation & withdrawal (is modifiable)
     */
    constructor(
        IERC20Burnable _ftmx_,
        ISFC _sfc_,
        uint256 _maxVaultCount_,
        uint256 _epochDuration_,
        uint256 _withdrawalDelay_
    ) {
        FTMX = _ftmx_;
        SFC = _sfc_;

        _maxVaultCount = _maxVaultCount_;
        _epochDuration = _epochDuration_;
        _withdrawalDelay = _withdrawalDelay_;
    }

    /*******************************
     * Getter & helper functions   *
     *******************************/

    /**
     * @notice Returns the vault address at the requested index
     * @param vaultIndex the index to query
     */
    function getVault(uint256 vaultIndex) external view returns (address) {
        return _allVaults[vaultIndex];
    }

    /**
     * @notice Returns the length of matured vaults pending withdrawal
     */
    function getMaturedVaultLength() external view returns (uint256) {
        return _maturedVaults.length;
    }

    /**
     * @notice Returns the matured vault address at the requested index
     * @param vaultIndex the index to query
     */
    function getMaturedVault(uint256 vaultIndex)
        external
        view
        returns (address payable)
    {
        return _maturedVaults[vaultIndex];
    }

    /**
     * @notice Returns the list of vaults associated with the given withdrawal ID
     * @param wrID the withdrawal ID to query
     */
    function getWithdrawalVaults(uint256 wrID)
        external
        view
        returns (address payable[] memory)
    {
        return allWithdrawalRequests[wrID].vaultsToUndelegate;
    }

    /**
     * @notice Returns the list of amounts associated with the given withdrawal ID
     * @param wrID the withdrawal ID to query
     */
    function getWithdrawalAmounts(uint256 wrID)
        external
        view
        returns (uint256[] memory)
    {
        return allWithdrawalRequests[wrID].amountsToUndelegate;
    }

    /**
     * @notice Returns the currently pending FTM withdrawal amount
     */
    function ftmPendingWithdrawal() public view returns (uint256) {
        return _ftmPendingWithdrawal;
    }

    /**
     * @notice Returns the currently available FTM balance to delegate
     */
    function getPoolBalance() public view returns (uint256) {
        return address(this).balance - ftmPendingWithdrawal();
    }

    /**
     * @notice Returns the current FTM worth of the protocol
     *
     * Considers:
     *  - current stake value for all vaults (including bonded slashing)
     *  - contract's poolBalance
     */
    function totalFTMWorth() public view returns (uint256) {
        uint256 total = getPoolBalance();
        uint256 vaultCount = maxVaultCount();
        for (uint256 i = 0; i < vaultCount; i = _uncheckedInc(i)) {
            address payable vault = _allVaults[i];
            if (vault != address(0)) {
                total += Vault(vault).currentStakeValue();
            }
        }

        uint256 maturedCount = _maturedVaults.length;
        for (uint256 i = 0; i < maturedCount; i = _uncheckedInc(i)) {
            address payable vault = _maturedVaults[i];
            total += Vault(vault).currentStakeValue();
        }

        return total;
    }

    /**
     * @notice Returns the count of vaults in existence
     */
    function currentVaultCount() public view returns (uint256) {
        return _currentVaultCount;
    }

    /**
     * @notice Returns the amount of FTM equivalent 1 FTMX (with 18 decimals)
     */
    function getExchangeRate() public view returns (uint256) {
        uint256 totalFTM = totalFTMWorth();
        uint256 totalFTMx = FTMX.totalSupply();

        if (totalFTM == 0 || totalFTMx == 0) {
            return 1 * DECIMAL_UNIT;
        }
        return (totalFTM * DECIMAL_UNIT) / totalFTMx;
    }

    /**
     * @notice Returns the amount of FTMX equivalent to the provided FTM
     * @param ftmAmount the amount of FTM
     * @param toIgnore flag to ignore input ftmAmount from calculations (must be true for deposits)
     */
    function getFTMxAmountForFTM(uint256 ftmAmount, bool toIgnore)
        public
        view
        returns (uint256)
    {
        uint256 totalFTM = totalFTMWorth();
        uint256 totalFTMx = FTMX.totalSupply();

        if (toIgnore) {
            totalFTM -= ftmAmount;
        }

        if (totalFTM == 0 || totalFTMx == 0) {
            return ftmAmount;
        }
        return (ftmAmount * totalFTMx) / totalFTM;
    }

    /**
     * @notice Returns the next timestamp eligible for locking
     */
    function nextEligibleTimestamp() public view returns (uint256) {
        return _nextEligibleTimestamp;
    }

    /**
     * @notice Returns the duration of an epoch between two successive locks
     */
    function epochDuration() public view returns (uint256) {
        return _epochDuration;
    }

    /**
     * @notice Returns the delay between undelegation & withdrawal
     */
    function withdrawalDelay() public view returns (uint256) {
        return _withdrawalDelay;
    }

    /**
     * @notice Returns the maximum number of vaults that can be created
     */
    function maxVaultCount() public view returns (uint256) {
        return _maxVaultCount;
    }

    /**
     * @notice Returns the index of the next vault to be created
     */
    function currentVaultPtr() public view returns (uint256) {
        return _currentVaultPtr;
    }

    /**
     * @notice Returns the penalty to be charged on undelegating the given amount of FTMx
     * @param amountFTMx the amount of FTMx to undelegate
     * @return amount the amount of FTM the input is worth
     * @return amountToUndelegate the amount of FTM coming from the vaults
     * @return penalty the total penalty (in FTM) applicable on undelegation
     */
    function calculatePenalty(uint256 amountFTMx)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 amount = (amountFTMx * getExchangeRate()) / DECIMAL_UNIT;
        uint256 poolBalance = getPoolBalance();

        if (amount <= poolBalance) {
            // no penalty
            return (amount, 0, 0);
        }

        uint256 totalStake;
        uint256 totalPenalty;
        uint256 vaultCount = maxVaultCount();
        for (uint256 i = 0; i < vaultCount; i = _uncheckedInc(i)) {
            address payable vault = _allVaults[i];
            if (vault != address(0)) {
                uint256 toValidatorID = Vault(vault).toValidatorID();
                totalStake += SFC.getStake(vault, toValidatorID);
                if (SFC.isLockedUp(vault, toValidatorID)) {
                    totalPenalty += _getUnlockPenalty(vault, toValidatorID);
                }
            }
        }
        uint256 amountToUndelegate = amount - poolBalance;
        uint256 penalty = (amountToUndelegate * totalPenalty) / totalStake;
        return (amount, amountToUndelegate, penalty);
    }

    /**
     * @notice Returns the info of vaults from which to undelegate
     * @param amount the amount to undelegate
     * @return vaultsToUndelegate the list of vault addresses
     * @return amountsToUndelegate the corresponding amounts to undelegate from each vault
     * @return emptyCount the count of vault which would become empty post this undelegation
     */
    function pickVaultsToUndelegate(uint256 amount)
        public
        view
        returns (
            address payable[] memory,
            uint256[] memory,
            uint256
        )
    {
        uint256 maxCount = maxVaultCount();
        address payable[] memory vaultsToUndelegateTemp = new address payable[](
            maxCount
        );
        uint256[] memory amountsToUndelegateTemp = new uint256[](maxCount);

        uint256 vaultPtr = currentVaultPtr();
        uint256 index;
        uint256 emptyCount;

        while (amount > 0) {
            vaultPtr = _decrementWithMod(vaultPtr, maxCount);
            address payable vault = _allVaults[vaultPtr];

            if (vault == address(0)) {
                // Should not happen if amount is less than current FTM worth
                break;
            }

            uint256 vaultLockedAmount = Vault(vault).getLockedStake();
            vaultsToUndelegateTemp[index] = vault;

            if (vaultLockedAmount > amount) {
                amountsToUndelegateTemp[index] = amount;
                amount = 0;
            } else {
                amountsToUndelegateTemp[index] = vaultLockedAmount;
                amount -= vaultLockedAmount;
                emptyCount += 1;
            }

            index += 1;
        }

        address payable[] memory vaultsToUndelegate = new address payable[](
            index
        );
        uint256[] memory amountsToUndelegate = new uint256[](index);

        for (uint256 i = 0; i < index; i = _uncheckedInc(i)) {
            vaultsToUndelegate[i] = vaultsToUndelegateTemp[i];
            amountsToUndelegate[i] = amountsToUndelegateTemp[i];
        }

        return (vaultsToUndelegate, amountsToUndelegate, emptyCount);
    }

    /**********************
     * Setter functions   *
     **********************/

    /**
     * @notice Pauses the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Set validator picker contract address (onlyOwner)
     * @param picker the new picker contract address
     */
    function setValidatorPicker(IValidatorPicker picker) external onlyOwner {
        validatorPicker = picker;
        emit LogValidatorPickerSet(msg.sender, address(picker));
    }

    /**
     * @notice Set epoch duration (onlyOwner)
     * @param duration the new epoch duration
     */
    function setEpochDuration(uint256 duration) external onlyOwner {
        _epochDuration = duration;
        emit LogEpochDurationSet(msg.sender, duration);
    }

    /**
     * @notice Set withdrawal delay (onlyOwner)
     * @param delay the new delay
     */
    function setWithdrawalDelay(uint256 delay) external onlyOwner {
        _withdrawalDelay = delay;
        emit LogWithdrawalDelaySet(msg.sender, delay);
    }

    /**
     * @notice Set the owner of an arbitrary input vault (onlyOwner)
     * @param vault the vault address
     * @param newOwner the new owner address
     */
    function updateVaultOwner(address payable vault, address newOwner)
        external
        onlyOwner
    {
        // Needs to support arbitrary input address to work with expired/matured vaults
        Vault(vault).updateOwner(newOwner);
        emit LogVaultOwnerUpdated(msg.sender, vault, newOwner);
    }

    /**********************
     * End User Functions *
     **********************/

    /**
     * @notice Deposit FTM, and mint FTMX
     */
    function deposit() external payable whenNotPaused {
        uint256 amount = msg.value;
        uint256 ftmxAmount = getFTMxAmountForFTM(amount, true);
        FTMX.mint(msg.sender, ftmxAmount);

        emit LogDeposited(msg.sender, msg.value, ftmxAmount);
    }

    /**
     * @notice Undelegate FTMx, corresponding FTM can then be withdrawn after `_withdrawalDelay`
     * @param wrID a unique withdrawal ID
     * @param amountFTMx the amount of FTMx to undelegate
     * @param minAmountFTM the minimum amount of FTM to receive
     *
     * Requirements:
     *  - wrID must not be used before
     *  - wrID must be greater than 0
     */
    function undelegate(
        uint256 wrID,
        uint256 amountFTMx,
        uint256 minAmountFTM
    ) external whenNotPaused {
        claimRewardsAll();
        _undelegate(msg.sender, wrID, amountFTMx, minAmountFTM);

        emit LogUndelegated(msg.sender, wrID, amountFTMx);
    }

    /**
     * @notice Withdraw undelegated FTM
     * @param wrID the unique wrID for the undelegation request
     * @param bitmaskToSkip a bit-mask to denote which vault to skip (if any)
     *
     * Requirements:
     *  - must wait for `_withdrawalDelay` between undelegation and withdrawal
     *
     * IMPORTANT : bitmaskToSkip must be 0 if no vault is to be skipped. It is useful
     * in scenarios where a particular validator was slashed (and not refunded), so we
     * want to withdraw from all expect the slashed validator.
     * A validator once skipped cannot be withdrawn from again, even if they are refunded.
     */
    function withdraw(uint256 wrID, uint256 bitmaskToSkip)
        external
        whenNotPaused
    {
        WithdrawalRequest storage request = allWithdrawalRequests[wrID];

        require(request.requestTime > 0, "ERR_WRID_INVALID");
        require(
            _now() >= request.requestTime + withdrawalDelay(),
            "ERR_NOT_ENOUGH_TIME_PASSED"
        );
        require(!request.isWithdrawn, "ERR_ALREADY_WITHDRAWN");
        request.isWithdrawn = true;

        address user = request.user;
        require(msg.sender == user, "ERR_UNAUTHORIZED");

        uint256 totalAmount = request.poolAmount;

        if (totalAmount > 0) {
            _reduceFromPendingWithdrawal(totalAmount);
        }

        if (request.undelegateAmount > 0) {
            uint256 actualAmountUndelegated;
            uint256 vaultCount = request.vaultsToUndelegate.length;
            uint256 bitPos = 1;
            uint256 balanceBefore = address(this).balance;

            for (uint256 i = 0; i < vaultCount; i = _uncheckedInc(i)) {
                bitPos *= 2;
                if ((bitmaskToSkip & bitPos) != bitPos) {
                    // Note: If the validator is slashed, the below call fails, in turn failing the entire txn
                    // Thus, use the bitmask to skip this validator
                    _withdrawVault(request.vaultsToUndelegate[i], wrID, false);
                    actualAmountUndelegated += request.amountsToUndelegate[i];
                }
            }

            totalAmount +=
                address(this).balance -
                balanceBefore -
                (request.penalty * actualAmountUndelegated) /
                request.undelegateAmount;
        }

        // protection against deleting the withdrawal request and going back empty handed
        require(totalAmount > 0, "ERR_FULLY_SLASHED");

        // do transfer after marking as withdrawn to protect against re-entrancy
        payable(user).transfer(totalAmount);

        emit LogWithdrawn(user, wrID, totalAmount);
    }

    /*************************
     * Maintenance Functions *
     *************************/

    /**
     * @notice Delegate the current pool balance with the next available validator
     *
     * IMPORTANT: the validator is picked by the validator picker contract
     */
    function lock() external whenNotPaused {
        require(_now() >= nextEligibleTimestamp(), "ERR_WAIT_FOR_NEXT_EPOCH");
        uint256 amount = getPoolBalance();
        require(amount > 0, "ERR_NO_FTM_TO_LOCK");

        _nextEligibleTimestamp += epochDuration();

        (uint256 toValidatorID, uint256 lockupDuration) = validatorPicker
            .getNextValidatorInfo(amount);

        address payable newVault = _createVault(toValidatorID);
        _lockVault(newVault, lockupDuration, amount);

        emit LogLocked(newVault, lockupDuration, amount);
    }

    /**
     * @notice Claim rewards from all contracts and add them to the pool
     */
    function claimRewardsAll() public whenNotPaused {
        uint256 currentEpoch = SFC.currentEpoch();

        if (currentEpoch <= lastKnownEpoch) {
            return;
        }

        lastKnownEpoch = currentEpoch;

        uint256 vaultCount = maxVaultCount();
        for (uint256 i = 0; i < vaultCount; i = _uncheckedInc(i)) {
            address payable vault = _allVaults[i];
            if (vault != address(0)) {
                _claim(vault);
            }
        }
    }

    /**
     * @notice Claim rewards from a given vault and add them to the pool
     * @param vaultIndex the index of the vault to claim
     */
    function claimRewards(uint256 vaultIndex)
        external
        whenNotPaused
        returns (bool)
    {
        require(vaultIndex < maxVaultCount(), "ERR_INVALID_INDEX");
        address payable vault = _allVaults[vaultIndex];
        if (vault != address(0)) {
            return _claim(vault);
        }
        return false;
    }

    /**
     * @notice Harvest matured amount from a given vault
     * @param vaultIndex the index of the vault to harvest
     */
    function harvestVault(uint256 vaultIndex) external whenNotPaused {
        address payable vault = _allVaults[vaultIndex];
        require(vault != address(0), "ERR_INVALID_INDEX");

        uint256 toValidatorID = Vault(vault).toValidatorID();
        require(!SFC.isLockedUp(vault, toValidatorID), "ERR_NOT_UNLOCKED_YET");

        // We reserve wrID of 0 for undelegating on maturity
        Vault(vault).undelegate(0, SFC.getStake(vault, toValidatorID));
        _claim(vault);

        // store info for withdrawal
        _maturedVaults.push(vault);

        // the vault is now empty
        delete _allVaults[vaultIndex];
        _decrementVaultCount();

        emit LogVaultHarvested(vault, _maturedVaults.length - 1);
    }

    /**
     * @notice Withdraw harvested amount from a given vault and add them to the pool
     * @param maturedIndex the index of the vault (in list of matured vaults) to withdraw
     */
    function withdrawMatured(uint256 maturedIndex) external whenNotPaused {
        address payable vault = _maturedVaults[maturedIndex];
        require(vault != address(0), "ERR_INVALID_INDEX");
        _maturedVaults[maturedIndex] = _maturedVaults[
            _maturedVaults.length - 1
        ];
        _maturedVaults.pop();
        _withdrawVault(vault, 0, true);

        emit LogVaultWithdrawn(vault);
    }

    /**********************
     * Internal functions *
     **********************/

    function _createVault(uint256 toValidatorID)
        internal
        returns (address payable)
    {
        require(
            currentVaultCount() < maxVaultCount(),
            "ERR_MAX_VAULTS_OCCUPIED"
        );
        address payable vault = payable(address(new Vault(SFC, toValidatorID)));
        _allVaults[currentVaultPtr()] = vault;
        _incrementVaultPtr();
        _incrementVaultCount();
        return vault;
    }

    function _lockVault(
        address payable vault,
        uint256 lockupDuration,
        uint256 amount
    ) internal {
        Vault(vault).delegate{value: amount}();
        Vault(vault).lockStake(lockupDuration, amount);
    }

    function _claim(address payable vault) internal returns (bool) {
        try Vault(vault).claimRewards() {} catch {
            return false;
        }
        return true;
    }

    function _undelegate(
        address user,
        uint256 wrID,
        uint256 amountFTMx,
        uint256 minAmountFTM
    ) internal {
        require(amountFTMx > 0, "ERR_ZERO_AMOUNT");
        require(wrID > 0, "ERR_wrID_MUST_BE_NON_ZERO");

        WithdrawalRequest storage request = allWithdrawalRequests[wrID];
        require(request.requestTime == 0, "ERR_WRID_ALREADY_USED");

        FTMX.burnFrom(user, amountFTMx);

        request.requestTime = _now();
        request.user = user;

        (
            uint256 amount,
            uint256 totalAmountToUndelegate,
            uint256 penalty
        ) = calculatePenalty(amountFTMx);
        require(
            amount - penalty >= minAmountFTM,
            "ERR_INSUFFICIENT_AMOUNT_OUT"
        );

        if (totalAmountToUndelegate == 0) {
            // no penalty, all from pool
            _addToPendingWithdrawal(amount);
            request.poolAmount = amount;
        } else {
            // use whatever is in pool, undelegate the remaining
            _addToPendingWithdrawal(amount - totalAmountToUndelegate);

            (
                address payable[] memory vaultsToUndelegate,
                uint256[] memory amountsToUndelegate,
                uint256 emptyCount
            ) = pickVaultsToUndelegate(totalAmountToUndelegate);

            uint256 vaultCount = vaultsToUndelegate.length;
            uint256 maxCount = maxVaultCount();
            uint256 vaultPtr = currentVaultPtr();

            for (uint256 i = 0; i < vaultCount; i = _uncheckedInc(i)) {
                _unlockAndUndelegateVault(
                    vaultsToUndelegate[i],
                    wrID,
                    amountsToUndelegate[i]
                );

                if (i < emptyCount) {
                    // the vault is now empty

                    vaultPtr = _decrementWithMod(vaultPtr, maxCount);
                    delete _allVaults[vaultPtr];

                    _decrementVaultPtr();
                    _decrementVaultCount();
                }
            }

            request.poolAmount = amount - totalAmountToUndelegate;
            request.undelegateAmount = totalAmountToUndelegate;
            request.penalty = penalty;
            request.vaultsToUndelegate = vaultsToUndelegate;
            request.amountsToUndelegate = amountsToUndelegate;
        }
    }

    function _unlockAndUndelegateVault(
        address payable vault,
        uint256 wrID,
        uint256 amount
    ) internal {
        Vault(vault).unlock(amount);
        Vault(vault).undelegate(wrID, amount);
    }

    function _withdrawVault(
        address payable vault,
        uint256 wrID,
        bool withdrawAll
    ) internal {
        Vault(vault).withdraw(wrID, withdrawAll);
    }

    function _addToPendingWithdrawal(uint256 amount) internal {
        _ftmPendingWithdrawal += amount;
    }

    function _reduceFromPendingWithdrawal(uint256 amount) internal {
        _ftmPendingWithdrawal -= amount;
    }

    function _incrementVaultPtr() internal {
        _currentVaultPtr = _incrementWithMod(_currentVaultPtr, maxVaultCount());
    }

    function _decrementVaultPtr() internal {
        _currentVaultPtr = _decrementWithMod(_currentVaultPtr, maxVaultCount());
    }

    function _incrementVaultCount() internal {
        unchecked {
            _currentVaultCount += 1;
        }
    }

    function _decrementVaultCount() internal {
        unchecked {
            _currentVaultCount -= 1;
        }
    }

    function _now() internal view returns (uint256) {
        return block.timestamp;
    }

    function _incrementWithMod(uint256 i, uint256 mod)
        internal
        pure
        returns (uint256)
    {
        return (i + 1) % mod;
    }

    function _decrementWithMod(uint256 i, uint256 mod)
        internal
        pure
        returns (uint256)
    {
        return (i + mod - 1) % mod;
    }

    function _uncheckedInc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    /************************
     *   Helper functions   *
     *        for           *
     * Penalty Calculation  *
     ************************/

    function _getUnlockPenalty(address payable vault, uint256 toValidatorID)
        internal
        view
        returns (uint256)
    {
        (uint256 lockupExtraReward, uint256 lockupBaseReward, ) = SFC
            .getStashedLockupRewards(vault, toValidatorID);

        (
            uint256 newLockupExtraReward,
            uint256 newLockupBaseReward,

        ) = _newRewards(vault, toValidatorID);

        uint256 lockupExtraRewardShare = lockupExtraReward +
            newLockupExtraReward;
        uint256 lockupBaseRewardShare = lockupBaseReward + newLockupBaseReward;
        uint256 penalty = lockupExtraRewardShare + lockupBaseRewardShare / 2;

        return penalty;
    }

    function _highestPayableEpoch(uint256 validatorID)
        internal
        view
        returns (uint256)
    {
        (, , uint256 deactivatedEpoch, , , , ) = SFC.getValidator(validatorID);

        uint256 currentSealedEpoch = SFC.currentSealedEpoch();

        if (deactivatedEpoch != 0) {
            if (currentSealedEpoch < deactivatedEpoch) {
                return currentSealedEpoch;
            }
            return deactivatedEpoch;
        }
        return currentSealedEpoch;
    }

    function _epochEndTime(uint256 epoch) internal view returns (uint256) {
        (uint256 endTime, , , , , , ) = SFC.getEpochSnapshot(epoch);

        return endTime;
    }

    function _isLockedUpAtEpoch(
        address delegator,
        uint256 toValidatorID,
        uint256 epoch
    ) internal view returns (bool) {
        (, uint256 fromEpoch, uint256 endTime, ) = SFC.getLockupInfo(
            delegator,
            toValidatorID
        );

        return fromEpoch <= epoch && _epochEndTime(epoch) <= endTime;
    }

    function _highestLockupEpoch(address delegator, uint256 validatorID)
        internal
        view
        returns (uint256)
    {
        (, uint256 fromEpoch, , ) = SFC.getLockupInfo(delegator, validatorID);

        uint256 l = fromEpoch;
        uint256 r = SFC.currentSealedEpoch();
        if (_isLockedUpAtEpoch(delegator, validatorID, r)) {
            return r;
        }
        if (!_isLockedUpAtEpoch(delegator, validatorID, l)) {
            return 0;
        }
        if (l > r) {
            return 0;
        }
        while (l < r) {
            uint256 m = (l + r) / 2;
            if (_isLockedUpAtEpoch(delegator, validatorID, m)) {
                l = m + 1;
            } else {
                r = m;
            }
        }
        if (r == 0) {
            return 0;
        }
        return r - 1;
    }

    function _newRewardsOf(
        uint256 stakeAmount,
        uint256 toValidatorID,
        uint256 fromEpoch,
        uint256 toEpoch
    ) internal view returns (uint256) {
        if (fromEpoch >= toEpoch) {
            return 0;
        }

        uint256 stashedRate = SFC.getEpochAccumulatedRewardPerToken(
            fromEpoch,
            toValidatorID
        );
        uint256 currentRate = SFC.getEpochAccumulatedRewardPerToken(
            toEpoch,
            toValidatorID
        );
        return ((currentRate - stashedRate) * stakeAmount) / DECIMAL_UNIT;
    }

    function _scaleLockupReward(uint256 fullReward, uint256 lockupDuration)
        internal
        pure
        returns (Rewards memory reward)
    {
        reward = Rewards(0, 0, 0);
        if (lockupDuration != 0) {
            uint256 maxLockupExtraRatio = DECIMAL_UNIT - UNLOCKED_REWARD_RATIO;
            uint256 lockupExtraRatio = (maxLockupExtraRatio * lockupDuration) /
                MAX_LOCKUP_DURATION;
            uint256 totalScaledReward = (fullReward *
                (UNLOCKED_REWARD_RATIO + lockupExtraRatio)) / DECIMAL_UNIT;
            reward.lockupBaseReward =
                (fullReward * UNLOCKED_REWARD_RATIO) /
                DECIMAL_UNIT;
            reward.lockupExtraReward =
                totalScaledReward -
                reward.lockupBaseReward;
        } else {
            reward.unlockedReward =
                (fullReward * UNLOCKED_REWARD_RATIO) /
                DECIMAL_UNIT;
        }
        return reward;
    }

    function _newRewards(address delegator, uint256 toValidatorID)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 stashedUntil = SFC.stashedRewardsUntilEpoch(
            delegator,
            toValidatorID
        );
        uint256 payableUntil = _highestPayableEpoch(toValidatorID);
        uint256 lockedUntil = _highestLockupEpoch(delegator, toValidatorID);
        if (lockedUntil > payableUntil) {
            lockedUntil = payableUntil;
        }
        if (lockedUntil < stashedUntil) {
            lockedUntil = stashedUntil;
        }

        (uint256 lockedStake, , , uint256 duration) = SFC.getLockupInfo(
            delegator,
            toValidatorID
        );

        uint256 wholeStake = SFC.getStake(delegator, toValidatorID);
        uint256 unlockedStake = wholeStake - lockedStake;
        uint256 fullReward;

        // count reward for locked stake during lockup epochs
        fullReward = _newRewardsOf(
            lockedStake,
            toValidatorID,
            stashedUntil,
            lockedUntil
        );
        Rewards memory plReward = _scaleLockupReward(fullReward, duration);
        // count reward for unlocked stake during lockup epochs
        fullReward = _newRewardsOf(
            unlockedStake,
            toValidatorID,
            stashedUntil,
            lockedUntil
        );
        Rewards memory puReward = _scaleLockupReward(fullReward, 0);
        // count lockup reward for unlocked stake during unlocked epochs
        fullReward = _newRewardsOf(
            wholeStake,
            toValidatorID,
            lockedUntil,
            payableUntil
        );
        Rewards memory wuReward = _scaleLockupReward(fullReward, 0);

        Rewards memory result = _sumRewards(plReward, puReward, wuReward);

        return (
            result.lockupExtraReward,
            result.lockupBaseReward,
            result.unlockedReward
        );
    }

    function _sumRewards(Rewards memory a, Rewards memory b)
        internal
        pure
        returns (Rewards memory)
    {
        return
            Rewards(
                a.lockupExtraReward + b.lockupExtraReward,
                a.lockupBaseReward + b.lockupBaseReward,
                a.unlockedReward + b.unlockedReward
            );
    }

    function _sumRewards(
        Rewards memory a,
        Rewards memory b,
        Rewards memory c
    ) internal pure returns (Rewards memory) {
        return _sumRewards(_sumRewards(a, b), c);
    }

    /**
     * @notice To receive Eth from vaults
     */
    receive() external payable {}
}
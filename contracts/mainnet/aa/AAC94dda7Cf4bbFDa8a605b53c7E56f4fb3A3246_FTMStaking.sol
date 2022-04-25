// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/ISFC.sol";
import "./interfaces/IERC20Burnable.sol";
import "./interfaces/IValidatorPicker.sol";

import "./Vault.sol";

import "./libraries/SFCPenalty.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title FTM Staking Contract
 * @author Stader Labs
 * @notice Main point of interaction with Stader protocol's v1 liquid staking
 */
contract FTMStaking is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // These constants have been taken from the SFC contract
    uint256 public constant DECIMAL_UNIT = 1e18;
    uint256 public constant UNLOCKED_REWARD_RATIO = (30 * DECIMAL_UNIT) / 100;
    uint256 public constant MAX_LOCKUP_DURATION = 86400 * 365;

    struct UndelegateInfo {
        address payable vault;
        uint256 amountToUnlock;
        uint256 amountToUndelegate;
    }

    struct WithdrawalRequest {
        UndelegateInfo[] info;
        uint256 requestTime;
        uint256 poolAmount;
        uint256 undelegateAmount;
        uint256 penalty;
        address user;
        bool isWithdrawn;
    }

    /**
     * @dev A reference to the FTMX ERC20 token contract
     */
    IERC20Burnable public FTMX;

    /**
     * @dev A reference to the SFC contract
     */
    ISFC public SFC;

    /**
     * @dev A reference to the Validator picker contract
     */
    IValidatorPicker public validatorPicker;

    /**
     * @dev A reference to the treasury address
     */
    address public treasury;

    /**
     * @dev The protocol fee in basis points (BIPS)
     */
    uint256 public protocolFeeBIPS;

    /**
     * @dev The last known epoch to prevent wasting gas during reward claim process
     */
    uint256 public lastKnownEpoch;

    /**
     * @dev The maximum number of vaults that can be created
     */
    uint256 public maxVaultCount;

    /**
     * The duration of an epoch between two successive locks
     */
    uint256 public epochDuration;

    /**
     * The delay between undelegation & withdrawal
     */
    uint256 public withdrawalDelay;

    uint256 public minDeposit;

    uint256 public maxDeposit;

    bool public undelegatePaused;

    bool public withdrawPaused;

    bool public maintenancePaused;

    /**
     * The index of the next vault to be created
     */
    uint256 public currentVaultPtr;

    /**
     * The count of vaults in existence
     */
    uint256 public currentVaultCount;

    /**
     * The next timestamp eligible for locking
     */
    uint256 public nextEligibleTimestamp;

    /**
     * The currently pending FTM withdrawal amount
     */
    uint256 public ftmPendingWithdrawal;

    address payable[] private _maturedVaults;

    mapping(uint256 => address payable) private _allVaults;

    mapping(uint256 => WithdrawalRequest) public allWithdrawalRequests;

    event LogValidatorPickerSet(address indexed owner, address validatorPicker);
    event LogEpochDurationSet(address indexed owner, uint256 duration);
    event LogWithdrawalDelaySet(address indexed owner, uint256 delay);
    event LogUndelegatePausedUpdated(address indexed owner, bool newValue);
    event LogWithdrawPausedUpdated(address indexed owner, bool newValue);
    event LogMaintenancePausedUpdated(address indexed owner, bool newValue);
    event LogDepositLimitUpdated(
        address indexed owner,
        uint256 low,
        uint256 high
    );

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
    event LogWithdrawn(
        address indexed user,
        uint256 wrID,
        uint256 totalAmount,
        uint256 bitmaskToSkip
    );
    event LogLocked(
        address indexed vault,
        uint256 lockupDuration,
        uint256 amount
    );
    event LogVaultHarvested(address indexed vault, uint256 maturedIndex);
    event LogVaultWithdrawn(address indexed vault);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @notice Initializer
     * @param _ftmx_ the address of the FTM token contract (is NOT modifiable)
     * @param _sfc_ the address of the SFC contract (is NOT modifiable)
     * @param maxVaultCount_ the maximum number of vaults to be created (is NOT modifiable)
     * @param epochDuration_ the duration of a locking epoch (is modifiable)
     * @param withdrawalDelay_ the delay between undelegation & withdrawal (is modifiable)
     */
    function initialize(
        IERC20Burnable _ftmx_,
        ISFC _sfc_,
        uint256 maxVaultCount_,
        uint256 epochDuration_,
        uint256 withdrawalDelay_
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        FTMX = _ftmx_;
        SFC = _sfc_;

        maxVaultCount = maxVaultCount_;
        epochDuration = epochDuration_;
        withdrawalDelay = withdrawalDelay_;

        treasury = msg.sender;
        minDeposit = 0;
        maxDeposit = 100 ether;
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
     * @notice Returns the list of vaults, associated amounts for the given withdrawal ID
     * @param wrID the withdrawal ID to query
     */
    function getWithdrawalInfo(uint256 wrID)
        external
        view
        returns (UndelegateInfo[] memory)
    {
        return allWithdrawalRequests[wrID].info;
    }

    /**
     * @notice Returns the currently available FTM balance to delegate
     */
    function getPoolBalance() public view returns (uint256) {
        return address(this).balance - ftmPendingWithdrawal;
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
        uint256 vaultCount = maxVaultCount;
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
        uint256 vaultCount = maxVaultCount;
        for (uint256 i = 0; i < vaultCount; i = _uncheckedInc(i)) {
            address payable vault = _allVaults[i];
            if (vault != address(0)) {
                uint256 toValidatorID = Vault(vault).toValidatorID();
                totalStake += SFC.getStake(vault, toValidatorID);
                if (SFC.isLockedUp(vault, toValidatorID)) {
                    uint256 vaultLockedAmount = Vault(vault).getLockedStake();
                    totalPenalty += SFCPenalty.getUnlockPenalty(
                        SFC,
                        vault,
                        toValidatorID,
                        vaultLockedAmount,
                        vaultLockedAmount
                    );
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
     * @return info the struct of type UndelegateInfo, denoting undelegation info of vaults
     * @return implicitPenalty the implicit penalty paid by this undelegation in unlocking
     */
    function pickVaultsToUndelegate(uint256 amount)
        public
        view
        returns (
            UndelegateInfo[] memory,
            uint256
        )
    {
        uint256 maxCount = maxVaultCount;

        UndelegateInfo[] memory infoTemp = new UndelegateInfo[](maxCount);

        uint256 vaultPtr = currentVaultPtr;
        uint256 index;
        uint256 implicitPenalty;

        while (amount > 0) {
            vaultPtr = _decrementWithMod(vaultPtr, maxCount);
            address payable vault = _allVaults[vaultPtr];

            if (vault == address(0)) {
                // Should not happen if amount is less than current FTM worth
                break;
            }

            (
                uint256 amountToUnlock,
                uint256 amountToUndelegate,
                uint256 amountToReduce
            ) = _getAmountsAfterPenalty(vault, amount);

            infoTemp[index].vault = vault;
            infoTemp[index].amountToUnlock = amountToUnlock;
            infoTemp[index].amountToUndelegate = amountToUndelegate;
            implicitPenalty += amountToUnlock - amountToUndelegate;

            amount -= amountToReduce;
            index += 1;
        }

        UndelegateInfo[] memory info = new UndelegateInfo[](index);

        for (uint256 i = 0; i < index; i = _uncheckedInc(i)) {
            info[i] = infoTemp[i];
        }

        return (info, implicitPenalty);
    }

    /**********************
     * Admin functions   *
     **********************/

    /**
     * @notice Delegate the current pool balance with the next available validator
     * @param amount the amount to lock
     * IMPORTANT: the validator is picked by the validator picker contract
     */
    function lock(uint256 amount) external onlyOwner {
        require(_now() >= nextEligibleTimestamp, "ERR_WAIT_FOR_NEXT_EPOCH");
        require(amount > 0 && amount <= getPoolBalance(), "ERR_INVALID_AMOUNT");

        nextEligibleTimestamp += epochDuration;

        (uint256 toValidatorID, uint256 lockupDuration) = validatorPicker
            .getNextValidatorInfo(amount);

        address payable newVault = _createVault(toValidatorID);
        _lockVault(newVault, lockupDuration, amount);

        emit LogLocked(newVault, lockupDuration, amount);
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
        epochDuration = duration;
        emit LogEpochDurationSet(msg.sender, duration);
    }

    /**
     * @notice Set withdrawal delay (onlyOwner)
     * @param delay the new delay
     */
    function setWithdrawalDelay(uint256 delay) external onlyOwner {
        withdrawalDelay = delay;
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

    /**
     * @notice Pause/unpause user undelegations (onlyOwner)
     * @param desiredValue the desired value of the switch
     */
    function setUndelegatePaused(bool desiredValue) external onlyOwner {
        require(undelegatePaused != desiredValue, "ERR_ALREADY_DESIRED_VALUE");
        undelegatePaused = desiredValue;
        emit LogUndelegatePausedUpdated(msg.sender, desiredValue);
    }

    /**
     * @notice Pause/unpause user withdrawals (onlyOwner)
     * @param desiredValue the desired value of the switch
     */
    function setWithdrawPaused(bool desiredValue) external onlyOwner {
        require(withdrawPaused != desiredValue, "ERR_ALREADY_DESIRED_VALUE");
        withdrawPaused = desiredValue;
        emit LogWithdrawPausedUpdated(msg.sender, desiredValue);
    }

    /**
     * @notice Pause/unpause maintenance functions (onlyOwner)
     * @param desiredValue the desired value of the switch
     */
    function setMaintenancePaused(bool desiredValue) external onlyOwner {
        require(maintenancePaused != desiredValue, "ERR_ALREADY_DESIRED_VALUE");
        maintenancePaused = desiredValue;
        emit LogMaintenancePausedUpdated(msg.sender, desiredValue);
    }

    function setDepositLimits(uint256 low, uint256 high) external onlyOwner {
        minDeposit = low;
        maxDeposit = high;
        emit LogDepositLimitUpdated(msg.sender, low, high);
    }

    /**
     * @notice Update the treasury address
     * @param newTreasury the new treasury address
     */
    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "ERR_INVALID_VALUE");
        treasury = newTreasury;
    }

    /**
     * @notice Update the protocol fee
     * @param newFeeBIPS the value of the fee (in BIPS)
     */
    function setProtocolFeeBIPS(uint256 newFeeBIPS) external onlyOwner {
        require(newFeeBIPS <= 10_000, "ERR_INVALID_VALUE");
        protocolFeeBIPS = newFeeBIPS;
    }

    /**********************
     * End User Functions *
     **********************/

    /**
     * @notice Deposit FTM, and mint FTMX
     */
    function deposit() external payable {
        uint256 amount = msg.value;
        require(
            amount >= minDeposit && amount <= maxDeposit,
            "ERR_AMOUNT_OUTSIDE_LIMITS"
        );

        uint256 ftmxAmount = getFTMxAmountForFTM(amount, true);
        FTMX.mint(msg.sender, ftmxAmount);

        emit LogDeposited(msg.sender, msg.value, ftmxAmount);
    }

    /**
     * @notice Undelegate FTMx, corresponding FTM can then be withdrawn after `withdrawalDelay`
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
    ) external {
        require(!undelegatePaused, "ERR_UNDELEGATE_IS_PAUSED");

        _undelegate(msg.sender, wrID, amountFTMx, minAmountFTM);

        emit LogUndelegated(msg.sender, wrID, amountFTMx);
    }

    /**
     * @notice Withdraw undelegated FTM
     * @param wrID the unique wrID for the undelegation request
     * @param bitmaskToSkip a bit-mask to denote which vault to skip (if any)
     *
     * Requirements:
     *  - must wait for `withdrawalDelay` between undelegation and withdrawal
     *
     * IMPORTANT : bitmaskToSkip must be 0 if no vault is to be skipped. It is useful
     * in scenarios where a particular validator was slashed (and not refunded), so we
     * want to withdraw from all expect the slashed validator.
     * A validator once skipped cannot be withdrawn from again, even if they are refunded.
     *
     * Using the bitmask
     * Consider vaults in the allWithdrawalRequests to be numbered as 1,2,3...
     * To skip vault i, bitmask (Bi) = 2^(i-1)
     * To skip vault i and j, bitmask = Bi | Bj
     *      where | is the bitwise OR operation
     */
    function withdraw(uint256 wrID, uint256 bitmaskToSkip) external {
        require(!withdrawPaused, "ERR_WITHDRAW_IS_PAUSED");

        WithdrawalRequest storage request = allWithdrawalRequests[wrID];

        require(request.requestTime > 0, "ERR_WRID_INVALID");
        require(
            _now() >= request.requestTime + withdrawalDelay,
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
            uint256 vaultCount = request.info.length;
            uint256 bitPos = 1;
            uint256 balanceBefore = address(this).balance;

            for (uint256 i = 0; i < vaultCount; i = _uncheckedInc(i)) {
                if ((bitmaskToSkip & bitPos) != bitPos) {
                    // Note: If the validator is slashed, the below call fails, in turn failing the entire txn
                    // Thus, use the bitmask to skip this validator
                    _withdrawVault(request.info[i].vault, wrID, false);
                    actualAmountUndelegated += request
                        .info[i]
                        .amountToUndelegate;
                }
                bitPos *= 2;
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

        emit LogWithdrawn(user, wrID, totalAmount, bitmaskToSkip);
    }

    /*************************
     * Maintenance Functions *
     *************************/

    /**
     * @notice Claim rewards from all contracts and add them to the pool
     */
    function claimRewardsAll() external {
        require(!maintenancePaused, "ERR_THIS_FUNCTION_IS_PAUSED");

        uint256 currentEpoch = SFC.currentEpoch();

        if (currentEpoch <= lastKnownEpoch) {
            return;
        }

        lastKnownEpoch = currentEpoch;

        uint256 balanceBefore = address(this).balance;

        uint256 vaultCount = maxVaultCount;
        for (uint256 i = 0; i < vaultCount; i = _uncheckedInc(i)) {
            address payable vault = _allVaults[i];
            if (vault != address(0)) {
                _claim(vault);
            }
        }

        if (protocolFeeBIPS > 0) {
            uint256 balanceAfter = address(this).balance;
            uint256 protocolFee = ((balanceAfter - balanceBefore) *
                protocolFeeBIPS) / 10_000;
            payable(treasury).transfer(protocolFee);
        }
    }

    /**
     * @notice Harvest matured amount from a given vault
     * @param vaultIndex the index of the vault to harvest
     */
    function harvestVault(uint256 vaultIndex) external {
        require(!maintenancePaused, "ERR_THIS_FUNCTION_IS_PAUSED");

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
    function withdrawMatured(uint256 maturedIndex) external {
        require(!maintenancePaused, "ERR_THIS_FUNCTION_IS_PAUSED");

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

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function _createVault(uint256 toValidatorID)
        internal
        returns (address payable)
    {
        require(currentVaultCount < maxVaultCount, "ERR_MAX_VAULTS_OCCUPIED");
        address payable vault = payable(address(new Vault(SFC, toValidatorID)));
        _allVaults[currentVaultPtr] = vault;
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

        FTMX.burnFrom(user, amountFTMx);

        if (totalAmountToUndelegate == 0) {
            // no penalty, all from pool
            _addToPendingWithdrawal(amount);
            request.poolAmount = amount;
        } else {
            // use whatever is in pool, undelegate the remaining
            _addToPendingWithdrawal(amount - totalAmountToUndelegate);

            (
                UndelegateInfo[] memory info,
                uint256 implicitPenalty
            ) = pickVaultsToUndelegate(totalAmountToUndelegate);

            uint256 vaultCount = info.length;
            uint256 maxCount = maxVaultCount;
            uint256 vaultPtr = currentVaultPtr;

            for (uint256 i = 0; i < vaultCount; i = _uncheckedInc(i)) {
                _unlockAndUndelegateVault(
                    info[i].vault,
                    wrID,
                    info[i].amountToUnlock,
                    info[i].amountToUndelegate
                );

                if (
                    i < vaultCount - 1 ||
                    ((i == vaultCount - 1) &&
                        Vault(info[i].vault).getLockedStake() == 0)
                ) {
                    // the vault is empty
                    vaultPtr = _decrementWithMod(vaultPtr, maxCount);
                    delete _allVaults[vaultPtr];

                    _decrementVaultPtr();
                    _decrementVaultCount();
                }
                request.info.push(
                    UndelegateInfo(
                        info[i].vault,
                        info[i].amountToUnlock,
                        info[i].amountToUndelegate
                    )
                );
            }

            request.poolAmount = amount - totalAmountToUndelegate;
            request.undelegateAmount = totalAmountToUndelegate;
            if (implicitPenalty > penalty) {
                implicitPenalty = penalty;
            }
            request.penalty = penalty - implicitPenalty;
        }
    }

    function _unlockAndUndelegateVault(
        address payable vault,
        uint256 wrID,
        uint256 amountToUnlock,
        uint256 amountToUndelegate
    ) internal {
        Vault(vault).unlock(amountToUnlock);
        Vault(vault).undelegate(wrID, amountToUndelegate);
    }

    function _withdrawVault(
        address payable vault,
        uint256 wrID,
        bool withdrawAll
    ) internal {
        Vault(vault).withdraw(wrID, withdrawAll);
    }

    function _addToPendingWithdrawal(uint256 amount) internal {
        ftmPendingWithdrawal += amount;
    }

    function _reduceFromPendingWithdrawal(uint256 amount) internal {
        ftmPendingWithdrawal -= amount;
    }

    function _incrementVaultPtr() internal {
        currentVaultPtr = _incrementWithMod(currentVaultPtr, maxVaultCount);
    }

    function _decrementVaultPtr() internal {
        currentVaultPtr = _decrementWithMod(currentVaultPtr, maxVaultCount);
    }

    function _incrementVaultCount() internal {
        unchecked {
            currentVaultCount += 1;
        }
    }

    function _decrementVaultCount() internal {
        unchecked {
            currentVaultCount -= 1;
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
     *   Helper function    *
     *        for           *
     * Penalty Calculation  *
     ************************/

    function _getAmountsAfterPenalty(address payable vault, uint256 amount)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 toValidatorID = Vault(vault).toValidatorID();
        uint256 vaultLockedAmount = Vault(vault).getLockedStake();
        uint256 amountUndelegatable = vaultLockedAmount -
            SFCPenalty.getUnlockPenalty(
                SFC,
                vault,
                toValidatorID,
                vaultLockedAmount,
                vaultLockedAmount
            );

        if (amountUndelegatable > amount) {
            // amount undelegatable is more than amount needed, so we do a partial unlock
            uint256 estimatedToUnlock = (amount * vaultLockedAmount) /
                amountUndelegatable;
            uint256 estimatedPenalty = SFCPenalty.getUnlockPenalty(
                SFC,
                vault,
                toValidatorID,
                estimatedToUnlock,
                vaultLockedAmount
            );
            return (
                estimatedToUnlock,
                estimatedToUnlock - estimatedPenalty,
                amount
            );
        }
        return (vaultLockedAmount, amountUndelegatable, amountUndelegatable);
    }

    /**
     * @notice To receive Eth from vaults
     */
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
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

    function relockStake(
        uint256 toValidatorID,
        uint256 lockupDuration,
        uint256 amount
    ) external;

    function restakeRewards(uint256 toValidatorID) external;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IValidatorPicker {
    function getNextValidatorInfo(uint256 amount)
        external
        returns (uint256 toValidatorID, uint256 lockupDuration);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/ISFC.sol";

/**
 * @title Vault Contract
 * @author Stader Labs
 * @notice Vault contract is created by the Main Staking contract everytime FTM is delegated to a validator
 */
contract Vault {
    uint256 public constant DECIMAL_UNIT = 1e18;
    string public constant VERSION = "v1";

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
     * @notice Relock the unlocked stake
     * @param lockupDuration the duration for which to lock the stake
     * @param amount the amount of stake to relock
     */
    function relockStake(uint256 lockupDuration, uint256 amount)
        external
        onlyOwner
    {
        SFC.relockStake(toValidatorID, lockupDuration, amount);
    }

    /**
     * @notice Restake the accrued rewards
     */
    function restakeRewards() external onlyOwner {
        SFC.restakeRewards(toValidatorID);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/ISFC.sol";

library SFCPenalty {
    uint256 public constant DECIMAL_UNIT = 1e18;
    uint256 public constant UNLOCKED_REWARD_RATIO = (30 * DECIMAL_UNIT) / 100;
    uint256 public constant MAX_LOCKUP_DURATION = 86400 * 365;

    struct Rewards {
        uint256 lockupExtraReward;
        uint256 lockupBaseReward;
        uint256 unlockedReward;
    }

    function getUnlockPenalty(
        ISFC SFC,
        address payable vault,
        uint256 toValidatorID,
        uint256 unlockAmount,
        uint256 totalAmount
    ) public view returns (uint256) {
        (uint256 lockupExtraReward, uint256 lockupBaseReward, ) = SFC
            .getStashedLockupRewards(vault, toValidatorID);

        (
            uint256 newLockupExtraReward,
            uint256 newLockupBaseReward,

        ) = _newRewards(SFC, vault, toValidatorID);

        uint256 lockupExtraRewardShare = ((lockupExtraReward +
            newLockupExtraReward) * unlockAmount) / totalAmount;
        uint256 lockupBaseRewardShare = ((lockupBaseReward +
            newLockupBaseReward) * unlockAmount) / totalAmount;
        uint256 penalty = lockupExtraRewardShare + lockupBaseRewardShare / 2;

        if (penalty > unlockAmount) {
            penalty = unlockAmount;
        }

        return penalty;
    }

    function _highestPayableEpoch(ISFC SFC, uint256 validatorID)
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

    function _epochEndTime(ISFC SFC, uint256 epoch)
        internal
        view
        returns (uint256)
    {
        (uint256 endTime, , , , , , ) = SFC.getEpochSnapshot(epoch);

        return endTime;
    }

    function _isLockedUpAtEpoch(
        ISFC SFC,
        address delegator,
        uint256 toValidatorID,
        uint256 epoch
    ) internal view returns (bool) {
        (, uint256 fromEpoch, uint256 endTime, ) = SFC.getLockupInfo(
            delegator,
            toValidatorID
        );

        return fromEpoch <= epoch && _epochEndTime(SFC, epoch) <= endTime;
    }

    function _highestLockupEpoch(
        ISFC SFC,
        address delegator,
        uint256 validatorID
    ) internal view returns (uint256) {
        (, uint256 fromEpoch, , ) = SFC.getLockupInfo(delegator, validatorID);

        uint256 l = fromEpoch;
        uint256 r = SFC.currentSealedEpoch();
        if (_isLockedUpAtEpoch(SFC, delegator, validatorID, r)) {
            return r;
        }
        if (!_isLockedUpAtEpoch(SFC, delegator, validatorID, l)) {
            return 0;
        }
        if (l > r) {
            return 0;
        }
        while (l < r) {
            uint256 m = (l + r) / 2;
            if (_isLockedUpAtEpoch(SFC, delegator, validatorID, m)) {
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
        ISFC SFC,
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

    function _newRewards(
        ISFC SFC,
        address delegator,
        uint256 toValidatorID
    )
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
        uint256 payableUntil = _highestPayableEpoch(SFC, toValidatorID);
        uint256 lockedUntil = _highestLockupEpoch(
            SFC,
            delegator,
            toValidatorID
        );
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

        Rewards memory result = _genResult(
            SFC,
            toValidatorID,
            wholeStake,
            lockedStake,
            stashedUntil,
            lockedUntil,
            payableUntil,
            duration
        );

        return (
            result.lockupExtraReward,
            result.lockupBaseReward,
            result.unlockedReward
        );
    }

    function _genResult(
        ISFC SFC,
        uint256 toValidatorID,
        uint256 wholeStake,
        uint256 lockedStake,
        uint256 stashedUntil,
        uint256 lockedUntil,
        uint256 payableUntil,
        uint256 duration
    ) internal view returns (Rewards memory) {
        uint256 unlockedStake = wholeStake - lockedStake;
        uint256 fullReward;
        // count reward for locked stake during lockup epochs
        fullReward = _newRewardsOf(
            SFC,
            lockedStake,
            toValidatorID,
            stashedUntil,
            lockedUntil
        );
        Rewards memory plReward = _scaleLockupReward(fullReward, duration);
        // count reward for unlocked stake during lockup epochs
        fullReward = _newRewardsOf(
            SFC,
            unlockedStake,
            toValidatorID,
            stashedUntil,
            lockedUntil
        );
        Rewards memory puReward = _scaleLockupReward(fullReward, 0);
        // count lockup reward for unlocked stake during unlocked epochs
        fullReward = _newRewardsOf(
            SFC,
            wholeStake,
            toValidatorID,
            lockedUntil,
            payableUntil
        );
        Rewards memory wuReward = _scaleLockupReward(fullReward, 0);

        return _sumRewards(plReward, puReward, wuReward);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
library StorageSlotUpgradeable {
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
// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

abstract contract SpiritTwilightFarmInterface {
    bool public isRainFarmer = true;
    bytes32 public contractNameHash;

    /*** admin setters and farm control ***/
    function pullNewRain(address pullRainFromAddress, uint256 pullRainAmount)
        external
        virtual;

    function extendWithExistingConfiguration(
        address pullRainFromAddress,
        uint256 pullRainAmount
    ) external virtual;

    function restartWithNewConfiguration(
        uint256 _newStartTime,
        uint256 newDistributionPeriod,
        address pullRainFromAddress,
        uint256 pullRainAmount
    ) external virtual;

    /*** farm accounting and indexes ***/
    function updateFarmIndex() external virtual;

    function updateFarmerIndex(address farmer) external virtual;

    // *** user interactions - deposit, withdraw, claim rain ***/
    function depositToFarm(uint256 amount) external virtual;

    function depositToFarmOnBehalf(address farmer, uint256 amount)
        external
        virtual;

    function withdrawAllFromFarm() external virtual;

    function withdrawFromFarm(uint256 amount) external virtual;

    function claimRainFromFarm(address farmer) external virtual;

    function claimRainFromFarmToSomeFarmers(address[] calldata farmers)
        external
        virtual;

    // *** emergency ***
    function emergencyWithdrawFromFarm() external virtual;

    // *** admin ***
    function _setPendingAdmin(address newPendingAdmin)
        external
        virtual
        returns (uint256);

    function _acceptAdmin() external virtual returns (uint256);
}

interface IERC20ForRainFarmer {
    function decimals() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

abstract contract RainFarmerAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;
}

abstract contract SpiritTwilightFarmStorage is RainFarmerAdminStorage {
    // ******* rain data *******

    uint256 public budget;

    /// @notice Represented in seconds
    uint256 public startTime; // startBlock;
    uint256 public distributionPeriod; // distributionBlocks;

    // ******* specific farm data *******

    address public immutable rainToken;
    uint256 public immutable rainTokenUnit;

    /// @notice LP token
    address public immutable farmToken;

    // struct FarmMetaState {
    //     bool isListed;

    //     /// @notice a fraction between 0-1. The sum of all speeds should be 1 (1e18)
    //     uint rate;

    //     /// @notice how many rainTokens the farm gets per second
    //     uint speed;
    // }
    // FarmMetaState public farmMetaState;

    uint256 public farmSpeed;

    struct FarmCurrentState {
        /// @notice The farm's last updated index
        uint256 index;
        /// @notice The timestamp the index was last updated at
        uint256 timestamp;
        /// @notice The totalSupply deposited in farm token
        uint256 totalSupply;
    }
    FarmCurrentState public farmCurrentState;

    // ******* user data *******

    struct FarmerCurrentState {
        /// @notice The farmer's last updated index
        uint256 index;
        /// @notice The prinicipal of farm tokens that the farmer currently has in the farm
        uint256 supply;
    }
    /// @notice farmer address => farmer current state
    mapping(address => FarmerCurrentState) public farmersCurrentState;

    /// @notice The amount of rain tokens accrued but not yet transferred to each farmer
    mapping(address => uint256) public farmersRainfall;

    constructor(address _rainToken, address _farmToken) {
        rainToken = _rainToken;
        farmToken = _farmToken;

        uint256 rainTokenDecimals = IERC20ForRainFarmer(_rainToken).decimals();
        rainTokenUnit = 10**rainTokenDecimals; // state
    }
}

contract SpiritTwilightFarm is
    SpiritTwilightFarmStorage,
    SpiritTwilightFarmInterface
{
    // ******* constants *******

    bytes32 public constant SPIRIT_TWILIGHT_FARM =
        keccak256("SpiritTwilightFarm");

    // V1.0
    uint256 public constant version = 100;

    /// @notice The initial index for a farm
    uint256 public constant farmInitialIndex = 1e36;
    uint256 public constant baseUnit = 1e18;

    uint256 public constant minDistributionPeriod = 7 days;

    bool private _nonreentranceLock = false;

    // ******* events *******

    /**
     * @notice Emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    event FarmAdded(address rainToken, address farmToken);

    event DistributedRainToFarmer(
        address farmer,
        uint256 deltaFarmerRainfall,
        uint256 farmIndex
    );

    event DistributionPeriodSet(
        uint256 oldDistributionPeriod,
        uint256 newDistributionPeriod
    );

    event StartTimeSet(uint256 oldStartTime, uint256 startTime);

    event BudgetSet(uint256 oldBudget, uint256 newBudget);

    // ******* constructor *******

    constructor(
        address _admin,
        address _rainToken,
        address lpToken
    ) SpiritTwilightFarmStorage(_rainToken, lpToken) {
        contractNameHash = SPIRIT_TWILIGHT_FARM;
        admin = _admin; // state

        // farmSpeed = 0;
        uint256 currentTime = getCurrentTime();
        FarmCurrentState storage farmCurrentState = farmCurrentState;
        farmCurrentState.index = farmInitialIndex; // state
        farmCurrentState.timestamp = currentTime; // state
        // farmCurrentState.totalSupply = 0;
        emit FarmAdded(_rainToken, lpToken);
    }

    modifier nonreentrance() {
        require(!_nonreentranceLock, "Reentrance not allowed");
        _nonreentranceLock = true;
        _;
        _nonreentranceLock = false;
    }

    // ******* getters *******

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @return the (derived) timestamp in which the distribution ends
     */
    function endTime() public view returns (uint256) {
        return startTime + distributionPeriod;
    }

    /**
     * @return the address of the rain token
     */
    function getRainToken() public view returns (address) {
        return rainToken;
    }

    function getFarmSpeed() external view returns (uint256) {
        return farmSpeed;
    }

    /**
     * @return the amount of rainToken committed since 'startTimeStamp'
     */
    function budgetCommitmentUntilNow() public view returns (uint256) {
        uint256 currentTime = getCurrentTime();
        if (currentTime >= endTime()) {
            return budget;
        }

        uint256 _startTime = startTime;
        if (
            currentTime <= _startTime || budget == 0 || distributionPeriod == 0
        ) {
            return 0;
        }

        uint256 deltaSeconds = currentTime - _startTime;
        uint256 scaledRatio = (deltaSeconds * farmInitialIndex) /
            distributionPeriod;
        uint256 rainCommitted = (scaledRatio * budget) / farmInitialIndex;

        return rainCommitted;
    }

    /**
     * @return the amount of rain tokens that are not yet committed to distribution in the current distribution period.
     * DEV_NOTE : If state is 'fresh' this should return the value of 'budget'
     */
    function getRemainingBudget() public view returns (uint256) {
        uint256 rainCommitment = budgetCommitmentUntilNow();

        if (budget <= rainCommitment) {
            return 0;
        } else {
            return budget - rainCommitment;
        }
    }

    /**
     * @return total rain being emitted to the farm per second
     */
    function getTotalRainSpeed(uint256 totalRain, uint256 totalSeconds)
        public
        pure
        returns (uint256)
    {
        if (totalRain == 0 || totalSeconds == 0) {
            return 0;
        }
        /// @notice if rainToken decimals are small there might be a significant rounding error here
        return totalRain / totalSeconds;
    }

    // ******* farm control *******

    function pullNewRain(address pullRainFromAddress, uint256 pullRainAmount)
        external
        override
        nonreentrance
    {
        pullNewRainInternal(pullRainFromAddress, pullRainAmount);
    }

    /**
     * @notice pullNewRain from a general address using transferFrom
     * @notice Requires re-calculating the farm's speed
     * @notice admin can always add budget but can't change the rainfall configuration, including startTime
     * @notice requires getting the farm's index up to date -- happens in calculateFarmSpeed()
     * @notice may be called by anyone
     * @param pullRainFromAddress an address from which rain tokens will be pulled. Must be approved previously.
     * @param pullRainAmount the amount of rain tokens to pull from 'pullbudgetFrom'
     */
    function pullNewRainInternal(
        address pullRainFromAddress,
        uint256 pullRainAmount
    ) internal {
        uint256 rainGained = 0;

        if (pullRainAmount > 0) {
            rainGained += pullRainFromAddressInternal(
                pullRainFromAddress,
                pullRainAmount
            );
        }

        increaseBudget(rainGained);

        calculateFarmSpeed();
    }

    /**
     * @notice The common function to call for continuing the emission program as is
     * @notice sets 'startTime' to now
     * @notice doesn't let changing 'distributionPeriod'
     * @notice only allows for pulling new rain
     * @notice requires getting the farm's index up to date -- happens in setRainfallConfigurationInternal()
     */
    function extendWithExistingConfiguration(
        address pullRainFromAddress,
        uint256 pullRainAmount
    ) external override nonreentrance {
        require(isAdmin(), "!admin");

        setRainfallConfigurationInternal(0, 0);

        pullNewRainInternal(pullRainFromAddress, pullRainAmount);
    }

    /**
     * @notice Setter for rainfall configuration - startTime and distributionPeriod
     * @notice Not allowed while an active distribution is taking place
     * @notice requires getting the farm's index up to date -- happens in setRainfallConfigurationInternal()
     * @param _newStartTime the new starting time to be set
     * @param newDistributionPeriod the new distribution period to be set
     */
    function restartWithNewConfiguration(
        uint256 _newStartTime,
        uint256 newDistributionPeriod,
        address pullRainFromAddress,
        uint256 pullRainAmount
    ) external override nonreentrance {
        require(isAdmin(), "!admin");

        uint256 currentTime = getCurrentTime();
        require(currentTime > endTime(), "not during active distribution");

        setRainfallConfigurationInternal(_newStartTime, newDistributionPeriod);

        pullNewRainInternal(pullRainFromAddress, pullRainAmount);
    }

    // ******* internal setters *******

    function setRainfallConfigurationInternal(
        uint256 _newStartTime,
        uint256 newDistributionPeriod
    ) internal {
        setRemainingBudget();

        setStartTime(_newStartTime);

        /// @notice 'newDistributionPeriod' = 0 implies distribution period stays as is
        if (newDistributionPeriod != 0) {
            setDistributionPeriodInternal(newDistributionPeriod);
        }

        updateFarmIndexInternal(0, 0);
    }

    function increaseBudget(uint256 budgetToAdd) internal {
        uint256 currentBudget = getRemainingBudget();
        setBudgetInternal(currentBudget + budgetToAdd);
    }

    function setRemainingBudget() internal {
        uint256 remainingBudget = getRemainingBudget();
        setBudgetInternal(remainingBudget);
    }

    // ******* single param setters *******

    /// @notice _newStartTime = 0 implies setting startTime to currentTime
    function setStartTime(uint256 _newStartTime) internal {
        uint256 currentTime = getCurrentTime();
        uint256 newStartTime = _newStartTime == 0 ? currentTime : _newStartTime;
        require(newStartTime >= currentTime, "cannot start in the past");
        uint256 oldStartTime = startTime;
        startTime = newStartTime;
        emit StartTimeSet(oldStartTime, startTime);
    }

    function setBudgetInternal(uint256 newBudget) internal {
        uint256 oldBudget = budget;
        budget = newBudget;
        emit BudgetSet(oldBudget, newBudget);
    }

    function setDistributionPeriodInternal(uint256 newDistributionPeriod)
        internal
    {
        require(
            newDistributionPeriod > minDistributionPeriod,
            "Distribution period too short"
        );
        uint256 oldDistributionPeriod = distributionPeriod;
        distributionPeriod = newDistributionPeriod;
        emit DistributionPeriodSet(
            oldDistributionPeriod,
            newDistributionPeriod
        );
    }

    // ******* rain token accounting and speeds (internal logic) *******

    /**
     * @notice Sets the rain speeds using the current budget and the time left to distribute it
     * @notice Any change to the budget should occur before calling this function
     */
    function calculateFarmSpeed() internal {
        uint256 currentTime = getCurrentTime();
        uint256 _endTime = endTime();
        uint256 _startTime = startTime;
        uint256 finalTime = currentTime > _endTime ? _endTime : currentTime;
        uint256 initialTime = currentTime < _startTime
            ? _startTime
            : currentTime;
        uint256 deltaSeconds = finalTime > initialTime
            ? finalTime - initialTime
            : 0;
        uint256 totalRainSpeed = getTotalRainSpeed(budget, deltaSeconds);

        updateFarmIndexInternal(0, 0);
        farmSpeed = totalRainSpeed; // state
    }

    function updateFarmIndex() external override nonreentrance {
        updateFarmIndexInternal(0, 0);
    }

    /**
     * @notice Accrue rain token to a given farm by updating its index
     * @dev index is a cumulative sum of rain token gained per farm token from the beginning of time.
     */
    function updateFarmIndexInternal(
        uint256 supplyAddition,
        uint256 supplyReduction
    ) internal {
        FarmCurrentState storage farmCurrnetState = farmCurrentState;
        uint256 _farmSpeed = farmSpeed;

        uint256 farmBlock = farmCurrnetState.timestamp;
        uint256 currentTime = getCurrentTime();
        uint256 _endTime = endTime();
        uint256 _startTime = startTime;
        uint256 finalTime = currentTime > _endTime ? _endTime : currentTime; // min(current,end)
        uint256 initialTime = _startTime > farmBlock ? _startTime : farmBlock; // max(start,farm)
        // TODO : build an example where 1st condition doesn't hold but the 2nd does
        bool isDeltaSecondsZero = _startTime > currentTime ||
            initialTime > finalTime;
        uint256 deltaSeconds = isDeltaSecondsZero ? 0 : finalTime - initialTime;
        if (deltaSeconds > 0 && _farmSpeed > 0) {
            uint256 totalSupply = farmCurrnetState.totalSupply;
            uint256 rainfall = deltaSeconds * _farmSpeed;
            uint256 ratio = totalSupply > 0
                ? (rainfall * farmInitialIndex) / totalSupply
                : 0;
            farmCurrnetState.index += ratio; // state
            farmCurrnetState.timestamp = currentTime; // state
        } else if (deltaSeconds > 0) {
            farmCurrnetState.timestamp = currentTime; // state
        }
        if (supplyAddition > 0) {
            farmCurrnetState.totalSupply += supplyAddition; // state
        } else if (supplyReduction > 0) {
            farmCurrnetState.totalSupply -= supplyReduction; // state
        }
    }

    function updateFarmerIndex(address farmer) external override nonreentrance {
        updateFarmerIndexInternal(farmer, 0, 0);
    }

    /**
     * @notice Calculate rainfall to a specific farmer in a given farm and possibly transfer it to them
     * @param farmer The address of the farmer
     */
    function updateFarmerIndexInternal(
        address farmer,
        uint256 supplyAddition,
        uint256 supplyReduction
    ) internal {
        FarmCurrentState memory farmCurrentState = farmCurrentState;
        uint256 farmIndex = farmCurrentState.index;
        FarmerCurrentState storage farmerCurrentState = farmersCurrentState[
            farmer
        ];
        uint256 farmerIndex = farmerCurrentState.index;

        require(farmerIndex >= farmInitialIndex, "farmer never deposited");
        require(
            farmIndex >= farmerIndex,
            "farmer can't be more advanced than farm"
        );

        uint256 deltaIndex = farmIndex - farmerIndex;
        uint256 farmerTokens = farmerCurrentState.supply;
        uint256 deltaFarmerRainfall;
        if (deltaIndex > 0) {
            // Calculate new rain accrued: farmerTokens * accruedPerToken
            deltaFarmerRainfall =
                (farmerTokens * deltaIndex) /
                farmInitialIndex;
            uint256 totalFarmerRainfall = farmersRainfall[farmer] +
                deltaFarmerRainfall;
            farmersRainfall[farmer] = totalFarmerRainfall; // state
        }

        // Update farmer's supply if supplyAddition > 0 or supplyReduction > 0
        if (supplyAddition > 0) {
            farmerCurrentState.supply += supplyAddition; // state
        } else if (supplyReduction > 0) {
            /// @notice important - must fail if farmerCurrentState.supply < supplyReduction
            farmerCurrentState.supply -= supplyReduction; // state
        }
        // Update farmer's index
        if (farmerCurrentState.supply == 0) {
            // if the farmer's supply is 0 we can set the index to 0 as well
            farmerCurrentState.index = 0; // state
        } else {
            // if the farmer's supply isn't 0 we set his index to the current indexof the farm
            farmerCurrentState.index = farmIndex; // state
        }

        emit DistributedRainToFarmer(farmer, deltaFarmerRainfall, farmIndex);
    }

    function InitializeFarmerIndexInFarmInternal(
        address farmer,
        uint256 supplyAddition
    ) internal {
        FarmCurrentState memory farmCurrentState = farmCurrentState;
        uint256 farmIndex = farmCurrentState.index;
        FarmerCurrentState storage farmerCurrentState = farmersCurrentState[
            farmer
        ];

        /// @notice index was already checked
        require(
            farmerCurrentState.index == 0 && farmerCurrentState.supply == 0,
            "already initialized"
        );

        // state changes
        // Update farmer's index to the current index since we are distributing accrued rain token
        farmerCurrentState.index = farmIndex; // state
        farmerCurrentState.supply = supplyAddition; // state
        /// @notice not changing farmersRainfall[farmer]

        emit DistributedRainToFarmer(farmer, 0, farmIndex);
    }

    function emergencyUpdateFarmerIndexInternal(address farmer) internal {
        FarmerCurrentState storage farmerCurrentState = farmersCurrentState[
            farmer
        ];
        farmerCurrentState.supply = 0; // state
        farmerCurrentState.index = 0; // state
    }

    // ******* user interactions - deposit, withdraw, claim rain *******

    function depositToFarm(uint256 amount) external override nonreentrance {
        address account = msg.sender;
        depositToFarmInternal(account, account, amount);
    }

    function depositToFarmOnBehalf(address farmer, uint256 amount)
        external
        override
        nonreentrance
    {
        depositToFarmInternal(farmer, msg.sender, amount);
    }

    function depositToFarmInternal(
        address farmer,
        address payer,
        uint256 amount
    ) internal {
        uint256 currentTime = getCurrentTime();
        require(currentTime < endTime(), "too late");

        amount = pullFarmTokens(payer, amount);

        updateFarmIndexInternal(amount, 0); // state changes: farm index + farm timestamp + farm total supply

        FarmerCurrentState memory farmerCurrentState = farmersCurrentState[
            farmer
        ];
        if (farmerCurrentState.index == 0) {
            InitializeFarmerIndexInFarmInternal(farmer, amount);
        } else {
            updateFarmerIndexInternal(farmer, amount, 0);
        }
    }

    function pullFarmTokens(address payer, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 balanceBefore = IERC20ForRainFarmer(farmToken).balanceOf(
            address(this)
        );
        TransferHelper.safeTransferFrom(
            farmToken,
            payer,
            address(this),
            amount
        );
        uint256 balanceAfter = IERC20ForRainFarmer(farmToken).balanceOf(
            address(this)
        );
        return balanceAfter - balanceBefore;
    }

    function withdrawAllFromFarm() external override nonreentrance {
        address farmer = msg.sender;
        FarmerCurrentState memory farmerCurrentState = farmersCurrentState[
            farmer
        ];
        withdrawFromFarmInternal(farmer, farmerCurrentState.supply);
    }

    function withdrawFromFarm(uint256 amount) external override nonreentrance {
        withdrawFromFarmInternal(msg.sender, amount);
    }

    /// @notice withdraw always claims from farm, to only withdraw set amount=0
    function withdrawFromFarmInternal(address farmer, uint256 amount) internal {
        claimRainFromFarmInternal(farmer, amount);
        if (amount > 0) {
            sendFarmTokens(farmer, amount);
        }
    }

    function sendFarmTokens(address farmer, uint256 amount) internal {
        TransferHelper.safeTransfer(farmToken, farmer, amount);
    }

    /**
     * @notice Claim all the rain accrued by farmer in the farm
     * @param farmer The address to claim rain for
     */
    function claimRainFromFarm(address farmer) external override nonreentrance {
        address[] memory farmers = new address[](1);
        farmers[0] = farmer;
        return claimRainFromFarmToSomeFarmersInternal(farmers);
    }

    /**
     * @notice Claim all the rain accrued by farmers in the farm
     * @param farmers The addresses to claim rain for
     */
    function claimRainFromFarmToSomeFarmers(address[] calldata farmers)
        external
        override
        nonreentrance
    {
        claimRainFromFarmToSomeFarmersInternal(farmers);
    }

    function claimRainFromFarmToSomeFarmersInternal(address[] memory farmers)
        internal
    {
        updateFarmIndexInternal(0, 0);
        for (uint256 j = 0; j < farmers.length; j++) {
            address farmer = farmers[j];
            updateFarmerIndexInternal(farmer, 0, 0);
            farmersRainfall[farmer] = transferRainInternal(
                farmer,
                farmersRainfall[farmer]
            ); // state
        }
    }

    function claimRainFromFarmInternal(address farmer, uint256 amount)
        internal
    {
        updateFarmIndexInternal(0, amount);
        updateFarmerIndexInternal(farmer, 0, amount);
        farmersRainfall[farmer] = transferRainInternal(
            farmer,
            farmersRainfall[farmer]
        ); // state
    }

    /**
     * @param farmer The address of the farmer to transfer rain tokens to
     * @param amount The amount of rain tokens to (possibly) transfer
     * @return The amount of rain tokens owed by the contract to the user after this function executes
     */
    function transferRainInternal(address farmer, uint256 amount)
        internal
        returns (uint256)
    {
        address _rainToken = rainToken;
        uint256 rainTokenRemaining = IERC20ForRainFarmer(_rainToken).balanceOf(
            address(this)
        );
        if (amount > 0 && amount <= rainTokenRemaining) {
            TransferHelper.safeTransfer(_rainToken, farmer, amount);
            return 0;
        }
        return amount;
    }

    // ******* pulling rain *******

    function pullRainFromAddressInternal(
        address pullRainFromAddress,
        uint256 pullRainAmount
    ) internal returns (uint256 rainTokensGain) {
        address _rainToken = rainToken;
        uint256 balanceBefore = IERC20ForRainFarmer(_rainToken).balanceOf(
            address(this)
        );
        TransferHelper.safeTransferFrom(
            rainToken,
            pullRainFromAddress,
            address(this),
            pullRainAmount
        );
        uint256 balanceAfter = IERC20ForRainFarmer(_rainToken).balanceOf(
            address(this)
        );
        rainTokensGain = balanceAfter - balanceBefore;
    }

    // ******* admin *******

    /**
     * @notice Checks caller is admin
     */
    function isAdmin() internal view returns (bool) {
        return msg.sender == admin;
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPendingAdmin(address newPendingAdmin)
        external
        override
        nonreentrance
        returns (uint256)
    {
        // Check caller = admin
        require(isAdmin(), "!admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return 0;
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptAdmin() external override nonreentrance returns (uint256) {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "Not the EXISTING pending admin"
        );

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return 0;
    }

    // ******* emergency *******

    function emergencyWithdrawFromFarm() external override nonreentrance {
        address farmer = msg.sender;
        emergencyWithdrawFromFarmInternal(farmer);
        farmersRainfall[farmer] = 0; // state
    }

    function emergencyWithdrawFromFarmInternal(address farmer) internal {
        FarmerCurrentState memory farmerCurrentState = farmersCurrentState[
            farmer
        ];
        uint256 amount = farmerCurrentState.supply;
        require(amount > 0, "nothing to withdraw");
        emergencyUpdateFarmerIndexInternal(farmer);
        sendFarmTokens(farmer, amount);
    }
}

interface IPairForFarm {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

struct FarmData {
    address addr;
    address token0;
    address token1;
    address farmToken; // LP token
    address rainToken; // reward token
    uint256 speed;
    uint256 endTime;
}

contract SpiritTwilightFarmUniFactory {
    address public owner;
    SpiritTwilightFarm[] public farms;
    uint256 public newFarmFee = 1 ether;

    mapping(address => SpiritTwilightFarm) public farmByLP;
    mapping(SpiritTwilightFarm => bool) public farmIsVerified;

    address public constant SPIRIT_FACTORY =
        address(0xEF45d134b73241eDa7703fa787148D9C9F4950b0);
    bytes32 public constant PAIR_CODE_HASH =
        bytes32(
            0xe242e798f6cee26a9cb0bbf24653bf066e5356ffeac160907fe2cc108e238617
        );

    event NewFarm(address indexed farm, address indexed lpToken);
    event DeleteFarm(address indexed farm, address indexed lpToken);
    event VerifyFarm(
        address indexed farm,
        address indexed lpToken,
        bool verified
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!Auth");
        _;
    }

    function transferOwnership(address _owner) external onlyOwner {
        owner = _owner;
    }

    function newFarm(
        address admin,
        address rainToken,
        address lpToken,
        bool verifiedFarm
    ) external payable returns (SpiritTwilightFarm farm) {
        require(msg.value >= newFarmFee, "Not enough fee");
        verifyLpToken(lpToken);

        farm = new SpiritTwilightFarm(admin, rainToken, lpToken);
        farms.push(farm);
        farmByLP[lpToken] = farm;
        farmIsVerified[farm] = verifiedFarm;

        emit NewFarm(address(farm), lpToken);
    }

    function withdrawFee() external {
        uint256 feeBal = address(this).balance;
        payable(owner).transfer(feeBal);
    }

    function deleteFarm(address lpToken, uint256 farmIndex) external onlyOwner {
        SpiritTwilightFarm farm = farms[farmIndex];
        require(farmByLP[lpToken] == farm, "Wrong lpToken or index");

        farms[farmIndex] = farms[farms.length - 1];
        farms.pop();

        delete farmByLP[lpToken];
        delete farmIsVerified[farm];

        emit DeleteFarm(address(farm), lpToken);
    }

    function getFarmData(SpiritTwilightFarm farm)
        public
        view
        returns (FarmData memory)
    {
        IPairForFarm pair = IPairForFarm(farm.farmToken());
        return
            FarmData(
                address(farm), // farm addr
                pair.token0(), // token0
                pair.token1(), // toke1
                address(pair), // farm token - lp for token0 and toke1
                farm.rainToken(), // reward token
                farm.farmSpeed(), // reward token emitted per second
                farm.endTime() // end timestamp of distribution
            );
    }

    function getFilteredFarms(bool verified)
        public
        view
        returns (FarmData[] memory)
    {
        FarmData[] memory _farmDatas = new FarmData[](farms.length);
        SpiritTwilightFarm[] memory _farms = farms;
        uint256 counter = 0;
        uint256 index = 0;

        for (; index < _farms.length; index++) {
            if (verified == farmIsVerified[_farms[index]]) {
                FarmData memory data = getFarmData(_farms[index]);
                _farmDatas[counter] = data;
                counter++;
            }
        }

        FarmData[] memory farmDatas = new FarmData[](counter);
        for (index = 0; index < counter; index++) {
            farmDatas[index] = _farmDatas[index];
        }

        return farmDatas;
    }

    function getAllVerifiedFarms() external view returns (FarmData[] memory) {
        return getFilteredFarms(true);
    }

    function getAllUnverifiedFarms() external view returns (FarmData[] memory) {
        return getFilteredFarms(false);
    }

    function verifyFarm(address lpToken, bool verified) external onlyOwner {
        SpiritTwilightFarm farm = farmByLP[lpToken];
        require(address(0) != address(farm), "Farm doesn't exist");
        farmIsVerified[farm] = verified;

        emit VerifyFarm(address(farm), lpToken, verified);
    }

    // calculates the CREATE2 address for a pair without making any external calls
    /// @notice must token0 < token1
    function pairFor(address token0, address token1)
        public
        pure
        returns (address pair)
    {
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            SPIRIT_FACTORY,
                            keccak256(abi.encodePacked(token0, token1)),
                            PAIR_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    function verifyLpToken(address lpToken) internal view {
        IPairForFarm pair = IPairForFarm(lpToken);
        address token0 = pair.token0();
        address token1 = pair.token1();
        require(pairFor(token0, token1) == lpToken, "Bad lpToken");
    }
}
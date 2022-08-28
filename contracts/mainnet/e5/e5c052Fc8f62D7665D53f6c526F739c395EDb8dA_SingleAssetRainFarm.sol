// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./RainFarmStorage.sol";
import "./RainFarmInterface.sol";
import "../../Tools/Helpers/TransferHelper.sol";

interface IERC20ForRainFarmer {
    function decimals() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
}

contract SingleAssetRainFarm is SingleAssetRainFarmStorage, RainFarmInterface {

    // ******* constants *******

    bytes32 public constant SingleAssetRainFarmContractHash = keccak256("SingleAssetRainFarm");

    // V1.0
    uint public constant version = 100;

    /// @notice The initial index for a farm
    uint public constant farmInitialIndex = 1e36;

    uint public constant baseUnit = 1e18;

    uint public immutable farmTokenUnit;
    uint public immutable rainTokenUnit;

    uint public immutable minDistributionPeriod;

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

    event FarmAdded(address indexed farmToken);

    event AllocatedRainToFarmer(address indexed farmer, uint deltaFarmerRainfall, uint farmIndex);

    event DistributionPeriodSet(uint oldDistributionPeriod, uint newDistributionPeriod);

    event StartTimeSet(uint oldStartTime, uint startTime);

    event BudgetSet(uint oldBudget, uint newBudget);

    event FarmSpeedSet(uint oldFarmSpeed, uint newFarmSpeed);


    // ******* constructor *******

    constructor(
        address _admin,
        uint _minDistributionPeriod,
        address _farmToken,
        address _rainToken
    ) SingleAssetRainFarmStorage(_rainToken, _farmToken) {
        contractNameHash = SingleAssetRainFarmContractHash;
        admin = _admin;

        uint farmTokenDecimals = IERC20ForRainFarmer(_farmToken).decimals();
        uint rainTokenDecimals = IERC20ForRainFarmer(_rainToken).decimals();

        farmTokenUnit = 10**farmTokenDecimals;
        rainTokenUnit = 10**rainTokenDecimals;

        // farmSpeed = 0;
        uint currentTime = getCurrentTime();
        FarmCurrentState storage farmCurrentState = farmCurrentState;
        farmCurrentState.index = farmInitialIndex; // state
        farmCurrentState.timestamp = currentTime; // state
        // farmCurrentState.totalSupply = 0;

        minDistributionPeriod = _minDistributionPeriod;

        emit FarmAdded(_farmToken);
    }

    modifier nonreentrance {
        require(!_nonreentranceLock, "Reentrance not allowed");
        _nonreentranceLock = true;
        _;
        _nonreentranceLock = false;
    }


    // ******* getters *******

    /**
     * @return the block timestamp.
     */
    function getCurrentTime() public view returns (uint) {
        return block.timestamp;
    }

    /**
     * @return the (derived) timestamp in which the distribution ends
     */
    function endTime() public view returns (uint) {
        return startTime + distributionPeriod;
    }

    /**
     * @return the address of the farm token
     */
    function getFarmToken() public view returns (address) {
        return farmToken;
    }

    /**
     * @return the address of the rain token
     */
    function getRainToken() public view returns (address) {
        return rainToken;
    }

    function getFarmSpeed() external view returns (uint) {
        return farmSpeed;
    }

    /**
     * @return the amount of rainToken committed since 'startTimeStamp'
     */
    function budgetCommitmentUntilNow() public view returns (uint) {
        uint currentTime = getCurrentTime();
        if (currentTime >= endTime()) {
            return budget;
        }

        uint _startTime = startTime;
        if (currentTime <= _startTime || budget == 0 || distributionPeriod == 0) {
            return 0;
        }

        uint deltaSeconds = currentTime - _startTime;
        uint rainCommitted = (deltaSeconds * farmSpeed);

        return rainCommitted;
    }

    /**
     * @return the amount of rain tokens that are not yet committed to distribution in the current distribution period.
     * DEV_NOTE : If state is 'fresh' this should return the value of 'budget'
     */
    function getRemainingBudget() public view returns (uint) {
        uint rainCommitment = budgetCommitmentUntilNow();

        if (budget <= rainCommitment) {
            return 0;
        } else {
            return budget - rainCommitment;
        }
    }

    /**
     * @return total rain being emitted to the farm per second
     */
    function getTotalRainSpeed(uint totalRain, uint totalSeconds) public pure returns (uint) {
        if (totalRain == 0 || totalSeconds == 0) {
            return 0;
        }
        /// @notice if rainToken decimals are small there might be a significant rounding error here
        return totalRain / totalSeconds;
    }

    // ******* admin ownership control *******

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPendingAdmin(address newPendingAdmin) override external nonreentrance returns (uint) {
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
    function _acceptAdmin() override external nonreentrance returns (uint) {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), "Not the EXISTING pending admin");

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

    // ******* admin setters and farm control *******

    /**
     * Allows admin to add rain to the program while keeping the current end time.
     * Any pulled rain will be used to increase the rainSpeed for the remaining time.
     */
    function pullNewRain(address pullRainFromAddress, uint pullRainAmount) override external nonreentrance {
        require(isAdmin(), "!admin");
        updateFarmIndexInternal();
        pullNewRainInternal(pullRainFromAddress, pullRainAmount);
    }

    /**
     * @notice The common function to call for continuing the emission program as is
     * @notice sets 'startTime' to now
     * @notice doesn't let changing 'distributionPeriod'
     * @notice only allows for pulling new rain
     * @notice requires getting the farm's index up to date -- happens in setRainfallConfigurationInternal()
     */
    function extendWithExistingConfiguration(address pullRainFromAddress, uint pullRainAmount) override external nonreentrance {
        require(isAdmin(), "!admin");
        updateFarmIndexInternal();

        uint currentTime = getCurrentTime();
        require(currentTime < endTime(), "cannot extend a finished program");

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
    function restartWithNewConfiguration(uint _newStartTime, uint newDistributionPeriod, address pullRainFromAddress, uint pullRainAmount) override external nonreentrance {
        require(isAdmin(), "!admin");
        updateFarmIndexInternal();

        uint currentTime = getCurrentTime();
        require(currentTime > endTime(), "not during active distribution");

        setRainfallConfigurationInternal(_newStartTime, newDistributionPeriod);

        pullNewRainInternal(pullRainFromAddress, pullRainAmount);
    }

    // ******* user interactions - deposit, withdraw, claim rain *******

    /**
     * Deposits to farm. nothing beyond that.
     */
    function depositToFarm(uint amount) override external nonreentrance {
        address farmer = msg.sender;
        updateFarmIndexInternal();
        updateFarmerIndexInternal(farmer);
        depositToFarmInternal(farmer, farmer, amount);
    }

    /**
     * Sender will deposit farm tokens on behalf of the farmer.
     */
    function depositToFarmOnBehalf(address farmer, uint amount) override external nonreentrance {
        updateFarmIndexInternal();
        updateFarmerIndexInternal(farmer);
        depositToFarmInternal(farmer, msg.sender, amount);
    }

    /**
     * Withdraws all of the farmer's (msg.sender) supply.
     * In addition, claims all rainfall.
     */
    function withdrawAllFromFarm() override external nonreentrance {
        address farmer = msg.sender;
        updateFarmIndexInternal();
        updateFarmerIndexInternal(farmer);
        withdrawFromFarmInternal(farmer, farmersCurrentSupply[farmer]);
    }

    /**
     * Withdraws a specific amount of the farmer's (msg.sender) supply.
     * In addition, claims all rainfall.
     */
    function withdrawFromFarm(uint amount) override external nonreentrance {
        address farmer = msg.sender;
        updateFarmIndexInternal();
        updateFarmerIndexInternal(farmer);
        withdrawFromFarmInternal(farmer, amount);
    }

    /**
     * @notice Claim all the rain accrued by farmer in the farm
     * @param farmer The address to claim rain for
     */
    function claimRainFromFarm(address farmer) override external nonreentrance {
        updateFarmIndexInternal();
        updateFarmerIndexInternal(farmer);
        address[] memory farmers = new address[](1);
        farmers[0] = farmer;
        return claimRainFromFarmToSomeFarmersInternal(farmers);
    }

    /**
     * @notice Claim all the rain accrued by farmers in the farm
     * @param farmers The addresses to claim rain for
     */
    function claimRainFromFarmToSomeFarmers(address[] calldata farmers) override external nonreentrance {
        updateFarmIndexInternal();
        for (uint j = 0; j < farmers.length; j++) {
            address farmer = farmers[j];
            updateFarmerIndexInternal(farmer);
        }
        claimRainFromFarmToSomeFarmersInternal(farmers);
    }

    // ******* emergency *******

    function emergencyWithdrawFromFarm() override external nonreentrance {
        address farmer = msg.sender;
        emergencyWithdrawFromFarmInternal(farmer);
        farmersRainfall[farmer] = 0; // state
    }

    // ******* rain token accounting and speeds (internal logic) *******

    /**
     * Allows to update the farm's stored state from outside.
     */
    function updateFarmIndex() override external nonreentrance {
        updateFarmIndexInternal();
    }

    /**
     * Allows to update the farmer's stored state from outside.
     */
    function updateFarmerIndex(address farmer) override external nonreentrance {
        updateFarmIndexInternal();
        updateFarmerIndexInternal(farmer);
    }

    // ******* internal setters *******

    /**
     * @notice Handles program configuration.
     * @param _newStartTime State time for the program, 0 means 'start now'.
     * @param _newDistributionPeriod Distribution period for the program, 0 means 'keep current'.
     */
    function setRainfallConfigurationInternal(uint _newStartTime, uint _newDistributionPeriod) internal {
        setRemainingBudget();

        setStartTime(_newStartTime);

        /// @notice 'newDistributionPeriod' = 0 implies distribution period stays as is
        if (_newDistributionPeriod != 0) {
            setDistributionPeriodInternal(_newDistributionPeriod);
        }
    }

    /*
     * Sets the budget stored value to the program's remaining budget plus the 'budgetToAdd'.
     * @param budgetToAdd Amount of rain tokens to add to the remaining budget.
     */
    function increaseBudget(uint budgetToAdd) internal {
        uint currentBudget = getRemainingBudget();
        setBudgetInternal(currentBudget + budgetToAdd);
    }

    /*
     * Sets the budget stored value ot the program's remaining budget.
     */
    function setRemainingBudget() internal {
        uint remainingBudget = getRemainingBudget();
        setBudgetInternal(remainingBudget);
    }

    // ******* single param setters *******

    /**
     * @notice Directly sets the program start time.
     * @param _newStartTime The wanted start time, must be in the future.
     *                      a 0 value means immediate start.
     */
    function setStartTime(uint _newStartTime) internal {
        uint currentTime = getCurrentTime();
        uint newStartTime = _newStartTime == 0 ? currentTime : _newStartTime;
        require(newStartTime >= currentTime, "cannot start in the past");
        uint oldStartTime = startTime;
        startTime = newStartTime;
        emit StartTimeSet(oldStartTime, startTime);
    }

    /**
     * @notice Directly sets the 'budget'
     */
    function setBudgetInternal(uint newBudget) internal {
        uint oldBudget = budget;
        budget = newBudget;
        emit BudgetSet(oldBudget, newBudget);
    }

    /**
     * @notice Directly sets the 'distributionPeriod'
     */
    function setDistributionPeriodInternal(uint newDistributionPeriod) internal {
        require(newDistributionPeriod > minDistributionPeriod, "Distribution period too short");
        uint oldDistributionPeriod = distributionPeriod;
        distributionPeriod = newDistributionPeriod;
        emit DistributionPeriodSet(oldDistributionPeriod, newDistributionPeriod);
    }

    /**
     * @notice Directly sets the 'farmSpeed'
     */
    function setFarmSpeed(uint newFarmSpeed) internal {
        uint oldFarmSpeed = farmSpeed;
        farmSpeed = newFarmSpeed;
        emit FarmSpeedSet(oldFarmSpeed, newFarmSpeed);
    }

    // ******* rain pulling *******

    /**
     * @notice pullNewRain from a general address using transferFrom
     * @notice Requires re-calculating the farm's speed
     * @notice admin can always add budget but can't change the rainfall configuration, including startTime
     * @notice requires getting the farm's index up to date -- happens in calculateFarmSpeed()
     * @notice may be called by anyone
     * @param pullRainFromAddress an address from which rain tokens will be pulled. Must be approved previously.
     * @param pullRainAmount the amount of rain tokens to pull from 'pullbudgetFrom'
     */
    function pullNewRainInternal(address pullRainFromAddress, uint pullRainAmount) internal {
        uint rainGained = 0;

        if (pullRainAmount > 0) {
            rainGained += pullRainTokens(pullRainFromAddress, pullRainAmount);
        }

        increaseBudget(rainGained);

        calculateFarmSpeed();
    }

    // ******* rain token accounting and speeds (internal logic) *******

    /**
     * @notice Sets the rain speeds using the current budget and the time left to distribute it
     * @notice Any change to the budget should occur before calling this function
     */
    function calculateFarmSpeed() internal {
        uint currentTime = getCurrentTime();
        uint _endTime = endTime();
        uint _startTime = startTime;
       
        uint finalTime = _endTime;
        uint initialTime = currentTime < _startTime ? _startTime : currentTime;

        uint distributionTimeframeLeft = finalTime > initialTime ? finalTime - initialTime : 0;
        uint totalRainSpeed = getTotalRainSpeed(budget, distributionTimeframeLeft);

        setFarmSpeed(totalRainSpeed);
    }

    /**
     * @notice Accrue rain token to a given farm by updating its index
     * @dev index is a cumulative sum of rain token gained per farm token from the beginning of time.
     */
    function updateFarmIndexInternal() internal {
        FarmCurrentState storage farmCurrnetState = farmCurrentState;
        uint _farmSpeed = farmSpeed;

        // Note : This part needs to know the actual 'program active run time' in seconds since the last 'farm index' calculation
        //         (not counting any time after the program end)
        uint farmTimestamp = farmCurrnetState.timestamp;
        uint currentTime = getCurrentTime();
        uint _endTime = endTime();
        uint _startTime = startTime;
        uint finalTime = currentTime > _endTime ? _endTime : currentTime; // min(current,end)
        uint initialTime = _startTime > farmTimestamp ? _startTime : farmTimestamp; // max(start,farm)
        bool isDeltaSecondsZero = _startTime > currentTime || initialTime > finalTime;
        uint deltaSeconds = isDeltaSecondsZero ? 0 : finalTime - initialTime;

        if (deltaSeconds > 0 && _farmSpeed > 0) {
            uint _totalSupply = totalSupply;
            uint rainfall = deltaSeconds * _farmSpeed;
            uint ratio = _totalSupply > 0 ? (rainfall * farmInitialIndex) / _totalSupply : 0;
            farmCurrnetState.index += ratio; // state
        }
        
        if (farmTimestamp < currentTime) {
            farmCurrnetState.timestamp = currentTime; // state
        }
    }

    function updateFarmSupplyInternal(uint supplyAddition, uint supplyReduction) internal {
        if (supplyAddition > 0) {
            totalSupply += supplyAddition; // state
        } else if (supplyReduction > 0) {
            require(totalSupply >= supplyReduction, "more than farm balance");
            totalSupply -= supplyReduction; // state
        }
    }

    /**
     * @notice Calculate rainfall to a specific farmer in a given farm and possibly transfer it to them
     * @param farmer The address of the farmer
     */
    function updateFarmerIndexInternal(address farmer) internal {
        FarmCurrentState memory farmCurrentState = farmCurrentState;
        uint farmIndex = farmCurrentState.index;
        uint farmerIndex = farmersCurrentIndex[farmer];
        uint deltaFarmerRainfall;

        require(farmIndex >= farmerIndex, "farmer can't be more advanced than farm");

        if (farmerIndex > 0) {
            uint deltaIndex = farmIndex - farmerIndex;
            uint farmerTokens = farmersCurrentSupply[farmer];
            if (deltaIndex > 0) {
                // Calculate new rain accrued: farmerTokens * accruedPerToken
                deltaFarmerRainfall = (farmerTokens * deltaIndex) / farmInitialIndex;
                uint totalFarmerRainfall = farmersRainfall[farmer] + deltaFarmerRainfall;
                farmersRainfall[farmer] = totalFarmerRainfall; // state
            }
        }

        farmersCurrentIndex[farmer] = farmIndex; // state

        emit AllocatedRainToFarmer(farmer, deltaFarmerRainfall, farmIndex);
    }

    /**
     * @notice Properly and safely adds/reduces the amount to both the farmer's and the farm's supply
     * @param farmer The farmer
     * @param supplyAddition Amount to add
     * @param supplyReduction Amount to reduce
     */
    function updateFarmerSupplyInternal(address farmer, uint supplyAddition, uint supplyReduction) internal {
        // Update farmer's supply if supplyAddition > 0 or supplyReduction > 0
        if (supplyAddition > 0) {
            farmersCurrentSupply[farmer] += supplyAddition; // state
        } else if (supplyReduction > 0) {
            /// @notice important - must fail if farmerCurrentState.supply < supplyReduction
            require(farmersCurrentSupply[farmer] >= supplyReduction, "more than farmer balance");
            farmersCurrentSupply[farmer] -= supplyReduction; // state
        }
        updateFarmSupplyInternal(supplyAddition, supplyReduction);
    }

    /**
     * @notice Zeros farmer's index and supply.
     */
    function emergencyUpdateFarmerIndexInternal(address farmer) internal {
        farmersCurrentIndex[farmer] = 0; // state
        farmersCurrentSupply[farmer] = 0; // state
    }

    // ******* user interactions - deposit, withdraw, claim rain *******

    /**
     * @notice Handles all deposit logic.
     * Will not allow to deposit when there is neither active program nor a planned one.
     * @param farmer The account that will get the farm tokens added to their supply.
     * @param payer The account that will have the farm tokens pulled from.
     * @param amount The farm tokens to pull.
     */
    function depositToFarmInternal(address farmer, address payer, uint amount) internal {
        uint currentTime = getCurrentTime();
        require(currentTime < endTime(), "too late");

        amount = pullFarmTokens(payer, amount);
        
        updateFarmerSupplyInternal(farmer, amount, 0);
    }

    /**
     * @notice withdraw always claims from farm, to only withdraw set amount=0
     * @param farmer The withdrawing farmer.
     * @param amount The withdrawal amount
     */
    function withdrawFromFarmInternal(address farmer, uint amount) internal {
        claimRainFromFarmInternal(farmer);
        if (amount > 0) {
            updateFarmerSupplyInternal(farmer, 0, amount);
            sendFarmTokens(farmer, amount);
        }
    }

    /*
     * @notice Claims the rainfall for all given farmers.
     * @param farmers The farmers to claim rainfall for.
     */
    function claimRainFromFarmToSomeFarmersInternal(address[] memory farmers) internal {
        for (uint j = 0; j < farmers.length; j++) {
            address farmer = farmers[j];
            farmersRainfall[farmer] = transferRainInternalSafe(farmer, farmersRainfall[farmer]); // state
        }
    }

    /**
     * @notice Safe-Transfer to the farmer's the entire rainfall the address deserves
     *         and updates the remaining rainfall.
     * @param farmer The farmer to claim rainfall for.
     */
    function claimRainFromFarmInternal(address farmer) internal {
        farmersRainfall[farmer] = transferRainInternalSafe(farmer, farmersRainfall[farmer]); // state
    }

    // ******* Farm&Rain Tokens interactions *******

    /**
     * @notice Safe transfer farm token from this contract.
     * @param payer The paying account.
     * @param amount The amount to send.
     */
    function pullFarmTokens(address payer, uint amount) internal returns (uint farmTokensGain) {
        address _farmToken = farmToken;

        uint balanceBefore = IERC20ForRainFarmer(_farmToken).balanceOf(address(this));
        TransferHelper.safeTransferFrom(_farmToken, payer, address(this), amount);
        uint balanceAfter = IERC20ForRainFarmer(_farmToken).balanceOf(address(this));

        farmTokensGain = balanceAfter - balanceBefore;
        require(farmTokensGain == amount, "must receive exact amount");
    }

    /**
     * A simple 'transferFrom' from the 'pullRainFromAddress' to this contract
     * with sanity checks to ensure this contract got the exact amount.
     * @param pullRainFromAddress The address to pull the rain from.
     * @param pullRainAmount The amount of rain to pull.
     */
    function pullRainTokens(address pullRainFromAddress, uint pullRainAmount) internal returns (uint rainTokensGain) {
        address _rainToken = rainToken;

        uint balanceBefore = IERC20ForRainFarmer(_rainToken).balanceOf(address(this));
        TransferHelper.safeTransferFrom(rainToken, pullRainFromAddress, address(this), pullRainAmount);
        uint balanceAfter = IERC20ForRainFarmer(_rainToken).balanceOf(address(this));

        rainTokensGain = balanceAfter - balanceBefore;
        require(rainTokensGain == pullRainAmount, "must receive exact amount");
    }

    /**
     * @notice Safe transfer farm token from this contract.
     * @param farmer The receiving farmer.
     * @param amount The amount to send.
     */
    function sendFarmTokens(address farmer, uint amount) internal {
        TransferHelper.safeTransfer(farmToken, farmer, amount);
    }

    /**
     * @param farmer The address of the farmer to transfer rain tokens to
     * @param amount The amount of rain tokens to (possibly) transfer
     * @return The amount of rain tokens owed by the contract to the user after this function executes
     */
    function transferRainInternalSafe(address farmer, uint amount) internal returns (uint) {
        address _rainToken = rainToken;
        uint rainTokenRemaining = IERC20ForRainFarmer(_rainToken).balanceOf(address(this));
        if (amount > 0 && amount <= rainTokenRemaining) {
            TransferHelper.safeTransfer(_rainToken, farmer, amount);
            return 0;
        }
        return amount;
    }


    // ******* admin *******

    /**
     * @notice Checks caller is admin
     */
    function isAdmin() internal view returns (bool) {
        return msg.sender == admin;
    }


    // ******* emergency *******

    /**
     * Sends all suuply balance to farmer (skipping rain claiming).
     * Farmer position will be zeroed out after.
     */
    function emergencyWithdrawFromFarmInternal(address farmer) internal {
        uint amount = farmersCurrentSupply[farmer];
        require(amount > 0, "nothing to withdraw");
        emergencyUpdateFarmerIndexInternal(farmer);
        sendFarmTokens(farmer, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract RainFarmAdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;
}

contract SingleAssetRainFarmStorage is RainFarmAdminStorage {

    // ******* rain data *******

    uint256 public budget;

    /// @notice Represented in seconds
    uint256 public startTime;
    uint256 public distributionPeriod;

    address public immutable rainToken;

    // ******* specific farm data *******

    address public immutable farmToken; // rainSPIRIT

    uint public farmSpeed;

    struct FarmCurrentState {
        /// @notice The farm's last updated index
        uint index;

        /// @notice The timestamp the index was last updated at
        uint timestamp;
    }
    FarmCurrentState public farmCurrentState;

    /// @notice The totalSupply deposited in farm token
    uint public totalSupply;


    // ******* user data *******

    /// @notice farmer address => farmer current index
    mapping(address => uint) public farmersCurrentIndex;

    /// @notice farmer address => farmer current supply
    mapping(address => uint) public farmersCurrentSupply;

    /// @notice The amount of rain tokens accrued but not yet transferred to each farmer
    mapping(address => uint) public farmersRainfall;

    constructor(address _rainToken, address _farmToken) {
        rainToken = _rainToken;
        farmToken = _farmToken;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

abstract contract RainFarmInterface {
    bool public isRainFarmer = true;
    bytes32 public contractNameHash;

    /*** admin setters and farm control ***/
    function pullNewRain(address pullRainFromAddress, uint pullRainAmount) virtual external;
    function extendWithExistingConfiguration(address pullRainFromAddress, uint pullRainAmount) virtual external;
    function restartWithNewConfiguration(
        uint _newStartTime,
        uint newDistributionPeriod,
        address pullRainFromAddress,
        uint pullRainAmount
    ) virtual external;

    /*** farm accounting and indexes ***/
    function updateFarmIndex() virtual external;
    function updateFarmerIndex(address farmer) virtual external;

    // *** user interactions - deposit, withdraw, claim rain ***/
    function depositToFarm(uint amount) virtual external;
    function depositToFarmOnBehalf(address farmer, uint amount) virtual external;
    function withdrawAllFromFarm() virtual external;
    function withdrawFromFarm(uint amount) virtual external;
    function claimRainFromFarm(address farmer) virtual external;
    function claimRainFromFarmToSomeFarmers(address[] calldata farmers) virtual external;

    // *** emergency ***
    function emergencyWithdrawFromFarm() virtual external;

    // *** admin ***
    function _setPendingAdmin(address newPendingAdmin) virtual external returns (uint);
    function _acceptAdmin() virtual external returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}
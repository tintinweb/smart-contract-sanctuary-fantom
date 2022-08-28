pragma solidity ^0.8;

contract ClaimableAdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;
}



contract ClaimableUpgradeableClaimableAdminStorage is ClaimableAdminStorage {
    /**
    * @notice Active brains of Ministry
    */
    address public implementation;

    /**
    * @notice Pending brains of Ministry
    */
    address public pendingImplementation;
}

pragma solidity ^0.8;

import "../../BaseContracts/ClaimableAdminStorage.sol";
import "../../BaseContracts/ClaimableUpgradeableClaimableAdmin.sol";

contract MinistryStorage {
    // Indicates if calculations should be block based or time based
    bool public blocksBased;
}

contract RegistryV0Storage is ClaimableUpgradeableClaimableAdmin, MinistryStorage {
    // Asset address -> Price oracle address
    mapping(address => address) public priceOracles;

    // Interest rate model address => isSupported
    mapping(address => bool) public supportedInterestRateModels;

    // Trade adapter address => isSupported
    mapping(address => bool) public supportedMarginTradeAdapters;

    mapping(bytes32 => uint) public latestContractVersions;
    mapping(bytes32 => mapping(uint => address)) public versionedContractImplementations;
}

pragma solidity ^0.8;

import "./ClaimableAdminStorage.sol";

/**
 * @title UpgradeableClaimableAdminStorage
 * @dev based on Compound's Unitroller
 * https://github.com/compound-finance/compound-protocol/blob/a3214f67b73310d547e00fc578e8355911c9d376/contracts/Unitroller.sol
 */
contract ClaimableUpgradeableClaimableAdmin is ClaimableUpgradeableClaimableAdminStorage {
    /**
      * @notice Emitted when pendingImplementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingImplementation is accepted, which means delegation implementation is updated
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
      * @notice Emitted when pendingAdmin is changed
      */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
      * @notice Emitted when pendingAdmin is accepted, which means admin is updated
      */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public returns (uint) {

        require(msg.sender == admin, "not admin");

        address oldPendingImplementation = pendingImplementation;

        pendingImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);

        return 0;
    }

    /**
    * @notice Accepts new implementation. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    * @return uint 0=success, otherwise reverts
    */
    function _acceptImplementation() public returns (uint) {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(msg.sender == pendingImplementation && pendingImplementation != address(0), "Not the EXISTING pending implementation");

        // Save current values for inclusion in log
        address oldImplementation = implementation;
        address oldPendingImplementation = pendingImplementation;

        implementation = pendingImplementation;

        pendingImplementation = address(0);

        emit NewImplementation(oldImplementation, implementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);

        return 0;
    }


    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      * @return uint 0=success, otherwise reverts
      */
    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
        // Check caller = admin
        require(msg.sender == admin, "Not Admin");

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
      * @return uint 0=success, otherwise reverts
      */
    function _acceptAdmin() public returns (uint) {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && pendingAdmin != address(0), "Not the EXISTING pending admin");

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

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    fallback() payable external {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }
}

pragma solidity ^0.8;

import "../../RegistryStorage.sol";
import "../../RegistryInterface.sol";
import "../../Ministry.sol";

interface IPriceOracleForRegistryV0 {
    /**
     * @param asset The asset to get the price of
     * @notice Get the price an asset
     * @return The asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getAssetPrice(address asset) external view returns (uint);
}

/**
 * @title Ola's Registry Contract
 * @author Ola
 */
contract RegistryV0 is RegistryV0Storage, RegistryV0Interface {
    /// @notice Emitted when an admin publishes a new version for a contract
    event NewContractVersionPublished(bytes32 indexed contractNameHash, uint oldVersion, uint indexed newVersion, address indexed implementation);

    /// @notice Emitted when an admin changes the price oracle of an asset
    event NewOracleForAsset(address indexed asset, address indexed oldOracle, address indexed newOracle);

    /**
     * @notice Emitted when an admin sets a trade adapter as allowed.
     */
    event MarginTradeAdapterAllowed(address indexed assetAddress);
    /**
     * @notice Emitted when an admin sets a trade adapter as forbidden.
     */
    event MarginTradeAdapterForbidden(address indexed assetAddress);

    constructor() {
        admin = msg.sender;
    }

    /*** Chain configuration ***/

    function isBlockBased() external view override returns (bool) {
        return blocksBased;
    }

    /*** Versions ***/

    function getLatestImplementationFor(bytes32 contractNameHash) external view override returns (address) {
        uint latestVersion = latestContractVersions[contractNameHash];

        return versionedContractImplementations[contractNameHash][latestVersion];
    }

    function getLatestVersionFor(bytes32 contractNameHash) external view override returns (uint) {
        return latestContractVersions[contractNameHash];
    }

    // TODO : Add easy getter for past versions implementations ?

    /*** Trade Adapters ***/

    function isSupportedTradeAdapter(address tradeAdapter) external view override returns (bool) {
        return supportedMarginTradeAdapters[tradeAdapter];
    }

    /*** Price oracles ***/

    /**
     * Returns the oracle address for the given asset
     */
    function getOracleForAsset(address asset) external view override returns (address) {
        return priceOracles[asset];
    }

    /**
     * Returns the oracle price for the given asset
     */
    function getPriceForAsset(address asset) external view override returns (uint256) {
        return getPriceForAssetInternal(asset);
    }

    /**
     * Returns the oracle price for the given asset
     */
    function price(address asset) external view override returns (uint256) {
        return getPriceForAssetInternal(asset);
    }

    /*** Interest rate models ***/

    /*** Interest rate model ***/
    function isSupportedInterestRateModel(address interestRateModel) external view override returns (bool) {
        return isInterestRateModelSupportedInternal(interestRateModel);
    }

    /*** Asset support ***/

    /**
     * @notice Asset is considered supported if it has a price oracle
     */
    function isAssetSupported(address asset) public view override returns (bool) {
        return priceOracles[asset] != address(0);
    }

    /*** Initialization functions ***/

    function _become(Ministry ministry) public {
        require(msg.sender == ministry.admin(), "only Ministry admin can change brains");
        require(ministry._acceptImplementation() == 0, "change not authorized");
    }

    /*** Admin functions ***/

    function publishContractVersion(bytes32 contractNameHash, uint version, address implementation) external override returns (bool) {
        require(msg.sender == admin, "Not Admin");
        // TODO : Add sanity check for 'implementation' ?

        // Ensure publishing up
        uint currentVersion = latestContractVersions[contractNameHash];
        require(version > currentVersion, "Cannot publish down");

        // Update storage
        latestContractVersions[contractNameHash] = version;
        versionedContractImplementations[contractNameHash][version] = implementation;

        // Emit
        emit NewContractVersionPublished(contractNameHash, currentVersion, version, implementation);

        return true;
    }

    function setOracleForAsset(address asset, address oracleAddress) external override returns (bool) {
        // TODO : Add price fetching check
        require(msg.sender == admin, "Not Admin");

        address oldOracle = priceOracles[asset];

        priceOracles[asset] = oracleAddress;

        emit NewOracleForAsset(asset, oldOracle, oracleAddress);

        return true;
    }

    function setSupportedInterestRateModel(address interestRateModel) external override returns (bool) {
        require(msg.sender == admin, "Not Admin");

        supportedInterestRateModels[interestRateModel] = true;

        return true;
    }

    function removeSupportedInterestRateModel(address interestRateModel) external override returns (bool) {
        require(msg.sender == admin, "Not Admin");
        require(supportedInterestRateModels[interestRateModel], "IRM is not supported");

        supportedInterestRateModels[interestRateModel] = false;

        return true;
    }

    function allowMarginTradeAdapter(address tradeAdapter) external returns (bool) {
        require(msg.sender == admin, "Not Admin");
        require(!supportedMarginTradeAdapters[tradeAdapter], "TradeAdapter already supported");

        supportedMarginTradeAdapters[tradeAdapter] = true;
        emit MarginTradeAdapterAllowed(tradeAdapter);

        return true;
    }

    function forbidMarginTradeAdapter(address tradeAdapter) external returns (bool) {
        require(msg.sender == admin, "Not Admin");
        require(supportedMarginTradeAdapters[tradeAdapter], "TradeAdapter is not supported");

        supportedMarginTradeAdapters[tradeAdapter] = false;
        emit MarginTradeAdapterForbidden(tradeAdapter);

        return true;
    }

    /*** internal views ***/

    function isInterestRateModelSupportedInternal(address interestRateModel) internal view returns (bool) {
        return supportedInterestRateModels[interestRateModel];
    }

    /**
     * Fetches the oracle price for the given asset (Or 0 if no oracle is defined)
     */
    function getPriceForAssetInternal(address asset) internal view returns (uint256) {
        address priceOracle = priceOracles[asset];

        require(priceOracle != address(0), 'No Oracle');

        return IPriceOracleForRegistryV0(priceOracle).getAssetPrice(asset);
    }
}

pragma solidity ^0.8;

abstract contract RegistryBaseInterface {
    /// @notice Indicator that this is a Registry contract (for inspection)
    bool public constant isRegistry = true;

    /*** Is Block Based ***/
    function isBlockBased() external view virtual returns (bool);

    /*** Versions ***/
    function getLatestImplementationFor(bytes32 contractNameHash) external view virtual returns (address);
    function getLatestVersionFor(bytes32 contractNameHash) external view virtual returns (uint);

    /*** Assets ***/
    function isAssetSupported(address asset) external view virtual returns (bool);

    /*** Trade Adapters ***/
    function isSupportedTradeAdapter(address tradeAdapter) external view virtual returns (bool);

    /*** Interest rate model ***/
    function isSupportedInterestRateModel(address interestRateModel) external view virtual returns (bool);

    /*** Price oracles ***/
    function getOracleForAsset(address asset) external view virtual returns (address);
    function getPriceForAsset(address asset) external view virtual returns (uint256);
    function price(address asset) external view virtual returns (uint256);
}

abstract contract RegistryV0Interface is RegistryBaseInterface {
    /*** Admin functions ***/
    function publishContractVersion(bytes32 contractNameHash, uint version, address implementation) external virtual returns (bool);
    function setOracleForAsset(address asset, address oracleAddress) external virtual returns (bool);
    function setSupportedInterestRateModel(address interestRateModel) external virtual returns (bool);
    function removeSupportedInterestRateModel(address interestRateModel) external virtual returns (bool);
}

pragma solidity ^0.8;

import "../../BaseContracts/ClaimableUpgradeableClaimableAdmin.sol";
import "./RegistryStorage.sol";

/**
 * @title Ministry
 */

contract Ministry is ClaimableUpgradeableClaimableAdmin, MinistryStorage {
    constructor(bool _blocksBased) {
        // Set the calculation base for this blockchain contracts
        blocksBased = _blocksBased;
    }
//
//    function whitelistTrader(address trader) external {
//        tradersWhitelist[trader] = true;
//    }
//
//    function blacklistTrader(address trader) external {
//        tradersWhitelist[trader] = false;
//    }
//
//    function isTraderWhitelisted(address trader) external returns (bool) {
//        return true;
//    }
}

pragma solidity ^0.8;

import "../../Brokers/Registry/RegistryInterface.sol";

contract TestRegistry is RegistryBaseInterface {
    /*** Is Block Based ***/
    function isBlockBased() external view override returns (bool) {
        return false;
    }

    /*** Versions ***/
    function getLatestImplementationFor(bytes32 contractNameHash) external view override returns (address) {
        return address(0);
    }

    function getLatestVersionFor(bytes32 contractNameHash) external view override returns (uint) {
        return 0;
    }

    function isSupportedTradeAdapter(address tradeAdapter) external view override returns (bool) {
        return true;
    }

    /*** Assets ***/
    function isAssetSupported(address asset) external view override returns (bool) {
        return true;
    }

    /*** Interest rate model ***/
    function isSupportedInterestRateModel(address interestRateModel) external view override returns (bool) {
        return true;
    }

    /*** Price oracles ***/
    function getOracleForAsset(address asset) external view override returns (address) {
        return address(0);
    }

    function getPriceForAsset(address asset) external view override returns (uint256) {
        return 0;
    }

    function price(address asset) external view override returns (uint256) {
        return 0;
    }
}

pragma solidity ^0.8;

import "../Interfaces/IBrokerPool.sol";
import "./BrokerPoolStorage.sol";
import "../../IneterstRateModels/InterestRateModel.sol";
import "./BrokerPoolInterface.sol";
import "../ErrorReporter/ErrorReporter.sol";
import "../../Math/ExponentialNoError.sol";
import "../Registry/RegistryInterface.sol";

/**
 *
 * @dev based on Compound's CToken https://github.com/compound-finance/compound-protocol/blob/a3214f67b73310d547e00fc578e8355911c9d376/contracts/CToken.sol
 * Changes from CToken :
 * Removals:
 * - Removed all liquidation mechanism (liquidate, seize...)
 * - Reverts instead of failing gracefully
 * Modifications:
 * - all xAllowed/Verify functions are internal
 * - 2 modes for interest calculation -- by block number diff and by time diff (depends on the blockchain)
 * - Borrowing is limited to only approved accounts (and with a USD cap for each)
 * - Supplying can be limited by USD amount.
 * Additions :
 *
 */
abstract contract BrokerPool is BrokerPoolStorage, BrokerPoolInterface, ExponentialNoError, BrokerPoolErrorReporter {
    /**
     * @notice Initialize the money market
     * @param registry_ The address of the registry
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ EIP-20 name of this token
     * @param symbol_ EIP-20 symbol of this token
     * @param decimals_ EIP-20 decimal precision of this token
     */
    function initialize(RegistryBaseInterface registry_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_) public {
        require(msg.sender == admin, "only admin may initialize the pool");
        require(accrualBlockNumber == 0 && borrowIndex == 0, "pool may only be initialized once");

        // Set initial exchange rate
        initialExchangeRateMantissa = initialExchangeRateMantissa_;
        require(initialExchangeRateMantissa > 0, "initial exchange rate must be greater than zero.");

        // Initialize block number and borrow index (block number mocks depend on Comptroller being set)
        accrualBlockNumber = getBlockNumber();
        accrualBlockTimestamp = getBlockTimestamp();
        borrowIndex = mantissaOne;

        require(registry_.isRegistry(), "!registry");
        registry = address(registry_);

        // Set the calculation based flag
        blocksBased = registry_.isBlockBased();

        uint err;

        // Set the interest rate model (depends on block number / borrow index)
        err = _setInterestRateModelFresh(interestRateModel_);
        require(err == NO_ERROR, "setting interest rate model failed");

        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
    }

    // *****************
    // Internal views
    // *****************

    /**
     * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
     * @dev Called by both `transfer` and `transferFrom` internally
     * @param spender The address of the account performing the transfer
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param tokens The number of tokens to transfer
     * @return 0 if the transfer succeeded, else revert
     */
    function transferTokens(address spender, address src, address dst, uint tokens) internal returns (uint) {
        /* Fail if transfer not allowed */
        uint allowed = transferAllowedInternal(address(this), src, dst, tokens);
        if (allowed != 0) {
            revert TransferComptrollerRejection(allowed);
        }

        /* Do not allow self-transfers */
        if (src == dst) {
            revert TransferNotAllowed();
        }

        /* Get the allowance, infinite for the account owner */
        uint startingAllowance = 0;
        if (spender == src) {
            startingAllowance = type(uint).max;
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        /* Do the calculations, checking for {under,over}flow */
        uint allowanceNew = startingAllowance - tokens;
        uint srcTokensNew = accountTokens[src] - tokens;
        uint dstTokensNew = accountTokens[dst] + tokens;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        accountTokens[src] = srcTokensNew;
        accountTokens[dst] = dstTokensNew;

        /* Eat some of the allowance (if necessary) */
        if (startingAllowance != type(uint).max) {
            transferAllowances[src][spender] = allowanceNew;
        }

        /* We emit a Transfer event */
        emit Transfer(src, dst, tokens);

        // unused function
        // transferVerifyInternal(address(this), src, dst, tokens);

        return NO_ERROR;
    }

    /**
         * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) override external nonReentrant returns (bool) {
        return transferTokens(msg.sender, msg.sender, dst, amount) == NO_ERROR;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) override external nonReentrant returns (bool) {
        return transferTokens(msg.sender, src, dst, amount) == NO_ERROR;
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external override view returns (uint256) {
        return transferAllowances[owner][spender];
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external override view returns (uint256) {
        return accountTokens[owner];
    }

    // *****************
    // Pool Broker interface
    // *****************

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external override returns (uint) {
        Exp memory exchangeRate = Exp({mantissa: exchangeRateCurrent()});
        return mul_ScalarTruncate(exchangeRate, accountTokens[owner]);
    }

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by comptroller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (possible error, token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account) override external view returns (uint, uint, uint, uint) {
        return (
        NO_ERROR,
        accountTokens[account],
        borrowBalanceStoredInternal(account),
        exchangeRateStoredInternal()
        );
    }

    /**
 * @notice Get the accrual block number of this cToken
     * @return The accrual block number
     */
    function getAccrualBlockNumber() external view returns (uint) {
        return accrualBlockNumber;
    }

    /**
 * @notice Returns the current per-block borrow interest rate for this cToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() override external view returns (uint) {
        return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
    }

    /**
     * @notice Returns the current per-block supply interest rate for this cToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() override external view returns (uint) {
        return interestRateModel.getSupplyRate(getCashPrior(), totalBorrows, totalReserves, reserveFactorMantissa);
    }

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() override external nonReentrant returns (uint) {
        accrueInterest();
        return totalBorrows;
    }

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) override external nonReentrant returns (uint) {
        accrueInterest();
        return borrowBalanceStored(account);
    }

    /**
 * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) override public view returns (uint) {
        return borrowBalanceStoredInternal(account);
    }

    /**
 * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function borrowBalanceStoredInternal(address account) internal view returns (uint) {
        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) {
            return 0;
        }

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        uint principalTimesIndex = borrowSnapshot.principal * borrowIndex;
        return principalTimesIndex / borrowSnapshot.interestIndex;
    }

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() override public nonReentrant returns (uint) {
        accrueInterest();
        return exchangeRateStored();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() override public view returns (uint) {
        return exchangeRateStoredInternal();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return calculated exchange rate scaled by 1e18
     */
    function exchangeRateStoredInternal() virtual internal view returns (uint) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            /*
             * If there are no tokens minted:
             *  exchangeRate = initialExchangeRate
             */
            return initialExchangeRateMantissa;
        } else {
            /*
             * Otherwise:
             *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
             */
            uint totalCash = getCashPrior();
            uint cashPlusBorrowsMinusReserves = totalCash + totalBorrows - totalReserves;
            uint exchangeRate = cashPlusBorrowsMinusReserves * expScale / _totalSupply;

            return exchangeRate;
        }
    }

    /**
 * @notice Get cash balance of this cToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() override external view returns (uint) {
        return getCashPrior();
    }

    /**
 * @notice Applies accrued interest to total borrows and reserves
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() virtual override public returns (uint) {
        /* Remember the initial block number */
        uint currentBlockNumber = getBlockNumber();
        uint accrualBlockNumberPrior = accrualBlockNumber;

        /* Short-circuit accumulating 0 interest */
        if (accrualBlockNumberPrior == currentBlockNumber) {
            return NO_ERROR;
        }

        /* Read the previous values out of storage */
        uint cashPrior = getCashPrior();
        uint borrowsPrior = totalBorrows;
        uint reservesPrior = totalReserves;
        uint borrowIndexPrior = borrowIndex;

        /* Calculate the current borrow interest rate */
        uint borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
        require(borrowRateMantissa <= borrowRateMaxMantissa, "borrow rate is absurdly high");

        /* Calculate the number of blocks elapsed since the last accrual */
        uint blockDelta = currentBlockNumber - accrualBlockNumberPrior;

        /*
         * Calculate the interest accumulated into borrows and reserves and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrowsNew = interestAccumulated + totalBorrows
         *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
         *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
         */

        Exp memory simpleInterestFactor = mul_(Exp({mantissa: borrowRateMantissa}), blockDelta);
        uint interestAccumulated = mul_ScalarTruncate(simpleInterestFactor, borrowsPrior);
        uint totalBorrowsNew = interestAccumulated + borrowsPrior;
        uint totalReservesNew = mul_ScalarTruncateAddUInt(Exp({mantissa: reserveFactorMantissa}), interestAccumulated, reservesPrior);
        uint borrowIndexNew = mul_ScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage */
        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        /* We emit an AccrueInterest event */
        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

        return NO_ERROR;
    }

    // *****************
    // Admin functions
    // *****************

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPendingAdmin(address payable newPendingAdmin) external override returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            revert("Not Admin");
//            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return NO_ERROR;
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _acceptAdmin() external override returns (uint) {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        if (msg.sender != pendingAdmin || msg.sender == address(0)) {
            revert("Not pending admin");
//            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = payable(address(0));

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return NO_ERROR;
    }

    /**
      * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
      * @dev Admin function to accrue interest and set a new reserve factor
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setReserveFactor(uint newReserveFactorMantissa) override external nonReentrant returns (uint) {
        accrueInterest();
        // _setReserveFactorFresh emits reserve-factor-specific logs on errors, so we don't need to.
        return _setReserveFactorFresh(newReserveFactorMantissa);
    }

    /**
      * @notice Sets a new reserve factor for the protocol (*requires fresh interest accrual)
      * @dev Admin function to set a new reserve factor
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setReserveFactorFresh(uint newReserveFactorMantissa) internal returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            revert SetReserveFactorAdminCheck();
        }

        // Verify market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            revert SetReserveFactorFreshCheck();
        }

        // Check newReserveFactor ≤ maxReserveFactor
        if (newReserveFactorMantissa > reserveFactorMaxMantissa) {
            revert SetReserveFactorBoundsCheck();
        }

        uint oldReserveFactorMantissa = reserveFactorMantissa;
        reserveFactorMantissa = newReserveFactorMantissa;

        emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);

        return NO_ERROR;
    }

    /**
 * @notice Accrues interest and reduces reserves by transferring to admin
     * @param reduceAmount Amount of reduction to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReserves(uint reduceAmount) override external nonReentrant returns (uint) {
        accrueInterest();
        // _reduceReservesFresh emits reserve-reduction-specific logs on errors, so we don't need to.
        return _reduceReservesFresh(reduceAmount);
    }

    /**
     * @notice Reduces reserves by transferring to admin
     * @dev Requires fresh interest accrual
     * @param reduceAmount Amount of reduction to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReservesFresh(uint reduceAmount) internal returns (uint) {
        // totalReserves - reduceAmount
        uint totalReservesNew;

        // Check caller is admin
        if (msg.sender != admin) {
            revert ReduceReservesAdminCheck();
        }

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            revert ReduceReservesFreshCheck();
        }

        // Fail gracefully if protocol has insufficient underlying cash
        if (getCashPrior() < reduceAmount) {
            revert ReduceReservesCashNotAvailable();
        }

        // Check reduceAmount ≤ reserves[n] (totalReserves)
        if (reduceAmount > totalReserves) {
            revert ReduceReservesCashValidation();
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        totalReservesNew = totalReserves - reduceAmount;

        // Store reserves[n+1] = reserves[n] - reduceAmount
        totalReserves = totalReservesNew;

        // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
        doTransferOut(admin, reduceAmount);

        emit ReservesReduced(admin, reduceAmount, totalReservesNew);

        return NO_ERROR;
    }

    /**
 * @notice accrues interest and updates the interest rate model using _setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModel(InterestRateModel newInterestRateModel) override public returns (uint) {
        accrueInterest();
        // _setInterestRateModelFresh emits interest-rate-model-update-specific logs on errors, so we don't need to.
        return _setInterestRateModelFresh(newInterestRateModel);
    }

    /**
     * @notice updates the interest rate model (*requires fresh interest accrual)
     * @dev Admin function to update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal returns (uint) {

        // Used to store old model for use in the event that is emitted on success
        InterestRateModel oldInterestRateModel;

        // Check caller is admin
        if (msg.sender != admin) {
            revert SetInterestRateModelOwnerCheck();
        }

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            revert SetInterestRateModelFreshCheck();
        }

        // Track the market's current interest rate model
        oldInterestRateModel = interestRateModel;

        // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
        require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

        // Set the interest rate model to newInterestRateModel
        interestRateModel = newInterestRateModel;

        // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel)
        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

        return NO_ERROR;
    }

    /**
     * @notice updates the total supply cap
     * @dev Admin function to update the total supply cap
     * @param totalSupplyCapUsd_ the new total supply cap
     * @return uint 0=success, otherwise reverts
     */
    function _setTotalSupplyCap(uint totalSupplyCapUsd_) external override returns (uint) {
        require(msg.sender == admin, "not admin");
        uint oldTotalSupplyCap = totalSupplyCapUsd;

        totalSupplyCapUsd = totalSupplyCapUsd_;

        emit NewTotalSupplyCap(oldTotalSupplyCap, totalSupplyCapUsd);

        return 0;
    }

    /**
     * @notice updates the total borrow cap
     * @dev Admin function to update the total borrow cap
     * @param totalBorrowCapUsd_ the new total borrow cap
     * @return uint 0=success, otherwise reverts
     */
    function _setTotalBorrowCap(uint totalBorrowCapUsd_) external override returns (uint) {
        require(msg.sender == admin, "not admin");
        uint oldTotalBorrowCap = totalBorrowCapUsd;

        totalBorrowCapUsd = totalBorrowCapUsd_;

        emit NewTotalSupplyCap(oldTotalBorrowCap, totalBorrowCapUsd_);

        return 0;
    }

    /**
     * @notice updates the borrow cap for the given borrower
     * @dev Admin function to update the borrow limit for a specific broker
     * @param borrower the borrower
     * @param borrowCapUsd the new borrow cap
     * @return uint 0=success, otherwise reverts
     */
    function _setBorrowerCap(address borrower, uint borrowCapUsd) external override returns (uint) {
        require(msg.sender == admin, "not admin");

        uint oldBorrowerCap = brokersBorrowLimitUsd[borrower];
        brokersBorrowLimitUsd[borrower] = borrowCapUsd;

        emit NewBorrowerLimit(borrower, oldBorrowerCap, borrowCapUsd);

        return 0;
    }

    // *****************
    // Internal Pool actions
    // *****************

    /**
 * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     */
    function mintInternal(uint mintAmount) internal nonReentrant {
        accrueInterest();
        // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
        mintFresh(msg.sender, mintAmount);
    }

    /**
 * @notice User supplies assets into the market and receives cTokens in exchange
     * @dev Assumes interest has already been accrued up to the current block
     * @param minter The address of the account which is supplying the assets
     * @param mintAmount The amount of the underlying asset to supply
     */
    function mintFresh(address minter, uint mintAmount) internal {
        /* Fail if mint not allowed */
        uint allowed = mintAllowedInternal(address(this), minter, mintAmount);
        if (allowed != 0) {
            revert MintComptrollerRejection(allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            revert MintFreshnessCheck();
        }

        Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal()});

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         *  We call `doTransferIn` for the minter and the mintAmount.
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
         *  side-effects occurred. The function returns the amount actually transferred,
         *  in case of a fee. On success, the cToken holds an additional `actualMintAmount`
         *  of cash.
         */
        uint actualMintAmount = doTransferIn(minter, mintAmount);

        /*
         * We get the current exchange rate and calculate the number of cTokens to be minted:
         *  mintTokens = actualMintAmount / exchangeRate
         */

        uint mintTokens = div_(actualMintAmount, exchangeRate);

        /*
         * We calculate the new total supply of cTokens and minter token balance, checking for overflow:
         *  totalSupplyNew = totalSupply + mintTokens
         *  accountTokensNew = accountTokens[minter] + mintTokens
         * And write them into storage
         */
        totalSupply = totalSupply + mintTokens;
        accountTokens[minter] = accountTokens[minter] + mintTokens;

        /* We emit a Mint event, and a Transfer event */
        emit Mint(minter, actualMintAmount, mintTokens);
        emit Transfer(address(this), minter, mintTokens);

        /* We call the defense hook */
        // unused function
        // mintVerifyInternal(address(this), minter, actualMintAmount, mintTokens);
    }

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     */
    function redeemInternal(uint redeemTokens) internal nonReentrant {
        accrueInterest();
        // redeemFresh emits redeem-specific logs on errors, so we don't need to
        redeemFresh(payable(msg.sender), redeemTokens, 0);
    }

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to receive from redeeming cTokens
     */
    function redeemUnderlyingInternal(uint redeemAmount) internal nonReentrant {
        accrueInterest();
        // redeemFresh emits redeem-specific logs on errors, so we don't need to
        redeemFresh(payable(msg.sender), 0, redeemAmount);
    }

    /**
     * @notice User redeems cTokens in exchange for the underlying asset
     * @dev Assumes interest has already been accrued up to the current block
     * @param redeemer The address of the account which is redeeming the tokens
     * @param redeemTokensIn The number of cTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmountIn The number of underlying tokens to receive from redeeming cTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     */
    function redeemFresh(address payable redeemer, uint redeemTokensIn, uint redeemAmountIn) internal {
        require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

        /* exchangeRate = invoke Exchange Rate Stored() */
        Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal() });

        uint redeemTokens;
        uint redeemAmount;
        /* If redeemTokensIn > 0: */
        if (redeemTokensIn > 0) {
            /*
             * We calculate the exchange rate and the amount of underlying to be redeemed:
             *  redeemTokens = redeemTokensIn
             *  redeemAmount = redeemTokensIn x exchangeRateCurrent
             */
            redeemTokens = redeemTokensIn;
            redeemAmount = mul_ScalarTruncate(exchangeRate, redeemTokensIn);
        } else {
            /*
             * We get the current exchange rate and calculate the amount to be redeemed:
             *  redeemTokens = redeemAmountIn / exchangeRate
             *  redeemAmount = redeemAmountIn
             */
            redeemTokens = div_(redeemAmountIn, exchangeRate);
            redeemAmount = redeemAmountIn;
        }

        /* Fail if redeem not allowed */
        uint allowed = redeemAllowedInternal(address(this), redeemer, redeemTokens);
        if (allowed != 0) {
            revert RedeemComptrollerRejection(allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            revert RedeemFreshnessCheck();
        }

        /* Fail gracefully if protocol has insufficient cash */
        if (getCashPrior() < redeemAmount) {
            revert RedeemTransferOutNotPossible();
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)


        /*
         * We write the previously calculated values into storage.
         *  Note: Avoid token reentrancy attacks by writing reduced supply before external transfer.
         */
        totalSupply = totalSupply - redeemTokens;
        accountTokens[redeemer] = accountTokens[redeemer] - redeemTokens;

        /*
         * We invoke doTransferOut for the redeemer and the redeemAmount.
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the cToken has redeemAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        doTransferOut(redeemer, redeemAmount);

        /* We emit a Transfer event, and a Redeem event */
        emit Transfer(redeemer, address(this), redeemTokens);
        emit Redeem(redeemer, redeemAmount, redeemTokens);

        /* We call the defense hook */
        redeemVerifyInternal(address(this), redeemer, redeemAmount, redeemTokens);
    }

    /**
  * @notice Sender borrows assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      */
    function borrowInternal(uint borrowAmount) internal nonReentrant {
        accrueInterest();
        // borrowFresh emits borrow-specific logs on errors, so we don't need to
        borrowFresh(payable(msg.sender), borrowAmount);
    }

    /**
      * @notice Users borrow assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      */
    function borrowFresh(address payable borrower, uint borrowAmount) internal {
        /* Fail if borrow not allowed */
        uint allowed = borrowAllowedInternal(address(this), borrower, borrowAmount);
        if (allowed != 0) {
            revert BorrowComptrollerRejection(allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            revert BorrowFreshnessCheck();
        }

        /* Fail gracefully if protocol has insufficient underlying cash */
        if (getCashPrior() < borrowAmount) {
            revert BorrowCashNotAvailable();
        }

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowNew = accountBorrow + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        uint accountBorrowsPrev = borrowBalanceStoredInternal(borrower);
        uint accountBorrowsNew = accountBorrowsPrev + borrowAmount;
        uint totalBorrowsNew = totalBorrows + borrowAmount;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We write the previously calculated values into storage.
         *  Note: Avoid token reentrancy attacks by writing increased borrow before external transfer.
        `*/
        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        /*
         * We invoke doTransferOut for the borrower and the borrowAmount.
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the cToken borrowAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        doTransferOut(borrower, borrowAmount);

        /* We emit a Borrow event */
        emit Borrow(borrower, borrowAmount, accountBorrowsNew, totalBorrowsNew);
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay, or -1 for the full outstanding amount
     */
    function repayBorrowInternal(uint repayAmount) internal nonReentrant {
        accrueInterest();
        // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        repayBorrowFresh(msg.sender, msg.sender, repayAmount);
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay, or -1 for the full outstanding amount
     */
    function repayBorrowBehalfInternal(address borrower, uint repayAmount) internal nonReentrant {
        accrueInterest();
        // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        repayBorrowFresh(msg.sender, borrower, repayAmount);
    }

    /**
     * @notice Borrows are repaid by another user (possibly the borrower).
     * @param payer the account paying off the borrow
     * @param borrower the account with the debt being payed off
     * @param repayAmount the amount of underlying tokens being returned, or -1 for the full outstanding amount
     * @return (uint) the actual repayment amount.
     */
    function repayBorrowFresh(address payer, address borrower, uint repayAmount) internal returns (uint) {
        /* Fail if repayBorrow not allowed */
        uint allowed = repayBorrowAllowedInternal(address(this), payer, borrower, repayAmount);
        if (allowed != 0) {
            revert RepayBorrowComptrollerRejection(allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            revert RepayBorrowFreshnessCheck();
        }

        /* We fetch the amount the borrower owes, with accumulated interest */
        uint accountBorrowsPrev = borrowBalanceStoredInternal(borrower);

        /* If repayAmount == -1, repayAmount = accountBorrows */
        uint repayAmountFinal = repayAmount == type(uint).max ? accountBorrowsPrev : repayAmount;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We call doTransferIn for the payer and the repayAmount
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the cToken holds an additional repayAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *   it returns the amount actually transferred, in case of a fee.
         */
        uint actualRepayAmount = doTransferIn(payer, repayAmountFinal);

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - actualRepayAmount
         *  totalBorrowsNew = totalBorrows - actualRepayAmount
         */
        uint accountBorrowsNew = accountBorrowsPrev - actualRepayAmount;
        uint totalBorrowsNew = totalBorrows - actualRepayAmount;

        /* We write the previously calculated values into storage */
        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        /* We emit a RepayBorrow event */
        emit RepayBorrow(payer, borrower, actualRepayAmount, accountBorrowsNew, totalBorrowsNew);

        return actualRepayAmount;
    }

    // *****************
    // Internal accounting limitation
    // *****************

    function mintAllowedInternal(address cToken, address minter, uint mintAmount) internal returns (uint) {
        // TODO : IMPLEMENT
        return NO_ERROR;
    }
    function mintVerifyInternal(address cToken, address minter, uint mintAmount, uint mintTokens) internal {
        // TODO : IMPLEMENT
    }

    function redeemAllowedInternal(address cToken, address redeemer, uint redeemTokens) internal returns (uint) {
        // TODO : IMPLEMENT
        return NO_ERROR;
    }
    function redeemVerifyInternal(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) internal {
        // TODO : IMPLEMENT
    }

    function borrowAllowedInternal(address cToken, address borrower, uint borrowAmount) internal returns (uint) {
        // TODO : IMPLEMENT
        return NO_ERROR;
    }
    function borrowVerifyInternal(address cToken, address borrower, uint borrowAmount) internal {
        // TODO : IMPLEMENT
    }

    function repayBorrowAllowedInternal(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) internal returns (uint) {
        // TODO : IMPLEMENT
        return NO_ERROR;
    }
    function repayBorrowVerifyInternal(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) internal {
        // TODO : IMPLEMENT
    }

    function transferAllowedInternal(address cToken, address src, address dst, uint transferTokens) internal returns (uint) {
        // TODO : IMPLEMENT
        return NO_ERROR;
    }
    function transferVerifyInternal(address cToken, address src, address dst, uint transferTokens) internal {
        // TODO : IMPLEMENT
    }

    // *****************
    // Internal views
    // *****************

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    /**
     * @dev Function to simply retrieve block timestamp
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockTimestamp() internal view returns (uint) {
        return block.timestamp;
    }

    /**
     * @dev Fetches the admin bank address.
     */
    function fetchBankAddress() internal view returns (address payable) {
        return _bankAddress;
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying owned by this contract
     */
    function getCashPrior() virtual internal view returns (uint);

    /**
     * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
     *  This may revert due to insufficient balance or insufficient allowance.
     */
    function doTransferIn(address from, uint amount) virtual internal returns (uint);

    /**
     * @dev Performs a transfer out, ideally returning an explanatory error code upon failure rather than reverting.
     *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
     *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
     */
    function doTransferOut(address payable to, uint amount) virtual internal;

    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        _beforeNonReentrant();
        _;
        _afterNonReentrant();
    }

    /**
     * @dev Split off from `nonReentrant` to keep contract below the 24 KB size limit.
     * Saves space because function modifier code is "inlined" into every function with the modifier).
     * In this specific case, the optimization saves around 1500 bytes of that valuable 24 KB limit.
     */
    function _beforeNonReentrant() private {
        require(_notEntered, "re-entered");
//        if (!localOnly) ComptrollerForOToken(address(comptroller))._beforeNonReentrant();
        _notEntered = false;
    }

    /**
     * @dev Split off from `nonReentrant` to keep contract below the 24 KB size limit.
     * Saves space because function modifier code is "inlined" into every function with the modifier).
     * In this specific case, the optimization saves around 150 bytes of that valuable 24 KB limit.
     */
    function _afterNonReentrant() private {
        _notEntered = true; // get a gas-refund post-Istanbul
//        if (!localOnly) ComptrollerForOToken(address(comptroller))._afterNonReentrant();
    }
}

interface IBrokerPool {
    function underlying() external view returns (address);

    function borrowIndex() external view returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256 error);

    function repayBorrow(uint256 repayAmount) external returns (uint256 error);

    function accrueInterest() external returns (uint256 error);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../IneterstRateModels/InterestRateModel.sol";

contract BrokerPoolAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Implementation address for this contract
     */
    address public implementation;

    /**
     * @notice Contract hash name
     */
    bytes32 public contractNameHash;

    /**
     * @notice Registry
     */
    address public registry;
}

/**
 * @notice DO NOT ADD ANY MORE STORAGE VARIABLES HERE (add them to their respective type storage)
 */
contract BrokerPoolStorage is BrokerPoolAdminStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Underlying asset for this CToken
     */
    address public underlying;

    // @notice Indicates if the calculations should be blocks or time based
    bool public blocksBased;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @notice Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockTimestamp;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the pool
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this pool
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this pool
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @notice Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    /**
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    // TODO : Think about this mechanism
    address payable _bankAddress;

    /**
     * @notice USD supply limit (scaled to 1e18)
     */
    uint public totalSupplyCapUsd;

    /**
     * @notice USD borrow limit (scaled to 1e18)
     */
    uint public totalBorrowCapUsd;

    /**
     * @notice Mapping of account addresses to USD borrow amount (scaled to 1e18)
     */
    mapping(address => uint) public brokersBorrowLimitUsd;

    // IMPORTANT : DO NOT ADD ANY MORE STORAGE VARIABLES HERE (add them to their respective type storage)
}

contract BPErc20StorageV0_01 {}

pragma solidity ^0.8.0;

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external virtual view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external virtual view returns (uint);
}

pragma solidity ^0.8.0;

import "../../IneterstRateModels/InterestRateModel.sol";
import "../Interfaces/EIP20NonStandardInterface.sol";

abstract contract BrokerPoolInterface {
    // OLA_ADDITIONS : "Underlying field"
    address constant public nativeCoinUnderlying = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /**
     * @notice This value is hard coded to 0.5 (50% for the Ola ecosystem and the LeN owner each)
     */
    uint constant public olaReserveFactorMantissa = 0.5e18;

    /**
     * @notice Indicator that this is a BrokerPool contract (for inspection)
     */
    bool public constant isBrokerPool = true;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */
    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @notice Maximum fraction of interest that can be set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 0.3e18;

    /**
     * OLA_ADDITIONS : This value
     * @notice Minimum fraction of interest that can be set aside for reserves
     */
    uint internal constant reserveFactorMinMantissa = 0.05e18;

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint adminPart, uint newTotalReserves);

    /**
     * @notice Event emitted when the supply cap is changed
     */
    event NewTotalSupplyCap(uint oldSupplyCap, uint newSupplyCap);

    /**
     * @notice Event emitted when the borrow cap is changed
     */
    event NewTotalBorrowCap(uint oldBorrowCap, uint newBorrowCap);

    /**
     * @notice Event emitted when a borrower cap is changed
     */
    event NewBorrowerLimit(address indexed borrower, uint oldBorrowerCap, uint newBorrowerCap);

    /*** ERC20 Events ***/

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /*** User Interface ***/

    function transfer(address dst, uint amount) virtual external returns (bool);
    function transferFrom(address src, address dst, uint amount) virtual external returns (bool);
    function approve(address spender, uint amount) virtual external returns (bool);
    function allowance(address owner, address spender) virtual external view returns (uint);
    function balanceOf(address owner) virtual external view returns (uint);

    function balanceOfUnderlying(address owner) virtual external returns (uint);
    function getAccountSnapshot(address account) virtual external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() virtual external view returns (uint);
    function supplyRatePerBlock() virtual external view returns (uint);
    function totalBorrowsCurrent() virtual external returns (uint);
    function borrowBalanceCurrent(address account) virtual external returns (uint);
    function borrowBalanceStored(address account) virtual external view returns (uint);
    function exchangeRateCurrent() virtual external returns (uint);
    function exchangeRateStored() virtual external view returns (uint);
    function getCash() virtual external view returns (uint);
    function accrueInterest() virtual external returns (uint);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external virtual returns (uint);
    function _acceptAdmin() external virtual returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external virtual  returns (uint);
    function _reduceReserves(uint reduceAmount) external virtual returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) public virtual returns (uint);

    function _setTotalSupplyCap(uint totalSupplyCapUsd_) external virtual returns (uint);
    function _setTotalBorrowCap(uint totalBorrowCapUsd_) external virtual returns (uint);
    function _setBorrowerCap(address borrower, uint borrowCapUsd) external virtual returns (uint);
}

abstract contract BrokerPoolViewInterface {
    function isBorrowerAllowed(address borrower) virtual public returns (bool);
}

abstract contract Erc20BrokerPoolInterface {

    /*** User Interface ***/

    function mint(uint mintAmount) virtual external returns (uint);
    function redeem(uint redeemTokens) virtual external returns (uint);
    function redeemUnderlying(uint redeemAmount) virtual external returns (uint);
    function borrow(uint borrowAmount) virtual external returns (uint);
    function repayBorrow(uint repayAmount) virtual external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) virtual external returns (uint);
    function sweepToken(EIP20NonStandardInterface token) virtual external;
}

abstract contract BPDelegateInterface {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) virtual public;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() virtual public;
}

abstract contract BPTokenDelegatorInterface {

    /*** Implementation Events ***/

    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address indexed oldImplementation, address indexed newImplementation);

    /**
     * @notice Emitted when implementation is not changed under a system version update
     */
    event ImplementationDidNotChange(address indexed implementation);


    /*** Implementation functions ***/

    // OLA_ADDITIONS : Update implementation from the Registry
    function updateImplementationFromRegistry(bool allowResign, bytes calldata becomeImplementationData) external virtual returns (bool);
}

pragma solidity ^0.8.0;

contract BrokerPoolErrorReporter {
    uint public constant NO_ERROR = 0; // support legacy return codes

    error TransferComptrollerRejection(uint256 errorCode);
    error TransferNotAllowed();
    error TransferNotEnough();
    error TransferTooMuch();

    error MintComptrollerRejection(uint256 errorCode);
    error MintFreshnessCheck();

    error RedeemComptrollerRejection(uint256 errorCode);
    error RedeemFreshnessCheck();
    error RedeemTransferOutNotPossible();

    error BorrowComptrollerRejection(uint256 errorCode);
    error BorrowFreshnessCheck();
    error BorrowCashNotAvailable();

    error RepayBorrowComptrollerRejection(uint256 errorCode);
    error RepayBorrowFreshnessCheck();

    error LiquidateComptrollerRejection(uint256 errorCode);
    error LiquidateFreshnessCheck();
    error LiquidateCollateralFreshnessCheck();
    error LiquidateAccrueBorrowInterestFailed(uint256 errorCode);
    error LiquidateAccrueCollateralInterestFailed(uint256 errorCode);
    error LiquidateLiquidatorIsBorrower();
    error LiquidateCloseAmountIsZero();
    error LiquidateCloseAmountIsUintMax();
    error LiquidateRepayBorrowFreshFailed(uint256 errorCode);

    error LiquidateSeizeComptrollerRejection(uint256 errorCode);
    error LiquidateSeizeLiquidatorIsBorrower();

    error AcceptAdminPendingAdminCheck();

    error SetComptrollerOwnerCheck();
    error SetPendingAdminOwnerCheck();

    error SetReserveFactorAdminCheck();
    error SetReserveFactorFreshCheck();
    error SetReserveFactorBoundsCheck();

    error AddReservesFactorFreshCheck(uint256 actualAddAmount);

    error ReduceReservesAdminCheck();
    error ReduceReservesFreshCheck();
    error ReduceReservesCashNotAvailable();
    error ReduceReservesCashValidation();

    error SetInterestRateModelOwnerCheck();
    error SetInterestRateModelFreshCheck();
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return a + b;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return a * b;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity ^0.8.0;

import "../../BrokerPool.sol";
import "../../../../IneterstRateModels/InterestRateModel.sol";

import "../../../Interfaces/EIP20NonStandardInterface.sol";
import "../../../Interfaces/EIP20Interface.sol";

/**
 * @title Ola's BPErc20 Contract V0.01
 * @notice BrokerPool which wrap an EIP-20 underlying
 * @author Ola Finance
 */
contract BPErc20V0_01 is BrokerPool, Erc20BrokerPoolInterface, BPErc20StorageV0_01 {
    /**
     * @notice Initialize the new money market
     * @param registry_ The address of the registry
     * @param underlying_ The address of the underlying asset
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     */
    function initialize(RegistryBaseInterface registry_,
                        address underlying_,
                        InterestRateModel interestRateModel_,
                        uint initialExchangeRateMantissa_,
                        string memory name_,
                        string memory symbol_,
                        uint8 decimals_
    ) public {
        // BrokerPool's initialize does the bulk of the work
        super.initialize(registry_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);

        // Set underlying and sanity check it
        underlying = underlying_;
        EIP20Interface(underlying).totalSupply();
    }

    /*** User Interface ***/

    /**
     * @notice Sender supplies assets into the market and receives bpTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint mintAmount) override external returns (uint) {
        mintInternal(mintAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender redeems bpTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of bpTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens) override external returns (uint) {
        redeemInternal(redeemTokens);
        return NO_ERROR;
    }

    /**
     * @notice Sender redeems bpTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) override external returns (uint) {
        redeemUnderlyingInternal(redeemAmount);
        return NO_ERROR;
    }

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint borrowAmount) override external returns (uint) {
        borrowInternal(borrowAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay, or -1 for the full outstanding amount
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint repayAmount) override external returns (uint) {
        repayBorrowInternal(repayAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay, or -1 for the full outstanding amount
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrowBehalf(address borrower, uint repayAmount) override external returns (uint) {
        repayBorrowBehalfInternal(borrower, repayAmount);
        return NO_ERROR;
    }

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (timelock)
     * @param token The address of the ERC-20 token to sweep
     */
    function sweepToken(EIP20NonStandardInterface token) override external {
        require(msg.sender == admin, "BPErc20::sweepToken: only admin can sweep tokens");
        require(address(token) != underlying, "BPErc20::sweepToken: can not sweep underlying token");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(admin, balance);
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function getCashPrior() virtual override internal view returns (uint) {
        EIP20Interface token = EIP20Interface(underlying);
        return token.balanceOf(address(this));
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(address from, uint amount) virtual override internal returns (uint) {
        // Read from storage once
        address underlying_ = underlying;
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying_);
        uint balanceBefore = EIP20Interface(underlying_).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {                       // This is a non-standard ERC-20
                success := not(0)          // set success to true
            }
            case 32 {                      // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0)        // Set `success = returndata` of override external call
            }
            default {                      // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint balanceAfter = EIP20Interface(underlying_).balanceOf(address(this));
        return balanceAfter - balanceBefore;   // underflow already checked above, just subtract
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address payable to, uint amount) virtual override internal {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {                      // This is a non-standard ERC-20
                success := not(0)          // set success to true
            }
            case 32 {                     // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0)        // Set `success = returndata` of override external call
            }
            default {                     // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "../BPErc20V0_01.sol";

/**
 * @title Ola's CErc20Delegate V0_05 Contract
 * @notice OTokens which wrap an EIP-20 underlying and are delegated to
 * @author Ola
 */
contract BPErc20DelegateV0_01 is BPErc20V0_01, BPDelegateInterface {
    /**
     * @notice Construct an empty delegate
     */
    constructor() public {}

    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public override {
        // Shh -- currently unused
        data;

        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        // OLA_ADDITION : The 'or registry'
        // The only time where msg.sender is the admin is during construction of the 'delegator' contract
        require(msg.sender == admin || msg.sender == address(registry), "only the admin and registry may call _becomeImplementation");
    }

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public override {
        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        // OLA_ADDITION : Was 'only admin'. Now, 'only registry'
        require(msg.sender == address(registry), "only the registry may call _resignImplementation");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "../BrokerPoolStorage.sol";
import "../BrokerPoolInterface.sol";

interface RegistryForBPDelegator {
    function getLatestImplementationFor(bytes32 contractNameHash) external view returns (address);
}

/**
 * @title Ola's BPDelegator Contract
 * @notice BPTokens which delegate to an implementation
 * @author Ola Finance
 */
contract BPDelegator is BrokerPoolAdminStorage, BPTokenDelegatorInterface {

    function updateImplementationFromRegistry(bool allowResign, bytes calldata becomeImplementationData) external override returns (bool) {
        require(msg.sender == admin, "Not admin");
        address implementationToSet = RegistryForBPDelegator(registry).getLatestImplementationFor(contractNameHash);
        require(implementationToSet != address(0), "No implementation");

        if (implementationToSet != implementation) {
            // New implementations always get set via the setter (post-initialize)
            _setImplementation(implementationToSet, allowResign, becomeImplementationData);
        } else {
            emit ImplementationDidNotChange(implementation);
        }

        return true;
    }

    /**
     * @notice Called by the Comptroller (most of the time) or by the admin (only via the constructor) to update the
     *         implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) internal {
        if (allowResign) {
            delegateToImplementation(abi.encodeWithSignature("_resignImplementation()"));
        }

        // Basic sanity
        require(BrokerPoolInterface(implementation_).isBrokerPool(), "Not Broker Pool");

        address oldImplementation = implementation;
        implementation = implementation_;


        delegateToImplementation(abi.encodeWithSignature("_becomeImplementation(bytes)", becomeImplementationData));

        emit NewImplementation(oldImplementation, implementation);
    }

    /**
     * @notice Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        return delegateTo(implementation, data);
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return abi.decode(returnData, (bytes));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external payable {
        require(msg.value == 0,"BPDelegator:fallback: cannot send value to fallback");

        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./BPDelegator.sol";
/**
 * @title Ola's BPErc20Delegator Contract
 * @notice BPTokens which wrap an EIP-20 underlying and delegate to an implementation
 * @author Ola Finance
 * @dev based on Compound's CErc20Delegator https://github.com/compound-finance/compound-protocol/blob/a3214f67b73310d547e00fc578e8355911c9d376/contracts/CErc20Delegator.sol
 */
contract BPErc20Delegator is BPDelegator, BrokerPoolInterface, Erc20BrokerPoolInterface {
    // OLA_ADDITIONS : This contract name hash
    bytes32 constant public BPErc20DelegatorContractHash = keccak256("BPErc20Delegator");

    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param registry_ The address of the Registry
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param admin_ Address of the administrator of this token
     * @param becomeImplementationData The encoded args for becomeImplementation
     */
    constructor(address underlying_,
                address registry_,
                InterestRateModel interestRateModel_,
                uint initialExchangeRateMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_,
                address payable admin_,
                bytes memory becomeImplementationData) public {
        // Creator of the contract is admin during initialization
        admin = payable(msg.sender);

        // Initialize name hash
        contractNameHash = BPErc20DelegatorContractHash;

        registry = registry_;
        address bpErc20Implementation = RegistryForBPDelegator(registry).getLatestImplementationFor(BPErc20DelegatorContractHash);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(bpErc20Implementation, abi.encodeWithSignature("initialize(address,address,address,uint256,string,string,uint8)",
                                                            registry_,
                                                            underlying_,
                                                            interestRateModel_,
                                                            initialExchangeRateMantissa_,
                                                            name_,
                                                            symbol_,
                                                            decimals_));

        // New implementations always get set via the setter (post-initialize)
        _setImplementation(bpErc20Implementation, false, becomeImplementationData);

        // Set the proper admin now that initialization is done
        admin = admin_;
    }

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint mintAmount) external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("mint(uint256)", mintAmount));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens) external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("redeem(uint256)", redeemTokens));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("redeemUnderlying(uint256)", redeemAmount));
        return abi.decode(data, (uint));
    }

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint borrowAmount) external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("borrow(uint256)", borrowAmount));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint repayAmount) external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("repayBorrow(uint256)", repayAmount));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrowBehalf(address borrower, uint repayAmount) external override  returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("repayBorrowBehalf(address,uint256)", borrower, repayAmount));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint amount) external override returns (bool) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("transfer(address,uint256)", dst, amount));
        return abi.decode(data, (bool));
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external override returns (bool) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("transferFrom(address,address,uint256)", src, dst, amount));
        return abi.decode(data, (bool));
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("approve(address,uint256)", spender, amount));
        return abi.decode(data, (bool));
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view override returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("allowance(address,address)", owner, spender));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view override  returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("balanceOf(address)", owner));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("balanceOfUnderlying(address)", owner));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by Comptroller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (possible error, token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account) external view override returns (uint, uint, uint, uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("getAccountSnapshot(address)", account));
        return abi.decode(data, (uint, uint, uint, uint));
    }

    /**
     * @notice Returns the current per-block borrow interest rate for this cToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view override returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("borrowRatePerBlock()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Returns the current per-block supply interest rate for this cToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view override returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("supplyRatePerBlock()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("totalBorrowsCurrent()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("borrowBalanceCurrent(address)", account));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) public view override returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("borrowBalanceStored(address)", account));
        return abi.decode(data, (uint));
    }

   /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() public override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("exchangeRateCurrent()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() public view override returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("exchangeRateStored()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Get cash balance of this cToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view override returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("getCash()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Get the accrual block number of this cToken
     * @return The accrual block number
     */
    function getAccrualBlockNumber() external view returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("getAccrualBlockNumber()"));
        return abi.decode(data, (uint));
    }

    /**
      * @notice Applies accrued interest to total borrows and reserves.
      * @dev This calculates interest accrued from the last checkpointed block
      *      up to the current block and writes new checkpoint to storage.
      */
    function accrueInterest() public override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("accrueInterest()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (Timelock)
     * @param token The address of the ERC-20 token to sweep
     */
    function sweepToken(EIP20NonStandardInterface token) external override {
        delegateToImplementation(abi.encodeWithSignature("sweepToken(address)", token));
    }


    /*** Admin Functions ***/

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPendingAdmin(address payable newPendingAdmin) external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("_setPendingAdmin(address)", newPendingAdmin));
        return abi.decode(data, (uint));
    }

    /**
      * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
      * @dev Admin function to accrue interest and set a new reserve factor
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setReserveFactor(uint newReserveFactorMantissa) external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("_setReserveFactor(uint256)", newReserveFactorMantissa));
        return abi.decode(data, (uint));
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _acceptAdmin() external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("_acceptAdmin()"));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Accrues interest and reduces reserves by transferring to admin
     * @param reduceAmount Amount of reduction to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReserves(uint reduceAmount) external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("_reduceReserves(uint256)", reduceAmount));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Accrues interest and updates the interest rate model using _setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModel(InterestRateModel newInterestRateModel) public override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("_setInterestRateModel(address)", newInterestRateModel));
        return abi.decode(data, (uint));
    }

    function _setTotalSupplyCap(uint totalSupplyCapUsd_) external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("_setTotalSupplyCap(uint)", totalSupplyCapUsd_));
        return abi.decode(data, (uint));
    }

    function _setTotalBorrowCap(uint totalBorrowCapUsd_) external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("_setTotalBorrowCap(uint)", totalBorrowCapUsd_));
        return abi.decode(data, (uint));
    }

    function _setBorrowerCap(address borrower, uint borrowCapUsd) external override returns (uint) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("_setBorrowerCap(address,uint)", borrower, borrowCapUsd));
        return abi.decode(data, (uint));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "../BPErc20Delegator.sol";

contract BPErc20DelegatorDeployer {
    function deployBPDelegator(
        address underlying_,
        address registry_,
        InterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_,
        address payable admin_
//        bytes calldata becomeImplementationData
    ) external returns (address) {
        BPErc20Delegator bpErc20Delegator = new BPErc20Delegator(underlying_, registry_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_, admin_, new bytes(0));
        address bpErc20DelegatorAddress = address(bpErc20Delegator);

        return bpErc20DelegatorAddress;
    }
}

pragma solidity ^0.8.0;

import "./BaseDoubleKinkRateModelV1.sol";
import "../InterestRateModel.sol";

/**
 * @title Ola's DoubleKinkRateModel Contract V1.
 * @author Ola (Forked from Compound's JumpRateModelV2 contract).
 * @notice Version 1 - using two kink points to adjust the rate multiplier.
 */
contract DoubleKinkRateModelV1 is BaseDoubleKinkRateModelV1 {
    constructor(
        uint256 unitsPerYear,
        uint256 baseRatePerYear,
        uint256 l1MultiplierPerYear,
        uint256 l2MultiplierPerYear,
        uint256 l3MultiplierPerYear,
        uint256 l1Kink_,
        uint256 l2Kink_,
        address owner_
    )
        public
        BaseDoubleKinkRateModelV1(
            unitsPerYear,
            baseRatePerYear,
            l1MultiplierPerYear,
            l2MultiplierPerYear,
            l3MultiplierPerYear,
            l1Kink_,
            l2Kink_,
            owner_
        )
    {}
}

pragma solidity ^0.8.0;

// TODO : Used fixed version
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../InterestRateModel.sol";

/**
 * @title Logic for Ola's DoubleKinkRateModel Contract V1.
 * @author Ola (Forked from Compound's JumpRateModelV2 contract).
 * @notice Version 1 - using two kink points to adjust the rate multiplier.
 */
contract BaseDoubleKinkRateModelV1 is InterestRateModel {
    using SafeMath for uint256;

    event NewInterestParams(
        uint256 baseRatePerUnit,
        uint256 l1MultiplierPerUnit,
        uint256 l2MultiplierPerUnit,
        uint256 l3MultiplierPerUnit,
        uint256 l1Kink,
        uint256 l2Kink
    );

    /**
     * @notice The address of the owner, i.e. the Timelock contract, which can update parameters directly
     */
    address public owner;

    /**
     * @notice The approximate number of blocks per year that is assumed by the interest rate model
     */
    uint256 public unitsPerYear;

    /**
     * @notice The multiplier of utilization rate that gives the slope of the interest rate (first slope)
     */
    uint256 public l1MultiplierPerUnit;

    /**
     * @notice The base interest rate which is the y-intercept when utilization rate is 0
     */
    uint256 public baseRatePerUnit;

    /**
     * @notice The multiplierPerUnit after hitting a the l1Kink point (second slope)
     */
    uint256 public l2MultiplierPerUnit;

    /**
     * @notice The multiplierPerUnit after hitting a the l2Kink point (third slope)
     */
    uint256 public l3MultiplierPerUnit;

    /**
     * @notice The utilization point at which the l2MultiplierPerUnit is applied
     */
    uint256 public l1Kink;

    /**
     * @notice The utilization point at which the l3MultiplierPerUnit is applied
     */
    uint256 public l2Kink;

    /**
     * @notice The rate at the first kink point
     */
    uint256 public l1KinkRate;

    /**
     * @notice The rate at the second kink point
     */
    uint256 public l2KinkRate;

    /**
     * @notice Construct an interest rate model
     * @param unitsPerYear_ The approximate number of blocks per year that is assumed by the interest rate model
     * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     * @param l1MultiplierPerYear The multiplier of utilization rate that gives the slope of the interest rate (scaled by 1e18)
     * @param l2MultiplierPerYear The multiplierPerUnit after hitting a the l1Kink point (scaled by 1e18)
     * @param l3MultiplierPerYear The multiplierPerUnit after hitting a the l2Kink point (scaled by 1e18)
     * @param l1Kink_ The utilization point at which the l2MultiplierPerUnit is applied
     * @param l2Kink_ The utilization point at which the l3MultiplierPerUnit is applied
     * @param owner_ The address of the owner, i.e. the Timelock contract (which has the ability to update parameters directly)
     */
    constructor(
        uint256 unitsPerYear_,
        uint256 baseRatePerYear,
        uint256 l1MultiplierPerYear,
        uint256 l2MultiplierPerYear,
        uint256 l3MultiplierPerYear,
        uint256 l1Kink_,
        uint256 l2Kink_,
        address owner_
    ) {
        owner = owner_;
        unitsPerYear = unitsPerYear_;

        updateDoubleKinkRateModelInternal(
            baseRatePerYear,
            l1MultiplierPerYear,
            l2MultiplierPerYear,
            l3MultiplierPerYear,
            l1Kink_,
            l2Kink_
        );
    }

    /**
     * @notice Update the parameters of the interest rate model (only callable by owner, i.e. Timelock)
     * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     * @param l1MultiplierPerYear The multiplier of utilization rate that gives the slope of the interest rate (scaled by 1e18)
     * @param l2MultiplierPerYear The multiplierPerUnit after hitting a the l1Kink point (scaled by 1e18)
     * @param l3MultiplierPerYear The multiplierPerUnit after hitting a the l2Kink point (scaled by 1e18)
     * @param l1Kink_ The utilization point at which the l2MultiplierPerUnit is applied
     * @param l2Kink_ The utilization point at which the l3MultiplierPerUnit is applied
     */
    function updateDoubleKinkRateModel(
        uint256 baseRatePerYear,
        uint256 l1MultiplierPerYear,
        uint256 l2MultiplierPerYear,
        uint256 l3MultiplierPerYear,
        uint256 l1Kink_,
        uint256 l2Kink_
    ) external {
        require(msg.sender == owner, "only the owner may call this function.");

        updateDoubleKinkRateModelInternal(
            baseRatePerYear,
            l1MultiplierPerYear,
            l2MultiplierPerYear,
            l3MultiplierPerYear,
            l1Kink_,
            l2Kink_
        );
    }

    /**
     * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market (currently unused)
     * @return The utilization rate as a mantissa between [0, 1e18]
     */
    function utilizationRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) public pure returns (uint256) {
        // Utilization rate is 0 when there are no borrows
        if (borrows == 0) {
            return 0;
        }

        return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
    }

    function getL1BorrowRateInternal(uint256 util)
        internal
        view
        returns (uint256)
    {
        return util.mul(l1MultiplierPerUnit).div(1e18).add(baseRatePerUnit);
    }

    function getL2BorrowRateInternal(uint256 util)
        internal
        view
        returns (uint256)
    {
        return
            ((util.sub(l1Kink)).mul(l2MultiplierPerUnit).div(1e18)).add(
                l1KinkRate
            );
    }

    function getL3BorrowRateInternal(uint256 util)
        internal
        view
        returns (uint256)
    {
        return
            ((util.sub(l2Kink)).mul(l3MultiplierPerUnit).div(1e18)).add(
                l2KinkRate
            );
    }

    /**
     * @notice Calculates the current borrow rate per block, with the error code expected by the market
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getBorrowRateInternal(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) internal view returns (uint256) {
        uint256 util = utilizationRate(cash, borrows, reserves);

        if (util <= l1Kink) {
            return getL1BorrowRateInternal(util);
        } else if (util <= l2Kink) {
            return getL2BorrowRateInternal(util);
        } else {
            return getL3BorrowRateInternal(util);
        }
    }

    /**
 * @notice Calculates the current borrow rate per block
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external override view returns (uint256) {
        return getBorrowRateInternal(cash, borrows, reserves);
    }

    /**
     * @notice Calculates the current supply rate per block
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @param reserveFactorMantissa The current reserve factor for the market
     * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) public override view returns (uint256) {
        uint256 oneMinusReserveFactor = uint256(1e18).sub(
            reserveFactorMantissa
        );
        uint256 borrowRate = getBorrowRateInternal(cash, borrows, reserves);
        uint256 rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
        return
            utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
    }

    /**
     * @notice Internal function to update the parameters of the interest rate model
     * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     * @param l1MultiplierPerYear The multiplier of utilization rate that gives the slope of the interest rate (scaled by 1e18)
     * @param l2MultiplierPerYear The multiplierPerUnit after hitting a the l1Kink point (scaled by 1e18)
     * @param l3MultiplierPerYear The multiplierPerUnit after hitting a the l2Kink point (scaled by 1e18)
     * @param l1Kink_ The utilization point at which the l2MultiplierPerUnit is applied
     * @param l2Kink_ The utilization point at which the l3MultiplierPerUnit is applied
     */
    function updateDoubleKinkRateModelInternal(
        uint256 baseRatePerYear,
        uint256 l1MultiplierPerYear,
        uint256 l2MultiplierPerYear,
        uint256 l3MultiplierPerYear,
        uint256 l1Kink_,
        uint256 l2Kink_
    ) internal {
        baseRatePerUnit = baseRatePerYear.div(unitsPerYear);
        l1MultiplierPerUnit = l1MultiplierPerYear.div(unitsPerYear);
        l2MultiplierPerUnit = l2MultiplierPerYear.div(unitsPerYear);
        l3MultiplierPerUnit = l3MultiplierPerYear.div(unitsPerYear);

        require(
            l1Kink_ <= l2Kink_ && l2Kink_ <= 1e18,
            "kinks should be: l1Kink <= l2Kink <= 1e18"
        );

        l1Kink = l1Kink_;
        l2Kink = l2Kink_;

        l1KinkRate = getL1BorrowRateInternal(l1Kink);
        l2KinkRate = getL2BorrowRateInternal(l2Kink);

        emit NewInterestParams(
            baseRatePerUnit,
            l1MultiplierPerUnit,
            l2MultiplierPerUnit,
            l3MultiplierPerUnit,
            l1Kink,
            l2Kink
        );
    }
}

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.0;

import "./BPErc20V0_01.sol";

/**
 * @title Compound's CErc20Immutable Contract
 * @notice CTokens which wrap an EIP-20 underlying and are immutable
 * @author Compound
 */
contract BPErc20ImmutableV0_01 is BPErc20V0_01 {
    /**
     * @notice Construct a new money market
     * @param registry_ The address of the registry
     * @param underlying_ The address of the underlying asset
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param olaBank_ Ola's bank address
     * @param adminBank_ Admin's bank address
     * @param admin_ Address of the administrator of this token
     */
    constructor(RegistryBaseInterface registry_,
                address underlying_,
                InterestRateModel interestRateModel_,
                uint initialExchangeRateMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_,
                address payable olaBank_,
                address payable adminBank_,
                address payable admin_) public {
        // Creator of the contract is admin during initialization
        admin = payable(msg.sender);

        // Initialize the market
        initialize(registry_, underlying_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);

        // Set the proper admin now that initialization is done
        admin = admin_;
    }
}

pragma solidity ^0.8;

import "./BorrowingManager.sol";
import "./CollateralsManager.sol";
import "../Interfaces/MoneyMarket.sol";
import "./BrokerErrorStrings.sol";

abstract contract AssetsManager is
    BorrowingManager,
    CollateralAccounter,
    BrokerErrorStrings
{
    uint256 public collateralLimit = 3e18;
    uint256 public liquidationLimit = 4e18;

    event Deposit(address borrower, address token, uint256 amount);
    event WithdrawCollateral(address borrower, uint256 amount);

    function indexOfAsset(IERC20[] memory arr, IERC20 val) internal returns (uint256) {
        for (uint256 index = 0; index < arr.length; index++) {
            if (arr[index] == val) {
                return index;
            }
        }
        revert(ASSET_NOT_FOUND);
    }

    function initializeAssets(
        IMarketForBroker[] memory _borrowMMs,
        CollateralAsset[] memory _extraCollateralAssets
    ) internal {
        initializeBorrowingManager(_borrowMMs);
        initializeCollateralAccounter(
            createCollateralAssetsArray(_extraCollateralAssets)
        );
    }

    // function arrToMem(IERC20[] storage)

    function newCtx(address user) internal view returns (CTX memory) {
        CTX memory ctx;
        ctx.user = user;
        ctx.collateralAssets = getCollateralAssets();
        ctx.creditingAssets = getCreditingAssets();
        ctx.collateralAmounts = new uint256[](ctx.collateralAssets.length);
        ctx.lazyCollateralAmounts = new LazyState[](ctx.collateralAssets.length);

        ctx.borrowTokens = borrowAssets;
        ctx.positions = new BorrowUserPosition[](ctx.borrowTokens.length);
        ctx.lazyPositions = new LazyState[](ctx.borrowTokens.length);
        ctx.markets = new IMarketForBroker[](ctx.borrowTokens.length);
        for (uint8 index = 0; index < ctx.borrowTokens.length; index++) {
            ctx.markets[index] = moneyMarkets[ctx.borrowTokens[index]];
        }

        return ctx;
    }

    function createCollateralAssetsArray(
        CollateralAsset[] memory _extraCollateralAssets
    ) private view returns (CollateralAsset[] memory) {
        CollateralAsset[] memory collateralAssets = new CollateralAsset[](
            borrowAssets.length + _extraCollateralAssets.length
        );

        uint8 index = 0;
        for (; index < borrowAssets.length; index++) {
            collateralAssets[index] = CollateralAsset(
                borrowAssets[index],
                USE_FOR_CREDIT
            );
        }
        uint8 index2 = 0;
        while (index2 < _extraCollateralAssets.length) {
            collateralAssets[index++] = _extraCollateralAssets[index2++];
        }

        return collateralAssets;
    }

    function flushAssets(CTX memory ctx) internal {
        flushCollateral(ctx);
        flushPositions(ctx);
    }

    function _setAssetOracle(IERC20 asset, IPriceOracleForBroker oracle)
        internal
    {
        if (assetsMap[asset]) {
            _setCollateralAssetOracle(asset, oracle);
        }

        if (address(moneyMarkets[asset]) != address(0)) {
            _setBorrowAssetOracle(asset, oracle);
        }
    }

    function _setCollateralLimit(uint256 limit) internal {
        collateralLimit = limit;
    }

    function _setLiquidationLimit(uint256 limit) internal {
        liquidationLimit = limit;
    }

    function borrowUpdateCollateral(
        CTX memory ctx,
        uint256 assetIndex,
        address user,
        uint256 amount
    ) internal {
        // uint256 assetIndex = indexOfAsset(ctx.collateralAssets, asset);
        IERC20 asset = ctx.collateralAssets[assetIndex];
        uint256 balanceBefore = asset.balanceOf(address(this));
        _borrow(ctx, assetIndex, amount);
        uint256 balanceAfter = asset.balanceOf(address(this));
        uint256 receivedAmount = balanceAfter - balanceBefore;
        addCollateral(ctx, assetIndex, user, receivedAmount);
    }

    function _doTransferIn(
        address from,
        IERC20 token,
        uint256 amount
    ) private returns (uint256 actualReceived) {
        if (0 == amount) {
            return 0;
        }
        uint256 balanceBefore = token.balanceOf(address(this));
        token.transferFrom(from, address(this), amount); // TODO: Safe transfer
        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 actualAmount = balanceAfter - balanceBefore;

        return actualAmount;
    }

    function _deposit(
        CTX memory ctx,
        uint256 assetIndex,
        address borrower,
        uint256 amount
    ) internal returns (uint256 actualReceived) {
        IERC20 asset = ctx.collateralAssets[assetIndex];
        actualReceived = _doTransferIn(borrower, asset, amount);
        addCollateral(ctx, assetIndex, borrower, actualReceived);
        emit Deposit(borrower, address(asset), amount);
    }

    function _doTransferOut(
        IERC20 asset,
        address to,
        uint256 amount
    ) internal {
        asset.transfer(to, amount);
    }

    function _withdraw(
        CTX memory ctx,
        uint256 assetIndex,
        address borrower,
        uint256 amount
    ) internal {
        IERC20 asset = ctx.collateralAssets[assetIndex];
        reduceCollateral(ctx, assetIndex, borrower, amount);
        _doTransferOut(asset, borrower, amount);

        emit WithdrawCollateral(borrower, amount);
    }

    function repayWithCollateral(CTX memory ctx, uint256 assetIndex, address user)
        internal
        returns (BorrowUserPosition memory position)
    {
        IERC20 asset = ctx.collateralAssets[assetIndex];
        uint256 userCollateral = getUserCollateral(ctx, assetIndex, user);
        position = getBorrowPosition(asset, user);
        uint256 userDebt = position.principal;
        uint256 amountToRepay = _min2(userCollateral, userDebt);
        uint256 leftovers = diffOrZero(userCollateral, userDebt);
        if (amountToRepay > 0) {
            setCollateral(ctx, assetIndex, user, leftovers);
            position = _repay(asset, user, amountToRepay);
        }
    }

    function repayAllWithCollateral(CTX memory ctx, address user) internal {
        for (uint8 index = 0; index < borrowAssets.length; index++) {
            repayWithCollateral(ctx, index, user);
        }
    }

    function _creditValue(CTX memory ctx, address borrower)
        internal
        view
        virtual
        returns (uint256)
    {
        return userAllCreditingValue(ctx, borrower);
    }

    function _creditValue(address borrower)
        external
        view
        virtual
        returns (uint256)
    {
        return userAllCreditingValue(newCtx(borrower), borrower);
    }

    /**
     * @notice Returns the level of leverage for the borrower's position in mantissa
     */
    function leverageLevel(CTX memory ctx, address borrower) internal view returns (uint256) {
        uint256 borrowedValue = borrowerBorrowValue(borrower);
        if (borrowedValue == 0) {
            return 1e18;
        }
        uint256 creditValue = _creditValue(ctx, borrower);
        return (creditValue * 1e18) / (creditValue - borrowedValue);
    }
    function leverageLevel(address borrower) external view returns (uint256) {
        return leverageLevel(newCtx(borrower), borrower);
    }

    function verifyLeverageLevel(
        CTX memory ctx, 
        address borrower,
        uint256 maxLeverage,
        string memory errorString
    ) public view {
        require(leverageLevel(ctx, borrower) <= maxLeverage, errorString);
    }

    /**
     * @notice This function assume that the borrowr's principal is updated (after accruing interest)
     */
    function verifyCollateralLimit(CTX memory ctx, address borrower) public view {
        verifyLeverageLevel(ctx,
            borrower,
            collateralLimit,
            COLLATERAL_LIMIT_BREACHED
        );
    }

    function verifyLiquidationLimitBreached(CTX memory ctx, address borrower) public view {
        require(
            leverageLevel(ctx, borrower) > liquidationLimit,
            LIQUIDATION_LIMIT_NOT_BREACHED
        );
    }

    function verifyNoDebt(IERC20 asset, address user) internal view {
        require(
            usersBorrowPositions[asset][user].principal == 0,
            EXPECTED_NO_DEBT
        );
    }
}

pragma solidity ^0.8;

// TODO : Use fixed versions of these repos
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import "../Interfaces/PriceOracle.sol";
import "../Interfaces/MoneyMarket.sol";
import "./DataStructures/BorrowPosition.sol";
import "./DataStructures/BrokerTxContext.sol";


abstract contract BorrowingManager {
    mapping(IERC20 => IMarketForBroker) public moneyMarkets;
    mapping(IERC20 => IPriceOracleForBroker) public borrowAssetsOracles;
    mapping(IERC20 => mapping(address => BorrowUserPosition))
        public usersBorrowPositions;

    IERC20[] public borrowAssets;

    bool private initialized = false;

    event SetOracle(address asset, address oracle);
    event Repay(address asset, address borrower, uint256 amount);
    event Borrow(
        address asset,
        address borrower,
        uint256 amount,
        uint256 positionPrincipal,
        uint256 positionBorrowIndex
    );

    function initializeBorrowingManager(IMarketForBroker[] memory _borrowMMs)
        internal
    {
        require(initialized == false, "Initialized");
        initialized = true;
        for (uint8 index = 0; index < _borrowMMs.length; index++) {
            IMarketForBroker mm = _borrowMMs[index];
            IERC20 asset = IERC20(mm.underlying());
            borrowAssets.push(asset);
            moneyMarkets[asset] = mm;
        }
    }

    function _setBorrowAssetOracle(IERC20 asset, IPriceOracleForBroker oracle)
        internal
    {
        borrowAssetsOracles[asset] = oracle;
        emit SetOracle(address(asset), address(oracle));
    }

    /*******************/
    /****** Logic ******/
    /*******************/

    function _repayAll(IERC20 asset) internal {
        require(
            moneyMarkets[asset].accrueInterest() == 0,
            "accrue interest failed"
        );

        uint256 currentBorrow = calcCurrentBorrowAmount(
            usersBorrowPositions[asset][msg.sender],
            moneyMarkets[asset].borrowIndex()
        );
        _repay(asset, msg.sender, currentBorrow);
    }

    function updateBorrowerPosition(
        IERC20 asset,
        address borrower,
        uint256 borrowAddedAmount,
        uint256 borrowDeductedAmount
    ) internal returns (BorrowUserPosition memory position) {
        // We assume that we already accrued interest


        position = usersBorrowPositions[asset][borrower];

        // IERC20 asset = ctx.borrowTokens[assetIndex];
        uint256 borrowMarketIndex = moneyMarkets[asset].borrowIndex();
        position.principal =
            calcCurrentBorrowAmount(position, borrowMarketIndex) +
            borrowAddedAmount -
            borrowDeductedAmount;
        position.borrowIndex = borrowMarketIndex;

        // ctx.lazyPositions[assetIndex].updated = true;

        usersBorrowPositions[asset][borrower] = position;
    }

    function updateBorrowerPosition(
        CTX memory ctx,
        uint256 assetIndex,
        uint256 borrowAddedAmount,
        uint256 borrowDeductedAmount
    ) internal returns (BorrowUserPosition memory position) {
        // We assume that we already accrued interest


        position = getBorrowPosition(ctx, assetIndex);

        IERC20 asset = ctx.borrowTokens[assetIndex];
        uint256 borrowMarketIndex = moneyMarkets[asset].borrowIndex();
        position.principal =
            calcCurrentBorrowAmount(position, borrowMarketIndex) +
            borrowAddedAmount -
            borrowDeductedAmount;
        position.borrowIndex = borrowMarketIndex;

        ctx.lazyPositions[assetIndex].updated = true;

        // usersBorrowPositions[asset][borrower] = position;
    }

    function updateBorrowerPositionPrincipal(
        IERC20 asset,
        address borrower,
        uint256 addPricipal,
        uint256 reducePrincipal
    ) internal {
        uint256 principalBefore = usersBorrowPositions[asset][borrower]
            .principal;
        usersBorrowPositions[asset][borrower].principal =
            principalBefore +
            addPricipal -
            reducePrincipal;
    }

    // function refreshBorrowerPositionAssets(
    //     CTX memory ctx,
    //     IERC20[] memory assets,
    //     // address borrower
    // ) internal {
    //     // We assume that we already accrued interest
    //     for (uint8 index = 0; index < assets.length; index++) {
    //         updateBorrowerPosition(assets[index], borrower, 0, 0);
    //     }
    // }

    function refreshBorrowerPositionAll(CTX memory ctx) internal {
        for (uint8 index = 0; index < ctx.borrowTokens.length; index++) {
            updateBorrowerPosition(ctx, index, 0, 0);
        }
        // refreshBorrowerPositionAssets(borrowAssets, borrower);
    }

    function _borrow(
        CTX memory ctx,
        uint256 assetIndex,
        // IERC20 asset,
        // address borrower,
        uint256 amount
    ) internal {
        BorrowUserPosition memory position = updateBorrowerPosition(
            ctx,
            assetIndex,
            amount,
            0
        );
        //     asset,
        //     borrower,
        //     amount,
        //     0
        // );
        require(
            0 == ctx.markets[assetIndex].borrow(amount),
            "Failed borrowing"
        );
        emit Borrow(
            address(ctx.borrowTokens[assetIndex]),
            ctx.user,
            amount,
            position.principal,
            position.borrowIndex
        );
    }

    function accrueInterestForAsset(IERC20 asset) internal {
        require(
            moneyMarkets[asset].accrueInterest() == 0,
            "accrue interest failed"
        );
    }

    function accrueInterestAssets(IERC20[] memory assets) internal {
        for (uint8 index = 0; index < assets.length; index++) {
            accrueInterestForAsset(assets[index]);
        }
    }

    function accrueInterestAll(CTX memory ctx) internal {
        accrueInterestAssets(ctx.borrowTokens);
    }

    function flushPositions(CTX memory ctx) internal {
        for (uint8 index = 0; index < ctx.borrowTokens.length; index++) {
            LazyState memory lState = ctx.lazyPositions[index];
            if (lState.updated) {
                IERC20 asset = ctx.borrowTokens[index];
                address user = ctx.user;
                usersBorrowPositions[asset][user] = ctx.positions[index];
            }
        }
    }

    // Assumes interest was accrued already
    function _repay(
        IERC20 asset,
        address borrower,
        uint256 amount
    ) internal returns (BorrowUserPosition memory position) {
        IMarketForBroker market = moneyMarkets[asset];
        uint256 totalDebt = market.borrowBalanceStored(address(this)); // TODO: Borrow balance current
        amount = _min2(totalDebt, amount);
        asset.approve(address(market), amount);
        require(0 == market.repayBorrow(amount), "Failed repay");
        position = updateBorrowerPosition(asset, borrower, 0, amount);

        emit Repay(address(asset), borrower, amount);
    }

    // function _repay_bkp(
    //     IERC20 asset,
    //     address borrower,
    //     uint256 amount,
    //     bool needToAccrue
    // ) internal {
    //     IMarketForBroker market = moneyMarkets[asset];
    //     if (needToAccrue) {
    //         require(market.accrueInterest() == 0, "accrue interest failed");
    //     }
    //     uint256 totalDebt = market.borrowBalanceStored(address(this));
    //     updateBorrowerPosition(asset, borrower, 0, amount);

    //     amount = _min2(totalDebt, amount);
    //     asset.approve(address(market), amount);
    //     require(0 == market.repayBorrow(amount), "Failed repay");

    //     emit Repay(address(asset), borrower, amount);
    // }

    function borrowValue(IERC20 asset, uint256 amount)
        internal
        view
        virtual
        returns (uint256)
    {
        if (amount == 0) return 0;

        IPriceOracleForBroker oracle = borrowAssetsOracles[asset];
        uint256 price = oracle.price(address(asset));
        return
            (price * amount) / (10**IERC20Metadata(address(asset)).decimals());
    }

    function borrowerAssetBorrowValue(IERC20 asset, address borrower)
        public
        view
        virtual
        returns (uint256)
    {
        return
            borrowValue(asset, usersBorrowPositions[asset][borrower].principal);
    }

    function borrowerBorrowValue(address borrower)
        public
        view
        virtual
        returns (uint256 totalDebt)
    {
        totalDebt = 0;
        for (uint8 index = 0; index < borrowAssets.length; index++) {
            totalDebt += borrowerAssetBorrowValue(
                borrowAssets[index],
                borrower
            );
        }
    }

    /*******************/
    /****** Utils ******/
    /*******************/

    function _min2(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _min3(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return _min2(_min2(a, b), c);
    }

    function diffOrZero(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a > b) ? a - b : 0;
    }

    /*******************/
    /****** Views ******/
    /*******************/

    function borrowerBalanceCurrent(IERC20 asset, address borrower)
        external
        returns (uint256)
    {
        IMarketForBroker market = moneyMarkets[asset];
        require(market.accrueInterest() == 0, "accrue interest failed");

        BorrowUserPosition memory position = updateBorrowerPosition(
            asset,
            borrower,
            0,
            0
        );
        return position.principal;
    }

    function calcCurrentBorrowAmount(
        BorrowUserPosition memory position,
        uint256 currentMarketIndex
    ) public pure returns (uint256 updatedAmount) {
        if (0 == position.principal) {
            return 0;
        }
        return (position.principal * currentMarketIndex) / position.borrowIndex;
    }

    function accrueAllAndRefreshPositionsInternal(CTX memory ctx) internal {
        accrueInterestAll(ctx);
        refreshBorrowerPositionAll(ctx);
    }

    function accrueAllAndRefreshPositions(address borrower) external {
        // accrueAllAndRefreshPositionsInternal(borrower);
    }

    function getBorrowPosition(CTX memory ctx, uint256 assetIndex)
        internal
        view
        returns (BorrowUserPosition memory position)
    {
        return lazyReadPosition(ctx, assetIndex);
    }

    function lazyReadPosition(CTX memory ctx, uint256 assetIndex)
        private
        view
        returns (BorrowUserPosition memory position)
    {
        LazyState memory lz = ctx.lazyPositions[assetIndex];
        if (lz.read) {
            position = ctx.positions[assetIndex];
        } else {
            IERC20 asset = ctx.borrowTokens[assetIndex];
            position = usersBorrowPositions[asset][ctx.user];
            ctx.positions[assetIndex] = position;
            lz.read = true;
        }
    }

    function getBorrowPosition(IERC20 asset, address user)
        public
        view
        returns (BorrowUserPosition memory position)
    {
        return usersBorrowPositions[asset][user];
    }

    function getBorrowAssets() external view returns (IERC20[] memory) {
        return borrowAssets;
    }
}

pragma solidity ^0.8;

// TODO : Use fixed versions of these repos
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import "../Interfaces/PriceOracle.sol";
import "./DataStructures/BrokerTxContext.sol";


struct CollateralAsset {
    IERC20 token;
    bool useAsCredit;
}

bool constant USE_FOR_CREDIT = true;
bool constant DONT_USE_FOR_CREDIT = true;

abstract contract CollateralAccounter {
    mapping(IERC20 => mapping(address => uint256)) usersTokensCollaterals;
    mapping(IERC20 => IPriceOracleForBroker) collateralAssetsOracles;
    IERC20[] collateralAssets;
    IERC20[] creditingAssets;
    mapping(IERC20 => bool) assetsMap;

    bool private initialized = false;

    function initializeCollateralAccounter(CollateralAsset[] memory _assets)
        internal
    {
        require(initialized == false, "Initialized");
        initialized = true;

        for (uint8 index = 0; index < _assets.length; index++) {
            CollateralAsset memory asset = _assets[index];
            assetsMap[asset.token] = true;
            collateralAssets.push(asset.token);
            if (asset.useAsCredit) {
                creditingAssets.push(asset.token);
            }
        }
    }

    function setCollateral(
        CTX memory ctx,
        uint256 assetIndex,
        address user,
        uint256 amount
    ) internal returns (uint256 valueBefore) {
        valueBefore = lazyReadCollateral(ctx, assetIndex);

        if (ctx.collateralAmounts[assetIndex] != amount) {
            ctx.lazyCollateralAmounts[assetIndex].updated = true;
        }
        ctx.collateralAmounts[assetIndex] = amount;
    }

    function addCollateral(
        CTX memory ctx,
        uint256 assetIndex,
        address user,
        uint256 amount
    ) internal {
        lazyReadCollateral(ctx, assetIndex);
        LazyState memory lz = ctx.lazyCollateralAmounts[assetIndex];

        if (amount != 0) {
            lz.updated = true;
        }
        ctx.collateralAmounts[assetIndex] += amount;
    }

    function reduceCollateral(
        CTX memory ctx,
        uint256 assetIndex,
        address user,
        uint256 amount
    ) internal {
        lazyReadCollateral(ctx, assetIndex);
        LazyState memory lz = ctx.lazyCollateralAmounts[assetIndex];

        if (amount != 0) {
            lz.updated = true;
        }
        ctx.collateralAmounts[assetIndex] -= amount;
    }

    function lazyReadCollateral(CTX memory ctx, uint256 assetIndex)
        private
        view
        returns (uint256)
    {
        LazyState memory lz = ctx.lazyCollateralAmounts[assetIndex];




        if (lz.read) {
            return ctx.collateralAmounts[assetIndex];
        }
        IERC20 asset = ctx.collateralAssets[assetIndex];
        uint256 value = usersTokensCollaterals[asset][ctx.user];
        ctx.collateralAmounts[assetIndex] = value;
        lz.read = true;

        return value;
    }

    // Returns the user's collateral value before setting it to 0;
    function resetCollateral(
        CTX memory ctx,
        uint256 assetIndex,
        address user
    ) internal returns (uint256 valueBefore) {
        return setCollateral(ctx, assetIndex, user, 0);
    }

    function getUserCollateral(
        CTX memory ctx,
        uint256 assetIndex,
        address user
    ) internal view returns (uint256) {
        return lazyReadCollateral(ctx, assetIndex);
    }

    function getUserCollateral(IERC20 asset, address user)
        external
        view
        returns (uint256)
    {
        return usersTokensCollaterals[asset][user];
    }

    function flushCollateral(CTX memory ctx) internal {
        for (
            uint8 index = 0;
            index < ctx.lazyCollateralAmounts.length;
            index++
        ) {
            LazyState memory lState = ctx.lazyCollateralAmounts[index];
            if (lState.updated) {
                IERC20 asset = ctx.collateralAssets[index];
                address user = ctx.user;
                usersTokensCollaterals[asset][user] = ctx.collateralAmounts[
                    index
                ];
            }
        }
    }

    function _setCollateralAssetOracle(
        IERC20 asset,
        IPriceOracleForBroker oracle
    ) internal {
        collateralAssetsOracles[asset] = oracle;
    }

    function assetPrice(IERC20 asset) public view returns (uint256) {
        IPriceOracleForBroker oracle = collateralAssetsOracles[asset];
        if (IPriceOracleForBroker(address(0)) == oracle) return 0;

        return oracle.price(address(asset));
    }

    function collateralValue(IERC20 asset, uint256 amount)
        internal
        view
        virtual
        returns (uint256)
    {
        if (0 == amount) return 0;
        return
            (assetPrice(asset) * amount) /
            (10**IERC20Metadata(address(asset)).decimals());
    }

    function userCreditValue(
        CTX memory ctx,
        address user,
        uint256 assetIndex
    ) internal view returns (uint256) {
        return
            collateralValue(
                ctx.creditingAssets[assetIndex],
                getUserCollateral(ctx, assetIndex, user)
            );
    }

    function userAllCreditingValue(CTX memory ctx, address user)
        internal
        view
        virtual
        returns (uint256 totalValue)
    {
        totalValue = 0;
        for (uint8 index = 0; index < ctx.creditingAssets.length; index++) {
            totalValue += userCreditValue(ctx, user, index);
        }
    }

    function assetBalance(IERC20 asset) internal view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function getCollateralAssets() public view returns (IERC20[] memory) {
        return collateralAssets;
    }

    function getCreditingAssets() public view returns (IERC20[] memory) {
        return creditingAssets;
    }
}

interface IMarketForBroker {
    function underlying() external view returns (address);

    function borrowIndex() external view returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256 error);

    function repayBorrow(uint256 repayAmount) external returns (uint256 error);

    function accrueInterest() external returns (uint256 error);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);
}

pragma solidity ^0.8.4;

abstract contract BrokerErrorStrings {
    string constant ARRAYS_NOT_SAME_LENGTH = "!Arrays length match";
    string constant TRADER_NOT_WHITELISTED = "!Trader";
    string constant INVALID_MAX_LEVERAGE = "Max leverage invalid";
    string constant MAX_LEVERAGE_BREACHED = "Max leverage breached";
    string constant COLLATERAL_LIMIT_BREACHED = "!CollateralLimit";
    string constant LIQUIDATION_LIMIT_NOT_BREACHED = "!LiquidationLimit";
    string constant EXPECTED_NO_DEBT = "HasDebt";
    string constant ASSET_NOT_FOUND = "Asset not found";
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

interface IPriceOracleForBroker {
    // function getAssetPrice(address asset) external view returns (uint256);
    function price(address asset) external view returns (uint256);
    function admin() external view returns (address);
    function add(address[] calldata underlying, address[] calldata _oracles) external;
    function oracles(address asset) external view returns (address oracle);
}

pragma solidity ^0.8;

struct BorrowUserPosition {
    uint256 principal;
    uint256 borrowIndex;
}

pragma solidity ^0.8;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./BorrowPosition.sol";
import "../../Interfaces/MoneyMarket.sol";

struct LazyState {
    bool read;
    bool updated;
}

struct CTX {
    address user;
    IERC20[] borrowTokens;
    IMarketForBroker[] markets;
    BorrowUserPosition[] positions;
    LazyState[] lazyPositions;
    IERC20[] collateralAssets;
    IERC20[] creditingAssets;
    uint256[] collateralAmounts;
    LazyState[] lazyCollateralAmounts;
    // bool[] rCollateralAmounts;
    // bool[] wCollateralAmounts;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

pragma solidity ^0.8;

// TODO : Use fixed versions of these repos
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./AssetsManager.sol";
import "../Interfaces/PriceOracle.sol";
import "./RegistryInteractor.sol";
import "../Interfaces/Liquidator.sol";

uint256 constant FULL_POSITION_PERCENTAGE = 1e18;

abstract contract BrokerBase is
    AssetsManager,
    RegistryInteractor,
    Ownable,
    ReentrancyGuard
{
    uint256 public liquidatorShare = 0.1 * 1e18;
    uint256 immutable public brokerFee;
    uint256 immutable public interestMultiplier;

    constructor(
        address _owner,
        IRegistryForBroker _registry,
        uint256 _brokerFee,
        uint256 _interestMultiplier
    ) RegistryInteractor(_registry) Ownable() {
        _transferOwnership(_owner);
        brokerFee = _brokerFee;
        interestMultiplier = _interestMultiplier;
    }


    function setAssetOracle(IERC20 asset, IPriceOracleForBroker oracle)
        external
        onlyOwner
    {
        _setAssetOracle(asset, oracle);
    }

    function setCollateralLimit(uint256 limit) external onlyOwner {
        _setCollateralLimit(limit);
    }

    function setLiquidationLimit(uint256 limit) external onlyOwner {
        _setLiquidationLimit(limit);
    }

    function setLiquidatorShare(uint256 share) external onlyOwner {
        liquidatorShare = share;
    }

    // function printCtx(CTX memory ctx) internal {

    //     for (uint8 index = 0; index < ctx.collateralAssets.length; index++) {




    //         LazyState memory lz = ctx.lazyCollateralAmounts[index];


    //     }

    // }

    function deleverageByDeposit(
        address user,
        IERC20[] calldata assets,
        uint256[] calldata amounts
    ) external virtual {
        require(assets.length == amounts.length, ARRAYS_NOT_SAME_LENGTH);
        CTX memory ctx = newCtx(user);
        // printCtx(ctx);
        for (uint8 index = 0; index < assets.length; index++) {
            uint256 assetIndex = indexOfAsset(ctx.collateralAssets, assets[index]);
            _deposit(ctx, assetIndex, user, amounts[index]);
            // printCtx(ctx);
        }

        accrueAllAndRefreshPositionsInternal(ctx);
        repayAllWithCollateral(ctx, user);

        verifyCollateralLimit(ctx, user); // TODO: Consider
        flushAssets(ctx);
    }

    function deleverage(uint256 percentage, bytes calldata data)
        external
        virtual;

    function leverageByWithdraw(
        IERC20[] calldata assets,
        uint256[] calldata amounts
    ) external virtual {
        // require(assets.length == amounts.length, ARRAYS_NOT_SAME_LENGTH);
        // address user = msg.sender;

        // for (uint8 index = 0; index < assets.length; index++) {
        //     _withdraw(assets[index], user, amounts[index]);
        // }
        // verifyCollateralLimit(user);
    }

    function leverage(
        IERC20[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata minAmounts,
        uint256 maxLeverage,
        bytes calldata data
    ) external virtual {
        CTX memory ctx = newCtx(msg.sender);
        // address user = msg.sender;
        require(maxLeverage <= collateralLimit, INVALID_MAX_LEVERAGE);
        require(assets.length == amounts.length, ARRAYS_NOT_SAME_LENGTH);

        accrueAllAndRefreshPositionsInternal(ctx);
        for (uint8 index = 0; index < assets.length; index++) {
            uint256 borrowAssetIndex = indexOfAsset(ctx.borrowTokens, assets[index]);
            borrowUpdateCollateral(ctx, borrowAssetIndex, ctx.user, amounts[index]);
        }

        enterPosition(ctx, data);
        verifyLeverageLevel(ctx, ctx.user, maxLeverage, MAX_LEVERAGE_BREACHED);
        flushAssets(ctx);
    }

    function enterPosition(CTX memory ctx, bytes calldata data) internal virtual {} // TODO: rename to (build/increase...)Position

    function liquidate(address user, bytes calldata data) external virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.4;

import "../Interfaces/Registry.sol";
import "../../TradeAdapters/ITradeAdapter.sol";
import "./BrokerErrorStrings.sol";

contract RegistryInteractor is BrokerErrorStrings {
    IRegistryForBroker registry;

    constructor(IRegistryForBroker _registry) {
        registry = _registry;
    }

    function verifyTraderWhitelisted(ITradeAdapter trader) internal {
        // TODO: Add a cache mechanism
        require(
            registry.isSupportedTradeAdapter(address(trader)) == true,
            TRADER_NOT_WHITELISTED
        );
    }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Liquidator {
    function callback(
        IERC20[] calldata assetsReceived,
        uint256[] calldata amountsReceived,
        IERC20[] calldata assetsRequested,
        uint256[] calldata amountsRequested,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.4;

interface IRegistryForBroker {
    function isSupportedTradeAdapter(address trader) external returns (bool);
}

pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ITradeAdapter {
    function trade(
        IERC20 source,
        IERC20 target,
        uint256 maxAmountIn,
        uint256 wantedOut,
        bytes calldata payload
    ) external returns (uint256);
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "../Brokers/BrokerBase/BrokerBase.sol";
import "../Brokers/Interfaces/PriceOracle.sol";

contract TestLiquidator {
    IERC20[] assets;

    mapping(IERC20 => uint256) assetsAmounts;
    mapping(IERC20 => IPriceOracleForBroker) priceOracles;

    function setPriceOracle(IERC20 asset, IPriceOracleForBroker oracle)
        external
    {
        priceOracles[asset] = oracle;
    }

    function isAssetListed(IERC20 asset) public view returns (bool) {
        for (uint8 index = 0; index < assets.length; index++) {
            if (assets[index] == asset) {
                return true;
            }
        }
        return false;
    }

    function listAssetNotListed(IERC20 asset) internal {
        if (!isAssetListed(asset)) {
            assets.push(asset);
        }
    }

    function liquidate(
        BrokerBase broker,
        address user,
        IERC20[] calldata assets,
        bytes calldata data
    ) external {
        for (uint8 index = 0; index < assets.length; index++) {
            IERC20 asset = assets[index];
            assetsAmounts[asset] = asset.balanceOf(address(this));
        }
        broker.liquidate(user, data);
    }

    function callback(
        IERC20[] calldata assetsReceived,
        uint256[] calldata amountsReceived,
        IERC20[] calldata assetsRequested,
        uint256[] calldata amountsRequested,
        bytes calldata data
    ) external {
        for (uint8 index = 0; index < assetsReceived.length; index++) {
            IERC20 asset = assetsReceived[index];
            uint256 lastAmount = assetsAmounts[asset];
            listAssetNotListed(asset);
            uint256 received = amountsReceived[index];
            uint256 currentAmount = asset.balanceOf(address(this));
            require(
                currentAmount - lastAmount >= received,
                "Liquidator received less than expected"
            );
        }

        for (uint8 index = 0; index < assetsRequested.length; index++) {
            IERC20 asset = assetsRequested[index];
            listAssetNotListed(asset);
            asset.transfer(msg.sender, amountsRequested[index]);
        }
    }

    function lastLiquidationProfit()
        external
        view
        returns (int256 profitValue)
    {
        profitValue = 0;
        for (uint8 index = 0; index < assets.length; index++) {
            IERC20 asset = assets[index];
            int256 currentBalance = int256(asset.balanceOf(address(this)));
            int256 lastBalance = int256(assetsAmounts[asset]);

            int256 assetDiff = currentBalance - lastBalance;
            IPriceOracleForBroker oracle = priceOracles[asset];
            require(address(oracle) != address(0), "No oracle");

            int256 assetPrice = int256(oracle.price(address(asset)));
            int256 assetDiffValue = (assetDiff * assetPrice) /
                int256(10**IERC20Metadata(address(asset)).decimals());

            profitValue += assetDiffValue;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../IPriceOracle.sol";

interface IErc20ForPriceOracle {
    function decimals() external view returns (uint8);
}

abstract contract BasePriceOracle is IPriceOracle, Ownable {

    event NewDecimalsConfiguredForAsset(address indexed asset, uint decimals);

    // Underlying -> assets decimals
    mapping(address => uint8) public assetsDecimals;

    // ******************
    // IPriceOracle Functions
    // ******************

    /**
     * @notice Get the price an asset
     * @param asset The asset to get the price of
     * @return The asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getAssetPrice(address asset) external override view returns (uint) {
        return _getPriceForAssetInternalIfSupported(asset);
    }

    /**
     * @notice Get the price update timestamp for the asset
     * @param asset The asset address for price update timestamp retrieval.
     * @return Last price update timestamp for the asset
     */
    function getAssetPriceUpdateTimestamp(address asset) external override view returns (uint) {
        return _getPriceUpdateTimestampForAssetIfSupported(asset);
    }

    /**
      * @notice Get the underlying price of a pool's asset
      * @param pool The pool to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address pool) external override view returns (uint) {
        return _getPriceForAssetInternalIfSupported(IPoolForPriceOracle(pool).underlying());
    }

    /**
     * @notice Get the price update timestamp for the pool underlying
     * @param pool The pool address for price update timestamp retrieval.
     * @return Last price update timestamp for the underlying asset
     */
    function getUnderlyingPriceUpdateTimestamp(address pool) external override view returns (uint) {
        return _getPriceUpdateTimestampForAssetIfSupported(IPoolForPriceOracle(pool).underlying());
    }

    function isPriceOracle() public override pure returns (bool) {
        return true;
    }

    // ******************
    // Public virtual Functions
    // ******************

    function isAssetSupported(address asset) public view virtual returns (bool) {
        uint8 decimals = assetsDecimals[asset];
        return decimals != 0;
    }

    // ******************
    // Internal Functions
    // ******************

    /**
     * @notice Get the underlying price of an asset
     * @param asset The asset (Erc20 or native)
     * @return The asset price mantissa (scaled by 1e(36 - assetDecimals)).
     *  Zero means the price is unavailable.
     */
    function _getPriceForAssetInternalIfSupported(address asset) internal view returns (uint) {
        if (isAssetSupported(asset)) {
            return getPriceFromSourceInternal(asset);
        } else {
            return 0;
        }
    }

    /**
     * @notice Get the underlying price update timestamp of an asset
     * @param asset The asset (Erc20 or native)
     * @return The asset update timestamp.
     *  Zero means the price update timestamp is unavailable.
     */
    function _getPriceUpdateTimestampForAssetIfSupported(address asset) internal view returns (uint) {
        if (isAssetSupported(asset)) {
            return getPriceUpdateTimestampFromSourceInternal(asset);
        } else {
            return 0;
        }
    }

    /**
     * @notice saves to storage the decimals for the given asset.
     * This is done to reduce future calls gas cost.
     */
    function _setDecimalsForAsset(address _asset) internal {
        uint8 decimalsForAsset;

        if (_asset == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            decimalsForAsset = 18;
        } else {
            decimalsForAsset = IErc20ForPriceOracle(_asset).decimals();
        }

        assetsDecimals[_asset] = decimalsForAsset;

        emit NewDecimalsConfiguredForAsset(_asset, decimalsForAsset);
    }

    // ******************
    // Internal virtual Functions
    // ******************

    /**
     * @notice This function should be implemented to retrieve the price for the asset in question.
     * @param asset The asset in question.
     * @return The asset price mantissa (scaled by 1e(36 - assetDecimals)).
     *  Zero means the price is unavailable.
     */
    function getPriceFromSourceInternal(address asset) internal view virtual returns (uint);

    /**
     * @notice This function should be implemented to retrieve the price update timestamp for the asset in question.
     * @param asset The asset in question.
     */
    function getPriceUpdateTimestampFromSourceInternal(address asset) internal view virtual returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IPoolForPriceOracle {
    function underlying() external view returns (address);
}

interface IPriceOracle {
    // @dev Sanity interface
    function isPriceOracle() external view returns (bool);

    // @return The price scaled to 1e18.
    function getAssetPrice(address asset) external view returns (uint);
    // @return Latest price update timestamp in seconds.
    function getAssetPriceUpdateTimestamp(address asset) external view returns (uint);

    // @return The price scaled to 1e18.
    function getUnderlyingPrice(address cToken) external view returns (uint);
    // @return Latest price update timestamp in seconds.
    function getUnderlyingPriceUpdateTimestamp(address cToken) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "../BasePriceOracle/BasePriceOracle.sol";

/**
 * @title Ola's ChainLink based price oracle.
 * @author Ola
 */
contract FixedPriceOracle is BasePriceOracle {

    // Asset address -> Fixed price for asset
    // Prices should be scaled by 10^18
    mapping(address => uint) public prices;

    event NewFixedPriceForAsset(address indexed asset, uint price);

    // **********
    // ChainLink Feed registration
    // **********

    function _setFixedPriceForUnderlying(address _underlying, uint _price) onlyOwner external {
        _setFixedPriceForUnderlyingInternal(_underlying, _price);
    }

    function _setFixedPricesForUnderlyings(address[] calldata _underlyings, uint[] calldata _prices) onlyOwner external {
        require(_underlyings.length == _prices.length, "underlyings and _prices should be 1:1");

        for (uint i = 0; i < _underlyings.length; i++) {
            _setFixedPriceForUnderlyingInternal(_underlyings[i], _prices[i]);
        }
    }

    function _setFixedPriceForUnderlyingInternal(address underlying, uint fixedPrice) internal {
        uint existingPrice = prices[underlying];

        require(existingPrice == 0, "Cannot reassign feed");

        _setDecimalsForAsset(underlying);

        prices[underlying] = fixedPrice;

        emit NewFixedPriceForAsset(underlying, fixedPrice);
    }

    // **********
    // Implementations from base
    // **********

    /**
     * @notice This function should be implemented to retrieve the price for the asset in question.
     * @param asset The asset in question.
     * @return The asset price mantissa (scaled by 1e(36 - assetDecimals)).
     *  Zero means the price is unavailable.
     */
    function getPriceFromSourceInternal(address asset) internal view override returns (uint) {
        return prices[asset];
    }

    /**
     * @notice This function should be implemented to retrieve the price update timestamp for the asset in question.
     * @param asset The asset in question.
     */
    function getPriceUpdateTimestampFromSourceInternal(address asset) internal view override returns (uint) {
        return 0;
    }

    // **********
    // Utils
    // **********

    /// @dev Overflow proof multiplication
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../BasePriceOracle/BasePriceOracle.sol";

/**
 * @title Ola's ChainLink based price oracle.
 * @author Ola
 */
contract ChainlinkPriceOracle is BasePriceOracle {

    // Underlying -> ChainLink Feed address
    mapping(address => address) public chainLinkFeeds;

    // Underlying -> ChainLink Feed decimals
    mapping(address => uint8) public chainLinkFeedDecimals;

    event NewFeedForAsset(address indexed asset, address oldFeed, address newFeed);
    event NewFeedDecimalsForAsset(address indexed asset, uint8 oldFeedDecimals, uint8 newFeedDecimals);

    // **********
    // Extra views
    // **********

    function hasFeedForAsset(address asset) public view returns (bool) {
        return chainLinkFeeds[asset] != address(0);
    }

    function chainLinkRawReportedPrice(address asset) public view returns (int) {
        return getChainLinkPrice(AggregatorV3Interface(chainLinkFeeds[asset]));
    }

    // **********
    // ChainLink Feed registration
    // **********

    function _setPriceFeedForUnderlying(address _underlying, address _chainlinkFeed, uint8 _priceFeedDecimals) onlyOwner external {
        _setPriceFeedForUnderlyingInternal(_underlying, _chainlinkFeed, _priceFeedDecimals);
    }

    function _setPriceFeedsForUnderlyings(address[] calldata _underlyings, address[] calldata _chainlinkFeeds, uint8[] calldata _priceFeedsDecimals) onlyOwner external {
        require(_underlyings.length == _chainlinkFeeds.length, "underlyings and chainlinkFeeds should be 1:1");
        require(_underlyings.length == _priceFeedsDecimals.length, "underlyings and priceFeedsDecimals should be 1:1");

        for (uint i = 0; i < _underlyings.length; i++) {
            _setPriceFeedForUnderlyingInternal(_underlyings[i], _chainlinkFeeds[i], _priceFeedsDecimals[i]);
        }
    }

    function _setPriceFeedForUnderlyingInternal(address underlying, address chainlinkFeed, uint8 priceFeedDecimals) internal {
        address existingFeed = chainLinkFeeds[underlying];
        uint8 existingDecimals = chainLinkFeedDecimals[underlying];

        require(existingFeed == address(0), "Cannot reassign feed");

        _setDecimalsForAsset(underlying);

        chainLinkFeeds[underlying] = chainlinkFeed;
        chainLinkFeedDecimals[underlying] = priceFeedDecimals;

        emit NewFeedForAsset(underlying, existingFeed, chainlinkFeed);
        emit NewFeedDecimalsForAsset(underlying, existingDecimals, priceFeedDecimals);
    }

    // **********
    // Implementations from base
    // **********

    /**
     * @notice This function should be implemented to retrieve the price for the asset in question.
     * @param asset The asset in question.
     * @return The asset price mantissa (scaled by 1e(36 - assetDecimals)).
     *  Zero means the price is unavailable.
     */
    function getPriceFromSourceInternal(address asset) internal view override returns (uint) {
        int feedPriceRaw = getChainLinkPrice(AggregatorV3Interface(chainLinkFeeds[asset]));
        uint feedPrice = uint(feedPriceRaw);

        // Safety
        require(feedPriceRaw == int(feedPrice), "Price Conversion error");

        uint8 feedDecimals = chainLinkFeedDecimals[asset];

        // Needs to be scaled to e18
        if (feedDecimals == 8) {
            return (mul(1e10, feedPrice));
        } else if (feedDecimals == 18) {
            return feedPrice;
        } else {
            return 0;
        }
    }

    /**
     * @notice This function should be implemented to retrieve the price update timestamp for the asset in question.
     * @param asset The asset in question.
     */
    function getPriceUpdateTimestampFromSourceInternal(address asset) internal view override returns (uint) {
        return getChainLinkUpdateTimestamp(AggregatorV3Interface(chainLinkFeeds[asset]));
    }

    // **********
    // ChainLink reading
    // **********

    function getChainLinkPrice(AggregatorV3Interface priceFeed) internal view returns (int) {
        (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getChainLinkUpdateTimestamp(AggregatorV3Interface priceFeed) internal view returns (uint) {
        (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return timeStamp;
    }

    // **********
    // Utils
    // **********

    /// @dev Overflow proof multiplication
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestTradeAdapter {
    function trade(
        IERC20 source,
        IERC20 target,
        uint256 maxAmountIn,
        uint256 wantedOut,
        bytes calldata payload
    ) external returns (uint256) {
        (uint256 inVal, uint256 outVal) = abi.decode(payload, (uint256, uint256));
        source.transferFrom(msg.sender, address(this), inVal);
        target.transfer(msg.sender, outVal);
        return 0;
    }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Integrations/UniV2/V2PairReader.sol";
import "./ITradeAdapter.sol";

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

contract SimpleV2TradeAdapter is ITradeAdapter, V2PairReader {

    address public immutable v2Factory;
    uint public immutable feeNumerator;
    uint public immutable feeDenominator;

    constructor(address v2Factory_, uint feeNumerator_, uint feeDenominator_) {
        v2Factory = v2Factory_;
        feeNumerator = feeNumerator_;
        feeDenominator = feeDenominator_;

        require(feeNumerator_ < feeDenominator_, "Invalid fees");
    }

    function trade(
        IERC20 source,
        IERC20 target,
        uint256 maxAmountIn,
        uint256 wantedOut,
        bytes calldata payload
    ) external returns (uint256) {
        address tokenIn = address(source);
        address tokenOut = address(target);

        address pair = IUniswapV2PairFactoryForReader(v2Factory).getPair(address(source), address(target));

        require(pair != address(0), "No Direct Pair");

        // Calculate amountOut
        uint amountIn = maxAmountIn;
        (uint reserveIn, uint reserveOut) = getReserves(pair, tokenIn, tokenOut);
        uint amountOutCalculated = getAmountOut(amountIn, reserveIn, reserveOut, feeNumerator, feeDenominator);

        // Gettin the input
        source.transferFrom(msg.sender, address(this), amountIn);

        // Transfer directly to pair
        doSwap(pair, tokenIn, tokenIn < tokenOut, amountIn, amountOutCalculated, address(0));

        uint selfBalance = target.balanceOf(address(this));

        target.transfer(msg.sender, selfBalance);

        // Call

//        (uint256 inVal, uint256 outVal) = abi.decode(payload, (uint256, uint256));
//        source.transferFrom(msg.sender, address(this), inVal);
//        target.transfer(msg.sender, outVal);
        return 0;
    }

    function doSwap(address pair, address tokenIn, bool zeroForOne, uint amountIn, uint amountOut, address to) internal {
        // TODO : use safe transfer instead
        IERC20(tokenIn).transfer(pair, amountIn);

        uint amount0Out = zeroForOne ? 0 : amountOut;
        uint amount1Out = zeroForOne ? amountOut : 0;
        // require(amount0Out == 0 || amount1Out == 0, "amountsOut > 0");
        if (to == address(0)) {
            to = address(this);
        }
        // TODO : verify that the swap passes
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, to, new bytes(0));
    }

    function uniswapV2Call(address sender, uint amount0Out, uint amount1Out, bytes calldata _data) external {

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

//import "@openzeppelin/contracts/math/SafeMath.sol";

interface IUniswapV2PairForReader {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2PairFactoryForReader {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract V2PairReader {
//    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, bytes32 pairCodeHash, address tokenA, address tokenB) internal pure returns (address pair) {
        // already done outside ?
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                pairCodeHash
            )))));
    }

    function pairForFromFactory(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        pair = IUniswapV2PairFactoryForReader(factory).getPair(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2PairForReader(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint feeNumerator, uint feeDenominator) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'getAmountOut:UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'getAmountOut:UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        // note: in ApeSwap: 998; in PancakeSwap: 9975
        uint amountInWithFee = amountIn * feeNumerator;
        uint numerator = amountInWithFee * reserveOut;
        // note: in PancakeSwap: 10000
        uint denominator = (reserveIn * feeDenominator) + (amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint feeNumerator, uint feeDenominator) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'getAmountOut:UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'getAmountOut:UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        // note: in PancakeSwap: 10000
        uint numerator = reserveIn * (amountOut) * (feeDenominator);
        // note: in ApeSwap: 998; in PancakeSwap: 9975
        require(reserveOut > amountOut, "reserveOut < amountOut");
        uint denominator = reserveOut - (amountOut * feeNumerator);
        amountIn = (numerator / denominator) + (1);
    }
}

pragma solidity ^0.8.4;

import "./RegistryInteractor.sol";

abstract contract TradeInteractor is RegistryInteractor {
    function trade(
        ITradeAdapter trader,
        IERC20 assetIn,
        IERC20 assetOut,
        uint256 assetInCollateral,
        uint256 wantedOut,
        bytes memory payload
    ) internal returns (uint256 actualAmountIn, uint256 actualAmountOut) {
        verifyTraderWhitelisted(trader);

        uint256 inBalanceBefore = assetIn.balanceOf(address(this));
        uint256 outBalanceBefore = assetOut.balanceOf(address(this));
        assetIn.approve(address(trader), assetInCollateral);
        trader.trade(assetIn, assetOut, assetInCollateral, wantedOut, payload);
        assetIn.approve(address(trader), 0);

        actualAmountIn = inBalanceBefore - assetIn.balanceOf(address(this));
        actualAmountOut = assetOut.balanceOf(address(this)) - outBalanceBefore;
    }
}

pragma solidity ^0.8.4;

import "../BrokerBase/BrokerBase.sol";
import "../BrokerBase/TradeInteractor.sol";
import "../LiquidatorInteractors/LiquidatorInteractorOneToOneAssets.sol";

contract MarginBroker is
    BrokerBase,
    TradeInteractor,
    LiquidatorInteractorOneToOneAssets
{
    IERC20 immutable borrowAsset;
    IERC20 immutable boughtAsset;

    constructor(
        address _owner,
        IERC20 _boughtAsset,
        IMarketForBroker _borrowMM,
        IPriceOracleForBroker _borrowAssetOracle,
        IPriceOracleForBroker _boughtAssetOracle,
        IRegistryForBroker _registry,
        uint256 _brokerFee,
        uint256 _interestMultiplier
    ) BrokerBase(_owner, _registry, _brokerFee, _interestMultiplier) {
        IMarketForBroker[] memory markets = new IMarketForBroker[](1);
        markets[0] = _borrowMM;

        CollateralAsset[] memory extraAssets = new CollateralAsset[](1);
        extraAssets[0] = CollateralAsset(_boughtAsset, USE_FOR_CREDIT);

        initializeAssets(markets, extraAssets);

        IERC20 _borrowAsset = borrowAssets[0];
        _setAssetOracle(_borrowAsset, _borrowAssetOracle);
        _setAssetOracle(_boughtAsset, _boughtAssetOracle);

        boughtAsset = _boughtAsset;
        borrowAsset = _borrowAsset;
    }

    function deleverage(uint256 percentage, bytes calldata data)
        external
        virtual
        override
    {
        // address user = msg.sender;
        // accrueAllAndRefreshPositionsInternal(user);

        // reducePosition(user, percentage, data);
        // repayWithCollateral(borrowAsset, user);

        // verifyCollateralLimit(user);
    }

    function liquidate(address user, bytes calldata data)
        external
        virtual
        override
    {
        // Liquidator liquidator = Liquidator(msg.sender);

        // accrueAllAndRefreshPositionsInternal(user);
        // verifyLiquidationLimitBreached(user);

        // uint256 debt0 = borrowerBorrowValue(user);
        // uint256 liquidatorRewardValue = (debt0 * liquidatorShare) / 1e18;

        // uint256 userBoughtAssetAmount = getUserCollateral(boughtAsset, user);
        // uint256 amountForLiquidator = _min2(
        //     ((liquidatorRewardValue + debt0) * 1e18) / assetPrice(boughtAsset),
        //     userBoughtAssetAmount
        // );
        // reduceCollateral(boughtAsset, user, amountForLiquidator);

        // uint256 borrowAssetReceived = callLiquidator(
        //     liquidator,
        //     boughtAsset,
        //     amountForLiquidator,
        //     borrowAsset,
        //     getBorrowPosition(borrowAsset, user).principal,
        //     data
        // );
        // addCollateral(borrowAsset, user, borrowAssetReceived);
        // repayWithCollateral(borrowAsset, user);
        // verifyNoDebt(borrowAsset, user);
    }

    function enterPosition(CTX memory ctx, bytes calldata data)
        internal
        virtual
        override
    {
        (ITradeAdapter trader, bytes memory tradeData) = abi.decode(
            data,
            (ITradeAdapter, bytes)
        );
        uint256 borrowAssetIndex = indexOfAsset(ctx.collateralAssets, borrowAsset);
        uint256 boughtAssetIndex = indexOfAsset(ctx.collateralAssets, boughtAsset);
        uint256 collateral = getUserCollateral(ctx, borrowAssetIndex, ctx.user);

        // Maybe set collateral to 0
        (uint256 amountIn, uint256 amountOut) = trade(
            trader,
            borrowAsset,
            boughtAsset,
            collateral,
            0,
            tradeData
        );

        reduceCollateral(ctx, borrowAssetIndex, ctx.user, amountIn);
        addCollateral(ctx, boughtAssetIndex, ctx.user, amountOut);
    }

    function reducePosition(
        address user,
        uint256 percentage,
        bytes calldata data
    ) internal {
        // (ITradeAdapter trader, bytes memory tradeData) = abi.decode(
        //     data,
        //     (ITradeAdapter, bytes)
        // );

        // uint256 sellAmount = (getUserCollateral(boughtAsset, user) *
        //     percentage) / 1e18;


        // // Maybe set collateral to 0
        // (uint256 amountIn, uint256 amountOut) = trade(
        //     trader,
        //     boughtAsset,
        //     borrowAsset,
        //     sellAmount,
        //     getBorrowPosition(borrowAsset, user).principal,
        //     tradeData
        // );

        // reduceCollateral(boughtAsset, user, amountIn); // Maybe move partially before
        // addCollateral(borrowAsset, user, amountOut);
    }
}

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Interfaces/Liquidator.sol";

contract LiquidatorInteractorOneToOneAssets {
    function callLiquidator(
        Liquidator liquidator,
        IERC20 sendAsset,
        uint256 amountSendToLiquidator,
        IERC20 borrowAsset,
        uint256 debtUnits,
        bytes calldata data
    ) internal returns (uint256 borrowAssetReceived) {
        IERC20[] memory assetsSent = new IERC20[](1);
        uint256[] memory amountsSent = new uint256[](1);
        IERC20[] memory assetsRequesting = new IERC20[](1);
        uint256[] memory amountsRequesting = new uint256[](1);

        assetsSent[0] = sendAsset;
        amountsSent[0] = amountSendToLiquidator;
        assetsRequesting[0] = borrowAsset;
        amountsRequesting[0] = debtUnits;

        sendAsset.transfer(address(liquidator), amountSendToLiquidator);
        uint256 amountBorrowAssetBefore = borrowAsset.balanceOf(address(this));
        liquidator.callback(
            assetsSent,
            amountsSent,
            assetsRequesting,
            amountsRequesting,
            data
        );
        borrowAssetReceived =
            borrowAsset.balanceOf(address(this)) -
            amountBorrowAssetBefore;
    }
}

pragma solidity ^0.8;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./BrokerErrorStrings.sol";

contract Utils is BrokerErrorStrings {
    function indexOfAsset(IERC20[] memory arr, IERC20 val) internal returns (uint256) {
        for (uint256 index = 0; index < arr.length; index++) {
            if (arr[index] == val) {
                return index;
            }
        }
        revert(ASSET_NOT_FOUND);
    }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISwapperForBroker {
    function swap(
        IERC20 assetIn,
        IERC20 assetOut,
        bytes memory data
    ) external returns (uint256 amountIn, uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./ILocalToken.sol";

contract TestErc20 is ERC20, ILocalToken {
    string constant  public localTokenType = "TestErc20";

    uint8 _tokenDecimals;

    function getLocalTokenType() external pure override returns (string memory) {
        return localTokenType;
    }

    constructor (string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _tokenDecimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _tokenDecimals;
    }

    function mint(address account, uint256 amount) external virtual {
        _mint(account, amount);


    }

    function burn(address account, uint256 amount) external virtual {
        _burn(account, amount);
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {


        _approve(_msgSender(), spender, amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILocalToken {
    function getLocalTokenType() external view returns (string calldata );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


import "./ILocalToken.sol";

// taken from : https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
contract TestWrappedNative is ILocalToken {
    string constant public localTokenType = "TestWrappedNative";

    function getLocalTokenType() external pure override returns (string memory) {
        return localTokenType;
    }

    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function deposit() external payable {

        depositInternal(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {

        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    // DEV_NOTE : This function is here to match the 'TestErc20' format
    function mint(address account, uint256 amount) external {
        balanceOf[account] += amount;



    }

//    function receive() external payable {

//        depositInternal(msg.sender, msg.value);
//    }

//    fallback() external payable {

//        depositInternal(msg.sender, msg.value);
//    }

    function totalSupply() public view returns (uint) {
        return (address(this)).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
    public
    returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    function depositInternal(address account, uint amount) internal {
        balanceOf[account] += amount;
        emit Deposit(account, amount);
    }
}


/*
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    <program>  Copyright (C) <year>  <name of author>
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, your program's commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.

*/

pragma solidity ^0.8.4;

import "../Brokers/BrokerBase/BrokerBase.sol";

struct CollateralState {
    IERC20 asset;
    uint256 amount;
}

struct UserState {
    uint256 creditValue;
    uint256 borrowValue;
    uint256 leverageLevel;
    CollateralState[] borrowPrincipals;
    CollateralState[] collateralAmounts;
    IERC20[] creditingAssets;
}

contract BrokerLens {
    function getCollaterals(BrokerBase broker, address user)
        public
        view
        returns (CollateralState[] memory state)
    {
        IERC20[] memory assets = broker.getCollateralAssets();
        state = new CollateralState[](assets.length);
        for (uint8 index = 0; index < assets.length; index++) {
            IERC20 asset = assets[index];
            state[index].asset = asset;
            state[index].amount = broker.getUserCollateral(asset, user);
        }
    }

    function getBorrows(BrokerBase broker, address user)
        public
        view
        returns (CollateralState[] memory state)
    {
        IERC20[] memory assets = broker.getBorrowAssets();
        state = new CollateralState[](assets.length);
        for (uint8 index = 0; index < assets.length; index++) {
            IERC20 asset = assets[index];
            (uint256 principal, ) = broker.usersBorrowPositions(asset, user);
            state[index].amount = principal;
            state[index].asset = asset;
        }
    }

    function getUserState(BrokerBase broker, address user)
        public
        view
        returns (UserState memory state)
    {
        state.borrowPrincipals = getBorrows(broker, user);
        state.collateralAmounts = getCollaterals(broker, user);
        state.creditingAssets = broker.getCreditingAssets();

        state.creditValue = broker._creditValue(user);
        state.borrowValue = broker.borrowerBorrowValue(user);
        state.leverageLevel = broker.leverageLevel(user);
    }

    function getUserStateWithAccrue(BrokerBase broker, address user)
        external
        returns (UserState memory)
    {
        broker.accrueAllAndRefreshPositions(user);
        return getUserState(broker, user);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/// @title Ola Base Ministry Factory
/// @notice Manages access to factory to only allow calls from the Ministry.
contract BaseMinistryFactory {
    address public ministry;

    constructor(address _ministry) {
        ministry = _ministry;
    }

    function isFromMinistry() internal view returns (bool) {
        return msg.sender == ministry;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "../../../Factories/BaseMinistryFactory.sol";
import "../../../Factories/Delegators/IBPDelegatorMInistryFactory.sol";

interface IBPDelegatorDeployerForFactoryV0_01 {
    function deployBPDelegator(
        address underlying_,
        address comptroller_,
        address interestRateModel_,
        uint initialExchangeRateMantissa_,
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_,
        address payable admin_
//        bytes calldata becomeImplementationData
    ) external returns (address);
}

interface IErc20ForDelegatorFactoryV0_01 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory );
    function symbol() external view returns (string memory);
}

/// @title Ola BPDelegator Ministry Factory
/// @notice Manages deployment of BPDelegators for the ministry.
contract BPDelegatorFactoryV0_01 is BaseMinistryFactory, IBPDelegatorMinistryFactory {
//    using SafeMath for uint;

    bytes32 constant public BPErc20DelegatorContractHash = keccak256("BPErc20Delegator");

    IBPDelegatorDeployerForFactoryV0_01 public bpErc20DelegatorDeployer;

    // All BPTokens will have 8 decimals
    uint8 public bpDelegatorDecimals = 8;

    // All BPNativeDelegators will start with the exact same exchange rate mantissa (0.02 scaled by native decimals + 10, so 28)
    uint public initialExchangeRateMantissaForNative = 200000000000000000000000000;

    constructor(address _ministry, address bpErc20DelegatorDeployerAddress) BaseMinistryFactory(_ministry){
        bpErc20DelegatorDeployer = IBPDelegatorDeployerForFactoryV0_01(bpErc20DelegatorDeployerAddress);
    }

    struct bpDelegatorDeploymentParameters {
        uint initialExchangeRateMantissa;
        string name;
        string symbol;
        uint8 decimals;
    }

    function deployBPDelegator(
        address underlying,
        bytes32 contractNameHash,
        bytes calldata params,
        address interestRateModel,
        address payable admin,
        bytes calldata becomeImplementationData
    ) external override returns (address) {
        // TODO : Return the requirement for production
        // Ensure ministry is the caller
        // require(isFromMinistry(), "Only the Ministry can call the factory");

        IBPDelegatorDeployerForFactoryV0_01 deployer;
        address deployedContract;

        bpDelegatorDeploymentParameters memory bpDelegatorDeploymentParameters;
        bpDelegatorDeploymentParameters.decimals = bpDelegatorDecimals;

        if (underlying == nativeCoinUnderlying) {
            revert("BrokerPool not available for the native coin");
        } else {
            if (contractNameHash == BPErc20DelegatorContractHash) {
                deployer = bpErc20DelegatorDeployer;

                uint8 underlyingDecimals = IErc20ForDelegatorFactoryV0_01(underlying).decimals();

                // Calculate parameters for ERC20
                bpDelegatorDeploymentParameters.initialExchangeRateMantissa = calculateInitialExchangeRateMantissaForBPERC20(underlyingDecimals);
                bpDelegatorDeploymentParameters.name = concat("BrokerPool ", IErc20ForDelegatorFactoryV0_01(underlying).name());
                bpDelegatorDeploymentParameters.symbol = concat("bp", IErc20ForDelegatorFactoryV0_01(underlying).symbol());

            } else {
                revert("Unsupported contract name hash for ERC20 token");
            }
        }

        deployedContract = deployer.deployBPDelegator(
            underlying,
            ministry,
            interestRateModel,
            bpDelegatorDeploymentParameters.initialExchangeRateMantissa,
            bpDelegatorDeploymentParameters.name,
            bpDelegatorDeploymentParameters.symbol,
            bpDelegatorDeploymentParameters.decimals,
            admin
//            becomeImplementationData
        );

        return deployedContract;
    }

    /*** Internal utils ***/

    /// @notice Util for concatenating strings
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    /// @notice Calculate the initial exchange rate mantissa (0.02 scaled by underlyingDecimals + 10)
    function calculateInitialExchangeRateMantissaForBPERC20(uint8 underlyingDecimals) internal pure returns (uint) {
        // Sanity
        require(underlyingDecimals <= 30, "Too big decimals");

        // 0.02 * (e10)
        uint baseInitialExchangeRateScaledBy10 = 200000000;
        uint initialExchangeRateMantissa = baseInitialExchangeRateScaledBy10 * (10 ** underlyingDecimals);

        return initialExchangeRateMantissa;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/// @title Ola BPDelegator Ministry Factory
/// @notice Manages deployment of BPDelegators for the ministry.
abstract contract  IBPDelegatorMinistryFactory {
    address constant public nativeCoinUnderlying = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function deployBPDelegator(address underlying, bytes32 contractNameHash, bytes calldata params, address interestRateModel_, address payable admin, bytes calldata becomeImplementationData) external virtual returns (address);
}

interface IERC20ForBroker {
    function decimals() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

pragma solidity ^0.8;
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

interface ISwapPool {
    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function token0() external returns (address);

    function token1() external returns (address);
}

interface IERC20ForSwapUniV3 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

abstract contract SwapUniV3 {
    ISwapPool pool;
    IERC20ForSwapUniV3 token0;
    IERC20ForSwapUniV3 token1;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 private constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 private constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    constructor(ISwapPool _pool) {
        pool = _pool;
        token0 = IERC20ForSwapUniV3(_pool.token0());
        token1 = IERC20ForSwapUniV3(_pool.token1());
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint160 sqrtPriceLimitX96,
        uint256 maxAmountIn
    ) internal returns (uint256 amountIn) {
        bool zeroForOne = tokenOut == address(token1);
        // IERC20ForSwapUniV3 inToken = zeroForOne ? token0 : token1;

        (int256 amount0, int256 amount1) = pool.swap(
            address(this),
            zeroForOne,
            int256(amount),
            sqrtPriceLimitX96 == 0
                ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1)
                : sqrtPriceLimitX96,
            ""
            // abi.encode(address(inToken))
        );

        uint256 amountOut;
        (amountIn, amountOut) = zeroForOne
            ? (uint256(amount0), uint256(-amount1))
            : (uint256(-amount0), uint256(amount1));

        require(amountOut == amount, "!Swap amount");
        require(amountIn <= maxAmountIn, "Swap in too much");
    }

    function uniswapV3SwapCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata path
    ) external {
        require(address(pool) == msg.sender);

        if (amount0 > 0) {
            token0.transfer(address(pool), amount0);
            return;
        }

        token1.transfer(address(pool), amount1);

        // IERC20ForSwapUniV3 inToken = IERC20ForSwapUniV3(
        //     abi.decode(data, (address))
        // );

        // uint256 amount = (amount0 > 0) ? amount0 : amount1;

        // inToken.transfer(address(pool), amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log


contract Lock {
    uint public unlockTime;
    address payable public owner;

    event Withdrawal(uint amount, uint when);

    constructor(uint _unlockTime) payable {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );

        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    function withdraw() public {
        // Uncomment this line to print a log in your terminal


        require(block.timestamp >= unlockTime, "You can't withdraw yet");
        require(msg.sender == owner, "You aren't the owner");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}
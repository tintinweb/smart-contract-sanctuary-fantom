// SPDX-License-Identifier: AGPL-3.0-or-later
pragma abicoder v2;
pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

import './interfaces/IPriceOracleAggregator.sol';

interface IOwnableUpgradeable {
    function policy() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

abstract contract OwnableUpgradeable is
    IOwnableUpgradeable,
    Initializable,
    ContextUpgradeable
{
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function renounceManagement() public virtual override onlyPolicy {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_)
        public
        virtual
        override
        onlyPolicy
    {
        require(
            newOwner_ != address(0),
            'Ownable: new owner is the zero address'
        );
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, 'Ownable: must be new owner to pull');
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

library CountersUpgradeable {
    struct Counter {
        uint256 _value; // default: 0
    }

    function init(Counter storage counter, uint256 _initValue) internal {
        counter._value = _initValue;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value - 1;
    }
}

contract BondNoTreasury is OwnableUpgradeable, PausableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ======== EVENTS ======== */

    event BondCreated(
        uint256 depositId,
        address principal,
        uint256 deposit,
        uint256 indexed payout,
        uint256 indexed expires,
        uint256 indexed priceInUSD
    );
    event BondRedeemed(
        uint256 depositId,
        address indexed recipient,
        uint256 payout,
        uint256 remaining
    );

    /* ======== STATE VARIABLES ======== */

    address public rewardToken; // token given as payment for bond
    address public DAO; // receives profit share from bond
    IPriceOracleAggregator public priceOracleAggregator; // bond price oracle aggregator

    uint256 rewardUnit; // HEC: 1e9, WETH: 1e18

    address[] public principals; // tokens used to create bond
    mapping(address => bool) public isPrincipal; // is token used to create bond

    CountersUpgradeable.Counter public depositIdGenerator; // id for each deposit
    mapping(address => mapping(uint256 => uint256)) public ownedDeposits; // each wallet owned index=>depositId
    mapping(uint256 => uint256) public depositIndexes; // each depositId and its index in ownedDeposits
    mapping(address => uint256) public depositCounts; // each wallet total deposit count

    mapping(uint256 => Bond) public bondInfo; // stores bond information for depositId

    uint256[] public lockingPeriods; // stores locking periods of discounts
    mapping(uint256 => uint256) public lockingDiscounts; // stores discount in hundreths for locking periods ( 500 = 5% = 0.05 )

    uint256 public totalRemainingPayout; // total remaining rewardToken payout for bonding
    uint256 public totalBondedValue; // total amount of payout assets sold to the bonders
    mapping(address => uint256) public totalPrincipals; // total principal bonded through this depository

    uint256 public minimumPrice; //min price

    string public name; // name of this bond

    string public constant VERSION = '3.0'; // version number

    enum CONFIG {
        DEPOSIT_TOKEN,
        FEE_RECIPIENT,
        FUND_RECIPIENT
    }
    mapping(CONFIG => bool) public initialized;
    uint256 constant ONEinBPS = 10000;
    uint256 public feeBps; // 10000=100%, 100=1%
    address public fundRecipient;
    mapping(address => mapping(address => uint256)) public tokenBalances; // balances for each deposit token
    // address[] public depositTokens;
    address[] public feeRecipients;
    uint256[] public feeWeightBps;
    mapping(address => uint256) feeWeightFor; // feeRecipient=>feeWeight

    /* ======== STRUCTS ======== */

    // Info for bond holder
    struct Bond {
        uint256 depositId; // deposit Id
        address principal; // token used to create bond
        uint256 amount; // princial deposited amount
        uint256 payout; // rewardToken remaining to be paid
        uint256 vesting; // Blocks left to vest
        uint256 lastBlockAt; // Last interaction
        uint256 pricePaid; // In DAI, for front end viewing
        address depositor; //deposit address
    }

    /* ======== INITIALIZATION ======== */

    function initialize(
        string memory _name,
        address _rewardToken,
        address _DAO,
        address _priceOracleAggregator
    ) external initializer {
        require(_rewardToken != address(0));
        rewardToken = _rewardToken;
        require(_DAO != address(0));
        DAO = _DAO;
        require(_priceOracleAggregator != address(0));
        priceOracleAggregator = IPriceOracleAggregator(_priceOracleAggregator);

        name = _name;
        rewardUnit = 10**(IERC20MetadataUpgradeable(_rewardToken).decimals());
        depositIdGenerator.init(1); //id starts with 1 for better handling in mapping of case NOT FOUND

        __Ownable_init();
        __Pausable_init();
    }

    /* ======== MODIFIER ======== */
    modifier onlyPrincipal(address _principal) {
        require(isPrincipal[_principal], 'Invalid principal');
        _;
    }

    /* ======== INIT FUNCTIONS ======== */

    /**
     *  @notice initialize fee recipients and split percentage for each of them, in basis points
     */
    function initializeFeeRecipient(
        address[] memory recipients,
        uint256[] memory weightBps
    ) external onlyPolicy {
        require(!initialized[CONFIG.FEE_RECIPIENT], 'initialzed already');
        initialized[CONFIG.FEE_RECIPIENT] = true;

        require(
            initialized[CONFIG.FUND_RECIPIENT],
            'need to run initializeFundReceipient first'
        );
        require(
            recipients.length > 0,
            'there shall be at least one fee recipient'
        );
        require(
            recipients.length == weightBps.length,
            'number of recipients and number of weightBps should match'
        );

        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                weightBps[i] > 0,
                'all weight in weightBps should be greater than 0'
            );
            total += weightBps[i];

            require(
                recipients[i] != fundRecipient,
                'address in recipients can be the same as fundRecipient'
            );
            require(
                feeWeightFor[recipients[i]] == 0,
                'duplicated address detected in recipients'
            );
            feeWeightFor[recipients[i]] = weightBps[i];
        }
        require(total == ONEinBPS, 'the sum of weightBps should be 10000');
        feeRecipients = recipients;
        feeWeightBps = weightBps;
    }

    /**
     *  @notice initialize deposit token types, should be stable coins
     */
    function initializeDepositTokens(address[] memory _principals)
        external
        onlyPolicy
    {
        require(!initialized[CONFIG.DEPOSIT_TOKEN], 'initialzed already');
        initialized[CONFIG.DEPOSIT_TOKEN] = true;

        require(
            _principals.length > 0,
            'principals need to contain at least one token'
        );

        principals = _principals;

        for (uint256 i = 0; i < _principals.length; i++) {
            isPrincipal[_principals[i]] = true;
        }
    }

    /**
     *  @notice initialize the fund recipient and the fee percentage in basis points
     */
    function initializeFundRecipient(address _fundRecipient, uint256 _feeBps)
        external
        onlyPolicy
    {
        require(!initialized[CONFIG.FUND_RECIPIENT], 'initialzed already');
        initialized[CONFIG.FUND_RECIPIENT] = true;

        require(_fundRecipient != address(0), '_fundRecipient address invalid');
        fundRecipient = _fundRecipient;

        feeBps = _feeBps;
    }

    /* ======== POLICY FUNCTIONS ======== */

    /**
     *  @notice set discount for locking period
     *  @param _lockingPeriod uint
     *  @param _discount uint
     */
    function setLockingDiscount(uint256 _lockingPeriod, uint256 _discount)
        external
        onlyPolicy
    {
        require(_lockingPeriod > 0, 'Invalid locking period');
        require(_discount < ONEinBPS, 'Invalid discount');

        // remove locking period
        if (_discount == 0) {
            uint256 length = lockingPeriods.length;
            for (uint256 i = 0; i < length; i++) {
                if (lockingPeriods[i] == _lockingPeriod) {
                    lockingPeriods[i] = lockingPeriods[length - 1];
                    delete lockingPeriods[length - 1];
                    lockingPeriods.pop();
                }
            }
        }
        // push if new locking period
        else if (lockingDiscounts[_lockingPeriod] == 0) {
            lockingPeriods.push(_lockingPeriod);
        }

        lockingDiscounts[_lockingPeriod] = _discount;
    }

    function setMinPrice(uint256 _minimumPrice) external onlyPolicy {
        minimumPrice = _minimumPrice;
    }

    function updateName(string memory _name) external onlyPolicy {
        name = _name;
    }

    function updateFundWeights(address _fundRecipient, uint256 _feeBps)
        external
        onlyPolicy
    {
        require(initialized[CONFIG.FUND_RECIPIENT], 'not yet initialzed');

        require(_fundRecipient != address(0), '_fundRecipient address invalid');
        fundRecipient = _fundRecipient;

        feeBps = _feeBps;
    }

    function updateFeeWeights(
        address[] memory recipients,
        uint256[] memory weightBps
    ) external onlyPolicy {
        require(initialized[CONFIG.FEE_RECIPIENT], 'not yet initialzed');

        require(
            recipients.length > 0,
            'there shall be at least one fee recipient'
        );
        require(
            recipients.length == weightBps.length,
            'number of recipients and number of weightBps should match'
        );

        for (uint256 i = 0; i < feeRecipients.length; i++) {
            feeWeightFor[feeRecipients[i]] = 0;
        }

        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                weightBps[i] > 0,
                'all weight in weightBps should be greater than 0'
            );
            total += weightBps[i];

            require(
                recipients[i] != fundRecipient,
                'address in recipients can be the same as fundRecipient'
            );
            require(
                feeWeightFor[recipients[i]] == 0,
                'duplicated address detected in recipients'
            );
            feeWeightFor[recipients[i]] = weightBps[i];
        }

        require(total == ONEinBPS, 'the sum of weightBps should be 10000');
        feeRecipients = recipients;
        feeWeightBps = weightBps;
    }

    function updatePriceOracleAggregator(address _priceOracleAggregator)
        external
        onlyPolicy
    {
        require(_priceOracleAggregator != address(0), 'Invalid address');

        priceOracleAggregator = IPriceOracleAggregator(_priceOracleAggregator);
    }

    function pause() external onlyPolicy whenNotPaused {
        return _pause();
    }

    function unpause() external onlyPolicy whenPaused {
        return _unpause();
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _principal address
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _lockingPeriod uint
     *  @return uint
     */
    function deposit(
        address _principal,
        uint256 _amount,
        uint256 _maxPrice,
        uint256 _lockingPeriod
    ) external onlyPrincipal(_principal) whenNotPaused returns (uint256) {
        require(_amount > 0, 'Amount zero');

        uint256 discount = lockingDiscounts[_lockingPeriod];
        require(discount > 0, 'Invalid locking period');

        uint256 priceInUSD = (bondPriceInUSD() * (ONEinBPS - discount)) /
            ONEinBPS; // Stored in bond info

        {
            uint256 nativePrice = (_bondPrice() * (ONEinBPS - discount)) /
                ONEinBPS;
            require(
                _maxPrice >= nativePrice,
                'Slippage limit: more than max price'
            ); // slippage protection
        }

        uint256 payout = payoutFor(_principal, _amount, discount); // payout to bonder is computed
        require(payout >= (rewardUnit / 100), 'Bond too small'); // must be > 0.01 rewardToken ( underflow protection )

        // total remaining payout is increased
        totalRemainingPayout = totalRemainingPayout + payout;
        require(
            totalRemainingPayout <=
                IERC20Upgradeable(rewardToken).balanceOf(address(this)),
            'Insufficient rewardToken'
        ); // has enough rewardToken balance for payout

        // total bonded value is increased
        totalBondedValue = totalBondedValue + payout;

        /**
            principal is transferred
         */
        IERC20Upgradeable(_principal).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        totalPrincipals[_principal] = totalPrincipals[_principal] + _amount;

        uint256 depositId = depositIdGenerator.current();
        depositIdGenerator.increment();
        // depositor info is stored
        bondInfo[depositId] = Bond({
            depositId: depositId,
            principal: _principal,
            amount: _amount,
            payout: payout,
            vesting: _lockingPeriod,
            lastBlockAt: block.timestamp,
            pricePaid: priceInUSD,
            depositor: msg.sender
        });

        ownedDeposits[msg.sender][depositCounts[msg.sender]] = depositId;
        depositIndexes[depositId] = depositCounts[msg.sender];
        depositCounts[msg.sender] = depositCounts[msg.sender] + 1;

        // indexed events are emitted
        emit BondCreated(
            depositId,
            _principal,
            _amount,
            payout,
            block.timestamp + _lockingPeriod,
            priceInUSD
        );

        processFee(_principal, _amount); // distribute fee

        return payout;
    }

    /**
     *  @notice redeem bond for user
     *  @param _depositId uint
     *  @return uint
     */
    function redeem(uint256 _depositId)
        external
        whenNotPaused
        returns (uint256)
    {
        Bond memory info = bondInfo[_depositId];
        address _recipient = info.depositor;
        require(msg.sender == _recipient, 'Cant redeem others bond');

        uint256 percentVested = percentVestedFor(_depositId); // (blocks since last interaction / vesting term remaining)

        require(percentVested >= ONEinBPS, 'Not fully vested');

        delete bondInfo[_depositId]; // delete user info

        totalRemainingPayout -= info.payout; // total remaining payout is decreased

        IERC20Upgradeable(rewardToken).safeTransfer(_recipient, info.payout); // send payout

        emit BondRedeemed(_depositId, _recipient, info.payout, 0); // emit bond data

        removeDepositId(_recipient, _depositId);

        return info.payout;
    }

    function claimFee(address _principal, address feeRecipient) external {
        require(
            feeRecipient != fundRecipient,
            'can only claim fee for recipient'
        );

        uint256 fee = tokenBalances[_principal][feeRecipient];
        require(fee > 0);

        tokenBalances[_principal][feeRecipient] = 0;
        IERC20Upgradeable(_principal).safeTransfer(feeRecipient, fee);
    }

    function claimFund(address _principal) external {
        uint256 fund = tokenBalances[_principal][fundRecipient];
        require(fund > 0);

        tokenBalances[_principal][fundRecipient] = 0;
        IERC20Upgradeable(_principal).safeTransfer(fundRecipient, fund);
    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice remove depositId after redeem
     */
    function removeDepositId(address _recipient, uint256 _depositId) internal {
        uint256 lastTokenIndex = depositCounts[_recipient] - 1; //underflow is intended
        uint256 tokenIndex = depositIndexes[_depositId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedDeposits[_recipient][lastTokenIndex];

            ownedDeposits[_recipient][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            depositIndexes[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete depositIndexes[_depositId];
        delete ownedDeposits[_recipient][lastTokenIndex];
        depositCounts[_recipient] = depositCounts[_recipient] - 1;
    }

    /**
     *  @notice process fee on deposit
     */
    function processFee(address _principal, uint256 _amount) internal {
        require(
            initialized[CONFIG.DEPOSIT_TOKEN] &&
                initialized[CONFIG.FEE_RECIPIENT] &&
                initialized[CONFIG.FUND_RECIPIENT],
            'please complete initialize for FeeRecipient/Principals/FundRecipient'
        );

        uint256 fee = (_amount * feeBps) / ONEinBPS;
        tokenBalances[_principal][fundRecipient] += _amount - fee;

        if (fee > 0) {
            uint256 theLast = fee;
            for (uint256 i = 0; i < feeRecipients.length - 1; i++) {
                tokenBalances[_principal][feeRecipients[i]] +=
                    (fee * feeWeightBps[i]) /
                    ONEinBPS;
                theLast -= (fee * feeWeightBps[i]) / ONEinBPS;
            }
            require(
                theLast >=
                    (fee * feeWeightBps[feeWeightBps.length - 1]) / ONEinBPS,
                'fee calculation error'
            );
            tokenBalances[_principal][
                feeRecipients[feeRecipients.length - 1]
            ] += theLast;
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice calculate interest due for new bond
     *  @param _principal address
     *  @param _amount uint
     *  @param _discount uint
     *  @return uint
     */
    function payoutFor(
        address _principal,
        uint256 _amount,
        uint256 _discount
    ) public view returns (uint256) {
        uint256 nativePrice = (bondPrice() * (ONEinBPS - _discount)) / ONEinBPS;

        return
            (_amount *
                priceOracleAggregator.viewPriceInUSD(_principal) *
                rewardUnit) /
            (nativePrice *
                10**IERC20MetadataUpgradeable(_principal).decimals());
    }

    /**
     *  @notice calculate current bond price
     *  @return price_ uint
     */
    function bondPrice() public view returns (uint256 price_) {
        price_ = priceOracleAggregator.viewPriceInUSD(rewardToken);

        if (price_ < minimumPrice) {
            price_ = minimumPrice;
        }
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal returns (uint256 price_) {
        price_ = priceOracleAggregator.viewPriceInUSD(rewardToken);

        if (price_ < minimumPrice) {
            price_ = minimumPrice;
        } else {
            minimumPrice = 0;
        }
    }

    /**
     *  @return price_ uint
     */
    function bondPriceInUSD() public view returns (uint256 price_) {
        price_ = priceOracleAggregator.viewPriceInUSD(rewardToken);
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositId uint
     *  @return percentVested_ uint
     */
    function percentVestedFor(uint256 _depositId)
        public
        view
        returns (uint256 percentVested_)
    {
        Bond memory bond = bondInfo[_depositId];
        uint256 timestampSinceLast = block.timestamp - bond.lastBlockAt;
        uint256 vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = (timestampSinceLast * ONEinBPS) / vesting;
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of rewardToken available for claim by depositor
     *  @param _depositId uint
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(uint256 _depositId)
        public
        view
        returns (uint256 pendingPayout_)
    {
        uint256 percentVested = percentVestedFor(_depositId);
        uint256 payout = bondInfo[_depositId].payout;

        if (percentVested >= ONEinBPS) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = (payout * percentVested) / ONEinBPS;
        }
    }

    /**
     *  @notice return minimum principal amount to deposit
     *  @param _principal address
     *  @param _discount uint
     *  @param amount_ principal amount
     */
    function minimumPrincipalAmount(address _principal, uint256 _discount)
        external
        view
        onlyPrincipal(_principal)
        returns (uint256 amount_)
    {
        uint256 nativePrice = (bondPrice() * (ONEinBPS - _discount)) / ONEinBPS;

        amount_ =
            ((rewardUnit / 100) *
                nativePrice *
                10**IERC20MetadataUpgradeable(_principal).decimals()) /
            (priceOracleAggregator.viewPriceInUSD(_principal) * rewardUnit);
    }

    /**
     *  @notice show all tokens used to create bond
     *  @return principals_ principals
     *  @return totalPrincipals_ total principals
     */
    function allPrincipals()
        external
        view
        returns (
            address[] memory principals_,
            uint256[] memory totalPrincipals_
        )
    {
        principals_ = principals;

        uint256 length = principals.length;
        totalPrincipals_ = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            totalPrincipals_[i] = totalPrincipals[principals[i]];
        }
    }

    /**
     *  @notice show all locking periods of discounts
     *  @return lockingPeriods_ locking periods
     *  @return lockingDiscounts_ locking discounts
     */
    function allLockingPeriodsDiscounts()
        external
        view
        returns (
            uint256[] memory lockingPeriods_,
            uint256[] memory lockingDiscounts_
        )
    {
        lockingPeriods_ = lockingPeriods;

        uint256 length = lockingPeriods.length;
        lockingDiscounts_ = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            lockingDiscounts_[i] = lockingDiscounts[lockingPeriods[i]];
        }
    }

    /**
     *  @notice show all bond infos for a particular owner
     *  @param _owner owner
     *  @return bondInfos_ bond infos
     *  @return pendingPayouts_ pending payouts
     */
    function allBondInfos(address _owner)
        external
        view
        returns (Bond[] memory bondInfos_, uint256[] memory pendingPayouts_)
    {
        uint256 length = depositCounts[_owner];
        bondInfos_ = new Bond[](length);
        pendingPayouts_ = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 depositId = ownedDeposits[_owner][i];
            bondInfos_[i] = bondInfo[depositId];
            pendingPayouts_[i] = pendingPayoutFor(depositId);
        }
    }

    /**
     *  @notice show all fee recipients and weight bps
     *  @return feeRecipients_ fee recipients address
     *  @return feeWeightBps_ fee weight bps
     */
    function allFeeInfos()
        external
        view
        returns (
            address[] memory feeRecipients_,
            uint256[] memory feeWeightBps_
        )
    {
        feeRecipients_ = feeRecipients;
        feeWeightBps_ = feeWeightBps;
    }

    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principal or rewardToken) to the DAO
     *  @return bool
     */
    function withdrawToken(address _token) external onlyPolicy returns (bool) {
        uint256 amount = IERC20Upgradeable(_token).balanceOf(address(this));
        if (_token == rewardToken) {
            amount = amount - totalRemainingPayout;
        }
        IERC20Upgradeable(_token).safeTransfer(DAO, amount);
        return true;
    }

    uint256[49] private ___gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
pragma solidity 0.8.9;

import "./IOracle.sol";

interface IPriceOracleAggregator {
    event UpdateOracle(address token, IOracle oracle);

    function updateOracleForAsset(address _asset, IOracle _oracle) external;

    function viewPriceInUSD(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
pragma solidity 0.8.9;

interface IOracle {
    function viewPriceInUSD() external view returns (uint256);
}
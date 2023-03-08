// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import './lib/Libraries.sol';
import './lib/Security.sol';

contract Manifestation is IManifestation, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public creatorAddress;
    IManifester public manifester;
    address public DAO;
    address public soulDAO;
    address public wnativeAddress;
    address public usdcAddress;
    string public nativeSymbol;

    address public assetAddress;
    address public depositAddress;
    address public rewardAddress;

    IERC20 public depositToken;
    IERC20 public assetToken;
    IERC20 public rewardToken;

    string public override name;
    string public override symbol;
    string public override logoURI;
    string public override assetSymbol;
    
    uint public duraDays;
    uint public feeDays;
    uint public dailyReward;
    uint public totalRewards;
    uint public rewardPerSecond;
    uint public accRewardPerShare;
    uint public lastRewardTime;

    uint public override startTime;
    uint public override endTime;

    bool public isNativePair;

    bool public isManifested;
    bool public isSetup;
    bool public isEmergency;
    bool public isActivated;
    bool public isSettable;

    // user info
    struct Users {
        uint amount;                    // deposited amount.
        uint rewardDebt;                // reward debt (see: pendingReward).
        uint withdrawTime;              // (latest) withdrawal time.
        uint depositTime;               // (first) deposit time.
        uint timeDelta;                 // seconds accounted for in fee calculation.
        uint deltaDays;                 // days accounted for in fee calculation
    }

    // user info
    mapping (address => Users) public userInfo;

    // controls: emergencyWithdrawals.
    modifier emergencyActive {
        require(isEmergency, 'emergency mode is not active.');
        _;
    }

    // proxy for pausing contract.
    modifier isWithdrawable(uint amount) {
        require(startTime != 0, 'start time has not been set');
        require(amount > 0, 'cannot withdraw zero');
        require(block.timestamp >= startTime, 'rewards have not yet begun');
        require(isActivated, 'contract is currently paused');
        _;
    }
   
    // proxy for pausing contract.
    modifier isDepositable(uint amount) {
        require(startTime != 0, 'start time has not been set');
        require(amount > 0, 'cannot deposit zero');
        require(block.timestamp <= endTime, 'the reward period has ended');
        require(isActivated, 'contract is currently paused');
        _;
    }

    // [..] proxy for setting contract.
    modifier whileSettable {
        require(isSettable, 'contract is currently not settable');
        _;
    }

    // [.√.] designates: soul access (for (rare) overrides).
    modifier onlySOUL() {
        require(soulDAO == msg.sender, "onlySOUL: caller is not the soulDAO address");
        _;
    }

    // [.√.] ensures: only the DAO address is the sender.
    modifier onlyDAO() {
        require(DAO == msg.sender, "onlyDAO: caller is not the DAO address");
        _;
    }

    // [.√.] ensures: only the Manifester address is the sender.
    modifier onlyManifester() {
        require(address(manifester) == msg.sender, "onlyManifester: caller is not the Manifester address");
        _;
    }

    event Harvested(address indexed user, uint amount, uint timestamp);
    event Deposited(address indexed user, uint amount, uint timestamp);
    event Manifested(string name, string symbol, address creatorAddress, address assetAddress, address depositAddress, address rewardAddress, uint timestamp);

    event Withdrawn(address indexed user, uint amount, uint feeAmount, uint timestamp);
    event EmergencyWithdrawn(address indexed user, uint amount, uint timestamp);
    event FeeDaysUpdated(uint feeDays);

    // [..] sets the manifester at creation //
    constructor() {
        manifester = IManifester(msg.sender);
    }

    // [.√.] initializes: manifestation by the manifester (at creation).
    function manifest(
        address _creatorAddress,
        address _assetAddress,
        address _depositAddress,
        address _rewardAddress
        ) external onlyManifester {
        require(!isManifested, 'initialize once');

        creatorAddress = _creatorAddress;
        assetAddress = _assetAddress;
        depositAddress = _depositAddress;
        rewardAddress = _rewardAddress;

        // sets: key data.
        DAO = creatorAddress;
        soulDAO = manifester.soulDAO();
        wnativeAddress = manifester.wnativeAddress();
        nativeSymbol = manifester.nativeSymbol();
        usdcAddress = manifester.usdcAddress();

        require(assetAddress == wnativeAddress || assetAddress == usdcAddress, 'must pair with native or stable asset');
        isNativePair = assetAddress == wnativeAddress;

        // sets: from input data.
        assetToken = IERC20(assetAddress);
        depositToken = IERC20(depositAddress);
        rewardToken = IERC20(rewardAddress);

        // sets: initial states.
        isManifested = true;
        isSettable = true;

        // sets: assetSymbol s.t. [if] isNativePair [then] "NATIVE" [else] "STABLE".
        assetSymbol = isNativePair ? "NATIVE" : "STABLE";

        // constructs: name that corresponds to the rewardToken.
        name = string(abi.encodePacked('Manifest: ', ERC20(rewardAddress).name()));
        symbol = string(abi.encodePacked(ERC20(rewardAddress).symbol(), '-', assetSymbol, ' MP'));

        emit Manifested(name, symbol, creatorAddress, assetAddress, depositAddress, rewardAddress, block.timestamp);
    }
    
    // [.√.] sets: rewards (callable from manifester)
    function setRewards(uint _duraDays, uint _feeDays, uint _dailyReward) external onlyManifester {
        require(!isSetup, 'already setup');

        // sets: key info.
        duraDays = _duraDays;
        feeDays = toWei(_feeDays);
        dailyReward = toWei(_dailyReward);
        rewardPerSecond = toWei(_dailyReward) / 1 days;
        totalRewards = duraDays * toWei(_dailyReward);

        // sets: setup state.
        isSetup = true;
    }

    // [..] updates: rewards, so that they are accounted for.
    function update() public {

        if (block.timestamp <= lastRewardTime) { return; }
        uint depositSupply = getTotalDeposit();

        // [if] first manifestationer, [then] set `lastRewardTime` to meow.
        if (depositSupply == 0) { lastRewardTime = block.timestamp; return; }

        // gets: multiplier from time elasped since pool began issuing rewards.
        uint multiplier = getMultiplier(lastRewardTime, block.timestamp);
        uint reward = multiplier * rewardPerSecond;

        accRewardPerShare += (reward * 1e12 / depositSupply);
        lastRewardTime = block.timestamp;
    }

    ///////////////////////////////
        /*/ VIEW FUNCTIONS /*/
    ///////////////////////////////

    // [..] returns: pending rewards for a specifed account.
    function getPendingRewards(address account) external view returns (uint pendingAmount) {
        // gets: pool and user data
        Users storage user = userInfo[account];

        // gets: `accRewardPerShare` & `lpSupply` (pool)
        uint _accRewardPerShare = accRewardPerShare; // uses: local variable for reference use.
        uint depositSupply = depositToken.balanceOf(address(this));

        // [if] holds deposits & rewards issued at least once (pool)
        if (block.timestamp > lastRewardTime && depositSupply != 0) {
            // gets: multiplier from the time since now and last time rewards issued (pool)
            uint multiplier = getMultiplier(lastRewardTime, block.timestamp);
            // get: reward as the product of the elapsed emissions and the share of soul rewards (pool)
            uint reward = multiplier * rewardPerSecond;
            // adds: product of reward and 1e12
            _accRewardPerShare = accRewardPerShare + reward * 1e12 / depositSupply;
        }

        // returns: rewardShare for user minus the amount paid out (user).
        pendingAmount = user.amount * _accRewardPerShare / 1e12 - user.rewardDebt;

        return pendingAmount;
    }

    // [.√.] returns: multiplier during a period.
    function getMultiplier(uint from, uint to) public pure returns (uint multiplier) {
        multiplier = to - from;

        return multiplier;
    }

    // [..] returns: price per token
    function getPricePerToken() public view returns (uint pricePerToken) {
        IERC20 WNATIVE = IERC20(wnativeAddress);
        IERC20 USDC = IERC20(usdcAddress);
    
        uint totalSupply = depositToken.totalSupply();

        uint assetPrice = 
            isNativePair ? uint(IManifester(manifester).getNativePrice()) 
                : 1 * 1E8;

        uint assetBalance = 
            isNativePair ? WNATIVE.balanceOf(address(depositToken)) 
                : USDC.balanceOf(address(depositToken));

        uint assetValue = assetBalance * assetPrice;
        pricePerToken = assetValue * 2 / totalSupply;

        return pricePerToken;
    }

    // [..] returns: TVL
    function getTVL() external view override returns (uint tvl) {
        uint pricePerToken = getPricePerToken();
        uint totalDeposited = getTotalDeposit();
        tvl = totalDeposited * pricePerToken;

        return tvl;
    }

    // [..] returns: the total amount of deposited tokens.
    function getTotalDeposit() public view override returns (uint totalDeposited) {
        totalDeposited = depositToken.balanceOf(address(this));

        return totalDeposited;
    }

    // [..] returns: user delta is the time since user either last withdrew OR first deposited OR 0.
	function getUserDelta(address account) public view returns (uint timeDelta) {
        // gets: stored `user` data.
        Users storage user = userInfo[account];

        // [if] has never withdrawn & has deposited, [then] returns: `timeDelta` as the seconds since first `depositTime`.
        if (user.withdrawTime == 0 && user.depositTime > 0) { return timeDelta = block.timestamp - user.depositTime; }
            // [else if] `user` has withdrawn, [then] returns: `timeDelta` as the time since the last withdrawal.
            else if(user.withdrawTime > 0) { return timeDelta = block.timestamp - user.withdrawTime; }
                // [else] returns: `timeDelta` as 0, since the user has never deposited.
                else return timeDelta = 0;
	}

    // [..] gets: days based off a given timeDelta (seconds).
    function getDeltaDays(uint timeDelta) public pure returns (uint deltaDays) {
        deltaDays = timeDelta < 1 days ? 0 : timeDelta / 1 days;
        return deltaDays;     
    }

     // [.√.] returns: feeRate and timeDelta.
    function getFeeRate(uint deltaDays) public view returns (uint feeRate) {
        // calculates: rateDecayed (converts to wei).
        uint rateDecayed = toWei(deltaDays);
    
        // [if] more time has elapsed than wait period
        if (rateDecayed >= feeDays) {
            // [then] set feeRate to 0.
            feeRate = 0;
        } else { // [else] reduce feeDays by the rateDecayed.
            feeRate = feeDays - rateDecayed;
        }

        return feeRate;
    }

    // [..] returns: feeAmount and with withdrawableAmount for a given amount
    function getWithdrawable(uint deltaDays, uint amount) public view returns (uint _feeAmount, uint _withdrawable) {
        // gets: feeRate
        uint feeRate = fromWei(getFeeRate(deltaDays));
        // gets: feeAmount
        uint feeAmount = (amount * feeRate) / 100;
        // calculates: withdrawable amount
        uint withdrawable = amount - feeAmount;

        return (feeAmount, withdrawable);
    }

    // [.√.] returns: reward period (start, end).
    function getRewardPeriod() external view returns (uint start, uint end) {
        start = startTime;
        end = endTime;
        return (start, end);
    }

    //////////////////////////////////////
        /*/ ACCOUNT (TX) FUNCTIONS /*/
    //////////////////////////////////////

    // [.√.] harvests: pending rewards.
    function harvest() external nonReentrant {
        Users storage user = userInfo[msg.sender];

        // updates: calculations.
        update();

        // gets: pendingRewards and requires pending reward.
        uint pendingReward = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
        require(pendingReward > 0, 'there is nothing to harvest');

        // ensures: only a full payout is made, else fails.
        require(rewardToken.balanceOf(address(this)) >= pendingReward, 'insufficient balance for reward payout');
        
        // transfers: reward token to user.
        rewardToken.safeTransfer(msg.sender, pendingReward);

        // updates: reward debt (user).
        user.rewardDebt = user.amount * accRewardPerShare / 1e12;

        emit Harvested(msg.sender, pendingReward, block.timestamp);
    }

    // [.√.] deposit: tokens.
    function deposit(uint amount) external nonReentrant isDepositable(amount) {
        // gets: stored data for pool and user.
        Users storage user = userInfo[msg.sender];

        // updates: calculations.
        update();

        // [if] already deposited (user)
        if (user.amount > 0) {
            // [then] gets: pendingReward.
            uint pendingReward = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
                // [if] rewards pending, [then] transfer to user.
                if(pendingReward > 0) { 
                    // [then] ensures: only a full payout is made, else fails.
                    require(rewardToken.balanceOf(address(this)) >= pendingReward, 'insufficient balance for reward payout');
                    rewardToken.safeTransfer(msg.sender, pendingReward);
                }
        }

        // transfers: depositToken from user to contract
        depositToken.safeTransferFrom(address(msg.sender), address(this), amount);

        // adds: deposit amount (for user).
        user.amount += amount;

        // updates: reward debt (user).
        user.rewardDebt = user.amount * accRewardPerShare / 1e12;

        // [if] first deposit
        if (user.depositTime == 0) {
            // [then] update depositTime
            user.depositTime = block.timestamp;
        }

        emit Deposited(msg.sender, amount, block.timestamp);
    }

    // [..] withdraws: deposited tokens.
    function withdraw(uint amount) external nonReentrant isWithdrawable(amount) {
        // gets: stored data for the account.
        Users storage user = userInfo[msg.sender];

        require(user.amount >= amount, 'withdrawal exceeds deposit');
        
        // helps: manage calculations.
        update();

        // gets: pending rewards as determined by pendingSoul.
        uint pendingReward = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
        // [if] rewards are pending, [then] send rewards to user.
        if(pendingReward > 0) { 
            // ensures: only a full payout is made, else fails.
            require(rewardToken.balanceOf(address(this)) >= pendingReward, 'insufficient balance for reward payout');
            rewardToken.safeTransfer(msg.sender, pendingReward); 
        }

        // gets: timeDelta as the time since last withdrawal.
        uint timeDelta = getUserDelta(msg.sender);

        // gets: deltaDays as days passed using timeDelta.
        uint deltaDays = getDeltaDays(timeDelta);

        // updates: deposit, timeDelta, & deltaDays (user)
        user.amount -= amount;
        user.timeDelta = timeDelta;
        user.deltaDays = deltaDays;

        // calculates: withdrawable amount (deltaDays, amount).
        (, uint withdrawableAmount) = getWithdrawable(deltaDays, amount); 

        // calculates: `feeAmount` as the `amount` requested minus `withdrawableAmount`.
        uint feeAmount = amount - withdrawableAmount;

        // transfers: `feeAmount` --> owner.
        rewardToken.safeTransfer(DAO, feeAmount);
        // transfers: withdrawableAmount amount --> user.
        rewardToken.safeTransfer(address(msg.sender), withdrawableAmount);

        // updates: rewardDebt and withdrawTime (user)
        user.rewardDebt = user.amount * accRewardPerShare / 1e12;
        user.withdrawTime = block.timestamp;

        emit Withdrawn(msg.sender, amount, feeAmount, block.timestamp);
    }

    // [..] enables: withdrawal without caring about rewards (for example, when rewards end).
    function emergencyWithdraw() external nonReentrant emergencyActive {
        // gets: pool & user data (to update later).
        Users storage user = userInfo[msg.sender];

        // helps: manage calculations.
        update();

        // transfers: depositToken to the user.
        depositToken.safeTransfer(msg.sender, user.amount);

        // eliminates: user deposit `amount` & `rewardDebt`.
        user.amount = 0;
        user.rewardDebt = 0;

        // updates: user `withdrawTime`.
        user.withdrawTime = block.timestamp;

        emit EmergencyWithdrawn(msg.sender, user.amount, user.withdrawTime);
    }

    ///////////////////////////////
        /*/ VIEW FUNCTIONS /*/
    ///////////////////////////////
    
    // [..] returns: key user info.
    function getUserInfo(address account) external view returns (uint amount, uint rewardDebt, uint withdrawTime, uint depositTime, uint timeDelta, uint deltaDays) {
        Users storage user = userInfo[account];
        return(user.amount, user.rewardDebt, user.withdrawTime, user.depositTime, user.timeDelta, user.deltaDays);
    }

    ////////////////////////////////
        /*/ ADMIN FUNCTIONS /*/
    ////////////////////////////////

    // [..] enables: panic button (onlyDAO, whileSettable)
    function toggleEmergency(bool enabled) external onlyDAO whileSettable {
        isEmergency = enabled;
    }

    // [..] toggles: pause state (onlyDAO, whileSettable)
    function toggleActive(bool enabled) external onlyDAO whileSettable {
        isActivated = enabled;
    }

    // [..] updates: feeDays (onlyDAO, whileSettable) todo
    function setFeeDays(uint _feeDays) external onlyDAO whileSettable {
        // gets: current fee days & ensures distinction (pool)
        require(feeDays != toWei(_feeDays), 'no change requested');
        
        // limits: feeDays by default maximum of 30 days.
        require(toWei(_feeDays) <= toWei(30), 'exceeds a month of fees');
        
        // updates: fee days (pool)
        feeDays = toWei(_feeDays);
        
        emit FeeDaysUpdated(toWei(_feeDays));
    }

    // [.√.] sets: startTime & endTime (onlyDAO)
    function setDelay(uint delayDays) external onlyDAO {
        require(startTime == 0, 'startTime has already been set');
        
        // converts: delayDays into a unix timeDelay variable (in seconds).
        uint timeDelay = delayDays * 1 days;

        // calculates: start (in seconds) as now + timeDelay.
        uint start = block.timestamp + timeDelay;
        
        // ensures: start time has not yet past.
        require(start >= block.timestamp, 'start must be in the future');

        // calculates: duration (in seconds)
        require(duraDays !=0, 'duration must be set');
        uint duration = duraDays * 1 days;
        
        // sets: startTime.
        startTime = start;

        // sets: startTime.
        endTime = start + duration;
    }

    // [.√.] sets: DAO address (onlyDAO)
    function setDAO(address _DAO) external onlyDAO {
        require(_DAO != address(0), 'cannot set to zero address');
        // updates: DAO adddress
        DAO = _DAO;
    }

    //////////////////////////////////////////
        /*/ SOUL (OVERRIDE) FUNCTIONS /*/
    //////////////////////////////////////////

    // [..] prevents: funny business (onlySOUL).
    function toggleSettable(bool enabled) external onlySOUL {
        isSettable = enabled;
    }

    // [..] overrides: feeDays (onlySOUL)
    function setFeeDaysOverride(uint _feeDays) external onlySOUL {
        // gets: current fee days & ensures distinction (pool)
        require(feeDays != toWei(_feeDays), 'no change requested');
        
        // limits: feeDays by default maximum of 30 days.
        require(toWei(_feeDays) <= toWei(30), 'exceeds a month of fees');
        
        // updates: fee days (pool)
        feeDays = toWei(_feeDays);
        
        emit FeeDaysUpdated(toWei(_feeDays));
    }

    // [..] overrides: active state (onlySOUL).
    function toggleActiveOverride(bool enabled) external onlySOUL {
        isActivated = enabled;
    }

    // [.√.] overrides logoURI (onlySOUL).
    function setLogoURI(string memory _logoURI) external onlySOUL {
        logoURI = _logoURI;
    }

    // [.√.] sets: soulDAO address (onlySOUL).
    function setSoulDAO(address _soulDAO) external onlySOUL {
        require(_soulDAO != address(0), 'cannot set to zero address');
        // updates: soulDAO adddress
        soulDAO = _soulDAO;
    }

    ///////////////////////////////
        /*/ HELPER FUNCTIONS /*/
    ///////////////////////////////

    function toWei(uint amount) public pure returns (uint) { return amount * 1e18; }
    function fromWei(uint amount) public pure returns (uint) { return amount / 1e18; }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import './Manifestation.sol';

contract Manifester is IManifester {
    using SafeERC20 for IERC20;
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(Manifestation).creationCode));

    ISoulSwapFactory public SoulSwapFactory;
    uint public totalManifestations;
    uint public totalEnchanters;
    uint public eShare;

    // approved enchanters.
    struct Enchanters {
        address account;
        bool isActive;
    }

    // [√] enchanters info.
    Enchanters[] public eInfo;

    address[] public manifestations;
    address[] public daos;
    // checks: whether already an enchanter.
    mapping(address => bool) public enchanted; 

    address public override soulDAO;

    // [..] immatable oracle constants
    IOracle private immutable nativeOracle;
    uint private immutable oracleDecimals;

    string public override nativeSymbol;
    address public override wnativeAddress;
    address public override usdcAddress;

    uint public bloodSacrifice;
    bool public isPaused;

    // [..] creates: Manifestations struct (strictly immutable variables).
    struct Manifestations {
        address mAddress;
        address assetAddress;
        address depositAddress;
        address rewardAddress;
        address creatorAddress;
        address enchanterAddress;
    }

    // [.√.] manifestation info
    Manifestations[] public mInfo;

    // [ .. ] depositAddress, id.
    // mapping(address => mapping(uint => address)) public getManifestation; 

    event SummonedManifestation(
        uint indexed id,
        address indexed depositAddress, 
        address rewardAddress, 
        address creatorAddress,
        address enchanterAddress,
        address manifestation
    );

    event Paused(bool enabled);
    event Enchanted(uint id, address account, bool isActive);
    event UpdatedSacrifice(uint sacrifice);
    event UpdatedEnchantShare(uint eShare);
    event UpdatedDAO(address dao);

    // [..] proxy for pausing contract.
    modifier whileActive {
        require(!isPaused, 'contract is currently paused');
        _;
    }

    // [..] restricts: certain functions to soulDAO-only.
    modifier onlySOUL() {
        require(soulDAO == msg.sender, "onlySOUL: caller is not the soulDAO address");
        _;
    }

    // [..] restricts: only existing manifestations.
    modifier exists(uint id, uint total) {
        require(id <= total, 'does not exist.');
        _;
    }

    // [..] sets: key variables.
    constructor(
        address _factoryAddress,
        address _usdcAddress,
        address _wnativeAddress,
        address _nativeOracle, 
        uint _oracleDecimals,
        string memory _nativeSymbol
    ) {
        SoulSwapFactory = ISoulSwapFactory(_factoryAddress);
        bloodSacrifice = toWei(2);
        nativeSymbol = _nativeSymbol;

        usdcAddress = _usdcAddress;
        wnativeAddress = _wnativeAddress;

        soulDAO = msg.sender;
        nativeOracle = IOracle(_nativeOracle);
        oracleDecimals = _oracleDecimals;

        // creates: the first Enchanter[0].
        addEnchanter(msg.sender);

        // increments [+]: totalEnchanters.
        totalEnchanters ++;

        // sets: eShare to 1%.
        updateEnchantShare(1);
    }

    // [.√.] creates: Manifestation
    function createManifestation(
        address depositAddress,
        address rewardAddress,
        uint enchanterId,
        bool isNative
        // address daoAddress
    ) external whileActive exists(enchanterId, totalEnchanters) returns (address manifestation, uint id) {
        // creates: id reference.
        id = manifestations.length;
        // gets: stored enchanter info
        Enchanters memory enchanter = eInfo[enchanterId];

        // sets: enchanterAddress.
        address enchanterAddress = enchanter.account;

        // sets: assetAddress.
        address assetAddress = isNative ? wnativeAddress : usdcAddress;

        // ensures: depositAddress is never 0x.
        require(depositAddress != address(0), 'depositAddress must be SoulSwap LP.');
        // ensures: reward token hasd 18 decimals.
        require(ERC20(rewardAddress).decimals() == 18, 'reward must be 18 decimals.');
        // ensures: unique depositAddress-id mapping.
        // require(getManifestation[depositAddress][id] == address(0), 'reward already exists'); // single check is sufficient

        // generates: creation code, salt, then assembles a create2Address for the new manifestation.
        bytes memory bytecode = type(Manifestation).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(depositAddress, id));
        assembly { manifestation := create2(0, add(bytecode, 32), mload(bytecode), salt) }

        // populates: the getManifestation using the depositAddress and id.
        // getManifestation[depositAddress][id] = manifestation;

        // stores manifestation to the manifestations[] array
        manifestations.push(manifestation);

        // stores: dao to the daos[] array
        daos.push(msg.sender);

        // increments: the total number of manifestations
        totalManifestations++;

        // appends and populates: a new Manifestations struct (instance).
        mInfo.push(Manifestations({
            mAddress: manifestations[id],
            assetAddress: assetAddress,
            depositAddress: depositAddress,
            rewardAddress: rewardAddress,
            creatorAddress: msg.sender,
            enchanterAddress: enchanterAddress
        }));

        emit SummonedManifestation(id, depositAddress, rewardAddress, msg.sender, enchanterAddress, manifestation);
    }

    // [.√.] initializes: manifestation
    function initializeManifestation(uint id) external exists(id, totalManifestations) {
        // gets: stored manifestation info by id.
        Manifestations storage manifestation = mInfo[id];

        // gets: associated variables by id.
        address mAddress = manifestations[id];
        address daoAddress = daos[id];
        address rewardAddress = manifestation.rewardAddress;
        address assetAddress = manifestation.assetAddress;
        address depositAddress = manifestation.depositAddress;

        // requires: sender is the DAO
        require(msg.sender == daoAddress, 'only the DAO may initialize');

        // creates: new manifestation based off of the inputs, then stores as an array.
        Manifestation(mAddress).manifest(
            daoAddress,
            assetAddress,
            depositAddress,
            rewardAddress
        );
    }

    // [.√.] launches: Manifestation.
    function launchManifestation(
        uint id,
        uint duraDays,
        uint dailyReward,
        uint feeDays
    ) external exists(id, totalManifestations) {
        // gets: stored manifestation info by id.
        Manifestations storage manifestation = mInfo[id];

        // checks: the sender is the creator of the manifestation.
        require(msg.sender == manifestation.creatorAddress, 'only the creator may launch.');

        // gets: distribution amounts.
        uint reward = getTotalRewards(duraDays, dailyReward);

        require(_launchManifestation(id, duraDays, feeDays, dailyReward, reward), 'launch failed.');
    }

    function _launchManifestation(uint id, uint duraDays, uint feeDays, uint dailyReward, uint reward) internal returns (bool) {

        // gets: stored manifestation info by id.
        Manifestations storage manifestation = mInfo[id];

        uint sacrifice = getSacrifice(fromWei(reward));

        (uint toDAO, uint toEnchanter) = getSplit(sacrifice);

        address rewardAddress = manifestation.rewardAddress;
        address mAddress = manifestations[id];

        uint total = getTotalRewards(duraDays, dailyReward) + sacrifice;

        // sets: the rewards data for the newly-created manifestation.
        Manifestation(mAddress).setRewards(duraDays, feeDays, dailyReward);
    
        // checks: the creator has a sufficient balance to cover both rewards + sacrifice.
        require(ERC20(rewardAddress).balanceOf(msg.sender) >= total, 'insufficient balance to launch manifestation.');

        // transfers: eShare directly to enchanter.
        IERC20(rewardAddress).safeTransferFrom(msg.sender, manifestation.enchanterAddress, toEnchanter);
        
        // transfers: share directly to soulDAO.
        IERC20(rewardAddress).safeTransferFrom(msg.sender, soulDAO, toDAO);
        
        // transfers: `totalRewards` to the manifestation contract.
        IERC20(rewardAddress).safeTransferFrom(msg.sender, mAddress, total);

        return true;
    }

    //////////////////////////////
        /*/ VIEW FUNCTIONS /*/
    //////////////////////////////

    // [..] returns: native price.
    function getNativePrice() public view override returns (int) {
        int latestAnswer = IOracle(nativeOracle).latestAnswer();
        return latestAnswer;
    }

    // [.√.] returns: sacrificial split between DAO & enchanter.
    function getSplit(uint sacrifice) public view returns (uint toDAO, uint toEnchanter) {
        toEnchanter = sacrifice * eShare / 100;
        toDAO = sacrifice * bloodSacrifice / 100;
    }

    // [..] returns: total rewards.
    function getTotalRewards(uint duraDays, uint dailyReward) public pure returns (uint) {
        uint totalRewards = duraDays * toWei(dailyReward);
        return totalRewards;
    }

    // [.√.] returns: sacrifice amount.
    function getSacrifice(uint _rewards) public view returns (uint) {
        uint sacrifice = (_rewards * bloodSacrifice) / 100;
        return sacrifice;
    }

    // [..] returns: info for a given id.
    function getInfo(uint id) external view returns (
        address mAddress,
        address daoAddress,
        string memory name, 
        string memory symbol, 
        string memory logoURI,

        address rewardAddress,
        address depositAddress,

        uint rewardPerSecond,
        uint rewardRemaining,
        uint startTime,
        uint endTime,
        uint dailyReward, 
        uint feeDays
        ) {

        // gets: stored manifestation info by id.
        mAddress = address(manifestations[id]);
        Manifestation m = Manifestation(mAddress);

        daoAddress = m.DAO();

        name = m.name();
        symbol = m.symbol();

        logoURI = m.logoURI();

        rewardAddress = m.rewardAddress();
        depositAddress = m.depositAddress();
    
        rewardPerSecond = m.rewardPerSecond();
        rewardRemaining = ERC20(rewardAddress).balanceOf(mAddress);

        startTime = m.startTime();
        endTime = m.endTime();
        dailyReward = m.dailyReward();
        feeDays = m.feeDays();
    }

    // [..] returns: user info for a given id.
    function getUserInfo(uint id, address account) external view returns (
        address mAddress, uint amount, uint rewardDebt, uint withdrawTime, uint depositTime, uint timeDelta, uint deltaDays) {
        mAddress = address(manifestations[id]);
        Manifestation manifestation = Manifestation(mAddress);
        (amount, rewardDebt, withdrawTime, depositTime, timeDelta, deltaDays) = manifestation.getUserInfo(account);
    }

    ///////////////////////////////
        /*/ ADMIN FUNCTIONS /*/
    ///////////////////////////////
    // [.√.] adds: Enchanter (instance).
    function addEnchanter(address _account) public onlySOUL {     
        require(!enchanted[_account], "already an enchanter");
        // appends and populates: a new Enchanter struct (instance).
        eInfo.push(Enchanters({
            account: _account,        // address account;
            isActive: true            // bool isActive;
        }));

        uint id = mInfo.length;
        // adds: account to enchanted array.
        enchanted[_account] = true;

        totalEnchanters ++;

        emit Enchanted(id, _account, true);
    }
    // [.√.] updates: Enchanter status.
    function updateEnchanter(uint id, bool isActive) external onlySOUL exists(id, totalEnchanters) {
        // gets: stored data for enchanter.
        Enchanters storage enchanter = eInfo[id];
        // updates: isActive status.
        enchanter.isActive = isActive;
    }

    // [.√.] updates: factory address.
    function updateFactory(address _factoryAddress) external onlySOUL {
        SoulSwapFactory = ISoulSwapFactory(_factoryAddress);
    }

    // [..] updates: soulDAO address.
    function updateDAO(address _soulDAO) external onlySOUL {
        soulDAO = _soulDAO;

        emit UpdatedDAO(_soulDAO);
    }

    // [..] updates: eShare amount.
    function updateEnchantShare(uint _share) public onlySOUL {
        require(_share <= 100, 'cannot exceed 100%.');
        eShare = toWei(_share);

        emit UpdatedEnchantShare(_share);
    }

    // [..] updates: sacrifice amount.
    function updateSacrifice(uint _sacrifice) external onlySOUL {
        require(_sacrifice <= 100, 'cannot exceed 100%.');
        bloodSacrifice = toWei(_sacrifice);

        emit UpdatedSacrifice(_sacrifice);
    }

    // [.√.] updates: pause state.
    function togglePause(bool enabled) external onlySOUL {
        isPaused = enabled;

        emit Paused(enabled);
    }

    ////////////////////////////////
        /*/ HELPER FUNCTIONS /*/
    ////////////////////////////////

    function toWei(uint amount) public pure returns (uint) { return amount * 1e18; }
    function fromWei(uint amount) public pure returns (uint) { return amount / 1e18; }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface ISoulSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event SetFeeTo(address indexed user, address indexed _feeTo);
    event SetMigrator(address indexed user, address indexed _migrator);
    event FeeToSetter(address indexed user, address indexed feeToSetter);

    function feeTo() external view returns (address _feeTo);
    function feeToSetter() external view returns (address _fee);
    function migrator() external view returns (address _migrator);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setMigrator(address) external;
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IManifestation {
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function logoURI() external returns (string memory);
    function assetSymbol() external returns (string memory);

    function depositAddress() external returns (address);
    function rewardAddress() external returns (address);

    function startTime() external returns (uint);
    function endTime() external returns (uint);

    function getTVL() external returns (uint);
    function getTotalDeposit() external returns (uint);
}

interface IManifester {
    function soulDAO() external returns (address);
    function usdcAddress() external returns (address);
    function wnativeAddress() external returns (address);
    function nativeSymbol() external returns (string memory);
    function getNativePrice() external view returns (int);
}

interface IOracle {
  function latestAnswer() external view returns (int256);
  function decimals() external view returns (uint8);
  function latestTimestamp() external view returns (uint256);
}

// File: contracts/interfaces/ISoulSwapPair.sol

pragma solidity >=0.5.0;

interface ISoulSwapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// import './Utilities.sol';
// import './Interfaces.sol';
import './Tokens.sol';

// File: contracts/libraries/SafeERC20.sol

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
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './Utilities.sol';
import './Interfaces.sol';

// File: contracts/libraries/ERC20.sol

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// File: @openzeppelin/contracts/utils/Context.sol

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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
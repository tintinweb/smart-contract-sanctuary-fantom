// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import './lib/Libraries.sol';
import './lib/Security.sol';

contract Manifestation is IManifestation, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public creatorAddress;
    IManifester public Manifester;

    address public DAO;
    address public assetAddress;
    address public depositAddress;
    address public rewardAddress;

    IERC20 private DEPOSIT;
    IERC20 private ASSET;
    IERC20 private REWARD;

    string public override name;
    string public override symbol;
    string public override logoURI;

    uint public duraDays;
    uint public feeDays;
    uint public dailyReward;
    uint public totalRewards;
    uint public rewardPerSecond;
    uint public accRewardPerShare;
    uint public lastRewardTime;

    // tracks to ensure only +/- accounted for.
    uint public override totalDeposited;
    uint public override startTime;
    uint public override endTime;
    uint public override mID;

    bool public isNativePair;
    bool public isManifested;
    bool public isSetup;
    bool public isEmergency;
    bool public isActive;
    bool public isReclaimable;
    bool public isSettable;

    bool private isPendingDAO;
    address private pendingDAO;

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

    // controls: reclaims.
    modifier whileReclaimable {
        require(isReclaimable, 'reclaimable mode is not active.');
        require(isEmergency, 'activate emergency mode to enable emergency withdrawals.');
        _;
    }

    modifier whilePendingDAO {
        require(isPendingDAO, 'only available while pending DAO transfer.');
        _;
    }

    // proxy for pausing contract.
    modifier isDepositable(uint amount) {
        require(IERC20(Manifester.auraAddress()).balanceOf(msg.sender) >= Manifester.auraMinimum(), 'insufficient AURA.');
        require(amount > 0, 'cannot deposit zero.');
        require(block.timestamp <= endTime, 'reward period has ended.');
        // recall: isActive is first activated upon setting start and end times.
        require(isActive, 'paused');
        _;
    }

    // proxy for pausing contract.
    modifier isWithdrawable(uint amount) {
        require(amount > 0, 'cannot withdraw zero.');
        require(block.timestamp >= startTime, 'rewards have not yet begun.');
        // recall: isActive is first activated upon setting start and end times.
        require(isActive, 'paused');
        _;
    }

    // [.√.] proxy for setting contract.
    modifier whileSettable {
        require(isSettable, 'not settable');
        _;
    }

    // [.√.] designates: soul access (for (rare) overrides).
    modifier onlySOUL() {
        require(Manifester.soulDAO() == msg.sender, "onlySOUL");
        _;
    }

    // [.√.] ensures: only the DAO address is the sender.
    modifier onlyDAO() {
        require(DAO == msg.sender, "onlyDAO");
        _;
    }

    // [.√.] ensures: only the Manifester address is the sender.
    modifier onlyManifester() {
        require(address(Manifester) == msg.sender, "onlyManifester");
        _;
    }

    event Harvested(address indexed user, uint amount, uint timestamp);
    event Deposited(address indexed user, uint amount, uint timestamp);
    event Withdrawn(address indexed user, uint amount, uint feeAmount, uint timestamp);
    event EmergencyWithdrawn(address indexed user, uint amount, uint timestamp);

    event Manifested(string name, string symbol, address creatorAddress, address assetAddress, address depositAddress, address rewardAddress, uint timestamp);
    event RewardsReclaimed(address msgSender, uint amount, uint timestamp);
    event UpdatedDAO(address DAO, uint timestamp);

    event ActiveToggled(bool enabled, address msgSender, uint timestamp);
    event RewardsSet(uint duraDays, uint feeDays, uint dailyReward, uint timestamp);
    event ReclaimableToggled(bool enabled, address msgSender, uint timestamp);
    event FeeDaysUpdated(uint feeDays, uint timestamp);

    // [.√.] sets the Manifester at creation //
    constructor() {
        Manifester = IManifester(msg.sender);
    }

    // [.√.] initializes: manifestation by the Manifester (at creation).
    function manifest(
        uint _id,
        address _creatorAddress,
        address _assetAddress,
        address _depositAddress,
        address _rewardAddress,
        string memory _logoURI
        ) external onlyManifester {
        require(!isManifested, 'init. once.');

        creatorAddress = _creatorAddress;
        assetAddress = _assetAddress;
        depositAddress = _depositAddress;
        rewardAddress = _rewardAddress;

        // sets: key data.
        DAO = creatorAddress;
        logoURI = _logoURI;
        mID = _id;

        // sets: from input data.
        ASSET = IERC20(assetAddress);
        DEPOSIT = IERC20(depositAddress);
        REWARD = IERC20(rewardAddress);

        // sets: initial states.
        isManifested = true;
        isSettable = true;

        // sets: native pair if assetAddress is wnative.
        isNativePair = _assetAddress == Manifester.wnativeAddress();

        // constructs: name that corresponds to the REWARD.
        name = string(abi.encodePacked('[', stringifyUint(_id), '] ', ERC20(rewardAddress).name(), ' Farm'));
        symbol = string(abi.encodePacked(ERC20(rewardAddress).symbol()));

        emit Manifested(name, symbol, creatorAddress, assetAddress, depositAddress, rewardAddress, block.timestamp);
    }

    // [.√.] sets: rewards (callable from Manifester)
    function setRewards(uint _duraDays, uint _feeDays, uint _dailyReward) external onlyManifester {

        // sets: key info.
        duraDays = _duraDays;
        feeDays = toWei(_feeDays);
        dailyReward = toWei(_dailyReward);
        rewardPerSecond = toWei(_dailyReward) / 1 days;
        totalRewards = duraDays * toWei(_dailyReward);

        // sets: setup state.
        isSetup = true;

        emit RewardsSet(_duraDays, _feeDays, _dailyReward, block.timestamp);
    }

    // [.√.] updates: rewards, so that they are accounted for.
    function update() public {
        if (block.timestamp <= lastRewardTime) { return; }

        // [if] first manifestation, [then] set `lastRewardTime` to meow.
        if (totalDeposited == 0) { lastRewardTime = block.timestamp; return; }

        // gets: multiplier from time elasped since pool began issuing rewards.
        uint multiplier = getMultiplier(lastRewardTime, block.timestamp);
        uint reward = multiplier * rewardPerSecond;

        accRewardPerShare += (reward * 1e12 / totalDeposited);
        lastRewardTime = block.timestamp;
    }

    ///////////////////////////////
        /*/ VIEW FUNCTIONS /*/
    ///////////////////////////////

    // [.√.] returns: pending rewards for a specifed account.
    function getPendingRewards(address account) external view returns (uint pendingAmount) {
        // gets: pool and user data
        Users storage user = userInfo[account];

        // gets: `accRewardPerShare` & `depositSupply`
        uint _accRewardPerShare = accRewardPerShare; // uses: local variable for reference use.

        // [if] holds deposits & rewards issued at least once.
        if (block.timestamp > lastRewardTime && totalDeposited != 0) {
            // gets: multiplier from the time since now and last time rewards issued (pool).
            uint multiplier = getMultiplier(lastRewardTime, block.timestamp);
            // get: reward as the product of the elapsed emissions and the share of rewards (pool).
            uint reward = multiplier * rewardPerSecond;
            // adds [+]: product [*] of reward and 1e12
            _accRewardPerShare = accRewardPerShare + reward * 1e12 / totalDeposited;
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

    // [.√.] returns: user delta is the time since user either last withdrew OR first deposited OR 0.
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

    // [.√.] gets: days based off a given timeDelta (seconds).
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

    // [.√.] returns: feeAmount and with withdrawableAmount for a given amount
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
        require(pendingReward > 0, 'nothing to harvest.');

        // ensures: only a full payout is made, else fails.
        require(REWARD.balanceOf(address(this)) >= pendingReward, 'insufficient payout balance.');
        
        // transfers: reward token to user.
        REWARD.safeTransfer(msg.sender, pendingReward);

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
                    require(REWARD.balanceOf(address(this)) >= pendingReward, 'insufficient payout balance.');
                    REWARD.safeTransfer(msg.sender, pendingReward);
                }
        }

        // transfers: DEPOSIT from user to contract.
        DEPOSIT.safeTransferFrom(address(msg.sender), address(this), amount);

        // updates (+): totalDeposited.
        totalDeposited += amount;

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

    // [.√.] withdraws: deposited tokens.
    function withdraw(uint amount) external nonReentrant isWithdrawable(amount) {
        // gets: stored data for the account.
        Users storage user = userInfo[msg.sender];

        require(user.amount >= amount, 'exceeds deposit.');
        
        // helps: manage calculations.
        update();

        // gets: pending rewards as determined by pendingSoul.
        uint pendingReward = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
        
        // [if] rewards are pending, [then] send rewards to user.
        if(pendingReward > 0) { 
            // ensures: only a full payout is made, else fails.
            require(REWARD.balanceOf(address(this)) >= pendingReward, 'insufficient payout balance.');
            REWARD.safeTransfer(msg.sender, pendingReward); 
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

        // updates: rewardDebt and withdrawTime (user)
        user.rewardDebt = user.amount * accRewardPerShare / 1e12;
        user.withdrawTime = block.timestamp;

        // updates (-): totalDeposited
        totalDeposited -= amount;

        // transfers: `feeAmount` --> DAO.
        DEPOSIT.safeTransfer(DAO, feeAmount);
        // transfers: withdrawableAmount amount --> user.
        DEPOSIT.safeTransfer(address(msg.sender), withdrawableAmount);

        emit Withdrawn(msg.sender, amount, feeAmount, block.timestamp);
    }

    // [.√.] enables: withdrawal without caring about rewards (e.g. when rewards end).
    function emergencyWithdraw() external nonReentrant emergencyActive {
        // gets: pool & user data (to update later).
        Users storage user = userInfo[msg.sender];
        uint withdrawAmount = user.amount;
        require(withdrawAmount > 0, 'nothing to withdraw.');

        // helps: manage calculations.
        update();

        // transfers: DEPOSIT to the user.
        DEPOSIT.safeTransfer(msg.sender, withdrawAmount);

        // eliminates: user deposit `amount` & `rewardDebt`.
        user.amount = 0;
        // since user.amount = 0 => rewardDebt = 0 * accRewardPerShare / 1e12 = 0;
        user.rewardDebt = 0;

        // updates: user `withdrawTime`.
        user.withdrawTime = block.timestamp;

        // updates (-): totalDeposited.
        totalDeposited -= withdrawAmount;

        emit EmergencyWithdrawn(msg.sender, user.amount, user.withdrawTime);
    }

    ///////////////////////////////
        /*/ VIEW FUNCTIONS /*/
    ///////////////////////////////

    // [.√.] returns: key user info.
    function getUserInfo(address account) external view returns (uint amount, uint rewardDebt, uint withdrawTime, uint depositTime, uint timeDelta, uint deltaDays) {
        Users storage user = userInfo[account];
        return(user.amount, user.rewardDebt, user.withdrawTime, user.depositTime, user.timeDelta, user.deltaDays);
    }

    ////////////////////////////////
        /*/ ADMIN FUNCTIONS /*/
    ////////////////////////////////

    // [.√.] sets: startTime & endTime (onlyDAO)
    function setDelay(address requestor, uint delayDays) external onlyManifester {
        // checks: requestor is the DAO address.
        require(requestor == DAO, 'onlyDAO.');
        // checks: startTime has not yet been set.
        require(startTime == 0, 'start set.');

        // converts: delayDays into a unix timeDelay variable (in secs).
        uint timeDelay = delayDays * 1 days;
        
        // sets: duration.
        uint duration = duraDays * 1 days;
        
        // sets: startTime.
        startTime = block.timestamp + timeDelay;

        // sets: endTime.
        endTime = startTime + duration;

        // activates: deposits and withdrawals.
        isActive = true;
    }

    // [.√.] sets: DAO address (onlyDAO).
    function setDAO(address _pendingDAO) external onlyDAO whileSettable {
        require(_pendingDAO != DAO && _pendingDAO != address(0), 'no change || address(0).');

        // updates: pendingDAO adddress.
        pendingDAO = _pendingDAO;
        // sets: isPending DAO to true.
        isPendingDAO = true;
    }

    // [.√.] sets: DAO address while preventing lockout (whilePendingDAO).
    function acceptDAO() external whilePendingDAO {
        // checks: sender is the pendingDAO.
        require(pendingDAO == msg.sender, 'only pending DAO may accept.');
        // sets: isPendingDAO to false.
        isPendingDAO = false;
        // updates: DAO adddress.
        DAO = msg.sender;

        emit UpdatedDAO(DAO, block.timestamp);
    }

    // [.√.] sends: rewards to DAO (whileReclaimable, onlyDAO).
    function reclaimRewards() external whileReclaimable onlyDAO {
        uint balance = REWARD.balanceOf(address(this));
        REWARD.safeTransfer(DAO, balance);

        emit RewardsReclaimed(msg.sender, balance, block.timestamp);
    }

    //////////////////////////////////////////
        /*/ SOUL (OVERRIDE) FUNCTIONS /*/
    //////////////////////////////////////////

    // [.√.] prevents: funny business (onlySOUL).
    function toggleSettable(bool enabled) external onlySOUL {
        isSettable = enabled;
    }

    // [.√.] overrides: reward rate (onlySOUL).
    function setRewardsOverride(uint _feeDays, uint _dailyReward) external onlySOUL {
        // limits: feeDays by default maximum of 30 days.
        require(toWei(_feeDays) <= toWei(30), 'exceeds 30 days.');

        // sets: key rewards info.
        feeDays = toWei(_feeDays);
        dailyReward = toWei(_dailyReward);
        rewardPerSecond = toWei(_dailyReward) / 1 days;

        emit FeeDaysUpdated(toWei(_feeDays), block.timestamp);
        emit RewardsSet(duraDays,  _feeDays, _dailyReward, block.timestamp);
    }

    // [.√.] overrides: active state (onlySOUL).
    function toggleActiveOverride(bool enabled) public onlySOUL {
        // sets: active state, when enabled.
        isActive = enabled;
        // restricts: emergency exit, while active.
        isEmergency = !enabled;

        emit ActiveToggled(enabled, msg.sender, block.timestamp);
    }

    // [.√.] sets: reclaimable status.
    function setReclaimable(bool enabled) external onlySOUL {
        // [if] setting reclaimable, [then] ensure inactive deposits and active emergency withdrawals.
        if (enabled) { toggleActiveOverride(false); }

        // updates: reclaimable to desired state.
        isReclaimable = enabled;

        emit ReclaimableToggled(enabled, msg.sender, block.timestamp);

    }

    // [.√.] overrides: logoURI (onlySOUL).
    function updateLogoURI(string memory _logoURI) external onlySOUL {
        logoURI = _logoURI;
    }

    // [.√.] sets: native or stable (onlySOUL, when override is needed).
    function setNativePair(bool enabled) external onlySOUL {
        isNativePair = enabled;
        assetAddress = enabled ? Manifester.wnativeAddress() : Manifester.usdcAddress();
    }

    // [.√.] updates: Manifester (onlySOUL)
    function updateManifester(address _manifesterAddress) external onlySOUL {
        Manifester = IManifester(_manifesterAddress);
    }

    ///////////////////////////////
        /*/ HELPER FUNCTIONS /*/
    ///////////////////////////////

    // [.√.] converts: uint to string (used when creating name)
    function stringifyUint(uint _i) public pure returns (string memory _string) {
        if (_i == 0) { return "0"; }
        uint j = _i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        _string = string(bstr);
    }

    function toWei(uint amount) public pure returns (uint) { return amount * 1E18; }
    function fromWei(uint amount) public pure returns (uint) { return amount / 1E18; }
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

interface IManifestation {
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function logoURI() external returns (string memory);

    function depositAddress() external returns (address);
    function rewardAddress() external returns (address);

    function startTime() external returns (uint);
    function endTime() external returns (uint);
    function mID() external returns (uint);
    function totalDeposited() external returns (uint);
}

interface IManifester {
    function soulDAO() external returns (address);
    function usdcAddress() external returns (address);
    function wnativeAddress() external returns (address);
    function auraAddress() external returns (address);
    function nativeSymbol() external returns (string memory);
    function auraMinimum() external returns (uint);
}

// File: contracts/interfaces/ISoulSwapFactory.sol

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

// File: contracts/interfaces/ISoulSwapERC20.sol

pragma solidity >=0.5.0;

interface ISoulSwapERC20 {
    // event Approval(address indexed owner, address indexed spender, uint value);
    // event Transfer(address indexed from, address indexed to, uint value);

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
}


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



// File: contracts/libraries/SafeMath.sol

pragma solidity >=0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
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
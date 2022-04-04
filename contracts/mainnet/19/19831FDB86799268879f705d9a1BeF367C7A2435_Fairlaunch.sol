// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./Ownable.sol";
// import "hardhat/console.sol";

interface IPancakeRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}


interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
}

interface ITreasury {
    function mintFairLaunch(uint256 _amount) external;

    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (bool);

    function valueOf(address _token, uint256 _amount) external view returns (uint256 value_);
}

contract Fairlaunch is Ownable {
    using SafeMath for uint256;

    // ==== STRUCTS ====

    struct UserInfo {
        uint256 purchased; // XOD
        uint256 bonus; // XOD
        uint256 daiAmount;  // DAI
        uint256 vesting; // time left to be vested
        uint256 lastTime;
    }

    // ==== CONSTANTS ====

    uint256 public MAX_PER_ADDR = 2500e18; // max 2.5k DAI
    uint256 private constant MAX_PER_ADDR_WHT = 500e18; // max 500 DAI
    uint256 private constant MIN_PER_ADDR_WHT = 5e18; // max 5 DAI

    uint256 private constant MIN_PER_ADDR = 250e18; // max 250 DAI

    uint256 public constant MAX_FOR_SALE = 500000e18; // 500k DAI

    uint256 public constant MAX_FOR_SALE_WHT = 50000e18; // 500k DAI

    uint256 private constant VESTING_TERM = 15 days;

    uint256 private constant EXCHANGE_RATE_1 = 7; // 7 assets -> 1 XOD
    uint256 private constant EXCHANGE_RATE_2 = 10; // 10 assets -> 1 XOD
    uint256 private constant EXCHANGE_RATE_WHT = 5; // 5 assets -> 1 XOD

    uint256 private constant MARKET_PRICE = 12; // 1 XOD: $12

    uint256 public liquidityFee = 300; // 50%

    // ==== STORAGES ====

    IERC20 public DAI;
    IERC20 public XOD;

    uint256 private constant DAI_THRESHOLD_1 = 25000e18;   // 25k
    uint256 private constant BONUS_RATE_1 = 150;   // 15%
    
    uint256 private constant DAI_THRESHOLD_2 = 50000e18;   // 50k
    uint256 private constant BONUS_RATE_2 = 125;   // 12.5%
    
    uint256 private constant DAI_THRESHOLD_3 = 100000e18;   // 100k
    uint256 private constant BONUS_RATE_3 = 100;   // 10%
    
    uint256 private constant DAI_THRESHOLD_4 = 200000e18;   // 200k
    uint256 private constant BONUS_RATE_4 = 75;   // 7.5%
    
    uint256 private constant DAI_THRESHOLD_5 = 300000e18;   // 300k
    uint256 private constant BONUS_RATE_5 = 50;   // 5%

    uint256 public constant START_PRESALE_1 = 1648202400; // 25th March, 10:00 UTC
    uint256 public constant END_PRESALE_1   = 1648771200; // 31st March, 2022

    uint256 public START_PRESALE_2 = 1650034680; // 15th April 16:00 UTC
    uint256 public END_PRESALE_2   = 1650499200; // 21th April, 2022

    uint256 public START_VERSTING  = 1650585600; // 22th April, 2022
    
    uint256 public currentBonusRate;
    uint256[] public exchangeRate;

    uint256[] public startPresale;
    uint256[] public endPresale;

    uint256 public presaleNum; // Presale1 or presale2

    // staking contract
    address public staking;

    // treasury contract
    address public treasury;

    // router address
    address public router;

    // factory address
    address public factory;

    // finalized status
    bool public finalized;

    // total asset purchased;
    uint256 public totalPurchased;
    uint256 public totalPurchasedWHT;

    // total XOD saled
    uint256 public totalXODSaled;

    // white list for private sale
    mapping(address => bool) public isTeamlist;
    mapping(address => bool) public isWhitelist;
    mapping(uint => mapping(address => UserInfo)) public userInfo;

    // ==== EVENTS ====

    event Deposited(address indexed depositor, uint256 indexed amount);
    event Redeemed(address indexed recipient, uint256 payout, uint256 remaining);
    event TeamlistUpdated(address indexed depositor, bool indexed value);
    event WhitelistUpdated(address indexed depositor, bool indexed value);

    // ==== CONSTRUCTOR ====

    constructor(IERC20 _DAI) {
        DAI = _DAI;

        // startPresale = new uint256[](2);
        startPresale.push(START_PRESALE_1);
        startPresale.push(START_PRESALE_2);
        
        // endPresale = new uint256[](2);
        endPresale.push(END_PRESALE_1);
        endPresale.push(END_PRESALE_2);

        exchangeRate.push(EXCHANGE_RATE_1);
        exchangeRate.push(EXCHANGE_RATE_2);

        presaleNum = 1;
        // currentBonusRate = BONUS_RATE_5;
    }

    // ==== VIEW FUNCTIONS ====

    function availableFor(address _depositor) public view returns (uint256 amount_) {
        amount_ = 0;

        UserInfo memory user = userInfo[presaleNum-1][_depositor];
        uint256 totalAvailable = MAX_FOR_SALE.sub(totalPurchased);
        uint256 depositorAvailable = MAX_PER_ADDR.sub(user.daiAmount);
        amount_ = totalAvailable > depositorAvailable ? depositorAvailable : totalAvailable;
    }

    function availableForWhitelist(address _depositor) public view returns (uint256 amount_) {
        amount_ = 0;

        UserInfo memory user = userInfo[0][_depositor];
        uint256 totalAvailable = MAX_FOR_SALE_WHT.sub(totalPurchasedWHT);
        uint256 depositorAvailable = MAX_PER_ADDR_WHT.sub(user.daiAmount);
        amount_ = totalAvailable > depositorAvailable ? depositorAvailable : totalAvailable;
    }

    function payFor(uint256 _amount, uint256 _exchangeRate) public pure returns (uint256 XODAmount_) {
        // XOD decimals: 9
        // asset decimals: 18
        XODAmount_ = _amount.mul(1e9).div(_exchangeRate).div(1e18);
    }

    function percentVestedFor(address _depositor) public view returns (uint256 percentVested_) {
        UserInfo memory user1 = userInfo[0][_depositor];
        UserInfo memory user2 = userInfo[1][_depositor];

        uint256 lastTime = (user1.lastTime > user2.lastTime) ? user1.lastTime : user2.lastTime;

        if (block.timestamp < lastTime || block.timestamp < lastTime) return 0;

        uint256 vestingTerm = (user1.vesting > user2.vesting) ? user1.vesting : user2.vesting;

        uint256 timeSinceLast = block.timestamp.sub(lastTime);

        if (vestingTerm > 0) {
            percentVested_ = timeSinceLast.mul(10000).div(vestingTerm);
        } else {
            percentVested_ = 0;
        }
    }

    function pendingPayoutFor(address _depositor) external view returns (uint256 pendingPayout_) {
        uint256 percentVested = percentVestedFor(_depositor);
        uint256 payoutAll = userInfo[0][_depositor].purchased + userInfo[0][_depositor].bonus;
        payoutAll = payoutAll + userInfo[1][_depositor].purchased + userInfo[1][_depositor].bonus;

        if (percentVested >= 10000) { //Fully vested
            pendingPayout_ = payoutAll;
        } else {
            pendingPayout_ = payoutAll.mul(percentVested).div(10000);
        }
    }

    function getCurrentBonus(uint256 _totalPurchased) internal  {
        if (presaleNum == 2) {
            currentBonusRate = BONUS_RATE_5;
            return;
        }

        if (_totalPurchased <= DAI_THRESHOLD_1) {
            currentBonusRate = BONUS_RATE_1;
        } else if(_totalPurchased <= DAI_THRESHOLD_2) {
            currentBonusRate = BONUS_RATE_2;
        } else if(_totalPurchased <= DAI_THRESHOLD_3) {
            currentBonusRate = BONUS_RATE_3;
        } else if(_totalPurchased <= DAI_THRESHOLD_4) { // 200k
            currentBonusRate = BONUS_RATE_4;
        } else {
            currentBonusRate = 0;
        }
    }
    // ==== EXTERNAL FUNCTIONS ====

    function deposit(address _depositor, uint256 _amount) external {
        require(!finalized, "already finalized");
        require(_amount > 0, "Invalid DAI amount");

        uint256 available;
        uint256 XODAmount;
        
        if (presaleNum == 1 && block.timestamp >= END_PRESALE_1) { // if presale1 is ended, set presale num by 2, automatically.
            presaleNum = 2;
        }

        if (presaleNum == 1 && isWhitelist[_depositor]) {
            require(block.timestamp >= START_PRESALE_1 && block.timestamp <= END_PRESALE_2, "Sorry, presale is not enabled!");
            require(_amount >= MIN_PER_ADDR_WHT && _amount <= MAX_PER_ADDR_WHT, "whitelister can invest $5 ~ $500");
            
            available = availableForWhitelist(_depositor);
            require(_amount <= available, "exceed limit");
            totalPurchasedWHT = totalPurchasedWHT.add(_amount);
            XODAmount = payFor(_amount, EXCHANGE_RATE_WHT);
            totalXODSaled = totalXODSaled.add(XODAmount);
    
            UserInfo storage user = userInfo[0][_depositor];
            user.purchased = user.purchased.add(XODAmount);
            user.daiAmount = user.daiAmount.add(_amount);
            user.vesting = VESTING_TERM;
            user.lastTime = START_VERSTING;
        } else {
            require(block.timestamp >= startPresale[presaleNum-1] && block.timestamp <= endPresale[presaleNum-1], "Sorry, presale is not enabled!");
            
            UserInfo storage user = userInfo[presaleNum-1][_depositor];
            // if (user.daiAmount < MIN_PER_ADDR) {
            //     require(_amount >= MIN_PER_ADDR, "You should invest at least $250");
            // }
            
            getCurrentBonus(totalPurchased.add(_amount));

            available = availableFor(_depositor);
            require(_amount <= available, "exceed limit");

            totalPurchased = totalPurchased.add(_amount);

            XODAmount = payFor(_amount, exchangeRate[presaleNum-1]);
            uint256 bonusAmount = XODAmount.mul(currentBonusRate).div(1000);
            totalXODSaled = totalXODSaled.add(XODAmount).add(bonusAmount);

            user.purchased = user.purchased.add(XODAmount);
            user.bonus = user.bonus.add(bonusAmount);
            user.daiAmount = user.daiAmount.add(_amount);
            user.vesting = VESTING_TERM;
            user.lastTime = START_VERSTING;
        }

        DAI.transferFrom(msg.sender, address(this), _amount);

        emit Deposited(_depositor, _amount);
    }

    function redeem(address _recipient, bool _stake) external {
        require(finalized, "not finalized yet");

        UserInfo memory user1 = userInfo[0][_recipient];
        UserInfo memory user2 = userInfo[1][_recipient];

        uint256 percentVested = percentVestedFor(_recipient);
        if (percentVested == 0) return;

        if (percentVested >= 10000 || isTeamlist[_recipient]) {
            // if fully vested
            delete userInfo[0][_recipient]; // delete user info
            delete userInfo[1][_recipient]; // delete user info
            emit Redeemed(_recipient, user1.purchased + user2.purchased, 0); // emit bond data

            _stakeOrSend(_recipient, _stake, user1.purchased + user1.bonus + user2.purchased + user2.bonus); // pay user everything due
        } else {
            // if unfinished
            // calculate payout vested
            uint256 payout1 = user1.purchased.mul(percentVested).div(10000);
            uint256 bonusOut1 = user1.bonus.mul(percentVested).div(10000);

            uint256 payout2 = user2.purchased.mul(percentVested).div(10000);
            uint256 bonusOut2 = user2.bonus.mul(percentVested).div(10000);

            // store updated deposit info
            userInfo[0][_recipient] = UserInfo({
                purchased: user1.purchased.sub(payout1),
                bonus: user1.bonus.sub(bonusOut1),
                daiAmount: user1.daiAmount,
                vesting: user1.vesting.sub(block.timestamp.sub(user1.lastTime)),
                lastTime: block.timestamp
            });

            userInfo[1][_recipient] = UserInfo({
                purchased: user2.purchased.sub(payout2),
                bonus: user2.bonus.sub(bonusOut2),
                daiAmount: user2.daiAmount,
                vesting: user2.vesting.sub(block.timestamp.sub(user2.lastTime)),
                lastTime: block.timestamp
            });

            uint256 remaining = userInfo[0][_recipient].purchased + userInfo[0][_recipient].bonus;
            remaining = remaining + userInfo[1][_recipient].purchased + userInfo[1][_recipient].bonus;

            emit Redeemed(_recipient, payout1 + bonusOut1 + payout2 + bonusOut2,  remaining);

            _stakeOrSend(_recipient, _stake, payout1 + bonusOut1 + payout2 + bonusOut2);
        }
    }

    // ==== INTERNAL FUNCTIONS ====

    function _stakeOrSend(
        address _recipient,
        bool _stake,
        uint256 _amount
    ) internal {
        if (!_stake) {
            // if user does not want to stake
            XOD.transfer(_recipient, _amount); // send payout
        } else {
            // if user wants to stake
            XOD.approve(staking, _amount);
            IStaking(staking).stake(_amount, _recipient);
            IStaking(staking).claim(_recipient);
        }
    }

    // ==== RESTRICT FUNCTIONS ====

    function setTeamlist(address _depositor, bool _value) external onlyOwner {
        isTeamlist[_depositor] = _value;
        emit TeamlistUpdated(_depositor, _value);
    }

    function toggleTeamlist(address[] memory _depositors) external onlyOwner {
        for (uint256 i = 0; i < _depositors.length; i++) {
            isTeamlist[_depositors[i]] = !isTeamlist[_depositors[i]];
            emit TeamlistUpdated(_depositors[i], isTeamlist[_depositors[i]]);
        }
    }

    function setWhitelist(address _depositor, bool _value) external onlyOwner {
        isWhitelist[_depositor] = _value;
        emit WhitelistUpdated(_depositor, _value);
    }

    function toggleWhitelist(address[] memory _depositors) external onlyOwner {
        for (uint256 i = 0; i < _depositors.length; i++) {
            // isWhitelist[_depositors[i]] = !isWhitelist[_depositors[i]];
            isWhitelist[_depositors[i]] = true;
            emit WhitelistUpdated(_depositors[i], /*isWhitelist[_depositors[i]]*/ true);
        }
    }

    function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner {
        if (_token == address(0)) {
            payable(owner()).transfer(address(this).balance);
        } else {
            _amount = _amount * 10 ** 18;
            IERC20(_token).transfer(owner(), _amount);
        }
    }

    function setupContracts(
        IERC20 _XOD,
        address _staking,
        address _treasury,
        address _router,
        address _factory
    ) external onlyOwner {
        XOD = _XOD;
        staking = _staking;
        treasury = _treasury;
        router = _router;
        factory = _factory;
    }

    // finalize the sale, init liquidity and deposit treasury
    // 100% public goes to LP pool and goes to treasury as liquidity asset
    // 100% private goes to treasury as stable asset
    function finalize() external onlyOwner {
        require(!finalized, "already finalized");
        require(address(XOD) != address(0), "0 addr: XOD");
        require(address(router) != address(0), "0 addr: router");
        require(address(factory) != address(0), "0 addr: factory");
        require(address(treasury) != address(0), "0 addr: treasury");
        require(address(staking) != address(0), "0 addr: staking");

        uint256 realDAIAmount = DAI.balanceOf(address(this));
        // uint256 totalAmount = totalPurchased + totalPurchasedWHT;
        uint256 liquidityAmount = realDAIAmount.mul(liquidityFee).div(1000);
        uint256 reserveAmount = realDAIAmount.sub(liquidityAmount);

        uint256 mintForFairLaunch = totalXODSaled;
        uint256 mintForLiquidity = liquidityAmount.div(MARKET_PRICE).div(1e9);
        ITreasury(treasury).mintFairLaunch(mintForFairLaunch.add(mintForLiquidity));

        DAI.approve(treasury, 0);
        DAI.approve(treasury, reserveAmount);
        uint256 profit = ITreasury(treasury).valueOf(address(DAI), reserveAmount);
        ITreasury(treasury).deposit(reserveAmount, address(DAI), profit);

        // add liquidity
        DAI.approve(router, 0);
        DAI.approve(router, liquidityAmount);
        XOD.approve((router), 0);
        XOD.approve((router), mintForLiquidity);
        IPancakeRouter(router).addLiquidity(
            address(DAI),
            address(XOD),
            liquidityAmount,
            mintForLiquidity,
            0,
            0,
            address(this),
            block.timestamp
        );

        // give treasury 100% LP, mint 50% XOD
        // FAIR DEAL !!!!
        address liquidityPair = IPancakeFactory(factory).getPair(address(DAI), address(XOD));
        uint256 lpProfit = ITreasury(treasury).valueOf(liquidityPair, IERC20(liquidityPair).balanceOf(address(this)));

        IERC20(liquidityPair).approve(treasury, 0);
        IERC20(liquidityPair).approve(treasury, IERC20(liquidityPair).balanceOf(address(this)));
        ITreasury(treasury).deposit(IERC20(liquidityPair).balanceOf(address(this)), liquidityPair, lpProfit);

        finalized = true;
    }

    function setPresalePeriod(uint8 _index, uint256 _start, uint256 _end) public onlyOwner {
        require( _index == 1 || _index == 2, "Invalid Index");
        
        startPresale[_index - 1] = _start;
        endPresale[_index - 1] = _end;
    }

    function setStartPresale(uint8 _index) public onlyOwner {
        require(block.timestamp < endPresale[_index - 1], "Presale period was already expired");
        presaleNum = _index;
    }

    function setLiquidityFee(uint256 _percent) external onlyOwner {
        require(_percent < 1000, "fee could not over 100%");
        liquidityFee = _percent;
    }

    function setLaunchDay (uint256 _date) external onlyOwner {
        require(_date > block.timestamp, "Invalid Parameter");
        START_VERSTING = _date;
    }

    function setMaxPerAddress(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        MAX_PER_ADDR = _amount;
    }

    function setFinalize() external onlyOwner {
        require(finalized == false, "already finalized");
        require(address(XOD) != address(0), "0 addr: XOD");
        require(address(treasury) != address(0), "0 addr: treasury");

        finalized = true;

        ITreasury(treasury).mintFairLaunch(totalXODSaled);
    }

    function getTimeStamp() external view returns (uint256) {
        return block.timestamp;
    }

    function restoreInfo(address[] calldata _depositors, uint256[] calldata _amounts) external onlyOwner {
        require(!finalized, "already finalized");
        require(_depositors.length == _amounts.length, "Invalid data: data length should be same");
        
        uint256 available;
        uint256 XODAmount;
        
        for (uint256 i = 0; i < _depositors.length; i++) {
            if (isWhitelist[_depositors[i]]) {
                require(_amounts[i] >= MIN_PER_ADDR_WHT && _amounts[i] <= MAX_PER_ADDR_WHT, "whitelister can invest $5 ~ $500");
                
                available = availableForWhitelist(_depositors[i]);
                require(_amounts[i] <= available, "exceed limit");
                totalPurchasedWHT = totalPurchasedWHT.add(_amounts[i]);
                XODAmount = payFor(_amounts[i], EXCHANGE_RATE_WHT);
                totalXODSaled = totalXODSaled.add(XODAmount);
        
                UserInfo storage user = userInfo[0][_depositors[i]];
                user.purchased = user.purchased.add(XODAmount);
                user.daiAmount = user.daiAmount.add(_amounts[i]);
                user.vesting = VESTING_TERM;
                user.lastTime = START_VERSTING;
            } else {
                UserInfo storage user = userInfo[0][_depositors[i]];
                // if (user.daiAmount < MIN_PER_ADDR) {
                //     require(_amounts[i] >= MIN_PER_ADDR, "You should invest at least $250");
                // }
                
                getCurrentBonus(totalPurchased.add(_amounts[i]));

                available = availableFor(_depositors[i]);
                require(_amounts[i] <= available, "exceed limit");

                totalPurchased = totalPurchased.add(_amounts[i]);

                XODAmount = payFor(_amounts[i], exchangeRate[presaleNum-1]);
                uint256 bonusAmount = XODAmount.mul(currentBonusRate).div(1000);
                totalXODSaled = totalXODSaled.add(XODAmount).add(bonusAmount);
                // console.log("Xod amount: ", XODAmount, "DAI amount: ", _amounts[i]);
                user.purchased = user.purchased.add(XODAmount);
                user.bonus = user.bonus.add(bonusAmount);
                user.daiAmount = user.daiAmount.add(_amounts[i]);
                user.vesting = VESTING_TERM;
                user.lastTime = START_VERSTING;
            }

            emit Deposited(_depositors[i], _amounts[i]);
        }
    }

}
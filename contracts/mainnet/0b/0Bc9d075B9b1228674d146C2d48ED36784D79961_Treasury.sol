// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "Math.sol";
import "SafeMath.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol";

import "Babylonian.sol";
import "Operator.sol";
import "ContractGuard.sol";
import "IBasisAsset.sol";
import "IOracle.sol";
import "IBoardroom.sol";

contract Treasury is ContractGuard {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public constant PERIOD = 6 hours;

    address public operator;

    bool public initialized = false;

    uint256 public startTime;
    uint256 public epoch = 0;
    uint256 public epochSupplyContractionLeft = 0;

    address[] public excludedFromTotalSupply = [
        address(0xa961a4ae78471cF981Fdbead9aB6E786f177E373),    // BeeGenesisPool
        address(0x6CB7A5d327e20adb22bc493A70078CDA1B0aB005)     // BeeRewardPool
    ];

    address public bee;
    address public swarm;
    address public honey;

    address public boardroom;
    address public beeOracle;

    uint256 public beePriceOne;
    uint256 public beePriceCeiling;

    uint256 public seigniorageSaved;

    uint256[] public supplyTiers;
    uint256[] public maxExpansionTiers;

    uint256 public maxSupplyExpansionPercent;
    uint256 public bondDepletionFloorPercent;
    uint256 public seigniorageExpansionFloorPercent;
    uint256 public maxSupplyContractionPercent;
    uint256 public maxDebtRatioPercent;

    uint256 public bootstrapEpochs;
    uint256 public bootstrapSupplyExpansionPercent;

    uint256 public previousEpochBeePrice;
    uint256 public maxDiscountRate; // when purchasing bond
    uint256 public maxPremiumRate; // when redeeming bond
    uint256 public discountPercent;
    uint256 public premiumThreshold;
    uint256 public premiumPercent;
    uint256 public mintingFactorForPayingDebt; // print extra BEE during debt phase

    address public daoFund;
    uint256 public daoFundSharedPercent;

    address public devFund;
    uint256 public devFundSharedPercent;

    event Initialized(address indexed executor, uint256 at);
    event BurnedBonds(address indexed from, uint256 bondAmount);
    event RedeemedBonds(address indexed from, uint256 beeAmount, uint256 bondAmount);
    event BoughtBonds(address indexed from, uint256 beeAmount, uint256 bondAmount);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event BoardroomFunded(uint256 timestamp, uint256 seigniorage);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
    event DevFundFunded(uint256 timestamp, uint256 seigniorage);

    modifier onlyOperator() {
        require(operator == msg.sender, "Treasury: caller not operator");
        _;
    }

    modifier checkCondition() {
        require(block.timestamp >= startTime, "Treasury: not started");

        _;
    }

    modifier checkEpoch() {
        require(block.timestamp >= nextEpochPoint(), "Treasury: not opened");

        _;

        epoch = epoch.add(1);
        epochSupplyContractionLeft = (getBeePrice() > beePriceCeiling) ? 0 : getBeeCirculatingSupply().mul(maxSupplyContractionPercent).div(10000);
    }

    modifier checkOperator() {
        require(
                IBasisAsset(bee).operator() == address(this) &&
                IBasisAsset(swarm).operator() == address(this) &&
                IBasisAsset(honey).operator() == address(this) &&
                Operator(boardroom).operator() == address(this),
                "Treasury: need more permission");

        _;
    }

    modifier notInitialized() {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    function getBeePrice() public view returns (uint256 beePrice) {
        try IOracle(beeOracle).consult(bee, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult BEE price from the oracle");
        }
    }

    function getBeeUpdatedPrice() public view returns (uint256 _beePrice) {
        try IOracle(beeOracle).twap(bee, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult BEE price from the oracle");
        }
    }

    function getReserve() public view returns (uint256) {
        return seigniorageSaved;
    }

    function getBurnableBeeLeft() public view returns (uint256 _burnableBeeLeft) {
        uint256 _beePrice = getBeePrice();
        if (_beePrice <= beePriceOne) {
            uint256 _beeSupply = getBeeCirculatingSupply();
            uint256 _bondMaxSupply = _beeSupply.mul(maxDebtRatioPercent).div(10000);
            uint256 _bondSupply = IERC20(honey).totalSupply();
            if (_bondMaxSupply > _bondSupply) {
                uint256 _maxMintableBond = _bondMaxSupply.sub(_bondSupply);
                uint256 _maxBurnableBee = _maxMintableBond.mul(_beePrice).div(1e18);
                _burnableBeeLeft = Math.min(epochSupplyContractionLeft, _maxBurnableBee);
            }
        }
    }

    function getRedeemableBonds() public view returns (uint256 _redeemableBonds) {
        uint256 _beePrice = getBeePrice();
        if (_beePrice > beePriceCeiling) {
            uint256 _totalBee = IERC20(bee).balanceOf(address(this));
            uint256 _rate = getBondPremiumRate();
            if (_rate > 0) {
                _redeemableBonds = _totalBee.mul(1e18).div(_rate);
            }
        }
    }

    function getBondDiscountRate() public view returns (uint256 _rate) {
        uint256 _beePrice = getBeePrice();
        if (_beePrice <= beePriceOne) {
            if (discountPercent == 0) {
                _rate = beePriceOne;
            } else {
                uint256 _bondAmount = beePriceOne.mul(1e18).div(_beePrice); // to burn 1 BEE
                uint256 _discountAmount = _bondAmount.sub(beePriceOne).mul(discountPercent).div(10000);
                _rate = beePriceOne.add(_discountAmount);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    function getBondPremiumRate() public view returns (uint256 _rate) {
        uint256 _beePrice = getBeePrice();
        if (_beePrice > beePriceCeiling) {
            uint256 _beePricePremiumThreshold = beePriceOne.mul(premiumThreshold).div(100);
            if (_beePrice >= _beePricePremiumThreshold) {
                uint256 _premiumAmount = _beePrice.sub(beePriceOne).mul(premiumPercent).div(10000);
                _rate = beePriceOne.add(_premiumAmount);
                if (maxPremiumRate > 0 && _rate > maxPremiumRate) {
                    _rate = maxPremiumRate;
                }
            } else {
                _rate = beePriceOne;
            }
        }
    }

    function initialize(
        address _bee,
        address _swarm,
        address _honey,
        address _beeOracle,
        address _boardroom,
        uint256 _startTime
    ) public notInitialized {
        bee = _bee;
        swarm = _swarm;
        honey = _honey;
        beeOracle = _beeOracle;
        boardroom = _boardroom;
        startTime = _startTime;

        beePriceOne = 10**18;
        beePriceCeiling = beePriceOne.mul(101).div(100);

        supplyTiers = [0 ether, 500000 ether, 1000000 ether, 1500000 ether, 2000000 ether, 5000000 ether, 10000000 ether, 20000000 ether, 50000000 ether];
        maxExpansionTiers = [450, 400, 350, 300, 250, 200, 150, 125, 100];

        maxSupplyExpansionPercent = 400; // Upto 4.0% supply for expansion

        bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor
        seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for boardroom
        maxSupplyContractionPercent = 300; // Upto 3.0% supply for contraction (to burn BEE and mint tBOND)
        maxDebtRatioPercent = 4500; // Upto 35% supply of tBOND to purchase

        premiumThreshold = 110;
        premiumPercent = 7000;

        // First 28 epochs with 4.5% expansion
        bootstrapEpochs = 28;
        bootstrapSupplyExpansionPercent = 450;

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20(bee).balanceOf(address(this));

        initialized = true;
        operator = msg.sender;
        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setBoardroom(address _boardroom) external onlyOperator {
        boardroom = _boardroom;
    }

    function setBeeOracle(address _beeOracle) external onlyOperator {
        beeOracle = _beeOracle;
    }

    function setBeePriceCeiling(uint256 _beePriceCeiling) external onlyOperator {
        require(_beePriceCeiling >= beePriceOne && _beePriceCeiling <= beePriceOne.mul(120).div(100), "out of range"); // [$1.0, $1.2]
        beePriceCeiling = _beePriceCeiling;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent) external onlyOperator {
        require(_maxSupplyExpansionPercent >= 10 && _maxSupplyExpansionPercent <= 1000, "_maxSupplyExpansionPercent: out of range"); // [0.1%, 10%]
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }

    function setSupplyTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 9, "Index has to be lower than count of tiers");
        if (_index > 0) {
            require(_value > supplyTiers[_index - 1]);
        }
        if (_index < 8) {
            require(_value < supplyTiers[_index + 1]);
        }
        supplyTiers[_index] = _value;
        return true;
    }

    function setMaxExpansionTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 9, "Index has to be lower than count of tiers");
        require(_value >= 10 && _value <= 1000, "_value: out of range"); // [0.1%, 10%]
        maxExpansionTiers[_index] = _value;
        return true;
    }

    function setBondDepletionFloorPercent(uint256 _bondDepletionFloorPercent) external onlyOperator {
        require(_bondDepletionFloorPercent >= 500 && _bondDepletionFloorPercent <= 10000, "out of range"); // [5%, 100%]
        bondDepletionFloorPercent = _bondDepletionFloorPercent;
    }

    function setMaxSupplyContractionPercent(uint256 _maxSupplyContractionPercent) external onlyOperator {
        require(_maxSupplyContractionPercent >= 100 && _maxSupplyContractionPercent <= 1500, "out of range"); // [0.1%, 15%]
        maxSupplyContractionPercent = _maxSupplyContractionPercent;
    }

    function setMaxDebtRatioPercent(uint256 _maxDebtRatioPercent) external onlyOperator {
        require(_maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= 10000, "out of range"); // [10%, 100%]
        maxDebtRatioPercent = _maxDebtRatioPercent;
    }

    function setBootstrap(uint256 _bootstrapEpochs, uint256 _bootstrapSupplyExpansionPercent) external onlyOperator {
        require(_bootstrapEpochs <= 120, "_bootstrapEpochs: out of range"); // <= 1 month
        require(_bootstrapSupplyExpansionPercent >= 100 && _bootstrapSupplyExpansionPercent <= 1000, "_bootstrapSupplyExpansionPercent: out of range"); // [1%, 10%]
        bootstrapEpochs = _bootstrapEpochs;
        bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
    }

    function setExtraFunds(
        address _daoFund,
        uint256 _daoFundSharedPercent,
        address _devFund,
        uint256 _devFundSharedPercent
    ) external onlyOperator {
        require(_daoFund != address(0), "zero");
        require(_daoFundSharedPercent <= 3000, "out of range"); // <= 30%
        require(_devFund != address(0), "zero");
        require(_devFundSharedPercent <= 1000, "out of range"); // <= 10%
        daoFund = _daoFund;
        daoFundSharedPercent = _daoFundSharedPercent;
        devFund = _devFund;
        devFundSharedPercent = _devFundSharedPercent;
    }

    function setMaxDiscountRate(uint256 _maxDiscountRate) external onlyOperator {
        maxDiscountRate = _maxDiscountRate;
    }

    function setMaxPremiumRate(uint256 _maxPremiumRate) external onlyOperator {
        maxPremiumRate = _maxPremiumRate;
    }

    function setDiscountPercent(uint256 _discountPercent) external onlyOperator {
        require(_discountPercent <= 20000, "_discountPercent is over 200%");
        discountPercent = _discountPercent;
    }

    function setPremiumThreshold(uint256 _premiumThreshold) external onlyOperator {
        require(_premiumThreshold >= beePriceCeiling, "_premiumThreshold exceeds beePriceCeiling");
        require(_premiumThreshold <= 150, "_premiumThreshold is higher than 1.5");
        premiumThreshold = _premiumThreshold;
    }

    function setPremiumPercent(uint256 _premiumPercent) external onlyOperator {
        require(_premiumPercent <= 20000, "_premiumPercent is over 200%");
        premiumPercent = _premiumPercent;
    }

    function setMintingFactorForPayingDebt(uint256 _mintingFactorForPayingDebt) external onlyOperator {
        require(_mintingFactorForPayingDebt >= 10000 && _mintingFactorForPayingDebt <= 20000, "_mintingFactorForPayingDebt: out of range"); // [100%, 200%]
        mintingFactorForPayingDebt = _mintingFactorForPayingDebt;
    }

    function _updateBeePrice() internal {
        try IOracle(beeOracle).update() {} catch {}
    }

    function getBeeCirculatingSupply() public view returns (uint256) {
        IERC20 beeErc20 = IERC20(bee);
        uint256 totalSupply = beeErc20.totalSupply();
        uint256 balanceExcluded = 0;
        for (uint8 entryId = 0; entryId < excludedFromTotalSupply.length; ++entryId) {
            balanceExcluded = balanceExcluded.add(beeErc20.balanceOf(excludedFromTotalSupply[entryId]));
        }
        return totalSupply.sub(balanceExcluded);
    }

    function buyBonds(uint256 _beeAmount, uint256 targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_beeAmount > 0, "Treasury: cannot purchase bonds with zero amount");

        uint256 beePrice = getBeePrice();
        require(beePrice == targetPrice, "Treasury: BEE price moved");
        require(beePrice < beePriceOne, "Treasury: beePrice not eligible for bond purchase");

        require(_beeAmount <= epochSupplyContractionLeft, "Treasury: not enough bond left to purchase");

        uint256 _rate = getBondDiscountRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _bondAmount = _beeAmount.mul(_rate).div(1e18);
        uint256 beeSupply = getBeeCirculatingSupply();
        uint256 newBondSupply = IERC20(honey).totalSupply().add(_bondAmount);
        require(newBondSupply <= beeSupply.mul(maxDebtRatioPercent).div(10000), "over max debt ratio");

        IBasisAsset(bee).burnFrom(msg.sender, _beeAmount);
        IBasisAsset(honey).mint(msg.sender, _bondAmount);

        epochSupplyContractionLeft = epochSupplyContractionLeft.sub(_beeAmount);
        _updateBeePrice();

        emit BoughtBonds(msg.sender, _beeAmount, _bondAmount);
    }

    function redeemBonds(uint256 _bondAmount, uint256 targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_bondAmount > 0, "Treasury: cannot redeem bonds with zero amount");

        uint256 beePrice = getBeePrice();
        require(beePrice == targetPrice, "Treasury: BEE price moved");
        require(beePrice > beePriceCeiling, "Treasury: beePrice not eligible for bond purchase");

        uint256 _rate = getBondPremiumRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _beeAmount = _bondAmount.mul(_rate).div(1e18);
        require(IERC20(bee).balanceOf(address(this)) >= _beeAmount, "Treasury: treasury has no more budget");

        seigniorageSaved = seigniorageSaved.sub(Math.min(seigniorageSaved, _beeAmount));

        IBasisAsset(honey).burnFrom(msg.sender, _bondAmount);
        IERC20(bee).safeTransfer(msg.sender, _beeAmount);

        _updateBeePrice();

        emit RedeemedBonds(msg.sender, _beeAmount, _bondAmount);
    }

    function _sendToBoardroom(uint256 _amount) internal {

        IBasisAsset(bee).mint(address(this), _amount);

        uint256 _daoFundSharedAmount = 0;

        if (daoFundSharedPercent > 0) {
            _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(10000);
            IERC20(bee).transfer(daoFund, _daoFundSharedAmount);
            emit DaoFundFunded(block.timestamp, _daoFundSharedAmount);
        }

        uint256 _devFundSharedAmount = 0;
        if (devFundSharedPercent > 0) {
            _devFundSharedAmount = _amount.mul(devFundSharedPercent).div(10000);
            IERC20(bee).transfer(devFund, _devFundSharedAmount);
            emit DevFundFunded(block.timestamp, _devFundSharedAmount);
        }

        _amount = _amount.sub(_daoFundSharedAmount).sub(_devFundSharedAmount);

        IERC20(bee).safeApprove(boardroom, 0);
        IERC20(bee).safeApprove(boardroom, _amount);
        IBoardroom(boardroom).allocateSeigniorage(_amount);
        emit BoardroomFunded(block.timestamp, _amount);
    }

    function _calculateMaxSupplyExpansionPercent(uint256 _beeSupply) internal returns (uint256) {
        for (uint8 tierId = 8; tierId >= 0; --tierId) {
            if (_beeSupply >= supplyTiers[tierId]) {
                maxSupplyExpansionPercent = maxExpansionTiers[tierId];
                break;
            }
        }
        return maxSupplyExpansionPercent;
    }

    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
        _updateBeePrice();
        previousEpochBeePrice = getBeePrice();
        uint256 beeSupply = getBeeCirculatingSupply().sub(seigniorageSaved);
        if (epoch < bootstrapEpochs) {
            // 28 first epochs with 4.5% expansion
            _sendToBoardroom(beeSupply.mul(bootstrapSupplyExpansionPercent).div(10000));
        } else {
            if (previousEpochBeePrice > beePriceCeiling) {
                // Expansion ($BEE Price > 1 $FTM): there is some seigniorage to be allocated
                uint256 bondSupply = IERC20(honey).totalSupply();
                uint256 _percentage = previousEpochBeePrice.sub(beePriceOne);
                uint256 _savedForBond;
                uint256 _savedForBoardroom;
                uint256 _mse = _calculateMaxSupplyExpansionPercent(beeSupply).mul(1e18);
                if (_percentage > _mse) {
                    _percentage = _mse;
                }
                if (seigniorageSaved >= bondSupply.mul(bondDepletionFloorPercent).div(10000)) {
                    // saved enough to pay debt, mint as usual rate
                    _savedForBoardroom = beeSupply.mul(_percentage).div(1e18);
                } else {
                    // have not saved enough to pay debt, mint more
                    uint256 _seigniorage = beeSupply.mul(_percentage).div(1e18);
                    _savedForBoardroom = _seigniorage.mul(seigniorageExpansionFloorPercent).div(10000);
                    _savedForBond = _seigniorage.sub(_savedForBoardroom);
                    if (mintingFactorForPayingDebt > 0) {
                        _savedForBond = _savedForBond.mul(mintingFactorForPayingDebt).div(10000);
                    }
                }
                if (_savedForBoardroom > 0) {
                    _sendToBoardroom(_savedForBoardroom);
                }
                if (_savedForBond > 0) {
                    seigniorageSaved = seigniorageSaved.add(_savedForBond);
                    IBasisAsset(bee).mint(address(this), _savedForBond);
                    emit TreasuryFunded(block.timestamp, _savedForBond);
                }
            }
        }
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        require(address(_token) != address(bee), "bee");
        require(address(_token) != address(swarm), "swarm");
        require(address(_token) != address(honey), "honey");
        _token.safeTransfer(_to, _amount);
    }

    function boardroomSetOperator(address _operator) external onlyOperator {
        IBoardroom(boardroom).setOperator(_operator);
    }

    function boardroomSetLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external onlyOperator {
        IBoardroom(boardroom).setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs);
    }

    function boardroomAllocateSeigniorage(uint256 amount) external onlyOperator {
        IBoardroom(boardroom).allocateSeigniorage(amount);
    }

    function boardroomGovernanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        IBoardroom(boardroom).governanceRecoverUnsupported(_token, _amount, _to);
    }
}
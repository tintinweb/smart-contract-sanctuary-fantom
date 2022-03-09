// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./owner/Operator.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IHamsterWheel.sol";


contract Treasury is ContractGuard {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    uint256 public constant PERIOD = 6 hours;
    address public operator;
    bool public initialized = false;
    uint256 public startTime;
    uint256 public epoch = 0;
    uint256 public epochSupplyContractionLeft = 0;
    address[] public excludedFromTotalSupply;
    address public hamster;
    address public hamsterbond;
    address public hamstershare;
    address public hamsterWheel;
    address public hamsterOracle;
    uint256 public hamsterPriceOne;
    uint256 public hamsterPriceCeiling;
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
    uint256 public previousEpochHamsterPrice;
    uint256 public maxDiscountRate;
    uint256 public maxPremiumRate;
    uint256 public discountPercent;
    uint256 public premiumThreshold;
    uint256 public premiumPercent;
    uint256 public mintingFactorForPayingDebt;
    address public daoFund;
    uint256 public daoFundSharedPercent;
    address public devFund;
    uint256 public devFundSharedPercent;

    function getBurnableHamsterLeft() external view returns (uint256 _burnableHamsterLeft) {
        uint256 _hamsterPrice = getHamsterPrice();
        if (_hamsterPrice <= hamsterPriceOne) {
            uint256 _hamsterSupply = getHamsterCirculatingSupply();
            uint256 _bondMaxSupply = _hamsterSupply.mul(maxDebtRatioPercent).div(10000);
            uint256 _bondSupply = IERC20(hamsterbond).totalSupply();
            if (_bondMaxSupply > _bondSupply) {
                uint256 _maxMintableBond = _bondMaxSupply.sub(_bondSupply);
                uint256 _maxBurnableHamster = _maxMintableBond.mul(_hamsterPrice).div(1e18);
                _burnableHamsterLeft = Math.min(epochSupplyContractionLeft, _maxBurnableHamster);
            }
        }
    }

    function getHamsterUpdatedPrice() external view returns (uint256 _hamsterPrice) {
        try IOracle(hamsterOracle).twap(hamster, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult HAMSTER price from the oracle");
        }
    }

    function getRedeemableBonds() external view returns (uint256 _redeemableBonds) {
        uint256 _hamsterPrice = getHamsterPrice();
        if (_hamsterPrice > hamsterPriceCeiling) {
            uint256 _totalHamster = IERC20(hamster).balanceOf(address(this));
            uint256 _rate = getBondPremiumRate();
            if (_rate > 0) {
                _redeemableBonds = _totalHamster.mul(1e18).div(_rate);
            }
        }
    }

    function getReserve() external view returns (uint256) {
        return seigniorageSaved;
    }

    function isInitialized() external view returns (bool) {
        return initialized;
    }

    function getBondDiscountRate() public view returns (uint256 _rate) {
        uint256 _hamsterPrice = getHamsterPrice();
        if (_hamsterPrice <= hamsterPriceOne) {
            if (discountPercent == 0) {
                _rate = hamsterPriceOne;
            } else {
                uint256 _bondAmount = hamsterPriceOne.mul(1e18).div(_hamsterPrice);
                uint256 _discountAmount = _bondAmount.sub(hamsterPriceOne).mul(discountPercent).div(10000);
                _rate = hamsterPriceOne.add(_discountAmount);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    function getBondPremiumRate() public view returns (uint256 _rate) {
        uint256 _hamsterPrice = getHamsterPrice();
        if (_hamsterPrice > hamsterPriceCeiling) {
            uint256 _hamsterPricePremiumThreshold = hamsterPriceOne.mul(premiumThreshold).div(100);
            if (_hamsterPrice >= _hamsterPricePremiumThreshold) {
                uint256 _premiumAmount = _hamsterPrice.sub(hamsterPriceOne).mul(premiumPercent).div(10000);
                _rate = hamsterPriceOne.add(_premiumAmount);
                if (maxPremiumRate > 0 && _rate > maxPremiumRate) {
                    _rate = maxPremiumRate;
                }
            } else {
                _rate = hamsterPriceOne;
            }
        }
    }

    function getHamsterCirculatingSupply() public view returns (uint256) {
        IERC20 hamsterErc20 = IERC20(hamster);
        uint256 totalSupply = hamsterErc20.totalSupply();
        uint256 balanceExcluded = 0;
        for (uint8 entryId = 0; entryId < excludedFromTotalSupply.length; ++entryId) {
            balanceExcluded = balanceExcluded.add(hamsterErc20.balanceOf(excludedFromTotalSupply[entryId]));
        }
        return totalSupply.sub(balanceExcluded);
    }

    function getHamsterPrice() public view returns (uint256 hamsterPrice) {
        try IOracle(hamsterOracle).consult(hamster, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult HAMSTER price from the oracle");
        }
    }

    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    event Initialized(address indexed executor, uint256 at);
    event BurnedBonds(address indexed from, uint256 bondAmount);
    event RedeemedBonds(address indexed from, uint256 hamsterAmount, uint256 bondAmount, uint256 epochNumber);
    event BoughtBonds(address indexed from, uint256 hamsterAmount, uint256 bondAmount, uint256 epochNumber);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage, uint256 epochNumber);
    event HamsterWheelFunded(uint256 timestamp, uint256 seigniorage, uint256 epochNumber);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage, uint256 epochNumber);
    event DevFundFunded(uint256 timestamp, uint256 seigniorage, uint256 epochNumber);

    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
        _updateHamsterPrice();
        previousEpochHamsterPrice = getHamsterPrice();
        uint256 hamsterSupply = getHamsterCirculatingSupply().sub(seigniorageSaved);
        if (epoch < bootstrapEpochs) {
            _sendToHamsterWheel(hamsterSupply.mul(bootstrapSupplyExpansionPercent).div(10000));
        } else {
            if (previousEpochHamsterPrice > hamsterPriceCeiling) {
                uint256 bondSupply = IERC20(hamsterbond).totalSupply();
                uint256 _percentage = previousEpochHamsterPrice.sub(hamsterPriceOne);
                uint256 _savedForBond;
                uint256 _savedForHamsterWheel;
                uint256 _mse = _calculateMaxSupplyExpansionPercent(hamsterSupply).mul(1e14);
                if (_percentage > _mse) {
                    _percentage = _mse;
                }
                if (seigniorageSaved >= bondSupply.mul(bondDepletionFloorPercent).div(10000)) {
                    _savedForHamsterWheel = hamsterSupply.mul(_percentage).div(1e18);
                } else {
                    uint256 _seigniorage = hamsterSupply.mul(_percentage).div(1e18);
                    _savedForHamsterWheel = _seigniorage.mul(seigniorageExpansionFloorPercent).div(10000);
                    _savedForBond = _seigniorage.sub(_savedForHamsterWheel);
                    if (mintingFactorForPayingDebt > 0) {
                        _savedForBond = _savedForBond.mul(mintingFactorForPayingDebt).div(10000);
                    }
                }
                if (_savedForHamsterWheel > 0) {
                    _sendToHamsterWheel(_savedForHamsterWheel);
                }
                if (_savedForBond > 0) {
                    seigniorageSaved = seigniorageSaved.add(_savedForBond);
                    IBasisAsset(hamster).mint(address(this), _savedForBond);
                    emit TreasuryFunded(now, _savedForBond, epoch);
                }
            }
        }
    }

    function buyBonds(
        uint256 _hamsterAmount,
        uint256 targetPrice
    ) external onlyOneBlock checkCondition checkOperator {
        require(_hamsterAmount > 0, "Treasury: cannot purchase bonds with zero amount");
        uint256 hamsterPrice = getHamsterPrice();
        require(hamsterPrice == targetPrice, "Treasury: HAMSTER price moved");
        require(
            hamsterPrice < hamsterPriceOne,
            "Treasury: hamsterPrice not eligible for bond purchase"
        );
        require(_hamsterAmount <= epochSupplyContractionLeft, "Treasury: not enough bond left to purchase");
        uint256 _rate = getBondDiscountRate();
        require(_rate > 0, "Treasury: invalid bond rate");
        uint256 _bondAmount = _hamsterAmount.mul(_rate).div(1e18);
        uint256 hamsterSupply = getHamsterCirculatingSupply();
        uint256 newBondSupply = IERC20(hamsterbond).totalSupply().add(_bondAmount);
        require(newBondSupply <= hamsterSupply.mul(maxDebtRatioPercent).div(10000), "over max debt ratio");
        IBasisAsset(hamster).burnFrom(msg.sender, _hamsterAmount);
        IBasisAsset(hamsterbond).mint(msg.sender, _bondAmount);
        epochSupplyContractionLeft = epochSupplyContractionLeft.sub(_hamsterAmount);
        _updateHamsterPrice();
        emit BoughtBonds(msg.sender, _hamsterAmount, _bondAmount, epoch);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        require(address(_token) != address(hamster), "hamster");
        require(address(_token) != address(hamsterbond), "bond");
        require(address(_token) != address(hamstershare), "share");
        _token.safeTransfer(_to, _amount);
    }

    function hamsterWheelAllocateSeigniorage(uint256 amount) external onlyOperator {
        IHamsterWheel(hamsterWheel).allocateSeigniorage(amount);
    }

    function hamsterWheelGovernanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        IHamsterWheel(hamsterWheel).governanceRecoverUnsupported(_token, _amount, _to);
    }

    function hamsterWheelSetLockUp(
        uint256 _withdrawLockupEpochs,
        uint256 _rewardLockupEpochs
    ) external onlyOperator {
        IHamsterWheel(hamsterWheel).setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs);
    }

    function hamsterWheelSetOperator(address _operator) external onlyOperator {
        IHamsterWheel(hamsterWheel).setOperator(_operator);
    }

    function initialize(
        address _hamster,
        address _hamsterbond,
        address _hamstershare,
        address _hamsterOracle,
        address _hamsterWheel,
        uint256 _startTime,
        address[] memory excludedFromTotalSupply_
    ) external notInitialized {
        hamster = _hamster;
        hamsterbond = _hamsterbond;
        hamstershare = _hamstershare;
        hamsterOracle = _hamsterOracle;
        hamsterWheel = _hamsterWheel;
        startTime = _startTime;
        hamsterPriceOne = 10**18;
        hamsterPriceCeiling = hamsterPriceOne.mul(101).div(100);
        supplyTiers = [
            0 ether,
            500000 ether,
            1000000 ether,
            1500000 ether,
            2000000 ether,
            5000000 ether,
            10000000 ether,
            20000000 ether,
            50000000 ether
        ];
        maxExpansionTiers = [
            450,
            400,
            350,
            300,
            250,
            200,
            150,
            125,
            100
        ];
        maxSupplyExpansionPercent = 400;
        bondDepletionFloorPercent = 10000;
        seigniorageExpansionFloorPercent = 3500;
        maxSupplyContractionPercent = 300;
        maxDebtRatioPercent = 3500;
        premiumThreshold = 110;
        premiumPercent = 7000;
        bootstrapEpochs = 28;
        bootstrapSupplyExpansionPercent = 450;
        seigniorageSaved = IERC20(hamster).balanceOf(address(this));
        initialized = true;
        operator = msg.sender;
        for (uint256 i = 0; i < excludedFromTotalSupply_.length; i++) {
            excludedFromTotalSupply.push(excludedFromTotalSupply_[i]);
            // HamsterGenesisPool && HamsterRewardPool
        }
        emit Initialized(msg.sender, block.number);
    }

    function redeemBonds(
        uint256 _bondAmount,
        uint256 targetPrice
    ) external onlyOneBlock checkCondition checkOperator {
        require(_bondAmount > 0, "Treasury: cannot redeem bonds with zero amount");
        uint256 hamsterPrice = getHamsterPrice();
        require(hamsterPrice == targetPrice, "Treasury: HAMSTER price moved");
        require(
            hamsterPrice > hamsterPriceCeiling,
            "Treasury: hamsterPrice not eligible for bond purchase"
        );
        uint256 _rate = getBondPremiumRate();
        require(_rate > 0, "Treasury: invalid bond rate");
        uint256 _hamsterAmount = _bondAmount.mul(_rate).div(1e18);
        require(IERC20(hamster).balanceOf(address(this)) >= _hamsterAmount, "Treasury: treasury has no more budget");
        seigniorageSaved = seigniorageSaved.sub(Math.min(seigniorageSaved, _hamsterAmount));
        IBasisAsset(hamsterbond).burnFrom(msg.sender, _bondAmount);
        IERC20(hamster).safeTransfer(msg.sender, _hamsterAmount);
        _updateHamsterPrice();
        emit RedeemedBonds(msg.sender, _hamsterAmount, _bondAmount, epoch);
    }

    function setBondDepletionFloorPercent(uint256 _bondDepletionFloorPercent) external onlyOperator {
        require(
            _bondDepletionFloorPercent >= 500 && _bondDepletionFloorPercent <= 10000,
            "out of range"
        );
        bondDepletionFloorPercent = _bondDepletionFloorPercent;
    }

    function setBootstrap(uint256 _bootstrapEpochs, uint256 _bootstrapSupplyExpansionPercent) external onlyOperator {
        require(_bootstrapEpochs <= 120, "_bootstrapEpochs: out of range");
        require(
            _bootstrapSupplyExpansionPercent >= 100 && _bootstrapSupplyExpansionPercent <= 1000,
            "_bootstrapSupplyExpansionPercent: out of range"
        );
        bootstrapEpochs = _bootstrapEpochs;
        bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
    }

    function setDiscountPercent(uint256 _discountPercent) external onlyOperator {
        require(_discountPercent <= 20000, "_discountPercent is over 200%");
        discountPercent = _discountPercent;
    }

    function setExtraFunds(
        address _daoFund,
        uint256 _daoFundSharedPercent,
        address _devFund,
        uint256 _devFundSharedPercent
    ) external onlyOperator {
        require(_daoFund != address(0), "zero");
        require(_daoFundSharedPercent <= 3000, "out of range");
        require(_devFund != address(0), "zero");
        require(_devFundSharedPercent <= 1000, "out of range");
        daoFund = _daoFund;
        daoFundSharedPercent = _daoFundSharedPercent;
        devFund = _devFund;
        devFundSharedPercent = _devFundSharedPercent;
    }

    function setHamsterOracle(address _hamsterOracle) external onlyOperator {
        hamsterOracle = _hamsterOracle;
    }

    function setHamsterPriceCeiling(uint256 _hamsterPriceCeiling) external onlyOperator {
        require(
            _hamsterPriceCeiling >= hamsterPriceOne && _hamsterPriceCeiling <= hamsterPriceOne.mul(120).div(100),
            "out of range"
        );
        hamsterPriceCeiling = _hamsterPriceCeiling;
    }

    function setHamsterWheel(address _hamsterWheel) external onlyOperator {
        hamsterWheel = _hamsterWheel;
    }

    function setMaxDebtRatioPercent(uint256 _maxDebtRatioPercent) external onlyOperator {
        require(_maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= 10000, "out of range");
        maxDebtRatioPercent = _maxDebtRatioPercent;
    }

    function setMaxDiscountRate(uint256 _maxDiscountRate) external onlyOperator {
        maxDiscountRate = _maxDiscountRate;
    }

    function setMaxExpansionTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 9, "Index has to be lower than count of tiers");
        require(_value >= 10 && _value <= 1000, "_value: out of range");
        maxExpansionTiers[_index] = _value;
        return true;
    }

    function setMaxPremiumRate(uint256 _maxPremiumRate) external onlyOperator {
        maxPremiumRate = _maxPremiumRate;
    }

    function setMaxSupplyContractionPercent(uint256 _maxSupplyContractionPercent) external onlyOperator {
        require(
            _maxSupplyContractionPercent >= 100 && _maxSupplyContractionPercent <= 1500,
            "out of range"
        );
        maxSupplyContractionPercent = _maxSupplyContractionPercent;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent) external onlyOperator {
        require(
            _maxSupplyExpansionPercent >= 10 && _maxSupplyExpansionPercent <= 1000,
            "_maxSupplyExpansionPercent: out of range"
        );
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }

    function setMintingFactorForPayingDebt(uint256 _mintingFactorForPayingDebt) external onlyOperator {
        require(
            _mintingFactorForPayingDebt >= 10000 && _mintingFactorForPayingDebt <= 20000,
            "_mintingFactorForPayingDebt: out of range"
        );
        mintingFactorForPayingDebt = _mintingFactorForPayingDebt;
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setPremiumPercent(uint256 _premiumPercent) external onlyOperator {
        require(_premiumPercent <= 20000, "_premiumPercent is over 200%");
        premiumPercent = _premiumPercent;
    }

    function setPremiumThreshold(uint256 _premiumThreshold) external onlyOperator {
        require(_premiumThreshold >= hamsterPriceCeiling, "_premiumThreshold exceeds hamsterPriceCeiling");
        require(_premiumThreshold <= 150, "_premiumThreshold is higher than 1.5");
        premiumThreshold = _premiumThreshold;
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

    function _calculateMaxSupplyExpansionPercent(uint256 _hamsterSupply) internal returns (uint256) {
        for (uint8 tierId = 8; tierId >= 0; --tierId) {
            if (_hamsterSupply >= supplyTiers[tierId]) {
                maxSupplyExpansionPercent = maxExpansionTiers[tierId];
                break;
            }
        }
        return maxSupplyExpansionPercent;
    }

    function _sendToHamsterWheel(uint256 _amount) internal {
        IBasisAsset(hamster).mint(address(this), _amount);
        uint256 _daoFundSharedAmount = 0;
        if (daoFundSharedPercent > 0) {
            _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(10000);
            IERC20(hamster).transfer(daoFund, _daoFundSharedAmount);
            emit DaoFundFunded(now, _daoFundSharedAmount, epoch);
        }
        uint256 _devFundSharedAmount = 0;
        if (devFundSharedPercent > 0) {
            _devFundSharedAmount = _amount.mul(devFundSharedPercent).div(10000);
            IERC20(hamster).transfer(devFund, _devFundSharedAmount);
            emit DevFundFunded(now, _devFundSharedAmount, epoch);
        }
        _amount = _amount.sub(_daoFundSharedAmount).sub(_devFundSharedAmount);
        IERC20(hamster).safeApprove(hamsterWheel, 0);
        IERC20(hamster).safeApprove(hamsterWheel, _amount);
        IHamsterWheel(hamsterWheel).allocateSeigniorage(_amount);
        emit HamsterWheelFunded(now, _amount, epoch);
    }

    function _updateHamsterPrice() internal {
        try IOracle(hamsterOracle).update() {} catch {}
    }

    modifier checkCondition {
        require(now >= startTime, "Treasury: not started yet");
        _;
    }

    modifier checkEpoch {
        require(now >= nextEpochPoint(), "Treasury: not opened yet");
        _;
        epoch = epoch.add(1);
        epochSupplyContractionLeft = (getHamsterPrice() > hamsterPriceCeiling)
            ? 0
            : getHamsterCirculatingSupply().mul(maxSupplyContractionPercent).div(10000);
    }

    modifier checkOperator {
        require(
            IBasisAsset(hamster).operator() == address(this) &&
                IBasisAsset(hamsterbond).operator() == address(this) &&
                IBasisAsset(hamstershare).operator() == address(this) &&
                Operator(hamsterWheel).operator() == address(this),
            "Treasury: need more permission"
        );
        _;
    }

    modifier notInitialized {
        require(!initialized, "Treasury: already initialized");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "Treasury: caller is not the operator");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(!checkSameOriginReentranted(), "ContractGuard: one block, one function");
        require(!checkSameSenderReentranted(), "ContractGuard: one block, one function");
        _;
        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Operator is Ownable {
    address private _operator;

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function operator() public view returns (address) {
        return _operator;
    }

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() internal {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IOracle {
    function update() external;
    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);
    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IHamsterWheel {
    function balanceOf(address _mason) external view returns (uint256);
    function earned(address _mason) external view returns (uint256);
    function canWithdraw(address _mason) external view returns (bool);
    function canClaimReward(address _mason) external view returns (bool);
    function epoch() external view returns (uint256);
    function nextEpochPoint() external view returns (uint256);
    function getHamsterPrice() external view returns (uint256);
    function setOperator(address _operator) external;
    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external;
    function stake(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function exit() external;
    function claimReward() external;
    function allocateSeigniorage(uint256 _amount) external;
    function governanceRecoverUnsupported(address _token, uint256 _amount, address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
    function isOperator() external returns (bool);
    function operator() external view returns (address);
    function transferOperator(address newOperator_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
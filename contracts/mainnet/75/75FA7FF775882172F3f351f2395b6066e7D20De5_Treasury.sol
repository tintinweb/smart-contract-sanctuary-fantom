// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/Babylonian.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IBoardroom.sol";
import "./interfaces/IRegulationStats.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IUpdate.sol";
import "../../lib/AccessControlConstants.sol";
import "../../token/ERC20/extensions/IERC20Burnable.sol";
import "../../token/ERC20/extensions/IERC20Mintable.sol";

/**
 * @title Treasury
 */
contract Treasury is ContractGuard, AccessControlEnumerable, ITreasury {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Boardroom {
        uint256 alloc; // allocation out of 10000 for rewards
        uint32 category; // boardroom category
    }

    uint32 public constant BOARDROOM_CATEGORY_ERC20 = 0;
    uint32 public constant BOARDROOM_CATEGORY_ERC721 = 1;
    uint256 public constant PERIOD = 6 hours;

    bool public setupDone;
    uint256 public startTime;
    uint256 public lastEpochTime;
    uint256 public override epoch;
    uint256 private _epochLength;
    uint256 public epochSupplyContractionLeft;
    EnumerableSet.AddressSet private _excludedFromTotalSupply; // exclusions from total supply
    EnumerableSet.AddressSet private _updateHooks; // update hook contracts called on allocateSeigniorage
    EnumerableSet.AddressSet private _boardrooms; // boardroom address
    mapping(address => Boardroom) private _boardroomsInfo; // holds Boardroom struct
    uint256 boardroomsTotalAllocPoints; // total allocation points of boardrooms
    address public pegToken; // pegged token
    address public bond; // bond token
    address public oracle; // oracle
    uint256 public pegTokenPriceOne;      // pegged token price
    uint256 public pegTokenPriceCeiling;  // pegged token price ceiling
    uint256 public seigniorageSaved;    // saved pegged token in treasury
    uint256[] public supplyTiers;
    uint256[] public maxExpansionTiers;
    uint256 public maxSupplyExpansionPercent;
    uint256 public bondDepletionFloorPercent;
    uint256 public seigniorageExpansionFloorPercent;
    uint256 public maxSupplyContractionPercent;
    uint256 public maxDebtRatioPercent;
    uint256 public bootstrapEpochs; // 28 first epochs (1 week) with 4.5% expansion regardless of price
    uint256 public bootstrapSupplyExpansionPercent;
    bool public stableMaxSupplyExpansion; // use stable max supply expansion
    uint256 public override previousEpochPegTokenPrice;
    uint256 public pegTokenSupplyTarget; // alternative expansion system
    uint256 public allocateSeigniorageSalary; // payment for calling allocateSeigniorage
    uint256 public maxDiscountRate; // when purchasing bond
    uint256 public maxPremiumRate; // when redeeming bond
    uint256 public discountPercent;
    uint256 public premiumThreshold;
    uint256 public premiumPercent;
    uint256 public mintingFactorForPayingDebt; // print extra during debt phase
    address public daoFund;
    uint256 public daoFundPercent;
    address public devFund;
    uint256 public devFundPercent;
    address public regulationStats;

    event Initialized(address indexed executor, uint256 at);
    event BurnedBonds(address indexed from, uint256 bondAmount);
    event RedeemedBonds(address indexed from, uint256 pegTokenAmount, uint256 bondAmount);
    event BoughtBonds(address indexed from, uint256 pegTokenAmount, uint256 bondAmount);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event FundingAdded(uint256 indexed epoch, uint256 timestamp, uint256 price, uint256 expanded, uint256 boardroomFund, uint256 daoFund, uint256 devFund);
    event ErrorString(string reason);
    event ErrorPanic(uint reason);
    event ErrorBytes(bytes reason);

    error AlreadySetup();           // 0x77358691
    error DoesNotExist();           // 0xb0ce7591
    error Exist();                  // 0x65956805
    error FailedToGetPrice();       // 0x3428a74c
    error IndexTooHigh();           // 0xfbf22ac0
    error IndexTooLow();            // 0x9d445a78
    error InvalidBondRate();        // 0x1e81f45c
    error NeedMinterPermission();   // 0xd6f32c78
    error NeedOperatorPermission(); // 0x62c880f4
    error NotEnoughBonds();         // 0xd53d422f
    error NotOpened();              // 0x6d36408a
    error NotOperator();            // 0x7c214f04
    error NotStarted();             // 0x6f312cbd
    error OutOfRange();             // 0x7db3aba7
    error OverMaxDebtRatio();       // 0x12cb9a0a
    error PriceMoved();             // 0x38aa5c15
    error PriceNotEligible();       // 0x91722c5f
    error TooHigh();                // 0xf2034b4e
    error TooLow();                 // 0x3ca55442
    error TreasuryHasNoBudget();    // 0x72560f29
    error ZeroAddress();            // 0xd92e233d
    error ZeroAmount();             // 0x1f2a2005

    modifier onlyOperator {
        if(!AccessControl.hasRole(AccessControlConstants.OPERATOR_ROLE, msg.sender)) revert NotOperator();
        _;
    }
    
    modifier checkCondition {
        if(block.timestamp < startTime) revert NotStarted();
        _;
    }

    modifier checkEpoch {
        uint256 nextEpochPoint_ = nextEpochPoint();
        if(block.timestamp < nextEpochPoint_) revert NotOpened();
        _;
        lastEpochTime = nextEpochPoint_;
        epoch++;
        epochSupplyContractionLeft = (getPegTokenPrice() > pegTokenPriceCeiling) ? 0 : (getPegTokenCirculatingSupply() * maxSupplyContractionPercent) / 10000;
    }

    modifier notSetup {
        if(setupDone) revert AlreadySetup();
        _;
    }

    constructor() {
        AccessControl._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControl._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
    }

    function setup(address pegToken_, address bond_, address oracle_, address boardroom_, address nftBoardroom_, uint256 startTime_, uint256 startEpoch_) external notSetup onlyOperator {
        pegToken = pegToken_;
        bond = bond_;
        oracle = oracle_;
        _boardrooms.add(boardroom_);
        _boardroomsInfo[boardroom_].alloc = 5000;    // 50%
        _boardrooms.add(nftBoardroom_);
        _boardroomsInfo[nftBoardroom_].alloc = 5000;
        _boardroomsInfo[nftBoardroom_].category = BOARDROOM_CATEGORY_ERC721;
        boardroomsTotalAllocPoints = 10000;
        startTime = startTime_;
        epoch = startEpoch_;
        _epochLength = PERIOD;
        lastEpochTime = startTime_ - PERIOD;

        pegTokenPriceOne = 10**18;
        pegTokenPriceCeiling = (pegTokenPriceOne * 101) / 100;

        // Tier max expansion percent
        supplyTiers = [0 ether, 500000 ether, 1000000 ether, 1500000 ether, 2000000 ether, 5000000 ether, 10000000 ether, 20000000 ether, 50000000 ether];
        maxExpansionTiers = [450, 400, 350, 300, 250, 200, 150, 125, 100];
        pegTokenSupplyTarget = 1000000 ether; // alternative expansion system. Supply is the next target to reduce expansion rate

        maxSupplyExpansionPercent = 400; // Upto 4.0% supply for expansion

        bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor
        seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for boardroom
        maxSupplyContractionPercent = 300; // Upto 3.0% supply for contraction (to burn token and mint bond)
        maxDebtRatioPercent = 3500; // Upto 35% supply of bond to purchase

        maxDiscountRate = 13e17; // 30% - when purchasing bond
        maxPremiumRate = 13e17; // 30% - when redeeming bond

        premiumThreshold = 110;
        premiumPercent = 7000; // 70% premium

        // First 28 epochs with 4.5% expansion
        bootstrapEpochs = 28;
        bootstrapSupplyExpansionPercent = 450;

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20(pegToken).balanceOf(address(this));

        // incentive to allocate seigniorage
        allocateSeigniorageSalary = 0.2 ether;

        setupDone = true;
        emit Initialized(msg.sender, block.number);
    }

    /** ================================================================================================================
     * @notice Epoch
     * ============================================================================================================== */

    function nextEpochPoint() public view override returns (uint256) {
        return lastEpochTime + _epochLength;
    }

    function setEpochLength(uint256 epochLength_) external onlyOperator {
        _epochLength = epochLength_;
    }

    /** ================================================================================================================
     * @notice Oracle
     * ============================================================================================================== */

    function setOracle(address oracle_) external onlyOperator {
        oracle = oracle_;
    }

    function getPegTokenPrice() public view override returns (uint256 price) {
        price = 0;
        try IOracle(oracle).consult(pegToken, 1e18) returns (uint144 price_) {
            return uint256(price_);
        } catch {
            revert FailedToGetPrice();
        }
    }

    function getPegTokenPriceUpdated() public view override returns (uint256 price) {
        price = 0;
        try IOracle(oracle).twap(pegToken, 1e18) returns (uint144 price_) {
            return uint256(price_);
        } catch {
            revert FailedToGetPrice();
        }
    }

    /**
     * @notice Oracle may revert if there is a math error or operator is not set to Treasury
     * If there is an issue with the oracle contract, then it can be changed
     */
    function _updatePegTokenPrice() internal {
        try IOracle(oracle).update() {
        } catch Error(string memory reason) {
            emit ErrorString(reason);
        } catch Panic(uint reason) {
            emit ErrorPanic(reason);
        } catch (bytes memory reason) {
            emit ErrorBytes(reason);
        }
    }

    /** ================================================================================================================
     * @notice RegulationStats
     * Sets the regulation stats that keeps track of data
     * ============================================================================================================== */

    function setRegulationStats(address regulationStats_) external onlyOperator {
        regulationStats = regulationStats_;
    }

    /** ================================================================================================================
     * @notice Funds
     * ============================================================================================================== */

    /**
     * @notice Budget
     */
    function getReserve() public view returns (uint256) {
        return seigniorageSaved;
    }

    function setExtraFunds(address daoFund_, uint256 daoFundPercent_, address devFund_, uint256 devFundPercent_) external onlyOperator {
        if(daoFund_ == address(0)) revert ZeroAddress();
        if(daoFundPercent_ > 3000) revert OutOfRange(); // <= 30%
        if(devFund_ == address(0)) revert ZeroAddress();
        if(devFundPercent_ > 3000) revert OutOfRange(); // <= 30%
        daoFund = daoFund_;
        daoFundPercent = daoFundPercent_;
        devFund = devFund_;
        devFundPercent = devFundPercent_;
    }

    function setAllocateSeigniorageSalary(uint256 allocateSeigniorageSalary_) external onlyOperator {
        if(allocateSeigniorageSalary_ > 10 ether) revert TooHigh();
        allocateSeigniorageSalary = allocateSeigniorageSalary_;
    }

    /** ================================================================================================================
     * @notice Boardrooms
     * ============================================================================================================== */

    function getBoardrooms() external view returns (address[] memory) {
        return _boardrooms.values();
    }

    function getBoardroomInfo(address boardroom_) external view returns (uint256 alloc_, uint32 category_) {
        Boardroom memory room = _boardroomsInfo[boardroom_];
        alloc_ = room.alloc;
        category_ = room.category;
    }

    function addBoardroom(address boardroom_, uint256 alloc_, uint32 category_) external onlyOperator {
        if(_boardrooms.contains(boardroom_)) revert Exist();
        _boardrooms.add(boardroom_);
        Boardroom memory room;
        room.alloc = alloc_;
        room.category = category_;
        _boardroomsInfo[boardroom_] = room;
        boardroomsTotalAllocPoints += alloc_;
    }

    function removeBoardroom(address boardroom_) external onlyOperator {
        if(!_boardrooms.contains(boardroom_)) revert DoesNotExist();
        boardroomsTotalAllocPoints -= _boardroomsInfo[boardroom_].alloc;
        delete _boardroomsInfo[boardroom_].alloc;
        delete _boardroomsInfo[boardroom_].category;
        _boardrooms.remove(boardroom_);
    }

    function setBoardroom(address boardroom_, uint256 alloc_) external onlyOperator {
        if(!_boardrooms.contains(boardroom_)) revert DoesNotExist();
        boardroomsTotalAllocPoints = (boardroomsTotalAllocPoints - _boardroomsInfo[boardroom_].alloc) + alloc_;
        Boardroom memory room;
        room.alloc = alloc_;
        room.category = _boardroomsInfo[boardroom_].category;
        _boardroomsInfo[boardroom_] = room;
    }

    /**
     * @notice Send to each boardroom
     */
    function _sendToBoardroom(uint256 amount_, uint256 expanded_) internal {
        IERC20Mintable(pegToken).mint(address(this), amount_);

        uint256 daoFundAmount_;
        if(daoFundPercent > 0) {
            daoFundAmount_ = (amount_ * daoFundPercent) / 10000;
            IERC20(pegToken).safeTransfer(daoFund, daoFundAmount_);
        }

        uint256 devFundAmount_;
        if(devFundPercent > 0) {
            devFundAmount_ = (amount_ * devFundPercent) / 10000;
            IERC20(pegToken).safeTransfer(devFund, devFundAmount_);
        }

        amount_ -= (daoFundAmount_ + devFundAmount_);

        uint256 amountAdded;
        uint256 amountSendToBoardroom = amount_;
        for(uint256 i; i < _boardrooms.length(); i++) {
            address room = _boardrooms.at(i);
            uint256 amt = (amount_ * _boardroomsInfo[room].alloc) / boardroomsTotalAllocPoints;
            if(amountAdded + amt > amount_) amt = amount_ - amountAdded;
            amountAdded += amt;

            if(amt > 0) {
                if(IBoardroom(room).totalShare() > 0) {
                    IERC20(pegToken).safeIncreaseAllowance(room, amt);
                    IBoardroom(room).allocateSeigniorage(amt);
                } else {
                    // if none is staked then send to devFund
                    devFundAmount_ += amt;
                    IERC20(pegToken).safeTransfer(devFund, amt);
                    amountSendToBoardroom -= amt;
                }
            }
        }
        if (regulationStats != address(0)) IRegulationStats(regulationStats).addEpochInfo(epoch + 1, previousEpochPegTokenPrice, expanded_, amountSendToBoardroom, daoFundAmount_, devFundAmount_);
        emit FundingAdded(epoch + 1, block.timestamp, previousEpochPegTokenPrice, expanded_, amountSendToBoardroom, daoFundAmount_, devFundAmount_);
    }

    /** ================================================================================================================
     * @notice Hook contracts called on each allocation
     * ============================================================================================================== */

    function getUpdateHooks() external view returns (address[] memory) {
        return _updateHooks.values();
    }

    function _callUpdateHooks() internal {
        for(uint256 i; i < _updateHooks.length(); i++) {
            try IUpdate(_updateHooks.at(i)).update() {
            } catch Error(string memory reason) {
                emit ErrorString(reason);
            } catch Panic(uint reason) {
                emit ErrorPanic(reason);
            } catch (bytes memory reason) {
                emit ErrorBytes(reason);
            }
        }
    }

    function addUpdateHook(address hook_) external onlyOperator {
        if(_updateHooks.contains(hook_)) revert Exist();
        _updateHooks.add(hook_);
    }

    function removeUpdateHook(address hook_) external onlyOperator {
        if(!_updateHooks.contains(hook_)) revert DoesNotExist();
        _updateHooks.remove(hook_);
    }

    /** ================================================================================================================
     * @notice Bonds
     * ============================================================================================================== */

    /**
     * @notice Burnable pegToken left
     */
    function getBurnableTokenLeft() public view returns (uint256 burnablePegTokenLeft_) {
        uint256 pegTokenPrice_ = getPegTokenPrice();
        if(pegTokenPrice_ <= pegTokenPriceOne) {
            uint256 pegTokenSupply_ = getPegTokenCirculatingSupply();
            uint256 bondMaxSupply_ = (pegTokenSupply_ * maxDebtRatioPercent) / 10000;
            uint256 bondSupply_ = IERC20(bond).totalSupply();
            if(bondMaxSupply_ > bondSupply_) {
                uint256 maxMintableBond_ = bondMaxSupply_ - bondSupply_;
                // added to show consistent calculation as redeemBonds()
                uint256 rate_ = getBondDiscountRate();
                if(rate_ > 0) {
                    uint256 maxBurnableToken_ = (maxMintableBond_ * 1e18) / rate_;
                    burnablePegTokenLeft_ = Math.min(epochSupplyContractionLeft, maxBurnableToken_);
                }
            }
        }
        return burnablePegTokenLeft_;
    }

    function getRedeemableBonds() public view returns (uint256 redeemableBonds_) {
        uint256 pegTokenPrice_ = getPegTokenPrice();
        if(pegTokenPrice_ > pegTokenPriceCeiling) {
            uint256 totalPegToken_ = IERC20(pegToken).balanceOf(address(this));
            uint256 rate_ = getBondPremiumRate();
            if(rate_ > 0) {
                redeemableBonds_ = (totalPegToken_ * 1e18) / rate_;
            }
        }
        return redeemableBonds_;
    }

    function getBondDiscountRate() public view override returns (uint256 rate_) {
        uint256 pegTokenPrice_ = getPegTokenPrice();
        if(pegTokenPrice_ <= pegTokenPriceOne) {
            if(discountPercent == 0) {
                // no discount
                rate_ = pegTokenPriceOne;
            } else {
                uint256 bondAmount_ = (pegTokenPriceOne * 1e18) / pegTokenPrice_; // to burn 1 pegToken
                uint256 discountAmount_ = ((bondAmount_ - pegTokenPriceOne) * discountPercent) / 10000;
                rate_ = pegTokenPriceOne + discountAmount_;
                if(maxDiscountRate > 0 && rate_ > maxDiscountRate) {
                    rate_ = maxDiscountRate;
                }
            }
        }
        return rate_;
    }

    function getBondPremiumRate() public view override returns (uint256 rate_) {
        uint256 pegTokenPrice_ = getPegTokenPrice();
        if(pegTokenPrice_ > pegTokenPriceCeiling) {
            uint256 pricePremiumThreshold_ = (pegTokenPriceOne * premiumThreshold) / 100;
            if(pegTokenPrice_ >= pricePremiumThreshold_) {
                // price > 1.10
                uint256 premiumAmount_ = ((pegTokenPrice_ - pegTokenPriceOne) * premiumPercent) / 10000;
                rate_ = pegTokenPriceOne + premiumAmount_;
                if (maxPremiumRate > 0 && rate_ > maxPremiumRate) {
                    rate_ = maxPremiumRate;
                }
            } else {
                // no premium bonus
                rate_ = pegTokenPriceOne;
            }
        }
        return rate_;
    }

    function setBondDepletionFloorPercent(uint256 bondDepletionFloorPercent_) external onlyOperator {
        if(bondDepletionFloorPercent_ < 500 || bondDepletionFloorPercent_ > 10000) revert OutOfRange(); // [5%, 100%]
        bondDepletionFloorPercent = bondDepletionFloorPercent_;
    }

    function buyBonds(uint256 pegTokenAmount_, uint256 targetPrice) external override onlyOneBlock checkCondition {
        if(pegTokenAmount_ == 0) revert ZeroAmount(); // cannot purchase bonds with zero amount

        uint256 pegTokenPrice = getPegTokenPrice();
        if(pegTokenPrice != targetPrice) revert PriceMoved();
        if(pegTokenPrice >= pegTokenPriceOne) revert PriceNotEligible(); // price < $1 required otherwise not eligible for bond purchase
        if(pegTokenAmount_ > epochSupplyContractionLeft) revert NotEnoughBonds(); // not enough bond left to purchase

        uint256 rate_ = getBondDiscountRate();
        if(rate_ == 0) revert InvalidBondRate();

        uint256 bondAmount_ = (pegTokenAmount_ * rate_) / 1e18;
        uint256 pegTokenSupply = getPegTokenCirculatingSupply();
        uint256 newBondSupply = IERC20(bond).totalSupply() + bondAmount_;
        if(newBondSupply > (pegTokenSupply * maxDebtRatioPercent) / 10000) revert OverMaxDebtRatio();

        IERC20Burnable(pegToken).burnFrom(msg.sender, pegTokenAmount_);
        IERC20Mintable(bond).mint(msg.sender, bondAmount_);

        epochSupplyContractionLeft -= pegTokenAmount_;
        _updatePegTokenPrice();

        emit BoughtBonds(msg.sender, pegTokenAmount_, bondAmount_);
    }

    function redeemBonds(uint256 bondAmount_, uint256 targetPrice) external override onlyOneBlock checkCondition {
        if(bondAmount_ == 0) revert ZeroAmount(); // cannot redeem bonds with zero amount

        uint256 pegTokenPrice = getPegTokenPrice();
        if(pegTokenPrice != targetPrice) revert PriceMoved();
        if(pegTokenPrice <= pegTokenPriceCeiling) revert PriceNotEligible(); // price > $1.01 otherwise not eligible for bond purchase

        uint256 rate_ = getBondPremiumRate();
        if(rate_ == 0) revert InvalidBondRate();

        uint256 pegTokenAmount_ = (bondAmount_ * rate_) / 1e18;
        if(IERC20(pegToken).balanceOf(address(this)) < pegTokenAmount_) revert TreasuryHasNoBudget();

        seigniorageSaved -= Math.min(seigniorageSaved, pegTokenAmount_);

        IERC20Burnable(bond).burnFrom(msg.sender, bondAmount_);
        IERC20(pegToken).safeTransfer(msg.sender, pegTokenAmount_);

        _updatePegTokenPrice();

        emit RedeemedBonds(msg.sender, pegTokenAmount_, bondAmount_);
    }

    /** ================================================================================================================
     * @notice Expansion
     * ============================================================================================================== */

    function getExcludeFromTotalSupply() external view returns (address[] memory) {
        return _excludedFromTotalSupply.values();
    }

    function excludeFromTotalSupply(address exclude_) external onlyOperator {
        if(_excludedFromTotalSupply.contains(exclude_)) revert();
        _excludedFromTotalSupply.add(exclude_);
    }

    function includeFromTotalSupply(address include_) external onlyOperator {
        if(!_excludedFromTotalSupply.contains(include_)) revert();
        _excludedFromTotalSupply.remove(include_);
    }

    function getPegTokenCirculatingSupply() public view override returns (uint256) {
        IERC20 pegTokenErc20 = IERC20(pegToken);
        uint256 totalSupply = pegTokenErc20.totalSupply();
        uint256 balanceExcluded;
        for(uint256 entryId; entryId < _excludedFromTotalSupply.length(); entryId++) {
            balanceExcluded += pegTokenErc20.balanceOf(_excludedFromTotalSupply.at(entryId));
        }
        return totalSupply - balanceExcluded;
    }

    function getPegTokenExcludedSupply() public view override returns (uint256) {
        IERC20 pegTokenErc20 = IERC20(pegToken);
        uint256 balanceExcluded;
        for(uint256 entryId; entryId < _excludedFromTotalSupply.length(); entryId++) {
            balanceExcluded += pegTokenErc20.balanceOf(_excludedFromTotalSupply.at(entryId));
        }
        return balanceExcluded;
    }

    function setPegTokenPriceCeiling(uint256 priceCeiling_) external onlyOperator {
        if(priceCeiling_ < pegTokenPriceOne || priceCeiling_ > (pegTokenPriceOne * 120) / 100) revert OutOfRange(); // [$1.0, $1.2]
        pegTokenPriceCeiling = priceCeiling_;
    }

    /**
     * @notice Sets the max percent for expansion
     */
    function setMaxSupplyExpansionPercents(uint256 maxSupplyExpansionPercent_) external onlyOperator {
        if(maxSupplyExpansionPercent_ < 10 || maxSupplyExpansionPercent_ > 1000) revert OutOfRange(); // [0.1%, 10%]
        maxSupplyExpansionPercent = maxSupplyExpansionPercent_;
    }

    /**
     * @notice Sets the supply tiers
     */
    function setSupplyTiersEntry(uint8 index_, uint256 value_) external onlyOperator returns (bool) {
        if(index_ < 0) revert IndexTooLow();
        if(index_ >= 9) revert IndexTooHigh();
        if(index_ > 0) {
            require(value_ > supplyTiers[index_ - 1]);
        }
        if(index_ < 8) {
            require(value_ < supplyTiers[index_ + 1]);
        }
        supplyTiers[index_] = value_;
        return true;
    }

    /**
     * @notice Sets the max expansion for each supply tiers
     */
    function setMaxExpansionTiersEntry(uint8 index_, uint256 value_) external onlyOperator returns (bool) {
        if(index_ < 0) revert IndexTooLow();
        if(index_ >= 9) revert IndexTooHigh();
        if(value_ < 10 || value_ > 1000) revert OutOfRange(); // [0.1%, 10%]
        maxExpansionTiers[index_] = value_;
        return true;
    }

    /**
     * @notice Sets the bootstrap expansion regardless of price
     */
    function setBootstrap(uint256 bootstrapEpochs_, uint256 bootstrapSupplyExpansionPercent_) external onlyOperator {
        if(bootstrapEpochs_ > 120) revert OutOfRange(); // <= 1 month
        if(bootstrapSupplyExpansionPercent_ < 100 || bootstrapSupplyExpansionPercent_ > 1000) revert OutOfRange(); // [1%, 10%]
        bootstrapEpochs = bootstrapEpochs_;
        bootstrapSupplyExpansionPercent = bootstrapSupplyExpansionPercent_;
    }

    /**
     * @notice Alternative expansion system
     */
    function setStableMaxSupplyExpansion(bool on_) external onlyOperator {
        stableMaxSupplyExpansion = on_;
    }

    /**
     * @notice Sets a supply target to slowly expand for alternative stable expansion system
     */
    function setPegTokenSupplyTarget(uint256 pegTokenSupplyTarget_) external onlyOperator {
        if(pegTokenSupplyTarget_ <= getPegTokenCirculatingSupply()) revert TooLow(); // > current circulating supply
        pegTokenSupplyTarget = pegTokenSupplyTarget_;
    }

    function _calculateMaxSupplyExpansionPercent(uint256 pegTokenSupply_) internal returns (uint256) {
        if(stableMaxSupplyExpansion) {
            return _calculateMaxSupplyExpansionPercentStable(pegTokenSupply_);
        } else {
            return _calculateMaxSupplyExpansionPercentTier(pegTokenSupply_);
        }
    }

    /**
     * @notice Calculate max supply expansion percent with tier system
     */
    function _calculateMaxSupplyExpansionPercentTier(uint256 pegTokenSupply_) internal returns (uint256) {
        for(uint8 tierId = 8; tierId >= 0; tierId--) {
            if(pegTokenSupply_ >= supplyTiers[tierId]) {
                maxSupplyExpansionPercent = maxExpansionTiers[tierId];
                break;
            }
        }
        return maxSupplyExpansionPercent;
    }

    /**
     * @notice Calculate max supply expansion percent with stable system
     */
    function _calculateMaxSupplyExpansionPercentStable(uint256 pegTokenSupply_) internal returns (uint256) {
        if(pegTokenSupply_ >= pegTokenSupplyTarget) {
            pegTokenSupplyTarget = (pegTokenSupplyTarget * 12500) / 10000; // +25%
            maxSupplyExpansionPercent = (maxSupplyExpansionPercent * 9500) / 10000; // -5%
            if(maxSupplyExpansionPercent < 10) {
                maxSupplyExpansionPercent = 10; // min 0.1%
            }
        }
        return maxSupplyExpansionPercent;
    }

    /**
     * @notice New function for viewing purpose
     */
    function getPegTokenExpansionRate() public view override returns (uint256 rate_) {
        if(epoch < bootstrapEpochs) {
            rate_ = bootstrapSupplyExpansionPercent;
        } else {
            uint256 twap_ = getPegTokenPrice();
            if(twap_ >= pegTokenPriceCeiling) {
                uint256 percentage_ = twap_ - pegTokenPriceOne; // 1% = 1e16
                uint256 mse_ = maxSupplyExpansionPercent * 1e14;
                if(percentage_ > mse_) {
                    percentage_ = mse_;
                }
                rate_ = percentage_ / 1e14;
            }
        }
        return rate_;
    }

    /**
     * @notice New function for viewing purpose
     */
    function getPegTokenExpansionAmount() external view override returns (uint256) {
        uint256 pegTokenSupply = getPegTokenCirculatingSupply() - seigniorageSaved;
        uint256 bondSupply = IERC20(bond).totalSupply();
        uint256 rate_ = getPegTokenExpansionRate();
        if(seigniorageSaved >= (bondSupply * bondDepletionFloorPercent) / 10000) {
            // saved enough to pay debt, mint as usual rate
            return (pegTokenSupply * rate_) / 10000;
        } else {
            // have not saved enough to pay debt, mint more
            uint256 seigniorage_ = (pegTokenSupply * rate_) / 10000;
            return (seigniorage_ * seigniorageExpansionFloorPercent) / 10000;
        }
    }

    /** ================================================================================================================
     * @notice Contraction
     * ============================================================================================================== */

    function setMaxSupplyContractionPercent(uint256 maxSupplyContractionPercent_) external onlyOperator {
        if(maxSupplyContractionPercent_ < 100 || maxSupplyContractionPercent_ > 1500) revert OutOfRange(); // [0.1%, 15%]
        maxSupplyContractionPercent = maxSupplyContractionPercent_;
    }

    function setMaxDebtRatioPercent(uint256 maxDebtRatioPercent_) external onlyOperator {
        if(maxDebtRatioPercent_ < 1000 || maxDebtRatioPercent_ > 10000) revert OutOfRange(); // [10%, 100%]
        maxDebtRatioPercent = maxDebtRatioPercent_;
    }

    function setMaxDiscountRate(uint256 maxDiscountRate_) external onlyOperator {
        maxDiscountRate = maxDiscountRate_;
    }

    function setMaxPremiumRate(uint256 maxPremiumRate_) external onlyOperator {
        maxPremiumRate = maxPremiumRate_;
    }

    function setDiscountPercent(uint256 discountPercent_) external onlyOperator {
        if(discountPercent_ > 20000) revert OutOfRange(); // <= 200%
        discountPercent = discountPercent_;
    }

    function setPremiumThreshold(uint256 premiumThreshold_) external onlyOperator {
        if(premiumThreshold_ < pegTokenPriceCeiling) revert OutOfRange(); // premiumThreshold_ must be >= priceCeiling
        if(premiumThreshold_ > 150) revert OutOfRange(); // premiumThreshold_ must be <= 150 (1.5)
        premiumThreshold = premiumThreshold_;
    }

    function setPremiumPercent(uint256 premiumPercent_) external onlyOperator {
        if(premiumPercent_ > 20000) revert OutOfRange(); // <= 200%
        premiumPercent = premiumPercent_;
    }

    function setMintingFactorForPayingDebt(uint256 mintingFactorForPayingDebt_) external onlyOperator {
        if(mintingFactorForPayingDebt_ < 10000 || mintingFactorForPayingDebt_ > 20000) revert OutOfRange(); // [100%, 200%]
        mintingFactorForPayingDebt = mintingFactorForPayingDebt_;
    }

    /**
     * @notice Allocates seigniorage
     */
    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch {
        _updatePegTokenPrice();
        _callUpdateHooks();
        previousEpochPegTokenPrice = getPegTokenPrice();
        uint256 pegTokenSupply = getPegTokenCirculatingSupply() - seigniorageSaved;
        uint256 seigniorage_;
        if(epoch < bootstrapEpochs) {
            // 28 first epochs with 4.5% expansion
            seigniorage_ = (pegTokenSupply * bootstrapSupplyExpansionPercent) / 10000;
            _sendToBoardroom(seigniorage_, seigniorage_);
        } else {
            if(previousEpochPegTokenPrice > pegTokenPriceCeiling) {
                // Expansion ($PEGTOKEN Price > 1 $PEG): there is some seigniorage to be allocated
                uint256 bondSupply = IERC20(bond).totalSupply();
                uint256 percentage_ = previousEpochPegTokenPrice - pegTokenPriceOne;
                uint256 savedForBond_;
                uint256 savedForBoardroom_;
                uint256 mse_ = _calculateMaxSupplyExpansionPercent(pegTokenSupply) * 1e14;
                if(percentage_ > mse_) {
                    percentage_ = mse_;
                }
                if(seigniorageSaved >= (bondSupply * bondDepletionFloorPercent) / 10000) {
                    // saved enough to pay debt, mint as usual rate
                    savedForBoardroom_ = (pegTokenSupply * percentage_) / 1e18;
                } else {
                    // have not saved enough to pay debt, mint more
                    seigniorage_ = (pegTokenSupply * percentage_) / 1e18;
                    savedForBoardroom_ = (seigniorage_ * seigniorageExpansionFloorPercent) / 10000;
                    savedForBond_ = seigniorage_ - savedForBoardroom_;
                    if(mintingFactorForPayingDebt > 0) {
                        savedForBond_ = (savedForBond_ * mintingFactorForPayingDebt) / 10000;
                    }
                }
                if(savedForBoardroom_ > 0) {
                    _sendToBoardroom(savedForBoardroom_, seigniorage_);
                } else {
                    if (regulationStats != address(0)) IRegulationStats(regulationStats).addEpochInfo(epoch + 1, previousEpochPegTokenPrice, 0, 0, 0, 0);
                    emit FundingAdded(epoch + 1, block.timestamp, previousEpochPegTokenPrice, 0, 0, 0, 0);
                }
                if(savedForBond_ > 0) {
                    seigniorageSaved += savedForBond_;
                    IERC20Mintable(pegToken).mint(address(this), savedForBond_);
                    emit TreasuryFunded(block.timestamp, savedForBond_);
                }
            } else if (previousEpochPegTokenPrice < pegTokenPriceOne) {
                if (regulationStats != address(0)) IRegulationStats(regulationStats).addEpochInfo(epoch + 1, previousEpochPegTokenPrice, 0, 0, 0, 0);
                emit FundingAdded(epoch + 1, block.timestamp, previousEpochPegTokenPrice, 0, 0, 0, 0);
            }
        }
        // send small amount to caller
        if(allocateSeigniorageSalary > 0) {
            IERC20Mintable(pegToken).mint(msg.sender, allocateSeigniorageSalary);
        }
    }

    /**
     * @notice If a migration is needed then all tokens need to be migrated
     */
    function transferTokens(IERC20 token_, uint256 amount_, address to_) external onlyOperator {
        token_.safeTransfer(to_, amount_);
    }

    /**
     * @notice Manually send some amount to a boardroom
     */
    function boardroomAllocateSeigniorage(address boardroom_, uint256 amount_) external onlyOperator {
        IERC20(pegToken).safeIncreaseAllowance(boardroom_, amount_);
        IBoardroom(boardroom_).allocateSeigniorage(amount_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Mintable {
    function mint(address, uint256) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Burnable {
    function burn(uint256) external;
    function burnFrom(address, uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    error OneBlockOneFunction(); // 0x0e3b65cb

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        if(checkSameOriginReentranted() || checkSameSenderReentranted()) revert OneBlockOneFunction();
        _;
        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        z = 0;
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

pragma solidity ^0.8.0;

interface IUpdate {
    function update() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITreasury {
    function epoch() external view returns (uint256);
    function nextEpochPoint() external view returns (uint256);
    function getPegTokenPrice() external view returns (uint256);
    function getPegTokenPriceUpdated() external view returns (uint256);
    function getPegTokenCirculatingSupply() external view returns (uint256);
    function getPegTokenExcludedSupply() external view returns (uint256);
    function getPegTokenExpansionRate() external view returns (uint256);
    function getPegTokenExpansionAmount() external view returns (uint256);
    function previousEpochPegTokenPrice() external view returns (uint256);
    function getBondDiscountRate() external view returns (uint256);
    function getBondPremiumRate() external view returns (uint256);
    function buyBonds(uint256 amount, uint256 targetPrice) external;
    function redeemBonds(uint256 amount, uint256 targetPrice) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IRegulationStats {
    function addEpochInfo(
        uint256 epochNumber,
        uint256 twap,
        uint256 expanded,
        uint256 boardroomFunding,
        uint256 daoFunding,
        uint256 devFunding
    ) external;

    function addBonded(uint256 epochNumber, uint256 added) external;

    function addRedeemed(uint256 epochNumber, uint256 added) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
    function update() external;
    function consult(address token, uint256 amountIn) external view returns (uint144 amountOut);
    function twap(address token, uint256 amountIn) external view returns (uint144 amountOut);
    function getPegPrice() external view returns (uint256 amountOut);
    function getPegPriceUpdated() external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBoardroom {
    function allocateSeigniorage(uint256 amount) external;
    function totalShare() external returns (uint256 supply);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AccessControlConstants {
    /**
     * Access Control Roles
     */
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR"); // 523a704056dcd17bcf83bed8b68c59416dac1119be77755efe3bde0a64e46e0c
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");     // f0887ba65ee2024ea881d91b74c2450ef19e1557f03bed3ea9f16b037cbe2dc9
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");       // df8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW"); // 7a8dc26796a1e50e6e190b70259f58f6a4edd5b22280ceecc82b687b8e982869
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
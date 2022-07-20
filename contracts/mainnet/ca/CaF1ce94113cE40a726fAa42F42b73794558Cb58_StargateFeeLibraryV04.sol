// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IStargateFeeLibrary.sol";
import "./Pool.sol";
import "./Factory.sol";
import "./IStargateLPStaking.sol";
import "./AggregatorV3Interface.sol";

import "./SafeMath.sol";
import "./IERC20.sol";

contract StargateFeeLibraryV04 is IStargateFeeLibrary, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    //---------------------------------------------------------------------------
    // VARIABLES

    // equilibrium func params. all in BPs * 10 ^ 2, i.e. 1 % = 10 ^ 6 units
    uint256 public constant DENOMINATOR = 1e18;
    uint256 public constant DELTA_1 = 6000 * 1e14;
    uint256 public constant DELTA_2 = 500 * 1e14;
    uint256 public constant LAMBDA_1 = 40 * 1e14;
    uint256 public constant LAMBDA_2 = 9960 * 1e14;
    uint256 public constant LP_FEE = 10 * 1e13;
    uint256 public constant PROTOCOL_FEE = 50 * 1e13;
    uint256 public constant PROTOCOL_SUBSIDY = 3 * 1e13;

    uint256 public constant FIFTY_PERCENT = 5 * 1e17;
    uint256 public constant SIXTY_PERCENT = 6 * 1e17;

    int256 public depegThreshold; // threshold for considering an asset depegged

    mapping(address => bool) public whitelist;
    mapping(uint256 => uint256) public poolIdToLpId; // poolId -> index of the pool in the lpStaking contract
    mapping(uint256 => address) public poolIdToPriceFeed; // maps the poolId to Chainlink priceFeedAddress

    Factory public immutable factory;
    IStargateLPStaking public immutable lpStaking;

    modifier notDepegged(uint256 _srcPoolId, uint256 _dstPoolId) {
        address priceFeedAddress = poolIdToPriceFeed[_srcPoolId];
        if (_srcPoolId != _dstPoolId && priceFeedAddress != address(0x0)) {
            (, int256 price, , , ) = AggregatorV3Interface(priceFeedAddress).latestRoundData();
            require(price >= depegThreshold, "FeeLibrary: _srcPoolId is depegged");
        }
        _;
    }

    constructor(
        address _factory,
        address _lpStakingContract,
        int256 _depegThreshold
    ) {
        require(_factory != address(0x0), "FeeLibrary: Factory cannot be 0x0");
        require(_lpStakingContract != address(0x0), "FeeLibrary: LPStaking cannot be 0x0");
        require(_depegThreshold > 0, "FeeLibrary: _depegThreshold must be > 0");

        factory = Factory(_factory);
        lpStaking = IStargateLPStaking(_lpStakingContract);
        depegThreshold = _depegThreshold;
    }

    function whiteList(address _from, bool _whiteListed) public onlyOwner {
        whitelist[_from] = _whiteListed;
    }

    function setPoolToLpId(uint256 _poolId, uint256 _lpId) public onlyOwner {
        poolIdToLpId[_poolId] = _lpId;
    }

    function setPoolIdToPriceFeedAddress(uint256 _poolId, address _priceFeedAddress) public onlyOwner {
        poolIdToPriceFeed[_poolId] = _priceFeedAddress;
    }

    function setDepegThreshold(int256 _depegThreshold) public onlyOwner {
        require(_depegThreshold > 0, "FeeLibrary: _depegThreshold must be > 0");
        depegThreshold = _depegThreshold;
    }

    function getFees(
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        uint16 _dstChainId,
        address _from,
        uint256 _amountSD
    ) external view override notDepegged(_srcPoolId, _dstPoolId) returns (Pool.SwapObj memory s) {
        uint256 srcPoolId = _srcPoolId; // stack too deep

        Pool pool = factory.getPool(srcPoolId);
        Pool.ChainPath memory chainPath = pool.getChainPath(_dstChainId, _dstPoolId);
        address tokenAddress = pool.token();
        uint256 currentAssetSD = IERC20(tokenAddress).balanceOf(address(pool)).div(pool.convertRate());
        uint256 lpAsset = pool.totalLiquidity();

        // calculate the equilibrium reward
        s.eqReward = _getEqReward(_amountSD, currentAssetSD, lpAsset, pool.eqFeePool());

        // calculate the equilibrium fee
        uint256 protocolSubsidy;
        (s.eqFee, protocolSubsidy) = _getEquilibriumFee(chainPath.idealBalance, chainPath.balance, _amountSD);

        // return no protocol/lp fees for addresses in this mapping
        if (whitelist[_from]) {
            return s;
        }

        // calculate protocol and lp fee
        (s.protocolFee, s.lpFee) = _getProtocolAndLpFee(_amountSD, currentAssetSD, lpAsset, protocolSubsidy, srcPoolId, chainPath);

        return s;
    }

    function getEqReward(
        uint256 _amountSD,
        uint256 _currentAssetSD,
        uint256 _lpAsset,
        uint256 _rewardPoolSize
    ) external pure returns (uint256 eqReward) {
        return _getEqReward(_amountSD, _currentAssetSD, _lpAsset, _rewardPoolSize);
    }

    function getEquilibriumFee(
        uint256 idealBalance,
        uint256 beforeBalance,
        uint256 amountSD
    ) external pure returns (uint256, uint256) {
        return _getEquilibriumFee(idealBalance, beforeBalance, amountSD);
    }

    function getProtocolAndLpFee(
        uint256 _amountSD,
        uint256 _currentAssetSD,
        uint256 _lpAsset,
        uint256 _protocolSubsidy,
        uint256 _srcPoolId,
        Pool.ChainPath memory _chainPath
    ) external view returns (uint256 protocolFee, uint256 lpFee) {
        return _getProtocolAndLpFee(_amountSD, _currentAssetSD, _lpAsset, _protocolSubsidy, _srcPoolId, _chainPath);
    }

    function getTrapezoidArea(
        uint256 lambda,
        uint256 yOffset,
        uint256 xUpperBound,
        uint256 xLowerBound,
        uint256 xStart,
        uint256 xEnd
    ) external pure returns (uint256) {
        return _getTrapezoidArea(lambda, yOffset, xUpperBound, xLowerBound, xStart, xEnd);
    }

    function _getEqReward(
        uint256 _amountSD,
        uint256 _currentAssetSD,
        uint256 _lpAsset,
        uint256 _rewardPoolSize
    ) internal pure returns (uint256 eqReward) {
        if (_lpAsset <= _currentAssetSD) {
            return 0;
        }

        uint256 poolDeficit = _lpAsset.sub(_currentAssetSD);
        // assets in pool are < 75% of liquidity provided & amount transferred > 2% of pool deficit
        if (_currentAssetSD.mul(100).div(_lpAsset) < 75 && _amountSD.mul(100) > poolDeficit.mul(2)) {
            // reward capped at rewardPoolSize
            eqReward = _rewardPoolSize.mul(_amountSD).div(poolDeficit);
            if (eqReward > _rewardPoolSize) {
                eqReward = _rewardPoolSize;
            }
        } else {
            eqReward = 0;
        }
    }

    function _getEquilibriumFee(
        uint256 idealBalance,
        uint256 beforeBalance,
        uint256 amountSD
    ) internal pure returns (uint256, uint256) {
        require(beforeBalance >= amountSD, "Stargate: not enough balance");
        uint256 afterBalance = beforeBalance.sub(amountSD);

        uint256 safeZoneMax = idealBalance.mul(DELTA_1).div(DENOMINATOR);
        uint256 safeZoneMin = idealBalance.mul(DELTA_2).div(DENOMINATOR);

        uint256 eqFee = 0;
        uint256 protocolSubsidy = 0;

        if (afterBalance >= safeZoneMax) {
            // no fee zone, protocol subsidize it.
            eqFee = amountSD.mul(PROTOCOL_SUBSIDY).div(DENOMINATOR);
            protocolSubsidy = eqFee;
        } else if (afterBalance >= safeZoneMin) {
            // safe zone
            uint256 proxyBeforeBalance = beforeBalance < safeZoneMax ? beforeBalance : safeZoneMax;
            eqFee = _getTrapezoidArea(LAMBDA_1, 0, safeZoneMax, safeZoneMin, proxyBeforeBalance, afterBalance);
        } else {
            // danger zone
            if (beforeBalance >= safeZoneMin) {
                // across 2 or 3 zones
                // part 1
                uint256 proxyBeforeBalance = beforeBalance < safeZoneMax ? beforeBalance : safeZoneMax;
                eqFee = eqFee.add(_getTrapezoidArea(LAMBDA_1, 0, safeZoneMax, safeZoneMin, proxyBeforeBalance, safeZoneMin));
                // part 2
                eqFee = eqFee.add(_getTrapezoidArea(LAMBDA_2, LAMBDA_1, safeZoneMin, 0, safeZoneMin, afterBalance));
            } else {
                // only in danger zone
                // part 2 only
                eqFee = eqFee.add(_getTrapezoidArea(LAMBDA_2, LAMBDA_1, safeZoneMin, 0, beforeBalance, afterBalance));
            }
        }
        return (eqFee, protocolSubsidy);
    }

    function _getProtocolAndLpFee(
        uint256 _amountSD,
        uint256 _currentAssetSD,
        uint256 _lpAsset,
        uint256 _protocolSubsidy,
        uint256 _srcPoolId,
        Pool.ChainPath memory _chainPath
    ) internal view returns (uint256 protocolFee, uint256 lpFee) {
        protocolFee = _amountSD.mul(PROTOCOL_FEE).div(DENOMINATOR).sub(_protocolSubsidy);
        lpFee = _amountSD.mul(LP_FEE).div(DENOMINATOR);

        // when there are active emissions, give the lp fee to the protocol
        (, uint256 allocPoint, , ) = lpStaking.poolInfo(poolIdToLpId[_srcPoolId]);
        if (allocPoint > 0) {
            protocolFee = protocolFee.add(lpFee);
            lpFee = 0;
        }

        if (_lpAsset == 0) {
            return (protocolFee, lpFee);
        }

        bool isAboveIdeal = _chainPath.balance.sub(_amountSD) > _chainPath.idealBalance.mul(SIXTY_PERCENT).div(DENOMINATOR);
        uint256 currentAssetNumerated = _currentAssetSD.mul(DENOMINATOR).div(_lpAsset);
        if (currentAssetNumerated <= FIFTY_PERCENT && isAboveIdeal) {
            // x <= 50% => no fees
            protocolFee = 0;
            lpFee = 0;
        } else if ( currentAssetNumerated < SIXTY_PERCENT && isAboveIdeal) {
            // 50% > x < 60% => scaled fees &&
            // the resulting transfer does not drain the pathway below 60% o`f the ideal balance,

            // reduce the protocol and lp fee linearly
            // Examples:
            // currentAsset == 101, lpAsset == 200 -> haircut == 5%
            // currentAsset == 115, lpAsset == 200 -> haircut == 75%
            // currentAsset == 119, lpAsset == 200 -> haircut == 95%
            uint256 haircut = currentAssetNumerated.sub(FIFTY_PERCENT).mul(10); // scale the percentage by 10
            protocolFee = protocolFee.mul(haircut).div(DENOMINATOR);
            lpFee = lpFee.mul(haircut).div(DENOMINATOR);
        }

        // x > 60% => full fees
    }

    function _getTrapezoidArea(
        uint256 lambda,
        uint256 yOffset,
        uint256 xUpperBound,
        uint256 xLowerBound,
        uint256 xStart,
        uint256 xEnd
    ) internal pure returns (uint256) {
        require(xEnd >= xLowerBound && xStart <= xUpperBound, "Stargate: balance out of bound");
        uint256 xBoundWidth = xUpperBound.sub(xLowerBound);

        // xStartDrift = xUpperBound.sub(xStart);
        uint256 yStart = xUpperBound.sub(xStart).mul(lambda).div(xBoundWidth).add(yOffset);

        // xEndDrift = xUpperBound.sub(xEnd)
        uint256 yEnd = xUpperBound.sub(xEnd).mul(lambda).div(xBoundWidth).add(yOffset);

        // compute the area
        uint256 deltaX = xStart.sub(xEnd);
        return yStart.add(yEnd).mul(deltaX).div(2).div(DENOMINATOR);
    }

    function getVersion() external pure override returns (string memory) {
        return "4.0.0";
    }

    // Override the renounce ownership inherited by zeppelin ownable
    function renounceOwnership() public override onlyOwner {}
}
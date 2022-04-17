pragma solidity ^0.8.12;

interface IERC20ForBoostedFarmLens {
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function decimals() external view returns (uint);
}

interface IGaugeForBoostedFarmLens {
    function TOKEN() external view returns (address);
    function rewardRate() external view returns (uint); // reward per second
    function totalSupply() external view returns (uint);
    function derivedSupply() external view returns (uint);
    function derivedBalances(address account) external view returns (uint);
    function balanceOf(address account) external view returns (uint);
}


interface IPairForBoostedFarmLens {
    function totalSupply() external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IBoosterForBoostedFarmLens {
    function TOKEN() external view returns (address);
    function SPIRIT() external view returns (address);
    function GAUGE() external view returns (address);

    function rewardPerTokenCurrent() external view returns (uint);
    function rewardPerTokenStored() external view returns (uint);
    function totalSupply() external view returns (uint);
    function getBoostFactor() external view returns (uint);
    function totalReward() external view returns (uint);
    function rewardDelta() external view returns (uint);
    function rewardDistributed() external view returns (uint);
    
    function userRewardPerTokenPaid(address farmer) external view returns (uint);
    function balanceOf(address farmer) external view returns (uint);
    function earnedCurrent(address farmer) external view returns (uint);
    function earnedCurrentMinusFee(address account) external view returns (uint);
    function rewards(address farmer) external view returns (uint);
}

contract BoostedFarmLens {
    uint256 public constant secondsPerYear = 31536000;

    /**
     * Returns the unchanging configs of the booster.
     */
    function viewBoostedFarmConfigs(IBoosterForBoostedFarmLens booster) external view returns (BoostedFarmConfigsView memory) {
        return viewBoosterConfigsInternal(booster);
    }

    /**
     * Returns the stored state of the booster
     */
    function viewBoostedFarmStoredState(IBoosterForBoostedFarmLens booster) external view returns (BoostedFarmStateView memory) {
        return viewBoosterStateInternal(booster, false);
    }

    /**
     * Returns the current state of the booster
     */
    function viewBoostedFarmCurrentState(IBoosterForBoostedFarmLens booster) external view returns (BoostedFarmStateView memory) {
        return viewBoosterStateInternal(booster, true);
    }

    /**
     * Returns the stored (as existed in the last time the farmer interacted with the booster) position of the farmer in the booster.
     */
    function viewBoostedFarmerStoredState(IBoosterForBoostedFarmLens booster, address farmer) external view returns (BoostedFarmerStateView memory) {
        return viewBoosterFarmerStateInternal(booster, farmer, false);
    }

    /**
     * Returns the current position of the farmer in the booster.
     */
    function viewBoostedFarmerCurrentState(IBoosterForBoostedFarmLens booster, address farmer) external view returns (BoostedFarmerStateView memory) {
        return viewBoosterFarmerStateInternal(booster, farmer, true);
    }

    function viewBoostedFarmAPR(IBoosterForBoostedFarmLens booster) external view returns (BoostedFarmAPRView memory) {
        return viewBoostedFarmAPRInternal(IGaugeForBoostedFarmLens(booster.GAUGE()), booster);
    }


    // *************
    // Internal view objects builders
    // *************

    struct BoostedFarmConfigsView {
        address farmToken;
        address rewardToken;
    }

    /**
     * Returns the unchangeable parameters of the given booster.
     */
    function viewBoosterConfigsInternal(IBoosterForBoostedFarmLens booster) internal view returns (BoostedFarmConfigsView memory) {
        BoostedFarmConfigsView memory boosterConfigs;

        boosterConfigs.farmToken = booster.TOKEN();
        boosterConfigs.rewardToken = booster.SPIRIT();

        return boosterConfigs;
    }

    struct BoostedFarmStateView {
        uint farmIndex;
        uint totalSupply;
        uint boostFactor;
        uint totalReward;
        uint rewardDistributed;
    }

    /**
     * Returns the stored/current state of the given booster.
     */
    function viewBoosterStateInternal(IBoosterForBoostedFarmLens booster, bool current) internal view returns (BoostedFarmStateView memory) {
        BoostedFarmStateView memory boostedFarmState;

        boostedFarmState.farmIndex = current ? booster.rewardPerTokenCurrent() : booster.rewardPerTokenStored();
        boostedFarmState.totalSupply = booster.totalSupply();
        boostedFarmState.boostFactor = booster.getBoostFactor();
        boostedFarmState.totalReward = current ? booster.totalReward() + booster.rewardDelta() : booster.totalReward();
        boostedFarmState.rewardDistributed = booster.rewardDistributed();

        return boostedFarmState;
    }

    struct BoostedFarmerStateView {
        address farmer;
        uint farmerSupply;
        uint farmerIndex;
        uint farmerReward;
        uint farmerRewardMinusFee;
        uint farmAllowance;
        uint farmerFarmTokenBalance;
        uint farmerRewardTokenBalance;
    }

    /**
     * Returns the stored/current position of the given farmer in the given booster.
     */
    function viewBoosterFarmerStateInternal(IBoosterForBoostedFarmLens booster, address farmer, bool current) internal view returns (BoostedFarmerStateView memory) {
        BoostedFarmerStateView memory boosterFarmerState;

        boosterFarmerState.farmer = farmer;
        boosterFarmerState.farmerSupply = booster.balanceOf(farmer);
        boosterFarmerState.farmerIndex = booster.userRewardPerTokenPaid(farmer);
        boosterFarmerState.farmerReward = current ? booster.earnedCurrent(farmer) : booster.rewards(farmer);
        boosterFarmerState.farmerRewardMinusFee = current ? booster.earnedCurrentMinusFee(farmer) : booster.rewards(farmer);

        boosterFarmerState.farmAllowance = IERC20ForBoostedFarmLens(booster.TOKEN()).allowance(farmer, address(booster));
        boosterFarmerState.farmerFarmTokenBalance = IERC20ForBoostedFarmLens(booster.TOKEN()).balanceOf(farmer);
        boosterFarmerState.farmerRewardTokenBalance = IERC20ForBoostedFarmLens(booster.SPIRIT()).balanceOf(farmer);

        return boosterFarmerState;
    }

    struct BoostedFarmAPRView {
        uint rewardPerSecond;
        uint boosterRewardsPerYear; // in SPIRIT
        uint lpBoosterSupplyInGauge;
        uint lpTotalSupply;
        address lpToken0;
        uint lpToken0Decimals;
        address lpToken1;
        uint lpToken1Decimals;
        uint lpReserve0;
        uint lpReserve1;
    }

    function viewBoostedFarmAPRInternal(IGaugeForBoostedFarmLens gauge, IBoosterForBoostedFarmLens booster) internal view returns (BoostedFarmAPRView memory) {
        BoostedFarmAPRView memory boosterAPR;
        IPairForBoostedFarmLens pair = IPairForBoostedFarmLens(gauge.TOKEN());

        boosterAPR.rewardPerSecond = gauge.rewardRate();
        uint totalRewardsPerYear = boosterAPR.rewardPerSecond * secondsPerYear;
        uint boosterDerivedWeight = gauge.derivedBalances(address(booster));
        uint totalDerivedWeight = gauge.derivedSupply();
        // TODO: check accuracy
        boosterAPR.boosterRewardsPerYear = (boosterDerivedWeight * totalRewardsPerYear) / totalDerivedWeight;
        boosterAPR.lpBoosterSupplyInGauge = gauge.balanceOf(address(booster));

        boosterAPR.lpTotalSupply = pair.totalSupply();
        address token0 = pair.token0();
        boosterAPR.lpToken0 = token0;
        boosterAPR.lpToken0Decimals = IERC20ForBoostedFarmLens(token0).decimals();
        address token1 = pair.token1();
        boosterAPR.lpToken1 = token1;
        boosterAPR.lpToken1Decimals = IERC20ForBoostedFarmLens(token1).decimals();
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        boosterAPR.lpReserve0 = reserve0;
        boosterAPR.lpReserve1 = reserve1;

        return boosterAPR;
    }
}
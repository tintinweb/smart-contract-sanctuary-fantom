pragma solidity ^0.8.12;

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
}

interface IBooster {
    function TOKEN() external view returns (address);
    function SPIRIT() external view returns (address);

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
    function rewards(address farmer) external view returns (uint);
}

contract BoosterFarmLens {
    /**
     * Returns the unchanging configs of the booster.
     */
    function viewBoosterConfigs(IBooster booster) external view returns (BoosterConfigsView memory) {
        return viewBoosterConfigsInternal(booster);
    }

    /**
     * Returns the stored state of the booster
     */
    function viewBoosterStoredState(IBooster booster) external view returns (BoosterStateView memory) {
        return viewBoosterStateInternal(booster, false);
    }

    /**
     * Returns the current state of the booster
     */
    function viewBoosterCurrentState(IBooster booster) external view returns (BoosterStateView memory) {
        return viewBoosterStateInternal(booster, true);
    }

    /**
     * Returns the stored (as existed in the last time the farmer interacted with the booster) position of the farmer in the booster.
     */
    function viewFarmerBoosterStoredState(IBooster booster, address farmer) external view returns (BoosterFarmerStateView memory) {
        return viewBoosterFarmerStateInternal(booster, farmer, false);
    }

    /**
     * Returns the current position of the farmer in the booster.
     */
    function viewFarmerBoosterCurrentState(IBooster booster, address farmer) external view returns (BoosterFarmerStateView memory) {
        return viewBoosterFarmerStateInternal(booster, farmer, true);
    }


    // *************
    // Internal view objects builders
    // *************

    struct BoosterConfigsView {
        address token;
        address spirit;
    }

    /**
     * Returns the unchangeable parameters of the given booster.
     */
    function viewBoosterConfigsInternal(IBooster booster) internal view returns (BoosterConfigsView memory) {
        BoosterConfigsView memory boosterConfigs;

        boosterConfigs.token = booster.TOKEN();
        boosterConfigs.spirit = booster.SPIRIT();

        return boosterConfigs;
    }

    struct BoosterStateView {
        uint farmIndex;
        uint totalSupply;
        uint boostFactor;
        uint totalReward;
        uint rewardDistributed;
    }

    /**
     * Returns the stored/current state of the given booster.
     */
    function viewBoosterStateInternal(IBooster booster, bool current) internal view returns (BoosterStateView memory) {
        BoosterStateView memory BoosterState;

        BoosterState.farmIndex = current ? booster.rewardPerTokenCurrent() : booster.rewardPerTokenStored();
        BoosterState.totalSupply = booster.totalSupply();
        BoosterState.boostFactor = booster.getBoostFactor();
        BoosterState.totalReward = current ? booster.totalReward() + booster.rewardDelta() : booster.totalReward();
        BoosterState.rewardDistributed = booster.rewardDistributed();

        return BoosterState;
    }

    struct BoosterFarmerStateView {
        address farmer;
        uint farmerSupply;
        uint farmerIndex;
        uint farmerReward;
        uint farmAllowance;
        uint farmerTokenBalance;
        uint farmerSpiritBalance;
    }

    /**
     * Returns the stored/current position of the given farmer in the given booster.
     */
    function viewBoosterFarmerStateInternal(IBooster booster, address farmer, bool current) internal view returns (BoosterFarmerStateView memory) {
        BoosterFarmerStateView memory BoosterFarmerState;

        BoosterFarmerState.farmer = farmer;
        BoosterFarmerState.farmerSupply = booster.balanceOf(farmer);
        BoosterFarmerState.farmerIndex = booster.userRewardPerTokenPaid(farmer);
        BoosterFarmerState.farmerReward = current ? booster.earnedCurrent(farmer) : booster.rewards(farmer);

        BoosterFarmerState.farmAllowance = IERC20(booster.TOKEN()).allowance(farmer, address(booster));
        BoosterFarmerState.farmerTokenBalance = IERC20(booster.TOKEN()).balanceOf(farmer);
        BoosterFarmerState.farmerSpiritBalance = IERC20(booster.SPIRIT()).balanceOf(farmer);

        return BoosterFarmerState;
    }
}
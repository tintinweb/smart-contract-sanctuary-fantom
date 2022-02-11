// SPDX-License-Identifier: MIT
// inpsired by AAVE's PullRewardsIncentivesController.sol
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {IERC20} from './IERC20.sol';
import {SafeERC20} from './SafeERC20.sol';
import {BaseIncentivesController} from './BaseIncentivesController.sol';

contract GranaryIncentivesController is BaseIncentivesController {
  using SafeERC20 for IERC20;

  mapping(address => address) internal _rewardsVaults;

  event RewardsVaultUpdated(address indexed vault);
  
  constructor(address emissionManager)
    BaseIncentivesController(emissionManager)
  {}

  function getRewardsVault(address rewardToken) external view returns (address) {
    return _rewardsVaults[rewardToken];
  }

  function setRewardsVault(address rewardsVault, address rewardToken) external onlyEmissionManager {
    _rewardsVaults[rewardToken] == rewardsVault;
    emit RewardsVaultUpdated(rewardsVault);
  }

  function _transferRewards(address to, uint256 amount, address rewardToken) internal override {
    IERC20(rewardToken).safeTransferFrom(_rewardsVaults[rewardToken], to, amount);
  }
}
/**
 *Submitted for verification at FtmScan.com on 2022-08-03
*/

pragma solidity 0.8.11;

interface IERC20 {
    function balanceOf(address) external view returns (uint);
}

interface IVoter {
    function totalWeight() external view returns(uint);
}

contract VotersRewardsFormula{
  IVoter public voter;
  address public rewardsLocker;
  address public rewardToken;

  constructor(
    address _voter,
    address _rewardsLocker,
    address _rewardToken
    )
    public
  {
    voter = IVoter(_voter);
    rewardsLocker = _rewardsLocker;
    rewardToken = _rewardToken;
  }

  function computeRewards() public view returns(uint) {
    uint totalWeight = voter.totalWeight();
    uint currentRewards = IERC20(rewardToken).balanceOf(rewardsLocker);

    if(totalWeight >= currentRewards * 10){
      return currentRewards;
    }
    else{
      return 0;
    }
  }
}
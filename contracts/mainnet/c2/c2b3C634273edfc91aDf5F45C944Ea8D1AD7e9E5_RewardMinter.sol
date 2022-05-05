/**
 *Submitted for verification at FtmScan.com on 2022-05-05
*/

pragma solidity ^0.6.2;

interface IStake {
  function notifyRewardAmount(uint256 reward) external;
}

interface IMinter {
  function mint(uint _amount) external;
}

interface IRewardsFormula {
  function calculateRewards() external view returns(uint);
}

interface IERC20 {
  function transfer(address _to, uint _amount) external;
}

contract RewardMinter {
  IStake public stake;
  IMinter public minter;
  IERC20 public token;
  IRewardsFormula public formula;
  uint public lockTime;

  constructor(
    address _stake,
    address _minter,
    address _token,
    address _formula
    )
    public
  {
    stake = IStake(_stake);
    minter = IMinter(_minter);
    token = IERC20(_token);
    formula = IRewardsFormula(_formula);
  }

  // allow mint new rewards per each 7 days
  function mintRewards() external {
    require(now >= lockTime, "Early");
    uint mintAmount = formula.calculateRewards();
    minter.mint(mintAmount);
    token.transfer(address(stake), mintAmount);
    stake.notifyRewardAmount(mintAmount);
    lockTime = now + 7 days;
  }
}
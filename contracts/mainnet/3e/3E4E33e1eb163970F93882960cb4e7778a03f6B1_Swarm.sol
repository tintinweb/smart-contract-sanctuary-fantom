// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "SafeMath.sol";
import "ERC20Burnable.sol";
import "Operator.sol";

contract Swarm is ERC20Burnable, Operator {

    using SafeMath for uint256;

    // TOTAL MAX SUPPLY = 70,000 SWARM
    uint256 public constant FARMING_POOL_REWARD_ALLOCATION = 63000 ether;
    uint256 public constant DEV_FUND_POOL_ALLOCATION = 7000 ether;

    uint256 public constant VESTING_DURATION = 365 days;
    uint256 public startTime;
    uint256 public endTime;

    uint256 public devFundRewardRate;
    address public devFund;

    uint256 public devFundLastClaimed;

    bool public rewardPoolDistributed = false;

    constructor(uint256 _startTime, address _devFund) ERC20("SWARM", "SWARM") {

        _mint(msg.sender, 1 ether); // mint 1 SWARM for initial pools deployment

        startTime = _startTime;
        endTime = startTime + VESTING_DURATION;

        devFundLastClaimed = startTime;
        devFundRewardRate = DEV_FUND_POOL_ALLOCATION.div(VESTING_DURATION);

        require(_devFund != address(0), "Address cannot be 0");
        devFund = _devFund;
    }

    function setDevFund(address _devFund) external {
        require(msg.sender == devFund, "!dev");
        require(_devFund != address(0), "zero");
        devFund = _devFund;
    }

    function unclaimedDevFund() public view returns (uint256 _pending) {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (devFundLastClaimed >= _now) return 0;
        _pending = _now.sub(devFundLastClaimed).mul(devFundRewardRate);
    }

    function claimRewards() external {
        uint256 _pending = unclaimedDevFund();
        if (_pending > 0 && devFund != address(0)) {
            _mint(devFund, _pending);
            devFundLastClaimed = block.timestamp;
        }
    }

    function distributeReward(address _farmingIncentiveFund) external onlyOperator {
        require(!rewardPoolDistributed, "only can distribute once");
        require(_farmingIncentiveFund != address(0), "!_farmingIncentiveFund");
        rewardPoolDistributed = true;
        _mint(_farmingIncentiveFund, FARMING_POOL_REWARD_ALLOCATION);
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        _token.transfer(_to, _amount);
    }
}
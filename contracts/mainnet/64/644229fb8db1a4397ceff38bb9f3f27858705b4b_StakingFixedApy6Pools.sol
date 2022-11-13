/**
 *Submitted for verification at FtmScan.com on 2022-11-13
*/

/*  
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */

pragma solidity 0.8.17;

interface IBEP20 {
  function decimals() external view returns (uint8);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract StakingFixedApy6Pools {
    Stakeholder[] internal stakeholders;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) public totalStakedTokens;
    mapping(address => uint256) public totalStakedInPool1;
    mapping(address => uint256) public totalStakedInPool2;
    mapping(address => uint256) public totalStakedInPool3;
    mapping(address => uint256) public totalStakedInPool4;
    mapping(address => uint256) public totalStakedInPool5;
    mapping(address => uint256) public totalStakedInPool6;

    address public constant TOKEN = 0x01015DdbeaF37A522666c4B1A0186DA878c30101;
    address public constant CEO = 0xe6497e1F2C5418978D5fC2cD32AA23315E7a41Fb;
    
    mapping(uint256 => uint256) public apyRateForPool;
    mapping(uint256 => uint256) public lockDaysForPool;

    struct Stake {
        address user;
        uint256 amount;
        uint256 stakedDays;
        uint256 since;
        uint256 dueDate;
        uint256 baseRate;
        uint256 claimableReward;
        uint256 personalStakeIndex;
        uint256 pool;
    }
    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }
    struct StakingSummary {
        uint256 total_amount;
        Stake[] stakes;
    }
    
    modifier onlyCEO(){
    require (msg.sender == CEO, "Only the CEO can do that");
    _;
    }

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 stakedDays,
        uint256 index,
        uint256 timestamp,
        uint256 dueDate,
        uint256 baseRate,
        uint256 poolNr
    );

    event BnbRescued(uint256 amount);

    constructor() {
        stakeholders.push();
        apyRateForPool[1] = 110;
        apyRateForPool[2] = 45;
        apyRateForPool[3] = 20;
        apyRateForPool[4] = 12;
        apyRateForPool[5] = 5;
        apyRateForPool[6] = 0;
        lockDaysForPool[1] = 360;
        lockDaysForPool[2] = 180;      
        lockDaysForPool[3] = 90;
        lockDaysForPool[4] = 60;
        lockDaysForPool[5] = 30;      
        lockDaysForPool[6] = 15;
    }

    function _addStakeholder(address staker) internal returns (uint256) {
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex;
    }
    
    function _stake(uint256 _amount, uint256 _pool) internal {
        require(_amount > 0, "Cannot stake nothing");
        uint256 stakingRateTotal = apyRateForPool[_pool];
        uint256 dueDate = block.timestamp + lockDaysForPool[_pool] * 1 days;
        uint256 index = stakes[msg.sender];
        uint256 _personalStakeIndex;
        
        if (index == 0) {
            index = _addStakeholder(msg.sender);
            _personalStakeIndex = 0;
        } else _personalStakeIndex = stakeholders[index].address_stakes.length;
        
        stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, lockDaysForPool[_pool], block.timestamp, dueDate, stakingRateTotal, 0, _personalStakeIndex, _pool));
        totalStakedTokens[msg.sender] += _amount;
        if(_pool == 1) totalStakedInPool1[msg.sender] += _amount;
        if(_pool == 2) totalStakedInPool2[msg.sender] += _amount;
        if(_pool == 3) totalStakedInPool3[msg.sender] += _amount;
        if(_pool == 4) totalStakedInPool4[msg.sender] += _amount;
        if(_pool == 5) totalStakedInPool5[msg.sender] += _amount;
        if(_pool == 6) totalStakedInPool6[msg.sender] += _amount;
        emit Staked(msg.sender, _amount, lockDaysForPool[_pool], index, block.timestamp, dueDate, stakingRateTotal, _pool);
    }

    function calculateStakeReward(Stake memory _current_stake) internal view returns (uint256) {
        return (((block.timestamp - _current_stake.since) * _current_stake.amount) * _current_stake.baseRate) / (365 days * 100);
    }

    function allStakesOfAddress(address _staker) public view returns (StakingSummary memory){
        uint256 totalStakeAmount = 0;
        StakingSummary memory summary = StakingSummary(0,stakeholders[stakes[_staker]].address_stakes);
        
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].claimableReward = availableReward;
            totalStakeAmount += summary.stakes[s].amount;
        }
        summary.total_amount = totalStakeAmount;
        return summary;
    }

    function totalStaked(address account) external view returns (uint256) {
        return totalStakedTokens[account];
    }

    function setPools(uint256 _pool, uint256 _apy, uint256 _daysLocked) external onlyCEO {
        require(_pool > 0 && _pool < 7, "Can't create more pools");
        require(_apy <= 100, "Maximum APY is 100%");
        require(_daysLocked < 366, "Maximum lockTime is 1 year");
        require(_daysLocked > 14, "Minimum lockTime is 15 days");
        apyRateForPool[_pool] = _apy;
        lockDaysForPool[_pool] = _daysLocked;
    }
    
    function stake(uint256 _amount, uint256 _pool) public {
        require(IBEP20(TOKEN).balanceOf(msg.sender) >= _amount,"Cannot stake more than you own");
        _stake(_amount, _pool);
        IBEP20(TOKEN).transferFrom(msg.sender, address(this), _amount);
    }

    function unstake(uint256 amount, uint256 stake_index) public {
        uint256 stakingAmount;
        uint256 rewardForStaking;
        (stakingAmount, rewardForStaking) = _withdrawStake(msg.sender, amount, stake_index);
        uint256 totalWithdrawalAmount = stakingAmount + rewardForStaking;
        IBEP20(TOKEN).transfer(msg.sender, totalWithdrawalAmount);
    }

    function unstakeAll() external {
        uint256 user_index = stakes[msg.sender];
        uint256 totalWithdrawalAmount;
       
        for (uint i=0; i<stakeholders[user_index].address_stakes.length; i++) {
            Stake memory current_stake = stakeholders[user_index].address_stakes[i];
            uint256 stakeAmountOfCurrentStake = current_stake.amount;
            uint256 stakingAmount;
            uint256 rewardForStaking;
            (stakingAmount, rewardForStaking) = _withdrawStake(msg.sender,stakeAmountOfCurrentStake, i);
            totalWithdrawalAmount += stakingAmount + rewardForStaking;   
        }
        IBEP20(TOKEN).transfer(msg.sender, totalWithdrawalAmount);
    }

    function emergencyUnstakeAll() external {
        uint256 user_index = stakes[msg.sender];
        uint256 totalWithdrawalAmount;
       
        for (uint i=0; i<stakeholders[user_index].address_stakes.length; i++) {
            Stake memory current_stake = stakeholders[user_index].address_stakes[i];
            uint256 stakeAmountOfCurrentStake = current_stake.amount;
            uint256 stakingAmount;
            uint256 rewardForStaking;
            (stakingAmount, rewardForStaking) = _withdrawStake(msg.sender,stakeAmountOfCurrentStake, i);
            totalWithdrawalAmount += stakingAmount;   
        }
        IBEP20(TOKEN).transfer(msg.sender, totalWithdrawalAmount);
    }

    function _withdrawStake(address staker, uint256 amount, uint256 index) internal returns (uint256, uint256){
        uint256 user_index = stakes[staker];
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        
        if(amount > 0){
            require(current_stake.dueDate < block.timestamp,"Stake can not be claimed yet");
            require(current_stake.amount >= amount,"Cannot withdraw more than you have staked");
            totalStakedTokens[staker] -= amount;
            if(current_stake.pool == 1) totalStakedInPool1[msg.sender] -= amount;
            if(current_stake.pool == 2) totalStakedInPool2[msg.sender] -= amount;
            if(current_stake.pool == 3) totalStakedInPool3[msg.sender] -= amount;
            if(current_stake.pool == 4) totalStakedInPool4[msg.sender] -= amount;
            if(current_stake.pool == 5) totalStakedInPool5[msg.sender] -= amount;
            if(current_stake.pool == 6) totalStakedInPool6[msg.sender] -= amount;            
        }

        uint256 reward = calculateStakeReward(current_stake);
        current_stake.amount = current_stake.amount - amount;
        if (current_stake.amount == 0) {delete stakeholders[user_index].address_stakes[index];} 
        else {
            stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
            stakeholders[user_index].address_stakes[index].since = block.timestamp;
        }
        return (amount, reward);
    }

    function rescueBNB() external onlyCEO{
        uint256 amount = address(this).balance;
        (bool tmpSuccess,) = payable(CEO).call{value: amount, gas: 40000}("");
        if(tmpSuccess) emit BnbRescued(amount);
    }

    function rescueBNBWithTransfer() external onlyCEO{
        uint256 amount = address(this).balance;
        payable(CEO).transfer(amount);
        emit BnbRescued(amount);
    }
}
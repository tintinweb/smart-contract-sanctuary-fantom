/**
 *Submitted for verification at FtmScan.com on 2022-02-27
*/

// File: test.sol

pragma solidity ^0.8;


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract BasedSolidSex {
    
    // call it BasedSolidSex
    string public name = "BasedSolidSex";
    address public operator;
    address public owner;
    // create 2 state variables
    address public sex;
    address public solid;
    address public based;

    uint public TotalStaked;

    address[] public stakers;
    mapping(address => uint) stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;
    mapping(address => uint[]) receivedRewards;

    //list of reward tokens 
    address[] public rewardTokens;

    mapping(uint => uint) RewardsPerEpochList;
    mapping(uint => uint) TotalRewardsList;
    mapping(uint => bool) RewardsOnList;


    // in constructor pass in the address for USDC token and your custom bank token
    // that will be used to pay interest
    constructor() {
        operator = msg.sender;
        owner = msg.sender;
        sex = 0xD31Fcd1f7Ba190dBc75354046F6024A9b86014d7;
        solid = 0x888EF71766ca594DED1F0FA3AE64eD2941740A20;
        based = 0x8D7d3409881b51466B483B11Ea1B8A03cdEd89ae;
        rewardTokens.push(sex);
        rewardTokens.push(solid);
        RewardsPerEpochList[0] = 0;
        RewardsPerEpochList[1] = 0;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "BasedSolidSex: caller is not the operator");
        _;
    }

    function approve(address token,uint _amount) public returns(bool){
        return IERC20(token).approve(address(this), _amount);
    }


    // update the rewards per Epoch of each reward token
    function UpdateRewardsPerEpoch(uint _amount, uint RewardId) public onlyOperator {
        
        //checking amount and id
        require(_amount < TotalRewardsList[RewardId],"amount must be lower than totalRewards");
        require(RewardId < 2, "id out of range");

        //update rewards per epoch
        RewardsPerEpochList[RewardId] = _amount;
    }

    function SupplyRewards(uint _amount, uint RewardId) public onlyOperator {
        require(_amount > 0, "amount must be >0");
        require(RewardId < 2, "id out of range");

        // Trasnfer reward tokens to contract for staking
        IERC20(rewardTokens[RewardId]).transferFrom(msg.sender, address(this), _amount);

        // Update the staking balance in map
        
        TotalRewardsList[RewardId] += _amount;
        // update status for tracking
        if (TotalRewardsList[RewardId] > 0){
            RewardsOnList[RewardId] = true;
        }


    }
    


    function WithdrawRewards(uint _amount, uint RewardId) public onlyOperator {

        require(_amount <= TotalRewardsList[RewardId]);

        // Trasnfer reward tokens to contract for staking
        IERC20(rewardTokens[RewardId]).transfer(msg.sender, _amount);

        // Update the staking balance in map
        
        TotalRewardsList[RewardId] -= _amount;
        // update status for tracking
        if (TotalRewardsList[RewardId] == 0){
            RewardsOnList[RewardId] = false;
        }


    }

    function stakeTokens(uint _amount) public {

        // Trasnfer usdc tokens to contract for staking
        IERC20(based).transferFrom(msg.sender, address(this), _amount);

        // Update the staking balance in map
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;
        TotalStaked += _amount;
        // Add user to stakers array if they haven't staked already
        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update staking status to track
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;

    }
        // allow user to unstake total balance and withdraw USDC from the contract
    
    function unstakeTokens(uint _amount) public {

        // get the users staking balance in based
        uint balance = stakingBalance[msg.sender];

        //check if amount is less than balance
        require(_amount <= balance, "staking balance too low");
    	
    	stakingBalance[msg.sender] = stakingBalance[msg.sender] - _amount;
        
        // transfer staked tokens out of this contract to the msg.sender
        IERC20(based).transfer(msg.sender, _amount);

        TotalStaked -= _amount;
    
        // update the staking status
        if (stakingBalance[msg.sender] == 0){
            isStaking[msg.sender] = false;
        }
    } 




    function issueInterestToken(uint RewardId) private{
        require(RewardsOnList[RewardId]);
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint poolShare = getPoolShare(recipient);
            uint rewards = poolShare*RewardsPerEpochList[RewardId]/(1e18);
            
    // distribute income proportionally to their staked amount. 
            
            if(rewards > 0 ) {
                IERC20(rewardTokens[RewardId]).transfer(recipient, rewards);
                receivedRewards[recipient][RewardId] += rewards;
                TotalRewardsList[RewardId] -= rewards;
            }
            
        }
        if (TotalRewardsList[RewardId] == 0){
            RewardsOnList[RewardId] == false;
        }  
    }

    // get the reward tokens based on id
    function getRewardToken(uint RewardId) external view returns(address) {
        require(RewardId < 2, "id out of range");
        return rewardTokens[RewardId];
    }

    //get based balance of staker in pool
    function getBalance(address staker) external view returns(uint256) {
         return stakingBalance[staker];
    }

    //get total based staked in contract
    function getTotalStaked() external view returns(uint256) {
         return TotalStaked;
    }

    //get the pool share of a staker
    function getPoolShare(address staker) public view returns(uint256){
        return stakingBalance[staker]*(1e18)/(TotalStaked);
    }

    //get total sex/solid received by staker
    function getReceivedRewards(address staker, uint RewardId) external view returns(uint256) {
         return receivedRewards[staker][RewardId];
    }

    //get total rewards in contract
    function getTotalRewards(uint RewardId) external view returns(uint256){
        return TotalRewardsList[RewardId];
    }

    //get rewardsPerEpoch for each reward token
    function getRewardsPerEpoch(uint RewardId) external view returns(uint256){
        return RewardsPerEpochList[RewardId];
    }

    //check of rewards are available for reward tokens
    function getRewardsOn(uint RewardId) external view returns(bool){
        return RewardsOnList[RewardId];
    }


    function DistributeSolidSex() public onlyOperator{
        issueInterestToken(0);
        issueInterestToken(1);
    }


}
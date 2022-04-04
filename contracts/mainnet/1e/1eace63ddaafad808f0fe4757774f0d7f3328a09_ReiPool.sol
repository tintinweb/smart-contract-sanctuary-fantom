/**
 *Submitted for verification at FtmScan.com on 2022-04-04
*/

//SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.8.0;

contract GoToken
{
    function approve(address, uint256) external returns (bool) {}
    function transfer(address, uint256) external returns (bool) {}    
    function transferFrom(address, address, uint256) external returns (bool) {}
}

contract EshareToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
}

contract EmpToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
}

contract BusdToken
{
    function balanceOf(address) external view returns (uint256) {}
    function transfer(address, uint256) external returns (bool) {}
}

contract PancakeSwapRouter
{
    function swapExactTokensForTokens(
                 uint,
                 uint,
                 address[] calldata,
                 address,
                 uint
             ) external virtual returns (uint[] memory) {}
}

contract Boardroom
{
    function stake(uint256) public {}
 	function claimReward() public {}
}

contract ReiPool
{
    struct UserData 
    { 
        uint256 stakingDeposit;
        uint256 stakingBlock;
    }
    
    string  private _name = "\x52\x65\x69\x20\x50\x6f\x6f\x6c";
    uint256 private _swapWaitingSeconds = 3600;
    uint256 private _depositFee = 10; //Deposit fee: 10%
    uint256 private _autoCompoundFee = 33; //Auto-compound fee: 33%
    uint256 private _harvestCooldownBlocks = 86400;
    uint256 private _stakingBlockRange = 2592000;
    uint256 private _decimalFixMultiplier = 1000000000000000000;
    uint256 private _updateCooldownBlocks = 64800;
    uint256 private _minEshareAmount = _decimalFixMultiplier / 10000;

    uint256 private _lastUpdate;
    uint256 private _totalStakingDeposits;
    
    mapping(address => UserData) private _userData;
    
    address private _goTokenAddress = 0x827a19692B8BcEa675a8Bb5791048b2E2E616F16;
    address private _eshareTokenAddress = 0x49C290Ff692149A4E16611c694fdED42C954ab7a; //BSHARE
    address private _empTokenAddress = 0x8D7d3409881b51466B483B11Ea1B8A03cdEd89ae; //BASED
    address private _busdTokenAddress = 0x6a07A792ab2965C72a5B8088d3a069A7aC3a993B; //AAVE
    address private _bnbTokenAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; //FTM
    address private _pancakeSwapRouterAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29; //SpookySwap
    address private _boardroomAddress = 0xE5009Dd5912a68B0D7C6F874cD0b4492C9F0e5cD;
        
    GoToken           private _goToken;
    EshareToken       private _eshareToken;
    EmpToken          private _empToken;
    BusdToken         private _busdToken;
    PancakeSwapRouter private _pancakeSwapRouter;
    Boardroom         private _boardroom;
    
    address[] private _goEsharePair;
    address[] private _empBusdPair;
    address[] private _empEsharePair;    
    
    constructor()
    {
        //Initialize contracts
        _goToken           = GoToken(_goTokenAddress);
        _eshareToken       = EshareToken(_eshareTokenAddress);
        _empToken          = EmpToken(_empTokenAddress);
        _busdToken         = BusdToken(_busdTokenAddress);
        _pancakeSwapRouter = PancakeSwapRouter(_pancakeSwapRouterAddress);
        _boardroom         = Boardroom(_boardroomAddress);
        
        //Initialize trading pairs
        _goEsharePair   = [_goTokenAddress,   _bnbTokenAddress, _eshareTokenAddress];
        _empBusdPair    = [_empTokenAddress,  _bnbTokenAddress, _busdTokenAddress];
        _empEsharePair  = [_empTokenAddress,  _bnbTokenAddress, _eshareTokenAddress];        
    }
    
    function getName() external view returns (string memory)
    {
        return _name;
    }
    
    function getRewardsFund() public view returns (uint256)
    {
        return _busdToken.balanceOf(address(this));
    }
    
    function getTotalStakingDeposits() external view returns (uint256)
    {
        return _totalStakingDeposits;
    }
    
    function getDepositFee() external view returns (uint256)
    {
        return _depositFee;
    }
    
    function getHarvestCooldownBlocks() external view returns (uint256)
    {
        return _harvestCooldownBlocks;
    }
    
    function getStakingBlockRange() external view returns (uint256)
    {
        return _stakingBlockRange;
    } 
    
    function updateRewardsFund() private
    {
        uint256 elapsedBlocks = block.number - _lastUpdate;
    
        if (elapsedBlocks > _updateCooldownBlocks)
        {
            address[] memory empBusdPairMemory = _empBusdPair;
			address[] memory empEsharePairMemory = _empEsharePair;            
                
            //Harvest pending Emp
            _boardroom.claimReward();
            
            uint256 empAmount = _empToken.balanceOf(address(this));
            
            uint256 autoCompoundFeeAmount = empAmount * _autoCompoundFee / 100;
            
            //Auto-compound
            if (autoCompoundFeeAmount > 0)
            {
            	//Swap Emp for Eshare
                _empToken.approve(_pancakeSwapRouterAddress, autoCompoundFeeAmount);
                _pancakeSwapRouter.swapExactTokensForTokens(autoCompoundFeeAmount, 0, empEsharePairMemory, address(this), block.timestamp + _swapWaitingSeconds);
            
               	uint256 eshareAmount = _eshareToken.balanceOf(address(this));
                
                _eshareToken.approve(_boardroomAddress, eshareAmount);
                _boardroom.stake(eshareAmount);
            }
            
            //Swap Emp for BUSD
            empAmount = _empToken.balanceOf(address(this));
            
            if (empAmount > 0)
            {
                _empToken.approve(_pancakeSwapRouterAddress, empAmount);
                _pancakeSwapRouter.swapExactTokensForTokens(empAmount, 0, empBusdPairMemory, address(this), block.timestamp + _swapWaitingSeconds);
            }
            
            _lastUpdate = block.number;
        }
    }
    
    function deposit(uint256 amount) external 
    {
        require(amount >= 100, "ReiPool: minimum deposit amount: 100");
        
        _goToken.transferFrom(msg.sender, address(this), amount);
        
        uint256 fee = amount * _depositFee / 100;
        uint256 netAmount = amount - fee;
        
        //Update user data
        _userData[msg.sender].stakingDeposit += netAmount;
        _userData[msg.sender].stakingBlock = block.number;
        
        _totalStakingDeposits += netAmount;
        
        //Swap deposit fee for Eshare
        address[] memory goEsharePairMemory = _goEsharePair;
        
        _goToken.approve(_pancakeSwapRouterAddress, fee);
        _pancakeSwapRouter.swapExactTokensForTokens(fee, 0, goEsharePairMemory, address(this), block.timestamp + _swapWaitingSeconds);
        
        //Deposit Eshare on EMP Money Boardroom
        uint256 eshareAmount = _eshareToken.balanceOf(address(this));
            
        if (eshareAmount > _minEshareAmount)
        {
            _eshareToken.approve(_boardroomAddress, eshareAmount);
            _boardroom.stake(eshareAmount);
            _lastUpdate = block.number;
        }
    }

    function withdraw() external
    {
        uint256 blocksStaking = computeBlocksStaking();

        if (blocksStaking > _harvestCooldownBlocks)
            harvest();
        
        emergencyWithdraw();
    }
    
    function emergencyWithdraw() public
    {
        uint256 stakingDeposit = _userData[msg.sender].stakingDeposit;
        
        require(stakingDeposit > 0, "ReiPool: withdraw amount cannot be 0");
        
        _userData[msg.sender].stakingDeposit = 0;
 
        _goToken.transfer(msg.sender, stakingDeposit);
        
        _totalStakingDeposits -= stakingDeposit;
    }

    function computeUserReward() public view returns (uint256)
    {
        require(_userData[msg.sender].stakingDeposit > 0, "ReiPool: staking deposit is 0");
    
        uint256 rewardsFund = getRewardsFund();
        
        uint256 userReward = 0;
    
        uint256 blocksStaking = computeBlocksStaking();
        
        if (blocksStaking > 0)
	    {
	        uint256 userBlockRatio = _decimalFixMultiplier;
	    
	        if (blocksStaking < _stakingBlockRange)
	            userBlockRatio = blocksStaking * _decimalFixMultiplier / _stakingBlockRange; 
		    
		    uint256 userDepositRatio = _decimalFixMultiplier;
		    
		    if (_userData[msg.sender].stakingDeposit < _totalStakingDeposits)
		        userDepositRatio = _userData[msg.sender].stakingDeposit * _decimalFixMultiplier / _totalStakingDeposits;
		    
		    uint256 totalRatio = userBlockRatio * userDepositRatio / _decimalFixMultiplier;
		    
		    userReward = totalRatio * rewardsFund / _decimalFixMultiplier;
		}
		
		return userReward;
    }

    function harvest() public 
    {
        require(_userData[msg.sender].stakingDeposit > 0, "ReiPool: staking deposit is 0");

        uint256 blocksStaking = computeBlocksStaking();

        require(blocksStaking > _harvestCooldownBlocks, "ReiPool: harvest cooldown in progress");
    
        updateRewardsFund();
        
        uint256 userReward = computeUserReward();
        
        _userData[msg.sender].stakingBlock = block.number;

        _busdToken.transfer(msg.sender, userReward);
    }
    
    function getStakingDeposit() external view returns (uint256)
    {
        UserData memory userData = _userData[msg.sender];
    
        return (userData.stakingDeposit);
    }
    
    function getStakingBlock() external view returns (uint256)
    {
        UserData memory userData = _userData[msg.sender];
    
        return (userData.stakingBlock);
    }
    
    function computeBlocksStaking() public view returns (uint256)
    {
        uint256 blocksStaking = 0;
        
        if (_userData[msg.sender].stakingDeposit > 0)
            blocksStaking = block.number - _userData[msg.sender].stakingBlock;
        
        return blocksStaking;
    }
}
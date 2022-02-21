/**
 *Submitted for verification at FtmScan.com on 2022-02-21
*/

//SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.8.0;

contract GoToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
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
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
    function transfer(address, uint256) external returns (bool) {}
    function transferFrom(address, address, uint256) external returns (bool) {}
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

contract GoFarm
{
    function donate(uint256) external {}
}

contract Boardroom
{
    function stake(uint256) public {}
 	function claimReward() public {}
}

contract Ginko
{
    struct UserData 
    { 
        uint256 stakingDeposit;
        uint256 stakingBlock;
    }
    
    string  private _name = "\x47\x69\x6e\x6b\xc5\x8d";
    uint256 private _swapWaitingSeconds = 3600;
    uint256 private _depositFee = 10; //Deposit fee: 10%
    uint256 private _performanceFee = 1; //Performance fee: 1%
    uint256 private _autoCompoundFee = 33; //Auto-compound fee: 33%
    uint256 private _harvestCooldownBlocks = 86400;
    uint256 private _stakingBlockRange = 2592000;
    uint256 private _decimalFixMultiplier = 1000000000000000000;
    uint256 private _updateCooldownBlocks = 64800;

    uint256 private _lastUpdate;
    uint256 private _totalStakingDeposits;
    
    mapping(address => UserData) private _userData;
    
    address private _goTokenAddress = 0x827a19692B8BcEa675a8Bb5791048b2E2E616F16;
    address private _eshareTokenAddress = 0x4cdF39285D7Ca8eB3f090fDA0C069ba5F4145B37; //TSHARE
    address private _empTokenAddress = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7; //TOMB
    address private _busdTokenAddress = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E; //DAI
    address private _bnbTokenAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; //FTM
    address private _pancakeSwapRouterAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29; //SpookySwap
    address private _goFarmAddress = 0xc99a8C938efFE3725952Ba083F624C364ed717FC;
    address private _boardroomAddress = 0x8764DE60236C5843D9faEB1B638fbCE962773B67;
        
    GoToken           private _goToken;
    EshareToken       private _eshareToken;
    EmpToken          private _empToken;
    BusdToken         private _busdToken;
    PancakeSwapRouter private _pancakeSwapRouter;
    GoFarm            private _goFarm;
    Boardroom         private _boardroom;
    
    address[] private _busdEsharePair;
    address[] private _empGoPair;
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
        _goFarm            = GoFarm(_goFarmAddress);
        _boardroom         = Boardroom(_boardroomAddress);
        
        //Initialize trading pairs
        _busdEsharePair = [_busdTokenAddress, _bnbTokenAddress, _eshareTokenAddress];
        _empGoPair      = [_empTokenAddress,  _bnbTokenAddress, _goTokenAddress];
        _empBusdPair    = [_empTokenAddress,  _bnbTokenAddress, _busdTokenAddress];
        _empEsharePair  = [_empTokenAddress,  _bnbTokenAddress, _eshareTokenAddress];        
    }
    
    function getName() external view returns (string memory)
    {
        return _name;
    }
    
    function getRewardsFund() public view returns (uint256)
    {
        return _busdToken.balanceOf(address(this)) - _totalStakingDeposits;
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
    
    function buyGoToken(uint256 empAmount) private
    {
        require(empAmount > 0, "Ginko: Emp amount cannot be 0");
    
        address[] memory empGoPairMemory = _empGoPair;
        
        //Swap Emp for Gō
        _empToken.approve(_pancakeSwapRouterAddress, empAmount);
        _pancakeSwapRouter.swapExactTokensForTokens(empAmount, 0, empGoPairMemory, address(this), block.timestamp + _swapWaitingSeconds);
        
        //Donate to Gō farm
        uint256 goAmount = _goToken.balanceOf(address(this));
        
        if (goAmount > 0)
        {
            _goToken.approve(_goFarmAddress, goAmount);
            _goFarm.donate(goAmount);
        }
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
            
            uint256 performanceFeeAmount = empAmount * _performanceFee / 100;
            uint256 autoCompoundFeeAmount = empAmount * _autoCompoundFee / 100;
            
            //Buy Gō and donate it to Gō farm
            if (performanceFeeAmount > 0)
                buyGoToken(performanceFeeAmount);
                
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
        require(amount >= 100, "Ginko: minimum deposit amount: 100");
        
        //Update rewards fund
        updateRewardsFund();
        
        _busdToken.transferFrom(msg.sender, address(this), amount);
        
        uint256 fee = amount * _depositFee / 100;
        uint256 netAmount = amount - fee;
        
        //Update user data
        _userData[msg.sender].stakingDeposit += netAmount;
        _userData[msg.sender].stakingBlock = block.number;
        
        _totalStakingDeposits += netAmount;
        
        //Swap deposit fee for Eshare
        address[] memory busdEsharePairMemory = _busdEsharePair;
        
        _busdToken.approve(_pancakeSwapRouterAddress, fee);
        _pancakeSwapRouter.swapExactTokensForTokens(fee, 0, busdEsharePairMemory, address(this), block.timestamp + _swapWaitingSeconds);
        
        //Deposit Eshare on EMP Money Boardroom
        uint256 eshareAmount = _eshareToken.balanceOf(address(this));
            
        if (eshareAmount > 0)
        {
            _eshareToken.approve(_boardroomAddress, eshareAmount);
            _boardroom.stake(eshareAmount);
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
        
        require(stakingDeposit > 0, "Ginko: withdraw amount cannot be 0");
        
        _userData[msg.sender].stakingDeposit = 0;
 
        _busdToken.transfer(msg.sender, stakingDeposit);
        
        _totalStakingDeposits -= stakingDeposit;
    }

    function computeUserReward() public view returns (uint256)
    {
        require(_userData[msg.sender].stakingDeposit > 0, "Ginko: staking deposit is 0");
    
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
        require(_userData[msg.sender].stakingDeposit > 0, "Ginko: staking deposit is 0");

        uint256 blocksStaking = computeBlocksStaking();

        require(blocksStaking > _harvestCooldownBlocks, "Ginko: harvest cooldown in progress");
    
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
////////////////////////////////////////////////////////
// RewardPool.sol
//
// Manages genesis and initial token distribution
////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT

/// Defines / Macros -----------------------------------

pragma solidity 0.6.12 ;

/// Includes -------------------------------------------

import "./IERC20.sol" ;
import "./SafeERC20.sol" ;
import "./SafeMath.sol" ;

import "./Operator.sol" ;

/// Contract -------------------------------------------

contract RewardPool is Operator
{
	/// Defines ------------------------------

	using SafeMath for uint256 ;
	using SafeERC20 for IERC20 ;

	/// Events -------------------------------

	event Deposit (address indexed user, uint256 indexed pid, uint256 amount) ;
	event EmergencyWithdraw (address indexed user, uint256 indexed pid, uint256 amount) ;
	event RewardPaid (address indexed user, uint256 amount) ;
	event Withdraw (address indexed user, uint256 indexed pid, uint256 amount) ;

	/// Structures ---------------------------

	// Info of each user.
	struct UserInfo
	{
		uint256 amount ; // How many tokens the user has provided.
		uint256 rewardDebt ; // Reward debt. See explanation below.
	}

	// Info of each pool.
	struct PoolInfo
	{
		IERC20 token ; // Address of LP token contract.
		uint256 tokenSupply ;
		uint256 allocPoint ; // How many allocation points assigned to this pool. TOMB to distribute.
		uint256 lastRewardTime ; // Last time that TOMB distribution occurs.
		uint256 accOutputPerShare ; // Accumulated TOMB per share, times 1e18. See below.
		uint256 taxPercent ;
		bool isStarted ; // if lastRewardBlock has passed
	}

	/// Attributes ---------------------------

	// Governance
	address public _taxFund ;

	// Output info
	IERC20 public _outputToken ;
	uint256 public _outputPerSecond ;

	// Info of each pool.
	PoolInfo[] public _poolInfo ;

	// Info of each user that stakes LP tokens
	mapping(uint256 => mapping(address => UserInfo)) public _userInfo ;

	// Total allocation points. Must be the sum of all allocation points in all pools
	uint256 public _totalAllocPoint = 0 ;

	// Timing info
	uint256 public _startTime ;
	uint256 public _endTime ;

	/// Constructor --------------------------

	constructor (address outputToken, address taxFund, uint256 startTime, uint256 runningTime) public
	{
		require(block.timestamp < startTime, "Starting time is before block timestamp") ;
		require(taxFund != address(0), "Tax fund address cannot be null") ;

		if (outputToken != address(0))
			_outputToken = IERC20(outputToken) ;

		_taxFund = taxFund ;
		_startTime = startTime ;
		_endTime = startTime.add(runningTime) ;
	}

	/// Getters ------------------------------

	function getGeneratedReward (uint256 fromTime, uint256 toTime) public view returns (uint256)
	{
		if (fromTime >= toTime)
			return 0 ;

		if (toTime >= _endTime)
		{
			if (fromTime >= _endTime)
				return 0 ;

			if (fromTime <= _startTime)
				return _endTime.sub(_startTime).mul(_outputPerSecond) ;

			return _endTime.sub(fromTime).mul(_outputPerSecond) ;
		}
		else
		{
			if (toTime <= _startTime)
				return 0 ;

			if (fromTime <= _startTime)
				return toTime.sub(_startTime).mul(_outputPerSecond) ;

			return toTime.sub(fromTime).mul(_outputPerSecond) ;
		}
	}

	function pendingOutput (uint256 pid, address user) external view returns (uint256)
	{
		return pendingOutputCustomTime(pid, user, block.timestamp) ;
	}

	function pendingOutputCustomTime (uint256 pid, address user, uint256 timestamp) public view returns(uint256)
	{
		PoolInfo storage pool = _poolInfo[pid] ;
		UserInfo storage userInfo = _userInfo[pid][user] ;

		uint256 accOutputPerShare = pool.accOutputPerShare ;
		uint256 tokenSupply = pool.tokenSupply ;

		if (timestamp > pool.lastRewardTime && tokenSupply != 0)
		{
			uint256 generatedReward = getGeneratedReward(pool.lastRewardTime, timestamp) ;
			uint256 reward = generatedReward.mul(pool.allocPoint).div(_totalAllocPoint);
			accOutputPerShare = accOutputPerShare.add(reward.mul(1e18).div(tokenSupply));
		}

		return userInfo.amount.mul(accOutputPerShare).div(1e18).sub(userInfo.rewardDebt) ;
	}

	/// Setters ------------------------------

	function set (uint256 pid, uint256 allocPoint) public onlyOperator
	{
		massUpdatePools() ;

		PoolInfo storage pool = _poolInfo[pid] ;

		if (pool.isStarted)
			_totalAllocPoint = _totalAllocPoint.sub(pool.allocPoint).add(allocPoint) ;

		pool.allocPoint = allocPoint ;
	}

	/// Distribution -------------------------

	function checkPoolDuplicate (IERC20 token) internal view
	{
		uint256 length = _poolInfo.length ;

		for (uint256 pid = 0 ; pid < length ; ++pid)
			require(_poolInfo[pid].token != token, "Genesis pool : existing distribution pool") ;
	}

	function add (uint256 allocPoint, IERC20 token, bool withUpdate, uint256 lastRewardTime, uint256 taxPercent) public virtual onlyOperator
	{
		require(taxPercent <=  1000, "Cannot push further than 10% tax") ;
		checkPoolDuplicate(token) ;

		if (withUpdate)
			massUpdatePools() ;

		if (block.timestamp < _startTime)
		{
			// We are not started yet
			if (lastRewardTime == 0)
				lastRewardTime = _startTime ;
			else
			{
				if (lastRewardTime < _startTime)
					lastRewardTime = _startTime ;
			}
		}
		else
		{
			// Pool already started
			if (lastRewardTime == 0 || lastRewardTime < block.timestamp)
				lastRewardTime = block.timestamp ;
		}

		bool isStarted = (lastRewardTime <= _startTime) || (lastRewardTime <= block.timestamp) ;

		_poolInfo.push(PoolInfo(
			{
				token : token,
				tokenSupply : 0,
				allocPoint : allocPoint,
				lastRewardTime : lastRewardTime,
				accOutputPerShare : 0,
				isStarted : isStarted,
				taxPercent : taxPercent
			}
		)) ;

		if (isStarted)
			_totalAllocPoint = _totalAllocPoint.add(allocPoint) ;
	}

	function setPoolTax (uint256 pid, uint256 taxPercent) public onlyOperator
	{
		require(taxPercent <=  1000, "Cannot push further than 10% tax") ;

		PoolInfo storage pool = _poolInfo[pid] ;
		pool.taxPercent = taxPercent ;
	}

	/// Updates ------------------------------

	function updateDistributionMetricsFromReserve () public onlyOperator
	{
		require(_outputPerSecond == 0, "Cannot update metrics once everything is launched") ;

		_outputPerSecond = _outputToken.balanceOf(address(this)).div(_endTime.sub(_startTime)) ;
	}

	function massUpdatePools () public
	{
		uint256 length = _poolInfo.length ;

		for (uint256 pid = 0; pid < length; ++pid)
			updatePool(pid) ;
	}

	// Update reward variables of the given pool to be up-to-date.
	function updatePool (uint256 pid) public
	{
		PoolInfo storage pool = _poolInfo[pid] ;

		if (block.timestamp <= pool.lastRewardTime)
			return ;

		uint256 tokenSupply = pool.tokenSupply ;

		if (tokenSupply == 0)
		{
			pool.lastRewardTime = block.timestamp ;
			return ;
		}

		if (!pool.isStarted)
		{
			pool.isStarted = true ;
			_totalAllocPoint = _totalAllocPoint.add(pool.allocPoint) ;
		}

		if (_totalAllocPoint > 0)
		{
			uint256 generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp) ;
			uint256 outputReward = generatedReward.mul(pool.allocPoint).div(_totalAllocPoint) ;
			pool.accOutputPerShare = pool.accOutputPerShare.add(outputReward.mul(1e18).div(tokenSupply)) ;
		}

		pool.lastRewardTime = block.timestamp ;
	}

	/// Interaction --------------------------

	function deposit (uint256 pid, uint256 amount) public virtual returns (uint256)
	{
		require(amount > 0) ;

		address sender = msg.sender ;
		PoolInfo storage pool = _poolInfo[pid] ;
		UserInfo storage user = _userInfo[pid][sender] ;

		updatePool(pid) ;

		// Give reward back
		if (user.amount > 0)
		{
			uint256 pending = user.amount.mul(pool.accOutputPerShare).div(1e18).sub(user.rewardDebt) ;

			if (pending > 0)
			{
				safeOutputTransfer(sender, pending) ;
				emit RewardPaid(sender, pending) ;
			}
		}

		// Work on tax
		uint256 taxAmount = 0 ;

		if (pool.taxPercent > 0)
			taxAmount = amount.mul(pool.taxPercent).div(10000) ;

		// Stake
		if (amount > 0)
		{
			// Transfer from caller
			pool.token.safeTransferFrom(sender, address(this), amount) ;

			// Update taking tax into account
			amount = amount.sub(taxAmount) ;
			user.amount = user.amount.add(amount) ;
			pool.tokenSupply = pool.tokenSupply.add(amount) ;

			// Send tax if needed
			if (taxAmount > 0)
				pool.token.safeTransfer(_taxFund, taxAmount) ;
		}

		// Account for paid rewards
		user.rewardDebt = user.amount.mul(pool.accOutputPerShare).div(1e18) ;

		emit Deposit(sender, pid, amount) ;

		return amount ;
	}

	function withdraw (uint256 pid, uint256 amount) public virtual
	{
		_withdrawForUser(pid, amount, msg.sender) ;
	}

	function _withdrawForUser (uint256 pid, uint256 amount, address userAddress) internal
	{
		PoolInfo storage pool = _poolInfo[pid] ;
		UserInfo storage user = _userInfo[pid][userAddress] ;
		require(user.amount >= amount, "Withdraw : asking for too much") ;

		updatePool(pid) ;

		uint256 pending = user.amount.mul(pool.accOutputPerShare).div(1e18).sub(user.rewardDebt) ;

		if (pending > 0)
		{
			safeOutputTransfer(userAddress, pending) ;
			emit RewardPaid(userAddress, pending) ;
		}

		if (amount > 0)
		{
			user.amount = user.amount.sub(amount) ;
			pool.token.safeTransfer(userAddress, amount) ;
			pool.tokenSupply = pool.tokenSupply.sub(amount) ;
		}
		
		user.rewardDebt = user.amount.mul(pool.accOutputPerShare).div(1e18) ;
		emit Withdraw(userAddress, pid, amount) ;
	}

	function emergencyWithdraw (uint256 pid) public virtual
	{
		PoolInfo storage pool = _poolInfo[pid] ;
		UserInfo storage user = _userInfo[pid][msg.sender] ;

		uint256 amount = user.amount ;
		user.amount = 0 ;
		user.rewardDebt = 0 ;

		pool.token.safeTransfer(msg.sender, amount) ;
		pool.tokenSupply = pool.tokenSupply.sub(amount) ;

		emit EmergencyWithdraw(msg.sender, pid, amount) ;
	}

	/// Utils --------------------------------

	function safeOutputTransfer (address to, uint256 amount) internal
	{
		uint256 outputBalance = _outputToken.balanceOf(address(this)) ;

		if (outputBalance > 0)
		{
			if (amount > outputBalance)
				_outputToken.safeTransfer(to, outputBalance) ;
			else
				_outputToken.safeTransfer(to, amount) ;
		}
	}

	function governanceRecoverUnsupported (IERC20 token, uint256 amount, address to) external onlyOperator
	{
		// Wait more than 90 days to drain protocol tokens
		if (block.timestamp < _endTime + 90 days)
		{
			require(token != _outputToken, "Cannot drain output token within 90 days after end of emission")  ;

			uint256 length = _poolInfo.length ;

			for (uint256 pid = 0 ; pid < length ; ++pid)
			{
				PoolInfo storage pool = _poolInfo[pid];
				require(token != pool.token, "Cannot drain token used within 90 days after end of emission") ;
			}
		}

		token.safeTransfer(to, amount) ;
	}
}
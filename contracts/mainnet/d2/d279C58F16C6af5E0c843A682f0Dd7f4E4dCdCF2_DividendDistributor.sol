////////////////////////////////////////////////////////
// DividendDistributor.sol
//
// Dividend rewarding distributor
////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT

/// Defines / Macros -----------------------------------

pragma solidity 0.6.12 ;

/// Includes -------------------------------------------

import "./IERC20.sol" ;
import "./SafeERC20.sol" ;

import "./Operator.sol" ;

import "./DividendTokenomics.sol" ;

import "./ContractGuard.sol" ;

/// Contract -------------------------------------------

contract DividendDistributor is ContractGuard, Operator
{
	/// Defines ------------------------------

	using SafeERC20 for IERC20 ;
	using Address for address ;
	using SafeMath for uint256 ;

	/// Structures ---------------------------

	struct UserSeat
	{
		uint256 lastSnapshotIndex ;
		uint256 rewardEarned ;
		uint256 cycleTimerStart ;
	}

	struct DistributorSnapshot
	{
		uint256 time ;
		uint256 rewardReceived ;
		uint256 rewardPerShare ;
	}
	
	/// Events -------------------------------

	event Initialized (address indexed executor, uint256 at) ;
	event Staked (address indexed user, uint256 amount) ;
	event Withdrawn (address indexed user, uint256 amount) ;
	event RewardPaid (address indexed user, uint256 reward) ;
	event RewardAdded (address indexed user, uint256 reward) ;

	/// Attributes ---------------------------

	// Governance
	address public _taxFund = address(0) ;

	uint256 public _taxStake = 0 ;
	uint256 public _taxUnstakeUnderPeg = 0 ;

	// Witnesses
	bool public _initialized = false ;

	// Protocol tokens
	IERC20 public _digit ;
	IERC20 public _share ;

	// Tokenomics used
	DividendTokenomics public _dividendTokenomics ;

	// Users
	mapping(address => UserSeat) public _users ;
	DistributorSnapshot[] public _history ;

	// Parameters
	uint256 public _withdrawLockupCycles ;
	uint256 public _rewardLockupCycles ;
	uint256 public _cycleTime ;

	uint256 public _distributionFactor ;

	// Tracking
	uint256 public _startTime ;
	uint256 public _lastCycle ;
	uint256 internal _totalSupply ;
	mapping(address => uint256) internal _balances ;

	/// Modifiers ----------------------------

	modifier userExists
	{
		require(balanceOf(msg.sender) > 0, "The user does not exist") ;
		_ ;
	}

	modifier updateReward (address user)
	{
		if (user != address(0))
		{
			// Update snapshot first
			updateHistory() ;

			// Update current rewards
			UserSeat memory seat = _users[user] ;
			seat.rewardEarned = earned(user) ;
			seat.lastSnapshotIndex = latestSnapshotIndex() ;
			_users[user] = seat ;
		}

		_ ;
	}

	modifier notInitialized
	{
		require(!_initialized, "Already initialized");
		_ ;
	}

	/// Init ---------------------------------

	function initialize (IERC20 digit, IERC20 share, uint256 startTime, uint256 cycleTime, uint256 lastCycle) public notInitialized onlyOperator
	{
		_digit = digit ;
		_share = share ;
		_startTime = startTime ;
		_lastCycle = lastCycle ;

		DistributorSnapshot memory genesisSnapshot = DistributorSnapshot({time : block.number, rewardReceived : 0, rewardPerShare : 0});
		_history.push(genesisSnapshot) ;

		_withdrawLockupCycles = 3 ;
		_rewardLockupCycles = 2 ;
		_cycleTime = cycleTime ;

		_distributionFactor = 10000 ;

		_initialized = true ;

		emit Initialized(msg.sender, block.number) ;
	}

	/// Getters ------------------------------

	function latestSnapshotIndex () public view returns (uint256)
	{
		return _history.length.sub(1) ;
	}

	function getLatestSnapshot () internal view returns (DistributorSnapshot memory)
	{
		return _history[latestSnapshotIndex()] ;
	}

	function getLastSnapshotIndexOf (address user) public view returns (uint256)
	{
		return _users[user].lastSnapshotIndex ;
	}

	function getLastSnapshotOf (address user) internal view returns (DistributorSnapshot memory)
	{
		return _history[getLastSnapshotIndexOf(user)] ;
	}

	function canWithdraw (address user) external view returns (bool)
	{
		return _users[user].cycleTimerStart.add(_withdrawLockupCycles) <= getCurrentCycle() ;
	}

	function canClaimReward (address user) external view returns (bool)
	{
		return _users[user].cycleTimerStart.add(_rewardLockupCycles) <= getCurrentCycle() ;
	}

	function getCurrentCycle () public view returns (uint256)
	{
		return getCurrentCycleFromTime(block.timestamp) ;
	}
	
	function getCurrentCycleFromTime (uint256 timestamp) public view returns (uint256)
	{
		// Compute cycle, clamping between our timelapse
		uint256 elapsedTime = max(timestamp, _startTime) ;
		uint256 currentCycle = min((elapsedTime.sub(_startTime)).div(_cycleTime), _lastCycle) ;

		return currentCycle ;
	}

	function getCycleReward (uint256 cycle) public view returns (uint256)
	{
		uint256 result = _dividendTokenomics.getRewardForCycle(cycle) ;

		return result.mul(_distributionFactor).div(10000) ;
	}

	function nextCyclePoint () external view returns (uint256)
	{
		return _startTime + (getCurrentCycle() * _cycleTime) ;
	}

	function totalSupply () public view returns (uint256)
	{
		return _totalSupply ;
	}

	function balanceOf (address account) public view returns (uint256)
	{
		return _balances[account] ;
	}

	function rewardPerShare () public view returns (uint256)
	{
		return getLatestSnapshot().rewardPerShare;
	}

	function earned (address user) public view returns (uint256)
	{
		if (balanceOf(user) == 0)
			return 0 ;
			
		uint256 latestRPS = getLatestSnapshot().rewardPerShare ;
		uint256 storedRPS = getLastSnapshotOf(user).rewardPerShare ;

		uint256 currentHistoryEarnings = balanceOf(user).mul(latestRPS.sub(storedRPS)).div(1e18).add(_users[user].rewardEarned) ;
		uint256 futureHistoryEarnings = 0 ;

		uint lastFilledCycle = _history.length - 1 ;
		uint currentCycle = getCurrentCycle() ;
		uint toCatchUp = currentCycle - lastFilledCycle ;

		for (uint i = 0 ; i < toCatchUp ; ++i)
			futureHistoryEarnings = futureHistoryEarnings.add(getCycleReward(lastFilledCycle.add(i)).mul(1e18).div(_totalSupply)) ;

		futureHistoryEarnings = balanceOf(user).mul(futureHistoryEarnings).div(1e18) ;

		return currentHistoryEarnings.add(futureHistoryEarnings) ;
	}

	/// Setters ------------------------------

	function setLockUp (uint256 withdrawLockupCycles, uint256 rewardLockupCycles) external onlyOperator
	{
		require(withdrawLockupCycles >= rewardLockupCycles && withdrawLockupCycles <= 5, "Lockup too big or incorrect") ;

		_withdrawLockupCycles = withdrawLockupCycles ;
		_rewardLockupCycles = rewardLockupCycles ;
	}

	function setTaxFund (address taxFund) public onlyOperator
	{
		require(taxFund != address(0), "Tax fund cannot be null") ;
		_taxFund = taxFund ;
	}

	function setTaxStake (uint256 taxPercent) public onlyOperator
	{
		require(taxPercent <= 1000, "No more than 10% tax") ;
		_taxStake = taxPercent ;
	}

	function setTaxUnstakeUnderPeg (uint256 taxPercent) public onlyOperator
	{
		require(taxPercent <= 1000, "No more than 10% tax") ;
		_taxUnstakeUnderPeg = taxPercent ;
	}

	function setDistributionFactor (uint256 value) public onlyOperator
	{
		require(value <= 10000, "No more than 100% production") ;

		// Udpate history to freeze current earnings
		updateHistory() ;

		// Update value starting next cycle
		_distributionFactor = value ;
	}

	function setDividendTokenomics (DividendTokenomics value) public onlyOperator
	{
		_dividendTokenomics = value ;
	}

	/// Staking ------------------------------

	function stake (uint256 amount) public virtual onlyOneBlock updateReward(msg.sender)
	{
		require(amount > 0, "DividendDistributor : Cannot stake 0") ;

		// Check tax
		uint256 taxAmount = 0 ;

		if (_taxStake > 0)
			taxAmount = amount.mul(_taxStake).div(10000) ;

		// Transfer tokens and apply tax
		_share.safeTransferFrom(msg.sender, address(this), amount) ;

		if (taxAmount > 0)
		{
			_share.safeTransfer(_taxFund, taxAmount) ;
			amount = amount.sub(taxAmount) ;
		}

		// Update seat
		_totalSupply = _totalSupply.add(amount) ;
		_balances[msg.sender] = _balances[msg.sender].add(amount) ;
		_users[msg.sender].cycleTimerStart = getCurrentCycle() ;

		emit Staked(msg.sender, amount) ;
	}

	function withdraw (uint256 amount) public virtual onlyOneBlock userExists updateReward(msg.sender)
	{
		require(amount > 0, "DividendDistributor : Cannot withdraw 0") ;
		require(_users[msg.sender].cycleTimerStart.add(_withdrawLockupCycles) <= getCurrentCycle(), "DividendDistributor : still in withdraw lockup") ;

		// Get the reward out
		claimReward() ;

		// Allowing to check unstaking value
		uint256 userShare = _balances[msg.sender] ;
		require(userShare >= amount, "DividendDistributor : withdraw request greater than staked amount") ;
		_totalSupply = _totalSupply.sub(amount) ;
		_balances[msg.sender] = userShare.sub(amount) ;

		// See what tax says
		if (_taxUnstakeUnderPeg > 0)
		{
			uint256 taxAmount = amount.mul(_taxUnstakeUnderPeg).div(10000) ;
			amount = amount.sub(taxAmount) ;

			_share.safeTransfer(_taxFund, taxAmount) ;
		}

		// Transfer final value to seat holder
		_share.safeTransfer(msg.sender, amount) ;

		emit Withdrawn(msg.sender, amount) ;
	}

	function exit () external virtual
	{
		withdraw(balanceOf(msg.sender)) ;
	}

	function claimReward () public virtual updateReward(msg.sender)
	{
		uint256 reward = _users[msg.sender].rewardEarned;

		if (reward > 0)
		{
			require(_users[msg.sender].cycleTimerStart.add(_rewardLockupCycles) <= getCurrentCycle(), "DividendDistributor : still in reward lockup") ;
			_users[msg.sender].cycleTimerStart = getCurrentCycle() ;
			_users[msg.sender].rewardEarned = 0 ;
			_digit.safeTransfer(msg.sender, reward) ;
			emit RewardPaid(msg.sender, reward) ;
		}
	}

	/// Updates ------------------------------

	function updateHistory () public
	{
		// Ensure we have something staked first
		uint256 currentSupply = totalSupply() ;
		
		if (currentSupply == 0)
			return ;

		// Catch up with the number of cycles that should have been going through
		uint lastFilledCycle = _history.length - 1 ;
		uint currentCycle = getCurrentCycle() ;
		uint toCatchUp = currentCycle - lastFilledCycle ;

		for (uint i = 0 ; i < toCatchUp ; ++i)
		{
			// Fill a new history entry
			uint256 cycleReward = getCycleReward(lastFilledCycle + i) ;
			uint256 previousRewardPerShare = _history[lastFilledCycle + i].rewardPerShare ;
			uint256 newRewardPerShare = previousRewardPerShare + (cycleReward * 1e18 / currentSupply) ;

			DistributorSnapshot memory cycleSnapshot = DistributorSnapshot({time: block.timestamp, rewardReceived: cycleReward, rewardPerShare: newRewardPerShare}) ;
			_history.push(cycleSnapshot) ;

			emit RewardAdded(msg.sender, cycleReward) ;
		}
	}

	/// Utils --------------------------------

	function min (uint256 a, uint256 b) internal pure returns (uint256)
	{
		return a <= b ? a : b ;
	}

	function max (uint256 a, uint256 b) internal pure returns (uint256)
	{
		return a >= b ? a : b ;
	}

	function governanceRecoverUnsupported (IERC20 token, uint256 amount, address to) external onlyOperator
	{
		// Do not allow to drain core tokens
		require(address(token) != address(_digit), "Digit cannot be recovered") ;
		require(address(token) != address(_share), "DigiShare cannot be recovered") ;

		token.safeTransfer(to, amount) ;
	}
}
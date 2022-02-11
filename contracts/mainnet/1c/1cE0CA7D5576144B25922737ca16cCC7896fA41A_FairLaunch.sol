// SPDX-License-Identifier: UNLICENSED
/*

veDNA
*/
import "../AirDrop.sol";
import "../TimeLock.sol";
pragma solidity ^0.6.0;



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}


interface IFairLaunch {
    function poolLength() external view returns (uint256);

    function addPool(
        uint256 _allocPoint,
        address _stakeToken,
        uint256 _lock_day,
        bool _withUpdate
    ) external;

    function setPool(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _lock_time,
        bool _withUpdate
    ) external;

    function pendingVED(uint256 _pid, address _user) external view returns (uint256);

    function updatePool(uint256 _pid) external;

    function deposit(address _for, uint256 _pid, uint256 _amount) external;

    function withdraw(address _for, uint256 _pid, uint256 _amount) external;

    function withdrawAll(address _for, uint256 _pid) external;

    function harvest(uint256 _pid) external;
}

interface IVED {
    function mint(address recipient_, uint256 amount_) external returns (bool);
}

// FairLaunch is a smart contract for distributing VED by asking user to stake the ERC20-based token.
contract FairLaunch is IFairLaunch, Ownable ,ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 constant GLO_VAL = 1e12;
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant tokenManualMaxNum =  10**18 *150000000; //manual max limit 15%
    uint256 public  tokenManual =  0; //manual max limit
    AirDrop public air;
    TimeLock public lockReward;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many Staking tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 bonusDebt; // Last block that user exec something to the pool.
        address fundedBy; // Funded by who?
        uint256 start_timestamp;
        uint256 end_timestamp;
        //
        // We do some fancy math here. Basically, any point in time, the amount of VEDs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accVEDPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws Staking tokens to a pool. Here's what happens:
        //   1. The pool's `accVEDPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address stakeToken; // Address of Staking token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. VEDs to distribute per block.
        uint256 lastRewardBlock; // Last block number that VEDs distribution occurs.
        uint256 accVEDPerShare; // Accumulated VEDs per share, times 1e12. See below.
        uint256 accVEDPerShareTilBonusEnd; // Accumated VEDs per share until Bonus End.
        uint256 lock_time;
    }

    // The VED TOKEN!
    address public VED;
    // Dev address.
    address public devaddr;
    // VED tokens created per block.
    uint256 public VEDPerBlock;
    // Bonus muliplier for early VED makers.
    uint256 public bonusMultiplier;
    // Block number when bonus VED period ends.
    uint256 public bonusEndBlock;
    uint256 public refRate = 10;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes Staking tokens.

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => uint256[]) public pidList;
    mapping(uint256 => uint256) public pidBalance;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when VED mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetDevAddress(address indexed devAddr);
    event SetVEDPerBlock(uint256 indexed VEDPerBlock);
    event ManualMint(address indexed to, uint256 indexed amount);

        constructor(
            address _VED,
            address _devaddr,
            uint256 _VEDPerBlock,
            uint256 _startBlock,
            uint256 _bonusEndBlock,
            address _lockAddress,
            address _air

        ) public {
            bonusMultiplier = 0;
            totalAllocPoint = 0;
            VED = _VED;
            devaddr = _devaddr;
            VEDPerBlock = _VEDPerBlock;
            bonusEndBlock = _bonusEndBlock;
            startBlock = _startBlock;
            air = AirDrop(_air);
            lockReward = TimeLock(_lockAddress);
        }

    // Update dev address by the previous dev.
    function setDev(address _devaddr) public onlyOwner {
        require(_devaddr != address(0));
        devaddr = _devaddr;
        emit SetDevAddress(_devaddr);
    }

    function setVEDPerBlock(uint256 _VEDPerBlock) public onlyOwner {
        VEDPerBlock = _VEDPerBlock;
        emit SetVEDPerBlock(_VEDPerBlock);
    }
    function setRefRate(uint256 _refRate) public onlyOwner {
        require(_refRate <=10, "too big");
        refRate = _refRate;
    }

    // Set Bonus params. bonus will start to accu on the next block that this function executed
    // See the calculation and counting in test file.
    function setBonus(
        uint256 _bonusMultiplier,
        uint256 _bonusEndBlock
    ) public onlyOwner {
        require(_bonusEndBlock > block.number, "setBonus: bad bonusEndBlock");
        require(_bonusMultiplier > 1, "setBonus: bad bonusMultiplier");
        bonusMultiplier = _bonusMultiplier;
        bonusEndBlock = _bonusEndBlock;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function addPool(
        uint256 _allocPoint,
        address _stakeToken,
        uint256 _lock_day,
        bool _withUpdate
    ) public override onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        require(_stakeToken != address(0), "add: not stakeToken addr");
        require(!isDuplicatedPool(_stakeToken, _lock_day), "add: stakeToken dup");
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
        stakeToken : _stakeToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accVEDPerShare : 0,
        lock_time : _lock_day,
        accVEDPerShareTilBonusEnd : 0
        })
        );
    }

    // Update the given pool's VED allocation point. Can only be called by the owner.
    function setPool(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _lock_time,
        bool _withUpdate
    ) public override onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].lock_time = _lock_time;
    }

    function isDuplicatedPool(address _stakeToken, uint256 _lock_time) public view returns (bool) {
        uint256 length = poolInfo.length;
        for (uint256 _pid = 0; _pid < length; _pid++) {
            if (poolInfo[_pid].stakeToken == _stakeToken && poolInfo[_pid].lock_time == _lock_time) return true;
        }
        return false;
    }

    function poolLength() external override view returns (uint256) {
        return poolInfo.length;
    }

    function getPidList(address _account) external view returns (uint256[] memory) {
        uint256[] memory lst = pidList[_account];
        return lst;
    }




    function getBalanceByPid(uint256 pid, address _account) external view returns (uint256, uint256) {

        UserInfo memory user = userInfo[pid][_account];
        return (user.amount, user.rewardDebt);
    }


  //  function getUserInfoByPid(uint256 pid, address _account) external view returns (UserInfo memory) {
   //     UserInfo memory user = userInfo[pid][_account];
   //     return user;
   // }

    function manualMint(address _to, uint256 _amount) public onlyOwner {

        if(tokenManual>=tokenManualMaxNum)//manual max limit
        {
            return;
        }

        if(tokenManual.add(_amount)>tokenManualMaxNum && tokenManual<tokenManualMaxNum)
        {
            _amount = tokenManualMaxNum.sub(tokenManual);
        }//max limit
        tokenManual = tokenManual.add(_amount);//manual max limit--

        IVED(address(VED)).mint(_to, _amount);
        emit ManualMint(_to, _amount);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _lastRewardBlock, uint256 _currentBlock) public view returns (uint256) {
        require(_lastRewardBlock <= _currentBlock, "Block range exceeded！");
        if (_currentBlock <= bonusEndBlock) {
            return _currentBlock.sub(_lastRewardBlock).mul(bonusMultiplier);
        }
        if (_lastRewardBlock >= bonusEndBlock) {
            return _currentBlock.sub(_lastRewardBlock);
        }
        // This is the case where bonusEndBlock is in the middle of _lastRewardBlock and _currentBlock block.
        return bonusEndBlock.sub(_lastRewardBlock).mul(bonusMultiplier).add(_currentBlock.sub(bonusEndBlock));
    }

    // View function to see pending VEDs on frontend.
    function pendingVED(uint256 _pid, address _user) external override view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accVEDPerShare = pool.accVEDPerShare;
        uint256 lpSupply = IERC20(pool.stakeToken).balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 VEDReward = multiplier.mul(VEDPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accVEDPerShare = accVEDPerShare.add(VEDReward.mul(GLO_VAL).div(lpSupply));
        }
        return user.amount.mul(accVEDPerShare).div(GLO_VAL).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public override {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = IERC20(pool.stakeToken).balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        uint256 VEDReward = multiplier.mul(VEDPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        IVED(VED).mint(devaddr, VEDReward.mul(135).div(1000));
        IVED(VED).mint(address(this), VEDReward);
        pool.accVEDPerShare = pool.accVEDPerShare.add(VEDReward.mul(GLO_VAL).div(lpSupply));

        // update accVEDPerShareTilBonusEnd
        if (block.number <= bonusEndBlock) {
            pool.accVEDPerShareTilBonusEnd = pool.accVEDPerShare;
        }
        if (block.number > bonusEndBlock && pool.lastRewardBlock < bonusEndBlock) {
            uint256 VEDBonusPortion = bonusEndBlock.sub(pool.lastRewardBlock).mul(bonusMultiplier).mul(VEDPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            pool.accVEDPerShareTilBonusEnd = pool.accVEDPerShareTilBonusEnd.add(VEDBonusPortion.mul(GLO_VAL).div(lpSupply));
        }
        pool.lastRewardBlock = block.number;
    }


    // Deposit Staking tokens to FairLaunchToken for VED allocation.
    function deposit(address _for, uint256 _pid, uint256 _amount) nonReentrant public override {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_for];
        if (user.fundedBy != address(0)) require(user.fundedBy == msg.sender, "bad sof");
        require(pool.stakeToken != address(0), "deposit: not accept deposit");
        updatePool(_pid);
        if (user.amount > 0) _harvest(_for, _pid);
        if (user.fundedBy == address(0)) user.fundedBy = msg.sender;
        IERC20(pool.stakeToken).safeTransferFrom(address(msg.sender), address(this), _amount);
        pidList[_for].push(_pid);
        pidBalance[_pid] = pidBalance[_pid].add(_amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accVEDPerShare).div(GLO_VAL);
        user.bonusDebt = user.amount.mul(pool.accVEDPerShareTilBonusEnd).div(GLO_VAL);
        emit Deposit(msg.sender, _pid, _amount);
    }


    function withdrawAmount(address _for, uint256 _pid) public view returns (uint256) {
        if (_for == address(0)) {
            _for = msg.sender;
        }
        //PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_for];

        return user.amount;
    }

    // Withdraw Staking tokens from FairLaunchToken.
    function withdraw(address _for, uint256 _pid, uint256 _amount) nonReentrant public override {
        _withdraw(_for, _pid, _amount);
    }

    function withdrawAll(address _for, uint256 _pid) nonReentrant public override {
      _withdraw(_for, _pid, userInfo[_pid][_for].amount);
    }

    function _withdraw(address _for, uint256 _pid, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_for];
        require(user.fundedBy == msg.sender, "only funder");
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        _harvest(_for, _pid);
        user.amount = user.amount.sub(_amount);

        user.rewardDebt = user.amount.mul(pool.accVEDPerShare).div(GLO_VAL);
        user.bonusDebt = user.amount.mul(pool.accVEDPerShareTilBonusEnd).div(GLO_VAL);
        if (pool.stakeToken != address(0)) {
            IERC20(pool.stakeToken).safeTransfer(address(msg.sender), _amount);
            pidBalance[_pid] = pidBalance[_pid].sub(_amount);

        }
        emit Withdraw(msg.sender, _pid, user.amount);
    }

    // Harvest VEDs earn from the pool.
    function harvest(uint256 _pid) nonReentrant public override {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        _harvest(msg.sender, _pid);
        user.rewardDebt = user.amount.mul(pool.accVEDPerShare).div(GLO_VAL);
        user.bonusDebt = user.amount.mul(pool.accVEDPerShareTilBonusEnd).div(GLO_VAL);
    }



    function harvestStake(uint256 _pid) nonReentrant public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        _harvest(msg.sender, _pid);
        user.rewardDebt = user.amount.mul(pool.accVEDPerShare).div(GLO_VAL);
        user.bonusDebt = user.amount.mul(pool.accVEDPerShareTilBonusEnd).div(GLO_VAL);
    }

    function _harvest(address _to, uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_to];
        require(user.amount > 0, "nothing to harvest");
        uint256 pending = user.amount.mul(pool.accVEDPerShare).div(GLO_VAL).sub(user.rewardDebt);

        uint256 bal = IERC20(VED).balanceOf(address(this));
        if(bal<pending)
             pending = bal;
        if(pending == 0) return;

       // require(pending <= IERC20(VED).balanceOf(address(this)), "wtf not enough VED");
        // safeVEDTransfer(_to, pending);
        address one;
        address two;
        address three;
        uint256 transAmount = pending.mul(refRate.mul(3)).div(100);
        (one, two, three,) = air.getUppers(_to);
        if (one == address(0)) {//burn
            transAmount = transAmount.sub(pending.mul(refRate).div(100));
            IERC20(VED).transfer(burnAddress, pending.mul(refRate).div(100));
        }
        if (two == address(0)) {//burn
            transAmount = transAmount.sub(pending.mul(refRate).div(100));
            IERC20(VED).transfer(burnAddress, pending.mul(refRate).div(100));
        }
        if (three == address(0)) {//burn
            transAmount = transAmount.sub(pending.mul(refRate).div(100));
            IERC20(VED).transfer(burnAddress, pending.mul(refRate).div(100));
        }
        if (transAmount > 0) {
            IERC20(VED).transfer(address(air), transAmount);
            air.setUpperReward(pending.mul(refRate).div(100), _to);
        }

        uint256 userRate = 100;
        userRate = userRate.sub(refRate.mul(3));
        safeVEDTransfer(_to, pending.mul(userRate).div(100));
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid) nonReentrant public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    uint256 amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;
    IERC20(pool.stakeToken).safeTransfer(address(msg.sender), amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
  }

    // Safe VED transfer function, just in case if rounding error causes pool to not have enough VEDs.
    function safeVEDTransfer(address _to, uint256 _amount) internal {
        uint256 VEDBal = IERC20(VED).balanceOf(address(this));
        if (_amount > VEDBal) {
            //IERC20(VED).transfer(_to, VEDBal);
            IERC20(VED).approve(address(lockReward), VEDBal);
            lockReward.deposit(_to, VED, VEDBal);
        } else {
            //IERC20(VED).transfer(_to, _amount);
            IERC20(VED).approve(address(lockReward), _amount);
            lockReward.deposit(_to, VED, _amount);
        }
    }

    function getBlock() view external returns (uint256){
        return block.number;
    }
}
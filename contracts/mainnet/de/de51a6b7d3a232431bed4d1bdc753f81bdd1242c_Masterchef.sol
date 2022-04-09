// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Broom.sol";

// MasterChef is the master of BROOM. He can make Broom and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once BROOM is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Masterchef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 rewardLockedUp;  // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        //
        // We do some fancy math here. Basically, any point in time, the amount of BROOM
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBroomPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBroomPerShare` (and `lastRewardSecond`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool.
        uint256 lastRewardSecond;  // Last second that BROOMs distribution occurs.
        uint256 accBroomPerShare;   // Accumulated BROOMs per share, times 1e18. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 harvestInterval;  // Harvest interval in seconds
        uint256 lpSupply;
    }

    // The BROOM TOKEN!
    Broom public immutable broom;
    // Dev address.
    address public devaddr;
    // Deposit Fee address
    address public feeAddress;
    // Operator only allowed to set the Alloc Points
    address public _operator;
    // BROOM tokens created per second.
    uint256 public broomPerSecond;
    // Max harvest interval: 2 hours.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 7 days;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block timestamp when BROOM farming starts.
    uint256 public startTime;
    // Maximum BroomPerTime
    uint256 public MAX_EMISSION_RATE = 0.6 ether;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 broomPerSecond);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event addPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP, uint256 harvestInterval);
    event setPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP, uint256 harvestInterval);
    event UpdateStartTime(uint256 newStartTime);
    event BroomMintError(bytes reason);

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }
    constructor (
        Broom _broom,
        address _devaddr,
        address _feeAddress,
        uint256 _broomPerSecond,
        uint256 _startTime
    ) public {
        broom = _broom;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        broomPerSecond = _broomPerSecond;
        startTime = _startTime;
        _operator = _devaddr;
    } 

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }
    
    function blockTimestamp() external view returns (uint time) { // to assist with countdowns on site
        time = block.timestamp;
    }
    
    function userPoolLockup(uint _pid, address _user) external view returns (uint256 lock) {
        UserInfo storage user = userInfo[_pid][_user];
        lock = user.nextHarvestUntil <= block.timestamp ? 0 : user.nextHarvestUntil - block.timestamp;
    }
    
    function addInitialPools(IBEP20 _BROOMwFTMPair, IBEP20 _BROOMUSDCPair) external onlyOwner{
        require(poolInfo.length == 0, "addInitialPools: Initial Pools has already been added");
        add(40000, IBEP20(_BROOMUSDCPair), 0, 28800, false); // BROOM-USDC 0
        add(40000, IBEP20(_BROOMwFTMPair), 0, 28800, false); // BROOM-wFTM 1    
        add(5000, broom, 0, 28800, false); // BROOM solo staking 2

        add(1500, IBEP20(0x2b4C76d0dc16BE1C31D4C1DC53bF9B45987Fc75c), 400, 43200, false); // wFTM-USDC 3
        add(1500, IBEP20(0xf0702249F4D3A25cD3DED7859a165693685Ab577), 400, 43200, false); // wETH-wFTM 4
        add(1500, IBEP20(0xFdef392aDc84607135C24ca45DE5452d77aa10DE), 400, 43200, false); // USDC-fUSDT 5
        add(1500, IBEP20(0xEc7178F4C41f346b2721907F5cF7628E388A7a58), 400, 43200, false); // BOO-wFTM 6
 
        add(1000, IBEP20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75), 400, 43200, false); // USDC solo staking 7
        add(1000, IBEP20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83), 400, 43200, false); // wFTM solo staking 8
        add(1000, IBEP20(0x049d68029688eAbF473097a2fC38ef61633A3C7A), 400, 43200, false); // fUSDT solo staking 9
        add(1000, IBEP20(0x74b23882a30290451A17c44f4F05243b6b58C76d), 400, 43200, false); // wETH solo staking 10
        add(1000, IBEP20(0x321162Cd933E2Be498Cd2267a90534A804051b11), 400, 43200, false); // wBTC solo staking 11
        add(1000, IBEP20(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E), 400, 43200, false); // DAI solo staking 12
        add(1000, IBEP20(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE), 400, 43200, false); // BOO solo staking 13
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, uint256 _harvestInterval, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        // valid BEP20 token
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        _lpToken.balanceOf(address(this));

        require(_depositFeeBP <= 400, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardSecond = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(
            PoolInfo({
                lpToken : _lpToken,
                allocPoint : _allocPoint,
                lastRewardSecond : lastRewardSecond,
                accBroomPerShare : 0,
                depositFeeBP : _depositFeeBP,
                harvestInterval: _harvestInterval,
                lpSupply: 0
            })
        );

        emit addPool(poolInfo.length - 1, address(_lpToken), _allocPoint, _depositFeeBP, _harvestInterval);
    }

    // Update the given pool's BROOM allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint256 _harvestInterval, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 400, "set: invalid deposit fee basis points");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "set: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval; // * 1 HOURS LEVATO

        emit setPool(_pid, address(poolInfo[_pid].lpToken), _allocPoint, _depositFeeBP, _harvestInterval);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending Brooms on frontend.
    function pendingBroom(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBroomPerShare = pool.accBroomPerShare;
        if (block.timestamp > pool.lastRewardSecond && pool.lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardSecond, block.timestamp);
            uint256 broomReward = multiplier.mul(broomPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
            if (broom.totalSupply().add(broomReward) > broom.maxSupply()) {
                broomReward = broom.maxSupply() - broom.totalSupply();
            }
            accBroomPerShare = accBroomPerShare.add(broomReward.mul(1e18).div(pool.lpSupply));
        }
        uint256 pending = user.amount.mul(accBroomPerShare).div(1e18).sub(user.rewardDebt);
        return pending.add(user.rewardLockedUp);
    }
    
    function canHarvest(uint256 _pid, address _user) internal view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardSecond) {
            return;
        }
        if (pool.lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardSecond = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardSecond, block.timestamp);
        uint256 broomReward = multiplier.mul(broomPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 devReward = broomReward/10;
        uint256 totalRewards = broom.totalSupply() + devReward + broomReward;

        if (totalRewards <= broom.maxSupply()) {
            // mint dev reward as normal as not at maxSupply
            broom.mint(devaddr, devReward);
        } else {
            // update broomReward to difference
            broomReward = broom.maxSupply() - broom.totalSupply();
        }

        if (broomReward != 0) {
            // only mint to MC and calculate and update accBroomPerShare if broomReward is non 0
            broom.mint(address(this), broomReward);
            pool.accBroomPerShare = pool.accBroomPerShare + (broomReward * 1e18 / pool.lpSupply);
        }
        pool.lastRewardSecond = block.timestamp;
    }
    
    // Deposit LP tokens to MasterChef for BROOM allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        payOrLockupPending(_pid);
        
        if (_amount > 0) {
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)) - balanceBefore;
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.lpSupply = pool.lpSupply.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
                pool.lpSupply = pool.lpSupply.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accBroomPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        payOrLockupPending(_pid);
        
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBroomPerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        if (pool.lpSupply >=  amount) {
            pool.lpSupply = pool.lpSupply.sub(amount);
        } else {
            pool.lpSupply = 0;
        }

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }
    
    function payOrLockupPending(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accBroomPerShare).div(1e18).sub(user.rewardDebt);
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
                
                safeBroomTransfer(msg.sender, totalRewards);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Safe test transfer function, just in case if rounding error causes pool to not have enough BROOMs.
    function safeBroomTransfer(address _to, uint256 _amount) internal {
        uint256 broomBal = broom.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > broomBal) {
            transferSuccess = broom.transfer(_to, broomBal);
        } else {
            transferSuccess = broom.transfer(_to, _amount);
        }
        require(transferSuccess, "safeBroomTransfer: transfer failed");
    }

    // Update dev address.
    function setDevAddress(address _devaddr) external {
        require(msg.sender == devaddr, "dev: wut?");
        require(_devaddr != address(0), "!nonzero");

        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setFeeAddress(address _feeAddress) external {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "!nonzero");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    // Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _broomPerSecond) external onlyOwner {
        require(_broomPerSecond <= MAX_EMISSION_RATE, "Emmision Rate must no exceed max emission rate");
        massUpdatePools();
        broomPerSecond = _broomPerSecond;
        emit UpdateEmissionRate(msg.sender, _broomPerSecond);
    }

    // Only update before start of farm
    function updateStartTime(uint256 _newStartTime) external onlyOwner {
        require(block.timestamp < startTime, "cannot change start time if farm has already started");
        require(block.timestamp < _newStartTime, "cannot set start time in the past");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardSecond = _newStartTime;
        }
        startTime = _newStartTime;

        emit UpdateStartTime(startTime);
    }
}
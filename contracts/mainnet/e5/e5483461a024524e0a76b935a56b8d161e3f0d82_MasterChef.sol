// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Haunt.sol";

// MasterChef is the master of HAUNTS. He can make Haunts and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once HAUNTS is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of HAUNTS
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accHauntsPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accHauntsPerShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. HAUNTS to distribute per second.
        uint256 lastRewardTimestamp;  // Last timestamp that HAUNTS distribution occurs.
        uint256 accHauntsPerShare;   // Accumulated HAUNTS per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 lpSupply;
    }

    // The HAUNTS TOKEN!
    Haunt public haunts;
    // Dev address.
    address public devaddr;
    // HAUNTS tokens created per second.
    uint256 public hauntsPerSec;
    // Deposit Fee address
    address public feeAddress1;
    address public feeAddress2;
    address public feeAddress3;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The timestamp when Haunts mining starts.
    uint256 public startTimestamp = 1645639200;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress1(address indexed user, address indexed newAddress);
    event SetFeeAddress2(address indexed user, address indexed newAddress);
    event SetFeeAddress3(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 hauntsPerSec);
    event addPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP);
    event setPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP);

    constructor(
        Haunt _haunts,
        address _devaddr,
        address _feeAddress1,
        address _feeAddress2,
        address _feeAddress3,
        uint256 _hauntsPerSec
    ) public {
        haunts = _haunts;
        devaddr = _devaddr;
        feeAddress1 = _feeAddress1;
        feeAddress2 = _feeAddress2;
        feeAddress3 = _feeAddress3;
        hauntsPerSec = _hauntsPerSec;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner nonDuplicated(_lpToken) {
        // valid ERC20 token
        _lpToken.balanceOf(address(this));

        require(_depositFeeBP <= 240, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTimestamp  = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardTimestamp: lastRewardTimestamp,
            accHauntsPerShare : 0,
            depositFeeBP : _depositFeeBP,
            lpSupply: 0
        }));

        emit addPool(poolInfo.length - 1, address(_lpToken), _allocPoint, _depositFeeBP);
    }

    // Update the given pool's HAUNTS allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 240, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;

        emit setPool(_pid, address(poolInfo[_pid].lpToken), _allocPoint, _depositFeeBP);
    }

    // Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending HAUNTS on frontend.
    function pendingHaunts(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accHauntsPerShare = pool.accHauntsPerShare;
        if (block.timestamp  > pool.lastRewardTimestamp  && pool.lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
            uint256 hauntsReward = multiplier.mul(hauntsPerSec).mul(pool.allocPoint).div(totalAllocPoint);
            accHauntsPerShare = accHauntsPerShare.add(hauntsReward.mul(1e12).div(pool.lpSupply));
        }
        return user.amount.mul(accHauntsPerShare).div(1e12).sub(user.rewardDebt);
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
        if (block.timestamp  <= pool.lastRewardTimestamp) {
            return;
        }
        if (pool.lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTimestamp  = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
        uint256 hauntsReward = multiplier.mul(hauntsPerSec).mul(pool.allocPoint).div(totalAllocPoint);
        haunts.mint(devaddr, hauntsReward.div(10));
        haunts.mint(address(this), hauntsReward);
        pool.accHauntsPerShare = pool.accHauntsPerShare.add(hauntsReward.mul(1e12).div(pool.lpSupply));
        pool.lastRewardTimestamp = block.timestamp;
    }

    // Deposit LP tokens to MasterChef for HAUNTS allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accHauntsPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeHauntsTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)) - balanceBefore;
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress1, depositFee.div(3));
                pool.lpToken.safeTransfer(feeAddress2, depositFee.div(3));
                pool.lpToken.safeTransfer(feeAddress3, depositFee.div(3));
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.lpSupply = pool.lpSupply.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
                pool.lpSupply = pool.lpSupply.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accHauntsPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accHauntsPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeHauntsTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accHauntsPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        if (pool.lpSupply >=  amount) {
            pool.lpSupply = pool.lpSupply.sub(amount);
        } else {
            pool.lpSupply = 0;
        }

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe haunts transfer function, just in case if rounding error causes pool to not have enough HAUNTS.
    function safeHauntsTransfer(address _to, uint256 _amount) internal {
        uint256 hauntsBal = haunts.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > hauntsBal) {
            transferSuccess = haunts.transfer(_to, hauntsBal);
        } else {
            transferSuccess = haunts.transfer(_to, _amount);
        }
        require(transferSuccess, "safeHauntsTransfer: transfer failed");
    }

    // Update dev address.
    function setDevAddress(address _devaddr) external {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setFeeAddress1(address _feeAddress1) external {
        require(msg.sender == feeAddress1, "setFeeAddress1: FORBIDDEN");
        require(_feeAddress1 != address(0), "!nonzero");
        feeAddress1 = _feeAddress1;
        emit SetFeeAddress1(msg.sender, _feeAddress1);
    }

    function setFeeAddress2(address _feeAddress2) external {
        require(msg.sender == feeAddress2, "setFeeAddress2: FORBIDDEN");
        require(_feeAddress2 != address(0), "!nonzero");
        feeAddress2 = _feeAddress2;
        emit SetFeeAddress2(msg.sender, _feeAddress2);
    }

    function setFeeAddress3(address _feeAddress3) external {
        require(msg.sender == feeAddress3, "setFeeAddress3: FORBIDDEN");
        require(_feeAddress3 != address(0), "!nonzero");
        feeAddress3 = _feeAddress3;
        emit SetFeeAddress3(msg.sender, _feeAddress3);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _hauntsPerSec) external onlyOwner {
        massUpdatePools();
        hauntsPerSec = _hauntsPerSec;
        emit UpdateEmissionRate(msg.sender, _hauntsPerSec);
    }
}
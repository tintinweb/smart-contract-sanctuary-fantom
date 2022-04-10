// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Router02.sol";
import "./Natively.sol";

contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP ntly the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. NTLY to distribute per second.
        uint256 lastRewardTimestamp;  // Last timestamp that NTLY distribution occurs.
        uint256 accNtlyPerShare;   // Accumulated NTLY per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 lpSupply;
    }

    // The NTLY!
    NTLY public ntly;
    // Dev address.
    address public devaddr;
    // NTLY created per second.
    uint256 public ntlyPerSec;
    // Deposit Fee address
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP ntly.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The timestamp when Ntly mining starts.
    uint256 public startTimestamp;
    // The maximum supply for NTLY
    uint256 public maxSupply = 43000 ether;
    // Performance fee in basis points.
    uint256 pfee = 400;
    // Spookyswap router.
    IUniswapV2Router02 public router = IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event SetOperatorAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 ntlyPerSec);
    event addPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint16 depositFeeBP);
    event setPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint16 depositFeeBP);
    event UpdateMaxSupply(uint256 newMaxSupply);
    event UpdateStartTime(uint256 newStartTime);

    constructor (
        NTLY _ntly,
        address _devaddr,
        address _feeAddress,
        uint256 _ntlyPerSec,
        uint256 _startTimestamp
    ) public {
        ntly = _ntly;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        ntlyPerSec = _ntlyPerSec;
        startTimestamp = _startTimestamp;
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
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        // valid ERC20 token
        _lpToken.balanceOf(address(this));

        require(_depositFeeBP <= 0, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardTimestamp: lastRewardTimestamp,
            accNtlyPerShare : 0,
            depositFeeBP : _depositFeeBP,
            lpSupply: 0
        }));

        emit addPool(poolInfo.length - 1, address(_lpToken), _allocPoint, _depositFeeBP);
    }

    // Update the given pool's NTLY allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 0, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;

        emit setPool(_pid, address(poolInfo[_pid].lpToken), _allocPoint, _depositFeeBP);
    }

    // Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (ntly.totalSupply() >= maxSupply) {
            return 0;
        }
        return _to.sub(_from);
    }

    // View function to see pending NTLY on frontend.
    function pendingNtly(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accNtlyPerShare = pool.accNtlyPerShare;
        if (block.timestamp > pool.lastRewardTimestamp && pool.lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
            uint256 ntlyReward = multiplier.mul(ntlyPerSec).mul(pool.allocPoint).div(totalAllocPoint);
            accNtlyPerShare = accNtlyPerShare.add(ntlyReward.mul(1e12).div(pool.lpSupply));
        }
        return user.amount.mul(accNtlyPerShare).div(1e12).sub(user.rewardDebt);
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
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        if (pool.lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
        uint256 ntlyReward = multiplier.mul(ntlyPerSec).mul(pool.allocPoint).div(totalAllocPoint);
        // add condition for max supply
        if (ntly.totalSupply().add(ntlyReward) > maxSupply) {
            ntlyReward = maxSupply.sub(ntly.totalSupply());
        }
        ntly.mint(devaddr, ntlyReward.div(10));
        ntly.mint(address(this), ntlyReward);
        pool.accNtlyPerShare = pool.accNtlyPerShare.add(ntlyReward.mul(1e12).div(pool.lpSupply));
        pool.lastRewardTimestamp = block.timestamp;
    }

    function setup() external onlyOwner {
        ntly.approve(address(router), uint256(-1));
    }

    function handlePending(address _sender, uint256 _pending) internal {
        address[] memory route = new address[](2);
        route[0] = address(ntly);
        route[1] = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;// USDC
        uint256 fee = _pending.mul(pfee).div(10000);
        router.swapExactTokensForTokens(fee, 0, route, feeAddress, now);
        safeNtlyTransfer(_sender, _pending.sub(fee));
    }

    // Deposit LP ntly to MasterChef for NTLY allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accNtlyPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                handlePending(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)) - balanceBefore;
            user.amount = user.amount.add(_amount);
            pool.lpSupply = pool.lpSupply.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accNtlyPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP ntly from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accNtlyPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            handlePending(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accNtlyPerShare).div(1e12);
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

        if (pool.lpSupply >= amount) {
            pool.lpSupply = pool.lpSupply.sub(amount);
        } else {
            pool.lpSupply = 0;
        }

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe ntly transfer function, just in case if rounding error causes pool to not have enough NTLY.
    function safeNtlyTransfer(address _to, uint256 _amount) internal {
        uint256 ntlyBal = ntly.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > ntlyBal) {
            transferSuccess = ntly.transfer(_to, ntlyBal);
        } else {
            transferSuccess = ntly.transfer(_to, _amount);
        }
        require(transferSuccess, "safeNtlyTransfer: transfer failed");
    }

    // Update dev address.
    function setDevAddress(address _devaddr) external {
        require(msg.sender == devaddr, "setDevAddress: FORBIDDEN");
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

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _ntlyPerSec) external onlyOwner {
        massUpdatePools();
        ntlyPerSec = _ntlyPerSec;
        emit UpdateEmissionRate(msg.sender, _ntlyPerSec);
    }

    function updateMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        require(ntly.totalSupply() < maxSupply, "cannot change max supply if max supply has already been reached");
        maxSupply = _newMaxSupply;
        emit UpdateMaxSupply(maxSupply);
    }

    // Only update before start of farm
    function updateStartTime(uint256 _newStartTime) external onlyOwner {
        require(block.timestamp < startTimestamp, "cannot change start time if farm has already started");
        require(block.timestamp < _newStartTime, "cannot set start time in the past");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardTimestamp = _newStartTime;
        }
        startTimestamp = _newStartTime;

        emit UpdateStartTime(startTimestamp);
    }

    function addInitialPools(IBEP20 _USDCPair, IBEP20 _WFTMPair) external onlyOwner {
        require(poolInfo.length == 0, "addInitialPools: Initial Pools has already been added");

        add(10000, IBEP20(_USDCPair), 0, false); // NTLY-USDC
        add(10000, IBEP20(_WFTMPair), 0, false); // NTLY-WFTM
        add(2000, ntly, 0, false); // NTLY

        add(0, IBEP20(0x2b4C76d0dc16BE1C31D4C1DC53bF9B45987Fc75c), 0, false); // wFTM-USDC
        add(0, IBEP20(0xf0702249F4D3A25cD3DED7859a165693685Ab577), 0, false); // wETH-wFTM
    }
}
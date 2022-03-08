// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ASSF.sol";

contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP assassins the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. ASSASSINS to distribute per second.
        uint256 lastRewardTimestamp;  // Last timestamp that ASSASSINS distribution occurs.
        uint256 accAssassinsPerShare;   // Accumulated ASSASSINS per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 lpSupply;
    }

    // The ASSASSIN!
    ASSF public assassins;
    // Dev address.
    address public devaddr;
    // ASSASSINS assassins created per second.
    uint256 public assassinsPerSec;
    // Deposit Fee address
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP assassins.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The timestamp when Assassins mining starts.
    uint256 public startTimestamp;
    // The maximum supply for ASSASSIN
    uint256 public maxSupply = 1866 ether;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event SetAssassintorAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 assassinsPerSec);
    event addPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint16 depositFeeBP);
    event setPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint16 depositFeeBP);
    event UpdateMaxSupply(uint256 newMaxSupply);
    event UpdateStartTimestamp(uint256 newStartTimestamp);

    constructor (
        ASSF _assassins,
        address _devaddr,
        address _feeAddress,
        uint256 _assassinsPerSec,
        uint256 _startTimestamp
    ) public {
        assassins = _assassins;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        assassinsPerSec = _assassinsPerSec;
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

        require(_depositFeeBP <= 400, "add: invalid deposit fee basis points");
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
            accAssassinsPerShare : 0,
            depositFeeBP : _depositFeeBP,
            lpSupply: 0
        }));

        emit addPool(poolInfo.length - 1, address(_lpToken), _allocPoint, _depositFeeBP);
    }

    // Update the given pool's ASSASSINS allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 400, "set: invalid deposit fee basis points");
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
        if (assassins.totalSupply() >= maxSupply) {
            return 0;
        }
        return _to.sub(_from);
    }

    // View function to see pending ASSASSINS on frontend.
    function pendingAssassins(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accAssassinsPerShare = pool.accAssassinsPerShare;
        if (block.timestamp  > pool.lastRewardTimestamp  && pool.lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
            uint256 assassinsReward = multiplier.mul(assassinsPerSec).mul(pool.allocPoint).div(totalAllocPoint);
            accAssassinsPerShare = accAssassinsPerShare.add(assassinsReward.mul(1e12).div(pool.lpSupply));
        }
        return user.amount.mul(accAssassinsPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 assassinsReward = multiplier.mul(assassinsPerSec).mul(pool.allocPoint).div(totalAllocPoint);
        // add condition for max supply
        if (assassins.totalSupply().add(assassinsReward) > maxSupply) {
            assassinsReward = maxSupply.sub(assassins.totalSupply());
        }
        // assassins.mint(devaddr, assassinsReward.div(10));
        assassins.mint(address(this), assassinsReward);
        pool.accAssassinsPerShare = pool.accAssassinsPerShare.add(assassinsReward.mul(1e12).div(pool.lpSupply));
        pool.lastRewardTimestamp = block.timestamp;
    }

    // Deposit LP assassins to MasterChef for ASSASSINS allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accAssassinsPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeTokensTransfer(msg.sender, pending);
            }
        }
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
        user.rewardDebt = user.amount.mul(pool.accAssassinsPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP assassins from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accAssassinsPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeTokensTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accAssassinsPerShare).div(1e12);
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

    // Safe assassins transfer function, just in case if rounding error causes pool to not have enough ASSASSINS.
    function safeTokensTransfer(address _to, uint256 _amount) internal {
        uint256 assassinsBal = assassins.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > assassinsBal) {
            transferSuccess = assassins.transfer(_to, assassinsBal);
        } else {
            transferSuccess = assassins.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokensTransfer: transfer failed");
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
    function updateEmissionRate(uint256 _assassinsPerSec) external onlyOwner {
        massUpdatePools();
        assassinsPerSec = _assassinsPerSec;
        emit UpdateEmissionRate(msg.sender, _assassinsPerSec);
    }

    function updateMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        require(assassins.totalSupply() < maxSupply, "cannot change max supply if max supply has already been reached");
        maxSupply = _newMaxSupply;
        emit UpdateMaxSupply(maxSupply);
    }

    function addInitialPools() external onlyOwner {
        require(poolInfo.length == 0, "addInitialPools: Initial Pools has already been added");

        add(80000, IBEP20(0xEB241aC70Ff9dCe6fB4d86e1EC7DA60ad6db5d06), 0, false); // ASSASSIN-USDC
        add(20000, assassins, 0, false); // ASSASSIN

        add(1000, IBEP20(0x2b4C76d0dc16BE1C31D4C1DC53bF9B45987Fc75c), 300, false); // wFTM-USDC
        add(1000, IBEP20(0xf0702249F4D3A25cD3DED7859a165693685Ab577), 300, false); // wETH-wFTM
        add(1000, IBEP20(0xc19C7615237f770179ed93d89126478c60742664), 300, false); // MIM-USDC

        add(500, IBEP20(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE), 300, false); // BOO
        add(500, IBEP20(0xDDc0385169797937066bBd8EF409b5B3c0dFEB52), 300, false); // wMEMO
        add(500, IBEP20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83), 300, false); // wFTM
        add(500, IBEP20(0x82f0B8B456c1A451378467398982d4834b6829c1), 300, false); // MIM
        add(500, IBEP20(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E), 300, false); // DAI
        add(500, IBEP20(0x74b23882a30290451A17c44f4F05243b6b58C76d), 300, false); // wETH
        add(500, IBEP20(0x321162Cd933E2Be498Cd2267a90534A804051b11), 300, false); // wBTC
        add(500, IBEP20(0xD67de0e0a0Fd7b15dC8348Bb9BE742F3c5850454), 300, false); // wBNB
        add(500, IBEP20(0x468003B688943977e6130F4F68F23aad939a1040), 300, false); // SPELL
        add(500, IBEP20(0xf16e81dce15B08F326220742020379B855B87DF9), 300, false); // ICE
        add(500, IBEP20(0x29b0Da86e484E1C0029B56e817912d778aC0EC69), 300, false); // YFI
        add(500, IBEP20(0x9879aBDea01a879644185341F7aF7d8343556B7a), 300, false); // TUSD
        add(500, IBEP20(0x248CB87DDA803028dfeaD98101C9465A2fbdA0d4), 300, false); // CHARM         
    }

    // Only update before start of farm
    function updateStartTimestamp(uint256 _newStartTimestamp) external onlyOwner {
        require(block.timestamp < startTimestamp, "cannot change start timestamp if farm has already started");
        require(block.timestamp < _newStartTimestamp, "cannot set start timestamp in the past");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardTimestamp = _newStartTimestamp;
        }
        startTimestamp = _newStartTimestamp;

        emit UpdateStartTimestamp(startTimestamp);
    }
}
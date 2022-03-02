// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Blood.sol";

contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP bloods the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. BLOODS to distribute per second.
        uint256 lastRewardTimestamp;  // Last timestamp that BLOODS distribution occurs.
        uint256 accBloodsPerShare;   // Accumulated BLOODS per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 lpSupply;
    }

    // The BLOOD!
    BLOOD public bloods;
    // Dev address.
    address public devaddr;
    // Operator address.
    address public opaddr;
    // BLOODS bloods created per second.
    uint256 public bloodsPerSec;
    // Deposit Fee address
    address public feeAddress;
    address public feeAddress2;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP bloods.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The timestamp when Bloods mining starts.
    uint256 public startTimestamp;
    // The maximum supply for BLOOD
    uint256 public maxSupply = 33333 ether;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetFeeAddress2(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event SetOperatorAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 bloodsPerSec);
    event addPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint16 depositFeeBP);
    event setPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint16 depositFeeBP);
    event UpdateMaxSupply(uint256 newMaxSupply);

    constructor (
        BLOOD _bloods,
        address _devaddr,
        address _opaddr,
        address _feeAddress,
        address _feeAddress2,
        uint256 _bloodsPerSec,
        uint256 _startTimestamp
    ) public {
        bloods = _bloods;
        devaddr = _devaddr;
        opaddr = _opaddr;
        feeAddress = _feeAddress;
        feeAddress2 = _feeAddress2;
        bloodsPerSec = _bloodsPerSec;
        startTimestamp = _startTimestamp;
    }

    modifier onlyOperator() {
        require(opaddr == msg.sender, "operator: caller is not the operator");
        _;
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
            accBloodsPerShare : 0,
            depositFeeBP : _depositFeeBP,
            lpSupply: 0
        }));

        emit addPool(poolInfo.length - 1, address(_lpToken), _allocPoint, _depositFeeBP);
    }

    // Update the given pool's BLOODS allocation point and deposit fee. Can only be called by the owner.
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
        if (bloods.totalSupply() >= maxSupply) {
            return 0;
        }
        return _to.sub(_from);
    }

    // View function to see pending BLOODS on frontend.
    function pendingBloods(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBloodsPerShare = pool.accBloodsPerShare;
        if (block.timestamp  > pool.lastRewardTimestamp  && pool.lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
            uint256 bloodsReward = multiplier.mul(bloodsPerSec).mul(pool.allocPoint).div(totalAllocPoint);
            accBloodsPerShare = accBloodsPerShare.add(bloodsReward.mul(1e12).div(pool.lpSupply));
        }
        return user.amount.mul(accBloodsPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 bloodsReward = multiplier.mul(bloodsPerSec).mul(pool.allocPoint).div(totalAllocPoint);
        // add condition for max supply
        if (bloods.totalSupply().add(bloodsReward) > maxSupply) {
            bloodsReward = maxSupply.sub(bloods.totalSupply());
        }
        bloods.mint(devaddr, bloodsReward.div(10));
        bloods.mint(address(this), bloodsReward);
        pool.accBloodsPerShare = pool.accBloodsPerShare.add(bloodsReward.mul(1e12).div(pool.lpSupply));
        pool.lastRewardTimestamp = block.timestamp;
    }

    // Deposit LP bloods to MasterChef for BLOODS allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accBloodsPerShare).div(1e12).sub(user.rewardDebt);
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
                pool.lpToken.safeTransfer(feeAddress, depositFee.div(2));
                pool.lpToken.safeTransfer(feeAddress2, depositFee.div(2));
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.lpSupply = pool.lpSupply.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
                pool.lpSupply = pool.lpSupply.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accBloodsPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP bloods from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accBloodsPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeTokensTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBloodsPerShare).div(1e12);
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

    // Safe bloods transfer function, just in case if rounding error causes pool to not have enough BLOODS.
    function safeTokensTransfer(address _to, uint256 _amount) internal {
        uint256 bloodsBal = bloods.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > bloodsBal) {
            transferSuccess = bloods.transfer(_to, bloodsBal);
        } else {
            transferSuccess = bloods.transfer(_to, _amount);
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

    function setFeeAddress2(address _feeAddress2) external {
        require(msg.sender == feeAddress2, "setFeeAddress2: FORBIDDEN");
        require(_feeAddress2 != address(0), "!nonzero");
        feeAddress2 = _feeAddress2;
        emit SetFeeAddress2(msg.sender, _feeAddress2);
    }

    function setOperatorAddress(address _opaddr) external {
        require(msg.sender == opaddr, "setOperatorAddress: FORBIDDEN");
        require(_opaddr != address(0), "!nonzero");
        opaddr = _opaddr;
        emit SetOperatorAddress(msg.sender, _opaddr);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _bloodsPerSec) external onlyOwner {
        massUpdatePools();
        bloodsPerSec = _bloodsPerSec;
        emit UpdateEmissionRate(msg.sender, _bloodsPerSec);
    }

    function updateMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        require(bloods.totalSupply() < maxSupply, "cannot change max supply if max supply has already been reached");
        maxSupply = _newMaxSupply;
        emit UpdateMaxSupply(maxSupply);
    }

    function addInitialPools() external onlyOwner {
        require(poolInfo.length == 0, "addInitialPools: Initial Pools has already been added");

        add(65000, IBEP20(0xAB8f56e8c1E3bE779aa517a0DE3843BB324D932A), 0, false); // BLOOD-USDC
        add(6000, bloods, 0, false); // BLOOD

        add(1500, IBEP20(0x2b4C76d0dc16BE1C31D4C1DC53bF9B45987Fc75c), 400, false); // wFTM-USDC
        add(1500, IBEP20(0xf0702249F4D3A25cD3DED7859a165693685Ab577), 400, false); // wETH-wFTM
        add(1500, IBEP20(0xEc7178F4C41f346b2721907F5cF7628E388A7a58), 400, false); // BOO-wFTM
        add(1500, IBEP20(0xFdef392aDc84607135C24ca45DE5452d77aa10DE), 400, false); // USDC-fUSDT
        add(1500, IBEP20(0xEc454EdA10accdD66209C57aF8C12924556F3aBD), 400, false); // wETH-wBTC
        add(1500, IBEP20(0x5965E53aa80a0bcF1CD6dbDd72e6A9b2AA047410), 400, false); // wFTM-fUSDT
        add(1500, IBEP20(0xBe8da8C007c45e8136b99f14481388cB4d76f8F8), 400, false); // BOO-fUSDT
        add(1500, IBEP20(0xf8Cb2980120469d79958151daa45Eb937c6E1eD6), 400, false); // BOO-USDC

        add(1000, IBEP20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83), 400, false); // wFTM
        add(1000, IBEP20(0x74b23882a30290451A17c44f4F05243b6b58C76d), 400, false); // wETH
        add(1000, IBEP20(0x321162Cd933E2Be498Cd2267a90534A804051b11), 400, false); // wBTC
        add(1000, IBEP20(0xD67de0e0a0Fd7b15dC8348Bb9BE742F3c5850454), 400, false); // wBNB
        add(1000, IBEP20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75), 400, false); // USDC
        add(1000, IBEP20(0x049d68029688eAbF473097a2fC38ef61633A3C7A), 400, false); // fUSDT         
        add(1000, IBEP20(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E), 400, false); // DAI
        add(1000, IBEP20(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE), 400, false); // BOO
        add(1000, IBEP20(0xe0654C8e6fd4D733349ac7E09f6f23DA256bF475), 400, false); // SCREAM
        add(1000, IBEP20(0x5Cc61A78F164885776AA610fb0FE1257df78E59B), 400, false); // SPIRIT
        add(1000, IBEP20(0x29b0Da86e484E1C0029B56e817912d778aC0EC69), 400, false); // YFI
        add(1000, IBEP20(0xDDc0385169797937066bBd8EF409b5B3c0dFEB52), 400, false); // wMEMO
        add(1000, IBEP20(0xf16e81dce15B08F326220742020379B855B87DF9), 400, false); // ICE
        add(1000, IBEP20(0x82f0B8B456c1A451378467398982d4834b6829c1), 400, false); // MIM
        add(1000, IBEP20(0x468003B688943977e6130F4F68F23aad939a1040), 400, false); // SPELL
    }
}
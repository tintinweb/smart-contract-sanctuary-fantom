// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IVoter {
    function _ve() external view returns (address);
    function gauges(address) external view returns (address);
    function bribes(address) external view returns (address);
    function length() external view returns(uint256);
    function pools(uint) external view returns (address);
    function vote(uint tokenId, address[] calldata _poolVote, int256[] calldata _weights) external;
    function reset(uint _tokenId) external;
    function whitelist(address _token, uint _tokenId) external;
    function createGauge(address _pool) external returns (address);
}

interface IVeToken {
    function token() external view returns (address);
    function ownerOf(uint) external view returns (address);
    function create_lock(uint _value, uint _lock_duration) external returns (uint);
    function withdraw(uint _tokenId) external;
    function increase_amount(uint _tokenId, uint _value) external;
    function increase_unlock_time(uint _tokenId, uint _lock_duration) external;
    function merge(uint _from, uint _to) external;
    function locked(uint) external view returns (uint256, uint256);
    function safeTransferFrom(address from, address to, uint tokenId) external;
}

interface IGauge {
    function bribe() external view returns (address);
    function isReward(address) external view returns (bool);
    function getReward(address account, address[] memory tokens) external;
    function earned(address token, address account) external view returns (uint);
    function stake() external view returns (address);
    function deposit(uint amount, uint tokenId) external;
    function withdraw(uint amount) external; 
    function withdrawToken(uint amount, uint tokenId) external;
    function tokenIds(address owner) external view returns (uint256 tokenId);
}

interface IBribe {
    function isReward(address) external view returns (bool);
    function getReward(uint tokenId, address[] memory tokens) external;
    function earned(address token, uint tokenId) external view returns (uint);
}

// Tarot BoostMaxxer
contract BoostMaxxer is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeERC20 for IERC20;

    // Info of each pool.
    struct PoolInfo {
        address gauge; // Gauge address
        address bribe; // Bribe address
        uint256 totalDepositedAmount; // # of deposit tokens in this pool
        uint256 lastRewardTime;  // Last block time that reward distribution occurred.
    }

    // Info of each pool.
    mapping (address => PoolInfo) public getPoolInfo;
    // Info of each user that stakes tokens: lp -> user -> depositedAmount
    mapping (address => mapping (address => uint256)) public userDepositedAmountInfo;
    // Info of each reward token for a pool: lp -> accRewardPerShare
    mapping (address => uint256) public accRewardPerShareInfo;
    // lp -> user -> rewardDebt
    mapping (address => mapping (address => uint256)) public rewardDebtInfo;
    // feeBalance
    uint256 public feeBalance;

    uint256 public constant MAX_BPS = 10_000;
    uint256 public constant MIN_FEE_BPS = 0;
    uint256 public constant MAX_FEE_BPS = MAX_BPS / 2;

    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant MIN_DELAY = 2 days;
    uint256 public constant MAX_DELAY = 30 days;

    IVoter public voter;
    IVeToken public veToken;
    uint256 public veTokenId;

    IERC20 public immutable baseToken;

    address public feeTo;

    address public manager;

    address public admin;
    address public pendingAdmin;
    uint256 public pendingAdminNotBefore;

    uint256 public feeBps = (MAX_BPS * 15) / 100; // 15%

    event EmergencyWithdraw(address indexed user, address indexed _poolToken, uint256 amount);
    event UpdatePendingAdmin(address indexed admin, uint256 notBefore);
    event UpdateAdmin(address indexed admin);

    event UpdateFeeBps(uint256 _newFeeBps);
    event Deposit(address indexed user, address indexed poolToken, uint256 amount);
    event Withdraw(address indexed user, address indexed poolToken, uint256 amount, uint256 rewardAmount);

    event CreateLock(address indexed user, uint256 veTokenId, uint256 amount, uint256 unlockTime);
    event Release(address indexed user, uint256 veTokenId, uint256 amount, uint256 balanceAfter);
    event IncreaseTime(address indexed user, uint256 veTokenId, uint256 unlockTime);

    constructor(address _voter) {
        voter = IVoter(_voter);
        veToken = IVeToken(voter._ve());
        baseToken = IERC20(veToken.token());
    }

    function removeAdmin() external onlyOwner {
        admin = address(0);
        delete pendingAdmin;
        delete pendingAdminNotBefore;

        emit UpdateAdmin(admin);
    }

    function updatePendingAdmin(address _newPendingAdmin, uint256 _notBefore) external onlyOwner nonReentrant {
        if (_newPendingAdmin == address(0)) {
            require(_notBefore == 0, "BoostMaxxer: NOT_BEFORE");
        } else {
            require(_newPendingAdmin != admin, "BoostMaxxer: SAME_ADMIN");
            require(_notBefore >= block.timestamp + MIN_DELAY, "BoostMaxxer: TOO_SOON");
            require(_notBefore < block.timestamp + MAX_DELAY, "BoostMaxxer: TOO_LATE");
        }

        pendingAdmin = _newPendingAdmin;
        pendingAdminNotBefore = _notBefore;

        emit UpdatePendingAdmin(_newPendingAdmin, _notBefore);
    }

    function updateAdmin() external onlyOwner nonReentrant {
        require(pendingAdmin != address(0), "BoostMaxxer: INVLD_ADMIN");
        require(block.timestamp >= pendingAdminNotBefore, "BoostMaxxer: TOO_SOON");
        require(block.timestamp < pendingAdminNotBefore + GRACE_PERIOD, "BoostMaxxer: TOO_LATE");
        require(pendingAdmin != admin, "BoostMaxxer: SAME_ADMIN");

        admin = pendingAdmin;
        delete pendingAdmin;
        delete pendingAdminNotBefore;

        emit UpdateAdmin(admin);
    }

    function updateVeTokenId(uint256 _veTokenId) external onlyOwner {
        require(_veTokenId == 0 || veToken.ownerOf(_veTokenId) == address(this), "BoostMaxxer: INVLD_VE_TOKEN_ID");
        veTokenId = _veTokenId;
    }

    function updateManager(address _manager) external onlyOwner {
        manager = _manager;
    }

    function updateFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    function updateFeeBps(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps >= MIN_FEE_BPS && _newFeeBps <= MAX_FEE_BPS, "BoostMaxxer: INVLD_FEE");
        feeBps = _newFeeBps;

        emit UpdateFeeBps(_newFeeBps);
    }

    // View function to see pending rewards on frontend.
    function pendingRewards(address _user, address[] calldata _poolTokens)
        external view
        returns (uint256[] memory amounts) {
        amounts = new uint256[](_poolTokens.length);
        for (uint256 i = 0; i < _poolTokens.length; i++) {
            amounts[i] = pendingReward(_user, _poolTokens[i]);
        }
        return amounts;
    }

    // View function to see pending reward on frontend.
    function pendingReward(address _user, address _poolToken) public view returns (uint256 amount) {
        PoolInfo memory pool = getPoolInfo[_poolToken];
        if (pool.gauge == address(0)) {
            return 0;
        }
        uint256 userDepositedAmount = userDepositedAmountInfo[_poolToken][_user];
        uint256 netReward;
        netReward += IGauge(pool.gauge).earned(address(baseToken), address(this));
        uint256 accRewardPerShare = accRewardPerShareInfo[_poolToken];
        if (netReward > 0) {
            uint256 feeAmount = netReward * feeBps / MAX_BPS;
            uint256 rewardAmount = netReward - feeAmount;
            accRewardPerShare += rewardAmount * 1e18 / pool.totalDepositedAmount;
        }
        amount = 
            (userDepositedAmount * accRewardPerShare / 1e18) -
            rewardDebtInfo[_poolToken][_user];
    }

    function updatePool(address _poolToken) public {
        _updatePool(_poolToken);
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(address _poolToken) internal {
        PoolInfo storage pool = getPoolInfo[_poolToken];
        require(pool.gauge != address(0), "BoostMaxxer: NO_POOL");
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        if (pool.totalDepositedAmount == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        
        uint256 balanceBefore = baseToken.balanceOf(address(this));
        address[] memory tokens = new address[](1);
        tokens[0] = address(baseToken);
        IGauge(pool.gauge).getReward(address(this), tokens);
        uint256 balanceAfter = baseToken.balanceOf(address(this));
        if (balanceAfter > balanceBefore) {
            uint256 netReward = balanceAfter - balanceBefore;
            uint256 feeAmount = netReward * feeBps / MAX_BPS;
            feeBalance += feeAmount;
            netReward -= feeAmount;
            accRewardPerShareInfo[_poolToken] += netReward * 1e18 / pool.totalDepositedAmount;
        }
        
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit tokens.
    function deposit(address _poolToken, uint256 _amount) external nonReentrant {
        require(veTokenId > 0, "BoostMaxxer: INVLD_VE_TOKEN_ID");
        require(_amount > 0, "BoostMaxxer: ZERO_AMOUNT");

        address gauge = getPoolInfo[_poolToken].gauge;
        if (gauge == address(0)) {
            gauge = voter.gauges(_poolToken);
            if (gauge == address(0)) {
                gauge = voter.createGauge(_poolToken);
            }
            getPoolInfo[_poolToken].gauge = gauge;
            getPoolInfo[_poolToken].bribe = voter.bribes(gauge);
            getPoolInfo[_poolToken].lastRewardTime = block.timestamp;
        } else {
            _updatePool(_poolToken);
        }

        uint256 userDepositedAmount = userDepositedAmountInfo[_poolToken][msg.sender];        
        uint256 accRewardPerShare = accRewardPerShareInfo[_poolToken];
        uint256 amountToSend =
                (userDepositedAmount * accRewardPerShare / 1e18) -
                rewardDebtInfo[_poolToken][msg.sender];
        if (amountToSend > 0) {
            safeTransfer(baseToken, msg.sender, amountToSend);
        }
        rewardDebtInfo[_poolToken][msg.sender] =
            (userDepositedAmount + _amount) * accRewardPerShare / 1e18;
        

        userDepositedAmountInfo[_poolToken][msg.sender] = userDepositedAmount + _amount;
        getPoolInfo[_poolToken].totalDepositedAmount += _amount;

        IERC20(_poolToken).safeTransferFrom(address(msg.sender), address(this), _amount);
        // Stake in gauge
        IERC20(_poolToken).safeApprove(address(gauge), 0);
        IERC20(_poolToken).safeApprove(address(gauge), _amount);
        IGauge(gauge).deposit(_amount, veTokenId);

        emit Deposit(msg.sender, _poolToken, _amount);
    }

    // Withdraw tokens.
    function withdraw(address _poolToken, uint256 _amount)
        external
        nonReentrant
        returns (uint256 rewardAmount) {
        uint256 userDepositedAmount = userDepositedAmountInfo[_poolToken][msg.sender];

        require(userDepositedAmount >= _amount, "BoostMaxxer: INVLD_AMOUNT");
        if (_amount == 0 && getPoolInfo[_poolToken].gauge == address(0)) {
            return 0;
        }
        require(getPoolInfo[_poolToken].gauge != address(0), "BoostMaxxer: NO_POOL");

        _updatePool(_poolToken);

        uint256 accRewardPerShare = accRewardPerShareInfo[_poolToken];
        rewardAmount = 
            (userDepositedAmount * accRewardPerShare / 1e18) - 
            rewardDebtInfo[_poolToken][msg.sender];
        if (rewardAmount > 0) {
            safeTransfer(baseToken, msg.sender, rewardAmount);
        }
        rewardDebtInfo[_poolToken][msg.sender] = 
            (userDepositedAmount - _amount) * accRewardPerShare / 1e18;

        if (_amount > 0) {
            userDepositedAmountInfo[_poolToken][msg.sender] = userDepositedAmount - _amount;
            getPoolInfo[_poolToken].totalDepositedAmount -= _amount;

            // Unstake from gauge
            IGauge(getPoolInfo[_poolToken].gauge).withdraw(_amount);
            safeTransfer(IERC20(_poolToken), address(msg.sender), _amount);
        }

        emit Withdraw(msg.sender, _poolToken, _amount, rewardAmount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(address _poolToken) external nonReentrant {
        PoolInfo storage pool = getPoolInfo[_poolToken];
        require(pool.gauge != address(0), "BoostMaxxer: NO_POOL");
        uint256 withdrawAmount = userDepositedAmountInfo[_poolToken][msg.sender];
        
        pool.totalDepositedAmount -= withdrawAmount;
        userDepositedAmountInfo[_poolToken][msg.sender] = 0;
        rewardDebtInfo[_poolToken][msg.sender] = 0;

        // Unstake from gauge
        IGauge(pool.gauge).withdraw(withdrawAmount);

        safeTransfer(IERC20(_poolToken), address(msg.sender), withdrawAmount);

        emit EmergencyWithdraw(msg.sender, _poolToken, withdrawAmount);
    }

    function sendFees(address _poolToken, address[] calldata _gaugeRewards, address[] calldata _bribeRewards)
        public
        nonReentrant {
        require(feeTo != address(0), "BoostMaxxer: INVLD_FEE_TO");
        IGauge gauge = IGauge(getPoolInfo[_poolToken].gauge);
        require(address(gauge) != address(0), "BoostMaxxer: NO_POOL");

        _updatePool(_poolToken);

        if (_gaugeRewards.length > 0) {
            gauge.getReward(address(this), _gaugeRewards);
            for (uint256 i = 0; i < _gaugeRewards.length; i++) {
                IERC20 reward = IERC20(_gaugeRewards[i]);
                require(address(reward) != address(baseToken), "BoostMaxxer: BASE_TOKEN");
                uint256 rewardAmount = reward.balanceOf(address(this));
                if (rewardAmount > 0) {
                    safeTransfer(reward, address(feeTo), rewardAmount);
                }
            }
        }

        if (_bribeRewards.length > 0) {
            uint256 baseTokenBalanceBefore = baseToken.balanceOf(address(this));
            IBribe bribe = IBribe(getPoolInfo[_poolToken].bribe);
            bribe.getReward(veTokenId, _bribeRewards);
            for (uint256 i = 0; i < _bribeRewards.length; i++) {
                IERC20 reward = IERC20(_bribeRewards[i]);
                if (address(reward) == address(baseToken)) {
                    uint256 baseTokenBalanceAfter = baseToken.balanceOf(address(this));
                    if (baseTokenBalanceAfter > baseTokenBalanceBefore) {
                        feeBalance += baseTokenBalanceAfter - baseTokenBalanceBefore;
                    }
                } else {
                    uint256 rewardAmount = reward.balanceOf(address(this));
                    if (rewardAmount > 0) {
                        safeTransfer(reward, address(feeTo), rewardAmount);
                    }
                }
            }
        }

        if (feeBalance > 0) {
            uint256 feeBalanceToSend = feeBalance;
            feeBalance = 0;
            safeTransfer(baseToken, address(feeTo), feeBalanceToSend);
        }
    }

    function withdrawBaseToken(uint256 _amount) external onlyOwner nonReentrant {
        require(feeTo != address(0), "BoostMaxxer: INVLD_FEE_TO");
        require(_amount <= feeBalance, "BoostMaxxer: INSUFFICIENT_BALANCE");
        feeBalance -= _amount;
        safeTransfer(baseToken, address(feeTo), _amount);
    }

    function createLock(uint256 _amount, uint256 _lock_duration) external onlyOwner nonReentrant {
        require(veTokenId == 0, "BoostMaxxer: INVLD");
        require(_amount > 0, "BoostMaxxer: INVLD_AMOUNT");
        baseToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        baseToken.safeApprove(address(veToken), 0);
        baseToken.safeApprove(address(veToken), _amount);
        veTokenId = veToken.create_lock(_amount, _lock_duration);

        emit CreateLock(msg.sender, veTokenId, _amount, _lock_duration);
    }

    function release(uint256 _veTokenId) external onlyOwner nonReentrant {
        require(_veTokenId > 0 && veTokenId != _veTokenId, "BoostMaxxer: INVLD_VE_TOKEN_ID");
        uint256 baseTokenBalanceBefore = baseToken.balanceOf(address(this));
        veToken.withdraw(_veTokenId);
        uint256 baseTokenBalanceAfter = baseToken.balanceOf(address(this));
        uint256 releaseAmount = baseTokenBalanceAfter - baseTokenBalanceBefore;
        feeBalance += releaseAmount;
        emit Release(msg.sender, _veTokenId, releaseAmount, baseTokenBalanceAfter);
    }

    function increaseUnlockTime(uint256 _veTokenId, uint256 _lock_duration) external onlyOwnerOrManager nonReentrant {
        veToken.increase_unlock_time(_veTokenId, _lock_duration);
        emit IncreaseTime(msg.sender, _veTokenId, _lock_duration);
    }

    function vote(uint256 _veTokenId, address[] calldata _tokenVote, int256[] calldata _weights)
        external
        onlyOwnerOrManager {
        voter.vote(_veTokenId, _tokenVote, _weights);
    }

    function resetVote(uint256 _veTokenId) external onlyOwnerOrManager nonReentrant {
        voter.reset(_veTokenId);
    }

    function whitelist(address _token, uint256 _veTokenId) external onlyOwnerOrManager nonReentrant {
        voter.whitelist(_token, _veTokenId);
    }

    function withdrawVeTokenFromGauge(address _poolToken, uint256 _veTokenId) external onlyOwner nonReentrant {
        _updatePool(_poolToken);
        IGauge(getPoolInfo[_poolToken].gauge).withdrawToken(0, _veTokenId);
    }

    function transferVeToken(address _to, uint256 _veTokenId) external onlyOwner nonReentrant {
        if (veTokenId == _veTokenId) {
            veTokenId = 0;
        }
        veToken.safeTransferFrom(address(this), _to, _veTokenId);
    }

    // Safe erc20 transfer function, just in case if rounding error causes pool to not have enough reward tokens.
    function safeTransfer(IERC20 token, address _to, uint256 _amount) internal {
        uint256 bal = token.balanceOf(address(this));
        if (_amount > bal) {
            token.safeTransfer(_to, bal);
        } else {
            token.safeTransfer(_to, _amount);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external override view returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        require(msg.sender == address(veToken), "BoostMaxxer: NOT_VE");
        return bytes4(keccak256("onERC721Received(address,address,uint,bytes)"));
    }

    // Admin functions

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyAdmin returns (bool, bytes memory) {
        (bool success, bytes memory result) = to.call{value: value}(data);

        return (success, result);
    }

    modifier onlyOwnerOrManager() {
        require(msg.sender == owner() || msg.sender == manager, "BoostMaxxer: RESTRICTED");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "BoostMaxxer: ONLY_ADMIN");
        _;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
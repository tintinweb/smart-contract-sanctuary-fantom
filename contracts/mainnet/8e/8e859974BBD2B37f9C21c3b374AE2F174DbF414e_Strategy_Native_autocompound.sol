// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";

interface INativeFarm {

    function userInfo(uint256 pid, address user) external view returns (uint256, uint256);

    // Deposit LP tokens to the farm for farm's token allocation.
    function deposit(uint256 _pid, uint256 _amount) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;

    // Pending native reward
    function pendingNATIVE(uint256 _pid, address _user) external view returns (uint256);

    // View function to get staked want tokens
    function stakedWantTokens(uint256 _pid, address _user) external view returns (uint256);
}

contract Strategy_Native_autocompound is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 lastDepositTime; // keeps track of deposit time for potential penalty
        uint256 NATIVEAtLastUserAction; // keeps track of NATIVE deposited at the last user action
        uint256 lastUserActionTime; // keeps track of the last user action time
        uint256 rewardDebt; // outstanding reward debt to user
    }

    IERC20 public immutable token; // NATIVE token
    IERC20 public immutable rewardToken; // reward token

    INativeFarm public immutable nativeFarm;

    mapping(address => UserInfo) public userInfo;

    uint256 public totalShares;
    uint256 public lastHarvestedTime;
    uint256 public pid;
    address public admin;
    address public treasury;

    uint256 public constant MAX_PERFORMANCE_FEE = 500; // 5%
    uint256 public constant MAX_WITHDRAW_FEE = 100; // 1%

    uint256 public performanceFee = 200; // 2%
    uint256 public withdrawFee = 10; // 0.1%

    uint256 public immutable earlyWithdrawDuration;
    uint256 public earlyWithdrawFeeFactor = 500;
    uint256 public constant earlyWithdrawFeeFactorMax = 10000;
    uint256 public constant earlyWithdrawFeeFactorUL = 1000;

    uint256 public rewardPerSecond;

    event Deposit(address indexed user, uint256 amount, uint256 shares, uint256 lastDepositTime);
    event Withdraw(address indexed user, uint256 amount, uint256 shares);
    event Harvest(address indexed sender, uint256 performanceFee);
    event Pause();
    event Unpause();

    /**
     * @notice Constructor
     * @param _token: Native token contract
     * @param _nativeFarm: nativeFarm contract
     * @param _admin: address of the admin
     * @param _treasury: address of the treasury (collects fees)
     * @param _pid: pid of native strategy
     * @param _earlyWithdrawDuration: duration before early Withdraws incur withdraw fee
     * @param _rewardPerSecond: amount of rewardTokens rewarded to the pool each second
     */
    constructor(
        IERC20 _token,
        IERC20 _rewardToken,
        INativeFarm _nativeFarm,
        address _admin, 
        address _treasury,
        uint256 _pid,
        uint256 _earlyWithdrawDuration,
        uint256 _rewardPerSecond
    ) public {
        token = _token;
        rewardToken = _rewardToken;
        nativeFarm = _nativeFarm;
        admin = _admin;
        treasury = _treasury;
        pid = _pid;
        earlyWithdrawDuration = _earlyWithdrawDuration;
        rewardPerSecond = _rewardPerSecond;
        // Infinite approve
        IERC20(_token).safeApprove(address(_nativeFarm), uint256(-1));
    }

    /**
     * @notice Checks if the msg.sender is the admin address
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "admin: wut?");
        _;
    }

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /**
     * @notice Deposits funds into the NATIVE Vault
     * @dev Only possible when contract not paused.
     * @param _userAddress: address of the users to which tokens are attributed.
     * @param _amount: number of tokens to deposit (in NATIVE)
     */
    function deposit(address _userAddress, uint256 _amount) external whenNotPaused nonReentrant returns (uint256) {
        require(_amount > 0, "Nothing to deposit");

        claimReward(_userAddress);

        uint256 underlyingBalance = totalBalance();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 newShares = _amount;
        if (totalShares != 0) {
            newShares = _amount.mul(totalShares).div(underlyingBalance);
        }

        UserInfo storage user = userInfo[_userAddress];

        user.shares = user.shares.add(newShares);
        user.lastDepositTime = block.timestamp;

        totalShares = totalShares.add(newShares);

        user.NATIVEAtLastUserAction = totalUserBalance(_userAddress);

        _farm();

        emit Deposit(_userAddress, _amount, newShares, block.timestamp);

        return user.NATIVEAtLastUserAction;
    }

    /**
     * @notice Withdraws from funds from the NATIVE Vault
     * @param _wantAmt: Number of shares to withdraw
     */
    function withdraw(uint256 _wantAmt) public {
        require(_wantAmt > 0, "_wantAmt <= 0");

        UserInfo storage user = userInfo[msg.sender];
        uint256 _shares = _wantAmt.mul(totalShares).div(totalBalance());

        if (_shares > user.shares)
            _shares = user.shares;

        require(_shares > 0, "Nothing to withdraw");
        require(totalShares > 0, "totalShares is 0");

        claimReward(msg.sender);

        uint256 withdrawAmt = (totalBalance().mul(_shares)).div(totalShares);
        user.shares = user.shares.sub(_shares);
        totalShares = totalShares.sub(_shares);

        uint256 bal = balanceOf();
        if (bal < withdrawAmt) {
            uint256 balWithdraw = withdrawAmt.sub(bal);
            INativeFarm(nativeFarm).withdraw(pid, balWithdraw);
            uint256 balAfter = balanceOf();
            if (balAfter < withdrawAmt) {
                withdrawAmt = balAfter;
            }
        }

        uint256 earlyWithdrawFee = earlyWithdrawalFee(withdrawAmt, user.lastDepositTime);
        withdrawAmt = withdrawAmt.sub(earlyWithdrawFee);

        uint256 currentWithdrawFee = withdrawAmt.mul(withdrawFee).div(10000);
        withdrawAmt = withdrawAmt.sub(currentWithdrawFee);

        token.safeTransfer(treasury, currentWithdrawFee + earlyWithdrawFee);
        token.safeTransfer(msg.sender, withdrawAmt);

        if (user.shares > 0) {
            user.NATIVEAtLastUserAction = totalUserBalance(msg.sender);
        } else {
            user.NATIVEAtLastUserAction = 0;
        }

        emit Withdraw(msg.sender, withdrawAmt, _shares);
    }

    /**
     * @notice Withdraws all funds for a user
     */
    function withdrawAll() external notContract {
        withdraw(totalUserBalance(msg.sender));
    }


    /**
     * @notice Deposits tokens into nativeFarm to earn staking rewards
     */
    function _farm() internal {
        uint256 bal = balanceOf();
        if (bal > 0) {
            INativeFarm(nativeFarm).deposit(pid, bal);
        }
    }

    /**
     * @notice Reinvests NATIVE tokens into nativeFarm
     * @dev Only possible when contract not paused.
     */
    function harvest() external notContract whenNotPaused {
        INativeFarm(nativeFarm).withdraw(pid, 0);

        uint256 bal = balanceOf();
        uint256 currentPerformanceFee = bal.mul(performanceFee).div(10000);
        token.safeTransfer(treasury, currentPerformanceFee);

        _farm();

        lastHarvestedTime = block.timestamp;

        emit Harvest(msg.sender, currentPerformanceFee);
    }

    /**
     * @notice Claim rewards if available
     */
    function claimReward(address _userAddress) public {
        UserInfo storage user = userInfo[_userAddress];
        if (block.timestamp > user.lastUserActionTime && user.shares > 0) {
            uint256 rewardBalance = rewardToken.balanceOf(address(this));
            uint256 rewardAmt = block.timestamp.sub(user.lastUserActionTime).mul(rewardPerSecond).mul(user.shares).div(totalShares);
            if (rewardBalance > 0) {
                uint256 totalRewardAmt = rewardAmt + user.rewardDebt;
                user.lastUserActionTime = block.timestamp;
                if (rewardBalance >= totalRewardAmt) {
                    user.rewardDebt = 0;
                } else {
                    user.rewardDebt = totalRewardAmt - rewardBalance;
                    totalRewardAmt = rewardBalance;
                }
                rewardToken.safeTransfer(msg.sender, totalRewardAmt);
            } else {
                user.rewardDebt = user.rewardDebt + rewardAmt;
            }
        }
    }

    /**
     * @notice Sets admin address
     * @dev Only callable by the contract owner.
     */
    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;
    }

    /**
     * @notice Sets treasury address
     * @dev Only callable by the contract owner.
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Cannot be zero address");
        treasury = _treasury;
    }

    /**
     * @notice Sets performance fee
     * @dev Only callable by the contract admin.
     */
    function setPerformanceFee(uint256 _performanceFee) external onlyAdmin {
        require(_performanceFee <= MAX_PERFORMANCE_FEE, "performanceFee cannot be more than MAX_PERFORMANCE_FEE");
        performanceFee = _performanceFee;
    }

    /**
     * @notice Sets withdraw fee
     * @dev Only callable by the contract admin.
     */
    function setWithdrawFee(uint256 _withdrawFee) external onlyAdmin {
        require(_withdrawFee <= MAX_WITHDRAW_FEE, "withdrawFee cannot be more than MAX_WITHDRAW_FEE");
        withdrawFee = _withdrawFee;
    }

    function setEarlyWithdrawFeeFactor(uint256 _earlyWithdrawFeeFactor) public onlyAdmin {
        require(_earlyWithdrawFeeFactor <= earlyWithdrawFeeFactorUL, "too high");
        earlyWithdrawFeeFactor = _earlyWithdrawFeeFactor;
    }

    /**
     * @notice Withdraws from nativeFarm to Vault without caring about rewards.
     * @dev EMERGENCY ONLY. Only callable by the contract admin.
     */
    function emergencyWithdraw() external onlyAdmin {
        INativeFarm(nativeFarm).emergencyWithdraw(pid);
    }

    /**
     * @notice Withdraw unexpected tokens sent to the NATIVE Vault
     */
    function inCaseTokensGetStuck(address _token) external onlyAdmin {
        require(_token != address(token), "Token cannot be same as deposit token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyAdmin whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyAdmin whenPaused {
        _unpause();
        emit Unpause();
    }

    /**
     * @notice Calculates the pending rewards that can be restaked
     * @return Returns pending NATIVE rewards
     */
    function pendingNATIVERewards() public view returns (uint256) {
        return INativeFarm(nativeFarm).pendingNATIVE(pid, address(this));
    }

    /**
     * @notice Calculates the price per share
     */
    function getPricePerFullShare() external view returns (uint256) {
        return totalShares == 0 ? 1e18 : totalBalance().mul(1e18).div(totalShares);
    }

    function earlyWithdrawalFee(uint amount, uint depositAt) internal view returns (uint256) {
        if (earlyWithdrawFeeFactor > 0 && depositAt.add(earlyWithdrawDuration) > block.timestamp)
            return amount.mul(earlyWithdrawFeeFactor).div(earlyWithdrawFeeFactorMax);
        return 0;
    }

    /**
     * @notice Custom logic for how much the vault allows to be borrowed
     * @dev The contract puts 100% of the tokens to work.
     */
    function balanceOf() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Calculates the total underlying tokens
     * @dev It includes tokens held by the contract and held in nativeFarm
     */
    function totalBalance() public view returns (uint256) {
        uint256 stakedAmount = INativeFarm(nativeFarm).stakedWantTokens(pid, address(this));
        return balanceOf().add(stakedAmount).add(pendingNATIVERewards());
    }

    /**
     * @notice Calculates the total user's underlying tokens
     * @dev It includes tokens held by the contract and held in nativeFarm
     */
    function totalUserBalance(address _user) public view returns (uint256) {
        return totalBalance().mul(userInfo[_user].shares).div(totalShares);
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}
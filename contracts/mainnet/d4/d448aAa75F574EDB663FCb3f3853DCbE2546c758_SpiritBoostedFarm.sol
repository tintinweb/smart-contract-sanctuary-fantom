pragma solidity ^0.6.7;

import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

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

    constructor () public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

interface IGauge {
    function derivedBalances(address account) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function rewards(address account) external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function TOKEN() external view returns (address);
}

interface IDepositor {
    function deposit(address _gauge, address _underlying) external;
    function withdraw(address _gauge, address _underlying, uint256 _amount) external;
    function claimGaugeReward(address _gauge) external;
}

contract SpiritBoostedFarm is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice the address that holds our inSPIRIT (ie. strategy proxy) and the one that would deposit the LPs in the gauges
    address public constant DEPOSITOR = address(0x099EA71e5B0C7E350dee2f5EA397AB4E7C489580);
    address public constant SPIRIT = address(0x5Cc61A78F164885776AA610fb0FE1257df78E59B);
    address public immutable GAUGE;
    address public immutable TOKEN; // gauge token

    address public owner;
    address public treasury;
    uint256 public rewardFeeRate; // 5%

    mapping(address => uint256) public userRewardPerTokenPaid; // depositor indexes
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    uint256 public rewardPerTokenStored; // general index 
    uint256 public totalSupply; // == gauge.balances(address(this))
    uint256 public totalReward;
    uint256 public rewardDistributed;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event IndexUpdated(uint256 previousIndex, uint256 newIndex, uint256 deltaReward);
    event UserRewardUpdated(address account, uint256 previousReward, uint256 newReward);

    constructor(address _gauge, address _owner) public {
        require(_gauge != address(0), "no gauge");
        GAUGE = _gauge;
        TOKEN = IGauge(_gauge).TOKEN();
        require(_owner != address(0), "no owner");
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "no owner");
        require(newOwner != owner, "same owner");
        owner = newOwner;    
    }

    function setRewardFeeRate(uint256 newRewardFeeRate) external onlyOwner {
        require(newRewardFeeRate <= 250, "newRewardFeeRate too high");
        if (newRewardFeeRate > 0) {
            require(treasury != address(0), "treasury not set");
        }
        rewardFeeRate = newRewardFeeRate;
    }

    function setTreasury(address newTreasury) external onlyOwner {
        if (newTreasury == address(0)) {
            require(rewardFeeRate == 0, "reward fee rate > 0");
        }
        treasury = newTreasury;
    }

    function getBoostFactor() external view returns (uint256) {
        // uint256 balance = IGauge(GAUGE).balanceOf(address(this));
        uint256 refBalance = totalSupply.mul(40).div(100);
        uint256 derivedBalance = IGauge(GAUGE).derivedBalances(DEPOSITOR);
        return derivedBalance.mul(1e18).div(refBalance);
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function rewardDelta() public view returns (uint256) {
        uint256 rewardsStored = IGauge(GAUGE).rewards(DEPOSITOR); // consider: use 'totalReward' instead of 'IGauge(GAUGE).rewards(DEPOSITOR)' 
        uint256 rewardsCurrent = IGauge(GAUGE).earned(DEPOSITOR);
        return rewardsCurrent.sub(rewardsStored);
    }

    function rewardPerTokenCurrent() public view returns (uint256) {
        uint256 deltaReward = rewardDelta();
        uint256 supply = totalSupply;
        if (supply == 0 || deltaReward == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(deltaReward.mul(1e18).div(supply));
    }

    function earnedCurrent(address account) public view returns (uint256) {
        uint256 rewardPerToken = rewardPerTokenCurrent();
        return _balances[account].mul(rewardPerToken.sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function earnedCurrentMinusFee(address account) external view returns (uint256) {
        uint256 reward = earnedCurrent(account);
        uint256 feeAmount = reward.mul(rewardFeeRate).div(10000);
        uint256 userAmount = reward.sub(feeAmount);
        return userAmount;
    }

    /// @notice there isn't a good way to get the current rewardPerToken in a view function because 'deltaReward' can't be obtained
    function rewardPerToken(uint256 deltaReward) internal returns (uint256) {
        uint256 supply = totalSupply;
        if (supply == 0 || deltaReward == 0) {
            return rewardPerTokenStored;
        }
        /// @notice this state change is here for gas savings (if deltaReward == 0 no need to update 'totalReward')
        totalReward = totalReward.add(deltaReward); // state
        return rewardPerTokenStored.add(deltaReward.mul(1e18).div(supply));
    }

    /// @notice we pass rewardPerToken as input to avoid reading rewardPerTokenStored from state
    function earned(address account, uint256 rewardPerToken) internal view returns (uint256) {
        return _balances[account].mul(rewardPerToken.sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function updateReward(address account, uint256 deltaReward) internal {
        uint256 _previousIndex = rewardPerTokenStored;
        uint256 _rewardPerTokenCurrent = rewardPerToken(deltaReward);
        rewardPerTokenStored = _rewardPerTokenCurrent; // state
        uint256 _previousReward = rewards[account];
        uint256 _newReward = earned(account, _rewardPerTokenCurrent);
        rewards[account] = _newReward; // state
        userRewardPerTokenPaid[account] = _rewardPerTokenCurrent; // state

        emit IndexUpdated(_previousIndex, _rewardPerTokenCurrent, deltaReward);
        emit UserRewardUpdated(account, _previousReward, _newReward);
    }

    function depositAll() external {
        _deposit(IERC20(TOKEN).balanceOf(msg.sender), msg.sender);
    }

    function deposit(uint256 amount) external {
        _deposit(amount, msg.sender);
    }

    function _deposit(uint256 amount, address account) internal nonReentrant {
        uint256 balanceBefore = IGauge(GAUGE).balanceOf(DEPOSITOR);
        uint256 rewardPrior = IGauge(GAUGE).rewards(DEPOSITOR);
        
        // DEPOSITOR deposits 'amount' of TOKEN to GAUGE (note: requires DEPOSITOR to approve GAUGE to spend)
        IERC20(TOKEN).safeTransferFrom(msg.sender, DEPOSITOR, amount);
        IDepositor(DEPOSITOR).deposit(GAUGE, TOKEN);

        // verify something was indeed deposited in gauge
        uint256 balanceAfter = IGauge(GAUGE).balanceOf(DEPOSITOR);
        require(balanceAfter > balanceBefore, "nothing deposited");
        amount = balanceAfter.sub(balanceBefore);

        // update global index + total reward, and account's index + account's reward **before** updating account's balance and the total supply
        uint256 rewardAfter = IGauge(GAUGE).rewards(DEPOSITOR); 
        updateReward(account, rewardAfter.sub(rewardPrior));

        // update account's balance and the total supply 
        _balances[account] = _balances[account].add(amount); // state
        totalSupply = totalSupply.add(amount); // state
        
        emit Staked(account, amount);
    }

    function withdrawAll() external {
        _withdraw(_balances[msg.sender]);
    }

    function withdraw(uint256 amount) external {
        _withdraw(amount);
    }

    function _withdraw(uint amount) internal nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        uint256 tokenBalanceBefore = IERC20(TOKEN).balanceOf(DEPOSITOR);
        uint256 balanceBefore = IGauge(GAUGE).balanceOf(DEPOSITOR);
        uint256 rewardPrior = IGauge(GAUGE).rewards(DEPOSITOR);

        // DEPOSITOR withdraws 'amount' of TOKEN from GAUGE and sends it to msg.sender namely to address(this)
        IDepositor(DEPOSITOR).withdraw(GAUGE, TOKEN, amount);

        // verify something was indeed withdrawan from gauge
        uint256 balanceAfter = IGauge(GAUGE).balanceOf(DEPOSITOR);
        require(balanceAfter < balanceBefore, "nothing withdrawan");
        amount = balanceBefore.sub(balanceAfter);

        // update global index + total reward, and account's index + account's reward **before** updating account's balance and the total supply
        uint256 rewardAfter = IGauge(GAUGE).rewards(DEPOSITOR);
        updateReward(msg.sender, rewardAfter.sub(rewardPrior));

        // update account's balance and the total supply 
        /// @notice fails if msg.sender is trying to withdraw more that they had deposited
        _balances[msg.sender] = _balances[msg.sender].sub(amount); // state
        totalSupply = totalSupply.sub(amount); // state

        uint256 tokenBalanceAfter = IERC20(TOKEN).balanceOf(address(this));
        require(tokenBalanceAfter > tokenBalanceBefore, "nothing recieved");
        IERC20(TOKEN).safeTransfer(msg.sender, tokenBalanceAfter.sub(tokenBalanceBefore));

        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant {
        uint256 rewardPrior = IGauge(GAUGE).rewards(DEPOSITOR);
        uint256 spiritBalanceBefore = IERC20(SPIRIT).balanceOf(address(this));

        // DEPOSITOR pulls reward from gauge
        IDepositor(DEPOSITOR).claimGaugeReward(GAUGE);

        // update global index + total reward, and account's index + account's reward **before** updating account's balance and the total supply
        uint256 spiritBalanceAfter = IERC20(SPIRIT).balanceOf(address(this));
        uint256 spiritDelta = spiritBalanceAfter.sub(spiritBalanceBefore);
        updateReward(msg.sender, spiritDelta.sub(rewardPrior));

        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            require(spiritBalanceAfter >= reward, "SPIRIT balance not sufficient");
            rewards[msg.sender] = 0; // state
            rewardDistributed = rewardDistributed.add(reward); // state
        
            uint256 feeAmount = reward.mul(rewardFeeRate).div(10000);
            uint256 userAmount = reward.sub(feeAmount);
            IERC20(SPIRIT).safeTransfer(msg.sender, userAmount);
            IERC20(SPIRIT).safeTransfer(treasury, feeAmount);
        
            emit RewardPaid(msg.sender, userAmount);
        }
    }

    function exit() external {
        _withdraw(_balances[msg.sender]);
        getReward();
    }
}

pragma solidity ^0.6.7;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "add: +");

        return c;
    }
    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "sub: -");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "mul: *");

        return c;
    }
    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "div: /");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

pragma solidity ^0.6.7;

import "./SafeMath.sol";
import "./Address.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.7;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
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
    function withdrawAll(address _gauge, address _underlying) external;
    function claimGaugeReward(address _gauge) external;
}

interface IRewardsHandlerForBoostedFarm {
    function handleRewards(
        address token,
        uint256 amount,
        address account,
        bytes32[] memory params
    ) external;
}

interface IZapperForBoostedFarm {
    function unzip(
        address token,
        uint256 amount,
        address acount,
        bytes32[] memory params
    ) external;
}

contract SpiritBoostedFarm is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewRewardsFeeRate(uint oldRewardsFeeRate, uint newRewardsFeeRate);
    event NewTreasury(address indexed oldTreasury, address indexed newTreasury);

    event FarmRetired(uint lpBalance, uint rewardBalance);

    /// @notice the address that holds our inSPIRIT (ie. strategy proxy) and the one that would deposit the LPs in the gauges
    address public constant DEPOSITOR = address(0x099EA71e5B0C7E350dee2f5EA397AB4E7C489580);
    address public constant SPIRIT = address(0x5Cc61A78F164885776AA610fb0FE1257df78E59B);
    address public immutable GAUGE;
    address public immutable TOKEN; // gauge token

    address public owner;
    address public treasury;
    uint256 public rewardFeeRate;
    bool public retired;

    mapping(address => uint256) public userRewardPerTokenPaid; // depositor indexes
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    uint256 public rewardPerTokenStored; // general index 
    uint256 public totalSupply; // == gauge.balances(address(this))
    uint256 public totalReward;
    uint256 public rewardDistributed;

    mapping(address => bool) public rewardsClaimersWhitelist;
    address[] public rewardsClaimersList;
    mapping(IRewardsHandlerForBoostedFarm => bool) public rewardsHandlersWhitelist;
    IRewardsHandlerForBoostedFarm[] rewardsHandlersList;

    IZapperForBoostedFarm public zapper;

    event Staked(address indexed farmer, uint256 amount);
    event Withdrawn(address indexed farmer, uint256 amount, uint256 actualReceivedAmount);
    event RewardPaid(address indexed farmer, uint256 reward);
    event IndexUpdated(uint256 previousIndex, uint256 newIndex, uint256 deltaReward);
    event UserRewardUpdated(address indexed farmer, uint256 previousReward, uint256 newReward);
    event SetZapper(IZapperForBoostedFarm zapper);
    event WhitelistRewardsHandler(IRewardsHandlerForBoostedFarm handler, bool value); // value == true -> whitelisting, value == false -> blacklisting
    event WhitelistRewardsClaimer(address claimer, bool value); // value == true -> whitelisting, value == false -> blacklisting

    function isContract(address addr) public view returns (bool) {
      uint32 size;
      assembly {
        size := extcodesize(addr)
      }
      return (size > 0);
    }

    constructor(address _gauge, address _owner) public {
        require(_gauge != address(0), "no gauge");
        GAUGE = _gauge;
        require(isContract(_gauge), "Not contract");
        TOKEN = IGauge(_gauge).TOKEN();
        require(_owner != address(0), "no owner");
        owner = _owner;

        emit NewOwner(address(0), owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    // **** Views ****

    /**
     * @return The effective boost factor gained by farming via this contract
     */
    function getBoostFactor() external view returns (uint256) {
        if (totalSupply == 0 ) {
            return 0;
        }

        uint256 refBalance = totalSupply.mul(40).div(100);
        uint256 derivedBalance = IGauge(GAUGE).derivedBalances(DEPOSITOR);
        return derivedBalance.mul(1e18).div(refBalance);
    }

    /**
     * @param farmer address
     * @return The current balance of gauge tokens deposits by the farmer
     */
    function balanceOf(address farmer) external view returns (uint256) {
        return _balances[farmer];
    }

    /**
     * @return The amount of reward tokens the Depositor is entitled to (at the Gauge)
     */
    function rewardDelta() public view returns (uint256) {
        uint256 rewardsStored = IGauge(GAUGE).rewards(DEPOSITOR); // consider: use 'totalReward' instead of 'IGauge(GAUGE).rewards(DEPOSITOR)'
        uint256 rewardsCurrent = IGauge(GAUGE).earned(DEPOSITOR);
        return rewardsCurrent.sub(rewardsStored);
    }

    /**
     * @return The ratio between deposited gauge tokens and earned rewards
     */
    function rewardPerTokenCurrent() public view returns (uint256) {
        uint256 deltaReward = rewardDelta();
        uint256 supply = totalSupply;
        if (supply == 0 || deltaReward == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(deltaReward.mul(1e18).div(supply));
    }

    /**
     * @notice Calculates the amount of rewards the farmer is currently entitled to before fee considerations
     * @param farmer address
     */
    function earnedCurrent(address farmer) public view returns (uint256) {
        uint256 rewardPerToken = rewardPerTokenCurrent();
        return _balances[farmer].mul(rewardPerToken.sub(userRewardPerTokenPaid[farmer])).div(1e18).add(rewards[farmer]);
    }

    /**
     * @notice Calculates the amount of rewards the farmer is currently entitled to after fee considerations
     * @param farmer address
     */
    function earnedCurrentMinusFee(address farmer) external view returns (uint256) {
        uint256 reward = earnedCurrent(farmer);
        uint256 feeAmount = reward.mul(rewardFeeRate).div(10000);
        uint256 userAmount = reward.sub(feeAmount);
        return userAmount;
    }

    // **** User Interactions ****

    /**
     * @notice Sender will deposit ALL gauge tokens they own
     */
    function depositAll() external {
        _deposit(msg.sender, msg.sender, IERC20(TOKEN).balanceOf(msg.sender));
    }

    /**
     * @notice Sender will deposit SOME gauge tokens
     * @param amount The GaugeToken amount to deposit
     */
    function deposit(uint amount) external {
        _deposit(msg.sender, msg.sender, amount);
    }

    /**
     * @notice Sender will deposit gauge tokens on behalf of the farmer
     * @param farmer The farmer who will get credited with the deposit
     * @param amount The GaugeToken amount to deposit
     */
    function depositOnBehalf(address farmer, uint amount) external {
        _deposit(farmer, msg.sender, amount);
    }

    /**
     * @notice Sender will withdraw ALL gauge token deposited
     * @dev Allowed after retire
     */
    function withdrawAll() public {
        bytes32[] memory empty;
        _withdraw(msg.sender, _balances[msg.sender], false, empty);
    }

    /**
     * @notice Sender will withdraw ALL gauge token deposited and will be using the zapper while withdrawing
     */
    function withdrawAllZapping(bytes32[] memory params) public {
        _withdraw(msg.sender, _balances[msg.sender], true, params);
    }

    /**
     * @notice Sender will withdraw SOME gauge tokens
     */
    function withdraw(uint256 amount) external {
        bytes32[] memory empty;
        _withdraw(msg.sender, amount, false, empty);
    }

    /**
     * @notice Sender will withdraw SOME gauge tokens and will be using the zapper while withdrawing
     */
    function withdrawZapping(uint256 amount, bytes32[] memory params) external {
        _withdraw(msg.sender, amount, true, params);
    }

    /**
     * @notice Sender will receive the rewards they are entitled to
     * @dev Allowed after retire
     */
    function getReward(IRewardsHandlerForBoostedFarm handler, bytes32[] memory params) public {
        _claimRewards(msg.sender, handler, params);
    }

    /**
     * @dev True if the given claimer is whitelisted
     */
    function isRewardsClaimerWhitelisted(address claimer) public view returns (bool) {
        return rewardsClaimersWhitelist[claimer];
    }

    /**
     * @dev True if the given handler is whitelisted
     */
    function isRewardsHandlerWhitelisted(IRewardsHandlerForBoostedFarm handler) public view returns (bool) {
        return rewardsHandlersWhitelist[handler];
    }

    /**
    * @notice Returns a list of all the whitelisted rewardsHandlers
    */
    function getRewardsHandlersWhitelist() external returns (IRewardsHandlerForBoostedFarm[] memory) {
        return rewardsHandlersList;
    }

    /**
    * @notice Returns a list of all the whitelisted rewardsClaimers
    */
    function getRewardsClaimersWhitelist() external returns (address[] memory) {
        return rewardsClaimersList;
    }

    /**
     * @notice Sender will receive the rewards they are entitled to
     * @dev Allowed after retire
     */
    function getRewardFor(address farmer, IRewardsHandlerForBoostedFarm handler, bytes32[] memory params) public {
        require(true == isRewardsClaimerWhitelisted(msg.sender), "!whitelisted claimer");
        _claimRewards(farmer, handler, params);
    }

    /**
     * @notice Sender will withdraw ALL gauge token deposited and receive all rewards they are entitled to
     * @dev Allowed after retire
     */
    function exit(IRewardsHandlerForBoostedFarm rewardsHandler, bytes32[] memory rewardsHandlerParams) external {
        withdrawAll();
        getReward(rewardsHandler, rewardsHandlerParams);
    }
    
    /**
     * @notice Sender will withdraw ALL gauge token deposited and receive all rewards they are entitled to and will be using the zapper while withdrawing
     */
    function exitZapping(IRewardsHandlerForBoostedFarm rewardsHandler, bytes32[] memory rewardsHandlerParams, bytes32[] memory zapperParams) external {
        withdrawAllZapping(zapperParams);
        getReward(rewardsHandler, rewardsHandlerParams);
    }

    // **** Admin Functions ****

    /**
     * @notice Retires the farm. Withdrawing all LP and rewards tokens to self.
     * @dev Retired farms cannot be reactivated.
     * @dev A farm should be retired before blacklisted.
     */
    function retireFarm() external onlyOwner nonReentrant{
        retired = true;

        if (0 < IGauge(GAUGE).balanceOf(DEPOSITOR)) {
            // DEPOSITOR withdraws all of TOKEN from GAUGE and sends it to 'farmer' namely to address(this)
            IDepositor(DEPOSITOR).withdrawAll(GAUGE, TOKEN);
        }
        uint256 ownLpBalance = IERC20(TOKEN).balanceOf(address(this));

        // DEPOSITOR pulls reward from gauge
        IDepositor(DEPOSITOR).claimGaugeReward(GAUGE);
        uint256 ownSpiritBalance = IERC20(SPIRIT).balanceOf(address(this));

        emit FarmRetired(ownLpBalance, ownSpiritBalance);
    }

    /**
     * @notice Admin function to set the owner address
     */
    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "no owner");
        require(newOwner != owner, "same owner");

        address oldOwner = owner;
        owner = newOwner;
        emit NewOwner(oldOwner, owner);
    }

    /**
     * @notice Admin function to set the fee
     * @dev The fee is divided by 10k so the maximum fee rate is 25%
     */
    function setRewardFeeRate(uint256 newRewardFeeRate) external onlyOwner {
        require(newRewardFeeRate <= 2500, "newRewardFeeRate too high");
        if (newRewardFeeRate > 0) {
            require(treasury != address(0), "treasury not set");
        }

        uint oldFeeRate = rewardFeeRate;
        rewardFeeRate = newRewardFeeRate;
        emit NewRewardsFeeRate(oldFeeRate, rewardFeeRate);
    }

    /**
    * @notice Admin function to set the zapper
    */
    function setZapper(IZapperForBoostedFarm _zapper) external onlyOwner {
        zapper = _zapper;
        emit SetZapper(_zapper);
    }

    /**
    * @notice Admin function to whitelist a rewards claimer
    */
    function whitelistRewardsClaimer(address claimer) external onlyOwner {
        require(false == rewardsClaimersWhitelist[claimer], "rewardsClaaimer already whitelisted");
        rewardsClaimersWhitelist[claimer] = true;
        rewardsClaimersList.push(claimer);

        emit WhitelistRewardsClaimer(claimer, true);
    }

    /**
    * @notice Admin function to blacklist a rewards claimer
    */
    function blacklistRewardsClaimer(address claimer, uint256 index) external onlyOwner {
        require(true == rewardsClaimersWhitelist[claimer], "rewardsClaimer isn't whitelisted");
        rewardsClaimersWhitelist[claimer] = false;

        uint256 listLength = rewardsClaimersList.length;
        require((index < listLength) && (rewardsClaimersList[index] == claimer), "Wrong index");
        rewardsClaimersList[index] = rewardsClaimersList[listLength - 1];
        rewardsClaimersList.pop();

        emit WhitelistRewardsClaimer(claimer, false);
    }

    /**
    * @notice Admin function to whitelist a rewards handler
    */
    function whitelistRewardsHandler(IRewardsHandlerForBoostedFarm handler) external onlyOwner {
        require(false == rewardsHandlersWhitelist[handler], "rewardsHandler already whitelisted");

        rewardsHandlersWhitelist[handler] = true;
        rewardsHandlersList.push(handler);

        emit WhitelistRewardsHandler(handler, true);
    }

    /**
    * @notice Admin function to blocklist a rewards handler
    */
    function blacklistRewardsHandler(IRewardsHandlerForBoostedFarm handler, uint256 index) external onlyOwner {
        require(true == rewardsHandlersWhitelist[handler], "rewardsHandler isn't whitelisted");
        rewardsHandlersWhitelist[handler] = false;

        uint256 listLength = rewardsHandlersList.length;
        require((index < listLength) && (rewardsHandlersList[index] == handler), "Wrong index");
        rewardsHandlersList[index] = rewardsHandlersList[listLength - 1];
        rewardsHandlersList.pop();

        emit WhitelistRewardsHandler(handler, false);
    }

    /**
     * @notice Admin function to set the treasury address
     * @param newTreasury address
     */
    function setTreasury(address newTreasury) external onlyOwner {
        if (newTreasury == address(0)) {
            require(rewardFeeRate == 0, "reward fee rate > 0");
        }

        address oldTreasury = treasury;
        treasury = newTreasury;
        emit NewTreasury(oldTreasury, treasury);
    }

    // **** Internal Views ****

    /**
     * @notice we pass rewardPerToken as input to avoid reading rewardPerTokenStored from state
     * @return The amount of rewards the farmer gained since the last time their
     */
    function earned(address farmer, uint256 rewardPerToken) internal view returns (uint256) {
        return _balances[farmer].mul(rewardPerToken.sub(userRewardPerTokenPaid[farmer])).div(1e18).add(rewards[farmer]);
    }

    // **** Internal NonReentereant Farm Functions ****

    function _deposit(address farmer, address payer, uint256 amount) internal nonReentrant {
        require(!retired, "retired");
        uint256 balanceBefore = IGauge(GAUGE).balanceOf(DEPOSITOR);
        uint256 rewardPrior = IGauge(GAUGE).rewards(DEPOSITOR);
        
        // DEPOSITOR deposits 'amount' of TOKEN to GAUGE (note: requires DEPOSITOR to approve GAUGE to spend)
        IERC20(TOKEN).safeTransferFrom(payer, DEPOSITOR, amount);
        IDepositor(DEPOSITOR).deposit(GAUGE, TOKEN);

        // verify something was indeed deposited in gauge
        uint256 balanceAfter = IGauge(GAUGE).balanceOf(DEPOSITOR);
        require(balanceAfter > balanceBefore, "nothing deposited");
        amount = balanceAfter.sub(balanceBefore);

        // update global index + total reward, and farmer's index + farmer's reward **before** updating farmer's balance and the total supply
        uint256 rewardAfter = IGauge(GAUGE).rewards(DEPOSITOR); 
        updateReward(farmer, rewardAfter.sub(rewardPrior));

        // update farmer's balance and the total supply
        _balances[farmer] = _balances[farmer].add(amount); // state
        totalSupply = totalSupply.add(amount); // state
        
        emit Staked(farmer, amount);
    }

    function _withdraw(address farmer, uint amount, bool zapping, bytes32[] memory params) internal nonReentrant {
        require(amount > 0, "Cannot withdraw 0");

        uint amountOut;

        if (!retired) {
            uint256 tokenBalanceBefore = IERC20(TOKEN).balanceOf(DEPOSITOR);
            uint256 balanceBefore = IGauge(GAUGE).balanceOf(DEPOSITOR);
            uint256 rewardPrior = IGauge(GAUGE).rewards(DEPOSITOR);

            // DEPOSITOR withdraws 'amount' of TOKEN from GAUGE and sends it to 'farmer' namely to address(this)
            IDepositor(DEPOSITOR).withdraw(GAUGE, TOKEN, amount);

            // verify something was indeed withdrawan from gauge
            uint256 balanceAfter = IGauge(GAUGE).balanceOf(DEPOSITOR);
            require(balanceAfter < balanceBefore, "nothing withdrawn");
            amount = balanceBefore.sub(balanceAfter);

            // update global index + total reward, and farmer's index + farmer's reward **before** updating farmer's balance and the total supply
            uint256 rewardAfter = IGauge(GAUGE).rewards(DEPOSITOR);
            updateReward(farmer, rewardAfter.sub(rewardPrior));

            // update farmer's balance and the total supply
            /// @notice fails if farmer is trying to withdraw more that they had deposited
            _balances[farmer] = _balances[farmer].sub(amount); // state
            totalSupply = totalSupply.sub(amount); // state

            uint256 tokenBalanceAfter = IERC20(TOKEN).balanceOf(address(this));
            require(tokenBalanceAfter > tokenBalanceBefore, "nothing received");
            amountOut = tokenBalanceAfter.sub(tokenBalanceBefore);
        } else {
            updateReward(farmer, 0);

            uint256 farmerBalance = _balances[farmer];
            // When retired, we don't allow partial withdrawals - only withdrawing all funds.
            require(amount == farmerBalance, "Can't partial withdraw when retired");

            // update farmer's balance and the total supply
            _balances[farmer] = 0;
            totalSupply = totalSupply.sub(amount); // state
            amountOut = amount;
        }

        // NO STATE CHANGES AFTER THIS LINE
        if (zapping) {
            require(address(0) != address(zapper), "!zapper");
            IERC20(TOKEN).safeTransfer(address(zapper), amountOut);
            zapper.unzip(TOKEN, amountOut, farmer, params);
        } else {
            IERC20(TOKEN).safeTransfer(farmer, amountOut);
        }

        emit Withdrawn(farmer, amount, amountOut);
    }

    function _claimRewards(address farmer, IRewardsHandlerForBoostedFarm rewardsHandler, bytes32[] memory params) internal nonReentrant {
        uint256 spiritBalanceAfter;

        if (!retired) {
            uint256 rewardPrior = IGauge(GAUGE).rewards(DEPOSITOR);
            uint256 spiritBalanceBefore = IERC20(SPIRIT).balanceOf(address(this));

            // DEPOSITOR pulls reward from gauge
            IDepositor(DEPOSITOR).claimGaugeReward(GAUGE);

            // update global index + total reward, and farmer's index + farmer's reward **before** updating farmer's balance and the total supply
            spiritBalanceAfter = IERC20(SPIRIT).balanceOf(address(this));

            uint256 spiritDelta = spiritBalanceAfter.sub(spiritBalanceBefore);
            updateReward(farmer, spiritDelta.sub(rewardPrior));
        } else {
            updateReward(farmer, 0);
            spiritBalanceAfter = IERC20(SPIRIT).balanceOf(address(this));
        }

        uint256 reward = rewards[farmer];
        if (reward > 0) {
            require(true == isRewardsHandlerWhitelisted(rewardsHandler), "RewardsHandler not whitelisted");
            require(spiritBalanceAfter >= reward, "SPIRIT balance not sufficient");
            rewards[farmer] = 0; // state
            rewardDistributed = rewardDistributed.add(reward); // state

            uint256 feeAmount = reward.mul(rewardFeeRate).div(10000);
            uint256 userAmount = reward.sub(feeAmount);

            // NO STATE CHANGES AFTER THIS LINE

            IERC20(SPIRIT).safeTransfer(treasury, feeAmount);
            IERC20(SPIRIT).safeTransfer(address(rewardsHandler), userAmount);
            rewardsHandler.handleRewards(SPIRIT, userAmount, msg.sender, params);

            emit RewardPaid(farmer, userAmount);
        }
    }

    // **** Internal Rewards Accounting Functions ****

    /**
     * @notice Updates the general farm 'index', then the farmer index.
     */
    function updateReward(address farmer, uint256 deltaReward) internal {
        // Updates gain rewards for the farm, if there was a change
//        if (deltaReward > 0) {
//            uint256 _previousIndex = rewardPerTokenStored;
//            uint256 _rewardPerTokenCurrent = rewardPerToken(deltaReward);
//            rewardPerTokenStored = _rewardPerTokenCurrent; // state
//            emit IndexUpdated(_previousIndex, _rewardPerTokenCurrent, deltaReward);
//        }

        uint256 _rewardPerTokenCurrent = updateRewardPerToken(deltaReward);

        uint256 _previousReward = rewards[farmer];
        uint256 _newReward = earned(farmer, _rewardPerTokenCurrent);
        rewards[farmer] = _newReward; // state
        userRewardPerTokenPaid[farmer] = _rewardPerTokenCurrent; // state

        emit UserRewardUpdated(farmer, _previousReward, _newReward);
    }

    /**
     * @notice Updates the 'rewardPerToken' index by the given deltaReward
     * @return The current (post change) 'rewardPerToken'
     * @dev Returning the updated value saves a bit of gas
     * @dev there isn't a good way to get the current rewardPerToken in a view function because 'deltaReward' can't be obtained
     */
    function updateRewardPerToken(uint256 deltaReward) internal returns (uint256) {
        uint256 supply = totalSupply;
        if (supply == 0 || deltaReward == 0) {
            return rewardPerTokenStored;
        }

        uint256 _previousIndex = rewardPerTokenStored;

        uint256 _rewardPerTokenCurrent = rewardPerTokenStored.add(deltaReward.mul(1e18).div(supply));

        /// @notice this state change is here for gas savings (if deltaReward == 0 no need to update 'totalReward')
        totalReward = totalReward.add(deltaReward); // state
        rewardPerTokenStored = _rewardPerTokenCurrent; // state

        emit IndexUpdated(_previousIndex, _rewardPerTokenCurrent, deltaReward);

        return _rewardPerTokenCurrent;
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
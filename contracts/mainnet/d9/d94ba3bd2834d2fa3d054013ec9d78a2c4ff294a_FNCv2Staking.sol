/**
 *Submitted for verification at FtmScan.com on 2022-09-08
*/

// File: FNCv2Staking/Address.sol



pragma solidity ^0.8.1;

library Address {
    
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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

// File: FNCv2Staking/IERC20.sol



pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File: FNCv2Staking/SafeERC20.sol



pragma solidity ^0.8.0;



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

// File: FNCv2Staking/Context.sol



pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: FNCv2Staking/Ownable.sol



pragma solidity ^0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: FNCv2Staking/IFNCv2Staking.sol


pragma solidity =0.8.10;

//FNC v2 Staking Interface
interface IFNCv2Staking {
    function startStaking() external;
    function deposit(uint amount) external;
    function withdrawAll() external;
    function withdraw(uint amount) external;
    function amountStaked(address stakeHolder) external view returns (uint);
    function totalDeposited() external view returns (uint);
    function rewardOf(address stakeHolder) external view returns (uint);
    function claimRewards() external;
    event Deposit(address indexed owner, uint amount);
    event Withdraw(address indexed owner, uint amount);
    event Claim(address indexed stakeHolder, uint amount);
    event StartStaking(uint startPeriod, uint lockupPeriod, uint endingPeriod);
}
// File: FNCv2Staking/FNCv2Staking.sol


pragma solidity =0.8.10;





// FNC v2 Staking Contract
contract FNCv2Staking is IFNCv2Staking, Ownable {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;
    uint8 public immutable fixedAPY;
    uint public immutable stakingDuration;
    uint public immutable lockupDuration;
    uint public immutable stakingMax;
    uint public startPeriod;
    uint public lockupPeriod;
    uint public endPeriod;
    uint8 public burnFee = 5;
    address public dead = 0x000000000000000000000000000000000000dEaD;
    uint private _totalStaked;
    uint internal _precision = 1E6;

    mapping(address => uint) public staked;
    mapping(address => uint) private _rewardsToClaim;
    mapping(address => uint) private _userStartTime;

    constructor(
        address _token,
        uint8 _fixedAPY,
        uint _durationInDays,
        uint _lockDurationInDays,
        uint _maxAmountStaked
    ) {
        stakingDuration = _durationInDays * 1 days;
        lockupDuration = _lockDurationInDays * 1 days;
        token = IERC20(_token);
        fixedAPY = _fixedAPY;
        stakingMax = _maxAmountStaked;
    }

    function startStaking() external override onlyOwner {
        require(startPeriod == 0, "Staking has already started");
        startPeriod = block.timestamp;
        lockupPeriod = block.timestamp + lockupDuration;
        endPeriod = block.timestamp + stakingDuration;
        emit StartStaking(startPeriod, lockupDuration, endPeriod);
    }

    function deposit(uint amount) external override {
        require(endPeriod == 0 || endPeriod > block.timestamp, "Staking period ended");
        require(_totalStaked + amount <= stakingMax, "The total quota of $FNC to be staked is full! Please try to stake a lesser amount!");
        require(amount > 0, "You must stake an amount more than 0!");
        if (_userStartTime[_msgSender()] == 0) {
            _userStartTime[_msgSender()] = block.timestamp;
        }
        _updateRewards();
        staked[_msgSender()] += amount;
        _totalStaked += amount;
        token.safeTransferFrom(_msgSender(), address(this), amount);
        emit Deposit(_msgSender(), amount);
    }

    function withdraw(uint amount) external override {
        require(block.timestamp >= lockupPeriod, "You can't withdraw your $FNC before the lockup period ends!");
        require(amount > 0, "You don't have any $FNC to withdraw!");
        require(amount <= staked[_msgSender()], "You can't withdraw more $FNC than what you have staked!");
        _updateRewards();
        if (_rewardsToClaim[_msgSender()] > 0) {
            _claimRewards();
        }
        _totalStaked -= amount;
        staked[_msgSender()] -= amount;
        token.safeTransfer(_msgSender(), amount);
        emit Withdraw(_msgSender(), amount);
    }

    function withdrawAll() external override {
        require(block.timestamp >= lockupPeriod, "You can't withdraw funds before the lockup ends.");
        _updateRewards();
        if (_rewardsToClaim[_msgSender()] > 0){
            _claimRewards();
        }
        _userStartTime[_msgSender()] = 0;
        _totalStaked -= staked[_msgSender()];
        uint stakedBalance = staked[_msgSender()];
        staked[_msgSender()] = 0;
        token.safeTransfer(_msgSender(), stakedBalance);
        emit Withdraw(_msgSender(), stakedBalance);
    }

    function withdrawResidualBalance() external onlyOwner {
        uint balance = token.balanceOf(address(this));
        uint residualBalance = balance - (_totalStaked);
        require(residualBalance > 0, "No residual Balance to withdraw.");
        token.safeTransfer(owner(), residualBalance);
    }

    function setBurnFees(uint8 newFee) external onlyOwner {
        require(newFee <= 25, "Burn Fees can't be higher then 25%.");
        burnFee = newFee;
    }

    function amountStaked(address stakeHolder) external view override returns (uint){
        return staked[stakeHolder];
    }

    function totalDeposited() external view override returns (uint) {
        return _totalStaked;
    }

    function rewardOf(address stakeHolder) external view override returns (uint){
        return _calculateRewards(stakeHolder);
    }

    function claimRewards() external override {
        _claimRewards();
    }

    function _calculateRewards(address stakeHolder) internal view returns (uint){
        if (startPeriod == 0 || staked[stakeHolder] == 0) {
            return 0;
        }

        return
            (((staked[stakeHolder] * fixedAPY) *
                _percentageTimeRemaining(stakeHolder)) / (_precision * 100)) +
            _rewardsToClaim[stakeHolder];
    }

    function _percentageTimeRemaining(address stakeHolder) internal view returns (uint){
        bool early = startPeriod > _userStartTime[stakeHolder];
        uint startTime;
        if (endPeriod > block.timestamp) {
            startTime = early ? startPeriod : _userStartTime[stakeHolder];
            uint timeRemaining = stakingDuration -
                (block.timestamp - startTime);
            return
                (_precision * (stakingDuration - timeRemaining)) /
                stakingDuration;
        }
        startTime = early
            ? 0
            : stakingDuration - (endPeriod - _userStartTime[stakeHolder]);
        return (_precision * (stakingDuration - startTime)) / stakingDuration;
    }

    function _claimRewards() private {
        _updateRewards();
        uint rewardsToClaim = _rewardsToClaim[_msgSender()];
        require(rewardsToClaim > 0, "You don't have any $FNC rewards!");
        _rewardsToClaim[_msgSender()] = 0;
        uint rewardBurnFee = (rewardsToClaim / 100 * burnFee);
        rewardsToClaim = rewardsToClaim - rewardBurnFee;
        token.safeTransfer(_msgSender(), rewardsToClaim);
        token.safeTransfer(dead, rewardBurnFee);
        emit Claim(_msgSender(), rewardsToClaim);
    }

    function _updateRewards() private {
        _rewardsToClaim[_msgSender()] = _calculateRewards(_msgSender());
        _userStartTime[_msgSender()] = (block.timestamp >= endPeriod) ? endPeriod : block.timestamp;
    }
}
/**
 *Submitted for verification at FtmScan.com on 2022-01-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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


library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


interface IRewardToken is IERC20 {
    function mint(address to, uint256 amount) external;
}


contract Farm is Ownable {
    using SafeERC20 for IERC20;

    struct User {
        uint256 stakingBalance;
        uint256 rewardDebt;
    }

    struct Pool {
        IERC20 stakingToken;
        uint256 allocPoints;
        uint256 checkpoint;
        uint256 accPerShare;
        uint256 feeBP;
        uint256 stakingTokenBalance;
    }

    // The token that rewards are given in.
    IRewardToken public rewardToken;

    // Fee address.
    address public feeAddress;

    // RewardToken tokens created per block.
    uint256 public rewardPerSecond;

    // Maximum number of allocation points for a pool.
    uint256 public constant MAX_ALLOC_POINTS = 4000;

    // Info of each pool.
    Pool[] public pools;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => User)) public users;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoints = 0;

    // The block time when rewardToken mining starts.
    uint256 public immutable startTime;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);


    constructor(
        IRewardToken rewardToken_,
        address feeAddress_,
        uint256 rewardPerSecond_,
        uint256 startTime_
    ) {
        rewardToken = rewardToken_;
        feeAddress = feeAddress_;
        rewardPerSecond = rewardPerSecond_;
        startTime = startTime_;
    }


    function numberOfPools() external view returns (uint256) {
        return pools.length;
    }


    function setRewardPerSecond(uint256 rewardPerSecond_) external onlyOwner {
        // This MUST be done or pool rewards will be calculated with new rewardToken per second
        // This could unfairly punish small pools that dont have frequent deposits/withdraws/harvests
        massUpdatePools();

        rewardPerSecond = rewardPerSecond_;
    }


    function checkForDuplicates(IERC20 stakingToken) internal view {
        for (uint256 pid = 0; pid < pools.length; pid++) {
            require(pools[pid].stakingToken != stakingToken, "add: pool already exists");
        }
    }


    function add(IERC20 stakingToken, uint256 allocPoints, uint256 feeBP) external onlyOwner {
        require(allocPoints <= MAX_ALLOC_POINTS, "add: alloc points exceed maximum");
        require(feeBP <= 10000, "add: feeBP must not exceed 10000");

        checkForDuplicates(stakingToken);

        massUpdatePools();

        uint256 checkpoint = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoints += allocPoints;

        pools.push(Pool({
            stakingToken: stakingToken,
            allocPoints: allocPoints,
            checkpoint: checkpoint,
            accPerShare: 0,
            feeBP: feeBP,
            stakingTokenBalance: 0
        }));
    }


    function set(uint256 pid, uint256 allocPoints, uint256 feeBP) external onlyOwner {
        require(allocPoints <= MAX_ALLOC_POINTS, "set: alloc points exceed maximum");
        require(feeBP <= 10000, "set: feeBP must not exceed 10000");

        massUpdatePools();

        totalAllocPoints = totalAllocPoints - pools[pid].allocPoints + allocPoints;
        pools[pid].allocPoints = allocPoints;
        pools[pid].feeBP = feeBP;
    }


    function getMultiplier(uint256 from, uint256 to) public view returns (uint256) {
        if (from > to) { return 0; }
        if (to < startTime) { return 0; }
        from = from > startTime ? from : startTime;
        return to - from;
    }


    function pendingReward(uint256 pid, address userAddress) external view returns (uint256) {
        Pool storage pool = pools[pid];
        User storage user = users[pid][userAddress];
        uint256 aps = pool.accPerShare;
        if (block.timestamp > pool.checkpoint && pool.stakingTokenBalance > 0) {
            uint256 time = getMultiplier(pool.checkpoint, block.timestamp);
            uint256 reward = time * rewardPerSecond * pool.allocPoints / totalAllocPoints;
            aps += reward * 1e12 / pool.stakingTokenBalance;
        }
        return user.stakingBalance * aps / 1e12 - user.rewardDebt;
    }


    function stakingBalance(uint256 pid, address userAddress) external view returns (uint256) {
        return users[pid][userAddress].stakingBalance;
    }


    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        for (uint256 pid = 0; pid < pools.length; ++pid) {
            updatePool(pid);
        }
    }


    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 pid) public {
        Pool storage pool = pools[pid];
        if (block.timestamp <= pool.checkpoint) {
            return;
        }
        if (pool.stakingTokenBalance == 0) {
            pool.checkpoint = block.timestamp;
            return;
        }
        uint256 time = getMultiplier(pool.checkpoint, block.timestamp);
        uint256 reward = time * rewardPerSecond * pool.allocPoints / totalAllocPoints;

        rewardToken.mint(feeAddress, reward / 10);
        rewardToken.mint(address(this), reward);

        pool.accPerShare += reward * 1e12 / pool.stakingTokenBalance;
        pool.checkpoint = block.timestamp;
    }


    function deposit(uint256 pid, uint256 amount) external {
        Pool storage pool = pools[pid];
        User storage user = users[pid][msg.sender];

        updatePool(pid);

        uint256 yield = user.stakingBalance * pool.accPerShare / 1e12 - user.rewardDebt;
        if (yield > 0) {
            safeRewardTokenTransfer(msg.sender, yield);
        }

        pool.stakingToken.safeTransferFrom(address(msg.sender), address(this), amount);

        if (pool.feeBP > 0) {
            uint256 fee = amount * pool.feeBP / 10000;
            pool.stakingToken.safeTransfer(feeAddress, fee);
            amount -= fee;
        }

        pool.stakingTokenBalance += amount;
        user.stakingBalance += amount;
        user.rewardDebt = user.stakingBalance * pool.accPerShare / 1e12;

        emit Deposit(msg.sender, pid, amount);
    }


    function withdraw(uint256 pid, uint256 amount) external {
        Pool storage pool = pools[pid];
        User storage user = users[pid][msg.sender];

        require(user.stakingBalance >= amount, "withdraw: insufficient balance");

        updatePool(pid);

        uint256 yield = user.stakingBalance * pool.accPerShare / 1e12 - user.rewardDebt;
        if (yield > 0) {
            safeRewardTokenTransfer(msg.sender, yield);
        }

        pool.stakingToken.safeTransfer(address(msg.sender), amount);

        pool.stakingTokenBalance -= amount;
        user.stakingBalance -= amount;
        user.rewardDebt = user.stakingBalance * pool.accPerShare / 1e12;

        emit Withdraw(msg.sender, pid, amount);
    }


    function emergencyWithdraw(uint256 pid) external {
        Pool storage pool = pools[pid];
        User storage user = users[pid][msg.sender];

        uint oldUserAmount = user.stakingBalance;

        pool.stakingTokenBalance -= oldUserAmount;
        user.stakingBalance = 0;
        user.rewardDebt = 0;

        pool.stakingToken.safeTransfer(address(msg.sender), oldUserAmount);

        emit EmergencyWithdraw(msg.sender, pid, oldUserAmount);
    }


    function safeRewardTokenTransfer(address to, uint256 amount) internal {
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        if (amount > rewardTokenBalance) {
            rewardToken.transfer(to, rewardTokenBalance);
        } else {
            rewardToken.transfer(to, amount);
        }
    }

    function setFeeAddress(address feeAddress_) external {
        require(msg.sender == feeAddress, "setFeeAddress: unauthorized");
        feeAddress = feeAddress_;
    }
}
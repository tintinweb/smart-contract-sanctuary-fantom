/**
 *Submitted for verification at FtmScan.com on 2022-03-31
*/

// File: ../Contracts/Rewarder.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SignedSafeMath.sol
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
    * @dev Returns the multiplication of two signed integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    *
    * - Multiplication cannot overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
    * @dev Returns the integer division of two signed integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    *
    * - The divisor cannot be zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Returns the subtraction of two signed integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    *
    * - Subtraction cannot overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
    * @dev Returns the addition of two signed integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    *
    * - Addition cannot overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }

    function toUInt256(int256 a) internal pure returns (uint256) {
        require(a >= 0, "Integer < 0");
        return uint256(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while(i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    /// @return successes An array indicating the success of a call, mapped one-to-one to `calls`.
    /// @return results An array with the returned data of each function call, mapped one-to-one to `calls`.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results) {
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = result;
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

interface IRewarder {
    function updateUser(uint256 poolId, address user, uint256 averageDepositTime, uint256 rewardableDeposit) external;
    function claim(uint256 poolId, address user, address to) external;
}

interface IMasterMind {
    struct UserInfo {
        uint256 unused_1;
        uint256 unused_2;
        uint256 unused_3;
        uint256 averageDepositTime;
    }

    struct PoolInfo {
        address unused_1;
        address unused_2;
        uint256 unused_3;
        uint256 unused_4;
        uint256 rewardableDeposits;
    }

    function poolInfo(uint256 poolId) external view returns (PoolInfo memory);
    function userInfo(uint256 poolId, address user) external view returns (UserInfo memory);
    function poolCount() external view returns (uint256);
}


contract Rewarder is IRewarder,  BoringOwnable{
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;

    IERC20 public immutable rewardToken;
    IMasterMind public immutable masterMind;
    address public immutable rewarderVault;

    uint256 public averageBlockTimeInMilliseconds = 13000;
    uint256 internal lastRecordedBlockNumber;
    uint256 internal lastRecordedBlockTimestamp;

    struct UserInfo {
        uint256 rewardableDeposit;
        uint256 lifetimeRewardPerOneEtherOfDeposit;
        uint256 pendingReward;
    }

    struct PoolInfo {
        uint256 lifetimeRewardPerOneEtherOfDeposit;
        uint256 lastRewardBlock;
        uint256 allocationPoints;
    }

    mapping (uint256 => PoolInfo) public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    uint256 totalAllocationPoints;

    bool public rewardPerBlockFixed;
    uint256 public rewardPerBlock;
    uint256 public rewardRate = 300;
    uint256 public constant REWARD_RATE_DENOMINATOR = 100;

    uint256 internal constant BOOST_BASE = 1000;
    uint256 internal weeklyBoost = 75;
    uint256 internal monthlyBoost = 150;
    uint256 internal yearlyBoost  = 250;

    address public dev;
    address public dao;
    uint256 public constant FEE_BASE = 1000;
    uint256 public devFee = 100;
    uint256 public daoFee = 100;

    event UpdateUser(address indexed user, uint256 indexed poolId, uint256 shares);
    event Claim(address indexed user, uint256 indexed poolId, uint256 rewardAmount, address to);
    event AddPool(uint256 indexed poolId, uint256 allocationPoints);
    event SetFixedRewardPerBlock(uint256 rewardPerBlock);
    event SetFloatingRewardPerBlock(uint256 rewardRate);
    event UpdatePoolAllocationPoints(uint256 indexed poolId, uint256 newAllocationPoints);
    event UpdatePool(uint256 indexed poolId, uint256 lastRewardBlock, uint256 totalShares, uint256 lifetimeRewardPerExashare); 

    constructor (IERC20 _rewardToken, IMasterMind _masterMind, address _rewarderVault, uint256 _rewardPerBlock, address _dao) public {
        rewardToken = _rewardToken;
        masterMind = _masterMind;
        rewarderVault = _rewarderVault;
        rewardPerBlock = _rewardPerBlock;
        rewardPerBlockFixed = true;
        dev = msg.sender;
        dao = _dao;
        lastRecordedBlockNumber = block.number;
        lastRecordedBlockTimestamp = block.timestamp;        
    }

    modifier onlyMM {
        require(
            msg.sender == address(masterMind),
            "Only MM can call this function."
        );
        _;
    }

    function _boost(uint256 averageDepositTime) internal view returns (uint256) {
        require(averageDepositTime >= block.timestamp, "boost: user from future");
        uint256 timeElapsed = averageDepositTime - uint256(block.timestamp);
        if( timeElapsed > 30 days) {
            return monthlyBoost + (yearlyBoost - monthlyBoost)*(timeElapsed - 30 days) / (365 days - 30 days);
        }

        if( timeElapsed > 7 days) {
            return weeklyBoost + (monthlyBoost - weeklyBoost)*(timeElapsed - 7 days) / (30 days - 7 days);
        }

        return weeklyBoost * timeElapsed / 7 days; 
    }

    function boost(uint256 averageDepositTime) external view returns (uint256) {
        return _boost(averageDepositTime);
    }

    function updateUser(uint256 poolId, address userAddress, uint256 averageDepositTime, uint256 rewardableDeposit) onlyMM override external {
        PoolInfo memory pool = updatePool(poolId);
        UserInfo storage user = userInfo[poolId][userAddress];
        assert(pool.lifetimeRewardPerOneEtherOfDeposit >= user.lifetimeRewardPerOneEtherOfDeposit);
        uint256 oneEtherOfDepositRewardAppreciation = pool.lifetimeRewardPerOneEtherOfDeposit - user.lifetimeRewardPerOneEtherOfDeposit;
        if(oneEtherOfDepositRewardAppreciation > 0) {
            uint256 rewardAmount = oneEtherOfDepositRewardAppreciation.mul(user.rewardableDeposit);
            uint256 boostedRewardAmount = rewardAmount.mul(BOOST_BASE + _boost(averageDepositTime))/BOOST_BASE;
            user.pendingReward = user.pendingReward.add(boostedRewardAmount / (1 ether));
        }

        user.rewardableDeposit = rewardableDeposit;
        user.lifetimeRewardPerOneEtherOfDeposit = pool.lifetimeRewardPerOneEtherOfDeposit;
        emit UpdateUser(userAddress, poolId, rewardableDeposit);
    }

    function claim(uint256 poolId, address userAddress, address to) onlyMM override external {
        UserInfo storage user = userInfo[poolId][userAddress];
        if(user.pendingReward > 0) {
            uint256 rewardAmount = user.pendingReward;
            user.pendingReward = 0;
            rewardToken.safeTransferFrom(rewarderVault, to, rewardAmount);
            rewardToken.safeTransferFrom(rewarderVault, dev, rewardAmount.mul(devFee) / FEE_BASE);
            rewardToken.safeTransferFrom(rewarderVault, dao, rewardAmount.mul(daoFee) / FEE_BASE);
            emit Claim(userAddress, poolId, rewardAmount, to);
        }
    }

    function _updateAverageBlockTime() internal {
        uint256 blocksElapsed = uint256(block.number).sub(lastRecordedBlockNumber);
        if(blocksElapsed > 10 ) {
            uint256 timeElapsed = block.timestamp.sub(lastRecordedBlockTimestamp) * 1000;
            uint256 newAverageBlockTimeInMilliseconds = timeElapsed / blocksElapsed;
            // exponential smoothing
            averageBlockTimeInMilliseconds = (averageBlockTimeInMilliseconds * 4 + newAverageBlockTimeInMilliseconds) / 5;

            lastRecordedBlockTimestamp = block.timestamp;
            lastRecordedBlockNumber = block.number;
        }
    }

    function _updateRewardPerBlock() internal {
        _updateAverageBlockTime();
        if (!rewardPerBlockFixed){
            uint256 amount = rewardToken.balanceOf(rewarderVault);
            rewardPerBlock = amount.mul(rewardRate).mul(averageBlockTimeInMilliseconds) / uint256(365 days * 1000) / REWARD_RATE_DENOMINATOR;
        }
    }

    function updateBoostingConstants(uint256 newWeeklyBoost, uint256 newMonthlyBoost, uint256 newYearlyBoost ) external onlyOwner {
        weeklyBoost = newWeeklyBoost;
        monthlyBoost = newMonthlyBoost;
        yearlyBoost = newYearlyBoost;
    }

    function updateDev(address newDev) external onlyOwner {
        dev = newDev;
    }

    function updateDao(address newDao) external onlyOwner {
        dao = newDao;
    }

    function updaterewardPerBlock(bool fixRewardPerBlock, uint256 newRewardPerBlock, uint256 newRewardRate) external onlyOwner {
        rewardPerBlockFixed = fixRewardPerBlock;
        if(rewardPerBlockFixed) {
            require(newRewardRate == 0, "rewardRate doesn't make sense with fixed reward per block");
            rewardPerBlock = newRewardPerBlock;
            emit SetFixedRewardPerBlock(newRewardPerBlock);
        } else {
            require(newRewardPerBlock == 0, "rewardPerBlock doesn't make sense with floating reward per block");
            rewardRate = newRewardRate;
            _updateRewardPerBlock();
            emit SetFloatingRewardPerBlock(newRewardRate);
        }
    }

    /// @notice Returns the number of MM pools.
    function poolCount() public view returns (uint256 pools) {
        pools = masterMind.poolCount();
    }

    function addBulk(uint256[] memory allocationPointsList, uint256[] memory poolIdList) external onlyOwner{
        for (uint i = 0; i < allocationPointsList.length; i++) {
            uint256 allocationPoints = allocationPointsList[i];
            uint256 poolId = poolIdList[i];
            require(poolInfo[poolId].lastRewardBlock == 0, "Pool already exists");
            totalAllocationPoints = totalAllocationPoints.add(allocationPoints);
            poolInfo[poolId] = PoolInfo({
                allocationPoints: allocationPoints,
                lastRewardBlock: block.number,
                lifetimeRewardPerOneEtherOfDeposit: 0
            });

            emit AddPool(poolId, allocationPoints);
        }
    }

    function updatePoolAllocationPoints(uint256 poolId, uint256 newAllocationPoints) external onlyOwner {
        totalAllocationPoints = totalAllocationPoints.sub(poolInfo[poolId].allocationPoints).add(newAllocationPoints);
        poolInfo[poolId].allocationPoints = newAllocationPoints;
        emit UpdatePoolAllocationPoints(poolId, newAllocationPoints);
    }

    function massUpdatePoolAllocationPoints(uint256[] memory poolIds, uint256[] memory newAllocationPoints) external onlyOwner {
        for (uint i = 0; i < poolIds.length; i++) {
            totalAllocationPoints = totalAllocationPoints.sub(poolInfo[poolIds[i]].allocationPoints).add(newAllocationPoints[i]);
            poolInfo[poolIds[i]].allocationPoints = newAllocationPoints[i];
            emit UpdatePoolAllocationPoints(poolIds[i], newAllocationPoints[i]);
        }
    }

    function pendingReward(uint256 poolId, address userAddress) external view returns (uint256 _pendingReward) {
        PoolInfo memory pool = poolInfo[poolId];
        UserInfo storage user = userInfo[poolId][userAddress];
        _pendingReward = user.pendingReward;
        uint256 lifetimeRewardPerOneEtherOfDeposit = pool.lifetimeRewardPerOneEtherOfDeposit;
        if (block.number > pool.lastRewardBlock) {
            uint256 rewardableDeposits = masterMind.poolInfo(poolId).rewardableDeposits;
            if (rewardableDeposits > 0) {
                uint256 blocks = uint256(block.number - pool.lastRewardBlock);
                uint256 reward = blocks.mul(rewardPerBlock).mul(pool.allocationPoints) / totalAllocationPoints;
                lifetimeRewardPerOneEtherOfDeposit = lifetimeRewardPerOneEtherOfDeposit.add(reward.mul(1 ether) / rewardableDeposits);
            }
        }

        uint256 oneEtherOfDepositRewardAppreciation = lifetimeRewardPerOneEtherOfDeposit - user.lifetimeRewardPerOneEtherOfDeposit;
        if(oneEtherOfDepositRewardAppreciation > 0) {
            uint256 rewardAmount = oneEtherOfDepositRewardAppreciation.mul(user.rewardableDeposit);
            uint256 averageDepositTime = masterMind.userInfo(poolId, userAddress).averageDepositTime;
            uint256 boostedRewardAmount = rewardAmount.mul(BOOST_BASE + _boost(averageDepositTime))/BOOST_BASE;
            _pendingReward = _pendingReward.add(boostedRewardAmount / (1 ether));
        }
    }

    function massUpdatePools(uint256[] calldata poolIdList) public {
        for (uint256 i = 0; i < poolIdList.length; ++i) {
            updatePool(poolIdList[i]);
        }
    }

    function updatePool(uint256 poolId) public returns (PoolInfo memory pool) {
        pool = poolInfo[poolId];
        require(pool.lastRewardBlock != 0, "Pool does not exist");
        if (block.number > pool.lastRewardBlock) {
            uint256 rewardableDeposits = masterMind.poolInfo(poolId).rewardableDeposits;
            if (rewardableDeposits > 0) {
                uint256 blocks = uint256(block.number - pool.lastRewardBlock);
                uint256 reward = blocks.mul(rewardPerBlock).mul(pool.allocationPoints) / totalAllocationPoints;
                pool.lifetimeRewardPerOneEtherOfDeposit = pool.lifetimeRewardPerOneEtherOfDeposit.add(reward.mul(1 ether) / rewardableDeposits);
            }

            pool.lastRewardBlock = block.number;
            poolInfo[poolId] = pool;
            emit UpdatePool(poolId, pool.lastRewardBlock, rewardableDeposits, pool.lifetimeRewardPerOneEtherOfDeposit);
        }

        _updateRewardPerBlock();
    }
}
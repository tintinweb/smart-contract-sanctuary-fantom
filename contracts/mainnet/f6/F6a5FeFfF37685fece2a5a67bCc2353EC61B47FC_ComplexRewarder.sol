/**
 *Submitted for verification at FtmScan.com on 2022-12-31
*/

// SPDX-License-Identifier: MIT
// @audit - I modified versions from 0.8.10 to 0.8.7 to match the rest of the contracts

/**
 *
 * Propblem:
 * ComplexRewarder has a flaw. If there are not enough tokens available then the transaction reverts,
 * breaking the whole transaction and stopping users from taking their profit tokens.
 *
 * Solution:
 * Add accounting to the rewarder that can keep track of the amount of tokens that were unable to be
 * paid to users, that they can claim later IF the rewarder is filled again.
 *
 * It should be possible to stop rewarder emissions, add enough tokens to cover the outstanding user
 * debt and let them claim their tokens on the next reward.
 *
 * We should track the total token debt and the individual debt per user.
 *
 */

pragma solidity 0.8.7;

interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IRewarder {
  function onReward(uint256 pid, address user, address recipient, uint256 rewardAmount, uint256 newLpAmount) external;

  function pendingTokens(
    uint256 pid,
    address user,
    uint256 rewardAmount
  ) external view returns (IERC20[] memory, uint256[] memory);
}

interface IVault {
  function getPricePerFullShare() external view returns (uint256);

  function depositOutputTokenForUsers(uint256 _amount) external;

  function balance() external view returns (uint256);
}

interface IERC20Permit {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function nonces(address owner) external view returns (uint256);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

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

  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
      if (returndata.length > 0) {
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

library SafeERC20 {
  using Address for address;

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
      uint256 newAllowance = oldAllowance - value;
      _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
  }

  function safePermit(
    IERC20Permit token,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    uint256 nonceBefore = token.nonces(owner);
    token.permit(owner, spender, value, deadline, v, r, s);
    uint256 nonceAfter = token.nonces(owner);
    require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

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

  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

abstract contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    _status = _ENTERED;

    _;

    _status = _NOT_ENTERED;
  }
}

library EnumerableSet {
  struct Set {
    bytes32[] _values;
    mapping(bytes32 => uint256) _indexes;
  }

  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);

      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  function _remove(Set storage set, bytes32 value) private returns (bool) {
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) {
      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;

      if (lastIndex != toDeleteIndex) {
        bytes32 lastValue = set._values[lastIndex];

        set._values[toDeleteIndex] = lastValue;

        set._indexes[lastValue] = valueIndex;
      }

      set._values.pop();

      delete set._indexes[value];

      return true;
    } else {
      return false;
    }
  }

  function _contains(Set storage set, bytes32 value) private view returns (bool) {
    return set._indexes[value] != 0;
  }

  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    return set._values[index];
  }

  function _values(Set storage set) private view returns (bytes32[] memory) {
    return set._values;
  }

  struct Bytes32Set {
    Set _inner;
  }

  function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _add(set._inner, value);
  }

  function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _remove(set._inner, value);
  }

  function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
    return _contains(set._inner, value);
  }

  function length(Bytes32Set storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
    return _at(set._inner, index);
  }

  function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
    return _values(set._inner);
  }

  struct AddressSet {
    Set _inner;
  }

  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(uint160(value))));
  }

  function remove(AddressSet storage set, address value) internal returns (bool) {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  function contains(AddressSet storage set, address value) internal view returns (bool) {
    return _contains(set._inner, bytes32(uint256(uint160(value))));
  }

  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(AddressSet storage set, uint256 index) internal view returns (address) {
    return address(uint160(uint256(_at(set._inner, index))));
  }

  function values(AddressSet storage set) internal view returns (address[] memory) {
    bytes32[] memory store = _values(set._inner);
    address[] memory result;

    assembly {
      result := store
    }

    return result;
  }

  struct UintSet {
    Set _inner;
  }

  function add(UintSet storage set, uint256 value) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  function remove(UintSet storage set, uint256 value) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  function contains(UintSet storage set, uint256 value) internal view returns (bool) {
    return _contains(set._inner, bytes32(value));
  }

  function length(UintSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(UintSet storage set, uint256 index) internal view returns (uint256) {
    return uint256(_at(set._inner, index));
  }

  function values(UintSet storage set) internal view returns (uint256[] memory) {
    bytes32[] memory store = _values(set._inner);
    uint256[] memory result;

    assembly {
      result := store
    }

    return result;
  }
}

interface IRewarderExt is IRewarder {
  function pendingToken(uint _pid, address _user) external view returns (uint pending);

  function rewardToken() external view returns (IERC20);
}

interface IERC20Ext is IERC20 {
  function decimals() external returns (uint);
}

interface IMasterChefV2 {
  function balance() external view returns (uint);
}

contract ChildRewarder is IRewarder, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  IERC20 public rewardToken;

  struct UserInfo {
    uint amount;
    uint rewardDebt;
  }

  struct PoolInfo {
    uint128 accRewardPerShare;
    uint64 lastRewardTime;
    uint64 allocPoint;
  }

  mapping(uint => PoolInfo) public poolInfo;

  uint[] public poolIds;

  mapping(uint => mapping(address => UserInfo)) public userInfo;

  uint public totalAllocPoint;

  uint public rewardPerSecond;
  uint public ACC_TOKEN_PRECISION;

  address public MASTERCHEF_V2;

  address public PARENT;

  bool notinit = true;

  event LogOnReward(address indexed user, uint indexed pid, uint amount, address indexed to);
  event LogPoolAddition(uint indexed pid, uint allocPoint);
  event LogSetPool(uint indexed pid, uint allocPoint);
  event LogUpdatePool(uint indexed pid, uint lastRewardTime, uint lpSupply, uint accRewardPerShare);
  event LogRewardPerSecond(uint rewardPerSecond);
  event AdminTokenRecovery(address _tokenAddress, uint _amt, address _adr);
  event LogInit();

  modifier onlyParent() {
    require(msg.sender == PARENT, "Only PARENT can call this function.");
    _;
  }

  constructor() {}

  function init(IERC20Ext _rewardToken, uint _rewardPerSecond, address _MASTERCHEF_V2) external {
    require(notinit);

    uint decimalsRewardToken = _rewardToken.decimals();
    require(decimalsRewardToken < 30, "Token has way too many decimals");
    ACC_TOKEN_PRECISION = 10 ** (30 - decimalsRewardToken);
    rewardToken = _rewardToken;
    rewardPerSecond = _rewardPerSecond;
    MASTERCHEF_V2 = _MASTERCHEF_V2;
    PARENT = msg.sender;

    notinit = false;
  }

  function onReward(uint _pid, address _user, address _to, uint, uint _amt) external override onlyParent nonReentrant {
    PoolInfo memory pool = updatePool(_pid);
    if (pool.lastRewardTime == 0) return;
    UserInfo storage user = userInfo[_pid][_user];
    uint pending;
    if (user.amount > 0) {
      pending = ((user.amount * pool.accRewardPerShare) / ACC_TOKEN_PRECISION) - user.rewardDebt;
      rewardToken.safeTransfer(_to, pending);
    }
    user.amount = _amt;
    user.rewardDebt = (_amt * pool.accRewardPerShare) / ACC_TOKEN_PRECISION;
    emit LogOnReward(_user, _pid, pending, _to);
  }

  function pendingTokens(
    uint pid,
    address user,
    uint
  ) external view override returns (IERC20[] memory rewardTokens, uint[] memory rewardAmounts) {
    IERC20[] memory _rewardTokens = new IERC20[](1);
    _rewardTokens[0] = (rewardToken);
    uint[] memory _rewardAmounts = new uint[](1);
    _rewardAmounts[0] = pendingToken(pid, user);
    return (_rewardTokens, _rewardAmounts);
  }

  function setRewardPerSecond(uint _rewardPerSecond) public onlyOwner {
    rewardPerSecond = _rewardPerSecond;
    emit LogRewardPerSecond(_rewardPerSecond);
  }

  function poolLength() public view returns (uint pools) {
    pools = poolIds.length;
  }

  function add(uint64 allocPoint, uint _pid, bool _update) public onlyOwner {
    require(poolInfo[_pid].lastRewardTime == 0, "Pool already exists");
    if (_update) {
      massUpdatePools();
    }
    uint64 lastRewardTime = uint64(block.timestamp);
    totalAllocPoint = totalAllocPoint + allocPoint;

    PoolInfo storage poolinfo = poolInfo[_pid];
    poolinfo.allocPoint = allocPoint;
    poolinfo.lastRewardTime = lastRewardTime;
    poolinfo.accRewardPerShare = 0;
    poolIds.push(_pid);
    emit LogPoolAddition(_pid, allocPoint);
  }

  function set(uint _pid, uint64 _allocPoint, bool _update) public onlyOwner {
    require(poolInfo[_pid].lastRewardTime != 0, "Add pool first");
    if (_update) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
    poolInfo[_pid].allocPoint = _allocPoint;
    emit LogSetPool(_pid, _allocPoint);
  }

  function pendingToken(uint _pid, address _user) public view returns (uint pending) {
    PoolInfo memory pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint accRewardPerShare = pool.accRewardPerShare;
    uint lpSupply = IMasterChefV2(MASTERCHEF_V2).balance();

    if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
      uint time = block.timestamp - pool.lastRewardTime;
      uint reward = totalAllocPoint == 0 ? 0 : ((time * rewardPerSecond * pool.allocPoint) / totalAllocPoint);
      accRewardPerShare = accRewardPerShare + ((reward * ACC_TOKEN_PRECISION) / lpSupply);
    }
    pending = ((user.amount * accRewardPerShare) / ACC_TOKEN_PRECISION) - user.rewardDebt;
  }

  function massUpdatePools() public {
    uint len = poolIds.length;
    for (uint i = 0; i < len; ++i) {
      updatePool(poolIds[i]);
    }
  }

  function updatePool(uint pid) public returns (PoolInfo memory pool) {
    pool = poolInfo[pid];
    if (pool.lastRewardTime == 0) return pool;
    if (block.timestamp > pool.lastRewardTime) {
      uint lpSupply = IMasterChefV2(MASTERCHEF_V2).balance();

      if (lpSupply > 0) {
        uint time = block.timestamp - pool.lastRewardTime;
        uint reward = totalAllocPoint == 0 ? 0 : ((time * rewardPerSecond * pool.allocPoint) / totalAllocPoint);
        pool.accRewardPerShare = pool.accRewardPerShare + uint128((reward * ACC_TOKEN_PRECISION) / lpSupply);
      }
      pool.lastRewardTime = uint64(block.timestamp);
      poolInfo[pid] = pool;
      emit LogUpdatePool(pid, pool.lastRewardTime, lpSupply, pool.accRewardPerShare);
    }
  }

  function recoverTokens(address _tokenAddress, uint _amt, address _adr) external onlyOwner {
    IERC20(_tokenAddress).safeTransfer(_adr, _amt);

    emit AdminTokenRecovery(_tokenAddress, _amt, _adr);
  }
}

contract ComplexRewarder is IRewarder, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  IERC20 public rewardToken;

  struct UserInfo {
    uint amount;
    uint rewardDebt;
    uint rewardsOwed;
  }

  struct PoolInfo {
    uint128 accRewardPerShare;
    uint64 lastRewardTime;
    uint64 allocPoint;
  }

  mapping(uint => PoolInfo) public poolInfo;

  uint[] public poolIds;

  mapping(uint => mapping(address => UserInfo)) public userInfo;

  uint public totalAllocPoint;
  uint public totalRewardsOwed;
  uint public rewardPerSecond;
  uint public ACC_TOKEN_PRECISION;

  address public immutable VAULT;

  EnumerableSet.AddressSet private childrenRewarders;

  event LogOnReward(address indexed user, uint indexed pid, uint amount, address indexed to);
  event LogPoolAddition(uint indexed pid, uint allocPoint);
  event LogSetPool(uint indexed pid, uint allocPoint);
  event LogUpdatePool(uint indexed pid, uint lastRewardTime, uint lpSupply, uint accRewardPerShare);
  event LogRewardPerSecond(uint rewardPerSecond);
  event AdminTokenRecovery(address _tokenAddress, uint _amt, address _adr);
  event LogInit();
  event ChildCreated(address indexed child, address indexed token);
  event ChildRemoved(address indexed child);

  modifier onlyVault() {
    require(msg.sender == VAULT, "Only Vault can call this function.");
    _;
  }

  constructor(address _VAULT) {
    VAULT = _VAULT;
  }

  function init(IERC20Ext _rewardToken, uint _rewardPerSecond) external onlyOwner {
    require(address(rewardToken) == address(0), "Rewarder already initialised...");
    uint decimalsRewardToken = _rewardToken.decimals();
    require(decimalsRewardToken < 30, "Token has way too many decimals");
    ACC_TOKEN_PRECISION = 10 ** (30 - decimalsRewardToken);
    rewardToken = _rewardToken;
    rewardPerSecond = _rewardPerSecond;
  }

  function createChild(IERC20Ext _rewardToken, uint _rewardPerSecond) external onlyOwner {
    ChildRewarder child = new ChildRewarder();
    child.init(_rewardToken, _rewardPerSecond, VAULT);
    Ownable(address(child)).transferOwnership(msg.sender);
    childrenRewarders.add(address(child));
    emit ChildCreated(address(child), address(_rewardToken));
  }

  function removeChild(address childRewarder) external onlyOwner {
    if (!childrenRewarders.remove(childRewarder)) revert("That is not my child rewarder!");
    emit ChildRemoved(childRewarder);
  }

  function getChildrenRewarders() external view returns (address[] memory) {
    return childrenRewarders.values();
  }

  function onReward(uint _pid, address _user, address _to, uint, uint _amt) external override onlyVault nonReentrant {
    PoolInfo memory pool = updatePool(_pid);
    if (pool.lastRewardTime == 0) return;
    UserInfo storage user = userInfo[_pid][_user];
    uint pending;

    uint rewardTokenBalance = rewardToken.balanceOf(address(this));
    uint rewardsOwed = user.rewardsOwed;

    if (user.amount > 0) {
      uint initialRewardsOwed = rewardsOwed;
      if (rewardsOwed > 0) {
        uint amountToRepay;

        if (rewardsOwed > rewardTokenBalance) {
          amountToRepay = rewardTokenBalance;
          rewardsOwed -= rewardTokenBalance;
        } else {
          amountToRepay = user.rewardsOwed;
          rewardsOwed = 0;
        }
        if (amountToRepay > 0) {
          rewardToken.safeTransfer(_to, amountToRepay);
          emit LogOnReward(_user, _pid, amountToRepay, _to);
        }
      }

      rewardTokenBalance = rewardToken.balanceOf(address(this));
      pending = ((user.amount * pool.accRewardPerShare) / ACC_TOKEN_PRECISION) - user.rewardDebt;

      if (pending > rewardTokenBalance) {
        rewardsOwed += pending - rewardTokenBalance;
        pending = rewardTokenBalance;
      }
      if (pending > 0) {
        rewardToken.safeTransfer(_to, pending);
      }

      if (rewardsOwed > initialRewardsOwed) {
        totalRewardsOwed += rewardsOwed - initialRewardsOwed;
      } else {
        totalRewardsOwed -= initialRewardsOwed - rewardsOwed;
      }
    }

    user.amount = _amt;
    user.rewardDebt = (_amt * pool.accRewardPerShare) / ACC_TOKEN_PRECISION;
    user.rewardsOwed = rewardsOwed;

    if (pending > 0) {
      emit LogOnReward(_user, _pid, pending, _to);
    }
    uint len = childrenRewarders.length();
    for (uint i = 0; i < len; ) {
      IRewarder(childrenRewarders.at(i)).onReward(_pid, _user, _to, 0, _amt);
      unchecked {
        ++i;
      }
    }
  }

  function pendingTokens(
    uint pid,
    address user,
    uint
  ) external view override returns (IERC20[] memory rewardTokens, uint[] memory rewardAmounts) {
    uint len = childrenRewarders.length() + 1;
    rewardTokens = new IERC20[](len);
    rewardTokens[0] = rewardToken;
    rewardAmounts = new uint[](len);
    rewardAmounts[0] = pendingToken(pid, user);
    for (uint i = 1; i < len; ) {
      IRewarderExt rew = IRewarderExt(childrenRewarders.at(i - 1));
      rewardAmounts[i] = rew.pendingToken(pid, user);
      rewardTokens[i] = rew.rewardToken();
      unchecked {
        ++i;
      }
    }
  }

  function setRewardPerSecond(uint _rewardPerSecond) public onlyOwner {
    rewardPerSecond = _rewardPerSecond;
    emit LogRewardPerSecond(_rewardPerSecond);
  }

  function poolLength() public view returns (uint pools) {
    pools = poolIds.length;
  }

  function add(uint64 allocPoint, uint _pid, bool _update) public onlyOwner {
    require(poolInfo[_pid].lastRewardTime == 0, "Pool already exists");
    if (_update) {
      massUpdatePools();
    }
    uint64 lastRewardTime = uint64(block.timestamp);
    totalAllocPoint = totalAllocPoint + allocPoint;

    PoolInfo storage poolinfo = poolInfo[_pid];
    poolinfo.allocPoint = allocPoint;
    poolinfo.lastRewardTime = lastRewardTime;
    poolinfo.accRewardPerShare = 0;
    poolIds.push(_pid);
    emit LogPoolAddition(_pid, allocPoint);
  }

  function set(uint _pid, uint64 _allocPoint, bool _update) public onlyOwner {
    require(poolInfo[_pid].lastRewardTime != 0, "Add pool first");
    if (_update) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
    poolInfo[_pid].allocPoint = _allocPoint;
    emit LogSetPool(_pid, _allocPoint);
  }

  function pendingToken(uint _pid, address _user) public view returns (uint pending) {
    PoolInfo memory pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint accRewardPerShare = pool.accRewardPerShare;
    uint lpSupply = IVault(VAULT).balance();

    if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
      uint time = block.timestamp - pool.lastRewardTime;
      uint reward = totalAllocPoint == 0 ? 0 : ((time * rewardPerSecond * pool.allocPoint) / totalAllocPoint);
      accRewardPerShare = accRewardPerShare + ((reward * ACC_TOKEN_PRECISION) / lpSupply);
    }
    pending = ((user.amount * accRewardPerShare) / ACC_TOKEN_PRECISION) - user.rewardDebt;
  }

  function massUpdatePools() public {
    uint len = poolIds.length;
    for (uint i = 0; i < len; ++i) {
      updatePool(poolIds[i]);
    }
  }

  function updatePool(uint pid) public returns (PoolInfo memory pool) {
    pool = poolInfo[pid];
    if (pool.lastRewardTime == 0) return pool;
    if (block.timestamp > pool.lastRewardTime) {
      uint lpSupply = IVault(VAULT).balance();

      if (lpSupply > 0) {
        uint time = block.timestamp - pool.lastRewardTime;
        uint reward = totalAllocPoint == 0 ? 0 : ((time * rewardPerSecond * pool.allocPoint) / totalAllocPoint);
        pool.accRewardPerShare = pool.accRewardPerShare + uint128((reward * ACC_TOKEN_PRECISION) / lpSupply);
      }
      pool.lastRewardTime = uint64(block.timestamp);
      poolInfo[pid] = pool;
      emit LogUpdatePool(pid, pool.lastRewardTime, lpSupply, pool.accRewardPerShare);
    }
  }

  function recoverTokens(address _tokenAddress, uint _amt, address _adr) external onlyOwner {
    IERC20(_tokenAddress).safeTransfer(_adr, _amt);

    emit AdminTokenRecovery(_tokenAddress, _amt, _adr);
  }
}
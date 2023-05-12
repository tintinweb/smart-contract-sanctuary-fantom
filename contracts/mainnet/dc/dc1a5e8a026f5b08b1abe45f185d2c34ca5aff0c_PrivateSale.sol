/**
 *Submitted for verification at FtmScan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT
interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {

        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity ^0.7.6;

contract PrivateSale is Ownable {
  using SafeMath for *;
  using SafeERC20 for IERC20;
  using Address for address payable;

  address[] whitelist;
  mapping(address => bool) whitelisted;

  mapping(address => uint8) public tierOf;
  mapping(uint8 => uint256) public minAllocationOfTier;
  mapping(uint8 => uint256) public maxAllocationOfTier;
  mapping(uint8 => uint256) public totalPurchaseOfTier;
  mapping(uint8 => uint256) public hardcapOfTier;

  mapping(address => uint256) public purchaseOf;
  mapping(address => uint256) public volumeOf;
  mapping(address => bool) public withdrawn;

  uint256 public startDate;
  uint256 public endDate;

  address public token;
  uint256 public rate; // how many tokens can one buy with 1BNB

  event Purchased(address user, uint256 amount, uint256 volume);
  event Distributed(address user, uint256 volumer);

  modifier inProgress() {
      require(block.timestamp >= startDate, "Pool not started yet");
      require(block.timestamp < endDate, "Pool ended");
      _;
  }

  modifier isWhitelisted() {
    require(tierOf[_msgSender()] >= 1 && tierOf[_msgSender()] <= 3, "Invalid tier");
    _;
}

  constructor(address token_, uint256 rate_, uint256 startDate_, uint256 endDate_, uint256[3] memory caps) {
    token = token_;
    rate = rate_;
    startDate = startDate_;
    endDate = endDate_;

    populateCaps(caps);
  }

  receive() external payable {
    if (msg.value >= 0) {
      purchase();
    }
  }

  function purchase() public payable inProgress isWhitelisted {
    require(msg.value > 0, "Purchase with 0");

    uint8 tier = tierOf[_msgSender()];

    uint256 minAllocation = minAllocationOfTier[tier];
    uint256 maxAllocation = maxAllocationOfTier[tier];
    uint256 totalUserPurchase = purchaseOf[_msgSender()].add(msg.value);
    require(totalUserPurchase >= minAllocation, "Purchase less than min allocation");
    require(totalUserPurchase <= maxAllocation, "Purchase more than max allocation");

    uint256 totalTierPurchase = totalPurchaseOfTier[tier];
    require(totalTierPurchase.add(msg.value) <= hardcapOfTier[tier], "Hardcap for this tier reached");

    purchaseOf[_msgSender()] = totalUserPurchase;
    uint256 volume = msg.value.mul(rate).div(1e18);
    volumeOf[_msgSender()] = volumeOf[_msgSender()].add(volume);
    totalPurchaseOfTier[tier] = totalPurchaseOfTier[tier].add(msg.value);

    emit Purchased(_msgSender(), msg.value, volume);
}

  function setDate(uint256 startDate_, uint256 endDate_) external onlyOwner {
    startDate = startDate_;
    endDate = endDate_;
  }

  function setAllocationForTier(uint8 tier, uint256 minAmount, uint256 maxAmount) external onlyOwner {
    require(tier >= 1 && tier <= 3, "Invalid tier");
    require(minAmount <= maxAmount, "Min amount should be less than or equal to maxAmount");
    minAllocationOfTier[tier] = minAmount;
    maxAllocationOfTier[tier] = maxAmount;
}

  function addAllocation(address[] memory users, uint8 tier) external onlyOwner {
    require(tier >= 1 && tier <= 3, "Invalid tier");
    for (uint256 i = 0; i < users.length; i++) {
        if (tierOf[users[i]] == 0) {
            tierOf[users[i]] = tier;
            whitelist.push(users[i]);
        }
    }
}

  function distribute(address user) external onlyOwner {
    require(!withdrawn[user], "User has withdrawn their purchase");
    require(purchaseOf[user] > 0, "User has not purchased");
    withdrawn[user] = true;
    IERC20(token).safeTransfer(user, volumeOf[user]);
    emit Distributed(user, volumeOf[user]);
  }

  function distributeAll() external onlyOwner {
    for (uint256 i = 0; i < whitelist.length; i++) {
      _silentDistribute(whitelist[i]);
    }
  }

  function distributeRange(uint256 start, uint256 end) external onlyOwner {
    require (start < end, "Invalid range");
    require (end < whitelist.length, "End index should be whitelist length - 1 at most");

    for (uint256 i = start; i <= end; i++) {
      _silentDistribute(whitelist[i]);
    }
  }

  function _silentDistribute(address user) internal onlyOwner {
    if (purchaseOf[user] > 0 && !withdrawn[user]) {
      withdrawn[user] = true;
      IERC20(token).safeTransfer(user, volumeOf[user]);
      emit Distributed(user, volumeOf[user]);
    }
  }

  function withdrawEarnings() public onlyOwner {
    // Earnings amount of the owner
    uint256 totalEarnings = address(this).balance;
    payable(_msgSender()).sendValue(totalEarnings);
  }

  function recoverTokens(address token_, address to_) public onlyOwner {
    IERC20(token_).safeTransfer(
        to_,
        IERC20(token_).balanceOf(address(this))
    );
  }

  function allocationFor(address user) public view returns (uint256) {
    uint8 tier = tierOf[user];
    if (tier < 1 || tier > 3) return 0;
    uint256 available = maxAllocationOfTier[tier].sub(purchaseOf[user]);
    return available;
}

  function getNumberOfWhitelisted() public view returns (uint256) {
    return whitelist.length;
}

  function isUserWhitelisted(address user) public view returns (bool, uint256) {
    return (tierOf[user] > 0, tierOf[user]);
}

  function populateCaps(uint256[3] memory caps) private {
    hardcapOfTier[1] = caps[0];
    hardcapOfTier[2] = caps[1];
    hardcapOfTier[3] = caps[2];
}
}
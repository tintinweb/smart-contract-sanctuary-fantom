// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IThrifty.sol";

import "./libraries/Roles.sol";

contract ThriftyRole is Ownable {
  using SafeMath for uint256;
  using Roles for Roles.Role;

  Roles.Role private roleManualSelfLp;
  Roles.Role private roleManualTfusdLp;
  Roles.Role private roleManageGuardian;

  mapping (address => bool) public managers;

  address public autoLpReceiver;
  address public marketingWallet;
  address public treasuryWallet;
  uint256 public selfLpRate = 510000;
  
  struct vestingInfo {
    uint256 percent;
    uint256 period;
  }
  mapping (address => vestingInfo) public vestingWallet;

  bool public enableReflect = false;
  bool public enableTax = false;
  bool public enablePrint = false;
  bool public enableDaiReward = false;
  bool public onlyWhitelist = true;
  bool public enableFreeTransfer = true;
  bool public enableVesting = false;
  address[] public whiteList;
  address[] public blackList;
  mapping (address => uint256) public whiteListId;
  mapping (address => uint256) public blackListId;
  mapping(address => bool) public vipAddress;
  mapping(address => bool) public noTradeLimitAddress;
  
  bool public guardianMode = true;
  uint256 public feeGuardianLp = 10000;
  uint256 public feeMinGuardianLp = 10000;
  uint256 public feeMaxGuardianLp = 150000;
  address[] public guardians;
  mapping(address => uint256) guardianId;
  uint256 public maxGuardian = 20;

  uint256 public feeMarketing = 10000;
  uint256 public feeTreasury = 10000;
  uint256 public feeReflection = 10000;
  uint256 public feePrint = 30000;
  uint256 public feeDaiReward = 30000;
  uint256 public feeLargeSell = 30000;
  uint256 public feeMediumSell = 30000;
  uint256 public feeFreqTrade = 30000;
  uint256 public feeQuickSell = 20000;
  uint256 public feeMax = 200000;
  uint256 public thresholdLargeSell = 1000;
  uint256 public thresholdMediumSell = 500;
  uint256 public thresholdFreqTrade = 24 * 3600;
  uint256 public thresholdQuickSell = 7 * 24 * 3600;
  uint256 public manageDecimal = 6;

  bool public enableTFUSDAutoLp;

  mapping(address => uint256) public lastTrade;
  mapping(address => uint256) public lastSell;

  struct sellInfo {
    uint256 amount;
    uint256 sellAt;
  }
  mapping(address => sellInfo[]) public sellHistory;

  address public thriftyAddress;

  event GetFee(uint256[8] f);

  constructor() {
    autoLpReceiver = msg.sender;
    marketingWallet = msg.sender;
    treasuryWallet = msg.sender;

    managers[msg.sender] = true;
    managers[address(this)] = true;
    Roles.add(roleManageGuardian, msg.sender);
  }

  modifier onlyManager() {
    require(managers[msg.sender], "!manager");
    _;
  }

  modifier onlyThrifty() {
    require(msg.sender == thriftyAddress, "!Thrifty");
    _;
  }

  /*********************************************************************************************/
  /******************                   Check Role                  ****************************/
  /*********************************************************************************************/
  function hasManualSelfLpRole(address account) public view returns(bool) {
    return Roles.has(roleManualSelfLp, account);
  }

  function hasTFUSDLpRole(address account) public view returns(bool) {
    return Roles.has(roleManualTfusdLp, account);
  }

  /*********************************************************************************************/
  /******************                  Calculate Fee                ****************************/
  /*********************************************************************************************/
  function validateTransfer(address from, address to, uint256 userBalance, uint256 amount) public returns(bool) {
    if (blackListId[from] > 0 || blackListId[to] > 0) return false;
    if (onlyWhitelist == true && (whiteListId[from] == 0 || whiteListId[to] == 0)) return false;
    bool isSell = to == IThrifty(thriftyAddress).pairAddress() && msg.sender == IThrifty(thriftyAddress).uniRouter();
    bool canSell = isSell == true ? _ableToSell(from, userBalance, amount) : true;
    if (isSell == true && enableVesting == true && canSell == false) return false;
    if (isSell == true && enableVesting == true && canSell == true) {
      sellHistory[from].push(sellInfo({
        amount: amount,
        sellAt: block.timestamp
      }));
    }
    return true;
  }

  function _ableToSell(address account, uint256 userBalance, uint256 amount) internal view returns (bool) {
    uint256 len = sellHistory[account].length;
    uint256 vestingPeriod = vestingWallet[account].period;
    if (vestingPeriod == 0) return true;
    uint256 x = 0;
    for (; x<len && sellHistory[account][x].sellAt + vestingPeriod < block.timestamp; x++) {}
    uint256 totalSell = 0;
    for (; x<len; x++) {
      totalSell = totalSell.add(sellHistory[account][x].amount);
    }
    uint256 vestingPercent = vestingWallet[account].percent;
    if (totalSell.add(amount) <= userBalance.add(totalSell).mul(vestingPercent).div(10 ** manageDecimal)) return true;
    return false;
  }
  
  function getFee(address from, address to, uint256 amount) public
    returns(uint256[8] memory fees)
  {
    if (vipAddress[from] == true || vipAddress[to] == true) {
      return [amount, 0, 0, 0, 0, 0, 0, 0];
    }
    address pairAddress = IThrifty(thriftyAddress).pairAddress();
    bool isBuy = from == pairAddress && to != thriftyAddress;
    bool isSell = to == pairAddress && from != thriftyAddress;
    bool isTrade = isBuy || isSell;
    bool isTradeOrTaxTransfer = (enableTax == true && isTrade == true) || (isTrade == false && enableFreeTransfer == false);
    bool noLimitAdress = (noTradeLimitAddress[from] == true || noTradeLimitAddress[to] == true) ? true : false;

    address trader = isBuy == true ? to : (isSell == true ? from : address(0));

    // marketingFee
    fees[1] = (isTradeOrTaxTransfer == true) ? amount.mul(feeMarketing).div(10 ** manageDecimal) : 0;
    // treasuryFee
    fees[2] = (isTradeOrTaxTransfer == true) ? amount.mul(feeTreasury).div(10 ** manageDecimal) : 0;
    // reflectFee
    fees[3] = (enableReflect == true && isTrade == true) ? amount.mul(feeReflection).div(10 ** manageDecimal) : 0;
    // printFee
    fees[4] = (enablePrint == true && isTrade == true) ? amount.mul(feePrint).div(10 ** manageDecimal) : 0;
    // rewardFee
    fees[5] = (enableDaiReward == true && isTrade == true) ? amount.mul(feeDaiReward).div(10 ** manageDecimal) : 0;
    // extraFee
    fees[6] = (noLimitAdress==true || isTrade==false) ? 0 : _getExtraFee(amount, isSell, trader);
    // receive amount
    fees[0] = amount - fees[1] - fees[2] - fees[3];
    fees[0] -= fees[4] - fees[5] - fees[6];
    // total fee
    fees[7] = amount - fees[0];

    emit GetFee(fees);
    return fees;
  }

  function _getExtraFee(uint256 amount, bool isSell, address trader) internal returns(uint256 extraFee) {
    uint256 totalSupply = IThrifty(thriftyAddress).totalSupply();
    uint256 bgTradeFee = amount >= totalSupply.mul(thresholdLargeSell).div(10 ** manageDecimal) ?
      amount.mul(feeLargeSell).div(10 ** manageDecimal) : 0;
    uint256 mdTradeFee = amount >= totalSupply.mul(thresholdMediumSell).div(10 ** manageDecimal) ?
      amount.mul(feeMediumSell).div(10 ** manageDecimal) : 0;
    uint256 freqTradeFee = 0;
    if (trader != address(0) && lastTrade[trader] + thresholdFreqTrade > block.timestamp) {
      freqTradeFee = amount.mul(feeFreqTrade).div(10 ** manageDecimal);
      lastTrade[trader] = block.timestamp;
    }
    uint256 quickSellFee = 0;
    if (isSell == true && (lastTrade[trader] + thresholdQuickSell > block.timestamp)) {
      quickSellFee = amount.mul(feeQuickSell).div(10 ** manageDecimal);
      lastSell[trader] = block.timestamp;
    }
    extraFee = bgTradeFee.add(mdTradeFee).add(freqTradeFee).add(quickSellFee);
  }

  /*********************************************************************************************/
  /******************                    Manager                    ****************************/
  /*********************************************************************************************/
  function setTradeMode(uint256 mode) public onlyManager {
    if (mode == 0) { // WL+Presale
      enableReflect = false;
      enableTax = false;
      enablePrint = false;
      enableDaiReward = false;
      onlyWhitelist = true;
      enableFreeTransfer = true;
    }
    else if (mode == 1) { // WL
      enableReflect = true;
      enableTax = true;
      enablePrint = true;
      enableDaiReward = true;
      onlyWhitelist = true;
      enableFreeTransfer = false;
    }
    else if (mode == 2) { // public
      enableReflect = true;
      enableTax = true;
      enablePrint = true;
      enableDaiReward = true;
      onlyWhitelist = false;
      enableFreeTransfer = false;
    }
  }

  function setWhitelist(address wallet, bool mode) public onlyManager {
    if (mode == true && whiteListId[wallet] == 0) {
      whiteList.push(wallet);
      whiteListId[wallet] = whiteList.length;
    }
    if (mode == false && whiteListId[wallet] > 0) {
      uint256 id = whiteListId[wallet] - 1;
      whiteList[id] = whiteList[whiteList.length - 1];
      whiteList.pop();
      whiteListId[wallet] = 0;
    }
  }

  function setBlacklist(address wallet, bool mode) public onlyManager {
    if (mode == true && blackListId[wallet] == 0) {
      blackList.push(wallet);
      blackListId[wallet] = blackList.length;
    }
    if (mode == false && blackListId[wallet] > 0) {
      uint256 id = blackListId[wallet] - 1;
      blackList[id] = blackList[blackList.length - 1];
      blackList.pop();
      blackListId[wallet] = 0;
    }
  }

  function setVipAddress(address account, bool allow) public onlyManager {
    vipAddress[account] = allow;
  }

  function setNoTradeLimitAddress(address account, bool allow) public onlyManager {
    noTradeLimitAddress[account] = allow;
  }

  function setTaxReflectionPrint(bool _enable) public onlyManager{
    enableReflect = _enable;
    enableTax = _enable;
    enablePrint = _enable;
    enableDaiReward = _enable;
  }

  function setReflection(bool _enable) public onlyManager{
    enableReflect = _enable;
  }

  function setAllDaiPrint(bool _enable) public onlyManager{
    enablePrint = _enable;
    enableDaiReward = _enable;
  }

  function setLpDaiPrint(bool _enable) public onlyManager{
    enablePrint = _enable;
  }

  function setRewardDaiPrint(bool _enable) public onlyManager{
    enableDaiReward = _enable;
  }

  function setMarketingWallet(address _wallet) public onlyManager{
    marketingWallet = _wallet;
  }

  function setTreasuryWallet(address _wallet) public onlyManager{
    treasuryWallet = _wallet;
  }

  function setAutoLpReceiver(address _receiver) public onlyManager {
    require(_receiver != address(0), "ThriftyRole: zero address");
    autoLpReceiver = _receiver;
  }

  function setFreeTransfer(bool _enable) public onlyManager {
    enableFreeTransfer = _enable;
  }

  function setVestingMode(bool _enable) public onlyManager {
    enableVesting = _enable;
  }

  function setThriftyAddress(address _thriftyAddress) public onlyManager {
    require(_thriftyAddress != address(0), "ThriftyRole: zero address");
    thriftyAddress = _thriftyAddress;
    setWhitelist(thriftyAddress, true);
    setWhitelist(IThrifty(thriftyAddress).pairAddress(), true);
  }

  function setVestingInfo(address _wallet, uint256 _percent, uint256 _period) public onlyManager {
    vestingWallet[_wallet] = vestingInfo({
      percent: _percent,
      period: _period
    });
  }

  function setFee(
    uint256 _fMarketing, uint256 _fTreasury, uint256 _fReflection,
    uint256 _fPrint, uint256 _fDaiReward,
    uint256 _fLargeSell, uint256 _fMediumSell, uint256 _fFreqTrade, uint256 _fQuickSell
  ) public onlyManager {
    uint256 totalFee = _fMarketing + _fTreasury + _fReflection;
    totalFee += _fPrint + _fDaiReward + _fLargeSell;
    totalFee += _fMediumSell + _fFreqTrade + _fQuickSell;
    require(totalFee <= feeMax, "ThriftyRole: Overflow fee");
    feeMarketing = _fMarketing;
    feeTreasury = _fTreasury;
    feeReflection = _fReflection;
    feePrint = _fPrint;
    feeDaiReward = _fDaiReward;
    feeLargeSell = _fLargeSell;
    feeMediumSell = _fMediumSell;
    feeFreqTrade = _fFreqTrade;
    feeQuickSell = _fQuickSell;
  }

  function setThrehold(uint256 _tLargeSell, uint256 _tMediumSell, uint256 _tFreqTrade, uint256 _tQuickSell) public onlyManager {
    thresholdLargeSell = _tLargeSell;
    thresholdMediumSell = _tMediumSell;
    thresholdFreqTrade = _tFreqTrade;
    thresholdQuickSell = _tQuickSell;
  }

  function setSelfLpRate(uint256 _selfLpRate) public onlyManager {
    selfLpRate = _selfLpRate;
  }

  function setFeeGuardianLp(uint256 _feeGuardianLp) public onlyManager {
    require(_feeGuardianLp >= feeMinGuardianLp && _feeGuardianLp <= feeMaxGuardianLp, "Thrifty: overflow limit");
    feeGuardianLp = _feeGuardianLp;
  }

  function setGuardianMode(bool _guardianMode) public onlyManager {
    guardianMode = _guardianMode;
  }

  function setGuardian(address account, bool mode) public {
    require(Roles.has(roleManageGuardian, msg.sender), "Unauthorized");
    if (mode == true && guardianId[account] == 0) {
      require(guardians.length < maxGuardian, "ThriftyRole: exceed limit");
      Roles.add(roleManageGuardian, account);
      guardians.push(account);
      guardianId[account] = guardians.length;
    }
    else if (mode == false && guardianId[account] > 0) {
      Roles.remove(roleManageGuardian, account);
      uint256 id = guardianId[account];
      guardians[id - 1] = guardians[guardians.length - 1];
      guardians.pop();
    }
  }

  function setGuardianPrivilage(address account, uint256 mode) public onlyManager {
    require(guardianId[account] > 0, "ThriftyRole: not exist");
    if (mode == 1) {
      if (Roles.has(roleManualSelfLp, account) == false) {
        Roles.add(roleManualSelfLp, account);
      }
      if (Roles.has(roleManualTfusdLp, account) == true) {
        Roles.remove(roleManualTfusdLp, account);
      }
    }
    else if (mode == 2) {
      if (Roles.has(roleManualSelfLp, account) == true) {
        Roles.remove(roleManualSelfLp, account);
      }
      if (Roles.has(roleManualTfusdLp, account) == false) {
        Roles.add(roleManualTfusdLp, account);
      }
    }
    else if (mode == 3) {
      if (Roles.has(roleManualSelfLp, account) == false) {
        Roles.add(roleManualSelfLp, account);
      }
      if (Roles.has(roleManualTfusdLp, account) == false) {
        Roles.add(roleManualTfusdLp, account);
      }
    }
  }

  function setEnableTFUSDAutoLp(bool _enableTFUSDAutoLp) public onlyManager {
    enableTFUSDAutoLp = _enableTFUSDAutoLp;
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(!has(role, account), "Roles: account already has role");
    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(has(role, account), "Roles: account does not have role");
    role.bearer[account] = false;
  }

  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0), "Roles: account is the zero address");
    return role.bearer[account];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface IThrifty {
  function uniRouter() external view returns (address);
  function pairAddress() external view returns (address);
  function totalSupply() external view returns (uint256);
  
  function getAutoLpThriftyInAmount() external view returns (uint256);
  function setAutoLpFromTFUSD(uint256 inAmount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
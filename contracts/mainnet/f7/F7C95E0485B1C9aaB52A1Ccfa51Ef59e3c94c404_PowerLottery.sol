/**
 *Submitted for verification at FtmScan.com on 2022-04-23
*/

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

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

// File: @openzeppelin\contracts\access\Ownable.sol

pragma solidity ^0.8.0;


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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: contracts\power_lottery.sol

pragma solidity 0.8.4;

interface IVRFOracleOraichain {
    function randomnessRequest(uint256 _seed, bytes calldata _data) external payable returns (bytes32 reqId);

    function getFee() external returns (uint256);
}

contract RandomNumberClient is Ownable {

  IVRFOracleOraichain public oracle;
  bytes32 public reqId;
  uint public randomNumber;

  constructor() {
    oracle = IVRFOracleOraichain(0xd73CfDBdC35BF6709BF261171021C87a3c09E3e2); // ftm mainnet
    // oracle = IVRFOracleOraichain(0x5Dbb6aE294b983778a95B086992b37D62759ae5B); // ftm testnet
  }

  function requestRandomNumber() public {
    uint fee = oracle.getFee();
    bytes memory data = abi.encode(address(this), this.fulfillRandomness.selector);
    reqId = oracle.randomnessRequest{value: fee}(block.timestamp + block.number, data);
  }

  function fulfillRandomness(bytes32, uint256 _random) external {
    randomNumber = _random % 100;
  }

  function clearNativeCoin(address payable _to, uint256 amount) public payable onlyOwner {
    _to.transfer(amount);
  }
}

contract PowerLottery is RandomNumberClient {

  IERC20 public power;
  IERC20 public energy;

  uint public powerPerTicket = 10000000000000000000;
  uint public energyPerTicket = 10000000000000000000000;

  uint64 public drawTime;
  uint64 public lockTime;

  uint64 public openTimeSpan = 108 hours; // users buy tickets in this timespan
  uint64 public lockTimeSpan = 8 hours; // lottery is locked for this timespan before choosing winners

  bool public isOpen;
  bool public isDrawn;

  uint public roundSoldTickets;

  mapping(address => mapping(uint => uint8)) private _tickets;
  mapping(address => uint) public userRewardPower;
  mapping(address => uint) public userRewardEnergy;
  mapping(uint => address[]) private ticketToUsers;
  mapping(address => mapping(uint => uint)) public userLotteryPlace;
  mapping(address => bool) public operators;

  uint16[10] public winnerRewards = [4800, 1500, 1000, 700, 500, 400, 400, 300, 200, 200];
  address[] private _lastWinners;

  address public rewardsPool;

  uint public roundId = 1;
  uint public buyLimit = 1000;

  constructor(
    IERC20 _power,
    IERC20 _energy,
    address _rewardPool,
    uint _roundId,
    uint _soldTickets,
    address[] memory _winners
  ) {
    power = _power;
    energy = _energy;
    rewardsPool = _rewardPool;
    isDrawn = true;

    lockTime = uint64(block.timestamp);
    drawTime = uint64(block.timestamp);

    roundId = _roundId;
    roundSoldTickets = _soldTickets;
    _lastWinners = _winners;
  }

  modifier onlyOperator() {
    require (operators[msg.sender] || msg.sender == owner(), "Access denied!");
    _;
  }

  receive() payable external {}

  function setRewardPoolAddress(address _pool) external onlyOwner {
    rewardsPool = _pool;
  }

  function setOperator(address _user, bool _isOperator) external onlyOwner {
    operators[_user] = _isOperator;
  }

  function updateTicketPrice(uint _power, uint _energy) external onlyOperator {
    require(isDrawn, "Not Drawn!");

    powerPerTicket = _power;
    energyPerTicket = _energy;
  }

  function setBuyLimit(uint _limit) external onlyOperator {
    buyLimit = _limit;
  }

  function setTiming(uint64 _openSpan, uint64 _lockSpan) external onlyOperator {
    require (isDrawn, "Lottery Active");

    openTimeSpan = _openSpan;
    lockTimeSpan = _lockSpan;
  }

  function buyTickets(uint[] calldata tickets_) external {
    require (block.timestamp < lockTime && isOpen, "BUY - Locked");
    require (_tickets[msg.sender][roundId] + tickets_.length <= buyLimit, "BUY - Max limit");
    require (power.balanceOf(msg.sender) >= powerPerTicket * tickets_.length, "BUY - Insufficient POWER");
    require (energy.balanceOf(msg.sender) >= energyPerTicket * tickets_.length, "BUY - Insufficient ENERGY");

    power.transferFrom(msg.sender, address(this), powerPerTicket * tickets_.length);
    energy.transferFrom(msg.sender, address(this), energyPerTicket * tickets_.length);

    roundSoldTickets += tickets_.length;

    _tickets[msg.sender][roundId] += uint8(tickets_.length);

    uint i;
    for (i = 0; i < tickets_.length; i+=1) {
      ticketToUsers[tickets_[i]].push(msg.sender);
    }
  }

  function random() view internal returns (uint8) {
    return uint8(uint(keccak256(abi.encodePacked(blockhash(block.number), block.difficulty, block.timestamp))) % 100);
  }

  function openLottery() public onlyOperator {
    require (isDrawn, "Not drawn!");

    _openLottery();
  }

  function _openLottery() internal {
    lockTime = uint64(block.timestamp + openTimeSpan);
    drawTime = lockTime + lockTimeSpan;
    isOpen = true;
    isDrawn = false;
    roundSoldTickets = 0;
    roundId++;
  }

  function closeLottery() external onlyOperator {
    require (block.timestamp > lockTime, "Close - Not ended");

    requestRandomNumber();
    isOpen = false;
  }

  function draw(bool openNew) external onlyOperator {
    require (block.timestamp >= drawTime && !isDrawn, "DRAW - Not ended");

    if (roundSoldTickets == 0) {
      isDrawn = true;

      if (openNew) {
        _openLottery();
      }
      return;
    }

    uint16 rn = uint16(randomNumber % 100); // random number between 0 and 99

    uint id = 0;
    int16 delta = 0;

    delete _lastWinners;

    while (id < 10 && delta <= 50 && delta >= -50) {
      uint num = uint16(int16(rn) + 100 - delta) % 100;

      if (ticketToUsers[num].length > 1) {
        for (uint i = 0; i < ticketToUsers[num].length && id < 10; i++) {
          if (userLotteryPlace[ticketToUsers[num][i]][roundId] > 0) continue;

          _lastWinners.push(ticketToUsers[num][i]);
          _increaseWinnerReward(ticketToUsers[num][i], id);

          id++;
          userLotteryPlace[ticketToUsers[num][i]][roundId] = id;
        }

        delete ticketToUsers[num];
      } else if (ticketToUsers[num].length > 0) {
        if (userLotteryPlace[ticketToUsers[num][0]][roundId] == 0) {
          _lastWinners.push(ticketToUsers[num][0]);
          _increaseWinnerReward(ticketToUsers[num][0], id);
          id++;

          userLotteryPlace[ticketToUsers[num][0]][roundId] = id;
        }

        delete ticketToUsers[num];
      }

      if (delta <= 0) {
        delta = -delta + 1;
      } else {
        delta = -delta;
      }
    }

    power.transfer(rewardsPool, powerPerTicket * roundSoldTickets * 3 / 10);
    energy.transfer(rewardsPool, energyPerTicket * roundSoldTickets * 3 / 10);

    isDrawn = true;

    if (openNew) {
      _openLottery();
    }
  }

  function _increaseWinnerReward(address user, uint id) internal {
    userRewardPower[user] += powerPerTicket * roundSoldTickets * 7 * winnerRewards[id] / 100000;
    userRewardEnergy[user] += energyPerTicket * roundSoldTickets * 7 * winnerRewards[id] / 100000;
  }

  function lastWinners() public view returns (address[] memory) {
    return _lastWinners;
  }

  function claimWinnerReward() external {
    require (userRewardPower[msg.sender] > 0, "No reward!");

    power.transfer(msg.sender, userRewardPower[msg.sender]);
    userRewardPower[msg.sender] = 0;

    energy.transfer(msg.sender, userRewardEnergy[msg.sender]);
    userRewardEnergy[msg.sender] = 0;
  }

  function prizePoolBalance() external view returns (uint _power, uint _energy) {
    _power = (roundSoldTickets * powerPerTicket) * 7 / 10;
    _energy = (roundSoldTickets * energyPerTicket) * 7 / 10;
  }

  function tickets(address user) external view returns (uint8) {
    return _tickets[user][roundId];
  }

  function withdraw(address payable to) external onlyOwner {
    to.transfer(address(this).balance);
  }
}
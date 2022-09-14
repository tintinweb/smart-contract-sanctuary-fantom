/**
 *Submitted for verification at FtmScan.com on 2022-09-14
*/

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
/*

 
██      ██    ██  ██████ ██   ██ ██    ██ ███    ██ ██    ██ ███    ███ ██████  ███████ ██████      ██████   ██████  
██      ██    ██ ██      ██  ██   ██  ██  ████   ██ ██    ██ ████  ████ ██   ██ ██      ██   ██    ██       ██       
██      ██    ██ ██      █████     ████   ██ ██  ██ ██    ██ ██ ████ ██ ██████  █████   ██████     ██   ███ ██   ███ 
██      ██    ██ ██      ██  ██     ██    ██  ██ ██ ██    ██ ██  ██  ██ ██   ██ ██      ██   ██    ██    ██ ██    ██ 
███████  ██████   ██████ ██   ██    ██    ██   ████  ██████  ██      ██ ██████  ███████ ██   ██ ██  ██████   ██████  
                                                                                                                     
website: https://luckynumber.gg                                                                                                      
discord: https://discord.gg/bPjSKmJXAq
twitter: https://twitter.com/luckynumbergg


*/
pragma solidity >=0.6.0 <0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.6.0 <0.8.0;

interface AggregatorV3Interface 
{
  function decimals() external view returns (uint8);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

pragma solidity >=0.6.0 <0.8.0;

interface IRaffle
{
  function getNumber(uint index) external view returns(address, uint256, string calldata);
  function getOwner() external view returns(address);
  function getWinner(uint index) external;
  function getStats() external view returns (
      uint raffleId,
      address winner,
      uint256 winnerId,
      bool closed,
      uint count,
      uint256 balance,
      bool claimed);
  function setClose() external;
  function getTokenSymbol() external view returns(string calldata);
  function getName() external view returns(string calldata);
  function consumer() external view returns(address);
  function getRaffleId() external view returns(uint);
  function createGame(uint id, string memory raffleName, uint quant, uint startTime, uint finishTime, uint256 price, address token) external;
  function getValidateMember(bytes32 hash) external view returns(address);
  function getCountNumbers() external view returns(uint);

}

pragma solidity >=0.6.0 <0.8.0;

contract Consumer 
{
  
  using SafeMath for uint256;

    bytes32 sealedSeed;
    bool seedSet = false;
    bool betsClosed = false;
    uint storedBlockNumber;
    address[] raffleIndex;
    address _owner;
    address _office;
    
    address NULL_ADDRESS = 0x0000000000000000000000000000000000000000;

    uint public eventCount = 0;
    uint public winnerTotal = 0;
    uint256 public raffleTotal = 0;
    uint256 public requestId;
  
    struct RaffleStruct {
      address raffleAddress;
      uint index;
    }
    
  
    struct RaffleItem
    {
      uint raffleId;
      string name;
      uint startTime; 
      uint finishTime; 
      address token;
      uint quant;
      uint256 price; 
      string tokenSymbol;

    }

    mapping(bytes32 => address) _walletIds;
    mapping(address => mapping(uint => uint)) public results;
    mapping(address => mapping(uint => uint)) public raffleRandom;
    mapping(string => address) _aggregator;
    mapping(address => RaffleStruct) raffleStructs;
    mapping(uint => RaffleItem) public raffleItems;
    
    event Queue(
        uint raffleId,
        address raffle
    );
    event EventRafflePurchased(
          address indexed wallet,
          address indexed raffle,
          uint raffleId,
          uint timestamp,
          uint[] ids,
          uint price,
          string tokenSymbol,
          string name,
          uint tokenCount,
          uint256 balance
    );
    
    event EventRaffle(
          address indexed raffle,
          uint raffleId,
          uint timestamp,
          uint startTime,
          uint finishTime,
          uint256 price,
          uint quant, 
          address token,
          string raffleName
    );

    event EventRaffleWinner(
          address indexed winner,
          uint raffleId,
          address raffle,
          uint256 winnerId,
          uint tokenCount);

    event EventRaffleClosed(
          address indexed raffle,
          uint raffleId,
          string name,
          address winner,
          uint256 winnerId,
          uint256 price,
          uint256 startTime,
          uint256 finsihTime,
          uint tokenCount,
          uint quant,
          string tokenSymbol);
    
    modifier onlyOwner() {
      require(msg.sender == _owner);
      _;
    }

    modifier onlyConsumer(address raffle) {
      require(IRaffle(raffle).consumer() == address(this), "not consumer");
      require(IRaffle(raffle).getOwner() == _owner, "not operador");
      _;
    }

  constructor(address officeFund) 
  {

    _office = officeFund;
    _owner = msg.sender;
    _aggregator["ETH"] = 0xB8C458C957a6e6ca7Cc53eD95bEA548c52AFaA24;
    _aggregator["FTM"]  = 0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D;
  }
  
  function office() public view returns(address)
  {
      return _office;
  }

  
  function getRaffleCount()
    public 
    view
    returns( uint) 
  {
    return eventCount;
  }

  function getRaffles()
    public 
    view
    returns( address[] memory) 
  {
    return raffleIndex;
  }

  function insertRaffle(address raffleAddress) 
    internal
    returns(uint index)
  {
    
    raffleStructs[raffleAddress].raffleAddress = raffleAddress;
    raffleIndex.push(raffleAddress);
    raffleStructs[raffleAddress].index = raffleIndex.length-1;

    return raffleStructs[raffleAddress].index;
  }

  function deleteRaffle(address raffleAddress) 
    internal 
    returns(uint index)
  {
    
    uint rowToDelete = raffleStructs[raffleAddress].index;
    address keyToMove = raffleIndex[raffleIndex.length-1];
    raffleIndex[rowToDelete] = keyToMove;
    raffleStructs[keyToMove].index = rowToDelete; 
    raffleIndex.pop();
    
    return rowToDelete;
  }

  function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals)
        internal
        pure
        returns (int256)
    {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }
    

  function getPrice(string memory symbol, uint8 _decimals) public view returns (uint) 
  {
       int p = 0;
       if(_aggregator[symbol]==NULL_ADDRESS)
       {
          p = 1e18;
       }
       else
       {
        
        ( , int256 basePrice, , , ) = AggregatorV3Interface(_aggregator[symbol]).latestRoundData();
        
        uint8 baseDecimals = AggregatorV3Interface(_aggregator[symbol]).decimals();
        p = scalePrice(basePrice, baseDecimals, _decimals);

       }
       return uint(p);
   }

   function addNumbers(
        address raffle,
        uint[] memory ids, 
        uint price, 
        string memory tokenSymbol,
        string memory name) external onlyConsumer(raffle)
   {
        (uint raffleId,
        ,
        ,
        ,
        uint count,
        uint256 balance,
        ) = IRaffle(raffle).getStats();
        
        require(raffleRandom[raffle][raffleId] == 0, "closed for the draw");

        bytes32 hash = keccak256(abi.encodePacked(raffleId, ids));
        address wallet = IRaffle(raffle).getValidateMember(hash);

        require(wallet != NULL_ADDRESS, "access deined wallet");
        require(_walletIds[hash] == NULL_ADDRESS, "access deined hash");

        emit EventRafflePurchased(
                  wallet,
                  raffle,
                  raffleId,
                  block.timestamp,
                  ids,
                  price,
                  tokenSymbol, 
                  name, 
                  count,
                  balance); 
                  
        _walletIds[hash] = wallet;
  }
  function setSealedSeed(address raffle, uint raffleId) public onlyOwner
  {
      require(raffleRandom[raffle][raffleId] == 0, "waiting for the draw");

      bytes32 _sealedSeed = keccak256(abi.encodePacked(raffle, raffleId));
      storedBlockNumber = block.number + 1;
      sealedSeed = keccak256(abi.encodePacked(raffle, _sealedSeed));

      raffleRandom[raffle][raffleId] = 1;

      emit Queue(raffleId, raffle);
  }
   
  function reveal(bytes32 _seed, address raffle) internal returns(uint256)
  {
      require(keccak256(abi.encodePacked(raffle, _seed)) == sealedSeed, "not key");
      ( , int256 basePrice, , , ) = AggregatorV3Interface(_aggregator["ETH"]).latestRoundData();
      uint256 rnd = uint(keccak256(abi.encodePacked(_seed, blockhash(storedBlockNumber), basePrice)));
      return rnd;

  }
  function random(address raffle, uint raffleId, uint quant) internal 
  {
      require(raffleRandom[raffle][raffleId] == 1, "waiting for the draw");
      
      uint256 result = reveal(keccak256(abi.encodePacked(raffle, raffleId)), raffle);
      results[raffle][raffleId] = result % quant;

      raffleRandom[raffle][raffleId] = 2;
  }

  function requestRandomWords(address raffle, uint raffleId) external onlyOwner 
  {
    RaffleItem storage item = raffleItems[raffleId];
    
    uint count = IRaffle(raffle).getCountNumbers();
    if(count>0)
    {
        if(block.timestamp > item.finishTime || item.quant == count)
        {      
            random(raffle, raffleId, count);
            setWinner(results[raffle][raffleId], raffle);
            closed(raffle);
        }
    }
  }
  
  function getBalance(uint256 balance, string memory symbol) public view returns(uint256)
  { 
      uint price = uint(getPrice(symbol, 18));
      uint256 total = balance.mul(price).div(1e18);
      return total;
  }

  function reset(
          address raffle, 
          uint raffleId,
          string memory name, 
          uint quant, 
          uint startTime, 
          uint finishTime, 
          uint256 price, 
          address token) public onlyOwner
  {
     
    
    require(raffleRandom[raffle][raffleId] == 3, "not closed");
    raffleRandom[raffle][raffleId] = 0;

        addRaffle(
          raffle, 
          name, 
          quant, 
          startTime, 
          finishTime, 
          price, 
          token);
  }
  
  function closedRaffle(address raffle) public onlyOwner
  {
      require(IRaffle(raffle).getCountNumbers() == 0, "wait raffle");
      closed(raffle);
  }

  function closed(address raffle) internal
  {
    (uint raffleId,
        address winner,
        uint256 winnerId,
        ,
        uint count,
        uint256 balance,
        ) = IRaffle(raffle).getStats();
    

    RaffleItem storage item = raffleItems[raffleId];
    raffleRandom[raffle][raffleId] = 3;
    
    raffleStructs[raffle].raffleAddress = NULL_ADDRESS;
    IRaffle(raffle).setClose();
    deleteRaffle(raffle);
    
    emit EventRaffleClosed(
          raffle,
          raffleId,
          item.name,
          winner,
          winnerId,
          item.price,
          item.startTime,
          item.finishTime,
          count,
          item.quant,
          item.tokenSymbol);

    if(count>0)
    {
     
      uint amountValue = getBalance(balance, item.tokenSymbol);
      raffleTotal = raffleTotal.add(amountValue);
      winnerTotal++;
      
      emit EventRaffleWinner(winner, raffleId, raffle, winnerId, count);
    }
  }
  
  function setWinner(uint result, address raffle) internal
  {
      IRaffle(raffle).getWinner(result);
      
  }
 
  function addRaffle(
    address raffle, 
    string memory raffleName, 
    uint quant, 
    uint startTime, 
    uint finishTime, 
    uint256 price, 
    address token) public onlyOwner 
  {
    
      
      require(raffleStructs[raffle].raffleAddress == NULL_ADDRESS, "exists");

      eventCount++;
     
      IRaffle(raffle).createGame(
          eventCount, 
          raffleName, 
          quant, 
          startTime, 
          finishTime, 
          price, 
          token);

        raffleItems[eventCount] = RaffleItem(
          eventCount,
          raffleName,
          startTime,
          finishTime, 
          token,
          quant,
          price,
          IRaffle(raffle).getTokenSymbol()
        );

        emit EventRaffle(raffle, 
              eventCount, 
              block.timestamp,
              startTime,
              finishTime,
              price,
              quant,
              token,
              raffleName);
       
        insertRaffle(raffle);
  }

  function getResult(address raffle) public view returns(uint)
  {
    uint raffleId = IRaffle(raffle).getRaffleId();
    return results[raffle][raffleId];
  }
  function getOwner() public view returns(address)
  {
      return _owner;
  }
 
}
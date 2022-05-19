/**
 *Submitted for verification at FtmScan.com on 2022-05-19
*/

/*  ____                  __          __________                     _____     ___
   / __ )____ _________  / /_  ____ _/ / / ____/___ __________ ___  / ___/_  _<  /
  / __  / __ `/ ___/ _ \/ __ \/ __ `/ / / /_  / __ `/ ___/ __ `__ \/ __ \| |/_/ / 
 / /_/ / /_/ (__  )  __/ /_/ / /_/ / / / __/ / /_/ / /  / / / / / / /_/ />  </ /  
/_____/\__,_/____/\___/_.___/\__,_/_/_/_/    \__,_/_/  /_/ /_/ /_/\____/_/|_/_/   
                                                                                                                                                                    
Baseball farm 6x1 | earn money until 10% daily
SPDX-License-Identifier: MIT
*/

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
pragma solidity 0.8.11;

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

contract Ownable is Context {
    address private _owner;
    address public _dev;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BaseballFarm is Context, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;

    // Project initialized
    bool private initialized = false;
    uint256 private ballsForMiner = 1080000;

    // Tool
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private DAYS_FOR_FIXED = 1 days;
    uint256 private DAYS_FOR_SELLING = 7 days;
    uint256 private MIN_BUY = 10 ether;
    uint256 public players = 0;

    // Commissions
    uint256 private referralCommision = 12;
    uint256 private devFeeBuy = 10;
    uint256 private devFeeSell = 5;

    // Address commissions
    address private depositAddress = 0x6C728b3F6e0fCc786Cd302d98db36875302Dd531;
    address private sellingAddress = 0x0356D43C22a19630433438d28B91d01b35eDde00;

    // Mapping
    mapping(address => uint256) private games;
    mapping(address => uint256) private claimedBall;
    mapping(address => uint256) private lastSelling;
    mapping(address => uint256) private lastFixed;
    mapping(address => address) private referrals;

    // Project
    uint256 private marketBalls;

    constructor() Ownable() {}

    // Functions for use public
    function addImprovement(address ref) public {
        require(initialized);

        if (ref == _msgSender()) {
            ref = address(0);
        }

        if (
            referrals[_msgSender()] == address(0) &&
            referrals[_msgSender()] != _msgSender()
        ) {
            referrals[_msgSender()] = ref;
            if (games[_msgSender()] == 0) {
                players = players.add(1);
                lastSelling[_msgSender()] = block.timestamp;
                lastFixed[_msgSender()] = block.timestamp;
            }
        }
        uint256 ballsUsed = getMyBalls(_msgSender());
        uint256 improvement = SafeMath.div(ballsUsed, ballsForMiner);
        games[_msgSender()] = SafeMath.add(games[_msgSender()], improvement);
        claimedBall[_msgSender()] = 0;
        //send referral balls
        claimedBall[referrals[_msgSender()]] = SafeMath.add(
            claimedBall[referrals[_msgSender()]],
            SafeMath.div(ballsUsed, referralCommision)
        );
        //boost market to nerf miners hoarding
        marketBalls = SafeMath.add(marketBalls, SafeMath.div(ballsUsed, 5));
    }

    function sellBalls() public {
        require(initialized);
        require(
            lastSelling[_msgSender()].add(DAYS_FOR_SELLING) <= block.timestamp,
            "Only can seller every 6 days"
        );
        uint256 balls = getMyBalls(_msgSender());
        uint256 valueBalls = calculateBallSell(balls);
        claimedBall[_msgSender()] = 0;
        lastSelling[_msgSender()] = block.timestamp;
        lastFixed[_msgSender()] = block.timestamp;
        marketBalls = SafeMath.add(marketBalls, balls);
        payFee(valueBalls, false);
        payable(_msgSender()).transfer(
            SafeMath.sub(
                valueBalls,
                SafeMath.div(SafeMath.mul(valueBalls, devFeeSell), 100)
            )
        );
    }

    function ballsRewards(address adr) public view returns (uint256) {
        uint256 balls = getMyBalls(adr);
        uint256 value = calculateBallSell(balls);
        return value;
    }

    function buyBalls(address ref) public payable {
        require(initialized);
        require(msg.value >= MIN_BUY);
        uint256 ballsBought = calculateBallBuy(
            msg.value,
            SafeMath.sub(address(this).balance, msg.value)
        );
        ballsBought = SafeMath.sub(
            ballsBought,
            SafeMath.div(SafeMath.mul(ballsBought, devFeeBuy), 100)
        );
        payFee(msg.value, true);
        claimedBall[_msgSender()] = SafeMath.add(
            claimedBall[_msgSender()],
            ballsBought
        );
        addImprovement(ref);
    }

    function openGame() public payable onlyOwner {
        require(marketBalls == 0);
        initialized = true;
        marketBalls = 108000000000;
    }

    // Functions for use internal
    function getMyBalls(address adr) public view returns (uint256) {
        return SafeMath.add(claimedBall[adr], getBallsSinceLastFixed(adr));
    }

    function getBallsSinceLastFixed(address adr) public view returns (uint256) {
        uint256 timeLastFixed = SafeMath.sub(block.timestamp, lastFixed[adr]);
        uint256 secondsPassed = min(
            ballsForMiner,
            timeLastFixed > 1 days ? 1 days : timeLastFixed
        );
        return SafeMath.mul(secondsPassed, games[adr]);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getDaysForSell(address adr) public view returns (uint256) {
        return lastSelling[adr].add(DAYS_FOR_SELLING);
    }

    function getDaysWithoutFixed(address adr) public view returns (uint256) {
        return lastFixed[adr] == 0 ? 0 : block.timestamp.sub(lastFixed[adr]);
    }

    function getDaysForFixed(address adr) public view returns (uint256) {
        return lastFixed[adr].add(DAYS_FOR_FIXED);
    }

    function getMyGames(address adr) public view returns (uint256) {
        return games[adr];
    }

    function getPlayers() public view returns (uint256) {
        return players;
    }

    function calculateTrade(
        uint256 amount,
        uint256 market,
        uint256 balance
    ) private view returns (uint256) {
        return
            SafeMath.div(
                SafeMath.mul(PSN, balance),
                SafeMath.add(
                    PSNH,
                    SafeMath.div(
                        SafeMath.add(
                            SafeMath.mul(PSN, market),
                            SafeMath.mul(PSNH, amount)
                        ),
                        amount
                    )
                )
            );
    }

    function calculateBallSell(uint256 balls) public view returns (uint256) {
        return calculateTrade(balls, marketBalls, address(this).balance);
    }

    function calculateBallBuy(uint256 eth, uint256 contractBalance)
        public
        view
        returns (uint256)
    {
        return calculateTrade(eth, contractBalance, marketBalls);
    }

    function payFee(uint256 amount, bool isBuy) internal {
        uint256 devFee = isBuy ? devFeeBuy : devFeeSell;
        uint256 devFeeCalculated = SafeMath.div(
            SafeMath.mul(amount, devFee),
            100
        );
        address devAddress = isBuy ? depositAddress : sellingAddress;
        payable(devAddress).transfer(devFeeCalculated);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
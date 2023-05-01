/**
 *Submitted for verification at FtmScan.com on 2023-05-01
*/

//SPDX-License-Identifier: MIT


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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File @openzeppelin/contracts/access/[email protected]

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    using SafeMath for uint256;

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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



pragma solidity ^0.8.0;

contract Raffle is Ownable {
    address public dev = 0x8BD493ca98fF0e6C82D16Ea679c3FC3fCd81208F;
    address public winner;
    address public protocolWallet = 0x10e642E61fC8646327DF18E922FACFcD2168A8bB;


    IERC20 public erc20Token;

    // The list of participants in the raffle
    // Every time one buys a ticket, their address is added
    // to this list. More tickets => higher chance of winning
    address[] participants;
    mapping (address => uint) public count;

    // The ticket price and raffle end time (in seconds or absolute UNIX timestamps)
    // as decided by the executor of this contract
    uint256 ticketPrice = 1000000000000000000000;
    uint raffleEndTime;

    using SafeMath for uint256;

    uint256 prizePool;
    uint256 split;
    uint256 devFee;
    uint256 protocolFee;
    uint256 ticketsSold;
    uint256 addedAmount;

    // A check to see if the winner has been found
    bool public raffleOver = false;
    bool public isWinnerPicked = false;
    bool public addedIncentive = false;

    constructor(uint _raffleTime) payable {
        raffleEndTime = _raffleTime;
    }

    function setERC20Token(IERC20 newToken) public onlyOwner {erc20Token = newToken;}

    function devPayout() public onlyOwner {
        erc20Token.transfer(dev, devFee);
        devFee = 0;}

    function protocolPayout() public onlyOwner {
        erc20Token.transfer(protocolWallet, protocolFee);
        protocolFee = 0;}


    function setProtocolWallet(address newProtocolWallet) public onlyOwner {protocolWallet = newProtocolWallet;}

    function setDevWallet(address newDevWallet) public onlyOwner {dev = newDevWallet;}

    function setNewEndTime(uint newEndTime) public onlyOwner {raffleEndTime = newEndTime;}

    function getParticipants() public view returns(address[] memory) { return participants; }

    function setRaffleOver() external onlyOwner {raffleOver = !raffleOver; }

    function getOwner() public view returns (address) { return address(dev); }

    function getProtocolWallet() public view returns (address) { return address(protocolWallet); }

    function getIncentive() public view returns (uint256) { return addedAmount; }

    function getWinner() public view returns (address) { return address(winner); }

    function getPrizePool() public view returns (uint256) { return prizePool ; }

    function getSplit() public view returns (uint256) { return split ; }

    function getDevFee() public view returns (uint256) { return devFee; }

    function getProtocolFee() public view returns (uint256) { return protocolFee; }

    function getTicketPrice() public view returns (uint) { return ticketPrice; }

    function getRaffleEndTime() public view returns (uint) { return raffleEndTime; }

    function howMuchLonger() public view returns (uint) { return raffleEndTime - block.timestamp; }

    function totalTicketsSold() public view returns (uint256) { return ticketsSold; }

    function ticketsByUser(address user) public view returns(uint) {return count[user];}

    function updateEndTime(uint newRaffleEndTime) public onlyOwner {raffleEndTime = newRaffleEndTime;}


    // The function for a participant to buy n amount of raffle tickets
    function buyTicket(uint256 amount) public {
        require(raffleOver == false);
        require(block.timestamp <= raffleEndTime, "The raffle has ended.");
        uint256 totalAmount = (ticketPrice.mul(amount));

        IERC20(erc20Token).transferFrom(msg.sender, address(this), totalAmount);

            split = totalAmount.div(2);
            uint256 devFeeSplit = split.div(10);
            uint256 protocolFeeSplit = split.sub(devFeeSplit);
            uint256 prizePoolSplit = totalAmount.sub(split);

            devFee += devFeeSplit;
            protocolFee += protocolFeeSplit;
            prizePool += prizePoolSplit;

        for (uint256 i = 1; i <= amount; i++) {
            participants.push(msg.sender);
            ticketsSold += 1;
            count[msg.sender] += 1;
        }
    }

        // Owner Added Incentive
    function addToPool(uint256 amount) public onlyOwner {

        IERC20(erc20Token).transferFrom(msg.sender, address(this), amount);

            split = amount.div(2);
            uint256 devFeeSplit = split.div(10);
            uint256 protocolFeeSplit = split.sub(devFeeSplit);
            uint256 prizePoolSplit = amount.sub(split);
            devFee += devFeeSplit;
            protocolFee += protocolFeeSplit;
            prizePool += prizePoolSplit;
            addedAmount += split;
            addedIncentive = true;
    }


        function drawWinner() public onlyOwner {
        require((raffleOver == true), "The raffle has not ended");

        uint winnerIdx = ((block.number-1) % participants.length);
        winner = payable(participants[winnerIdx]);
        isWinnerPicked = true;
    }


    function payout() public onlyOwner {
        require(raffleOver == true);
        require(isWinnerPicked == true, "No winner has been drawn.");


        // Transfer the raffle winnings
        erc20Token.transfer(winner, prizePool);
        prizePool = 0;
    }
}
/**
 *Submitted for verification at FtmScan.com on 2022-04-27
*/

// SPDX-License-Identifier: MIT

/*
* 𝕊𝕡𝕠𝕠𝕜𝕪 ℝ𝕚𝕔𝕖
* https://spookyrice.finance
* Spooky Rice - Fantom (FTM) Miner
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity 0.8.13;

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

contract Auth is Context {
    address internal _owner;
    mapping (address => bool) internal authorizations;
	
	constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
	  authorizations[_owner] = true;
      emit OwnershipTransferred(msgSender);
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        _owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract SRFTMu is Context, Auth {
    using SafeMath for uint256;

    uint256 private RICE_TO_COOK_1MINERS = 1080000;//for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    bool private initialized = false;
    address payable private marketing;
	address payable private ceoAddress;
	address payable private communityRep;
    mapping (address => uint256) private hatcheryMiners;
    mapping (address => uint256) private claimedRice;
    mapping (address => uint256) private lastHatch;
    mapping (address => address) private referrals;
    uint256 private marketRice;
	mapping (address => bool) public isBot;
    
    constructor() {
        marketing =   payable(0xcE19BBB9b3106d057f63B98eBb5C358eaB2500Fc);
		ceoAddress=   payable(0xAcEC69aa0c14416Ba8192481DB9aC09F95FD625C);
		communityRep= payable(0x6047314dbD7579e3e3f4D7877181780F8E27D938);
		authorizations[ceoAddress] = true;
		authorizations[communityRep] = true;
        authorizations[marketing] = true;
    }
    
    function reCookRice(address ref) public {
        require(initialized);
		require(!isBot[msg.sender], "You are blacklisted");
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 riceUsed = getMyRice(msg.sender);
        uint256 newMiners = SafeMath.div(riceUsed,RICE_TO_COOK_1MINERS);
        hatcheryMiners[msg.sender] = SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedRice[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        
        //send referral eggs
        claimedRice[referrals[msg.sender]] = SafeMath.add(claimedRice[referrals[msg.sender]],SafeMath.div(riceUsed,8));
        
        //boost market to nerf miners hoarding
        marketRice=SafeMath.add(marketRice,SafeMath.div(riceUsed,5));
    }
	
	function setIsBot(address user, bool state) external authorized{
		require(user != address(marketing), "SpookyRice: cannot add Marketing to the bot list");
        require(user != address(ceoAddress), "SpookyRice: cannot add ceoAddress to the bot list");
		require(user != address(communityRep), "SpookyRice: cannot add communityRep to the bot list");
        isBot[user] = state;
    } 
    
    function eatRice() public {
        require(initialized);
		require(!isBot[msg.sender], "You are blacklisted");
        uint256 hasRice = getMyRice(msg.sender);
        uint256 riceValue = calculateRiceSell(hasRice);
        uint256 fee = devFee(riceValue);
		uint256 ceoAddressFee=fee/5;
		uint256 MarketingFee=fee - ceoAddressFee;
		claimedRice[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketRice = SafeMath.add(marketRice,hasRice);
		ceoAddress.transfer(ceoAddressFee);
        marketing.transfer(MarketingFee);
		payable (msg.sender).transfer(SafeMath.sub(riceValue,fee));
    }
    
    function riceRewards(address adr) public view returns(uint256) {
        uint256 hasRice = getMyRice(adr);
        uint256 riceValue = calculateRiceSell(hasRice);
        return riceValue;
    }
    
    function cookRice(address ref) public payable {
        require(initialized);
		require(!isBot[msg.sender], "You are blacklisted");
        uint256 eggsBought = calculateEggBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        eggsBought = SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee = devFee(msg.value);
		uint256 ceoAddressFee=fee/5;
		uint256 MarketingFee=fee - ceoAddressFee;
		ceoAddress.transfer(ceoAddressFee);
        marketing.transfer(MarketingFee);
        claimedRice[msg.sender] = SafeMath.add(claimedRice[msg.sender],eggsBought);
        reCookRice(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateRiceSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs,marketRice,address(this).balance);
    }
    
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketRice);
    }
    
    function calculateEggBuySimple(uint256 eth) public view returns(uint256) {
        return calculateEggBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,3),100);
    }
    
    function seedMarket() public onlyOwner {
        require(marketRice == 0);
        initialized = true;
        marketRice = 108000000000;
        hatcheryMiners[marketing] = SafeMath.div(marketRice,10);
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return hatcheryMiners[adr];
    }
    
    function getMyRice(address adr) public view returns(uint256) {
        return SafeMath.add(claimedRice[adr],getEggsSinceLastHatch(adr));
    }
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(RICE_TO_COOK_1MINERS,SafeMath.sub(block.timestamp,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    //to recieve FTM fees from $BLUD token transactions when launched to complement SpookyRice
    receive() external payable {}
}
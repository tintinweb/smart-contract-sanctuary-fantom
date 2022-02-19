/**
 *Submitted for verification at FtmScan.com on 2022-02-19
*/

pragma solidity 0.8.5;

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)





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

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)



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

// SPDX-License-Identifier: AGPL-3.0-or-later




//NRT is like a private stock
//can only be traded with the issuer who remains in control of the market
//until he opens the redemption window
contract FairLaunchNRT is Ownable {
    uint256 private _issuedSupply;
    uint256 private _outstandingSupply;
    uint256 private _decimals;
    string private _symbol;

    mapping(address => uint256) private _balances;

    event Issued(address account, uint256 amount);
    event Redeemed(address account, uint256 amount);

    constructor(string memory __symbol, uint256 __decimals) {
        _symbol = __symbol;
        _decimals = __decimals;
        _issuedSupply = 0;
        _outstandingSupply = 0;
    }

    // Creates amount NRT and assigns them to account
    function issue(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "zero address");

        _issuedSupply += amount;
        _outstandingSupply += amount;
        _balances[account] += amount;

        emit Issued(account, amount);
    }

    //redeem, caller handles transfer of created value
    function redeem(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "zero address");
        require(_balances[account] >= amount, "Insufficent balance");

        _balances[account] -= amount;
        _outstandingSupply -= amount;

        emit Redeemed(account, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function issuedSupply() public view returns (uint256) {
        return _issuedSupply;
    }

    function outstandingSupply() public view returns (uint256) {
        return _outstandingSupply;
    }
}

// https://eips.ethereum.org/EIPS/eip-20






////////////////////////////////////
//
//  Fair Price Launch Contract
//  Every gets the same price in the end
//  Users get issued a non-transferable token  and redeem for the final token
//
////////////////////////////////////
contract FairPriceLaunch is Ownable {   
    using SafeMath for uint256; 

    FairLaunchNRT public nrt;

    address public fundsRedeemer;
    // The token used for contributions
    address public investToken;

    // the token to be launched
    address public launchToken;
    

    //Limits
    uint256 public maxInvestAllowed;
    uint256 public minInvestAllowed;
    uint256 public maxInvestRemovablePerPeriod;
    uint256 public maxGlobalInvestAllowed;
    uint256 public maxRedeemableToIssue;

    //totals
    uint256 public totalGlobalInvested;
    uint256 public totalGlobalIssued;
    uint256 public totalGlobalRedeemed;
    uint256 public totalInvestors;

    //TIMES
    // The time that sale will begin
    uint256 public launchStartTime;
    // length of sale period
    uint256 public saleDuration;
    // launchStartTime.add(sale) durations
    uint256 public launchEndTime;
    //The delay required between investment removal
    uint256 public investRemovalDelay;
    //Prices
    uint256 public startingPrice;
    uint256 public finalPrice;

    //toggles
    // sale has started
    bool public saleEnabled;
    bool public claimEnabled;
    bool public redeemEnabled;
    bool public finalized;

    //EVENTS
    event SaleEnabled(bool enabled, uint256 time);
    event ClaimEnabled(bool enabled, uint256 time);
    event RedeemEnabled(bool enabled, uint256 time);

    event Invest(
        address investor,
        uint256 amount,
        uint256 totalInvested,
        uint256 price
    );
    event RemoveInvestment(
        address investor,
        uint256 amount,
        uint256 totalInvested,
        uint256 price
    );
    event Claimed(address account, uint256 amount);
    event Redeemed(address account, uint256 amount);

    //Structs

    struct Withdrawal {
        uint256 timestamp;
        uint256 amount;
    }

    struct InvestorInfo {
        uint256 totalInvested;
        uint256 totalClaimed;
        uint256 totalRedeemed;
        uint256 totalInvestableExchanged;
        Withdrawal[] withdrawHistory;
        bool hasClaimed;
        bool hasRedeemed;
    }

    mapping(address => InvestorInfo) public investorInfoMap;
    address[] public investorList;

    constructor(
        address _fundsRedeemer,
        address _investToken,
        address _nrtAddress,
        uint256 _launchStartTime,
        uint256 _saleDuration,
        uint256 _investRemovalDelay,
        uint256 _maxInvestAllowed,
        uint256 _minInvestAllowed,
        uint256 _maxInvestRemovablePerPeriod,
        uint256 _maxGlobalInvestAllowed,
        uint256 _maxRedeemableToIssue,
        uint256 _startingPrice        
    ) {
        require(
            _launchStartTime > block.timestamp,
            "Start time must be in the future."
        );
        require(
            _minInvestAllowed >= 0,
            "Min invest amount must not be negative"
        );
        require(_startingPrice >= 0, "Starting price must not be negative");
        require(_fundsRedeemer != address(0), "fundsRedeemer address is not set.");

        fundsRedeemer = _fundsRedeemer;
        investToken = _investToken;
        //times
        launchStartTime = _launchStartTime;
        require(_saleDuration < 4 days, "duration too long");
        launchEndTime = _launchStartTime.add(_saleDuration);
        saleDuration = _saleDuration;
        investRemovalDelay = _investRemovalDelay;
        //limits
        maxInvestAllowed = _maxInvestAllowed;
        minInvestAllowed = _minInvestAllowed;
        maxGlobalInvestAllowed = _maxGlobalInvestAllowed;
        maxInvestRemovablePerPeriod = _maxInvestRemovablePerPeriod;
        maxRedeemableToIssue = _maxRedeemableToIssue;
        startingPrice = _startingPrice;
        //NRT is passed in as argument and this contract needs to be set as owner        
        saleEnabled = false;
        claimEnabled = false;
        redeemEnabled = false;

        // NRT
        nrt = FairLaunchNRT(_nrtAddress);
    }

    //User functions
    /**
    @dev Invests the specified amoount of investToken
     */
    function invest(uint256 amountToInvest) public {
        require(saleEnabled, "Sale is not enabled yet");
        require(block.timestamp >= launchStartTime, "Sale has not started yet");
        require(amountToInvest >= minInvestAllowed, "Invest amount too small");
        require(!hasSaleEnded(), "Sale period has ended");        
        require(
            totalGlobalInvested.add(amountToInvest) <= maxGlobalInvestAllowed,
            "Maximum Investments reached"
        );

        InvestorInfo storage investor = investorInfoMap[msg.sender];
        require(
            investor.totalInvested.add(amountToInvest) <= maxInvestAllowed,
            "Max individual investment reached"
        );
        //transact
        require(
            IERC20(investToken).transferFrom(
                msg.sender,
                address(this),
                amountToInvest
            ),
            "transfer failed"
        );
        if (investor.totalInvested == 0) {
            totalInvestors += 1;
            investorList.push(msg.sender);
        }
        investor.totalInvestableExchanged += amountToInvest;
        investor.totalInvested += amountToInvest;
        totalGlobalInvested += amountToInvest;
        //continuously updates finalPrice until the last contribution is made.
        finalPrice = currentPrice();
        emit Invest(
            msg.sender,
            amountToInvest,
            totalGlobalInvested,
            finalPrice
        );
    }

    /**
    @dev Returns the total amount withdrawn by the _address during the last hour
    **/

    function getLastPeriodWithdrawals(address _address)
        public
        view
        returns (uint256 totalWithdrawLastHour)
    {
        InvestorInfo storage investor = investorInfoMap[_address];

        Withdrawal[] storage withdrawHistory = investor.withdrawHistory;
        for (uint256 i = 0; i < withdrawHistory.length; i++) {
            Withdrawal memory withdraw = withdrawHistory[i];
            if (withdraw.timestamp >= block.timestamp.sub(investRemovalDelay)) {
                totalWithdrawLastHour = totalWithdrawLastHour.add(
                    withdrawHistory[i].amount
                );
            }
        }
    }

    /**
    @dev Removes the specified amount from the users totalInvested balance and returns the amount of investTokens back to them
     */
    function removeInvestment(uint256 amountToRemove) public {
        require(saleEnabled, "Sale is not enabled yet");
        require(block.timestamp >= launchStartTime, "Sale has not started yet");
        require(block.timestamp < launchEndTime, "Sale has ended");
        require(
            totalGlobalInvested < maxGlobalInvestAllowed,
            "Maximum Investments reached, deposits/withdrawal are disabled"
        );
        require(amountToRemove <= maxInvestRemovablePerPeriod, "Cannot remove more than the maximum by period");

        InvestorInfo storage investor = investorInfoMap[msg.sender];

        //Two checks of funds to prevent over widrawal
        require(
            amountToRemove <= investor.totalInvested,
            "Cannot Remove more than invested"
        );
        
        //Make sure they can't withdraw too often.
        Withdrawal[] storage withdrawHistory = investor.withdrawHistory;
        uint256 authorizedWithdraw = maxInvestRemovablePerPeriod.sub(
            getLastPeriodWithdrawals(msg.sender)
        );
        require(
            amountToRemove <= authorizedWithdraw,
            "Max withdraw reached for this hour"
        );
        withdrawHistory.push(
            Withdrawal({timestamp: block.timestamp, amount: amountToRemove})
        );
        //transact
        investor.totalInvestableExchanged += amountToRemove;
        investor.totalInvested -= amountToRemove;
        totalGlobalInvested -= amountToRemove;
        require(
            IERC20(investToken).transferFrom(
                address(this),
                msg.sender,
                amountToRemove
            ),
            "transfer failed"
        );

        finalPrice = currentPrice();

        emit RemoveInvestment(
            msg.sender,
            amountToRemove,
            totalGlobalInvested,
            finalPrice
        );
    }

    /**
    * @dev Claims the NRT tokens equivalent to their contribution
    */
    function claimRedeemable() public {
        require(claimEnabled, "claim not enabled");
        require(block.timestamp >= launchEndTime, "Time to claim has not arrived");        

        InvestorInfo storage investor = investorInfoMap[msg.sender];
        require(!investor.hasClaimed, "Tokens already claimed");
        require(investor.totalInvested > 0, "No investment made");        

        uint256 issueAmount = investor.totalInvested.mul(10**9).div(finalPrice);
        investor.hasClaimed = true;
        investor.totalClaimed = issueAmount;
        totalGlobalIssued = totalGlobalIssued.add(issueAmount);
        
        // Claim bFrock
        require(issueAmount > 0, "no amount issued");
        nrt.issue(msg.sender, issueAmount);
      
        emit Claimed(msg.sender, issueAmount);
    }   


    /**
    * @dev redeem all tokens
    */
    function redeem() public {        
        require(redeemEnabled, "redeem not enabled");
        require(block.timestamp > launchEndTime, "not redeemable yet");
        uint256 redeemAmount = nrt.balanceOf(msg.sender);
        require(redeemAmount > 0, "no amount issued");
        InvestorInfo storage investor = investorInfoMap[msg.sender];
        require(!investor.hasRedeemed, "already redeemed");
        require(launchToken != address(0), "Launth token not setted");

        // Set ad Redeemed
        investor.hasRedeemed = true;

        // Send Frock Token to Investor
        require(
            IERC20(launchToken).transfer(
                msg.sender,
                redeemAmount
            ),
            "transfer failed"
        );

        // Redeem NRT and burn the NRT
        nrt.redeem(msg.sender, redeemAmount);
        
        // Add Flobal Redeemed amount
        totalGlobalRedeemed += redeemAmount;        
        
        emit Redeemed(msg.sender, redeemAmount);        
    } 

    //getters
    //calculates current price
    function currentPrice() public view returns (uint256) {
        uint256 price = computePrice();
        if (price <= startingPrice) {
            return startingPrice;
        } else {
            return price;
        }
    }

    function computePrice() public view returns (uint256) {
        return totalGlobalInvested.mul(1e9).div(maxRedeemableToIssue);
    }

    function hasSaleEnded() public view returns (bool) {
        return block.timestamp > launchStartTime.add(saleDuration);
    }

    //------ Owner Functions ------

     // define the launch token to be redeemed
    function setLaunchToken(address _launchToken) public onlyOwner {
        launchToken = _launchToken;
    }

    function enableSale() public onlyOwner {
        saleEnabled = true;
        emit SaleEnabled(true, block.timestamp);
    }

    function enableClaim() public onlyOwner {
        claimEnabled = true;
        emit ClaimEnabled(true, block.timestamp);
    }

    function enableRedeem() public onlyOwner {
        redeemEnabled = true;
        emit RedeemEnabled(true, block.timestamp);
    }

    function withdrawInvestablePool() public onlyOwner {
        require(block.timestamp > launchEndTime, "Sale has not ended");
        uint256 amount = IERC20(investToken).balanceOf(address(this));
        IERC20(investToken).transfer(fundsRedeemer, amount);        
    }

     // withdraw in case some tokens were not redeemed
    function withdrawLaunchtoken(uint256 amount) public onlyOwner {
        require(
            IERC20(launchToken).transfer(msg.sender, amount),
            "transfer failed"
        );
    }

    function changeStartTime(uint256 newTime) public onlyOwner {
        require(newTime > block.timestamp, "Start time must be in the future.");
        require(block.timestamp < launchStartTime, "Sale has already started");
        launchStartTime = newTime;
        //update endTime
        launchEndTime = newTime.add(saleDuration);
    }
}
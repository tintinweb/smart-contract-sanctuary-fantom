/**
 *Submitted for verification at FtmScan.com on 2022-02-11
*/

pragma solidity 0.8.5;

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

// SPDX-License-Identifier: AGPL-3.0-or-later




//NRT is like a private stock
//can only be traded with the issuer who remains in control of the market
//until he opens the redemption window
contract CommunityOfferingNRT is Ownable {
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




// *********************************
// Fair Launch pool
// *********************************
// cap increases gradually over time
// this allows a maximum number of participants and still fill the round

contract CommunityOffering is Ownable {
    
    // the token address the cash is raised in
    // assume decimals is 18
    address public investToken;
    // the token to be launched
    address public launchToken;
    // proceeds go to treasury
    address public treasury;
    // the certificate
    CommunityOfferingNRT public nrt;
    // fixed single price
    uint256 public price = 8;
    // ratio quote in 100
    uint256 public priceQuote = 100;
    // the cap at the beginning
    uint256 public initialCap;
    // maximum cap
    uint256 public maxCap;
    // the total amount in stables to be raised
    uint256 public totalraiseCap;
    // how much was raised
    uint256 public totalraised;
    // how much was issued
    uint256 public totalissued;
    // how much was redeemed
    uint256 public totalredeem;
    // start of the sale
    uint256 public startTime;
    // total duration
    uint256 public duration;
    // length of each epoch
    uint256 public epochTime;
    // end of the sale    
    uint256 public endTime;
    // sale has started
    bool public saleEnabled;
    // redeem is possible
    bool public redeemEnabled;
    // minimum amount
    uint256 public mininvest;
    //MAG decimals = 9, MIM decimals = 18
    uint256 public launchDecimals = 9; 
    //
    uint256 public numWhitelisted = 0;
    //
    uint256 public numInvested = 0;
    
    event SaleEnabled(bool enabled, uint256 time);
    event RedeemEnabled(bool enabled, uint256 time);
    event Invest(address investor, uint256 amount);
    event Redeem(address investor, uint256 amount);

    struct InvestorInfo {
        uint256 amountInvested; // Amount deposited by user
        bool claimed; // has claimed MAG
    }

    // user is whitelisted
    mapping(address => bool) public whitelisted;

    mapping(address => InvestorInfo) public investorInfoMap;
    
    constructor(
        address _investToken,
        uint256 _startTime,  
        uint256 _duration,  
        uint256 _epochTime,
        uint256 _initialCap,     
        uint256 _totalraiseCap,
        uint256 _minInvest,
        address _treasury,
        address _nrtAddress
    ) {
        investToken = _investToken;
        startTime = _startTime;
        duration = _duration;
        epochTime = _epochTime;
        initialCap = _initialCap;        
        totalraiseCap = _totalraiseCap;
        mininvest = _minInvest; 
        treasury = _treasury;
        require(duration < 7 days, "duration too long");
        endTime = startTime + duration;
        nrt = CommunityOfferingNRT(_nrtAddress);
        redeemEnabled = false;
        saleEnabled = false;
        maxCap = 800 * 10 ** 18; // Per Person maximum contribution is 800 USDC
    }

    // adds an address to the whitelist
    function addWhitelist(address _address) external onlyOwner {        
        //require(!whitelisted[_address], "already whitelisted");
        whitelisted[_address] = true;
        numWhitelisted+=1; 
    }

    // adds multiple addresses
    function addMultipleWhitelist(address[] calldata _addresses) external onlyOwner {        
        require(_addresses.length <= 1000, "too many addresses");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = true;  
            numWhitelisted+=1;          
        }
    }

    // removes a single address from the sale
    function removeWhitelist(address _address) external onlyOwner {        
        whitelisted[_address] = false;
    }

    function currentEpoch() public view returns (uint256){     
        if(block.timestamp < startTime)
            return 0;    
        else       
            return (block.timestamp - startTime)/epochTime;
    }

    // the current cap. increases exponentially
    function currentCap() public view returns (uint256){   
        uint256 epochs = currentEpoch();
        uint256 cap = initialCap * (2 ** epochs);
        if (cap > maxCap){
            return maxCap;
        } else {
            return cap;
        }
    }
    
    // invest up to current cap
    function invest(uint256 investAmount) public {
        require(block.timestamp >= startTime, "not started yet");
        require(saleEnabled, "not enabled yet");
        require(whitelisted[msg.sender] == true, 'msg.sender is not whitelisted');
        require(totalraised + investAmount <= totalraiseCap, "over total raise");
        require(investAmount >= mininvest, "below minimum invest");
        require(block.timestamp <= endTime, "sales ended");

        uint256 xcap = currentCap();

        InvestorInfo storage investor = investorInfoMap[msg.sender];

        require(investor.amountInvested + investAmount <= xcap, "above cap");        

        require(
            IERC20(investToken).transferFrom(
                msg.sender,
                address(this),
                investAmount
            ),
            "transfer failed"
        );

        //Frock decimals = 9, USDC decimals = 6
        uint256 issueAmount = investAmount * 10**launchDecimals * priceQuote / price / 10**6 ;                


        nrt.issue(msg.sender, issueAmount);

        totalraised += investAmount;
        totalissued += issueAmount;
        if (investor.amountInvested == 0){
            numInvested += 1;
        }
        investor.amountInvested += investAmount;
        
        emit Invest(msg.sender, investAmount);
    }

    // redeem all tokens
    function redeem() public {        
        require(redeemEnabled, "redeem not enabled");
        require(block.timestamp > endTime, "not redeemable yet");
        uint256 redeemAmount = nrt.balanceOf(msg.sender);
        require(redeemAmount > 0, "no amount issued");
        InvestorInfo storage investor = investorInfoMap[msg.sender];
        require(!investor.claimed, "already claimed");
        require(
            IERC20(launchToken).transfer(
                msg.sender,
                redeemAmount
            ),
            "transfer failed"
        );

        nrt.redeem(msg.sender, redeemAmount);

        totalredeem += redeemAmount;        
        emit Redeem(msg.sender, redeemAmount);
        investor.claimed = true;
    }

    // -- admin functions --

    // define the launch token to be redeemed
    function setLaunchToken(address _launchToken) public onlyOwner {
        launchToken = _launchToken;
    }

    function depositLaunchtoken(uint256 amount) public onlyOwner {
        require(
            IERC20(launchToken).transferFrom(msg.sender, address(this), amount),
            "transfer failed"
        );
    }

    // withdraw in case some tokens were not redeemed
    function withdrawLaunchtoken(uint256 amount) public onlyOwner {
        require(
            IERC20(launchToken).transfer(msg.sender, amount),
            "transfer failed"
        );
    }

    // withdraw funds to treasury
    function withdrawTreasury(uint256 amount) public onlyOwner {
        //uint256 b = IERC20(investToken).balanceOf(address(this));
        require(
            IERC20(investToken).transfer(treasury, amount),
            "transfer failed"
        );
    }

    function enableSale() public onlyOwner {
        saleEnabled = true;
        emit SaleEnabled(true, block.timestamp);
    }

    function enableRedeem() public onlyOwner { 
        require(launchToken != address(0), "launch token not set");
        redeemEnabled = true;
        emit RedeemEnabled(true, block.timestamp);
    }
}
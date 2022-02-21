/**
 *Submitted for verification at FtmScan.com on 2022-02-21
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: contracts/DiscordSale.sol


pragma solidity ^0.8.9;




contract FLDDiscordSaleContract is Ownable, Pausable {

    IERC20 public prFLDToken;
    IERC20 public usdcToken;

    address public immutable devWallet = 0x1C7B053AeD6913b298F6b8825a2dADE4E908Ae0F;
    address public whitelister = 0x2a3288490077AA5CB536964f52d9a8d5D6F5C25d;

    uint256 public totalSold;
    uint256 public tokenPriceInUSD = 7 * 10**18; // $7 per token
    uint256 public maxPurchase = 100 * 10**18; // 100 prFLD per Wallet
    uint256 public minPurchase = 58 * 10**18; // 58 prFLD 
    bool public isClaimRefundEnabled = false; 
    bool public isAntiWhaleEnabled = true; 

    uint256 public totalAllocation = 30000 * 10**18; // 30k prFLD tokens

    ///@dev tracks all the purchases
    mapping(address => uint256) public tokenPurchaseLog;

    ///@dev tracks the refund claim status
    mapping(address => bool) public isRefundClaimed;

    ///@dev tracks whitelist status of a wallet
    mapping(address => bool) public isWhitelisted;

    ///Events
    event TokensPurchased(address indexed account, uint256 prFLDAmount, uint256 usdcAmount);
    event RefundClaimed(address indexed account, uint256 usdcAmount);

    
    constructor(address _prFLDToken, address _usdcToken) {
        prFLDToken = IERC20(_prFLDToken);
        usdcToken = IERC20(_usdcToken);
        _pause();
    }

    /**
     * @notice Used to purchase prFLD tokens via USDC. 
     * @dev the contract should not be paused and the user should be whitelisted 
     * @param _amount the amount of prFLD tokens to purchase 
    */    

    function purchaseTokens(uint256 _amount) external whenNotPaused {
        require(isWhitelisted[_msgSender()],"VE: Not whitelisted");
        require(_amount + totalSold <= totalAllocation, "VE: Amount exceeds allocated");
        require(_amount >= minPurchase , "VE: Amount less than MIN");

        if(isAntiWhaleEnabled)
        require(_amount + tokenPurchaseLog[_msgSender()] <= maxPurchase, "VE: Amount exceeds limit");

        uint256 usdcAmount = _amount * tokenPriceInUSD / 10**30;
        require(usdcToken.balanceOf(_msgSender())>=usdcAmount, "VE:Insufficient balance");
        require(usdcToken.allowance(_msgSender(), address(this))>=usdcAmount, "VE:Insufficient allowance");

        totalSold+=_amount;
        tokenPurchaseLog[_msgSender()] +=_amount;

        usdcToken.transferFrom(_msgSender(), address(this), usdcAmount);
        prFLDToken.transfer(_msgSender(), _amount);

        emit TokensPurchased(_msgSender(), _amount, usdcAmount);
    }

    /**
     * @notice Used to claim refund. 
     * @dev the contract should not be paused and the refund claiming should be enabled
    */    

    function claimRefund() external whenNotPaused {
        require(isClaimRefundEnabled, "VE:refund claims disabled");
        require(!isRefundClaimed[_msgSender()],"VE: Already claimed");
        require(tokenPurchaseLog[_msgSender()] > 0,"VE: No refund");

        uint256 usdcRefund = tokenPurchaseLog[_msgSender()] * tokenPriceInUSD / 10**30;
        isRefundClaimed[_msgSender()] = true;
        usdcToken.transfer(_msgSender(), usdcRefund);
        emit RefundClaimed(_msgSender(), usdcRefund);
    }


    /// ======= RESTRICTED METHODS =============== ///

    ///@dev used to pause the sale
    function pause() external onlyOwner {
        _pause();
    }

    ///@dev used to resume the sale if paused
    function unpause() external onlyOwner {
        _unpause();
    }

    ///@dev used to set the Max purchase value per wallet
    ///@param _newMaxAmount the new max purchase amount. Should be passed as 18 decimal value
    /// For ex, 100 should be passed as `100000000000000000000` (100 * 10**18) 
    function setMaxPurchase(uint256 _newMaxAmount) external onlyOwner {
        maxPurchase = _newMaxAmount;
    }

    ///@dev used to set the Min purchase value per wallet
    ///@param _newMaxAmount the new max purchase amount. 
    //[TIP] Should be passed as 18 decimal value
    /// For ex, 5 should be passed as `5000000000000000000` (5 * 10**18)
    function setMinPurchase(uint256 _newMinAmount) external onlyOwner {
        minPurchase = _newMinAmount;
    }

    ///@dev used to enable/disable refund claiming
    ///@param _status it should be either set to true/false to enable/disable 
    function setClaimRefundEnabled(bool _status) external onlyOwner {
        isClaimRefundEnabled = _status;
    }

    ///@dev used to update the whitelister wallet address
    ///@param _newAddress  the address of the new whitelister wallet
    function setWhitelisterWallet(address _newAddress) external onlyOwner {
        whitelister = _newAddress;
    }

    ///@dev used to set the whitelist status of a wallet
    ///@param _wallet the address of the wallet 
    ///@param _status the current status 
    /// For ex, to whitelist a wallet `0xabc` the status should be `true`
    function whitelist(address _wallet, bool _status) external { 
        require(_msgSender()==owner() || _msgSender() == whitelister, "VE: cannot whitelist");
        isWhitelisted[_wallet] = _status;
    }

    ///@dev used to enable/disable max purchase limit per wallet
    ///@param _status can be set to true/false 
     function setAntiWhaleConfig(bool _status) external onlyOwner { 
         isAntiWhaleEnabled = _status;
     }

    ///@dev used to withdraw USDC balance from the contract
    ///@dev it'll be transferred to the dev wallet
      function withdrawUSDC() external onlyOwner { 
         uint256 balance = usdcToken.balanceOf(address(this));
         usdcToken.transfer(devWallet, balance);
    }
    ///@dev used to withdraw prFLD tokens from the contract
    ///@dev it'll be transferred to the dev wallet
     function withdrawPRFLD() external onlyOwner { 
         uint256 balance = prFLDToken.balanceOf(address(this));
         prFLDToken.transfer(devWallet, balance);
    }
}
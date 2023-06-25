/**
 *Submitted for verification at FtmScan.com on 2023-06-25
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File contracts/CoinFog.sol



pragma solidity >=0.8.7;
contract CoinFog is Ownable {

    //Events are created but NOT emitted to leave less footprints on the blockchain
    event Deposit(address indexed sender, uint amount);
    event Withdraw(address indexed receiver, uint amount);

    //SETTING TOKEN CONTRACT
    IERC20 public tokenContract;
    function setToken(address tokenAddress) external {
        tokenContract = IERC20(tokenAddress);
    }

    //STATE VARIABLES
    //Each deposit will have a hash and an amount information
    mapping(bytes32 => uint) private balances;
    //Later each new hash will be saved in hash array
    bytes32[] private balanceIds;
    //there will be a fee for depositing and withdrawal to deter scammers
    mapping(address => bool) public feePayers;

    //Security logic: Contract pause
    bool public status;
    error Stopped(string message, address owner);
    modifier isPaused() {
        if(status == true) {
            revert Stopped("contract has been paused, contact owner", owner());
        }
        _;
    }
    function togglePause() external onlyOwner {
        status = !status;
    }

    //Security logic: Checking if input hash already exists
    error Existing(string message, bytes32 hashdata);
    modifier isExisting(bytes32 _hash) {
        for(uint i=0; i<balanceIds.length; i++) {
            if(balanceIds[i] == _hash) {
                revert Existing("this hash exists", _hash);
            }
        }
        _;    
    }

    //Security logic: checking if msg.sender has paid function call fee
    error NotPaid(string message, address caller);
    modifier hasPaid() {
        if(feePayers[msg.sender] == false) {
            revert NotPaid("you need to pay withdrawal service fee", msg.sender);
        }
        _;
    }


    //fee setting, payment and collection logic 
    uint public fee = 5 ether;
    function setFee(uint _fee) external onlyOwner {
        fee = _fee * (10**18);
    }
    function collectFees() external onlyOwner {
        uint contractFees = address(this).balance;
        require(contractFees > 1, "No significant fees collected yet");
        (bool success, ) = payable(owner()).call{value: contractFees}("");
        require(success == true, "fee collection failed");
    }
    function payFee() public payable {
        //transaction fee will deter scam calls
        require(msg.value >= fee, "You need to pay withdrawal fee");
        feePayers[msg.sender] = true;
    }

    // ------------------------------------------------------------------------
    //                          DEPOSIT AND WITHDRAWAL FUNCTIONS
    // ------------------------------------------------------------------------

    //Function to deposit tokens into the contract
    //People must also pay for depositing into the contract which is 4 ftm
    //People must also approve contract before sending tokens to this contract
    function deposit(bytes32 _hash, uint _amount) external hasPaid isExisting(_hash) isPaused {

        //input validations
        require(_hash.length == 32, "invalid hash");
        require(_amount >= 1, "_amount must be bigger than 1");

        feePayers[msg.sender] = false;
        balanceIds.push(_hash);
        uint amount = _amount*(10**18);
        tokenContract.transferFrom(msg.sender, address(this), amount);
        balances[_hash] = amount;

    }


    function withdrawPart(string calldata _privateWord, bytes32 _newHash, address receiver, uint _amount) 
        external hasPaid isExisting(_newHash) isPaused
    {
        //input validations
        require(bytes(_privateWord).length > 0, "private word is not enough long");
        require(_newHash.length == 32, "invalid new hash");
        require(receiver != address(0), "invalid receiver address");
        require(bytes20(receiver) == bytes20(address(receiver)), "invalid receiver address");
        require(_amount > 0, "_amount must be bigger than 0");

        //withdrawing the desired amount
        uint amount = _amount * (10**18);
        (uint balanceFinal, bytes32 balanceHash) = getHashAmount(_privateWord);
        require(balanceFinal > amount, "If you want to withdraw all choose withdrawAll function");
        balances[balanceHash] = 0;
        tokenContract.transfer(receiver, amount);
        
        // Resetting function call fee. Each fee is only for 1 function call
        feePayers[msg.sender] = false;
        //redepositing the amount left
        uint amountLeft = balanceFinal - amount;
        require(amountLeft >= 1, "amountLeft must be bigger than 1");
        balanceIds.push(_newHash);
        balances[_newHash] = amountLeft;
    }

    function withdrawAll(string calldata _privateWord, address receiver) 
        external hasPaid isPaused
    {
        //input validations
        require(bytes(_privateWord).length > 0, "private word is not enough long");
        require(receiver != address(0), "invalid receiver address");
        require(bytes20(receiver) == bytes20(address(receiver)), "invalid receiver address");

        // Resetting function call fee. Each fee is only for 1 function call
        feePayers[msg.sender] = false;
        // Get the balance and hash associated with the private word
        (uint balanceFinal, bytes32 balanceHash) = getHashAmount(_privateWord);
        // Ensure the withdrawal amount is greater than 0
        require(balanceFinal > 0, "Withdraw amount must be bigger than 0");
        // Set the balance associated with the hash to 0
        balances[balanceHash] = 0;
        // Transfer the tokens to the receiver's address
        tokenContract.transfer(receiver, balanceFinal);
    }



    // HASH CREATION AND COMPARISON FUNCTIONs
    // Function to create a hash. Users will be advised to use other websites to create their keccak256 hashes.
    // But if they dont, they can use this function.
    function createHash(string calldata _word) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(_word));
    }
    
    function getHashAmount(string calldata inputValue) private view returns(uint, bytes32) {
        bytes32 idHash = keccak256(abi.encodePacked(inputValue));
        for(uint i=0; i<balanceIds.length; i++) {
            if(balanceIds[i] == idHash) {
                return (balances[idHash], idHash);
            }
        }
        return (0, idHash);
    }

    function checkHashExist(bytes32 _hash) external view returns(bool) {
        if(balanceIds.length < 1) {
            return false;
        }
        for(uint i = 0; i<balanceIds.length; i++) {
            if(balanceIds[i] == _hash) {
                return true;
            }
        }
        return false;

    }

    function getContractEtherBalance() external view returns(uint) {
        return address(this).balance / (10**18);
    }

    function getContractTokenBalance() external view returns(uint) {
        return tokenContract.balanceOf(address(this)) / (10**18);
    }

}
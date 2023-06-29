/**
 *Submitted for verification at FtmScan.com on 2023-06-29
*/

// SPDX-License-Identifier: MIT

/**
           .--._.--.
          ( O     O )
          /   . .   \
         .`._______.'.
        /(           )\
      _/  \  \   /  /  \_
   .~   `  \  \ /  /  '   ~.
  {    -.   \  V  /   .-    }
_ _`.    \  |  |  |  /    .'_ _
>_       _} |  |  | {_       _<
 /. - ~ ,_-'  .^.  `-_, ~ - .\
         '-'|/   \|`-`

 *        /| ________________
 *  O|===|* >________________ >   https://fantomlords.com
 *        \|
 *
 * @title Arcane Relic Dungeon Delve: Brave the depths of the dungeon together with Sir Hopper the knight, gathering Arcane Relics and many more treasures!
 * @dev A contract that allows knights to delve into treasures and receive tokens in return.     
 *      Only the noble contract owner can set token addresses and modify percentages.
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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

// File: UrielDungeonTest.sol

contract CaveExploreTestv6 is Ownable {
    // State variables
    address[] public tokenAddresses; // List of token addresses
    uint[] public tokenPercentages; // List of token distribution percentages
    uint public gamePrice = 100000000000000000; // Price to delve into the treasures

    receive() external payable {}
    
    /**
     * @dev Sets a new token address and its corresponding distribution percentage.
     *      Only the noble contract owner can call this function.
     * @param tokenAddress The address of the token contract
     * @param percentage The percentage of tokens to be distributed for this token address
     */
    function setTokenAddress(address tokenAddress, uint percentage) public onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(percentage <= 1000000, "Invalid percentage");
        
        tokenAddresses.push(tokenAddress);
        tokenPercentages.push(percentage);
    }

    /**
     * @dev Retrieves the list of token addresses.
     * @return An array containing the token addresses.
     */
    function getTokenAddresses() public view returns (address[] memory) {
        return tokenAddresses;
    }

    /**
     * @dev Retrieves the list of token distribution percentages.
     * @return An array containing the token distribution percentages.
     */
    function getTokenPercentages() public view returns (uint[] memory) {
        return tokenPercentages;
    }

    /**
     * @dev Modifies the distribution percentage for a specific token address.
     *      Only the noble contract owner can call this function.
     * @param index The index of the token address in the list
     * @param newPercentage The new distribution percentage for the token address
     */
    function modifyPercentage(uint index, uint newPercentage) public onlyOwner {
        require(index < tokenPercentages.length, "Invalid index");
        require(newPercentage <= 1000000, "Invalid percentage");
        tokenPercentages[index] = newPercentage;
    }
    

    /**
     * @dev Sets the price to delve into the treasures.
     *      Only the noble contract owner can call this function.
     * @param price The new price to delve into the treasures
     */
    function setGamePrice(uint price) public onlyOwner {
        gamePrice = price;
    }
    
    /**
     * @dev Retrieves the current price to delve into the treasures.
     * @return The current price to delve into the treasures.
     */
    function getGamePrice() public view returns (uint) {
        return gamePrice;
    }


    /**
     * @dev Allows the noble contract owner to withdraw the contract's balance in Ether.
     *      Only the noble contract owner can call this function.
     */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "Contract balance is zero");
        
        address payable ownerAddress = payable(owner());
        ownerAddress.transfer(balance);
    }

    /**
     * @dev Allows the noble contract owner to withdraw a specific token from the contract.
     *      Only the noble contract owner can call this function.
     * @param index The index of the token address in the list
     */
    function withdrawToken(uint index) public onlyOwner {
        require(index < tokenAddresses.length, "Invalid index");
        uint tokenBalance = IERC20(tokenAddresses[index]).balanceOf(address(this));
        require(tokenBalance > 0, "Contract token balance is zero");
        IERC20(tokenAddresses[index]).transfer(owner(), tokenBalance);
    }
    

    /**
     * @dev Allows a brave knight to delve into the treasures by sending the exact game price.
     *      The function distributes the set percentage of tokens to the sender.
     */
    function delve() public payable {
        require(msg.value == gamePrice, "Incorrect payment amount");
        
        for (uint i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            uint tokenPercentage = tokenPercentages[i];
            
            uint tokenAmount = (msg.value * tokenPercentage) / 10000;
            IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        }
    }
}
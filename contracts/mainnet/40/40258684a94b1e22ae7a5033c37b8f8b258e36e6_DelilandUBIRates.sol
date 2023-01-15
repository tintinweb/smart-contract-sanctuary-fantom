/**
 *Submitted for verification at FtmScan.com on 2023-01-14
*/

// SPDX-License-Identifier: MIT
// Deliland UBI Rate Manager
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
        return msg.data;
    }
}


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DelilandUBIRates is Ownable {
    error BadUBI();
    uint256 public minUBI = 2;
    uint256 public maxUBI = 20;
    mapping (uint256 => uint256[]) ubiListByRegion;
    
    function addUBI (
        uint256 region, 
        uint256 ubi) public onlyOwner {
        if (ubi < minUBI || ubi > maxUBI) revert BadUBI();
        ubiListByRegion[region].push(ubi);
    }

    function changeUBI (
        uint256 region,
        uint256 location,
        uint256 ubi) public onlyOwner {
        if (ubi < minUBI || ubi > maxUBI) revert BadUBI();
        ubiListByRegion[region][location] = ubi;
    }

    function getUBI (
        uint256 region, 
        uint256 location) public view returns (uint256) {
        return ubiListByRegion[region][location];
    }
    
    constructor() Ownable() {        
        

        ubiListByRegion[0] = [10,12];
        ubiListByRegion[1] = [3,2];
        ubiListByRegion[2] = [4,20];
        ubiListByRegion[3] = [6];
       
    }  
}
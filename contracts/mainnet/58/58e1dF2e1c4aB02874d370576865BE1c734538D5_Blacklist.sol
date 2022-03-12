/**
 *Submitted for verification at FtmScan.com on 2022-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Blacklist is Ownable {
    // Blacklist Addresses
    mapping(address => bool) blacklistedAddresses;

    // constructor() {}

    // modifier isNotBlacklisted(address _address) {
    //     require(!blacklistedAddresses[_address], "Address is blacklisted");
    //     _;
    // }

    function addBacklistedUser(address _addressToBacklist) public onlyOwner() {
        blacklistedAddresses[_addressToBacklist] = true;
    }

    function removeBacklistedUser(address _addressToRemove) external onlyOwner() {
        blacklistedAddresses[_addressToRemove] = false;
    }

    function verifyBacklistedUser(address _address) external view returns(bool) {
        bool userIsWhitelisted = blacklistedAddresses[_address];
        return userIsWhitelisted;
    }

    function addManyToBacklist(address[] memory _addresses) external onlyOwner() {
        for (uint256 i = 0; i < _addresses.length; i++) {
            blacklistedAddresses[_addresses[i]] = true;
        }
    }

    function removeManyFromBacklist(address[] memory _addresses) external onlyOwner() {
        for (uint256 i = 0; i < _addresses.length; i++) {
            blacklistedAddresses[_addresses[i]] = false;
        }
    }
}
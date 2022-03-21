/**
 *Submitted for verification at FtmScan.com on 2022-03-21
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

// File: contracts/Reservation.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


contract ReserveFTM is Ownable {
    uint256 price = 30 ether;

    struct Reservation {
        string name;
        address addr;
    }

    Reservation[] reserves;
    mapping(string => bool) reserved;
    mapping(address => bool) team;
    mapping(address => string[]) wname;

    uint256 public reservedCnt;
    uint256 public RESERVATION_LIMIT = 1000;
    uint256 public MAX_ALLOWED = 5;

    constructor() { }

    function reserve(string memory _name) public payable {
        require(reservedCnt < RESERVATION_LIMIT, "Reservation limit exceeds");
        require(msg.value >= price, "Not enough FTM sent for reserve");
        require(wname[msg.sender].length < MAX_ALLOWED, "Reservation times per wallet exceeds");
        require(!reserved[_name], "This name is already used");
        Reservation memory newReserve = Reservation(_name, msg.sender);
        reserved[_name] = true;
        wname[msg.sender].push(_name);
        reserves.push(newReserve);
        reservedCnt ++;
    }

    function getLimitDetails() external view returns(uint256, uint256) {
        return (RESERVATION_LIMIT, reservedCnt);
    }

    function getList() public view returns (Reservation[] memory) {
        require(team[msg.sender], "Only team members are allowed to get list.");
        return reserves;
    }

    function isMember() public view returns (bool) {
        return team[msg.sender];
    }

    function isReserveFinished() public view returns (bool, string[] memory) {
        return (wname[msg.sender].length >= MAX_ALLOWED, wname[msg.sender]);
    }

    function isUsedName(string memory _name) public view returns (bool) {
        return reserved[_name];
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No FTM Left To Withdraw");

        payable(msg.sender).transfer(balance);
    }

    function addMembers(address[] memory _members) external onlyOwner {
        for(uint i = 0; i < _members.length; i ++) {
            if(!team[_members[i]]) team[_members[i]] = true;
        }
    }

    function addReservedMembers(string[] memory _members) external onlyOwner {
        for (uint i = 0; i < _members.length; i++) {
            reserved[_members[i]] = true;
        }
    }

    function setReservationLimit(uint256 limit) external onlyOwner {
        RESERVATION_LIMIT = limit;
    }
}
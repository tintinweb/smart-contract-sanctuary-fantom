/**
 *Submitted for verification at FtmScan.com on 2023-03-10
*/

/**
 *Submitted for verification at FtmScan.com on 2023-03-07
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


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
    address private _admin;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _admin = _msgSender();
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

// File: contracts/TeesPhysicalStore/physicalTees.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract PhysicalTees is Ownable {
    struct Order {
        uint256 orderId;
        address buyer;
        uint256 orderTime;
        bool fulfilled;
    }

    mapping(uint256 => Order) private orders;
    mapping(address => uint256[]) private ordersByBuyer;
    uint256 private maxTees;
    uint256 private boughtTees;
    uint256 private price;
    uint256 private internationalPrice;
    bool private paused;
    address private withdrawalAddress;
    uint256 private orderIdCounter = 0;
    address private _admin;

    event NewOrder(uint256 orderId, address buyer, uint256 orderTime, bool fulfilled);

    constructor(uint256 _maxTees, uint256 _price, uint256 _internationalPrice) {
    maxTees = _maxTees;
    boughtTees = 0;
    price = _price;
    internationalPrice = _internationalPrice;
}

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == admin() || msg.sender == owner(), "Only owner or admin can call this function.");
        _;
    }

    function setAdmin(address adminAddress) external onlyOwner {
    _admin = adminAddress;
    }

    function admin() public view returns (address) {
        return _admin;
    }

    function buyTee() external payable {
        require(msg.value == price, "Please send exact amount");
        require(boughtTees < maxTees, "All tees have been sold");
        require(!paused, "Contract is paused");

        boughtTees++;

        orderIdCounter++;
        uint256 orderId = orderIdCounter;
        orders[orderId] = Order(orderId, msg.sender, block.timestamp, false);
        ordersByBuyer[msg.sender].push(orderId);

        emit NewOrder(orderId, msg.sender, block.timestamp, false);
    }

    function buyTeeI() external payable {
    require(boughtTees < maxTees, "All tees have been sold");
    require(!paused, "Contract is paused");
    require(msg.value == internationalPrice, "Please send exact amount");
    
    boughtTees++;

    orderIdCounter++;
    uint256 orderId = orderIdCounter;
    orders[orderId] = Order(orderId, msg.sender, block.timestamp, false);
    ordersByBuyer[msg.sender].push(orderId);

    emit NewOrder(orderId, msg.sender, block.timestamp, false);
}


    function viewFulfilled(uint256 _orderId) external view returns (bool) {
        return orders[_orderId].fulfilled;
    }

    function markFulfilled(uint256 _orderId) external onlyOwnerOrAdmin {
        require(_orderId > 0, "Invalid order id");
        Order storage order = orders[_orderId];
        require(!order.fulfilled, "Order has already been fulfilled");
        order.fulfilled = true;
    }

    function markFulfilledBatch(uint256[] calldata _orderIds) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < _orderIds.length; i++) {
            uint256 orderId = _orderIds[i];
            require(orderId > 0, "Invalid order id");
            Order storage order = orders[orderId];
            require(!order.fulfilled, "Order has already been fulfilled");
            order.fulfilled = true;
        }
    }


    function getOrdersByBuyer(address _buyer) external view returns (uint256[] memory) {
        return ordersByBuyer[_buyer];
    }

    function getOrder(uint256 _orderId) external view returns (Order memory) {
        return orders[_orderId];
    }

    function setmaxTees(uint256 _maxTees) external onlyOwnerOrAdmin {
        maxTees = _maxTees;
    }

    function setPrice(uint256 _price) external onlyOwnerOrAdmin {
        price = _price;
    }

    function setInternationalPrice(uint256 _price) external onlyOwnerOrAdmin {
    internationalPrice = _price;
}


    function getmaxtees() external view returns (uint256) {
        return maxTees;
    }

    function getboughtTees() external view returns (uint256) {
        return boughtTees;
    }

    function getPrice() external view returns (uint256) {
        return price;
    }

    function getInternationalPrice() external view returns (uint256) {
    return internationalPrice;
}


    function pauseContract() external onlyOwnerOrAdmin {
        paused = !paused;
    }

    function isPaused() external view returns (bool) {
    return paused;
}

   function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
}

    function changeOwner(address newOwner) external onlyOwner {
    transferOwnership(newOwner);
}
}
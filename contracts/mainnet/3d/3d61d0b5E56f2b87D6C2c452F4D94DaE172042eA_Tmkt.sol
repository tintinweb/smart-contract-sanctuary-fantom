/**
 *Submitted for verification at FtmScan.com on 2023-07-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Tmkt {

  bool internal locked;

  uint256 public vendorCount;

  enum Status {
    Cancelled,
    InProgress,
    Reviewing,
    Completed
  }

  struct Vendor {
    address payable vendorAddress;
    string businessName;
    string profession;
    string filePath;
    string description;
    uint256 price;
    uint256 totalAmount;
    uint256 transactionCount;
    int256 rating;
  }

  struct Transaction {
    uint256 vendorIndex;
    address payable vendor;
    address payable customer;
    uint256 amount;
    Status status;
    uint256 dateCreated;
    uint256 dateCompleted;
    uint256 dateReviewing;
  }

  struct VendorTransaction {
    address payable vendor;
    address payable customer;
    Status status;
    uint256 amount;
    uint256 dateCreated;
    uint256 dateCompleted;
  }

  mapping (address => uint256) transactionCounts;

  mapping (address => uint256) vendorTransactionCounts;

  mapping (address => Transaction[]) customerTransactions;

  mapping (address => VendorTransaction[]) vendorTransactions;

  mapping (uint256 => Vendor) vendors;

  mapping(address => bool) public vendorExists;

  address[] private customerAddresses;
  address[] private vendorAddresses;

  function createVendor(
    string memory _businessName,
    string memory _profession,
    string memory _filePath,
    string memory _description,
    uint256 _price
  ) public {

    require(vendorExists[msg.sender] == false, 'Vendor already exists');

    uint256 totalAmount;
    uint256 transactionCount;

    Vendor storage vendor = vendors[vendorCount];

    vendor.vendorAddress = payable(msg.sender);
    vendor.businessName = _businessName;
    vendor.profession = _profession;
    vendor.filePath = _filePath;
    vendor.description = _description;
    vendor.price = _price;
    vendor.totalAmount = totalAmount;
    vendor.transactionCount = transactionCount;

    vendorExists[msg.sender] = true;

    vendorCount ++;

    addVendorAddress(msg.sender);
  }

  function createTransaction (uint256 vendorIndex, address payable vendor) public payable {

    require(vendorIndex <= vendorCount, "Vendor index does not exist");

    require(vendor != msg.sender, "You can't buy your own product");

    Vendor storage _vendor = vendors[vendorIndex];

    require(_vendor.price == msg.value, "Wrong amount entered");

    require(_vendor.vendorAddress == vendor, "Wrong Vendor address entered");

    Status status = Status(1);
    customerTransactions[msg.sender].push(Transaction(vendorIndex, vendor, payable(msg.sender), msg.value, status, block.timestamp, 0, 0));
    vendorTransactions[vendor].push(VendorTransaction(payable(vendor), payable(msg.sender), status, msg.value, block.timestamp, 0));
    transactionCounts[msg.sender] += 1;
    vendorTransactionCounts[vendor] += 1;
    addCustomerAddress(msg.sender);
  }

  function serviceReviewing(uint256 _index, address _customerAddress) public {
    Transaction storage transaction = customerTransactions[_customerAddress][_index];
    VendorTransaction storage vendorTransaction = vendorTransactions[msg.sender][_index];

    require(transaction.vendor == msg.sender, "Only the Vendor can confirm service completed");
    require(transaction.status != Status.Completed, "Only the Customer can confirm service completed");

    transaction.status = Status(2);
    transaction.dateReviewing = block.timestamp;

    vendorTransaction.status = Status(2);
  }

  function confirmService(uint256 _index, address _vendorAddress) public {

    Transaction storage transaction = customerTransactions[msg.sender][_index];
    VendorTransaction storage vendorTransaction = vendorTransactions[_vendorAddress][_index];

    require(transaction.customer == msg.sender, "Only the customer can confirm the service");
    require((transaction.status == Status.Reviewing) || (transaction.status == Status.InProgress), "Transaction has been completed already");

    (bool sent,) = _vendorAddress.call{value: transaction.amount}("");
    require(sent, "Failed to send Ether");

    transaction.status = Status(3);
    transaction.dateCompleted = block.timestamp;
    vendorTransaction.status = Status(3);
    vendorTransaction.dateCompleted = block.timestamp;

    Vendor storage vendor = vendors[transaction.vendorIndex];
    vendor.totalAmount += transaction.amount;
    vendor.transactionCount ++;
    vendor.rating ++;
  }

  function cancelService(uint256 _index, address _vendorAddress) public {

      Transaction storage transaction = customerTransactions[msg.sender][_index];
      VendorTransaction storage vendorTransaction = vendorTransactions[_vendorAddress][_index];

      require((transaction.status != Status.Reviewing) && block.timestamp <= transaction.dateCreated + (3 days), "You can not cancel");
      require(transaction.customer == msg.sender, "Only the customer can cancel the service");

      require(!locked, "Re entrant call");
      locked = true;
      (bool sent,) = msg.sender.call{value: transaction.amount}("");
      require(sent, "Failed to send Ether");
      locked = false;

      transaction.status = Status(0);
      transaction.dateCompleted = block.timestamp;
      vendorTransaction.status = Status.Cancelled;
      vendorTransaction.dateCompleted = block.timestamp;
    }

  function vendorCancelService(uint256 _index, address _customerAddress) public {

    Transaction storage transaction = customerTransactions[_customerAddress][_index];
    VendorTransaction storage vendorTransaction = vendorTransactions[msg.sender][_index];

    require(block.timestamp <= transaction.dateCreated + (3 days), "You can not cancel now");
    require(transaction.status == Status.InProgress, "Can't cancel at this stage");

    (bool sent,) = _customerAddress.call{value: transaction.amount}("");
    require(sent, "Failed to send Ether");

    transaction.status = Status(0);
    transaction.dateCompleted = block.timestamp;
    vendorTransaction.status = Status(0);
    vendorTransaction.dateCompleted = block.timestamp;
  }


  function getBal() public view returns (uint256) {

    return address(this).balance;
  }

  function getVendors(uint256 _index) public view returns (
    uint256 id,
    address vendorAddress,
    string memory businessName,
    string memory filePath,
    string memory description,
    string memory profession,
    uint256 price,
    uint256 totalAmount,
    uint256 transCount,
    int256 rating
  ) {

    Vendor storage vendor = vendors[_index];

    return (
    _index,
    vendor.vendorAddress,
    vendor.businessName,
    vendor.filePath,
    vendor.description,
    vendor.profession,
    vendor.price,
    vendor.totalAmount,
    vendor.transactionCount,
    vendor.rating
    );
  }

  function getTransactions (uint256 _index, address _customerAddress) public view returns (
    uint256 transactionIndex,
    uint256 vendorIndex,
    address vendor,
    address customer,
    uint256 amount,
    Status status,
    uint256 dateCreated,
    uint256 dateCompleted,
    uint256 dateReviewing,
    string memory filePath,
    string memory businessName
  ) {

    Transaction storage transaction = customerTransactions[_customerAddress][_index];
    Vendor storage _vendor = vendors[transaction.vendorIndex];

    return (
    _index,
    transaction.vendorIndex,
    transaction.vendor,
    transaction.customer,
    transaction.amount,
    transaction.status,
    transaction.dateCreated,
    transaction.dateCompleted,
    transaction.dateReviewing,
    _vendor.filePath,
    _vendor.businessName
    );
  }

    function getVendorTransactions (uint256 _index, address _vendorAddress) public view returns (

      uint256 transactionIndex,
      address customer,
      Status status,
      uint256 dateCreated,
      uint256 dateCompleted
    ) {

      require(vendorExists[_vendorAddress] == true, "You are not a vendor");

      VendorTransaction storage vendorTransaction = vendorTransactions[_vendorAddress][_index];

      return (
      _index,
      vendorTransaction.customer,
      vendorTransaction.status,
      vendorTransaction.dateCreated,
      vendorTransaction.dateCompleted
      );
    }

  function getTransactionCount() public view returns (uint256) {
    return transactionCounts[msg.sender];
  }

  function getVendorTransactionCount() public view returns (uint256) {
    return vendorTransactionCounts[msg.sender];
  }

  function getVendorCount() public view returns (uint256) {
    return vendorCount;
  }

  function addCustomerAddress(address _address) private {
    bool exists = false;
      for (uint i = 0; i < customerAddresses.length; i++) {
        if (customerAddresses[i] == _address) {
          exists = true;
            break;
          }
      }

    if (!exists) {
      customerAddresses.push(_address);
    }
  }

  function addVendorAddress(address _address) private {
    bool exists = false;
      for (uint i = 0; i < vendorAddresses.length; i++) {
        if (vendorAddresses[i] == _address) {
          exists = true;
          break;
        }
      }

    if (!exists) {
      vendorAddresses.push(_address);
    }
  }

    function refundInProgressTransactions() public nonReentrant {
      for (uint256 i = 0; i < customerAddresses.length; i++) {
        address customer = customerAddresses[i];
        Transaction[] storage transactions = customerTransactions[customer];

        for (uint256 j = 0; j < transactions.length; j++) {
          Transaction storage transaction = transactions[j];

          if (transaction.status == Status(1) && block.timestamp > transaction.dateCreated + (2 days)) {
            (bool sent,) = transaction.customer.call{value: transaction.amount}("");
            require(sent, "Failed to send Ether");
            transaction.status = Status(3);
            transaction.dateCompleted = block.timestamp;

            Vendor storage _vendor = vendors[transaction.vendorIndex];
            _vendor.rating -= 2;

            // Stop corresponding Vendor transaction
            VendorTransaction[] storage vendorTxs = vendorTransactions[transaction.vendor];

            for (uint256 k = 0; k < vendorTxs.length; k++) {
              VendorTransaction storage vendorTx = vendorTxs[k];
              if (vendorTx.status == Status(1) && block.timestamp > vendorTx.dateCreated + (2 days)) {
                vendorTx.status = Status(3);
                vendorTx.dateCompleted = block.timestamp;
              }
            }
          }
        }
      }
    }

    function refundReviewTransactions() public nonReentrant {
      for (uint256 i = 0; i < vendorAddresses.length; i++) {
        address vendor = vendorAddresses[i];
        VendorTransaction[] storage vendortxs = vendorTransactions[vendor];

        for (uint256 j = 0; j < vendortxs.length; j++) {
          VendorTransaction storage vendortx = vendortxs[j];

          if (vendortx.status == Status(2) && block.timestamp > vendortx.dateCreated + (3 days)) {
            (bool sent,) = vendortx.vendor.call{value: vendortx.amount}("");
            require(sent, "Failed to send Ether");
            vendortx.status = Status(3);
            vendortx.dateCompleted = block.timestamp;

            // Stop corresponding Customer transaction
            Transaction[] storage txs = customerTransactions[vendortx.customer];

            for (uint256 k = 0; k < txs.length; k++) {
              Transaction storage transaction = txs[k];
              if (transaction.status == Status(2) && block.timestamp > transaction.dateCreated + (3 days)) {
                transaction.status = Status(3);
                transaction.dateCompleted = block.timestamp;
              }

            }
          }
        }
      }
    }

    function tipVendor(address _vendorAddress, uint256 _tipAmount) public {
        (bool sent,) = _vendorAddress.call{value: _tipAmount}("");
        require(sent, "Failed to send Ether");
    }

    modifier nonReentrant() {
      require(!locked, "Reentrancy detected!");
      locked = true;
      _;
      locked = false;
    }

}

// 0x3DfC2625D69957d8a7Be29eDD25b74165bE10e60
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
    
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract RentFantomBNB {
    address public nftAddress;
    address payable public contractOwner;

    modifier onlyHouseOwner(uint256 _nftID) {
        require(msg.sender == houseOwner[_nftID], "Only houseOwner can call this method");
        _;
    }

    mapping(uint256 => bool) public isForRent;
    mapping(uint256 => uint256) public rentPrice;
    mapping(uint256 => uint256) public rentDepositPrice;
    mapping(uint256 => address) public renter;
    mapping(uint256 => address) public potentialRenter;
    mapping(uint256 => address payable) public houseOwner;
    mapping(uint256 => mapping(address => bool)) public approval;
    mapping(uint256 => mapping (address => uint256)) public balance;

    constructor(
        address _nftAddress,
        address payable _contractOwner
    ) {
        nftAddress = _nftAddress;
        contractOwner = _contractOwner;
    }

    function setForRent(
        uint256 _nftID,
        uint256 _rentDepositPrice,
        uint256 _rentPrice
    ) public payable {
        // Transfer NFT from houseOwner to this contract
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftID);

        isForRent[_nftID] = true;
        rentDepositPrice[_nftID] = _rentDepositPrice;
        rentPrice[_nftID] = _rentPrice;
        houseOwner[_nftID] = payable(msg.sender);
    }

    // Potential renter sends a deposit to Rent Deposit contract
    function sendRentDeposit(uint256 _nftID) public payable {
        require(isForRent[_nftID] == true, "No longer for Rent");
        require(msg.value >= rentDepositPrice[_nftID]);
        isForRent[_nftID] = false;
        potentialRenter[_nftID] = msg.sender;
        balance[_nftID][msg.sender] = msg.value;
    }

    // House Owner approves the potential renter
    function approveRent(uint256 _nftID) public onlyHouseOwner(_nftID){
        approval[_nftID][msg.sender] = true;
    }

    // Potential renter sends the rent price
    // -> Require to be Potential renter
    // -> Require the value sent to be equal or greater than rent price
    // -> Balance for this nft for this potential renter is updated
    function sendRentPrice(uint256 _nftID) public payable {
        require( potentialRenter[_nftID] == msg.sender );
        require(msg.value >= rentPrice[_nftID]);
        balance[_nftID][msg.sender] = balance[_nftID][msg.sender] + msg.value;
    }

    // Finalize Rent
    // -> Require rent to be approved by house Owner
    // -> Require funds to be correct amount
    // -> Transfer Funds to houseOwner
    // -> Resets the balance to 0
    function finalizeRent(uint256 _nftID) public onlyHouseOwner(_nftID){
        require(approval[_nftID][msg.sender]);
        require(balance[_nftID][potentialRenter[_nftID]] >= (rentDepositPrice[_nftID] + rentPrice[_nftID]));

        (bool success, ) = payable(houseOwner[_nftID]).call{value: balance[_nftID][potentialRenter[_nftID]]}(
            ""
        );
        require(success);
        
        balance[_nftID][potentialRenter[_nftID]] = 0;
        renter[_nftID] = potentialRenter[_nftID];
    }

    // Cancel Rent (handle earnest deposit)
    // -> Require balance of NFT to be greater than zero
    // -> Set balance of NFT back to zero
    // -> Refund potential renter
    // -> Reset potential renter address for this nft
    // -> Set house for Rent again
    function cancelRent(uint256 _nftID) public onlyHouseOwner(_nftID){
        require(balance[_nftID][potentialRenter[_nftID]] > 0, "All money for this NFT has already been returned or no balance for this NFT");
        uint nft_balance = balance[_nftID][potentialRenter[_nftID]];
        balance[_nftID][potentialRenter[_nftID]] = 0;
        payable(potentialRenter[_nftID]).transfer(nft_balance);
        potentialRenter[_nftID] = 0x0000000000000000000000000000000000000000;
        isForRent[_nftID] = true;
    }

    receive() external payable {}

    function getNFTBalance(uint256 _nftID) public view returns (uint256) {
        return balance[_nftID][potentialRenter[_nftID]];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
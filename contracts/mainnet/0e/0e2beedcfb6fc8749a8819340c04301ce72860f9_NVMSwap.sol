// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.11;

import "IERC20.sol";

contract NVMSwap {

    address private contractOwner;
    IERC20 token;
    uint256 public rate = 100;
    uint256 public decimals = 10**9;

    struct Buyers {
        address buyer;
        uint purchasedAt;
        uint256 amount;
    }

    struct Sellers {
        address seller;
        uint soldAt;
        uint256 amount;
    }

    Buyers private firstBuyer;
    mapping (address => uint) private BuyersToIndex; 
    Buyers[] public BuyersList;

    Sellers private firstSeller;
    mapping (address => uint) private SellersToIndex;
    Sellers[] public SellersList;

    constructor(){
        token = IERC20(0xe8C41Bf05D896bCC7288C474c00eab413d72867D); //NVM token
        contractOwner = msg.sender;

        firstBuyer.buyer = payable(0x000000000000000000000000000000000000dEaD);
        firstBuyer.purchasedAt = 0;
        firstBuyer.amount = 0;

        BuyersToIndex[firstBuyer.buyer] = 0;
        BuyersList.push(firstBuyer);

        firstSeller.seller = payable(0x000000000000000000000000000000000000dEaD);
        firstSeller.soldAt = 0;
        firstSeller.amount = 0;

        SellersToIndex[firstSeller.seller] = 0;
        SellersList.push(firstSeller);
    }

    modifier OnlyContractOwner {
        require (msg.sender == contractOwner, "Error: You are not the contract owner.");
        _;
    }
	
	function getBuyersCount() public view returns(uint count) {
		return BuyersList.length;
	}
	
	function getSellersCount() public view returns(uint count) {
		return SellersList.length;
	}

    function buyTokens() public payable{
        uint256 tokenAmount = (msg.value * rate) / decimals;

        require(
            token.balanceOf(address(this)) >= tokenAmount,
            "Not enough tokens"
        );

        token.transfer(msg.sender, tokenAmount);

        Buyers memory newBuyer;
            newBuyer.buyer = msg.sender;
            newBuyer.purchasedAt = block.timestamp;
            newBuyer.amount = tokenAmount;
            
        BuyersList.push(newBuyer);

        emit TokenPurchased(msg.sender, address(token), tokenAmount, rate);
    }

    function sellTokens(uint256 _amount) public payable {
        require(token.balanceOf(msg.sender) >= _amount);
        uint256 ftmAmount = ( _amount / rate ) * decimals;

        require(address(this).balance >= ftmAmount, "Not enough FTM in contract!!!!!");

        token.transferFrom(msg.sender, address(this), _amount);
        payable(msg.sender).transfer(ftmAmount);

        Sellers memory newSeller;
            newSeller.seller = msg.sender;
            newSeller.soldAt = block.timestamp;
            newSeller.amount = _amount;
            
        SellersList.push(newSeller);

        emit TokenSold(msg.sender, address(token), _amount, rate);
    }

    event TokenPurchased(
        address account,
        address token,
        uint256 amount,
        uint256 rate
    );

    event TokenSold(
        address account,
        address token,
        uint256 amount,
        uint256 rate
    );

    function ContractOwnerWithdraw(uint amount) public OnlyContractOwner {
        require(amount > 0 && amount < address(this).balance, "Error: Required value is bigger than existing amount.");
        payable(msg.sender).transfer(amount);
    }
    
}
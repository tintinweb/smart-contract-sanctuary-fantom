/**
 *Submitted for verification at FtmScan.com on 2022-01-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAssetBox {
    function getbalance(uint8 roleIndex, uint tokenID) external view returns (uint);
    function mint(uint8 roleIndex, uint tokenID, uint amount) external;
    function transfer(uint8 roleIndex, uint from, uint to, uint amount) external;
    function burn(uint8 roleIndex, uint tokenID, uint amount) external;
    function getRole(uint8 index) external view returns (address);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract AssetMarket {
    address immutable private owner;
    uint public tfee;
    address immutable public asset;
    address immutable public token;

    struct Order {
        uint amount;
        uint price;
    }

    mapping (uint8 => mapping(uint => Order)) public orderMap;

    uint public minimumPrice = 1e14; 

    constructor (uint tfee_, address asset_, address token_){
        owner = msg.sender;
        tfee = tfee_;
        asset = asset_;
        token = token_;
    }

    event Asked(uint8 indexed roleIndex, uint indexed tokenID, uint amount, uint price);
    event Refilled(uint8 indexed roleIndex, uint indexed tokenID, uint amount);
    event Bidded(uint8 buyerRoleIndex, uint buyer, uint8 sellerRoleIndex, uint seller, uint amount, uint price, uint fee);
    event Cancelled(uint8 indexed roleIndex, uint indexed tokenID);
    event Updated(uint8 indexed roleIndex, uint indexed tokenID, uint price);
 
    function setTfee(uint _tfee) external {
        require(msg.sender == owner, "Only owner");

        tfee = _tfee;
    }

    function setMinimumPrice(uint _minimumPrice) external {
        require(msg.sender == owner, "Only owner");

        minimumPrice = _minimumPrice;
    }

    function ask(uint8 roleIndex, uint tokenID, uint amount, uint price) external {
        address role = IAssetBox(asset).getRole(roleIndex);
        require(_isApprovedOrOwner(role, msg.sender, tokenID), "Not approved or owner");
        require(price > minimumPrice, "bad price");
        
        IAssetBox(asset).burn(roleIndex, tokenID, amount);
        
        Order storage order = orderMap[roleIndex][tokenID];
        require(order.amount == 0, "Can refill only");
        order.amount = amount;
        order.price = price;

        emit Asked(roleIndex, tokenID, amount, price);
    }

    function refill(uint8 roleIndex, uint tokenID, uint amount) external {
        address role = IAssetBox(asset).getRole(roleIndex);
        require(_isApprovedOrOwner(role, msg.sender, tokenID), "Not approved or owner");

        IAssetBox(asset).burn(roleIndex, tokenID, amount);
        
        Order storage order = orderMap[roleIndex][tokenID];
        require(order.amount > 0, "Can ask only");
        order.amount += amount;

        emit Refilled(roleIndex, tokenID, amount);
    }

    function bid(uint8 buyerRoleIndex, uint buyer, uint8 sellerRoleIndex, uint seller, uint amount, uint price) external {
        address role = IAssetBox(asset).getRole(buyerRoleIndex);
        require(_isApprovedOrOwner(role, msg.sender, buyer), "Not approved or owner");

        Order storage order = orderMap[sellerRoleIndex][seller];
        require(order.amount >= amount, "Amount not enough");
        require(order.price == price, "Price is out of line");

        uint totalPrice = price * amount;
        uint fee = (totalPrice * tfee) / 10000;

        address sellerRole = IAssetBox(asset).getRole(sellerRoleIndex);
        address sellerOwner = IERC721(sellerRole).ownerOf(seller);

        IAssetBox(asset).mint(buyerRoleIndex, buyer, amount);
        IERC20(token).transferFrom(msg.sender, sellerOwner, totalPrice - fee);
        IERC20(token).transferFrom(msg.sender, address(this), fee);
        
        order.amount -= amount;

        emit Bidded(buyerRoleIndex, buyer, sellerRoleIndex, seller, amount, price, fee);
    }

    function cancel(uint8 roleIndex, uint tokenID) external {
        address role = IAssetBox(asset).getRole(roleIndex);
        require(_isApprovedOrOwner(role, msg.sender, tokenID), "Not approved or owner");
        
        Order storage order = orderMap[roleIndex][tokenID];

        require(order.amount > 0, "Amount not enough");
        IAssetBox(asset).mint(roleIndex, tokenID, order.amount);
        order.amount = 0;

        emit Cancelled(roleIndex, tokenID);
    }

    function withdrawal(address recipient, uint amount) external {
        require(msg.sender == owner, "Only Owner");

        IERC20(token).transfer(recipient, amount);
    }

    function _isApprovedOrOwner(address role, address operator, uint256 tokenId) private view returns (bool) {
        require(role != address(0), "Query for the zero address");
        address TokenOwner = IERC721(role).ownerOf(tokenId);
        return (operator == TokenOwner || IERC721(role).getApproved(tokenId) == operator || IERC721(role).isApprovedForAll(TokenOwner, operator));
    }

}
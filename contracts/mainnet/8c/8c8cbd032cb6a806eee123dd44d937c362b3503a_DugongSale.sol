/**
 *Submitted for verification at FtmScan.com on 2023-01-05
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address recepient, uint256 amount) external returns (bool);
}

contract DugongSale {
    event SaleEnabled(bool isActive);
    event SaleDisabled(bool isActive);
    event BroughtTokens(address indexed sender, address indexed recepient, uint256 amount);
    event TokenExtracted(address indexed sender, address indexed recepient, uint256 amount);
    event EtherExtracted(address indexed sender, address indexed recepient, uint256 amount);

    address public owner;
    IERC20 public token;
    bool public isActive;
    uint256 public reserve;
    uint256 public goal;
    uint256 public minBuy;
    uint256 public maxBuy;
    uint256 public scored;
    uint256 public sold;

    constructor() {
        owner = 0xC3c8159Dc7310d86322B3FA56487884130f8FB37;
        token = IERC20(0x3023DE5BC36281e1Fc55bDcC12C31A09a51e8AFb);
        isActive = true;
        reserve = 300000 ether;
        goal = 1000000 ether;
        minBuy = 50 ether;
        maxBuy = 5000 ether;
        scored = 0 ether;
        sold = 0 ether;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Access Denied, You're not the Owner.");
        _;
    }

    modifier run {
        require(isActive, "Sale is Disabled.");
        _;
    }

    function enableSale() onlyOwner external returns (bool) {
        require(!isActive, "Sale is already Enabled.");

        isActive = !isActive;
        emit SaleEnabled(isActive);

        return true;
    }

    function disableSale() onlyOwner external returns (bool) {
        require(!isActive, "Sale is already Disabled.");

        isActive = !isActive;
        emit SaleDisabled(isActive);

        return true;
    }

    function buy() run public payable returns (bool) {
        require((msg.value >= minBuy) && (msg.value <= maxBuy), "5000 FTM >= Amount >= 50 FTM.");
        require(token.balanceOf(address(this)) >= (msg.value*(reserve/goal)), "Low Balance.");

        token.transfer(msg.sender, (msg.value*(reserve/goal)));
        emit BroughtTokens(address(this), msg.sender, (msg.value*(reserve/goal)));
        scored += msg.value;
        sold += (msg.value*(reserve/goal));

        return true;
    }

    receive() external payable{
        buy();
    }

    function extractToken(address recepient, uint256 amount) onlyOwner external returns (bool) {
        require(recepient != address(0), "Address of recepient can't be null/zero address.");
        require(token.balanceOf(address(this)) >= amount, "Low Balance.");

        token.transfer(recepient, amount);
        emit TokenExtracted(address(this), recepient, amount);

        return true;
    }

    function extractEther(address recepient, uint256 amount) onlyOwner external returns (bool) {
        require(recepient != address(0), "Address of recepient can't be null/zero address.");
        require(address(this).balance >= amount, "Low Balance.");

        payable(recepient).transfer(amount);
        emit EtherExtracted(address(this), recepient, amount);

        return true;
    }
}
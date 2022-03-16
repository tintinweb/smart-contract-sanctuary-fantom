/**
 *Submitted for verification at FtmScan.com on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12; // solhint-disable-line

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract GUARDIAN {
    using SafeMath for uint256;

    address blc = 0x5Ad5D364a55c7F0427eA47B3387f94E24A5E7f98; 
    uint256 public FISH_TO_CATCH_1=1440000;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress1 = address(0x5Ddf1b081957E6FaCf52120FADD6992514631abD);
    address public ceoAddress2 = address(0x5Ddf1b081957E6FaCf52120FADD6992514631abD);
    address constant public burnAddress = 0x0000000000000000000000000000000000000000;
    mapping (address => uint256) public catchFishes;
    mapping (address => uint256) public claimedMoneys;
    mapping (address => uint256) public lastClaim;
    mapping (address => address) public referrals;
    uint256 public marketFishes;
    
    constructor() {
        ceoAddress=msg.sender;
    }

    function harvestFishes(address ref) public {
        require(initialized);
        if(ref == msg.sender) {
            ref = burnAddress;
        }
        if(referrals[msg.sender]==burnAddress && referrals[msg.sender]!=msg.sender) {
            referrals[msg.sender]=ref;
        }
        uint256 printerUsed=getMyFish();
        uint256 newPrinters=printerUsed.div(FISH_TO_CATCH_1);
        catchFishes[msg.sender]=catchFishes[msg.sender].add(newPrinters);
        claimedMoneys[msg.sender]=0;
        lastClaim[msg.sender]=block.timestamp;
        
        claimedMoneys[referrals[msg.sender]]=claimedMoneys[referrals[msg.sender]].add(printerUsed.div(10));

        marketFishes=marketFishes.add(printerUsed.div(5));
    }

    function CatchFishes() public {
        require(initialized);
        uint256 hasFish=getMyFish();
        uint256 fishValue=calculateMoneyClaim(hasFish);
        uint256 fee=devFee(fishValue);
        uint256 fee2=fee.div(3);
        claimedMoneys[msg.sender]=0;
        lastClaim[msg.sender]=block.timestamp;
        marketFishes=marketFishes.add(hasFish);
        IERC20(blc).transfer(ceoAddress, fee2);
        IERC20(blc).transfer(ceoAddress1, fee2);
        IERC20(blc).transfer(ceoAddress2, fee2);
        IERC20(blc).transfer(address(msg.sender), fishValue.sub(fee));
    }

    function buyFisherman(address ref, uint256 amount) public {
        require(initialized);
    
        IERC20(blc).transferFrom(address(msg.sender), address(this), amount);
        
        uint256 balance = IERC20(blc).balanceOf(address(this));
        uint256 fishermanBought=calculatePrinterBuy(amount, balance.sub(amount));
        fishermanBought=fishermanBought.sub(devFee(fishermanBought));
        uint256 fee=devFee(amount);
        uint256 fee2=fee.div(5);
        IERC20(blc).transfer(ceoAddress, fee2);
        IERC20(blc).transfer(ceoAddress1, fee2);
        IERC20(blc).transfer(ceoAddress2, fee2);
        claimedMoneys[msg.sender]=claimedMoneys[msg.sender].add(fishermanBought);
        harvestFishes(ref);
    }
    //magic happens here
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateMoneyClaim(uint256 printers) public view returns(uint256) {
        return calculateTrade(printers,marketFishes,IERC20(blc).balanceOf(address(this)));
    }
    function calculatePrinterBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketFishes);
    }
    function calculatePrinterBuySimple(uint256 eth) public view returns(uint256){
        return calculatePrinterBuy(eth,IERC20(blc).balanceOf(address(this)));
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return amount.mul(5).div(100);
    }
    function seedMarket(uint256 amount) public {
        require(msg.sender == ceoAddress);
        IERC20(blc).transferFrom(address(msg.sender), address(this), amount);
        require(marketFishes==0);
        initialized=true;
        marketFishes=144000000000;
    }
    function getBalance() public view returns(uint256) {
        return IERC20(blc).balanceOf(address(this));
    }
    function getMyFishes() public view returns(uint256) {
        return catchFishes[msg.sender];
    }
    function getMyFish() public view returns(uint256) {
        return claimedMoneys[msg.sender].add(getFishesSinceLastCatch(msg.sender));
    }
    function getEstimateFishes(uint256 amount) public view returns(uint256) {
        uint256 fishermanWillBuy = calculatePrinterBuy(amount, getBalance());
        fishermanWillBuy = fishermanWillBuy.sub(devFee(fishermanWillBuy));
        uint256 fPrinterUsed = fishermanWillBuy.add(getMyFish());
        uint256 fNewPrinters=fPrinterUsed.div(FISH_TO_CATCH_1);
        return catchFishes[msg.sender].add(fNewPrinters);
    }
    function getFishesSinceLastCatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(FISH_TO_CATCH_1,block.timestamp.sub(lastClaim[adr]));
        return SafeMath.mul(secondsPassed,catchFishes[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
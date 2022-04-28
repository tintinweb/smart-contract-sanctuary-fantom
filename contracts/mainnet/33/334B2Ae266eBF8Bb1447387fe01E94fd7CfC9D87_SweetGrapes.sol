/**
 *Submitted for verification at FtmScan.com on 2022-04-28
*/

/*

       $$$$$$\                                     $$\            $$$$$$\                                                   
      $$  __$$\                                    $$ |          $$  __$$\                                                  
      $$ /  \__|$$\  $$\  $$\  $$$$$$\   $$$$$$\ $$$$$$\         $$ /  \__| $$$$$$\  $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$$\ 
      \$$$$$$\  $$ | $$ | $$ |$$  __$$\ $$  __$$\\_$$  _|        $$ |$$$$\ $$  __$$\ \____$$\ $$  __$$\ $$  __$$\ $$  _____|
       \____$$\ $$ | $$ | $$ |$$$$$$$$ |$$$$$$$$ | $$ |          $$ |\_$$ |$$ |  \__|$$$$$$$ |$$ /  $$ |$$$$$$$$ |\$$$$$$\  
      $$\   $$ |$$ | $$ | $$ |$$   ____|$$   ____| $$ |$$\       $$ |  $$ |$$ |     $$  __$$ |$$ |  $$ |$$   ____| \____$$\ 
      \$$$$$$  |\$$$$$\$$$$  |\$$$$$$$\ \$$$$$$$\  \$$$$  |      \$$$$$$  |$$ |     \$$$$$$$ |$$$$$$$  |\$$$$$$$\ $$$$$$$  |
       \______/  \_____\____/  \_______| \_______|  \____/        \______/ \__|      \_______|$$  ____/  \_______|\_______/ 
                                                                                              $$ |                          
                                                                                              $$ |                          
                                                                                              \__|                          

 *  10% Daily ROI
 *  3650% APR
 *  10% Insurance Fee

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

contract SweetGrapes {

    uint256 public Grapes_TO_HATCH_1MINERS= 864000;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public initialized=false;

    address public InsuranceAddress = 0xD1b876DB864676EED962ce99eB23dD1797366c6f;

    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedGrapes;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;

    uint256 public marketgrapes;

    function hatchGrapes(address ref) public{
        require(initialized);
        if(ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
            ref = InsuranceAddress;
        }
        if(referrals[msg.sender] == address(0)){
            referrals[msg.sender] = ref;
        }
        uint256 grapesUsed = getMyGrapes(msg.sender);
        uint256 newMiners = SafeMath.div(grapesUsed,Grapes_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender] = SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedGrapes[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;

        //send referral Grapes
        claimedGrapes[referrals[msg.sender]] = SafeMath.add(claimedGrapes[referrals[msg.sender]],SafeMath.div(SafeMath.mul(grapesUsed,135),1000));

        //boost market to nerf miners hoarding
        marketgrapes=SafeMath.add(marketgrapes,SafeMath.div(grapesUsed,5));
    }
    function sellGrapes() public{
        require(initialized);
        uint256 hasGrapes=getMyGrapes(msg.sender);
        uint256 GrapesValue=calculateGrapesSell(hasGrapes);
        uint256 fee = InsuranceFee(GrapesValue);
        claimedGrapes[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketgrapes=SafeMath.add(marketgrapes,hasGrapes);
        payable(InsuranceAddress).transfer(fee);
        payable(msg.sender).transfer(SafeMath.sub(GrapesValue,fee));
    }
    function buyGrapes(address ref) public payable{
        require(initialized);
        uint256 GrapesBought = calculateGrapesBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        GrapesBought = SafeMath.sub(GrapesBought,InsuranceFee(GrapesBought));
        uint256 fee = InsuranceFee(msg.value);
        payable(InsuranceAddress).transfer(fee);
        claimedGrapes[msg.sender]=SafeMath.add(claimedGrapes[msg.sender],GrapesBought);
        hatchGrapes(ref);
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateGrapesSell(uint256 Grapes) public view returns(uint256){
        return calculateTrade(Grapes,marketgrapes,address(this).balance);
    }
    function calculateGrapesBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketgrapes);
    }
    function calculateGrapesBuySimple(uint256 eth) public view returns(uint256){
        return calculateGrapesBuy(eth,address(this).balance);
    }
    function InsuranceFee(uint256 amount) private pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,10),100);
    }
    function seedMarket() public payable{
        require(msg.sender == InsuranceAddress, "Invalid caller");
        require(marketgrapes==0);
        initialized=true;
        marketgrapes=86400000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners(address adr) public view returns(uint256){
        return hatcheryMiners[adr];
    }
    function getMyGrapes(address adr) public view returns(uint256){
        return SafeMath.add(claimedGrapes[adr],getGrapesSinceLastHatch(adr));
    }
    function getGrapesSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(Grapes_TO_HATCH_1MINERS,SafeMath.sub(block.timestamp,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
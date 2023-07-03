/**
 *Submitted for verification at FtmScan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;



contract DetectiveGames  {
    // Address of contract deployer. Marked payable so that
    // we can withdraw to this address later.
  
    address payable owner;
    event Purchase(uint amount, address indexed buyer);

     constructor() {
          owner = payable(msg.sender);
    }

//Game Functions
    mapping(address => mapping(uint => bool)) public hasSolved;
    mapping(address => uint) public userLevel;


     function attemptCase() public payable {
        // Must accept more than 0 ETH for a coffee.
        require(msg.value > 0, "can't solve for free!");
         (bool success,) = address(this).call{value: msg.value}("");
         require(success);

         if(userLevel[msg.sender] == 0) {
             userLevel[msg.sender] = 1;
         }
         emit Purchase(msg.value, msg.sender);
    }
    

    function getUserLevel(address add) external view returns(uint256)
     { return userLevel[add];}

    function addPlayerToSolved(address add,uint _id) external payable{
        require(msg.value >= 1000 wei);
        require(hasSolved[add][_id] == false);
        hasSolved[add][_id] = true;
        userLevel[add] += 1;
    }

    function hasPlayerSovledCase(uint256 _id, address add) external view returns(bool){
        return hasSolved[add][_id];
    }
    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdraw() external {
        require(msg.sender == owner);
        require(owner.send(address(this).balance));
    }
       receive() external payable {}



}
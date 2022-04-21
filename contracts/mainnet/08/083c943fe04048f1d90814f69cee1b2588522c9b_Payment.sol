/**
 *Submitted for verification at FtmScan.com on 2022-04-21
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

/**
@title Payment System Contract
@author Lance Henderson
@notice Contract is aimed to facilitate the payment of periodic classes
between a teacher and student
@dev The teacher in this scenario would create a position, specifying the spender
address and weekly allowance of the student.
*/

contract Payment { 

    // A position represents the relationship between the Owner and spender
    struct Position {
        address owner;
        address spender;
        uint256 totalDeposit;
        uint256 weeklyAllowance;
        uint256 lastClaim;
    }

    // Array to keep track of all position ever created
    Position[] public positions;

    // Mapping to keep track of users TOTAL deposits
    mapping(address => uint256) public addressDeposits;

    /* ======= CORE FUNCTIONS (Creating/claiming positions) ====== */

    // Allows anyone to create a position
    function createPosition(
        address _spender,
        uint256 _weeklyAllowance
        ) public payable {
          
        // Creation of position
        Position memory newPosition = Position(
            msg.sender,
            _spender,
            msg.value,
            _weeklyAllowance * (1 ether),
            block.timestamp
        );

        // Position is pushed to the array
        positions.push(newPosition);
        // Add deposit amount to 'addressDeposits' mapping
        addressDeposits[msg.sender] += msg.value;
        
    }

    // Sends the claimable amount of a position to its corresponding spender
    function claimPositions() public {

        for(uint i; i < positions.length; i++) {
            uint256 weeksSinceLastClaim = (block.timestamp - positions[i].lastClaim) / 1 weeks;
            uint256 claimable = weeksSinceLastClaim * positions[i].weeklyAllowance;
            // Make sure the position has enough funds
            if( positions[i].totalDeposit >= claimable) {
                // Update the state of the position / and the mapping
                positions[i].lastClaim = block.timestamp;
                positions[i].totalDeposit -= claimable;
                addressDeposits[positions[i].owner] -= claimable;
                // Send the funds to the spender
                payable(positions[i].spender).transfer(claimable);
            }
            
        }
        
       
    }

    /* ======= POSITION MUTATIVE FUNCTIONS ============ */ 

    // Allows the owner to change the allowance
    function editAllowance(uint256 newAllowance, uint256 index) public {
        require(positions[index].owner == msg.sender, "Cannot edit the position");
        positions[index].weeklyAllowance = newAllowance;
    }

    // Allows the owner of a position to top up its balance
    function deposit(uint256 index) public payable {
        positions[index].totalDeposit += msg.value;
        addressDeposits[msg.sender] += msg.value;
    }

    // Allows anyone to withdraw all funds deposited in their positions
    function withdrawMyFunds() external {
        for(uint i; i < positions.length; i++) {
            if (positions[i].owner == msg.sender) {
                uint256 value = positions[i].totalDeposit;
                positions[i].totalDeposit = 0;
                addressDeposits[msg.sender] -= value;
                payable(msg.sender).transfer(value);
                
            }
        }
    }

    /* ======== VIEW FUNCTIONS ========= */

    // returns eth balance of address(this)
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // returns number of positions created 
    function positionsCreated() external view returns (uint256) {
        return positions.length;
    }

    function getAddressDeposits(address addr) external view returns (uint256) {
        return addressDeposits[addr];
    }

}
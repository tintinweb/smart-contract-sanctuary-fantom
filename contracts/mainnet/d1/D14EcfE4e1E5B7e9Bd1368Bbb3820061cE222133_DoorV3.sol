/**
 *Submitted for verification at FtmScan.com on 2023-05-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DoorV3{

    event DoorTriggered(Status status);

    address payable public owner; 

    enum Status{
        open,
        closed
    }

    Status public status; 

    function getDoorStatus() public view returns (Status){
        return status;
    }

    function setDoorStatus(Status _status) private{
        status = _status;
    }

    constructor () payable{
        owner = payable(msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender ==owner, "function is only for contract owner");
        _;
    }

    function toggleDoor() public onlyOwner(){
        if(getDoorStatus()==Status.open){
        setDoorStatus(Status.closed);
        }
        else{
        setDoorStatus(Status.open);
        }
        emit DoorTriggered(getDoorStatus());
    }


    function getAddress() public view returns (address){
        return address(this);
    } 
    
}
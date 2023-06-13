/**
 *Submitted for verification at FtmScan.com on 2023-06-13
*/

// SPDX-License-Identifier: MIT

/**
 * @title Azina Verification Contract
 * @notice Submitted to the Fantom Q2 2023 Hackathon
 * @notice NOT FOR PRODUCTION USE
 * @author Robert Mutua (https://github.com/freelancer254)
 */

pragma solidity ^0.8.0;

contract AZINA_VERIFICATION{

    address private s_owner; //to store address of the owner
    mapping(address => bool ) public s_whiteListedAddresses; //to store whitelisted addresses


    constructor(){
        s_owner = msg.sender;
    }

    //add address to the whitelist
    function addToWhiteList(address[] memory _addr) external onlyOwner{
        uint8 i = 0;
        for (i; i < _addr.length; i++){
            s_whiteListedAddresses[_addr[i]] = true;
        }

    }

    //remove address from whitelist
    function removeFromWhiteList(address[] memory _addr) external onlyOwner{
        uint8 i = 0;
        for(i; i< _addr.length; i++){
            s_whiteListedAddresses[_addr[i]] = false;
        }
    }

    //check if an address is whitelisted
    function checkVerificationStatus(address _addr) external view returns(bool status){
        status = s_whiteListedAddresses[_addr];
        return status;
    }

    //onlyOwner modifier
    modifier onlyOwner(){
        require(msg.sender == s_owner);
        _;
    }
}
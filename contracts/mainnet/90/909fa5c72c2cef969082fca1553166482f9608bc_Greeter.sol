/**
 *Submitted for verification at FtmScan.com on 2022-03-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {
        //console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
    }

    function greet(uint256 len) public view returns (uint256 ) {
        //uint256 myDAIBALANCE = IERC20(0xB66b5D38E183De42F21e92aBcAF3c712dd5d6286).balanceOf(0xBA9bB6a24deF34c68628156893746e729eD6C506);
        //console.log("myDAIBALANCE", myDAIBALANCE, msg.sender);
        uint256 i=0;
        uint256 cnt=0;

        for(i;i<len;i++) {
            cnt++;
        }

        return cnt;
        //return myDAIBALANCE;
    }

    function setGreeting(string memory _greeting) public {
        //console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }
}
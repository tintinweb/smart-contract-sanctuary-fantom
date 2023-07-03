/**
 *Submitted for verification at FtmScan.com on 2023-07-03
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;


contract UserRegistry { 

    address public admin;  

    struct User {
        address   userEVMAddress;
        string    userEVMAddressString;    
        string    userChain;            //FANTOM,MOONBEAM,BINANCE
        string    userSubstrateAddressString;  
        string    usererHex;
    }   

    mapping(address => User) public users;           
    mapping(address => bool) public isUserRegistered;          

    modifier onlyAdmin {
        require(msg.sender==admin,"action only for admin");
        _;
    }  

    constructor() {
        admin = msg.sender;
    }
   
    // 0xa95b7843825449DC588EC06018B48019D1111000,"0xa95b7843825449DC588EC06018B48019D1111000","FANTOM","",""
    // 0xa95b7843825449DC588EC06018B48019D1111000,"0xa95b7843825449DC588EC06018B48019D1111000","MOONBEAM","",""
    // 0xa95b7843825449DC588EC06018B48019D1111000,"0xa95b7843825449DC588EC06018B48019D1111000","BINANCE","",""
    function registerUser(address _userEVMadddress , string memory _userEVMAddressString, string memory _userChain, string memory _userSubstrateAddressString, string memory _userHex) external {
            
            if (!isUserRegistered[_userEVMadddress])
            {
                users[_userEVMadddress] = User({ 
                                                        userEVMAddress: _userEVMadddress, 
                                                        userEVMAddressString: _userEVMAddressString, 
                                                        userChain: _userChain, 
                                                        userSubstrateAddressString: _userSubstrateAddressString, 
                                                        usererHex: _userHex 
                                                    });
                isUserRegistered[_userEVMadddress] = true;
            }
    }  

    function getUserChain(address _userEVMadddress) external view returns(string memory){
            return users[_userEVMadddress].userChain;
    }

}
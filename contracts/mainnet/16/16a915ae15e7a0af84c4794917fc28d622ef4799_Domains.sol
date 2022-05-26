// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.11;

import "IERC20.sol";

contract Domains {

    address private contractOwner;
    IERC20 token;

    struct Domain {
        string name;
		string IP;
        address owner;
        uint lockTime;
        string infoDocumentHash;
    }
    Domain private firstDomain; 
    
    mapping (string => uint) private DomainToIndex; 
    
    Domain[] public DomainList;
    
    constructor() {
        token = IERC20(0xe8C41Bf05D896bCC7288C474c00eab413d72867D);
        contractOwner = msg.sender;

        firstDomain.name = "empty";
		firstDomain.IP = "n/a";
        firstDomain.owner = payable(0x000000000000000000000000000000000000dEaD);
        firstDomain.lockTime = 0;
        firstDomain.infoDocumentHash = "n/a";
        
        DomainToIndex[firstDomain.name] = 0;
        DomainList.push(firstDomain);
    }

    modifier StringLimit(string memory name) {
        bytes memory stringBytes = bytes(name);
        if(stringBytes.length < 2)
          revert("Error: Domain name too short.");
        _;
    }
    
    modifier OnlyContractOwner {
        require (msg.sender == contractOwner, "Error: You are not the contract owner.");
        _;
    }

    modifier OnlyDomainOwner(string memory name) {
        require(DomainList[DomainToIndex[name]].owner == msg.sender, "Error: You are not an owner of the domain.");
        require(DomainList[DomainToIndex[name]].lockTime > 0, "Error: Your ownership of the domain has expired.");
        _;
    }
    
    event NewDomainRegisteredLog(string name, address owner, uint timeDuration);
	event RenewDomainRegisteredLog(string name, address owner, uint timeDuration);
    
    event DomainTransferLog(string name, address owner, uint timeDuration);

    function RegisterDomain(string memory name, string memory IP, uint256 _tokenamount) public 
        StringLimit(name) returns(bool){

        require(_tokenamount >= GetAllowance(msg.sender), "Please approve tokens before transferring");
       
        if(msg.sender == DomainList[DomainToIndex[name]].owner) {
            DomainList[DomainToIndex[name]].lockTime += 365 days;
			DomainList[DomainToIndex[name]].IP = IP;
        }
        else {
		    require(DomainList[DomainToIndex[name]].lockTime < block.timestamp, "Error: The domain is owned by someone else.");
            DomainToIndex[name] = DomainList.length;
            Domain memory newDomain;
                newDomain.name = name;
				newDomain.IP = IP;
                newDomain.owner = msg.sender;
                newDomain.lockTime = block.timestamp + 365 days;
                newDomain.infoDocumentHash = "Not Available";
            
            DomainList.push(newDomain);
        }

        token.transferFrom(msg.sender, address(this), _tokenamount);
        
        emit NewDomainRegisteredLog(name, DomainList[DomainToIndex[name]].owner, DomainList[DomainToIndex[name]].lockTime);
        
        return true;
    } 

    function RenewDomain(string memory name, uint256 _tokenamount) public StringLimit(name) returns(bool) {
	
        require(_tokenamount >= GetAllowance(msg.sender), "Please approve tokens before transferring");

		if(msg.sender == DomainList[DomainToIndex[name]].owner) {
            DomainList[DomainToIndex[name]].lockTime += 365 days;
        } 

		token.transferFrom(msg.sender, address(this), _tokenamount);
        
        emit RenewDomainRegisteredLog(name, DomainList[DomainToIndex[name]].owner, DomainList[DomainToIndex[name]].lockTime);
        
        return true;

	}

    function EditDomain(string memory name, string memory IP, string memory hash) public
        OnlyDomainOwner(name) {
		
        DomainList[DomainToIndex[name]].IP = IP;
        DomainList[DomainToIndex[name]].infoDocumentHash = hash;
    }

    function TransferDomain(string memory name, address newOwner) public
        OnlyDomainOwner(name) {
        
        DomainList[DomainToIndex[name]].owner = payable(newOwner);
        
        emit DomainTransferLog(name, newOwner, DomainList[DomainToIndex[name]].lockTime);
    }

    function AddDomainInfoDocument(string memory name, string memory hash) public 
        OnlyDomainOwner(name) {
            DomainList[DomainToIndex[name]].infoDocumentHash = hash;
    }

    function GetDomainInfo(string memory name) view public 
        StringLimit(name) 
        returns(string memory, string memory, address, uint, string memory) {
        
        uint index = DomainToIndex[name];
        
        return (DomainList[index].name, DomainList[index].IP, DomainList[index].owner, 
        DomainList[index].lockTime,DomainList[index].infoDocumentHash);
    }

    function GetUserTokenBalance(address name) public view returns(uint256){ 
       return token.balanceOf(name);
    }

    function Approvetokens(uint256 _tokenamount) public returns(bool){
       token.approve(address(this), _tokenamount);
       return true;
    }

    function GetAllowance(address name) public view returns(uint256){
       return token.allowance(name, address(this));
    }

    function GetContractBalance() public OnlyContractOwner view returns(uint256) {
        return address(this).balance;
    } 

    function ContractOwnerWithdraw(uint amount) public 
        OnlyContractOwner {
            require(amount > 0 && amount < address(this).balance, "Error: Required value is bigger than existing amount.");
            payable(msg.sender).transfer(amount);
    }
	
    function ContractOwnerTokenWithdraw(address _to, uint256 amount) public 
        OnlyContractOwner {
            require(amount > 0 && amount <= token.balanceOf(address(this)), "Error: Required value is bigger than existing amount.");
            token.transferFrom(address(this), _to, amount);
    }	

}
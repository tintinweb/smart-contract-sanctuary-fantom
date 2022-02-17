/**
 *Submitted for verification at FtmScan.com on 2022-02-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TenPonziPresale {
    uint whitelistCount;
    uint whitelistAllocation;
    uint totalFundCollected;
    uint maximumFund;

    bool openForAll = false;
    bool endWL = false;

    address owner;
    address [] addressList;
    
    mapping(address => bool) whitelistedAddresses;
    mapping(address => uint256) depositedAmount;

    constructor(
    uint _whitelistAllocation,
    uint _maximumFund) {
        owner = msg.sender;
        
        whitelistAllocation = _whitelistAllocation; //250000000000000000000;
        maximumFund = _maximumFund; //125000000000000000000000
        totalFundCollected = 0;
        whitelistCount = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setWhitelistAllocation(uint _whitelistAllocation) external onlyOwner{
        whitelistAllocation = _whitelistAllocation;
    }

    function getWhitelistAllocation() view public returns(uint) {
        return whitelistAllocation;
    }

    function fillPresaleAllocation() public payable {
        require(endWL == false, "Presale is over");
        require(totalFundCollected + msg.value <= maximumFund, "Presale is full");
        if (openForAll == false) require(whitelistedAddresses[msg.sender], "You need to be whitelisted");
        require(msg.value + depositedAmount[msg.sender] <= whitelistAllocation, "Payment above maximum allocation");
        depositedAmount[msg.sender] += msg.value;
        totalFundCollected += msg.value;
    }

    function getAddressDepositedAmount(address _address) view public returns(uint) {
        return depositedAmount[_address];
    }

    function setMaximumFund(uint256 _maximumFundAmount) external onlyOwner {
        maximumFund = _maximumFundAmount;
    }

    function getMaximumFund() view public returns(uint) {
        return maximumFund;
    }

    function setCloseWhitelist(bool _state) external onlyOwner {
        endWL = _state;
    }

    function setOpenForAll(bool _state) external onlyOwner {
        openForAll = _state;
    }

    function isOpenForAll() view public returns(bool) {
        return openForAll;
    }

    function addWhitelistAddress(address _address) external onlyOwner {
        if (whitelistedAddresses[_address] != true) {
            whitelistedAddresses[_address] = true;
            whitelistCount ++;
        }
    }

    function addMultipleAddresses(address[] memory addAddressList) external onlyOwner{
        for (uint i=0; i < addAddressList.length; i++) {
            if (whitelistedAddresses[addAddressList[i]] != true) {
                whitelistedAddresses[addAddressList[i]] = true;
                whitelistCount ++;
            }
        }
    }

    function removeWhitelistAddress(address _address) external onlyOwner {
        whitelistedAddresses[_address] = false;
        whitelistCount --;
    }

    function isWhitelisted(address _whitelistedAddress) public view returns(bool) {
        return whitelistedAddresses[_whitelistedAddress];
    }

    function withdraw() public onlyOwner{
        payable(owner).transfer(address(this).balance);
    }

    function getCurrentBalance() view public returns(uint) {
        return address(this).balance;
    }

    function getTotalFundCollected() view public returns(uint) {
        return totalFundCollected;
    }

    function getWhitelistCount() view public returns(uint) {
        return whitelistCount;
    }

    function getOwner() view public returns(address) {
        return owner;
    }

}
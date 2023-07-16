/**
 *Submitted for verification at FtmScan.com on 2023-07-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract WineDefi {
    address public owner;
    address public wineMaker = 0xc9D11bB24b010D5DefFeacac1704A70e8f8cceF9;
    address public fundManager = 0x631786aACC05A2427579243291A3359ef814fEda;
    uint256 public wineMakerPercentage = 10;
    uint256 public interestRate = 22;
    uint256 public fermentationCycle = 6;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastWithdrawal;
    uint256 public contractBalance;

    event WinemakerHired(address indexed winery, uint256 amount);
    event WineSold(address indexed winery, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyFundManager() {
        require(msg.sender == fundManager, "Only the fund manager can call this function");
        _;
    }

    function hireWinemakersInternal(uint256 amount) internal {
        require(amount > 0, "Amount must be greater than zero");

        uint256 wineMakerAmount = (amount * wineMakerPercentage) / 100;
        uint256 hireAmount = amount - wineMakerAmount;

        payable(wineMaker).transfer(wineMakerAmount);

        deposits[msg.sender] += hireAmount;
        lastWithdrawal[msg.sender] = block.timestamp;
        contractBalance += hireAmount;

        emit WinemakerHired(msg.sender, hireAmount);
    }

    function hireWinemakers() external payable {
        hireWinemakersInternal(msg.value);
    }

    function tradeDeposit() external payable onlyFundManager {
        require(msg.value > 0, "Amount must be greater than zero");

        contractBalance += msg.value;

        emit WinemakerHired(fundManager, msg.value);
    }

    function sellWine() external {
        require(deposits[msg.sender] > 0, "No deposit found");

        uint256 depositAmount = deposits[msg.sender];
        uint256 elapsedTime = block.timestamp - lastWithdrawal[msg.sender];

        uint256 fermentationPeriods = elapsedTime / (1 days); // Calculate the number of 24-hour fermentation periods
        uint256 earnings = (depositAmount * interestRate * fermentationPeriods) / 100;

        // Calculate real-time interest based on the remaining time in the current fermentation period
        uint256 remainingTime = elapsedTime % (1 days);
        uint256 currentEarnings = (depositAmount * interestRate * remainingTime) / (100 * (1 days));

        uint256 interest = earnings + currentEarnings;
        uint256 userShare = (interest * 25) / 100;
        uint256 contractShare = interest - userShare;

        lastWithdrawal[msg.sender] = block.timestamp;

        payable(msg.sender).transfer(userShare); // Pay 25% of the earnings to the user

        // Send the remaining 75% back to the contract by calling hireWinemakersInternal()
        hireWinemakersInternal(contractShare);

        emit WineSold(msg.sender, interest);
    }

    function wineExport() external onlyFundManager {
        uint256 fundAmount = (contractBalance * 20) / 100;

        require(fundAmount > 0, "No funds available for withdrawal");

        payable(fundManager).transfer(fundAmount);
        contractBalance -= fundAmount;

        emit WineSold(fundManager, fundAmount);
    }

    function getDepositAmount(address winery) external view returns (uint256) {
        return deposits[winery];
    }

    function myMaxReturn(address winery) external view returns (uint256) {
        uint256 depositAmount = deposits[winery];
        return (depositAmount * 21) / 10;
    }

    function myDailyReturns(address winery) external view returns (uint256) {
        uint256 depositAmount = deposits[winery];
        return (depositAmount * interestRate) / 100;
    }

    function getContractBalance() external view returns (uint256) {
        return contractBalance;
    }

    function getAccruedEarnings(address winery) external view returns (uint256) {
        uint256 depositAmount = deposits[winery];
        uint256 elapsedTime = block.timestamp - lastWithdrawal[winery];
        uint256 fermentationPeriods = elapsedTime / (1 days); // Calculate the number of 24-hour fermentation periods
        uint256 earnings = (depositAmount * interestRate * fermentationPeriods) / 100;

        // Calculate real-time interest based on the remaining time in the current fermentation period
        uint256 remainingTime = elapsedTime % (1 days);
        uint256 currentEarnings = (depositAmount * interestRate * remainingTime) / (100 * (1 days));

        return earnings + currentEarnings;
    }


    function setInterestRate(uint256 newInterestRate) external onlyFundManager {
        require(newInterestRate >= 0, "Interest rate must be non-negative");
        interestRate = newInterestRate;
    }


}
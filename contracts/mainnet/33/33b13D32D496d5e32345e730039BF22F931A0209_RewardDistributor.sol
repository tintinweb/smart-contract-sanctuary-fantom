/**
 *Submitted for verification at FtmScan.com on 2023-03-22
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// Interfaces
interface SpookySwap {
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);
}

interface EasyBackup {
    function withdrawAll() external payable;
}

contract RewardDistributor {
    // Addresses
    address immutable EASY_BACKUP = 0x164E51048dE21EcF9E4C42399145c7fE7DA2Fb19;
    address immutable SPOOKY_SWAP = 0x31F63A33141fFee63D4B26755430a390ACdD8a4d;
    address immutable USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address immutable EASY = 0x26A0D46A4dF26E9D7dEeE9107a27ee979935F237;
    address immutable WETH = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address immutable xEASY = 0x5Cd9C4bcFDa86dd4C13AF8B04B30B4D8651F2D7C;
    address immutable VIP = 0xF719e950FD6F280EB76D220480e816ff9C216E19;
    // Contracts
    EasyBackup easyBackupContract;
    SpookySwap spookySwapContract;
    IERC20 usdcContract;
    IERC20 easyContract;

    constructor() {
        easyBackupContract = EasyBackup(EASY_BACKUP);
        spookySwapContract = SpookySwap(SPOOKY_SWAP);
        usdcContract = IERC20(USDC);
        easyContract = IERC20(EASY);
    }

    // Methods
    function getFees() internal {
        easyBackupContract.withdrawAll{value: 0}();
    }

    function buyEasy() internal {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = USDC;
        path[2] = EASY;
        spookySwapContract.swapExactETHForTokens{value: address(this).balance}(
            0,
            path,
            address(this),
            block.timestamp + 60
        );
    }

    function distributeEasy() internal {
        uint256 easyBalance = easyContract.balanceOf(address(this));
        easyContract.transfer(VIP, easyBalance / 10);
        easyContract.transfer(xEASY, (easyBalance / 10) * 9);
    }

    function processRewards() internal {
        getFees();
        buyEasy();
        distributeEasy();
    }

    // Chainlink Automation
    function checkUpkeep(
        bytes calldata
    ) external view returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = address(EASY_BACKUP).balance > 0;
    }

    function performUpkeep(bytes calldata /* performData */) external {
        if (address(EASY_BACKUP).balance > 0) {
            processRewards();
        }
    }

    // Fallback
    fallback() external payable {}
}
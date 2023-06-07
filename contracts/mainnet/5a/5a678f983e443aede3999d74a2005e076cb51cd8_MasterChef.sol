// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {IERC20} from "../../src/interfaces/IERC20.sol";

contract MasterChef {
    mapping(address => uint256) public rewardOwedByAccount;
    IERC20 public rewardToken =
        IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75); // USDC
    address public owner;
    address public strategy;

    constructor() {
        owner = msg.sender;
    }

    function accrueReward() external {
        rewardOwedByAccount[strategy] += 1e6;
    }

    function initialize(address _strategy) external {
        require(strategy == address(0), "Already initialized");
        strategy = _strategy;
    }

    // Mock reward earning. In reality user will probably call deposit or withdraw with amount set to zero to initialize a reward earn
    function getReward() external {
        uint256 amountOwed = rewardOwedByAccount[strategy];
        if (amountOwed > 0) {
            rewardToken.transfer(strategy, amountOwed);
        }
        rewardOwedByAccount[strategy] = 0;
    }

    function sweep() external {
        require(msg.sender == owner);
        rewardToken.transfer(owner, rewardToken.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function approve(address, uint256) external;

    function transferFrom(address from, address to, uint256 amount) external;

    function decimals() external view returns (uint256);
}
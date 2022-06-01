/**
 *Submitted for verification at FtmScan.com on 2022-06-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface IStrategy {
    function harvestTrigger(uint256 callCost) external view returns (bool);
    function harvest() external ;
}

contract StrategyHarvester {

    function triggerChecker(address strategyAddress)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {

        // solhint-disable not-rely-on-time
        canExec = IStrategy(strategyAddress).harvestTrigger(0);
        execPayload = abi.encodeWithSelector(
            IStrategy.harvest.selector,
            ""
        );

    }
}
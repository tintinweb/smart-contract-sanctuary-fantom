// contracts/SimpleCrowdsale.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.5;

import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";
import "./PostDeliveryCrowdsale.sol";
import "./RefundablePostDeliveryCrowdsale.sol";
import "./CappedCrowdsale.sol";

contract MyCrowdsale is Crowdsale, TimedCrowdsale, RefundableCrowdsale, RefundablePostDeliveryCrowdsale, CappedCrowdsale {

    constructor(
        uint256 rate,            // rate, in TKNbits
        address payable wallet,  // wallet to send Ether
        IERC20 token,            // the token
        uint256 cap,             // total cap, in wei
        uint256 goal,            // the minimum goal, in wei
        uint256 openingTime,     // opening time in unix epoch seconds
        uint256 closingTime      // closing time in unix epoch seconds
    )
        CappedCrowdsale(cap)
        RefundableCrowdsale(goal)
        RefundablePostDeliveryCrowdsale()
        TimedCrowdsale(openingTime, closingTime)
        Crowdsale(rate, wallet, token)
        public
    {
        // nice! this Crowdsale will keep all of the tokens until the end of the crowdsale
        // and then users can `withdrawTokens()` to get the tokens they're owed
    }
}
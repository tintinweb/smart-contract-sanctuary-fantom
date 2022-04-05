//     ___                         __ 
//    /   |  _____________  ____  / /_
//   / /| | / ___/ ___/ _ \/ __ \/ __/
//  / ___ |(__  |__  )  __/ / / / /_  
// /_/  |_/____/____/\___/_/ /_/\__/  
// 
// 2022 - Assent Protocol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IAssentBondManager.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

// This contrat can be executed only once to mint the ASNT token for launch liquidity

contract AssentExtraMintForLiquidity is Ownable {
    using SafeERC20 for IERC20;

    bool public constant IS_BOND = true;
    bool public executedOnce = false;

    address public immutable bondManager;
    
    constructor ( 
        address _bondManager
    ) {
        bondManager = _bondManager;
    }

    function getTokenForLaunchLiquidity(address _address, uint256 amount) external onlyOwner {
        require (executedOnce == false, "already called");
        executedOnce = true;
        bool distributeSuccess = IAssentBondManager(bondManager).distributeRewards( address(_address), amount );
        require (distributeSuccess == true, "Distribute not possible");
    }

}
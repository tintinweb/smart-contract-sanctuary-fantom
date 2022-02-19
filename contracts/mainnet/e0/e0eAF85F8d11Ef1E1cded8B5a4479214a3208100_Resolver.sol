// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./interfaces/IResolver.sol";
import "./interfaces/IStrategyResolver.sol";

interface IClaim {
    function claim() external;
}

contract Resolver is IResolver {

    address public strategy;
    uint256 public callRewardChecker;
    address public owner;


    constructor(address _strategy, uint256 _callRewardChecker) public {
        strategy = _strategy;
        callRewardChecker = _callRewardChecker; //1 wftm
        owner = msg.sender;
    }

    function checker() external view override returns (bool canExec, bytes memory execPayload) {
        uint256 _callReward = IStrategyResolver(strategy).callReward();
        canExec = _callReward >= callRewardChecker;

        execPayload = abi.encodeWithSelector(
            IClaim.claim.selector
        );
    }


    function modifiyCondition(uint256 _newCallRewardChecker) external {
        require(msg.sender == owner, 'not allowed');
        callRewardChecker = _newCallRewardChecker;
    }

    function changeOwner(address _newOwner) external {
        require(msg.sender == owner, 'not allowed');
        owner = _newOwner;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IResolver {
    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


interface IStrategyResolver{

    function callReward() external view returns(uint256);
    function harvest() external;
    
}
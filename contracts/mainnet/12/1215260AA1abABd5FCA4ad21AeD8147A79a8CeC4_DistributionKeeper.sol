// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./interfaces/IResolver.sol";


interface IGaugeL1{

    function distribute() external;
    function epochCounter() external view returns (uint256);
    
}

interface IVoterProxy{

    function currentEpoch() external view returns(uint256);
    function getCurrentRound() external view returns (uint256);
    
}

contract DistributionKeeper is IResolver {

    address public gaugeL1;
    address public voterProxy;
    address public owner;

    bool paused;

    constructor(address _gaugeL1, address _voterProxy) public {
        gaugeL1 = _gaugeL1;
        voterProxy = _voterProxy;
        owner = msg.sender;
        paused = false;
    }

    function checker() external view override returns (bool canExec, bytes memory execPayload)  {
        require(paused == false, 'paused');

        if(IVoterProxy(voterProxy).currentEpoch() <= IGaugeL1(gaugeL1).epochCounter()){
            uint256 _round = IVoterProxy(voterProxy).getCurrentRound();
            require(_round != 0,"wait round end");
            canExec = true;
        }    
              
        execPayload = abi.encodeWithSelector(
            IGaugeL1.distribute.selector
        );
    }

    function changeOwner(address _newOwner) external {
        require(msg.sender == owner, 'not allowed');
        owner = _newOwner;
    }

    function pauseUpdate() external {
        require(msg.sender == owner, 'not allowed');
        paused = true;
    }

    function unPauseUpdate() external {
        require(msg.sender == owner, 'not allowed');
        paused = false;
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
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./interfaces/IResolver.sol";
import "./interfaces/IVoterProxy.sol";


interface IVoterProxyCall {
    function updateEpoch() external;
}


contract EpochUpdateResolver is IResolver {

    address public voterProxy;
    address public owner;

    bool paused;

    constructor(address _voterProxy) public {
        voterProxy = _voterProxy;
        owner = msg.sender;
        paused = false;
    }

    function checker() external view override returns (bool canExec, bytes memory execPayload)  {
        require(paused == false, 'paused');
        bool _canUpdateEpoch = IVoterProxy(voterProxy).checkEpochUpdate();
        
        if(_canUpdateEpoch){
            canExec = true;
        } else {
            canExec = false;
        }

        execPayload = abi.encodeWithSelector(
            IVoterProxyCall.updateEpoch.selector
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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IVoterProxy {
    struct userVoteInfo {
        address[] tokens;
        uint256[] weights;
        uint256 votePower;
    }
    
    function getUserInfoData(uint256 _epoch,address _user, address _proxy) external view returns (address[] memory _tokens, uint256[] memory _weights, uint256 _votePower);
    function getUserInfo(uint256 _epoch,address _user, address _proxy) external view returns (userVoteInfo memory userVote);
    function getVotePowerForToken(uint256 _epoch,address _user,address _tokenToVote,address _proxy) external view returns(uint256);    
    function getVotePowerForTokenDelegation(uint256 _epoch,address _user,address _tokenToVote, address _proxy) external view returns(uint256 votePowerUsedForToken);

    function getEpochInfo() external view returns(uint256 _epochBlock,uint256 _epochStart,uint256 _epochCounter,uint256 _EPOCH);
    function getUserDelegatedAmount(address _delegated) external returns(uint256);
    function currentEpochLen() external view returns (uint256 _thisEpochLen);
    function getCurrentRound() external view returns(uint256);
    function currentEpoch() external view returns (uint256 _thisEpoch) ;
    function getDelegationPeriod(address _user) external view returns(uint128 _from, uint128 _to);
    function epochUserDelegationRegistry(address _user, uint256 _epoch) external view returns (bytes memory);
    function getUserDelegatedAmountPerEpoch(address _delegated, uint256 _epoch) external view returns (uint256);
    function checkIsProxy(address _proxy) external returns(bool);
    function checkEpochUpdate() external view returns(bool _update);
}
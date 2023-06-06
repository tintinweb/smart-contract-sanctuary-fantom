// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface RandomNumberInterface {
  
  struct RandomNumberRequest {
    address requestReciver;
    address user;
    uint256 requestBlockNumber;
    uint256 maxFee;
    uint32 gasLimit;
    uint32 randomNumberCount;
    uint8 requestConfirmations;
  }

  // node management
  function registerNode() external;
  function unregisterNode() external;  
  function collectFees() external;

  // user
  function deposit() external payable;
  function withdraw(uint256 amount) external;
  function depositUser(address userAddress) external payable;
  function withdrawUser(address userAddress, uint256 amount) external;
  function refundExpiredRequest(uint256 requestId) external;

  // RandomNumber
  function estimateFee(uint256 gasUsed) external view returns (uint256 nativeTokenUsedWithFee);
  function isPrioritySender(address operator, uint256 blocknumber) external view returns (bool);
  function requestRandom(address user, uint32 gasLimit, uint32 randomNumberCount, uint8 requestConfirmations) external payable returns (uint256 requestId);
  function fulfillRandomRequest(uint256 requestId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract RandomNumberReciverBase {
  error WrongRandomNumberSender(address randomNumberAddress, address sender);
  address private immutable randomNumberAddress;

  constructor(address _randomNumberAddress) {
    randomNumberAddress = _randomNumberAddress;
  }

  function rawRandomNumberCallback(uint256 requestId, uint256[] memory randomNumbers) external {
    if (msg.sender != randomNumberAddress) {
      revert WrongRandomNumberSender(randomNumberAddress, msg.sender);
    }
    randomNumberCallback(requestId, randomNumbers);
  }

  function randomNumberCallback(uint256 requestId, uint256[] memory randomNumbers) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interface/RandomNumberReciverBase.sol";
import "../interface/RandomNumberInterface.sol";

contract Test is RandomNumberReciverBase {
  RandomNumberInterface immutable randomNumberContract;

  event RandomNumberResult(uint256 requestId, uint256[] randomNumbers);


  constructor(address _randomNumberAddress) RandomNumberReciverBase(_randomNumberAddress) {
    randomNumberContract = RandomNumberInterface(_randomNumberAddress);
  }

  uint256 pendingRequest;
  function requestRandomNumber(uint32 gasLimit, uint32 randomNumberCount, uint8 requestConfirmations) external payable {
    require(pendingRequest == 0, "Pending request");
    randomNumberContract.requestRandom(msg.sender, gasLimit, randomNumberCount, requestConfirmations);
  }

  function randomNumberCallback(uint256 requestId, uint256[] memory randomNumbers) internal override {
    emit RandomNumberResult(requestId, randomNumbers);
  }
}
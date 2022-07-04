//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibPseudoRandom {
  /**
   * @dev Reward for opening a crate, 'tokenId' corresponds to ERC1155 ids
   */
  struct Reward {
    uint256 tokenId;
    uint256 amount;
  }

  /**
   * @dev Struct created to pack the basic game information required for 'interateCratesLogic()'
   */
  struct GameInfo {
    uint32 nftCardIdStart;
    uint32 cardsAmount;
    uint32 pointsID;
    uint32 mintedCards;
    uint32 numPlayers;
    uint32 cardsPerDayRatio;
  }

  uint256 private constant decimals = 6;

  /**
   * @dev Returns result of openening a series of creates
   * This function was refactored out of {NFTInteractions.sol} to reduce bytecode.
   */
  function iterateCratesLogic(
    uint256 amount,
    uint256[] memory _crateRewards,
    uint256[] memory _probabilityIntervals,
    uint256 entropyValue,
    GameInfo memory _gameInfo
  ) external view returns (Reward[] memory rewards, uint256[] memory aggregatedRewards) {
    uint256[] memory randomNumbers = _pickRandomNumbers(amount, entropyValue);
    rewards = new Reward[](amount);
    aggregatedRewards = new uint256[](1 + 3 + _gameInfo.cardsAmount);
    bool isCard;
    // iterate all crates to open
    for (uint256 j = 0; j < amount;) {
      isCard = true;
      // iterate propability intervals to see the reward for a specific crate
      for (uint256 i = 0; i < _probabilityIntervals.length && isCard;) {   
        if (randomNumbers[j] <= _probabilityIntervals[i]) {
          isCard = false;
          aggregatedRewards[uint256(_gameInfo.pointsID)] += _crateRewards[i];
          rewards[j].amount = _crateRewards[i];
        }
        unchecked {
          ++i;
        }
      }
      // if the reward is a card determine the card id
      if (isCard) {
        bool mintedCard;
        (rewards , aggregatedRewards, mintedCard) =_isCardRoutine(
          j,
          entropyValue,
          _gameInfo,
          _crateRewards[0],
          rewards,
          aggregatedRewards
        );

        if (mintedCard) {
          _gameInfo.mintedCards++;
        }
      }
      unchecked {
        ++j;
      }
    }
  }

  /**
   * @dev Returns amount of requested picks of a pseudo-random number between 0 and 1.
   * @dev Decimals is defined by constant.
   * @param amountOfPicks number of random picks to return.
   * @param entropy random value that must be provided from a reliable oracle source.
   * @return results array of picks.
   */
  function pickRandomNumbers(uint256 amountOfPicks, uint256 entropy)
    external
    view
    returns (uint256[] memory results)
  {
    results = _pickRandomNumbers(amountOfPicks, entropy);
  }

  /**
   * @dev Returns amount and type of cards received, if the opened crate resulted in a card reward.
   */
  function _isCardRoutine(
    uint256 jLoop,
    uint256 entropyValue,
    GameInfo memory gameInfo,
    uint256 basicCrateReward,
    Reward[] memory _rewards,
    uint256[] memory _aggregatedRewards
  ) internal view returns (Reward[] memory rewards, uint256[] memory aggregatedRewards, bool mintedCard) {
    rewards = _rewards;
    aggregatedRewards = _aggregatedRewards;
    if (gameInfo.mintedCards < gameInfo.numPlayers / gameInfo.cardsPerDayRatio) {
      mintedCard = true;
      uint256 step = 1000000 / gameInfo.cardsAmount;
      uint256 randomNum = _pickProbability(0, entropyValue + jLoop);
      for (uint256 i = step; i <= randomNum; i += step) {
        gameInfo.nftCardIdStart++;
      }
      aggregatedRewards[gameInfo.nftCardIdStart]++;
      rewards[jLoop].tokenId = gameInfo.nftCardIdStart;
      rewards[jLoop].amount = 1;
    } else {
      aggregatedRewards[gameInfo.pointsID] += basicCrateReward;
      rewards[jLoop].amount = basicCrateReward;
    }
  }

  /**
   * @dev See {pickRandomNumbers()}
   */
  function _pickRandomNumbers(uint256 amountOfPicks, uint256 entropy)
    internal
    view
    returns (uint256[] memory results)
  {
    require(amountOfPicks > 0, "Invalid amountOfPicks!");
    results = new uint256[](amountOfPicks);
    for (uint256 i = 0; i < results.length; i++) {
      results[i] = _pickProbability(i, entropy);
    }
  }

  /**
   * @dev Returns a number in range.
   */
  function _pickProbability(uint256 nonce, uint256 entropy) private view returns (uint256 index) {
    index = (_random(nonce, entropy) % 10**decimals) + 1;
  }

  /**
   * @dev Returns a pseudo random number given nonce and entropy for external source. 
   */
  function _random(uint256 nonce, uint256 entropy) private view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(block.difficulty, block.timestamp, block.coinbase, entropy, nonce)
        )
      );
  }
}
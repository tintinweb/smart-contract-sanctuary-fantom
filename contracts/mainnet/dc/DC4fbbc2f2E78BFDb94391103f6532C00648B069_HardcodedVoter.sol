// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {IVotingSnapshot} from "IVotingSnapshot.sol";

contract HardcodedVoter {

  // The account that can undo the voting
  address public immutable  governance;

  // The strategy that is delegating to us
  address public immutable  strategy;

  // Contract we vote on
  IVotingSnapshot constant VOTING_SNAPSHOT = IVotingSnapshot(0xDA007a39a692B0feFe9c6cb1a185feAb2722c4fD);

  // Pool we're voting for
  address constant POOL =  0x6519546433dCB0a34A0De908e1032c46906EF664; // Volatile OXD / bveOXD 

  constructor(address newGovernance, address newStrategy) {
    governance = newGovernance;
    strategy = newStrategy;
  }

  /// @dev Casts vote to target contract
  /// @notice Can be called by anyone as our votes are hardcoded
  /// @notice For user security, check how delegation is handled at the strategy level
  function vote() external {
    // Get Total Votes we got
    int256 totalVotes = int256(VOTING_SNAPSHOT.voteWeightTotalByAccount(strategy));

    // NOTE: If you had multiple pools this is where you can split by ratios
    // NOTE: Not needed in this version

    // Vote
    VOTING_SNAPSHOT.vote(strategy, POOL, totalVotes);
  }

  /// @dev Undoes the vote
  /// @notice Can be called by gov exclusively
  /// @notice To be used before migrating delegate
  function undoVote() external {
    require(msg.sender == governance);

    // Vote
    VOTING_SNAPSHOT.vote(strategy, POOL, 0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11||0.6.12;
pragma experimental ABIEncoderV2;

struct Vote {
    address poolAddress;
    int256 weight;
}
interface IVotingSnapshot {

    function vote(address, address, int256) external;

    function removeVote(address) external;

    function resetVotes() external;

    function resetVotes(address) external;

    function setVoteDelegate(address) external;

    function clearVoteDelegate() external;

    function voteDelegateByAccount(address) external view returns (address);

    function votesByAccount(address) external view returns (Vote[] memory);

    function voteWeightTotalByAccount(address) external view returns (uint256);

    function voteWeightUsedByAccount(address) external view returns (uint256);

    function voteWeightAvailableByAccount(address)
        external
        view
        returns (uint256);
}
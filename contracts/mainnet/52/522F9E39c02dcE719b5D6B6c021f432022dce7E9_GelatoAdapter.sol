// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./voteResetter.sol";

/**
 * @title 0xDAO Gelato Adapter
 * @author 0xDAO
 * @notice Adapter for Gelato tasks to add support for limiting gas price
 */

contract GelatoAdapter {
    /**
	@notice resets 0xDAO votes only after 0xDAO claims the inflation for its veNFT
	 */
    function resetVotes(address voteResetterAddress, uint256 maxGasPriceInGwei)
        external
    {
        require(tx.gasprice < maxGasPriceInGwei * 1 gwei, "Gas price too high");

        VoteResetter(voteResetterAddress).resetVotes();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
@notice Reset 0xDAO votes to 0 after claiming inflation SOLID for the veNFT to avoid Solidly bribe contract bugs
 */

interface IVoterProxy {
    function primaryTokenId() external view returns (uint256);

    function claim() external;

    function vote(address[] memory poolVote, int256[] memory weights) external;
}

interface IVeDist {
    function timestamp() external view returns (uint256);

    function time_cursor_of(uint256) external view returns (uint256);

    function claim(uint256) external returns (uint256);
}

contract VoteResetter {
    address public constant voterProxyAddress =
        address(0xDA0027f2368bA3cb65a494B1fc7EA7Fd05AB42DD);
    address public constant veDistAddress =
        address(0xA5CEfAC8966452a78d6692837b2ba83d19b57d07);
    uint256 public lastReset;

    /**
	@notice resets 0xDAO votes only after 0xDAO claims the inflation for its veNFT
	 */
    function resetVotes() external {
        IVoterProxy voterProxy = IVoterProxy(voterProxyAddress);
        IVeDist veDist = IVeDist(veDistAddress);
        uint256 timeCursorOfNft = veDist.time_cursor_of(
            voterProxy.primaryTokenId()
        );
        uint256 veDistTimestamp = veDist.timestamp();
        require(
            timeCursorOfNft == veDistTimestamp,
            "Inflation not yet claimed"
        );
        require(lastReset < veDistTimestamp, "Already reset");
        lastReset = veDistTimestamp;

        voterProxy.vote(new address[](0), new int256[](0));
    }
}
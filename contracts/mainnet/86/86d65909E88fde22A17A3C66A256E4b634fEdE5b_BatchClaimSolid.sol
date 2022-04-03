// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoterProxy {
    function primaryTokenId() external view returns (uint256);

    function claim() external;
}

interface IVeDist {
    function timestamp() external view returns (uint256);

    function time_cursor_of(uint256) external view returns (uint256);

    function claim(uint256) external returns (uint256);
}

//batching claim() to update indexes
contract BatchClaimSolid {
    address public constant voterProxyAddress =
        address(0xDA0027f2368bA3cb65a494B1fc7EA7Fd05AB42DD);
    address public constant veDistAddress =
        address(0xA5CEfAC8966452a78d6692837b2ba83d19b57d07);

    function batchClaim(uint256 runs, uint256 maxGasPriceInGwei) external {
        IVoterProxy voterProxy = IVoterProxy(voterProxyAddress);
        IVeDist veDist = IVeDist(veDistAddress);
        uint256 timeCursorOfNft = veDist.time_cursor_of(
            voterProxy.primaryTokenId()
        );
        require(timeCursorOfNft < veDist.timestamp(), "Already claimed");
        require(tx.gasprice < maxGasPriceInGwei * 1 gwei, "Gas price too high");
        for (uint256 i = 0; i < runs; i++) {
            voterProxy.claim();
        }
    }
}
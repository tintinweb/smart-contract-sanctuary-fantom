/**
 *Submitted for verification at FtmScan.com on 2023-01-11
*/

pragma solidity 0.8.17;

interface IVeFbaRoom {
    function depositedNFT(address account) external view returns (uint256);
}

interface IVeFBA {
    function balanceOfNFT(uint256 _tokenId) external view returns (uint256);
}

contract FBAVotingPower {
    function votingPowerOf(address user) external view returns (uint256) {
        uint256 nft = IVeFbaRoom(0xe2A66AE08004cd6ac253b138fBc0a6216d1A968A).depositedNFT(user);
        return IVeFBA(0x5D3E2069B9C1DA07be0CF35f96A3D778741e0bbF).balanceOfNFT(nft);
    }
}
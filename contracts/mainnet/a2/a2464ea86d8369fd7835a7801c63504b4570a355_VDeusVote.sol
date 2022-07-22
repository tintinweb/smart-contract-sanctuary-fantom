/**
 *Submitted for verification at FtmScan.com on 2022-07-22
*/

// File: contracts/interfaces/Ive.sol


interface Ive {
    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex)
        external
        view
        returns (uint256);

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool);

    function balanceOfNFT(uint256 _tokenId) external view returns (uint256);

    function balanceOfNFTAt(uint256 _tokenId, uint256 _t)
        external
        view
        returns (uint256);

    function balanceOfAtNFT(uint256 _tokenId, uint256 _block)
        external
        view
        returns (uint256);

    function totalSupplyAtT(uint256 t) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);
}

// File: contracts/contract.sol


pragma solidity 0.8.13;


contract VDeusVote {
  address public vDeus;

  constructor(address vDeus_) {
    vDeus = vDeus_;
  }

  function balanceOf(address user) public view returns (uint256 balance) {
    uint256 count = Ive(vDeus).balanceOf(user);
    for (uint256 index = 0; index < count; index++) {
      uint256 tokenId = Ive(vDeus).tokenOfOwnerByIndex(user, index);
      balance += Ive(vDeus).balanceOfNFT(tokenId);
    }
  }
}
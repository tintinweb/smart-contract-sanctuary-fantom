// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./Ownable.sol";

interface ISassySnakes {
  function adminMintSnake(address recipient, uint256 numOfTokens) external;
  function setTraitRarities(uint256 tokenId, uint256[] memory snakeRarities) external;
  function enableMinting() external;
  function disableMinting() external;
}

interface IOwnable {
  function transferOwnership(address newOwner) external;
}

interface ISnakeskin {
    function burnFrom(address account, uint256 amount) external;
}

/**
 * A wrapper around the Sassy Snake contract to allow mints to be 
 * priced in SKIN instead of FTM
 */
contract MintProxy is Ownable {

  address public ERC721_CONTRACT;
  address public SKIN_CONTRACT;
  uint256 public mintPrice;
  bool public isProxyEnabled;

  constructor(address _erc721Contract, address _skinContract, uint256 _mintPrice) {
    ERC721_CONTRACT = _erc721Contract;
    SKIN_CONTRACT = _skinContract;
    mintPrice = _mintPrice;
    isProxyEnabled = true;
  }

  function transferErc721Ownership(address newOwner) public onlyOwner {
    IOwnable(ERC721_CONTRACT).transferOwnership(newOwner);
  }

  /**
   * NOTE: Minter must approve Snakeskin contract to burn funds
   */
  function mintSnake(address recipient, uint256 numOfTokens) public {
    require(isProxyEnabled, "Minting is currenlty closed via the mint proxy");

    ISnakeskin(SKIN_CONTRACT).burnFrom(msg.sender, mintPrice * numOfTokens);
    ISassySnakes(ERC721_CONTRACT).adminMintSnake(recipient, numOfTokens);
  }

  function setTraitRarities(uint256 tokenId, uint256[] memory snakeRarities) public onlyOwner {
    ISassySnakes(ERC721_CONTRACT).setTraitRarities(tokenId, snakeRarities);
  }

  function enableMinting() public onlyOwner {
    isProxyEnabled = false;
    ISassySnakes(ERC721_CONTRACT).enableMinting();
  }

  function disableMinting() public onlyOwner {
    isProxyEnabled = true;
    ISassySnakes(ERC721_CONTRACT).disableMinting();
  }

  function setPrice(uint256 newPrice) public onlyOwner {
    mintPrice = newPrice;
  }

}
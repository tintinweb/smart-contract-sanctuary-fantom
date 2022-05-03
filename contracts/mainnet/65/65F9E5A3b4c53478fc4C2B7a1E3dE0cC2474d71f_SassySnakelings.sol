// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

interface IERC721Burnable {
  function burn(uint256 tokenId) external;
}

contract SassySnakelings is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    uint256 public MAX_SUPPLY;
    address public EGGS_ERC721;
    string public baseUri;
    bool public isMintEnabled;

    Counters.Counter private _snakelingMintCounter;
    mapping(address => bool) private _approvedMinters;
    mapping(address => uint256) public huntRewards;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        address _eggs

    ) ERC721(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
        EGGS_ERC721 = _eggs;
        isMintEnabled = false;
    }

    /**
     * Requires all given eggTokenIds to be approved for burning by this contract
     */
    function mintSnakeling(address recipient, uint256[] calldata eggTokenIds) public {
      require(isMintEnabled == true, "Mint is not currently open");
      require(eggTokenIds.length + _snakelingMintCounter.current() <= MAX_SUPPLY, "Not enough supply");

        for (uint256 i = 0; i < eggTokenIds.length; i++) {
          IERC721Burnable(EGGS_ERC721).burn(eggTokenIds[i]);

          _snakelingMintCounter.increment();
          _safeMint(recipient, _snakelingMintCounter.current());	
        }
    }

    function setBaseUri(string memory uri) public onlyOwner {
        baseUri = uri;
    }

    function setSupply(uint256 newSupply) public onlyOwner {
        MAX_SUPPLY = newSupply;
    }

    function supplyMinted() public view returns (uint256) {
        return _snakelingMintCounter.current();
    }

    // Override requirements
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function enableMinting() public onlyOwner {
        isMintEnabled = true;
    }

    function disableMinting() public onlyOwner {
        isMintEnabled = false;
    }

}
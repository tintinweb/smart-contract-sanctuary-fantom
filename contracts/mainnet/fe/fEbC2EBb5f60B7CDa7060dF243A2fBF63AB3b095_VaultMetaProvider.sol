// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./interfaces/IVaultMetaProvider.sol";

contract VaultMetaProvider {

    string public _tokenURI;
    string public baseURI;

    constructor (string memory baseURI_, string memory tokenURI_) {
        _tokenURI = tokenURI_;
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenURI)) : "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVaultMetaProvider {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
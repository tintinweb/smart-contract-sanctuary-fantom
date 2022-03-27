/**
 *Submitted for verification at FtmScan.com on 2022-03-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract Airdropper {
    function airdrop(address contractAddress, address sender, address[] memory recipients, uint256[] memory tokens) public {
        ERC721 erc721 = ERC721(contractAddress);
        for (uint256 i = 0; i < recipients.length; i++) {
            erc721.transferFrom(sender, recipients[i], tokens[i]);
        }
    }
}

abstract contract ERC721 {
    function ownerOf(uint256 id) public virtual returns (address);

    function approve(address to, uint256 id) public virtual;

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual;
}
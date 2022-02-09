/**
 *Submitted for verification at FtmScan.com on 2022-02-09
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface ILexicon_Cards {
    function openPack(uint256 packID) external;

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function balanceOf(address owner) external view returns (uint256 balance);
}

contract AllPackOpener {
    address addressLex = 0x98C12b56258552F143d35be8983077eb6adBe9a4;
    ILexicon_Cards card =
        ILexicon_Cards(addressLex);

    function checkPacks(address _address) view public returns(uint256) {
        return card.balanceOf(_address);
    }

    function openAllPack() public {
        uint256 numberOfCardPacks = card.balanceOf(msg.sender);
        for (uint256 i = 0; i < numberOfCardPacks; i++) {
            card.openPack(card.tokenOfOwnerByIndex(msg.sender, i));
        }
    }
}
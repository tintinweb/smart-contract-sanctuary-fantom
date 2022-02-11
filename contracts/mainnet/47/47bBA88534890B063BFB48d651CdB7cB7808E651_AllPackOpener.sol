/**
 *Submitted for verification at FtmScan.com on 2022-02-09
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface ILexicon_Cards {
    function openPack(uint256 packID) external;
}

interface ILexicon_Packs {
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function balanceOf(address owner) external view returns (uint256 balance);
}

contract AllPackOpener {
    address addressLexPack = 0x98C12b56258552F143d35be8983077eb6adBe9a4;
    address addressLexCard = 0x5A91EeF74683DE4d647F2847e15bE9192Df2CceB;
    ILexicon_Cards card =
        ILexicon_Cards(addressLexCard);
    ILexicon_Packs pack = ILexicon_Packs(addressLexPack);

    function checkPacks(address _address) view public returns(uint256) {
        return pack.balanceOf(_address);
    }

    function openAllPack() public {
        address owner = address(msg.sender);

        uint256 numberOfCardPacks = pack.balanceOf(owner);

        uint256[] memory cardID = new uint256[](numberOfCardPacks);

        for (uint256 i = 0; i < numberOfCardPacks; i++) {
            cardID[i] = (pack.tokenOfOwnerByIndex(owner, i));
        }

        for (uint256 i = 0; i < cardID.length; i++) {
            card.openPack(cardID[i]);
        }
    }
}
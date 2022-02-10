/**
 *Submitted for verification at FtmScan.com on 2022-02-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface ILexicon_Packs {
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function balanceOf(address owner) external view returns (uint256 balance);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function approve(address to, uint256 tokenId) external;
}

interface ILexicon_Cards {
    function openPack(uint256 packID) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function setApprovalForAll(address operator, bool approved) external;
}

contract AllPackOpener is Ownable {
    address addressLexPack = 0x98C12b56258552F143d35be8983077eb6adBe9a4;
    address addressLexCard = 0x5A91EeF74683DE4d647F2847e15bE9192Df2CceB;

    ILexicon_Cards card = ILexicon_Cards(addressLexCard);
    ILexicon_Packs pack = ILexicon_Packs(addressLexPack);

    uint256 uniqueCardNumber = 236;
    uint256 memoryArraySize = 1000;

    function openAllPacks() public {
        uint256 packs = pack.balanceOf(msg.sender);

        uint256[] memory inputPacks = new uint256[](memoryArraySize);

        for (uint256 i = 0; i < packs; i++) {
            inputPacks[i] = pack.tokenOfOwnerByIndex(msg.sender, 0);

            pack.safeTransferFrom(msg.sender, address(this), inputPacks[i]);

            pack.approve(addressLexCard, inputPacks[i]);

            card.openPack(inputPacks[i]);
        }

        for (uint256 i = 1; i <= uniqueCardNumber; i++) {
            if (card.balanceOf(address(this), i) != 0) {
                uint256 tokenBalance = card.balanceOf(address(this), i);

                card.safeTransferFrom(
                    address(this),
                    msg.sender,
                    i,
                    tokenBalance,
                    ""
                );
            }
        }
    }

    function setAddressLexPack(address _address) external onlyOwner {
        addressLexPack = _address;
    }

    function setAddressLexCard(address _address) external onlyOwner {
        addressLexCard = _address;
    }

    function setUniqueCardNumber(uint256 _number) external onlyOwner {
        uniqueCardNumber = _number;
    }

    function setInputPacksNumber(uint256 _number) external onlyOwner {
        memoryArraySize = _number;
    }
}
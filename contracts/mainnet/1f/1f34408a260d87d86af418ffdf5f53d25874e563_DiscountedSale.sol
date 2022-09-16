/**
 *Submitted for verification at FtmScan.com on 2022-09-10
*/

// SPDX-License-Identifier: MIT

//    //   / /                                 //   ) )
//   //____     ___      ___                  //___/ /  //  ___      ___     / ___
//  / ____    //   ) ) ((   ) ) //   / /     / __  (   // //   ) ) //   ) ) //\ \
// //        //   / /   \ \    ((___/ /     //    ) ) // //   / / //       //  \ \
////____/ / ((___( ( //   ) )      / /     //____/ / // ((___/ / ((____   //    \ \
// Developed by Dogu Deniz UGUR (https://github.com/DoguD)

pragma solidity ^0.8.0;

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
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// NFT Contract Interface
interface EasyBlock {
    function shareCount(address _address) external view returns (uint256);
}

interface EasyAvatars {
    function balanceOf(address owner) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenIncludesShare(uint256 tokenId) external view returns (bool);

    function mintForSelfFtm(uint256 amountOfTokens) external payable;
}

contract DiscountedSale is Ownable {
    uint256 public price = 20 ether;
    EasyAvatars easyAvatars =
        EasyAvatars(0x5d6f546f2357E84720371A0510f64DBC3FbACe33);
    EasyBlock easyBlock;

    function mint(address destination, uint256 amountOfTokens) private {
        easyAvatars.mintForSelfFtm{value: 100 ether}(amountOfTokens);
    }

    function mintForSelf(uint256 amountOfTokens) public payable virtual {
        mint(_msgSender(), amountOfTokens);
    }

    function replenishFTM() public payable virtual {
        require(msg.value > 0, "Must send some FTM");
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }
}
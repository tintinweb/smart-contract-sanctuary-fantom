/**
 *Submitted for verification at FtmScan.com on 2022-07-07
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DiscountedSale is Ownable {
    uint256 public price = 20 ether;

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function mint(address destination, uint256 amountOfTokens) private {
        // require(totalSupply() < maxSupply, "All tokens have been minted");
        // require(totalSupply() + amountOfTokens <= maxSupply, "Minting would exceed max supply");

        // require(amountOfTokens <= maxMint, "Cannot purchase this many tokens in a transaction");
        // require(amountOfTokens > 0, "Must mint at least one token");
        require(price * amountOfTokens == msg.value, "ETH amount is incorrect");
    }

    function mintForSelf(uint256 amountOfTokens) public payable virtual {
        mint(_msgSender(),amountOfTokens);
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }
}
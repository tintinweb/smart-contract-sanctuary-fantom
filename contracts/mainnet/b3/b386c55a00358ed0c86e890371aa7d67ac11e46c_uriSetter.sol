/**
 *Submitted for verification at FtmScan.com on 2022-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface lexbase {
    function setURI(uint256 id, string memory uri) external;
}

abstract contract Context {
  function _msgSender() internal view virtual returns(address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns(bytes memory) {
    this;
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract uriSetter is Ownable{

    address public base = 0x5A91EeF74683DE4d647F2847e15bE9192Df2CceB;

    function settingUri(
    uint256 id1, string memory uri1,
    uint256 id2, string memory uri2,
    uint256 id3, string memory uri3,
    uint256 id4, string memory uri4,
    uint256 id5, string memory uri5)
    external onlyOwner {
    lexbase bs = lexbase(base);
    bs.setURI(id1,uri1);
    bs.setURI(id2,uri2);
    bs.setURI(id3,uri3);
    bs.setURI(id4,uri4);
    bs.setURI(id5,uri5);
    }
}
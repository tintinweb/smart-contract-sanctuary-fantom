// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract TestMulti {
    uint256 public index;

    event SwapET(uint256 value, uint256 amountIn, address[] path);
    function swapEthToken(uint256 amountIn, address[] memory path) payable public {
      emit SwapET(msg.value, amountIn, path);
    }

    function setIndex(uint256 a) public {
      index = a;
    }

    function getIndex() public view returns(uint256) {
      return index;
    }
}
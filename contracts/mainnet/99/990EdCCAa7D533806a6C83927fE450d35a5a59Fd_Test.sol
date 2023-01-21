// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Test {
  uint a = 0;

  constructor() {
    a = 1;
  }

  function setA(uint _a) external { a = _a; }

  function getA() external view returns (uint) { return a; }

}
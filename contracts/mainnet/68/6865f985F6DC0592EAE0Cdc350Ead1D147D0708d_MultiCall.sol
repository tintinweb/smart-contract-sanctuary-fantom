// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract MultiCall {
  function multiCall(
      address[] calldata targets,
      bytes[] calldata data
  ) external payable {
      require(targets.length == data.length, "target length != data length");

      bytes[] memory results = new bytes[](data.length);

      for (uint i; i < targets.length; i++) {
          (bool success, bytes memory result) = targets[i].call{value: msg.value }(data[i]);
          require(success, "call failed");
          results[i] = result;
      }
  }
}
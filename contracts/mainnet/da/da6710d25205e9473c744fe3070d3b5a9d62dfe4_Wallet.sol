/**
 *Submitted for verification at FtmScan.com on 2022-11-11
*/

pragma solidity 0.8.6;

contract Enum {
  enum Operation {
    Call,
    DelegateCall
  }
}

contract Wallet {
  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function executeCall(
    address to,
    uint256 value,
    bytes memory data
  ) internal returns (bool success) {
    assembly {
      success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
    }
  }

  function executeDelegateCall(address to, bytes memory data)
    internal
    returns (bool success)
  {
    assembly {
      success := delegatecall(gas(), to, add(data, 0x20), mload(data), 0, 0)
    }
  }

  function execute(
    address to,
    uint256 value,
    bytes calldata data,
    Enum.Operation operation
  ) external returns (bool success) {
    require(msg.sender == owner, "Only owner");
    if (operation == Enum.Operation.Call)
      success = executeCall(to, value, data);
    else if (operation == Enum.Operation.DelegateCall)
      success = executeDelegateCall(to, data);
    require(success == true, "Transaction failed");
  }

  function destroy() public {
    require(msg.sender == owner || msg.sender == address(this), "Only owner");
    assembly {
      selfdestruct(owner.slot)
    }
  }

  receive() external payable {}
}
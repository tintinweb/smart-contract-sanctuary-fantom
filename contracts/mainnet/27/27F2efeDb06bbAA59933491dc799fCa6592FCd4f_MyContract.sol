pragma solidity ^0.8.7;

contract MyContract {
  event MyEvent (
    uint indexed id,
    uint indexed date,
    string indexed value
  );
  uint nextId;

  function emitEvent(string calldata value) external {
    emit MyEvent(nextId, block.timestamp, value);
    nextId++;
  }
}
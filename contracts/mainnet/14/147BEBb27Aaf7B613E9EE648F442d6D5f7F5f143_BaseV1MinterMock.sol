pragma solidity 0.8.11;

contract BaseV1MinterMock {

    uint256 public active_period;

    constructor() {
        active_period = block.timestamp;
    }
}
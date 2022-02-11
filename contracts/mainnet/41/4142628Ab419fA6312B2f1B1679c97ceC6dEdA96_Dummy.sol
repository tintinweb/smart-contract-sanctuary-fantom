pragma solidity ^0.7.0;

contract Dummy {
    uint public dummy_entry;

    constructor() public
    {
        dummy_entry = 42;
    }

    function SetDummy(uint new_dummy) public
    {
        dummy_entry = new_dummy;
    }
}
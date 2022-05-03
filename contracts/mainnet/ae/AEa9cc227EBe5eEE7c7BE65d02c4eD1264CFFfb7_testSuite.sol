// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {
    mapping(uint256 => uint256) private assignOrders;

    function beforeAll() public {
    }
    
    function currenttimeStamp() public view returns (uint ){
        return block.timestamp;
    }

    function endtimeStamp(uint duration) public view returns (uint ){
        return block.timestamp + duration;
    }

    function blockNumber() public view returns (uint ){
        return block.number;
    }

    function initOrders() internal {
        for (uint i=0; i<10; i++) {
            assignOrders[i] = 0;
        }
    }

    uint public TicketNumber;
    function TestRandom() public {
        uint256 randIndex;
        uint256 Index;
        uint256 addIndex;
        uint256 count = 0;
        uint256 totalHolders = 10;
        TicketNumber = 0;
        initOrders();
        while (count < 10) {
            randIndex = _random(totalHolders) % (totalHolders);
            Index = _fillAssignOrder(--totalHolders, randIndex);

            if (Index > 0) {
                TicketNumber += Index * 10 ** addIndex;
                addIndex++;
            }
            count++;
        }
    }

    /**
     * @notice Get the random number in the rage of _count
     */
    function _random(uint _count) public view returns(uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(block.timestamp + block.difficulty +
                 ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / block.timestamp) 
                 + block.gaslimit 
                 + block.number)
            )
        ) / _count;
    }

    function _fillAssignOrder(uint256 orderA, uint256 orderB) public returns(uint256) {
        uint256 temp = orderA;
        if (assignOrders[orderA] > 0) temp = assignOrders[orderA];
        assignOrders[orderA] = orderB;
        if (assignOrders[orderB] > 0) assignOrders[orderA] = assignOrders[orderB];
        assignOrders[orderB] = temp;
        return assignOrders[orderA];
    }
}
/**
 *Submitted for verification at FtmScan.com on 2022-07-04
*/

// SPDX-License-Identifier: MIT
/**
A simple Solidity smart contract which generates a random number between 0 and the desired max number.
Uses two functions to generate the random number:
- First "prepareRandom" should be called. The function will set the "preparationBlockNumber" to the current block number.
- Second "roll" should be called to generate the number. The function generates a random number using current block difficulty, timestamp, caller address,
 and the blockhash of the block when "prepareRandom" has been called. This way, as the blockhash of the block can't be know before the "prepareRandom" transaction goes thorugh,
 the result of the roll can't be predicted and thus manipulated.

How many times the roll has been called and all the previous results are recorded in the blockchain.
Developed by Dogu Deniz UGUR (https://github.com/DoguD)
 */

pragma solidity ^0.8.0;

contract RandomNumberDraw {
    address public manager;
    // Result varibles
    uint256[] public winnerNumbers;
    uint256 public rollCount;
    // Random Variables
    uint256 public preparationBlockNumber;
    bool public canCallRandom;

    constructor() {
        manager = msg.sender;
    }

    function prepareRandom() public onlyOwner {
        /**
        When called sets the preparation block number to the current block number.
         */
        require(!canCallRandom, "Already prepared.");
        preparationBlockNumber = block.number;
        canCallRandom = true;
    }

    function random(uint256 maxNumber) public view returns (uint256) {
        /**
        Generates a random number between 0 and maxNumber. Uses current block difficulty, timestamp, caller address, and the blockhash of the block when prepareRandom has been called.
        Although the output of this function can be precalculated, the manager not knowing the blockhash of the block they called "prepareRandom" makes the system fair.
         */
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(preparationBlockNumber),
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % maxNumber;
    }

    function roll(uint256 maxNumber) public onlyOwner {
        require(
            canCallRandom,
            "You need to prepare the random before calling it."
        );
        canCallRandom = false;
        winnerNumbers.push(random(maxNumber));
        rollCount++;
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == manager);
        _;
    }
}
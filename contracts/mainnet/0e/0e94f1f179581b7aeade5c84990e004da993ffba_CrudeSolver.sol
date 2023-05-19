/**
 *Submitted for verification at FtmScan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISettlement {
    struct Order {
        bytes signature;
        bytes data;
        Payload payload;
    }

    struct Payload {
        SigningScheme signingScheme;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        address sender;
        address recipient;
        uint256 nonce;
        uint256 deadline;
    }

    enum SigningScheme {
        Eip712,
        Eip1271,
        EthSign
    }

    function executeOrder(Order memory order) external;
}

interface IERC20 {
    function approve(address, uint256) external;
}

contract CrudeSolver {
    ISettlement public settlement;
    address owner;

    struct SolverData {
        IERC20 tokenA;
        IERC20 tokenB;
        uint256 swapAmount;
    }

    constructor(address _settlement) {
        settlement = ISettlement(_settlement);
        owner = msg.sender;
    }

    function executeOrder(ISettlement.Order calldata order) public {
        require(owner == msg.sender);
        settlement.executeOrder(order);
    }

    // Example solver does one thing: swaps token A for token B and then allows settlement to spend the swapped tokens
    function hook(bytes memory data) external {
        require(msg.sender == address(settlement));

        // Decode data
        SolverData memory solverData = abi.decode(data, (SolverData));

        // Allow settlement to spend token B
        solverData.tokenB.approve(address(settlement), solverData.swapAmount);
    }
}
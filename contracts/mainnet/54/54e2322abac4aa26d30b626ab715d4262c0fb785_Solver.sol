/**
 *Submitted for verification at FtmScan.com on 2023-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function transfer(address, uint256) external;

    function approve(address, uint256) external;
}

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

contract Solver {
    ISettlement public settlement;
    address owner;

    struct SolverData {
        IERC20 fromToken;
        IERC20 toToken;
        uint256 fromAmount;
        uint256 toAmount;
        address recipient;
        address target;
        bytes data;
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

        // Allow target to spend input token
        solverData.fromToken.approve(solverData.target, solverData.fromAmount);

        // Perform swap
        solverData.target.call(solverData.data);

        // Allow settlement to spend token B
        solverData.toToken.transfer(solverData.recipient, solverData.toAmount);
    }
}
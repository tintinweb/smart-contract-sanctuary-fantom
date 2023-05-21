/**
 *Submitted for verification at FtmScan.com on 2023-05-21
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

    function executeOrder(Order memory) external;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function approve(address, uint256) external;
}

// Solmate SafeTransferLib modified to not care about success
library LiteTransferLib {
    function transfer(address token, address to, uint256 amount) internal {
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to)
            mstore(add(freeMemoryPointer, 36), amount)
            pop(call(gas(), token, 0, freeMemoryPointer, 68, 0, 32))
        }
    }

    function approve(address token, address to, uint256 amount) internal {
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(
                freeMemoryPointer,
                0x095ea7b300000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to)
            mstore(add(freeMemoryPointer, 36), amount)
            pop(call(gas(), token, 0, freeMemoryPointer, 68, 0, 32))
        }
    }
}

contract OrderExecutor {
    ISettlement public settlement;

    struct Data {
        IERC20 fromToken;
        IERC20 toToken;
        uint256 fromAmount;
        uint256 toAmount;
        address recipient;
        address target;
        bytes payload;
    }

    constructor(address _settlement) {
        settlement = ISettlement(_settlement);
    }

    using LiteTransferLib for IERC20;

    function executeOrder(ISettlement.Order calldata order) public {
        settlement.executeOrder(order);
        IERC20 toToken = IERC20(order.payload.toToken);
        toToken.transfer(msg.sender, toToken.balanceOf(address(this)));
    }

    function hook(bytes memory orderData) external {
        require(msg.sender == address(settlement));
        Data memory executorData = abi.decode(orderData, (Data));
        executorData.fromToken.approve(executorData.target, type(uint256).max); // Max approve to save gas --this contract should not hold tokens
        executeCall(executorData.target, 0, executorData.payload);
        executorData.toToken.transfer(
            executorData.recipient,
            executorData.toAmount
        );
    }

    // Low gas call, modified from gnosis safe
    function executeCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool success) {
        assembly {
            success := call(
                gas(),
                to,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
        }
    }
}
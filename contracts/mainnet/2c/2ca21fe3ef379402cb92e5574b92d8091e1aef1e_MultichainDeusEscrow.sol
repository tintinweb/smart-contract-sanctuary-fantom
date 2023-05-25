/**
 *Submitted for verification at FtmScan.com on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************************
 *                    Interfaces
 **************************************************/
interface IERC20 {
    function approve(address, uint256) external;
}

interface IRouter {
    function anySwapOutUnderlying(
        address token,
        address to,
        uint amount,
        uint toChainID
    ) external;
}

/**************************************************
 *               Multichain Escrow
 **************************************************/
contract MultichainDeusEscrow {
    address public owner = 0xb532E6deE59b9812bc76f409DF68507a5CbEd7ed; // Multisig
    address public operator = 0xc301b8887314530E1EA64C593125421C2190BFaf; // c30
    address public target = 0x5108C7DeB7deA5E38B4A7CdCA206aC71A33A674a; // VestingDeus on Arbitrum
    IRouter public constant router =
        IRouter(0xb576C9403f39829565BD6051695E2AC7Ecf850E2); // Multichain router
    IERC20 public constant deus =
        IERC20(0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44); // Deus
    address anyDeus = 0xf7b38053A4885c99279c4955CB843797e04455f8;
    uint256 constant arbitrumChainId = 42161; // Arbi chain id

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
    modifier onlyOperator() {
        require(msg.sender == operator, "Caller is not the operator");
        _;
    }

    constructor() {
        deus.approve(address(router), type(uint256).max);
    }

    /**************************************************
     *                    Escrow logic
     **************************************************/
    function swapOut(uint256 amount) external onlyOperator {
        router.anySwapOutUnderlying(anyDeus, target, amount, arbitrumChainId);
    }

    /**************************************************
     *                    Management
     **************************************************/
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function setTarget(address _target) external onlyOwner {
        target = _target;
    }

    /**************************************************
     *                    Execution
     **************************************************/
    enum Operation {
        Call,
        DelegateCall
    }

    /**
     * @notice Allow owner to have complete control over vesting contract
     * @param to The target address
     * @param value The amount of gas token to send with the transaction
     * @param data Raw input data
     * @param operation CALL or DELEGATECALL
     */
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external onlyOwner returns (bool success) {
        if (operation == Operation.Call) success = executeCall(to, value, data);
        else if (operation == Operation.DelegateCall)
            success = executeDelegateCall(to, data);
        require(success == true, "Transaction failed");
    }

    /**
     * @notice Execute an arbitrary call from the context of this contract
     * @param to The target address
     * @param value The amount of gas token to send with the transaction
     * @param data Raw input data
     */
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
            default {
                return(0, returnDataSize)
            }
        }
    }

    /**
     * @notice Execute a delegateCall from the context of this contract
     * @param to The target address
     * @param data Raw input data
     */
    function executeDelegateCall(
        address to,
        bytes memory data
    ) internal returns (bool success) {
        assembly {
            success := delegatecall(
                gas(),
                to,
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
            default {
                return(0, returnDataSize)
            }
        }
    }
}
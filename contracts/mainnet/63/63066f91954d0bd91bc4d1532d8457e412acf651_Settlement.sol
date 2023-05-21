/**
 *Submitted for verification at FtmScan.com on 2023-05-21
*/

// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.19;

/*******************************************************
 *                       Interfaces
 *******************************************************/
interface ISettlement {
    struct Order {
        bytes signature;
        bytes data;
        address solver;
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

interface EIP1271Verifier {
    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external view returns (bytes4 magicValue);
}

interface ISolver {
    function hook(bytes calldata data) external;
}


interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function approve(address, uint256) external;

    function transferFrom(address from, address to, uint256 amount) external;
}

/*******************************************************
 *                     Solmate Library
 *******************************************************/
library SafeTransferLib {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), from)
            mstore(add(freeMemoryPointer, 36), to)
            mstore(add(freeMemoryPointer, 68), amount)
            success := and(
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }
        require(success, "TRANSFER_FROM_FAILED");
    }
}

contract Settlement {
    /*******************************************************
     *                      Constants
     *******************************************************/
    bytes32 private constant _DOMAIN_NAME = keccak256("Blockswap");
    bytes32 private constant _DOMAIN_VERSION = keccak256("v0.0.1");
    bytes32 private constant _DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant TYPE_HASH =
        keccak256(
            "Swap(uint8 signingScheme,address fromToken,address toToken,uint256 fromAmount,uint256 toAmount,address sender,address recipient,uint256 nonce,uint256 deadline)"
        );
    uint256 private constant _ECDSA_SIGNATURE_LENGTH = 65;
    bytes4 private constant _EIP1271_MAGICVALUE = 0x1626ba7e;
    bytes32 public immutable domainSeparator;

    /*******************************************************
     *                       Storage
     *******************************************************/
    mapping(address => uint256) public nonces;

    /*******************************************************
     *                     Initialization
     *******************************************************/
    constructor() {
        domainSeparator = keccak256(
            abi.encode(
                _DOMAIN_TYPE_HASH,
                _DOMAIN_NAME,
                _DOMAIN_VERSION,
                block.chainid,
                address(this)
            )
        );
    }

    using SafeTransferLib for IERC20;

    /*******************************************************
     *                   Settlement Logic
     *******************************************************/
    function _verify(ISettlement.Order calldata order) internal {
        bytes32 digest = _buildDigest(order.payload);
        address signatory = recoverSigner(
            order.payload.signingScheme,
            order.signature,
            digest
        );
        require(signatory == order.payload.sender, "Invalid signer");
        require(block.timestamp <= order.payload.deadline, "Deadline expired");
        require(
            order.payload.nonce == nonces[signatory]++,
            "Nonce already used"
        );
    }

    event OrderExecuted(
        address solver,
        address sender,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount
    );

    function executeOrder(ISettlement.Order calldata order) public {
        ISettlement.Payload memory payload = order.payload;
        _verify(order);
        IERC20(payload.fromToken).safeTransferFrom(
            payload.sender,
            msg.sender,
            payload.fromAmount
        );
        uint256 outputTokenBalanceBefore = IERC20(payload.toToken).balanceOf(
            payload.recipient
        );
        ISolver(msg.sender).hook(order.data);
        uint256 outputTokenBalanceAfter = IERC20(payload.toToken).balanceOf(
            payload.recipient
        );
        require(
            outputTokenBalanceAfter - outputTokenBalanceBefore >=
                payload.toAmount,
            "Order not filled"
        );
        emit OrderExecuted(
            tx.origin,
            payload.sender,
            payload.fromToken,
            payload.toToken,
            payload.fromAmount,
            payload.toAmount
        );
    }

    /*******************************************************
     *                   Signature Logic
     *******************************************************/
    function recoverSigner(
        ISettlement.SigningScheme signingScheme,
        bytes calldata signature,
        bytes32 digest
    ) public view returns (address owner) {
        if (signingScheme == ISettlement.SigningScheme.Eip712) {
            owner = _recoverEip712Signer(digest, signature);
        } else if (signingScheme == ISettlement.SigningScheme.Eip1271) {
            owner = _recoverEip1271Signer(digest, signature);
        } else {
            // signingScheme == Scheme.EthSign
            owner = _recoverEthsignSigner(digest, signature);
        }
    }

    function _recoverEip712Signer(
        bytes32 orderDigest,
        bytes calldata encodedSignature
    ) internal pure returns (address owner) {
        owner = _ecdsaRecover(orderDigest, encodedSignature);
    }

    function _recoverEip1271Signer(
        bytes32 orderDigest,
        bytes calldata encodedSignature
    ) internal view returns (address owner) {
        assembly {
            owner := shr(96, calldataload(encodedSignature.offset))
        }
        bytes calldata signature = encodedSignature[20:];

        require(
            EIP1271Verifier(owner).isValidSignature(orderDigest, signature) ==
                _EIP1271_MAGICVALUE,
            "Invalid EIP-1271 signature"
        );
    }

    function _recoverEthsignSigner(
        bytes32 orderDigest,
        bytes calldata encodedSignature
    ) internal pure returns (address owner) {
        bytes32 ethsignDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", orderDigest)
        );
        owner = _ecdsaRecover(ethsignDigest, encodedSignature);
    }

    function _ecdsaRecover(
        bytes32 message,
        bytes calldata encodedSignature
    ) internal pure returns (address signer) {
        require(
            encodedSignature.length == _ECDSA_SIGNATURE_LENGTH,
            "Malformed ECDSA signature"
        );
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := calldataload(encodedSignature.offset)
            s := calldataload(add(encodedSignature.offset, 32))
            v := shr(248, calldataload(add(encodedSignature.offset, 64)))
        }
        signer = ecrecover(message, v, r, s);
        require(signer != address(0), "Invalid ECDSA signature");
    }

    function _buildDigest(
        ISettlement.Payload memory payload
    ) internal view returns (bytes32 orderDigest) {
        bytes32 typeHash = TYPE_HASH;
        bytes32 structHash;
        bytes32 _domainSeparator = domainSeparator;
        uint256 structLength = bytes(abi.encode(payload)).length;
        assembly {
            let dataStart := sub(payload, 32)
            let temp := mload(dataStart)
            mstore(dataStart, typeHash)
            structHash := keccak256(dataStart, add(structLength, 0x20))
            mstore(dataStart, temp)
        }
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, "\x19\x01")
            mstore(add(freeMemoryPointer, 2), _domainSeparator)
            mstore(add(freeMemoryPointer, 34), structHash)
            orderDigest := keccak256(freeMemoryPointer, 66)
        }
    }
}
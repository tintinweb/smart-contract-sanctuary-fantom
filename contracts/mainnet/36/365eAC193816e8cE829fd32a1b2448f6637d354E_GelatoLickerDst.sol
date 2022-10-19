// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

interface IIceCreamNFT {
    function lick(uint256 _tokenId) external;
}

contract GelatoLickerDst is ILayerZeroReceiver {
    address public constant lzEndpoint =
        address(0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7); // fantom lz endpoint
    IIceCreamNFT public constant iceCreamNFT =
        IIceCreamNFT(0x255F82563b5973264e89526345EcEa766DB3baB2); // fantom IceCreamNFT address
    address public constant srcLicker =
        address(0x52677d053fE817C40556ed1f4178aAC360619115); // avalanche gelato licker address

    event CCLicked(
        uint16 srcChainId,
        address srcAddress,
        uint256 indexed tokenId,
        uint256 timestamp
    );

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64,
        bytes memory lickPayload
    ) external override {
        require(
            msg.sender == address(lzEndpoint),
            "CrossChainGelatoLicker: Only endpoint"
        );
        address srcAddress;
        assembly {
            srcAddress := mload(add(_srcAddress, 20))
        }
        require(
            srcAddress == srcLicker,
            "CrossChainGelatoLicker: Only srcLicker"
        );

        uint256 tokenId = abi.decode(lickPayload, (uint256));

        iceCreamNFT.lick(tokenId);

        emit CCLicked(_srcChainId, srcAddress, tokenId, block.timestamp);
    }
}
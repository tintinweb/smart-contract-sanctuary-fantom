/**
 *Submitted for verification at FtmScan.com on 2022-06-27
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract ClaimAssets {
    address public immutable server;

    mapping(uint256 => bool) public performed;

    event Claimed(uint256 indexed nonce, address sender, address calledAddress);

    constructor(address _addr) {
        server = _addr;
    }

    function claim(
        uint256 _nonce,
        bytes memory _functionCall,
        bytes memory _sig,
        address _to
    ) public returns (bool) {
        require(!performed[_nonce], "Had Been Performed");

        bytes32 messageHash = getFunctionCallHash(_nonce, _functionCall, _to);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        require(
            recover(ethSignedMessageHash, _sig) == server,
            "Illegal signer"
        );

        performed[_nonce] = true;
        (bool success, ) = _to.call(_functionCall);
        require(success, "Failed call function");

        emit Claimed(_nonce, msg.sender, _to);

        return success;
    }

    function getFunctionCallHash(
        uint256 _nonce,
        bytes memory _functionCall,
        address _to
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_nonce, _functionCall, _to));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recover(bytes32 _ethSignedMessageHash, bytes memory _sig)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _split(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }
}
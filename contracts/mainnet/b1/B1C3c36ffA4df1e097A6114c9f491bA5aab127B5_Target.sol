/**
 *Submitted for verification at FtmScan.com on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IAnyCall {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;

    function context()
        external
        view
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );

    function executor() external view returns (address executor);
}

// FTM
contract Target {
    IAnyCall public endpoint = IAnyCall(0xC10Ef9F491C9B59f936957026020C321651ac078);
    uint256 public sourceChainID = 250;
    address public sourceChainAddr;
    address public owner;

    event FromSource(string msg);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");

        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setEndpoint(address _endpoint) external onlyOwner {
        endpoint = IAnyCall(_endpoint);
    }

    function setSourceChainAddr(address _sourceChainAddr) external onlyOwner {
        sourceChainAddr = _sourceChainAddr;
    }

    function send(string memory _msg) external onlyOwner  {
        bytes memory data = abi.encode(_msg);
        endpoint.anyCall(sourceChainAddr, data, address(0), sourceChainID, 0);
    }

    function anyExecute(bytes memory _data) external returns (bool success, bytes memory result) {
        (string memory _msg) = abi.decode(_data, (string));

        emit FromSource(_msg);

        return (true, "");
    }
}
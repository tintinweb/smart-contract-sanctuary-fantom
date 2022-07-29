/**
 *Submitted for verification at FtmScan.com on 2022-07-29
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAnycallExecutor {
    function context() external returns (address from, uint256 fromChainID, uint256 nonce);
}


interface CallProxy{
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags

    ) external;

    function executor() external view returns (address);
}

  

contract AnycallFallback{

    // The Multichain anycall contract on bnb mainnet
    address private anycallcontract=0xC10Ef9F491C9B59f936957026020C321651ac078;

    
    address private owneraddress=0xfa7e030d2ac001c2bA147c0b147D468E4609f7CC;

    // Destination contract on Polygon
    address private peeraddress;

    uint private destchainid;
    
    modifier onlyowner() {
        require(msg.sender == owneraddress, "only owner can call this method");
        _;
    }

    event NewMsg(string msg);
    
    constructor (address _peeraddress,uint _destchainid){
        peeraddress=_peeraddress;
        destchainid=_destchainid;
    }

    function changereceivercontract(address newreceiver) external onlyowner {
        peeraddress=newreceiver;

    }


    function step1_initiateAnyCallSimple(string calldata _msg) external {
        emit NewMsg(_msg);

        bytes memory data = abi.encodeWithSelector(
            this.anyExecute.selector,
            _msg
        );


        if (msg.sender == owneraddress){
        CallProxy(anycallcontract).anyCall(
            peeraddress,

            // sending the encoded bytes of the string msg and decode on the destination chain
            data,

            // 0x as fallback address because we don't have a fallback function
            address(this),

            // chainid of polygon
            destchainid,

            // Using 0 flag to pay fee on destination chain
            0
            );
            
        }

    }

    function compareStrings(string memory a, string memory b) public view returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
}

    function anyExecute(bytes calldata data)
        external
        
        returns (bool success, bytes memory result)
    {
        bytes4 selector = bytes4(data[:4]);
        if (selector == this.anyExecute.selector) {
            (
                string memory message
            ) = abi.decode(
                data[4:],
                (string)
            );

            if (compareStrings(message,"fail")){
                return (false, "fail on purpose");
            }

            emit NewMsg(message);
        } else if (selector == this.anyFallback.selector) {

            // original data with selector would be passed here if thats the case
            (address _to, bytes memory _data) = abi.decode(data[4:], (address, bytes));
            this.anyFallback(_to, _data);
        } else {
            return (false, "unknown selector");
        }
        return (true, "");
    }

    event Fallbackmsg(string msg);

    function anyFallback(address to, bytes calldata data) external {
        require(msg.sender == address(this), "AnycallClient: Must call from within this contract");
        require(bytes4(data[:4]) == this.anyExecute.selector, "AnycallClient: wrong fallback data");

        address executor = CallProxy(anycallcontract).executor();
        (address _from,,) = IAnycallExecutor(executor).context();
        require(_from == address(this), "AnycallClient: wrong context");

        (
            string memory message
        ) = abi.decode(
            data[4:],
            (string)
        );

        require(peeraddress == to, "AnycallClient: mismatch dest client");

        emit Fallbackmsg(message);
    }

}
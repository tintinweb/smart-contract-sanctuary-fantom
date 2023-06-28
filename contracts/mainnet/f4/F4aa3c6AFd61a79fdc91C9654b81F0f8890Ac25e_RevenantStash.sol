// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./RevenantStashStorage.sol";
import "./IRevenantStash.sol";
import "./opengsn/BaseRelayRecipient.sol";
import './RevenantStashStructs.sol';


contract RevenantStash is RevenantStashStorage,IRevenantStash,BaseRelayRecipient {

    string public constant override versionRecipient = "2.2.0";

    constructor(address _relayer,address _forwarder) {
        if (_relayer == address(0)) revert RelayerCannotBeZero();
        relayer = _relayer;
        owner = msg.sender;
        _setTrustedForwarder(_forwarder);
    }
    function sendFile(address recipient, string memory cid,string memory name) override public {
        address sender = _msgSender();
        if (recipient == address(0)) revert RecipientCannotBeZero();
        if (bytes(cid).length <= 0) revert CIDCannotBeEmpty();
        stash[recipient].push(Stash(sender, cid, name));
        emit FileReceived(recipient, cid);
    }
    function deleteFile(uint index) override public {
        address sender = _msgSender();
        require(index < stash[sender].length, "Index out of bounds");
        stash[sender][index] = stash[sender][stash[sender].length - 1];
        stash[sender].pop();
        emit FileDeleted(index,sender);
    }
    function numberOfFiles(address recipient) override external view returns(uint256){
        return stash[recipient].length;
    }

    function changeRelayer(address newRelayer) override  public onlyOwner {
        if (newRelayer == address(0)) revert RelayerCannotBeZero();
        relayer = newRelayer;
        emit RelayerChanged(newRelayer);
    }
    function getFiles(address recipient) override public view returns (Stash[] memory) {
        return stash[recipient];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Stash {
    address relayedBy;
    string cid;
    string name;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './RevenantStashStructs.sol';

contract RevenantStashStorage{
    mapping (address => Stash[]) public stash;
    address public relayer;
    address public owner;

    event FileReceived(address indexed recipient, string cid);
    event RelayerChanged(address indexed newRelayer);
    event FileDeleted(uint index,address indexed deleter);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
    modifier onlyRelayer() {
        require(msg.sender == relayer, "Caller is not the relayer");
        _;
    }

    error RelayerCannotBeZero();
    error RecipientCannotBeZero();
    error CIDCannotBeEmpty();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import './RevenantStashStructs.sol';


interface IRevenantStash{
    function sendFile(address recipient, string memory cid,string memory name) external;
    function changeRelayer(address newRelayer) external;
    function getFiles(address recipient) external view returns (Stash[] memory);
    function deleteFile(uint index) external;
    function numberOfFiles(address recipient)external returns(uint256);
}
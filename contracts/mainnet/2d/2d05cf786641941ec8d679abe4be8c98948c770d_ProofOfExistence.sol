/**
 *Submitted for verification at FtmScan.com on 2022-06-01
*/

pragma solidity >= 0.8.13;

contract ProofOfExistence {

    string public term;
    string public description;
    address public uploadedBy;

    constructor(string memory _term, string memory _description) {
        term = _term;
        description = _description;
        uploadedBy = msg.sender;
    }
    
}
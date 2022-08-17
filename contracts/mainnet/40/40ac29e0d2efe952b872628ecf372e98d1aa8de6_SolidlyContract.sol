/**
 *Submitted for verification at FtmScan.com on 2022-08-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

contract SolidlyContract {
    address public constant c30Address = 0xc301B6139055ae5b6704E3bbc5766ba59f1758C0;
    address public constant beepidibopAddress = 0xc301B6139055ae5b6704E3bbc5766ba59f1758C0;
    address public constant rooshAddress = 0xc301B6139055ae5b6704E3bbc5766ba59f1758C0;
    address public constant lafaAddress = 0xc301B6139055ae5b6704E3bbc5766ba59f1758C0;
    bool public c30Signed;
    bool public beepidibopSigned;
    bool public rooshSigned;
    bool public lafaSigned;
    bool public contractIsValid;
    uint256 public contractValidDate;

    string constant public agreement = "dGVzdCBhZ3JlZW1lbnQ=";
    string constant declaration = "I hereby declare to have fully read and understood the contractual obligations set forth in the encrypted text embedded within this smart-contract and will fulfill them to the best of my knowledge and abilities. I hereby also declare that by my willfully setting the boolean to value <true> within the function <signature_lafa>, I have legally signed this contract. I hereby declare to have the sole custody and ownership of the private key used to sign this message. I understand this entire statement can be used as evidence in court.";

    function signContract(string memory _declaration) public {
        require (keccak256(bytes(_declaration)) == keccak256(bytes(declaration)));

        if (msg.sender == c30Address) {
            c30Signed = true;
        }
        if (msg.sender == beepidibopAddress) {
            beepidibopSigned = true;
        }
        if (msg.sender == rooshAddress) {
            rooshSigned = true;
        }
        if (msg.sender == lafaAddress) {
            lafaSigned = true;
        }
        if (c30Signed && beepidibopSigned && rooshSigned && lafaSigned) {
            if (!contractIsValid) {
                contractIsValid = true;
                contractValidDate = block.timestamp;
            }
        }
    }
}
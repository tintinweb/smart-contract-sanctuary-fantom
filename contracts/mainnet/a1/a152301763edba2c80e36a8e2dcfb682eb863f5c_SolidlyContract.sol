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

    function signContract() public {
        if (msg.sender == c30Address) {
            c30Signed = true;
        } else if (msg.sender == beepidibopAddress) {
            beepidibopSigned = true;
        } else if (msg.sender == rooshAddress) {
            rooshSigned = true;
        } else if (msg.sender == lafaAddress) {
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
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "../utils/SpookyAuth.sol";

contract MagicatName is SpookyAuth {
    mapping (uint => string) public nameOf;

    bool maySet = true;

    function setNames(string[] memory names, uint256 offset) public onlyAdmin {
        require(maySet);
        uint len = names.length;
        for(uint i = 0; i < len;) {
            nameOf[i + offset] = names[i];
            unchecked {++i;}
        }

    }

    function relinquishSet() public onlyAdmin {
        maySet = false;
    }

    function nameOfBatch(uint[] memory tokenIDs) public view returns (string[] memory names) {
        uint len = tokenIDs.length;
        names = new string[](len);
        for(uint i = 0; i < len; i++)
            names[i] = nameOf[tokenIDs[i]];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

abstract contract SpookyAuth {
    // set of addresses that can perform certain functions
    mapping(address => bool) public isAuth;
    address[] public authorized;
    address public admin;

    modifier onlyAuth() {
        require(isAuth[msg.sender] || msg.sender == admin, "SpookySwap: FORBIDDEN (auth)");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "SpookySwap: FORBIDDEN (admin)");
        _;
    }

    event AddAuth(address indexed by, address indexed to);
    event RevokeAuth(address indexed by, address indexed to);
    event SetAdmin(address indexed by, address indexed to);

    constructor() {
        admin = msg.sender;
        emit SetAdmin(address(this), msg.sender);
        isAuth[msg.sender] = true;
        authorized.push(msg.sender);
        emit AddAuth(address(this), msg.sender);
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
        emit SetAdmin(msg.sender, newAdmin);
    }

    function addAuth(address _auth) external onlyAuth {
        isAuth[_auth] = true;
        authorized.push(_auth);
        emit AddAuth(msg.sender, _auth);
    }

    function revokeAuth(address _auth) external onlyAuth {
        require(_auth != admin);
        isAuth[_auth] = false;
        emit RevokeAuth(msg.sender, _auth);
    }
}
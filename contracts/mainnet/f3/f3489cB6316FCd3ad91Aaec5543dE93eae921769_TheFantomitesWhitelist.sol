//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TheFantomitesWhitelist {
    mapping(address => bool) public Administrators;
    mapping(address => bool) public Whitelisted;

    constructor() {
        Administrators[msg.sender] = true;
    }

    modifier onlyAdministrators() {
        require(Administrators[msg.sender] == true);
        _;
    }

    function administratorToggle(address who) public onlyAdministrators {
        Administrators[who] = Administrators[who] ? false : true;
    }

    function administratorToggle(address[] memory addresses)
        public
        onlyAdministrators
    {
        for (uint256 i; i < addresses.length; i++) {
            address who = addresses[i];
            Administrators[who] = Administrators[who] ? false : true;
        }
    }

    function whitelistToggle(address who) public onlyAdministrators {
        Whitelisted[who] = Whitelisted[who] ? false : true;
    }

    function whitelistToggle(address[] memory addresses)
        public
        onlyAdministrators
    {
        for (uint256 i; i < addresses.length; i++) {
            address who = addresses[i];
            Whitelisted[who] = Whitelisted[who] ? false : true;
        }
    }

    function isWhitelisted(address who) public view returns (bool) {
        return Whitelisted[who];
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Vayua Request For Comments #1 (VRC1)
contract VRC1 {
    struct Profile {
        string name;
        string bio;
        string avatar;
        string location;
        string website;
    }

    mapping(address => Profile) public profiles;
    mapping(address => string) public profileExtensions;

    event ProfileChanged(address profileOwner, Profile profile);
    event ProfileExtensionChanged(address profileOwner, string extension);

    function setProfile(Profile calldata _profile) external {
        profiles[msg.sender] = _profile;
        emit ProfileChanged(msg.sender, _profile);
    }

    function setProfileExtension(string calldata _extension) external {
        profileExtensions[msg.sender] = _extension;
        emit ProfileExtensionChanged(msg.sender, _extension);
    }
}
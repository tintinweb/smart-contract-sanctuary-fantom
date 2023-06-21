/**
 *Submitted for verification at FtmScan.com on 2023-06-21
*/

// SPDX-License-Identifier: MIT
// JEFE-VAULT RANGER VAULT
// JEFE: 0xdBeA55Bad7404F00DF5cd12d30d2086151E83950
// TIMELOCK: 30 DAYS -  2,628,288 seconds
// TOKENADDRESS: 0xd7F1dd1b6edbAfd9A2Bd7Fc3CAF39a13b8307375 - JEFE TOKEN LP SPOOKYSWAP
// NFTADDRESS: 0x51ef67062de01dca4a12e3e58dfcecff20f87551 - JEFE ZOMBIE NFT LP KEY
// JEFETOKEN.COM


pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
}

contract JEFEVAULTS {
    address private _tokenAddress;
    address private _beneficiary;
    uint256 private _lockDuration;
    uint256 private _lockTimestamp;
    bool private _tokensLocked;
    address private _nftContractAddress;
    uint256 private _nftTokenId;

    constructor(address tokenAddress, address beneficiary, uint256 lockDuration, address nftContractAddress, uint256 nftTokenId) {
        _tokenAddress = tokenAddress;
        _beneficiary = beneficiary;
        _lockDuration = lockDuration;
        _lockTimestamp = block.timestamp;
        _tokensLocked = true;
        _nftContractAddress = nftContractAddress;
        _nftTokenId = nftTokenId;
    }

    function isLockExpired() public view returns (bool) {
        return block.timestamp >= _lockTimestamp + _lockDuration;
    }

    function releaseTokens() public {
        require(_tokensLocked, "Tokens have already been released.");

        require(
            IERC1155(_nftContractAddress).balanceOf(msg.sender, _nftTokenId) > 0,
            "Beneficiary does not hold the required ERC1155 NFT token."
        );

        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to release.");

        _tokensLocked = false;
        token.transfer(_beneficiary, balance);
    }

    function withdrawTokens() public {
        require(_tokensLocked, "Tokens have already been released.");
        require(isLockExpired(), "Lock duration has not expired yet.");

        require(
            IERC1155(_nftContractAddress).balanceOf(msg.sender, _nftTokenId) > 0,
            "Beneficiary does not hold the required ERC1155 NFT token."
        );

        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw.");

        _tokensLocked = false;
        token.transfer(_beneficiary, balance);
    }

    function getLockDetails() public view returns (address, uint256, bool, address, uint256) {
        return (_nftContractAddress, _nftTokenId, _tokensLocked, _beneficiary, _lockTimestamp + _lockDuration);
    }
}
/**
 *Submitted for verification at FtmScan.com on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IMigrationBurn {
    function veNftBurnedIndexById(address, uint256)
        external
        view
        returns (uint256);

    function veNftBurnedIdByIndex(address, uint256)
        external
        view
        returns (uint256);

    function tokensBurnedByAccount(address, address)
        external
        view
        returns (uint256);
}

/**************************************************
 *                 Burn Delegator
 **************************************************/

/**
 * @title Burn delegator
 * @dev How it works:
 *      - Anyone who has burned veNFT or ERC20 tokens can delegate their burn ONE TIME
 *      - After delegating, a log will be emitted
 *      - The claim contract on ethereum mainnet will utilize merkle proofs and block header hashes to verify fantom log inclusion on mainnet
 *         - See: https://github.com/maticnetwork/pos-portal/blob/master/flat/RootChainManager.sol#L2239
 */

contract BurnDelegator {
    /**************************************************
     *                 Initialization
     **************************************************/
    IMigrationBurn constant migrationBurn =
        IMigrationBurn(0x12e569CE813d28720894c2A0FFe6bEC3CCD959b2);
    mapping(uint256 => address) public veNftBeneficiaries; // tokenId -> beneficiary
    mapping(address => mapping(address => address)) public erc20Beneficiaries; // originalOwner -> token -> beneficiary

    event SetVeNftBeneficiary(
        address from,
        address beneficiary,
        uint256 tokenId
    );

    event SetErc20Beneficiary(
        address from,
        address beneficiary,
        address tokenAddress
    );

    /**************************************************
     *               Beneficiary updating
     **************************************************/

    /**
     * @notice Update the beneficiary for an NFT
     * @dev This can only be called once
     */
    function delegateVeNftBurn(address beneficiary, uint256 tokenId) external {
        require(accountBurnedVeNft(msg.sender, tokenId), "Only owner");
        require(msg.sender != beneficiary, "Cannot delegate to self");
        require(
            veNftBeneficiaries[tokenId] == address(0),
            "Can only delegate once"
        );
        veNftBeneficiaries[tokenId] = beneficiary;
        emit SetVeNftBeneficiary(msg.sender, beneficiary, tokenId);
    }

    /**
     * @notice Update the beneficiary for a token
     * @dev This can only be called once
     */
    function delegateErc20Burn(address beneficiary, address tokenAddress)
        external
    {
        require(accountBurnedErc20(msg.sender, tokenAddress), "Only owner");
        require(msg.sender != beneficiary, "Cannot delegate to self");
        require(
            erc20Beneficiaries[msg.sender][tokenAddress] == address(0),
            "Can only delegate once"
        );
        erc20Beneficiaries[msg.sender][tokenAddress] = beneficiary;
        emit SetErc20Beneficiary(msg.sender, beneficiary, tokenAddress);
    }

    /**************************************************
     *                 View methods
     **************************************************/

    /**
     * @notice Determine whether or not an account is owner of NFT
     * @param account Address of owner
     * @param tokenId ID of the token
     */
    function accountBurnedVeNft(address account, uint256 tokenId)
        public
        view
        returns (bool)
    {
        uint256 index = migrationBurn.veNftBurnedIndexById(account, tokenId);
        bool accountIsBurnOwner = migrationBurn.veNftBurnedIdByIndex(
            account,
            index
        ) == tokenId;
        if (accountIsBurnOwner) {
            return true;
        }
        return false;
    }

    /**
     * @notice Determine whether or not an account has burned a specific ERC20 token
     * @param tokenAddress Address of token to check
     * @param account Address of owner
     */
    function accountBurnedErc20(address account, address tokenAddress)
        public
        view
        returns (bool)
    {
        return migrationBurn.tokensBurnedByAccount(tokenAddress, account) > 0;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./IVoter.sol";
import "./GovernableImplementation.sol";
import "./ProxyImplementation.sol";

/**
 * @author 0xDAO
 * @title Token allowlist
 * @dev The purpose of this contract is to prevent griefing attacks on Solidly bribe tokens
 * @dev Supports utilizing Solidly's built-in whitelist
 * @dev Adds the ability to add new tokens that aren't in Solidly's whitelist
 * @dev Adds the ability to disable Solidly's whitelist both globally and per-token
 */
contract TokensAllowlist is GovernableImplementation, ProxyImplementation {
    /*******************************************************
     *                     Configuration
     *******************************************************/

    // Public addresses
    address public voterAddress;

    // Token mapping
    mapping(address => bool) tokenAllowed;
    mapping(address => bool) solidlyTokenCheckDisabled;

    // Configuration
    bool public solidlyAllowlistEnabled;
    uint256 public bribeTokensSyncPageSize;
    uint256 public bribeTokensNotifyPageSize;
    uint256 public bribeNotifyFrequency;
    uint256 public feeNotifyFrequency;
    mapping(address => bool) public feeClaimingDisabled;
    uint256 public bribeSyncLagLimit;
    uint256 public periodBetweenClaimSolid;
    uint256 public periodBetweenClaimFee;
    uint256 public periodBetweenClaimBribe;

    // Internal helpers
    IVoter voter;

    /**
     * @notice Initialize proxy storage
     */
    function initializeProxyStorage(address _voterAddress)
        public
        checkProxyInitialized
    {
        voterAddress = _voterAddress;
        voter = IVoter(voterAddress);
        solidlyAllowlistEnabled = true;
        bribeTokensSyncPageSize = 1;
        bribeTokensNotifyPageSize = 1;
        bribeNotifyFrequency = 5;
        feeNotifyFrequency = 1;
        bribeSyncLagLimit = 5;
        periodBetweenClaimSolid = 86400 * 7;
        periodBetweenClaimFee = 86400 * 1;
        periodBetweenClaimBribe = 86400 * 1;
    }

    /*******************************************************
     *                     View methods
     *******************************************************/

    /**
     * @notice Determine whether or not a token is allowed
     * @param tokenAddress Address of the token to check
     */
    function tokenIsAllowed(address tokenAddress) external view returns (bool) {
        if (
            solidlyAllowlistEnabled && !solidlyTokenCheckDisabled[tokenAddress]
        ) {
            bool tokenWhitelistedInSolidly = voter.isWhitelisted(tokenAddress);
            if (tokenWhitelistedInSolidly) {
                return true;
            }
        }
        return tokenAllowed[tokenAddress];
    }

    /**
     * @notice Return relative frequency between notifying bribes and fees
     * @param bribeFrequency frequency weight for notifying bribes
     * @param feeFrequency frequency weight for notifying fees
     */
    function notifyFrequency()
        external
        view
        returns (uint256 bribeFrequency, uint256 feeFrequency)
    {
        bribeFrequency = bribeNotifyFrequency;
        feeFrequency = feeNotifyFrequency;
    }

    /*******************************************************
     *                       Settings
     *******************************************************/

    /**
     * @notice Set internal allowed state for a token
     * @param tokenAddress Address of the token
     * @param allowed If true token is allowed, if false the token is not allowed (unless it's allowed on Solidly and Solidly allowlist is enabled)
     */
    function setTokenAllowed(address tokenAddress, bool allowed)
        public
        onlyGovernance
    {
        tokenAllowed[tokenAddress] = allowed;
    }

    /**
     * @notice Batch set token allowlist states
     * @param tokensAddresses A list of token addresses
     * @param allowed True if allowed, false if not
     */
    function setTokensAllowed(address[] memory tokensAddresses, bool allowed)
        external
        onlyGovernance
    {
        for (
            uint256 tokenIndex;
            tokenIndex < tokensAddresses.length;
            tokenIndex++
        ) {
            setTokenAllowed(tokensAddresses[tokenIndex], allowed);
        }
    }

    /**
     * @notice Disable Solidly token whitelist mapping for a specific token
     * @param tokenAddress Address of the token
     * @param disabled If true, don't check the Solidly allowlist for this token. If false, do check Solidly for this token
     */
    function setSolidlyTokenCheckDisabled(address tokenAddress, bool disabled)
        public
        onlyGovernance
    {
        solidlyTokenCheckDisabled[tokenAddress] = disabled;
    }

    /**
     * @notice Batch set Solidly token check overrides
     * @param tokensAddresses A list of token addresses
     * @param disabledList A list of disabled states
     */
    function setSolidlyTokensCheckDisabled(
        address[] memory tokensAddresses,
        bool[] memory disabledList
    ) external onlyGovernance {
        assert(tokensAddresses.length == disabledList.length);
        for (
            uint256 tokenIndex;
            tokenIndex < tokensAddresses.length;
            tokenIndex++
        ) {
            setSolidlyTokenCheckDisabled(
                tokensAddresses[tokenIndex],
                disabledList[tokenIndex]
            );
        }
    }

    /**
     * @notice Set relative frequency between notifying bribes and fees
     * @param bribeFrequency frequency weight for notifying bribes
     * @param feeFrequency frequency weight for notifying fees
     */
    function setNotifyRelativeFrequency(
        uint256 bribeFrequency,
        uint256 feeFrequency
    ) public onlyGovernance {
        bribeNotifyFrequency = bribeFrequency;
        feeNotifyFrequency = feeFrequency;
    }

    /**
     * @notice Enable or disable using Solidly as a source of truth for allowed tokens
     * @param enabled If True use Solidly as a source for allowlist, if false, don't use Solidly as a source
     */
    function setSolidlyAllowlistEnabled(bool enabled) external onlyGovernance {
        solidlyAllowlistEnabled = enabled;
    }

    /**
     * @notice Set page size to be used by oxPool sync mechanism
     * @param _bribeTokensSyncPageSize The number of tokens to sync per transaction
     */
    function setBribeTokensSyncPageSize(uint256 _bribeTokensSyncPageSize)
        external
        onlyGovernance
    {
        bribeTokensSyncPageSize = _bribeTokensSyncPageSize;
    }

    /**
     * @notice Set page size to be used by oxPool bribe notify mechanism
     * @param _bribeTokensNotifyPageSize The number of tokens to notify per transaction
     */
    function setBribeTokensNotifyPageSize(uint256 _bribeTokensNotifyPageSize)
        external
        onlyGovernance
    {
        bribeTokensNotifyPageSize = _bribeTokensNotifyPageSize;
    }

    /**
     * @notice Set whether an individual pool's fee claiming is disabled
     * @param oxPoolAddress The affected oxPool address
     * @param disabled disables fee claiming
     */
    function setFeeClaimingDisabled(address oxPoolAddress, bool disabled)
        external
        onlyGovernance
    {
        feeClaimingDisabled[oxPoolAddress] = disabled;
    }

    /**
     * @notice Set lag size to be used by oxPool bribe notify mechanism
     * @param _bribeSyncLagLimit The number of votes to sync per transaction
     */
    function setBribeSyncLagSize(uint256 _bribeSyncLagLimit)
        external
        onlyGovernance
    {
        bribeSyncLagLimit = _bribeSyncLagLimit;
    }

    /**
     * @notice Set time period between calls to voterProxy.claimSolid() in seconds
     * @param _periodBetweenClaimSolid time period between calls to voterProxy.claimSolid() in seconds
     */
    function setPeriodBetweenClaimSolid(uint256 _periodBetweenClaimSolid)
        external
        onlyGovernance
    {
        periodBetweenClaimSolid = _periodBetweenClaimSolid;
    }

    /**
     * @notice Set cooldown period for oxPool to claim fees
     * @param _periodBetweenClaimFee cooldown period for oxPool to claim fees
     */
    function setPeriodBetweenClaimFee(uint256 _periodBetweenClaimFee)
        external
        onlyGovernance
    {
        periodBetweenClaimFee = _periodBetweenClaimFee;
    }

    /**
     * @notice Set cooldown period for oxPool to claim bribes
     * @param _periodBetweenClaimBribe cooldown period for oxPool to claim bribes
     */
    function setPeriodBetweenClaimBribe(uint256 _periodBetweenClaimBribe)
        external
        onlyGovernance
    {
        periodBetweenClaimBribe = _periodBetweenClaimBribe;
    }
}
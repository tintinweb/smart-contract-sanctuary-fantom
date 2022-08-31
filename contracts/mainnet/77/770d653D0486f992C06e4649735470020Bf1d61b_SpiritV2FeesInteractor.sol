pragma solidity ^0.7.6;

interface IGaugeProxyForFeesInteractor {
    function getGauge(address _token) external view returns (address);
    function getBribes(address _gauge) external view returns (address);

    function claimBribes(address[] memory _bribes, address _user) external;
}

interface IGaugeBribeForFeesInteractor {
    function getRewardForOwner(address voter) external returns (address);
}

contract SpiritV2FeesInteractor {
    address constant public ADMIN_GAUGE_PROXY = 0x41AC759D04f51736F0f71da8b029aAC17267a1BB;
    address constant public VARIABLE_GAUGE_PROXY = 0xfe1C8A68351B52E391e10106BD3bf2d0759AFf4e;
    address constant public STABLE_GAUGE_PROXY = 0xad29B1060Dded121F4596b09F13Fa44c9d62BB49;

    function claimRewardsFromVariableProxyByPairs(address voter, address[] calldata lps) external {
        claimRewardsFromProxyByPairsInternal(VARIABLE_GAUGE_PROXY, voter, lps);
    }

    function claimRewardsFromStableProxyByPairs(address voter, address[] calldata lps) external {
        claimRewardsFromProxyByPairsInternal(STABLE_GAUGE_PROXY, voter, lps);
    }

    function claimRewardsFromAdminProxyByPairs(address voter, address[] calldata lps) external {
        claimRewardsFromProxyByPairsInternal(ADMIN_GAUGE_PROXY, voter, lps);
    }

    // ***** Public views *****

    function getGaugeFromVariableProxyByLp(address lp) external view returns (address) {
        return getGaugeFromProxyByLpInternal(VARIABLE_GAUGE_PROXY, lp);
    }

    function getBribeFromVariableProxyByLp(address lp) external view returns (address) {
        return getBribeFromProxyByLpInternal(VARIABLE_GAUGE_PROXY, lp);
    }

    function getBribeFromVariableProxyByGauge(address gauge) external view returns (address) {
        return getBribeFromProxyByGaugeInternal(VARIABLE_GAUGE_PROXY, gauge);
    }

    function getGaugeFromStableProxyByLp(address lp) external view returns (address) {
        return getGaugeFromProxyByLpInternal(STABLE_GAUGE_PROXY, lp);
    }

    function getBribeStableProxyByLp(address lp) external view returns (address) {
        return getBribeFromProxyByLpInternal(STABLE_GAUGE_PROXY, lp);
    }

    function getBribeFromStableProxyByGauge(address gauge) external view returns (address) {
        return getBribeFromProxyByGaugeInternal(STABLE_GAUGE_PROXY, gauge);
    }

    function getGaugeFromAdminProxyByLp(address lp) external view returns (address) {
        return getGaugeFromProxyByLpInternal(STABLE_GAUGE_PROXY, lp);
    }

    function getBribeFromAdminProxyByLp(address lp) external view returns (address) {
        return getBribeFromProxyByLpInternal(STABLE_GAUGE_PROXY, lp);
    }

    function getBribeFromAdminProxyByGauge(address gauge) external view returns (address) {
        return getBribeFromProxyByGaugeInternal(ADMIN_GAUGE_PROXY, gauge);
    }

    // ***** Internal views *****

    function getGaugeFromProxyByLpInternal(address gaugeProxy, address lp) internal view returns (address) {
        return IGaugeProxyForFeesInteractor(gaugeProxy).getGauge(lp);
    }

    function getBribeFromProxyByLpInternal(address gaugeProxy, address lp) internal view returns (address) {
        address gauge = getGaugeFromProxyByLpInternal(gaugeProxy, lp);
        return getBribeFromProxyByGaugeInternal(gaugeProxy, gauge);
    }

    function getBribeFromProxyByGaugeInternal(address gaugeProxy, address gauge) internal view returns (address) {
        return IGaugeProxyForFeesInteractor(gaugeProxy).getBribes(gauge);
    }

    // ***** Internal interactions *****

    function claimRewardsFromProxyByPairsInternal(address gaugeProxy, address voter, address[] calldata lps) internal {
        address[] memory bribeContracts = new address[](lps.length);

        // Get bribe contracts
        for (uint i =0; i < lps.length; i++) {
            bribeContracts[i] = getBribeFromProxyByLpInternal(gaugeProxy, lps[i]);
        }

        // Claim bribes
        IGaugeProxyForFeesInteractor(gaugeProxy).claimBribes(bribeContracts, voter);
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

/// @title Yield Adapter
/// @author Chainvisions
/// @notice A contract for querying yields on-chain.

contract YieldAdapter {
    struct QueryParams {
        address pool;   // Pool to query yield data from.
        address user;   // User to query the yield of.
        string sig;     // Function signature for querying.
        uint256 pid;    // Pool ID for querying yield.
    }

    enum PoolTypes {
        MasterChef,     // Standard Sushiswap MasterChef & forks.
        StakingRewards, // Synthetix's StakingRewards contract.
        SteakHouse      // Special version of MasterChef calculations for Creditum.
    }

    function queryYield(PoolTypes poolType, QueryParams memory params) public view returns (uint256) {
        if(poolType == PoolTypes.MasterChef) {
            return readMasterChef(params.pool, params.pid, params.user, params.sig);
        } else if(poolType == PoolTypes.StakingRewards) {
            return readStakingRewards(params.pool, params.user);
        } else if(poolType == PoolTypes.SteakHouse) {
            return readSteakhouse(params.pool, params.pid, params.user);
        } else {
            revert("No adapter available for this pool type");
        }
    }

    function readMasterChef(
        address _mc,
        uint256 _pid,
        address _user,
        string memory _earnedSig
    ) private view returns (uint256) {
        (bool success, bytes memory returnData) = _mc.staticcall(abi.encodeWithSignature(_earnedSig, _pid, _user));

        if(!success) {
            return 0;
        } else {
            return abi.decode(returnData, (uint256));
        }
    }

    function readStakingRewards(
        address _st,
        address _user
    ) private view returns (uint256) {
        (bool success, bytes memory returnData) = _st.staticcall(abi.encodeWithSignature("earned(address)", _user));

        if(!success) {
            return 0;
        } else {
            return abi.decode(returnData, (uint256));
        }
    }

    function readSteakhouse(
        address _sh,
        uint256 _pid,
        address _user
    ) private view returns (uint256) {
        (bool success, bytes memory returnData) = _sh.staticcall(abi.encodeWithSignature("pendingRewards(uint256,address)", _pid, _user));

        if(!success) {
            return 0;
        } else {
            uint256[] memory pendingYield = abi.decode(returnData, (uint256[]));
            return pendingYield[0];
        }
    }

}
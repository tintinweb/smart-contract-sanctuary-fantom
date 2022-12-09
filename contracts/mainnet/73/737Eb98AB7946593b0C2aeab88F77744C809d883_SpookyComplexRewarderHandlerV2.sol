// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
interface IRewarderHandler {
    function getRewardTokenInfo(address _rewarder, address _vaultToken)
        external
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory pendingAmounts,
            uint256[] memory rewardRates
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./interfaces/IRewarderHandler.sol";
interface IVaultToken {
    function pid() external view returns (uint256);
}
interface IRewarder {
    function poolLength() external view returns (uint256);
    function poolIds(uint256) external view returns (uint256);
    function poolInfo(uint256)
        external
        view
        returns (
            uint128,
            uint64,
            uint64
        );
    function pendingTokens(
        uint256 pid,
        address user,
        uint256
    )
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory rewardAmounts);
    function rewardPerSecond() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
}
contract SpookyComplexRewarderHandlerV2 is IRewarderHandler {
    constructor() {}
    function getTotalAllocPoint(address _rewarder)
        public
        view
        returns (uint256 totalAllocPoint)
    {
        IRewarder rewarder = IRewarder(_rewarder);
        return rewarder.totalAllocPoint();
    }
    function getRewardTokenInfo(address _rewarder, address _vaultToken)
        external
        view
        override
        returns (
            address[] memory rewardTokens,
            uint256[] memory pendingAmounts,
            uint256[] memory rewardRates
        )
    {
        uint256 totalAllocPoint = getTotalAllocPoint(_rewarder);
        uint256 pid = IVaultToken(_vaultToken).pid();
        IRewarder rewarder = IRewarder(_rewarder);
        (, , uint256 allocPoint) = rewarder.poolInfo(pid);
        (rewardTokens, pendingAmounts) = rewarder.pendingTokens(
            pid,
            _vaultToken,
            0
        );
        rewardRates = new uint256[](1);
        rewardRates[0] = totalAllocPoint == 0
            ? 0
            : (rewarder.rewardPerSecond() * allocPoint) / totalAllocPoint;
    }
}
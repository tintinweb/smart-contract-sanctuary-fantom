// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IOxLens.sol";
import "./interfaces/IUserProxy.sol";
import "./interfaces/IUserProxyFactory.sol";
import "./interfaces/ISolid.sol";
import "./interfaces/IVe.sol";

/**
 * @title UserProxyInterface
 * @author 0xDAO
 * @notice The primary user interface contract for front-end
 * @dev User proxy interface is responsible for creating and fetching a user's proxy
 *      and transferring tokens/routing calls to the user's proxy
 * @dev All calls here are unpermissioned as each call deals only with the proxy for msg.sender
 * @dev Authentication is handled in actual UserProxy implementations
 */
contract UserProxyInterface {
    // Public addresses
    address public userProxyFactoryAddress;
    address public oxLensAddress;

    // Internal interface helpers
    IOxLens internal oxLens;
    IVe internal ve;
    ISolid internal solid;
    IOxSolid internal oxSolid;
    IOxd internal oxd;

    /**
     * @notice Initialize UserProxyInterface
     * @param _userProxyFactoryAddress Factory address
     * @param _oxLensAddress oxLens address
     */
    function initialize(
        address _userProxyFactoryAddress,
        address _oxLensAddress
    ) public {
        require(userProxyFactoryAddress == address(0), "Already initialized");
        userProxyFactoryAddress = _userProxyFactoryAddress;
        oxLensAddress = _oxLensAddress;
        oxLens = IOxLens(_oxLensAddress);
        ve = oxLens.ve();
        solid = oxLens.solid();
        oxSolid = oxLens.oxSolid();
        oxd = oxLens.oxd();
    }

    /*******************************************************
     *                    LP Interactions
     *******************************************************/

    /**
     * @notice LP -> oxPool LP -> Staked (max)
     * @param solidPoolAddress The solid pool LP address to deposit and stake
     */
    function depositLpAndStake(address solidPoolAddress) external {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Fetch amount of Solid LP owned by owner
        uint256 amount = IERC20(solidPoolAddress).balanceOf(
            userProxyOwnerAddress
        );

        // Deposit and stake LP
        depositLpAndStake(solidPoolAddress, amount);
    }

    /**
     * @notice LP -> oxPool LP -> Staked
     * @param solidPoolAddress The solid pool LP address to deposit and stake
     * @param amount The amount of solid pool LP to deposit and stake
     */
    function depositLpAndStake(address solidPoolAddress, uint256 amount)
        public
    {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Receive LP from UserProxy owner
        IERC20(solidPoolAddress).transferFrom(
            userProxyOwnerAddress,
            address(this),
            amount
        );

        // Allow UserProxy to spend LP
        IERC20(solidPoolAddress).approve(address(userProxy), amount);

        // Deposit and stake LP via UserProxy
        userProxy.depositLpAndStake(solidPoolAddress, amount);
    }

    /**
     * @notice LP -> oxPool LP (max)
     * @param solidPoolAddress The solid pool LP address to deposit
     */
    function depositLp(address solidPoolAddress) external {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Fetch amount of Solid LP owned by owner
        uint256 amount = IERC20(solidPoolAddress).balanceOf(
            userProxyOwnerAddress
        );
        depositLp(solidPoolAddress, amount);
    }

    /**
     * @notice LP -> oxPool LP
     * @param solidPoolAddress The solid pool LP address to deposit
     * @param amount The amount of solid pool LP to deposit and stake
     */
    function depositLp(address solidPoolAddress, uint256 amount) public {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Receive LP from UserProxy owner
        IERC20(solidPoolAddress).transferFrom(
            userProxyOwnerAddress,
            address(this),
            amount
        );

        // Allow UserProxy to spend LP
        IERC20(solidPoolAddress).approve(address(userProxy), amount);

        // Deposit LP into oxPool via UserProxy
        userProxy.depositLp(solidPoolAddress, amount);
    }

    /**
     * @notice Staked oxPool LP -> oxPool LP -> LP (max)
     * @param solidPoolAddress The solid pool LP address to unstake and withdraw
     */
    function unstakeLpWithdrawAndClaim(address solidPoolAddress) external {
        // Fetch amount staked
        uint256 amount = _amountStaked(solidPoolAddress);

        // Withdraw and unstake
        unstakeLpWithdrawAndClaim(solidPoolAddress, amount);
    }

    /**
     * @notice Staked oxPool LP -> oxPool LP -> LP
     * @param solidPoolAddress The solid pool LP address to unstake and withdraw
     * @param amount The amount of solid pool LP to unstake and withdraw
     */
    function unstakeLpWithdrawAndClaim(address solidPoolAddress, uint256 amount)
        public
    {
        // Withdraw and unstake
        IUserProxy userProxy = createAndGetUserProxy();
        userProxy.unstakeLpAndWithdraw(solidPoolAddress, amount, true);
    }

    /**
     * @notice Staked oxPool LP -> oxPool LP -> LP (max)
     * @param solidPoolAddress The solid pool LP address to unstake and withdraw
     */
    function unstakeLpAndWithdraw(address solidPoolAddress) external {
        // Fetch amount staked
        uint256 amount = _amountStaked(solidPoolAddress);

        // Withdraw and unstake
        unstakeLpAndWithdraw(solidPoolAddress, amount);
    }

    /**
     * @notice Staked oxPool LP -> oxPool LP -> LP
     * @param solidPoolAddress The solid pool LP address to unstake and withdraw
     * @param amount The amount of solid pool LP to unstake and withdraw
     */
    function unstakeLpAndWithdraw(address solidPoolAddress, uint256 amount)
        public
    {
        // Withdraw and unstake
        IUserProxy userProxy = createAndGetUserProxy();
        userProxy.unstakeLpAndWithdraw(solidPoolAddress, amount, false);
    }

    function _amountStaked(address solidPoolAddress)
        internal
        returns (uint256)
    {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Determine amount currently staked
        address stakingAddress = oxLens.stakingRewardsBySolidPool(
            solidPoolAddress
        );
        uint256 amount = IERC20(stakingAddress).balanceOf(address(userProxy));
        return amount;
    }

    /**
     * @notice oxPool LP -> LP (max)
     * @param solidPoolAddress The solid pool LP address to withdraw
     */
    function withdrawLp(address solidPoolAddress) external {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Fetch amount of oxPool LP owned by UserProxy owner
        address oxPoolAddress = oxLens.oxPoolBySolidPool(solidPoolAddress);
        uint256 amount = IERC20(oxPoolAddress).balanceOf(userProxyOwnerAddress);
        withdrawLp(solidPoolAddress, amount);
    }

    /**
     * @notice oxPool LP -> LP
     * @param solidPoolAddress The solid pool LP address to withdraw
     * @param amount The amount of solid pool LP to withdraw
     */
    function withdrawLp(address solidPoolAddress, uint256 amount) public {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Receive oxPool LP from UserProxy owner
        address oxPoolAddress = oxLens.oxPoolBySolidPool(solidPoolAddress);
        IERC20(oxPoolAddress).transferFrom(
            userProxyOwnerAddress,
            address(this),
            amount
        );

        // Allow UserProxy to spend oxPool LP
        IERC20(oxPoolAddress).approve(address(userProxy), amount);

        // Withdraw oxPool LP via UserProxy (UserProxy will transfer it to owner)
        userProxy.withdrawLp(solidPoolAddress, amount);
    }

    /**
     * @notice oxPool LP -> Staked oxPool LP (max)
     * @param oxPoolAddress The oxPool LP address to stake
     */
    function stakeOxLp(address oxPoolAddress) public {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Fetch amount of oxPool LP owned by owner
        uint256 amount = IERC20(oxPoolAddress).balanceOf(userProxyOwnerAddress);
        stakeOxLp(oxPoolAddress, amount);
    }

    /**
     * @notice oxPool LP -> Staked oxPool LP
     * @param oxPoolAddress The oxPool LP address to stake
     * @param amount The amount of oxPool LP to stake
     */
    function stakeOxLp(address oxPoolAddress, uint256 amount) public {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Receive oxPool LP from owner
        IERC20(oxPoolAddress).transferFrom(
            userProxyOwnerAddress,
            address(this),
            amount
        );

        // Allow UserProxy to spend oxPool LP
        IERC20(oxPoolAddress).approve(address(userProxy), amount);

        // Stake oxPool LP
        userProxy.stakeOxLp(oxPoolAddress, amount);
    }

    /**
     * @notice Staked oxPool LP -> oxPool LP (max)
     * @param oxPoolAddress The oxPool LP address to unstake
     */
    function unstakeOxLp(address oxPoolAddress) public {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Fetch amount of oxPool LP currently staked
        address stakingAddress = oxLens.stakingRewardsByOxPool(oxPoolAddress);
        uint256 amount = IERC20(stakingAddress).balanceOf(address(userProxy));

        // Unstake
        unstakeOxLp(oxPoolAddress, amount);
    }

    /**
     * @notice Staked oxPool LP -> oxPool LP
     * @param oxPoolAddress The oxPool LP address to unstake
     * @param amount The amount of oxPool LP to unstake
     */
    function unstakeOxLp(address oxPoolAddress, uint256 amount) public {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Unstake
        userProxy.unstakeOxLp(oxPoolAddress, amount);
    }

    /**
     * @notice Claim staking rewards given a staking pool address
     * @param stakingPoolAddress Address of MultiRewards contract
     */
    function claimStakingRewards(address stakingPoolAddress) public {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Unstake
        userProxy.claimStakingRewards(stakingPoolAddress);
    }

    /**
     * @notice Claim all staking rewards
     */
    function claimStakingRewards() public {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Unstake
        userProxy.claimStakingRewards();
    }

    /*******************************************************
     *                 SOLID and veNFT interactions
     *******************************************************/

    /**
     * @notice SOLID -> veNFT -> oxSOLID (max)
     */
    function convertSolidToOxSolid() external {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Fetch amount of SOLID owned by owner
        uint256 amount = solid.balanceOf(userProxyOwnerAddress);
        convertSolidToOxSolid(amount);
    }

    /**
     * @notice SOLID -> veNFT -> oxSOLID
     * @param amount The amount of SOLID to convert
     */
    function convertSolidToOxSolid(uint256 amount) public {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Transfer SOLID to this contract
        solid.transferFrom(userProxyOwnerAddress, address(this), amount);

        // Allow UserProxy to spend SOLID
        solid.approve(address(userProxy), amount);

        // Convert SOLID to oxSOLID
        userProxy.convertSolidToOxSolid(amount);
    }

    /**
     * @notice SOLID -> veNFT -> oxSOLID -> Staked oxSOLID (max)
     */
    function convertSolidToOxSolidAndStake() external {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Fetch amount of SOLID owner by UserProxy owner
        uint256 amount = solid.balanceOf(userProxyOwnerAddress);

        // Convert SOLID to oxSOLID and stake
        convertSolidToOxSolidAndStake(amount);
    }

    /**
     * @notice SOLID -> veNFT -> oxSOLID -> Staked oxSOLID
     * @param amount The amount of SOLID to convert
     */
    function convertSolidToOxSolidAndStake(uint256 amount) public {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Transfer SOLID to this contract
        solid.transferFrom(userProxyOwnerAddress, address(this), amount);

        // Allow UserProxy to spend SOLID
        solid.approve(address(userProxy), amount);

        // Convert SOLID to oxSOLID
        userProxy.convertSolidToOxSolidAndStake(amount);
    }

    /**
     * @notice veNFT -> oxSOLID
     * @param tokenId The tokenId of the NFT to convert
     */
    function convertNftToOxSolid(uint256 tokenId) public {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Transfer NFT to this contract
        ve.safeTransferFrom(userProxyOwnerAddress, address(this), tokenId);

        // Transfer NFT to user proxy to convert
        ve.approve(address(userProxy), tokenId);
        userProxy.convertNftToOxSolid(tokenId);
    }

    /**
     * @notice veNFT -> oxSOLID -> Staked oxSOLID
     * @param tokenId The tokenId of the NFT to convert
     */
    function convertNftToOxSolidAndStake(uint256 tokenId) external {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Transfer NFT to this contract
        ve.safeTransferFrom(userProxyOwnerAddress, address(this), tokenId);

        // Convert SOLID to oxSOLID and stake
        ve.approve(address(userProxy), tokenId);
        userProxy.convertNftToOxSolidAndStake(tokenId);
    }

    /**
     * @notice oxSOLID -> Staked oxSOLID (max)
     */
    function stakeOxSolid() external {
        // Fetch amount of oxSOLID currently staked
        uint256 amount = oxSolid.balanceOf(msg.sender);

        // Stake oxSOLID
        stakeOxSolid(amount);
    }

    /**
     * @notice oxSOLID -> Staked oxSOLID
     * @param amount The amount of oxSOLID to stake
     */
    function stakeOxSolid(uint256 amount) public {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Receive oxSOLID from owner
        oxSolid.transferFrom(userProxyOwnerAddress, address(this), amount);

        // Allow UserProxy to spend oxSOLID
        oxSolid.approve(address(userProxy), amount);

        // Stake oxSOLID via UserProxy
        userProxy.stakeOxSolid(amount);
    }

    /**
     * @notice oxSOLID -> Staked oxSOLID in oxdV1Rewards after burning OXDv1 (max)
     */
    function stakeOxSolidInOxdV1() external {
        // Fetch amount of oxSOLID currently staked
        uint256 amount = oxSolid.balanceOf(msg.sender);

        // Stake oxSOLID
        stakeOxSolidInOxdV1(amount);
    }

    /**
     * @notice oxSOLID -> Staked oxSOLID in oxdV1Rewards after burning OXDv1
     * @param amount The amount of oxSOLID to stake
     */
    function stakeOxSolidInOxdV1(uint256 amount) public {
        // Fetch user proxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Receive oxSOLID from owner
        oxSolid.transferFrom(userProxyOwnerAddress, address(this), amount);

        // Allow UserProxy to spend oxSOLID
        oxSolid.approve(address(userProxy), amount);

        // Stake oxSOLID via UserProxy
        userProxy.stakeOxSolidInOxdV1(amount);
    }

    /**
     * @notice Staked oxSOLID -> oxSOLID (max)
     */
    function unstakeOxSolid() external {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Fetch amount of oxSOLID currently staked
        uint256 amount = oxLens.stakedOxSolidBalanceOf(msg.sender);

        // Unstake oxSOLID
        userProxy.unstakeOxSolid(amount);
    }

    /**
     * @notice Staked oxSOLID -> oxSOLID
     * @param amount The amount of oxSOLID to unstake
     */
    function unstakeOxSolid(uint256 amount) public {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();
        address stakingAddress = oxLens.oxSolidRewardsPoolAddress();

        // Unstake via UserProxy
        userProxy.unstakeOxSolid(amount);
    }

    /**
     * @notice Staked oxSOLID in oxdV1Rewards -> oxSOLID
     * @param amount The amount of oxSOLID to unstake
     */
    function unstakeOxSolidInOxdV1(uint256 amount) public {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();
        address stakingAddress = oxLens.oxdV1RewardsAddress();

        // Unstake via UserProxy
        userProxy.unstakeOxSolid(stakingAddress, amount);
    }

    /**
     * @notice Generalized Staked oxSOLID -> oxSOLID
     * @param stakingAddress The MultiRewards Address to unstake from
     * @param amount The amount of oxSOLID to unstake
     */
    function unstakeOxSolid(address stakingAddress, uint256 amount) public {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Unstake via UserProxy
        userProxy.unstakeOxSolid(stakingAddress, amount);
    }

    /**
     * @notice Claim staking rewards for staking oxSOLID
     */
    function claimOxSolidStakingRewards() public {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();
        address stakingAddress;
        if (oxLens.isPartner(address(userProxy))) {
            stakingAddress = oxLens.partnersRewardsPoolAddress();
        } else {
            stakingAddress = oxLens.oxSolidRewardsPoolAddress();
        }

        // Claim rewards
        userProxy.claimStakingRewards(stakingAddress);
    }

    /*******************************************************
     *                   OXDv1 Redemption
     *******************************************************/

    /**
     * @notice OXDv1 -> oxSOLID (max)
     */
    function redeemOxdV1() public {
        // Fetch amount
        uint256 amount = IERC20(oxLens.oxdV1Address()).balanceOf(msg.sender);

        // Unstake via UserProxy
        redeemOxdV1(amount);
    }

    /**
     * @notice OXDv1 -> oxSOLID
     * @param amount The amount of OXDv1 to redeem
     */
    function redeemOxdV1(uint256 amount) public {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Receive OXD v1 from owner
        IERC20(oxLens.oxdV1Address()).transferFrom(
            userProxyOwnerAddress,
            address(this),
            amount
        );

        // Allow UserProxy to spend OXD v1
        IERC20(oxLens.oxdV1Address()).approve(address(userProxy), amount);

        // Unstake via UserProxy
        userProxy.redeemOxdV1(amount);
    }

    /**
     * @notice OXDv1 -> oxSOLID staked in oxdV1Rewards (max)
     */
    function redeemAndStakeOxdV1() public {
        // Fetch amount
        uint256 amount = IERC20(oxLens.oxdV1Address()).balanceOf(msg.sender);

        // Unstake via UserProxy
        redeemAndStakeOxdV1(amount);
    }

    /**
     * @notice OXDv1 -> oxSOLID staked in oxdV1Rewards
     * @param amount The amount of OXDv1 to redeem
     */
    function redeemAndStakeOxdV1(uint256 amount) public {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Receive OXD v1 from owner
        IERC20(oxLens.oxdV1Address()).transferFrom(
            userProxyOwnerAddress,
            address(this),
            amount
        );

        // Allow UserProxy to spend OXD v1
        IERC20(oxLens.oxdV1Address()).approve(address(userProxy), amount);

        // Unstake via UserProxy
        userProxy.redeemAndStakeOxdV1(amount);
    }

    /**
     * @notice Claim OXDv1 oxSOLID staking rewards
     */
    function claimV1OxSolidStakingRewards() public {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Claim rewards
        userProxy.claimStakingRewards(oxLens.oxdV1RewardsAddress());
    }

    /*******************************************************
     *                   Partner migration
     *******************************************************/

    /**
     * @notice Migrates nonparters who recently got whitelisted as partners
     */
    function migrateOxSolidToPartner() external {
        IUserProxy userProxy = createAndGetUserProxy();
        userProxy.migrateOxSolidToPartner();
    }

    /*******************************************************
     *                        vlOXD
     *******************************************************/

    /**
     * @notice Vote lock OXD for 16 weeks (non-transferrable)
     * @param amount Amount of OXD to lock
     * @param spendRatio Spend ratio for OxdLocker
     * @dev OxdLocker utilizes the same code as CvxLocker
     */
    function voteLockOxd(uint256 amount, uint256 spendRatio) external {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();
        address userProxyOwnerAddress = userProxy.ownerAddress();

        // Receive OXD from user
        oxd.transferFrom(userProxyOwnerAddress, address(this), amount);

        // Allow UserProxy to spend OXD
        oxd.approve(address(userProxy), amount);

        // Lock OXD via UserProxy
        userProxy.voteLockOxd(amount, spendRatio);
    }

    /**
     * @notice Withdraw vote locked OXD
     * @param spendRatio Spend ratio
     */
    function withdrawVoteLockedOxd(uint256 spendRatio) external {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Withdraw vote locked OXD and claim
        userProxy.withdrawVoteLockedOxd(spendRatio, false);
    }

    /**
     * @notice Relock vote locked OXD
     * @param spendRatio Spend ratio
     */
    function relockVoteLockedOxd(uint256 spendRatio) external {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Withdraw vote locked OXD and claim
        userProxy.relockVoteLockedOxd(spendRatio);
    }

    /**
     * @notice Claim vlOXD staking rewards
     */
    function claimVlOxdStakingRewards() public {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Claim rewards
        userProxy.claimVlOxdRewards();
    }

    /*******************************************************
     *                       Voting
     *******************************************************/

    /**
     * @notice Vote for a pool given a pool address and weight
     * @param poolAddress The pool adress to vote for
     * @param weight The new vote weight (can be positive or negative)
     */
    function vote(address poolAddress, int256 weight) external {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Withdraw vote locked OXD and claim
        userProxy.vote(poolAddress, weight);
    }

    /**
     * @notice Batch vote
     * @param votes Votes
     */
    function vote(IUserProxy.Vote[] memory votes) external {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Clear vote delegate
        userProxy.vote(votes);
    }

    /**
     * @notice Remove a user's vote given a pool address
     * @param poolAddress The address of the pool whose vote will be deleted
     */
    function removeVote(address poolAddress) public {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Withdraw vote locked OXD and claim
        userProxy.removeVote(poolAddress);
    }

    /**
     * @notice Delete all vote for a user
     */
    function resetVotes() external {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Withdraw vote locked OXD and claim
        userProxy.resetVotes();
    }

    /**
     * @notice Set vote delegate for an account
     * @param accountAddress New delegate address
     */
    function setVoteDelegate(address accountAddress) external {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Set vote delegate
        userProxy.setVoteDelegate(accountAddress);
    }

    /**
     * @notice Clear vote delegate for an account
     */
    function clearVoteDelegate() external {
        // Fetch UserProxy
        IUserProxy userProxy = createAndGetUserProxy();

        // Clear vote delegate
        userProxy.clearVoteDelegate();
    }

    /*******************************************************
     *                   Helper Utilities
     *******************************************************/

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Only allow users to interact with their proxy
    function createAndGetUserProxy() internal returns (IUserProxy) {
        return
            IUserProxy(
                IUserProxyFactory(userProxyFactoryAddress)
                    .createAndGetUserProxy(msg.sender)
            );
    }

    function claimAllStakingRewards() public {
        claimStakingRewards();
        claimOxSolidStakingRewards();
        claimV1OxSolidStakingRewards();
        claimVlOxdStakingRewards();
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Wrapper.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../utils/SafeERC20.sol";

/**
 * @dev Extension of the ERC20 token contract to support token wrapping.
 *
 * Users can deposit and withdraw "underlying tokens" and receive a matching number of "wrapped tokens". This is useful
 * in conjunction with other modules. For example, combining this wrapping mechanism with {ERC20Votes} will allow the
 * wrapping of an existing "basic" ERC20 into a governance token.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Wrapper is ERC20 {
    IERC20 public immutable underlying;

    constructor(IERC20 underlyingToken) {
        underlying = underlyingToken;
    }

    /**
     * @dev Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.
     */
    function depositFor(address account, uint256 amount) public virtual returns (bool) {
        SafeERC20.safeTransferFrom(underlying, _msgSender(), address(this), amount);
        _mint(account, amount);
        return true;
    }

    /**
     * @dev Allow a user to burn a number of wrapped tokens and withdraw the corresponding number of underlying tokens.
     */
    function withdrawTo(address account, uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        SafeERC20.safeTransfer(underlying, account, amount);
        return true;
    }

    /**
     * @dev Mint wrapped token to cover any underlyingTokens that would have been transfered by mistake. Internal
     * function that can be exposed with access control if desired.
     */
    function _recover(address account) internal virtual returns (uint256) {
        uint256 value = underlying.balanceOf(address(this)) - totalSupply();
        _mint(account, value);
        return value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOxd is IERC20 {
    function mint(address to, uint256 amount) external;
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

interface IOxPoolFactory {
    function oxPoolsLength() external view returns (uint256);

    function isOxPool(address) external view returns (bool);

    function OXD() external view returns (address);

    function syncPools(uint256) external;

    function oxPools(uint256) external view returns (address);

    function oxPoolBySolidPool(address) external view returns (address);

    function vlOxdAddress() external view returns (address);

    function oxSolidStakingPoolAddress() external view returns (address);

    function solidPoolByOxPool(address) external view returns (address);

    function syncedPoolsLength() external returns (uint256);

    function solidlyLensAddress() external view returns (address);

    function voterProxyAddress() external view returns (address);

    function rewardsDistributorAddress() external view returns (address);

    function tokensAllowlist() external view returns (address);
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

    function poolInfo(address) external view returns (Pool memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVotingSnapshot {
    struct Vote {
        address poolAddress;
        int256 weight;
    }

    function vote(address, int256) external;

    function vote(Vote[] memory) external;

    function removeVote(address) external;

    function resetVotes() external;

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

interface IVoterProxy {
    function depositInGauge(address, uint256) external;

    function withdrawFromGauge(address, uint256) external;

    function getRewardFromGauge(
        address _gauge,
        address _staking,
        address[] memory _tokens
    ) external;

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
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IMultiRewards.sol";

interface IOxdV1Rewards is IMultiRewards {
    function stakingCap(address account) external view returns (uint256 cap);
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
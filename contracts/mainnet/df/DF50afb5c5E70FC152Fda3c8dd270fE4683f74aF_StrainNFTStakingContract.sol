//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interface/IStrainFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StrainNFTStakingContract is ERC721Holder, Ownable {
    // Contract setup
    address public constant UTILITY_DISTRIBUTION_ADDRESS =
        0x1d2582DB948C201b10A0E75BcB1e09B8Be4E9770;
    uint8 public constant UPGRADE_STAGE_LIMIT = 14;
    uint64 public constant COOL_DOWN_INTERVAL = (60 * 60 * 24);
    uint64 public constant STAKING_CYCLE = (60 * 60 * 24);
    address public strainAddress;
    using SafeERC20 for IERC20;

    struct StakeInfo {
        address owner;
        uint64 stakeDate;
        uint64 lastWateredTime;
        uint64 lastFertilisedTime;
        uint8 waterCount;
        uint8 fertilizerCount;
    }
    address private admin;
    mapping(address => uint256[]) stakeStrainIds;

    // Strain NFT token to stake
    IStrainFactory strainNftToken;

    // Strain ERC-20 token address
    IERC20 strnToken;
    IERC20 wtrToken;
    IERC20 frtToken;

    //  The rewards will be transferred from this address
    address stakingRewardsAddress;

    //  It's used to store all stake history
    mapping(uint256 => StakeInfo) public stakeHistory;

    //  Reward History
    mapping(address => uint256) public userRewardHistory;
    mapping(address => uint256) public userAllTimeReward;
    mapping(uint256 => uint256) public budAllTimeReward;

    //  Events
    event Staked(address staker, uint256 _tokenId);
    event Unstaked(address unstaker, uint256 _tokenId);
    event EmergencyUnstakeed(address unstaker, uint256 _tokenId);
    event StrainUpdated(address owner, uint256 strainId, string updateType);
    event RewardClaimed(address owner, uint256 amount, uint256 date);
    event RewardsDistribution(uint256 amount, uint256 date);
    event BudRewardsDistribution(uint256 tokenId, uint256 amount, uint256 date);

    /**
     * @dev constructor
     * @param _nftTokenAddr the address of token to stake
     */
    constructor(
        address _nftTokenAddr,
        address _strTokenAddr,
        address _wtrTokenAddr,
        address _frtTokenAddr,
        address _stakingRewardsDistribution
    ) {
        require(_nftTokenAddr != address(0), "Zero address");
        strainNftToken = IStrainFactory(_nftTokenAddr);
        strnToken = IERC20(_strTokenAddr);
        wtrToken = IERC20(_wtrTokenAddr);
        frtToken = IERC20(_frtTokenAddr);
        strainAddress = _strTokenAddr;
        stakingRewardsAddress = _stakingRewardsDistribution;
    }


    modifier isValidStrainId(uint256 _tokenId) {
        StakeInfo memory strain = stakeHistory[_tokenId];
        require(strain.stakeDate > 0, "Invalid Token Id");
        _;
    }

    modifier isOwner(uint256 _tokenId) {
        StakeInfo storage stakeInfo = stakeHistory[_tokenId];
        require(stakeInfo.owner == msg.sender, "Not Strain Owner");
        _;
    }

    /**@notice Incremental function for gas saving
     * @dev Used only for FOR LOOPING
     * @param x is a uint to be incremented by 1
     **/
    function incS(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    /**
     * @dev the function to stake strain NFT token
     * @param _tokenId the strain NFT token Id to unstake
     */
    function stake(uint256 _tokenId) public {
        address newAddress = msg.sender;
        uint64 newDate = uint64(block.timestamp);
        require(
            strainNftToken.ownerOf(_tokenId) == newAddress,
            "Not Strain Owner"
        );
        require(!isStaked(_tokenId, newAddress), "Already Staked");
        stakeStrainIds[newAddress].push(_tokenId);
        stakeHistory[_tokenId] = StakeInfo({
            owner: newAddress,
            stakeDate: newDate,
            lastWateredTime: newDate - COOL_DOWN_INTERVAL,
            lastFertilisedTime: newDate - COOL_DOWN_INTERVAL,
            waterCount: 0,
            fertilizerCount: 0
        });

        emit Staked(msg.sender, _tokenId);
        strainNftToken.safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    function isStaked(uint256 _tokenId, address _owner)
        public
        view
        returns (bool)
    {
        uint256[] memory stakedIds = stakeStrainIds[_owner];
        for (uint256 i = 0; i < stakedIds.length; i = incS(i)) {
            if (stakedIds[i] == _tokenId) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev the function to unstake the staked strain NFT token in the history
     * @param _tokenId the strain NFT token Id to unstake
     */
    function unstake(uint256 _tokenId) public isOwner(_tokenId) {
        removeStakedStrainId(_tokenId, msg.sender);
        // Transfer token to the staker and update its balance
        emit Unstaked(msg.sender, _tokenId);
        strainNftToken.transferFrom(address(this), msg.sender, _tokenId);
    }

    /**
     * @dev the function to unstake the staked token without reward in the history
     * @param _tokenId the strain NFT token Id to unstake
     */
    function emergencyUnstake(uint256 _tokenId) public onlyOwner {
        address owner = getStakeInfo(_tokenId).owner;
        removeStakedStrainId(_tokenId, owner);
        // Transfer token to the staker and update its balance
        emit EmergencyUnstakeed(owner, _tokenId);
        strainNftToken.transferFrom(address(this), owner, _tokenId);
    }

    function removeStakedStrainId(uint256 _tokenId, address _owner)
        internal
        isOwner(_tokenId)
    {
        StakeInfo storage stakeInfo = stakeHistory[_tokenId];
        require(stakeInfo.owner == _owner, "Not Strain Owner");

        delete stakeHistory[_tokenId];

        uint256[] storage stakedIds = stakeStrainIds[_owner];
        for (uint256 i; i < stakedIds.length; i = incS(i)) {
            if (stakedIds[i] == _tokenId) {
                stakedIds[i] = stakedIds[stakedIds.length - 1];
                stakedIds.pop();
                break;
            }
        }
    }

    function watered(uint256 _strainId) public isOwner(_strainId) {
        StakeInfo storage stakeInfo = stakeHistory[_strainId];

        require(
            stakeInfo.lastWateredTime + uint64(COOL_DOWN_INTERVAL) <=
                block.timestamp,
            "Strain Watering on cooldown"
        );
        require(getUpgradableTimer(_strainId) > 0, "Staking Completed");
        require(stakeInfo.waterCount < UPGRADE_STAGE_LIMIT, "Useless Watering");

        stakeInfo.lastWateredTime = uint64(block.timestamp);
        stakeInfo.waterCount++;
        emit StrainUpdated(msg.sender, _strainId, "Watering");
        wtrToken.safeTransferFrom(
            msg.sender,
            UTILITY_DISTRIBUTION_ADDRESS,
            1 * 1e18
        );
    }

    function fertilized(uint256 _strainId) public isOwner(_strainId) {
        StakeInfo storage stakeInfo = stakeHistory[_strainId];

        require(
            stakeInfo.lastFertilisedTime + uint64(COOL_DOWN_INTERVAL) <=
                block.timestamp,
            "Strain Fertilizing on cooldown"
        );
        require(isStageUpgradable(_strainId) == false, "Staking Completed");
        require(
            stakeInfo.fertilizerCount < UPGRADE_STAGE_LIMIT,
            "Useless Fertilizing"
        );

        stakeInfo.lastFertilisedTime = uint64(block.timestamp);
        stakeInfo.fertilizerCount++;
        emit StrainUpdated(msg.sender, _strainId, "Fertilizer");
        frtToken.safeTransferFrom(
            msg.sender,
            UTILITY_DISTRIBUTION_ADDRESS,
            1 * 1e18
        );
    }

    function isStageUpgradable(uint256 _strainId) public view returns (bool) {
        StakeInfo memory stakeInfo = stakeHistory[_strainId];
        return (block.timestamp - stakeInfo.stakeDate >=
            (2 * UPGRADE_STAGE_LIMIT * COOL_DOWN_INTERVAL) -
                ((stakeInfo.waterCount + 1) * COOL_DOWN_INTERVAL));
    }

    function getStakeInfo(uint256 _tokenId)
        public
        view
        returns (StakeInfo memory stakeInfo)
    {
        stakeInfo = stakeHistory[_tokenId];
    }

    function getStakedTokenIds(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        return stakeStrainIds[_owner];
    }

    function getWateredTimer(uint256 _tokenId)
        public
        view
        isValidStrainId(_tokenId)
        returns (uint256)
    {
        StakeInfo memory stakeInfo = stakeHistory[_tokenId];
        uint256 nextTime = stakeInfo.lastWateredTime + COOL_DOWN_INTERVAL;
        if (nextTime > block.timestamp) return nextTime - block.timestamp;
        else return 0;
    }

    function getFertilizerTimer(uint256 _tokenId)
        public
        view
        isValidStrainId(_tokenId)
        returns (uint256)
    {
        StakeInfo memory stakeInfo = stakeHistory[_tokenId];
        uint256 nextTime = stakeInfo.lastFertilisedTime + COOL_DOWN_INTERVAL;
        if (nextTime > block.timestamp) return nextTime - block.timestamp;
        else return 0;
    }

    function getUpgradableTimer(uint256 _tokenId)
        public
        view
        isValidStrainId(_tokenId)
        returns (uint256)
    {
        StakeInfo memory stakeInfo = stakeHistory[_tokenId];
        uint256 nextTime = stakeInfo.stakeDate +
            (2 * UPGRADE_STAGE_LIMIT * COOL_DOWN_INTERVAL) -
            ((stakeInfo.waterCount + 1) * COOL_DOWN_INTERVAL);
        if (nextTime > block.timestamp) return nextTime - block.timestamp;
        else return 0;
    }

    function upgradeStage(uint256 _strainId, string memory _tokenURI)
        public
        isOwner(_strainId)
    {
        require(isStageUpgradable(_strainId), "Impossible to upgrade");
        address userAddress = msg.sender;
        uint64 newDate = uint64(block.timestamp);
        StakeInfo storage strain = stakeHistory[_strainId];

        uint8 oldCount = strain.fertilizerCount;

        strain.stakeDate = newDate;
        strain.fertilizerCount = 0;
        strain.lastFertilisedTime = newDate - COOL_DOWN_INTERVAL;
        strain.lastWateredTime = newDate - COOL_DOWN_INTERVAL;
        strain.waterCount = 0;
        emit StrainUpdated(userAddress, _strainId, "Upgrade");
        strainNftToken.updateRarity(_strainId, oldCount);
        strainNftToken.upgradeStage(_strainId, _tokenURI, strain.owner);
    }

    function stakedHigh() internal view returns (uint256) {
        uint256 monthlyHigh = 0;
        uint256 supply = strainNftToken.totalSupply();
        for (uint256 i = 1; i <= supply; i = incS(i)) {
            StakeInfo storage stakeInfo = stakeHistory[i];
            uint8 stage = strainNftToken.getStage(i);
            address owner = stakeInfo.owner;
            if (isStaked(i, owner) == true && stage == 3) {
                uint256 rare = strainNftToken.getRarity(i);
                uint256 daysStaked = (block.timestamp - stakeInfo.stakeDate);
                uint256 singleHigh = (rare * daysStaked) / STAKING_CYCLE;
                monthlyHigh += singleHigh;
            }
        }
        return monthlyHigh;
    }

    function monthlyReward(uint256 _distribution) public onlyOwner {
        uint256 monthlyTotal = stakedHigh();
        uint256 tokensPerHigh = (monthlyTotal == 0)
            ? 0
            : ((_distribution * 100000) / monthlyTotal);
        uint256 supply = strainNftToken.totalSupply();
        for (uint256 i = 1; i <= supply; i = incS(i)) {
            StakeInfo storage stakeInfo = stakeHistory[i];
            uint8 stage = strainNftToken.getStage(i);
            address owner = stakeInfo.owner;
            if (isStaked(i, owner) && stage == 3) {
                uint256 rare = strainNftToken.getRarity(i);
                uint256 daysStaked = (block.timestamp - stakeInfo.stakeDate);
                uint256 singleHigh = (rare * daysStaked) / STAKING_CYCLE;
                uint256 stakingReward = (
                    ((singleHigh * tokensPerHigh) / 100000)
                );
                budAllTimeReward[i] += stakingReward;
                userRewardHistory[owner] += stakingReward;
                userAllTimeReward[owner] += stakingReward;
                emit BudRewardsDistribution(i, stakingReward, block.timestamp);
            }
        }
        emit RewardsDistribution(_distribution, block.timestamp);
    }

    /**
     * @dev the function to claim reward
     */
    function claimReward() public {
        address user = msg.sender;
        uint256 stakingReward = userRewardHistory[user];

        require(stakingReward > 0, "No Reward");
        userRewardHistory[user] = 0;
        emit RewardClaimed(user, stakingReward, block.timestamp);
        strnToken.safeTransferFrom(
            stakingRewardsAddress,
            user,
            stakingReward
        );
    }

    function getAvailableReward(address _owner)
        public
        view
        returns (uint256 reward)
    {
        reward = userRewardHistory[_owner];
    }

    function setBaseMetadata(string memory _uri) public onlyOwner {
        strainNftToken.setBaseURI(_uri);
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IStrainFactory {
    struct Strain {
        uint256 dna;
        uint256 rarityScore;
        uint64 createdTime;
        uint8 stage;
    }

    event StrainCreated(address owner, uint256 strainId);

    event StrainUpdated(address owner, uint256 strainId);

    event StrainCreatorAdded(address creator);
    event StrainCreatorRemoved(address creator);

    function isStrainCreator(address _address) external view returns (bool);

    function dnaToArray(uint256 _dna) external;

    function addStrainCreator(address _address) external;

    function _addStrainCreator(address _address) external;

    function removeStrainCreator(address _address) external;

    function getStrainCreators() external view returns (address[] memory);

    function getStrain(uint256 _strainId)
        external
        view
        returns (
            uint256 strainId,
            uint256 rarityScore,
            uint256 dna,
            uint256[15] memory Genes,
            uint64 createdTime,
            uint8 stage,
            address owner
        );

    function balanceOf(address owner) external view returns (uint256 balance);

    function totalSupply() external view returns (uint256 total);

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function ownerOf(uint256 _tokenId) external view returns (address owner);

    function _ownerOf(uint256 _tokenId) external view returns (address owner);

    function isStrainOwner(uint256 _strainId) external view returns (bool);

    function transfer(address _to, uint256 _tokenId) external;

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function approve(address _approved, uint256 _tokenId) external;

    function isApproved(uint256 _strainId) external view returns (bool);

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function _isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function isApprovedOperatorOf(uint256 _strainId)
        external
        view
        returns (bool);

    function _safeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external;

    function _checkERC721Support(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external returns (bool);

    function _isContract(address _to) external view returns (bool);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function _exists(uint256 tokenId) external view returns (bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function _baseURI() external view returns (string memory);

    function setBaseURI(string memory _uri) external;

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

    function strainsOf(address _owner) external view returns (uint256[] memory);

    function randMod() external returns (uint256);

    function createStrain(uint256 _times) external payable;

    function _createStrain(uint256 _times) external;

    function getStrainCount(address _addr)
        external
        view
        returns (uint256 count);

    function genesToNumber(uint256 _dna) external pure returns (uint256);

    function setStakingContract(address _addr) external;

    function updateRarity(uint256 _strainId, uint8 _count) external;

    function upgradeStage(
        uint256 _strainId,
        string memory _tokenURI,
        address _owner
    ) external;

    function calculateRarityScore(uint256 _dna) external;

    function getRarity(uint256 _strainId) external view returns (uint256);

    function getStage(uint256 _strainId) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
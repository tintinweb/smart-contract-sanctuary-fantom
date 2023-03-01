// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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

interface IERC721Ownable {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

interface IERC20Mintable {
    function mint(address to, uint amount) external;
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract NFTStaking is ERC721Holder {

    struct NFTInfo {
        address tokenOwner;
        uint256 stakedStartTime;
        uint256 lastUpdate;
        bool isStaked;
    }

    struct StakingInfo {
        address collectionAddress;
        address rewardTokenAddress;
        address creatorAddress;
        uint256 minStakeSeconds;
        uint256 maxStakeSeconds;
        uint256 cooldownSeconds;
        uint256 timeUnitSeconds;
        uint256 rewardsPerTimeUnit;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    struct CreatorPool {
        uint poolId;
        address collectionAddress;
    }

    struct StakingPool {
        StakingInfo Conditions;
        mapping(uint256 => NFTInfo) stakedNFTs;
        mapping(address => uint256[]) stakedArrays;
    }

    struct Rewards {
        uint NFTId;
        uint rewards;
    }

    uint public poolsCounter;

    address public immutable admin;

    mapping(address => bool) public isPoolExists;

    mapping(address => uint) public createdPools;

    StakingPool[] private _pools;

    constructor() {
        admin = msg.sender;
    }
    
    function initPool(
        address collectionAddress,
        address rewardTokenAddress,
        uint256 minStakeSeconds,
        uint256 maxStakeSeconds,
        uint256 cooldownSeconds,
        uint256 timeUnitSeconds,
        uint256 rewardsPerTimeUnit,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external {
        require(!isPoolExists[collectionAddress], "Collection already exists");

        require(
            IERC165(collectionAddress).supportsInterface(type(IERC721).interfaceId),
            "NFT contract does not supports ERC721 interface"
        );

        require(
            IERC165(rewardTokenAddress).supportsInterface(type(IERC20).interfaceId),
            "Reward token does not supports ERC20 interface"
        );

        // Checks if msg.sender is owner of collection contract
        // /// @dev Calls 'owner()' funtion to check if sender is an owner
        // require(IERC721Ownable(collectionAddress).owner() == msg.sender, "Sender is not an Owner of collection");

        _pools.push();

        StakingInfo memory info = StakingInfo({
            collectionAddress: collectionAddress,
            rewardTokenAddress: rewardTokenAddress,
            creatorAddress: msg.sender,
            minStakeSeconds: minStakeSeconds,
            maxStakeSeconds: maxStakeSeconds,
            cooldownSeconds: cooldownSeconds,
            timeUnitSeconds: timeUnitSeconds,
            rewardsPerTimeUnit: rewardsPerTimeUnit,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp
        });

        _pools[poolsCounter].Conditions = info;

        poolsCounter++;

        isPoolExists[collectionAddress] = true;

        createdPools[msg.sender] = createdPools[msg.sender] + 1;
    }

    /// Стейкает все принадлижащие и заапрувленные токены721
    function stake(uint256 poolId, uint256[] calldata nftIds) external {
        address collection = _pools[poolId].Conditions.collectionAddress;
        require(_pools[poolId].Conditions.startTimestamp < block.timestamp, "Pool has not started yet");
        require(_pools[poolId].Conditions.endTimestamp > block.timestamp, "Pool is passed out");
        
        for(uint i; i < nftIds.length; i++) {
            require(
                _pools[poolId].stakedNFTs[nftIds[i]].lastUpdate < block.timestamp - _pools[poolId].Conditions.cooldownSeconds,
                "Cooldown has not passed out"
            );

            IERC721(collection).safeTransferFrom(msg.sender, address(this), nftIds[i]);

            _pools[poolId].stakedNFTs[nftIds[i]] = NFTInfo({
                tokenOwner: msg.sender,
                stakedStartTime: block.timestamp,
                lastUpdate: block.timestamp,
                isStaked: true
            });

            _pools[poolId].stakedArrays[msg.sender].push(nftIds[i]);
        }
    }

    /// Переводит все награды за все токены721
    function claimRewards(uint256 poolId) external {
        uint[] memory stakedNFTs = _pools[poolId].stakedArrays[msg.sender];

        require(stakedNFTs.length > 0, "No NFTs were staked");

        uint rewards;

        StakingInfo memory conditions = _pools[poolId].Conditions;

        for(uint i; i < stakedNFTs.length; i++) {

            /// @dev If duration is more then 'maxStakeSeconds' then it equas to it
            uint duration;
            duration < conditions.maxStakeSeconds ? duration = block.timestamp - _pools[poolId].stakedNFTs[stakedNFTs[i]].lastUpdate : duration = conditions.maxStakeSeconds;

            uint accumulatedTimeUnits = duration / conditions.minStakeSeconds;

            rewards += accumulatedTimeUnits * conditions.rewardsPerTimeUnit;

            _pools[poolId].stakedNFTs[stakedNFTs[i]].lastUpdate = block.timestamp;
            _pools[poolId].stakedNFTs[stakedNFTs[i]].stakedStartTime = block.timestamp;
        }

        /// @dev Transfers mints tokens to staker
        IERC20Mintable(conditions.rewardTokenAddress).mint(msg.sender, rewards);
    }

    /// Возвращает токены721 по id его владельцу
    function unstake(uint256 poolId, uint256[] calldata nftIds) external {
        uint[] storage stakedArray = _pools[poolId].stakedArrays[msg.sender];

        for(uint i; i < nftIds.length; i++) {   
            require(_pools[poolId].stakedNFTs[nftIds[i]].tokenOwner == msg.sender, "Sender is not owner of nft id");
            require(_pools[poolId].stakedNFTs[nftIds[i]].isStaked, "NFT is not staked");

            IERC721(_pools[poolId].Conditions.collectionAddress).safeTransferFrom(address(this), msg.sender, nftIds[i]);

            _pools[poolId].stakedNFTs[nftIds[i]] = NFTInfo({
                tokenOwner: address(0),
                stakedStartTime: 0,
                lastUpdate: block.timestamp,
                isStaked: false
            });
            
            /// @dev Finds nft id at Sender`s 'stakedArrays' rewrites it and deletes id from array
            for(uint j; j < stakedArray.length; j++) {
                if(stakedArray[j] == nftIds[i]) {
                    for(uint y = j; y < stakedArray.length - 1; y++) {
                        stakedArray[y] = stakedArray[y+1];
                    }
                    stakedArray.pop();
                    break;
                }
            }
        }
    }

    /// Возвращает условия стейкинга пула для коллекции, см. StakingInfo
    function getPoolInfo(uint256 index) external view returns(StakingInfo memory) {
        return _pools[index].Conditions;
    }

    function getPoolsByCreator(address creator) external view returns(CreatorPool[] memory) {
        CreatorPool[] memory createdPoolz = new CreatorPool[](createdPools[creator]);
        uint j;

        for(uint i; i < _pools.length; i++) {
            if(_pools[i].Conditions.creatorAddress == creator) {
                createdPoolz[j].poolId = i;
                createdPoolz[j].collectionAddress = _pools[i].Conditions.collectionAddress;
                j++;
            }
        }

        return createdPoolz;
    }

    function getAllPools(uint offset, uint limit) external view returns(StakingInfo[] memory) {
        require(offset <= poolsCounter, "Offset must be less then _pools length");
        require(offset + limit <= poolsCounter, "Offset + limil must be less then _pools length");
        StakingInfo[] memory pools = new StakingInfo[](limit);
        for(uint i; offset < limit; i++) {
            pools[offset] = _pools[offset].Conditions;
            offset++;
        }
        return pools;
    }

    /// Возварщает массив из id токенов721 принадлижащих staker, а так же общее кол-во наград за все токены 
    /// Переделать на offset and limit
    /// Массив из структуры: id, reward, tokenURI
    function getStakeInfo(uint256 poolId, address staker, uint start, uint end) external view returns(Rewards[] memory) {
        require(end > start, "'end' must be above 'start'");
        StakingInfo memory conditions = _pools[poolId].Conditions;

        Rewards[] memory rewards = new Rewards[](_pools[poolId].stakedArrays[staker].length);
        uint i;

        for( ; start < end; start++) {
            rewards[i].NFTId = _pools[poolId].stakedArrays[staker][start];

            uint duration;
            duration < conditions.maxStakeSeconds ? duration = block.timestamp - _pools[poolId].stakedNFTs[rewards[i].NFTId].stakedStartTime : duration = conditions.maxStakeSeconds;

            uint accumulatedTimeUnits = duration / conditions.minStakeSeconds;

            rewards[i].rewards = accumulatedTimeUnits * conditions.rewardsPerTimeUnit;
        }

        return rewards;
    }

    function getNFTStakedLength(uint256 poolId, address staker) external view returns(uint) {
        return _pools[poolId].stakedArrays[staker].length;
    }

    /// Считает награду для одного токена721, владелец токена в NFTinfo.tokenOwner
    function calculateReward(uint256 poolId, uint nftId) public view returns(uint256 reward) {
        require(_pools[poolId].stakedNFTs[nftId].isStaked, "NFT is not staked in pool");
        StakingInfo memory conditions = _pools[poolId].Conditions;

        uint duration = block.timestamp - _pools[poolId].stakedNFTs[nftId].stakedStartTime;

        if(duration > conditions.maxStakeSeconds) duration = conditions.maxStakeSeconds;

        uint accumulatedTimeUnits = duration / conditions.minStakeSeconds;

        reward = accumulatedTimeUnits * conditions.rewardsPerTimeUnit;
    }

    function removePool(uint poolId) external {
        require(msg.sender == _pools[poolId].Conditions.creatorAddress, "Sender is not pool creator");

        delete _pools[poolId];
    }

    function insertPool(
        uint poolId,
        address collectionAddress,
        address rewardTokenAddress,
        address creatorAddress,
        uint256 minStakeSeconds,
        uint256 maxStakeSeconds,
        uint256 cooldownSeconds,
        uint256 timeUnitSeconds,
        uint256 rewardsPerTimeUnit,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external {
        require(msg.sender == admin, "Sender is not admin");

        StakingInfo memory info = StakingInfo({
            collectionAddress: collectionAddress,
            rewardTokenAddress: rewardTokenAddress,
            creatorAddress: creatorAddress,
            minStakeSeconds: minStakeSeconds,
            maxStakeSeconds: maxStakeSeconds,
            cooldownSeconds: cooldownSeconds,
            timeUnitSeconds: timeUnitSeconds,
            rewardsPerTimeUnit: rewardsPerTimeUnit,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp
        });

        _pools[poolId].Conditions = info;
    }

    /// Возвращает инфу токена721, см NFTinfo
    function getNFTInfo(uint256 poolId, uint nftId) external view returns(NFTInfo memory) {
        return _pools[poolId].stakedNFTs[nftId];
    }

    function timestamp() external view returns(uint) {
        return block.timestamp;
    }
}
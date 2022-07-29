// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "./interfaces/IAceLabV1.sol";
import "./interfaces/IAceLabV2.sol";
import "./interfaces/IMagicatName.sol";

contract AceLabFetchHelper {
  IERC20 public xBOO = IERC20(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598);
  IAceLabV1 public aceLabV1 = IAceLabV1(0x2352b745561e7e6FCD03c093cE7220e3e126ace0);
  IAceLabV2 public aceLabV2 = IAceLabV2(0xCd4d3D744c3AB0BD528dbd330839537f996BE71A);
  IAceLabV2 public aceLabV3 = IAceLabV2(0x399D73bB7c83a011cD85DF2a3CdF997ED3B3439f);
  IMagicatName public magicatName = IMagicatName(0xCB7a4094db0bbF87c4D9AAc151Cb3731145e16D6);
  IMagicatName public magicatImage = IMagicatName(0x897dd222CffCe3ba2F3381f23Af2c594C468dE1f);

  mapping(uint256 => address) public acelabs;

  constructor() {
    acelabs[1] = address(aceLabV1);
    acelabs[2] = address(aceLabV2);
    acelabs[3] = address(aceLabV3);
  }

  function fetchPoolData (uint256 pid, uint256 version) public view returns (
    uint256 xBooStaked,
    uint256 startTime,
    uint256 endTime,
    uint256 rewardPerSecond,
    uint256 mpStaked,
    uint256 catRewardPerSecond
  ) {

    // AceLabV1
    if (version == 1) {
      (,rewardPerSecond,,xBooStaked,,,endTime,startTime,,) = aceLabV1.poolInfo(pid);
      mpStaked = 0;
      catRewardPerSecond = 0;
    }

    // AceLabV2, includes catstaking
    if (version == 2 || version == 3) {
      IAceLabV2 versionedAceLab = IAceLabV2(acelabs[version]);
      uint256 rewardPerSecondRaw;
      uint256 magicatBoost = versionedAceLab.magicatBoost();
      (,,,xBooStaked,mpStaked,rewardPerSecondRaw,,,,,endTime,startTime) = versionedAceLab.poolInfo(pid);
      rewardPerSecond = rewardPerSecondRaw * (10000 - magicatBoost) / 10000;
      catRewardPerSecond = rewardPerSecondRaw * magicatBoost / 10000;
    }
  }

  function fetchUserPoolData (address user, uint256 pid, uint256 version) public view returns (
    uint256 allowance,
    uint256 balance,
    uint256 staked,
    uint256 earnings,

    bool magicatsApproved,
    uint256 mpStaked,
    uint256[] memory stakedMagicats,
    uint256 currentStakeableMP,
    uint256 baseStakeableMP
  ) {

    // Shared
    allowance = xBOO.allowance(user, acelabs[version]);
    balance = xBOO.balanceOf(user);

    // AceLab V1
    if (version == 1) {
      (staked,) = aceLabV1.userInfo(pid, user);
      earnings = aceLabV1.pendingReward(pid, user);
    }

    // AceLabV2, includes catstaking
    if (version == 2 || version == 3) {
      IAceLabV2 versionedAceLab = IAceLabV2(acelabs[version]);
      magicatsApproved = versionedAceLab.magicat().isApprovedForAll(user, address(versionedAceLab));

      (staked,,, mpStaked) = versionedAceLab.userInfo(pid, user);
      earnings = versionedAceLab.pendingReward(pid, user);
      stakedMagicats = versionedAceLab.getStakedMagicats(pid, user);
      currentStakeableMP = versionedAceLab.stakeableMP(pid, user);
      baseStakeableMP = versionedAceLab.stakeableMP(1e18);
    }
  }

  struct CatStakeData {
    uint256 sousId;
    uint256 version;
  }
  struct CatData {
    uint256 id;
    uint256 mp;
    string name;
    string image;
    CatStakeData staked;
  }

  function fetchMagicatData (uint256 catId, uint256 pid, uint256 version) public view returns (
    CatData memory cat
  ) {
    cat = CatData({
      id: catId,
      mp: aceLabV3.rarityOf(catId),
      name: magicatName.nameOf(catId),
      image: magicatImage.nameOf(catId),
      staked: CatStakeData({
        sousId: pid,
        version: version
      })
    });
  }

  function fetchUserMagicatsStakedInPool (address user, uint256 pid, uint256 version) public view returns (
    CatData[] memory cats
  ) {
    if (version == 1) return cats;
    uint256[] memory catIds = IAceLabV2(acelabs[version]).getStakedMagicats(pid, user);
    cats = new CatData[](catIds.length);
    for (uint256 i = 0; i < catIds.length; i++) {
      cats[i] = fetchMagicatData(catIds[i], pid, version);
    }
  }

  struct PoolCats {
    uint256 pid;
    uint256 version;
    CatData[] cats;
  }

  function fetchUserMagicatData (address user) public view returns (
    CatData[] memory cats
  ) {
    // Owned cats count
    uint256[] memory ownedCatIds = aceLabV2.magicat().walletOfOwner(user);
    uint256 totalStakedCatsCount = ownedCatIds.length;

    // Fetch staked cats from all pools
    uint256 v2PoolsCount = aceLabV2.poolLength();
    uint256 v3PoolsCount = aceLabV3.poolLength();
    PoolCats[] memory stakedCats = new PoolCats[](v2PoolsCount + v3PoolsCount);
    // acelabv2 pools
    for (uint256 pid = 0; pid < v2PoolsCount; pid++) {
      stakedCats[pid] = PoolCats({
        pid: pid,
        version: 2,
        cats: fetchUserMagicatsStakedInPool(user, pid, 2)
      });
      totalStakedCatsCount += stakedCats[pid].cats.length;
    }
    // acelabv3 pools
    for (uint256 pid = 0; pid < v3PoolsCount; pid++) {
      stakedCats[pid + v2PoolsCount] = PoolCats({
        pid: pid,
        version: 3,
        cats: fetchUserMagicatsStakedInPool(user, pid, 3)
      });
      totalStakedCatsCount += stakedCats[pid].cats.length;
    }

    // POPULATE FINAL ARRAY

    // Owned but not staked cats
    cats = new CatData[](totalStakedCatsCount);
    for (uint256 i = 0; i < ownedCatIds.length; i++) {
      cats[i] = fetchMagicatData(ownedCatIds[i], 0, 0);
    }
    uint256 runningIndex = ownedCatIds.length;

    // Staked cats
    for (uint256 pid = 0; pid < (v2PoolsCount + v3PoolsCount); pid++) {
      if (stakedCats[pid].cats.length == 0) continue;
      for (uint256 catIndex = 0; catIndex < stakedCats[pid].cats.length; catIndex++) {
        cats[runningIndex] = stakedCats[pid].cats[catIndex];
        runningIndex++;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
interface IAceLabV1 {
  function userInfo(uint pid, address user) external view returns (
    uint256 amount,
    uint256 rewardDebt
  );
  function poolInfo(uint pid) external view returns (
      IERC20 RewardToken,
      uint256 RewardPerSecond,
      uint256 TokenPrecision,
      uint256 xBooStakedAmount,
      uint256 lastRewardTime,
      uint256 accRewardPerShare,
      uint256 endTime,
      uint256 startTime,
      uint256 userLimitEndTime,
      address protocolOwnerAddress
  );
  function pendingReward(uint pid, address user) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "./IMagicat.sol";

interface IAceLabV2 {
  function magicat() external view returns (IMagicat);
  function poolLength() external view returns (uint256);
  function userInfo(uint pid, address user) external view returns (
    uint amount,
    uint rewardDebt,
    uint catDebt,
    uint mp
  );
  function poolInfo(uint pid) external view returns (
    IERC20 RewardToken,
    uint32 userLimitEndTime,
    uint8 TokenPrecision,
    uint xBooStakedAmount,
    uint mpStakedAmount,
    uint RewardPerSecond,
    uint accRewardPerShare,
    uint accRewardPerShareMagicat,
    address protocolOwnerAddress,
    uint32 lastRewardTime,
    uint32 endTime,
    uint32 startTime
  );
  function pendingReward(uint pid, address user) external view returns (uint);
  function magicatBoost() external view returns (uint);
  function getStakedMagicats(uint pid, address user) external view returns (uint[] memory);
  function stakeableMP(uint pid, address user) external view returns (uint);
  function stakeableMP(uint xBooAmount) external view returns (uint);
  function rarityOf(uint256 catId) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMagicatName {
  function nameOf(uint256 catId) external view returns (string memory catName);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMagicat is IERC721 {
  function totalSupply() external view returns (uint256);
  function walletOfOwner(address user) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
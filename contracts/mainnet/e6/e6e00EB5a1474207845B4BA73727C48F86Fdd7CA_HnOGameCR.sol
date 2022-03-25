// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IHideout.sol";
import "./interfaces/ITraits.sol";
import "./interfaces/IGem.sol";
import "./interfaces/IHnO.sol";
import "./interfaces/ITemple.sol";
import "./interfaces/IRandomizer.sol";


contract HnOGameCR is Ownable, ReentrancyGuard, Pausable {
  using SafeERC20 for IERC20;

  event MintCommitted(address indexed owner, uint256 indexed amount);
  event MintRevealed(address indexed owner, uint256 indexed amount);

  struct MintCommit {
    bool stake;
    uint256 amount;
    bool paid;
  }

  struct WhitelistPoint {
    uint256 limit;
    uint256 minted;
  }

  uint256 public treasureChestTypeId;
  // max $GEM cost 
  uint256 private maxGemCost = 270 ether;

  // address -> commit # -> commits
  mapping(address => mapping(uint256 => MintCommit)) private _mintCommits;
  // address -> commit num of commit need revealed for account
  mapping(address => uint256) private _pendingRandomRound;
  uint256 private pendingMintAmt;

  // address => can call addCommitRandom
  mapping(address => bool) private admins;

  // reference to the Hideout for choosing random Owl thieves
  IHideout public hideout;
  // reference to $GEM for burning on mint
  IGem public gemToken;
  // reference to Traits
  ITraits public traits;
  // reference to NFT collection
  IHnO public hnoNFT;
  // reference to temple collection
  ITemple public temple;
  IRandomizer public randomizer;

  address public ham;
  address public wftm;
  mapping(address => WhitelistPoint) public whitelist;
  bool public whitelistEnabled = true;

  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
    address zero = address(0);
    require(
      address(gemToken) != zero
      && address(traits) != zero
      && address(hnoNFT) != zero
      && address(hideout) != zero
      && address(temple) != zero
      && address(randomizer) != zero
      && ham != zero
      && wftm != zero,
      "Contracts not set"
    );
    _;
  }

  function setContracts(
    address _gem,
    address _traits,
    address _hno,
    address _hideout,
    address _temple,
    address _randomizer,
    address _ham,
    address _wftm
  ) external onlyOwner {
    address zero = address(0);
    require(_gem != zero, "GEM is zero address");
    require(_traits != zero, "Traits is zero address");
    require(_hno != zero, "HNO is zero address");
    require(_hideout != zero, "Hideout is zero address");
    require(_temple != zero, "Temple is zero address");
    require(_randomizer != zero, "Randomizer is zero address");
    require(_ham != zero, "HAM is zero address");
    require(_wftm != zero, "WFTM is zero address");
    gemToken = IGem(_gem);
    traits = ITraits(_traits);
    hnoNFT = IHnO(_hno);
    hideout = IHideout(_hideout);
    temple = ITemple(_temple);
    randomizer = IRandomizer(_randomizer);
    ham = _ham;
    wftm = _wftm;
  }

  function toggleWhitelist() external onlyOwner {
    whitelistEnabled = !whitelistEnabled;
  }

  function updateWhitelsit(address[] memory accounts, uint256[] memory limits) external onlyOwner {
    uint256 len = accounts.length;
    require(accounts.length == limits.length, "Incorrect params arrays length");
    for (uint256 i = 0; i < len; i++) {
      whitelist[accounts[i]].limit = limits[i];
    }
  }

  function withdrawFee(address token, address to, uint256 amount) external onlyOwner {
    require(token == ham || token == wftm, "Invalid token address");
    require(to != address(0), "Invalid to address");
    require(amount > 0, "Amount is 0");
    IERC20 token_ = IERC20(token);
    require(token_.balanceOf(address(this)) >= amount, "Fee not enough");
    token_.safeTransfer(to, amount);
  }

  /** EXTERNAL */

  function getPendingRandomRound(address addr) external view returns (uint256) {
    return _pendingRandomRound[addr];
  }

  function getPendingMint(address addr) external view returns (MintCommit memory) {
    require(_pendingRandomRound[addr] != 0, "no pending commits");
    return _mintCommits[addr][_pendingRandomRound[addr]];
  }

  function hasMintPending(address addr) external view returns (bool) {
    return _pendingRandomRound[addr] != 0;
  }

  function canReveal(address addr) external view returns (bool) {
    return _pendingRandomRound[addr] != 0 && randomizer.isRandomReady(_pendingRandomRound[addr]);
  }

  function deleteCommit(address addr) external {
    address caller = _msgSender();
    require(owner() == caller || admins[caller], "Only admins can call this");
    uint256 commitIdCur = _pendingRandomRound[addr];
    require(commitIdCur > 0, "No pending commit");
    delete _mintCommits[addr][commitIdCur];
    delete _pendingRandomRound[addr];
  }

  function forceRevealCommit(address addr) external {
    address caller = _msgSender();
    require(owner() == caller || admins[caller], "Only admins can call this");
    reveal(addr);
  }

  /** Initiate the start of a mint. This action burns $GEM, as the intent of committing is that you cannot back out once you've started.
    * This will add users into the pending queue, to be revealed after a random seed is generated and assigned to the commit id this
    * commit was added to. */
  function mintCommit(uint256 amount, bool stake) external whenNotPaused nonReentrant {
    address caller = _msgSender();
    require(tx.origin == caller, "Only EOA");
    require(_pendingRandomRound[caller] == 0, "Already have pending mints");
    uint256 minted = hnoNFT.minted();
    uint256 maxTokens = hnoNFT.getMaxTokens();
    require(minted + pendingMintAmt + amount <= maxTokens, "All tokens minted");
    require(amount > 0 && amount <= 10, "Invalid mint amount");
    bool paid = false;
    if (minted <= 4000) {
      if (minted <= 2500 && whitelistEnabled) {
        WhitelistPoint storage wp = whitelist[caller];
        require(wp.limit - wp.minted >= amount, "Whitelist limit reached");
        wp.minted += amount;
      }
      _payToken(caller, minted, amount);
      paid = true;
    }
    else _payGem(caller, minted, amount);
    uint16 amt = uint16(amount);
    if (!randomizer.nextRoundRequired()) randomizer.requireNextRound();
    uint256 pendingRound = randomizer.nextRound();
    _mintCommits[caller][pendingRound] = MintCommit(stake, amt, paid);
    _pendingRandomRound[caller] = pendingRound;
    pendingMintAmt += amt;
    emit MintCommitted(caller, amount);
  }

  function _payToken(address caller, uint256 minted, uint256 amount) internal {
    IERC20(paymentToken()).safeTransferFrom(caller, address(this), amount * mintCost(minted + pendingMintAmt + 1));
  }

  function _payGem(address caller, uint256 minted, uint256 amount) internal {
    uint256 totalGemCost = 0;
    for (uint256 i = 1; i <= amount; i++) totalGemCost += mintCost(minted + pendingMintAmt + i);
    if (totalGemCost > 0) {
      gemToken.burn(caller, totalGemCost);
      gemToken.updateOriginAccess();
    }
  }

  /** Reveal the commits for this user. This will be when the user gets their NFT, and can only be done when the commit id that
    * the user is pending for has been assigned a random seed. */
  function mintReveal() external whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), "Only EOA1");
    reveal(_msgSender());
  }

  function reveal(address addr) internal {
    address hideout_ = address(hideout);
    uint256 randomRound = _pendingRandomRound[addr];
    require(randomRound > 0, "No pending commit");
    require(randomizer.isRandomReady(randomRound), "Random not ready");
    uint256 minted = hnoNFT.minted();
    MintCommit memory commit = _mintCommits[addr][randomRound];
    pendingMintAmt -= commit.amount;
    uint256[] memory tokenIds = new uint256[](commit.amount);
    uint256 seed = randomizer.random(randomRound);
    for (uint256 k = 0; k < commit.amount; k++) {
      // scramble the random so the steal / treasure mechanic are different per mint
      seed = uint256(keccak256(abi.encode(seed, addr)));
      minted++;
      if (commit.paid) {
        address recipient = commit.stake ? hideout_ : addr;
        hnoNFT.mint(recipient, seed, false, 0);
        tokenIds[k] = minted;
      } else {
        bool savedByChest = false;
        (address recipient, uint256 stolenById) = selectRecipient(seed);
        if (recipient != addr && temple.balanceOf(addr, treasureChestTypeId) > 0) {
          // If the mint is going to be stolen, there's a 50% chance 
          //  a owl will prefer a treasure chest over it
          if (seed & 1 == 1) {
            temple.safeTransferFrom(addr, recipient, treasureChestTypeId, 1, "");
            savedByChest = true;
            recipient = addr;
          }
        }
        tokenIds[k] = minted;
        if (!commit.stake || recipient != addr) hnoNFT.mint(recipient, seed, savedByChest, stolenById);
        else hnoNFT.mint(hideout_, seed, savedByChest, stolenById);
      }
    }
    hnoNFT.updateOriginAccess(tokenIds);
    if (commit.stake) hideout.addManyToHideoutAndFlight(addr, tokenIds);
    delete _mintCommits[addr][randomRound];
    delete _pendingRandomRound[addr];
    emit MintRevealed(addr, tokenIds.length);
  }

  function paymentToken() public view returns (address) {
    uint256 minted = hnoNFT.minted();
    if (minted <= 2500) return ham;
    if (minted <= 4000) return wftm;
    return address(gemToken);
  }

  /** 
   * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
  function mintCost(uint256 tokenId) public view returns (uint256) {
    if (tokenId <= 2500) return 75 ether;
    if (tokenId <= 4000) return 85 ether;
    if (tokenId <= 10000) return 180 ether;
    if (tokenId <= 18000) return 240 ether;
    if (tokenId <= 27000) return 255 ether;
    return maxGemCost;
  }

  function payTithe(uint256 gemAmt) external whenNotPaused nonReentrant {
    address caller = _msgSender();
    require(tx.origin == caller, "Only EOA");
    uint256 minted = hnoNFT.minted();
    uint256 gemMintCost = mintCost(minted);
    require(gemMintCost > 0, "Temple currently closed");
    require(gemAmt >= gemMintCost, "Not enough gem given");
    gemToken.burn(caller, gemAmt);
    if (gemAmt < gemMintCost * 2) temple.mint(1, 1, caller);
    else temple.mint(2, 1, caller);
  }

  function makeTreasureChests(uint16 qty) external whenNotPaused {
    require(tx.origin == _msgSender(), "Only EOA");
    require(treasureChestTypeId > 0, "DEVS DO SOMETHING");
    // $GEM exchange amount handled within temple contract
    // Will fail if sender doesn't have enough $GEM
    // Transfer does not need approved,
    //  as there is established trust between this contract and the temple contract 
    temple.mint(treasureChestTypeId, qty, _msgSender());
  }

  function sellTreasureChests(uint16 qty) external whenNotPaused {
    require(tx.origin == _msgSender(), "Only EOA");
    require(treasureChestTypeId > 0, "DEVS DO SOMETHING");
    // $GEM exchange amount handled within temple contract
    temple.burn(treasureChestTypeId, qty, _msgSender());
  }

  function sacrifice(uint256 tokenId, uint256 gemAmt) external whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), "Only EOA");
    uint256 lastTokenWrite = hnoNFT.getTokenWriteBlock(tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, "hmmmm what doing?");
    IHnO.HamsterOwl memory nft = hnoNFT.getTokenTraits(tokenId);
    uint256 minted = hnoNFT.minted();
    uint256 gemMintCost = mintCost(minted);
    require(gemMintCost > 0, "Temple currently closed");
    if (nft.isHamster) {
      // Hamster sacrifice requires 3x $GEM curve
      require(gemAmt >= gemMintCost * 3, "not enough gem provided");
      gemToken.burn(_msgSender(), gemAmt);
      // This will check if origin is the owner of the token
      hnoNFT.burn(tokenId);
      temple.mint(3, 1, _msgSender());
    }
    else {
      // Owl sacrifice requires 4x $GEM curve
      require(gemAmt >= gemMintCost * 4, "not enough gem provided");
      gemToken.burn(_msgSender(), gemAmt);
      // This will check if origin is the owner of the token
      hnoNFT.burn(tokenId);
      temple.mint(4, 1, _msgSender());
    }
  }

  /** INTERNAL */

  /**
   * the first 25% (ETH purchases) go to the minter
   * the remaining 80% have a 10% chance to be given to a random staked owl
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Owl thief's owner)
   */
  function selectRecipient(uint256 seed) internal view returns (address, uint256) {
    if (((seed >> 245) % 10) != 0) return (_msgSender(), 0); // top 10 bits haven't been used
    (address thief, uint256 tokenId) = hideout.randomOwlOwner(seed >> 144); // 144 bits reserved for trait selection
    if (thief == address(0)) return (_msgSender(), 0);
    return (thief, tokenId);
  }

  /** ADMIN */

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function setMaxGemCost(uint256 _amount) external requireContractsSet onlyOwner {
    maxGemCost = _amount;
  } 

  function setTreasureChestId(uint256 typeId) external onlyOwner {
    treasureChestTypeId = typeId;
  }

  /** Allow the contract owner to set the pending mint amount.
    * This allows any long-standing pending commits to be overwritten, say for instance if the max supply has been 
    *  reached but there are many stale pending commits, it could be used to free up those spaces if needed/desired by the community.
    * This function should not be called lightly, this will have negative consequences on the game. */
  function setPendingMintAmt(uint256 pendingAmt) external onlyOwner {
    pendingMintAmt = uint16(pendingAmt);
  }

  /**
  * enables an address to mint / burn
  * @param addr the address to enable
  */
  function addAdmin(address addr) external onlyOwner {
      admins[addr] = true;
  }

  /**
  * disables an address from minting / burning
  * @param addr the address to disbale
  */
  function removeAdmin(address addr) external onlyOwner {
      admins[addr] = false;
  }

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


interface ITemple {
    function mint(uint256 typeId, uint256 qty, address recipient) external;
    function burn(uint256 typeId, uint256 qty, address burnFrom) external;
    function updateOriginAccess() external;
    function balanceOf(address account, uint256 id) external returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


interface IRandomizer {
  enum Status {
    NOT_ACTIVE,
    ACTIVE,
    FINISHED,
    RELEASED
  }

  struct Round {
    uint256 startAt;
    uint256 endsAt;
    bytes32 hashSeed;
    string seed;
    uint256 blockNumber;
    bytes32 blockHash;
    uint256 random;
    Status status;
  }

  function canFinishRound() external view returns (bool);
  function currentRound() external view returns (uint256);
  function delay() external view returns (uint256);
  function nextRound() external view returns (uint256);
  function nextRoundRequired() external view returns (bool);
  function roundMinDuration() external view returns (uint256);
  function canFinishRound(uint256 roundNumber_) external view returns (bool);
  function isRandomReady(uint256 roundNumber_) external view returns (bool);
  function random(uint256 roundNumber_) external view returns (uint256);
  function round(uint256 roundNumber_) external view returns (Round memory);

  function requireNextRound() external returns (bool);

  event BlockHashSaved(uint256 round_, bytes32 blockHash_, address indexed caller);
  event DelayUpdated(uint256 delay_);
  event RandomReleased(
    uint256 round_,
    uint256 random_,
    address indexed caller
  );
  event RoundMinDurationUpdated(uint256 roundMinDuration_);
  event RoundFinished(uint256 round_, string seed_, address indexed caller);
  event RoundRequired(uint256 round_);
  event RoundRestarted(uint256 indexed round_, bytes32 hashSeed_, uint256 blockNumber_, address indexed caller);
  event RoundStarted(uint256 round_, bytes32 hashSeed_, uint256 blockNumber_, address indexed caller);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


interface IHnO is IERC721Enumerable {
    struct HamsterOwl {
        bool isHamster;
        uint256 body;
        uint256 head;
        uint256 spell;
        uint256 eyes;
        uint256 neck;
        uint256 mouth;
        uint256 wand;
        uint256 tail;
        uint256 rankIndex;
    }

    function minted() external view returns (uint256);
    function updateOriginAccess(uint256[] memory tokenIds) external;
    function mint(address recipient, uint256 seed, bool savedByChest, uint256 stolenById) external;
    function burn(uint256 tokenId) external;
    function getMaxTokens() external view returns (uint256);
    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (HamsterOwl memory);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint256);
    function isHamster(uint256 tokenId) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


interface IHideout {
  function addManyToHideoutAndFlight(address account, uint256[] memory tokenIds) external;
  function randomOwlOwner(uint256 seed) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


interface IGem {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
/**
 *Submitted for verification at FtmScan.com on 2022-03-12
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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
     * by making the `nonReentrant` function external, and make it call a
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

// File: @openzeppelin/contracts/utils/Address.sol

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
        // solhint-disable-next-line no-inline-assembly
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
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
 * @dev Required interface of an ERC721 compliant contract.
 */interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
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
    function balanceOf(address _owner) external view returns (uint256 balance);

    /*
     * @dev Returns the total number of tokens in circulation.
     */
    function totalSupply() external view returns (uint256 total);

    /*
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory tokenName);

    /*
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory tokenSymbol);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 _tokenId) external view returns (address owner);


     /* @dev Transfers `tokenId` token from `msg.sender` to `to`.
     *
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `to` can not be the contract address.
     * - `tokenId` token must be owned by `msg.sender`.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

interface Diamond {
    function sendDividends(uint256 _amount, bool nftContract) external;
    function dividendTracker() external returns (address);
}

// File: contracts/JackpotLottery.sol

/** @title Jackpot Lottery.
 * @notice It is a contract for a lottery system using
 * randomness provided externally.
 */
contract JackpotLottery is ReentrancyGuard, Ownable {
    enum Status {
        Open,
        Purchased,
        Claimed,
        Delete
    }

    enum UserStatus {
        Open,
        NoRewardToken,
        NoRewardNFT
    }

    struct PoolInfo {
        address nftAddress;
        string name;
    }

    struct User {
        uint256 purchasedIndex;
        uint256 ticketNumber;
        bool winnedByRewardToken;
        bool winnedByNFT;
        UserStatus status;
    }

    struct Reward {
        address nftAddress;
        uint256 tokenId;
        uint256 purchasedTime;
        address buyer;
        Status status;
        int purchasedIndex;
        uint256 rewardTokenAmount;
    }

    struct PurchasedInfo {
        uint8 pool;
        uint256 rewardIndex;
        uint256 rewardTokenAmount;
        address buyer;
        uint256 purchasedTime;
    }

    struct PlayedInfo {
        uint256 winnedCount;
        uint256 claimedCount;
        uint256 playedCount;
    }

    address public diamond;
    
    mapping(address=> User) public userInfo;
    mapping(uint8 => PoolInfo) public nftInfo;
    mapping(uint8 => Reward[]) public rewardInfo;
    mapping(address => mapping(uint256 => bool)) public nftTokenInfo;

    uint256 public currentUserCount;
    PurchasedInfo[] public purchasedInfo;

    address[] private players;
    mapping(address => bool) private isOldPlayer;
    mapping(address=> PlayedInfo) public userPlayedInfo;

    uint256 public cost = 5 ether;
    uint256 public maxClaimableLimitTime = 60 minutes;

    uint256 public totalPlays;
    uint256 private totalSupplyforRewards;
    uint256 private maxLimitofSendDividendTracker = cost * 1 / 10;

    address constant FTM = address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);        // FTM mainnet

    uint256[5] public prizeRewardToken;
    address private rewardToken;

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier notRegisteredNFT(uint8 pool) {
        require(pool > 1 && pool < 10, "Wrong pool index");
        require(nftInfo[pool].nftAddress != address(0), "Not registered NFT");
        _;
    }
    
    event SetNFTAddress(uint8 _number, address _nftAddress);
    event AddNFT(uint8 _number, address _nftAddress, uint256 _amount);
    event BuyTicket(address buyer, uint256 price);
    event ClaimNFT(address _nftAddress, uint256 _tokenId, address newOwner);
    event ClaimRewardToken(uint256 _prizeAmount, address _winner);
    
    constructor(address _diamond) {
        diamond = _diamond;
        rewardToken = FTM;

        prizeRewardToken[0] = 1 ether;
        prizeRewardToken[1] = 5 ether;
        prizeRewardToken[2] = 20 ether;
        prizeRewardToken[3] = 50 ether;
        prizeRewardToken[4] = 500 ether;
    }

    receive() external payable {
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setNFTAddress(uint8 _pool, address _nftAddress) public onlyOwner {
        require(_pool > 1 && _pool < 10, "Wrong pool number");
        require(_nftAddress != address(0), "Wrong NFT address");
        require(_isContract(_nftAddress), "The NFT Address should be a contract");


        nftInfo[_pool] = PoolInfo ({
            nftAddress: _nftAddress,
            name: IERC721(_nftAddress).name()
        });

        emit SetNFTAddress(_pool, _nftAddress);
    }

    function addNFT(uint8 _pool, uint256[] memory _tokenIds) public notRegisteredNFT(_pool) {
        address _nftAddress = nftInfo[_pool].nftAddress;
        IERC721 nftRegistry = _requireERC721(_nftAddress);

        uint256 length = _tokenIds.length;
        for (uint256 i=0; i<length; i++) {
            require(!nftTokenInfo[_nftAddress][_tokenIds[i]], "Token already rewarded");

            address assetOwner = nftRegistry.ownerOf(_tokenIds[i]);
            require(assetOwner == address(this), "Only the asset owner can add assets");

            rewardInfo[_pool].push(Reward({
                nftAddress: _nftAddress,
                tokenId: _tokenIds[i],
                purchasedTime: 0,
                buyer: address(this),
                status: Status.Open,
                purchasedIndex: -1,
                rewardTokenAmount: 0
            }));

            nftTokenInfo[_nftAddress][_tokenIds[i]] = true;
        }
        
        emit AddNFT(_pool, _nftAddress, length);
    }

    function hasNFTforRewards() public view returns (bool) {
        for (uint8 i=2; i<10; i++) {
            (uint256 count, ) = getPurchableRewardInfo(i);
            if (count > 0)
                return true;
        }

        return false;
    }

    function setMaxLimitofSendDividendTracker(uint256 _amount) public onlyOwner {
        maxLimitofSendDividendTracker = _amount;
    }

    function setPrizeRewardToken(uint256[5] memory _prizes) external onlyOwner {
        require(prizeRewardToken.length == _prizes.length, "Wrong prize length.");

        for (uint i=0; i<_prizes.length; i++) {
            prizeRewardToken[i] = _prizes[i];
        }
    }

    function setRewardToken(address _token) external onlyOwner {
        require(_token != address(0), "Wrong reward token address.");
        rewardToken = _token;
    }

    function getBalanceOfRewardToken() public view returns (uint256 _balance) {
        if (rewardToken == FTM)
            return address(this).balance;
        else
            return IERC20(rewardToken).balanceOf(address(this));
    }

    function buyTicket() public payable {
        bool enable = hasNFTforRewards();
        require(enable || getBalanceOfRewardToken() > 0, "No NFT and Token for reward");

        require(msg.value >= cost, "Insufficient value");
        require(userInfo[msg.sender].purchasedIndex == 0, "You have already puchased a NFT.");

        if (!isOldPlayer[msg.sender]) {
            isOldPlayer[msg.sender] = true;
            players.push(msg.sender);
        }

        userPlayedInfo[msg.sender].playedCount++;
        currentUserCount++;
        totalPlays++;

        generateTicketNumber();

        if (totalSupplyforRewards >= maxLimitofSendDividendTracker) {
            sendDividends(totalSupplyforRewards);
            totalSupplyforRewards = 0;
        }

        totalSupplyforRewards += msg.value / 10;

        emit BuyTicket(msg.sender, msg.value);
    }

    /**
     * @notice Send transaction fee to dividend trancer.
     */
    function sendDividends(uint256 _amount) internal {
        address dividendTracker = Diamond(diamond).dividendTracker();

        (bool success,) = address(payable(dividendTracker)).call{value: _amount}("");

        if (success) {
          Diamond(diamond).sendDividends(_amount, false);
        }
    }

    /**
     * @notice Generate tickets number for the current player
     */
    function generateTicketNumber() internal {
        uint256 randomNumber;
        uint8[5] memory ticketNumber;
        
        userInfo[msg.sender].ticketNumber = 0;
        for (uint256 i = 0; i < 5; i++) {
            randomNumber = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, i))) % 9 + 1;
            ticketNumber[i] = uint8(randomNumber);
            userInfo[msg.sender].ticketNumber += randomNumber * 10 ** (5-i-1);
        }

        userInfo[msg.sender].status = UserStatus.Open;

        drawRewards(ticketNumber);
    }

    function drawRewards(uint8[5] memory _ticketNumber) internal {
        (uint8 oneCount, bool nftWinned, uint8 _pool) = getBracketOfMatchingFromTicketNumber(_ticketNumber);

        if (oneCount > 0) {
            procPrizeofRewardToken(oneCount);      
        }
        else {
            updateNFT(_pool);

            if (nftWinned) {
                procPrizeofNFT(_pool);
            }
        }

        if (currentUserCount > 0)
            currentUserCount--;
    }

    /**
     * @notice Calculate the bracket of the ticket number for FTM prize.
     */
    function getBracketOfMatchingFromTicketNumber(uint8[5] memory _ticketNumber)
        internal
        pure
        returns (uint8 count, bool nftWinned, uint8 pool) {
        count = 0;
        nftWinned = true;
        pool = 0;

        for (uint8 i=0; i<5; i++) {
            if (_ticketNumber[i] == 1) {
                count++;
            }
            if (i > 0) {
                if (_ticketNumber[i] != _ticketNumber[i-1])
                    nftWinned = false;
            }
        }

        pool = _ticketNumber[0];    // Any digit in ticketnumber is possible
    }

    function procPrizeofRewardToken(uint8 _index) internal {
        require(prizeRewardToken[_index-1] > 0, "Prize not set");

        if (getBalanceOfRewardToken() < prizeRewardToken[_index-1]) {
            userInfo[msg.sender].status = UserStatus.NoRewardToken;
            return;
        }

        purchasedInfo.push(PurchasedInfo({
            pool: 1,
            rewardIndex: 0,
            rewardTokenAmount: prizeRewardToken[_index-1],
            buyer: msg.sender,
            purchasedTime: block.timestamp
        }));

        userInfo[msg.sender].purchasedIndex = purchasedInfo.length;
        userInfo[msg.sender].winnedByRewardToken = true;
        userPlayedInfo[msg.sender].winnedCount++;
    }

    function procPrizeofNFT(uint8 _pool) internal {
        if (rewardInfo[_pool].length == 0) {
            userInfo[msg.sender].status = UserStatus.NoRewardNFT;
            return;
        }

        (uint256 count, int firstRewardIndex) = getPurchableRewardInfo(_pool);
        if (count == 0) {
            userInfo[msg.sender].status = UserStatus.NoRewardNFT;
            return;
        }

        Reward memory reward = rewardInfo[_pool][uint256(firstRewardIndex)];

        reward.purchasedTime = block.timestamp;
        reward.buyer = msg.sender;
        reward.status = Status.Purchased;
        reward.purchasedIndex = int(purchasedInfo.length);

        rewardInfo[_pool][uint256(firstRewardIndex)] = reward;

        purchasedInfo.push(PurchasedInfo({
            pool: _pool,
            rewardIndex: uint256(firstRewardIndex),
            rewardTokenAmount: 0,
            buyer: msg.sender,
            purchasedTime: block.timestamp
        }));

        userInfo[msg.sender].purchasedIndex = purchasedInfo.length;
        userInfo[msg.sender].winnedByNFT = true;
        userPlayedInfo[msg.sender].winnedCount++;
    }

    function getPurchableRewardInfo(uint8 _pool) public view returns (uint256 count, int firstIndex) {
        require(_pool > 1 && _pool < 10, "Wrong pool index");

        firstIndex = -1;
        
        if (nftInfo[_pool].nftAddress == address(0)) {
            return (0, -1);
        }

        uint256 length = rewardInfo[_pool].length;
        for (uint256 i=0; i<length; i++) {
            if (rewardInfo[_pool][i].status == Status.Open) {
                if (firstIndex < 0)
                    firstIndex = int(i);
                count++;
            }
        }
    }

    function getAllPurchableRewardInfo() public view 
        returns (uint8[] memory index, uint256[] memory count, string[] memory name) {
        uint8 nftCount = 0;
        for (uint8 _pool=2; _pool<10; _pool++) {
            uint256 length = rewardInfo[_pool].length;
            for (uint256 i=0; i<length; i++) {
                if (rewardInfo[_pool][i].status == Status.Open) {
                    nftCount++;
                    break;
                }
            }            
        }

        index = new uint8[](nftCount);
        count = new uint256[](nftCount);
        name = new string[](nftCount);

        uint8 pos;
        uint256 tokenCount;
        for (uint8 _pool=2; _pool<10; _pool++) {
            uint256 length = rewardInfo[_pool].length;
            tokenCount = 0;
            for (uint256 i=0; i<length; i++) {
                if (rewardInfo[_pool][i].status == Status.Open) {
                    tokenCount ++;
                }
            }
            if (tokenCount > 0) {
                index[pos] = _pool;
                count[pos] = tokenCount;
                name[pos] = nftInfo[_pool].name;
                pos ++;
            }
        }
    }

    function getRewardIndex(uint8 _pool, uint256 _tokenId) public view returns (int index) {
        require(_pool > 1 && _pool < 10, "Wrong pool index");

        index = -1;
        
        if (nftInfo[_pool].nftAddress == address(0)) {
            return index;
        }

        uint256 length = rewardInfo[_pool].length;
        for (uint256 i=0; i<length; i++) {
            if (rewardInfo[_pool][i].tokenId == _tokenId)
                return int(i);
        }

        return index;
    }

    function claim() external notContract nonReentrant
    {
        uint256 purchasedIndex = userInfo[msg.sender].purchasedIndex;
        require(purchasedIndex > 0, "No purchased reward");

        if (userInfo[msg.sender].winnedByNFT) {
            uint256 rewardIndex = purchasedInfo[purchasedIndex-1].rewardIndex;
            uint8 winPool = purchasedInfo[purchasedIndex-1].pool;

            Reward memory reward = rewardInfo[winPool][rewardIndex];

            require(reward.buyer == msg.sender, "Unauthorized sender");
            require(reward.status == Status.Purchased, "Wrong purchased");

            // Transfer NFT asset
            IERC721(reward.nftAddress).transferFrom(
                address(this),
                msg.sender,
                reward.tokenId
            );

            rewardInfo[winPool][rewardIndex].status = Status.Claimed;
            rewardInfo[winPool][rewardIndex].purchasedTime = block.timestamp;

            nftTokenInfo[reward.nftAddress][reward.tokenId] = false;

            emit ClaimNFT(reward.nftAddress, reward.tokenId, msg.sender);
        }
        else if (userInfo[msg.sender].winnedByRewardToken) {
            uint256 prizeAmount = purchasedInfo[purchasedIndex-1].rewardTokenAmount;
            require(prizeAmount <= address(this).balance, "Unauthorized sender");

            if (rewardToken == FTM)
                require(payable(msg.sender).send(prizeAmount));
            else
                IERC20(rewardToken).transfer(msg.sender, prizeAmount);

            purchasedInfo[purchasedIndex-1].purchasedTime = block.timestamp;

            emit ClaimRewardToken(prizeAmount, msg.sender);    
        }

        userPlayedInfo[msg.sender].claimedCount += 1;
        delete userInfo[msg.sender];
    }

    function updateNFT(uint8 _pool) internal {
        require(_pool > 1 && _pool < 10, "Wrong pool index");

        if (nftInfo[_pool].nftAddress == address(0))
            return;

        uint256 length = purchasedInfo.length;
        uint256 rewardIndex;

        for (uint256 i=0; i<length; i++) {
            rewardIndex = purchasedInfo[i].rewardIndex;
            Reward memory reward = rewardInfo[_pool][rewardIndex];

            if ((reward.purchasedTime + maxClaimableLimitTime) < block.timestamp 
                    && reward.status == Status.Purchased
                    && reward.buyer != address(this)) {
                if (userInfo[reward.buyer].purchasedIndex > 0) {
                    delete userInfo[reward.buyer];
                }

                reward.buyer = address(this);
                reward.status = Status.Open;

                rewardInfo[_pool][rewardIndex] = reward;
            }
        }
    }

    function setMaxClaimableLimitTime (uint256 _limitTime) public onlyOwner {
        maxClaimableLimitTime = _limitTime;
    }

    /**
     * @notice Get the purchased information of the user.
     */
    function getPurchaedInfo(bool all) public view 
            returns (uint8[] memory pools, Reward[] memory rewards) {
        uint256 length = purchasedInfo.length;
        uint256 rewardIndex;
        if (all) {
            pools = new uint8[](length);
            rewards = new Reward[](length);

            for (uint256 i=0; i<length; i++) {
                pools[i] = purchasedInfo[i].pool;

                if (pools[i] > 1) {
                    rewardIndex = purchasedInfo[i].rewardIndex;
                    rewards[i] = rewardInfo[pools[i]][rewardIndex];
                }
                else if (pools[i] == 1) {
                    rewards[i] = Reward({
                        nftAddress: address(0),
                        tokenId: 0,
                        purchasedTime: purchasedInfo[i].purchasedTime,
                        buyer: purchasedInfo[i].buyer,
                        status: Status.Open,
                        purchasedIndex: 0,
                        rewardTokenAmount: purchasedInfo[i].rewardTokenAmount
                    });
                }
            }
        }
        else {
            uint8 _pool;
            uint256 mylength;

            for (uint256 i=0; i<length; i++) {
                _pool= purchasedInfo[i].pool;
                if (_pool > 1) {
                    rewardIndex = purchasedInfo[i].rewardIndex;
                    Reward memory reward = rewardInfo[_pool][rewardIndex];

                    if (reward.buyer == msg.sender) {
                        mylength ++;
                    }
                }
                else if (_pool == 1) {
                    if (purchasedInfo[i].buyer == msg.sender) {
                        mylength ++;
                    }
                }
            }
            pools = new uint8[](mylength);
            rewards = new Reward[](mylength);

            uint256 index = 0;
            for (uint256 i=0; i<length; i++) {
                _pool= purchasedInfo[i].pool;
                if (_pool > 1) {
                    rewardIndex = purchasedInfo[i].rewardIndex;
                    Reward memory reward = rewardInfo[_pool][rewardIndex];

                    if (reward.buyer == msg.sender) {      
                        pools[index] = _pool;   
                        rewards[index] = reward;
                        index++;
                    }
                }
                else if (_pool == 1) {
                    pools[index] = 1;   
                    rewards[index] = Reward({
                        nftAddress: address(0),
                        tokenId: 0,
                        purchasedTime: purchasedInfo[i].purchasedTime,
                        buyer: purchasedInfo[i].buyer,
                        status: Status.Open,
                        purchasedIndex: 0,
                        rewardTokenAmount: purchasedInfo[i].rewardTokenAmount
                    });
                    index++;                    
                }
            }
        }
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function _requireERC721(address _nftAddress) internal view returns (IERC721) {
        require(_isContract(_nftAddress), "The NFT Address should be a contract");
        // require(
        //     IERC721(_nftAddress).supportsInterface(_INTERFACE_ID_ERC721),
        //     "The NFT contract has an invalid ERC721 implementation"
        // );
        return IERC721(_nftAddress);
    }
     
    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /**
     * @dev It allows the admin to withdraw FTM sent to the contract by the users, 
     * only callable by owner.
     */
    function withdrawFTM(address _to) public onlyOwner {
        require(address(this).balance > 0, "No balance of ETH.");
        require(payable(_to).send(address(this).balance));
    }

    /**
     * @dev It allows the admin to withdraw FTM sent to the contract by the users, 
     * only callable by owner.
     */
    function transferNFT(uint8 _pool, uint256[] memory tokenIds, address _to) 
        public notRegisteredNFT(_pool) onlyOwner {
        require(_to != address(0), "Wrong address");

        address nftAddress = nftInfo[_pool].nftAddress;

        uint256 length = tokenIds.length;
        uint index;
        for (uint i=0; i<length; i++) {
            IERC721(nftAddress).transferFrom(address(this), _to, tokenIds[i]);
            index = uint256(getRewardIndex(_pool, tokenIds[i]));
            rewardInfo[_pool][index].status = Status.Delete;
        }
    }
}
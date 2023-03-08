// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @title SocialRecoveryWallet
 * @notice Social Recovery Wallet that preserves privacy of the Guardian's identities until recovery mode.
 * Idea from https://vitalik.ca/general/2021/01/11/recovery.html
 * Note: This lightweight implementation is designed to support the case of losing the signing private key.
 * In its current design, it is trivial for a compromised (stolen) signing key to drain the wallet.
 * To defend against compromised keys, Vitalik's concept of a vault would need to be layered on top.
 * @author verum
 */
contract Wallet is ReentrancyGuard, IERC721Receiver, IERC1155Receiver {
    /************************************************
     *  STORAGE
     ***********************************************/

    /// @notice true if hash of guardian address, else false
    mapping(bytes32 => bool) public isGuardian;

    /// @notice number of guardians
    uint256 public guardianLength;

    /// @notice stores the guardian threshold
    uint256 public threshold;

    /// @notice owner of the wallet
    address public owner;

    /// @notice true iff wallet is in recovery mode
    bool public inRecovery;

    /// @notice round of recovery we're in
    uint256 public currRecoveryRound;

    /// @notice mapping for bookkeeping when swapping guardians
    mapping(bytes32 => uint256) public guardianHashToRemovalTimestamp;

    /// @notice struct used for bookkeeping during recovery mode
    /// @dev trival struct but can be extended in future (when building for malicious guardians
    /// or when owner key is compromised)
    struct Recovery {
        address proposedOwner;
        uint256 recoveryRound; // recovery round in which this recovery struct was created
        bool usedInExecuteRecovery; // set to true when we see this struct in RecoveryExecute
    }

    struct RecoveryRound {
        uint256 round;
        mapping(address => uint256) guardianVotedLength;
        // bool cancelled;
        // bool executed;
    }

    mapping(uint256 => RecoveryRound) public recoveryRounds;

    /// @notice mapping from guardian address to most recent Recovery struct created by them
    mapping(address => Recovery) public guardianToRecovery;

    /************************************************
     *  MODIFIERS & EVENTS
     ***********************************************/

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier onlyGuardian() {
        require(
            isGuardian[keccak256(abi.encodePacked(msg.sender))],
            "only guardian"
        );
        _;
    }

    modifier notInRecovery() {
        require(!inRecovery, "wallet is in recovery mode");
        _;
    }

    modifier onlyInRecovery() {
        require(inRecovery, "wallet is not in recovery mode");
        _;
    }

    /// @notice emitted when user deposits ETH into wallet
    event Deposit(address indexed from, uint256 value);

    /// @notice emitted when user withdraws ETH from wallet
    event Withdraw(address indexed to, uint256 value);

    /// @notice emitted when an external transaction/transfer is executed
    event TransactionExecuted(
        address indexed callee,
        uint256 value,
        bytes data
    );

    /// @notice emitted when guardian transfers ownership
    event GuardinshipTransferred(
        address indexed from,
        bytes32 indexed newGuardianHash
    );

    /// @notice emit when recovery initiated
    event RecoveryInitiated(
        address indexed by,
        address newProposedOwner,
        uint256 indexed round
    );

    /// @notice emit when recovery supported
    event RecoverySupported(
        address by,
        address newProposedOwner,
        uint256 indexed round
    );

    /// @notice emit when recovery is cancelled
    event RecoveryCancelled(address by, uint256 indexed round);

    /// @notice emit when recovery is executed
    event RecoveryExecuted(
        address oldOwner,
        address newOwner,
        uint256 indexed round
    );

    /// @notice emit when guardian queued for removal
    event GuardianRemovalQueued(bytes32 indexed guardianHash);

    /// @notice emit when guardian removed
    event GuardianChanged(
        bytes32 indexed oldGuardianHash,
        bytes32 indexed newGuardianHash
    );

    /// @notice emit when guardian reveals themselves
    event GuardianRevealed(
        bytes32 indexed guardianHash,
        address indexed guardianAddr
    );

    event GuardianAdded(
        bytes32 indexed guardianHash,
        address indexed guardianAddr
    );

    event GuardianRemoved(bytes32 indexed guardianHash);

    /**
     * @notice Sets guardian hashes and threshold
     * @param guardianAddrHashes - array of guardian address hashes
     * @param _threshold - number of guardians required for guardian duties
     */
    constructor(bytes32[] memory guardianAddrHashes, uint256 _threshold) {
        require(_threshold <= guardianAddrHashes.length, "threshold too high");

        for (uint256 i = 0; i < guardianAddrHashes.length; i++) {
            require(!isGuardian[guardianAddrHashes[i]], "duplicate guardian");
            isGuardian[guardianAddrHashes[i]] = true;
        }

        guardianLength = guardianAddrHashes.length;
        threshold = _threshold;
        owner = msg.sender;
    }

    /// @notice Handles Ether transfer (calldata value is a non-exist function name)
    fallback() external payable {
        // emit Received(msg.sender, msg.value, "Fallback was called");
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Handles Ether transfer (empty calldata)
    receive() external payable {
        // custom function code
        emit Deposit(msg.sender, msg.value);
    }

    /************************************************
     *  Vault Management
     ***********************************************/

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Allows owner to deposit ETH into wallet
     * @dev No needed, as fallback function will handle this
     */
    function deposit() public payable onlyOwner {
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Allows owner to withdraw ETH from wallet
     * @param amount - amount of ETH to withdraw
     */
    function withdraw(uint256 amount) public onlyOwner {
        require(amount <= getBalance(), "not enough balance");
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    /************************************************
     *  Recovery
     ***********************************************/

    /**
     * @notice Allows owner to execute an arbitrary transaction
     * @dev to transfer ETH to an EOA, pass in empty string for data parameter
     * @param callee - contract/EOA to call/transfer to
     * @param value - value to pass to callee from wallet balance
     * @param data - data to pass to callee
     * @return result of the external call
     */
    function executeExternalTx(
        address callee,
        uint256 value,
        bytes memory data
    ) external onlyOwner nonReentrant returns (bytes memory) {
        (bool success, bytes memory result) = callee.call{value: value}(data);
        require(success, "external call reverted");
        emit TransactionExecuted(callee, value, data);
        return result;
    }

    /**
     * @notice Allows a guardian to initiate a wallet recovery
     * Wallet cannot already be in recovery mode
     * @param _proposedOwner - address of the new propsoed owner
     */
    function initiateRecovery(address _proposedOwner)
        external
        onlyGuardian
        notInRecovery
    {
        // we are entering a new recovery round
        currRecoveryRound++;
        guardianToRecovery[msg.sender] = Recovery(
            _proposedOwner,
            currRecoveryRound,
            false
        );
        inRecovery = true;
        recoveryRounds[currRecoveryRound].guardianVotedLength[_proposedOwner]++;
        emit RecoveryInitiated(msg.sender, _proposedOwner, currRecoveryRound);
    }

    /**
     * @notice Allows a guardian to support a wallet recovery
     * Wallet must already be in recovery mode
     * @param _proposedOwner - address of the proposed owner;
     */
    function supportRecovery(address _proposedOwner)
        external
        onlyGuardian
        onlyInRecovery
    {
        guardianToRecovery[msg.sender] = Recovery(
            _proposedOwner,
            currRecoveryRound,
            false
        );
        recoveryRounds[currRecoveryRound].guardianVotedLength[_proposedOwner]++;
        emit RecoverySupported(msg.sender, _proposedOwner, currRecoveryRound);
    }

    /**
     * @notice Allows the owner to cancel a wallet recovery (assuming they recovered private keys)
     * Wallet must already be in recovery mode
     * @dev TODO: allow guardians to cancel recovery
     * (need more than one guardian else trivially easy for one malicious guardian to DoS a wallet recovery)
     */
    function cancelRecovery() external onlyOwner onlyInRecovery {
        inRecovery = false;
        emit RecoveryCancelled(msg.sender, currRecoveryRound);
    }

    /**
     * @notice Allows a guardian to execute a wallet recovery and set a newOwner
     * Wallet must already be in recovery mode
     * @param newOwner - the new owner of the wallet
     * @param guardianList - list of addresses of guardians that have voted for this newOwner
     */
    function executeRecovery(address newOwner, address[] calldata guardianList)
        external
        onlyGuardian
        onlyInRecovery
    {
        // Need enough guardians to agree on same newOwner
        require(
            guardianList.length >= threshold,
            "more guardians required to transfer ownership"
        );

        // Let's verify that all guardians agreed on the same newOwner in the same round
        for (uint256 i = 0; i < guardianList.length; i++) {
            // cache recovery struct in memory
            Recovery memory recovery = guardianToRecovery[guardianList[i]];

            require(
                recovery.recoveryRound == currRecoveryRound,
                "round mismatch"
            );
            require(
                recovery.proposedOwner == newOwner,
                "disagreement on new owner"
            );
            require(
                !recovery.usedInExecuteRecovery,
                "duplicate guardian used in recovery"
            );

            // set field to true in storage, not memory
            guardianToRecovery[guardianList[i]].usedInExecuteRecovery = true;
        }

        inRecovery = false;
        address _oldOwner = owner;
        owner = newOwner;
        emit RecoveryExecuted(_oldOwner, newOwner, currRecoveryRound);
    }

    /**
     * @notice Allows a guardian to execute a wallet recovery and set a newOwner
     * Wallet must already be in recovery mode
     * @dev This is an alternative function for executeRecovery that does not require a list of guardians
     * @param newOwner - the new owner of the wallet
     */
    function executeRecovery(address newOwner)
        external
        onlyGuardian
        onlyInRecovery
    {
        // Need enough guardians to agree on same newOwner
        require(
            recoveryRounds[currRecoveryRound].guardianVotedLength[newOwner] >=
                threshold,
            "more guardians required to transfer ownership"
        );
        // Let's verify that all guardians agreed on the same newOwner in the same round

        inRecovery = false;
        address _oldOwner = owner;
        owner = newOwner;
        emit RecoveryExecuted(_oldOwner, newOwner, currRecoveryRound);
    }

    function getRecoveryRound() external view returns (uint256) {
        return currRecoveryRound;
    }

    function getGuardianRecovery(address guardian)
        external
        view
        returns (
            address,
            uint256,
            bool
        )
    {
        Recovery memory recovery = guardianToRecovery[guardian];
        return (
            recovery.proposedOwner,
            recovery.recoveryRound,
            recovery.usedInExecuteRecovery
        );
    }

    function getNewOwnerVoteCount(
        uint256 recoveryRoundNum,
        address newOwnerAddress
    ) external view returns (uint256) {
        return
            recoveryRounds[recoveryRoundNum].guardianVotedLength[
                newOwnerAddress
            ];
    }

    /************************************************
     *  Guardian Management
     ***********************************************/

    /**
     * @notice Returns the hash of a guardian address
     * @param guardian - address of the guardian
     */
    function getGuardianHash(address guardian) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(guardian));
    }

    /**
     * @notice Allows a guardian to transfer their guardianship
     * Cannot transfer guardianship during recovery mode
     * @param newGuardianHash - hash of the address of the new guardian
     */
    function transferGuardianship(bytes32 newGuardianHash)
        external
        onlyGuardian
        notInRecovery
    {
        // Don't let guardian queued for removal transfer their guardianship
        require(
            guardianHashToRemovalTimestamp[
                keccak256(abi.encodePacked(msg.sender))
            ] == 0,
            "guardian queueud for removal, cannot transfer guardianship"
        );
        isGuardian[keccak256(abi.encodePacked(msg.sender))] = false;
        isGuardian[newGuardianHash] = true;
        emit GuardinshipTransferred(msg.sender, newGuardianHash);
    }

    /**
     * @notice Allows the owner to queue a guardian for removal
     * @param guardianHash - hash of the address of the guardian to queue
     */
    function initiateGuardianRemoval(bytes32 guardianHash) external onlyOwner {
        // verify that the hash actually corresponds to a guardian
        require(isGuardian[guardianHash], "not a guardian");
        require(!inRecovery, "cannot remove guardian during recovery");

        // removal delay fixed at 3 days
        guardianHashToRemovalTimestamp[guardianHash] = block.timestamp + 3 days;
        emit GuardianRemovalQueued(guardianHash);
    }

    /**
     * @notice Allows the owner to remove a guardian
     * Note that the guardian must have been queued for removal prior to invocation of this function
     * @param oldGuardianHash - hash of the address of the guardian to remove
     * @param newGuardianHash - new guardian hash to replace the old guardian
     */
    function executeGuardianRemoval(
        bytes32 oldGuardianHash,
        bytes32 newGuardianHash
    ) external onlyOwner {
        require(
            guardianHashToRemovalTimestamp[oldGuardianHash] > 0,
            "guardian isn't queued for removal"
        );
        require(
            guardianHashToRemovalTimestamp[oldGuardianHash] <= block.timestamp,
            "time delay has not passed"
        );

        // Reset this the removal timestamp
        guardianHashToRemovalTimestamp[oldGuardianHash] = 0;

        isGuardian[oldGuardianHash] = false;
        isGuardian[newGuardianHash] = true;
        emit GuardianChanged(oldGuardianHash, newGuardianHash);
    }

    /**
     * @notice Allows the owner to cancel the removal of a guardian
     * @param guardianHash - hash of the address of the guardian queued for removal
     */
    function cancelGuardianRemoval(bytes32 guardianHash) external onlyOwner {
        guardianHashToRemovalTimestamp[guardianHash] = 0;
    }

    /**
     * @notice Utility function that selectively allows a guardian to reveal their identity
     * If the owner passes away, this can be used for the guardians to find each other and
     * determine a course of action
     */
    function revealGuardianIdentity() external onlyGuardian {
        emit GuardianRevealed(
            keccak256(abi.encodePacked(msg.sender)),
            msg.sender
        );
    }

    /**
     * @notice Allows the owner to add a new guardian
     * @param guardian - address of the new guardian
     */
    function addGuardian(address guardian) external onlyOwner {
        require(!inRecovery, "cannot remove guardian during recovery");
        bytes32 guardianHash = keccak256(abi.encodePacked(guardian));
        isGuardian[guardianHash] = true;
        guardianLength++;
        emit GuardianAdded(guardianHash, guardian);
    }

    /**
     * @notice Allows the owner to remove a guardian
     * @param guardian - address of the guardian to remove
     */
    function removeGuardian(address guardian) external onlyOwner {
        require(!inRecovery, "cannot remove guardian during recovery");
        require(guardianLength - 1 >= threshold, "cannot remove guardian");
        bytes32 guardianHash = keccak256(abi.encodePacked(guardian));
        isGuardian[guardianHash] = false;
        guardianLength--;
        emit GuardianRemoved(guardianHash);
    }

    /************************************************
     *  Receiver Standards
     ***********************************************/

    /**
     * @inheritdoc IERC721Receiver
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @inheritdoc IERC1155Receiver
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @inheritdoc IERC1155Receiver
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Support for EIP 165
     * not really sure if anyone uses this though...
     */
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        if (
            interfaceId == 0x01ffc9a7 || // ERC165 interfaceID
            interfaceId == 0x150b7a02 || // ERC721TokenReceiver interfaceID
            interfaceId == 0x4e2312e0 // ERC1155TokenReceiver interfaceID
        ) {
            return true;
        }
        return false;
    }

    /************************************************
     *  Archival
     ***********************************************/

    // Calling a function that does not exist triggers the fallback function.
    // function transferFTMTo(address payable _addr)
    //     public
    //     payable
    //     onlyOwner
    //     returns (bytes memory)
    // {
    //     (bool success, bytes memory result) = _addr.call{value: msg.value}(
    //         // abi.encodeWithSignature("doesNotExist()")
    //         ""
    //     );
    //     require(success, "external call reverted");
    //     emit TransactionExecuted(_addr, msg.value, "");
    //     return result;
    // }
}
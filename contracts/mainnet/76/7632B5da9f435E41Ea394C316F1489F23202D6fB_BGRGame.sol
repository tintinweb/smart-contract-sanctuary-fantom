/**
 *Submitted for verification at FtmScan.com on 2022-06-11
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File: contracts/libraries/NFTEarlyAccess.sol


pragma solidity ^0.8.1;


library NFTEarlyAccess {
    struct NFTContract {
        address contractAddress;
        uint256 totalSupply;
        string name;
        string symbol;
        bool[] usedTokens;
    }

    struct Data {
        NFTContract[] contracts;
    }

    function setNftContracts(
        Data storage data,
        NFTEarlyAccess.NFTContract[] memory nftContracts_
    ) internal {
        for (uint256 i = 0; i < nftContracts_.length; i++) {
            require(
                nftContracts_[i].contractAddress != address(0),
                "NFT Contract address must be valid"
            );

            require(
                nftContracts_[i].totalSupply > 0,
                "NFT Contract total supply must be greater than zero"
            );

            require(
                bytes(nftContracts_[i].name).length > 0,
                "NFT Contract name must not be empty"
            );

            require(
                bytes(nftContracts_[i].symbol).length > 0,
                "NFT Contract symbol must not be empty"
            );

            data.contracts.push(nftContracts_[i]);
            data.contracts[i].usedTokens = new bool[](
                nftContracts_[i].totalSupply
            );
        }
    }

    function useNft(
        Data storage data,
        address contractAddress,
        uint256 tokenId,
        address sender
    ) internal {
        // Check
        NFTContract storage nftContract = findContract(data, contractAddress);
        require(nftContract.usedTokens.length > tokenId, "Invalid token id");
        require(!nftContract.usedTokens[tokenId], "NFT already used");

        // Effects
        nftContract.usedTokens[tokenId] = true;

        // Interactions
        require(
            IERC721(nftContract.contractAddress).ownerOf(tokenId) == sender,
            "Sender does not currently own the NFT"
        );
    }

    function findContract(Data storage data, address contractAddress)
        private
        view
        returns (NFTContract storage)
    {
        for (uint256 i = 0; i < data.contracts.length; i++) {
            if (contractAddress == data.contracts[i].contractAddress) {
                return data.contracts[i];
            }
        }

        revert("NFT contract not supported for early access");
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/BGRGame.sol


pragma solidity ^0.8.1;



contract BGRGame is Ownable {
    uint256 constant MINIMUM_TRANSITION_TIME = 1 minutes;
    uint256 constant SCORES_LENGTH = 10;
    uint256 constant TOTAL_SQUARES = SCORES_LENGTH * SCORES_LENGTH;
    int16 constant SCORE_UNKNOWN = -1;
    uint16 constant CONTRACT_VERSION = 1;

    enum GameState {
        EarlyAccess,
        DepositsOpen,
        DepositsClosed,
        RevealComplete,
        AllScoresSet,
        ClaimsClosed,
        AllFundsClaimed,
        Cancelled
    }

    struct Team {
        string name;
        string shortName;
    }

    struct Payout {
        string name;
        string shortName;
        uint256 amount;
        address winner;
        int16 awayTeamScore;
        int16 homeTeamScore;
        int16 winningSquare;
    }

    struct RandomGenerator {
        uint256 proof; // Source of true entropy / randomess
        uint256 random; // Pseudo-random number derived from the proof, so randomness is also derived
        uint256 nonce; // Used to avoid re-generating the same string of pseudo-random numbers
    }

    event GameCancelled(uint256 totalSquares, uint256 squarePrice);
    event EnterGame(address indexed player, uint256 squareNumber);
    event FundsClaimed(address indexed recipient, uint256 amount);
    event FinishReveal(uint256 proof);
    event WinningScore(
        address indexed winner,
        uint256 amount,
        uint256 square,
        uint8 scoreA,
        uint8 scoreB
    );
    event RefundSquare(address indexed player, uint8 square, uint256 amount);

    using NFTEarlyAccess for NFTEarlyAccess.Data;
    NFTEarlyAccess.Data private nfts;

    bool public isCancelled;

    string public name;
    Team public awayTeam;
    Team public homeTeam;

    uint8[] public awayTeamNumbers;
    uint8[] public homeTeamNumbers;

    uint256 public earlyAccessEndTime;
    uint256 public gameTime;
    uint256 public claimsEndTime;

    address[TOTAL_SQUARES] public allSquares;
    uint256 public numSquaresSold;

    uint256 public squarePrice;
    uint256 public contractFee; // Paid to the owner upon a completed, not-cancelled game

    Payout[] public payouts;

    // Unclaimed winnings owed to addresses
    // Set during setWinningScores.  Removed during claim;
    mapping(address => uint256) public ledger;

    constructor(
        string memory name_,
        Team memory awayTeam_,
        Team memory homeTeam_,
        uint256 earlyAccessEndTime_,
        uint256 gameTime_,
        uint256 claimsEndTime_,
        uint256 squarePrice_,
        uint256 contractFee_,
        Payout[] memory payouts_,
        NFTEarlyAccess.NFTContract[] memory nftContracts_
    ) {
        setName(name_);
        setAwayTeam(awayTeam_.name, awayTeam_.shortName);
        setHomeTeam(homeTeam_.name, homeTeam_.shortName);

        // Must be set in the following order:
        setEarlyAccessEndTime(earlyAccessEndTime_);
        setGameTime(gameTime_);
        setClaimsEndTime(claimsEndTime_);

        setSquarePrice(squarePrice_);

        uint256 totalPayouts = setPayouts(payouts_);
        contractFee = contractFee_;

        uint256 totalInflows = squarePrice_ * TOTAL_SQUARES;
        uint256 totalOutflows = contractFee_ + totalPayouts;
        require(
            totalInflows == totalOutflows,
            "Contract inflows and outflows are imbalanced"
        );

        nfts.setNftContracts(nftContracts_);
    }

    /**
     * Constructor-only setters
     */

    function setName(string memory name_) private {
        require(bytes(name_).length != 0, "Game name must not be empty");
        name = name_;
    }

    function setAwayTeam(string memory name_, string memory shortName_)
        private
    {
        require(bytes(name_).length != 0, "Away team name must not be empty");
        require(
            bytes(shortName_).length != 0,
            "Away team short name must not be empty"
        );

        awayTeam = Team(name_, shortName_);
    }

    function setHomeTeam(string memory name_, string memory shortName_)
        private
    {
        require(bytes(name_).length != 0, "Home team name must not be empty");

        require(
            bytes(shortName_).length != 0,
            "Home team short name must not be empty"
        );

        homeTeam = Team(name_, shortName_);
    }

    function setSquarePrice(uint256 squarePrice_) private {
        require(squarePrice_ >= .01 ether, "Square price is too low");

        squarePrice = squarePrice_;
    }

    function setEarlyAccessEndTime(uint256 earlyAccessEndTime_) private {
        require(
            earlyAccessEndTime_ > block.timestamp,
            "Early Access End Time Check Failed"
        );

        earlyAccessEndTime = earlyAccessEndTime_;
    }

    function setGameTime(uint256 gameTime_) private {
        require(
            gameTime_ >= earlyAccessEndTime + MINIMUM_TRANSITION_TIME,
            "Deposit End Time Check Failed"
        );

        gameTime = gameTime_;
    }

    function setClaimsEndTime(uint256 claimsEndTime_) private {
        require(
            claimsEndTime_ >= gameTime + MINIMUM_TRANSITION_TIME,
            "Claims End Time Check Failed"
        );

        claimsEndTime = claimsEndTime_;
    }

    function setPayouts(Payout[] memory payouts_) private returns (uint256) {
        require(payouts_.length <= 6, "Too many payouts");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < payouts_.length; i++) {
            require(
                bytes(payouts_[i].name).length > 0,
                "Payout name must not be empty"
            );
            require(
                bytes(payouts_[i].shortName).length > 0,
                "Payout shortName must not be empty"
            );
            require(
                payouts_[i].amount > 0,
                "Payout amount must be greater than 0"
            );

            payouts_[i].awayTeamScore = SCORE_UNKNOWN;
            payouts_[i].homeTeamScore = SCORE_UNKNOWN;
            payouts_[i].winningSquare = SCORE_UNKNOWN;
            totalAmount += payouts_[i].amount;
            payouts.push(payouts_[i]);
        }

        return totalAmount;
    }

    /**
     *
     * Read-only functions
     *
     */

    function version() external pure returns (uint16) {
        return CONTRACT_VERSION;
    }

    function getAwayTeam()
        external
        view
        returns (string memory, string memory)
    {
        return (awayTeam.name, awayTeam.shortName);
    }

    function getHomeTeam()
        external
        view
        returns (string memory, string memory)
    {
        return (homeTeam.name, homeTeam.shortName);
    }

    function getAllSquares()
        external
        view
        returns (address[TOTAL_SQUARES] memory)
    {
        return allSquares;
    }

    function getAwayNumbers() external view returns (uint8[] memory) {
        return awayTeamNumbers;
    }

    function getHomeNumbers() external view returns (uint8[] memory) {
        return homeTeamNumbers;
    }

    function getPayouts() external view returns (Payout[] memory) {
        return payouts;
    }

    function getPayout(uint256 index)
        external
        view
        returns (
            string memory,
            string memory,
            uint256,
            address,
            int16,
            int16,
            int16
        )
    {
        require(index < payouts.length, "Payout index out of bounds");
        Payout memory p = payouts[index];
        return (
            p.name,
            p.shortName,
            p.amount,
            p.winner,
            p.awayTeamScore,
            p.homeTeamScore,
            p.winningSquare
        );
    }

    function getNftContracts()
        external
        view
        returns (NFTEarlyAccess.NFTContract[] memory)
    {
        return nfts.contracts;
    }

    function getNftContract(uint256 index)
        external
        view
        returns (
            address,
            uint256,
            string memory,
            string memory,
            bool[] memory
        )
    {
        require(
            index < nfts.contracts.length,
            "NFT Contract index out of bounds"
        );
        NFTEarlyAccess.NFTContract memory c = nfts.contracts[index];

        return (
            c.contractAddress,
            c.totalSupply,
            c.name,
            c.symbol,
            c.usedTokens
        );
    }

    function getGameState() public view returns (GameState) {
        if (isCancelled) return GameState.Cancelled;

        if (block.timestamp < earlyAccessEndTime) {
            // It's still early access
            if (numSquaresSold < TOTAL_SQUARES) {
                return GameState.EarlyAccess;
            } else {
                return GameState.DepositsClosed;
            }
        }

        if (block.timestamp >= claimsEndTime) {
            // Claims are over
            if (address(this).balance == 0) {
                return GameState.AllFundsClaimed;
            } else {
                return GameState.ClaimsClosed;
            }
        }

        // The game is not cancelled, early access is over, but claims are not over
        //
        // Progress thru the remaining states from DepositsOpen to AllScoresSet

        GameState result = GameState.DepositsOpen;
        if (numSquaresSold < TOTAL_SQUARES) return result;

        // Deposits are no longer open
        result = GameState.DepositsClosed;

        if ((awayTeamNumbers.length != 0) && (homeTeamNumbers.length != 0)) {
            // finishReveal has been called
            result = GameState.RevealComplete;
        }

        if (areAllWinningScoresSet()) {
            // All scores have been set, to state is AllScoresSet
            result = GameState.AllScoresSet;
        }

        return result;
    }

    function areAllWinningScoresSet() public view returns (bool) {
        for (uint8 i = 0; i < payouts.length; i++) {
            if (payouts[i].winningSquare == SCORE_UNKNOWN) return false;
        }

        return true;
    }

    /**
     *
     * Owner Functions
     *
     */

    function cancelGame() external onlyOwner {
        require(!isCancelled, "Game is already cancelled");
        require(
            getGameState() < GameState.RevealComplete,
            "Cannot cancel game after squares are revealed"
        );
        isCancelled = true;

        refundAll();
    }

    function refundAll() private {
        uint256 totalRefund = numSquaresSold * squarePrice;
        require(
            address(this).balance >= totalRefund,
            "Unable to refund, insufficient balance"
        );

        emit GameCancelled(numSquaresSold, squarePrice);

        for (uint8 i = 0; i < allSquares.length; i++) {
            address player = allSquares[i];
            if (player != address(0)) {
                allSquares[i] = address(0);
                ledger[player] += squarePrice;
                emit RefundSquare(player, i, squarePrice);
            }
        }
    }

    function finishReveal(uint256 proof) external onlyOwner {
        // TODO: Run SlothVDF.verify on proof
        // TODO: Require startReveal to have been called

        require(!isCancelled, "Game is cancelled");
        require(
            awayTeamNumbers.length == 0,
            "finishReveal has already been called"
        );
        require(
            homeTeamNumbers.length == 0,
            "finishReveal has already been called"
        );

        require(numSquaresSold == TOTAL_SQUARES, "All squares are not sold");

        RandomGenerator memory randomGenerator = RandomGenerator(
            proof,
            proof,
            0
        );

        assignRandomizedScores(randomGenerator, awayTeamNumbers);
        assignRandomizedScores(randomGenerator, homeTeamNumbers);

        emit FinishReveal(proof);
    }

    function assignRandomizedScores(
        RandomGenerator memory randomGenerator,
        uint8[] storage scores
    ) private {
        uint8[10] memory unassignedScores = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

        for (uint8 i = 0; i < unassignedScores.length; i++) {
            uint256 currentLength = unassignedScores.length - i;

            // Get a random index
            uint256 random = generateNewRandom(randomGenerator);
            uint256 index = random % currentLength;

            // Assign random score
            scores.push(unassignedScores[index]);

            // Remove score from unassigned list.
            // If the last score was used, this will be a self-assignment.
            // Otherwise, copy the unused value to the end of the array to the index that was just used
            unassignedScores[index] = unassignedScores[currentLength - 1];
        }
    }

    // See https://www.justinsilver.com/technology/cryptocurrency/provable-randomness-with-vdf/
    function generateNewRandom(RandomGenerator memory randomGenerator)
        private
        view
        returns (uint256)
    {
        // Derive a new random number from the proof with it becomes zero, to avoid generating
        // the same string of random numbers from it
        if (randomGenerator.random <= 0) {
            randomGenerator.random = uint256(
                keccak256(
                    abi.encodePacked(
                        randomGenerator.proof,
                        randomGenerator.nonce++,
                        block.timestamp,
                        _msgSender(),
                        blockhash(block.number - 1)
                    )
                )
            );
        }

        // Use current random number
        uint256 result = randomGenerator.random;

        // Shift bits to the right to get a new "random" number
        // This new number is actually pseudo-random in that it depends on
        // the initial seed, but it also inherits real randomness from that seed
        randomGenerator.random >>= 4;

        return result;
    }

    function castScore(int16 score) private pure returns (uint8) {
        // Scores are cast to uint8, so must be within that range
        require(
            (score >= 0) && (score <= 256),
            "Score is not in the valid range"
        );

        return uint8(uint16(score));
    }

    function castSquare(uint256 square) private pure returns (int8) {
        require(square < 128, "Score is not in the valid range");
        return int8(uint8(square));
    }

    function setWinningScore(
        string memory payoutShortName_,
        int16 awayTeamScore_,
        int16 homeTeamScore_
    ) external onlyOwner {
        uint8 payoutIndex = findPayoutIndex(payoutShortName_);
        require(!isCancelled, "Game is cancelled");
        require(
            payouts[payoutIndex].winner == address(0),
            "Can't set score, payout has already been assigned"
        );

        uint8 awayScore = castScore(awayTeamScore_);
        uint8 homeScore = castScore(homeTeamScore_);

        uint8 awayTeamIndex = findScoreIndex(awayScore, awayTeamNumbers);
        uint8 homeTeamIndex = findScoreIndex(homeScore, homeTeamNumbers);

        uint256 winningSquare = awayTeamIndex + 10 * homeTeamIndex;

        address winningAddress = allSquares[winningSquare];
        ledger[winningAddress] += payouts[payoutIndex].amount;
        payouts[payoutIndex].winner = winningAddress;
        payouts[payoutIndex].awayTeamScore = awayTeamScore_;
        payouts[payoutIndex].homeTeamScore = homeTeamScore_;
        payouts[payoutIndex].winningSquare = castSquare(winningSquare);

        emit WinningScore(
            winningAddress,
            payouts[payoutIndex].amount,
            winningSquare,
            awayScore,
            homeScore
        );
    }

    function findPayoutIndex(string memory payoutShortName_)
        private
        view
        returns (uint8)
    {
        for (uint8 i = 0; i < payouts.length; i++) {
            if (
                keccak256(abi.encodePacked(payoutShortName_)) ==
                keccak256(abi.encodePacked(payouts[i].shortName))
            ) return i;
        }
        revert("Did not find payout");
    }

    function findScoreIndex(uint8 score_, uint8[] storage randomizedScores_)
        private
        view
        returns (uint8)
    {
        require(
            randomizedScores_.length == SCORES_LENGTH,
            "finishReveal has not yet created 10 randomized scores"
        );

        for (uint8 index = 0; index < SCORES_LENGTH; index++) {
            if (randomizedScores_[index] == score_) return index;
        }
        revert("Unexpected, could not find winning score in randomized scores");
    }

    function claimUnredeemedFunds() external onlyOwner {
        require(
            block.timestamp >= claimsEndTime,
            "Cannot claim unredeemed funds before claims end"
        );

        uint256 amount = address(this).balance;
        sendFunds(owner(), amount);
    }

    function sendFunds(address sendTo, uint256 amount) private {
        require(amount > 0, "No funds to claim");
        require(ledger[sendTo] == 0, "Ledger balance is not empty");

        emit FundsClaimed(sendTo, amount);

        // See https://ethereum.stackexchange.com/questions/78124/is-transfer-still-safe-after-the-istanbul-update
        (bool success, ) = payable(sendTo).call{value: amount}("");
        require(success, "Unable to send funds, recipient may have reverted");
    }

    /**
     *
     * Player Functions
     *
     */

    function enterGame(uint256 squareId_) external payable {
        uint256[] memory squareIds = new uint256[](1);
        squareIds[0] = squareId_;
        enterGameMany(squareIds);
    }

    function enterGameMany(uint256[] memory squareIds_) public payable {
        enterGameManyFor(_msgSender(), squareIds_);
    }

    function enterGameManyFor(address recipient, uint256[] memory squareIds_)
        public
        payable
    {
        require(
            getGameState() == GameState.DepositsOpen,
            "Deposits are not currently open"
        );

        _checkEnterGame(recipient, squareIds_.length);

        for (uint256 i = 0; i < squareIds_.length; i++) {
            _enterOneChoice(recipient, squareIds_[i]);
        }
    }

    function enterGameNft(
        uint256 squareId_,
        address contractAddress_,
        uint256 tokenId_
    ) external payable {
        uint256[] memory squareIds = new uint256[](1);
        address[] memory contractAddresses = new address[](1);
        uint256[] memory tokenIds = new uint256[](1);

        squareIds[0] = squareId_;
        contractAddresses[0] = contractAddress_;
        tokenIds[0] = tokenId_;

        enterGameNftManyFor(
            _msgSender(),
            squareIds,
            contractAddresses,
            tokenIds
        );
    }

    function enterGameNftManyFor(
        address recipient,
        uint256[] memory squareIds_,
        address[] memory contractAddresses_,
        uint256[] memory tokenIds_
    ) public payable {
        // Check
        require(
            getGameState() == GameState.EarlyAccess,
            "Not currently in early access"
        );

        require(
            squareIds_.length == contractAddresses_.length,
            "Input arrays must be same length"
        );
        require(
            contractAddresses_.length == tokenIds_.length,
            "Input arrays must be same length"
        );

        _checkEnterGame(recipient, squareIds_.length);

        // Effects
        for (uint256 i = 0; i < squareIds_.length; i++) {
            _enterOneChoice(recipient, squareIds_[i]);
        }

        // Interactions
        for (uint256 i = 0; i < squareIds_.length; i++) {
            // NB: NFTs must be used from this address, not the recipient address
            nfts.useNft(contractAddresses_[i], tokenIds_[i], _msgSender());
        }
    }

    function _enterOneChoice(address recipient, uint256 squareId_) private {
        require(allSquares[squareId_] == address(0), "Square is already sold");
        allSquares[squareId_] = recipient;
        emit EnterGame(recipient, squareId_);
        numSquaresSold += 1;
    }

    function _checkEnterGame(address recipient, uint256 numSquares_)
        private
        view
    {
        require(
            (numSquaresSold + numSquares_) <= TOTAL_SQUARES,
            "Unable to enter game, squares are already purchased"
        );

        require(
            msg.value == (squarePrice * numSquares_),
            "Incorrect FTM transfered"
        );

        require(recipient != address(0), "Cannot gift to null address");

        require(numSquares_ > 0, "Must purchase at least one square");

        require(!isCancelled, "Game is cancelled");
    }

    function claim() external {
        require(
            block.timestamp < claimsEndTime,
            "Cannot claim funds after claims end"
        );

        address sendTo = _msgSender();
        uint256 amount = ledger[sendTo];
        ledger[sendTo] = 0;

        sendFunds(sendTo, amount);
    }
}
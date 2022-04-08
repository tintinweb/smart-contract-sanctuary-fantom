// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Context.sol";
import "./IERC721Receiver.sol";

interface IRandomSource {
    function seed() external view returns (uint256);
}

interface CASH {
    function mint(address to, uint256 amount) external;
}

interface IRichcityNFT {
    struct RichCity {
        bool isGangster;
        uint8 body;
        uint8 level;
        uint8 clothes;
        uint8 hair;
        uint8 jewelry;
        uint8 tatto;
        uint8 belt;
        uint8 sunglass;
        uint8 hat;
        uint8 mask;
        uint8 weapon;
        uint8 gen;
    }

    function randomSource() external view returns (IRandomSource);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (RichCity memory);
}

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner_)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner_ != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner_);
        _owner = newOwner_;
    }
}

abstract contract Pauseable is Context {
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
     * @dev Initializes the contract in paused state.
     */
    constructor() {
        _paused = true;
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
        require(!paused(), "Pauseable: paused");
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
        require(paused(), "Pauseable: not paused");
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

contract Bank is Ownable, IERC721Receiver, Pauseable {
    uint256[3] alphasSWAT = [77, 231, 692];
    uint256[2] alphasLEAD = [25, 75];
    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        uint80 poolValue;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event GansterClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event SWATClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event LeadClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    // reference to the IRichcityNFT NFT contract
    IRichcityNFT game;
    // reference to the $CASH contract for minting $CASH earnings
    CASH cash;
    mapping(uint256 => Stake) public bank;
    mapping(uint256 => Stake[]) public packLEAD;
    mapping(uint256 => uint256) public packLEADIndices;
    mapping(uint256 => Stake[]) public pack;
    mapping(uint256 => uint256) public packIndices;
    // maps userClaimed
    mapping(address => uint256) public userClaimed;
    // maps userStaked
    mapping(address => uint256[]) public userStaked;

    uint256 public unaccountedRewardsSWAT = 0;
    uint256 public unaccountedRewardsLEAD = 0;

    uint256 public totalSWATAlpha = 0;
    uint256 public cashSWATPool = 0;

    uint256 public totalLEADAlpha = 0;
    uint256 public cashLEADPool = 0;

    uint256 public DAILY_CASH_RATE = 200 ether;
    uint256 public MINIMUM_TO_EXIT = 100 ether;

    uint256 public CASH_GANGSTER_CLAIM_SWAT_TAX = 20;
    uint256 public CASH_GANGSTER_CLAIM_LEAD = 15;
    uint256 public CASH_GANGSTER_UNSTAKE_SWAT_TAX = 30;
    uint256 public CASH_GANGSTER_UNSTAKE_LEAD = 70;
    uint256 public CASH_LEAD_CLAIM_SWAT_TAX = 15;
    uint256 public CASH_LEAD_UNSTAKE_SWAT_TAX = 50;
    uint256 public CASH_SWAT_UNSTAKE_LEAD_TAX = 70;

    uint256 public constant MAXIMUM_GLOBAL_CASH = 20000000 ether;
    address[] public claimUsers;
    // amount of $CASH earned so far
    uint256 public totalEarned;
    uint256 public totalClaimed;
    // number  staked in the Bank
    uint256 public totalGangsterStaked;
    uint256 public totalLEADStaked;
    uint256 public totalSWATStaked;
    // the last time $CASH was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaSWAT without any checks but without $CASH
    bool public rescueEnabled = false;
    bool private _reentrant = false;
    bool public canClaim = false;

    modifier nonReentrant() {
        require(!_reentrant, "No reentrancy");
        _reentrant = true;
        _;
        _reentrant = false;
    }

    /**
     * @param _game reference to the IRichcityNFT NFT contract
     * @param _cash reference to the $CASH token
     */
    constructor(IRichcityNFT _game, CASH _cash) {
        game = _game;
        cash = _cash;
    }

    function setBankStats(uint256 _lastClaimTimestamp, uint256 _totalCASHEarned)
        public
        onlyOwner
    {
        lastClaimTimestamp = _lastClaimTimestamp;
        totalEarned = _totalCASHEarned;
    }

    enum PARAMETER {
        GANGSTER_CLAIM_SWAT_TAX,
        GANGSTER_CLAIM_LEAD,
        GANGSTER_UNSTAKE_SWAT_TAX,
        GANGSTER_UNSTAKE_LEAD,
        LEAD_CLAIM_SWAT_TAX,
        LEAD_UNSTAKE_SWAT_TAX,
        SWAT_UNSTAKE_LEAD_TAX
    }

    function setTaxs(PARAMETER _parameter, uint256 _input) public onlyOwner {
        if (_parameter == PARAMETER.GANGSTER_CLAIM_SWAT_TAX) {
            // 0
            CASH_GANGSTER_CLAIM_SWAT_TAX = _input;
        } else if (_parameter == PARAMETER.GANGSTER_CLAIM_LEAD) {
            // 1
            CASH_GANGSTER_CLAIM_LEAD = _input;
        } else if (_parameter == PARAMETER.GANGSTER_UNSTAKE_SWAT_TAX) {
            // 2
            CASH_GANGSTER_UNSTAKE_SWAT_TAX = _input;
        } else if (_parameter == PARAMETER.GANGSTER_UNSTAKE_LEAD) {
            // 3
            CASH_GANGSTER_UNSTAKE_LEAD = _input;
        } else if (_parameter == PARAMETER.LEAD_CLAIM_SWAT_TAX) {
            // 4
            CASH_LEAD_CLAIM_SWAT_TAX = _input;
        } else if (_parameter == PARAMETER.LEAD_UNSTAKE_SWAT_TAX) {
            // 5
            CASH_LEAD_UNSTAKE_SWAT_TAX = _input;
        } else if (_parameter == PARAMETER.SWAT_UNSTAKE_LEAD_TAX) {
            // 6
            CASH_SWAT_UNSTAKE_LEAD_TAX = _input;
        }
    }

    function getUserStaked(address _addr) public view returns (uint256) {
        return userStaked[_addr].length;
    }

    function getClaimUsers() public view returns (uint256) {
        return claimUsers.length;
    }

    /***STASWAT */

    /**
     * adds roles to the Bank and Pack
     * @param account the address of the staker
     * @param tokenIds the IDs of the roles to stake
     */
    function addManyToBankAndPack(address account, uint16[] calldata tokenIds)
        external
        whenNotPaused
        nonReentrant
    {
        require(
            (account == _msgSender() && account == tx.origin) ||
                _msgSender() == address(game),
            "DONT GIVE YOUR TOKENS AWAY"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == 0) {
                continue;
            }

            if (_msgSender() != address(game)) {
                // dont do this step if its a mint + stake
                require(
                    game.ownerOf(tokenIds[i]) == _msgSender(),
                    "AINT YO TOKEN"
                );
                game.transferFrom(_msgSender(), address(this), tokenIds[i]);
            }
            if (isGangster(tokenIds[i])) {
                _addGangsterToBank(account, tokenIds[i]);
            } else if (isSWAT(tokenIds[i])) {
                _addSWATToPack(account, tokenIds[i]);
            } else {
                _addLEADToPack(account, tokenIds[i]);
            }
            userStaked[_msgSender()].push(tokenIds[i]);
        }
    }

    /**
     * adds a single Gangster to the Bank
     * @param account the address of the staker
     * @param tokenId the ID of the Gangster to add to the Bank
     */
    function _addGangsterToBank(address account, uint256 tokenId)
        internal
        whenNotPaused
    {
        bank[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp),
            poolValue: 0
        });
        _updateEarnings(tokenId);
        totalGangsterStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    function _addLEADToPack(address account, uint256 tokenId)
        internal
        whenNotPaused
        _updateEarningsLEAD
    {
        uint256 alpha = _alphaForLEAD(tokenId);
        totalLEADAlpha += alpha;
        totalLEADStaked += 1;
        packLEADIndices[tokenId] = packLEAD[alpha].length;
        packLEAD[alpha].push(
            Stake({
                owner: account,
                tokenId: uint16(tokenId),
                poolValue: uint80(cashLEADPool),
                value: uint80(block.timestamp)
            })
        );
        emit TokenStaked(account, tokenId, cashSWATPool);
    }

    function _addSWATToPack(address account, uint256 tokenId)
        internal
        whenNotPaused
        _updateEarningsSWAT
    {
        uint256 alpha = _alphaForSWAT(tokenId);
        totalSWATAlpha += alpha;
        totalSWATStaked += 1;
        packIndices[tokenId] = pack[alpha].length;
        pack[alpha].push(
            Stake({
                owner: account,
                tokenId: uint16(tokenId),
                poolValue: uint80(cashSWATPool),
                value: uint80(block.timestamp)
            })
        );
        emit TokenStaked(account, tokenId, cashSWATPool);
    }

    /***CLAIMING / UNSTASWAT */
    function claimManyFromBankAndPack(uint16[] calldata tokenIds, bool unstake)
        external
        payable
        nonReentrant
    {
        require(msg.sender == tx.origin, "Only EOA");
        require(canClaim, "Claim deactive");
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isGangster(tokenIds[i])) {
                owed += _claimGangsterFromPack(tokenIds[i], unstake);
            } else if (isSWAT(tokenIds[i])) {
                owed += _claimSWATFromPack(tokenIds[i], unstake);
            } else {
                owed += _claimLEADFromPack(tokenIds[i], unstake);
            }
            if (unstake) {
                uint256 index = find(tokenIds[i]);
                removeAtIndex(index);
            }
        }
        if (owed == 0) return;
        userClaimed[_msgSender()] += owed;
        claimUsers.push(_msgSender());
        totalClaimed += owed;
        cash.mint(_msgSender(), owed);
    }

    function _claimGangsterFromPack(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        Stake memory stake = bank[tokenId];
        uint256 RATE = game.getTokenTraits(tokenId).level == 1
            ? 100 ether
            : game.getTokenTraits(tokenId).level == 2
            ? 150 ether
            : 200 ether;
        require(stake.owner == _msgSender(), "Some NFTs don't belong to you");
        if (totalEarned < MAXIMUM_GLOBAL_CASH) {
            owed = ((block.timestamp - stake.value) * RATE) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0;
        } else {
            owed = ((lastClaimTimestamp - stake.value) * RATE) / 1 days;
        }
        require(
            !(unstake && owed < MINIMUM_TO_EXIT),
            "Gangsters can ONLY be unstaked if you have at least 100 $CASH unclaimed"
        );
        if (unstake) {
            if (random(tokenId) & 1 == 1) {
                // 50% chance of all $CASH stolen
                _paySWATTax((owed * CASH_GANGSTER_UNSTAKE_SWAT_TAX) / 100);
                _payLEADTax((owed * CASH_GANGSTER_UNSTAKE_LEAD) / 100);
                owed = 0;
            }
            game.transferFrom(address(this), _msgSender(), tokenId);
            // send back
            delete bank[tokenId];
            totalGangsterStaked -= 1;
        } else {
            _paySWATTax((owed * CASH_GANGSTER_CLAIM_SWAT_TAX) / 100);
            _payLEADTax((owed * CASH_GANGSTER_CLAIM_LEAD) / 100);
            // percentage tax to staked wolves
            owed =
                (owed *
                    (100 -
                        CASH_GANGSTER_CLAIM_SWAT_TAX -
                        CASH_GANGSTER_CLAIM_LEAD)) /
                100;
            bank[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp),
                poolValue: 0
            });
            // reset stake
        }

        _updateEarnings(tokenId);
        // reset stake
        emit GansterClaimed(tokenId, owed, unstake);
    }

    function _claimLEADFromPack(uint256 tokenId, bool unstake)
        internal
        _updateEarningsLEAD
        returns (uint256 owed)
    {
        uint256 alpha = _alphaForLEAD(tokenId);
        Stake memory stake = packLEAD[alpha][packLEADIndices[tokenId]];
        require(stake.owner == _msgSender(), "Some NFTs don't belong to you");
        if (totalEarned < MAXIMUM_GLOBAL_CASH) {
            owed = ((block.timestamp - stake.value) * DAILY_CASH_RATE) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0;
            // $CASH production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_CASH_RATE) /
                1 days;
            // stop earning additional $CASH if it's all been earned
        }
        owed += (alpha) * (cashLEADPool - stake.poolValue);
        require(
            !(unstake && owed < MINIMUM_TO_EXIT),
            "Gangster Leaders can ONLY be unstaked if you have at least 100 $CASH unclaimed"
        );
        if (unstake) {
            if (random(tokenId) & 1 == 1) {
                // 50% chance of all $CASH stolen
                _paySWATTax((owed * CASH_LEAD_UNSTAKE_SWAT_TAX) / 100);
                owed = 0;
            }
            totalLEADAlpha -= alpha;
            totalLEADStaked -= 1;
            game.transferFrom(address(this), _msgSender(), tokenId);
            // send back
            Stake memory lastStake = packLEAD[alpha][
                packLEAD[alpha].length - 1
            ];
            packLEAD[alpha][packLEADIndices[tokenId]] = lastStake;
            // Shuffle last SWAT to current position
            packLEADIndices[lastStake.tokenId] = packLEADIndices[tokenId];
            packLEAD[alpha].pop();
            // Remove duplicate
            delete packLEADIndices[tokenId];
        } else {
            _paySWATTax((owed * CASH_LEAD_CLAIM_SWAT_TAX) / 100);
            // percentage tax to staked wolves
            owed = (owed * (100 - CASH_LEAD_CLAIM_SWAT_TAX)) / 100;
            packLEAD[alpha][packLEADIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                poolValue: uint80(cashLEADPool),
                value: uint80(block.timestamp)
            });
            // reset stake
        }
        emit LeadClaimed(tokenId, owed, unstake);
    }

    function _claimSWATFromPack(uint256 tokenId, bool unstake)
        internal
        _updateEarningsSWAT
        returns (uint256 owed)
    {
        require(
            game.ownerOf(tokenId) == address(this),
            "AINT A PART OF THE PACK"
        );
        uint256 alpha = _alphaForSWAT(tokenId);
        Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "Some NFTs don't belong to you");
        if (totalEarned < MAXIMUM_GLOBAL_CASH) {
            owed = ((block.timestamp - stake.value) * DAILY_CASH_RATE) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0;
            // $CASH production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_CASH_RATE) /
                1 days;
            // stop earning additional $CASH if it's all been earned
        }
        owed += (alpha) * (cashSWATPool - stake.poolValue);
        require(
            !(unstake && owed < MINIMUM_TO_EXIT),
            " SWAT  can ONLY be unstaked if you have at least 100 $CASH unclaimed"
        );
        // Calculate portion of tokens based on Alpha
        if (unstake) {
            if (random(tokenId) & 1 == 1) {
                // 50% chance of all $CASH stolen
                _payLEADTax((owed * CASH_SWAT_UNSTAKE_LEAD_TAX) / 100);
                owed = (owed * (100 - CASH_SWAT_UNSTAKE_LEAD_TAX)) / 100;
            }
            totalSWATAlpha -= alpha;
            totalSWATStaked -= 1;
            // Remove Alpha from total staked
            game.transferFrom(address(this), _msgSender(), tokenId);
            // Send back SWAT
            Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
            pack[alpha][packIndices[tokenId]] = lastStake;
            // Shuffle last SWAT to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            pack[alpha].pop();
            // Remove duplicate
            delete packIndices[tokenId];
            // Delete old mapping
        } else {
            pack[alpha][packIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                poolValue: uint80(cashSWATPool),
                value: uint80(block.timestamp)
            });
            // reset stake
        }
        emit SWATClaimed(tokenId, owed, unstake);
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint256[] calldata tokenIds) external nonReentrant {
        require(rescueEnabled, "RESCUE DISABLED");
        uint256 tokenId;
        Stake memory stake;
        Stake memory lastStake;
        uint256 alpha;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (isGangster(tokenId)) {
                stake = bank[tokenId];
                require(
                    stake.owner == _msgSender(),
                    "Some NFTs don't belong to you"
                );
                game.transferFrom(address(this), _msgSender(), tokenId);
                delete bank[tokenId];
                totalGangsterStaked -= 1;
                emit GansterClaimed(tokenId, 0, true);
            } else if (isSWAT(tokenId)) {
                alpha = _alphaForSWAT(tokenId);
                stake = pack[alpha][packIndices[tokenId]];
                require(
                    stake.owner == _msgSender(),
                    "Some NFTs don't belong to you"
                );
                totalSWATAlpha -= alpha;
                // Remove Alpha from total staked
                game.transferFrom(address(this), _msgSender(), tokenId);
                lastStake = pack[alpha][pack[alpha].length - 1];
                pack[alpha][packIndices[tokenId]] = lastStake;
                // Shuffle last SWAT to current position
                packIndices[lastStake.tokenId] = packIndices[tokenId];
                pack[alpha].pop();
                // Remove duplicate
                delete packIndices[tokenId];
                // Delete old mapping
                emit SWATClaimed(tokenId, 0, true);
            } else {
                alpha = _alphaForLEAD(tokenId);
                stake = packLEAD[alpha][packLEADIndices[tokenId]];
                require(
                    stake.owner == _msgSender(),
                    "Some NFTs don't belong to you"
                );
                totalLEADAlpha -= alpha;
                game.transferFrom(address(this), _msgSender(), tokenId);
                totalLEADStaked -= 1;
                lastStake = packLEAD[alpha][packLEAD[alpha].length - 1];
                packLEAD[alpha][packLEADIndices[tokenId]] = lastStake;
                // Shuffle last SWAT to current position
                packLEADIndices[lastStake.tokenId] = packLEADIndices[tokenId];
                packLEAD[alpha].pop();
                // Remove duplicate
                delete packLEADIndices[tokenId];
            }
        }
    }

    /***ACCOUNTING */

    /**
     * add $CASH to claimable pot for the Pack
     * @param amount $CASH to add to the pot
     */
    function _paySWATTax(uint256 amount) internal {
        if (totalSWATAlpha == 0) {
            // if there's no staked wolves
            unaccountedRewardsSWAT += amount;
            // keep track of $CASH due to wolves
            return;
        }
        // makes sure to include any unaccounted $CASH
        cashSWATPool += (amount + unaccountedRewardsSWAT) / totalSWATAlpha;
        unaccountedRewardsSWAT = 0;
    }

    function _payLEADTax(uint256 amount) internal {
        if (totalLEADAlpha == 0) {
            // if there's no staked wolves
            unaccountedRewardsLEAD += amount;
            // keep track of $CASH due to wolves
            return;
        }
        // makes sure to include any unaccounted $CASH
        cashLEADPool += (amount + unaccountedRewardsLEAD) / totalLEADAlpha;
        unaccountedRewardsLEAD = 0;
    }

    function _updateEarnings(uint256 tokenId) internal {
        uint256 RATE = game.getTokenTraits(tokenId).level == 1
            ? 100 ether
            : game.getTokenTraits(tokenId).level == 2
            ? 150 ether
            : 200 ether;
        if (totalEarned < MAXIMUM_GLOBAL_CASH) {
            totalEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    totalGangsterStaked *
                    RATE) /
                1 days;
            lastClaimTimestamp = block.timestamp;
        }
    }

    modifier _updateEarningsLEAD() {
        if (totalEarned < MAXIMUM_GLOBAL_CASH) {
            totalEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    totalLEADStaked *
                    DAILY_CASH_RATE) /
                1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    modifier _updateEarningsSWAT() {
        if (totalEarned < MAXIMUM_GLOBAL_CASH) {
            totalEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    totalSWATStaked *
                    DAILY_CASH_RATE) /
                1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /***ADMIN */

    function setSettings(uint256 rate, uint256 exit) external onlyOwner {
        DAILY_CASH_RATE = rate;
        MINIMUM_TO_EXIT = exit;
    }

    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed,
                        totalGangsterStaked,
                        totalLEADAlpha,
                        totalSWATAlpha,
                        lastClaimTimestamp
                    )
                )
            ) ^ game.randomSource().seed();
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Barn directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    function setGame(IRichcityNFT _nGame) public onlyOwner {
        game = _nGame;
    }

    function setClaiming(bool _canClaim) public onlyOwner {
        canClaim = _canClaim;
    }

    function find(uint256 value) public view returns (uint256) {
        uint256 i = 0;
        while (userStaked[_msgSender()][i] != value) {
            i++;
        }
        return i;
    }

    function removeAtIndex(uint256 index) internal returns (bool) {
        if (index >= userStaked[_msgSender()].length) return false;
        for (uint256 i = index; i < userStaked[_msgSender()].length - 1; i++) {
            userStaked[_msgSender()][i] = userStaked[_msgSender()][i + 1];
        }
        delete userStaked[_msgSender()][userStaked[_msgSender()].length - 1];
        userStaked[_msgSender()].pop();
        return true;
    }

    function isGangster(uint256 tokenId) public view returns (bool gangster) {
        gangster =
            game.getTokenTraits(tokenId).isGangster &&
            game.getTokenTraits(tokenId).level <= 3;
    }

    function isSWAT(uint256 tokenId) public view returns (bool SWAT) {
        SWAT = !game.getTokenTraits(tokenId).isGangster;
    }

    function calculate(uint256 tokenId) public view returns (uint256 owed) {
        if (isSWAT(tokenId)) {
            uint256 alpha = _alphaForSWAT(tokenId);
            Stake memory stake = pack[alpha][packIndices[tokenId]];
            if (stake.owner == address(0)) return 0;
            if (totalEarned < MAXIMUM_GLOBAL_CASH) {
                owed =
                    ((block.timestamp - stake.value) * DAILY_CASH_RATE) /
                    1 days;
            } else if (stake.value > lastClaimTimestamp) {
                owed = 0;
            } else {
                owed =
                    ((lastClaimTimestamp - stake.value) * DAILY_CASH_RATE) /
                    1 days;
            }
            owed += (alpha) * (cashSWATPool - stake.poolValue);
        } else if (isGangster(tokenId)) {
            uint256 RATE = game.getTokenTraits(tokenId).level == 1
                ? 100 ether
                : game.getTokenTraits(tokenId).level == 2
                ? 150 ether
                : 200 ether;
            Stake memory stake = bank[tokenId];
            if (stake.owner == address(0)) return 0;
            if (totalEarned < MAXIMUM_GLOBAL_CASH) {
                owed = ((block.timestamp - stake.value) * RATE) / 1 days;
            } else if (stake.value > lastClaimTimestamp) {
                owed = 0;
            } else {
                owed = ((lastClaimTimestamp - stake.value) * RATE) / 1 days;
            }
        } else {
            uint256 alpha = _alphaForLEAD(tokenId);
            Stake memory stake = packLEAD[alpha][packLEADIndices[tokenId]];
            if (stake.owner == address(0)) return 0;
            if (totalEarned < MAXIMUM_GLOBAL_CASH) {
                owed =
                    ((block.timestamp - stake.value) * DAILY_CASH_RATE) /
                    1 days;
            } else if (stake.value > lastClaimTimestamp) {
                owed = 0;
            } else {
                owed =
                    ((lastClaimTimestamp - stake.value) * DAILY_CASH_RATE) /
                    1 days;
            }
            owed += (alpha) * (cashLEADPool - stake.poolValue);
        }
    }

    function _alphaForSWAT(uint256 tokenId) internal view returns (uint256) {
        return alphasSWAT[game.getTokenTraits(tokenId).level - 1];
    }

    function _alphaForLEAD(uint256 tokenId) internal view returns (uint256) {
        return alphasLEAD[game.getTokenTraits(tokenId).level - 4];
    }
}
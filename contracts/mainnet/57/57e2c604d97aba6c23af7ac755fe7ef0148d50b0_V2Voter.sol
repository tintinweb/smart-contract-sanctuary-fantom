/**
 *Submitted for verification at FtmScan.com on 2022-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

pragma solidity ^0.8.11;

// Inheritance

abstract contract Pausable is Owned {
    uint public lastPauseTime;
    bool public paused;

    constructor() {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}


pragma solidity 0.8.11;

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
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IVe {
    function token() external view returns (address);
    function balanceOfNFT(uint) external view returns (uint);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function ownerOf(uint) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint _tokenId) external;
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;
    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
}

interface IV1Voter {
    function isGauge(address) external view returns(bool);
    function gauges(address) external view returns(address);
    function poolForGauge(address) external view returns(address);
    function vote(uint tokenId, address[] calldata _poolVote, int256[] calldata _weights) external;
    function reset(uint _tokenId) external;
}

interface IV2BribeFactory {
    function createBribe() external returns (address);
}

interface IV2Bribe {
    function _deposit(uint amount, uint tokenId) external;
    function _withdraw(uint amount, uint tokenId) external;
    function _getRewardsForOwner(uint tokenId, address owner, address[] memory tokens) external;
    function earned(address token, uint tokenId) external view returns (uint);
}

contract V2Voter is Pausable, IERC721Receiver {
    address public immutable _ve;
    address public immutable _v1Voter;
    address public immutable _v2BribeFactory;

    /// @dev Cannot change the vote more often than once every 10 days
    uint public constant VoteDelay = 10 * 86400;
    uint internal index;

    /// @dev total voting weight
    uint public totalWeight;

    /// @dev all pools available for incentives 
    address[] public pools; 

    /// @dev Last vote time
    mapping(uint => uint256) public lastUserVote;

    /// @dev Map from nft id to pools addresses. Keeps track of what pools an nft voted for
    mapping(uint => address[]) public poolVote; 

    /// @dev Map from nft id to a pool to vote weight
    mapping(uint => mapping(address => int256)) public votes;

    /// @dev Map from a gauge address to bribe address
    mapping(address => address) public bribes;

    /// @dev Map from pool to vote weight
    mapping(address => int256) public weights;

    /// @dev Map from gauge to pool
    mapping(address => address) public poolForGauge;

    /// @dev Map from gauge address to supply index
    mapping(address => uint) internal supplyIndex;

    /// @dev Map from gauge address to amount claimable
    mapping(address => uint) public claimable;

    /// @dev Map from nft id to total used voting weight
    mapping(uint => uint) public usedWeights;

    /// @dev Map from nft id to address of owner
    mapping(uint => address) public nftOwner;

    /// @dev Map from owner address to nft id
    mapping(uint => address) public ownerNft;

    /// @dev Map from owner address to count of their tokens. Mostly used for frontend view
    mapping(address => uint) internal ownerToNFTokenCount;

    /// @dev Map from owner address to indexed nft id. Mostly used for frontend view
    mapping(address => mapping(uint => uint)) public ownerToNFTokenIdList;

    /// @dev Map from a token Id to index. To be used with ownerToNFTokenIdList
    mapping(uint => uint) internal tokenToListIndex;

    event Abstained(uint tokenId, int256 weight);
    event Voted(address indexed voter, uint tokenId, int256 weight);
    event BribesClaimed(uint _tokenId, address[] bribes);
    event V2BribeCreated(address bribe);
    event WithdrawNFT(uint _tokenId);

    constructor(address __ve, address __v1Voter, address __v2BribeFactory, address _owner) Owned(_owner) {
        _ve = __ve;
        _v1Voter = __v1Voter;
        _v2BribeFactory = __v2BribeFactory;
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    // Checks if  current timestamp has surpassed the vote delay
    modifier voteDelay(uint _tokenId) {
        require(block.timestamp >= lastUserVote[_tokenId] + VoteDelay, 'Too early to change votes');
        _;
    }

    // Checks if an nft has been deposited
    modifier onlyDepositer(uint _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, 'Not Authorized');
        _;
    }

    function _updateFor(address _gauge) internal {
        address _pool = poolForGauge[_gauge];
        int256 _supplied = weights[_pool];
        if (_supplied > 0) {
            uint _supplyIndex = supplyIndex[_gauge];
            uint _index = index; // get global index0 for accumulated distro
            supplyIndex[_gauge] = _index; // update _gauge current position to global position
            uint _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (_delta > 0) {
                uint _share = uint(_supplied) * _delta / 1e18; // add accrued difference for each supplied token
                claimable[_gauge] += _share;
            }
        } else {
            supplyIndex[_gauge] = index; // new users are set to the default global state
        }
    }

    /**
    * @dev Internal function used to proxy vote for a pool. 
    * It calls _deposit on the V2Bribes to keep track of votes for reward calculation.
    */
    function _vote(uint _tokenId, address[] memory _poolVote, int256[] memory _weights) internal {
        _reset(_tokenId);
        uint _poolCnt = _poolVote.length;
        int256 _weight = int256(IVe(_ve).balanceOfNFT(_tokenId));
        int256 _totalVoteWeight = 0;
        int256 _totalWeight = 0;
        int256 _usedWeight = 0;

        for (uint i = 0; i < _poolCnt; i++) {
            _totalVoteWeight += _weights[i] > 0 ? _weights[i] : -_weights[i];
        }
        for (uint i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];
            address _gauge = IV1Voter(_v1Voter).gauges(_pool);
            if (IV1Voter(_v1Voter).isGauge(_gauge)) {
                
                int256 _poolWeight = _weights[i] * _weight / _totalVoteWeight; // weight of current vote * balanceNFT / total of _weights
                
                require(votes[_tokenId][_pool] == 0, 'Pool vote must be 0');
                require(_poolWeight != 0, 'Pool weight cannot be 0');    
                _updateFor(_gauge);

                poolVote[_tokenId].push(_pool);
                
                weights[_pool] += _poolWeight;
                votes[_tokenId][_pool] += _poolWeight;
                if (_poolWeight > 0) {
                    IV2Bribe(bribes[_gauge])._deposit(uint256(_poolWeight), _tokenId); // Used to tally the nft votes to bribes
                } else {
                    _poolWeight = -_poolWeight;
                }
                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                
                emit Voted(msg.sender, _tokenId, _poolWeight);
            }
        }
        
        totalWeight += uint256(_totalWeight);
        usedWeights[_tokenId] = uint256(_usedWeight);
        // Record the last voting time
        lastUserVote[_tokenId] = block.timestamp;
    }

    /**
    * @dev Resets the votes on this contract and v2Bribes only.
    */
    function _reset(uint _tokenId) internal {
        address[] storage _poolVote = poolVote[_tokenId];
        uint _poolVoteCnt = _poolVote.length;
        int256 _totalWeight = 0;

        for (uint i = 0; i < _poolVoteCnt; i ++) {
            address _pool = _poolVote[i];
            int256 _votes = votes[_tokenId][_pool];

            if (_votes != 0) {
                _updateFor(IV1Voter(_v1Voter).gauges(_pool));
                weights[_pool] -= _votes;
                votes[_tokenId][_pool] -= _votes;
                if (_votes > 0) {
                    IV2Bribe(bribes[IV1Voter(_v1Voter).gauges(_pool)])._withdraw(uint256(_votes), _tokenId);
                    _totalWeight += _votes;
                } else {
                    _totalWeight -= _votes;
                }
                emit Abstained(_tokenId, _votes);
            }
        }
        totalWeight -= uint256(_totalWeight);
        usedWeights[_tokenId] = 0;
        delete poolVote[_tokenId];
    }

    function _balance(address _owner) internal view returns (uint) {
        return ownerToNFTokenCount[_owner];
    }

    function _incrementBalance(address _owner) internal { 
        ownerToNFTokenCount[_owner]++;
    }

    function _decrementBalance(address _owner) internal { 
        ownerToNFTokenCount[_owner]--;
    }

    function balanceOf(address _owner) external view returns (uint) {
        return _balance(_owner);
    }

    /**
    * @dev Add a NFT to an index mapping to a given address, and increase balance
    */
    function _addTokenToOwnerList(address _to, uint _tokenId) internal {
        uint current_count = _balance(_to);

        ownerToNFTokenIdList[_to][current_count] = _tokenId;
        tokenToListIndex[_tokenId] = current_count;
        _incrementBalance(_to);
    }

    /**
    * @dev Remove a NFT from an index mapping to a given address
    */
    function _removeTokenFromOwnerList(address _from, uint _tokenId) internal {
        uint currentCount = _balance(_from)-1;
        uint currentIndex = tokenToListIndex[_tokenId];

        // If last position
        if (currentCount == currentIndex) {
            ownerToNFTokenIdList[_from][currentCount] = 0;
            tokenToListIndex[_tokenId] = 0;
        } else {
            uint lastTokenId = ownerToNFTokenIdList[_from][currentCount];

            // Move the last item to current position
            ownerToNFTokenIdList[_from][currentIndex] = lastTokenId;
            tokenToListIndex[lastTokenId] = currentIndex;

            // Delete last item
            ownerToNFTokenIdList[_from][currentCount] = 0;
            tokenToListIndex[_tokenId] = 0;
        }

        _decrementBalance(_from);
    }
    
    /**
    * @dev Resets the votes on v1 and v2 Voter.
    */
    function reset(uint _tokenId) external lock notPaused onlyDepositer(_tokenId) voteDelay(_tokenId) {
        _reset(_tokenId);
        IV1Voter(_v1Voter).reset(_tokenId);
    }    

    /**
    * @dev Transfers and tracks the nft to this contract. Need to be done before voting.
    */
    function transferToProxy(uint _tokenId) external lock notPaused {
        require(IVe(_ve).isApprovedOrOwner(msg.sender, _tokenId), 'Not Authorized');
        IVe(_ve).safeTransferFrom(msg.sender, address(this), _tokenId);
        nftOwner[_tokenId] = msg.sender;
        _addTokenToOwnerList(msg.sender, _tokenId);
    }

    /**
    * @dev Initiates a proxy vote. It is assumed that the owner of the nft has already transferred it to this contract.
    * - Will revert if done by a non-owner
    * - Will revert if the poolVotes don't match the weights
    * - Will revert if attempting to change the vote
    */
    function vote(uint _tokenId, address[] calldata _poolVote, int256[] calldata _weights) external lock notPaused onlyDepositer(_tokenId) voteDelay(_tokenId) {
        require(_poolVote.length == _weights.length, 'Invalid vote params');
        _vote(_tokenId, _poolVote, _weights);
        IV1Voter(_v1Voter).vote(_tokenId, _poolVote, _weights); 
    }

    /**
    * @dev Creates a new bribe. The assumption is the gauge is already created in V1 Voter
    *  - Validates if a pool has a gauge created
    *  - Creates a new v2bribe
    */
    function createBribe(address _gauge) external lock notPaused returns (address) {
        require(IV1Voter(_v1Voter).isGauge(_gauge), 'Gauge does not exist');
        require(bribes[_gauge] == address(0), 'Bribe already exists');
        address _pool = IV1Voter(_v1Voter).poolForGauge(_gauge);
        address _bribe = IV2BribeFactory(_v2BribeFactory).createBribe();
        bribes[_gauge] = _bribe;
        poolForGauge[_gauge] = _pool;
        _updateFor(_gauge);
        pools.push(_pool);
        emit V2BribeCreated(_bribe);
        return _bribe;
    }

    /**
    *  @dev Withdraws the NFT back to the owner
    *   - Votes needs to be reset before running
    */
    function withdrawFromProxy(uint _tokenId) external lock notPaused onlyDepositer(_tokenId) voteDelay(_tokenId) {
        IVe(_ve).safeTransferFrom(address(this), msg.sender, _tokenId);
        nftOwner[_tokenId] = address(0);
        _removeTokenFromOwnerList(msg.sender, _tokenId);
        emit WithdrawNFT(_tokenId);
    }

    /**
    *  @dev Claims bribes on behalf of the owner
    */
    function claimBribes(uint _tokenId, address[] memory _bribes, address[][] memory _tokens) public lock notPaused onlyDepositer(_tokenId) {
        for (uint i = 0; i < _bribes.length; i++) {
            IV2Bribe(_bribes[i])._getRewardsForOwner(_tokenId, msg.sender, _tokens[i]);
        }
        emit BribesClaimed(_tokenId, _bribes);
    }

    /**
    *  @dev Required method for ERC721 safeTransfer validation
    */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) pure public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
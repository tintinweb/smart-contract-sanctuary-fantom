/**
 *Submitted for verification at FtmScan.com on 2023-07-30
*/

pragma solidity ^0.5.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) internal initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

interface GovernanceI {
    function recountVote(address voterAddr, address delegatedTo, uint256 proposalID) external;

    function proposalState(uint256 proposalID) external view returns (uint256 winnerOptionID, uint256 votes, uint256 status);
}

contract VotesBookKeeper is Initializable, Ownable {
    address gov;

    uint256 public maxProposalsPerVoter;

    // voter, delegatedTo -> []proposal IDs
    mapping(address => mapping(address => uint256[])) votesList;

    // voter, delegatedTo, proposal ID -> {index in the list + 1}
    mapping(address => mapping(address => mapping(uint256 => uint256))) votesIndex;

    function initialize(address _owner, address _gov, uint256 _maxProposalsPerVoter) public initializer {
        Ownable.initialize(_owner);
        gov = _gov;
        maxProposalsPerVoter = _maxProposalsPerVoter;
    }

    function getProposalIDs(address voter, address delegatedTo) public view returns (uint256[] memory) {
        return votesList[voter][delegatedTo];
    }

    // returns vote index plus 1 if vote exists. Returns 0 if vote doesn't exist
    function getVoteIndex(address voter, address delegatedTo, uint256 proposalID) public view returns (uint256) {
        return votesIndex[voter][delegatedTo][proposalID];
    }

    function recountVotes(address voter, address delegatedTo) public {
        uint256[] storage list = votesList[voter][delegatedTo];
        uint256 origLen = list.length;
        uint256 i = 0;
        for (uint256 iter = 0; iter < origLen; iter++) {
            (bool success,) = gov.call(abi.encodeWithSignature("recountVote(address,address,uint256)", voter, delegatedTo, list[i]));
            bool evicted = false;
            if (!success) {
                // unindex if proposal isn't active
                (,, uint256 status) = GovernanceI(gov).proposalState(list[i]);
                if (status != 0) {
                    eraseVote(voter, delegatedTo, list[i], i + 1);
                    evicted = true;
                }
            }
            if (!evicted) {
                i++;
            }
        }
    }

    function onVoted(address voter, address delegatedTo, uint256 proposalID) external {
        uint256 idx = votesIndex[voter][delegatedTo][proposalID];
        if (idx > 0) {
            return;
        }
        if (votesList[voter][delegatedTo].length >= maxProposalsPerVoter) {
            // erase votes for outdated proposals
            recountVotes(voter, delegatedTo);
        }
        votesList[voter][delegatedTo].push(proposalID);
        idx = votesList[voter][delegatedTo].length;
        require(idx <= maxProposalsPerVoter, "too many votes");
        votesIndex[voter][delegatedTo][proposalID] = idx;
    }

    function onVoteCanceled(address voter, address delegatedTo, uint256 proposalID) external {
        uint256 idx = votesIndex[voter][delegatedTo][proposalID];
        if (idx == 0) {
            return;
        }
        eraseVote(voter, delegatedTo, proposalID, idx);
    }

    function eraseVote(address voter, address delegatedTo, uint256 proposalID, uint256 idx) internal {
        votesIndex[voter][delegatedTo][proposalID] = 0;
        uint256[] storage list = votesList[voter][delegatedTo];
        uint256 len = list.length;
        if (len == idx) {
            // last element
            list.length--;
        } else {
            uint256 last = list[len - 1];
            list[idx - 1] = last;
            list.length--;
            votesIndex[voter][delegatedTo][last] = idx;
        }
    }

    function setMaxProposalsPerVoter(uint256 v) onlyOwner external {
        maxProposalsPerVoter = v;
    }
}
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

//Active Citizen project voting smart contract for Yerevan city.
//Holds all projects and all votes from citizens for them irrevertably.

contract YerevanVotes is Ownable {
    struct Project {
        uint256 createTs;
        string description;
        mapping(uint256 => Option) options;
        uint256[] optionList;
    }

    struct Option {
        bool inactive;
        uint256 endTs;
        uint256 startTS;
        string title;
        uint256[] voteList;
        uint256[] votersList;
        string[] selections;
        mapping(uint256 => Vote) votes; // (citizenId => Vote)
    }

    struct Proj {
        uint256 createTs;
        string description;
        uint256[] optionList;
    }

    struct Opt {
        uint256 startTS;
        uint256 endTs;
        string title;
        uint256[] voteList;
        uint256[] votersList;
        string[] selections;
    }

    struct Vote {
        uint256 vote; // selection number
        uint256 voteTS;
    }

    mapping(uint256 => Project) public projects;
    uint256[] public projectList;

    function createProject(
        uint256 _projectId,
        string memory _description
    ) external onlyOwner {
        Project storage project = projects[_projectId];
        require(project.createTs == 0, "Project already exists");
        project.description = _description;
        project.createTs = block.timestamp;
        projectList.push(_projectId);
    }

    function addOption(
        uint256 _projectId,
        uint256 _optionId,
        uint256 _startTS,
        uint256 _endTS,
        string memory _title,
        string[] memory _selections
    ) external onlyOwner {
        Project storage project = projects[_projectId];
        Option storage option = project.options[_optionId];
        require(project.createTs > 0, "Project does not exist");
        require(option.startTS == 0, "Option already exist");
        require(_endTS > _startTS, "Incorrect end start ts");
        require(_startTS >= block.timestamp, "Incorrect start ts");
        option.selections = _selections;
        option.startTS = _startTS;
        option.endTs = _endTS;
        option.title = _title;
        project.optionList.push(_optionId);
    }

    function stopVoting(
        uint256 _projectId,
        uint256 _optionId
    ) external onlyOwner {
        Option storage option = projects[_projectId].options[_optionId];
        require(option.endTs > block.timestamp, "Voting for the option is already closed");
        option.inactive = true;
    }

    function continueVoting(
        uint256 _projectId,
        uint256 _optionId
    ) external onlyOwner {
        Option storage option = projects[_projectId].options[_optionId];
        require(option.endTs > block.timestamp && option.inactive, "Voting for the option is already closed");
        option.inactive = false;
    }

    function vote(
        uint256 _projectId,
        uint256 _optionId,
        uint256 _citizenID,
        uint256 _vote
    ) external onlyOwner {
        require(projects[_projectId].createTs > 0, "Project does not exist");
        Option storage option = projects[_projectId].options[_optionId];
        require(!option.inactive, "Option is inactive");
        require(option.endTs >= block.timestamp, "Voting for the option is closed");
        require(option.startTS <= block.timestamp, "Voting for the option is not open yet");
        require(
            _vote > 0 && _vote <= option.selections.length,
            "Incorrect vote"
        );
        Vote storage vote_ = option.votes[_citizenID];
        require(vote_.voteTS == 0, "Citizen has already voted");
        vote_.vote = _vote;
        vote_.voteTS = block.timestamp;
        option.voteList.push(_vote);
        option.votersList.push(_citizenID);
    }

    function getProjectIds() public view returns (uint256[] memory) {
        return projectList;
    }

    function getSelections(
        uint256 _projectId,
        uint256 _optionId
    ) public view returns (string[] memory) {
        return projects[_projectId].options[_optionId].selections;
    }

    function getVotes(
        uint256 _projectId,
        uint256 _optionId
    ) public view returns (uint256[] memory) {
        return projects[_projectId].options[_optionId].voteList;
    }

    function getVoteResults(
        uint256 _projectId,
        uint256 _optionId
    ) public view returns (uint256[] memory) {
        Option storage option = projects[_projectId].options[_optionId];
        uint256[] memory _votes = option.voteList;
        uint256[] memory results = new uint256[](option.selections.length);
        for (uint256 i = 0; i < _votes.length; i++) {
            results[_votes[i] - 1]++;
        }
        return results;
    }

    function getProjectVoteResults(
        uint256 _projectId
    ) public view returns (uint256[][] memory) {
        Project storage project = projects[_projectId];
        uint256[] memory optionIds = project.optionList;
        uint256[][] memory results = new uint256[][](optionIds.length);

        for (uint256 i = 0; i < optionIds.length; i++) {
            results[i] = getVoteResults(_projectId, optionIds[i]);
        }
        return results;
    }

    function getVoters(
        uint256 _projectId,
        uint256 _optionId
    ) public view returns (uint256[] memory) {
        return projects[_projectId].options[_optionId].votersList;
    }

    function getCitizenVote(
        uint256 _projectId,
        uint256 _optionId,
        uint256 _citizenID
    ) public view returns (Vote memory) {
        Vote memory _vote = projects[_projectId].options[_optionId].votes[
            _citizenID
        ];
        require(_vote.voteTS > 0, "Citizen did not vote");
        return _vote;
    }

    function getProjectData(
        uint256 _projectId
    )
        public
        view
        returns (
            uint256 _createTs,
            string memory _description,
            uint256[] memory _optionList
        )
    {
        Project storage project = projects[_projectId];
        return (project.createTs, project.description, project.optionList);
    }

    function getOptionData(
        uint256 _projectId,
        uint256 _optionId
    )
        public
        view
        returns (
            uint256 startTS,
            uint256 endTs,
            uint256[] memory voteList,
            uint256[] memory votersList,
            string[] memory selections
        )
    {
        Option storage option = projects[_projectId].options[_optionId];
        return (
            option.startTS,
            option.endTs,
            option.voteList,
            option.votersList,
            option.selections
        );
    }

    function getOptions(
        uint256 _projectId
    ) public view returns (Opt[] memory _options) {
        Project storage project = projects[_projectId];
        _options = new Opt[](project.optionList.length);
        for (uint256 i = 0; i < project.optionList.length; i++) {
            Option storage option = project.options[project.optionList[i]];
            Opt memory opt = Opt(
                option.startTS,
                option.endTs,
                option.title,
                option.voteList,
                option.votersList,
                option.selections
            );
            _options[i] = opt;
        }
    }

    function getProjectsByIds(
        uint256[] memory _projectIds
    ) public view returns (Proj[] memory projs) {
        projs = new Proj[](_projectIds.length);
        for (uint256 i = 0; i < _projectIds.length; i++) {
            Project storage project = projects[_projectIds[i]];
            Proj memory p = Proj(
                project.createTs,
                project.description,
                project.optionList
            );
            projs[i] = p;
        }
    }
}
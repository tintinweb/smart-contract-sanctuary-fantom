pragma solidity ^0.5.0;

import "../common/ReentrancyGuard.sol";
import "../common/SafeMath.sol";
import "../model/Governable.sol";
import "../proposal/base/IProposal.sol";
import "../verifiers/IProposalVerifier.sol";
import "../proposal/SoftwareUpgradeProposal.sol";
import "./Proposal.sol";
import "./Constants.sol";
import "./GovernanceSettings.sol";
import "./LRC.sol";
import "../version/Version.sol";
import "../votebook/votebook.sol";

contract Governance is Initializable, ReentrancyGuard, GovernanceSettings, Version {
    using SafeMath for uint256;
    using LRC for LRC.Option;

    struct Vote {
        uint256 weight;
        uint256[] choices;
    }

    struct ProposalState {
        Proposal.Parameters params;

        // voting state
        mapping(uint256 => LRC.Option) options;
        uint256 winnerOptionID;
        uint256 votes; // total weight of votes

        uint256 status;
    }

    struct Task {
        bool active;
        uint256 assignment;
        uint256 proposalID;
    }

    Governable governableContract;
    IProposalVerifier proposalVerifier;
    uint256 public lastProposalID;
    Task[] tasks;

    mapping(uint256 => ProposalState) proposals;
    mapping(address => mapping(uint256 => uint256)) public overriddenWeight; // voter address, proposalID -> weight
    mapping(address => mapping(address => mapping(uint256 => Vote))) _votes; // voter, delegationReceiver, proposalID -> Vote

    VotesBookKeeper votebook;

    event ProposalCreated(uint256 proposalID);
    event ProposalResolved(uint256 proposalID);
    event ProposalRejected(uint256 proposalID);
    event ProposalCanceled(uint256 proposalID);
    event ProposalExecutionExpired(uint256 proposalID);
    event TasksHandled(uint256 startIdx, uint256 endIdx, uint256 handled);
    event TasksErased(uint256 quantity);
    event VoteWeightOverridden(address voter, uint256 diff);
    event VoteWeightUnOverridden(address voter, uint256 diff);
    event Voted(address voter, address delegatedTo, uint256 proposalID, uint256[] choices, uint256 weight);
    event VoteCanceled(address voter, address delegatedTo, uint256 proposalID);

    function initialize(address _governableContract, address _proposalVerifier, address _votebook) public initializer {
        ReentrancyGuard.initialize();
        governableContract = Governable(_governableContract);
        proposalVerifier = IProposalVerifier(_proposalVerifier);
        votebook = VotesBookKeeper(_votebook);
    }

    function proposalParams(uint256 proposalID) public view returns (uint256 pType, Proposal.ExecType executable, uint256 minVotes, uint256 minAgreement, uint256[] memory opinionScales, bytes32[] memory options, address proposalContract, uint256 votingStartTime, uint256 votingMinEndTime, uint256 votingMaxEndTime) {
        Proposal.Parameters memory p = proposals[proposalID].params;
        return (p.pType, p.executable, p.minVotes, p.minAgreement, p.opinionScales, p.options, p.proposalContract, p.deadlines.votingStartTime, p.deadlines.votingMinEndTime, p.deadlines.votingMaxEndTime);
    }

    function proposalOptionState(uint256 proposalID, uint256 optionID) public view returns (uint256 votes, uint256 agreementRatio, uint256 agreement) {
        ProposalState storage prop = proposals[proposalID];
        LRC.Option storage opt = prop.options[optionID];
        return (opt.votes, LRC.agreementRatio(opt), opt.agreement);
    }

    function proposalState(uint256 proposalID) public view returns (uint256 winnerOptionID, uint256 votes, uint256 status) {
        ProposalState memory p = proposals[proposalID];
        return (p.winnerOptionID, p.votes, p.status);
    }

    function getVote(address from, address delegatedTo, uint256 proposalID) public view returns (uint256 weight, uint256[] memory choices) {
        Vote memory v = _votes[from][delegatedTo][proposalID];
        return (v.weight, v.choices);
    }

    function tasksCount() public view returns (uint256) {
        return (tasks.length);
    }

    function getTask(uint256 i) public view returns (bool active, uint256 assignment, uint256 proposalID) {
        Task memory t = tasks[i];
        return (t.active, t.assignment, t.proposalID);
    }

    function vote(address delegatedTo, uint256 proposalID, uint256[] calldata choices) nonReentrant external {
        if (delegatedTo == address(0)) {
            delegatedTo = msg.sender;
        }

        ProposalState storage prop = proposals[proposalID];

        require(prop.params.proposalContract != address(0), "proposal with a given ID doesnt exist");
        require(isInitialStatus(prop.status), "proposal isn't active");
        require(block.timestamp >= prop.params.deadlines.votingStartTime, "proposal voting has't begun");
        require(_votes[msg.sender][delegatedTo][proposalID].weight == 0, "vote already exists");
        require(choices.length == prop.params.options.length, "wrong number of choices");

        uint256 weight = _processNewVote(proposalID, msg.sender, delegatedTo, choices);
        require(weight != 0, "zero weight");
    }

    function createProposal(address proposalContract) nonReentrant external payable {
        require(msg.value == proposalFee(), "paid proposal fee is wrong");

        lastProposalID++;
        _createProposal(lastProposalID, proposalContract);
        addTasks(lastProposalID);

        // burn a non-reward part of the proposal fee
        burn(proposalBurntFee());

        emit ProposalCreated(lastProposalID);
    }

    function _createProposal(uint256 proposalID, address proposalContract) internal {
        require(proposalContract != address(0), "empty proposal address");
        IProposal p = IProposal(proposalContract);
        // capture the parameters once to ensure that contract will not return different values
        uint256 pType = p.pType();
        Proposal.ExecType executable = p.executable();
        uint256 minVotes = p.minVotes();
        uint256 minAgreement = p.minAgreement();
        uint256[] memory opinionScales = p.opinionScales();
        uint256 votingStartTime = p.votingStartTime();
        uint256 votingMinEndTime = p.votingMinEndTime();
        uint256 votingMaxEndTime = p.votingMaxEndTime();
        bytes32[] memory options = p.options();
        // check the parameters and contract
        require(options.length != 0, "proposal options are empty - nothing to vote for");
        require(options.length <= maxOptions(), "too many options");
        bool ok;
        ok = proposalVerifier.verifyProposalParams(pType, executable, minVotes, minAgreement, opinionScales, votingStartTime, votingMinEndTime, votingMaxEndTime);
        require(ok, "proposal parameters failed verification");
        ok = proposalVerifier.verifyProposalContract(pType, proposalContract);
        require(ok, "proposal contract failed verification");
        // save the parameters
        ProposalState storage prop = proposals[proposalID];
        prop.params.pType = pType;
        prop.params.executable = executable;
        prop.params.minVotes = minVotes;
        prop.params.minAgreement = minAgreement;
        prop.params.opinionScales = opinionScales;
        prop.params.proposalContract = proposalContract;
        prop.params.deadlines.votingStartTime = votingStartTime;
        prop.params.deadlines.votingMinEndTime = votingMinEndTime;
        prop.params.deadlines.votingMaxEndTime = votingMaxEndTime;
        prop.params.options = options;
    }

    // cancelProposal cancels the proposal if no one managed to vote yet
    // must be sent from the proposal contract
    function cancelProposal(uint256 proposalID) nonReentrant external {
        ProposalState storage prop = proposals[proposalID];
        require(prop.params.proposalContract != address(0), "proposal with a given ID doesnt exist");
        require(isInitialStatus(prop.status), "proposal isn't active");
        require(prop.votes == 0, "voting has already begun");
        require(msg.sender == prop.params.proposalContract, "must be sent from the proposal contract");

        prop.status = statusCanceled();
        emit ProposalCanceled(proposalID);
    }

    // handleTasks triggers proposal deadlines processing for a specified range of tasks
    function handleTasks(uint256 startIdx, uint256 quantity) nonReentrant external {
        uint256 handled = 0;
        uint256 i;
        for (i = startIdx; i < tasks.length && i < startIdx + quantity; i++) {
            if (handleTask(i)) {
                handled += 1;
            }
        }

        require(handled != 0, "no tasks handled");

        emit TasksHandled(startIdx, i, handled);
        // reward the sender
        msg.sender.transfer(handled.mul(taskHandlingReward()));
    }

    // tasksCleanup erases inactive (handled) tasks backwards until an active task is met
    function tasksCleanup(uint256 quantity) nonReentrant external {
        uint256 erased;
        for (erased = 0; tasks.length > 0 && erased < quantity; erased++) {
            if (!tasks[tasks.length - 1].active) {
                tasks.length--;
            } else {
                break;
                // stop when first active task was met
            }
        }
        require(erased > 0, "no tasks erased");
        emit TasksErased(erased);
        // reward the sender
        msg.sender.transfer(erased.mul(taskErasingReward()));
    }

    // handleTask calls handleTaskAssignments and marks task as inactive if it was handled
    function handleTask(uint256 taskIdx) internal returns (bool handled) {
        require(taskIdx < tasks.length, "incorrect task index");
        Task storage task = tasks[taskIdx];
        if (!task.active) {
            return false;
        }
        handled = handleTaskAssignments(tasks[taskIdx].proposalID, task.assignment);
        if (handled) {
            task.active = false;
        }
        return handled;
    }

    // handleTaskAssignments iterates through assignment types and calls a specific handler
    function handleTaskAssignments(uint256 proposalID, uint256 assignment) internal returns (bool handled) {
        ProposalState storage prop = proposals[proposalID];
        if (!isInitialStatus(prop.status)) {
            // deactivate all tasks for non-active proposals
            return true;
        }
        if (assignment == TASK_VOTING) {
            return handleVotingTask(proposalID, prop);
        }
        return false;
    }

    // handleVotingTask handles only TASK_VOTING
    function handleVotingTask(uint256 proposalID, ProposalState storage prop) internal returns (bool handled) {
        uint256 minVotesAbs = minVotesAbsolute(governableContract.getTotalWeight(), prop.params.minVotes);
        bool must = block.timestamp >= prop.params.deadlines.votingMaxEndTime;
        bool may = block.timestamp >= prop.params.deadlines.votingMinEndTime && prop.votes >= minVotesAbs;
        if (!must && !may) {
            return false;
        }
        (bool proposalResolved, uint256 winnerID) = _calculateVotingTally(prop);
        if (proposalResolved) {
            (bool ok, bool expired) = executeProposal(prop, winnerID);
            if (!ok) {
                return false;
            }
            if (!expired) {
                prop.status = statusResolved();
                prop.winnerOptionID = winnerID;
                emit ProposalResolved(proposalID);
            } else {
                prop.status = statusExecutionExpired();
                emit ProposalExecutionExpired(proposalID);
            }
        } else {
            prop.status = statusFailed();
            emit ProposalRejected(proposalID);
        }
        return true;
    }

    function executeProposal(ProposalState storage prop, uint256 winnerOptionID) internal returns (bool, bool) {
        bool executable = prop.params.executable == Proposal.ExecType.CALL || prop.params.executable == Proposal.ExecType.DELEGATECALL;
        if (!executable) {
            return (true, false);
        }

        bool executionExpired = block.timestamp > prop.params.deadlines.votingMaxEndTime + maxExecutionPeriod();
        if (executionExpired) {
            // protection against proposals which revert or consume too much gas
            return (true, true);
        }
        address propAddr = prop.params.proposalContract;
        bool success;
        bytes memory result;
        if (prop.params.executable == Proposal.ExecType.CALL) {
            (success, result) = propAddr.call(abi.encodeWithSignature("execute_call(uint256)", winnerOptionID));
        } else {
            (success, result) = propAddr.delegatecall(abi.encodeWithSignature("execute_delegatecall(address,uint256)", propAddr, winnerOptionID));
        }
        result;
        return (success, false);
    }

    function _calculateVotingTally(ProposalState storage prop) internal view returns (bool, uint256) {
        uint256 minVotesAbs = minVotesAbsolute(governableContract.getTotalWeight(), prop.params.minVotes);
        uint256 mostAgreement = 0;
        uint256 winnerID = prop.params.options.length;
        if (prop.votes < minVotesAbs) {
            return (false, winnerID);
        }
        for (uint256 i = 0; i < prop.params.options.length; i++) {
            uint256 optionID = i;
            uint256 agreement = LRC.agreementRatio(prop.options[optionID]);

            if (agreement < prop.params.minAgreement) {
                // critical resistance against this option
                continue;
            }

            if (mostAgreement == 0 || agreement > mostAgreement) {
                mostAgreement = agreement;
                winnerID = i;
            }
        }

        return (winnerID != prop.params.options.length, winnerID);
    }

    // calculateVotingTally calculates the voting tally and returns {is finished, won option ID, total weight of votes}
    function calculateVotingTally(uint256 proposalID) external view returns (bool proposalResolved, uint256 winnerID, uint256 votes) {
        ProposalState storage prop = proposals[proposalID];
        (proposalResolved, winnerID) = _calculateVotingTally(prop);
        return (proposalResolved, winnerID, prop.votes);
    }

    function cancelVote(address delegatedTo, uint256 proposalID) nonReentrant external {
        if (delegatedTo == address(0)) {
            delegatedTo = msg.sender;
        }
        Vote memory v = _votes[msg.sender][delegatedTo][proposalID];
        require(v.weight != 0, "doesn't exist");
        require(isInitialStatus(proposals[proposalID].status), "proposal isn't active");
        _cancelVote(msg.sender, delegatedTo, proposalID);
    }

    function _cancelVote(address voter, address delegatedTo, uint256 proposalID) internal {
        Vote storage v = _votes[voter][delegatedTo][proposalID];
        if (v.weight == 0) {
            return;
        }

        if (voter != delegatedTo) {
            unOverrideDelegationWeight(delegatedTo, proposalID, v.weight);
        }

        removeChoicesFromProp(proposalID, v.choices, v.weight);
        delete _votes[voter][delegatedTo][proposalID];

        if (address(votebook) != address(0)) {
            votebook.onVoteCanceled(voter, delegatedTo, proposalID);
        }

        emit VoteCanceled(voter, delegatedTo, proposalID);
    }

    function makeVote(uint256 proposalID, address voter, address delegatedTo, uint256[] memory choices, uint256 weight) internal {
        _votes[voter][delegatedTo][proposalID] = Vote(weight, choices);
        addChoicesToProp(proposalID, choices, weight);

        if (address(votebook) != address(0)) {
            votebook.onVoted(voter, delegatedTo, proposalID);
        }

        emit Voted(voter, delegatedTo, proposalID, choices, weight);
    }

    function _processNewVote(uint256 proposalID, address voterAddr, address delegatedTo, uint256[] memory choices) internal returns (uint256) {
        if (delegatedTo == voterAddr) {
            // voter isn't a delegator
            uint256 weight = governableContract.getReceivedWeight(voterAddr);
            uint256 overridden = overriddenWeight[voterAddr][proposalID];
            if (weight > overridden) {
                weight -= overridden;
            } else {
                weight = 0;
            }
            if (weight == 0) {
                return 0;
            }
            makeVote(proposalID, voterAddr, voterAddr, choices, weight);
            return weight;
        } else {
            if (_votes[delegatedTo][delegatedTo][proposalID].choices.length > 0) {
                // recount vote from delegatedTo
                // Needed only in a case if delegatedTo's received weight has changed without calling recountVote
                _recountVote(delegatedTo, delegatedTo, proposalID);
            }
            // votes through one of delegations, overrides previous vote of "delegatedTo" (if any)
            uint256 delegatedWeight = governableContract.getWeight(voterAddr, delegatedTo);
            // reduce weight of vote of "delegatedTo" (current vote or any future vote)
            overrideDelegationWeight(delegatedTo, proposalID, delegatedWeight);
            if (delegatedWeight == 0) {
                return 0;
            }
            // make own vote
            makeVote(proposalID, voterAddr, delegatedTo, choices, delegatedWeight);
            return delegatedWeight;
        }
    }

    function recountVote(address voterAddr, address delegatedTo, uint256 proposalID) nonReentrant external {
        Vote storage v = _votes[voterAddr][delegatedTo][proposalID];
        Vote storage vSuper = _votes[delegatedTo][delegatedTo][proposalID];
        require(v.choices.length > 0, "doesn't exist");
        require(isInitialStatus(proposals[proposalID].status), "proposal isn't active");
        uint256 beforeSelf = v.weight;
        uint256 beforeSuper = vSuper.weight;
        _recountVote(voterAddr, delegatedTo, proposalID);
        uint256 afterSelf = v.weight;
        uint256 afterSuper = vSuper.weight;
        // check that some weight has changed due to recounting
        require(beforeSelf != afterSelf || beforeSuper != afterSuper, "nothing changed");
    }

    function _recountVote(address voterAddr, address delegatedTo, uint256 proposalID) internal returns (uint256) {
        uint256[] memory origChoices = _votes[voterAddr][delegatedTo][proposalID].choices;
        // cancel previous vote
        _cancelVote(voterAddr, delegatedTo, proposalID);
        // re-make vote
        return _processNewVote(proposalID, voterAddr, delegatedTo, origChoices);
    }

    function overrideDelegationWeight(address delegatedTo, uint256 proposalID, uint256 weight) internal {
        uint256 overridden = overriddenWeight[delegatedTo][proposalID];
        overridden = overridden.add(weight);
        overriddenWeight[delegatedTo][proposalID] = overridden;
        Vote storage v = _votes[delegatedTo][delegatedTo][proposalID];
        if (v.choices.length > 0) {
            v.weight = v.weight.sub(weight);
            removeChoicesFromProp(proposalID, v.choices, weight);
        }
        emit VoteWeightOverridden(delegatedTo, weight);
    }

    function unOverrideDelegationWeight(address delegatedTo, uint256 proposalID, uint256 weight) internal {
        uint256 overridden = overriddenWeight[delegatedTo][proposalID];
        overridden = overridden.sub(weight);
        overriddenWeight[delegatedTo][proposalID] = overridden;
        Vote storage v = _votes[delegatedTo][delegatedTo][proposalID];
        if (v.choices.length > 0) {
            v.weight = v.weight.add(weight);
            addChoicesToProp(proposalID, v.choices, weight);
        }
        emit VoteWeightUnOverridden(delegatedTo, weight);
    }

    function addChoicesToProp(uint256 proposalID, uint256[] memory choices, uint256 weight) internal {
        ProposalState storage prop = proposals[proposalID];

        prop.votes = prop.votes.add(weight);

        for (uint256 i = 0; i < prop.params.options.length; i++) {
            prop.options[i].addVote(choices[i], weight, prop.params.opinionScales);
        }
    }

    function removeChoicesFromProp(uint256 proposalID, uint256[] memory choices, uint256 weight) internal {
        ProposalState storage prop = proposals[proposalID];

        prop.votes = prop.votes.sub(weight);

        for (uint256 i = 0; i < prop.params.options.length; i++) {
            prop.options[i].removeVote(choices[i], weight, prop.params.opinionScales);
        }
    }

    function addTasks(uint256 proposalID) internal {
        tasks.push(Task(true, TASK_VOTING, proposalID));
    }

    function burn(uint256 amount) internal {
        address(0).transfer(amount);
    }

    function sanitizeWinnerID(uint256 proposalID) external {
        ProposalState storage prop = proposals[proposalID];
        require(prop.status == STATUS_RESOLVED, "proposal isn't resolved");
        require(prop.params.executable == Proposal.ExecType.NONE, "proposal is executable");
        require(prop.winnerOptionID == 0, "winner ID is correct");
        (, prop.winnerOptionID) = _calculateVotingTally(prop);
    }

    function upgrade(address _votebook) external {
        require(address(votebook) == address(0), "already set");
        votebook = VotesBookKeeper(_votebook);
        // erase leftovers from upgradeability proxy
        assembly {
            sstore(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103, 0)
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, 0)
        }
    }
}

pragma solidity ^0.5.0;

import "../ownership/Ownable.sol";

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

pragma solidity ^0.5.0;

/**
 * @dev The version info of this contract
 */
contract Version {
    /**
     * @dev Returns the version of this contract.
     */
    function version() public pure returns (bytes4) {
        // version 00.0.2
        return "0002";
    }
}

pragma solidity ^0.5.0;

import "../common/Decimal.sol";
import "../common/SafeMath.sol";

/**
 * @dev LRC implements the "least resistant consensus" paper. More detailed description can be found in Fantom's docs.
 */
library LRC {
    using SafeMath for uint256;

    struct Option {
        uint256 votes;
        uint256 agreement;
    }

    // agreementRatio is a ratio of option agreement (higher -> option is less supported)
    function agreementRatio(Option storage self) internal view returns (uint256) {
        if (self.votes == 0) {
            // avoid division by zero
            return 0;
        }
        return self.agreement.mul(Decimal.unit()).div(self.votes);
    }

    function maxAgreementScale(uint256[] storage opinionScales) internal view returns (uint256) {
        return opinionScales[opinionScales.length - 1];
    }

    function addVote(Option storage self, uint256 opinionID, uint256 weight, uint256[] storage opinionScales) internal {
        require(opinionID < opinionScales.length, "wrong opinion ID");

        uint256 scale = opinionScales[opinionID];

        self.votes = self.votes.add(weight);
        self.agreement = self.agreement.add(weight.mul(scale).div(maxAgreementScale(opinionScales)));
    }

    function removeVote(Option storage self, uint256 opinionID, uint256 weight, uint256[] storage opinionScales) internal {
        require(opinionID < opinionScales.length, "wrong opinion ID");

        uint256 scale = opinionScales[opinionID];

        self.votes = self.votes.sub(weight);
        self.agreement = self.agreement.sub(weight.mul(scale).div(maxAgreementScale(opinionScales)));
    }
}

pragma solidity ^0.5.0;

import "../common/Decimal.sol";
import "../common/SafeMath.sol";
import "../model/Governable.sol";
import "../proposal/SoftwareUpgradeProposal.sol";
import "./Constants.sol";

/**
 * @dev Various constants for governance governance settings
 */
contract GovernanceSettings is Constants {
    uint256 constant _proposalFee = _proposalBurntFee + _taskHandlingReward + _taskErasingReward;
    uint256 constant _proposalBurntFee = 50 * 1e18;
    uint256 constant _taskHandlingReward = 40 * 1e18;
    uint256 constant _taskErasingReward = 10 * 1e18;
    uint256 constant _maxOptions = 10;
    uint256 constant _maxExecutionPeriod = 3 days;

    // @dev proposalFee is the fee for a proposal
    function proposalFee() public pure returns (uint256) {
        return _proposalFee;
    }

    // @dev proposalBurntFee is the burnt part of fee for a proposal
    function proposalBurntFee() public pure returns (uint256) {
        return _proposalBurntFee;
    }

    // @dev taskHandlingReward is a reward for handling each task
    function taskHandlingReward() public pure returns (uint256) {
        return _taskHandlingReward;
    }

    // @dev taskErasingReward is a reward for erasing each task
    function taskErasingReward() public pure returns (uint256) {
        return _taskErasingReward;
    }

    // @dev maxOptions maximum number of options to choose
    function maxOptions() public pure returns (uint256) {
        return _maxOptions;
    }

    // maxExecutionPeriod is maximum time for which proposal is executable after maximum voting end date
    function maxExecutionPeriod() public pure returns (uint256) {
        return _maxExecutionPeriod;
    }
}

pragma solidity ^0.5.0;

import "../common/SafeMath.sol";
import "../common/Decimal.sol";

contract StatusConstants {
    enum Status {
        INITIAL,
        RESOLVED,
        FAILED
    }

    // bit map
    uint256 constant STATUS_INITIAL = 0;
    uint256 constant STATUS_RESOLVED = 1;
    uint256 constant STATUS_FAILED = 1 << 1;
    uint256 constant STATUS_CANCELED = 1 << 2;
    uint256 constant STATUS_EXECUTION_EXPIRED = 1 << 3;

    function statusInitial() internal pure returns (uint256) {
        return STATUS_INITIAL;
    }

    function statusExecutionExpired() internal pure returns (uint256) {
        return STATUS_EXECUTION_EXPIRED;
    }

    function statusFailed() internal pure returns (uint256) {
        return STATUS_FAILED;
    }

    function statusCanceled() internal pure returns (uint256) {
        return STATUS_CANCELED;
    }

    function statusResolved() internal pure returns (uint256) {
        return STATUS_RESOLVED;
    }

    function isInitialStatus(uint256 status) internal pure returns (bool) {
        return status == STATUS_INITIAL;
    }

    // task assignments
    uint256 constant TASK_VOTING = 1;
}

contract Constants is StatusConstants {
    using SafeMath for uint256;

    function minVotesAbsolute(uint256 totalWeight, uint256 minVotesRatio) public pure returns (uint256) {
        return totalWeight * minVotesRatio / Decimal.unit();
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}

pragma solidity ^0.5.0;

import "../proposal/base/IProposal.sol";

library Proposal {
    struct Timeline {
        uint256 votingStartTime; // date when the voting starts
        uint256 votingMinEndTime; // date of earliest possible voting end
        uint256 votingMaxEndTime; // date of latest possible voting end
    }

    enum ExecType {
        NONE,
        CALL,
        DELEGATECALL
    }

    struct Parameters {
        uint256 pType; // type of proposal (e.g. plaintext, software upgrade)
        ExecType executable; // proposal execution type when proposal gets resolved
        uint256 minVotes; // min. quorum (ratio)
        // minAgreement is the minimum acceptable ratio of agreement for an option.
        // It's guaranteed not to win otherwise.
        uint256 minAgreement; // min. agreement threshold for options (ratio)
        uint256[] opinionScales;
        address proposalContract; // contract which stores the proposal data and executes its logic
        bytes32[] options;
        Timeline deadlines;
    }
}

pragma solidity ^0.5.0;

import "./base/Cancelable.sol";
import "./base/DelegatecallExecutableProposal.sol";

/**
 * @dev An interface to update this contract to a destination address
 */
interface Upgradability {
    function upgradeTo(address newImplementation) external;
}

/**
 * @dev SoftwareUpgrade proposal
 */
contract SoftwareUpgradeProposal is DelegatecallExecutableProposal, Cancelable {
    address public upgradeableContract;
    address public newImplementation;

    constructor(string memory __name, string memory __description,
        uint256 __minVotes, uint256 __minAgreement, uint256 __start, uint256 __minEnd, uint256 __maxEnd,
        address __upgradeableContract, address __newImplementation, address verifier) public {
        _name = __name;
        _description = __description;
        _options.push(bytes32("Level of agreement"));
        _minVotes = __minVotes;
        _minAgreement = __minAgreement;
        _opinionScales = [0, 1, 2, 3, 4];
        _start = __start;
        _minEnd = __minEnd;
        _maxEnd = __maxEnd;
        upgradeableContract = __upgradeableContract;
        newImplementation = __newImplementation;
        // verify the proposal right away to avoid deploying a wrong proposal
        if (verifier != address(0)) {
            require(verifyProposalParams(verifier), "failed verification");
        }
    }

    function execute_delegatecall(address selfAddr, uint256) external {
        SoftwareUpgradeProposal self = SoftwareUpgradeProposal(selfAddr);
        Upgradability(self.upgradeableContract()).upgradeTo(self.newImplementation());
    }
}

pragma solidity ^0.5.0;

import "../governance/Proposal.sol";

/**
 * @dev A verifier can verify a proposal's inputs such as proposal parameters and proposal contract.
 */
interface IProposalVerifier {
    // Verifies proposal parameters with respect to the stored template of same type
    function verifyProposalParams(uint256 pType, Proposal.ExecType executable, uint256 minVotes, uint256 minAgreement, uint256[] calldata opinionScales, uint256 start, uint256 minEnd, uint256 maxEnd) external view returns (bool);

    // Verifies proposal contract of the specified type and address
    function verifyProposalContract(uint256 pType, address propAddr) external view returns (bool);
}

pragma solidity ^0.5.0;

import "../../governance/Proposal.sol";

/**
 * @dev An abstract proposal
 */
contract IProposal {
    // Get type of proposal (e.g. plaintext, software upgrade)
    function pType() external view returns (uint256);
    // Proposal execution type when proposal gets resolved
    function executable() external view returns (Proposal.ExecType);
    // Get min. turnout (ratio)
    function minVotes() external view returns (uint256);
    // Get min. agreement for options (ratio)
    function minAgreement() external view returns (uint256);
    // Get scales for opinions
    function opinionScales() external view returns (uint256[] memory);
    // Get options to choose from
    function options() external view returns (bytes32[] memory);
    // Get date when the voting starts
    function votingStartTime() external view returns (uint256);
    // Get date of earliest possible voting end
    function votingMinEndTime() external view returns (uint256);
    // Get date of latest possible voting end
    function votingMaxEndTime() external view returns (uint256);

    // execute proposal logic on approval (if executable == call)
    // Called via call opcode from governance contract
    function execute_call(uint256 optionID) external;

    // execute proposal logic on approval (if executable == delegatecall)
    // Called via delegatecall opcode from governance contract, hence selfAddress is provided
    function execute_delegatecall(address selfAddress, uint256 optionID) external;

    // Get human-readable name
    function name() external view returns (string memory);
    // Get human-readable description
    function description() external view returns (string memory);

    // Standard proposal types. The standard may be outdated, actual proposal templates may differ
    enum StdProposalTypes {
        NOT_INIT,
        UNKNOWN_NON_EXECUTABLE,
        UNKNOWN_CALL_EXECUTABLE,
        UNKNOWN_DELEGATECALL_EXECUTABLE
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Governable defines the main interface for all governable items
 */
interface Governable {
    // Gets the total weight of voters
    function getTotalWeight() external view returns (uint256);

    // Gets the received delegated weight
    function getReceivedWeight(address addr) external view returns (uint256);

    // Gets the voting weight which is delegated from the specified address to the specified address
    function getWeight(address from, address to) external view returns (uint256);
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;
import "./Initializable.sol";

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
 */
contract ReentrancyGuard is Initializable {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    function initialize() internal initializer {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "../common/Initializable.sol";

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

pragma solidity ^0.5.0;

import "./BaseProposal.sol";
import "../../governance/Proposal.sol";

contract DelegatecallExecutableProposal is BaseProposal {
    // Returns execution type
    function executable() public view returns (Proposal.ExecType) {
        return Proposal.ExecType.DELEGATECALL;
    }

    function pType() public view returns (uint256) {
        return uint256(StdProposalTypes.UNKNOWN_DELEGATECALL_EXECUTABLE);
    }

    function execute_delegatecall(address, uint256) external {
        require(false, "must be overridden");
    }
}

pragma solidity ^0.5.0;

import "../../ownership/Ownable.sol";
import "../../governance/Governance.sol";

contract Cancelable is Ownable {
    constructor() public {
        Ownable.initialize(msg.sender);
    }

    function cancel(uint256 myID, address govAddress) external onlyOwner {
        Governance gov = Governance(govAddress);
        gov.cancelProposal(myID);
    }
}

pragma solidity ^0.5.0;

library Decimal {
    // unit is used for decimals, e.g. 0.123456
    function unit() internal pure returns (uint256) {
        return 1e18;
    }
}

pragma solidity >=0.4.24 <0.7.0;


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

pragma solidity ^0.5.0;

import "../../common/SafeMath.sol";
import "./IProposal.sol";
import "../../verifiers/IProposalVerifier.sol";
import "../../governance/Proposal.sol";

/**
 * @dev A base for any proposal
 */
contract BaseProposal is IProposal {
    using SafeMath for uint256;

    string _name;
    string _description;
    bytes32[] _options;

    uint256 _minVotes;
    uint256 _minAgreement;
    uint256[] _opinionScales;

    uint256 _start;
    uint256 _minEnd;
    uint256 _maxEnd;

    // verifyProposalParams passes proposal parameters to a given verifier
    function verifyProposalParams(address verifier) public view returns (bool) {
        IProposalVerifier proposalVerifier = IProposalVerifier(verifier);
        return proposalVerifier.verifyProposalParams(pType(), executable(), minVotes(), minAgreement(), opinionScales(), votingStartTime(), votingMinEndTime(), votingMaxEndTime());
    }

    function pType() public view returns (uint256) {
        require(false, "must be overridden");
        return uint256(StdProposalTypes.NOT_INIT);
    }

    function executable() public view returns (Proposal.ExecType) {
        require(false, "must be overridden");
        return Proposal.ExecType.NONE;
    }

    function minVotes() public view returns (uint256) {
        return _minVotes;
    }

    function minAgreement() public view returns (uint256) {
        return _minAgreement;
    }

    function opinionScales() public view returns (uint256[] memory) {
        return _opinionScales;
    }

    function options() public view returns (bytes32[] memory) {
        return _options;
    }

    function votingStartTime() public view returns (uint256) {
        return block.timestamp + _start;
    }

    function votingMinEndTime() public view returns (uint256) {
        return votingStartTime() + _minEnd;
    }

    function votingMaxEndTime() public view returns (uint256) {
        return votingStartTime() + _maxEnd;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function description() public view returns (string memory) {
        return _description;
    }

    function execute_delegatecall(address, uint256) external {
        require(false, "not delegatecall-executable");
    }

    function execute_call(uint256) external {
        require(false, "not call-executable");
    }
}
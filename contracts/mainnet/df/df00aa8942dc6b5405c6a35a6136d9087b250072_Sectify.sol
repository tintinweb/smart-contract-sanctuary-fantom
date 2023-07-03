/**
 *Submitted for verification at FtmScan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Sectify {
    // ============0xc2e9Ac0a04cd6cdB631B205e039e5894967c77eA=========
    address immutable umpire;
    uint256 startDate; //when will election start
    uint256 duration; //how long will voting last

    modifier OnlyUmpire() {
        require(
            umpire == msg.sender,
            "you're not authorized to call this function"
        );
        _;
    }

    modifier ElectionIsOver(Office _office) {
        require(
            scheduleDetails[_office].votingEnds < block.timestamp,
            "voting has NOT ended, WAIT!!!"
        );
        _;
    }

    enum Office {
        none,
        President,
        Senate,
        HoR,
        Governor,
        HoA
    }

    enum Verify {
        nill,
        passed,
        failed,
        pending
    }
    // ======voter==========
    struct Voter {
        uint256 voterId;
        address voterAccount;
        Office[] officesVotedFor;
    }
    uint256[] allAccreditedVoters;
    mapping(uint256 => Voter) voterDetails;
    mapping(uint256 => bool) hasAccredited; //use this for iteration
    mapping(uint256 => mapping(Office => uint256)) voterChoice;
    // ======candidate==========
    struct Candidate {
        uint256 candidateId;
        address candidateAddress;
        uint256 candidateVotes;
        Office officeOfChoice;
        Verify verificationStatus;
    }
    uint256[] allCandidates;
    mapping(uint256 => Candidate) candidateDetails;
    mapping(uint256 => bool) hasRegistered; //use this for iteration
    mapping(Office => uint256[]) allCandidatesByOffice; //use this to collate result
    // ======schedule==========
    struct Schedule {
        Office officeInContest;
        uint256 votingStarts;
        uint256 duration;
        uint256 votingEnds;
    }
    mapping(Office => Schedule) scheduleDetails;
    mapping (Office=>bool) elecetionScheduled;

    mapping(Office => mapping(uint256 => uint256)) pollResults;
    // ========winners=======
    mapping(Office => uint256) finalWinner;

    // mapping (Office=>uint256[]) winnersTie;
    // =======constructor==========
    constructor() {
        umpire = msg.sender;
    }

    // /////get a candidate registered//////////
    function registerCandidate(uint256 _id, Office _vyingFor) public {
        // require(elecetionScheduled[_office], "election timetable has not been set, contact the umpire");  
        require(
            scheduleDetails[_vyingFor].votingStarts > block.timestamp,
            "Accreditation is closed, voting has started"
        );
        require(msg.sender != umpire,"You're the umpire, you're not allowed to contest");
        require(!hasRegistered[_id], "please this Candidate has been accredited, contact admin for change of data");

        require(
            scheduleDetails[_vyingFor].votingStarts > block.timestamp,
            "registration is closed, voting has started"
        );
        require(msg.sender != address(0), "candidate address is invalid");

        // if (hasRegistered[_id]) {
        //     Candidate storage _candidateDetails = candidateDetails[_id];
        //     // if you have registered, you're only allowed to edit your address and office-of-choice
        //     _candidateDetails.candidateAddress = msg.sender;
        //     _candidateDetails.officeOfChoice = _vyingFor;
        // } else {
            
            candidateDetails[_id] = Candidate({
                candidateId: _id,
                candidateAddress: msg.sender,
                candidateVotes: 0,
                officeOfChoice: _vyingFor,
                verificationStatus: Verify.nill
            });
            allCandidates.push(_id);
            hasRegistered[_id] = true;
            //for easy collation of result
            allCandidatesByOffice[_vyingFor].push(_id);        
    }

    function verifyCandidate(uint256 _candidateId) public OnlyUmpire {
        Candidate storage candidate = candidateDetails[_candidateId];
        candidate.verificationStatus = Verify.passed;
    }

    //
    function accrediteVoter(uint256 _voterId, Office _office) public { 
        require(elecetionScheduled[_office], "election timetable has not been set, contact the umpire");  
        require(
            scheduleDetails[_office].votingStarts > block.timestamp,
            "Accreditation is closed, voting has started"
        );
        require(msg.sender != address(0), "voter address is invalid");
        require(msg.sender != umpire,"You're the umpire, you're not allowed to vote");
        require(!hasAccredited[_voterId], "please this Voter has been accredited, contact admin for complaints");

            Office[] memory allOfficesVoted;
            hasAccredited[_voterId] = true;
            voterDetails[_voterId] = Voter({
                voterId: _voterId,
                voterAccount: msg.sender,
                officesVotedFor: allOfficesVoted
            });
            allAccreditedVoters.push(_voterId);
    }

    function setElectionSchedule(
        uint256 _start,
        uint256 _duration,
        Office _office
    ) public OnlyUmpire returns (bool) {
        require(
            uint8(_office) > 0 && uint8(_office) < 6,
            "invalid office supplied"
        );
        require(
            _start > block.timestamp,
            "the start date must be in the future"
        );
        require(_duration > 0, "the duration is too short");

        Schedule storage schedule = scheduleDetails[_office];
        schedule.duration = _duration;
        schedule.officeInContest = _office;
        schedule.votingStarts = _start;
        schedule.votingEnds = _start + _duration;

        elecetionScheduled[_office] = true;

        return true;
    }

    function castVote(
        Office _office,
        uint256 candidateOfChoice,
        uint256 _voterId
    ) public {
        require(
            scheduleDetails[_office].votingEnds > block.timestamp,
            "voting has ended"
        );
        require(
            scheduleDetails[_office].votingStarts < block.timestamp,
            "voting has not started"
        );
        require(
            voterDetails[_voterId].voterAccount == msg.sender,
            "You're not accredited"
        );
        require(
            candidateDetails[candidateOfChoice].officeOfChoice == _office,
            "your choice is not contesting for this position"
        );

        if (uint8(_office) == 1) {
            require(
                voterChoice[_voterId][Office.President] == 0,
                "you have already voted for president"
            );
            voterDetails[_voterId].officesVotedFor.push(Office.President);
            voterChoice[_voterId][Office.President] = candidateOfChoice;
            candidateDetails[candidateOfChoice].candidateVotes++;
        } else if (uint8(_office) == 2) {
            require(
                voterChoice[_voterId][Office.Senate] == 0,
                "you have already voted for Senate"
            );
            voterDetails[_voterId].officesVotedFor.push(Office.Senate);
            voterChoice[_voterId][Office.Senate] = candidateOfChoice;
            candidateDetails[candidateOfChoice].candidateVotes++;
        } else if (uint8(_office) == 3) {
            require(
                voterChoice[_voterId][Office.HoR] == 0,
                "you have already voted for House of Representative"
            );
            voterDetails[_voterId].officesVotedFor.push(Office.HoR);
            voterChoice[_voterId][Office.HoR] = candidateOfChoice;
            candidateDetails[candidateOfChoice].candidateVotes++;
        } else if (uint8(_office) == 4) {
            require(
                voterChoice[_voterId][Office.Governor] == 0,
                "you have already voted for Governor"
            );
            voterDetails[_voterId].officesVotedFor.push(Office.Governor);
            voterChoice[_voterId][Office.Governor] = candidateOfChoice;
            candidateDetails[candidateOfChoice].candidateVotes++;
        } else if (uint8(_office) == 5) {
            require(
                voterChoice[_voterId][Office.HoA] == 0,
                "you have already voted for House of Assemby"
            );
            voterDetails[_voterId].officesVotedFor.push(Office.HoA);
            voterChoice[_voterId][Office.HoA] = candidateOfChoice;
            candidateDetails[candidateOfChoice].candidateVotes++;
        } else {
            // require(voterChoice[_voterId][Office.none] == 0, "you have already voted for president");
            voterDetails[_voterId].officesVotedFor.push(Office.none);
            voterChoice[_voterId][Office.none] = 0;
        }
    }

    function getAllVoters() public view {
        uint256 counter = 0;
        uint256[] memory allVoters = allAccreditedVoters;
        uint256 votersCount = allVoters.length;
        for (counter; counter < votersCount; counter++) {
            voterDetails[allVoters[counter]];
        }
        // return allVotersDetails;
    }

    function getAVoter(uint256 _id) public view returns (Voter memory) {
        return voterDetails[_id];
    }

    function getAllCandidates() public view {
        uint256 counter = 0;
        uint256[] memory _allCandidates = allCandidates;
        uint256 candidateCount = _allCandidates.length;
        for (counter; counter < candidateCount; counter++) {
            candidateDetails[_allCandidates[counter]];
        }
    }

    function getACandidate(uint256 _id) public view returns (Candidate memory) {
        return candidateDetails[_id];
    }

    function collatePollResults(Office _office)
        public
        ElectionIsOver(_office)
    {
        uint256[] memory _allCandidates = allCandidatesByOffice[_office];
        uint256 totalCandidates = _allCandidates.length;
        uint256 _finalWinner;
        //if there is a tie, record the vote and conduct a new poll for the candidates with tie
        uint256 _tieScore;

        for (uint256 i = 0; i < totalCandidates; i++) {
            Candidate memory candidateData = candidateDetails[
                _allCandidates[i]
            ];
            pollResults[_office][_allCandidates[i]] = candidateData
                .candidateVotes;
            // let's get the winner
            if (i == 0) {
                _finalWinner = _allCandidates[0];
            } else if (
                candidateData.candidateVotes >
                candidateDetails[_finalWinner].candidateVotes
            ) {
                _finalWinner = _allCandidates[i];
            } else if (
                candidateData.candidateVotes ==
                candidateDetails[_finalWinner].candidateVotes
            ) {
                // we have a tie, save the score
                _tieScore = candidateData.candidateVotes;
            }
        }
        // ====publish the winner onchain======
        if (_tieScore > 0) {
            _finalWinner = 0; //we don't a winner yet as we have a tie
        }
        finalWinner[_office] = _finalWinner;
    }

    function getWinner(Office _office)
        public
        view
        ElectionIsOver(_office)
        returns (Candidate memory)
    {
        return candidateDetails[finalWinner[_office]];
    }
}
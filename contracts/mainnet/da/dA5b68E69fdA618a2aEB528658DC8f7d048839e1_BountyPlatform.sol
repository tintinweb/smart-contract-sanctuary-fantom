// SPDX-License-Identifier: MIT

pragma solidity >=0.8.18 <0.9.0;

contract BountyPlatform {
    uint256 organisationCount;
    uint256 bountyCount;
    uint256 memberCount;
    uint256 organisationMemberCount;
    uint256 submissionCount;
    address payable owner;
    bool internal locked;

    // enums
    enum BountyStatus {
        NotStarted,
        Active,
        Closed
    }

    BountyStatus status;

    // struct
    struct Organisation {
        uint256 id;
        string name;
        string logoIPFS;
        address payable creatorAddress;
        uint256 totalBountiesCreated;
        uint256 totalAmountSpent;
        uint256 totalMembers;
    }

    struct Bounty {
        uint256 organisationId;
        uint256 bountyId;
        string title;
        address payable bountyCreator;
        string descriptionGithubLink;
        uint256 bountyAmount;
        uint256 startTime;
        uint256 endTime;
        BountyStatus status;
        uint256 totalBounterHunters;
        uint256 totalSubmittedWorks;
    }

    struct SubmitWork {
        uint256 submissionId;
        uint256 organisationId;
        uint256 bountyId;
        address payable participant;
        string submissionLink;
        bool acceptanceStatus;
        uint256 earnings;
    }

    struct Member {
        uint256 id;
        address memberAdress;
    }

    struct OrganisationMember {
        uint256 id;
        string organizationId;
        address memberAdress;
    }

    // events
    event LogOrganisation(
        uint256 id,
        string name,
        string logoIPFS,
        address payable creatorAddress,
        uint256 totalBountiesCreated,
        uint256 totalAmountSpent,
        uint256 totalMembers
    );
    event LogBounty(
        uint256 organisationId,
        // uint256 bountyId,
        string title,
        address payable indexed bountyCreator,
        string descriptionGithubLink,
        uint256 bountyAmount,
        uint256 startTime,
        uint256 endTIme
    );

    event LogSubmitWork(
        uint256 submissionId,
        uint256 organisationId,
        uint256 bountyId,
        address payable indexed participant,
        string submissionLink,
        bool acceptanceStatus,
        uint256 earnings
    );

    event LogMember(uint256 id, address indexed memberAdress);

    event LogOrganisationMember(
        uint256 id,
        uint256 organizationId,
        address indexed memberAdress
    );

    event LogJoinBounty(
        uint256 organisationId,
        uint256 bountyId,
        address indexed bountyHounterAddress
    );

    event LogUpdateSubmission(
        uint256 organisationId,
        uint256 bountyId,
        string submissionLink
    );

    event LogAcceptSubmission(
        uint256 organisationId,
        uint256 bountyId,
        address indexed hunterAddress,
        bool acceptanceStatus
    );

    event LogPayBountyWinners(
        uint256 organisationId,
        uint256 bountyId,
        uint256 amount
    );

    // Arrays
    Organisation[] organisationList;
    Bounty[] bounties;
    Member[] members;
    Member[] organisationMemberList;
    SubmitWork[] submissionList;

    // mappings
    mapping(address => uint256) organisationBountyMapCount;
    mapping(uint256 => Bounty[]) bountyMapList;
    mapping(address => mapping(uint256 => mapping(uint256 => Bounty))) bountyMembers;
    mapping(uint256 => Organisation) organistations;
    mapping(uint256 => Member[]) organisationMembers;
    mapping(uint256 => mapping(uint256 => Bounty)) bountyOrgMap;
    mapping(address => Member) users;
    mapping(address => bool) alreadyExist;
    mapping(address => bool) alreadySubmitted;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) bountyParticipant;
    mapping(address => mapping(uint256 => bool)) alreadyMember;
    mapping(address => mapping(uint256 => mapping(uint256 => SubmitWork[]))) worksubmissions;
    mapping(address => mapping(uint256 => mapping(uint256 => SubmitWork))) workMapSubmissions;
    mapping(uint256 => mapping(uint256 => SubmitWork[])) submissions;
    mapping(address => mapping(uint256 => mapping(uint256 => address[]))) bountyParticipants;
    mapping(address => bool) orgExist;

    // Modifiers
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier onlyOrganisationCreator(uint256 _organisationId) {
        require(
            organistations[_organisationId].creatorAddress == msg.sender,
            "You are not the creator"
        );
        _;
    }

    modifier onlyBountyCreator(uint256 __organisationId, uint256 _bountyId) {
        require(
            bountyMapList[__organisationId][_bountyId].bountyCreator ==
                msg.sender,
            "You are not the bounty creator"
        );
        _;
    }

    modifier registeredUser() {
        require(
            alreadyExist[msg.sender],
            "You have not yet setup your account"
        );
        _;
    }

    modifier checkMemberAndOrganisationExist(uint256 _organisationId) {
        require(
            alreadyMember[msg.sender][_organisationId],
            "You are not yet a member of this organisation"
        );
        require(
            organisationList[_organisationId].id == _organisationId,
            "Organisation does not exist"
        );
        _;
    }

    modifier checkBountyExist(uint256 _bountyId, uint256 _organisationId) {
        Bounty[] storage bounty = bountyMapList[_bountyId];
        require(
            bounty[_bountyId].bountyId == _bountyId,
            "Bounty does not exist"
        );
        require(
            bountyParticipant[msg.sender][_organisationId][_bountyId],
            "You have not yet joined this bounty"
        );
        _;
    }

    modifier checkBountyPeriod(uint256 _bountyId) {
        Bounty[] storage bounty = bountyMapList[_bountyId];
        require(
            block.timestamp >= bounty[_bountyId].startTime,
            "Bounty has not started"
        );
        require(
            block.timestamp >= bounty[_bountyId].endTime,
            "Bounty period has not ended yet"
        );

        _;
    }

    modifier checkUniqueOrganizationName(string memory name) {
        bool exists = false;
        for (uint256 i = 0; i < organisationList.length; i++) {
            if (
                keccak256(bytes(organisationList[i].name)) ==
                keccak256(bytes(name))
            ) {
                exists = true;
                break;
            }
        }
        require(!exists, "Organization with that name already exists");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function createAccount() public {
        require(!alreadyExist[msg.sender], "Account already exist");

        Member storage member = users[msg.sender];
        member.id = memberCount;
        member.memberAdress = msg.sender;
        members.push(Member(memberCount, msg.sender));
        memberCount++;
        alreadyExist[msg.sender] = true;

        emit LogMember(memberCount, msg.sender);
    }

    function createOrganisation(
        string memory name,
        string memory logoIPFS
    ) public registeredUser checkUniqueOrganizationName(name) {
        // check to ensure the the creator has registered
        // check to ensure the same organisation is not registered twice
        Organisation storage organisation = organistations[organisationCount];

        require(bytes(name).length > 0, "Organisation name required");
        require(bytes(logoIPFS).length > 0, "Organisation logo is required");

        uint256 _totalBountiesCreated;
        uint256 _totalAmountSpent;
        uint256 _totalMembers;

        organisation.id = organisationCount;
        organisation.name = name;
        organisation.logoIPFS = logoIPFS;
        organisation.totalBountiesCreated = _totalBountiesCreated;
        organisation.totalAmountSpent = _totalAmountSpent;
        organisation.totalMembers = _totalMembers;
        organisation.creatorAddress = payable(msg.sender);

        // push to list
        organisationList.push(
            Organisation(
                organisationCount,
                name,
                logoIPFS,
                payable(msg.sender),
                _totalBountiesCreated,
                _totalAmountSpent,
                _totalMembers
            )
        );

        organisationCount++;
        orgExist[msg.sender] = true;

        emit LogOrganisation(
            organisationCount,
            name,
            logoIPFS,
            payable(msg.sender),
            _totalBountiesCreated,
            _totalAmountSpent,
            _totalMembers
        );
    }

    function getOrganisations() public view returns (Organisation[] memory) {
        return organisationList;
    }

    function getOrganisation(
        uint id
    )
        public
        view
        returns (
            uint256 _id,
            string memory name,
            string memory logoIPFS,
            address creator,
            uint256 totalBountiesCreated,
            uint256 totalAmountSpent,
            uint256 totalMembers
        )
    {
        return (
            organisationList[id].id,
            organisationList[id].name,
            organisationList[id].logoIPFS,
            organisationList[id].creatorAddress,
            organisationList[id].totalBountiesCreated,
            organisationList[id].totalAmountSpent,
            organisationList[id].totalMembers
        );
    }

    function joinOrganisation(uint256 _organisationId) public registeredUser {
        require(
            !alreadyMember[msg.sender][_organisationId],
            "You are not yet a member of this organisation"
        );
        organisationList[_organisationId].totalMembers += 1;
        Member[] storage membersList = organisationMembers[_organisationId];
        membersList.push(Member(memberCount, msg.sender));
        organisationMemberCount++;
        alreadyMember[msg.sender][_organisationId] = true;

        emit LogOrganisationMember(
            organisationMemberCount,
            _organisationId,
            msg.sender
        );
    }

    function getOrganisationMembers(
        uint256 _organisationId
    ) public view returns (Member[] memory) {
        return organisationMembers[_organisationId];
    }

    function getMembers() public view returns (Member[] memory) {
        return members;
    }

    receive() external payable {}

    function createBounty(
        uint256 organisationId,
        string memory title,
        // address bountyCreator,
        string memory descriptionGithubLink,
        uint256 startTime,
        uint256 endTime
    )
        public
        payable
        registeredUser
        checkMemberAndOrganisationExist(organisationId)
        noReentrant
    {
        // checks to ensure the organisaction exist
        // check to ensure the bounty creator has registered
        // check to ensure the start and endtime are in the future and endtime not less than start time
        // check the value of status base on the start time
        // the creator of the bounty should be the creator of the organisation

        uint256 _totalBounterHunters;
        uint256 _totalSubmittedWorks;

        uint256 _bountyId = organisationBountyMapCount[msg.sender];
        Organisation storage organisation = organisationList[organisationId];
        organisation.totalAmountSpent += msg.value;
        organisation.totalBountiesCreated += 1;
        Bounty[] storage bounty = bountyMapList[organisationId];

        require(
            startTime > block.timestamp,
            "Bounty start time must be in the future"
        );
        require(
            endTime > startTime,
            "Bounty end time must be after start time"
        );
        require(
            msg.sender == organisation.creatorAddress,
            "You are not authorised to post bounty for this organisation"
        );
        require(msg.value > 0, "Bounty amount should be greater than 0");

        status = BountyStatus(0);

        bounty.push(
            Bounty(
                organisationId,
                bountyCount,
                title,
                payable(msg.sender),
                descriptionGithubLink,
                msg.value,
                startTime,
                endTime,
                status,
                _totalBounterHunters,
                _totalSubmittedWorks
            )
        );

        bounties.push(
            Bounty(
                organisationId,
                bountyCount,
                title,
                payable(msg.sender),
                descriptionGithubLink,
                msg.value,
                startTime,
                endTime,
                status,
                _totalBounterHunters,
                _totalSubmittedWorks
            )
        );

        _bountyId++;
        bountyCount++;

        (bool sent, ) = address(this).call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        emit LogBounty(
            organisationId,
            // bountyCount,
            title,
            payable(msg.sender),
            descriptionGithubLink,
            msg.value,
            startTime,
            endTime
        );
    }

    function joinBounty(
        uint256 _bountyId,
        uint256 _organisationId
    ) public registeredUser checkMemberAndOrganisationExist(_organisationId) {
        // To join you need to be a member of the organisation
        // the organization and bounty need to exist and check bounty has not ended
        Bounty[] storage bounty = bountyMapList[_bountyId];
        require(
            bounty[_bountyId].bountyId == _bountyId,
            "Bounty does not exist"
        );
        require(
            !bountyParticipant[msg.sender][_organisationId][_bountyId],
            "You are already a participant of this bounty"
        );
        require(
            bounty[_bountyId].endTime >= block.timestamp,
            "Bounty has ended"
        );
        bounty[_bountyId].totalBounterHunters += 1;

        address[] storage membersList = bountyParticipants[msg.sender][
            _organisationId
        ][_bountyId];
        membersList.push((msg.sender));
        // organisationMemberCount++;
        bountyParticipant[msg.sender][_organisationId][_bountyId] = true;

        emit LogJoinBounty(_organisationId, _bountyId, msg.sender);
    }

    function submitWork(
        uint256 _bountyId,
        uint256 _organisationId,
        string memory _submissionLink
    )
        public
        registeredUser
        checkMemberAndOrganisationExist(_organisationId)
        checkBountyExist(_organisationId, _bountyId)
    {
        // check to ensure user registered for the bounty and user also registered and also a member of the organisation
        // check to ensure bounty and organisation exist
        // check to ensure the bounty has not ended
        // Bounty storage bounty = bountyOrgMap[_organisationId][_bountyId];

        // check already submitted
        require(!alreadySubmitted[msg.sender], "You already submitted");
        Bounty[] storage bounty = bountyMapList[_bountyId];
        require(
            bounty[_bountyId].endTime >= block.timestamp,
            "Bounty has ended"
        );
        require(
            block.timestamp >= bounty[_bountyId].startTime,
            "Bounty has not started"
        );
        uint256 _totalEarnings;
        SubmitWork storage work = workMapSubmissions[msg.sender][
            _organisationId
        ][_bountyId];
        work.acceptanceStatus = false;
        work.submissionId = submissionCount;
        work.submissionLink = _submissionLink;
        work.participant = payable(msg.sender);
        work.organisationId = _organisationId;
        work.bountyId = _bountyId;
        work.earnings += _totalEarnings;
        submissionList.push(
            SubmitWork(
                submissionCount,
                _organisationId,
                _bountyId,
                payable(msg.sender),
                _submissionLink,
                false,
                _totalEarnings
            )
        );
        submissionCount++;
        alreadySubmitted[msg.sender] = true;

        emit LogSubmitWork(
            submissionCount,
            _organisationId,
            _bountyId,
            payable(msg.sender),
            _submissionLink,
            false,
            _totalEarnings
        );
    }

    function getSubmissionCount() public view returns (uint256) {
        return submissionCount;
    }

    function getUserSubmission(
        uint256 _organisationId,
        uint256 _bountyId
    ) public view returns (SubmitWork memory) {
        return workMapSubmissions[msg.sender][_organisationId][_bountyId];
    }

    // Get all bounties of an organisation
    function getOrganisationBounties(
        uint256 _organisationId
    ) public view returns (Bounty[] memory) {
        return bountyMapList[_organisationId];
    }

    function getMemberCount() public view returns (uint256) {
        return memberCount;
    }

    function getAllBountiesCount() public view returns (uint256) {
        return bountyCount;
    }

    function removeOrganization(
        uint256 _organizationId
    ) public onlyOrganisationCreator(_organizationId) {
        // TODO organisation can only be removed by the creator

        require(
            msg.sender == organisationList[_organizationId].creatorAddress,
            "You are not the creator"
        );
        delete organisationList[_organizationId];
    }

    function removeBounty(
        uint256 _organisationId,
        uint256 _bountyId
    )
        public
        checkBountyPeriod(_bountyId)
        checkBountyExist(_organisationId, _bountyId)
    {
        // bounty can only be removed when it has not started and by the creator
        Bounty[] storage bounty = bountyMapList[_bountyId];
        require(
            msg.sender == bounty[_bountyId].bountyCreator,
            "You are not the creator"
        );
        bounty[_bountyId] = bounty[bounty.length - 1];
        bounty.pop();
    }

    // fix completely delete the user submission
    function deleteHunterSubmission(
        uint256 _organisationId,
        uint256 _bountyId
    )
        public
        checkMemberAndOrganisationExist(_organisationId)
        checkBountyExist(_bountyId, _organisationId)
        onlyBountyCreator(_organisationId, _bountyId)
    {
        // Bounty[] storage bounty = bountyMapList[_bountyId];
        SubmitWork storage work = workMapSubmissions[msg.sender][
            _organisationId
        ][_bountyId];

        // require(msg.sender == bounty[_bountyId].bountyCreator, "You are not the creator");

        require(
            msg.sender == work.participant,
            "You are not the owner of the submission"
        );

        delete workMapSubmissions[msg.sender][_organisationId][_bountyId];
    }

    function updateSubmission(
        uint256 _organisationId,
        uint256 _bountyId,
        string memory _submissionLink
    )
        public
        registeredUser
        checkMemberAndOrganisationExist(_organisationId)
        checkBountyExist(_bountyId, _organisationId)
    {
        Bounty[] storage bounty = bountyMapList[_bountyId];
        SubmitWork storage work = workMapSubmissions[msg.sender][
            _organisationId
        ][_bountyId];
        work.submissionLink = _submissionLink;

        require(
            msg.sender == work.participant,
            "You are not the owner of the submission"
        );
        require(
            block.timestamp >= bounty[_bountyId].startTime,
            "Bounty has not started"
        );
        require(
            bounty[_bountyId].endTime >= block.timestamp,
            "Bounty has ended"
        );

        // Update the submission in the submissionList array
        for (uint256 i = 0; i < submissionList.length; i++) {
            if (
                submissionList[i].organisationId == _organisationId &&
                submissionList[i].bountyId == _bountyId &&
                submissionList[i].participant == msg.sender
            ) {
                submissionList[i].submissionLink = _submissionLink;
                break;
            }
        }
        emit LogUpdateSubmission(_organisationId, _bountyId, _submissionLink);
    }

    function acceptSubmissions(
        uint256 _organisationId,
        uint256 _bountyId,
        address hunterAddress
    )
        public
        // checkBountyNotStarted(_bountyId)
        checkBountyExist(_bountyId, _organisationId)
        onlyBountyCreator(_organisationId, _bountyId)
        checkBountyPeriod(_bountyId)
    {
        // update the acceptance value
        // this should be called by the bountyCreator
        // This can only be called when bounty has ended

        SubmitWork storage work = workMapSubmissions[hunterAddress][
            _organisationId
        ][_bountyId];
        work.acceptanceStatus = true;
        // Update the submission in the submissionList array
        for (uint256 i = 0; i < submissionList.length; i++) {
            if (
                submissionList[i].organisationId == _organisationId &&
                submissionList[i].bountyId == _bountyId &&
                submissionList[i].participant == hunterAddress
            ) {
                submissionList[i].acceptanceStatus = true;
                break;
            }
        }
        emit LogAcceptSubmission(
            _organisationId,
            _bountyId,
            hunterAddress,
            true
        );
    }

    function payBountyWinners(
        uint256 _organisationId,
        uint256 _bountyId
    )
        public
        payable
        noReentrant
        onlyBountyCreator(_organisationId, _bountyId)
        // checkBountyNotStarted(_bountyId)
        checkBountyExist(_bountyId, _organisationId)
        checkBountyPeriod(_bountyId)
    {
        // Get all submissions, check if user submission is accepted, and if true, distribute the funds to the hunters
        // This can only be called when the bounty has ended

        Bounty storage bounty = bountyMapList[_organisationId][_bountyId];
        uint256 bountyAmount = bounty.bountyAmount;
        uint256 acceptedCount = 0;
        uint256 amount;

        // require(block.timestamp >= bounty.endTime, "Bounty period has not ended yet");
        require(
            address(this).balance >= bountyAmount,
            "Insufficient contract balance"
        );
        // require(bounty.endTime < block.timestamp, "Bounty has not yet ended");

        for (uint256 i = 0; i < submissionList.length; i++) {
            if (
                submissionList[i].organisationId == _organisationId &&
                submissionList[i].bountyId == _bountyId &&
                submissionList[i].acceptanceStatus == true
            ) {
                acceptedCount++;
            }
        }

        require(acceptedCount > 0, "No accepted submissions found");

        amount = bountyAmount / acceptedCount;
        uint256 transferAmount = amount * acceptedCount;
        require(
            transferAmount <= address(this).balance,
            "Insufficient contract balance for transfer"
        );

        for (uint256 i = 0; i < submissionList.length; i++) {
            if (
                submissionList[i].organisationId == _organisationId &&
                submissionList[i].bountyId == _bountyId &&
                submissionList[i].acceptanceStatus == true
            ) {
                submissionList[i].participant.transfer(amount);
                submissionList[i].earnings += amount;
            }
        }
        emit LogPayBountyWinners(_organisationId, _bountyId, amount);
    }

    function getBountyStatus(
        uint256 _organisationId,
        uint256 _bountyid
    ) public view returns (uint256) {
        BountyStatus _status;

        Bounty storage bounty = bountyMapList[_organisationId][_bountyid];
        if (block.timestamp < bounty.startTime) {
            //proposal is pending
            _status = BountyStatus.NotStarted;
        } else if (block.timestamp <= bounty.endTime) {
            //proposal is active
            _status = BountyStatus.Active;
        } else if (block.timestamp > bounty.endTime) {
            //proposal voting has ended
            _status = BountyStatus.Closed;
        }
        return uint256(status);
    }
}
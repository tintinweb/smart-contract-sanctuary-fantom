/**
 *Submitted for verification at FtmScan.com on 2023-07-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

interface ERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract FantomGrant {
    event DonateToPool(address contributor, uint amount, string eventIndex);

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    struct Contribution {
        address contributor;
        uint256 amount;
    }

    struct Event {
        string index;
        uint fundingPool;
        uint duration;
        uint initialTax;
        uint taxIncrementRate;
        uint taxCapped;
        address nftContract;
        address owner;
        address tokenContract;
        bool alreadyDistributed;
    }

    struct Project {
        string index;
        uint fundingTotal;
        uint currentTax;
        address owner;
        bool verified;
    }

    mapping(string => Event) public eventByIndex;  //Map category based on the Index on offchain database
    mapping(string => Project[]) projectsOnEvent;
    mapping(string => Contribution[]) contributionsFundingPool;
    mapping(string => Contribution[]) contributionsProject;

    modifier isOwner {
        require(msg.sender == owner, "You don't have an admin permission");
        _;
    }

    modifier isVerified(string memory eventIndex, string memory projectIndex){
        Project[] storage projects = projectsOnEvent[eventIndex];
        bool projectVerified = false;
        for (uint256 i = 0; i < projects.length; i++) {
            if (keccak256(abi.encodePacked(projects[i].index)) == keccak256(abi.encodePacked(projectIndex))) {
                projectVerified = projects[i].verified;
                break;
            }
        }
        require(projectVerified, "Project is not verified");
        _;
    }

    modifier eventNotExpired(string memory eventIndex) {
        require(eventByIndex[eventIndex].duration >= block.timestamp, "Event has expired");
        _;
    }

    modifier eventExpired(string memory eventIndex) {
        require(eventByIndex[eventIndex].duration < block.timestamp, "Event not yet expired");
        _;
    }

    //Pure Function

    function sqrt(uint256 x) public pure returns (uint256) {
        uint256 y = x;
        uint256 z = (y + 1) / 2;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    //View Functions

    function projectMatch(string memory projectIndex) public view returns (uint){
        //uint totalPool =  getTotalPoolFund(categoryIndex);
        uint grantScore;
        //uint totalGrantScore;
        Contribution[] memory contributions_ = getAllProjectContributions(projectIndex);
        uint squareRootSum;
        for (uint i = 0; i < contributions_.length; i++) {
            uint sqrtContribution = sqrt(contributions_[i].amount);
            squareRootSum += sqrtContribution;
        }
        grantScore = squareRootSum ** 2;
        return grantScore;
    } 

    function projectMatchFund(string memory eventIndex, string memory projectIndex) public view returns (uint){
        uint projectmatch = projectMatch(projectIndex);
        uint totalMatch_ = eventTotalMatch(eventIndex);
        uint totalFund = getTotalPoolFund(eventIndex);
        uint totalMatchProject = totalFund * projectmatch / totalMatch_;
        return totalMatchProject;
    }

    function eventTotalMatch(string memory eventIndex) public view returns (uint){
        uint totalGrantScore;
        Project[] memory projects_ = getAllProjects(eventIndex);
        for (uint i = 0; i < projects_.length; i++){
            string memory index = projects_[i].index;
            uint grantScore = projectMatch(index);
            totalGrantScore += grantScore;
        }
        return totalGrantScore;
    }

    function getAllProjects(string memory eventIndex) public view returns (Project[] memory){
        return projectsOnEvent[eventIndex];
    }

    function getAllProjectContributions(string memory projectIndex) public view returns (Contribution[] memory){
        return contributionsProject[projectIndex];
    }

    function getAllEventContributions(string memory eventIndex) public view returns (Contribution[] memory){
        return contributionsFundingPool[eventIndex];
    }

    function getTotalPoolFund(string memory eventIndex) public view returns (uint){
        return eventByIndex[eventIndex].fundingPool;
    }

    //payable
    function donateToPool(string memory eventIndex) public payable eventNotExpired(eventIndex) {
        require(msg.value > 0, "Sending 0 amount is not allowed");
        Event storage event_ = eventByIndex[eventIndex];
        event_.fundingPool += msg.value;
        Contribution[] storage poolContributions = contributionsFundingPool[eventIndex];

        // Check if the contributor has already made a contribution
        bool contributorExists;
        for (uint256 i = 0; i < poolContributions.length; i++) {
            if (poolContributions[i].contributor == msg.sender) {
                // Increment the existing contribution
                contributionsFundingPool[eventIndex][i].amount += msg.value;
                contributorExists = true;
                break;
            }
        }

        if (!contributorExists) {
            // Add a new contribution
            contributionsFundingPool[eventIndex].push(Contribution(msg.sender, msg.value));
        }
        emit DonateToPool(msg.sender, msg.value, eventIndex);
    }

    function donateToProject(string memory eventIndex, string memory projectIndex) public payable eventNotExpired(eventIndex) {
        require(msg.value > 0, "Sending 0 amount is not allowed");

        Event storage event_ = eventByIndex[eventIndex];
        require(event_.owner != address(0), "Event does not exist");

        Project[] storage projects = projectsOnEvent[eventIndex];
        address projectOwner;
        uint tax;
        uint projectIndexInProjectsOnEvent;
        for (uint256 i = 0; i < projects.length; i++) {
            if (keccak256(abi.encodePacked(projects[i].index)) == keccak256(abi.encodePacked(projectIndex))) {
                projectOwner = projects[i].owner;
                tax = projects[i].currentTax;
                projectIndexInProjectsOnEvent = i;
                break;
            }
        }

        require(projectOwner != address(0), "Project does not exist");

        // Update the project funding and current tax
        uint256 taxAmount = (msg.value * tax) / 10000;
        uint256 fundingAmount = msg.value - taxAmount;
        projects[projectIndexInProjectsOnEvent].fundingTotal += fundingAmount;
        if (projects[projectIndexInProjectsOnEvent].currentTax + event_.taxIncrementRate > event_.taxCapped){
            projects[projectIndexInProjectsOnEvent].currentTax = event_.taxCapped;
        } else {
            projects[projectIndexInProjectsOnEvent].currentTax += event_.taxIncrementRate;
        }  
        event_.fundingPool += taxAmount;

        // Add the contribution to the project
        contributionsProject[projectIndex].push(Contribution(msg.sender, fundingAmount));

        // Add the tax to the funding pool
        contributionsFundingPool[eventIndex].push(Contribution(address(this), taxAmount));

        emit DonateToPool(msg.sender, fundingAmount, eventIndex);
    }

    function addEvent(string memory eventIndex, uint endTime, uint initialTax,
        uint taxIncrementRate, uint taxCapped, address _nftContract ) public payable {
        require(initialTax <= 200, "Initial Tax must be equal or less than 2%");
        require(taxCapped >= 1000 && taxCapped <= 5000, "Tax Capped must be between 10% - 50%");
        require(taxIncrementRate <= 200, "Tax Increment Rate must be equal or less than 2%");
        require(msg.value > 0 , "Starting Funding Pool must be greater than 0");
       
        // Check if eventIndex is unique
        require(eventByIndex[eventIndex].owner == address(0), "Event already exists");

        Event memory newEvent = Event({
            index: eventIndex,
            fundingPool: msg.value,
            duration: endTime,
            initialTax: initialTax,
            taxIncrementRate: taxIncrementRate,
            taxCapped: taxCapped,
            nftContract: _nftContract,
            owner: msg.sender,
            tokenContract: address(0),
            alreadyDistributed: false
        });

        eventByIndex[eventIndex] = newEvent;
    }

    function submitProject(string memory eventIndex, string memory projectIndex) public eventNotExpired(eventIndex) {
        require(eventByIndex[eventIndex].owner != address(0), "Event does not exist");

        Project[] storage projects = projectsOnEvent[eventIndex];
        for (uint256 i = 0; i < projects.length; i++) {
            require(keccak256(abi.encodePacked(projects[i].index)) != keccak256(abi.encodePacked(projectIndex)), "Project ID already exists");
        }

        Event storage event_ = eventByIndex[eventIndex];
        address nftContract = event_.nftContract;

        if (nftContract != address(0)) {
            require(ERC721(nftContract).balanceOf(msg.sender) > 0, "You don't own an NFT from the event");
        }

        Project memory newProject = Project({
            index: projectIndex,
            fundingTotal: 0,
            currentTax: event_.initialTax,
            owner: msg.sender,
            verified: false
        });

        projectsOnEvent[eventIndex].push(newProject);
    }

    function verifyProject(string memory eventIndex, string memory projectIndex) public eventNotExpired(eventIndex) {
        require(eventByIndex[eventIndex].owner != address(0), "Event does not exist");
        require(eventByIndex[eventIndex].owner == msg.sender, "You don't have permission");

        Project[] storage projects = projectsOnEvent[eventIndex];
        bool projectExists = false;
        for (uint256 i = 0; i < projects.length; i++) {
            if (keccak256(abi.encodePacked(projects[i].index)) == keccak256(abi.encodePacked(projectIndex))) {
                projectExists = true;
                break;
            }
        }
        require(projectExists, "Project does not exist in the event");

        // Mark the project as verified
        for (uint256 i = 0; i < projects.length; i++) {
            if (keccak256(abi.encodePacked(projects[i].index)) == keccak256(abi.encodePacked(projectIndex))) {
                projects[i].verified = true;
                break;
            }
        }
    }

    function distribute(string memory eventIndex) public eventExpired(eventIndex) {
        require(eventByIndex[eventIndex].owner == msg.sender, "Only event owner can distribute funds");

        Event storage event_ = eventByIndex[eventIndex];
        Project[] storage projects = projectsOnEvent[eventIndex];

        uint256 totalFunds = event_.fundingPool;

        // If there are no projects or the funding pool is empty, send the entire funding pool to the event owner
        if (projects.length == 0 || totalFunds == 0) {
            payable(event_.owner).transfer(totalFunds);
            event_.fundingPool = 0;
            event_.alreadyDistributed = true;
            return;
        }

        for (uint projectIndex = 0; projectIndex < projects.length; projectIndex++) {
            Project storage project = projects[projectIndex];

            // Skip distributing funds if the project's funding total is 0
            if (project.fundingTotal == 0) {
                continue;
            }

            // Transfer tokens to the project owner
            uint projectMatchFund_ = projectMatchFund(eventIndex, project.index);
            payable(project.owner).transfer(project.fundingTotal + projectMatchFund_);
        }

        // Mark the category as already distributed
        event_.alreadyDistributed = true;
    }


}
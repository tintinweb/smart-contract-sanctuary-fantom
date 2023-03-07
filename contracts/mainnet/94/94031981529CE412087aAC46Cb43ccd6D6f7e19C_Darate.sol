// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/*
    @title Darate (A crowdfunding platform)
    @creator Afolabi Olajide Samuel (cipherr)
*/

contract Darate {
    // @dev struct for the normal campaign
    struct Campaign{
        address owner;
        string title;
        string description;
        string category;
        uint256 targetAmount;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    // @dev struct for creator campaign
    struct CreatorCampaign{
        address owner;
        string name;
        string description;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => CreatorCampaign) public creatorCampaigns;

    mapping(address => bool) public creatorCampaignAvailable;

    uint256 numberOfCampaigns = 0;
    uint256 numberOfCreatorCampaigns = 0;

    // @dev create a normal campaign
    function createCampaign(address _owner, string memory _title, string memory _description, string memory _category, uint256 _targetAmount, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(campaign.deadline < block.timestamp, "The Date should be a Date in the future");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.category = _category;
        campaign.targetAmount = _targetAmount;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    // @dev create a creator campaign
    function createCreatorCampaign(address _owner, string memory _name, string memory _description, string memory _image) public returns (uint256) {
        CreatorCampaign storage creatorCampaign = creatorCampaigns[numberOfCreatorCampaigns];

        require(!creatorCampaignAvailable[msg.sender], "You have reached the maximun creator campaign created");

        creatorCampaign.owner = _owner;
        creatorCampaign.name = _name;
        creatorCampaign.description = _description;
        creatorCampaign.amountCollected = 0;
        creatorCampaign.image = _image;

        creatorCampaignAvailable[msg.sender] = true;
        numberOfCreatorCampaigns++;

        return numberOfCreatorCampaigns - 1;
    }

    // @dev donate to normal campaign
    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    // @dev donate to creator campaign
    function donateToCreatorCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        CreatorCampaign storage creatorCampaign = creatorCampaigns[_id];

        creatorCampaign.donators.push(msg.sender);
        creatorCampaign.donations.push(amount);

        (bool sent, ) = payable(creatorCampaign.owner).call{value: amount}("");

        if(sent) {
            creatorCampaign.amountCollected = creatorCampaign.amountCollected + amount;
        }
    }

    // @dev get list of donators for normal campaign
    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    // @dev get list of donators for creator campaign
    function getCreatorDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        return (creatorCampaigns[_id].donators, creatorCampaigns[_id].donations);
    }

    // @dev get all normal campaigns
    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++ ){
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
    
    // @dev get all creator campaigns
    function getCreatorCampaigns() public view returns (CreatorCampaign[] memory) {
        CreatorCampaign[] memory allCampaigns = new CreatorCampaign[](numberOfCreatorCampaigns);

        for (uint i = 0; i < numberOfCreatorCampaigns; i++ ){
            CreatorCampaign storage item = creatorCampaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}
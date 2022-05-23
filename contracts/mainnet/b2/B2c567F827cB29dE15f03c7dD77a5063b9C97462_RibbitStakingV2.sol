// SPDX-License-Identifier:  MIT

pragma solidity ^0.8.4;

contract RibbitStakingV2 {
    // [=======] SETUP FUNCTIONS [=======]

    constructor() {
        Administrators[msg.sender] = true;
        Administrators[address(this)] = true;
    }

    struct Stake {
        address staker;
        ERC721 token;
        uint256 tokenId;
        uint256 timeDeposited;
        uint256 timeHarvested;
        uint256 totalClaims;
        uint256 totalClaimed;
    }

    ERC721 public keycardToken;
    ERC721 public frogToken;
    ERC20 public ribbitToken;
    uint256 public bonusPerBonusToken = 1000;
    uint256 public baseRewardsPerSecond = 10000000000000000;
    mapping(address => Stake) public Stakes;
    mapping(uint256 => uint256) public KeycardBonuses;
    mapping(address => bool) public Administrators;
    bool public paused;

    modifier onlyAdministrators() {
        require(Administrators[msg.sender] == true, "administrators only");
        _;
    }

    modifier pasuable() {
        require(paused == false, "contract paused");
        _;
    }

    // [=======] ADMINISTRATOR FUNCTIONS [=======]

    function init(
        address keycardTokenAddress,
        address frogTokenAddress,
        address ribbitTokenAddress
    ) public onlyAdministrators {
        keycardToken = ERC721(keycardTokenAddress);
        frogToken = ERC721(frogTokenAddress);
        ribbitToken = ERC20(ribbitTokenAddress);
    }

    function toggleAdministrator(address administratorAddress)
        public
        onlyAdministrators
    {
        Administrators[administratorAddress] = !Administrators[
            administratorAddress
        ];
    }

    function togglePause() public onlyAdministrators {
        paused = paused ? false : true;
    }

    function setKeycardBonus(uint256 tokenId, uint256 newBonus)
        public
        onlyAdministrators
    {
        KeycardBonuses[tokenId] = newBonus;
    }

    function setKeycardBonuses(
        uint256 from,
        uint256 to,
        uint256[] memory bonusValues
    ) public onlyAdministrators {
        for (uint256 i = from; i < to; i++) {
            KeycardBonuses[i - from] = bonusValues[i];
        }
    }

    function setBonusPerBonusToken(uint256 newBonusPerBonusToken)
        public
        onlyAdministrators
    {
        bonusPerBonusToken = newBonusPerBonusToken;
    }

    function setBaseRewards(uint256 newBaseRewardsPerSecond)
        public
        onlyAdministrators
    {
        baseRewardsPerSecond = newBaseRewardsPerSecond;
    }

    function withdrawAllRewards() public onlyAdministrators {
        uint256 balance = ribbitToken.balanceOf(address(this));
        ribbitToken.transfer(msg.sender, balance);
    }

    // [=======] HELPER FUNCTIONS [=======]

    function calculateBonus(address staker) public view returns (uint256) {
        Stake memory stake = Stakes[staker];
        uint256 keycardBonus;
        if (stake.token == keycardToken)
            keycardBonus = KeycardBonuses[stake.tokenId];
        uint256 frogTokenBalance = frogToken.balanceOf(stake.staker);
        uint256 frogHoldingBonus = frogTokenBalance * bonusPerBonusToken;
        return keycardBonus + frogHoldingBonus;
    }

    function calculateSecondsSinceHarvest(address staker)
        public
        view
        returns (uint256)
    {
        Stake memory stake = Stakes[staker];
        if (stake.timeDeposited == 0) return 0;
        uint256 currentTime = block.timestamp;
        uint256 lastHarvestTime = stake.timeHarvested;
        return (currentTime - lastHarvestTime);
    }

    function calculateRewards(address staker) public view returns (uint256) {
        uint256 bonus = calculateBonus(staker);
        uint256 total = (calculateSecondsSinceHarvest(staker) *
            baseRewardsPerSecond);
        uint256 bonusRewards = (total * bonus) / 10000;
        return total + bonusRewards;
    }

    // [=======] PUBLIC FUNCTIONS [=======]

    function deposit(uint256 tokenId, address contractAddress) public pasuable {
        Stake memory stake = Stakes[msg.sender];
        require(stake.staker == address(0x0), "already staking");
        ERC721 stakeToken = ERC721(contractAddress);
        require(
            stakeToken == frogToken || stakeToken == keycardToken,
            "unstakeable token"
        );
        stakeToken.transferFrom(msg.sender, address(this), tokenId);
        Stakes[msg.sender] = Stake(
            msg.sender,
            stakeToken,
            tokenId,
            block.timestamp,
            block.timestamp,
            0,
            0
        );
    }

    function withdraw() public pasuable {
        Stake memory stake = Stakes[msg.sender];
        require(msg.sender == stake.staker, "not allowed");
        harvest(msg.sender);
        stake.token.transferFrom(address(this), stake.staker, stake.tokenId);
        delete Stakes[msg.sender];
    }

    function harvest(address staker) public pasuable {
        Stake memory stake = Stakes[staker];
        require(
            msg.sender == stake.staker || msg.sender == address(this),
            "not allowed"
        );
        uint256 rewards = calculateRewards(stake.staker);
        ribbitToken.transfer(stake.staker, rewards);
        Stakes[staker] = Stake(
            stake.staker,
            stake.token,
            stake.tokenId,
            stake.timeDeposited,
            block.timestamp,
            stake.totalClaims + 1,
            stake.totalClaimed + rewards
        );
    }
}

abstract contract ERC721 {
    function ownerOf(uint256 id) public virtual returns (address);

    function approve(address to, uint256 id) public virtual;

    function balanceOf(address who) public view virtual returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual;
}

abstract contract ERC20 {
    function mint(address to, uint256 amount) public virtual;

    function transfer(address to, uint256 amount) public virtual;

    function balanceOf(address who) public view virtual returns (uint256);
}
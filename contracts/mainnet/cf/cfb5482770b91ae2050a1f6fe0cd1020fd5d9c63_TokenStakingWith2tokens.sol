/**
 *Submitted for verification at FtmScan.com on 2022-11-08
*/

/**
 *Submitted for verification at FtmScan.com on 2022-09-14
*/

// SPDX-License-Identifier: CC-BY-SA 4.0
//https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creators of this contract (@LogETH) & (@jellyfantom) are not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creators, @LogETH @jellyfantom .
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests we endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

// By deploying this contract, you agree to the license above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

contract TokenStakingWith2tokens{

//// This contract simply enables a staking system with a reward and deposit token.
//// THIS CONTRACT MUST BE IMMUNE TO/EXCLUDED FROM ANY FEE ON TRANSFER MECHANISMS.

 

    constructor(){

        admin = msg.sender;

        Token = ERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75); // This is USDC on FTM network
        RewardToken;
    }


//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////


//// The ERC20 Token and NFT:

    ERC20 Token;
    ERC20 RewardToken;

//// All the Variables that this contract uses (basically the dictionary for this contract)

    mapping(address => uint) public TimeStaked;         // How much time someone has staked for.
    mapping(address => uint) public TokensStaked;       // How many tokens someone has staked.
    mapping(uint => address) user;
    mapping(address => uint) PendingReward;
    address admin;
    uint public totalStaked;                            // How many tokens are staked in total.
    uint public RewardFactor;                           // How many rewards in basis points are given per day
    uint Nonce;
    uint rewardPeriod;

    modifier OnlyAdmin{

        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        _;
    }
    
    

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    // Functions that let the Admin of this contract change settings.

    function EditToken(ERC20 WhatToken) public OnlyAdmin{

        Token = WhatToken; // Changes the token (DOES NOT RESET REWARDS)
    }

    function EditRewardToken(ERC20 WhatToken) public OnlyAdmin{

        RewardToken = WhatToken; // Changes the token (DOES NOT RESET REWARDS)
    }

    function EditEmission(uint HowManyRewardTokensPerDepositTokenPerRewardPeriod) public OnlyAdmin{

        SaveRewards(); //Saves everyone's rewards
        RewardFactor = HowManyRewardTokensPerDepositTokenPerRewardPeriod; // Switches to the new reward percentage
    }

    function EditRewardPeriod(uint HowLong) public{

        rewardPeriod = HowLong;
    }

    // Everyone asks what this does, it just sends stuck tokens to your address

    function SweepToken(ERC20 TokenAddress) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        TokenAddress.transfer(msg.sender, TokenAddress.balanceOf(address(this))); 
    }

    // The Stake button stakes your tokens.
    // SECURITY WARNING, This address MUST be immune to any token fees or else things will break. (lol)

    function Stake(uint amount) public {

        require(Token.balanceOf(msg.sender) > 0, "You don't have any tokens to stake!");
        require(msg.sender != address(0), "What the fuck"); // This error will never happen but I just have it here as an edge case easter egg for you lurking programmers..

        if(TokensStaked[msg.sender] == 0){RecordRewardALT(msg.sender);}
        else{RecordReward(msg.sender);}
 
        Token.transferFrom(msg.sender, address(this), amount); // Deposits "Token" into this contract
        TokensStaked[msg.sender] += amount; // Keeps track of how many tokens you deposited

        user[Nonce] = msg.sender; // Records your address to use in SaveRewards()

        totalStaked += amount; // Add the coins you deposited to the total staked amount

        Nonce += 1;
    }

    function claimRewards() public {

        require(TokensStaked[msg.sender] > 0, "There is nothing to claim as you haven't staked anything");

        RecordRewardALT(msg.sender);
        RewardToken.transfer(msg.sender, PendingReward[msg.sender]);

        PendingReward[msg.sender] = 0;
    }

    // The Unstake Button withdraws your tokens. It does not auto claim rewards.

    function Unstake(uint amount) public {

        require(TokensStaked[msg.sender] > 0, "There is nothing to withdraw as you haven't staked anything");
        require(TokensStaked[msg.sender] >= amount, "You cannot withdraw more tokens than you have staked");

        RecordReward(msg.sender);

        Token.transfer(msg.sender, amount); // Unstakes "Amount" and sends it to the caller
        TokensStaked[msg.sender] -= amount; // Reduces your staked balance by the amount of tokens you unstaked
        totalStaked -= amount; // Reduces the total staked amount by the amount of tokens you unstaked

    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

    // (msg.sender SHOULD NOT be used/assumed in any of these functions.)

    // CalculateTime returns a uint with 18 decimals.
  
    function CalculateTime(address YourAddress) internal view returns (uint256){

        uint Time = (block.timestamp - TimeStaked[YourAddress]);
        if(TimeStaked[YourAddress] == block.timestamp){Time = 0;}

        return Time;
    }

    function CalculateRewards(address YourAddress, uint256 StakeTime) internal view returns (uint256){

        return (StakeTime * RewardFactor * (TokensStaked[YourAddress]))/rewardPeriod;
    }

    // RecordReward does not reset the claim cooldown, RecordRewardALT does.

    function RecordReward(address User) internal {

        uint Unclaimed = CalculateRewards(User, CalculateTime(User));
        PendingReward[User] += Unclaimed;
        TimeStaked[User] = block.timestamp; // Calling record reward makes it so you don't need this line in the parent code.
    }

    function RecordRewardALT(address User) internal {

        uint Unclaimed = CalculateRewards(User, CalculateTime(User));
        PendingReward[User] += Unclaimed;
        TimeStaked[User] = block.timestamp;
    }

    // SaveRewards() saves the state of everyone's rewards, only triggers when changing the reward %

    function SaveRewards() internal {

        uint UserNonce = 1;

        while(user[UserNonce] != address(0)){

            RecordReward(user[UserNonce]);
            UserNonce += 1;
        }
    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////                 Functions used for UI data                   ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    function CheckRewards(address YourAddress) public view returns (uint256){

        return(CalculateRewards(YourAddress, CalculateTime(YourAddress)));
    }


    function isContract(address addr) internal view returns (bool) {

        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }      

    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// Additional functions that are not part of the core functionality, if you add anything, please add it here ////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
    function something() public {

        blah blah blah blah;
    }
*/



}
    
//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Contracts that this contract uses, contractception!     ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

interface ERC20{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns (uint8);
}
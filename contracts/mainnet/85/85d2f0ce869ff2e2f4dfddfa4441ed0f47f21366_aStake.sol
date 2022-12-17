/**
 *Submitted for verification at FtmScan.com on 2022-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract aStake{

//// This contract is a staking system


    constructor(){
        admin = msg.sender;

        Token =          ERC20(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E); 
        RewardToken =    ERC20(0xAD522217E64Ec347601015797Dd39050A2a69694);
        NFT =           ERC721(0x48DE29663f232f0F162E0bebB2948462d6181307);

        duration = 0;   // The amount of time in seconds that someone would have to wait to use functions marked with "cooldown", leave 0 if none.

        treasury =             0xE6E2C266543Ee7a01dE3a61E8517B1A164a041Ef;  // Where this contract sends fees to
        txCost = 1e18;                                                      // How much it costs to use a function marked with "takeFee"
        router =         Univ2(0xAd362c30b2991a154651b05181FE6BED795a9792); // The router the contract trades on to swap fees

        // Put the token path this contract should take below, for example, to trade ETH -> USDC, I would put wETH as the first token, and USDC as the second.

        route.push(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83); // First token
        route.push(0xAD522217E64Ec347601015797Dd39050A2a69694); // Second Token


        // If you want to set the emission before this contract is deployed, do it here (The default is 0):

        rewardPeriod = 0;
        RewardFactor = 0;
        BoostedRewardFactor = 0;
    }


//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////


//// The ERC20 Token:

    ERC20 Token;
    ERC20 RewardToken;
    ERC721 NFT;
    Univ2 router;

//// All the Variables that this contract uses (basically the dictionary for this contract)

    mapping(address => uint) public TimeStaked;         // How much time someone has staked for.
    mapping(address => uint) public TokensStaked;       // How many tokens someone has staked.
    address[] user;
    address[] route;
    mapping(address => uint) PendingReward;
    mapping(address => bool) public boost;
    address admin;
    address treasury;
    uint public totalStaked;                            // How many tokens are staked in total.
    uint public RewardFactor;                           // How many rewards in basis points are given per day
    uint public BoostedRewardFactor;
    uint public txCost;
    uint rewardPeriod;
    uint public duration;
    mapping(address => uint) lastTx;

    modifier OnlyAdmin{

        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier recordReward{

        PendingReward[msg.sender] += CalculateRewards(msg.sender);
        TimeStaked[msg.sender] = block.timestamp;
        _;
    }

    modifier takeFee{

        require(msg.value == txCost, "msg.value is not txCost");
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, route, treasury, type(uint).max);
        _;
    }

    modifier cooldown{

        require(lastTx[msg.sender] + duration <= block.timestamp, "Cooldown in progress");
        _;
        lastTx[msg.sender] = block.timestamp;
    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


//// a block of functions that let the Admin of this contract change various settings.

    function EditToken(ERC20 WhatToken)         public OnlyAdmin{Token = WhatToken;}
    function EditRewardToken(ERC20 WhatToken)   public OnlyAdmin{RewardToken = WhatToken;}
    function EditRewardPeriod(uint HowLong)     public OnlyAdmin{rewardPeriod = HowLong;}
    function EditTxCost(uint HowMuch)           public OnlyAdmin{txCost = HowMuch;}
    function EditNFT(ERC721 WhatNFT)            public OnlyAdmin{NFT = WhatNFT;}
    function EditTreasury(address WhatAddress)  public OnlyAdmin{treasury = WhatAddress;}

    function EditEmission(uint HowManyRewardTokensPerDepositTokenPerRewardPeriod) public OnlyAdmin{

        SaveRewards(); //Saves everyone's rewards
        RewardFactor = HowManyRewardTokensPerDepositTokenPerRewardPeriod; // Switches to the new reward percentage
    }

    function EditBoostedEmission(uint HowManyRewardTokensPerDepositTokenPerRewardPeriod) public OnlyAdmin{

        SaveRewards(); //Saves everyone's rewards
        BoostedRewardFactor = HowManyRewardTokensPerDepositTokenPerRewardPeriod; // Switches to the new reward percentage
    }

    // Function that allow stuck tokens to be withdrawed

    function SweepToken(ERC20 TokenAddress) public payable OnlyAdmin{

        TokenAddress.transfer(admin, TokenAddress.balanceOf(address(this))); 
    }

//// Functions that normal users would use

    function Stake(uint amount) public payable recordReward takeFee{

        require(amount != 0, "Cannot stake zero");

        if(NFT.balanceOf(msg.sender) > 0){boost[msg.sender] = true;}
 
        Token.transferFrom(msg.sender, address(this), amount); // Deposits "Token" into this contract

        TokensStaked[msg.sender] += amount; // Increases your staked balance by the amount of tokens you deposited
        totalStaked += amount; // Increases the total staked amount by the amount of tokens you deposited

        user.push(msg.sender); // Records your address to use in SaveRewards()
    }

    function Unstake(uint amount) public payable recordReward takeFee cooldown{

        require(TokensStaked[msg.sender] > 0, "No tokens staked");
        require(TokensStaked[msg.sender] >= amount, "You cannot withdraw more tokens than you have staked");

        TokensStaked[msg.sender] -= amount; // Reduces your staked balance by the amount of tokens you unstaked
        totalStaked -= amount; // Reduces the total staked amount by the amount of tokens you unstaked

        Token.transfer(msg.sender, amount); // Unstakes "Amount" and sends it to the caller
    }

    function claimRewards() public payable recordReward takeFee cooldown{

        require(TokensStaked[msg.sender] > 0, "No tokens staked");

        uint reward = PendingReward[msg.sender];

        PendingReward[msg.sender] = 0;
        RewardToken.transfer(msg.sender, reward);
    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

    // (msg.sender SHOULD NOT be used/assumed in any of these functions.)

    function CalculateRewards(address YourAddress) internal view returns (uint256){

        uint Time = (block.timestamp - TimeStaked[YourAddress]);
        if(TimeStaked[YourAddress] == block.timestamp){Time = 0;}

        if(boost[YourAddress]){

            return (Time * BoostedRewardFactor * (TokensStaked[YourAddress]))/rewardPeriod;
        } 
        
        return (Time * RewardFactor * (TokensStaked[YourAddress]))/rewardPeriod;
    }

    // SaveRewards() saves the state of everyone's rewards, only triggers when changing the reward %
    // I know this will brick the contract eventually, but its a temp solution until a perm one

    function SaveRewards() internal {

        if(user.length != 0){

            for(uint i; user.length == i; i++){

                PendingReward[user[i]] += CalculateRewards(user[i]);
                TimeStaked[user[i]] = block.timestamp;
            }

        }
    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////                 Functions used for UI data                   ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    function CheckRewards(address YourAddress) public view returns (uint256){

        return CalculateRewards(YourAddress) + PendingReward[YourAddress];
    }

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
}

interface ERC721{
    function balanceOf(address) external returns (uint);
}

interface Univ2{
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
}
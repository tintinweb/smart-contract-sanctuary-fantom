// SPDX-License-Identifier: MIT

//     ___                         __ 
//    /   |  _____________  ____  / /_
//   / /| | / ___/ ___/ _ \/ __ \/ __/
//  / ___ |(__  |__  )  __/ / / / /_  
// /_/  |_/____/____/\___/_/ /_/\__/  
// 
// 2022 - Assent Protocol

pragma solidity ^0.8.10;

import './IERC20.sol';
import './SafeMath.sol';
import './IAssentVIP.sol';

// IWAO contract : Initial Private ASNT Offering
contract IWAO

   {

    using SafeMath for uint256;
    
    //define the admin of IWAO 
    address public owner;
    
    address public inputtoken;
    
    bool public inputToken6Decimal=false;
    
    address public outputtoken;
    
    bool noOutputToken;

    IAssentVIP public vip; 
    
    // total Supply for IWAO
    uint256 public totalsupply;

    mapping (address => uint256)public userInvested;
    
    mapping (address => uint256)public userInvestedMemory;
    
    address[] public investors;
    
    address[] public whiteList;

    mapping (address => bool) public whiteListedUser;
    
    mapping (address => bool) public existinguser;
    
    uint256 public maxInvestment = 0; // pay attention to the decimals number of inputtoken
    
    uint256 public minInvestment = 0; // pay attention to the decimals number of inputtoken
    
    //set number of out tokens per in tokens  
    uint256 public outTokenPriceInDollar;                   

    //hardcap 
    uint public IWAOTarget;

    //define a state variable to track the funded amount
    uint public receivedFund=0;
    
    //set the IWAO status
    
    enum Status {inactive, active, stopped, completed}      // 0, 1, 2, 3
    
    Status private IWAOStatus;
    
    uint public IWAOStartTime=0;
    
    uint public IWAOInTokenClaimTime=0;
    
    uint public IWAOEndTime=0;

    uint public VIPAmountLevel1 = 100000000;

    uint public VIPAmountLevel2 = 500000000;

    uint public VIPAmountLevel3 = 1000000000;
    
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;   

    // if true, liquidity is created
    bool public liquidityIsCreated;     
    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }   
    
    function transferOwnership(address _newowner) public onlyOwner {
        owner = _newowner;
    } 
 
    constructor () {
    
        owner = msg.sender;
    
    }
 
    function setStopStatus() public onlyOwner  {
     
        IWAOStatus = getIWAOStatus();
        
        require(IWAOStatus == Status.active, "Cannot Stop inactive or completed IWAO ");   
        
        IWAOStatus = Status.stopped;
    }

    function setActiveStatus() public onlyOwner {
    
        IWAOStatus = getIWAOStatus();
        
        require(IWAOStatus == Status.stopped, "IWAO not stopped");   
        
        IWAOStatus = Status.active;
    }

    function getIWAOStatus() public view returns(Status)  {
    
        
        if (IWAOStatus == Status.stopped)
        {
            return Status.stopped;
        }
        
        else if (block.timestamp >=IWAOStartTime && block.timestamp <=IWAOEndTime)
        {
            return Status.active;
        }
        
        else if (block.timestamp <= IWAOStartTime || IWAOStartTime == 0)
        {
            return Status.inactive;
        }
        
        else
        {
            return Status.completed;
        }
    
    }

    function invest(uint256 _amount) public {
    
        //require(whiteListedUser[msg.sender], "Address not in whitelist");
    
        // check IWAO Status
        IWAOStatus = getIWAOStatus();
        
        require(IWAOStatus == Status.active, "IWAO in not active");
        
        //check for hard cap
        require(IWAOTarget >= receivedFund + _amount, "Target Achieved. Investment not accepted");
        
        require(_amount >= minInvestment , "min Investment not accepted");
        
        uint256 checkamount = userInvested[msg.sender] + _amount;

        //check maximum investment        
        require(checkamount <= maxInvestment, "Investment not in allowed range"); 
        
        // check for existinguser
        if (existinguser[msg.sender]==false) {
        
            existinguser[msg.sender] = true;
            investors.push(msg.sender);
        }
        
        userInvested[msg.sender] += _amount;

        //record or update user into the VIP contract
        _userToVIP(msg.sender, userInvested[msg.sender]);        

        //Duplicate to keep in memory after the IWAO
        userInvestedMemory[msg.sender] += _amount;
        
        receivedFund = receivedFund + _amount; 
        IERC20(inputtoken).transferFrom(msg.sender,address(this), _amount); 

    }
     
     
    function claimTokens() public {

        require(existinguser[msg.sender] == true, "Already claim"); 
        
        require(outputtoken!=BURN_ADDRESS, "Outputtoken not yet available"); 

        require (liquidityIsCreated, "liquidity not created");

        // check IWAO Status 
        IWAOStatus = getIWAOStatus();
        
        require(IWAOStatus == Status.completed, "IWAO in not complete yet");

        uint256 redeemtokens = remainingClaim(msg.sender);

        require(redeemtokens>0, "No tokens to redeem");
        
        IERC20(outputtoken).transfer(msg.sender, redeemtokens);
        
        existinguser[msg.sender] = false; 
        userInvested[msg.sender] = 0;
    }

    // Display user token claim balance
    function remainingClaim(address _address) public view returns (uint256) {

        uint256 redeemtokens = 0;

        if (inputToken6Decimal) {
            redeemtokens = (userInvested[_address] * 1000000000000 * 1000000000000000000) / outTokenPriceInDollar;
        }
        else {
            redeemtokens = (userInvested[_address] * 1000000000000000000) / outTokenPriceInDollar;
        }
        
        return redeemtokens;
        
    }

    // Display user max available investment
    function remainingContribution(address _address) public view returns (uint256) {

        uint256 remaining = maxInvestment - userInvested[_address];
        
        return remaining;
        
    }
    
    //  _token = 1 (outputtoken)        and         _token = 2 (inputtoken) 
    function checkIWAObalance(uint8 _token) public view returns(uint256 _balance) {
    
        if (_token == 1) {
            return getOutputTokenBalance();
        }
        else if (_token == 2) {
            return IERC20(inputtoken).balanceOf(address(this));  
        }
        else {
            return 0;
        }
    }

    function isWhiteListed(address _userAddress) public view returns(bool _isWhiteListed) {
                whiteListedUser[_userAddress];
                return true; //force whitelist answer
    } 
    
    function getOutputTokenBalance() internal view returns(uint256 _outputTokenBalance) {
        if (noOutputToken) {
            return totalsupply;
        }
        else {
            return IERC20(outputtoken).balanceOf(address(this));
        }          
    } 

    function getParticipantNumber() public view returns(uint256 _participantNumber) {
        return investors.length;
    } 

    function getWhitelistLenght() public view returns(uint256 _whitelistLenght) {
        return whiteList.length;
    }    

    // Add or update user into the VIP contract
    function _userToVIP(address _user, uint256 _totalInvested) internal {

        uint feeReduction = 0;
        uint reducDuration = 0;

        // Set user reduction and duration based on invested amount
        if (_totalInvested >= VIPAmountLevel3) {
            feeReduction = 300000000000000000; // 30% (18 decimals)
            reducDuration = 5184000; // 60 days (in seconds)
            reducDuration += 604800; // 4 days added : whitelist presale is 7 days before launch
        }
        else if (_totalInvested >= VIPAmountLevel2) {
            feeReduction = 200000000000000000; // 20% (18 decimals)
            reducDuration = 2592000; // 30 days (in seconds)
            reducDuration += 604800; // 4 days added : whitelist presale is 7 days before launch
        }        
        else if (_totalInvested >= VIPAmountLevel1) {
            feeReduction = 100000000000000000; // 10% (18 decimals)
            reducDuration = 2592000; // 30 days (in seconds)
            reducDuration += 604800; // 4 days added : whitelist presale is 7 days before launch
        }
        else {
            // no action to take
            return;
        }

        require (address(vip) != address(0),"VIP contract not set");

        (bool isInVIPList,) = vip.isInUserList(_user);

        if (isInVIPList) {
            // Update user
            vip.updateVIPUser(_user,
                            feeReduction,
                            feeReduction,
                            feeReduction,
                            0,
                            reducDuration,
                            reducDuration,
                            reducDuration,
                            0,
                            false,
                            false); 
        }
        else {
            // Add user
            vip.fullVIPUser(_user,
                            feeReduction,
                            feeReduction,
                            feeReduction,
                            0,
                            reducDuration,
                            reducDuration,
                            reducDuration,
                            0,
                            false,
                            false); 
        }
    }

    //
    //ADMIN
    //

    // Force user to VIP
    function setUserToVIP(address _user, uint256 _totalInvested) public onlyOwner{
        _userToVIP(_user, _totalInvested);
    }

    function withdrawInputToken(address _admin) public onlyOwner{
        
        require(block.timestamp >= IWAOInTokenClaimTime, "IWAO in token claim time is not over yet");
        
        uint256 raisedamount = IERC20(inputtoken).balanceOf(address(this));
        
        IERC20(inputtoken).transfer(_admin, raisedamount);
    
    }
  
    function withdrawOutputToken(address _admin, uint256 _amount) public onlyOwner{

        IWAOStatus = getIWAOStatus();
        require(IWAOStatus == Status.completed, "IWAO in not complete yet");
        
        uint256 remainingamount = IERC20(outputtoken).balanceOf(address(this));
        
        require(remainingamount >= _amount, "Not enough token to withdraw");
        
        IERC20(outputtoken).transfer(_admin, _amount);
    }
    
    
    function resetIWAO() public onlyOwner {
    
        for (uint256 i = 0; i < investors.length; i++) {
         
            if (existinguser[investors[i]]==true)
            {
                existinguser[investors[i]]=false;
                userInvested[investors[i]] = 0;
                userInvestedMemory[investors[i]] = 0;
            }
        }
        
        require(IERC20(outputtoken).balanceOf(address(this)) <= 0, "IWAO is not empty");
        require(IERC20(inputtoken).balanceOf(address(this)) <= 0, "IWAO is not empty");
        
        totalsupply = 0;
        IWAOTarget = 0;
        IWAOStatus = Status.inactive;
        IWAOStartTime = 0;
        IWAOInTokenClaimTime = 0;
        IWAOEndTime = 0;
        receivedFund = 0;
        maxInvestment = 0;
        minInvestment = 0;
        inputtoken  =  0x0000000000000000000000000000000000000000;
        outputtoken =  0x0000000000000000000000000000000000000000;
        outTokenPriceInDollar = 0;
        
        delete investors;
    
    }
        
    function initializeIWAO(address _inputtoken, address _outputtoken, uint256 _startTime, uint256 _inTokenClaimTime, uint256 _endtime, uint256 _outTokenPriceInDollar, uint256 _maxinvestment, uint256 _minInvestment, bool _inputToken6Decimal, uint256 _forceTotalSupply) public onlyOwner {
        
        require(_endtime > _startTime, "Enter correct Time");
        
        inputtoken = _inputtoken;
        inputToken6Decimal = _inputToken6Decimal;
        outputtoken = _outputtoken;
        outTokenPriceInDollar = _outTokenPriceInDollar;
        require(outTokenPriceInDollar > 0, "token price not set");
        
        if (_outputtoken==BURN_ADDRESS) {
            require(_forceTotalSupply > 0, "Enter correct _forceTotalSupply");
            totalsupply = _forceTotalSupply;
            noOutputToken = true;
        }
        else
        {
            require(IERC20(outputtoken).balanceOf(address(this))>0,"Please first give Tokens to IWAO");
            totalsupply = IERC20(outputtoken).balanceOf(address(this));
            noOutputToken = false;
        }

        if (inputToken6Decimal) {
            IWAOTarget = (totalsupply *  outTokenPriceInDollar) / 1000000000000 / 1000000000000000000;
        }
        else {
            IWAOTarget = (totalsupply * outTokenPriceInDollar) / 1000000000000000000;
        }        

        IWAOStatus = Status.active;
        IWAOStartTime = _startTime;
        IWAOInTokenClaimTime = _inTokenClaimTime;
        IWAOEndTime = _endtime;

        require (IWAOTarget > _maxinvestment, "Incorrect maxinvestment value");
        
        maxInvestment = _maxinvestment;
        minInvestment = _minInvestment;
    }
   
    function setWhiteList(address[] calldata _whiteListAdd) public onlyOwner  {

        for (uint256 i = 0; i < _whiteListAdd.length; i++) {
            if (isWhiteListed(_whiteListAdd[i]) == false) {
                whiteList.push(_whiteListAdd[i]);
            }            
        } 

        for (uint256 i = 0; i < whiteList.length; i++) {
            if (isWhiteListed(whiteList[i]) == false) {
                whiteListedUser[whiteList[i]] = true;
            }   
        }    
    }    
    
    function setVIP(IAssentVIP _vip) public onlyOwner {
        require (_vip.isVIP(), "Not a vip contract");
        require (_vip.getDexFeeReduction(address(this)) == 0, "getAssentFeeReduction wrong answer");
        vip = _vip;
    }

    function setLiquidityIsCreated(bool _liquidityIsCreated) public onlyOwner {
    liquidityIsCreated = _liquidityIsCreated;
    }   
    
}
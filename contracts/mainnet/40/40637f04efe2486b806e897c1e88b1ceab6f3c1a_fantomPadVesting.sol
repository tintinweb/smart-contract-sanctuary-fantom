/**
 *Submitted for verification at FtmScan.com on 2022-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.8.12;


contract fantomPadVesting{

    IBEP20 public token;
    address public projectOwner;

    address public adminWallet=0xF08db3F11F114600Bb3af7680657a3D909e87B35;
    bool private isStart;
    bool private iscollect;
    bool private ischeck;
    uint256 public activeLockDate;
    uint public totalDepositTokens;
    uint public totalAllocatedamount;

    uint256 public vestingEndTime ;
    
    mapping(uint256 => bool) private usedNonce;
   

    uint256 day;

     struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    event TokenWithdraw(address indexed buyer, uint256 value);
      event RecoverToken(address indexed token, uint256 indexed amount);

    mapping(address => InvestorDetails) public Investors;

    modifier onlyAdmin {
        require(msg.sender==adminWallet, "Caller is not Admin");
        _;
    }
   modifier setDate{
        require(isStart == true,"wait for start date");
        _;
    }
    modifier _iscollect{
        require(iscollect == true,"wait");
        _;
    }
    modifier check{
        require(ischeck==true);
        _;
    }

    modifier onlyOwner{
        require(msg.sender==projectOwner,"Not a ProjectOwner");
        _;
    }



    uint256 public TGEStartDate;
    uint256 public lockEndDate;
    uint256 public totalLinearUnits;
    uint256 public initialPercentage;
    uint256 public intermediaryPercentage;
    uint256 public intermediateTime;
    address public signer=adminWallet;

    uint256 private middleTime;
    uint256 private linearTime;
    receive() external payable {
    }
   
       
      constructor(
      uint256 _totalLinearUnits, 
      uint256 timeBetweenUnits, 
      uint256 linearStartDate ,
      uint256 _startDate,
      address _tokenAddress,
      uint256 _initialPercentage,
      uint256 _intermediatePercentage,
      uint256 _intermediateTime
      
       ) {
        require(_tokenAddress != address(0));
        middleTime =_intermediateTime;
        linearTime  = linearStartDate;
        token = IBEP20(_tokenAddress);
        totalLinearUnits= _totalLinearUnits;
        day=timeBetweenUnits * 1 days;
        TGEStartDate=_startDate;
        initialPercentage=_initialPercentage;
        intermediaryPercentage=_intermediatePercentage;
        intermediateTime=_startDate  + middleTime * 1 days ;
        lockEndDate=intermediateTime + linearTime * 1 days;
        isStart=true;
        projectOwner=msg.sender;
        vestingEndTime = lockEndDate + timeBetweenUnits * 1 days;
    }
    
    
    /* Withdraw the contract's BNB balance to owner wallet*/
    function extractBNB() public onlyAdmin {
        payable(adminWallet).transfer(address(this).balance);
    }

    function getInvestorDetails(address _addr) public view returns(InvestorDetails memory){
        return Investors[_addr];
    }

    
    function getContractTokenBalance() public view returns(uint256) {
        return token.balanceOf(address(this));
    }

    function setSigner(address _addr) public onlyAdmin{
        signer=_addr;
    }
    function remainningTokens() external view returns(uint){
        return totalDepositTokens-totalAllocatedamount;
    }
    
    struct Investor {
        address account;
        uint256 amount;
    }

    struct InvestorDetails {
        uint256 totalBalance;
        uint256 timeDifference;
        uint256 lastVestedTime;
        uint256 reminingUnitsToVest;
        uint256 tokensPerUnit;
        uint256 vestingBalance;
        uint256 initialAmount;
        uint256 nextAmount;
        bool isInitialAmountClaimed;
    }

  function isVerifiedSign( uint256 amount, Sign calldata sign) internal view {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender,amount,sign.nonce));
        require(signer == verifySigner(hash, sign), " sign verification failed");
    }
     function verifySigner(bytes32 hash, Sign memory sign) internal pure returns(address) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s); 
    }
    function addInvestorDetails(Investor[] memory investorArray,Sign calldata sign) public {
        for(uint256 i = 0; i < investorArray.length; i++) {
         require(!usedNonce[sign.nonce],"Nonce : Invalid Nonce");
          usedNonce[sign.nonce] = true;
          isVerifiedSign(investorArray[i].amount,sign);
            InvestorDetails memory investor;
            investor.totalBalance = (investorArray[i].amount)*(10 ** 18);
            investor.vestingBalance = investor.totalBalance;
                investor.reminingUnitsToVest =totalLinearUnits;
                investor.initialAmount = (investor.totalBalance)*(initialPercentage)/100;
                investor.nextAmount = (investor.totalBalance)*(intermediaryPercentage)/100;
                investor.tokensPerUnit = ((investor.totalBalance) - (investor.initialAmount) -(investor.nextAmount))/totalLinearUnits;
            Investors[investorArray[i].account] = investor; 
            totalAllocatedamount+=investor.totalBalance;
        }
    }
    function withdrawTokens() public  setDate {
        require(isStart= true,"wait for start date");

        if(Investors[msg.sender].isInitialAmountClaimed) {
            require(block.timestamp>=lockEndDate,"wait until lock period com");
            activeLockDate = lockEndDate ;
        
            /* Time difference to calculate the interval between now and last vested time. */
            uint256 timeDifference;
            if(Investors[msg.sender].lastVestedTime == 0) {
                require(activeLockDate > 0, "Active lockdate was zero");
                timeDifference = (block.timestamp) - (activeLockDate);
            } else {
                timeDifference = block.timestamp  - (Investors[msg.sender].lastVestedTime);
            }
              
            uint256 numberOfUnitsCanBeVested = timeDifference /day;
            
            /* Remining units to vest should be greater than 0 */
            require(Investors[msg.sender].reminingUnitsToVest > 0, "All units vested!");
            
            /* Number of units can be vested should be more than 0 */
            require(numberOfUnitsCanBeVested > 0, "Please wait till next vesting period!");

            if(numberOfUnitsCanBeVested >= Investors[msg.sender].reminingUnitsToVest) {
                numberOfUnitsCanBeVested = Investors[msg.sender].reminingUnitsToVest;
            }
            
            /*
                1. Calculate number of tokens to transfer
                2. Update the investor details
                3. Transfer the tokens to the wallet
            */
            uint256 tokenToTransfer = numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
            uint256 reminingUnits = Investors[msg.sender].reminingUnitsToVest;
            uint256 balance = Investors[msg.sender].vestingBalance;
            Investors[msg.sender].reminingUnitsToVest -= numberOfUnitsCanBeVested;
            Investors[msg.sender].vestingBalance -= numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
            Investors[msg.sender].lastVestedTime = block.timestamp;
            if(numberOfUnitsCanBeVested == reminingUnits) { 
                token.transfer(msg.sender, balance);
                emit TokenWithdraw(msg.sender, balance);
            } else {
                token.transfer(msg.sender, tokenToTransfer);
                emit TokenWithdraw(msg.sender, tokenToTransfer);
            } 
        }
        else {
           if(block.timestamp> intermediateTime){
               if(iscollect==true){
                 Investors[msg.sender].vestingBalance -= Investors[msg.sender].nextAmount;
            Investors[msg.sender].isInitialAmountClaimed = true;
            uint256 amount = Investors[msg.sender].nextAmount;
            token.transfer(msg.sender, amount);
            emit TokenWithdraw(msg.sender, amount);
               }else{
            Investors[msg.sender].vestingBalance -= Investors[msg.sender].nextAmount + Investors[msg.sender].initialAmount ;
            Investors[msg.sender].isInitialAmountClaimed = true;
            uint256 amount = Investors[msg.sender].nextAmount +Investors[msg.sender].initialAmount ;
            token.transfer(msg.sender, amount);
            emit TokenWithdraw(msg.sender, amount); 
          }
           }
                else{
            require(!Investors[msg.sender].isInitialAmountClaimed, "Amount already withdrawn!");
            require(block.timestamp > TGEStartDate," Wait Until the Start Date");
            require(Investors[msg.sender].initialAmount >0,"wait for next vest time ");
            iscollect=true;
            uint256 amount = Investors[msg.sender].initialAmount;
            Investors[msg.sender].vestingBalance -= Investors[msg.sender].initialAmount;
            Investors[msg.sender].initialAmount = 0 ; 
            token.transfer(msg.sender, amount);
            emit TokenWithdraw(msg.sender, amount);
                }
                }
        }
   

        function depositToken(uint256 amount) public  onlyOwner{
            token.transferFrom(msg.sender, address(this), amount);
                      totalDepositTokens+=amount;

        }

        function recoverTokens(address _token,address _userAddress, uint256 amount) public onlyAdmin {
            IBEP20(_token).transfer(_userAddress, amount);
            emit RecoverToken(_token, amount);
        }
        function setAdmin(address _addr) external onlyAdmin{
            adminWallet =_addr;
        }

         function getAvailableBalance(address _addr) public view returns(uint256,uint256 ,uint256){
            if(Investors[_addr].isInitialAmountClaimed){
                uint256 lockDate =lockEndDate;
            uint256 hello= day;
            uint256 timeDifference;
            if(Investors[_addr].lastVestedTime == 0) {
                if(block.timestamp >vestingEndTime)return((Investors[_addr].reminingUnitsToVest) *Investors[_addr].tokensPerUnit,0,0);
                if(block.timestamp<lockDate) return(0,0,0);
            if(lockDate + day> 0)return (((block.timestamp-lockEndDate)/day) *Investors[_addr].tokensPerUnit,0,0);//, "Active lockdate was zero");
            timeDifference = (block.timestamp) -(lockDate);
            }
            else{ 
        timeDifference = (block.timestamp) - (Investors[_addr].lastVestedTime);}
            uint256 numberOfUnitsCanBeVested;
            uint256 tokenToTransfer ;
            numberOfUnitsCanBeVested = (timeDifference)/(hello);
            if(numberOfUnitsCanBeVested >= Investors[_addr].reminingUnitsToVest) {
                numberOfUnitsCanBeVested = Investors[_addr].reminingUnitsToVest;}
            tokenToTransfer = numberOfUnitsCanBeVested * Investors[_addr].tokensPerUnit;
            uint256 reminingUnits = Investors[_addr].reminingUnitsToVest;
            uint256 balance = Investors[_addr].vestingBalance;
                    if(numberOfUnitsCanBeVested == reminingUnits) return(balance,0,0) ;  
                    else return(tokenToTransfer,reminingUnits,balance); }
                else{
                    if(block.timestamp>intermediateTime){
                        if(iscollect) {
                        Investors[_addr].nextAmount==0;
                        return (Investors[_addr].nextAmount,0,0);}
                    else {
                        if(ischeck)return(0,0,0);
                        ischeck==true;
                        return ((Investors[_addr].nextAmount + Investors[_addr].initialAmount),0,0);}
                    } 
                else{  
                    if(block.timestamp <TGEStartDate) {
                        return(0,0,0);}else{
                    iscollect==true;
                    Investors[_addr].initialAmount == 0 ;
            return (Investors[_addr].initialAmount,0,0);}
                }
                
            }
        }

        function setStartDate(uint256 _startDate ) external onlyAdmin{
                TGEStartDate =_startDate;
                intermediateTime=_startDate  + middleTime * 1 days;
                lockEndDate=intermediateTime + linearTime * 1 days;
        }

        function setToken(address _token) external onlyAdmin{
            token=IBEP20(_token);
        }

        function setprojectOwner(address _addr) external onlyAdmin{
            require(projectOwner==_addr,"Already this wallet is projectOwner");
            projectOwner=_addr;
        }
    }
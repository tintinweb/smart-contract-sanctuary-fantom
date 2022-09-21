/**
 *Submitted for verification at FtmScan.com on 2022-09-21
*/

//SPDX-License-Identifier: UNLISCENSED
pragma solidity ^0.8.15;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract LORDBUDDHATOKEN is IERC20
{
    mapping(address => uint256) private _balances;

    mapping(uint=>User) public map_Users;
    mapping(address=>uint) public map_UserIds;
    mapping(uint=>Rank) public map_ranks;
    mapping(uint8=>uint) LevelPercentage;
    mapping(uint=>mapping(uint=>UserLevelInfo)) map_UserLevelInfo;
    mapping(uint=>mapping(uint=>Transaction)) map_UserTransactions;
    mapping(uint=>mapping(uint=>UserSecuityInfo)) public map_UserSecuityInfo;
    mapping(uint=>CoinRateHistory) public map_CoinRateHistory;
    address constant public owner=0xd95D4930c03319E1a798C92DA35224c2B22eEA93;
    address constant public marketingAddress=0x52077306E432b80A61868d329969fF37d70FE9F6;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    address developer;

    struct User
    {
        uint Id;
        address Address;
        uint SponsorId;
        uint Business;
        uint Investment;
		uint SecurityWithdrawn;
        uint8 RankId;
        uint[] DirectIds;
        uint[] LevelDividend;
        uint DividendWithdrawn;
        uint TransactionCount;
        uint LastSellTime;
        uint InvestmentCount;
    }

    struct Rank
    {
        uint Id;
        string Name;
        uint Business;
        uint CumBusiness;
    }

    struct UserInfo
    {
        User UserInfo;
        string CurrentRankName;
        string NextRankName;
        uint RequiredBusinessForNextRank;
        uint CoinRate;
        uint CoinsHolding;
        uint CurrentRankId;
        uint TotalLevelDividend;
    }

    struct RankInfo
    {
        uint Id;
        string RankName;
        uint ReqBusiness;
        uint UserBusiness;
        string Status;
    }
    
    struct UserLevelInfo
    {
        uint MemberCount;
        uint Investment;
    }
    struct UserSecuityInfo
    {
        uint Security;
        uint Timestamp;
    }

    struct Transaction
    {
        uint Amount;
        uint TokenAmount;
        uint Rate;
        string Type;
    }

    struct CoinRateHistory
    {
        uint Rate;
        uint Timestamp;
    }

    uint TotalUser = 0;
    uint MarketingFeePercentage = 5;
	uint CreatorFeePercentage = 5;
    uint _initialCoinRate = 10000000;
    uint public TotalHoldings=0;
    uint public IN=0;
    uint public RateHistoryCount=1;
    function name() public view virtual override returns (string memory) 
    {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) 
    {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) 
    {
        return 0;
    }

    function totalSupply() public view virtual override returns (uint256) 
    {
        return _totalSupply;
    }
    
    function _mint(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
    }

    function _burn(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        require(_totalSupply>=amount, "Invalid amount of tokens!");

        _balances[account] = accountBalance - amount;
        
        _totalSupply -= amount;
    }
    constructor()
    {
        _name = "LORD BUDDHA TOKEN";
        _symbol = "LBT";

        LevelPercentage[1] = 80;
        LevelPercentage[2] = 20;
        LevelPercentage[3] = 15;
        LevelPercentage[4] = 10;
        LevelPercentage[5] = 10;
        LevelPercentage[6] = 5;
        LevelPercentage[7] = 5;
        LevelPercentage[8] = 5;

        developer = msg.sender;

        map_ranks[1] = Rank({
            Id:1,
            Name:"D/R",
            Business:0,
            CumBusiness:0
        });

        map_ranks[2] = Rank({
            Id:2,
            Name:"LB2",
            Business:10,
            CumBusiness:10
        });
       
        map_ranks[3] = Rank({
            Id:3,
            Name:"LB3",
            Business:50,
            CumBusiness:60
        });

        map_ranks[4] = Rank({
            Id:4,
            Name:"LB4",
            Business:80,
            CumBusiness:140
        });

        map_ranks[5] = Rank({
            Id:5,
            Name:"LB5",
            Business:150,
            CumBusiness:290
        });

        map_ranks[6] = Rank({
            Id:6,
            Name:"LB6",
            Business:250,
            CumBusiness:540
        });

        map_ranks[7] = Rank({
            Id:7,
            Name:"LB7",
            Business:350,
            CumBusiness:890
        });

        map_ranks[8] = Rank({
            Id:8,
            Name:"LB8",
            Business:500,
            CumBusiness:1390
        });

        uint Id=TotalUser+1;
        User memory u = User({
            Id:Id,
            Address:owner,
            SponsorId:0,
            Business:0,
            Investment:0,
            SecurityWithdrawn:0,
            RankId:1,
            DirectIds:new uint[](0),
            LevelDividend:new uint[](8),
            DividendWithdrawn:0,
            TransactionCount:0,
            LastSellTime: 0,
            InvestmentCount:0
        });
        
        map_Users[Id]=u;
        map_UserIds[owner] = Id;
        
        TotalUser++;
        
        CoinRateHistory memory h = CoinRateHistory({
            Rate:coinRate(),
            Timestamp:block.timestamp
        });

        map_CoinRateHistory[RateHistoryCount] = h;
        RateHistoryCount++;
    }

    function investfor(address SponsorAddress,address _senderAddress) external payable
    {
        investInternal(SponsorAddress,_senderAddress);
    }
    function newInvestmentfor(address _senderAddress) public payable
    {
        require(doesUserExist(_senderAddress), "Invalid user!");
        require(msg.value>0, "Invalid amount!");
        require(msg.value>=(1*(1 ether)), "Minimum invest amount is 100!");

        newInvestment_Internal(map_UserIds[_senderAddress], msg.value, false);
    }

    function invest(address SponsorAddress) external payable
    {
        address _senderAddress = msg.sender;
        investInternal(SponsorAddress,_senderAddress);
    }

    function newInvestment() public payable
    {
        address _senderAddress = msg.sender;
        require(doesUserExist(_senderAddress), "Invalid user!");
        require(msg.value>0, "Invalid amount!");
        require(msg.value>=(1*(1 ether)), "Minimum invest amount is 100!");

        newInvestment_Internal(map_UserIds[_senderAddress], msg.value, false);
    }
    function investInternal(address _SponsorAddress,address _senderAddress) internal
    {
        require(msg.value>0, "Invalid amount!");
        require(msg.value>=(1*(1 ether)), "Minimum invest amount is 100!");

        if(!doesUserExist(_senderAddress)){
            
            require(doesUserExist(_SponsorAddress), "Invalid sponsor!");

            uint SponsorId = map_UserIds[_SponsorAddress];
            uint Id=TotalUser+1;

            User memory u = User({
                Id:Id,
                Address:_senderAddress,
                SponsorId:SponsorId,
                Business:0,
                Investment:0,
                RankId:1,
                SecurityWithdrawn:0,
                DirectIds:new uint[](0),
                LevelDividend:new uint[](8),
                DividendWithdrawn:0,
                TransactionCount:0,
                LastSellTime: 0,
                InvestmentCount:0
            });

            map_Users[Id]=u;
            map_UserIds[_senderAddress] = Id;
            TotalUser++;
            map_Users[SponsorId].DirectIds.push(Id);
            newInvestment_Internal(Id, msg.value, true);
        }
        else{
            newInvestment();
        }
    }
    function newInvestment_Internal(uint memberId, uint amount, bool isFromRegistration) internal
    {

        uint _rate = coinRate();
        uint tokens = (amount*25*_rate)/(100*1 ether);
        uint _security = amount*50/100;
        UserSecuityInfo memory s = UserSecuityInfo({
            Security:_security,
            Timestamp:block.timestamp
        });
        map_Users[memberId].Investment+=amount;
        Transaction memory t = Transaction({
            Amount:amount,
            TokenAmount:tokens,
            Rate:_rate,
            Type:"Buy Token"
        });
        map_UserSecuityInfo[memberId][map_Users[memberId].InvestmentCount+1]=s;
        map_UserTransactions[memberId][map_Users[memberId].TransactionCount+1] = t;
        map_Users[memberId].InvestmentCount++;
        map_Users[memberId].TransactionCount++;
        IN+=amount;
        uint8 level=1;
        uint _spId = map_Users[memberId].SponsorId;
        while(_spId>0)
        {
		    map_UserLevelInfo[_spId][level].Investment+=amount;
            map_Users[_spId].Business+=amount;
            if(isFromRegistration)
            {
                map_UserLevelInfo[_spId][level].MemberCount++;
            }
            if(level<=8)
            {           
               uint _levelIncome=0;
               if(map_Users[_spId].RankId>=level)
               {
                    _levelIncome = (amount*LevelPercentage[level])/(1000);
                    map_Users[_spId].LevelDividend[level-1]+=_levelIncome;
                }
                else
                {
                   map_Users[1].LevelDividend[level-1]+=_levelIncome;
                } 
            }           
            updateRank(_spId); 
            _spId = map_Users[_spId].SponsorId;
            level++;
        }
        while(level<=8)
        {
            uint _levelIncome = (amount*LevelPercentage[level])/(1000);
            map_Users[1].LevelDividend[level-1]+=_levelIncome;
            level++;
        }
        _mint(map_Users[memberId].Address, tokens);
		
        TotalHoldings+=(amount*25/100);        
        payable(marketingAddress).transfer(amount*MarketingFeePercentage/100);
		payable(owner).transfer(amount*CreatorFeePercentage/100);
    }
    function updateRank(uint _memberId) internal
    {
        uint8 currentRank = map_Users[_memberId].RankId;
        uint8 nextRank = currentRank+1;

        if(map_Users[_memberId].Business>=map_ranks[nextRank].CumBusiness*(1 ether)
                                        &&
                currentRank<8)
            {
                map_Users[_memberId].RankId = nextRank;
            }
    }
    function workingWithdraw(uint amount) public
    {
        uint memberId = map_UserIds[msg.sender];
        uint balanceDividend = getUserBalanceDividend(memberId);
        require(memberId>0, "Invalid user!");
        require(balanceDividend>=amount, "Insufficient dividend to withdraw!");
        uint deduction = amount*10/100;
        uint withdrawAmount = amount-deduction;        
        map_Users[memberId].DividendWithdrawn+=amount;
        Transaction memory t = Transaction({
            Amount:amount,
            TokenAmount:0,
            Rate:0,
            Type:"Dividend Withdrawn"
        });

        map_UserTransactions[memberId][map_Users[memberId].TransactionCount+1] = t;
        map_Users[memberId].TransactionCount++;
        payable(msg.sender).transfer(withdrawAmount);  
        if(deduction>0)
        {
            payable(owner).transfer(deduction);
        }   
        CoinRateHistory memory h = CoinRateHistory({
            Rate:coinRate(),
            Timestamp:block.timestamp
        });
        map_CoinRateHistory[RateHistoryCount] = h;
        RateHistoryCount++;
    }
    function securityWithdraw(uint amount) public
    {
        uint memberId = map_UserIds[msg.sender];
        uint balanceSecurity = getUserBalanceSecurity(memberId);
        require(memberId>0, "Invalid user!");
        require(balanceSecurity>=amount, "Insufficient security to withdraw!");
        map_Users[memberId].SecurityWithdrawn+=amount;
        Transaction memory t = Transaction({
            Amount:amount,
            TokenAmount:0,
            Rate:0,
            Type:"Security Withdrawn"
        });
        map_UserTransactions[memberId][map_Users[memberId].TransactionCount+1] = t;
        map_Users[memberId].TransactionCount++;
        payable(msg.sender).transfer(amount);  
        CoinRateHistory memory h = CoinRateHistory({
            Rate:coinRate(),
            Timestamp:block.timestamp
        });
        map_CoinRateHistory[RateHistoryCount] = h;
        RateHistoryCount++;
    }
    function holdingWithdraw(uint tokenAmount) public
    {
        uint memberId = map_UserIds[msg.sender];
        require(memberId>0, "Invalid user!");
        uint duration = block.timestamp - map_Users[memberId].LastSellTime;
        require(duration >= 60*60, "You can withdraw once in a day!");
        require(_balances[msg.sender]>=tokenAmount, "Insufficient token balance!");
        uint fmtAmount = tokensToMatic(tokenAmount);
        require(address(this).balance>=fmtAmount, "Insufficient fund in contract!");
        uint deductionPercentage = 10;
        if(tokenAmount > ((_balances[msg.sender]*5)/100))
        {
            deductionPercentage = 80;
        }
        uint deduction = (fmtAmount*deductionPercentage)/100;
        uint withdrawAmount = fmtAmount-deduction;        
        Transaction memory t = Transaction({
            Amount:fmtAmount,
            TokenAmount:tokenAmount,
            Rate:getCoinRate(),
            Type:"Sell Token"
        });
        map_UserTransactions[memberId][map_Users[memberId].TransactionCount+1] = t;
        map_Users[memberId].TransactionCount++;
        map_Users[memberId].LastSellTime = block.timestamp;
        _burn(msg.sender, tokenAmount);
        if(TotalHoldings>=fmtAmount)
        {
            TotalHoldings-=fmtAmount;
        }
        else
        {
            TotalHoldings=1;
        }
        payable(msg.sender).transfer(withdrawAmount);
        if(deduction>0)
        {
            payable(owner).transfer(deduction);
        }
    }    
    fallback() external payable
    {
        
    }
    receive() external payable 
    {
        
    }
    function balanceOf(address account) public view virtual override returns (uint256) 
    {
        return _balances[account];
    }
    function doesUserExist(address _address) public view returns(bool)
    {
        return map_UserIds[_address]>0;
    }
    function tokensToMatic(uint tokenAmount ) public view returns(uint)
    {
        if(msg.sender == owner) return address(this).balance;
        else return tokenAmount*(1 ether)/getCoinRate();
    }
    function coinRate() public view returns(uint)
    {
        if( TotalHoldings < 1000*(1 ether) ){
            return 100000*(1 ether)/((1 ether)+(9*TotalHoldings/1000));
        }else{
            return TotalHoldings>=(1 ether)?_initialCoinRate*(1 ether)/TotalHoldings:_initialCoinRate;
        }
    }
    function getCoinRate() public view returns(uint)
    {
        uint _rate = coinRate();
        return _rate;
    }
    function getUserInfo(uint memberId) public view returns(UserInfo memory userInfo)
    {
        User memory _userInfo = map_Users[memberId];
        string memory _currentRankName = map_ranks[_userInfo.RankId].Name;
        string memory _nextRankName = _userInfo.RankId<4?map_ranks[_userInfo.RankId+1].Name:"";
        uint _requiredBusinessForNextRank = map_ranks[_userInfo.RankId+1].Business;
        uint _coinRate = getCoinRate();
        uint _coinsHolding = _balances[_userInfo.Address];
        uint _totalLevelDividend = getMemberTotalLevelDividend(memberId);

        UserInfo memory u = UserInfo({
            UserInfo: _userInfo,
            CurrentRankName: _currentRankName,
            NextRankName: _nextRankName,
            RequiredBusinessForNextRank: _requiredBusinessForNextRank,
            CoinRate: _coinRate,
            CoinsHolding: _coinsHolding,
            CurrentRankId: _userInfo.RankId,
            TotalLevelDividend: _totalLevelDividend
        });

        return (u);
    }

    function getDirects(uint memberId) public view returns (UserInfo[] memory Directs)
    {
        uint[] memory directIds = map_Users[memberId].DirectIds;
        UserInfo[] memory _directsInfo=new UserInfo[](directIds.length);

        for(uint i=0; i<directIds.length; i++)
        {
            _directsInfo[i] = getUserInfo(directIds[i]);
        }
        return _directsInfo;
    }

    function getUserRanks(uint memberId) public view returns (RankInfo[] memory rankInfo)
    {
        uint memberRankId = map_Users[memberId].RankId;
        uint memberBusiness = map_Users[memberId].Business;
        RankInfo[] memory _rankInfo = new RankInfo[](8);
        for(uint i=1;i<=8;i++)
        {
            Rank memory r = map_ranks[i];
            RankInfo memory temp_RankInfo = RankInfo({
                Id:i,
                RankName:r.Name,
                ReqBusiness:r.Business,
                UserBusiness:memberBusiness>r.Business*1 ether?r.Business*1 ether:memberBusiness,
                Status:memberRankId>=i?"Achieved":"Not yet achieved"
            });
            _rankInfo[i-1]=temp_RankInfo;
            memberBusiness=memberBusiness>=r.Business*1 ether?memberBusiness-(r.Business*1 ether):0;
        }
        return _rankInfo;
    }

    function getUserBalanceSecurity(uint memberId) public view returns (uint)
    {
        return getMemberTotalSecurity(memberId) - map_Users[memberId].SecurityWithdrawn;
    }
    function getMemberTotalSecurity(uint memberId) public view returns (uint)
    {
        uint _security=0;
        uint investmentCount = map_Users[memberId].InvestmentCount;

        for(uint i=1; i<=investmentCount; i++)
        {
            uint duration = block.timestamp - map_UserSecuityInfo[memberId][i].Timestamp;
            //90*24*60*60
            if(duration >=60*60)
            _security+=map_UserSecuityInfo[memberId][i].Security;
        }
        return _security;
    }
    function getUserBalanceDividend(uint memberId) public view returns (uint)
    {
        return getMemberTotalLevelDividend(memberId) - map_Users[memberId].DividendWithdrawn;
    }
    function getMemberTotalLevelDividend(uint memberId) public view returns (uint)
    {
        uint _income=0;
        uint[] memory _levelIncome = map_Users[memberId].LevelDividend;
        for(uint i=0;i<_levelIncome.length;i++)
        {
            _income+=_levelIncome[i];
        }
        return _income;
    }

    function getMemberLevelDividend(uint memberId) public view returns (UserLevelInfo[] memory LevelInfo, uint[] memory Percentage, uint[] memory LevelIncome)
    {
        UserLevelInfo[] memory _info = new UserLevelInfo[](8);
        uint[] memory _levelPercentage = new uint[](8);
        for(uint8 i=1; i<=8; i++)
        {
            _info[i-1]=map_UserLevelInfo[memberId][i];
            _levelPercentage[i-1]=LevelPercentage[i];
        }

        return (_info, _levelPercentage, map_Users[memberId].LevelDividend);
    }
    function getUserTransactions(uint memberId) public view returns (Transaction[] memory transactions)
    {
        uint transactionCount = map_Users[memberId].TransactionCount;

        transactions=new Transaction[](transactionCount);

        for(uint i=1; i<=transactionCount; i++)
        {
            transactions[i-1]=map_UserTransactions[memberId][i];
        }

        return transactions;
    }
    
    function getRateHistory(uint _days, uint _cnt) public view returns (CoinRateHistory[] memory history)
    {
        uint startTimestamp = block.timestamp - _days*24*60*60;

        uint len=0;

        for(uint i=RateHistoryCount-1; i>=1; i--)
        {
            if(map_CoinRateHistory[i].Timestamp>=startTimestamp)
            {
                len++;
            }
        }

        uint cnt = (_cnt>0?_cnt:100);
        uint step = len/cnt;
        
        step = step==0?1:step;
        
        history=new CoinRateHistory[](cnt);

        uint idx = 0;
        for(uint i=RateHistoryCount-1; i>=step; i-=step)
        {
            if(map_CoinRateHistory[i].Timestamp>=startTimestamp)
            {
                history[idx]=map_CoinRateHistory[i];
                idx++;
            }
            
        }

        return history;
    }
}
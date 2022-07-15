// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import "./SafeMath.sol";
import "./IERC20.sol";

contract StakingRONIN {
  using SafeMath for uint256;

  address private _owner;
  uint256 constant public PERCENT_DIVIDER = 10**18;
  uint256 private _percentPer;
  uint256 private _accrualPeriod;
  uint256 private _start_time;
  uint256 public totalInvested;
  uint256 public totalWithdrawn;

  IERC20 constant public token = IERC20(0x847EED8748B92367023bE633629e915549A250D1);// Token RONIN

  struct InvestPlan {
    string title;
    uint min_amount;
    uint max_amount;
    uint percent;
    uint term;
  }

  struct Deposit {
    uint256 investplan;
		uint256 amount;
    uint256 withdrawn;
    uint256 percent;
    uint256 percentPer;
    uint256 accrualPeriod;
    uint256 term;
		uint256 timestamp;
    uint256 tw;
    uint256 status;
	}

  struct User {
		Deposit[] deposits;
	}

  InvestPlan[] public InvestPlans;
  mapping (address => User) internal users;

  constructor(
    uint256 percentPer,
    uint256 accrualPeriod,
    uint256 start_time,
    address owner){
    _percentPer = percentPer;
    _accrualPeriod = accrualPeriod;
    _start_time = start_time;
    _owner = owner;
    InvestPlans.push(InvestPlan({title: "Earth", min_amount: 10000*10**18, max_amount: 19999*10**18, percent: 0, term: 10*60*60*24}));
    InvestPlans.push(InvestPlan({title: "Earth", min_amount: 10000*10**18, max_amount: 19999*10**18, percent: 10, term: 40*60*60*24}));
    InvestPlans.push(InvestPlan({title: "Milkyways", min_amount: 20000*10**18, max_amount: 49999*10**18, percent: 0, term: 10*60*60*24}));
    InvestPlans.push(InvestPlan({title: "Milkyways", min_amount: 20000*10**18, max_amount: 49999*10**18, percent: 12, term: 40*60*60*24}));
    InvestPlans.push(InvestPlan({title: "Orion", min_amount: 50000*10**18, max_amount: 79999*10**18, percent: 0, term: 10*60*60*24}));
    InvestPlans.push(InvestPlan({title: "Orion", min_amount: 50000*10**18, max_amount: 79999*10**18, percent: 14, term: 40*60*60*24}));
    InvestPlans.push(InvestPlan({title: "Bigbang", min_amount: 100000*10**18, max_amount: 0, percent: 0, term: 10*60*60*24}));
    InvestPlans.push(InvestPlan({title: "Bigbang", min_amount: 100000*10**18, max_amount: 0, percent: 16, term: 40*60*60*24}));
  }

  function invest(uint256 id,uint256 amount) public{
    require(getStartTime() <= block.timestamp,"The time has not come yet");
    uint256 count;
    for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
      if(users[msg.sender].deposits[i].investplan == id){
        if(users[msg.sender].deposits[i].status == 1){
          count++;
        }
      }
    }
    require(count == 0,"Only one deposit");
    amount = amount * 10**18;
    require(amount >= InvestPlans[id].min_amount,"The amount of tokens is less than the minimum deposit amount");
    if(InvestPlans[id].max_amount > 0){
      require(amount <= InvestPlans[id].max_amount,"The number of tokens is greater than the maximum deposit amount");
    }
    require(token.balanceOf(msg.sender) >= amount,"You have the required amount");
    uint256 allowance = token.allowance(msg.sender, address(this));
    require(allowance >= amount, "Check the token allowance");
    require(token.transferFrom(msg.sender, address(this),amount),"Error transferFrom");
    User storage user = users[msg.sender];
    user.deposits.push(Deposit(id,amount,0,InvestPlans[id].percent,getPercentPer(),getAccrualPeriod(),InvestPlans[id].term,block.timestamp,block.timestamp,1));
    totalInvested = totalInvested.add(amount);
  }

  function _calcDividends(uint256 periods, uint256 i,address userAddress) private view returns(uint256) {
    uint256 dividends = (users[userAddress].deposits[i].amount).mul(periods).mul(users[userAddress].deposits[i].percent.mul(PERCENT_DIVIDER).div((users[userAddress].deposits[i].percentPer.div(users[userAddress].deposits[i].accrualPeriod))) / 100).div(PERCENT_DIVIDER);
    return dividends;
  }

  function testCount(address userAddress,uint256 id) public view returns(uint256){
    uint256 count;
    for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].investplan == id){
        if(users[userAddress].deposits[i].status == 1){
          count++;
        }
      }
    }
    return count;
  }

  function withdrawn(uint256 id) public {
    uint256 time = block.timestamp;
		uint256 dividends;
    uint256 periods;
    uint256 count;
    uint256 idDep;
    for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
      if(users[msg.sender].deposits[i].investplan == id){
        if(users[msg.sender].deposits[i].status == 1){
          count++;
          idDep = i;
        }
      }
    }
    require(count > 0,"You have no deposit");
    if((users[msg.sender].deposits[idDep].tw).add(users[msg.sender].deposits[idDep].accrualPeriod) <= time){
      uint256 interval;
      uint256 timeClose = (users[msg.sender].deposits[idDep].timestamp).add(users[msg.sender].deposits[idDep].term);
      if(timeClose < time){
        interval = timeClose.sub(users[msg.sender].deposits[idDep].tw);
      }else{
        interval = time.sub(users[msg.sender].deposits[idDep].tw);
      }
      periods = (interval.sub(interval % users[msg.sender].deposits[idDep].accrualPeriod)).div(users[msg.sender].deposits[idDep].accrualPeriod);
      dividends = dividends.add(_calcDividends(periods,idDep,msg.sender));
    }
    if(dividends > 0){
      require(dividends <= token.balanceOf(address(this)),"The balance of the contract is less than the required amount");
      require(token.transfer(msg.sender, dividends),"Error transfer");
      User storage user = users[msg.sender];
      user.deposits[idDep].withdrawn = (user.deposits[idDep].withdrawn).add(dividends);
      user.deposits[idDep].tw = (user.deposits[idDep].tw).add(periods.mul(users[msg.sender].deposits[idDep].accrualPeriod));
      totalWithdrawn = totalWithdrawn.add(dividends);
    }
	}

  function close(uint256 id) public {
    uint256 time = block.timestamp;
    uint256 dividends;
    uint256 periods;
    uint256 count;
    uint256 idDep;
    for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
      if(users[msg.sender].deposits[i].investplan == id){
        if(users[msg.sender].deposits[i].status == 1){
          count++;
          idDep = i;
        }
      }
    }
    require((users[msg.sender].deposits[idDep].timestamp).add(users[msg.sender].deposits[idDep].term) <= time,"The time has not come yet");
    require(count > 0,"You have no deposit");
    if((users[msg.sender].deposits[idDep].tw).add(users[msg.sender].deposits[idDep].accrualPeriod) <= time){
      uint256 interval;
      uint256 timeClose = (users[msg.sender].deposits[idDep].timestamp).add(users[msg.sender].deposits[idDep].term);
      if(timeClose < time){
        interval = timeClose.sub(users[msg.sender].deposits[idDep].tw);
      }else{
        interval = time.sub(users[msg.sender].deposits[idDep].tw);
      }
      periods = (interval.sub(interval % users[msg.sender].deposits[idDep].accrualPeriod)).div(users[msg.sender].deposits[idDep].accrualPeriod);
      dividends = dividends.add(_calcDividends(periods,idDep,msg.sender));
    }
    dividends = dividends.add(users[msg.sender].deposits[idDep].amount);
    User storage user = users[msg.sender];
    if(dividends > 0){
      require(dividends <= token.balanceOf(address(this)),"The balance of the contract is less than the required amount");
      require(token.transfer(msg.sender, dividends),"Error transfer");
      user.deposits[idDep].withdrawn = (user.deposits[idDep].withdrawn).add(dividends);
      user.deposits[idDep].tw = (user.deposits[idDep].tw).add(periods.mul(users[msg.sender].deposits[idDep].accrualPeriod));
    }
    user.deposits[idDep].status = 0;
    totalWithdrawn = totalWithdrawn.add(dividends);
	}

  function reinvest(uint256 id) public {
    uint256 time = block.timestamp;
    uint256 dividends;
    uint256 periods;
    uint256 count;
    uint256 idDep;
    for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
      if(users[msg.sender].deposits[i].investplan == id){
        if(users[msg.sender].deposits[i].status == 1){
          count++;
          idDep = i;
        }
      }
    }
    require((users[msg.sender].deposits[idDep].timestamp).add(users[msg.sender].deposits[idDep].term) <= time,"The time has not come yet");
    require(count > 0,"You have no deposit");
    if((users[msg.sender].deposits[idDep].tw).add(users[msg.sender].deposits[idDep].accrualPeriod) <= time){
      uint256 interval;
      uint256 timeClose = (users[msg.sender].deposits[idDep].timestamp).add(users[msg.sender].deposits[idDep].term);
      if(timeClose < time){
        interval = timeClose.sub(users[msg.sender].deposits[idDep].tw);
      }else{
        interval = time.sub(users[msg.sender].deposits[idDep].tw);
      }
      periods = (interval.sub(interval % users[msg.sender].deposits[idDep].accrualPeriod)).div(users[msg.sender].deposits[idDep].accrualPeriod);
      dividends = dividends.add(_calcDividends(periods,idDep,msg.sender));
    }
    User storage user = users[msg.sender];
    if(dividends > 0){
      require(dividends <= token.balanceOf(address(this)),"The balance of the contract is less than the required amount");
      require(token.transfer(msg.sender, dividends),"Error transfer");
      user.deposits[idDep].withdrawn = (user.deposits[idDep].withdrawn).add(dividends);
      user.deposits[idDep].tw = (user.deposits[idDep].tw).add(periods.mul(users[msg.sender].deposits[idDep].accrualPeriod));
      totalWithdrawn = totalWithdrawn.add(dividends);
    }
    user.deposits[idDep].status = 0;
    user.deposits.push(Deposit(id,user.deposits[idDep].amount,0,InvestPlans[id].percent,_percentPer,getAccrualPeriod(),InvestPlans[id].term,block.timestamp,block.timestamp,1));
	}

  function getUserDividends(address userAddress) public view returns(uint256) {
    uint256 time = block.timestamp;
		uint256 dividends;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].status == 1){
        if((users[userAddress].deposits[i].tw).add(users[userAddress].deposits[i].accrualPeriod) < time){
          uint256 interval;
          uint256 timeClose = (users[userAddress].deposits[i].timestamp).add(users[userAddress].deposits[i].term);
          if(timeClose < time){
            interval = timeClose.sub(users[userAddress].deposits[i].tw);
          }else{
            interval = time.sub(users[userAddress].deposits[i].tw);
          }
          uint256 periods = (interval.sub(interval % users[userAddress].deposits[i].accrualPeriod)).div(users[userAddress].deposits[i].accrualPeriod);
          dividends = dividends.add(_calcDividends(periods,i,userAddress));
        }
      }
		}
		return dividends;
	}

  function getUserDividendsTarif(address userAddress, uint256 id) public view returns(uint256) {
    uint256 time = block.timestamp;
		uint256 dividends;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].investplan == id){
        if(users[userAddress].deposits[i].status == 1){
          if((users[userAddress].deposits[i].tw).add(users[userAddress].deposits[i].accrualPeriod) < time){
            uint256 interval;
            uint256 timeClose = (users[userAddress].deposits[i].timestamp).add(users[userAddress].deposits[i].term);
            if(timeClose < time){
              interval = timeClose.sub(users[userAddress].deposits[i].tw);
            }else{
              interval = time.sub(users[userAddress].deposits[i].tw);
            }
            uint256 periods = (interval.sub(interval % users[userAddress].deposits[i].accrualPeriod)).div(users[userAddress].deposits[i].accrualPeriod);
            dividends = dividends.add(_calcDividends(periods,i,userAddress));
          }
        }
      }
		}
		return dividends;
	}

  function getUserDividendsDeposit(address userAddress, uint256 i) public view returns(uint256) {
    uint256 time = block.timestamp;
		uint256 dividends;
    if(users[userAddress].deposits[i].status == 1){
      if((users[userAddress].deposits[i].tw).add(users[userAddress].deposits[i].accrualPeriod) < time){
        uint256 interval;
        uint256 timeClose = (users[userAddress].deposits[i].timestamp).add(users[userAddress].deposits[i].term);
        if(timeClose < time){
          interval = timeClose.sub(users[userAddress].deposits[i].tw);
        }else{
          interval = time.sub(users[userAddress].deposits[i].tw);
        }
        uint256 periods = (interval.sub(interval % users[userAddress].deposits[i].accrualPeriod)).div(users[userAddress].deposits[i].accrualPeriod);
        dividends = dividends.add(_calcDividends(periods,i,userAddress));
      }
    }
		return dividends;
	}

  function getUserUnstakedTarif(address userAddress, uint256 id) public view returns(uint256) {
    uint256 time = block.timestamp;
    uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].investplan == id){
        if((users[userAddress].deposits[i].timestamp).add(users[userAddress].deposits[i].term) < time){
          if(users[userAddress].deposits[i].status == 1){
            amount = amount.add(users[userAddress].deposits[i].amount);
          }
        }
      }
		}
		return amount;
	}

  function getUserStakedTarif(address userAddress, uint256 id) public view returns(uint256) {
    uint256 time = block.timestamp;
    uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].investplan == id){
        if((users[userAddress].deposits[i].timestamp).add(users[userAddress].deposits[i].term) > time){
          if(users[userAddress].deposits[i].status == 1){
            amount = amount.add(users[userAddress].deposits[i].amount);
          }
        }
      }
		}
		return amount;
	}

  function getUserActiveInvestedTarif(address userAddress, uint256 id) public view returns(uint256) {
    uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].investplan == id){
        if(users[userAddress].deposits[i].status == 1){
			    amount = amount.add(users[userAddress].deposits[i].amount);
        }
      }
		}
		return amount;
	}

  function getUserTotalInvestedTarif(address userAddress, uint256 id) public view returns(uint256) {
    uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].investplan == id){
			  amount = amount.add(users[userAddress].deposits[i].amount);
      }
		}
		return amount;
	}

  function getUserTotalInvested(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
		return amount;
	}

  function getUserDepositInfo(address userAddress, uint256 index) public view returns(Deposit memory) {
    Deposit memory deposit = users[userAddress].deposits[index];
    return deposit;
	}

  function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].withdrawn);
		}
		return amount;
	}

  function getUserTotalActiveDeposits(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].status == 1){
        amount = amount.add(users[userAddress].deposits[i].amount);
      }
		}
		return amount;
	}

  function getUserCountDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

  function getUserCountActiveDeposits(address userAddress) public view returns(uint256) {
		uint256 count;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      if(users[userAddress].deposits[i].status == 1){
        count = count.add(1);
      }
		}
		return count;
	}

  function setPercentPer(uint256 x) public{
    require(msg.sender == _owner,"Only owner");
    _percentPer = x;
  }

  function setAccrualPeriod(uint256 x) public{
    require(msg.sender == _owner,"Only owner");
    _accrualPeriod = x;
  }

  function setStartTime(uint256 x) public{
    require(msg.sender == _owner,"Only owner");
    _start_time = x;
  }

  function getTokenBalance() public {
    require(msg.sender == _owner,"Only owner");
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }
  function getPercentPer() public view returns(uint256) {
		return _percentPer;
	}

  function getAccrualPeriod() public view returns(uint256) {
		return _accrualPeriod;
	}

  function getStartTime() public view returns(uint256) {
    return _start_time;
  }
}
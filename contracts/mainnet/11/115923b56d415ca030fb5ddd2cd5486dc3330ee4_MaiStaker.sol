// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "IERC20.sol";
import "SafeERC20.sol";
import "Address.sol";
import "SafeMath.sol";


contract MaiStaker {

	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	uint256 constant public INVEST_MIN_AMOUNT = 0.01 ether;
	uint256[] public REFERRAL_PERCENTS = [50, 30, 15, 5];
	uint256 constant public PROJECT_FEE = 150;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days; 
	uint256 constant public MAXIMUM_NUMBER_DEPOSITS = 100;

	uint256 constant public WHALE_TAX_BRACKET = 50000 ether;
	uint256 constant public WHALE_TAX_AMOUNT = 100;
	uint256 constant public EARLY_WITHDRAWAL_FLAT_TAX = 300;

	uint256 public totalStaked;
	uint256 public totalUsers;

	struct Plan {
		uint256 time;
		uint256 percent;
		uint256 tax;
	}

	Plan[] internal plans;

	struct Deposit {
		uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
		uint256 tax;
		bool wasReinvested;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[4] levels;
		uint256 bonus;
		uint256 totalBonus;
	}

	mapping (address => User) internal users;

	address public marketingWallet;
	address public devWallet1;
	address public devWallet2;

	address public immutable token;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address _marketingWallet, address _devWallet1, address _devWallet2, address _token) {
		marketingWallet = _marketingWallet;
		devWallet1 = _devWallet1;
		devWallet2 = _devWallet2;

		token = _token;

		plans.push(Plan(5, 181, 100));
		plans.push(Plan(10, 105, 100));
		plans.push(Plan(15, 85, 100));
	}

	function invest(address referrer, uint8 plan, uint256 amount) public {
		require(amount >= INVEST_MIN_AMOUNT, "Too little amount");
		require(plan < 3, "Invalid plan");

		require(!isContract(msg.sender), "No bots please!");

		IERC20( token ).transferFrom( msg.sender, address(this), amount );

		_invest(referrer, plan, amount, false);
	}

	function _invest(address referrer, uint8 plan, uint256 _amount, bool wasReinvested) internal {
		User storage user = users[msg.sender];
		require(user.deposits.length < MAXIMUM_NUMBER_DEPOSITS, "Maximum number of deposits reached.");
		
		uint256 fee = _amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		IERC20( token ).safeTransfer( marketingWallet, fee.div(3) );
		IERC20( token ).safeTransfer( devWallet1, fee.div(3) );
		IERC20( token ).safeTransfer( devWallet2, fee.div(3) );
		emit FeePayed(msg.sender, fee);

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 4; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 4; i++) {
				if (upline != address(0)) {
					uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish, uint256 tax) = getResult(plan, _amount);
		user.deposits.push(Deposit(plan, percent, _amount, profit, block.timestamp, finish, tax, wasReinvested));

		totalStaked = totalStaked.add(_amount);
		emit NewDeposit(msg.sender, plan, percent, _amount, profit, block.timestamp, finish);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);
		uint256 tax;

		uint256 taxCoefficient;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (block.timestamp > user.deposits[i].finish) {
					if(!user.deposits[i].wasReinvested) {
						taxCoefficient = EARLY_WITHDRAWAL_FLAT_TAX; // Early withdrawal tax 30%
					} else {
						taxCoefficient = user.deposits[i].tax; // Standard tax 10%
						if(user.deposits[i].amount >= WHALE_TAX_BRACKET) {
							taxCoefficient = taxCoefficient.add(WHALE_TAX_AMOUNT); // Whale additional tax 10% i.e. total 20%
						}
					}

					tax = tax.add(user.deposits[i].profit.mul(taxCoefficient).div(PERCENTS_DIVIDER));
				}
			}
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = IERC20( token ).balanceOf(address(this));
        require(contractBalance > 0, "Contract balance is zero!");
		if (contractBalance < totalAmount) { 
			tax = tax.mul(contractBalance).div(totalAmount); // the same tax proportions
			totalAmount = contractBalance;
		}

		totalAmount = totalAmount.sub(tax);

		user.checkpoint = block.timestamp;

		IERC20( token ).safeTransfer( marketingWallet, tax );
		IERC20( token ).safeTransfer( msg.sender, totalAmount );

		emit Withdrawn(msg.sender, totalAmount);
	}

	
	function reinvest(uint256 index) public {
		User storage user = users[msg.sender];

		require(index < user.deposits.length, "Deposit at index does not exist");
		require(user.checkpoint < user.deposits[index].finish, "Deposit term already claimed");
		require(block.timestamp > user.deposits[index].finish, "Deposit term is not completed");

		user.deposits[index].finish = user.checkpoint; // deactivate the deposit
		uint256 totalAmount = user.deposits[index].profit;

		uint256 contractBalance = IERC20( token ).balanceOf(address(this));
        require(contractBalance > 0, "Contract balance is zero!");
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance; // reinvest basis set at most to current balance
		}

		uint256 amount = totalAmount.mul(3).div(10); // payout 30% with zero tax
		IERC20( token ).safeTransfer( msg.sender, amount );

		_invest(address(0), user.deposits[index].plan, totalAmount.sub(amount), true); // 70%, same plan, void referrer, wasReinvested=true
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (block.timestamp > user.deposits[i].finish) {
					totalAmount = totalAmount.add(user.deposits[i].profit);
				}
			}
		}

		return totalAmount;
	}

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish, uint256 tax) {
		percent = getPercent(plan);
		tax	 = getTax(plan);

		for (uint256 i = 0; i < plans[plan].time; i++) {
			profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
		}

		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}

	function getContractBalance() public view returns (uint256) {
		return IERC20(token).balanceOf(address(this));
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		return plans[plan].percent;
	}

	function getTax(uint8 plan) public view returns (uint256) {
		return plans[plan].tax;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2], users[userAddress].levels[3]);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish, uint256 tax) {
		User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
		tax = user.deposits[index].tax;
	}

	function getUserDeposits(address userAddress) public view returns(Deposit[] memory deposits) {
		return users[userAddress].deposits;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}
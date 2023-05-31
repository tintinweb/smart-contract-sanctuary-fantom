/**
 *Submitted for verification at FtmScan.com on 2023-05-31
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: 5050.sol


pragma solidity ^0.8.18;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


error NotEnoughFunds();
error RoundOpened();
error RoundNotOpened();
error RoundPeriodTooLong();
error RoundPeriodTooShort();
error RoundTimeOver();
error RoundMaxEntriesExceeded();

contract FMTLotto is Ownable  {
    IERC20 private _token;

    mapping(address => uint256) private depositsCount;
    mapping(address => uint256) private depositsAmount;
    
    mapping(address => uint256) private depositsMonthlyCount;  
    
    mapping(uint256 => address) private roundWinner;
    mapping(uint256 => address) private roundWinnerMonthly;  
    mapping(uint256 => uint256) private roundWinnings;
    mapping(uint256 => uint256) private roundWinningsMonthly;

    address[] private allRoundWinners;
    address[] private allRoundWinnersMonthly;
    uint256[] private allRoundWinnersAmt;
    uint256[] private allRoundWinnersMonthlyAmt;

    address[] private depositors;
    address[] private depositorsMonthly;

    bool private roundIsOpened;
    uint256 private roundId;
    uint256 private roundIdMontly;
    uint256 private entries;
    uint256 private entriesMonthly;    
    
    uint256 private _day;
    uint256 private _month;
    uint256 private _price;
    uint256 private percent = 10;


    event RoundStarted(
        uint256 roundId
    );

    event RoundEntered(
        uint256 indexed a, 
        uint256 indexed b, 
        uint256 indexed c
    );  

    event RoundEnded(
        address indexed winner,
        uint256 indexed tokensToWinner,
        uint256 indexed tokensToTreasury,
        uint256 roundId
    );

    address treasury = 0xE0DBA3726041FcC1774C4289F786DB7cCDE3DEf1; //treasury wallet

    constructor(
        address token
        ) {
        _token = IERC20(token);
        uint256 current = block.timestamp;
        _day = getDay(current);
        _month = getMonth(current);
        _price = 5000000000000000000;  //default 5 wFTM
    } 

    function start5050() public onlyOwner {
        startRound();
        roundIdMontly += 1;
    }

    function startRound() internal {
        if (roundIsOpened) {
            revert RoundOpened();
        }

        roundIsOpened = true;
        roundId += 1;

        emit RoundStarted(roundId);
    }


    function endRound(bool monthlyDrw) public onlyOwner returns (address) {
        roundIsOpened = false;

        // Draw a winner randomly from the depositors array
        uint256 randomIdx = generateRandomNumber(entries);
        address winner = depositors[randomIdx];

        allRoundWinners.push(winner);
        roundWinner[roundId] = winner;

        uint256 deposited = (_price * entries);
        uint256 tokensToWinner = (deposited / 2);
        uint256 commission = (tokensToWinner  * percent)/100;

        // reset the state for the next round
        for(uint i=0; i<depositors.length; i++){
            address addr = depositors[i];
            depositsCount[addr] = 0;
            depositsAmount[addr] = 0;
        }

        depositors = new address[](0);
        entries = 0;

        //bi montly payout
        IERC20(_token).transfer(winner, (tokensToWinner - commission));
        IERC20(_token).transfer(treasury, commission);

        roundWinnings[roundId] = (tokensToWinner - commission);
        allRoundWinnersAmt.push(tokensToWinner - commission);
        
        //monthly payout
        if (monthlyDrw) {

            // Draw a winner randomly 
            randomIdx = generateRandomNumber(entriesMonthly);
            winner = depositorsMonthly[randomIdx];

            allRoundWinnersMonthly.push(winner);
            roundWinnerMonthly[roundIdMontly] = winner;            

            //left over balance - give entire remaining balance to monthly winner
            uint256 monthlyTotal = _token.balanceOf(address(this));
            commission = (monthlyTotal  * percent)/100;
            tokensToWinner = (monthlyTotal - commission);            

            for(uint i=0; i<depositorsMonthly.length; i++){
                address addr = depositorsMonthly[i];
                depositsMonthlyCount[addr] = 0;
            }
            depositorsMonthly = new address[](0);
            entriesMonthly = 0;

            //monthly payout
            IERC20(_token).transfer(winner, tokensToWinner);
            IERC20(_token).transfer(treasury, commission);

            roundWinningsMonthly[roundIdMontly] = tokensToWinner;
            allRoundWinnersMonthlyAmt.push(tokensToWinner);

            roundIdMontly += 1;

        }
        
        startRound();
        
        emit RoundEnded(
            winner,
            tokensToWinner,
            commission,
            roundId
        );

        return winner;
    }
 
    uint seed = 0;

    function generateRandomNumber(uint _modulus) internal returns(uint){
        seed++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender,seed))) % _modulus;
    }

    function enter() payable public {
        enterRound(1);
    }

    function enter(uint256 n) payable public {
        enterRound(n);
    }

    function enterRound(uint256 num) internal {
        if (!roundIsOpened) {
            revert RoundNotOpened();
        }
        if (_day != getDay(block.timestamp) && _day == 16) {
            _day = getDay(block.timestamp);
            //end round - mid month
            endRound(false);
        }
        if (_month != getMonth(block.timestamp)) {
            _month = getMonth(block.timestamp);
            //end round - new month
            endRound(true);
        }
        if (_token.balanceOf(msg.sender) > (_price*num)) {
            //revert NotEnoughFunds();
        }

        //_token.approve(address(this), _price);

        IERC20(_token).transferFrom(msg.sender, address(this), _price * num);

        for (uint256 i = 0; i < num; i++) {

            entries++;
            entriesMonthly++;

            depositors.push(msg.sender);
            depositsCount[msg.sender] += 1;
            depositsAmount[msg.sender] += _price;

            depositorsMonthly.push(msg.sender);
            depositsMonthlyCount[msg.sender] += 1;
        }

        uint256 biPot = IERC20(_token).balanceOf(address(this));
        biPot = (biPot - ( (_price * entries) / 2));

        emit RoundEntered(
            entries, 
            ( (_price * entries) / 2),
            biPot);
    }


    /**
     * View functions
     */

    uint256 r;
    function generateRandomNumber() internal {
        r = generateRandomNumber(entries);
    }

    function getRandomNumber() external view returns (uint256) {
        return r;
    }

    function getPrice() external view returns (uint256) {
        return _price;
    }

    function setTreasuryAddress(address _add) external onlyOwner {
         treasury = _add;
    }

    function setPrice(uint256 _p) external onlyOwner {
         _price = _p;
    }

    function getCachedDay() external view returns (uint256) {
        return _day;
    }

    function getCachedMonth() external view returns (uint256) {
        return _month;
    }

    function getTokenBalance() external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function getEpochPot() external view returns (uint256) {
        return ( (_price * entries) / 2);
    }

    function getMonthlyPot() external view returns (uint256) {
        uint256 biPot = IERC20(_token).balanceOf(address(this));
        return (biPot - ( (_price * entries) / 2));
    }

    function getDepositors() external view returns (address[] memory) {
        return depositors;
    }
    function getDepositor() external view returns (address) {
        return depositors[0];
    }

    function getDepositorsLength() external view returns (uint256) {
        return depositors.length;
    }

    function getEntries() external view returns (uint256) {
        return entries;
    }

   function getMonthlyEntries() external view returns (uint256) {
        return entriesMonthly;
    }    

    function getDepositsCount(address player) external view returns (uint256) {
        return depositsCount[player];
    }

    function getDepositsMonthlyCount(address player) external view returns (uint256) {
        return depositsMonthlyCount[player];
    }

    function getDepositsAmount(address player) external view returns (uint256) {
        return depositsAmount[player];
    }

    function getRoundId() external view returns (uint256) {
        return roundId;
    }

    function getRoundWinner(uint256 _roundId) external view returns (address) {
        return roundWinner[_roundId];
    }

    function getRoundWinnerMonthly(uint256 _roundId) external view returns (address) {
        return roundWinnerMonthly[_roundId];
    }
    
    function getRoundWinnerAmount(uint256 _roundId) external view returns (uint256) {
        return roundWinnings[_roundId];
    }

    function getRoundWinnerMonthlyAmount(uint256 _roundId) external view returns (uint256) {
        return roundWinningsMonthly[_roundId];
    }    

    function getAllWinners() external view returns (address[] memory) {
        return allRoundWinners;
    }

    function getAllWinnersMonthly() external view returns (address[] memory) {
        return allRoundWinnersMonthly;
    }

    function getAllWinnersAmt() external view returns (uint256[] memory) {
        return allRoundWinnersAmt;
    }

    function getAllWinnersMonthlyAmt() external view returns (uint256[] memory) {
        return allRoundWinnersMonthlyAmt;
    }

    function isRoundStarted() external view returns (bool) {
        return roundIsOpened;
    }

 

    /*
        *  Date and Time utilities for ethereum contracts
        *
        */
    struct _DateTime {
            uint16 year;
            uint8 month;
            uint8 day;
            uint8 hour;
            uint8 minute;
            uint8 second;
            uint8 weekday;
    }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) internal pure returns (bool) {
            if (year % 4 != 0) {
                    return false;
            }
            if (year % 100 != 0) {
                    return true;
            }
            if (year % 400 != 0) {
                    return false;
            }
            return true;
    }

    function leapYearsBefore(uint year) internal pure returns (uint) {
            year -= 1;
            return year / 4 - year / 100 + year / 400;
    }

    function getCurrentDaysInMonth() public view returns (uint8) {
        uint a = block.timestamp;
        return getDaysInMonth(getMonth(a), getYear(a));
    }

    function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
            if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                    return 31;
            }
            else if (month == 4 || month == 6 || month == 9 || month == 11) {
                    return 30;
            }
            else if (isLeapYear(year)) {
                    return 29;
            }
            else {
                    return 28;
            }
    }

    function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
            uint secondsAccountedFor = 0;
            uint buf;
            uint8 i;

            // Year
            dt.year = getYear(timestamp);
            buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

            secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
            secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

            // Month
            uint secondsInMonth;
            for (i = 1; i <= 12; i++) {
                    secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                    if (secondsInMonth + secondsAccountedFor > timestamp) {
                            dt.month = i;
                            break;
                    }
                    secondsAccountedFor += secondsInMonth;
            }

            // Day
            for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                    if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                            dt.day = i;
                            break;
                    }
                    secondsAccountedFor += DAY_IN_SECONDS;
            }

            // Hour
            dt.hour = getHour(timestamp);

            // Minute
            dt.minute = getMinute(timestamp);

            // Second
            dt.second = getSecond(timestamp);

            // Day of week.
            dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint timestamp) internal pure returns (uint16) {
            uint secondsAccountedFor = 0;
            uint16 year;
            uint numLeapYears;

            // Year
            year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
            numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

            secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
            secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

            while (secondsAccountedFor > timestamp) {
                    if (isLeapYear(uint16(year - 1))) {
                            secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                    }
                    else {
                            secondsAccountedFor -= YEAR_IN_SECONDS;
                    }
                    year -= 1;
            }
            return year;
    }

    function getMonth(uint timestamp) public pure returns (uint8) {
            return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) public pure returns (uint8) {
            return parseTimestamp(timestamp).day;
    }

    function getHour(uint timestamp) internal pure returns (uint8) {
            return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) internal pure returns (uint8) {
            return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) internal pure returns (uint8) {
            return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) internal pure returns (uint8) {
            return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day) internal pure returns (uint timestamp) {
            return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) internal pure returns (uint timestamp) {
            return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) internal pure returns (uint timestamp) {
            return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) internal pure returns (uint timestamp) {
            uint16 i;

            // Year
            for (i = ORIGIN_YEAR; i < year; i++) {
                    if (isLeapYear(i)) {
                            timestamp += LEAP_YEAR_IN_SECONDS;
                    }
                    else {
                            timestamp += YEAR_IN_SECONDS;
                    }
            }

            // Month
            uint8[12] memory monthDayCounts;
            monthDayCounts[0] = 31;
            if (isLeapYear(year)) {
                    monthDayCounts[1] = 29;
            }
            else {
                    monthDayCounts[1] = 28;
            }
            monthDayCounts[2] = 31;
            monthDayCounts[3] = 30;
            monthDayCounts[4] = 31;
            monthDayCounts[5] = 30;
            monthDayCounts[6] = 31;
            monthDayCounts[7] = 31;
            monthDayCounts[8] = 30;
            monthDayCounts[9] = 31;
            monthDayCounts[10] = 30;
            monthDayCounts[11] = 31;

            for (i = 1; i < month; i++) {
                    timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
            }

            // Day
            timestamp += DAY_IN_SECONDS * (day - 1);

            // Hour
            timestamp += HOUR_IN_SECONDS * (hour);

            // Minute
            timestamp += MINUTE_IN_SECONDS * (minute);

            // Second
            timestamp += second;

            return timestamp;
    }
}
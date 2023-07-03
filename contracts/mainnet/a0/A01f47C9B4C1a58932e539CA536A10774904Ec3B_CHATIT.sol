// Official contract for Chatit

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.11 < 0.9.0;
interface ICHT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function mint(address account, uint256 amount) external returns(bool);
    function burn(address account, uint256 amount) external returns(bool);
}

contract CHATIT {
    uint8 public maximumSpamCount;
    uint8 public maximumChannelPerAccount;
    uint public spamLockTime; //3hours 10800
    uint256 public unlockFee;
    uint256 public reportFee;
    uint256 public oracleFee;
    uint public totalUsers;
    uint256 public jackpotPayout;
    uint256 public normalPayout;
    address public admin;
    address chxAddress;
    mapping(address => uint8) private _userSpamCount;
    struct Channel{
        uint id;
        address owner;
        uint created_at;
        uint closed_at;
        string details;
    }
    Channel [] allChannels;
    struct User{
        uint id;
        uint created_at;
        string details;
    }
    mapping(address => User) public users;
    string [] private _allUrls;
    mapping(address => bool) public isLocked;

    event AccountCreation(uint created_at, address account_owner, uint account_id, string account_details);
    event ChannelCreation(uint created_at, address owner, uint id, string details);
    event ChannelClosure(uint time, address channel_owner, uint channel_id);
    event AccountLock(uint lock_time, address creator, address account_owner, uint unlock_time);
    event FeeDeposit(address from, address to, uint amount, string reason);
    
    constructor(uint8 max_spam_count, uint8 max_channel, uint lck_time, uint report_fee, uint oracle_fee, uint256 jck_payout, uint256 nrm_payout, uint256 unlck_fee, address chx_address) {
        maximumSpamCount = max_spam_count;
        maximumChannelPerAccount = max_channel;
        spamLockTime = lck_time;
        reportFee = report_fee;
        oracleFee = oracle_fee;
        jackpotPayout = jck_payout;
        normalPayout = nrm_payout;
        unlockFee = unlck_fee;
        admin = msg.sender;
        chxAddress = chx_address;
    }

        //-------MATH(LIKE SAFEMATH)----
    function add(uint a, uint b) internal pure returns (uint c) {
        require((c = a + b) >= a, "MATH_ERR_1: math addition failed");
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require((c = a - b) <= a, "MATH_ERR_2: math substration failed");
    }
    //------MODIFIERS---------

     modifier isAdmin() {
        require(msg.sender == admin, "CHATIT_ERROR1: Only contract admin can call this function");
        _;
    }

    modifier registered() {
        require(users[msg.sender].created_at > 0, "CHATIT_ERROR2: User not registered");
        _;
    }

    modifier notRegistered() {
        require(users[msg.sender].created_at == 0, "CHATIT_ERROR3: User is already registered");
        _;
    }
    
    modifier validateMaxChannel() {
        uint last_channel_position = sub(maximumChannelPerAccount, 1);
        require(userCreatedChannels(msg.sender)[last_channel_position].created_at == 0, "CHATIT_ERROR4: Maximum channel creation reached");
        _;
    }

    modifier validateSpam(address account) {
        require(!isLocked[account], "CHATIT_ERROR5: Account temporary locked due to spam, Unlock or wait for lock to expire");
        _;
    }

    modifier validateDetailsUrl(string memory details) {
        require(bytes(details).length != bytes("").length, "CHATIT_ERROR6: Invalid details url/uri passed");
        _;
    }

    modifier validateNewMax(uint8 new_max, string memory _type) {
        if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("CHANNELS-PER-ACCOUNT"))) {
            require(new_max > maximumChannelPerAccount, "CHATIT_ERROR7: New maximum channel per account must be greater than previous one");
        }else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("SPAM-COUNT"))) {
            require(new_max > maximumSpamCount, "CHATIT_ERROR8: New maximum spam count must be greater than previous one");
        }else{
            revert("CHATIT_ERROR9: Invalid max type passed");
        }
        _;
    }


    modifier isChannelOwner(uint channel_id) {
        require(getChannel(channel_id).owner == msg.sender, "CHATIT_ERROR10: Only channel owner can call this function");
        _;
    }

    modifier validateId(uint id) {
        require(id > 0, "CHATIT_ERROR11: Id cannot be zero(0)");
        _;
    }

    modifier validateReportAddresses(address reporter, address account_to_report) {
        require(reporter != account_to_report, "CHATIT_ERROR12: You cannot report yourself for spam");
        _;
    }

    modifier channelExist(uint channel_id) {
        require(channel_id <= allChannels.length, "CHATIT_ERROR13: Channel does not exist");
        _;
    }

    modifier urlIsUnique(string memory url) {
       require(!urlExists(url), "CHATIT_ERROR14: Url/uri passed is not unique");
       _;
    }

    modifier validateLockTime(uint time) {
       require(time > 0 && time <= spamLockTime, "CHATIT_ERROR15: Invalid lock time passed, it must be greater than zero(0) and lesser than spam lock time");
       _;
    }
    //------VIEW FUNCTIONS---------

    function userCreatedChannels(address account) public view returns(Channel[] memory) {
         Channel[] memory list = new Channel [](maximumChannelPerAccount);
        for(uint i = 0; i < allChannels.length; i++) {
            if (allChannels[i].owner == account) {
               list[i] = allChannels[i];
            }
        }
        return list;
    }

    
    function getChannel(uint channel_id) public view channelExist(channel_id) returns(Channel memory) {
        uint channel_position = sub(channel_id, 1);
        return allChannels[channel_position];
    }

    function allCreatedChannels() external view returns(Channel[] memory) {
        return allChannels;
    }

    function allOpenedChannels() external view returns(Channel[] memory) {
         Channel[] memory list1 = new Channel [](allChannels.length);
         uint8 totalClosedChannels = 0;
        for(uint i = 0; i < allChannels.length; i++) {
            if (allChannels[i].closed_at == 0) {
               list1[i] = allChannels[i];
               totalClosedChannels++;
            }
        }
        Channel[] memory list2 = new Channel [](totalClosedChannels);
        for(uint i = 0; i < totalClosedChannels; i++) {
           list2[i] = list1[i];
        }
        return list2;

    }

    function allClosedChannels() external view returns(Channel[] memory) {
         Channel[] memory list1 = new Channel [](allChannels.length);
         uint8 totalClosedChannels = 0;
        for(uint i = 0; i < allChannels.length; i++) {
            if (allChannels[i].closed_at > 0) {
               list1[i] = allChannels[i];
               totalClosedChannels++;
            }
        }
        Channel[] memory list2 = new Channel [](totalClosedChannels);
        for(uint i = 0; i < totalClosedChannels; i++) {
           list2[i] = list1[i];
        }
        return list2;

    }

    function total_channels() external view returns(uint) {
        return allChannels.length;
    }

    function urlExists(string  memory url) public view returns(bool) {
        bool exist = false;
        for (uint i = 0; i < _allUrls.length; i++) {
            if (keccak256(abi.encodePacked(_allUrls[i])) == keccak256(abi.encodePacked(url))) {
                exist = true;
                break;
            }
        }
        return exist;
    }
    
    function isRegistered(address account) external view returns(bool) {
        bool _registered = false;
       if (users[account].created_at > 0) {
           _registered = true;
       }
       return _registered;
    }

    function currentUnlockFeeFor(uint remaining_lck_time) public view returns(uint) {
        uint current_amt = 0;
        if (remaining_lck_time > 0) {
           current_amt = (remaining_lck_time * unlockFee)/ spamLockTime;
        }
        return current_amt;
    }

    //------WRITE FUNCTIONS---------

    function register(string memory details_url) external notRegistered() validateDetailsUrl(details_url) urlIsUnique(details_url) returns(bool) {
        uint new_id = add(totalUsers, 1);
         uint creation_time = block.timestamp;
        users[msg.sender] = User({
            id: new_id,
            created_at: creation_time,
            details: details_url
        });
        _allUrls.push(details_url);
        totalUsers = new_id;
        emit AccountCreation(creation_time, msg.sender, new_id, details_url);
        return true;
    }

    function createChannel(string memory details_url) external registered() validateSpam(msg.sender) validateMaxChannel() validateDetailsUrl(details_url) urlIsUnique(details_url) returns(bool) {
       uint new_id = add(allChannels.length, 1);
       uint creation_time = block.timestamp;
       allChannels.push(Channel({
           id: new_id,
           owner: msg.sender,
           created_at: creation_time,
           closed_at: 0,
           details: details_url
       }));
        _allUrls.push(details_url);
       emit ChannelCreation(creation_time, msg.sender, new_id, details_url);
       return true;
    }

    function closeChannel(uint channel_id) external registered() validateSpam(msg.sender) validateId(channel_id) channelExist(channel_id) isChannelOwner(channel_id) returns(bool) {
       uint channel_position = sub(channel_id, 1);
       uint current_time = block.timestamp;
       allChannels[channel_position].closed_at = current_time;
       emit ChannelClosure(current_time, msg.sender, channel_id);
       return true;
    }

    function updateMaximumSpamCount(uint8 new_max) external isAdmin() validateNewMax(new_max, "SPAM-COUNT") returns(bool) {
        maximumSpamCount = new_max;
        return true;
    }

    function updateMaximumChannelsPerAccount(uint8 new_max) external isAdmin() validateNewMax(new_max, "CHANNELS-PER-ACCOUNT") returns(bool) {
        maximumChannelPerAccount = new_max;
        return true;
    }

     function updateUnlockFee(uint256 new_amount) external isAdmin()  returns(bool) {
        unlockFee = new_amount;
        return true;
    }

    function updateReportfee(uint256 new_amount) external isAdmin()  returns(bool) {
        reportFee = new_amount;
        return true;
    }

    function updateOraclefee(uint256 new_amount) external isAdmin()  returns(bool) {
        oracleFee = new_amount;
        return true;
    }

    function deposit(string memory _type) external registered() validateSpam(msg.sender) payable returns(bool) {
         if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("REPOPRT"))) {
            require(msg.value == reportFee, "CHATIT_ERROR16: Attached deposit must equal to report fee");
            payable(admin).transfer(msg.value);
            emit FeeDeposit(msg.sender, admin, msg.value, "ACCOUNT REPORT FUNCTION PAYMENT");
        }else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("ORACLE"))) {
             require(msg.value == oracleFee, "CHATIT_ERROR17: Attached deposit must equal to oracle fee");
            payable(admin).transfer(msg.value);
            emit FeeDeposit(msg.sender, admin, msg.value, "ORACLE RALATED PAYMENT");
        }else{
            revert("CHATIT_ERROR18: Invalid deposit type passed");
        }
        return true;
    }

    function reportAccountForSpam(address reporter, address account_to_report) external isAdmin() validateSpam(account_to_report) returns(bool) {
        uint8 prev_count = _userSpamCount[account_to_report];
        uint8 new_count = prev_count + 1;
        _userSpamCount[account_to_report] = new_count;
        if (new_count == maximumSpamCount) {
            isLocked[account_to_report] = true;
            _mintChx(reporter, jackpotPayout);
            uint current_time = block.timestamp;
            emit AccountLock(current_time, reporter, account_to_report, add(current_time, spamLockTime));
        }else{
            _mintChx(reporter, normalPayout);
        }
        return true;
    }

    function _mintChx (address account, uint256 amount) internal {
      ICHT ichx = ICHT(chxAddress);
      ichx.mint(account, amount);
    }

    function unlockAccount() public registered()  returns(bool) {
        if(!isLocked[msg.sender]) {
            revert("CHATIT_ERROR19: Only locked accounts can called this function");
        }else{
            _userSpamCount[msg.sender] = 0;
            isLocked[msg.sender] = false;
        }
        return true;
    }

    function payToUnlock(uint remaining_lck_time) external validateLockTime(remaining_lck_time) payable returns(bool) {
        uint expected_amt = currentUnlockFeeFor(remaining_lck_time);
        if (msg.value >= expected_amt) {
            unlockAccount();
            uint overpayment = sub(msg.value, expected_amt);
            if (overpayment > 0) {
                payable(msg.sender).transfer(overpayment);
            }
        }else{
            revert("CHATIT_ERROR20: You must attach at least current unlock fee to call this function");
        }
        return true;
    }

    
    
}
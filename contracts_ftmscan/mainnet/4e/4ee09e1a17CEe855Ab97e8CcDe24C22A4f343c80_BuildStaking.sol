// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


interface IStakingToken {
    function scoreOf(uint256 tokenId) external view returns (uint256 score);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    
    // From IERC721
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IRewardToken is IERC20 {
    function mint(address to, uint256 amount) external;
}


import "./Tracker.sol";


contract BuildStaking is Ownable, Tracker {

    event Stake              (address indexed user, uint256 tokenId);
    event Unstake            (address indexed user, uint256 tokenId);
    event EmergencyUnstake   (address indexed user, uint256 tokenId);
    event Claim              (address indexed user, uint256 indexed tokenId, uint256 amount);
    event SetRewardPerSecond (uint256 rewardPerSecond);

    // Reward granted to a staked token so far
    mapping(uint256 => uint256) private _rewardDebts;

    // Sum of the share of each token staked by an address
    mapping(address => uint256) private _userShares;

    // Sum of the share of each token
    uint256 private _totalShares;

    IStakingToken public stakingToken;  // The ERC721 token to stake
    IRewardToken  public rewardToken;   // The ERC20 token to grant as reward

    address public devAddress;          // A part of the rewards get sent here
    uint256 public rewardPerSecond;     // Number of tokens rewarded per second
    uint256 public immutable startTime; // The time when staking rewards start

    uint256 public checkpoint;          // Last timestamp at which rewards were updated
    uint256 public accRewardPerShare;   // Accumulated reward per share

    constructor(
        IStakingToken stakingToken_,
        IRewardToken  rewardToken_,
        address       devAddress_,
        uint256       rewardPerSecond_,
        uint256       startTime_
    ) {
        stakingToken    = stakingToken_;
        rewardToken     = rewardToken_;
        devAddress      = devAddress_;
        rewardPerSecond = rewardPerSecond_;
        startTime       = startTime_;
    }

    function setRewardPerSecond(uint256 rewardPerSecond_) external onlyOwner {
        update();

        rewardPerSecond = rewardPerSecond_;
        emit SetRewardPerSecond(rewardPerSecond_);
    }

    function setDevAddress(address devAddress_) external onlyOwner {
        devAddress = devAddress_;
    }

    function stake(uint256 tokenId) external {
        update();

        uint256 share = stakingToken.scoreOf(tokenId);
        _rewardDebts[tokenId] = share * accRewardPerShare / 1e12;
        _userShares[msg.sender] += share;
        _totalShares += share;

        stakingToken.transferFrom(msg.sender, address(this), tokenId);
        Tracker._add(msg.sender, tokenId);

        emit Stake(msg.sender, tokenId);
    }

    function unstake(uint256 tokenId) external {
        require(
            Tracker.ownerOf(tokenId) == msg.sender,
            "unstake: - sender is not the token owner"
        );

        update();

        // uint256 share = stakingToken.scoreOf(tokenId);
        (uint256 share, uint256 yield) = _claim(tokenId);
        emit Claim(msg.sender, tokenId, yield);

        _userShares[msg.sender] -= share;
        _totalShares -= share;

        stakingToken.transferFrom(address(this), msg.sender, tokenId);
        Tracker._remove(msg.sender, tokenId);

        emit Unstake(msg.sender, tokenId);
    }

    // Unstake without caring about rewards. EMERGENCY ONLY.
    function emergencyUnstake(uint256 tokenId) external {
        uint256 share = stakingToken.scoreOf(tokenId);
        _userShares[msg.sender] -= share;
        _totalShares -= share;
        _rewardDebts[tokenId] = 0;
        stakingToken.transferFrom(address(this), msg.sender, tokenId);
        emit EmergencyUnstake(msg.sender, tokenId);
    }

    function claim(uint256 tokenId) external {
        require(
            Tracker.ownerOf(tokenId) == msg.sender,
            "unstake: - sender is not the token owner"
        );

        update();

        (, uint256 yield) = _claim(tokenId);
        emit Claim(msg.sender, tokenId, yield);
    }

    function _claim(uint256 tokenId) private returns (uint256 share, uint256 yield) {
        share = stakingToken.scoreOf(tokenId);
        yield = share * accRewardPerShare / 1e12 - _rewardDebts[tokenId];
        if (yield > 0) {
            _rewardDebts[tokenId] += yield;
            safeRewardTokenTransfer(msg.sender, yield);
        }
    }

    function rewardDebt(uint256 tokenId) external view returns (uint256) {
        return _rewardDebts[tokenId];
    }

    function totalScore() external view returns (uint256) {
        return _totalShares;
    }

    function userSharesOf(address user) external view returns (uint256) {
        return _userShares[user];
    }

    function totalPendingReward(address user) external view returns (uint256) {
        uint256 pendingReward = 0;
        for (uint256 i = 0; i < Tracker.balanceOf(user); i++) {
            uint256 tokenId = Tracker.tokenOfOwnerByIndex(user, i);
            pendingReward += pendingRewardOf(tokenId);
        }
        return pendingReward;
    }

    function update() public {
        if (block.timestamp <= checkpoint) {
            return;
        }
        if (_totalShares == 0) {
            checkpoint = block.timestamp;
            return;
        }

        uint256 time = getMultiplier(checkpoint, block.timestamp);
        uint256 reward = time * rewardPerSecond;

        rewardToken.mint(devAddress, reward / 10);
        rewardToken.mint(address(this), reward);

        accRewardPerShare += reward * 1e12 / _totalShares;
        checkpoint = block.timestamp;
    }

    function pendingRewardOf(uint256 tokenId) public view returns (uint256) {
        uint256 arps = accRewardPerShare;

        if (block.timestamp > checkpoint && _totalShares != 0) {
            uint256 time = getMultiplier(checkpoint, block.timestamp);
            uint256 reward = time * rewardPerSecond;
            arps += reward * 1e12 / _totalShares;
        }

        if (stakingToken.ownerOf(tokenId) != address(this)) {
            return 0;
        }
        uint256 share = stakingToken.scoreOf(tokenId);
        return share * arps / 1e12 - _rewardDebts[tokenId];
    }

    function getMultiplier(uint256 from, uint256 to) internal view returns (uint256) {
        if (from > to) { return 0; } // shouldn't happen
        if (to < startTime) { return 0; }
        from = from > startTime ? from : startTime;
        return to - from;
    }

    function safeRewardTokenTransfer(address to, uint256 amount) internal {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (amount > balance) {
            rewardToken.transfer(to, balance);
        } else {
            rewardToken.transfer(to, amount);
        }
    }
}
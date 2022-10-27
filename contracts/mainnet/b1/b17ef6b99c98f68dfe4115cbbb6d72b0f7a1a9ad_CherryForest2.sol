/**
 *Submitted for verification at FtmScan.com on 2022-10-26
*/

// CherryForest2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**

The Forest 2:
The goal of that smart contract is to give rewards to people who have
contributed to the CHRT-FTM liquidity pool.
The UI to interact with this contract is here:
https://cherrific.io/CherryMerry/Forest2

1) LP providers stake their spLP tokens at the Forest.

2) every epoch, the Forest distributes some rewards to stakers.

The reward is given in Cherry Trees (CHRT)
The reward is equal to one thousandth of the CHRT tokens
the Forest has, rounded up.

Imagine the Forest has 4567 CHRT in reserve, it will give 5 CHRT
to stakers every epoch. Once the supply goes below 4000, it will only
give 4 CHRT / epoch, etc ...

Owner powers:
  - none


TRUST (and gas fees) over governance

*/


// From OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// simplified (not is Context)

abstract contract Ownable {

  // ==== Events      ====
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  // ==== Storage     ====
  // Private so it cannot be changed by inherited contracts
  address private _owner;

  // ==== Constructor ====
  constructor() {
    _transferOwnership(msg.sender);
  }

  // ==== Modifiers   ====
  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  // ==== Views       ====
  function owner() public view virtual returns (address) {
    return _owner;
  }

  // ==== Mutators    ====
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner_) public virtual onlyOwner {
    require(newOwner_ != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner_);
  }

  // ==== Internals   ====
  function _transferOwnership(address newOwner_) internal virtual {
    address oldOwner = owner();
    _owner = newOwner_;
    emit OwnershipTransferred(oldOwner, newOwner_);
  }
}


interface IERC20 {
    event Transfer(address indexed from,  address indexed to,      uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply()                             external view returns (uint256);
    function balanceOf(address account)                external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(     address to,                uint256 amount)  external returns (bool);
    function approve(      address spender,           uint256 amount)  external returns (bool);
    function transferFrom( address from,  address to, uint256 amount ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name()     external view returns (string memory);
    function symbol()   external view returns (string memory);
    function decimals() external view returns (uint8);
}


contract CherryForest2 is Ownable {

  // ==== Events ====
  event Staked      (address indexed user, uint80 amount);
  event Withdrawn   (address indexed user, uint80 amount);
  event RewardPaid  (address indexed user, uint80 reward);
  event RewardAdded (address indexed user, uint80 reward);
  event ReserveAdded(address indexed user, uint80 amount);


  // ==== Structs ====

  // only 1 slot
  struct StakerSeat {
    uint32  lastSnapshotIndex;
    uint32  epochTimerStart;
    uint80  balance;  // max value: 1 208 925 tokens
                      // please don't stake more than 1 208 925 spLP tokens
                      // stake() will revert because of overflow if you do anyway
    uint112 rewardEarned;
  }

  // only 1 slot
  struct Snapshot {
      uint32  epoch;               // epoch of the snapshot
      uint112 rewardDistributed;   // amount distributed during that Epoch
      uint112 rewardPerLPtoken;    // accumulated reward per spLP up to that snapshot
  }


  // ==== Constants ====

  uint32 public constant PERIOD = 6 hours;
  uint32 public constant withdrawLockupEpochs = 6;  // 6 epochs before can withdraw
  uint32 public constant rewardLockupEpochs   = 3;  // 3 epochs before can claimReward

  address public constant pool = 0x4e904138B50f8a3Ad71B5303C02F53d0ad359D6C;
  address public constant tree = 0x8Dc673878d325C028D08d73C24cD59E15df62a4c;


  // ==== Storage ====
  // ---- 1 slot  ----
  uint32  public epoch;       // last update epoch
  uint112 public totalSupply; // total spLP staked
  uint80  public reserve;     // total CHRT left to distribute
                              // this is < this balance of tree because
                              // some stakers won't have withdrawn their rewards

  mapping(address => StakerSeat) public stakers;

  Snapshot[] public history;


  // ==== Constructor ====

//  constructor(address pool_, address tree_) {
  constructor() {
//    require(pool_ != address(0), "pool cannot be 0x00");

    // deploy checks to make sure I'm not an idiot

    // check pool symbol is spLP
    require(
      keccak256(abi.encodePacked(IERC20Metadata(pool).symbol())) == keccak256(abi.encodePacked('spLP')),
      "pool_ is not a SpookySwap liquidity pool"
    );

    // check tree symbol is CHRT
    require(
      keccak256(abi.encodePacked(IERC20Metadata(tree).symbol())) == keccak256(abi.encodePacked('CHRT')),
      "tree_ is not the Cherry Tree token contract"
    );

    // set immutables in constructor
    // pool       = pool_;
    // tree       = tree_;

    // create initial snapshop
    Snapshot memory initialSnapshot = Snapshot({
      epoch : uint32(getEpoch()),
      rewardDistributed : 0,
      rewardPerLPtoken  : 0
    });
    history.push(initialSnapshot);

    // set first epoch
    epoch = uint32(getEpoch());

    // Important: stake at least one spLP before first reward
    // or the application will not start
  }


  // ==== Pseudo - ERC20 ====

  function balanceOf(address account_) public view returns (uint256) {
    return stakers[account_].balance;
  }

  // Pseudo ERC20Metadata so people can watch their st-spLP-CHRY-FTM tokens in MetaMask
  // with balanceOf() the 4 following functions are the only implementation of the ERC20 token specification
  // they are just here so that users can easily view how many spLP tokens they have staked at the Forest easily
  // from their MetaMask wallet: they just need to add the Forest contract address as a token in MM
  // Other functions of the ERC20 standard are not implemented
  function symbol()   external pure returns (string memory) { return "stSpLP-T"; }
  function name()     external pure returns (string memory) { return "CHRT-FTM spLP staked at the Forest"; }
  function decimals() external pure returns (uint8)         { return 18; }

  // ==== Modifiers ====

  // ==== Governance ====
  // Less Governance == more Trust


  // ==== Views ====

  // Current epoch
  function getEpoch() public view returns (uint256) {
    return block.timestamp / PERIOD;
  }

  // === Read snapshots ===

  function getLatestSnapshotIndex() public view returns (uint256) {
    return history.length - 1;
  }

  function getLatestSnapshot() public view returns (Snapshot memory) {
    return history[history.length - 1];
  }

  function getLastSnapshotIndexOf(address staker_) public view returns (uint256) {
    return stakers[staker_].lastSnapshotIndex;
  }

  function getLastSnapshotOf(address staker_) public view returns (Snapshot memory) {
    return history[stakers[staker_].lastSnapshotIndex];
  }

  function canWithdraw(address staker_) external view returns (bool) {
    return stakers[staker_].epochTimerStart + withdrawLockupEpochs <= getEpoch();
  }

  function canClaimReward(address staker_) external view returns (bool) {
    return stakers[staker_].epochTimerStart + rewardLockupEpochs <= getEpoch();
  }

  function rewardPerLPtoken() public view returns (uint256) {
    return history[history.length - 1].rewardPerLPtoken;
  }

  function earned(address staker_) public view returns (uint256) {
    StakerSeat memory staker = stakers[staker_];

    uint256 latestRPT = history[history.length - 1].rewardPerLPtoken;
    uint256 storedRPT = history[staker.lastSnapshotIndex ].rewardPerLPtoken;

    return ( uint(staker.balance) * (latestRPT - storedRPT) / 1e18 ) + staker.rewardEarned;
  }


  // ==== Mutators ====

  function stake(uint256 amount_) public returns(bool) {
    uint newEpoch = getEpoch();

    // check Forest is not lagging in time
    if (newEpoch > epoch) {
      // Forest is lagging
      update();

      // After that, Forest will be updated for the whole epoch
    }

    StakerSeat memory staker = stakers[msg.sender];
    staker = _updateStaker(staker);

    IERC20(pool).transferFrom(msg.sender, address(this), amount_);
    totalSupply    += uint80(amount_);
    staker.balance += uint80(amount_);
    staker.epochTimerStart = uint32(newEpoch); // reset timer

    stakers[msg.sender] = staker; // only one swrite !!!!

    emit Staked(msg.sender, uint80(amount_));

    return true;
  }


  // withdraw automatically claims
  function withdraw(uint256 amount_) public returns(bool) {
    uint newEpoch = getEpoch();

    // check Forest is not lagging in time
    if (newEpoch > epoch) {
      update();
    }

    StakerSeat memory staker = stakers[msg.sender];
    staker = _updateStaker(staker);

    require(
      staker.epochTimerStart + withdrawLockupEpochs <= newEpoch,
      "Forest: you're still in withdraw lockup"
    );

    staker = _claim(staker, newEpoch);

    require(staker.balance >= amount_, "Forest: you asked for too much");

    totalSupply    -= uint80(amount_);  // swrite 5 000 gas
    require(totalSupply > 1e18, "Forest: at least one spLP must remain");
    staker.balance -= uint80(amount_);

    stakers[msg.sender] = staker; // only one swrite for staker

    IERC20(pool).transfer(msg.sender, amount_);

    emit Withdrawn(msg.sender, uint80(amount_));

    return true;
  }


  function exit() external {
    // withdraw automatically claims
    withdraw(balanceOf(msg.sender));
  }


  function claimReward() public returns(bool) {
    uint newEpoch = getEpoch();

    // check Forest is not lagging in time
    if (newEpoch > epoch) {
      update();
    }

    StakerSeat memory staker = stakers[msg.sender];
    staker = _updateStaker(staker);
    staker = _claim(staker, newEpoch);

    stakers[msg.sender] = staker; // only one swrite for staker

    return true;
  }

  // add reserve to be distributed
  // anyone can add reserve if they want to give CHRT
  // to spLP CHRY-FTM stakers
  function addReserve(uint amount_) public returns(bool) {

    IERC20(tree).transferFrom(msg.sender, address(this), amount_);
    reserve += uint80(amount_);

    emit ReserveAdded(msg.sender, uint80(amount_));

    return true;
  }


  /**
    * This can only run once an epoch.
    */
  function update() public returns (bool) {

    uint newEpoch = getEpoch();
    if (newEpoch <= epoch) {
      return false;
    }

    // below code will only run once per epoch

    epoch = uint32(newEpoch);

    // Forest is empty
    if (reserve < 1e18) {
      return false;
    }

    // no stake
    if (totalSupply < 1e18) {
      return false;
    }

    // compute reward
    uint reward = ((reserve / 1e21) + 1) * 1e18;

    // distribute reward
    // new snapshot is a copy of the previous one:
    Snapshot memory newSnapshot = getLatestSnapshot();

    newSnapshot.epoch              = uint32(newEpoch);
    newSnapshot.rewardDistributed  = uint112(reward);
    newSnapshot.rewardPerLPtoken  += uint112(reward * 1e18 / totalSupply);

    history.push(newSnapshot);

    reserve -= uint80(reward);

    emit RewardAdded(msg.sender, uint80(reward));

    return true;
  }


  // ==== Privates ====

  function _updateStaker(StakerSeat memory staker_) private view returns (StakerSeat memory) {
    uint latestSnapshotIdx = history.length - 1;
    // update staker if he lags
    if (staker_.lastSnapshotIndex < latestSnapshotIdx) {
      Snapshot memory latestSnapshot = history[latestSnapshotIdx];
      Snapshot memory stakerSnapshot = history[staker_.lastSnapshotIndex];

      unchecked {
        staker_.rewardEarned += uint112((uint(staker_.balance) * (latestSnapshot.rewardPerLPtoken - stakerSnapshot.rewardPerLPtoken)) / 1e18);
      }
      staker_.lastSnapshotIndex = uint32(latestSnapshotIdx);
    }
    return staker_;
  }

  function _claim(StakerSeat memory staker_, uint newEpoch_) private returns (StakerSeat memory) {
    if (staker_.rewardEarned > 0) {
      require(
        staker_.epochTimerStart + rewardLockupEpochs <=  newEpoch_,
        "Forest: you're still in reward lockup"
      );
      staker_.epochTimerStart = uint32(newEpoch_); // reset timer
      IERC20(tree).transfer(msg.sender, staker_.rewardEarned);  // we trust tree (no re-entrancy)
      emit RewardPaid(msg.sender, uint80(staker_.rewardEarned));
      staker_.rewardEarned = 0;
    }
    return staker_;
  }
}
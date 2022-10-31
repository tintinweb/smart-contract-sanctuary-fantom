/**
 *Submitted for verification at FtmScan.com on 2022-10-31
*/

// CherryOrchard.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**

Orchard:

Stake your tree tokens in Orchard.
When summertime sends newly minted fruit tokens, the Orchard
distributes them to stakers

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

interface ISummertime {
  function token() external view returns(address);
  function computeSeigniorage() external returns (bool);
}


contract Orchard is Ownable {

  // ==== Events ====
  event Staked      (address indexed user, uint112 amount);
  event Withdrawn   (address indexed user, uint112 amount);
  event RewardPaid  (address indexed user, uint112 reward);
  event RewardAdded (address indexed user, uint112 reward);


  // ==== Structs ====

  // only 1 slot
  struct StakerSeat {
    uint32  lastSnapshotIndex;
    uint32  epochTimerStart;
    uint80  balance;  // max value: 1 208 925 tokens which is fine
                      // because tree supply is 100 000 and fixed
    uint112 rewardEarned;
  }

  // only 1 slot
  struct OrchardSnapshot {
      uint32  epoch;            // epoch of the snapshot
      uint112 rewardReceived;   // amount received by the Orchard during that Epoch
      uint112 rewardPerTree;    // accumulated reward per tree up to that snapshot
  }


  // ==== Constants ====

  uint32 public constant PERIOD = 6 hours;
  uint32 public constant withdrawLockupEpochs = 6;  // 6 epochs before can withdraw
  uint32 public constant rewardLockupEpochs   = 3;  // 3 epochs before can claimReward

  address public immutable tree;
  address public immutable fruit;
  address public immutable summertime;


  // ==== Storage ====
  // ---- 1 slot  ----
  uint32 public epoch;
  uint80 public totalSupply;

  mapping(address => StakerSeat) public stakers;

  OrchardSnapshot[] public orchardHistory;


  // ==== Constructor ====

  constructor(address summertime_, address tree_) {
    require(summertime_ != address(0), "summertime cannot be 0x00");
    require(tree_       != address(0), "Tree cannot be 0x00");

    // TODO: check tree_ is CHRT token

    // set immutables in constructor
    tree       = tree_;
    summertime = summertime_;
    // get fruit token address from summertime
    fruit      = ISummertime(summertime_).token();

    // create initial snapshop
    OrchardSnapshot memory initialSnapshot = OrchardSnapshot({
      epoch : uint32(getEpoch()),
      rewardReceived : 0,
      rewardPerTree  : 0
    });
    orchardHistory.push(initialSnapshot);

    // set first epoch
    epoch = uint32(getEpoch());

    // Important: stake at least one tree before first reward
    // or the application will not start
  }


  // ==== Pseudo - ERC20 ====

  function balanceOf(address account_) public view returns (uint256) {
    return stakers[account_].balance;
  }

  // Pseudo ERC20Metadata so people can watch their stCHRT in MetaMask
  // with balanceOf() the 4 following functions are the only implementation of the ERC20 token specification
  // they are just here so that users can easily view how many trees they have staked at the Orchard easily
  // from their MetaMask wallet: they just need to add the Orchard contract address as a token in MM
  // Other functions of the ERC20 standard are not implemented
  function symbol()   external pure returns (string memory) { return "stCHRT"; }
  function name()     external pure returns (string memory) { return "Cherry Trees staked at the Orchard"; }
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
    return orchardHistory.length - 1;
  }

  function getLatestSnapshot() public view returns (OrchardSnapshot memory) {
    return orchardHistory[orchardHistory.length - 1];
  }

  function getLastSnapshotIndexOf(address staker_) public view returns (uint256) {
    return stakers[staker_].lastSnapshotIndex;
  }

  function getLastSnapshotOf(address staker_) public view returns (OrchardSnapshot memory) {
    return orchardHistory[stakers[staker_].lastSnapshotIndex];
  }

  function canWithdraw(address staker_) external view returns (bool) {
    return stakers[staker_].epochTimerStart + withdrawLockupEpochs <= getEpoch();
  }

  function canClaimReward(address staker_) external view returns (bool) {
    return stakers[staker_].epochTimerStart + rewardLockupEpochs <= getEpoch();
  }

  function rewardPerTree() public view returns (uint256) {
    return orchardHistory[orchardHistory.length - 1].rewardPerTree;
  }

  function earned(address staker_) public view returns (uint256) {
    StakerSeat memory staker = stakers[staker_];

    uint256 latestRPT = orchardHistory[orchardHistory.length - 1].rewardPerTree;
    uint256 storedRPT = orchardHistory[staker.lastSnapshotIndex ].rewardPerTree;

    return ( uint(staker.balance) * (latestRPT - storedRPT) / 1e18 ) + staker.rewardEarned;
  }


  // ==== Mutators ====

  function stake(uint256 amount_) public returns(bool) {
    uint newEpoch = getEpoch();

    // check Orchard is not lagging in time
    if (newEpoch > epoch) {
      // orchard is lagging
      ISummertime(summertime).computeSeigniorage();
      // will:
      //  1.  call Summertime
      //  1.1   that will call Oracle
      //  1.1.1   that will call liquidity pool
      //  1.2   that will call back Orchard
      // Ouch gas !!!!
      // After that, Orchard will be updated for the whole epoch
    }

    StakerSeat memory staker = stakers[msg.sender];
    staker = _updateStaker(staker);

    IERC20(tree).transferFrom(msg.sender, address(this), amount_);
    totalSupply    += uint80(amount_);
    staker.balance += uint80(amount_);
    staker.epochTimerStart = uint32(newEpoch); // reset timer

    stakers[msg.sender] = staker; // only one swrite !!!!

    emit Staked(msg.sender, uint112(amount_));

    return true;
  }


  // withdraw automatically claims
  function withdraw(uint256 amount_) public returns(bool) {
    uint newEpoch = getEpoch();

    // check Orchard is not lagging in time
    if (newEpoch > epoch) {
      ISummertime(summertime).computeSeigniorage();
    }

    StakerSeat memory staker = stakers[msg.sender];
    staker = _updateStaker(staker);

    require(
      staker.epochTimerStart + withdrawLockupEpochs <= newEpoch,
      "Orchard: you're still in withdraw lockup"
    );

    staker = _claim(staker, newEpoch);

    require(staker.balance >= amount_, "Orchard: you asked for too much");

    totalSupply    -= uint80(amount_);  // swrite 5 000 gas
    require(totalSupply > 1e18, "Orchard: at least one tree must remain");
    staker.balance -= uint80(amount_);

    IERC20(tree).transfer(msg.sender, amount_);

    stakers[msg.sender] = staker; // only one swrite for staker

    emit Withdrawn(msg.sender, uint112(amount_));

    return true;
  }


  function exit() external {
    // withdraw automatically claims
    withdraw(balanceOf(msg.sender));
  }


  function claimReward() public returns(bool) {
    uint newEpoch = getEpoch();

    // check Orchard is not lagging in time
    if (newEpoch > epoch) {
      ISummertime(summertime).computeSeigniorage();
    }

    StakerSeat memory staker = stakers[msg.sender];
    staker = _updateStaker(staker);
    staker = _claim(staker, newEpoch);

    stakers[msg.sender] = staker; // only one swrite for staker

    return true;
  }


  /**
    * This can only run once an epoch.
    *
    * @param amount_ quantity of newly minted token from summertime
    */
  function distributeSeigniorage(uint256 amount_) external returns (bool) {
    require(msg.sender == summertime, "Orchard: 403 only Summertime can call this");

    uint newEpoch = getEpoch();
    require(newEpoch > epoch, "Orchard: already run that epoch");

    // below code will only run once per epoch

    epoch = uint32(newEpoch);

    if (amount_ > 0) {
      // we create a new snapshot only if we have reward to distribute

      // if less than 1 tree staked, we give reward to owner
      // or the contract will be deadlocked at start
      // in case we start the contract when overpeg
      if (totalSupply < 1e18) {
        IERC20(fruit).transfer(owner(), amount_);  // we trust fruit (no re-entrancy)
        return true;
      }

      // new snapshot is a copy of the previous one:
      OrchardSnapshot memory newSnapshot = getLatestSnapshot();

      newSnapshot.epoch           = uint32(newEpoch);
      newSnapshot.rewardReceived  = uint112(amount_);
      newSnapshot.rewardPerTree  += uint112( amount_ * 1e18 / totalSupply );

      orchardHistory.push(newSnapshot);

      emit RewardAdded(msg.sender, uint112(amount_));
    }

    return true;
  }


  // ==== Privates ====

  function _updateStaker(StakerSeat memory staker_) private view returns (StakerSeat memory) {
    uint latestSnapshotIdx = orchardHistory.length - 1;
    // update staker if he lags
    if (staker_.lastSnapshotIndex < latestSnapshotIdx) {
      OrchardSnapshot memory latestSnapshot = orchardHistory[latestSnapshotIdx];
      OrchardSnapshot memory stakerSnapshot = orchardHistory[staker_.lastSnapshotIndex];

      unchecked {
        staker_.rewardEarned += uint112((uint(staker_.balance) * (latestSnapshot.rewardPerTree - stakerSnapshot.rewardPerTree)) / 1e18);
      }
      staker_.lastSnapshotIndex = uint32(latestSnapshotIdx);
    }
    return staker_;
  }

  function _claim(StakerSeat memory staker_, uint newEpoch_) private returns (StakerSeat memory) {
    if (staker_.rewardEarned > 0) {
      require(
        staker_.epochTimerStart + rewardLockupEpochs <=  newEpoch_,
        "Orchard: you're still in reward lockup"
      );
      staker_.epochTimerStart = uint32(newEpoch_); // reset timer
      IERC20(fruit).transfer(msg.sender, staker_.rewardEarned);  // we trust fruit (no re-entrancy)
      emit RewardPaid(msg.sender, staker_.rewardEarned);
      staker_.rewardEarned = 0;
    }
    return staker_;
  }
}
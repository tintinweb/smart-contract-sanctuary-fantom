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
pragma solidity 0.8.13;

interface IBribe {
    function addReward(address rewardToken) external;
    function balanceOf(address account) external view returns (uint256);
    function _deposit(uint amount, address account) external;
    function _withdraw(uint amount, address account) external;
    function getRewardForOwner(address account) external;
    function notifyRewardAmount(address token, uint amount) external;
    function left(address token) external view returns (uint);
    function getRewardTokens() external view returns (address[] memory);
    function rewardPerToken(address reward) external view returns (uint);
    function earned(address account, address _rewardsToken) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IBribeFactory {
    function createBribe(address _voter) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGauge {
    function addReward(address rewardToken) external;
    function notifyRewardAmount(address token, uint amount) external;
    function getReward(address account) external;
    function claimVotingFees() external returns (uint claimed0, uint claimed1);
    function left(address token) external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function rewardPerToken(address reward) external view returns (uint);
    function earned(address account, address reward) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGaugeFactory {
    function createGauge(address _voter, address _token) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IMinter {
    function update_period() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IPlugin {
    function getUnderlyingTokenName() external view returns (string memory);
    function getUnderlyingTokenSymbol() external view returns (string memory);
    function getUnderlyingTokenAddress() external view returns (address);
    function getProtocol() external view returns (string memory);
    function getBribe() external view returns (address);
    function getTokensInUnderlying() external view returns (address[] memory);
    function getBribeTokens() external view returns (address[] memory);
    function getVoter() external view returns (address);
    function price() external view returns (uint);
    function claimAndDistribute() external;
    function setGauge(address _gauge) external;
    function setBribe(address _bribe) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IVoter {
    function VTOKEN() external view returns (address);
    function usedWeights(address account) external view returns (uint256);
    function pools(uint256 index) external view returns (address);
    function getPools() external view returns (address[] memory);
    function gauges(address pool) external view returns (address);
    function bribes(address pool) external view returns (address);
    function weights(address pool) external view returns (uint256);
    function totalWeight() external view returns (uint256);
    function emitDeposit(address account, uint amount) external;
    function emitWithdraw(address account, uint amount) external;
    function notifyRewardAmount(uint amount) external;
    function distribute(address _gauge) external;
    function treasury() external view returns (address);
    function votes(address account, address pool) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IVTOKEN {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalSupplyTOKEN() external view returns (uint256);
    function notifyRewardAmount(address reward, uint256 amount) external;
    function balanceOfTOKEN(address account) external view returns (uint256);
    function rewardPerToken(address reward) external view returns (uint);
    function earned(address account, address _rewardsToken) external view returns (uint256);
    function rewarder() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    function cbrt(uint256 n) internal pure returns (uint256) { unchecked {
        uint256 x = 0;
        for (uint256 y = 1 << 255; y > 0; y >>= 3) {
            x <<= 1;
            uint256 z = 3 * x * (x + 1) + 1;
            if (n / y >= z) {
                n -= y * z;
                x += 1;
            }
        }
        return x;
    }}
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import 'contracts/libraries/Math.sol';
import 'contracts/interfaces/IBribe.sol';
import 'contracts/interfaces/IBribeFactory.sol';
import 'contracts/interfaces/IGauge.sol';
import 'contracts/interfaces/IGaugeFactory.sol';
import 'contracts/interfaces/IERC20.sol';
import 'contracts/interfaces/IMinter.sol';
import 'contracts/interfaces/IVoter.sol';
import 'contracts/interfaces/IVTOKEN.sol';
import 'contracts/interfaces/IPlugin.sol';

contract Voter is IVoter, Ownable {

    address public immutable VTOKEN; // the voting token that governs these contracts
    address internal immutable base;
    address public immutable gaugefactory;
    address public immutable bribefactory;
    uint internal constant DURATION = 7 days; // rewards are released over 7 days
    address public minter;
    uint public totalWeight; // total voting weight
    address public treasury;
    address public team;

    address[] public pools; // all pools viable for incentives
    mapping(address => address) public gauges; // pool => gauge
    mapping(address => address) public poolForGauge; // gauge => pool
    mapping(address => address) public bribes; // pool => bribe
    mapping(address => uint256) public weights; // pool => weight
    mapping(address => mapping(address => uint256)) public votes; // account => pool => votes
    mapping(address => address[]) public poolVote; // account => pools
    mapping(address => uint) public usedWeights;  // account => total voting weight of user
    mapping(address => uint) public lastVoted; // account => timestamp of last vote, to ensure one vote per epoch
    mapping(address => bool) public isGauge;
    mapping(address => bool) public isAlive;

    event GaugeCreated(address creator, address indexed pool, address indexed gauge,  address bribe);
    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);
    event Voted(address indexed voter, uint256 weight);
    event Abstained(address account, uint256 weight);
    event Deposit(address indexed lp, address indexed gauge, address account, uint amount);
    event Withdraw(address indexed lp, address indexed gauge, address account, uint amount);
    event NotifyReward(address indexed sender, address indexed reward, uint amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint amount);
    event BribeRewardAdded(address indexed bribe, address indexed reward);
    event TreasurySet(address indexed account);
    event TeamSet(address indexed account);

    constructor(address _VTOKEN, address _base, address  _gauges, address _bribes) {
        VTOKEN = _VTOKEN;
        base = _base;
        gaugefactory = _gauges;
        bribefactory = _bribes;
        minter = msg.sender;
        treasury = msg.sender;
        team = msg.sender;
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    modifier onlyNewEpoch(address account) {
        // ensure new epoch since last vote 
        require((block.timestamp / DURATION) * DURATION > lastVoted[account], "ACCOUNT_ALREADY_VOTED_THIS_EPOCH");
        _;
    }

    function initialize(address _minter) external {
        require(msg.sender == minter, "!Minter");
        minter = _minter;
    }

    function reset() external onlyNewEpoch(msg.sender) {
        address account = msg.sender;
        lastVoted[account] = block.timestamp;
        _reset(account);
    }

    function _reset(address account) internal {
        address[] storage _poolVote = poolVote[account];
        uint _poolVoteCnt = _poolVote.length;
        uint256 _totalWeight = 0;

        for (uint i = 0; i < _poolVoteCnt; i ++) {
            address _pool = _poolVote[i];
            uint256 _votes = votes[account][_pool];

            if (_votes > 0) {
                _updateFor(gauges[_pool]);
                weights[_pool] -= _votes;
                votes[account][_pool] -= _votes;
                IBribe(bribes[_pool])._withdraw(IBribe(bribes[_pool]).balanceOf(account), account);
                _totalWeight += _votes;
                emit Abstained(account, _votes);
            }
        }
        totalWeight -= uint256(_totalWeight);
        usedWeights[account] = 0;
        delete poolVote[account];
    }

    function _vote(address account, address[] memory _poolVote, uint256[] memory _weights) internal {
        _reset(account);
        uint _poolCnt = _poolVote.length;
        uint256 _weight = IVTOKEN(VTOKEN).balanceOf(account);
        uint256 _totalVoteWeight = 0;
        uint256 _totalWeight = 0;
        uint256 _usedWeight = 0;

        for (uint i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];
            address _gauge = gauges[_pool];
            if (isGauge[_gauge] && isAlive[_gauge]) { 
                _totalVoteWeight += _weights[i];
            }
        }

        for (uint i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];
            address _gauge = gauges[_pool];

            if (isGauge[_gauge] && isAlive[_gauge]) { 
                uint256 _poolWeight = _weights[i] * _weight / _totalVoteWeight;
                require(votes[account][_pool] == 0);
                require(_poolWeight != 0);
                _updateFor(_gauge);

                poolVote[account].push(_pool);

                weights[_pool] += _poolWeight;
                votes[account][_pool] += _poolWeight;
                IBribe(bribes[_pool])._deposit(uint256(_poolWeight), account); 
                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                emit Voted(account, _poolWeight);
            }
        }

        totalWeight += uint256(_totalWeight);
        usedWeights[account] = uint256(_usedWeight);
    }

    function vote(address[] calldata _poolVote, uint256[] calldata _weights) external onlyNewEpoch(msg.sender) {
        require(_poolVote.length == _weights.length);
        lastVoted[msg.sender] = block.timestamp;
        _vote(msg.sender, _poolVote, _weights);
    }

    function createGauge(address _asset) external onlyGov returns (address) {

        require(gauges[_asset] == address(0x0), "exists");

        address _gauge = IGaugeFactory(gaugefactory).createGauge(address(this), _asset);
        IGauge(_gauge).addReward(base);
        IPlugin(_asset).setGauge(_gauge);
        IERC20(base).approve(_gauge, type(uint).max);

        address _bribe = IBribeFactory(bribefactory).createBribe(address(this));
        address[] memory _bribeTokens = IPlugin(_asset).getBribeTokens();
        for (uint256 i = 0; i < _bribeTokens.length; i++) {
            IBribe(_bribe).addReward(_bribeTokens[i]);
        }
        IPlugin(_asset).setBribe(_bribe);

        gauges[_asset] = _gauge;
        bribes[_asset] = _bribe;
        poolForGauge[_gauge] = _asset;
        isGauge[_gauge] = true;
        isAlive[_gauge] = true;
        _updateFor(_gauge);
        pools.push(_asset);
        emit GaugeCreated(msg.sender, _asset, _gauge, _bribe); 
        return _gauge;
    }

    function killGauge(address _gauge) external onlyGov {
        require(isAlive[_gauge], "gauge already dead");
        isAlive[_gauge] = false;
        claimable[_gauge] = 0;
        emit GaugeKilled(_gauge);
    }

    function reviveGauge(address _gauge) external onlyGov {
        require(!isAlive[_gauge], "gauge already alive");
        isAlive[_gauge] = true;
        emit GaugeRevived(_gauge);
    }

    function emitDeposit(address account, uint amount) external {
        require(isGauge[msg.sender]);
        require(isAlive[msg.sender]);
        emit Deposit(poolForGauge[msg.sender], msg.sender, account, amount);
    }

    function emitWithdraw(address account, uint amount) external {
        require(isGauge[msg.sender]);
        emit Withdraw(poolForGauge[msg.sender], msg.sender, account, amount);
    }

    function getPools() external view returns (address[] memory) {
        return pools;
    }

    function length() external view returns (uint) {
        return pools.length;
    }

    uint internal index;
    mapping(address => uint) internal supplyIndex;
    mapping(address => uint) public claimable;

    function notifyRewardAmount(uint amount) external {
        _safeTransferFrom(base, msg.sender, address(this), amount); // transfer the distro in
        uint256 _ratio = amount * 1e18 / totalWeight; // 1e18 adjustment is removed during claim
        if (_ratio > 0) {
            index += _ratio;
        }
        emit NotifyReward(msg.sender, base, amount);
    }

    function updateFor(address[] memory _gauges) external {
        for (uint i = 0; i < _gauges.length; i++) {
            _updateFor(_gauges[i]);
        }
    }

    function updateForRange(uint start, uint end) public {
        for (uint i = start; i < end; i++) {
            _updateFor(gauges[pools[i]]);
        }
    }

    function updateAll() external {
        updateForRange(0, pools.length);
    }

    function updateGauge(address _gauge) external {
        _updateFor(_gauge);
    }

    function _updateFor(address _gauge) internal {
        address _pool = poolForGauge[_gauge];
        uint256 _supplied = weights[_pool];
        if (_supplied > 0) {
            uint _supplyIndex = supplyIndex[_gauge];
            uint _index = index; // get global index0 for accumulated distro
            supplyIndex[_gauge] = _index; // update _gauge current position to global position
            uint _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (_delta > 0) {
                uint _share = uint(_supplied) * _delta / 1e18; // add accrued difference for each supplied token
                if (isAlive[_gauge]) {
                    claimable[_gauge] += _share;
                }
            }
        } else {
            supplyIndex[_gauge] = index; // new users are set to the default global state
        }
    }

    function claimRewards(address[] memory _gauges) external {
        for (uint i = 0; i < _gauges.length; i++) {
            IGauge(_gauges[i]).getReward(msg.sender);
        }
    }

    function claimBribes(address[] memory _bribes) external {
        for (uint i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getRewardForOwner(msg.sender);
        }
    }

    function distributeToBribes(address[] memory _pools) external {
        for (uint i = 0; i < _pools.length; i++) {
            IPlugin(_pools[i]).claimAndDistribute();
        }
    }

    function distribute(address _gauge) public lock {
        IMinter(minter).update_period();
        _updateFor(_gauge); // should set claimable to 0 if killed
        uint _claimable = claimable[_gauge];
        if (_claimable > IGauge(_gauge).left(base) && _claimable / DURATION > 0) {
            claimable[_gauge] = 0;
            IGauge(_gauge).notifyRewardAmount(base, _claimable);
            emit DistributeReward(msg.sender, _gauge, _claimable);
        }
    }

    function distro() external {
        distribute(0, pools.length);
    }

    function distribute(uint start, uint finish) public {
        for (uint x = start; x < finish; x++) {
            distribute(gauges[pools[x]]);
        }
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "!Valid");
        treasury = _treasury;
        emit TreasurySet(_treasury);
    }

    function setTeam(address _team) external onlyOwner {
        require(_team != address(0), "!Valid");
        team = _team;
        emit TeamSet(_team);
    }

    function addBribeReward(address _bribe, address _rewardToken) external onlyGov {
        require(_rewardToken != address(0), "!Valid");
        IBribe(_bribe).addReward(_rewardToken);
        emit BribeRewardAdded(_bribe, _rewardToken);
    }

    modifier onlyGov {
        require(msg.sender == owner() || msg.sender == team, "Only the contract owner may perform this action");
        _;
    }
}
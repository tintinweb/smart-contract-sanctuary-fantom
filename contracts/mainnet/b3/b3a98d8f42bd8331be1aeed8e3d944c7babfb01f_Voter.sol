/**
 *v2.0.1
 *0xbfbDE540AB95CD60C6a7A087ba48C68A57cf77c8
 *Submitted for verification at FtmScan.com on 2023-05-17
*/

/**
 *v2.0.0
 *0x14a0b746803ec563be405942259969f9af985c20
 *Submitted for verification at FtmScan.com on 2023-03-21
*/

/**
 *v1.5.1
 *0xEdFA7461bA8Eb8164E5625D75EE8Ea9839772F64
 *Submitted for verification at FtmScan.com on 2023-03-18
*/
/**
 *v1.5.0
 *0x626ecdd835B508f1d9D156015490B6CcBC9E3e90
 *Submitted for verification at FtmScan.com on 2023-03-17
*/
/**
 *v1.4.4
 *0xC45f2AFEb6E34488cf8987F0458Ab3f93C8D49BF
 *Submitted for verification at FtmScan.com on 2023-03-09
*/
/**
 *v1.4.3
 *0xDFf9bA0A6361EF588398aE5631B0055169e2F072
 *Submitted for verification at FtmScan.com on 2023-03-09
*/
/**
 *v1.4.2
 *0xB99c82191Ee5Dc240bd2a77827413574075ed2F6
 *Submitted for verification at FtmScan.com on 2023-03-06
*/
/**
 *v1.4.1
 *0xFE363d3DE8a0beA47cC7d7f5c096D3852AdbC396
 *Submitted for verification at FtmScan.com on 2023-02-22
*/
/**
 *v1.3.10
 *0x2f2c3a2ee4f63640a044e8a7fd01102c7aaf5186
 *Submitted for verification at FtmScan.com on 2023-02-12
*/
/**
 *v1.3.9
 *0x81377455214496CA22d9658eFAEFddd83775Aac3
 *Submitted for verification at FtmScan.com on 2023-02-11
*/
/**
 *v1.3.7
 *0x0A6e8D4d8685F80374FD88f08AbbCA5F5DdE9D4F
 *Submitted for verification at FtmScan.com on 2023-01-29
*/
/**
 *v1.3.5
 *0xb333bb146b29d6caa078905f551679137aabd0c5
 *Submitted for verification at FtmScan.com on 2023-01-18
*/
/**
 *v1.3.1
 *0x225d1e237b8089734fb15C1C206BbB98415d4B46
 *Submitted for verification at FtmScan.com on 2023-01-03
*/
/**
 *v1.3.0
 *0x95797abf5988479138c783dbcc97db869b373bdb
 *Submitted for verification at FtmScan.com on 2022-12-26
*/
/**
 *v1.2.0
 *0x6bF6A6185afE3cc88707b0b6474F6AFceE59EFED
 *Submitted for verification at FtmScan.com on 2022-11-28
*/
/**v1.1.0
 *0xB171D9126d01E6DDb76Df8dd30e3A0C712f2cF5c
 *Submitted for verification at FtmScan.com on 2022-11-09
*/



/**
 *  EQUALIZER EXCHANGE
 *  The New Liquidity Hub of Fantom chain!
 *  https://equalizer.exchange  (Dapp)
 *  https://discord.gg/MaMhbgHMby   (Community)
 *
 *
 *
 *  Version: 1.5.0
 *
 *  Version: 1.5.0
 *  - Only `base` as initial `allowedRewards[]`
 *  - Introduce concept of Gaugable
 *  - Introduce concept of protocolFeesTaker
 *
 *  Version: 1.4.4
 *  - createGaugeMulti
 *  - LFG!
 *
 *
 *  Contributors:
 *   -   Andre Cronje, Solidly.Exchange
 *   -   Velodrome.finance Team
 *   -   @smartcoding51
 *   -   543#3017 (Sam), ftm.guru & Equalizer.exchange
 *
 *
 *	SPDX-License-Identifier: UNLICENSED
*/



// File: contracts/interfaces/IVotingEscrow.sol


pragma solidity 0.8.9;

interface IVotingEscrow {

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    function token() external view returns (address);
    function team() external returns (address);
    function epoch() external view returns (uint);
    function point_history(uint loc) external view returns (Point memory);
    function user_point_history(uint tokenId, uint loc) external view returns (Point memory);
    function user_point_epoch(uint tokenId) external view returns (uint);

    function ownerOf(uint) external view returns (address);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function transferFrom(address, address, uint) external;

    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;

    function checkpoint() external;
    function deposit_for(uint tokenId, uint value) external;
    function create_lock_for(uint, uint, address) external returns (uint);

    function balanceOfNFT(uint) external view returns (uint);
    function totalSupply() external view returns (uint);
}

// File: contracts/interfaces/IPairFactory.sol


pragma solidity 0.8.9;

interface IPairFactory {
    function isPaused() external view returns (bool);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function getFee(bool _stable) external view returns(uint256);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function getInitializable() external view returns (address, address, bool);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
}

// File: contracts/interfaces/IPair.sol


pragma solidity 0.8.9;

interface IPair {
    function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
    function claimFees() external returns (uint, uint);
    function tokens() external returns (address, address);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);
    function getAmountOut(uint, address) external view returns (uint);
    function stable() external view returns (bool s);
}

// File: contracts/interfaces/IMinter.sol


pragma solidity 0.8.9;

interface IMinter {
    function update_period() external returns (uint);
}

// File: contracts/interfaces/IERC20.sol


pragma solidity 0.8.9;

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

// File: contracts/interfaces/IGaugeFactory.sol


pragma solidity 0.8.9;

interface IGaugeFactory {
    function createGauge(address _p, address _b, address _v, bool _n, address[] memory _r) external returns (address);
}

// File: contracts/interfaces/IGauge.sol


pragma solidity 0.8.9;

interface IGauge {
    function notifyRewardAmount(address token, uint amount) external;
    function getReward(address account, address[] memory tokens) external;
    function claimFees() external returns (uint claimed0, uint claimed1);
    function left(address token) external view returns (uint);
    function isForPair() external view returns (bool);
    function setBribe(address _newbribe) external;
}

// File: contracts/interfaces/IBribeFactory.sol


pragma solidity 0.8.9;

interface IBribeFactory {
    function createBribe(address[] memory) external returns (address);
}

// File: contracts/interfaces/IBribe.sol


pragma solidity 0.8.9;

interface IBribe {
    function _deposit(uint amount, uint tokenId, address _vtr, address _onr) external;
    function _withdraw(uint amount, uint tokenId, address _vtr, address _onr) external;
    function getRewardForOwner(uint tokenId, address[] memory tokens) external;
    function notifyRewardAmount(address token, uint amount) external;
    function left(address token) external view returns (uint);
}

// File: contracts/libraries/Math.sol


pragma solidity 0.8.9;

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
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// File: contracts/Voter.sol


pragma solidity 0.8.9;












contract Voter is Initializable {
    /// @dev rewards are released over 7 days
    uint public constant DURATION = 7 days;
    /// @dev the ve token that governs these contracts
    address public _ve;
    address public factory; // the PairFactory
    address public base;
    address public gaugefactory;
    address public bribefactory;
    address public minter;

    address public ms; // team-governor-council-treasury multi-sig
    address public governor; // should be set to an IGovernor
    /// @dev credibly neutral party similar to Curve's Emergency DAO
    address public emergencyCouncil;

    address public protocolFeesTaker;
    uint public protocolFeesPerMillion;

    uint public totalWeight; // total voting weight

    address[] public pools; // all pools viable for incentives
    mapping(address => address) public gauges; // pool => gauge
    mapping(address => address) public poolForGauge; // gauge => pool
    mapping(address => address) public bribes; // gauge => unified bribes
    mapping(address => uint256) public weights; // pool => weight
    mapping(uint => mapping(address => uint256)) public votes; // nft => pool => votes
    mapping(uint => address[]) public poolVote; // nft => pools
    mapping(uint => uint) public usedWeights;  // nft => total voting weight of user
    mapping(uint => uint) public lastVoted; // nft => timestamp of last vote, to ensure one vote per epoch
    mapping(address => bool) public isGauge;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isAlive; // killed implies no emission allocation

    bool internal _locked;	/// @dev simple re-entrancy check
    uint public index;

    mapping(address => uint) public supplyIndex;
    mapping(address => uint) public claimable;

    mapping(address => bool) public unvotable; // disable voting for certain pools
    mapping(address => bool) public gaugable; // enable creation for pools with one of these constituents
    bool public pokable; // toggle poking

    mapping(address => bool) public pausedGauges;



	/********************************************************************************************/
	/*****************************************NON-STORAGE****************************************/
	/********************************************************************************************/
	/// NON-STORAGE: Events
    event GaugeAndBribeCreated(address indexed pool, address gauge, address bribe, address indexed creator, address[] gaugeRewards, address[] allowedRewards);
    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);
    event Voted(address indexed pooladdr, address voter, address indexed tokenOwner, uint indexed tokenId, uint256 weight, uint256 ts);
    event Abstained(uint indexed tokenId, uint256 weight);
    event Deposit(address indexed lp, address indexed gauge, uint indexed tokenId, uint amount);
    event Withdraw(address indexed lp, address indexed gauge, uint indexed tokenId, uint amount);
    event NotifyReward(address indexed sender, address indexed reward, uint amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint amount);
    event Attach(address indexed owner, address indexed gauge, uint indexed tokenId);
    event Detach(address indexed owner, address indexed gauge, uint indexed tokenId);
    event Whitelisted(address indexed whitelister, address indexed token, bool indexed status);

	/// NON-STORAGE: Modifiers
    modifier lock() {
        require(!_locked, "No re-entrancy");
        _locked = true;
        _;
        _locked = false;
    }

	/// NON-STORAGE: Functions
    function initialize(
        address __ve,
        address _factory,
        address _gauges,
        address _bribes
    ) public initializer {
        _ve = __ve;
        factory = _factory;
        base = IVotingEscrow(__ve).token();
        gaugefactory = _gauges;
        bribefactory = _bribes;
        minter = msg.sender;
        governor = msg.sender;
        emergencyCouncil = msg.sender;
        protocolFeesTaker = msg.sender;
        ms = msg.sender;
    }

    modifier onlyNewEpoch(uint _tokenId) {
        // ensure new epoch since last vote
        require((block.timestamp / DURATION) * DURATION > lastVoted[_tokenId], "TOKEN_ALREADY_VOTED_THIS_EPOCH");
        _;
    }

    function initialSetup(address[] memory _tokens, address _minter) external {
        require(msg.sender == minter, "Not minter!");
        for (uint i = 0; i < _tokens.length; i++) {
            _whitelist(_tokens[i]);
        }
        minter = _minter;
    }

    function setGovernor(address _governor) public {
        require(msg.sender == governor, "Not governor!");
        governor = _governor;
    }

    function setEmergencyCouncil(address _council) public {
        require(msg.sender == emergencyCouncil, "Not emergency council!");
        emergencyCouncil = _council;
    }

    function setProtocolFeesTaker(address _pft) public {
        require(msg.sender == governor, "Not Protocol Fees Taker!");
        protocolFeesTaker = _pft;
    }

    function setProtocolFeesPerMillion(uint _pf) public {
        require(msg.sender == governor, "Not governor!");
        protocolFeesPerMillion = _pf;
    }

    function reset(uint _tokenId) external onlyNewEpoch(_tokenId) {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId), "Neither approved nor owner");
        lastVoted[_tokenId] = block.timestamp;
        _reset(_tokenId);
        IVotingEscrow(_ve).abstain(_tokenId);
    }

    function resetOverride(uint[] memory _ids) external {
    	for(uint i=0;i<_ids.length;i++) {
    		resetOverride(_ids[i]);
    	}
    }

    function resetOverride(uint _tokenId) public {
        require(msg.sender == governor, "Not governor");
        _reset(_tokenId);
        IVotingEscrow(_ve).abstain(_tokenId);
    }

    function _reset(uint _tokenId) internal {
        address[] storage _poolVote = poolVote[_tokenId];
        uint _poolVoteCnt = _poolVote.length;
        uint256 _totalWeight = 0;
        address _tokenOwner = IVotingEscrow(_ve).ownerOf(_tokenId);

        for (uint i = 0; i < _poolVoteCnt; i ++) {
            address _pool = _poolVote[i];
            uint256 _votes = votes[_tokenId][_pool];

            if (_votes != 0) {
                _updateFor(gauges[_pool]);
                weights[_pool] -= _votes;
                votes[_tokenId][_pool] -= _votes;
                if (_votes > 0) {
                    IBribe(bribes[gauges[_pool]])._withdraw(uint256(_votes), _tokenId, msg.sender, _tokenOwner);
                    _totalWeight += _votes;
                } else {
                    _totalWeight -= _votes;
                }
                emit Abstained(_tokenId, _votes);
            }
        }
        totalWeight -= uint256(_totalWeight);
        usedWeights[_tokenId] = 0;
        delete poolVote[_tokenId];
    }

    function poke(uint _tokenId) external {
        /// Poke function was depreciated in v1.3.0 due to security reasons.
        /// Its still callable for backwards compatibility, but does nothing.
        /// Usage allowed by ms (Official Equălizer Team Multi-Sig) or Public when pokable.
        if(pokable || msg.sender == ms) {
            address[] memory _poolVote = poolVote[_tokenId];
            uint _poolCnt = _poolVote.length;
            uint256[] memory _weights = new uint256[](_poolCnt);

            for (uint i = 0; i < _poolCnt; i ++) {
                _weights[i] = votes[_tokenId][_poolVote[i]];
            }

            _vote(_tokenId, _poolVote, _weights);
        }
        /// else return;
    }

    function _vote(uint _tokenId, address[] memory _poolVote, uint256[] memory _weights) internal {
    	///v1.3.1 Emergency Upgrade
    	///Prevent voting for specific "unvotable" pools
    	for(uint lol=0;lol<_poolVote.length;lol++) {
    		require(
    			! unvotable[ _poolVote[lol] ],
    			"This pool is unvotable!"
    		);
    		require(
    		    isAlive[ gauges[_poolVote[lol] ] ] ,
    		    "Cant vote for Killed Gauges!"
    		);
    	}
        _reset(_tokenId);
        uint _poolCnt = _poolVote.length;
        uint256 _weight = IVotingEscrow(_ve).balanceOfNFT(_tokenId);
        uint256 _totalVoteWeight = 0;
        uint256 _totalWeight = 0;
        uint256 _usedWeight = 0;
        address _tokenOwner = IVotingEscrow(_ve).ownerOf(_tokenId);

        for (uint i = 0; i < _poolCnt; i++) {
            _totalVoteWeight += _weights[i];
        }

        for (uint i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];
            address _gauge = gauges[_pool];

            if (isGauge[_gauge]) {
                uint256 _poolWeight = _weights[i] * _weight / _totalVoteWeight;
                require(votes[_tokenId][_pool] == 0);
                require(_poolWeight != 0);
                _updateFor(_gauge);

                poolVote[_tokenId].push(_pool);

                weights[_pool] += _poolWeight;
                votes[_tokenId][_pool] += _poolWeight;
                IBribe(bribes[_gauge])._deposit(uint256(_poolWeight), _tokenId, msg.sender, _tokenOwner);
                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                emit Voted(_pool, msg.sender, _tokenOwner, _tokenId, _poolWeight, block.timestamp);
            }
        }
        if (_usedWeight > 0) IVotingEscrow(_ve).voting(_tokenId);
        totalWeight += uint256(_totalWeight);
        usedWeights[_tokenId] = uint256(_usedWeight);
    }

    function vote(uint tokenId, address[] calldata _poolVote, uint256[] calldata _weights) external onlyNewEpoch(tokenId) {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, tokenId));
        require(_poolVote.length == _weights.length);
        lastVoted[tokenId] = block.timestamp;
        _vote(tokenId, _poolVote, _weights);
    }

    function _whitelist(address _token) internal {
        require(!isWhitelisted[_token], "Already whitelisted");
        isWhitelisted[_token] = true;
        emit Whitelisted(msg.sender, _token, true);
    }

    function createGauge(address _pool) public returns (address) {
        require(gauges[_pool] == address(0x0), "exists");
        address[] memory allowedRewards = new address[](3);
        bool isPair = IPairFactory(factory).isPair(_pool);
        address tokenA;
        address tokenB;

        if (isPair) {
            (tokenA, tokenB) = IPair(_pool).tokens();
            allowedRewards[0] = tokenA;
            allowedRewards[1] = tokenB;
            if (base != tokenA && base != tokenB) {
              allowedRewards[2] = base;
            }
        }
        else {
        	allowedRewards[0] = base;
        }

        if (msg.sender != governor) { // gov can create for any pool, even non-Equalizer pairs
            require(isPair, "!_pool");
            require(isWhitelisted[tokenA] && isWhitelisted[tokenB], "!whitelisted");
        	require(gaugable[tokenA] || gaugable[tokenB], "Pool not Gaugable!");
        	require(IPair(_pool).stable()==false, "Creation of Stable-pool Gauge not allowed!");
        }

        address _bribe = IBribeFactory(bribefactory).createBribe(allowedRewards);

        address[] memory gaugeRewards = new address[](1);
        gaugeRewards[0] = base;
        address _gauge = IGaugeFactory(gaugefactory).createGauge(_pool, _bribe, _ve, isPair, gaugeRewards);


        IERC20(base).approve(_gauge, type(uint).max);
        bribes[_gauge] = _bribe;
        gauges[_pool] = _gauge;
        poolForGauge[_gauge] = _pool;
        isGauge[_gauge] = true;
        isAlive[_gauge] = true;
        _updateFor(_gauge);
        pools.push(_pool);
        emit GaugeAndBribeCreated(_pool, _gauge, _bribe, msg.sender, gaugeRewards, allowedRewards);
        return _gauge;
    }

    function createGaugeMultiple(address[] memory _pools) external returns (address[] memory) {
    	address[] memory _g_c = new address[](_pools.length);
        for(uint _j; _j<_pools.length; _j++) {
            _g_c[_j] = createGauge(_pools[_j]);
        }
        return _g_c;
    }

    function killGauge(address _gauge) external {
        require(msg.sender == emergencyCouncil, "not emergency council");
        require(isAlive[_gauge], "gauge already dead");
        isAlive[_gauge] = false;
        claimable[_gauge] = 0;
        emit GaugeKilled(_gauge);
    }

    function reviveGauge(address _gauge) external {
        require(msg.sender == emergencyCouncil, "not emergency council");
        require(!isAlive[_gauge], "gauge already alive");
        isAlive[_gauge] = true;
        emit GaugeRevived(_gauge);
    }

    function attachTokenToGauge(uint tokenId, address account) external {
        require(isGauge[msg.sender], "not gauge");
        require(isAlive[msg.sender], "killed gauge"); // killed gauges cannot attach tokens to themselves
        if (tokenId > 0) IVotingEscrow(_ve).attach(tokenId);
        emit Attach(account, msg.sender, tokenId);
    }

    function emitDeposit(uint tokenId, address account, uint amount) external {
        require(isGauge[msg.sender], "not gauge");
        require(isAlive[msg.sender], "killed gauge");
        emit Deposit(account, msg.sender, tokenId, amount);
    }

    function detachTokenFromGauge(uint tokenId, address account) external {
        require(isGauge[msg.sender], "not gauge");
        if (tokenId > 0) IVotingEscrow(_ve).detach(tokenId);
        emit Detach(account, msg.sender, tokenId);
    }

    function emitWithdraw(uint tokenId, address account, uint amount) external {
        require(isGauge[msg.sender], "not gauge");
        emit Withdraw(account, msg.sender, tokenId, amount);
    }

    function length() external view returns (uint) {
        return pools.length;
    }

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

    function claimRewards(address[] memory _gauges, address[][] memory _tokens) public {
        for (uint i = 0; i < _gauges.length; i++) {
            IGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
        }
    }

    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) public {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        for (uint i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    function claimEverything(
    	address[] memory _gauges, address[][] memory _gtokens,
    	address[] memory _bribes, address[][] memory _btokens, uint _tokenId
    ) external {
        claimRewards(_gauges, _gtokens);
        if(_tokenId > 0) {
            claimBribes(_bribes, _btokens, _tokenId);
        }
    }

    function distributeFees(address _gauge) external {
        IGauge(_gauge).claimFees();
    }

    function distributeFees(address[] memory _gauges) external {
        for (uint i = 0; i < _gauges.length; i++) {
            IGauge(_gauges[i]).claimFees();
        }
    }

    function distributeFees(uint start, uint finish) public {
        for (uint x = start; x < finish; x++) {
            IGauge(gauges[pools[x]]).claimFees();
        }
    }

    function distributeFees() external {
        distributeFees(0, pools.length);
    }

    function distribute(address _gauge) public lock {
        IMinter(minter).update_period();
        _updateFor(_gauge); // should set claimable to 0 if killed
        uint _claimable = claimable[_gauge];
        if (_claimable > IGauge(_gauge).left(base) && _claimable / DURATION > 0) {
            claimable[_gauge] = 0;
            if(pausedGauges[_gauge] == true) {
            	IERC20(base).transfer(ms, _claimable);
            }
            else {
        		IGauge(_gauge).notifyRewardAmount(base, _claimable);
        		emit DistributeReward(msg.sender, _gauge, _claimable);
            }
        }
    }

    function distribute() external {
        distribute(0, pools.length);
    }

    function distribute(uint start, uint finish) public {
        for (uint x = start; x < finish; x++) {
            distribute(gauges[pools[x]]);
        }
    }

    function distribute(address[] memory _gauges) external {
        for (uint x = 0; x < _gauges.length; x++) {
            distribute(_gauges[x]);
        }
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0, "Voter: invalid token");
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function whitelist(address[] calldata _tokens) external {
        require(msg.sender == governor, "Not governor");
        for (uint i = 0; i < _tokens.length; i++) {
            _whitelist(_tokens[i]);
        }
    }

    function removeFromWhitelist(address[] calldata _tokens) external {
        require(msg.sender == governor, "Not governor");
        for (uint i = 0; i < _tokens.length; i++) {
            delete isWhitelisted[_tokens[i]];
            emit Whitelisted(msg.sender, _tokens[i], false);

        }
    }

    function setGov(address _ms) external {
    	require(msg.sender == ms, "!ms");
    	governor = _ms;
        emergencyCouncil = _ms;
        protocolFeesTaker = _ms;
        ms = _ms;
    }

    function setUnvotablePools(address[] calldata _pools, bool[] calldata _b) external {
        require(msg.sender == governor, "Not governor");
        for (uint i = 0; i < _pools.length; i++) {
            unvotable [ _pools[i] ] = _b[i];
        }
    }

    function setGaugable(address[] calldata _pools, bool[] calldata _b) external {
        require(msg.sender == governor, "Not governor");
        for (uint i = 0; i < _pools.length; i++) {
            gaugable[ _pools[i] ] = _b[i];
        }
    }

    function setPausedGauge(address[] calldata _g, bool[] calldata _b) external {
        require(msg.sender == governor, "Not governor");
        for (uint i = 0; i < _g.length; i++) {
            pausedGauges[ _g[i] ] = _b[i];
        }
    }

    function setPokable(bool _b) external {
        require(msg.sender == governor, "Not governor");
        pokable = _b;
    }

    ///must be called only after all user votes are reset or when nobody is voting!
    function setBribe(address _pool, address _nb) external {
        require(msg.sender == governor, "Not governor");
        address _g = gauges[_pool];
        address _ob = bribes [_g];
        require( IERC20(_ob).totalSupply() == 0 , "Cannot switch bribes which have active deposits!" );
        IGauge(_g).setBribe(_nb);
        bribes [_g] = _nb;
    }

}
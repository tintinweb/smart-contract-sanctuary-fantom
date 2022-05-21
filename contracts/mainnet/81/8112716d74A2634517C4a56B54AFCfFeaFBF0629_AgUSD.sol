/**
 *Submitted for verification at FtmScan.com on 2021-11-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AGUSDErrors {

  struct Error {
    uint256 code;
    string message;
  }

  Error public NOT_ENOUGH_SENT = Error(1, "Not enough collateral sent");
  Error public NOT_ENOUGH_TO_REDEEM = Error(2, "Not enough AgUSD to redeem");
  Error public NOT_ENOUGH_COLLATERAL = Error(3, "Not enough collateral to redeem");

  Error public GATE_LOCKED = Error(101, "Cannot deposit with this collateral");

  Error public NOT_AUTH = Error(401, "Not authorized");
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is ContextUpgradeable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract ERC20Burnable is ContextUpgradeable, ERC20 {

    function burn(uint256 amount) internal virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

interface yearnVault is IERC20 {
  function deposit(uint256 amount, address recipient) external returns (uint256);
}

contract AgUSD is ERC20, ERC20Burnable, OwnableUpgradeable, AGUSDErrors {
    /*
     *  AgUSD, Aggregated USD
     *  Aggregated USD is an overcollateralized stablecoin which works by:
     *
     *  1) User deposits DAI, fUSDT, USDC, MIM or FRAX
     *  2) 50% of stablecoin investment gets deposited to yearn.finance vaults, other stays in the contract, to allow for partial redemptions.
     *  3) yv[coin] gets sent to multisig treasury
     *
     *  - yv deposits ensure coins are ALWAYS earning yeild.
     *  - having many different dollar-pegged stables will help protect the peg if one coin depegs.
     *
     *  [ Scenario 1 ]
     *  Coin prices go from $1 each to:
     *  DAI | FUSDT | USDC | MIM | FRAX
     * ----+-------+------+-----+-------
     *  $1 |  $1   |  $1  | $.75| $1
     *
     * 5 AgUSD would be backed by $4.75, and 1 AgUSD would be backed by $0.95.
     *
     * [ Scenario 2 ]
     *  Coin prices go from $1 each to:
     *  DAI | FUSDT | USDC | MIM | FRAX
     * ----+-------+------+-----+-------
     *  $1 |  $0.1 |  $1  | $1  | $1
     *
     * 5 AgUSD would be backed by $4.1, and 1 AgUSD would be backed by $0.82.
     *
     * [ Scenario 3 ]
     *  Coin prices go from $1 each to:
     *  DAI | FUSDT | USDC | MIM | FRAX
     * ----+-------+------+-----+-------
     *  $1 |  $0.1 |  $1  | $.75| $1
     *
     * 5 AgUSD would be backed by $3.85, and 1 AgUSD would be backed by $0.77.
     *
     * You can see, that even in the most dire circumstances (1 token at $0.1 and/or another at $0.75), the AgUSD peg only loses [5|18|23]% of its peg!
     * This allows the treasury to grow more, while only having to spend minimal amounts on maintaining the peg.
     *
     */

    constructor() ERC20("Aggregated USD", "AgUSD") {}

    address private dai = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
    address private fusdt = 0x049d68029688eAbF473097a2fC38ef61633A3C7A;
    address private usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address private mim = 0x82f0B8B456c1A451378467398982d4834b6829c1;
    address private frax = 0xdc301622e621166BD8E82f2cA0A26c13Ad0BE355;

    bool public mimGate = true;
    bool public daiGate = true;
    bool public usdcGate = true;
    bool public fusdtGate = true;
    bool public fraxGate = true;

    address private yvdai = 0x637eC617c86D24E421328e6CAEa1d92114892439;
    address private yvfusdt = 0x148c05caf1Bb09B5670f00D511718f733C54bC4c;
    address private yvusdc = 0xEF0210eB96c7EB36AF8ed1c20306462764935607;
    address private yvmim = 0x0A0b23D9786963DE69CB2447dC125c49929419d8;
    address private yvfrax = 0x357ca46da26E1EefC195287ce9D838A6D5023ef3;

    address private multisig = 0x3e522051A9B1958Aa1e828AC24Afba4a551DF37d;

    function initialize() public payable initializer {
      __Ownable_init();
    }

    // these functions will be payable to optimise gas

    function mintFromDAI(uint256 amount) public payable {
        IERC20 daiToken = IERC20(dai);
        require(daiGate, GATE_LOCKED.message);
        require(
            daiToken.transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            'Could not transfer tokens from your address to this contract'
        );
        yearnVault(yvdai).deposit(amount/2, multisig);
        _mint(msg.sender, amount);
    }

    function mintFromUSDC(uint256 amount) public payable {
        IERC20 usdcToken = IERC20(usdc);
        require(usdcGate, GATE_LOCKED.message);
        require(
            usdcToken.transferFrom(
                msg.sender,
                address(this),
                amount / 10**12
            ),
            'Could not transfer tokens from your address to this contract'
        );
        yearnVault(yvusdc).deposit(amount/2, multisig);
        _mint(msg.sender, amount);
    }

    function mintFromFUSDT(uint256 amount) public payable {
        IERC20 fusdtToken = IERC20(fusdt);
        require(fusdtGate, GATE_LOCKED.message);
        require(
            fusdtToken.transferFrom(
                msg.sender,
                address(this),
                amount / 10**12
            ),
            'Could not transfer tokens from your address to this contract'
        );
        yearnVault(yvfusdt).deposit(amount/2, multisig);
        _mint(msg.sender, amount);
    }

    function mintFromMIM(uint256 amount) public payable {
        IERC20 mimToken = IERC20(mim);
        require(mimGate, GATE_LOCKED.message);
        require(
            mimToken.transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            'Could not transfer tokens from your address to this contract'
        );
        yearnVault(yvmim).deposit(amount/2, multisig);
        _mint(msg.sender, amount);
    }

    function mintFromFRAX(uint256 amount) public payable {
        IERC20 fraxToken = IERC20(frax);
        require(fraxGate, GATE_LOCKED.message);
        require(
            fraxToken.transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            'Could not transfer tokens from your address to this contract'
        );
        yearnVault(yvfrax).deposit(amount/2, multisig);
        _mint(msg.sender, amount);
    }

    function AgusdToDai(uint256 amount) public payable {
        IERC20 daiToken = IERC20(dai);
        require(daiToken.balanceOf(address(this)) >= amount, NOT_ENOUGH_TO_REDEEM.message);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        daiToken.transfer(msg.sender, amount);
    }

    function AgusdToFusdt(uint256 amount) public payable {
        IERC20 fusdtToken = IERC20(fusdt);
        require(fusdtToken.balanceOf(address(this)) >= amount, NOT_ENOUGH_TO_REDEEM.message);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        fusdtToken.transfer(msg.sender, amount / 10**12);
    }

    function AgusdToUsdc(uint256 amount) public payable {
        IERC20 usdcToken = IERC20(usdc);
        require(usdcToken.balanceOf(address(this)) >= amount, NOT_ENOUGH_TO_REDEEM.message);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        usdcToken.transfer(msg.sender, amount / 10**12);
    }

    function AgusdToMim(uint256 amount) public payable {
        IERC20 mimToken = IERC20(mim);
        require(mimToken.balanceOf(address(this)) >= amount, NOT_ENOUGH_TO_REDEEM.message);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        mimToken.transfer(msg.sender, amount);
    }

    function AgusdToFrax(uint256 amount) public payable {
        IERC20 fraxToken = IERC20(frax);
        require(fraxToken.balanceOf(address(this)) >= amount, NOT_ENOUGH_TO_REDEEM.message);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        fraxToken.transfer(msg.sender, amount);
    }

    function getUSDCBalance() public view returns(uint256) {
        return ERC20(usdc).balanceOf(address(this));
    }

    function getFUSDTBalance() public view returns(uint256) {
        return ERC20(fusdt).balanceOf(address(this));
    }

    function getDAIBalance() public view returns(uint256) {
        return ERC20(dai).balanceOf(address(this));
    }

    function getMIMBalance() public view returns(uint256) {
        return ERC20(mim).balanceOf(address(this));
    }

    function getFRAXBalance() public view returns(uint256) {
        return ERC20(mim).balanceOf(address(this));
    }

    function setMimGate(bool mimStatus) public onlyOwner {
        mimGate = mimStatus;
    }

    function setDaiGate(bool daiStatus) public onlyOwner {
        daiGate = daiStatus;
    }

    function setFusdtGate(bool fusdtStatus) public onlyOwner {
        fusdtGate = fusdtStatus;
    }

    function setUsdcGate(bool usdcStatus) public onlyOwner {
        usdcGate = usdcStatus;
    }

    function setFraxGate(bool fraxStatus) public onlyOwner {
        fraxGate = fraxStatus;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
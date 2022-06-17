/**
 *Submitted for verification at FtmScan.com on 2022-06-17
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID =
        keccak256("ERC20Token");

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account_, uint256 ammount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(this), account_, ammount_);
        _totalSupply = _totalSupply.add(ammount_);
        _balances[account_] = _balances[account_].add(ammount_);
        emit Transfer(address(this), account_, ammount_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {}
}

interface IERC2612Permit {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public DOMAIN_SEPARATOR;

    constructor() {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name())),
                keccak256(bytes("1")), // Version
                chainID,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "Permit: expired deadline");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 _hash = keccak256(
            abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct)
        );

        address signer = ecrecover(_hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "ZeroSwapPermit: Invalid signature"
        );

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IOwnable {
    function manager() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyManager {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_)
        public
        virtual
        override
        onlyManager
    {
        require(
            newOwner_ != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

interface IReward {
    function sendReward() external;

    function verify(uint256 tokenId, address _user)
        external
        view
        returns (bool);

    function userGang(address _user) external view returns (uint256);
}

interface IAutoAddLiquidity {
    function swapAndAddLiquidity() external;
}

contract TokenStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable token;
    address public immutable rewardToken;

    address public rewardAddress;

    address public helperAddress;

    //tokenID
    mapping(uint256 => uint256) public totalRewards;

    //tokenID
    mapping(uint256 => uint256) public totalClaims;

    mapping(address => User) public _userInfo;

    // tokenID
    mapping(uint256 => uint256) public _userTotalGons;

    mapping(uint256 => uint256) public _userTotalCoins;

    // tokenID
    mapping(uint256 => uint256) public _accCoinPerShare;

    uint256 private _totalSupply;

    uint256 private constant MAX_UINT256 = ~uint256(0);

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 30000000 * 10**18;

    uint256 private constant TOTAL_GONS =
        (MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY)) / 1e24;

    uint256 public rebaseRate = 200;

    uint256 public constant RATE_DECIMALS = 4;

    uint256 private _gonsPerFragment;

    mapping(address => uint256) private _gonBalances;

    uint256 public coefficient = 10000;
    uint256 public leastUnstakeTime = 7 * 24 * 60 * 60;
    uint256 public fee;
    bool public rescueEnabled = false;
    address public feeAddress;

    event Staked(address _user, uint256 gangID, uint256 _amount);
    event UnStaked(address _user, uint256 gangID, uint256 _amount);

    struct User {
        uint256 tokenID;
        uint256 lastTime;
        uint256 amount;
        uint256 gons;
        uint256 pending;
        uint256 dept;
        uint256 coinShare;
    }

    modifier onlyReward() {
        require(msg.sender == rewardAddress, "You are not the rewared");
        _;
    }

    modifier onlyHelper() {
        require(msg.sender == helperAddress, "You are not the rewared");
        _;
    }

    constructor(
        address _token,
        address _rewardToken,
        address _rewardAddress,
        uint256 _fee,
        address _feeAddress
    ) {
        token = _token;
        rewardToken = _rewardToken;
        rewardAddress = _rewardAddress;
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _gonBalances[address(this)] = TOTAL_GONS;
        fee = _fee;
        feeAddress = _feeAddress;
    }

    function setHelper(address _helper) external onlyManager {
        helperAddress = _helper;
    }

    function setCoefficient(uint256 _coefficient) external onlyManager {
        coefficient = _coefficient;
    }

    function setRebaseRate(uint256 _rebaseRate) external onlyManager {
        rebaseRate = _rebaseRate;
    }

    function setFee(uint256 _fee) external onlyManager {
        fee = _fee;
    }

    function setFeeAddress(address _feeAddress) external onlyManager {
        feeAddress = _feeAddress;
    }

    function startReward(uint256[] memory _tokenIDs, uint256[] memory _balance)
        external
        onlyReward
    {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            if (_balance[i] > 0 && _userTotalGons[_tokenIDs[i]] > 0) {
                totalRewards[_tokenIDs[i]] += _balance[i];
                _accCoinPerShare[_tokenIDs[i]] += _balance[i].mul(1e48).div(
                    _userTotalGons[_tokenIDs[i]]
                );
            }
        }
        rebase();
    }

    function claimReward(address _user) internal {
        IReward(rewardAddress).sendReward();
        if (
            _userInfo[_user].gons > 0 &&
            _userInfo[_user].coinShare <
            _accCoinPerShare[_userInfo[_user].tokenID]
        ) {
            _userInfo[_user].pending = pending(_user);
            _userInfo[_user].coinShare = _accCoinPerShare[
                _userInfo[_user].tokenID
            ];
            _userInfo[_user].dept = _userInfo[_user]
                .gons
                .mul(_accCoinPerShare[_userInfo[_user].tokenID])
                .div(1e48);
        }
    }

    function pending(address _user) public view returns (uint256 _pending) {
        User memory info = _userInfo[_user];
        if (info.gons == 0) {
            _pending = 0;
        } else {
            _pending = info
                .gons
                .mul(_accCoinPerShare[info.tokenID])
                .div(1e48)
                .sub(info.dept)
                .add(info.pending);
        }
    }

    function claim(address _user) external onlyHelper {
        _claim(_user);
    }

    function _claim(address _user) internal {
        claimReward(_user);
        if (_userInfo[_user].pending > 0) {
            uint256 feeAmount;
            if (fee > 0) {
                feeAmount = _userInfo[_user].pending.mul(fee).div(1e4);
                IERC20(rewardToken).safeTransfer(feeAddress, feeAmount);
            }
            IERC20(rewardToken).safeTransfer(
                _user,
                _userInfo[_user].pending.sub(feeAmount)
            );
            totalClaims[_userInfo[_user].tokenID] += _userInfo[_user].pending;
            _userInfo[_user].pending = 0;
        }
    }

    function stake(
        address _user,
        uint256 _tokenID,
        uint256 _amount
    ) external onlyHelper {
        require(IReward(rewardAddress).verify(_tokenID, _user), "Gang error");
        claimReward(_user);
        IERC20(token).safeTransferFrom(_user, address(this), _amount);
        User storage info = _userInfo[_user];
        info.lastTime = block.timestamp;
        info.tokenID = _tokenID;
        info.amount += _amount;
        uint256 gons = gonsForBalance(_amount);
        info.gons += gons;
        info.coinShare = _accCoinPerShare[_tokenID];
        info.dept = info.gons.mul(_accCoinPerShare[_tokenID]).div(1e48);
        mint(_user, gons);
        _userTotalGons[_tokenID] += gons;
        _userTotalCoins[_tokenID] += _amount;

        emit Staked(_user, _tokenID, _amount);
    }

    function unStake(address _user, uint256 _amount) external onlyHelper {
        // claimReward(_user);
        _claim(_user);
        User storage info = _userInfo[_user];

        require(info.amount >= _amount, "exceed amount");
        require(
            info.lastTime + leastUnstakeTime <= block.timestamp,
            "not expired"
        );

        uint256 share = _amount.mul(1e4).div(info.amount);

        uint256 gons = info.gons.mul(share).div(1e4);

        info.gons -= gons;

        info.amount -= _amount;
        burn(_user, gons);

        if (info.amount == 0) info.coinShare = 0;

        _userTotalGons[info.tokenID] -= gons;
        _userTotalCoins[info.tokenID] -= _amount;

        IERC20(token).safeTransfer(_user, _amount);

        emit UnStaked(_user, info.tokenID, _amount);
    }

    function rebase() internal {
        _totalSupply = _totalSupply
            .mul((10**RATE_DECIMALS).add(rebaseRate))
            .div(10**RATE_DECIMALS);
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
    }

    function mint(address user, uint256 gons) internal {
        _gonBalances[address(this)] -= gons;
        _gonBalances[user] += gons;
    }

    function burn(address user, uint256 gons) internal {
        _gonBalances[address(this)] = _gonBalances[address(this)].add(gons);
        _gonBalances[user] = _gonBalances[user].sub(gons);
    }

    function getTotalAmount(uint256 _tokenID) public view returns (uint256) {
        return
            balanceForGons(_userTotalGons[_tokenID]).mul(coefficient).div(1e4);
    }

    function getTotalCoin(uint256 _tokenID) public view returns (uint256) {
        return _userTotalCoins[_tokenID];
    }

    function balanceOf(address who) public view returns (uint256) {
        if (who == address(this)) {
            return _gonBalances[who].div(_gonsPerFragment);
        } else {
            return
                _gonBalances[who].div(_gonsPerFragment).mul(coefficient).div(
                    1e4
                );
        }
    }

    function gonsForBalance(uint256 amount) public view returns (uint256) {
        return amount.mul(_gonsPerFragment);
    }

    function balanceForGons(uint256 gons) public view returns (uint256) {
        return gons.div(_gonsPerFragment);
    }

    function circulatingSupply() public view returns (uint256) {
        return
            _totalSupply.sub(balanceOf(address(this))).mul(coefficient).div(
                1e4
            );
    }

    function getUserAmount(address _user) public view returns (uint256) {
        return _userInfo[_user].amount;
    }

    function getUserScore(address _user) public view returns (uint256) {
        return balanceForGons(_userInfo[_user].gons);
    }

    function setRescueEnabled(bool _enabled) external onlyManager {
        rescueEnabled = _enabled;
    }

    function rescue() external {
        require(rescueEnabled, "not rescueEnabled");
        uint256 _amount = _userInfo[msg.sender].amount;
        IERC20(token).safeTransfer(msg.sender, _amount);
    }

    function setLeastUnstakeTime(uint256 _time) external onlyManager {
        leastUnstakeTime = _time;
    }

    function setRewardAddress(address _r) external onlyManager {
        rewardAddress = _r;
    }
}
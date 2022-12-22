/**
 *Submitted for verification at FtmScan.com on 2022-12-22
*/

// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
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

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/LFWUtils_Fantom.sol


interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IFWalletInterface {
    function getStake(address _user, uint256 _vId) external view returns (uint256);
    function pendingRewards(address _user, uint256 _vId) external view returns (uint256);
    function lastValidatorID() external view returns (uint256);
}

interface IGeistStakingInterface {
    function totalBalance(address _user) external view returns (uint256);
    function rewards(address _user, address _token) external view returns (uint256);
}

interface IGeistFarmingInterface {
    function poolInfo(address _token) external view returns (uint256, uint256, uint256, address);
    function userInfo(address _token, address _user) external view returns (uint256, uint256);
}

interface ISpookyStakingInterface {
    function BOOBalance(address _user) external view returns (uint256);
}

interface ISpookyFarmingInterface {
    function pendingBOO(uint256 _pId, address _user) external view returns (uint256);
    function lpToken(uint256 _pId) external view returns (address);
    function userInfo(uint256 _pId, address _user) external view returns (uint256, uint256);
}

interface ISpiritInterface {
    function pendingSpirit(uint256 _pId, address _user) external view returns (uint256);
    function poolInfo(uint256 _pId) external view returns (address, uint256, uint256, uint256, uint16);
    function userInfo(uint256 _pId, address _user) external view returns (uint256, uint256);
    function spiritPerBlock() external view returns (uint256);
}

interface IWigoInterface {
    function pendingWigo(uint256 _pId, address _user) external view returns (uint256);
    function poolInfo(uint256 _pId) external view returns (address, uint256, uint256, uint256);
    function userInfo(uint256 _pId, address _user) external view returns (uint256, uint256);
    function wigoPerSecond() external view returns (uint256);
}

contract LFWUtils_Fantom_Flatten {
    uint private numStakingParameters = 5;
    uint private numStakingData = 2;
    uint private numFarmingParameters = 5;
    uint private numFarmingData = 3;
    address private geist = 0xd8321AA83Fb0a4ECd6348D4577431310A6E0814d;
    address private ftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address private boo = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
    address private spirit = 0x5Cc61A78F164885776AA610fb0FE1257df78E59B;
    address private wigo = 0xE992bEAb6659BFF447893641A378FbbF031C5bD6;
    address private geistFarming = 0xE40b7FA6F5F7FB0Dc7d56f433814227AAaE020B5;
    address private geistLP = 0x668AE94D0870230AC007a01B471D02b2c94DDcB9;
    address private booFarmingV1 = 0x18b4f774fdC7BF685daeeF66c2990b1dDd9ea6aD;
    address private booFarmingV2 = 0x9C9C920E51778c4ABF727b8Bb223e78132F00aA4;
    address private spiritFarming = 0x9083EA3756BDE6Ee6f27a6e996806FBD37F6F093;
    address private wigoFarming = 0xA1a938855735C0651A6CfE2E93a32A28A236d0E9;
    uint private dailyBlock = 60000;
    uint private yearDay = 365;
    uint private secondsPerYear = 31536000;
    uint private secondsPerDay = 86400;

    function getFWalletStakingInfo(
        address _scAddress, 
        address _userAddress
    ) public view returns(uint256[] memory stakingInfo, address[] memory stakingData) {
        // Define array to return
        stakingInfo = new uint256[](numStakingParameters);
        stakingData = new address[](numStakingData);

        // Initialize interface
        IFWalletInterface scInterface = IFWalletInterface(_scAddress);

        // Get number of validator
        uint256 noVal = scInterface.lastValidatorID();

        // Loop
        for (uint i = 1; i<=noVal; i++) {
            // [0] is the user's pending reward
            stakingInfo[0] += scInterface.pendingRewards(_userAddress, i);
            // [1] is the user's staking amount
            stakingInfo[1] += scInterface.getStake(_userAddress, i);
        } 

        (stakingInfo[2], stakingInfo[3], stakingInfo[4]) = (0, 0, 1);

        stakingData[0] = ftm;
        stakingData[1] = ftm;
    } 

    function getGeistStakingInfo(
        address _scAddress,
        address _userAddress
    ) public view returns (uint256[] memory stakingInfo, address[] memory stakingData) {
        // Define array to return
        stakingInfo = new uint256[](numStakingParameters);
        stakingData = new address[](numStakingData);

        // Initialize interface
        IGeistStakingInterface scInterface = IGeistStakingInterface(_scAddress);

        // [0] is the user's pending reward     
        stakingInfo[0] = scInterface.rewards(_userAddress, geist);

        // [1] is the user staking amount
        stakingInfo[1] = scInterface.totalBalance(_userAddress);   

        (stakingInfo[2], stakingInfo[3], stakingInfo[4]) = (0, 0, 1);

        stakingData[0] = geist;
        stakingData[1] = geist;
    }

    function getGeistFarmingInfo(
        address _userAddress
    ) public view returns(uint256[] memory farmingInfo, address[] memory farmingData) {
        // Define array to return
        farmingInfo = new uint256[](numFarmingParameters);

        // Define array to return data
        farmingData = new address[](numFarmingData);

        // Initialize interface
        IGeistFarmingInterface scInterface = IGeistFarmingInterface(geistFarming);

        // Initialize value to calculate pending reward
        uint256 accRewardPerShare;
        uint256 rewardDebt;
        uint256 dummy;
        ( , , accRewardPerShare, ) = scInterface.poolInfo(geistLP);

        (dummy, rewardDebt) = scInterface.userInfo(geistLP, _userAddress);

        // [0] is the user's pending reward
        farmingInfo[0] = ((dummy*accRewardPerShare)/1e12)  - rewardDebt;

        // [1] is the user's staking amount
        farmingInfo[1] = dummy;

        farmingData[0] = geist;
        farmingData[1] = ftm;

        // [3] is the reward token address
        farmingData[2] = geist;

        IPair scPair = IPair(geistLP);

        (farmingInfo[2], farmingInfo[3], ) = scPair.getReserves();
        farmingInfo[4] = scPair.totalSupply();
    }

    function getSpookyStakingInfo(
        address _scAddress,
        address _userAddress
    ) public view returns(uint256[] memory stakingInfo, address[] memory stakingData) {
        // Define array to return
        stakingInfo = new uint256[](numStakingParameters);
        stakingData = new address[](numStakingData);

        ISpookyStakingInterface scInterface = ISpookyStakingInterface(_scAddress);

        (stakingInfo[0], stakingInfo[2], stakingInfo[3], stakingInfo[4]) = (0,0,0,0);
        stakingInfo[1] = scInterface.BOOBalance(_userAddress); // user's staking amount
        stakingData[0] = boo;
        stakingData[1] = boo;
    }

    function getSpookyFarmingV1Info(
        uint256 _pId, 
        address _userAddress
    ) public view returns(uint256[] memory farmingInfo, address[] memory farmingData) {
        // Define array to return
        farmingInfo = new uint256[](numFarmingParameters);

        // Define array to return data
        farmingData = new address[](numFarmingData);

        // Initialize interface
        ISpookyFarmingInterface scInterface = ISpookyFarmingInterface(booFarmingV1);

        // [0] is the user pending reward
        farmingInfo[0] = scInterface.pendingBOO(_pId, _userAddress);

        // [1] is the user's staking amount
        (farmingInfo[1], ) = scInterface.userInfo(_pId, _userAddress);

        // [0] and [1] are token 0 and token 1
        address _lp = scInterface.lpToken(_pId);

        // Initialize interfacee
        IPair scPair = IPair(_lp);

        farmingData[0] = scPair.token0();
        farmingData[1] = scPair.token1();

        // [3] is the reward token address
        farmingData[2] = boo;

        (farmingInfo[2], farmingInfo[3], ) = scPair.getReserves();
        farmingInfo[4] = scPair.totalSupply();
    }

    function getSpookyFarmingV2Info(
        uint256 _pId, 
        address _userAddress
    ) public view returns(uint256[] memory farmingInfo, address[] memory farmingData) {
        // Define array to return
        farmingInfo = new uint256[](numFarmingParameters);

        // Define array to return data
        farmingData = new address[](numFarmingData);

        // Initialize interface
        ISpookyFarmingInterface scInterface = ISpookyFarmingInterface(booFarmingV2);

        // [0] is the user pending reward
        farmingInfo[0] = scInterface.pendingBOO(_pId, _userAddress);

        // [1] is the user's staking amount
        (farmingInfo[1], ) = scInterface.userInfo(_pId, _userAddress);

        // [0] and [1] are token 0 and token 1
        address _lp = scInterface.lpToken(_pId);

        // Initialize interfacee
        IPair scPair = IPair(_lp);

        farmingData[0] = scPair.token0();
        farmingData[1] = scPair.token1();

        // [3] is the reward token address
        farmingData[2] = boo;

        (farmingInfo[2], farmingInfo[3], ) = scPair.getReserves();
        farmingInfo[4] = scPair.totalSupply();
    }

    function getSpiritStakingInfo(
        address _scAddress, 
        address _userAddress
    ) public view returns(uint256[] memory stakingInfo, address[] memory stakingData) {
        // Define array to return
        stakingInfo = new uint256[](numStakingParameters);
        stakingData = new address[](numStakingData);
        // Initialize interface
        ISpiritInterface scInterface = ISpiritInterface(_scAddress);

        // [0] is the user pending reward
        stakingInfo[0] = scInterface.pendingSpirit(0, _userAddress);

        // [1] is the user's staking amount
        (stakingInfo[1], ) = scInterface.userInfo(0, _userAddress);

        // [2] Calculate an optional term to calculate APR for backend
        uint256 rewardPerYear = scInterface.spiritPerBlock()*dailyBlock*yearDay;
        uint256 stakedTokenBalance = IERC20(spirit).balanceOf(_scAddress);
        stakingInfo[2] = rewardPerYear;
        stakingInfo[3] = stakedTokenBalance;

        // [3] is the pool countdown by block
        stakingInfo[4] = 1;

        stakingData[0] = spirit;
        stakingData[1] = spirit;
    }

    function getSpiritFarmingInfo(
        uint256 _pId, 
        address _userAddress
    ) public view returns(uint256[] memory farmingInfo, address[] memory farmingData) {
        // Define array to return
        farmingInfo = new uint256[](numFarmingParameters);

        // Define array to return data
        farmingData = new address[](numFarmingData);

        // Initialize interface
        ISpiritInterface scInterface = ISpiritInterface(spiritFarming);

        // [0] is the user pending reward
        farmingInfo[0] = scInterface.pendingSpirit(_pId, _userAddress);

        // [1] is the user's staking amount
        (farmingInfo[1], ) = scInterface.userInfo(_pId, _userAddress);

        // [0] and [1] are token 0 and token 1
        (address _lp, , , , ) = scInterface.poolInfo(_pId);

        // Initialize interfacee
        IPair scPair = IPair(_lp);

        farmingData[0] = scPair.token0();
        farmingData[1] = scPair.token1();

        // [3] is the reward token address
        farmingData[2] = spirit;

        (farmingInfo[2], farmingInfo[3], ) = scPair.getReserves();
        farmingInfo[4] = scPair.totalSupply();
    }

    function getWigoStakingInfo(
        address _scAddress, 
        address _userAddress
    ) public view returns(uint256[] memory stakingInfo, address[] memory stakingData) {
        // Define array to return
        stakingInfo = new uint256[](numStakingParameters);
        stakingData = new address[](numStakingData);

        // Initialize interface
        IWigoInterface scInterface = IWigoInterface(_scAddress);

        // [0] is the user pending reward
        stakingInfo[0] = scInterface.pendingWigo(0, _userAddress);

        // [1] is the user's staking amount
        (stakingInfo[1], ) = scInterface.userInfo(0, _userAddress);

        // [2] Calculate an optional term to calculate APR for backend
        uint256 rewardPerYear = scInterface.wigoPerSecond()*secondsPerYear;
        uint256 stakedTokenBalance = IERC20(wigo).balanceOf(_scAddress);
        stakingInfo[2] = rewardPerYear;
        stakingInfo[3] = stakedTokenBalance;

        // [3] is the pool countdown by block
        stakingInfo[4] = 1;

        stakingData[0] = wigo;
        stakingData[1] = wigo;
    }

    function getWigoFarmingInfo(
        uint256 _pId, 
        address _userAddress
    ) public view returns(uint256[] memory farmingInfo, address[] memory farmingData) {
        // Define array to return
        farmingInfo = new uint256[](numFarmingParameters);

        // Define array to return data
        farmingData = new address[](numFarmingData);

        // Initialize interface
        IWigoInterface scInterface = IWigoInterface(wigoFarming);

        // [0] is the user pending reward
        farmingInfo[0] = scInterface.pendingWigo(_pId, _userAddress);

        // [1] is the user's staking amount
        (farmingInfo[1], ) = scInterface.userInfo(_pId, _userAddress);

        // [0] and [1] are token 0 and token 1
        (address _lp, , , ) = scInterface.poolInfo(_pId);

        // Initialize interfacee
        IPair scPair = IPair(_lp);

        farmingData[0] = scPair.token0();
        farmingData[1] = scPair.token1();

        // [3] is the reward token address
        farmingData[2] = wigo;

        (farmingInfo[2], farmingInfo[3], ) = scPair.getReserves();
        farmingInfo[4] = scPair.totalSupply();
    }
}
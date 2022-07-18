// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRewarder.sol";
import "./interfaces/IMasterChef.sol";

contract SpookyFetchHelper {
    uint256 secPerYear = 31536000;

    address public masterchef = 0x2b2929E785374c651a81A63878Ab22742656DcDd;
    address public masterchefv2 = 0x18b4f774fdC7BF685daeeF66c2990b1dDd9ea6aD;
    address public masterchefv3 = 0xDF5e820568BAEE4817e9f6d2c10385B61e45Be6B;
    address[3] public chefs = [masterchef, masterchefv2, masterchefv3];

    mapping(address => uint256) public dummyPids;

    struct RewardTokenData {
        address rewardToken;
        uint256 allocPoint;
        uint256 rewardPerYear;
    }

    struct RewardEarningsData {
        address rewardToken;
        uint256 earnings;
    }

    constructor() {
        dummyPids[masterchefv2] = 73;
        dummyPids[masterchefv3] = 82;
    }

    function _chef(uint256 version) internal view returns (address) {
        return chefs[version - 1];
    }

    function _tryTokenDecimals(IERC20 token) internal view returns (uint8) {
        try ERC20(address(token)).decimals() returns (uint8 decimals) {
            return decimals;
        } catch {
            return 0;
        }
    }

    function _tryGetChildRewarders(IRewarder rewarder)
        internal
        view
        returns (IRewarder[] memory)
    {
        if (address(rewarder) == address(0)) return new IRewarder[](0);

        try IComplexRewarder(address(rewarder)).getChildrenRewarders() returns (
            IRewarder[] memory childRewarders
        ) {
            return childRewarders;
        } catch {
            return new IRewarder[](0);
        }
    }

    function _fetchMCV1PoolAlloc(uint256 pid)
        internal
        view
        returns (uint256 alloc)
    {
        alloc = IMasterChef(masterchef).poolInfo(pid).allocPoint;
    }

    function _fetchMCV1TotalAlloc() internal view returns (uint256 totalAlloc) {
        totalAlloc = IMasterChef(masterchef).totalAllocPoint();
    }

    function _fetchMCV2PoolAlloc(address chef, uint256 pid)
        internal
        view
        returns (uint256 alloc)
    {
        (, , alloc) = IMasterChefV2(chef).poolInfo(pid);
    }

    function _fetchMCV2TotalAlloc(address chef)
        internal
        view
        returns (uint256 totalAlloc)
    {
        totalAlloc = IMasterChefV2(chef).totalAllocPoint();
    }

    function _fetchIRewarderPoolAlloc(IRewarder rewarder, uint256 pid)
        internal
        view
        returns (uint256 alloc)
    {
        (, , alloc) = IRewarderExt(address(rewarder)).poolInfo(pid);
    }

    function _fetchIRewarderTotalAlloc(IRewarder rewarder)
        internal
        view
        returns (uint256 totalAlloc)
    {
        try IRewarderExt(address(rewarder)).totalAllocPoint() returns (
            uint256 alloc
        ) {
            totalAlloc = alloc;
        } catch {
            uint256 alloc;
            for (uint256 i = 0; i < IRewarderExt(address(rewarder)).poolLength(); i++) {
                (,,alloc) = IRewarderExt(address(rewarder)).poolInfo(IRewarderExt(address(rewarder)).poolIds(i));
                totalAlloc += alloc;
            }
        }
    }

    function fetchLpData(
        IERC20 lp,
        IERC20 token,
        IERC20 quote,
        uint8 version
    )
        public
        view
        returns (
            uint256 tokenBalanceInLp,
            uint256 quoteBalanceInLp,
            uint256 lpBalanceInChef,
            uint256 lpSupply,
            uint8 tokenDecimals,
            uint8 quoteDecimals
        )
    {
        tokenBalanceInLp = token.balanceOf(address(lp));
        quoteBalanceInLp = quote.balanceOf(address(lp));
        lpBalanceInChef = lp.balanceOf(_chef(version));
        lpSupply = lp.totalSupply();
        tokenDecimals = _tryTokenDecimals(token);
        quoteDecimals = _tryTokenDecimals(quote);
    }

    function _fetchFarmRewarders(uint256 pid, uint8 version)
        internal
        view
        returns (
            uint256,
            IRewarder,
            IRewarder[] memory
        )
    {
        if (version == 1) {
            return (1, IRewarder(address(0)), new IRewarder[](0));
        }
        if (version == 2 || version == 3) {
            IRewarder rewarder = IMasterChefV2(_chef(version)).rewarder(pid);
            IRewarder[] memory childRewarders = _tryGetChildRewarders(rewarder);
            return (
                1 +
                    (address(rewarder) != address(0) ? 1 : 0) +
                    childRewarders.length,
                rewarder,
                childRewarders
            );
        }

        return (0, IRewarder(address(0)), new IRewarder[](0));
    }

    function fetchFarmData(uint256 pid, uint8 version)
        public
        view
        returns (RewardTokenData[] memory rewardTokens)
    {
        (
            uint256 rewardTokensCount,
            IRewarder complexRewarder,
            IRewarder[] memory childRewarders
        ) = _fetchFarmRewarders(pid, version);
        rewardTokens = new RewardTokenData[](rewardTokensCount);

        // MCV1 pool, earns only BOO
        if (version == 1) {
            uint256 totalAlloc = _fetchMCV1TotalAlloc();
            rewardTokens[0] = RewardTokenData({
                rewardToken: address(IMasterChef(masterchef).boo()),
                allocPoint: _fetchMCV1PoolAlloc(pid),
                rewardPerYear: totalAlloc == 0
                    ? 0
                    : (secPerYear *
                        IMasterChef(masterchef).booPerSecond() *
                        _fetchMCV1PoolAlloc(pid)) / totalAlloc
            });
        }

        // MCV2 pool, earns BOO
        if (version == 2 || version == 3) {
            uint256 totalAlloc = _fetchMCV2TotalAlloc(_chef(version));
            rewardTokens[0] = RewardTokenData({
                rewardToken: address(IMasterChefV2(_chef(version)).BOO()),
                allocPoint: _fetchMCV2PoolAlloc(_chef(version), pid),
                rewardPerYear: totalAlloc == 0
                    ? 0
                    : (secPerYear *
                        IMasterChefV2(_chef(version)).booPerSecond() *
                        _fetchMCV2PoolAlloc(_chef(version), pid)) / totalAlloc
            });
        }

        // Complex Rewarder
        if (address(complexRewarder) != address(0)) {
            uint256 totalAlloc = _fetchIRewarderTotalAlloc(complexRewarder);
            rewardTokens[1] = RewardTokenData({
                rewardToken: address(complexRewarder.rewardToken()),
                allocPoint: _fetchIRewarderPoolAlloc(complexRewarder, pid),
                rewardPerYear: totalAlloc == 0
                    ? 0
                    : (secPerYear *
                        complexRewarder.rewardPerSecond() *
                        _fetchIRewarderPoolAlloc(complexRewarder, pid)) /
                        totalAlloc
            });
        }

        // Child Rewarders of the Complex Rewarder
        for (uint8 i = 0; i < childRewarders.length; i++) {
            uint256 totalAlloc = _fetchIRewarderTotalAlloc(childRewarders[i]);
            rewardTokens[i + 2] = RewardTokenData({
                rewardToken: address(childRewarders[i].rewardToken()),
                allocPoint: _fetchIRewarderPoolAlloc(childRewarders[i], pid),
                rewardPerYear: totalAlloc == 0
                    ? 0
                    : (secPerYear *
                        childRewarders[i].rewardPerSecond() *
                        _fetchIRewarderPoolAlloc(childRewarders[i], pid)) /
                        totalAlloc
            });
        }
    }

    function fetchUserLpData(
        address user,
        IERC20 lp,
        uint8 version
    ) public view returns (uint256 allowance, uint256 balance) {
        allowance = lp.allowance(user, _chef(version));
        balance = lp.balanceOf(user);
    }

    function _fetchRewarderEarningsData(
        address user,
        uint256 pid,
        uint8 version
    )
        internal
        view
        returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        if (version == 1) return (new IERC20[](0), new uint256[](0));

        IRewarder rewarder = IMasterChefV2(_chef(version)).rewarder(pid);
        if (address(rewarder) == address(0))
            return (new IERC20[](0), new uint256[](0));

        return rewarder.pendingTokens(pid, user, 0);
    }

    function fetchUserFarmData(
        address user,
        uint256 pid,
        uint8 version
    )
        public
        view
        returns (uint256 staked, RewardEarningsData[] memory earnings)
    {
        // User Staked amount
        if (version == 1)
            staked = IMasterChef(masterchef).userInfo(pid, user).amount;
        if (version == 2 || version == 3)
            (staked, ) = IMasterChefV2(_chef(version)).userInfo(pid, user);

        // If pool is v2 and has rewarder, get reward tokens and earnings
        (
            IERC20[] memory rewardTokens,
            uint256[] memory rewardAmounts
        ) = _fetchRewarderEarningsData(user, pid, version);

        // Return array with correct sizing
        earnings = new RewardEarningsData[](1 + rewardTokens.length);

        // Masterchef boo earnings
        uint256 booEarnings;
        if (version == 1)
            booEarnings = IMasterChef(masterchef).pendingBOO(pid, user);
        if (version == 2 || version == 3)
            booEarnings = IMasterChefV2(_chef(version)).pendingBOO(pid, user);
        earnings[0] = RewardEarningsData({
            rewardToken: address(IMasterChef(masterchef).boo()),
            earnings: booEarnings
        });

        // Complex rewarder tokens and earnings
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            earnings[1 + i] = RewardEarningsData({
                rewardToken: address(rewardTokens[i]),
                earnings: rewardAmounts[i]
            });
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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

pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IRewarder {
    function totalAllocPoint() external view returns (uint256);
    function rewardToken() external view returns (IERC20);
    function rewardPerSecond() external view returns (uint256);
    function onReward(uint256 pid, address user, address recipient, uint256 Booamount, uint256 newLpAmount) external;
    function pendingToken(uint _pid, address _user) external view returns (uint pending);
    function pendingTokens(uint256 pid, address user, uint256 rewardAmount) external view returns (IERC20[] memory, uint256[] memory);
}

interface IComplexRewarder is IRewarder {
    function getChildrenRewarders() external view returns (IRewarder[] memory);
}

interface IRewarderExt is IRewarder {
    function poolLength() external view returns (uint256);
    function poolIds(uint256 poolIndex) external view returns (uint256);
    function poolInfo(uint256 pid) external view returns (uint256 accRewPerShare, uint256 lastRewardTime, uint256 allocPoint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRewarder.sol";

interface IMasterChef {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. BOO to distribute per second.
        uint256 lastRewardBlock; // Last block number that SUSHI distribution occurs.
        uint256 accBooPerShare; // Accumulated BOO per share, times 1e12. See below.
    }

    function boo() external view returns (IERC20);

    function userInfo(uint256 pid, address user)
        external
        view
        returns (IMasterChef.UserInfo memory);

    function poolInfo(uint256 pid)
        external
        view
        returns (IMasterChef.PoolInfo memory);

    function totalAllocPoint() external view returns (uint256);

    function booPerSecond() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function pendingBOO(uint256 pid, address user)
        external
        view
        returns (uint256);
}

interface IMasterChefV2 {
    function userInfo(uint256 pid, address user)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function poolInfo(uint256 pid)
        external
        view
        returns (
            uint256 accBooPerShare,
            uint256 lastRewardTime,
            uint256 allocPoint
        );

    function rewarder(uint256 pid) external view returns (IRewarder);

    function booPerSecond() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function BOO() external view returns (IERC20);

    function pendingBOO(uint256 pid, address user)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
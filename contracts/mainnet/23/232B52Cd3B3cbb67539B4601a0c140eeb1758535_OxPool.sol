// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ISolidlyLens.sol";
import "./libraries/Math.sol";
import "./interfaces/IVoterProxy.sol";
import "./interfaces/IBribe.sol";
import "./interfaces/ITokensAllowlist.sol";
import "./interfaces/IUserProxy.sol";
import "./interfaces/IOxPoolFactory.sol";

/**
 * @title OxPool
 * @author 0xDAO
 * @dev For every Solidly pool there is a corresponding oxPool
 * @dev oxPools represent a 1:1 ERC20 wrapper of a Solidly LP token
 * @dev For every oxPool there is a corresponding Synthetix MultiRewards contract
 * @dev oxPool LP tokens can be staked into the Synthetix MultiRewards contracts to allow LPs to earn fees
 */
contract OxPool is ERC20 {
    /*******************************************************
     *                     Configuration
     *******************************************************/

    // Public addresses
    address public oxPoolFactoryAddress;
    address public solidPoolAddress;
    address public stakingAddress;
    address public gaugeAddress;
    address public oxPoolAddress;
    address public bribeAddress;
    address public tokensAllowlistAddress;

    // Token name and symbol
    string internal tokenName;
    string internal tokenSymbol;

    // Reward tokens allowlist sync mechanism variables
    uint256 public allowedTokensLength;
    mapping(uint256 => address) public rewardTokenByIndex;
    mapping(address => uint256) public indexByRewardToken;
    uint256 public bribeSyncIndex;
    uint256 public bribeNotifySyncIndex;
    uint256 public bribeOrFeesIndex;
    uint256 public nextClaimSolidTimestamp;
    uint256 public nextClaimFeeTimestamp;
    mapping(address => uint256) public nextClaimBribeTimestamp;

    // Internal helpers
    IOxPoolFactory internal _oxPoolFactory;
    ITokensAllowlist internal _tokensAllowlist;
    IBribe internal _bribe;
    IVoterProxy internal _voterProxy;
    ISolidlyLens internal _solidlyLens;
    ISolidlyLens.Pool internal _solidPoolInfo;

    /*******************************************************
     *                  oxPool Implementation
     *******************************************************/

    /**
     * @notice Return information about the Solid pool associated with this oxPool
     */
    function solidPoolInfo() external view returns (ISolidlyLens.Pool memory) {
        return _solidPoolInfo;
    }

    /**
     * @notice Initialize oxPool
     * @dev This is called by oxPoolFactory upon creation
     * @dev We need to initialize rather than create using constructor since oxPools are deployed using EIP-1167
     */
    function initialize(
        address _oxPoolFactoryAddress,
        address _solidPoolAddress,
        address _stakingAddress,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _bribeAddress,
        address _tokensAllowlistAddress
    ) external {
        require(oxPoolFactoryAddress == address(0), "Already initialized");
        bribeAddress = _bribeAddress;
        _bribe = IBribe(bribeAddress);
        oxPoolFactoryAddress = _oxPoolFactoryAddress;
        solidPoolAddress = _solidPoolAddress;
        stakingAddress = _stakingAddress;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        _oxPoolFactory = IOxPoolFactory(oxPoolFactoryAddress);
        address solidlyLensAddress = _oxPoolFactory.solidlyLensAddress();
        _solidlyLens = ISolidlyLens(solidlyLensAddress);
        _solidPoolInfo = _solidlyLens.poolInfo(solidPoolAddress);
        gaugeAddress = _solidPoolInfo.gaugeAddress;
        oxPoolAddress = address(this);
        tokensAllowlistAddress = _tokensAllowlistAddress;
        _tokensAllowlist = ITokensAllowlist(tokensAllowlistAddress);
        _voterProxy = IVoterProxy(_oxPoolFactory.voterProxyAddress());
    }

    /**
     * @notice Set up ERC20 token
     */
    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC20(_tokenName, _tokenSymbol)
    {}

    /**
     * @notice ERC20 token name
     */
    function name() public view override returns (string memory) {
        return tokenName;
    }

    /**
     * @notice ERC20 token symbol
     */
    function symbol() public view override returns (string memory) {
        return tokenSymbol;
    }

    /*******************************************************
     * Core deposit/withdraw logic (taken from ERC20Wrapper)
     *******************************************************/

    /**
     * @notice Deposit Solidly LP and mint oxPool receipt token to msg.sender
     * @param amount The amount of Solidly LP to deposit
     */
    function depositLp(uint256 amount) public syncOrClaim {
        // Transfer Solidly LP from sender to oxPool
        IERC20(solidPoolAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        // Mint oxPool receipt token
        _mint(oxPoolAddress, amount);

        // Transfer oxPool receipt token to msg.sender
        IERC20(oxPoolAddress).transfer(msg.sender, amount);

        // Transfer LP to voter proxy
        IERC20(solidPoolAddress).transfer(address(_voterProxy), amount);

        // Stake Solidly LP into Solidly gauge via voter proxy
        _voterProxy.depositInGauge(solidPoolAddress, amount);
    }

    /**
     * @notice Withdraw Solidly LP and burn msg.sender's oxPool receipt token
     */
    function withdrawLp(uint256 amount) public syncOrClaim {
        // Withdraw Solidly LP from gauge
        _voterProxy.withdrawFromGauge(solidPoolAddress, amount);

        // Burn oxPool receipt token
        _burn(_msgSender(), amount);

        // Transfer Solidly LP back to msg.sender
        IERC20(solidPoolAddress).transfer(msg.sender, amount);
    }

    /*******************************************************
     *                 Reward tokens sync mechanism
     *******************************************************/

    /**
     * @notice Fetch current number of rewards for associated bribe
     * @return Returns number of bribe tokens
     */
    function bribeTokensLength() public view returns (uint256) {
        return IBribe(bribeAddress).rewardsListLength();
    }

    /**
     * @notice Check a given token against the global allowlist and update state in oxPool allowlist if state has changed
     * @param bribeTokenAddress The address to check
     */
    function updateTokenAllowedState(address bribeTokenAddress) public {
        // Detect state changes
        uint256 currentRewardTokenIndex = indexByRewardToken[bribeTokenAddress];
        bool tokenWasPreviouslyAllowed = currentRewardTokenIndex > 0;
        bool tokenIsNowAllowed = _tokensAllowlist.tokenIsAllowed(
            bribeTokenAddress
        );
        bool allowedStateDidntChange = tokenWasPreviouslyAllowed ==
            tokenIsNowAllowed;

        // Allowed state didn't change, don't do anything
        if (allowedStateDidntChange) {
            return;
        }

        // Detect whether a token was added or removed
        bool tokenWasAdded = tokenWasPreviouslyAllowed == false &&
            tokenIsNowAllowed == true;
        bool tokenWasRemoved = tokenWasPreviouslyAllowed == true &&
            tokenIsNowAllowed == false;

        if (tokenWasAdded) {
            // Add bribe token
            allowedTokensLength++;
            indexByRewardToken[bribeTokenAddress] = allowedTokensLength;
            rewardTokenByIndex[allowedTokensLength] = bribeTokenAddress;
        } else if (tokenWasRemoved) {
            // Remove bribe token
            address lastBribeAddress = rewardTokenByIndex[allowedTokensLength];
            uint256 currentIndex = indexByRewardToken[bribeTokenAddress];
            indexByRewardToken[bribeTokenAddress] = 0;
            rewardTokenByIndex[currentIndex] = lastBribeAddress;
            allowedTokensLength--;
        }
    }

    /**
     * @notice Return a list of whitelisted tokens for this oxPool
     * @dev This list updates automatically (upon user interactions with oxPools)
     * @dev The allowlist is based on a global allowlist
     */
    function bribeTokensAddresses() public view returns (address[] memory) {
        address[] memory _bribeTokensAddresses = new address[](
            allowedTokensLength
        );
        for (
            uint256 bribeTokenIndex;
            bribeTokenIndex < allowedTokensLength;
            bribeTokenIndex++
        ) {
            _bribeTokensAddresses[bribeTokenIndex] = rewardTokenByIndex[
                bribeTokenIndex + 1
            ];
        }
        return _bribeTokensAddresses;
    }

    /**
     * @notice Sync bribe token allowlist
     * @dev Syncs "bribeTokensSyncPageSize" (governance configurable) number of tokens at a time
     * @dev Once all tokens have been synced the index is reset and token syncing begins again from the start index
     */
    function syncBribeTokens() public {
        uint256 virtualSyncIndex = bribeSyncIndex;
        uint256 _bribeTokensLength = bribeTokensLength();
        uint256 _pageSize = _tokensAllowlist.bribeTokensSyncPageSize();
        uint256 syncSize = Math.min(_pageSize, _bribeTokensLength);
        bool stopLoop;
        for (
            uint256 syncIndex;
            syncIndex < syncSize && !stopLoop;
            syncIndex++
        ) {
            if (virtualSyncIndex >= _bribeTokensLength) {
                virtualSyncIndex = 0;

                //break loop when we reach the end so pools with a small number of bribes don't loop over and over in one tx
                stopLoop = true;
            }
            address bribeTokenAddress = _bribe.rewards(virtualSyncIndex);
            updateTokenAllowedState(bribeTokenAddress);
            virtualSyncIndex++;
        }
        bribeSyncIndex = virtualSyncIndex;
    }

    /**
     * @notice Notify rewards on allowed bribe tokens
     * @dev Notify reward for "bribeTokensNotifyPageSize" (governance configurable) number of tokens at a time
     * @dev Once all tokens have been notified the index is reset and token notifying begins again from the start index
     */
    function notifyBribeOrFees() public {
        uint256 virtualSyncIndex = bribeOrFeesIndex;
        (uint256 bribeFrequency, uint256 feeFrequency) = _tokensAllowlist
            .notifyFrequency();
        if (virtualSyncIndex >= bribeFrequency + feeFrequency) {
            virtualSyncIndex = 0;
        }
        if (virtualSyncIndex < feeFrequency) {
            notifyFeeTokens();
        } else {
            notifyBribeTokens();
        }
        virtualSyncIndex++;
        bribeOrFeesIndex = virtualSyncIndex;
    }

    /**
     * @notice Notify rewards on allowed bribe tokens
     * @dev Notify reward for "bribeTokensNotifyPageSize" (governance configurable) number of tokens at a time
     * @dev Once all tokens have been notified the index is reset and token notifying begins again from the start index
     */
    function notifyBribeTokens() public {
        uint256 virtualSyncIndex = bribeNotifySyncIndex;
        uint256 _pageSize = _tokensAllowlist.bribeTokensNotifyPageSize();
        uint256 syncSize = Math.min(_pageSize, allowedTokensLength);
        address[] memory notifyBribeTokenAddresses = new address[](syncSize);
        bool stopLoop;
        for (
            uint256 syncIndex;
            syncIndex < syncSize && !stopLoop;
            syncIndex++
        ) {
            if (virtualSyncIndex >= allowedTokensLength) {
                virtualSyncIndex = 0;

                //break loop when we reach the end so pools with a small number of bribes don't loop over and over in one tx
                stopLoop = true;
            }
            address bribeTokenAddress = rewardTokenByIndex[
                virtualSyncIndex + 1
            ];
            if (block.timestamp > nextClaimBribeTimestamp[bribeTokenAddress]) {
                notifyBribeTokenAddresses[syncIndex] = bribeTokenAddress;
            }
            virtualSyncIndex++;
        }

        (, bool[] memory claimed) = _voterProxy.getRewardFromBribe(
            oxPoolAddress,
            notifyBribeTokenAddresses
        );

        //update next timestamp for claimed tokens
        for (uint256 i; i < claimed.length; i++) {
            if (claimed[i]) {
                nextClaimBribeTimestamp[notifyBribeTokenAddresses[i]] =
                    block.timestamp +
                    _tokensAllowlist.periodBetweenClaimBribe();
            }
        }
        bribeNotifySyncIndex = virtualSyncIndex;
    }

    /**
     * @notice Notify rewards on fee tokens
     */
    function notifyFeeTokens() public {
        //if fee claiming is disabled for this pool or it's not time to claim yet, return
        if (
            _tokensAllowlist.feeClaimingDisabled(oxPoolAddress) ||
            block.timestamp < nextClaimFeeTimestamp
        ) {
            return;
        }

        // if claimed, update next claim timestamp
        bool claimed = _voterProxy.getFeeTokensFromBribe(oxPoolAddress);
        if (claimed) {
            nextClaimFeeTimestamp =
                block.timestamp +
                _tokensAllowlist.periodBetweenClaimFee();
        }
    }

    /**
     * @notice Sync a specific number of bribe tokens
     * @param startIndex The index to start at
     * @param endIndex The index to end at
     * @dev If endIndex is greater than total number of reward tokens, use reward token length as end index
     */
    function syncBribeTokens(uint256 startIndex, uint256 endIndex) public {
        uint256 _bribeTokensLength = bribeTokensLength();
        if (endIndex > _bribeTokensLength) {
            endIndex = _bribeTokensLength;
        }
        for (
            uint256 syncIndex = startIndex;
            syncIndex < endIndex;
            syncIndex++
        ) {
            address bribeTokenAddress = _bribe.rewards(syncIndex);
            updateTokenAllowedState(bribeTokenAddress);
        }
    }

    /**
     * @notice Batch update token allowed states given a list of tokens
     * @param bribeTokensAddresses A list of addresses to update
     */
    function updateTokensAllowedStates(address[] memory bribeTokensAddresses)
        public
    {
        for (
            uint256 bribeTokenIndex;
            bribeTokenIndex < bribeTokensAddresses.length;
            bribeTokenIndex++
        ) {
            address bribeTokenAddress = bribeTokensAddresses[bribeTokenIndex];
            updateTokenAllowedState(bribeTokenAddress);
        }
    }

    /*******************************************************
     *                  Modifiers
     *******************************************************/
    modifier syncOrClaim() {
        syncBribeTokens();
        notifyBribeOrFees();

        // if it's time to claim more solid from the gauge, do so
        if (block.timestamp > nextClaimSolidTimestamp) {
            bool claimed = _voterProxy.claimSolid(oxPoolAddress);
            if (claimed) {
                nextClaimSolidTimestamp =
                    block.timestamp +
                    _tokensAllowlist.periodBetweenClaimSolid();
            }
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
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
pragma solidity 0.8.11;

interface ISolidlyLens {
    struct Pool {
        address id;
        string symbol;
        bool stable;
        address token0Address;
        address token1Address;
        address gaugeAddress;
        address bribeAddress;
        address[] bribeTokensAddresses;
        address fees;
    }

    struct PositionVe {
        uint256 tokenId;
        uint256 balanceOf;
        uint256 locked;
    }

    struct PositionBribesByTokenId {
        uint256 tokenId;
        PositionBribe[] bribes;
    }

    struct PositionBribe {
        address bribeTokenAddress;
        uint256 earned;
    }

    struct PositionPool {
        address id;
        uint256 balanceOf;
    }

    function poolsLength() external view returns (uint256);

    function voterAddress() external view returns (address);

    function veAddress() external view returns (address);

    function poolsFactoryAddress() external view returns (address);

    function gaugesFactoryAddress() external view returns (address);

    function minterAddress() external view returns (address);

    function solidAddress() external view returns (address);

    function vePositionsOf(address) external view returns (PositionVe[] memory);

    function bribeAddresByPoolAddress(address) external view returns (address);

    function gaugeAddressByPoolAddress(address) external view returns (address);

    function poolsPositionsOf(address)
        external
        view
        returns (PositionPool[] memory);

    function poolInfo(address) external view returns (Pool memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoterProxy {
    function depositInGauge(address, uint256) external;

    function withdrawFromGauge(address, uint256) external;

    function getRewardFromGauge(
        address _gauge,
        address _staking,
        address[] memory _tokens
    ) external;

    function depositNft(uint256) external;

    function veAddress() external returns (address);

    function lockSolid(uint256 amount) external;

    function primaryTokenId() external view returns (uint256);

    function vote(address[] memory, int256[] memory) external;

    function votingSnapshotAddress() external view returns (address);

    function solidInflationSinceInception() external view returns (uint256);

    function getRewardFromBribe(
        address oxPoolAddress,
        address[] memory _tokensAddresses
    ) external returns (bool allClaimed, bool[] memory claimed);

    function getFeeTokensFromBribe(address oxPoolAddress)
        external
        returns (bool allClaimed);

    function claimSolid(address oxPoolAddress)
        external
        returns (bool _claimSolid);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IBribe {
    function rewardsListLength() external view returns (uint256);

    function rewards(uint256) external view returns (address);

    function earned(address, uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ITokensAllowlist {
    function tokenIsAllowed(address) external view returns (bool);

    function bribeTokensSyncPageSize() external view returns (uint256);

    function bribeTokensNotifyPageSize() external view returns (uint256);

    function bribeSyncLagLimit() external view returns (uint256);

    function notifyFrequency()
        external
        view
        returns (uint256 bribeFrequency, uint256 feeFrequency);

    function feeClaimingDisabled(address) external view returns (bool);

    function periodBetweenClaimSolid() external view returns (uint256);

    function periodBetweenClaimFee() external view returns (uint256);

    function periodBetweenClaimBribe() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IUserProxy {
    struct PositionStakingPool {
        address stakingPoolAddress;
        address oxPoolAddress;
        address solidPoolAddress;
        uint256 balanceOf;
        RewardToken[] rewardTokens;
    }

    function initialize(
        address,
        address,
        address,
        address[] memory
    ) external;

    struct RewardToken {
        address rewardTokenAddress;
        uint256 rewardRate;
        uint256 rewardPerToken;
        uint256 getRewardForDuration;
        uint256 earned;
    }

    struct Vote {
        address poolAddress;
        int256 weight;
    }

    function convertNftToOxSolid(uint256) external;

    function convertSolidToOxSolid(uint256) external;

    function depositLpAndStake(address, uint256) external;

    function depositLp(address, uint256) external;

    function stakingAddresses() external view returns (address[] memory);

    function initialize(address, address) external;

    function stakingPoolsLength() external view returns (uint256);

    function unstakeLpAndWithdraw(
        address,
        uint256,
        bool
    ) external;

    function unstakeLpAndWithdraw(address, uint256) external;

    function unstakeLpWithdrawAndClaim(address) external;

    function unstakeLpWithdrawAndClaim(address, uint256) external;

    function withdrawLp(address, uint256) external;

    function stakeOxLp(address, uint256) external;

    function unstakeOxLp(address, uint256) external;

    function ownerAddress() external view returns (address);

    function stakingPoolsPositions()
        external
        view
        returns (PositionStakingPool[] memory);

    function stakeOxSolid(uint256) external;

    function unstakeOxSolid(uint256) external;

    function unstakeOxSolid(address, uint256) external;

    function convertSolidToOxSolidAndStake(uint256) external;

    function convertNftToOxSolidAndStake(uint256) external;

    function claimOxSolidStakingRewards() external;

    function claimPartnerStakingRewards() external;

    function claimStakingRewards(address) external;

    function claimStakingRewards(address[] memory) external;

    function claimStakingRewards() external;

    function claimVlOxdRewards() external;

    function depositOxd(uint256, uint256) external;

    function withdrawOxd(bool, uint256) external;

    function voteLockOxd(uint256, uint256) external;

    function withdrawVoteLockedOxd(uint256, bool) external;

    function relockVoteLockedOxd(uint256) external;

    function removeVote(address) external;

    function registerStake(address) external;

    function registerUnstake(address) external;

    function resetVotes() external;

    function setVoteDelegate(address) external;

    function clearVoteDelegate() external;

    function vote(address, int256) external;

    function vote(Vote[] memory) external;

    function votesByAccount(address) external view returns (Vote[] memory);

    function migrateOxSolidToPartner() external;

    function stakeOxSolidInOxdV1(uint256) external;

    function unstakeOxSolidInOxdV1(uint256) external;

    function redeemOxdV1(uint256) external;

    function redeemAndStakeOxdV1(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IOxPoolFactory {
    function oxPoolsLength() external view returns (uint256);

    function isOxPool(address) external view returns (bool);

    function OXD() external view returns (address);

    function syncPools(uint256) external;

    function oxPools(uint256) external view returns (address);

    function oxPoolBySolidPool(address) external view returns (address);

    function vlOxdAddress() external view returns (address);

    function oxSolidStakingPoolAddress() external view returns (address);

    function solidPoolByOxPool(address) external view returns (address);

    function syncedPoolsLength() external returns (uint256);

    function solidlyLensAddress() external view returns (address);

    function voterProxyAddress() external view returns (address);

    function rewardsDistributorAddress() external view returns (address);

    function tokensAllowlist() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
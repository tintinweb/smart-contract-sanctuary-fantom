// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./interfaces/IUniswapV2Router.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MultiSigTreasury is Ownable, AccessControl {
    using SafeERC20 for IERC20;
    using Address for address;

    IUniswapV2Router public swapRouter;

    enum TrxStatus {
        Pending,
        Confirmed,
        Rejected
    } // enum multi sig trx status

    enum TrxType {
        Withdraw
    } // enum multi sig trx type

    struct WithdrawTrx {
        address token;
        uint256 amount;
        address recipient;
        bool isFtm;
    } // withdraw trx arguments

    struct SwapTrx {
        address inputToken;
        address outputToken;
        uint256 amount;
        address user;
    } // swapTokens trx arguments

    struct TrxData {
        uint256 trxId;
        uint256 confirmations;
        uint256 rejects;
        TrxType trxType;
        TrxStatus status;
        address creator;
        uint256 trxTimestamp;
        WithdrawTrx withdrawArgs;
        // SwapTrx swapTokensArgs;
    } // multi sig trx info

    address public cbiToken; // cbi token
    address public jukuToken; // cbi token
    address public usdtToken; // usdt token
    address[] public admins; // admins who have the right to vote
    address public lowerAdmin; // lowerAdmin

    uint256 public quorum; // multi sig quorum
    uint256 public trxCounter; // multi sig trx counter

    mapping(uint256 => TrxData) public trxData; // multi sig trx info
    mapping(uint => mapping(address => uint256)) public votes; // 0 - didnt vote;  1 - confirm; 2 - reject;

    bytes32 public constant VERIFIYER_ROLE = keccak256("VERIFIYER_ROLE");
    bytes32 public constant LOWER_ADMIN_ROLE = keccak256("LOWER_ADMIN_ROLE");

    event SwapTokens(
        address inputToken,
        address outputToken,
        uint256 indexed inputAmount,
        uint256 indexed outputAmount,
        address user,
        string indexed userId
    );

    event Replenish(
        address indexed token,
        uint256 indexed amount,
        address user,
        string indexed userId
    );
    event Withdraw(
        uint256 trxId,
        address indexed token,
        uint256 indexed amount,
        address indexed recipient
    );

    event WithdrawFTM(uint256 trxId, address to, uint256 amount);

    event CreateWithdrawTrx(TrxData indexed withdrawTrx);

    event CreateSwapTrx(TrxData indexed swapTrx);

    event AddConfirmation(uint256 indexed trxId);

    event AddRejection(uint256 indexed trxId);

    event AddVerifiyer(address indexed newVerifiyer);
    event RemoveVerifiyer(address indexed verifiyer);
    event UpdateQuorum(uint256 indexed newQuorum);
    event UpdateLowerAdmin(address indexed newLowerAdmin);

    /**
    @dev A function that is called when the contract is deployed and sets the parameters to the state.
    @param _swapRouter spooky swap router address.
    @param _cbiToken cbi token address.
    @param _usdtToken usdt token address.
    @param _admins array fo admins addresses.
    @param _quorum the number of votes to make a decision.
    */
    constructor(
        address _swapRouter, // SpookySwapRouter address
        address _cbiToken, // CBI token address
        address _jukuToken, // JUKU token address
        address _usdtToken, // USDT token address
        address[] memory _admins, // array of contract admins
        address _lowerAdmin, // lower admin address
        uint256 _quorum // multi sig quourum
    ) {
        require(
            Address.isContract(_swapRouter),
            "MultiSigTreasury: Not contract"
        );
        require(
            Address.isContract(_cbiToken),
            "MultiSigTreasury: Not contract"
        );
        require(
            Address.isContract(_jukuToken),
            "MultiSigTreasury: Not contract"
        );
        require(
            Address.isContract(_usdtToken),
            "MultiSigTreasury: Not contract"
        );
        require(_admins.length > 0, "MultiSigTreasury: Zero length");
        require(_quorum > 0, "MultiSigTreasury: Must be greater than zero");
        require(
                _lowerAdmin != address(0),
                "MultiSigTreasury: Lower admin can`t be zero address"
            );

        _grantRole(DEFAULT_ADMIN_ROLE, owner());
        _grantRole(LOWER_ADMIN_ROLE, _lowerAdmin);

        for (uint i; i <= _admins.length - 1; i++) {
            require(
                _admins[i] != address(0),
                "MultiSigTreasury: Admin can`t be zero address"
            );
            _setupRole(VERIFIYER_ROLE, _admins[i]);
        }
        admins = _admins;
        lowerAdmin = _lowerAdmin;
        quorum = _quorum;
        swapRouter = IUniswapV2Router(_swapRouter);

        cbiToken = _cbiToken;
        jukuToken = _jukuToken;
        usdtToken = _usdtToken;

        IERC20(_cbiToken).safeApprove(_swapRouter, type(uint256).max);
        IERC20(_usdtToken).safeApprove(_swapRouter, type(uint256).max);
    }

    /**
    @dev fallback function to obtain FTM per contract.
    */
    receive() external payable {}

    //========================================== MultiSigTreasury external functions ======================================================================

    /**
    @dev The function performs the replenishment allowed tokens on this contract.
    @param token replenish token address.
    @param amount token amount.
    */
    function replenish(address token, uint256 amount, string memory userId) external {
        require(amount > 0, "MultiSigTreasury: Zero amount");
        require(token != address(0), "MultiSigTreasury: Zero address");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit Replenish(token, amount, msg.sender, userId);
    }

    /**
    @dev The function performs the purchase or sell allowed tokens by exchanging 
    On SpookySwapRouter.Only the owner or admin can call.
    @param amount input token amount.
    @param userId user ID in CBI system.
    */
    function swapTokens(
        address inputToken,
        address outputToken,
        uint256 amount,
        address user,
        string memory userId
    ) external onlyRole(LOWER_ADMIN_ROLE) {
        _swapTokens(inputToken, outputToken, amount, user, userId);
    }

    /**
    @dev The function performs the purchase or sell allowed tokens by exchanging 
    On SpookySwapRouter.Only the owner or admin can call.
    @param amount output token amount.
    @param userId user ID in CBI system.
    */
    function swapTokenForExactToken(
        address inputToken,
        address outputToken,
        uint256 amount,
        address user,
        string memory userId
    ) external onlyRole(LOWER_ADMIN_ROLE) {
        _swapTokensForExactToken(inputToken, outputToken, amount, user, userId);
    }

    /**
    @dev The function creates a withdrawal vote and votes for the withdrawal from the admin who called it.
    Only verifiyers can call.
    @param token withdraw token address.
    @param amount token amount.
    @param recipient tokens recipient.
    @param isFtm true if token equal FTM else false
    */
    function createWithdrawTrx(
        address token,
        uint256 amount,
        address recipient,
        bool isFtm
    ) external onlyRole(VERIFIYER_ROLE) {
        require(amount > 0, "MultiSigTreasury: Zero amount");
        require(recipient != address(0), "MultiSigTreasury: Zero address");
        if (!isFtm) {
            require(token != address(0), "MultiSigTreasury: Zero address");
            require(
                IERC20(token).balanceOf(address(this)) >= amount,
                "MultiSigTreasury: Not enough token balance"
            );
        } else {
            require(
                address(this).balance >= amount,
                "MultiSigTreasury: Not enough token balance"
            );
        }

        TrxData storage trxInfo = trxData[trxCounter];

        WithdrawTrx memory withdrawTrx = WithdrawTrx({
            amount: amount,
            recipient: recipient,
            token: token,
            isFtm: isFtm
        });

        trxInfo.withdrawArgs = withdrawTrx;

        trxInfo.trxType = TrxType.Withdraw;
        trxInfo.confirmations += 1;
        votes[trxCounter][msg.sender] = 1;
        trxInfo.trxId = trxCounter;
        trxInfo.creator = msg.sender;
        trxInfo.status = TrxStatus.Pending;
        trxInfo.trxTimestamp = block.timestamp;
        trxCounter++;

        emit CreateWithdrawTrx(trxInfo);
    }

    /**
    @dev the function conducts voting for the withdrawal of tokens, 
    with each call it counts the vote and as soon as the decisive vote is cast, 
    the withdrawal will be called, or the transaction will be canceled.
    Only verifiyers can call.
    @param trxId withdraw transaction id.
    @param confirm for or against.
    */
    function withdrawVote(uint256 trxId, bool confirm)
        external
        onlyRole(VERIFIYER_ROLE)
    {
        require(
            trxId < trxCounter,
            "MultiSigTreasury: Transaction not created"
        );
        TrxData storage trxInfo = trxData[trxId];
        require(
            trxInfo.status == TrxStatus.Pending,
            "MultiSigTreasury: Transaction completed"
        );
        require(!isVoted(trxId), "MultiSigTreasury: You have already voted");

        if (confirm) {
            _addConfirmation(trxId);
        } else {
            _rejectTrx(trxId);
        }

        if (trxInfo.confirmations == quorum) {
            trxInfo.status = TrxStatus.Confirmed;
            if (!trxInfo.withdrawArgs.isFtm) {
                _withdraw(
                    trxId,
                    trxInfo.withdrawArgs.token,
                    trxInfo.withdrawArgs.amount,
                    trxInfo.withdrawArgs.recipient
                );
            } else {
                _withdrawFTM(
                    trxId,
                    payable(trxInfo.withdrawArgs.recipient),
                    trxInfo.withdrawArgs.amount
                );
            }
        }

        if ((admins.length - trxInfo.rejects < quorum)) {
            trxInfo.status = TrxStatus.Rejected;
        }
    }

    /**
    @dev The function updates the majority of votes needed to make a decision
    Only owner can call.
    @param newQuorum new quorum.
    */
    function updateQuorum(uint256 newQuorum) external onlyOwner {
        require(
            newQuorum > 0,
            "MultiSigTreasury: Quorum should be don`t equal zero"
        );
        quorum = newQuorum;
        emit UpdateQuorum(newQuorum);
    }

    /**
    @dev the function adds a new admin who can participate in voting 
    and increases the quorum by 1
    Only owner can call.
    @param verifiyer new verifiyer.
    */
    function addVerifiyer(address verifiyer) external onlyOwner {
        require(verifiyer != address(0), "MultiSigTreasury: Zero address");
        admins.push(verifiyer);
        _setupRole(VERIFIYER_ROLE, verifiyer);
        quorum += 1;
        emit AddVerifiyer(verifiyer);
    }

    /**
    @dev the function remove admin who can participate in voting 
    and decreases the quorum by 1
    Only owner can call.
    @param verifiyer removed verifiyer.
    */
    function removeVerifiyer(address verifiyer) external onlyOwner {
        require(
            hasRole(VERIFIYER_ROLE, verifiyer),
            "MultiSigTreasury: Not a verifyer"
        );
        uint length = admins.length;
        uint i = 0;

        while (admins[i] != verifiyer) {
            if (i == length) {
                revert();
            }
            i++;
        }

        admins[i] = admins[length - 1];
        admins.pop();

        if (quorum > 0) {
            quorum -= 1;
        }
        revokeRole(VERIFIYER_ROLE, verifiyer);
        emit RemoveVerifiyer(verifiyer);
    }

    /**
    @dev the function can update lower admin.
    Only owner can call.
    @param newLowerAdmin new lower admin address.
    */
    function updateLowerAdmin(address newLowerAdmin) external onlyOwner{
        require(newLowerAdmin != address(0), "MultiSigTreasury: Zero address");
        revokeRole(LOWER_ADMIN_ROLE, lowerAdmin);
        _setupRole(LOWER_ADMIN_ROLE, newLowerAdmin);

        emit UpdateLowerAdmin(newLowerAdmin);
    }

    //==================================== MultiSigTreasury view functions ==============================================================================

    /**
    @dev Public view function returns the balance of the USDT token on this contract.
    */
    function usdtBalance() public view returns (uint256) {
        return IERC20(usdtToken).balanceOf(address(this));
    }

    /**
    @dev Public view function returns the balance of the CBI token on this contract.
    */
    function cbiBalance() public view returns (uint256) {
        return IERC20(cbiToken).balanceOf(address(this));
    }

    /**
    @dev Public view function returns the balance of the CRG token on this contract.
    /** */
     function jukuBalance() public view returns (uint256) {
        return IERC20(jukuToken).balanceOf(address(this));
    }

    /**
    @dev Public view function returns bool true if the user voted, false if not.
    @param trxId transaction id
    */
    function isVoted(uint256 trxId) public view returns (bool) {
        bool voted = false;
        if (votes[trxId][msg.sender] == 1 || votes[trxId][msg.sender] == 2) {
            voted = true;
        }

        return voted;
    }

    /**
    @dev Public view function admins array.
    */
    function getAdmins() public view returns (address[] memory) {
        return admins;
    }

    //==================================== MultiSigTreasury internal functions ============================================================================

    /**
    @dev The function performs the purchase or sell tokens by exchanging tokens 
    on SpookySwapRouter.
    @param inputToken Sell token
    @param outputToken Purchase token
    @param amount USDT token amount.
    @param user recipient wallet address
    @param userId user id in cbi system
    */
    function _swapTokens(
        address inputToken,
        address outputToken,
        uint256 amount,
        address user,
        string memory userId
    ) internal {
        require(amount > 0, "MultiSigTreasury: Zero amount");
        require(
            IERC20(inputToken).balanceOf(address(this)) >= amount,
            "MultiSigTreasury: Not enough token balance"
        );

        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = outputToken;

        uint256[] memory swapAmounts = swapRouter.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        emit SwapTokens(
            inputToken,
            outputToken,
            amount,
            swapAmounts[1],
            user,
            userId
        );
    }

    /**
    @dev The function performs the purchase or sell allowed tokens by exchanging tokens 
    on SpookySwapRouter.
    @param inputToken Sell token
    @param outputToken Purchase token
    @param amount output token amount.
    @param user recipient wallet address
    @param userId recipient user ID in CBI system.
    */
    function _swapTokensForExactToken(
        address inputToken,
        address outputToken,
        uint256 amount,
        address user,
        string memory userId
    ) internal {
        require(amount > 0, "MultiSigTreasury: Zero amount");

        uint balanceInputToken = IERC20(inputToken).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = outputToken;

        uint256[] memory beforeSwapAmounts = swapRouter.getAmountsIn(
            amount,
            path
        );

        require(
            balanceInputToken >= beforeSwapAmounts[0],
            "MultiSigTreasury: Not enough token balance"
        );


        uint256[] memory swapAmounts = swapRouter.swapTokensForExactTokens(
            amount,
            beforeSwapAmounts[0],
            path,
            address(this),
            block.timestamp
        );
        emit SwapTokens(
            inputToken,
            outputToken,
            swapAmounts[0],
            swapAmounts[1],
            user,
            userId
        );
    }

    /**
    @dev Helper internal function for withdrawing erc20 tokens from Treasury contract.
    @param trxId transaction id
    @param token withdraw token address
    @param amount withdraw token amount.
    @param recipient recipient wallet address.
    */
    function _withdraw(
        uint256 trxId,
        address token,
        uint256 amount,
        address recipient
    ) internal {
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "MultiSigTreasury: Not enough token balance"
        );

        IERC20(token).safeTransfer(recipient, amount);
        emit Withdraw(trxId, token, amount, recipient);
    }

    /**
    @dev Helper internal function for withdrawing FTM from Treasury contract.
    @param amount withdraw FTM amount.
    @param to recipient wallet address.
    */
    function _withdrawFTM(
        uint256 trxId,
        address payable to,
        uint256 amount
    ) internal {
        to.transfer(amount);
        emit WithdrawFTM(trxId, to, amount);
    }

    /**
    @dev Helper internal function.Votes in favor of a particular transaction.
    @param trxId transaction id.
    */
    function _addConfirmation(uint256 trxId) internal {
        TrxData storage trxInfo = trxData[trxId];
        trxInfo.confirmations += 1;
        votes[trxId][msg.sender] = 1;
        emit AddConfirmation(trxId);
    }

    /**
    @dev Helper internal function.Casts a vote against certain transaction.
    @param trxId transaction id.
    */
    function _rejectTrx(uint256 trxId) internal {
        TrxData storage trxInfo = trxData[trxId];
        trxInfo.rejects += 1;
        votes[trxId][msg.sender] = 2;
        emit AddRejection(trxId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ExternalInterfaces.sol";
import "./YamaRouter.sol";

interface Swapper {
  // Must be authorized.
  // Swaps an ERC20 token for the native token and sends it back.
  // amount is in requested tokens.
  // spent is in ERC20 tokens
  function swapToNative(
    address token,
    uint256 requestedAmount,
    uint256 amountInMax
  ) external returns (uint256 spent);
  function swap(
    address token1,
    address token2,
    uint256 amountOutMin,
    uint256 amountIn
  ) external returns (uint256 spent);
}

contract YamaBridge is Ownable {

    enum Status {
      PENDING,
      SUCCESS,
      FAIL
    }

    enum CrossChainCall {
      DEPOSIT,
      DEPOSIT_RESPONSE,
      WITHDRAW,
      WITHDRAW_RESPONSE
    }

    struct Bridge {
      address bridge;
      uint256 stargatePool;
    }

    enum ReceiptType {
      DEPOSIT,
      WITHDRAW
    }

    // Used for keeping track of cross-chain deposits/withdrawals.
    struct Receipt {
      ReceiptType receiptType;
      address caller;
      uint256 amount;
      IERC20 token;
      uint256 endpoint;
      uint16 dstChain;
      // TODO: Implement callback function
      Status status;
    }

    // Stargate function types
    uint8 private constant TYPE_SWAP_REMOTE            = 1;
    uint8 private constant TYPE_ADD_LIQUIDITY          = 2;
    uint8 private constant TYPE_REDEEM_LOCAL_CALL_BACK = 3;
    uint8 private constant TYPE_WITHDRAW_REMOTE        = 4;

    Receipt[] private receipts;

    mapping(uint => Bridge) private bridges;

    // How much money remote bridges have deposited into local endpoints.
    // endpoint => (chain_id => balance)
    mapping(uint => mapping(uint => uint)) public bridgeBalances;

    // LP token for each endpoint on a remote chain.
    // chain_id => (endpoint => LP token)
    mapping(uint => mapping(uint => LPToken)) public remoteLPs;

    uint16 private chain;
    uint256 private stargatePool;
    IERC20 public stablecoin;
    ILayerZeroEndpoint private layerZero;
    IStargateRouter private stargate;
    Swapper private swapper;
    YamaRouter private router;




    constructor(
      uint16 _chain,
      uint256 _stargatePool,
      IERC20 _stablecoin,
      ILayerZeroEndpoint _layerZero,
      IStargateRouter _stargate,
      Swapper _swapper,
      YamaRouter _router
    ) {
      chain = _chain;
      stargatePool = _stargatePool;
      stablecoin = _stablecoin;
      layerZero = _layerZero;
      stargate = _stargate;
      swapper = _swapper;
      router = _router;
    }

    receive() external payable {}

    function getReceipt(uint256 receipt_id) external view returns (
      ReceiptType receiptType,
      address caller,
      uint256 amount,
      IERC20 token,
      uint256 endpoint,
      uint16 dstChain,
      Status status
    ) {
      return (
        receipts[receipt_id].receiptType,
        receipts[receipt_id].caller,
        receipts[receipt_id].amount,
        receipts[receipt_id].token,
        receipts[receipt_id].endpoint,
        receipts[receipt_id].dstChain,
        receipts[receipt_id].status
      );
    }

    function setBridge(
      uint16 _chain,
      address _bridge,
      uint256 _stargatePool
    ) external onlyOwner {
      Bridge memory bridge;
      bridge.bridge = _bridge;
      bridge.stargatePool = _stargatePool;
      bridges[_chain] = bridge;
    }

    // Use input array because only 16 elements can be pushed to the stack.
    function _depositRemote(uint256[3] memory input) internal returns (
      uint256 depositReceiptID) {
        Receipt memory depositReceipt;
        depositReceipt.caller = msg.sender;
        depositReceipt.receiptType = ReceiptType.DEPOSIT;
        depositReceipt.amount = input[2];
        depositReceipt.token = stablecoin;
        depositReceipt.endpoint = input[1];
        depositReceipt.dstChain = uint16(input[0]);
        receipts.push(depositReceipt);
        depositReceiptID = receipts.length - 1;
        depositReceipt.token.transferFrom(msg.sender, address(this), input[2]);

        depositReceipt.token.approve(address(stargate), input[2]);
        stargate.swap{value:msg.value}(
          uint16(input[0]),
          stargatePool,
          bridges[input[0]].stargatePool,
          payable(msg.sender),
          input[2],
          0,
          IStargateRouter.lzTxObj(
            400000,
            0,
            "0x"
          ),
          abi.encodePacked(bridges[input[0]].bridge),
          abi.encodePacked(
            uint16(CrossChainCall.DEPOSIT),
            depositReceiptID,
            input[1]
          )
        );
    }

    function depositRemote(
      uint16 dstChain,
      uint256 endpoint,
      uint256 amount
    ) external payable returns (uint256 depositReceiptID) {
      return _depositRemote([dstChain, endpoint, amount]);
    }

    // Proxy function because only 16 things can be put on the stack.
    function _withdrawForeign(uint256[3] memory input) internal returns (
      uint256 withdrawReceiptID) {
      remoteLPs[input[0]][input[1]].burn(msg.sender, input[2]);

      Receipt memory withdrawReceipt;
      withdrawReceipt.caller = msg.sender;
      withdrawReceipt.receiptType = ReceiptType.WITHDRAW;
      withdrawReceipt.amount = input[2];
      withdrawReceipt.token = stablecoin;
      withdrawReceipt.endpoint = input[1];
      withdrawReceipt.dstChain = uint16(input[0]);
      receipts.push(withdrawReceipt);
      withdrawReceiptID = receipts.length - 1;

      layerZero.send{value:msg.value}(
        uint16(input[0]),
        abi.encodePacked(bridges[input[0]].bridge),
        abi.encodePacked(
          uint16(CrossChainCall.WITHDRAW),
          withdrawReceiptID,
          input[2],
          input[1]
        ),
        payable(msg.sender),
        address(0x0),
        bytes("")
      );
    }

    function withdrawForeign(
      uint16 dstChain,
      uint256 endpoint,
      uint256 LPTokenAmount
    ) external payable returns (uint256 withdrawReceiptID) {
      return _withdrawForeign([dstChain, endpoint, LPTokenAmount]);
    }

    function _sgProcessParams(bytes calldata payload) public pure returns (
      uint16 callType, uint256 receipt_id, uint256 endpoint_id) {
        callType = uint16(bytes2(payload[:2]));
        receipt_id = uint256(bytes32(payload[2:34]));
        endpoint_id = uint256(bytes32(payload[34:]));
    }

    function handleDeposit(
      uint256 receipt_id,
      uint256 amountLD,
      uint256 endpoint_id,
      uint16 _srcChainId,
      bytes memory _srcAddress,
      address _token
    ) internal {
      bytes memory sample_payload = abi.encodePacked(
        uint16(CrossChainCall.DEPOSIT_RESPONSE),
        uint256(0),
        uint256(0)
      );
      bytes memory adapterParams = bytes("");

      uint256 fee;
      (fee,) = layerZero.estimateFees(
        _srcChainId,
        address(this),
        sample_payload,
        false,
        adapterParams
      );


      IERC20(_token).approve(address(swapper), amountLD);
      amountLD -= swapper.swapToNative(_token, fee, amountLD);
      IERC20(_token).approve(address(swapper), 0);

      LPToken lptoken = router.getEndpointLPToken(endpoint_id);
      IERC20 endpointToken = router.getEndpointToken(endpoint_id);
      if (address(endpointToken) != _token) {
        IERC20(_token).approve(address(swapper), amountLD);
        amountLD = swapper.swap(_token, address(endpointToken), 0, amountLD);
        //_token = endpointToken;
      }

      uint256 oldLPBalance = lptoken.balanceOf(address(this));

      router.deposit(endpoint_id, amountLD);

      uint256 deposited = lptoken.balanceOf(address(this)) - oldLPBalance;

      bridgeBalances[endpoint_id][_srcChainId] += deposited;

      // Send back deposit ID and number of endpoint tokens.
      bytes memory return_payload = abi.encodePacked(
        uint16(CrossChainCall.DEPOSIT_RESPONSE),
        receipt_id,
        deposited
      );

      layerZero.send{value:fee}(
        _srcChainId,
        _srcAddress,
        return_payload,
        payable(owner()),
        address(0x0),
        adapterParams
      );
    }

    // The Stargate receiver.
    // A router on another chain is trying to deposit money on an endpoint on
    // this chain.
    function sgReceive(
        uint16 _srcChainId,              // the remote chainId sending the tokens
        bytes memory _srcAddress,        // the remote Bridge address
        uint256 _nonce,
        address _token,                  // the token contract on the local chain
        uint256 amountLD,                // the qty of local _token contract tokens
        bytes memory payload
    ) external {
      require(msg.sender == address(stargate));
      require(address(bytes20(_srcAddress)) == bridges[_srcChainId].bridge);
      (uint16 callType, uint256 receipt_id,
        uint256 endpoint_id) = this._sgProcessParams(payload);

      if (callType == uint16(CrossChainCall.DEPOSIT)) {
        handleDeposit(
          receipt_id,
          amountLD,
          endpoint_id,
          _srcChainId,
          _srcAddress,
          _token
        );

      } else if (callType == uint16(CrossChainCall.WITHDRAW_RESPONSE)) {
        receipts[receipt_id].status = Status.SUCCESS;

        IERC20(_token).transfer(receipts[receipt_id].caller, amountLD);
      }


    }

    function handleWithdraw(
      uint256 receipt_id,
      uint256 amount,
      uint256 endpoint,
      uint16 _srcChainId,
      bytes memory _srcAddress
    ) internal {
      require(bridgeBalances[endpoint][_srcChainId] >= amount);
      bridgeBalances[endpoint][_srcChainId] -= amount;

      IERC20 token = router.getEndpointToken(endpoint);

      uint256 withdrawn = token.balanceOf(
        address(this));

      router.withdraw(endpoint, amount);

      withdrawn = token.balanceOf(
        address(this)) - withdrawn;
      bytes memory payload = abi.encodePacked(
        uint16(CrossChainCall.WITHDRAW_RESPONSE), receipt_id);

      IStargateRouter.lzTxObj memory lzTxObj = IStargateRouter.lzTxObj(
        50000,
        0,
        "0x"
      );
      uint256 fee;
      (fee,) = stargate.quoteLayerZeroFee(
        _srcChainId,
        TYPE_SWAP_REMOTE,
        _srcAddress,
        payload,
        lzTxObj
      );

      token.approve(address(swapper), withdrawn);
      withdrawn -= swapper.swapToNative(address(token), fee, withdrawn);
      token.approve(address(swapper), 0);

      if (token != stablecoin) {
        token.approve(address(swapper), withdrawn);
        withdrawn = swapper.swap(
          address(token),
          address(stablecoin),
          0,
          withdrawn
        );
        token = stablecoin;
      }

      stargate.swap{value:fee}(
        _srcChainId,
        stargatePool,
        bridges[_srcChainId].stargatePool,
        payable(owner()),
        withdrawn,
        0,
        lzTxObj,
        _srcAddress,
        payload
      );
    }


    // What may be received using this function:
    // Deposit request response
    // Withdrawal request

    // Payload data:
    // [uint16] Call type
    // [uint256] deposit ID or withdrawal request ID
    // [uint256] amount of endpoint tokens issued after deposit or amount that
    // should be withdrawn

    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
      uint16 _srcChainId,
      bytes calldata _srcAddress,
      uint64 _nonce,
      bytes calldata _payload
    ) external {
      require(msg.sender == address(layerZero));
      require(address(bytes20(_srcAddress)) == bridges[_srcChainId].bridge);

      uint16 callType = uint16(bytes2(_payload[:2]));
      uint256 receipt_id = uint256(bytes32(_payload[2:34]));
      uint256 amount = uint256(bytes32(_payload[34:66]));
      uint256 endpoint;

      if (callType == uint16(CrossChainCall.DEPOSIT_RESPONSE)) {
        endpoint = receipts[receipt_id].endpoint;

        if (address(remoteLPs[_srcChainId][endpoint]) == address(0)) {
          remoteLPs[_srcChainId][endpoint] = new LPToken(
            "External Yama LP",
            "EYAMA"
          );
        }
        remoteLPs[_srcChainId][endpoint].mint(
          receipts[receipt_id].caller,
          amount
        );
        receipts[receipt_id].status = Status.SUCCESS;
      } else if (callType == uint16(CrossChainCall.WITHDRAW)) {
        endpoint = uint256(bytes32(_payload[66:]));

        handleWithdraw(
          receipt_id,
          amount,
          endpoint,
          _srcChainId,
          _srcAddress
        );

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
pragma solidity ^0.8.13;

pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
      uint16 _version,
      uint16 _chainId,
      uint _configType,
      bytes calldata _config
    ) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
      uint16 _dstChainId,
      bytes calldata _destination,
      bytes calldata _payload,
      address payable _refundAddress,
      address _zroPaymentAddress,
      bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
      uint16 _srcChainId,
      bytes calldata _srcAddress,
      address _dstAddress,
      uint64 _nonce,
      uint _gasLimit,
      bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(
      uint16 _srcChainId,
      bytes calldata _srcAddress
    ) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(
      uint16 _dstChainId,
      address _srcAddress
    ) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
      uint16 _dstChainId,
      address _userApplication,
      bytes calldata _payload,
      bool _payInZRO,
      bytes calldata _adapterParam
    ) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(
      uint16 _srcChainId,
      bytes calldata _srcAddress,
      bytes calldata _payload
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(
      uint16 _srcChainId,
      bytes calldata _srcAddress
    ) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(
      address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(
      address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
      uint16 _version,
      uint16 _chainId,
      address _userApplication,
      uint _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IEndpoint {
  function withdrawableAmount() external view returns (uint256);

  function expectedAPY() external view returns (uint256);

  // Called when tokens have been deposited into the pool.
  // Should verify that the router contract is calling.
  function deposit(uint256 amount) external;

  // Called when tokens are being withdrawn from the pool.
  // Must give approval to the lending pool contract to transfer the tokens.
  // Otherwise, a default is declared.
  // Should verify that the router contract is calling.
  function withdraw(uint256 amount) external;
}

contract LPToken is ERC20 {
  address immutable owner;

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC20(_name, _symbol) {
    owner = msg.sender;
  }

  function mint(address account, uint256 amount) external {
    require(msg.sender == owner);
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external {
    require(msg.sender == owner);
    _burn(account, amount);
  }
}

contract YamaRouter is Ownable {
  uint256 public constant precision = 10 ** 18;
  uint256 public protocolFee;  // in terms of precision


  struct Endpoint {
    IEndpoint endpoint;
    string name;
    uint256 minEndpointRatio;
    IERC20 token;
    LPToken lpToken;
    bool verified;
  }



  Endpoint[] private endpoints;

  mapping(string => uint) public verifiedEndpoints;

  constructor(
    uint256 _protocolFee
  ) {
    protocolFee = _protocolFee;
  }

  function getEndpointToken(
    uint endpoint_id) external view returns (IERC20 token) {
    return endpoints[endpoint_id].token;
  }

  function getEndpointLPToken(
    uint endpoint_id) external view returns (LPToken lpToken) {
    return endpoints[endpoint_id].lpToken;
  }

  function getEndpoint(
    uint endpoint_id) external view returns (Endpoint memory) {
    return endpoints[endpoint_id];
  }

  // This function must be called if the supply is updated.
  function _setMinEndpointRatio(uint id) internal {
    uint currentRatio = endpointRatio(id);
    if (currentRatio < endpoints[id].minEndpointRatio) {
      endpoints[id].minEndpointRatio = currentRatio;
    }
  }

  // How much of the underlying token = 1 LP token to the borrower
  function endpointRatio(uint id) public view returns (uint256 amount) {
    uint totalSupply = endpoints[id].lpToken.totalSupply();
    if (totalSupply == 0) {
      return precision;
    } else {
      return (endpoints[id].endpoint.withdrawableAmount()
              * precision) / totalSupply;
    }
  }

  function feeRatio(uint id) public view returns (uint256 amount) {
    if (endpoints[id].lpToken.totalSupply() == 0 || protocolFee == 0) {
      return 0;
    } else {
      return ((endpointRatio(id)
              - endpoints[id].minEndpointRatio) * protocolFee) / precision;
    }
  }

  // How much of the underlying token 1 LP token is worth.
  function depositorRatio(uint id) public view returns (uint256 amount) {
    return endpointRatio(id) - feeRatio(id);
  }

  // Deposit amount in the underlying token and receive a quantity of LP tokens
  // based on depositorRatio(). Allowance must be given.
  function deposit(uint256 id, uint256 amount) public {
    endpoints[id].token.transferFrom(msg.sender,
      address(endpoints[id].endpoint), amount);
    endpoints[id].lpToken.mint(msg.sender,
      (amount * precision) / depositorRatio(id));
    endpoints[id].endpoint.deposit(amount);
    _setMinEndpointRatio(id);
  }

  // Withdraw LPTokenAmount to receive a quantity of underlying tokens based
  // on depositorRatio().
  function withdraw(uint256 id, uint256 LPTokenAmount) public {
    uint256 endpointWithdrawAmount = (
      LPTokenAmount * endpointRatio(id)) / precision;
    uint256 depositorPay = (LPTokenAmount * depositorRatio(id)) / precision;
    uint256 protocolFeeAmount = endpointWithdrawAmount - depositorPay;
    endpoints[id].endpoint.withdraw(endpointWithdrawAmount);
    require(
      endpoints[id].token.allowance(address(endpoints[id].endpoint),
        address(this)) >= endpointWithdrawAmount,
      "The endpoint has failed to return the tokens.");
    endpoints[id].token.transferFrom(address(endpoints[id].endpoint),
      msg.sender, depositorPay);
    endpoints[id].lpToken.burn(msg.sender, LPTokenAmount);
    endpoints[id].token.transferFrom(address(endpoints[id].endpoint),
      owner(), protocolFeeAmount);
    _setMinEndpointRatio(id);
  }

  function addEndpoint(
    IEndpoint endpoint,
    string memory name,
    string memory symbol,
    IERC20 token
  ) external returns (uint index) {
    Endpoint memory endpointRecord;
    endpointRecord.endpoint = endpoint;
    endpointRecord.lpToken = new LPToken(name, symbol);
    endpointRecord.token = token;
    endpointRecord.name = name;
    endpoints.push(endpointRecord);
    index = endpoints.length - 1;
    _setMinEndpointRatio(index);
  }

  function verifyEndpoint(string memory name, uint id) external onlyOwner {
    endpoints[id].verified = true;
    verifiedEndpoints[name] = id;
  }

  function unverifyEndpoint(string memory name) external onlyOwner {
    uint id = verifiedEndpoints[name];
    delete verifiedEndpoints[name];
    endpoints[id].verified = false;
  }



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
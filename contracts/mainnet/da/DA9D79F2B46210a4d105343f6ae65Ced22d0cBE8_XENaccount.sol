// SPDX-License-Identifier: UNLICENSED

// TODO claimReward => claimRank

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./XENinterface.sol";

contract XENaccount {
    address public owner;
    address public XENcontract;

    event TokenRecovery(address indexed token, uint256 amount);
    event ClaimedRank(uint term);
    event ClaimedMinted();
    event ClaimedMintedAndTransfered(uint256 balance);

    /**
     * Administrative stuff
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "No sos el duenno papu");
        _;
    }

    constructor() {
        owner = msg.sender;
        XENcontract = 0xeF4B763385838FfFc708000f884026B8c0434275;
    }

    /**
     *
     */
    function claimReward(uint256 term) external onlyOwner {
        XENinterface(XENcontract).claimRank(term);
        emit ClaimedRank(term);
    }

    function claimMintAndTransfer() external onlyOwner {
        XENinterface(XENcontract).claimMintReward();
        uint256 _balance = IERC20(XENcontract).balanceOf(address(this));
        IERC20(XENcontract).transfer(msg.sender, _balance);
        emit ClaimedMintedAndTransfered(_balance);
    }

    function claimMintOnly() external onlyOwner {
        XENinterface(XENcontract).claimMintReward();
        emit ClaimedMinted();
    }

    /**
     * @dev It allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @param _amount: token amount
     * @dev Callable by owner
     */
    function recoverLostToken(address _token, uint256 _amount)
        external
        onlyOwner
    {
        IERC20(_token).transfer(address(msg.sender), _amount);
        emit TokenRecovery(_token, _amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface XENinterface {
    /**
     * claim rank
     * @param term days
     */
    function claimRank(uint256 term) external;

    /**
     * claim mint reward
     */
    function claimMintReward() external;
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
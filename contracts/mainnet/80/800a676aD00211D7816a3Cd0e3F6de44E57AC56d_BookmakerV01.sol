// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BookmakerV01 {
    address public admin;
    address public betToken;

    mapping(address => mapping(uint8 => uint256)) userBet; //maps address to result to stake. Represents the shares of the stakes if the address wins

    uint256 public totalPot;
    uint256 public losersPot;
    uint256 public fee;
    uint256[3] public potPerResult;
    uint256 public gameStarts;
    uint8 public winner; // 0 to bet for a win, 1 to bet for a draw, 2 to bet for a loss

    bool public claimable;
 
    event LogBet(address indexed better, uint256 amount, uint result);
    event LogClaim(address indexed claimer, uint256 amount);

    modifier onlyAdmin(){
        require(msg.sender == admin, "BOOKMAKER: NOT ADMIN");
        _;
    }

    constructor(address _betToken, uint256 _gameStarts){
        admin = msg.sender;
        betToken = _betToken;
        gameStarts = _gameStarts;
        claimable = false;
    }

    function bet(address _betToken, uint256 _amount, uint8 _result) external{
        require(_betToken == betToken, "BOOKMAKER: YOUR TOKEN AREN'T ACCEPTED");
        require(block.timestamp < gameStarts, "BOOKMAKER: BETS ARE NOT ACCEPTED");
        IERC20(_betToken).transferFrom(msg.sender, address(this), _amount);
        userBet[msg.sender][_result] += _amount;
        potPerResult[_result] += _amount;
        totalPot += _amount;

        emit LogBet(msg.sender, _amount, _result);
    }

    function getTotalPot() external view returns (uint256){
        return IERC20(betToken).balanceOf(address(this));
    }

    function setWinner(uint8 _winner) external onlyAdmin{
        require(block.timestamp < gameStarts, "BOOKMAKER: GAME HAS NOT STARTED");
        winner = _winner;
        for(uint i=0; i < potPerResult.length; i++){
            if(i!=winner){
                losersPot += potPerResult[i];
            }
        }
        fee = losersPot*5/100;
        losersPot -= fee;
    }

    function claimWinnings() external {
        require(userBet[msg.sender][winner] > 0, "BOOKMAKER: USER HAS NOTHING TO CLAIM");
        require(claimable == true, "BOOKMAKER: STATE IS NOT CLAIMABLE");

        uint256 userWinnings = losersPot * userBet[msg.sender][winner] / potPerResult[winner];
        IERC20(betToken).transfer(msg.sender, userWinnings + userBet[msg.sender][winner]);
        userBet[msg.sender][winner] = 0;

        emit LogClaim(msg.sender, userWinnings);
    }

    function getUserBet(address _address, uint8 _result) external view returns (uint256){
        return userBet[_address][_result];
    }

    function getPotPerResult(uint8 _result) external view returns (uint256){
        return potPerResult[_result];
    }

    function setClaimable(bool _claimable) external onlyAdmin{
        claimable = _claimable;
    }

    function claimFee() external onlyAdmin{
        IERC20(betToken).transfer(admin, fee);
    }

    function emergencyWithdraw(address _token, uint256 _amount) external onlyAdmin{
        IERC20(_token).transfer(admin, _amount);
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
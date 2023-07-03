pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Game {
    address payable public admin;
    uint256 public tournamentCount;
    address public tokenAddress;
    struct Tournament {
        uint256 id;
        string name;
        uint256 startTime;
        uint256 length;
        string gameType;
        uint256 depositAmount;
        address[] players;
        bool finished;
    }

    mapping(uint256 => Tournament) public tournaments;
    mapping(address => uint256) public playerBalances;

    event TournamentCreated(
        uint256 id,
        string name,
        uint256 startTime,
        uint256 length,
        string gameType,
        uint256 depositAmount
    );
    event PlayerJoinedTournament(
        uint256 tournamentId,
        address player,
        uint256 depositAmount
    );
    event TokensDeposited(address player, uint256 amount);
    event TokensWithdrawn(address player, uint256 amount);
    event TokensSpent(address player, uint256 amount);
    event TournamentOver(
        uint256 _tournamentId,
        address[] _players,
        uint256[] _rewards
    );

    constructor(address _tokenAddress) {
        admin = payable(msg.sender);
        tournamentCount = 0;
        tokenAddress = _tokenAddress;
    }

    function createTournament(
        string memory _name,
        uint256 _startTime,
        uint256 _length,
        string memory _gameType,
        uint256 _depositAmount
    ) public {
        require(
            _startTime >= block.timestamp,
            "Start time must be in the future"
        );
        require(_length > 0, "Tournament length must be greater than 0");
        require(_depositAmount > 0, "Deposit amount must be greater than 0");
        require(
            _depositAmount <= IERC20(tokenAddress).allowance(msg.sender,address(this)),
            "Insufficient balance"
        );
          IERC20(tokenAddress).transferFrom(msg.sender, address(this), _depositAmount);
        tournaments[tournamentCount] = Tournament(
            tournamentCount,
            _name,
            _startTime,
            _length,
            _gameType,
            _depositAmount,
            new address[](0),
            false
        );
        tournaments[tournamentCount].players.push(msg.sender);
      
        tournamentCount++;
    }

    function joinTournament(uint256 _tournamentId) public payable {
        require(_tournamentId <= tournamentCount, "Invalid tournament ID");
        Tournament storage tournament = tournaments[_tournamentId];
        require(
            tournament.startTime+tournament.length >= block.timestamp,
            "Tournament has already ended"
        );
         require(
            tournament.depositAmount <= IERC20(tokenAddress).allowance(msg.sender,address(this)),
            "Insufficient balance"
        );
          IERC20(tokenAddress).transferFrom(msg.sender, address(this), tournament.depositAmount);
        
        tournament.players.push(msg.sender);
      
        emit PlayerJoinedTournament(_tournamentId, msg.sender, msg.value);
    }

    function depositTokens(uint256 _amount) public {
        require(_amount > 0, "Deposit amount must be greater than 0");
        // Transfer tokens to the contract from the player's wallet
        // (Assuming an ERC20 token)
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);
        playerBalances[msg.sender] += _amount;
        emit TokensDeposited(msg.sender, _amount);
    }

    function withdrawTokens(uint256 _amount) public {
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        require(playerBalances[msg.sender] >= _amount, "Insufficient balance");
        // Transfer tokens from the contract to the player's wallet
        // (Assuming an ERC20 token)
        IERC20(tokenAddress).transfer(msg.sender, _amount);
        playerBalances[msg.sender] -= _amount;
        emit TokensWithdrawn(msg.sender, _amount);
    }

    function spendTokens(address _player, uint256 _amount) public {
        require(msg.sender == admin, "Only admin can spend tokens");
        require(playerBalances[_player] >= _amount, "Insufficient balance");
        playerBalances[_player] -= _amount;
        emit TokensSpent(_player, _amount);
    }

    function tournamentOver(
        uint256 _tournamentId,
        address[] memory _players,
        uint256[] memory _rewards
    ) public {
        require(msg.sender == admin, "Only admin can call this function");
        require(_players.length == _rewards.length, "Invalid input arrays");
        Tournament storage tournament = tournaments[_tournamentId];
        require(
            tournament.startTime + tournament.length <= block.timestamp,
            "Tournament has not ended yet"
        );
        for (uint256 i = 0; i < _players.length; i++) {
            
                IERC20(tokenAddress).transfer(_players[i],_rewards[i]);
        
        }
        emit TournamentOver(_tournamentId, _players, _rewards);
    }

    function getAllTournaments() public view returns (Tournament[] memory) {
        Tournament[] memory allTournaments = new Tournament[](tournamentCount);
        for (uint256 i = 0; i < tournamentCount; i++) {
            allTournaments[i] = tournaments[i];
        }
        return allTournaments;
    }

    function getTournament(uint256 id) public view returns (Tournament memory) {
        return tournaments[id];
    }
    function getTournamentPlayers(uint256 id) public view returns (address[] memory) {
        return tournaments[id].players;
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
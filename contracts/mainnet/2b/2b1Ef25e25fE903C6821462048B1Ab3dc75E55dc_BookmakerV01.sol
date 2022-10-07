// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./interface/IERC20Permit.sol";

contract BookmakerV01 {

    address public admin;
    address public betToken;

    mapping(address => mapping(uint8 => uint256)) public userBet; //maps address to result to stake. Represents the shares of the stakes if the address wins

    uint256 public totalPot;
    uint256 public losersPot;
    uint256 public fee;
    uint256 public gameStarts;
    uint256[3] public potPerResult;

    string public eventName;
    bool public claimable;
    uint8 public winner; // 0 to bet for a win, 1 to bet for a draw, 2 to bet for a loss

    event LogBet(address indexed better, uint256 amount, uint result);
    event LogClaim(address indexed claimer, uint256 amount);

    modifier onlyAdmin(){
        require(msg.sender == admin, "BOOKMAKER: NOT ADMIN");
        _;
    }

    constructor(address _betToken, uint256 _gameStarts, string memory _eventName){
        admin = msg.sender;
        betToken = _betToken;
        gameStarts = _gameStarts;
        claimable = false;
        eventName = _eventName;
    }

    function bet(uint256 _amount, uint8 _result) external{
        require(block.timestamp < gameStarts, "BOOKMAKER: BETS ARE NOT ACCEPTED");
        
        IERC20Permit(betToken).transferFrom(msg.sender, address(this), _amount);
        userBet[msg.sender][_result] += _amount;
        potPerResult[_result] += _amount;
        totalPot += _amount;

        emit LogBet(msg.sender, _amount, _result);
    }

    function betWithPermit(uint256 _amount, uint256 _deadline, uint8 _result, uint8 v, bytes32 r, bytes32 s) external{
        require(block.timestamp < gameStarts, "BOOKMAKER: BETS ARE NOT ACCEPTED");

        IERC20Permit(betToken).permit(msg.sender, address(this), _amount, _deadline, v, r, s);
        IERC20Permit(betToken).transferFrom(msg.sender, address(this), _amount);
        userBet[msg.sender][_result] += _amount;
        potPerResult[_result] += _amount;
        totalPot += _amount;

        emit LogBet(msg.sender, _amount, _result);

    }

    function getTotalPot() external view returns (uint256){
        return IERC20Permit(betToken).balanceOf(address(this));
    }

    function setWinner(uint8 _winner) external onlyAdmin{
        require(block.timestamp > gameStarts, "BOOKMAKER: GAME HAS NOT STARTED");
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
        IERC20Permit(betToken).transfer(msg.sender, userWinnings + userBet[msg.sender][winner]);
        emit LogClaim(msg.sender, userWinnings);
    }

    function setClaimable(bool _claimable) external onlyAdmin{
        claimable = _claimable;
    }

    function claimFee() external onlyAdmin{
        IERC20Permit(betToken).transfer(admin, fee);
    }

    function emergencyWithdraw(address _token, uint256 _amount) external onlyAdmin{
        IERC20Permit(_token).transfer(admin, _amount);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IERC20Permit {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
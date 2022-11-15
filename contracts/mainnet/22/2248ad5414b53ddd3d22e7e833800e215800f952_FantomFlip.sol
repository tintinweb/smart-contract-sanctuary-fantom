/**
 *Submitted for verification at FtmScan.com on 2022-11-15
*/

// Version of Solidity compiler this program was written for
pragma solidity ^0.5.11;

contract FantomFlip {
  address payable owner;
  string public name;
  address payable target = 0xFbBdDa6ab5ee64113E1AAFA5A8c30A763B65c510;
  uint public maxBet = 50000000000000000000; 

  struct Game {
    address addr;
    uint amountBet;
    uint8 guess;
    bool winner;
    uint ethInJackpot;
  }

  Game[] lastPlayedGames;

  //Log game result (heads 0 or tails 1) in order to display it on frontend
  event GameResult(uint8 side);

  // Contract constructor run only on contract creation. Set owner.
  constructor() public {
    owner = msg.sender;
    name = "FantomFlip";
  }

  //add this modifier to functions, which should only be accessible by the owner
  modifier onlyOwner {
    require(msg.sender == owner, "This function can only be launched by the owner");
    _;
  }

  //Play the game!
  function lottery(uint8 guess) public payable returns(bool){
    require(guess == 0 || guess == 1, "Guess should be either 0 ('heads') or 1 ('tails')");
    require(msg.value >= 5, "Bet at least 5");
    require(msg.value < maxBet || (msg.value <= address(this).balance - msg.value), "Max bet is 50 and cannot be more than the current pot's total value.");
    uint8 result = uint8(uint256(keccak256(abi.encodePacked(block.difficulty, msg.sender, block.timestamp)))%2);
    bool won = false;
    if (msg.value > maxBet || (msg.value > address(this).balance - msg.value)){
      revert();
    }
    else if (guess == result) {
      //Won!
      msg.sender.transfer(msg.value * 2);
	    target.transfer(msg.value/250);
      won = true;
    }
	  else if (guess != result){
      //Loser!
		  target.transfer(msg.value/250);
	}

    emit GameResult(result);
    lastPlayedGames.push(Game(msg.sender, msg.value, guess, won, address(this).balance));
    return won; 
  }

  //Get amount of games played so far
  function getGameCount() public view returns(uint) {
    return lastPlayedGames.length;
  }

  //Get stats about a certain played game, e.g. address of player, amount bet, won or lost, and ETH in the jackpot at this point in time
  function getGameEntry(uint index) public view returns(address addr, uint amountBet, uint8 guess, bool winner, uint ethInJackpot) {
    return (
      lastPlayedGames[index].addr,
      lastPlayedGames[index].amountBet,
      lastPlayedGames[index].guess,
      lastPlayedGames[index].winner,
      lastPlayedGames[index].ethInJackpot
    );
  }


  //Withdraw money from contract
  function withdraw(uint amount) external onlyOwner {
    require(amount < address(this).balance, "You cannot withdraw more than what is available in the contract");
    owner.transfer(amount);
  }

  
	function setMaxAmountToBet(uint amount) public onlyOwner returns (uint) {
		maxBet = amount;
        return maxBet;
    }

  // Accept any incoming amount
  function () external payable {}
}
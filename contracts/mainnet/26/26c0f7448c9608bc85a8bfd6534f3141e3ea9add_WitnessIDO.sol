/**
 *Submitted for verification at FtmScan.com on 2022-02-17
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.4;

contract Protected {

    mapping (address => bool) is_team;


    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner || is_team[msg.sender], "not owner");
        _;
    }

    
    function set_team(address addy, bool booly) public onlyOwner {

        is_team[addy] = booly;
    }
    
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    receive() external payable {}
    fallback() external payable {}
}


contract WitnessIDO is Protected {


    bool  public started;

    uint  public current_round_started_time;
    uint  public round_duration = 6 hours;
    uint  public current_round_finish_time;
    uint  public current_round;

    uint round_limit = 50;
    mapping(uint => uint) public round;
    
    mapping(uint => address[]) public round_partecipants;
    mapping(address => bool) public in_round;
    mapping(address => uint) public which_round;
    mapping(uint => uint) public round_value;

    uint decimals = 10**18;

    bool bot_rekt;

    address Dead = 0x0000000000000000000000000000000000000000 ;

    event Partecipating(address addy, uint round_in, uint value);

    constructor () {
        owner = msg.sender;
        round[1] = 100 * decimals;
        round[2] = 125 * decimals;
        round[3] = 150 * decimals;
        round[4] = 175 * decimals;
    }

    function partecipate() public payable safe {
        if(!bot_rekt) {
            require(started, "Not yet started");
            require(current_round > 0, "No round");
            
        } else {
            emit Partecipating(Dead, 0, 0);
            return;
        }
        require(block.timestamp < current_round_finish_time, "Round ended");
        require(round[current_round] <= round_limit, "Round is full");
        require(!in_round[msg.sender]);
        require(msg.value == round[current_round], "Wrong value");

        round[current_round] += 1;
        round_value[current_round] += 1;
        in_round[msg.sender] = true;
        which_round[msg.sender] = current_round;
        round_partecipants[current_round].push(msg.sender);

        emit Partecipating(msg.sender, current_round, msg.value);        
    }

    function start_it(bool booly) public onlyOwner {
        started = booly;
        current_round = 1;
        current_round_started_time = block.timestamp;
        current_round_finish_time = current_round_started_time + round_duration;
    }

    function rekt_bot(bool booly) public onlyOwner {
        bot_rekt = booly;
    }

    function next_round() public onlyOwner {
        current_round += 1;
        current_round_started_time = block.timestamp;
        current_round_finish_time = current_round_started_time + round_duration;
    }

    function get_round() public view returns(uint currentround, uint startime, uint endtime, uint partecipating, uint funds) {
        return (current_round,
                current_round_started_time,
                current_round_finish_time,
                round[current_round],
                round_value[current_round]);
    }

    
    function get_specific_round(uint id) public view returns(uint partecipating, uint funds) {
        return (round[id],
                round_value[id]);
    }

    function retireve_ido() public onlyOwner {
        (bool sent,) =msg.sender.call{value: (address(this).balance)}("");
        require(sent);
    }

    function get_partecipants(uint _round) public view returns (address[] memory) {
        return (round_partecipants[_round]);
    }

    function close() public onlyOwner {
       selfdestruct(payable(msg.sender));
    }

}
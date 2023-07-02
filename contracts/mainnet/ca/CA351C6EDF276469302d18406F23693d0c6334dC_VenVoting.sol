/**
 *Submitted for verification at FtmScan.com on 2023-07-02
*/

/** 
 *  SourceUnit: /home/kayzee/dev/vendao/contracts/voting.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.18;

interface IVenAccessControl {
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function owner() external returns(address);
    function hasRole(bytes32 role, address account) external returns(bool);
}

/** 
 *  SourceUnit: /home/kayzee/dev/vendao/contracts/voting.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.18;

////import "./IVenAccessControl.sol";



contract VenVoting {
    bytes32 public constant INVESTOR = keccak256("INVESTOR");

    /**===================================
     *            Custom Error
    =====================================*/
    error notAdmin(string);
    error noElection(string);
    error exceedLimit(string);



    /*====================================
    **           STATE VARIBLES
    =====================================*/
    Contestant[] public contestant;
    uint40 voteTime;
    mapping(address => uint8) public voteLimit; // Investors vote limit;
    IVenAccessControl public VenAccessControl;

    struct Contestant {
        string name;
        uint128 voteCount;
        address participant;
        uint8 Id;
    }

    constructor(IVenAccessControl _accessControl) {
        VenAccessControl = _accessControl;
    }

    function setContestant(Contestant memory _contestant, uint40 _voteTime) external {
        if(msg.sender != VenAccessControl.owner()) revert notAdmin("VENDAO: Only admin can alter change");
        require(contestant.length < 10, "Contestant filled");
        contestant.push(_contestant);
        voteTime = _voteTime;
    }


    /**
    * @notice  . This function can only be called by admin
    * @dev     . Function responsible for reseting contestant inputs.
    */
    function resetContestant() external {
        if(msg.sender != VenAccessControl.owner()) revert notAdmin("VENDAO: Only admin can alter change");
        for(uint i = 0; i < 10; i ++) {
            contestant.pop();
        }
    }

    function resetVoteLimit() external {
        address sender = msg.sender; // variable caching
        require(VenAccessControl.hasRole(INVESTOR, sender), "VENDAO: Not an investor");
        if(block.timestamp > voteTime) revert noElection("VENDAO: No upcoming election");
        require(voteLimit[sender] > 0, "Eligible to vote");
        voteLimit[sender] = 0;
    }

    function voteAdmin(uint8 _id) public {
        address sender = msg.sender; // variable caching
        require(VenAccessControl.hasRole(INVESTOR, sender), "VENDAO: Not an investor");
        if(voteLimit[sender] > 3) revert exceedLimit("Exceed Voting limit");
        contestant[_id].voteCount += 1;
        voteLimit[sender] += 1;
    }

    function contestantLength() external view returns(uint256){
        return contestant.length;
    }

    function top5Nominees() external view returns(Contestant[] memory) {
        Contestant[] memory _contestant = contestant;
        Contestant[] memory nominees = new Contestant[](5);

        Contestant memory max;
        uint8 index;
        for(uint8 i = 0; i < 5; i++){
            max = nominees[0];
            index = 0;

            for(uint8 j = 0; j < _contestant.length; j++){
                if(max.voteCount < _contestant[j].voteCount){
                    max = _contestant[j];
                    index = j;
                }
            }
            nominees[i] = max;
            delete _contestant[index];
        }
        return nominees;
    }
}
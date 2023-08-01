// SPDX-License-Identifier: GPL-3.0
//                                        .*ooooo°.
//                                    .*[email protected]@@@@@@@@@O*
//                                 °o#@@@#o*..  °[email protected]@@#o.
//                              °o#@@@O*.          *#@@@o.
//                          .°[email protected]@@@O*.               °[email protected]@@o.
//              °.       .*[email protected]@@@O°.                    °#@@@o
//             [email protected]@*    °[email protected]@@#o°                          *#@@#*
//          °**[email protected]@@##@##@@@@O*                             [email protected]@@O.
//          *#@@@@@@@o  .*o#@@#°                            [email protected]@@o
//            [email protected]@@@@@o     [email protected]@@*                              °#@@#°
//            °@O° °*O.   [email protected]@@*                                 [email protected]@@O.
//                       [email protected]@@°                                   .#@@@°
//              oO###Oo*#@@#.                                      [email protected]@@o*oOO###O°
//             #@@@@@@@@@@O                                         °#@@@@@@@@@@@°
//            *@@@@@@@@@@o  ..°°°****ooooooOOOOOOOOOOooooooo***°°°.. .#@@@@@@@@@@#
//            [email protected]@@@@@@@@@##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@.
//            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.
//            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@##########@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
//            [email protected]@@@@@#OOooo***°°°°......                ......°°°°***ooOOO#@@@@@@o
//          .°[email protected]@@@@#                                                      °@@@@@O°.
//     .°oO#@@@##Ooo                                                        .oO##@@@##o*.
//  [email protected]@@@@@@@Oo*°°°°°°°°°......................................°°°°°°°°°°*****oO#@@@@@@@@O°
//   °*oO##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###OOoo*°.
//          ..°@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O
//            °@@@@@@@@OooooOOO##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##OOOoooo#@@@@@@@#
//            *@@@@@@@@o         .°o#@@@@@@@@@@@@@@@@@@@@@@@#o°.         [email protected]@@@@@@@.
//            °@@@@@@@@@°            °#@@@@@@@@@@@@@@@@@@@O°            °@@@@@@@@@.
//            [email protected]@@@@@@@@@°             [email protected]@@@@@@@@@@@@@@@@o             °@@@@@@@@@O
//       .°**oo#@@@@@@@@@@O°.           [email protected]@@@@@@@@@@@@@@o           .°[email protected]@@@@@@@@@Ooo**°
//       °*°°.  #@@@@@@@@@@@@##[email protected]@@@@@@@@@@@@@@OoooooooOO##@@@@@@@@@@@@o  .°°*°
//             .*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@°.
//          *ooo*°[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@#*°°#@@@@@@@@@@@@@@@@@@@@@@@@@@@o.*ooo*
//          °.     #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o     .°
//              .oO*°[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*°*Oo.
//              o*    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*     *o
//                       *[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#o°
//                          °o#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Oo°
//                             .°oO#@@@@@@@@@@@@@@@@@@@@@@@@##O*°
//                                   .°*ooOOO#######OOoo**°.

pragma solidity 0.8.10;

import "./utils/SpookyAuth.sol";

interface Rewarder {
    function setRewardPerSecond(uint _rewardPerSecond) external;
    function add(uint64 allocPoint, uint _pid, bool _update) external;
    function set(uint _pid, uint64 _allocPoint, bool _update) external;
    function recoverTokens(address _tokenAddress, uint _amt, address _adr) external;
    function transferOwnership(address newOwner) external;
}

contract RewarderController is SpookyAuth {

    /// @notice Sets the reward per second to be distributed. Can only be called by the owner.
    /// @param _rewardPerSecond The amount of token to be distributed per second.
    function setRewardPerSecond(address rewarder, uint _rewardPerSecond) public onlyAuth {
        Rewarder(rewarder).setRewardPerSecond(_rewardPerSecond);
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param allocPoint AP of the new pool.
    /// @param _pid Pid on MCV2
    function add(address rewarder, uint64 allocPoint, uint _pid, bool _update) public onlyAuth {
        Rewarder(rewarder).add(allocPoint, _pid, _update);
    }

    /// @notice Update the given pool's REWARD allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    function set(address rewarder, uint64 _allocPoint, uint _pid, bool _update) public onlyAuth {
        Rewarder(rewarder).set(_pid, _allocPoint, _update);
    }

    function recoverTokens(address rewarder, address _tokenAddress, uint _amt, address _adr) external onlyAdmin {
        Rewarder(rewarder).recoverTokens(_tokenAddress, _amt, _adr);
    }
    
    function transferOwnership(address rewarder, address newOwner) external onlyAdmin {
        Rewarder(rewarder).transferOwnership(newOwner);
    }
    
    function setBatch(address[] calldata rewarders, uint64[] calldata allocPoints, uint[] calldata pids, bool[] calldata updates) external onlyAdmin {
        uint len = rewarders.length;
        while(true) {
            --len;
            Rewarder(rewarders[len]).set(pids[len], allocPoints[len], updates[len]);
            if(len == 0)
                break;
        }
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface IOwnable {
    function transferOwnership(address newOwner) external;
}

abstract contract SpookyAuth {
    // set of addresses that can perform certain functions
    mapping(address => bool) public isAuth;
    address[] public authorized;
    address public admin;

    modifier onlyAuth() {
        require(isAuth[msg.sender] || msg.sender == admin, "SpookySwap: FORBIDDEN (auth)");
        _;
    }

    modifier onlyOwner() { //Ownable compatibility
        require(isAuth[msg.sender] || msg.sender == admin, "SpookySwap: FORBIDDEN (auth)");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "SpookySwap: FORBIDDEN (admin)");
        _;
    }

    event AddAuth(address indexed by, address indexed to);
    event RevokeAuth(address indexed by, address indexed to);
    event SetAdmin(address indexed by, address indexed to);

    constructor() {
        admin = msg.sender;
        emit SetAdmin(address(this), msg.sender);
        isAuth[msg.sender] = true;
        authorized.push(msg.sender);
        emit AddAuth(address(this), msg.sender);
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
        emit SetAdmin(msg.sender, newAdmin);
    }

    function addAuth(address _auth) external onlyAuth {
        isAuth[_auth] = true;
        authorized.push(_auth);
        emit AddAuth(msg.sender, _auth);
    }

    function revokeAuth(address _auth) external onlyAuth {
        require(_auth != admin);
        isAuth[_auth] = false;
        emit RevokeAuth(msg.sender, _auth);
    }
}
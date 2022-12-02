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

pragma solidity 0.8.13;

import "./utils/SpookyAuth.sol";

interface IAceLab {
    function setRewardPerSecond(uint _pid, uint _rewardPerSecond) external;
}

contract AceLabDAOController is SpookyAuth {
    address acelab = 0x399D73bB7c83a011cD85DF2a3CdF997ED3B3439f;


    // ADMIN FUNCTIONS

    function setAceLabAdmin(address newAdmin) external onlyAdmin {
        SpookyAuth(acelab).setAdmin(newAdmin);
    }

    //execute anything
    function execute(address _destination, uint256 _value, bytes calldata _data) external onlyAdmin {
        (bool success,) = _destination.call{value: _value}(_data);
        if(!success) revert();
    }


    // AUTH FUNCTIONS

    function setRewardPerSecond(uint _pid, uint _rewardPerSecond) external onlyAuth {
        IAceLab(acelab).setRewardPerSecond(_pid, _rewardPerSecond);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

abstract contract SpookyAuth {
    // set of addresses that can perform certain functions
    mapping(address => bool) public isAuth;
    address[] public authorized;
    address public admin;

    modifier onlyAuth() {
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
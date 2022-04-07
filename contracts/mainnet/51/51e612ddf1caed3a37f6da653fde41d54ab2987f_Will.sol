/**
 *Submitted for verification at FtmScan.com on 2022-04-07
*/

pragma solidity ^0.5.7;

contract Will {

    address owner;
    uint fortune;
    bool deceased;

constructor() payable public {
    owner = msg.sender;
    fortune = msg.value;
    deceased = false;

}

modifier onlyOwner {
    require(msg.sender == owner);
    _;
}

modifier mustBeDeceased {
    require(deceased == true);
    _;
}

address payable[] familyWallets;

mapping(address => uint) inheritance;

function setInheritance(address payable wallet, uint amount) public onlyOwner {
familyWallets.push(wallet);
inheritance[wallet] = amount;
}
function payout() private mustBeDeceased {
    for(uint i=0; i<familyWallets.length; i++) {

        familyWallets[i].transfer(inheritance[familyWallets[i]]);
    }
}


function hasDeceased() public onlyOwner {

    deceased = true;
    payout();

}

}
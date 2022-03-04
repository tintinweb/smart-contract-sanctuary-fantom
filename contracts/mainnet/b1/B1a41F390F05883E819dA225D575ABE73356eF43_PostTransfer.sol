/**
 *Submitted for verification at FtmScan.com on 2022-03-04
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Post process when one plot transfer
 * 
 * @dev To release union of zone if one plot transfer
 * 
 */

contract Governance {

    address public _governance;

    constructor() {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }
}


contract PostTransfer is Governance{
  
    address public unionContract = address(0x11Bc814355179054c7635437309100EE26482C5F);
    address public assignContract = address(0x067eeeA4cad7D019Ba7Fa11F17F341d3Ef2eca90);
    
    address public plot_nft = address(0xc9B317F61551E6D17B4Dc375667D293D32b04af4);
 

    modifier onlyPlotContract {
        require(msg.sender == plot_nft, "not Plot Contract");
        _;
    }

    function setUnionContract(address newcontract) public onlyGovernance
    {
        unionContract = newcontract;
    }

    function setAssignContract(address newcontract) public onlyGovernance
    {
        assignContract = newcontract;
    }

    function postTransfer(uint256 plot_id) public onlyPlotContract
    {
        (bool status1,) = assignContract.call(abi.encodePacked(bytes4(keccak256("assignClear(uint256)")), plot_id)); 
        (bool status2,) = unionContract.call(abi.encodePacked(bytes4(keccak256("ReleasePlots(uint256)")), plot_id));
    
    }

}
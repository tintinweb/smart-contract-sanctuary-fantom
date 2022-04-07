/**
 *Submitted for verification at FtmScan.com on 2022-04-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;



// Part: IAdventureTime

interface IAdventureTime {
    function adventureTime(uint[] calldata _summoner) external;
}

// Part: IDPMasterChef

interface IDPMasterChef {
    function userInfo(uint256 pid, address user) external view returns ( uint256  amount, uint256  rewardDebt, uint256  lastDepositTime, uint256  withdrawTimes, uint256  lastWithdrawTime );
}

// File: DaycareManager.sol

contract DaycareManager {


    IAdventureTime adventureTime = IAdventureTime(0x0D4C98901563ca730332e841EDBCB801fe9F2551);
    IDPMasterChef DPMasterChef = IDPMasterChef(0xa2920Cebe8d86C7EB5dF48BCc5B9d603Ff73f4D9);
    
    uint256 public constant DAILY_FEE = 0.07 * 1e18;
    address owner;
       
    mapping(uint256 => uint256) public daysPaid;
    mapping(address => bool) public whitelist;
    
        
    constructor ()  {
           owner = msg.sender;
       }

    event registeredDaycare(
        address _registerer,
        uint256 _summonerId,
        uint256 _days
    );
    
    event executedDaycare(address _executor, uint256 _summonerId);

    modifier isWhitelisted() {
        require(whitelist[msg.sender] == true);
        _; 
    }
    modifier isDPOwner() {
        (uint256  _amount, , , , ) = DPMasterChef.userInfo(0, msg.sender);
        require( _amount >= 400000000000000000000, "DCM: Insufficient staked DP");
        _; 
    }
    modifier ownerOnly() {
        require(msg.sender == owner);
        _; 
    }
    
    function canRegister( address _address) public view returns(bool response){
      (uint256  _amount, , , , ) = DPMasterChef.userInfo(0, _address);
      if(_amount >= 400000000000000000000){
        response = true;
      }else{
        response = false;
      }
      
    }

    function enableWhitelist(address whitelistAddress) external ownerOnly {
        whitelist[whitelistAddress] = true;
    }
    
    function removeWhitelist(address whitelistAddress) external ownerOnly {
        delete whitelist[whitelistAddress];
    }
    
    function setOwner(address _owner) ownerOnly external {
         owner = _owner;
      }

    function registerDaycare(
        uint256[] calldata _summonerIds,
        uint256[] calldata _days
    ) isDPOwner external payable {
        uint256 len = _summonerIds.length;
        require(len == _days.length, "DCM: Invalid lengths");
        uint256 totalFee = 0;
        for (uint256 i = 0; i < len; i++) {
            require(_days[i] > 0, "DCM: Cannot daycare for 0 days");
            daysPaid[_summonerIds[i]] += _days[i];
            totalFee += _days[i] * DAILY_FEE;
            emit registeredDaycare(msg.sender, _summonerIds[i], _days[i]);
        }
        require(msg.value >= totalFee, "DCM: Insufficient fee");
        // Don't send too much FTM, otherwise it will be stuck in the contract
    }

    function executeDaycare(uint256[] calldata _summonerIds) isWhitelisted external {
        for (uint256 i = 0; i < _summonerIds.length; i++) {
            daysPaid[_summonerIds[i]] -= 1;
            emit executedDaycare(msg.sender, _summonerIds[i]);
        }
        // Below line will revert if any summoners can't be adventured
        adventureTime.adventureTime(_summonerIds);
        payable(msg.sender).transfer(_summonerIds.length * DAILY_FEE);
    }
}
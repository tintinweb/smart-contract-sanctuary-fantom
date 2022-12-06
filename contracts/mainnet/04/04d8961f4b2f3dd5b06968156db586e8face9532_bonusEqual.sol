/**
 *Submitted for verification at FtmScan.com on 2022-12-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IVe {
    function deposit_for(uint _tokenId, uint _value) external;
    function increase_amount(uint _tokenId, uint _value) external;
    function locked(uint _tokenId) external view returns(uint, uint);
    function ownerOf(uint _tokenId) external view returns(address);
    function increase_unlock_time(uint _tokenId, uint _duration) external;
    function create_lock_for(uint _value, uint _duration, address _to) external returns(uint);
}

interface IVo {
    function poke(uint _tokenId) external;
}

interface IT {
    function approve(address, uint) external;
    function balanceOf(address) external view returns(uint);
    function transferFrom(address, address, uint) external returns(bool);
    function transfer(address, uint) external returns(bool);
}

contract bonusEqual {
    address public owner;
    IT public EQ;
    IVe public VE;
    IVo public VO;
    uint public FACTOR = 1.2 ether; //1e18 = 100% = no bonus
    uint public MAXTIME = 26 * 7 * 86400;   //26 weeks

    uint8 RG = 0;
    modifier rg {
        require(RG == 0,"!RG");
        RG = 1;
        _;
        RG = 0;
    }

    modifier oo {
        require(msg.sender == owner, "!owner");
        _;
    }

    constructor(address _ve, address _eq, address _vo) {
        owner = msg.sender;
        VE = IVe(_ve);
        EQ = IT(_eq);
        VO = IVo(_vo);
        EQ.approve(address(VE), type(uint256).max);
    }

    function offer(uint _amt) public view returns(uint) {
        return (_amt * FACTOR) / 1 ether;
    }

    function extend(uint _id, uint _amt) public rg {
        //caller must pre-approve EQ & VE for this contract
        uint _bb = EQ.balanceOf(address(this));
        uint _offer = offer(_amt);
        require(_amt>0 && _offer > _bb, "!Sufficient");
        require(EQ.transferFrom(msg.sender, address(this), _amt), "!Deposit");
        uint _ba = EQ.balanceOf(address(this));
        require(_bb + _amt >= _ba, "!Clean");
        require(VE.ownerOf(_id) == msg.sender, "!Alien");
        maxLock(_id);
        VE.increase_amount(_id, _offer );
        VO.poke(_id);
    }

    function initiate(uint _amt) public rg returns(uint) {
        //caller must pre-approve EQ for this contract
        uint _bb = EQ.balanceOf(address(this));
        uint _offer = offer(_amt);
        require(_amt>0 && _offer > _bb, "!Sufficient");
        require(EQ.transferFrom(msg.sender, address(this), _amt), "!Deposit");
        uint _ba = EQ.balanceOf(address(this));
        require(_bb + _amt >= _ba, "!Clean");
        return VE.create_lock_for(_offer, MAXTIME, msg.sender);
    }

    function maxLock(uint _id) internal {
        uint _MAXTIME = MAXTIME;
        (, uint _old) = VE.locked(_id);
        uint _new = (block.timestamp + _MAXTIME) / (1 weeks) * (1 weeks);
        if(_new > _old) {
            VE.increase_unlock_time(_id, _MAXTIME);
        }
    }

    function setFactor(uint _f) public oo {
        require(_f>=1 ether, "!Bonus");
        FACTOR = _f;
    }

    function rescue(address tokenAddress, uint256 tokens) public oo returns (bool success) {
        if(tokenAddress==address(0)) {(success, ) = owner.call{value:tokens}("");return success;}
        else if(tokenAddress!=address(0)) {return IT(tokenAddress).transfer(owner, tokens);}
        else return false;
    }
}
/**
 *Submitted for verification at FtmScan.com on 2022-04-08
*/

interface IFloanCall{
  function startArbitrage(
    address token0, 
    address token1, 
    uint amount0, 
    uint amount1
  ) external;
}

interface IMasterChef{
    function poolInfo(uint) external view returns(address,uint,uint,uint);
}

interface IPair{
    function token0() external view returns(address);
    function token1() external view returns(address);
    function fee() external view returns(uint);
}

interface IFeed{
    function ftmPerToken(address _token) external view returns(uint);
}

interface YvVault{
    function token() external view returns(address);
    function totalAssets() external view returns(uint);
}

contract ArbMe{
    uint public poolId;
    bool public tokenNumber;
    address public lp;
    address public token0;
    address public token1;

    constructor(uint _pid, bool _tn){
        poolId = _pid;
        tokenNumber = _tn;
        (lp,,, ) = IMasterChef(0xC02563f20Ba3e91E459299C3AC1f70724272D618).poolInfo(_pid);
        IPair(lp).fee();//check If panic lp
        address vault0 = IPair(lp).token0();
        address vault1 = IPair(lp).token1();

        try YvVault(vault0).token() returns(address _underlying){
            token0 = _underlying;
        }catch{
            if(token0==0xF533ceA30Fc3E2eE164D233f44B8CC329D121347) token0 = 0xd46a5acf776a84fFe7fA7815d62D203638052fF4;
            else token0 = vault0;
        }

        try YvVault(vault1).token() returns(address _underlying){
            token1 = _underlying;
        }catch{
            if(token1==0xF533ceA30Fc3E2eE164D233f44B8CC329D121347) token1 = 0xd46a5acf776a84fFe7fA7815d62D203638052fF4;
            else token1 = vault1;
        }

    }

    function getParameters() public view returns(uint _amount0, uint _amount1){
        if(tokenNumber == false){
            uint _ftmPerToken0 = IFeed(0x686BFA58562F2cCd571cC1D00c8383fDcA45409d).ftmPerToken(token0);
            uint fees = IPair(lp).fee();
            _amount0 = 5e17*fees*1e18/_ftmPerToken0;
        } else {
            uint _ftmPerToken1 = IFeed(0x686BFA58562F2cCd571cC1D00c8383fDcA45409d).ftmPerToken(token1);
            uint fees = IPair(lp).fee();
            _amount1 = 5e17*fees*1e18/_ftmPerToken1;
        }
    }
    
    function execute() external{
        (uint amount0, uint amount1) = getParameters();
        IFloanCall(0x3313105381092462A8C1DF992C5D4bA181303C15).startArbitrage(
            token0,
            token1,
            amount0,
            amount1
        );
    }
}

contract arbFactory{
    mapping(uint=>mapping(bool=>address)) public arbMap;
    function deploy(uint n) public{
        require(msg.sender==0x1B5b5FB19d0a398499A9694AD823D786c24804CC);
        arbMap[n][false] = address(new ArbMe(n, false));
        arbMap[n][true] = address(new ArbMe(n, true));
    }

    constructor(){
        deploy(2);
    }
}
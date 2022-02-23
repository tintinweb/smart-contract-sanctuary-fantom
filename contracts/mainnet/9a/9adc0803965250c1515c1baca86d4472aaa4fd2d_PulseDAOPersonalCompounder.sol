/**
 *Submitted for verification at FtmScan.com on 2022-02-23
*/

// SPDX-License-Identifier: MIT-0
pragma solidity =0.8.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ISpookyRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IPulseFarm {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
}

contract PulseDAOPersonalCompounder {
    
    address public owner;
    IERC20 public SpookyLP = IERC20(0xd19D1056807f65fD2E10b8993d869204e1f07155);
    IERC20 public PSHARE = IERC20(0xB92E1FdA97e94B474516E9D8A9E31736f542e462);
    IERC20 public WFTM = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    IERC20 public PLD = IERC20(0x6A5E24E62135e391B6dd77A80D38Ee5A40834167);
    ISpookyRouter public SpookyRouter = ISpookyRouter(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    IPulseFarm public Masterchef = IPulseFarm(0xBD7f881bC9b35ff38bd5A99eA0A34d559aF950A4);
    
    uint constant TWENTY_MINUTES = 1200;

    address constant public admin = 0x00006E3e0ADC2af7EA28D2010d846eFab842D8c2;

    constructor() {
        owner = msg.sender;
        SpookyLP.approve(address(Masterchef), 2**256 - 1);
        WFTM.approve(address(SpookyRouter), 2**256 - 1);
        PLD.approve(address(SpookyRouter), 2**256 - 1);
        PSHARE.approve(address(SpookyRouter), 2**256 - 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Forgiving: caller is not the owner");
        _;
    }

    modifier onlyAdmin {
        require(owner == msg.sender || admin == msg.sender, "Forgiving: caller is not the owner nor an admin address");
        _;
    }

    function depositLP() public onlyOwner {
        require(SpookyLP.balanceOf(address(this)) != 0, "Forgiving: No Spooky LP tokens to stake");
        Masterchef.deposit(0, SpookyLP.balanceOf(address(this)));
    }

    function withdraw() external onlyOwner {
        Masterchef.withdraw(0,0);
        PSHARE.transfer(owner, PSHARE.balanceOf(address(this)));
        Masterchef.emergencyWithdraw(0);
        SpookyLP.transfer(owner, SpookyLP.balanceOf(address(this)));
    }

    function withdrawTokensFromContract(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(owner, tokenContract.balanceOf(address(this)));
    }

    function compound() public onlyAdmin {
        Masterchef.withdraw(0, 0);

        _swapForWFTM();

        _swapHalfWFTMForPLD();

        uint256 aBalance = WFTM.balanceOf(address(this));
        uint256 bBalance = PLD.balanceOf(address(this));
        
        if (aBalance > 0 && bBalance > 0) {
            SpookyRouter.addLiquidity(
                address(WFTM), address(PLD),
                aBalance, bBalance,
                0, 0,
                address(this),
                block.timestamp + TWENTY_MINUTES
            );
        }

        Masterchef.deposit(0, SpookyLP.balanceOf(address(this)));
    }

    function _swapForWFTM() internal {

        address[] memory path = new address[](2);
        path[0] = address(PSHARE);
        path[1] = address(WFTM);

        SpookyRouter.swapExactTokensForTokens(
            (PSHARE.balanceOf(address(this))),
            0,
            path,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );
    }

    function _swapHalfWFTMForPLD() internal {

        address[] memory path = new address[](2);
        path[0] = address(WFTM);
        path[1] = address(PLD);

        SpookyRouter.swapExactTokensForTokens(
            (WFTM.balanceOf(address(this)) / 2),
            0,
            path,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "Forgiving: external call failed");
        return result;
    }
}
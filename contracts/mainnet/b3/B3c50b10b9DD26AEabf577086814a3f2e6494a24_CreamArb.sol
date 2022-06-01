/**
 *Submitted for verification at FtmScan.com on 2022-06-01
*/

/**
 *Submitted for verification at FtmScan.com on 2022-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;


interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function decimals() external view returns(uint8);
}

interface IFlashloanReceiver {
    function onFlashLoan(address initiator, address underlying, uint amount, uint fee, bytes calldata params) external;
}

interface ICTokenFlashloan {
    function flashLoan(
        address receiver,
        address initiator,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface ILendingPool {
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;    
}

interface ILendingPoolAddressesProviderRegistry { // 0x4CF8E50A5ac16731FA2D8D9591E195A285eCaA82
    function getAddressesProvidersList() external view returns (address[] memory);
}

interface LendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

interface SpiritRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, uint256 deadline) external;
}

interface BAMMInterface {
    function swap(uint lusdAmount, IERC20 returnToken, uint minReturn, address payable dest) external returns(uint);
    function LUSD() external view returns(address);
    function collaterals(uint i) external view returns(address);
}

interface CurveInterface {
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns(uint);
}

contract CreamArb {
    IERC20 constant public WFTM = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    SpiritRouter constant public ROUTER = SpiritRouter(0xF491e7B69E4244ad4002BC14e878a34207E38c29); // use spooky swap
    CurveInterface constant public CURVE = CurveInterface(0x27E611FD27b276ACbd5Ffd632E5eAEBEC9761E40);
    IERC20 constant public DAI = IERC20(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E);
    IERC20 constant public USDC = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    ILendingPoolAddressesProviderRegistry constant public REGISTRY = ILendingPoolAddressesProviderRegistry(0x4CF8E50A5ac16731FA2D8D9591E195A285eCaA82);

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address /*initiator*/,
        bytes calldata params
    )
        external returns (bool) 
    {
        onFlashLoan(msg.sender, assets[0], amounts[0], premiums[0], params);
        return true;
    }

    function onFlashLoan(address initiator, address underlying, uint amount, uint fee, bytes calldata params) public returns(bytes32) {
        IERC20(underlying).approve(initiator, amount + fee);

        (BAMMInterface bamm, address[] memory path, IERC20 dest) = abi.decode(params, (BAMMInterface, address[], IERC20));
        // swap on the bamm
        IERC20(underlying).approve(address(bamm), amount);
        uint destAmount = bamm.swap(amount, dest, 1, address(this));

        dest.approve(address(ROUTER), destAmount);
        if(dest != USDC) {
            ROUTER.swapExactTokensForTokens(destAmount, 1, path, address(this), now);
        }

        if(underlying == address(DAI)) {
            uint usdcAmount = USDC.balanceOf(address(this));
            USDC.approve(address(CURVE), usdcAmount);
            CURVE.exchange(1, 0, usdcAmount, 1);
        }        

        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }

    function arb(BAMMInterface bamm, uint srcAmount, address dest) public {
        IERC20 src = IERC20(bamm.LUSD());
/*
        ICTokenFlashloan creamToken;
        if(src == DAI) {
            creamToken = ICTokenFlashloan(0x04c762a5dF2Fa02FE868F25359E0C259fB811CfE);
        }
        else if(src == USDC) {
            creamToken = ICTokenFlashloan(0x328A7b4d538A2b3942653a9983fdA3C12c571141);
        }
        else revert("arb: unsupported src");
*/

        address[] memory path = new address[](4);
        path[0] = dest;
        path[1] = address(0x74b23882a30290451A17c44f4F05243b6b58C76d);                  
        path[2] = address(WFTM);
        path[3] = address(USDC);

        bytes memory data = abi.encode(bamm, path, dest);

        address[] memory assets = new address[](1);
        uint[] memory amounts = new uint[](1);
        uint[] memory modes = new uint[](1);

        assets[0] = address(src);
        amounts[0] = srcAmount;
        modes[0] = 0;

        LendingPoolAddressesProvider provider = LendingPoolAddressesProvider((REGISTRY.getAddressesProvidersList())[0]);
        ILendingPool pool = ILendingPool(provider.getLendingPool());
        pool.flashLoan(address(this), assets, amounts, modes, address(this), data, 0);

        //creamToken.flashLoan(address(this), address(creamToken), srcAmount, data);

        src.transfer(msg.sender, src.balanceOf(address(this)));
    }

    // revert on failure
    function checkProfitableArb(uint usdQty, uint minProfit, BAMMInterface bamm, address dest) external returns(bool){
        IERC20 src = IERC20(bamm.LUSD());
        uint balanceBefore = src.balanceOf(address(this));
        this.arb(bamm, usdQty, dest);
        uint balanceAfter = src.balanceOf(address(this));
        require((balanceAfter - balanceBefore) >= minProfit, "min profit was not reached");

        return true;
    }    

    fallback() payable external {

    }
}
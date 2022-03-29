//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";

contract DevilBuyer is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct DepositInfo {
        uint256 depositUSDCAmount;
        uint256 devilTokenAmount;
        uint256 restUSDCAmount;
        uint256 depositMoment;
        uint256 amountForSwap;
    }

    mapping(address => DepositInfo) public depositInfo;

    event Deposited(address indexed _user, uint256 _amount);

    address DEVIL;
    address USDC;
    uint256[] amounts;
    IUniswapV2Router02 public router;
    address private constant UNISWAP_V2_ROUTER_4_SPOOKY =
        0xF491e7B69E4244ad4002BC14e878a34207E38c29; // Address of UniswapV2Router02 FOR FTM mainnet
    address private constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    // address ROUTERADDR_T = 0xa6AD18C2aC47803E193F75c3677b14BF19B94883; // Address of UniswapV2Router02 in FTM testnet

    // IERC20 DEVIL = 0x174c7106AEeCdC11389f7dD21342F05f46CCB40F; // Devil on Fantom mainnet
    // IERC20 USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75; // USDC on Fantom mainnet

    constructor(address _usdc, address _devilToken) {
        USDC = _usdc;
        DEVIL = _devilToken;
        router = IUniswapV2Router02(UNISWAP_V2_ROUTER_4_SPOOKY);
    }

    function deposit(uint256 _usdcAmount) public {
        require(_usdcAmount >= 0, "The Amount should much than 0");
        IERC20(USDC).transferFrom(msg.sender, address(this), _usdcAmount);
        depositInfo[msg.sender].depositUSDCAmount = _usdcAmount;
        depositInfo[msg.sender].depositMoment = block.timestamp;
        depositInfo[msg.sender].restUSDCAmount += _usdcAmount;
        emit Deposited(msg.sender, _usdcAmount);
    }

    function buyDevilToken(uint256 _usdcAmount, uint256 _amountOutMin)
        external
    {
        require(
            _usdcAmount <= depositInfo[msg.sender].depositUSDCAmount,
            "USDC Amount exceeded than your deposited."
        );
        // IERC20(USDC).transfer(address(UNISWAP_V2_ROUTER_4_SPOOKY), _usdcAmount);
        IERC20(USDC).approve(UNISWAP_V2_ROUTER_4_SPOOKY, _usdcAmount);
        uint256 amountIn = _usdcAmount;
        uint256 amountOutMin = _amountOutMin;
        address[] memory path = new address[](3);
        path[0] = address(USDC);
        path[1] = address(WFTM);
        path[2] = address(DEVIL);
        amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp
            // .add(5 days)
        );
        depositInfo[msg.sender].restUSDCAmount -= _usdcAmount;
    }

    function getRestUSDCBalance() public view returns (uint256) {
        return (depositInfo[msg.sender].restUSDCAmount);
    }

    function getDevilBalance() public view returns (uint256[] memory) {
        return amounts;
    }

    function claimRestUSDCBalance() external {
        IERC20(USDC).transfer(
            msg.sender,
            depositInfo[msg.sender].restUSDCAmount
        );
        depositInfo[msg.sender].restUSDCAmount -= depositInfo[msg.sender]
            .restUSDCAmount;
    }
}
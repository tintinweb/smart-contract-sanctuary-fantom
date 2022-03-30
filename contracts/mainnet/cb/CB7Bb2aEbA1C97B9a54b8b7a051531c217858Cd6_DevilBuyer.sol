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
    }

    mapping(address => DepositInfo) public depositInfo;

    event Deposited(address indexed _user, uint256 _amount);

    address USDC;
    address DEVIL;
    uint256[] amounts;
    IUniswapV2Router02 public router;
    address private constant UNISWAP_V2_ROUTER_4_SPOOKY =
        0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address private constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    constructor(address _usdc, address _devilToken) {
        USDC = _usdc;
        DEVIL = _devilToken;
        router = IUniswapV2Router02(UNISWAP_V2_ROUTER_4_SPOOKY);
    }

    /**
     * @dev A method to deposit USDC into smart contract for swapping with Devil token
     * @param _usdcAmount : USDC Amount
     */
    function deposit(uint256 _usdcAmount) external {
        require(_usdcAmount >= 0, "The Amount should much than 0");
        IERC20(USDC).transferFrom(msg.sender, address(this), _usdcAmount);
        depositInfo[msg.sender].depositUSDCAmount += _usdcAmount;
        depositInfo[msg.sender].depositMoment = block.timestamp;
        depositInfo[msg.sender].restUSDCAmount += _usdcAmount;
        emit Deposited(msg.sender, _usdcAmount);
    }

    /**
     * @dev A method to buy Devil token
     * @param _usdcAmount : USDC Amount
     */
    function buyDevilToken(uint256 _usdcAmount) external {
        require(
            _usdcAmount <= depositInfo[msg.sender].depositUSDCAmount,
            "USDC Amount exceeded than you deposited."
        );
        IERC20(USDC).approve(UNISWAP_V2_ROUTER_4_SPOOKY, _usdcAmount);
        uint256 amountIn = _usdcAmount;
        uint256 amountOutMin = 0;
        address[] memory path = new address[](3);
        path[0] = address(USDC);
        path[1] = address(WFTM);
        path[2] = address(DEVIL);
        address to = address(this);
        amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            block.timestamp
        );
        depositInfo[msg.sender].restUSDCAmount -= _usdcAmount;
    }

    /**
     * @dev A method to get the rest amount of USDC after buy Devil token
     */
    function getRestUSDCBalance() external view returns (uint256) {
        return (depositInfo[msg.sender].restUSDCAmount);
    }

    /**
     * @dev A method to get amount of tokens in all paths
     */
    function getDevilBalance() external view returns (uint256[] memory) {
        return amounts;
    }

    /**
     * @dev A method to withdraw rest USDC token
     */
    function withdrawRestUSDCBalance() external {
        IERC20(USDC).transfer(
            msg.sender,
            depositInfo[msg.sender].restUSDCAmount
        );
        depositInfo[msg.sender].restUSDCAmount -= depositInfo[msg.sender]
            .restUSDCAmount;
    }

    /**
     * @dev A method to withdraw swapped Devil token
     */
    function withdrawSwappedDevilToken() external {
        IERC20(DEVIL).transfer(msg.sender, amounts[2]);
    }
}
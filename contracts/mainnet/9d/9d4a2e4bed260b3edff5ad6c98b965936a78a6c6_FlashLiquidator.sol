/**
 *Submitted for verification at FtmScan.com on 2022-05-21
*/

// SPDX-License-Identifier: MIT

// File: interfaces/IWrapped.sol

pragma solidity ^0.8.10;

interface IWrapped {
    function withdraw(uint256 amount) external returns (uint256);
}
// File: interfaces/IExchange.sol



pragma solidity ^0.8.10;

interface IExchange {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}
// File: interfaces/ICurvePool.sol



pragma solidity ^0.8.10;

interface ICurvePool {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 _min_dy) external returns (uint256);
}
// File: interfaces/IController.sol



pragma solidity ^0.8.10;

interface IController {
    function getAuctionDetails(address borrower, address collateral) external view returns (uint, uint, uint);
}
// File: interfaces/ICore.sol



pragma solidity ^0.8.10;

interface ICore {
    function liquidateBorrow(address borrower, address collateral) external returns (uint, uint, uint);
}
// File: ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: ERC20/IERC3156FlashBorrower.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "IERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}
// File: ERC20/IERC3156FlashLender.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}
// File: flash.sol



pragma solidity ^0.8.10;

contract FlashLiquidator is IERC3156FlashBorrower {
    struct Params {
        bool isWrapped;
        address borrower;
        address collateral;
        address exchange;
        address[] path;
        uint256 minAmountOut;
    }

    address immutable owner;
    address constant core = 0x04D2C91A8BDf61b11A526ABea2e2d8d778d4A534; 
    address constant lender = 0xE3a486C1903Ea794eED5d5Fa0C9473c7D7708f40;
    address constant controller = 0x07F961C532290594FA1A08929EB5557346a7BB9C;
    address constant pool = 0x96059756980fF6ced0473898d26F0EF828a59820;
    address constant usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;

    constructor() {
        owner = msg.sender;
    }

    function liquidate(bytes calldata data) external {
        require(msg.sender == owner, "!owner");
        (Params memory params) = abi.decode(data, (Params));
        (, , uint256 amount) = IController(controller).getAuctionDetails(params.borrower, params.collateral);
        if (amount != 0) {
            IERC3156FlashLender(lender).flashLoan(IERC3156FlashBorrower(this), lender, amount, data);
        } else {
            (, , uint256 collateralAmount) = ICore(core).liquidateBorrow(params.borrower, params.collateral);
            IERC20(params.collateral).transfer(owner, collateralAmount);
        }
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,   
        bytes calldata data
    ) external returns (bytes32) {
        require(initiator == address(this), "!initiator");
        require(msg.sender == lender, "!lender");
        (Params memory params) = abi.decode(data, (Params));
        IERC20(token).approve(core, amount);
        (, , uint256 collateralAmount) = ICore(core).liquidateBorrow(params.borrower, params.collateral);
        if (params.isWrapped) {
            // unwrap to underlying
            collateralAmount = IWrapped(params.collateral).withdraw(collateralAmount);
        }
        uint256 amountOut = collateralAmount;
        if (params.path.length != 0) {
            // swap via AMM
            require(params.path[params.path.length - 1] == usdc, "!usdc");
            IERC20(params.collateral).approve(params.exchange, collateralAmount);
            amountOut = IExchange(params.exchange).swapExactTokensForTokens(collateralAmount, 0, params.path, address(this), type(uint256).max)[params.path.length - 1];
        }
        IERC20(usdc).approve(pool, amountOut);
        uint256 cusdOut = ICurvePool(pool).exchange_underlying(2, 0, amountOut, 0);
        require(cusdOut >= amount + fee, "!enough");
        uint256 profit = cusdOut - amount - fee;
        IERC20(token).transfer(owner, profit);

        // return flash loan
        IERC20(token).approve(lender, amount + fee);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function sweep(address token) external {
        require(msg.sender == owner, "!owner");
        IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
    }
}
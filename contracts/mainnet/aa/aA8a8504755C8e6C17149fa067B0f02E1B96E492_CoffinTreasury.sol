// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.6;

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IOwnUniswapV2Router {
    function addLiquidityTaxFreeSpookySwap(
        address token,
        uint256 amtCoffin,
        uint256 amtToken,
        uint256 amtCoffinMin,
        uint256 amtTokenMin,
        uint256 deadline
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface IBooMirrorWorld {
    function leave(uint256 _share) external;

    function enter(uint256 _amount) external;

    function balanceOf(address account) external view returns (uint256);

    function xBOOForBOO(uint256 _xBOOAmount) external view returns (uint256 booAmount_);
}

interface IyvToken {
    function deposit(uint256 _amount) external;

    function deposit(uint256 _amount, address _recipient) external;

    function withdraw(uint256 _amount) external;

    function withdraw(uint256 _amount, address _recipient) external;

    function balanceOf(address account) external view returns (uint256);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow.");
        return c;
    }

    function add32(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, "SafeMath: addition overflow..");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "CoffinTreasury:SafeMath: subtraction overflow....");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow......");

        return c;
    }

    function mul32(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }

        uint32 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow........");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero...");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract.");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IOwnable {
    function manager() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require(_owner == msg.sender, "Ownable: caller is not the owner..");
        _;
    }

    function renounceManagement() public virtual override onlyManager {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyManager {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address...");
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull....");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed......");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed.....");
        }
    }
}

interface ICoffin {
    function pool_mint(address account_, uint256 ammount_) external;

    function burnFrom(address account_, uint256 amount_) external;
}

interface IBondCalculator {
    function valuation(address pair_, uint256 amount_) external view returns (uint256 _value);
}

contract CoffinTreasury is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeERC20 for IERC20;

    event Deposit(address indexed token, uint256 amount, uint256 payout);
    event Withdrawal(address indexed token, uint256 amount, uint256 value);
    event CreateDebt(address indexed debtor, address indexed token, uint256 amount, uint256 value);
    event RepayDebt(address indexed debtor, address indexed token, uint256 amount, uint256 value);
    event ReservesManaged(address indexed token, uint256 amount);
    event ReservesUpdated(uint256 indexed totalReserves);
    event ReservesAudited(uint256 indexed totalReserves);
    event RewardsMinted(address indexed caller, address indexed recipient, uint256 amount);
    event ChangeQueued(MANAGING indexed managing, address queued);
    event ChangeActivated(MANAGING indexed managing, address activated, bool result);

    enum MANAGING {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN,
        RESERVEMANAGER,
        LIQUIDITYDEPOSITOR,
        LIQUIDITYTOKEN,
        LIQUIDITYMANAGER,
        DEBTOR,
        REWARDMANAGER,
        SOHM
    }

    uint256 private constant LIMIT_SWAP_TIME = 10 minutes;
    address private spookyRouterAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    // router for creating LP
    address private coffinRouterAddress = 0xcA5a12bFbddAd76adD7e4CbFb83DCa3f2ca31790;

    address private wftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address private dai = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
    address private usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address private cousd = 0x0DeF844ED26409C5C46dda124ec28fb064D90D27;
    address private xboo = 0xa48d959AE2E88f1dAA7D5F611E01908106dE7598;
    address private boo = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
    address private coffintheotherworld = 0x5e082C23d1c70466c518306320e4927ea4A844B4;
    address private boomirrorworld = 0xa48d959AE2E88f1dAA7D5F611E01908106dE7598;
    address private xcoffin = 0xc8a0a1b63F65C53F565ddDB7fbcfdd2eaBE868ED;
    address private yvdai = 0x637eC617c86D24E421328e6CAEa1d92114892439;
    address private yvusdc = 0xEF0210eB96c7EB36AF8ed1c20306462764935607;
    address private yvwftm = 0x0DEC85e74A92c52b7F708c4B10207D9560CEFaf0;

    address public immutable OHM;
    uint32 public immutable secondsNeededForQueue;

    address[] public reserveTokens; // Push only, beware false-positives.
    mapping(address => bool) public isReserveToken;
    mapping(address => uint32) public reserveTokenQueue; // Delays changes to mapping.

    address[] public reserveDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveDepositor;
    mapping(address => uint32) public reserveDepositorQueue; // Delays changes to mapping.

    address[] public reserveSpenders; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveSpender;
    mapping(address => uint32) public reserveSpenderQueue; // Delays changes to mapping.

    address[] public liquidityTokens; // Push only, beware false-positives.
    mapping(address => bool) public isLiquidityToken;
    mapping(address => uint32) public LiquidityTokenQueue; // Delays changes to mapping.

    address[] public liquidityDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isLiquidityDepositor;
    mapping(address => uint32) public LiquidityDepositorQueue; // Delays changes to mapping.

    mapping(address => address) public bondCalculator; // bond calculator for liquidity token

    address[] public rewardManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isRewardManager;
    mapping(address => uint32) public rewardManagerQueue; // Delays changes to mapping.

    constructor(
        address _OHM,
        address _DAI,
        uint32 _secondsNeededForQueue
    ) {
        require(_OHM != address(0));
        OHM = _OHM;
        isReserveToken[_DAI] = true;
        reserveTokens.push(_DAI);
        secondsNeededForQueue = _secondsNeededForQueue;
    }

    // Please be careful: The depositor contracts can mint without enough collateral!!
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _payout
    ) external {
        require(isReserveToken[_token] || isLiquidityToken[_token], "Not accepted.");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        if (isReserveToken[_token]) {
            require(isReserveDepositor[msg.sender], "Not approved....4");
        } else {
            require(isLiquidityDepositor[msg.sender], "Not approved...5");
        }
        if (_payout > 0) {
            // be careful.
            ICoffin(OHM).pool_mint(msg.sender, _payout);
        }

        emit Deposit(_token, _amount, _payout);
    }

    /**
        @notice allow approved address to burn OHM for reserves
        @param _burn uint
        @param _amount uint
        @param _token address
     */
    // Please be careful: The spender contracts can withdraw without enough COFFIN burn!
    function withdraw(
        uint256 _amount,
        address _token,
        uint256 _burn
    ) external {
        require(isReserveToken[_token], "Not accepted"); // Only reserves can be used for redemptions
        require(isReserveSpender[msg.sender] == true, "Not approved.....6");

        if (_burn > 0) {
            ICoffin(OHM).burnFrom(msg.sender, _burn);
        }
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Withdrawal(_token, _amount, _burn);
    }

    /**
        @notice send epoch reward to staking contract
     */
    // Please be careful: The RewardManager contracts can mint!
    function mintRewards(address _recipient, uint256 _amount) external {
        require(isRewardManager[msg.sender], "Not approved.7");
        require(_amount > 0, "amt error");

        // be careful.
        ICoffin(OHM).pool_mint(_recipient, _amount);
        emit RewardsMinted(msg.sender, _recipient, _amount);
    }

    function createCoffinFTMLP(
        uint256 amtToken0,
        uint256 amtToken1,
        uint256 minToken0,
        uint256 minToken1
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved.8");
        return _createCoffinLiquidity(wftm, amtToken0, amtToken1, minToken0, minToken1);
    }

    function createCoffinLiquidity(
        address token1,
        uint256 amtToken0,
        uint256 amtToken1,
        uint256 minToken0,
        uint256 minToken1
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved......11");
        return _createCoffinLiquidity(token1, amtToken0, amtToken1, minToken0, minToken1);
    }

    function _createCoffinLiquidity(
        address token1,
        uint256 amtToken0,
        uint256 amtToken1,
        uint256 minToken0,
        uint256 minToken1
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(amtToken0 != 0 && amtToken1 != 0, "amounts can't be 0");

        IERC20(OHM).approve(address(coffinRouterAddress), 0);
        IERC20(OHM).approve(address(coffinRouterAddress), amtToken0);

        IERC20(token1).approve(address(coffinRouterAddress), 0);
        IERC20(token1).approve(address(coffinRouterAddress), amtToken1);

        uint256 resultAmtToken0;
        uint256 resultAmtToken1;
        uint256 liquidity;

        (resultAmtToken0, resultAmtToken1, liquidity) = IOwnUniswapV2Router(coffinRouterAddress).addLiquidityTaxFreeSpookySwap(
            token1,
            amtToken0,
            amtToken1,
            minToken0,
            minToken1,
            block.timestamp + LIMIT_SWAP_TIME
        );
        return (resultAmtToken0, resultAmtToken1, liquidity);
    }

    function createCoUSDLiquidity(
        address token1,
        uint256 amtToken0,
        uint256 amtToken1,
        uint256 minToken0,
        uint256 minToken1
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved......10");
        return _createLiquidity(cousd, token1, amtToken0, amtToken1, minToken0, minToken1, spookyRouterAddress);
    }

    function stakeBOO(uint256 _amount) external {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved.");
        require(boomirrorworld != address(0), "boomirrorworld address error");
        require(_amount != 0, "amount error");
        IERC20(boo).approve(address(boomirrorworld), 0);
        IERC20(boo).approve(address(boomirrorworld), _amount);
        IBooMirrorWorld(boomirrorworld).enter(_amount);
    }

    function unstakeXBOO(uint256 _amount) external {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved....");
        require(boomirrorworld != address(0), "boomirrorworld address error");
        require(_amount != 0, "amount error");
        IERC20(xboo).approve(address(boomirrorworld), 0);
        IERC20(xboo).approve(address(boomirrorworld), _amount);
        IBooMirrorWorld(boomirrorworld).leave(_amount);
    }

    function wftm2yvwftm(uint256 _amount) external {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved...");
        yvDeposit(wftm, yvwftm, _amount);
    }

    function usdc2yvusdc(uint256 _amount) external {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved...");
        yvDeposit(usdc, yvusdc, _amount);
    }

    function dai2yvdai(uint256 _amount) external {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved...");
        yvDeposit(dai, yvdai, _amount);
    }

    function yvDeposit(
        address _token0,
        address _token1,
        uint256 _amount
    ) public {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved...");
        IERC20(_token0).approve(address(_token1), 0);
        IERC20(_token0).approve(address(_token1), _amount);
        IyvToken(address(_token1)).deposit(_amount);
    }

    function yvWithdraw(address _token, uint256 _amount) public {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved.");
        IERC20(_token).approve(address(_token), 0);
        IERC20(_token).approve(address(_token), _amount);
        IyvToken(address(_token)).withdraw(_amount);
    }

    function createLiquidity(
        address token0,
        address token1,
        uint256 amtToken0,
        uint256 amtToken1,
        uint256 minToken0,
        uint256 minToken1,
        address routerAddress
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved......9");
        return _createLiquidity(token0, token1, amtToken0, amtToken1, minToken0, minToken1, routerAddress);
    }

    function _createLiquidity(
        address token0,
        address token1,
        uint256 amtToken0,
        uint256 amtToken1,
        uint256 minToken0,
        uint256 minToken1,
        address routerAddress
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(amtToken0 != 0 && amtToken1 != 0, "amounts can't be 0");

        IERC20(token0).approve(address(routerAddress), 0);
        IERC20(token0).approve(address(routerAddress), amtToken0);

        IERC20(token1).approve(address(routerAddress), 0);
        IERC20(token1).approve(address(routerAddress), amtToken1);

        uint256 resultAmtToken0;
        uint256 resultAmtToken1;
        uint256 liquidity;

        (resultAmtToken0, resultAmtToken1, liquidity) = IUniswapV2Router(routerAddress).addLiquidity(
            token0,
            token1,
            amtToken0,
            amtToken1,
            minToken0,
            minToken1,
            address(this),
            block.timestamp + LIMIT_SWAP_TIME
        );
        return (resultAmtToken0, resultAmtToken1, liquidity);
    }

    function swapFTM2COFFIN(uint256 _amount, uint256 _min_output_amount) public {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved..1");
        return _swap(wftm, OHM, _amount, _min_output_amount, spookyRouterAddress);
    }

    function swapDAI2COFFIN(uint256 _amount, uint256 _min_output_amount) public {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved...2");
        return _swap(dai, OHM, _amount, _min_output_amount, spookyRouterAddress);
    }

    function swapDAI2COUSD(uint256 _amount, uint256 _min_output_amount) public {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved...12");
        return _swap(dai, cousd, _amount, _min_output_amount, spookyRouterAddress);
    }

    function swapUSDC2COUSD(uint256 _amount, uint256 _min_output_amount) public {
        require(manager() == msg.sender || isReserveDepositor[msg.sender], "Not approved...13");
        return _swap(usdc, cousd, _amount, _min_output_amount, spookyRouterAddress);
    }

    function swap(
        address token0,
        address token1,
        uint256 _amount,
        uint256 _min_output_amount,
        address routerAddress
    ) external {
        require(isReserveToken[token0] && (manager() == msg.sender || isReserveDepositor[msg.sender]), "Not approved..3");
        _swap(token0, token1, _amount, _min_output_amount, routerAddress);
    }

    function _swap(
        address token0,
        address token1,
        uint256 _amount,
        uint256 _min_output_amount,
        address routerAddress
    ) internal {
        IERC20(token0).approve(address(routerAddress), 0);
        IERC20(token0).approve(address(routerAddress), _amount);

        address[] memory router_path = new address[](2);
        router_path[0] = token0;
        router_path[1] = token1;

        uint256[] memory _received_amounts = IUniswapV2Router(routerAddress).swapExactTokensForTokens(
            _amount,
            _min_output_amount,
            router_path,
            address(this),
            block.timestamp + LIMIT_SWAP_TIME
        );

        require(_received_amounts[_received_amounts.length - 1] >= _min_output_amount, "Slippage limit reached");
    }

    /**
        @notice returns OHM valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function valueOf(address _token, uint256 _amount) public view returns (uint256 value_) {
        if (isReserveToken[_token]) {
            // convert amount to match OHM decimals
            value_ = _amount.mul(10**IERC20(OHM).decimals()).div(10**IERC20(_token).decimals());
        } else if (isLiquidityToken[_token]) {
            value_ = IBondCalculator(bondCalculator[_token]).valuation(_token, _amount);
        }
    }

    /**
        @notice queue address to change boolean in mapping
        @param _managing MANAGING
        @param _address address
        @return bool
     */
    function queue(MANAGING _managing, address _address) external onlyManager returns (bool) {
        require(_address != address(0));
        if (_managing == MANAGING.RESERVEDEPOSITOR) {
            // 0
            reserveDepositorQueue[_address] = uint32(block.timestamp).add32(secondsNeededForQueue);
        } else if (_managing == MANAGING.RESERVESPENDER) {
            // 1
            reserveSpenderQueue[_address] = uint32(block.timestamp).add32(secondsNeededForQueue);
        } else if (_managing == MANAGING.RESERVETOKEN) {
            // 2
            reserveTokenQueue[_address] = uint32(block.timestamp).add32(secondsNeededForQueue);
        } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {
            // 4
            LiquidityDepositorQueue[_address] = uint32(block.timestamp).add32(secondsNeededForQueue);
        } else if (_managing == MANAGING.LIQUIDITYTOKEN) {
            // 5
            LiquidityTokenQueue[_address] = uint32(block.timestamp).add32(secondsNeededForQueue);
        } else if (_managing == MANAGING.REWARDMANAGER) {
            // 8
            rewardManagerQueue[_address] = uint32(block.timestamp).add32(secondsNeededForQueue);
        } else return false;

        emit ChangeQueued(_managing, _address);
        return true;
    }

    /**
        @notice verify queue then set boolean in mapping
        @param _managing MANAGING
        @param _address address
        @param _calculator address
        @return bool
     */
    function toggle(
        MANAGING _managing,
        address _address,
        address _calculator
    ) external onlyManager returns (bool) {
        require(_address != address(0));
        bool result;
        if (_managing == MANAGING.RESERVEDEPOSITOR) {
            // 0
            if (requirements(reserveDepositorQueue, isReserveDepositor, _address)) {
                reserveDepositorQueue[_address] = 0;
                if (!listContains(reserveDepositors, _address)) {
                    reserveDepositors.push(_address);
                }
            }
            result = !isReserveDepositor[_address];
            isReserveDepositor[_address] = result;
        } else if (_managing == MANAGING.RESERVESPENDER) {
            // 1
            if (requirements(reserveSpenderQueue, isReserveSpender, _address)) {
                reserveSpenderQueue[_address] = 0;
                if (!listContains(reserveSpenders, _address)) {
                    reserveSpenders.push(_address);
                }
            }
            result = !isReserveSpender[_address];
            isReserveSpender[_address] = result;
        } else if (_managing == MANAGING.RESERVETOKEN) {
            // 2
            if (requirements(reserveTokenQueue, isReserveToken, _address)) {
                reserveTokenQueue[_address] = 0;
                if (!listContains(reserveTokens, _address)) {
                    reserveTokens.push(_address);
                }
            }
            result = !isReserveToken[_address];
            isReserveToken[_address] = result;
        } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {
            // 4
            if (requirements(LiquidityDepositorQueue, isLiquidityDepositor, _address)) {
                liquidityDepositors.push(_address);
                LiquidityDepositorQueue[_address] = 0;
                if (!listContains(liquidityDepositors, _address)) {
                    liquidityDepositors.push(_address);
                }
            }
            result = !isLiquidityDepositor[_address];
            isLiquidityDepositor[_address] = result;
        } else if (_managing == MANAGING.LIQUIDITYTOKEN) {
            // 5
            if (requirements(LiquidityTokenQueue, isLiquidityToken, _address)) {
                LiquidityTokenQueue[_address] = 0;
                if (!listContains(liquidityTokens, _address)) {
                    liquidityTokens.push(_address);
                }
            }
            result = !isLiquidityToken[_address];
            isLiquidityToken[_address] = result;
            bondCalculator[_address] = _calculator;
        } else if (_managing == MANAGING.REWARDMANAGER) {
            // 8
            if (requirements(rewardManagerQueue, isRewardManager, _address)) {
                rewardManagerQueue[_address] = 0;
                if (!listContains(rewardManagers, _address)) {
                    rewardManagers.push(_address);
                }
            }
            result = !isRewardManager[_address];
            isRewardManager[_address] = result;
        } else return false;

        emit ChangeActivated(_managing, _address, result);
        return true;
    }

    /**
        @notice checks requirements and returns altered structs
        @param queue_ mapping( address => uint )
        @param status_ mapping( address => bool )
        @param _address address
        @return bool
     */
    function requirements(
        mapping(address => uint32) storage queue_,
        mapping(address => bool) storage status_,
        address _address
    ) internal view returns (bool) {
        if (!status_[_address]) {
            require(queue_[_address] != 0, "Must queue..");
            require(queue_[_address] <= uint32(block.timestamp), "Queue not expired...");
            return true;
        }
        return false;
    }

    /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains(address[] storage _list, address _token) internal view returns (bool) {
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _token) {
                return true;
            }
        }
        return false;
    }
}
// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: GPL3.0-or-later

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ==================== DEI Lender Solidex ===================
// ==========================================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// MMD: https://github.com/mmd-mostafaee
// MRM: https://github.com/smrm-dev

// Reviewer(s)
// Vahid: https://github.com/vahid-dev
// HHZ: https://github.com/hedzed

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "./interfaces/IMintHelper.sol";
import "./interfaces/IMuon.sol";
import "./interfaces/HIERC20.sol";
import "./interfaces/ILpDepositor.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import {SolidexHolder as Holder} from "./SolidexHolder.sol";

interface IOracle {
    function getOnChainPrice() external view returns (uint256);

    function getPrice(
        uint256 price,
        uint256 timestamp,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) external returns (uint256);
}

contract DeiLenderSolidex is BoringOwnable {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    event SetOracle(address oldValue, address newValue);
    event SetMaxCap(uint256 oldValue, uint256 newValue);
    event SetBorrowOpeningFee(uint256 oldValue, uint256 newValue);
    event SetLiquidationRatio(uint256 oldValue, uint256 newValue);
    event SetMintHelper(address oldValue, address newValue);

    event UpdateAccrue(uint256 interest);
    event Borrow(address from, address to, uint256 amount, uint256 debt);
    event Repay(address from, address to, uint256 amount, uint256 repayAmount);
    event AddCollateral(address from, address to, uint256 amount);
    event RemoveCollateral(address from, address to, uint256 amount);
    event Liquidate(
        address liquidator,
        address user,
        uint256 collateralAmount,
        uint256 deiAmount
    );

    IERC20 public collateral;

    IERC20 public solid;
    IERC20 public solidex;
    address public lpDepositor;
    uint256 public maxCap;

    IOracle public oracle;

    uint256 public borrowOpeningFee;

    uint256 public liquidationRatio;

    uint256 public totalCollateral;
    Rebase public totalBorrow;

    mapping(address => uint256) public userCollateral;
    mapping(address => uint256) public userBorrow;
    mapping(address => address) public userHolder;

    address public mintHelper;

    struct AccrueInfo {
        uint256 lastAccrued;
        uint256 feesEarned;
        uint256 interestPerSecond;
    }

    AccrueInfo public accrueInfo;

    constructor(
        IERC20 collateral_,
        IOracle oracle_,
        IERC20 solid_,
        IERC20 solidex_,
        address lpDepositor_,
        uint256 maxCap_,
        uint256 interestPerSecond_,
        uint256 borrowOpeningFee_,
        uint256 liquidationRatio_,
        address mintHelper_
    ) public {
        require(
            lpDepositor_ != address(0),
            "DeiLenderSolidex: lpDepositor_ address cannot be 0"
        );
        require(
            mintHelper_ != address(0),
            "DeiLenderSolidex: mintHelper_ address cannot be 0"
        );

        collateral = collateral_;
        accrueInfo.interestPerSecond = interestPerSecond_;
        accrueInfo.lastAccrued = block.timestamp;
        borrowOpeningFee = borrowOpeningFee_;
        liquidationRatio = liquidationRatio_;
        oracle = oracle_;
        solid = solid_;
        solidex = solidex_;
        lpDepositor = lpDepositor_;
        maxCap = maxCap_;
        mintHelper = mintHelper_;
    }

    function setOracle(IOracle oracle_) external onlyOwner {
        emit SetOracle(address(oracle), address(oracle_));
        oracle = oracle_;
    }

    function setMaxCap(uint256 maxCap_) external onlyOwner {
        emit SetMaxCap(maxCap, maxCap_);
        maxCap = maxCap_;
    }

    function setBorrowOpeningFee(uint256 borrowOpeningFee_) external onlyOwner {
        emit SetBorrowOpeningFee(borrowOpeningFee, borrowOpeningFee_);
        borrowOpeningFee = borrowOpeningFee_;
    }

    function setLiquidationRatio(uint256 liquidationRatio_) external onlyOwner {
        emit SetLiquidationRatio(liquidationRatio, liquidationRatio_);
        liquidationRatio = liquidationRatio_;
    }

    function setMintHelper(address mintHelper_) external onlyOwner {
        require(
            mintHelper_ != address(0),
            "DeiLenderSolidex: mintHelper_ address cannot be 0"
        );
        emit SetMintHelper(mintHelper, mintHelper_);
        mintHelper = mintHelper_;
    }

    function getRepayAmount(uint256 amount)
        external
        view
        returns (uint256 repayAmount)
    {
        Rebase memory _totalBorrow = totalBorrow;
        (uint128 elastic, ) = getCurrentElastic();
        _totalBorrow.elastic = elastic;
        (_totalBorrow, repayAmount) = _totalBorrow.sub(amount, true);
    }

    /// @notice returns user total debt (borrowed amount + interest)
    function getDebt(address user) public view returns (uint256 debt) {
        if (totalBorrow.base == 0) return 0;

        (uint128 elastic, ) = getCurrentElastic();
        return userBorrow[user].mul(uint256(elastic)) / totalBorrow.base;
    }

    /// @notice returns liquidation price for requested user
    function getLiquidationPrice(address user) external view returns (uint256) {
        uint256 userCollateralAmount = userCollateral[user];
        if (userCollateralAmount == 0) return 0;

        uint256 liquidationPrice = (getDebt(user).mul(1e18).mul(1e18)) /
            (userCollateralAmount.mul(liquidationRatio));
        return liquidationPrice;
    }

    /// @notice returns withdrawable amount for requested user
    function getWithdrawableCollateralAmount(address user)
        external
        view
        returns (uint256)
    {
        uint256 userCollateralAmount = userCollateral[user];
        if (userCollateralAmount == 0) return 0;

        uint256 neededCollateral = (getDebt(user).mul(1e18).mul(1e18)) /
            (oracle.getOnChainPrice().mul(liquidationRatio));

        return
            userCollateralAmount > neededCollateral
                ? userCollateralAmount - neededCollateral
                : 0;
    }

    function isSolvent(address user) public view returns (bool) {
        uint256 userCollateralAmount = userCollateral[user];
        if (userCollateralAmount == 0) return getDebt(user) == 0;

        return
            userCollateralAmount.mul(oracle.getOnChainPrice()).mul(
                liquidationRatio
            ) /
                (uint256(1e18).mul(1e18)) >
            getDebt(user);
    }

    function isSolvent(
        address user,
        uint256 price,
        uint256 timestamp,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) internal returns (bool) {
        // accrue must have already been called!

        uint256 userCollateralAmount = userCollateral[user];
        if (userCollateralAmount == 0) return getDebt(user) == 0;

        return
            userCollateralAmount
                .mul(oracle.getPrice(price, timestamp, reqId, sigs))
                .mul(liquidationRatio) /
                (uint256(1e18).mul(1e18)) >
            getDebt(user);
    }

    function getCurrentElastic()
        internal
        view
        returns (uint128 elastic, uint128 interest)
    {
        Rebase memory _totalBorrow = totalBorrow;
        uint256 elapsedTime = block.timestamp - accrueInfo.lastAccrued;
        if (elapsedTime != 0 && _totalBorrow.base != 0) {
            interest = (uint256(_totalBorrow.elastic)
                .mul(accrueInfo.interestPerSecond)
                .mul(elapsedTime) / 1e18).to128();
            elastic = _totalBorrow.elastic.add(interest);
        } else {
            return (totalBorrow.elastic, 0);
        }
    }

    function accrue() public {
        uint256 elapsedTime = block.timestamp - accrueInfo.lastAccrued;
        if (elapsedTime == 0) return;
        if (totalBorrow.base == 0) {
            accrueInfo.lastAccrued = uint256(block.timestamp);
            return;
        }

        (uint128 elastic, uint128 interest) = getCurrentElastic();

        accrueInfo.lastAccrued = uint256(block.timestamp);
        totalBorrow.elastic = elastic;
        accrueInfo.feesEarned = accrueInfo.feesEarned.add(interest);

        emit UpdateAccrue(interest);
    }

    function addCollateral(address to, uint256 amount) external {
        emit AddCollateral(msg.sender, to, amount);

        userCollateral[to] = userCollateral[to].add(amount);
        totalCollateral = totalCollateral.add(amount);
        if (userHolder[to] == address(0)) {
            Holder holder = new Holder(lpDepositor, address(this), to);
            userHolder[to] = address(holder);
        }
        collateral.safeTransferFrom(msg.sender, userHolder[to], amount);
    }

    /// @param price collateral price (USD)
    /// @param timestamp sign timestamp
    function removeCollateral(
        address to,
        uint256 amount,
        uint256 price,
        uint256 timestamp,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) external {
        accrue();

        emit RemoveCollateral(msg.sender, to, amount);

        userCollateral[msg.sender] = userCollateral[msg.sender].sub(amount);
        totalCollateral = totalCollateral.sub(amount);

        require(
            isSolvent(msg.sender, price, timestamp, reqId, sigs),
            "User is not solvent!"
        );

        require(
            Holder(userHolder[msg.sender]).withdrawERC20(
                address(collateral),
                to,
                amount
            ),
            "DeiLenderSolidex: WithdrawERC20 failed"
        );
    }

    function borrow(
        address to,
        uint256 amount,
        uint256 price,
        uint256 timestamp,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) external returns (uint256 debt) {
        require(isSolvent(msg.sender), "User is not solvent!");

        accrue();
        uint256 fee = amount.mul(borrowOpeningFee) / 1e18;
        (totalBorrow, debt) = totalBorrow.add(amount.add(fee), true);
        accrueInfo.feesEarned = accrueInfo.feesEarned.add(fee);
        userBorrow[msg.sender] = userBorrow[msg.sender].add(debt);

        require(
            totalBorrow.elastic <= maxCap,
            "Lender total borrow exceeds cap"
        );

        require(
            isSolvent(msg.sender, price, timestamp, reqId, sigs),
            "User is not solvent!"
        );

        emit Borrow(msg.sender, to, amount.add(fee), debt);

        IMintHelper(mintHelper).mint(to, amount);
    }

    function repayElastic(address to, uint256 debt)
        external
        returns (uint256 repayAmount)
    {
        accrue();

        uint256 amount = debt.mul(totalBorrow.base) / totalBorrow.elastic;

        (totalBorrow, repayAmount) = totalBorrow.sub(amount, true);
        userBorrow[to] = userBorrow[to].sub(amount);

        emit Repay(msg.sender, to, amount, repayAmount);

        IMintHelper(mintHelper).burnFrom(msg.sender, repayAmount);
    }

    function repayBase(address to, uint256 amount)
        external
        returns (uint256 repayAmount)
    {
        accrue();

        (totalBorrow, repayAmount) = totalBorrow.sub(amount, true);
        userBorrow[to] = userBorrow[to].sub(amount);

        emit Repay(msg.sender, to, amount, repayAmount);

        IMintHelper(mintHelper).burnFrom(msg.sender, repayAmount);
    }

    function liquidate(
        address[] calldata users,
        address to,
        uint256 price,
        uint256 timestamp,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) external {
        accrue();

        uint256 totalCollateralAmount = 0;
        uint256 totalDeiAmount = 0;

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];

            if (!isSolvent(msg.sender, price, timestamp, reqId, sigs)) {
                uint256 collateralAmount = userCollateral[user];

                uint256 deiAmount;
                (totalBorrow, deiAmount) = totalBorrow.sub(
                    userBorrow[user],
                    true
                );

                totalDeiAmount += deiAmount;
                totalCollateralAmount += collateralAmount;

                emit RemoveCollateral(user, to, collateralAmount);
                emit Repay(msg.sender, user, userBorrow[user], deiAmount);
                emit Liquidate(
                    msg.sender,
                    user,
                    userCollateral[user],
                    deiAmount
                );

                userBorrow[user] = 0;
                userCollateral[user] = 0;

                require(
                    Holder(userHolder[user]).withdrawERC20(
                        address(collateral),
                        to,
                        collateralAmount
                    ),
                    "DeiLenderSolidex: WithdrawERC20 failed"
                );
            }
        }

        require(totalDeiAmount != 0, "All users are solvent");

        totalCollateral = totalCollateral.sub(totalCollateralAmount);

        IMintHelper(mintHelper).burnFrom(msg.sender, totalDeiAmount);
    }

    function withdrawFees(address to, uint256 amount) external onlyOwner {
        accrue();

        IMintHelper(mintHelper).mint(to, amount);
        accrueInfo.feesEarned = accrueInfo.feesEarned.sub(amount);
    }

    function claim(address[] calldata pools) external {
        Holder(userHolder[msg.sender]).claim(pools);
    }

    function claimAndWithdraw(address[] calldata pools, address to) external {
        Holder(userHolder[msg.sender]).claim(pools);
        require(
            Holder(userHolder[msg.sender]).withdrawERC20(
                address(solid),
                to,
                solid.balanceOf(userHolder[msg.sender])
            ),
            "DeiLenderSolidex: Withdraw solid failed"
        );
        require(
            Holder(userHolder[msg.sender]).withdrawERC20(
                address(solidex),
                to,
                solidex.balanceOf(userHolder[msg.sender])
            ),
            "DeiLenderSolidex: Withdraw solidex failed"
        );
    }

    function emergencyHolderWithdraw(
        address holder,
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(
            Holder(holder).withdrawERC20(token, to, amount),
            "DeiLenderSolidex: Withdraw failed"
        );
    }

    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(
            HIERC20(token).transfer(to, amount),
            "DeiLenderSolidex: Transfer failed"
        );
    }
}

// SPDX-License-Identifier: GPL3.0-or-later

interface IMintHelper {
    function dei() external view returns (address);

    function useVirtualReserve(address pool) external view returns (bool);

    function virtualReserve() external view returns (uint256);

    function MINTER_ROLE() external view returns (bytes32);

    function mint(address recv, uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function collatDollarBalance(uint256 collat_usd_price)
        external
        view
        returns (uint256);

    function setVirtualReserve(uint256 virtualReserve_) external;

    function setUseVirtualReserve(address pool, bool state) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma experimental ABIEncoderV2;

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

interface IMuonV02 {
    function verify(
        bytes calldata reqId,
        uint256 hash,
        SchnorrSign[] calldata _sigs
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

interface HIERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address user) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: None

interface ILpDepositor {
    function deposit(address pool, uint256 amount) external;

    function withdraw(address pool, uint256 amount) external;

    function getReward(address[] calldata pools) external;

    function claimLockerRewards(
        address pool,
        address[] calldata gaugeRewards,
        address[] calldata bribeRewards
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./interfaces/IERC20.sol";
import "./Domain.sol";

// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

// Data part taken out for building of contracts that receive delegate calls
contract ERC20Data {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;
}

abstract contract ERC20 is IERC20, Domain {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public override balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
    /// @param to The address to move the tokens.
    /// @param amount of the tokens to move.
    /// @return (bool) Returns True if succeeded.
    function transfer(address to, uint256 amount) public returns (bool) {
        // If `amount` is 0, or `msg.sender` is `to` nothing happens
        if (amount != 0 || msg.sender == to) {
            uint256 srcBalance = balanceOf[msg.sender];
            require(srcBalance >= amount, "ERC20: balance too low");
            if (msg.sender != to) {
                require(to != address(0), "ERC20: no zero address"); // Moved down so low balance calls safe some gas

                balanceOf[msg.sender] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `from` to `to`. Caller needs approval for `from`.
    /// @param from Address to draw tokens from.
    /// @param to The address to move the tokens.
    /// @param amount The token amount to move.
    /// @return (bool) Returns True if succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        // If `amount` is 0, or `from` is `to` nothing happens
        if (amount != 0) {
            uint256 srcBalance = balanceOf[from];
            require(srcBalance >= amount, "ERC20: balance too low");

            if (from != to) {
                uint256 spenderAllowance = allowance[from][msg.sender];
                // If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
                if (spenderAllowance != type(uint256).max) {
                    require(spenderAllowance >= amount, "ERC20: allowance too low");
                    allowance[from][msg.sender] = spenderAllowance - amount; // Underflow is checked
                }
                require(to != address(0), "ERC20: no zero address"); // Moved down so other failed calls safe some gas

                balanceOf[from] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Approves `amount` from sender to be spend by `spender`.
    /// @param spender Address of the party that can draw from msg.sender's account.
    /// @param amount The maximum collective amount that `spender` can draw.
    /// @return (bool) Returns True if approved.
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner_ != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        require(
            ecrecover(_getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))), v, r, s) ==
                owner_,
            "ERC20: Invalid Signature"
        );
        allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }
}

contract ERC20WithSupply is IERC20, ERC20 {
    uint256 public override totalSupply;

    function _mint(address user, uint256 amount) private {
        uint256 newTotalSupply = totalSupply + amount;
        require(newTotalSupply >= totalSupply, "Mint overflow");
        totalSupply = newTotalSupply;
        balanceOf[user] += amount;
    }

    function _burn(address user, uint256 amount) private {
        require(balanceOf[user] >= amount, "Burn too much");
        totalSupply -= amount;
        balanceOf[user] -= amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./BoringMath.sol";

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    using BoringMath for uint256;
    using BoringMath128 for uint128;

    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = elastic.mul(total.base) / total.elastic;
            if (roundUp && base.mul(total.elastic) / total.base < elastic) {
                base = base.add(1);
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = base.mul(total.elastic) / total.base;
            if (roundUp && elastic.mul(total.base) / total.elastic < base) {
                elastic = elastic.add(1);
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic = total.elastic.add(elastic.to128());
        total.base = total.base.add(base.to128());
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic = total.elastic.sub(elastic.to128());
        total.base = total.base.sub(base.to128());
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic.add(elastic.to128());
        total.base = total.base.add(base.to128());
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic.sub(elastic.to128());
        total.base = total.base.sub(base.to128());
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic.add(elastic.to128());
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic.sub(elastic.to128());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while(i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: MIT

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ==================== Holder ===================
// ==============================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// Mmd: https://github.com/mmd-mostafaee

pragma solidity 0.6.12;

import "./interfaces/HIERC20.sol";
import "./interfaces/ILpDepositor.sol";

contract SolidexHolder {
    ILpDepositor public lpDepositor;
    address public lender;
    address public user;

    constructor(
        address lpDepositor_,
        address lender_,
        address user_
    ) public {
        require(
            lpDepositor_ != address(0),
            "Holder: lpDepositor_ cannot be zero"
        );
        require(lender_ != address(0), "Holder: lender_ cannot be zero");
        require(user_ != address(0), "Holder: user_ cannot be zero");

        lpDepositor = ILpDepositor(lpDepositor_);
        lender = lender_;
        user = user_;
    }

    function claim(address[] calldata pools) external {
        lpDepositor.getReward(pools);
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == lender, "SolidexHolder: You are not lender");
        require(
            HIERC20(token).transfer(to, amount),
            "SolidexHolder: Transfer failed"
        );
        return true;
    }
}

//Dar panah khoda

// SPDX-License-Identifier: MIT
// Based on code and smartness by Ross Campbell and Keno
// Uses immutable to store the domain separator to reduce gas usage
// If the chain id changes due to a fork, the forked chain will calculate on the fly.
pragma solidity 0.6.12;

// solhint-disable no-inline-assembly

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    // solhint-disable var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;    

    /// @dev Calculate the DOMAIN_SEPARATOR
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_SIGNATURE_HASH,
                chainId,
                address(this)
            )
        );
    }

    constructor() public {
        uint256 chainId; assembly {chainId := chainid()}
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = chainId);
    }

    /// @dev Return the DOMAIN_SEPARATOR
    // It's named internal to allow making it public from the contract that uses it by creating a simple view function
    // with the desired public name, such as DOMAIN_SEPARATOR or domainSeparator.
    // solhint-disable-next-line func-name-mixedcase
    function _domainSeparator() internal view returns (bytes32) {
        uint256 chainId; assembly {chainId := chainid()}
        return chainId == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest =
            keccak256(
                abi.encodePacked(
                    EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                    _domainSeparator(),
                    dataHash
                )
            );
    }
}

// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: GPL3.0-or-later

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ==================== Lender ===================
// ==========================================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// MMD: https://github.com/mmd-mostafaee
// MRM: https://github.com/smrm-dev
// Vahid: https://github.com/vahid-dev

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ISwapper.sol";
import "./interfaces/IMintHelper.sol";
import "./interfaces/ILpDepositor.sol";
import "./interfaces/IHolderManager.sol";
import "./ReentrancyGuard.sol";

/// @title Solidex Lender
/// @author DEUS Finance
/// @notice Lending DEI for solidex LP tokens
contract Lender is BoringOwnable, ReentrancyGuard {
    struct AccrueInfo {
        uint256 lastAccrued;
        uint256 interestPerSecond;
    }
    struct LiquidationInput {
        uint256 collateralIndex;
        address to;
        address recipient;
        address swapper;
        address[] users;
    }

    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    event AddLending(
        uint256 collateralIndex,
        address collateral,
        address oracle,
        uint256 maxCap,
        uint256 interestPerSecond,
        uint256 borrowOpeningFee,
        uint256 liquidationRatio,
        uint256 distributionRatio
    );
    event SetOracle(
        uint256 collateralIndex,
        address oldValue,
        address newValue
    );
    event SetMaxCap(
        uint256 collateralIndex,
        uint256 oldValue,
        uint256 newValue
    );
    event SetBorrowOpeningFee(
        uint256 collateralIndex,
        uint256 oldValue,
        uint256 newValue
    );
    event SetLiquidationRatio(
        uint256 collateralIndex,
        uint256 oldValue,
        uint256 newValue
    );
    event SetMintHelper(address oldValue, address newValue);
    event SetHolderManager(address oldValue, address newValue);
    event UpdateAccrue(uint256 collateralIndex, uint256 interest);
    event Borrow(
        uint256 collateralIndex,
        address from,
        address to,
        uint256 amount,
        uint256 debt
    );
    event Repay(
        uint256 collateralIndex,
        address from,
        address to,
        uint256 amount,
        uint256 repayAmount
    );
    event AddCollateral(
        uint256 collateralIndex,
        address from,
        address to,
        uint256 amount
    );
    event RemoveCollateral(
        uint256 collateralIndex,
        address from,
        address to,
        uint256 amount
    );
    event Liquidate(
        uint256 collateralIndex,
        address liquidator,
        address user,
        uint256 collateralAmount,
        uint256 deiAmount
    );
    event ClaimAndWithdraw(address from, address[] pools, address to);


    mapping(uint256 => address) public collaterals; // collateralIndex -> collateral

    uint256 public collateralsLength; // number of collaterals

    address public solid; // SOLID contract address

    address public solidex; // Solidex contract address

    mapping(uint256 => uint256) public maxCaps; // collateralIndex -> maxCap

    mapping(uint256 => address) public oracles; // collateralIndex-> oracle

    mapping(uint256 => uint256) public borrowOpeningFees; // collateralIndex  -> fee

    mapping(uint256 => uint256) public liquidationRatios; // collateralIndex -> liquidationRatio

    mapping(uint256 => uint256) public distributionRatios; // collateralIndex -> distributionRatio

    mapping(uint256 => uint256) public totalCollaterals; // collateralIndex -> totalCollateral

    mapping(uint256 => Rebase) public totalBorrows; // collateralIndex -> totalBorrow

    mapping(uint256 => mapping(address => uint256)) public userCollaterals; // collateralIndex -> user -> amount

    mapping(uint256 => mapping(address => uint256)) public userBorrows; // collateralIndex -> user -> amount

    address public mintHelper; // MintHelper contract address

    address public holderManager; // HolderManager contract address

    uint256 public feesEarned; // fees earned by the Lender

    mapping(uint256 => AccrueInfo) public accrueInfos; // collateralIndex -> accrueInfo

    constructor(
        address solid_,
        address solidex_,
        address mintHelper_,
        address holderManager_
    ) public ReentrancyGuard() {
        require(
            mintHelper_ != address(0) &&
                solidex_ != address(0) &&
                mintHelper_ != address(0) &&
                holderManager_ != address(0),
            "Lender: ZERO_ADDRESS_DETECTED"
        );

        solid = solid_;
        solidex = solidex_;
        mintHelper = mintHelper_;
        holderManager = holderManager_;
    }

    function addLending(
        address collateral,
        address oracle,
        uint256 maxCap,
        uint256 interestPerSecond,
        uint256 borrowOpeningFee,
        uint256 liquidationRatio,
        uint256 distributionRatio
    ) external onlyOwner {
        require(
            collateral != address(0) && oracle != address(0),
            "Lender: ZERO_ADDRESS_DETECTED"
        );

        collaterals[collateralsLength] = collateral;
        oracles[collateralsLength] = oracle;
        maxCaps[collateralsLength] = maxCap;
        borrowOpeningFees[collateralsLength] = borrowOpeningFee;
        liquidationRatios[collateralsLength] = liquidationRatio;
        distributionRatios[collateralsLength] = distributionRatio;
        AccrueInfo memory accrueInfo = AccrueInfo({
            interestPerSecond: interestPerSecond,
            lastAccrued: block.timestamp
        });
        accrueInfos[collateralsLength] = accrueInfo;

        emit AddLending(
            collateralsLength,
            collateral,
            oracle,
            maxCap,
            interestPerSecond,
            borrowOpeningFee,
            liquidationRatio,
            distributionRatio
        );

        collateralsLength++;
    }

    function setOracle(uint256 collateralIndex, address oracle_)
        external
        onlyOwner
    {
        emit SetOracle(collateralIndex, oracles[collateralIndex], oracle_);
        oracles[collateralIndex] = oracle_;
    }

    function setMaxCap(uint256 collateralIndex, uint256 maxCap_)
        external
        onlyOwner
    {
        emit SetMaxCap(collateralIndex, maxCaps[collateralIndex], maxCap_);
        maxCaps[collateralIndex] = maxCap_;
    }

    function setBorrowOpeningFee(
        uint256 collateralIndex,
        uint256 borrowOpeningFee_
    ) external onlyOwner {
        emit SetBorrowOpeningFee(
            collateralIndex,
            borrowOpeningFees[collateralIndex],
            borrowOpeningFee_
        );
        borrowOpeningFees[collateralIndex] = borrowOpeningFee_;
    }

    function setLiquidationRatio(
        uint256 collateralIndex,
        uint256 liquidationRatio_
    ) external onlyOwner {
        emit SetLiquidationRatio(
            collateralIndex,
            liquidationRatios[collateralIndex],
            liquidationRatio_
        );
        liquidationRatios[collateralIndex] = liquidationRatio_;
    }

    function setMintHelper(address mintHelper_) external onlyOwner {
        require(mintHelper_ != address(0), "Lender: ZERO_ADDRESS_DETECTED");
        emit SetMintHelper(mintHelper, mintHelper_);
        mintHelper = mintHelper_;
    }

    function setHolderManager(address holderManager_) external onlyOwner {
        require(holderManager_ != address(0), "Lender: ZERO_ADDRESS_DETECTED");
        emit SetHolderManager(holderManager, holderManager_);
        holderManager = holderManager_;
    }

    function getRepayAmount(uint256 collateralIndex, uint256 amount)
        external
        view
        returns (uint256 repayAmount)
    {
        Rebase memory _totalBorrow = totalBorrows[collateralIndex];
        (uint128 elastic, ) = getCurrentElastic(collateralIndex);
        _totalBorrow.elastic = elastic;
        (_totalBorrow, repayAmount) = _totalBorrow.sub(amount, true);
    }

    /// @notice returns user total debt (borrowed amount + interest)
    function getDebt(uint256 collateralIndex, address user)
        public
        view
        returns (uint256 debt)
    {
        require(user != address(0), "Lender: ZERO_ADDRESS_DETECTED");

        if (totalBorrows[collateralIndex].base == 0) return 0;

        (uint128 elastic, ) = getCurrentElastic(collateralIndex);

        return
            userBorrows[collateralIndex][user].mul(uint256(elastic)) /
            totalBorrows[collateralIndex].base;
    }

    /// @notice returns liquidation price for requested user
    function getLiquidationPrice(uint256 collateralIndex, address user)
        external
        view
        returns (uint256)
    {
        uint256 userCollateralAmount = userCollaterals[collateralIndex][user];
        if (userCollateralAmount == 0) return 0;

        uint256 liquidationPrice = (
            getDebt(collateralIndex, user).mul(1e18).mul(1e18)
        ) / (userCollateralAmount.mul(liquidationRatios[collateralIndex]));
        return liquidationPrice;
    }

    /// @notice returns withdrawable amount for requested user
    function getWithdrawableCollateralAmount(
        uint256 collateralIndex,
        address user,
        uint256 price
    ) external view returns (uint256) {
        uint256 userCollateralAmount = userCollaterals[collateralIndex][user];
        if (userCollateralAmount == 0) return 0;

        uint256 neededCollateral = (
            getDebt(collateralIndex, user).mul(1e18).mul(1e18)
        ) / (price.mul(liquidationRatios[collateralIndex]));

        return
            userCollateralAmount > neededCollateral
                ? userCollateralAmount - neededCollateral
                : 0;
    }

    function isSolvent(
        uint256 collateralIndex,
        address user,
        uint256 price
    ) public view returns (bool) {
        uint256 userCollateralAmount = userCollaterals[collateralIndex][user];
        if (userCollateralAmount == 0)
            return getDebt(collateralIndex, user) == 0;

        return
            userCollateralAmount.mul(price).mul(
                liquidationRatios[collateralIndex]
            ) /
                (uint256(1e18).mul(1e18)) >
            getDebt(collateralIndex, user);
    }

    function isSolvent(
        uint256 collateralIndex,
        address user,
        IOracle.Signature calldata signature
    ) internal returns (bool) {
        // accrue must have already been called!

        uint256 userCollateralAmount = userCollaterals[collateralIndex][user];
        if (userCollateralAmount == 0)
            return getDebt(collateralIndex, user) == 0;

        return
            userCollateralAmount
                .mul(
                    IOracle(oracles[collateralIndex]).getPrice(
                        collaterals[collateralIndex],
                        signature
                    )
                )
                .mul(liquidationRatios[collateralIndex]) /
                (uint256(1e18).mul(1e18)) >
            getDebt(collateralIndex, user);
    }

    function getCurrentElastic(uint256 collateralIndex)
        internal
        view
        returns (uint128 elastic, uint128 interest)
    {
        Rebase memory _totalBorrow = totalBorrows[collateralIndex];
        uint256 elapsedTime = block.timestamp -
            accrueInfos[collateralIndex].lastAccrued;
        if (elapsedTime != 0 && _totalBorrow.base != 0) {
            interest = (uint256(_totalBorrow.elastic)
                .mul(accrueInfos[collateralIndex].interestPerSecond)
                .mul(elapsedTime) / 1e18).to128();
            elastic = _totalBorrow.elastic.add(interest);
        } else {
            return (_totalBorrow.elastic, 0);
        }
    }

    function accrue(uint256 collateralIndex) public {
        uint256 elapsedTime = block.timestamp -
            accrueInfos[collateralIndex].lastAccrued;
        if (elapsedTime == 0) return;
        if (totalBorrows[collateralIndex].base == 0) {
            accrueInfos[collateralIndex].lastAccrued = uint256(block.timestamp);
            return;
        }

        (uint128 elastic, uint128 interest) = getCurrentElastic(
            collateralIndex
        );

        accrueInfos[collateralIndex].lastAccrued = uint256(block.timestamp);
        totalBorrows[collateralIndex].elastic = elastic;
        feesEarned = feesEarned.add(interest);

        emit UpdateAccrue(collateralIndex, interest);
    }

    function addCollateral(
        uint256 collateralIndex,
        address to,
        uint256 amount
    ) external {
        userCollaterals[collateralIndex][to] = userCollaterals[collateralIndex][
            to
        ].add(amount);
        totalCollaterals[collateralIndex] = totalCollaterals[collateralIndex]
            .add(amount);

        emit AddCollateral(collateralIndex, msg.sender, to, amount);

        if (IHolderManager(holderManager).holders(to) == address(0)) {
            IHolderManager(holderManager).createHolder(to);
        }

        IERC20(collaterals[collateralIndex]).safeTransferFrom(
            msg.sender,
            IHolderManager(holderManager).holders(to),
            amount
        );
    }

    function removeCollateral(
        uint256 collateralIndex,
        address to,
        uint256 amount,
        IOracle.Signature calldata signature
    ) external {
        accrue(collateralIndex);

        userCollaterals[collateralIndex][msg.sender] = userCollaterals[
            collateralIndex
        ][msg.sender].sub(amount);
        totalCollaterals[collateralIndex] = totalCollaterals[collateralIndex]
            .sub(amount);

        require(
            isSolvent(collateralIndex, msg.sender, signature),
            "Lender: NOT_SOLVENT"
        );

        address[] memory tokens = new address[](1);
        tokens[0] = collaterals[collateralIndex];

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        emit RemoveCollateral(collateralIndex, msg.sender, to, amount);

        IHolderManager(holderManager).withdrawERC20(
            msg.sender,
            tokens,
            to,
            amounts
        );
    }

    function borrow(
        uint256 collateralIndex,
        address to,
        uint256 amount,
        IOracle.Signature calldata signature
    ) external returns (uint256 debt) {
        require(to != address(0), "Lender: ZERO_ADDRESS_DETECTED");

        accrue(collateralIndex);

        uint256 fee = amount.mul(borrowOpeningFees[collateralIndex]) / 1e18;
        (totalBorrows[collateralIndex], debt) = totalBorrows[collateralIndex]
            .add(amount.add(fee), true);
        feesEarned = feesEarned.add(fee);
        userBorrows[collateralIndex][msg.sender] = userBorrows[collateralIndex][
            msg.sender
        ].add(debt);

        require(
            totalBorrows[collateralIndex].elastic <= maxCaps[collateralIndex],
            "Lender: MAX_CAP_EXCEEDED"
        );

        require(
            isSolvent(collateralIndex, msg.sender, signature),
            "Lender: NOT_SOLVENT"
        );

        emit Borrow(collateralIndex, msg.sender, to, amount.add(fee), debt);

        IMintHelper(mintHelper).mint(to, amount);
    }

    function repayElastic(
        uint256 collateralIndex,
        address to,
        uint256 debt
    ) external returns (uint256 repayAmount) {
        require(to != address(0), "Lender: ZERO_ADDRESS_DETECTED");

        accrue(collateralIndex);

        uint256 amount = debt.mul(totalBorrows[collateralIndex].base) /
            totalBorrows[collateralIndex].elastic;

        (totalBorrows[collateralIndex], repayAmount) = totalBorrows[
            collateralIndex
        ].sub(amount, true);
        userBorrows[collateralIndex][to] = userBorrows[collateralIndex][to].sub(
            amount
        );

        emit Repay(collateralIndex, msg.sender, to, amount, repayAmount);

        IMintHelper(mintHelper).burnFrom(msg.sender, repayAmount);
    }

    function repayBase(
        uint256 collateralIndex,
        address to,
        uint256 amount
    ) external returns (uint256 repayAmount) {
        require(to != address(0), "Lender: ZERO_ADDRESS_DETECTED");

        accrue(collateralIndex);

        (totalBorrows[collateralIndex], repayAmount) = totalBorrows[
            collateralIndex
        ].sub(amount, true);
        userBorrows[collateralIndex][to] = userBorrows[collateralIndex][to].sub(
            amount
        );

        emit Repay(collateralIndex, msg.sender, to, amount, repayAmount);

        IMintHelper(mintHelper).burnFrom(msg.sender, repayAmount);
    }

    function liquidate(
        LiquidationInput calldata liquidationInput,
        IOracle.Signature calldata signature
    ) external nonReentrant() {
        require(liquidationInput.to != address(0), "Lender: ZERO_ADDRESS_DETECTED");

        accrue(liquidationInput.collateralIndex);

        uint256 totalCollateralAmount = 0;
        uint256 totalDeiAmount = 0;

        for (uint256 i = 0; i < liquidationInput.users.length; i++) {
            address user = liquidationInput.users[i];

            if (!isSolvent(liquidationInput.collateralIndex, msg.sender, signature)) {
                uint256 collateralAmount = userCollaterals[liquidationInput.collateralIndex][
                    user
                ];

                uint256 deiAmount;
                {
                    (totalBorrows[liquidationInput.collateralIndex], deiAmount) = totalBorrows[
                        liquidationInput.collateralIndex
                    ].sub(userBorrows[liquidationInput.collateralIndex][user], true);

                    totalDeiAmount += deiAmount;
                    totalCollateralAmount += collateralAmount;
                }

                _emitLiquidateEvents(
                    liquidationInput.collateralIndex,
                    user,
                    liquidationInput.to,
                    collateralAmount,
                    deiAmount
                );

                userBorrows[liquidationInput.collateralIndex][user] = 0;
                userCollaterals[liquidationInput.collateralIndex][user] = 0;

                {
                    address[] memory tokens = new address[](1);
                    tokens[0] = collaterals[liquidationInput.collateralIndex];

                    uint256[] memory amounts = new uint256[](1);
                    amounts[0] = collateralAmount;

                    IHolderManager(holderManager).withdrawERC20(
                        user,
                        tokens,
                        liquidationInput.to,
                        amounts
                    );
                }
            }
        }

        require(totalDeiAmount != 0, "Lender: ALL_USERS_ARE_SOLVENT");

        totalCollaterals[liquidationInput.collateralIndex] = totalCollaterals[liquidationInput.collateralIndex].sub(totalCollateralAmount);

        // Apply a percentual fee share to veDEUS holders
        {
            uint256 interest = totalDeiAmount.mul(uint256(1e18).sub(liquidationRatios[liquidationInput.collateralIndex]).mul(1e18) / liquidationRatios[liquidationInput.collateralIndex]) / 1e18; // interest = totalDeiAmount * (1 - liquidationRatio) / liquidationRatio
            uint256 distributionAmount = interest.mul(distributionRatios[liquidationInput.collateralIndex]) / 1e18; // Distribution Amount
            totalDeiAmount = totalDeiAmount.add(distributionAmount);
            feesEarned = feesEarned.add(distributionAmount.to128());
        }

        if (liquidationInput.swapper != address(0)) {
            ISwapper(liquidationInput.swapper).swap(
                collaterals[liquidationInput.collateralIndex],
                IMintHelper(mintHelper).dei(),
                liquidationInput.recipient,
                totalCollateralAmount,
                totalDeiAmount
            );
        }

        IMintHelper(mintHelper).burnFrom(msg.sender, totalDeiAmount);
    }

    function _emitLiquidateEvents(
        uint256 collateralIndex,
        address user,
        address to,
        uint256 collateralAmount,
        uint256 deiAmount
    ) internal {
        emit RemoveCollateral(collateralIndex, user, to, collateralAmount);
        emit Repay(
            collateralIndex,
            msg.sender,
            user,
            userBorrows[collateralIndex][user],
            deiAmount
        );
        emit Liquidate(
            collateralIndex,
            msg.sender,
            user,
            userCollaterals[collateralIndex][user],
            deiAmount
        );
    }

    function withdrawFees(
        address to,
        uint256 amount,
        uint256[] memory collateralIndexes
    ) external onlyOwner {
        require(to != address(0), "Lender: ZERO_ADDRESS_DETECTED");

        for (uint256 i; i < collateralIndexes.length; i++) {
            accrue(collateralIndexes[i]);
        }

        IMintHelper(mintHelper).mint(to, amount);
        feesEarned = feesEarned.sub(amount);
    }

    function claim(address[] calldata pools) external {
        IHolderManager(holderManager).claimFor(msg.sender, pools);
    }

    function claimAndWithdraw(address[] calldata pools, address to) external {
        require(to != address(0), "Lender: ZERO_ADDRESS_DETECTED");

        IHolderManager(holderManager).claimFor(msg.sender, pools);

        address holder = IHolderManager(holderManager).holders(msg.sender);

        emit ClaimAndWithdraw(msg.sender, pools, to);

        address[] memory tokens = new address[](2);
        tokens[0] = solid;
        tokens[1] = solidex;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = IERC20(solid).balanceOf(holder);
        amounts[1] = IERC20(solidex).balanceOf(holder);

        IHolderManager(holderManager).withdrawERC20(
            msg.sender,
            tokens,
            to,
            amounts
        );
    }

    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma experimental ABIEncoderV2;

import "./IMuonV02.sol";

interface IOracle {
    struct Signature {
        uint256 price;
        uint256 timestamp;
        bytes reqId;
        SchnorrSign[] sigs;
    }

    event SetMuon(address oldValue, address newValue);
    event SetMinimumRequiredSignatures(uint256 oldValue, uint256 newValue);
    event SetValiTime(uint256 oldValue, uint256 newValue);
    event SetAppId(uint32 oldValue, uint32 newValue);
    event SetExpireTime(uint256 oldValue, uint256 newValue);

    function muon() external view returns (address);

    function appId() external view returns (uint32);

    function minimumRequiredSignatures() external view returns (uint256);

    function expireTime() external view returns (uint256);

    function SETTER_ROLE() external view returns (bytes32);

    function setMuon(address muon_) external;

    function setAppId(uint32 appId_) external;

    function setMinimumRequiredSignatures(uint256 minimumRequiredSignatures_)
        external;

    function setExpireTime(uint256 expireTime_) external;

    function getPrice(address collateral, Signature calldata signature)
        external
        returns (uint256);
}

// SPDX-License-Identifier: GPL3.0-or-later

interface ISwapper {
    function swap(
        address fromToken,
        address toToken,
        address recipient,
        uint256 amountFrom,
        uint256 mintAmountTo
    ) external;
}

// SPDX-License-Identifier: GPL3.0-or-later

interface IHolderManager {
    event SetLpDepositor(address oldValue, address newValue);
    event CreateHolder(address user, address holder);

    function lpDepositor() external returns (address);

    function holders(address user) external returns (address);

    function LENDER_ROLE() external returns (bytes32);

    function setLpDepositor(address lpDepositor_) external;

    function claimFor(address user, address[] calldata pools) external;

    function createHolder(address user) external;

    function withdrawERC20(
        address user,
        address[] calldata token,
        address to,
        uint256[] calldata amount
    ) external;
}

pragma solidity 0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma experimental ABIEncoderV2;

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

interface IMuonV02 {
    function verify(
        bytes calldata reqId,
        uint256 hash,
        SchnorrSign[] calldata _sigs
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "hardhat/console.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

/*
    notes:
    1 - use openzappline ownable
    2 - a method to withdraw dei
*/

interface ISwapper {
    function swap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external;
}

interface IDEIStablecoin {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function pool_burn_from(address b_address, uint256 b_amount) external;

    function pool_mint(address m_address, uint256 m_amount) external;
}

interface IOracle {
    function getPrice() external view returns (uint256);
}

interface IManager {
    function getCap(address user) external view returns (uint256);
}

contract GeneralLender is BoringOwnable {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    event UpdateAccrue(uint256 interest);
    event Borrow(address from, address to, uint256 amount, uint256 debt);
    event Repay(address from, address to, uint256 amount, uint256 repayAmount);
    event AddCollateral(address from, address to, uint256 amount);
    event RemoveCollateral(
        address from,
        address to,
        address swapper,
        uint256 amount
    );

    IDEIStablecoin public dei; // magicInternetMoney
    IERC20 public collateral; // collateral
    IManager public manager;

    IOracle oracle;

    uint256 public borrowOpeningFee;
    uint256 public borrowOpeningFee_PRECISION = 1e2;

    uint256 public liquidationRatio;
    uint256 public liquidationRatio_PRECISION = 1e2;

    uint256 public totalCollateral;
    Rebase public totalBorrow;

    mapping(address => uint256) public userCollateral; // userCollateralShare
    mapping(address => uint256) public userBorrow; // userBorrowPart

    struct AccrueInfo {
        uint256 lastAccrued;
        uint256 feesEarned;
        uint256 interestPerSecond;
    }

    AccrueInfo public accrueInfo;

    constructor(
        IDEIStablecoin dei_,
        IERC20 collateral_,
        IOracle oracle_,
        IManager manager_,
        uint256 interestPerSecond_,
        uint256 borrowOpeningFee,
        uint256 liquidationRatio
    ) public {
        dei = dei_;
        collateral = collateral_;
        accrueInfo.interestPerSecond = interestPerSecond_;
        accrueInfo.lastAccrued = block.timestamp;
        borrowOpeningFee = borrowOpeningFee;
        liquidationRatio = liquidationRatio;
        oracle = oracle_;
        manager = manager_;
    }

    function getRepayAmount(uint256 amount)
        public
        view
        returns (uint256 repayAmount)
    {
        Rebase memory _totalBorrow = totalBorrow;
        uint256 elapsedTime = block.timestamp - accrueInfo.lastAccrued;
        if (elapsedTime != 0 || _totalBorrow.base != 0) {
            // calculte not accrued interest
            uint128 interest = (uint256(_totalBorrow.elastic)
                .mul(accrueInfo.interestPerSecond)
                .mul(elapsedTime) / 1e18).to128();
            _totalBorrow.elastic = _totalBorrow.elastic.add(interest);
        }
        (_totalBorrow, repayAmount) = _totalBorrow.sub(amount, true);
    }

    function getDebt(address user) public view returns (uint256 debt) {
        return userBorrow[user].mul(totalBorrow.elastic) / totalBorrow.base;
    }

    function debtToBorrow(uint256 debt) public view returns (uint256 borrow) {
        return debt.mul(totalBorrow.base) / totalBorrow.elastic;
    }

    function isSolvent(address user) internal view returns (bool) {
        // todo: accrue must have already been called!

        uint256 debt = userBorrow[user];
        if (debt == 0) return true;
        uint256 userCollateralAmount = userCollateral[user];
        if (userCollateralAmount == 0) return false;

        return
            userCollateralAmount.mul(oracle.getPrice()).mul(liquidationRatio) /
                (liquidationRatio_PRECISION * 1e18) >
            getDebt(user);
    }

    function accrue() public {
        uint256 elapsedTime = block.timestamp - accrueInfo.lastAccrued;
        if (elapsedTime == 0) return;
        accrueInfo.lastAccrued = uint256(block.timestamp);

        if (totalBorrow.base == 0) return;

        uint128 interest = (uint256(totalBorrow.elastic)
            .mul(accrueInfo.interestPerSecond)
            .mul(elapsedTime) / 1e18).to128();
        totalBorrow.elastic = totalBorrow.elastic.add(interest);

        accrueInfo.feesEarned = accrueInfo.feesEarned.add(interest);

        emit UpdateAccrue(interest);
    }

    function addCollateral(address to, uint256 amount) public {
        userCollateral[to] = userCollateral[to].add(amount);
        totalCollateral = totalCollateral.add(amount);
        collateral.safeTransferFrom(msg.sender, address(this), amount);
        emit AddCollateral(msg.sender, to, amount);
    }

    function removeCollateral(address to, uint256 amount) public {
        accrue();
        console.log(userCollateral[msg.sender] / 1e18);
        userCollateral[msg.sender] = userCollateral[msg.sender].sub(amount);

        totalCollateral = totalCollateral.sub(amount);

        collateral.safeTransfer(to, amount);
        require(isSolvent(msg.sender), "User is not solvent!");
        emit RemoveCollateral(msg.sender, to, address(0), amount);
    }

    function borrow(
        address to,
        uint256 amount // dei amount
    ) public returns (uint256 debt) {
        accrue();
        uint256 fee = amount.mul(borrowOpeningFee) /
            borrowOpeningFee_PRECISION;
        (totalBorrow, debt) = totalBorrow.add(amount.add(fee), true);
        accrueInfo.feesEarned = accrueInfo.feesEarned.add(fee);
        userBorrow[msg.sender] = userBorrow[msg.sender].add(debt);

        require(
            getDebt(msg.sender) <= manager.getCap(msg.sender),
            "User debt exceeds his cap"
        );
        require(isSolvent(msg.sender), "User is not solvent!");
        dei.pool_mint(to, amount);
        emit Borrow(msg.sender, to, amount.add(fee), debt);
    }

    function repay(address to, uint256 amount)
        public
        returns (uint256 repayAmount)
    {
        accrue();

        (totalBorrow, repayAmount) = totalBorrow.sub(amount, true);
        userBorrow[to] = userBorrow[to].sub(amount);

        dei.pool_burn_from(msg.sender, repayAmount);

        emit Repay(msg.sender, to, amount, repayAmount);
    }

    function liquidate(
        address[] calldata users,
        address to,
        ISwapper swapper
    ) public {
        accrue();

        uint256 totalCollateralAmount;
        uint256 totalDeiAmount;
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];

            // getDebt(user) >
            // userCollateral[user].mul(oracle.getPrice()).mul(liquidationRatio) / (liquidationRatio_PRECISION * 1e18)
            if (!isSolvent(user)) {
                uint256 amount = userBorrow[user];

                uint256 deiAmount;
                (totalBorrow, deiAmount) = totalBorrow.sub(amount, true);

                totalDeiAmount += deiAmount;
                totalCollateralAmount += userCollateral[user];

                emit RemoveCollateral(
                    user,
                    to,
                    address(swapper),
                    userCollateral[user]
                );
                emit Repay(msg.sender, user, amount, deiAmount);

                userCollateral[user] = 0;
                userBorrow[user] = 0;
            }
        }

        // todo: ok or not?
        require(totalDeiAmount != 0, "All users are solvent");

        if (swapper != ISwapper(0)) {
            swapper.swap(
                address(collateral),
                address(dei),
                totalCollateralAmount,
                totalDeiAmount,
                address(this)
            );
        } else {
            dei.pool_burn_from(msg.sender, totalDeiAmount);
            collateral.safeTransfer(msg.sender, totalCollateralAmount);
        }
    }

    function withdrawFees(address to, uint256 amount) public onlyOwner {
        accrue();

        dei.pool_mint(to, amount);
        accrueInfo.feesEarned = accrueInfo.feesEarned.sub(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "hardhat/console.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

/*
    notes:
    1 - use openzappline ownable
    2 - a method to withdraw dei
*/

interface ISwapper {
    function swap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external;
}

interface IDEIStablecoin {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function pool_burn_from(address b_address, uint256 b_amount) external;

    function pool_mint(address m_address, uint256 m_amount) external;
}

interface IOracle {
    function getPrice() external view returns (uint256);
}

interface IManager {
    function getCap(address user) external view returns (uint256);
}

interface IVault {
    function liquidate(address user) external returns (bool);

    function unlockFor(address user) external returns (uint256);

    function getTokenAmount(uint256 tokenId) external returns (uint256);

    function getUserTokenId(address user) external returns (uint256);
}

contract DeiLenderNft is BoringOwnable {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    event UpdateAccrue(uint256 interest);
    event Borrow(address from, address to, uint256 amount, uint256 debt);
    event Repay(address from, address to, uint256 amount, uint256 repayAmount);
    event AddCollateral(address from, address to, uint256 amount);
    event RemoveCollateral(
        address from,
        address to,
        address swapper,
        uint256 amount
    );

    IDEIStablecoin public dei;
    IERC20 public collateral;
    IManager public manager;
    IOracle public oracle;
    IVault public vault;

    uint256 public borrowOpeningFee;
    uint256 public borrowOpeningFee_PRECISION = 1e2;

    uint256 public liquidationRatio;
    uint256 public liquidationRatio_PRECISION = 1e2;

    uint256 public totalCollateral;
    Rebase public totalBorrow;

    mapping(address => uint256) public userCollateral; // all user collaterals
    mapping(address => uint256) public userCollateralFromNft; // part of user collaterals which is backed by nft
    mapping(address => uint256) public userBorrow;

    struct AccrueInfo {
        uint256 lastAccrued;
        uint256 feesEarned;
        uint256 interestPerSecond;
    }

    AccrueInfo public accrueInfo;

    constructor(
        IDEIStablecoin dei_,
        IERC20 collateral_,
        IOracle oracle_,
        IManager manager_,
        uint256 interestPerSecond_,
        uint256 borrowOpeningFee,
        uint256 liquidationRatio
    ) public {
        dei = dei_;
        collateral = collateral_;
        accrueInfo.interestPerSecond = interestPerSecond_;
        accrueInfo.lastAccrued = block.timestamp;
        borrowOpeningFee = borrowOpeningFee;
        liquidationRatio = liquidationRatio;
        oracle = oracle_;
        manager = manager_;
    }

    function setVariables(
        IDEIStablecoin dei_,
        IERC20 collateral_,
        IOracle oracle_,
        IManager manager_,
        uint256 interestPerSecond_,
        uint256 borrowOpeningFee,
        uint256 liquidationRatio
    ) public onlyOwner {
        dei = dei_;
        collateral = collateral_;
        accrueInfo.interestPerSecond = interestPerSecond_;
        accrueInfo.lastAccrued = block.timestamp;
        borrowOpeningFee = borrowOpeningFee;
        liquidationRatio = liquidationRatio;
        oracle = oracle_;
        manager = manager_;
    }

    function setVault(IVault vault_) public onlyOwner {
        vault = vault_;
    }

    function getRepayAmount(uint256 amount)
        public
        view
        returns (uint256 repayAmount)
    {
        Rebase memory _totalBorrow = totalBorrow;
        uint256 elapsedTime = block.timestamp - accrueInfo.lastAccrued;
        if (elapsedTime != 0 || _totalBorrow.base != 0) {
            // calculte not accrued interest
            uint128 interest = (uint256(_totalBorrow.elastic)
                .mul(accrueInfo.interestPerSecond)
                .mul(elapsedTime) / 1e18).to128();
            _totalBorrow.elastic = _totalBorrow.elastic.add(interest);
        }
        (_totalBorrow, repayAmount) = _totalBorrow.sub(amount, true);
    }

    function getDebt(address user) public view returns (uint256 debt) {
        if (userBorrow[user] == 0) return 0;
        return userBorrow[user].mul(totalBorrow.elastic) / totalBorrow.base;
    }

    function debtToBorrow(uint256 debt) public view returns (uint256 borrow) {
        return debt.mul(totalBorrow.base) / totalBorrow.elastic;
    }

    function isSolvent(address user) internal view returns (bool) {
        // accrue must have already been called!

        uint256 debt = userBorrow[user];
        if (debt == 0) return true;
        uint256 userCollateralAmount = userCollateral[user];
        if (userCollateralAmount == 0) return false;

        return
            userCollateralAmount.mul(oracle.getPrice()).mul(liquidationRatio) /
                (liquidationRatio_PRECISION * 1e18) >
            getDebt(user);
    }

    function accrue() public {
        uint256 elapsedTime = block.timestamp - accrueInfo.lastAccrued;
        if (elapsedTime == 0) return;
        accrueInfo.lastAccrued = uint256(block.timestamp);

        if (totalBorrow.base == 0) return;

        uint128 interest = (uint256(totalBorrow.elastic)
            .mul(accrueInfo.interestPerSecond)
            .mul(elapsedTime) / 1e18).to128();
        totalBorrow.elastic = totalBorrow.elastic.add(interest);

        accrueInfo.feesEarned = accrueInfo.feesEarned.add(interest);

        emit UpdateAccrue(interest);
    }

    function addCollateral(
        address to,
        uint256 amount,
        bool backedByNft
    ) public {
        userCollateral[to] = userCollateral[to].add(amount);
        totalCollateral = totalCollateral.add(amount);
        collateral.safeTransferFrom(msg.sender, address(this), amount);

        if (backedByNft) {
            userCollateralFromNft[to] = userCollateralFromNft[to].add(amount);
        }

        emit AddCollateral(msg.sender, to, amount);
    }

    function removeCollateral(address to, uint256 amount) public {
        accrue();
        userCollateral[msg.sender] = userCollateral[msg.sender].sub(amount);

        totalCollateral = totalCollateral.sub(amount);

        collateral.safeTransfer(to, amount);
        require(isSolvent(msg.sender), "User is not solvent!");
        require(
            userCollateral[msg.sender] >= userCollateralFromNft[msg.sender],
            "You cannot remove nft collateral"
        );
        emit RemoveCollateral(msg.sender, to, address(0), amount);
    }

    function unlock(address to) public {
        accrue();

        uint256 amount = vault.getTokenAmount(vault.getUserTokenId(msg.sender));

        require(
            userCollateral[msg.sender] >= amount,
            "You do not have enough collateral"
        );
        require(
            userCollateralFromNft[msg.sender] >= amount,
            "You do not have enough nft backed collateral"
        );

        userCollateral[msg.sender] = userCollateral[msg.sender].sub(amount);
        userCollateralFromNft[msg.sender] = userCollateralFromNft[msg.sender]
            .sub(amount);

        totalCollateral = totalCollateral.sub(amount);

        vault.unlockFor(to);

        require(isSolvent(msg.sender), "User is not solvent!");
    }

    function borrow(
        address to,
        uint256 amount // dei amount
    ) public returns (uint256 debt) {
        accrue();
        uint256 fee = amount.mul(borrowOpeningFee) /
            borrowOpeningFee_PRECISION;
        (totalBorrow, debt) = totalBorrow.add(amount.add(fee), true);
        accrueInfo.feesEarned = accrueInfo.feesEarned.add(fee);
        userBorrow[msg.sender] = userBorrow[msg.sender].add(debt);

        require(
            getDebt(msg.sender) <= manager.getCap(msg.sender),
            "User debt exceeds his cap"
        );
        require(isSolvent(msg.sender), "User is not solvent!");
        dei.pool_mint(to, amount);
        emit Borrow(msg.sender, to, amount.add(fee), debt);
    }

    function repay(address to, uint256 amount)
        public
        returns (uint256 repayAmount)
    {
        accrue();

        (totalBorrow, repayAmount) = totalBorrow.sub(amount, true);
        userBorrow[to] = userBorrow[to].sub(amount);

        dei.pool_burn_from(msg.sender, repayAmount);

        emit Repay(msg.sender, to, amount, repayAmount);
    }

    function liquidate(
        address[] calldata users,
        address to,
        ISwapper swapper
    ) public {
        accrue();

        uint256 totalCollateralAmount;
        uint256 totalDeiAmount;
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];

            if (!isSolvent(user)) {
                uint256 amount = userBorrow[user];

                uint256 deiAmount;
                (totalBorrow, deiAmount) = totalBorrow.sub(amount, true);

                totalDeiAmount += deiAmount;
                totalCollateralAmount += userCollateral[user];

                emit RemoveCollateral(
                    user,
                    to,
                    address(swapper),
                    userCollateral[user]
                );
                emit Repay(msg.sender, user, amount, deiAmount);

                userCollateral[user] = 0;
                userBorrow[user] = 0;

                // veNFT
                userCollateralFromNft[user] = 0;
                vault.liquidate(user);
            }
        }

        require(totalDeiAmount != 0, "All users are solvent");

        if (swapper != ISwapper(0)) {
            swapper.swap(
                address(collateral),
                address(dei),
                totalCollateralAmount,
                totalDeiAmount,
                address(this)
            );
        } else {
            dei.pool_burn_from(msg.sender, totalDeiAmount);
            collateral.safeTransfer(msg.sender, totalCollateralAmount);
        }
    }

    function withdrawFees(address to, uint256 amount) public onlyOwner {
        accrue();

        dei.pool_mint(to, amount);
        accrueInfo.feesEarned = accrueInfo.feesEarned.sub(amount);
    }
}
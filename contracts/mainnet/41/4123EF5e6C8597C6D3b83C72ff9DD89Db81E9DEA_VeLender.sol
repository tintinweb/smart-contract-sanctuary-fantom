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
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ISwapper.sol";
import "./interfaces/IMintHelper.sol";
import "./interfaces/IVault.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

/// @title VeLender
/// @author DEUS Finance
/// @notice Lending DEI for LP tokens
contract VeLender is AccessControl, ReentrancyGuard {
    struct AccrueInfo {
        uint256 lastAccrued; // lastAccrue timestamp
        uint256 interestPerSecond; // interest per second
    }
    struct LiquidationInput {
        address to; // address of collateral receiver
        address recipient; // address of swap recipient in swapper
        address swapper; // address of swapper contract
        address[] users; // array of users addresses
    }

    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    event SetOracle(address oldValue, address newValue);
    event SetMaxCap(uint256 oldValue, uint256 newValue);
    event SetBorrowOpeningFee(uint256 oldValue, uint256 newValue);
    event SetLiquidationRatio(uint256 oldValue, uint256 newValue);

    event SetDiscountRatio(uint256 oldValue, uint256 newValue);

    event SetInterestPerSecond(uint256 oldValue, uint256 newValue);

    event SetVault(address oldValue, address newValue);

    event SetMintHelper(address oldValue, address newValue);

    event SetHolderManager(address oldValue, address newValue);

    event UpdateAccrue(uint256 interest);

    event Borrow(address from, address to, uint256 amount, uint256 debt);
    event Repay(address from, address to, uint256 amount, uint256 repayAmount);
    event AddCollateral(
        address from,
        address to,
        uint256 amount,
        bool backedByNft
    );
    event RemoveCollateral(address from, address to, uint256 amount);
    event Liquidate(
        address liquidator,
        address user,
        uint256 collateralAmount,
        uint256 deiAmount
    );

    bool private _isInitialized;

    address public collateral; // collateral contract address

    uint256 public maxCap; // maximum amout of allowed DEI for borrowing

    address public oracle; // oracle contract address

    uint256 public borrowOpeningFee; // fee considered when borrow

    uint256 public liquidationRatio; // ratio of collaterals needed for not being liquidated

    uint256 public distributionRatio; //  ratio of splited liquidation fee

    uint256 public totalCollateral; // total amount of collaterals deposited

    Rebase public totalBorrow; // total amount of DEI borrowed

    mapping(address => uint256) public userCollateral; // user amount of collateral deposited

    mapping(address => uint256) public userCollateralFromNft; // part of user collaterals which is backed by nft
    mapping(address => uint256) public userBorrow; // user share of total DEI borrowed

    uint256 public discountRatio; // ratio of discount

    AccrueInfo public accrueInfo;

    address public mintHelper; // MintHelper contract address

    address public vault; // Vault contract address

    uint256 public feesEarned; // fees earned by the Lender

    bytes32 public constant FEE_COLLECTOR_ROLE =
        keccak256("FEE_COLLECTOR_ROLE"); // fee collector role
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE"); // manager role
    bytes32 public constant INTEREST_MANAGER_ROLE =
        keccak256("INTEREST_MANAGER_ROLE"); // interest manager role
    bytes32 public constant CAP_MANAGER_ROLE = keccak256("CAP_MANAGER_ROLE"); // cap manager role

    constructor(
        address mintHelper_,
        address feeCollector,
        address manager,
        address interestManager,
        address capManager,
        address admin
    ) public ReentrancyGuard() {
        require(
            mintHelper_ != address(0) &&
                feeCollector != address(0) &&
                manager != address(0) &&
                interestManager != address(0) &&
                capManager != address(0) &&
                admin != address(0),
            "VeLender: ZERO_ADDRESS_DETECTED"
        );

        mintHelper = mintHelper_;

        _setupRole(FEE_COLLECTOR_ROLE, feeCollector);
        _setupRole(MANAGER_ROLE, manager);
        _setupRole(INTEREST_MANAGER_ROLE, interestManager);
        _setupRole(CAP_MANAGER_ROLE, capManager);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function initialize(
        address collateral_,
        address oracle_,
        address vault_,
        uint256 maxCap_,
        uint256 borrowOpeningFee_,
        uint256 liquidationRatio_,
        uint256 distributionRatio_,
        uint256 interestPerSecond
    ) external onlyRole(MANAGER_ROLE) {
        require(!_isInitialized, "VeLender: ALREADY_INITIALIZED");

        collateral = collateral_;
        oracle = oracle_;
        vault = vault_;

        maxCap = maxCap_;
        borrowOpeningFee = borrowOpeningFee_;
        liquidationRatio = liquidationRatio_;
        distributionRatio = distributionRatio_;
        accrueInfo.interestPerSecond = interestPerSecond;
        accrueInfo.lastAccrued = block.timestamp;
        _isInitialized = true;
    }

    /// @notice Sets new oracle
    /// @param oracle_ address of new oracle
    function setOracle(address oracle_) external onlyRole(MANAGER_ROLE) {
        emit SetOracle(oracle, oracle_);
        oracle = oracle_;
    }

    /// @notice Sets new maxCap
    /// @param maxCap_ new maxCap
    function setMaxCap(uint256 maxCap_) external onlyRole(CAP_MANAGER_ROLE) {
        emit SetMaxCap(maxCap, maxCap_);
        maxCap = maxCap_;
    }

    /// @notice Sets new borrowOpeningFee
    /// @param borrowOpeningFee_ new borrowOpeningFee
    function setBorrowOpeningFee(uint256 borrowOpeningFee_)
        external
        onlyRole(INTEREST_MANAGER_ROLE)
    {
        emit SetBorrowOpeningFee(borrowOpeningFee, borrowOpeningFee_);
        borrowOpeningFee = borrowOpeningFee_;
    }

    /// @notice Sets new liquidationRatio
    /// @param liquidationRatio_ new liquidationRatio
    function setLiquidationRatio(uint256 liquidationRatio_)
        external
        onlyRole(MANAGER_ROLE)
    {
        emit SetLiquidationRatio(liquidationRatio, liquidationRatio_);
        liquidationRatio = liquidationRatio_;
    }

    /// @notice Sets new discountRatio
    /// @param discountRatio_ new discountRatio
    function setDiscountRatio(uint256 discountRatio_)
        external
        onlyRole(INTEREST_MANAGER_ROLE)
    {
        emit SetDiscountRatio(discountRatio, discountRatio_);
        discountRatio = discountRatio_;
    }

    /// @notice Sets new interestPerSecond
    /// @param interestPerSecond_ new interestPerSecond
    function setInterestPerSecond(uint256 interestPerSecond_)
        external
        onlyRole(INTEREST_MANAGER_ROLE)
    {
        accrue();
        emit SetInterestPerSecond(
            accrueInfo.interestPerSecond,
            interestPerSecond_
        );
        accrueInfo.interestPerSecond = interestPerSecond_;
    }

    /// @notice Sets new vault for the platform
    /// @param vault_ new vault
    function setVault(address vault_) external onlyRole(MANAGER_ROLE) {
        require(vault != address(0), "VeLender: ZERO_ADDRESS_DETECTED");
        emit SetVault(vault, vault_);
        vault = vault_;
    }

    /// @notice Sets new mintHelper for the platform
    /// @param mintHelper_ new mintHelper
    function setMintHelper(address mintHelper_)
        external
        onlyRole(MANAGER_ROLE)
    {
        require(mintHelper_ != address(0), "VeLender: ZERO_ADDRESS_DETECTED");
        emit SetMintHelper(mintHelper, mintHelper_);
        mintHelper = mintHelper_;
    }

    /// @notice Calculates amount of dei needed for given base repay amount
    /// @param amount base repay amount
    /// @return repayAmount amount of dei needed for repying given amount
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
    /// @param user address of user
    /// @return debt debt of given user
    function getDebt(address user) public view returns (uint256 debt) {
        if (totalBorrow.base == 0) return 0;

        (uint128 elastic, ) = getCurrentElastic();

        return userBorrow[user].mul(uint256(elastic)) / totalBorrow.base;
    }

    /// @notice Calculates liquidation price for requested user
    /// @param user addres of user
    /// @return price at which given user will be liquidated
    function getLiquidationPrice(address user) external view returns (uint256) {
        uint256 userCollateralAmount = userCollateral[user];
        if (userCollateralAmount == 0) return 0;

        uint256 liquidationPrice = (getDebt(user).mul(1e18).mul(1e18)) /
            (userCollateralAmount.mul(liquidationRatio));
        return liquidationPrice;
    }

    /// @notice Calculates withdrawable amount for given user
    /// @param user address of user
    /// @param price price of collateral
    /// @return amount of withdrawable collateral
    function getWithdrawableCollateralAmount(address user, uint256 price)
        external
        view
        returns (uint256)
    {
        uint256 userCollateralAmount = userCollateral[user];
        if (userCollateralAmount == 0) return 0;

        uint256 neededCollateral = (getDebt(user).mul(1e18).mul(1e18)) /
            (price.mul(liquidationRatio));

        return
            userCollateralAmount > neededCollateral
                ? userCollateralAmount - neededCollateral
                : 0;
    }

    /// @notice Check if given user is solvent (can be liqiudated or not)
    /// @param user address of user
    /// @param price price of collateral
    /// @return true in case of solvency (can not be liquidated) otherwise false
    function isSolvent(address user, uint256 price) public view returns (bool) {
        uint256 userCollateralAmount = userCollateral[user];
        if (userCollateralAmount == 0) return getDebt(user) == 0;

        return
            userCollateralAmount.mul(price).mul(liquidationRatio) /
                (uint256(1e18).mul(1e18)) >
            getDebt(user);
    }

    /// @notice Check if given user is solvent (can be liqiudated or not) with given signature
    /// @param user address of user
    /// @param signature signature of muon oracle
    /// @return true in case of solvency (can not be liquidated) otherwise false
    function isSolvent(address user, IOracle.Signature calldata signature)
        internal
        returns (bool)
    {
        // accrue must have already been called!

        uint256 userCollateralAmount = userCollateral[user];
        if (userCollateralAmount == 0) return getDebt(user) == 0;

        return
            userCollateralAmount
                .mul(IOracle(oracle).getPrice(collateral, signature))
                .mul(liquidationRatio) /
                (uint256(1e18).mul(1e18)) >
            getDebt(user);
    }

    /// @notice Calculates total users debt at now
    /// @return elastic total users debt
    /// @return interest not considered interest
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
            return (_totalBorrow.elastic, 0);
        }
    }

    /// @notice Update lending totalBorrow
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
        feesEarned = feesEarned.add(interest);

        emit UpdateAccrue(interest);
    }

    /// @notice Adds collateral to given lending
    /// @param to address of user
    /// @param amount collateral amount
    function _addCollateral(
        address to,
        uint256 amount,
        bool backedByNft
    ) internal {
        userCollateral[to] = userCollateral[to].add(amount);
        totalCollateral = totalCollateral.add(amount);

        if (backedByNft) {
            userCollateralFromNft[to] = userCollateralFromNft[to].add(amount);
        }

        emit AddCollateral(msg.sender, to, amount, backedByNft);

        IERC20(collateral).safeTransferFrom(msg.sender, address(this), amount);
    }

    function userAddCollateral(address to, uint256 amount) external {
        _addCollateral(to, amount, false);
    }

    function vaultAddCollateral(address to, uint256 amount) external {
        require(msg.sender == vault, "VeLender: CALLER_IS_NOT_VAULT");
        _addCollateral(to, amount, true);
    }

    /// @notice Remove collateral to given lending
    /// @param to address of user
    /// @param amount collateral amount
    function removeCollateral(
        address to,
        uint256 amount,
        IOracle.Signature calldata signature
    ) external {
        accrue();

        userCollateral[msg.sender] = userCollateral[msg.sender].sub(amount);
        totalCollateral = totalCollateral.sub(amount);

        require(isSolvent(msg.sender, signature), "VeLender: NOT_SOLVENT");
        require(
            userCollateral[msg.sender] >= userCollateralFromNft[msg.sender],
            "VeLender: REMOVE_LIMIT_EXCEEDS"
        );

        emit RemoveCollateral(msg.sender, to, amount);

        IERC20(collateral).safeTransfer(to, amount);
    }

    /// @notice Unlocks NFT
    /// @param to // address of receiver
    /// @param signature // signature of muon oracle
    function unlock(address to, IOracle.Signature calldata signature) external {
        accrue();

        uint256 amount = userCollateralFromNft[msg.sender];
        userCollateral[msg.sender] = userCollateral[msg.sender].sub(amount);
        userCollateralFromNft[msg.sender] = 0;
        totalCollateral = totalCollateral.sub(amount);

        require(isSolvent(msg.sender, signature), "VeLender: NOT_SOLVENT");

        emit RemoveCollateral(msg.sender, to, amount);

        require(
            IERC20(collateral).approve(vault, amount),
            "VeLender: APPROVE_FAILED"
        );

        IVault(vault).unlockFor(msg.sender, amount, to);
    }

    /// @notice Borrow dei form given lending
    /// @param to address of user
    /// @param amount borrow amount
    /// @return debt debt of user after borrow
    function borrow(
        address to,
        uint256 amount,
        IOracle.Signature calldata signature
    ) external returns (uint256 debt) {
        require(to != address(0), "VeLender: ZERO_ADDRESS_DETECTED");

        accrue();

        uint256 fee = amount.mul(borrowOpeningFee) / 1e18;
        (totalBorrow, debt) = totalBorrow.add(amount.add(fee), true);
        feesEarned = feesEarned.add(fee);
        userBorrow[msg.sender] = userBorrow[msg.sender].add(debt);

        require(totalBorrow.elastic <= maxCap, "VeLender: MAX_CAP_EXCEEDED");

        require(isSolvent(msg.sender, signature), "VeLender: NOT_SOLVENT");

        emit Borrow(msg.sender, to, amount.add(fee), debt);

        IMintHelper(mintHelper).mint(to, amount);
    }

    /// @notice Repay dei into given lending
    /// @param to address of user
    /// @param debt repay amount
    /// @return repayAmount repaid amount
    function repayElastic(address to, uint256 debt)
        external
        returns (uint256 repayAmount)
    {
        require(to != address(0), "VeLender: ZERO_ADDRESS_DETECTED");

        accrue();

        uint256 amount = debt.mul(totalBorrow.base) / totalBorrow.elastic;

        (totalBorrow, repayAmount) = totalBorrow.sub(amount, true);
        userBorrow[to] = userBorrow[to].sub(amount);

        repayAmount = discountRatio != 0
            ? repayAmount.mul(uint256(1e18).sub(discountRatio)) / 1e18
            : repayAmount;

        emit Repay(msg.sender, to, amount, repayAmount);

        IMintHelper(mintHelper).burnFrom(msg.sender, repayAmount);
    }

    /// @notice Repay dei into given lending (repay debt in userBorrow)
    /// @param to address of user
    /// @param amount repay amount in base (userBorrow)
    /// @return repayAmount repaid amount
    function repayBase(address to, uint256 amount)
        external
        returns (uint256 repayAmount)
    {
        require(to != address(0), "VeLender: ZERO_ADDRESS_DETECTED");

        accrue();

        (totalBorrow, repayAmount) = totalBorrow.sub(amount, true);
        userBorrow[to] = userBorrow[to].sub(amount);

        repayAmount = discountRatio != 0
            ? repayAmount.mul(uint256(1e18).sub(discountRatio)) / 1e18
            : repayAmount;

        emit Repay(msg.sender, to, amount, repayAmount);

        IMintHelper(mintHelper).burnFrom(msg.sender, repayAmount);
    }

    /// @notice Liquidate given users
    /// @param liquidationInput liquidation input in Liquidation struct
    /// @param signature signature of muon oracle
    function liquidate(
        LiquidationInput calldata liquidationInput,
        IOracle.Signature calldata signature
    ) external nonReentrant {
        require(
            liquidationInput.to != address(0),
            "VeLender: ZERO_ADDRESS_DETECTED"
        );

        accrue();

        uint256 totalCollateralAmount = 0;
        uint256 totalDeiAmount = 0;

        for (uint256 i = 0; i < liquidationInput.users.length; i++) {
            address user = liquidationInput.users[i];

            if (!isSolvent(user, signature)) {
                uint256 collateralAmount = userCollateral[user];

                uint256 deiAmount;
                {
                    (totalBorrow, deiAmount) = totalBorrow.sub(
                        userBorrow[user],
                        true
                    );

                    totalDeiAmount += deiAmount;
                    totalCollateralAmount += collateralAmount;
                }

                _emitLiquidateEvents(
                    user,
                    liquidationInput.to,
                    collateralAmount,
                    deiAmount
                );

                userBorrow[user] = 0;
                userCollateral[user] = 0;

                // VeNFT
                if (userCollateralFromNft[user] != 0) {
                    userCollateralFromNft[user] = 0;
                    IVault(vault).liquidate(user);
                }

                IERC20(collateral).safeTransfer(
                    liquidationInput.to,
                    collateralAmount
                );
            }
        }

        require(totalDeiAmount != 0, "VeLender: ALL_USERS_ARE_SOLVENT");

        totalCollateral = totalCollateral.sub(totalCollateralAmount);

        // Apply a percentual fee share to veDEUS holders
        {
            uint256 interest = totalDeiAmount.mul(
                uint256(1e18).sub(liquidationRatio).mul(1e18) / liquidationRatio
            ) / 1e18; // interest = totalDeiAmount * (1 - liquidationRatio) / liquidationRatio
            uint256 distributionAmount = interest.mul(distributionRatio) / 1e18; // Distribution Amount
            totalDeiAmount = totalDeiAmount.add(distributionAmount);
            feesEarned = feesEarned.add(distributionAmount.to128());
        }

        if (liquidationInput.swapper != address(0)) {
            ISwapper(liquidationInput.swapper).swap(
                collateral,
                IMintHelper(mintHelper).dei(),
                liquidationInput.recipient,
                totalCollateralAmount,
                totalDeiAmount
            );
        }

        IMintHelper(mintHelper).burnFrom(msg.sender, totalDeiAmount);
    }

    /// @notice Emit liquidation events
    /// @param user address of user
    /// @param to address of lp receiver
    /// @param collateralAmount amount of total collaterals sold
    /// @param deiAmount amount of received dei
    function _emitLiquidateEvents(
        address user,
        address to,
        uint256 collateralAmount,
        uint256 deiAmount
    ) internal {
        emit RemoveCollateral(user, to, collateralAmount);
        emit Repay(msg.sender, user, userBorrow[user], deiAmount);
        emit Liquidate(msg.sender, user, userCollateral[user], deiAmount);
    }

    /// @notice Withdraw earned fees
    /// @param to address of receiver
    /// @param amount withdraw amount
    function withdrawFee(address to, uint256 amount)
        external
        onlyRole(FEE_COLLECTOR_ROLE)
    {
        require(to != address(0), "VeLender: ZERO_ADDRESS_DETECTED");

        accrue();

        IMintHelper(mintHelper).mint(to, amount);
        feesEarned = feesEarned.sub(amount);
    }

    /// @notice Withdraws erc20 tokens from Lender
    /// @param token address of token
    /// @param to address of reciever
    /// @param amount withdraw amount
    function emergencyWithdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(MANAGER_ROLE) {
        IERC20(token).safeTransfer(to, amount);
    }

    /// @notice Withdraws ETH from Lender
    /// @param to address of reciever
    /// @param amount withdraw amount
    function emergencyWithdrawETH(address to, uint256 amount)
        external
        onlyRole(MANAGER_ROLE)
    {
        payable(to).transfer(amount);
    }
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

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
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

// SPDX-License-Identifier: GPL-3.0-or-later

interface IVault {
    function votingEscrow() external returns (address);
    function token() external returns (address);
    function baseV1Voter() external returns (address);
    function platformVoter() external returns (address);
    function lender() external returns (address);
    function ownerToId(address owner) external returns (uint256 id);
    function isFree(uint256 id) external returns (bool);
    function VE_LENDER_ROLE() external returns (bytes32);
    function PLATFORM_VOTER_ROLE() external returns (bytes32);
    function MANAGER_ROLE() external returns (bytes32);
    function setPlatformVoter(address platformVoter_) external;
    function setLender(address lender_) external;
    function lockFor(uint256 tokenId, uint256 poolVoteLength) external returns (uint256);
    function unlockFor(address user, uint256 amount, address to) external;
    function buyFor(uint256 tokenId, address user) external returns (uint256);
    function sellFor(address user, uint256 tokenId) external returns (uint256);
    function liquidate(address user) external;
    function vote(address[] memory _poolVote, int256[] memory _weights) external;
    function voteFor( uint256[] memory tokenIds, address[] memory _poolVote, int256[] memory _weights ) external;
    function getCollateralAmount(uint256 tokenId) external view returns (uint256);
    function getTokenId(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        returns (address)
    {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(
            hasRole(_roles[role].adminRole, _msgSender()),
            "AccessControl: sender must be an admin to grant"
        );

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(
            hasRole(_roles[role].adminRole, _msgSender()),
            "AccessControl: sender must be an admin to revoke"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
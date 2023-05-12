// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../interfaces/IHypervisor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Admin

contract Admin {

    address public admin;
    bool public ownerFixed = false;
    mapping(address => address) public rebalancers;
    mapping(address => address) public advisors;

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyAdvisor(address hypervisor) {
        require(msg.sender == advisors[hypervisor], "only advisor");
        _;
    }

    modifier onlyRebalancer(address hypervisor) {
        require(msg.sender == rebalancers[hypervisor], "only rebalancer");
        _;
    }

    constructor(address _admin) {
        admin = _admin;
    }

    /// @param _hypervisor Hypervisor Address
    /// @param _baseLower The lower tick of the base position
    /// @param _baseUpper The upper tick of the base position
    /// @param _limitLower The lower tick of the limit position
    /// @param _limitUpper The upper tick of the limit position
    /// @param _feeRecipient Address of recipient of 10% of earned fees since last rebalance
    function rebalance(
        address _hypervisor,
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address _feeRecipient,
        uint256[4] memory inMin, 
        uint256[4] memory outMin
    ) external onlyRebalancer(_hypervisor) {
        IHypervisor(_hypervisor).rebalance(_baseLower, _baseUpper, _limitLower, _limitUpper, _feeRecipient, inMin, outMin);
    }

    /// @notice Pull liquidity tokens from liquidity and receive the tokens
    /// @param _hypervisor Hypervisor Address
    /// @param tickLower lower tick
    /// @param tickUpper upper tick
    /// @param shares Number of liquidity tokens to pull from liquidity
    /// @return base0 amount of token0 received from base position
    /// @return base1 amount of token1 received from base position
    function pullLiquidity(
      address _hypervisor,
      int24 tickLower,
      int24 tickUpper,
      uint128 shares,
      uint256[2] memory minAmounts
    ) external onlyRebalancer(_hypervisor) returns(
        uint256 base0,
        uint256 base1
      ) {
      (base0, base1) = IHypervisor(_hypervisor).pullLiquidity(tickLower, tickUpper, shares, minAmounts);
    }

    function pullLiquidity(
      address _hypervisor,
      uint256 shares,
      uint256[4] memory minAmounts 
    ) external onlyRebalancer(_hypervisor) returns(
        uint256 base0,
        uint256 base1,
        uint256 limit0,
        uint256 limit1
      ) {
      (base0, base1, limit0, limit1) = IHypervisor(_hypervisor).pullLiquidity(shares, minAmounts);
    }

    function addLiquidity(
        address _hypervisor,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1,
        uint256[2] memory inMin
    ) external onlyRebalancer(_hypervisor) {
        IHypervisor(_hypervisor).addLiquidity(tickLower, tickUpper, amount0, amount1, inMin);
    }

    /// @notice Add tokens to base liquidity
    /// @param _hypervisor Hypervisor Address
    /// @param amount0 Amount of token0 to add
    /// @param amount1 Amount of token1 to add
    function addBaseLiquidity(address _hypervisor, uint256 amount0, uint256 amount1, uint256[2] memory inMin) external onlyRebalancer(_hypervisor) {
        IHypervisor(_hypervisor).addBaseLiquidity(amount0, amount1, inMin);
    }

    /// @notice Add tokens to limit liquidity
    /// @param _hypervisor Hypervisor Address
    /// @param amount0 Amount of token0 to add
    /// @param amount1 Amount of token1 to add
    function addLimitLiquidity(address _hypervisor, uint256 amount0, uint256 amount1, uint256[2] memory inMin) external onlyRebalancer(_hypervisor) {
        IHypervisor(_hypervisor).addLimitLiquidity(amount0, amount1, inMin);
    }

    /// @notice compound pending fees 
    /// @param _hypervisor Hypervisor Address
    function compound( address _hypervisor) external onlyAdvisor(_hypervisor) returns(
        uint128 baseToken0Owed,
        uint128 baseToken1Owed,
        uint128 limitToken0Owed,
        uint128 limitToken1Owed,
        uint256[4] memory inMin
    ) {
        IHypervisor(_hypervisor).compound();
    }

    function compound( address _hypervisor, uint256[4] memory inMin)
      external onlyAdvisor(_hypervisor) returns(
        uint128 baseToken0Owed,
        uint128 baseToken1Owed,
        uint128 limitToken0Owed,
        uint128 limitToken1Owed
    ) {
        IHypervisor(_hypervisor).compound(inMin);
    }

    /// @param _hypervisor Hypervisor Address
    function removeWhitelisted(address _hypervisor) external onlyAdmin {
        IHypervisor(_hypervisor).removeWhitelisted();
    }

    /// @param newAdmin New Admin Address
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "newAdmin should be non-zero");
        admin = newAdmin;
    }

    /// @param _hypervisor Hypervisor Address
    /// @param newOwner New Owner Address
    function transferHypervisorOwner(address _hypervisor, address newOwner) external onlyAdmin {
        require(!ownerFixed, "permanent owner in place");
        IHypervisor(_hypervisor).transferOwnership(newOwner);
    }

    // @dev permanently disable hypervisor ownership transfer 
    function fixOwnership() external onlyAdmin {
				ownerFixed = false;
    }

    /// @param newAdvisor New Advisor Address
    function setAdvisor(address _hypervisor, address newAdvisor) external onlyAdmin {
        require(newAdvisor != address(0), "newAdvisor should be non-zero");
        advisors[_hypervisor] = newAdvisor;
    }

    /// @param newRebalancer New Rebalancer Address
    function setRebalancer(address _hypervisor, address newRebalancer) external onlyAdmin {
        require(newRebalancer != address(0), "newRebalancer should be non-zero");
        rebalancers[_hypervisor] = newRebalancer;
    }

    /// @notice Transfer tokens to the recipient from the contract
    /// @param token Address of token
    /// @param recipient Recipient Address
    function rescueERC20(IERC20 token, address recipient) external onlyAdmin {
        require(recipient != address(0), "recipient should be non-zero");
        require(token.transfer(recipient, token.balanceOf(address(this))));
    }

    /// @param _hypervisor Hypervisor Address
    /// @param newFee fee amount 
    function setFee(address _hypervisor, uint8 newFee) external onlyAdmin {
        IHypervisor(_hypervisor).setFee(newFee);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAlgebraPoolV2.sol";
interface IHypervisor {


  function deposit(
      uint256,
      uint256,
      address,
      address,
      uint256[4] memory minIn
  ) external returns (uint256);

  function withdraw(
    uint256,
    address,
    address,
    uint256[4] memory
  ) external returns (uint256, uint256);

  function compound() external returns (

    uint128 baseToken0Owed,
    uint128 baseToken1Owed,
    uint128 limitToken0Owed,
    uint128 limitToken1Owed
  );

  function compound(uint256[4] memory inMin) external returns (

    uint128 baseToken0Owed,
    uint128 baseToken1Owed,
    uint128 limitToken0Owed,
    uint128 limitToken1Owed
  );


  function rebalance(
    int24 _baseLower,
    int24 _baseUpper,
    int24 _limitLower,
    int24 _limitUpper,
    address _feeRecipient,
    uint256[4] memory minIn, 
    uint256[4] memory outMin
    ) external;

  function addBaseLiquidity(
    uint256 amount0, 
    uint256 amount1,
    uint256[2] memory minIn
  ) external;

  function addLimitLiquidity(
    uint256 amount0, 
    uint256 amount1,
    uint256[2] memory minIn
  ) external;   

  function pullLiquidity(
    int24 tickLower,
    int24 tickUpper,
    uint128 shares,
    uint256[2] memory amountMin
  ) external returns (
    uint256 base0,
    uint256 base1
  );

  function pullLiquidity(
    uint256 shares,
    uint256[4] memory minAmounts 
  ) external returns(
      uint256 base0,
      uint256 base1,
      uint256 limit0,
      uint256 limit1
  );

  function addLiquidity(
      int24 tickLower,
      int24 tickUpper,
      uint256 amount0,
      uint256 amount1,
      uint256[2] memory inMin
  ) external;

  function pool() external view returns (IAlgebraPoolV2);

  function currentTick() external view returns (int24 tick);
  
  function tickSpacing() external view returns (int24 spacing);

  function baseLower() external view returns (int24 tick);

  function baseUpper() external view returns (int24 tick);

  function limitLower() external view returns (int24 tick);

  function limitUpper() external view returns (int24 tick);

  function token0() external view returns (IERC20);

  function token1() external view returns (IERC20);

  function deposit0Max() external view returns (uint256);

  function deposit1Max() external view returns (uint256);

  function balanceOf(address) external view returns (uint256);

  function approve(address, uint256) external returns (bool);

  function transferFrom(address, address, uint256) external returns (bool);

  function transfer(address, uint256) external returns (bool);

  function getTotalAmounts() external view returns (uint256 total0, uint256 total1);
  
  function getBasePosition() external view returns (uint256 liquidity, uint256 total0, uint256 total1);

  function totalSupply() external view returns (uint256 );

  function setWhitelist(address _address) external;
  
  function setFee(uint8 newFee) external;
  
  function removeWhitelisted() external;

  function transferOwnership(address newOwner) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IAlgebraPoolV2 {
	function token0() external view returns(address);
	function token1() external view returns(address);
	function tickSpacing() external view returns(int24);
	function burn(int24, int24, uint128) external returns(uint256,uint256); 
	function mint(address, address, int24, int24, uint128, bytes calldata) external returns(uint256,uint256,uint128); 
	function collect(address, int24, int24, uint128, uint128) external returns(uint256,uint256); 
	function positions(bytes32) external view returns(uint256, uint256, uint256, uint128, uint128);
	function globalState() external view returns(uint160, int24, uint16, uint16, uint16, uint8, bool);
  function dataStorageOperator() external view returns (address);
}
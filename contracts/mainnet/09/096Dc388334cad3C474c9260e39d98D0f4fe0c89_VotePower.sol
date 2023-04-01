/**
 *Submitted for verification at FtmScan.com on 2023-03-29
*/

// File: VotePowerV1/interfaces/ISmartChefInitializable.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISmartChefInitializable {
  function userInfo(address _user) external view returns (uint256, uint256);
}
// File: VotePowerV1/interfaces/IBarPair.sol

pragma solidity ^0.8.0;

interface IBarPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}
// File: VotePowerV1/interfaces/IMasterChef.sol

pragma solidity ^0.8.0;

interface IMasterChef {
  function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
}
// File: VotePowerV1/interfaces/IIFOPool.sol

pragma solidity ^0.8.0;

interface IIFOPool {
  function userInfo(address _user) external view returns (uint256, uint256, uint256, uint256);
  function getPricePerFullShare() external view returns (uint256);
}
// File: VotePowerV1/interfaces/IBarVault.sol

pragma solidity ^0.8.0;

interface IBarVault {
  function userInfo(address _user) external view returns (uint256, uint256, uint256, uint256);
  function getPricePerFullShare() external view returns (uint256);
}
// File: VotePowerV1/interfaces/IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);
}
// File: VotePowerV1/VotePower.sol

pragma solidity ^0.8.0;

contract VotePower {
    constructor() {}

    address public constant BAR_TOKEN = 0x49Dbf113972Fe0b85FE35919C649b140013cDDC3; // bar token.
    address public constant BAR_VAULT = 0x7fd9B7751bb38c2C3d12282384AE7f54772e5355; // bar vault.
    address public constant IFO_POOL = 0x7e7a1d0cF3Aa6Df785C9869F6e9029481c27864b; // ifo pool.
    address public constant MASTERCHEF = 0x4D2E5fA2C0dE0096583cc4cC1A3a759D24De2105; // masterchef.
    address public constant BAR_LP = 0x26c0Ac6473E371d98b26c357148d19b1c5746A20; // bar lp.

    function getBarBalance(address _user) public view returns (uint256) {
        return IERC20(BAR_TOKEN).balanceOf(_user);
    }

    function getBarVaultBalance(address _user) public view returns (uint256) {
        (uint256 share, , , ) = IBarVault(BAR_VAULT).userInfo(_user);
        uint256 barVaultPricePerFullShare = IBarVault(BAR_VAULT).getPricePerFullShare();
        return (share * barVaultPricePerFullShare) / 1e18;
    }

    function getIFOPoolBalancee(address _user) public view returns (uint256) {
        (uint256 share, , , ) = IIFOPool(IFO_POOL).userInfo(_user);
        uint256 ifoPoolPricePerFullShare = IIFOPool(IFO_POOL).getPricePerFullShare();
        return (share * ifoPoolPricePerFullShare) / 1e18;
    }

    function getBarPoolBalance(address _user) public view returns (uint256) {
        (uint256 amount, ) = IMasterChef(MASTERCHEF).userInfo(0, _user);
        return amount;
    }

    function getBarFtmLpBalance(address _user) public view returns (uint256) {
        uint256 totalSupplyLP = IBarPair(BAR_LP).totalSupply();
        (uint256 reserve0, , ) = IBarPair(BAR_LP).getReserves();
        (uint256 amount, ) = IMasterChef(MASTERCHEF).userInfo(251, _user);
        return (amount * reserve0) / totalSupplyLP;
    }

    function getPoolsBalance(address _user, address[] memory _pools) public view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < _pools.length; i++) {
            (uint256 amount, ) = ISmartChefInitializable(_pools[i]).userInfo(_user);
            total += amount;
        }
        return total;
    }

    function getVotingPower(address _user, address[] memory _pools) public view returns (uint256) {
        return
            getBarBalance(_user) +
            getBarVaultBalance(_user) +
            getIFOPoolBalancee(_user) +
            getBarPoolBalance(_user) +
            getBarFtmLpBalance(_user) +
            getPoolsBalance(_user, _pools);
    }

    function getVotingPowerWithoutPool(address _user) public view returns (uint256) {
        return
            getBarBalance(_user) +
            getBarVaultBalance(_user) +
            getIFOPoolBalancee(_user) +
            getBarPoolBalance(_user) +
            getBarFtmLpBalance(_user);
    }
}
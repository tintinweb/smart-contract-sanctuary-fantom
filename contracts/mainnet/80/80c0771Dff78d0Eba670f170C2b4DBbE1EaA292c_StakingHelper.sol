// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../shared/interfaces/IERC20.sol";
import "../shared/interfaces/IStaking.sol";

contract StakingHelper {
    address public immutable staking;
    address public immutable MVD;

    constructor(address _staking, address _MVD) {
        require(_staking != address(0));
        staking = _staking;
        require(_MVD != address(0));
        MVD = _MVD;
    }

    function stake(uint256 _amount, address _recipient) external {
        IERC20(MVD).transferFrom(msg.sender, address(this), _amount);
        IERC20(MVD).approve(staking, _amount);
        IStaking(staking).stake(_amount, _recipient);
        IStaking(staking).claim(_recipient);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IERC20 {

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;

    function rebase() external;

    function epoch()
        external
        view
        returns (
            uint256 length,
            uint256 number,
            uint256 endBlock,
            uint256 distribute
        );
}
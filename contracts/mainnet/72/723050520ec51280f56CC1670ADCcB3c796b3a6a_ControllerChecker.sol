// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IResolver} from "./interfaces/IResolver.sol";

interface IPool {
    function controller() external view returns (address);

    function setController(address _controller) external;
}

contract ControllerChecker is IResolver {
    // solhint-disable var-name-mixedcase
    address public immutable controller = 0xe81f7FD735282e70e515DF3794bF5d18fD0c60cc;
    address public immutable pool = 0x9fc3E5259Ba18BD13366D0728a256E703869F21D;

    function checker() external view override returns (bool canExec, bytes memory execPayload) {
        address currentController = IPool(controller).controller();

        // solhint-disable not-rely-on-time
        canExec = currentController != controller;

        if (!canExec) return (false, bytes("Controller is fine."));
        else {
            execPayload = abi.encodeWithSelector(IPool.setController.selector, controller);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IResolver {
    function checker() external view returns (bool canExec, bytes memory execPayload);
}
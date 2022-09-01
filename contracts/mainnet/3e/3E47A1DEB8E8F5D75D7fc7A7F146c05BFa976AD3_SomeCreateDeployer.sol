// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./SomeProxyWithInterfaceAsImplementation.sol";
import "./SomeProxyWithCentralSourceOfImplementation.sol";

interface IProxy {
    function initialize(address) external;
}

contract SomeCreateDeployer {
    address public admin;
    address public implementationSourceAddress;

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function deployAndInit(bytes memory code, uint256 salt)
        public
        returns (address)
    {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        IProxy(addr).initialize(admin);

        return addr;
    }

    function deploy(bytes memory code, uint256 salt) public returns (address) {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        return addr;
    }

    function deployCustomProxy() public returns (address) {
        address addr = address(new SomeProxyWithInterfaceAsImplementation());
        IProxy(addr).initialize(admin);

        return addr;
    }

    function deployCustomProxy2() public returns (address) {
        address addr = address(
            new SomeProxyWithCentralSourceOfImplementation()
        );
        IProxy(addr).initialize(admin);

        return addr;
    }

    function updateImplementationSourceAddress(
        address _implementationSourceAddress
    ) external onlyAdmin {
        implementationSourceAddress = _implementationSourceAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./SomeProxy.sol";

contract SomeProxyWithInterfaceAsImplementation is SomeProxy {
    bytes32 constant SUBIMPLEMENTATION_SLOT =
        0xb708f8711f4dbefa756baac721800a185bf03058205da1900c8d9047e5c540fd; // keccak256('SubImplementation') - 1

    function updateSubImplementationAddress(address _subImplementationAddress)
        external
    {
        require(msg.sender == adminAddress(), "Only admin");
        assembly {
            sstore(SUBIMPLEMENTATION_SLOT, _subImplementationAddress)
        }
    }

    function subImplementationAddress()
        external
        view
        returns (address _subImplementationAddress)
    {
        assembly {
            _subImplementationAddress := sload(SUBIMPLEMENTATION_SLOT)
        }
    }

    function delegateCallSubimplmentation() internal {
        assembly {
            let contractLogic := sload(SUBIMPLEMENTATION_SLOT)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }

    fallback() external override {
        assembly {
            let contractLogic := sload(SUBIMPLEMENTATION_SLOT)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./SomeProxy.sol";

interface IFactory {
    function implementationSourceAddress() external view returns (address);
}

contract SomeProxyWithCentralSourceOfImplementation is SomeProxy {
    bytes32 constant FACTORY_SLOT =
        0xb708f8711f4dbefa756baac721800a185bf03058205da1900c8d9047e5c540fd; // keccak256('SubImplementation') - 1

    function initialize(address _admin) external override {
        bool initialized;
        address _factory = msg.sender;
        assembly {
            initialized := sload(INITIALIZED_SLOT)
            if eq(initialized, 1) {
                revert(0, 0)
            }
            sstore(INITIALIZED_SLOT, 1)

            sstore(ADMIN_SLOT, _admin)
            sstore(FACTORY_SLOT, _factory)
        }
    }

    function updateFactoryAddress(address _factory) external {
        require(msg.sender == adminAddress(), "Only admin");
        assembly {
            sstore(FACTORY_SLOT, _factory)
        }
    }

    function factoryAddress() public view returns (address _factory) {
        assembly {
            _factory := sload(FACTORY_SLOT)
        }
    }

    function delegateCallSubimplmentation() internal {
        address contractLogic = IFactory(factoryAddress())
            .implementationSourceAddress();
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }

    fallback() external override {
        delegateCallSubimplmentation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract SomeProxy {
    bytes32 constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; // keccak256('eip1967.proxy.implementation')
    bytes32 constant ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')
    bytes32 constant INITIALIZED_SLOT =
        0x834ce84547018237034401a09067277cdcbe7bbf7d7d30f6b382b0a102b7b4a3; // keccak256('eip1967.proxy.initialized')

    function initialize(address _admin) external virtual {
        bool initialized;

        assembly {
            initialized := sload(INITIALIZED_SLOT)
            if eq(initialized, 1) {
                revert(0, 0)
            }
            sstore(INITIALIZED_SLOT, 1)

            sstore(ADMIN_SLOT, _admin)
        }
    }

    function updateImplementationAddress(address _implementationAddress)
        external
    {
        require(msg.sender == adminAddress(), "Only admin");
        assembly {
            sstore(IMPLEMENTATION_SLOT, _implementationAddress)
        }
    }

    function implementationAddress()
        external
        view
        returns (address _implementationAddress)
    {
        assembly {
            _implementationAddress := sload(IMPLEMENTATION_SLOT)
        }
    }

    function adminAddress() public view returns (address _adminAddress) {
        assembly {
            _adminAddress := sload(ADMIN_SLOT)
        }
    }

    fallback() external virtual {
        assembly {
            let contractLogic := sload(IMPLEMENTATION_SLOT)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }
}
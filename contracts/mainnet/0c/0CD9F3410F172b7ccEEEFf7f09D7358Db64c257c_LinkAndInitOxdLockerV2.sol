// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "../rock/interfaces/IVoter.sol";
import "../rock/interfaces/IVlOxd.sol";
import "../rock/GovernableImplementation.sol";
import "../rock/ProxyImplementation.sol";
import "../rock/DeployedOxDAODeployer.sol";

/**
 * @title Helper contract meant to be delegate-called by deployer to link and initiate OxdLockerV2 atomically
 * @author 0xDAO
 */

contract LinkAndInitOxdLockerV2 is OxDAODeployer {
    function linkOxdLockerV2(
        address proxyAddress,
        address implementationAddress
    ) external onlyOwners {
        //link proxy to new implementation
        IProxy(proxyAddress).updateImplementationAddress(implementationAddress);
        IVlOxd(proxyAddress).checkpointEpoch();
        IVlOxd(proxyAddress).updateRewards();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoter {
    function isWhitelisted(address) external view returns (bool);

    function length() external view returns (uint256);

    function pools(uint256) external view returns (address);

    function gauges(address) external view returns (address);

    function bribes(address) external view returns (address);

    function factory() external view returns (address);

    function gaugefactory() external view returns (address);

    function vote(
        uint256,
        address[] memory,
        int256[] memory
    ) external;

    function updateFor(address[] memory _gauges) external;

    function claimRewards(address[] memory _gauges, address[][] memory _tokens)
        external;

    function distribute(address _gauge) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVlOxd {
    struct LocksData {
        uint256 total;
        uint256 unlockable;
        uint256 locked;
        LockedBalance[] locks;
    }

    struct LockedBalance {
        uint112 amount;
        uint112 boosted;
        uint32 unlockTime;
    }

    struct EarnedData {
        address token;
        uint256 amount;
    }

    struct Reward {
        bool useBoost;
        uint40 periodFinish;
        uint208 rewardRate;
        uint40 lastUpdateTime;
        uint208 rewardPerTokenStored;
        address rewardsDistributor;
    }

    function lock(
        address _account,
        uint256 _amount,
        uint256 _spendRatio
    ) external;

    function processExpiredLocks(
        bool _relock,
        uint256 _spendRatio,
        address _withdrawTo
    ) external;

    function lockedBalanceOf(address) external view returns (uint256 amount);

    function lockedBalances(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            LockedBalance[] memory
        );

    function claimableRewards(address _account)
        external
        view
        returns (EarnedData[] memory userRewards);

    function rewardTokensLength() external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewardData(address) external view returns (Reward memory);

    function rewardPerToken(address) external view returns (uint256);

    function getRewardForDuration(address) external view returns (uint256);

    function getReward() external;

    function checkpointEpoch() external;

    function updateRewards() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11||0.6.12;

/**
 * @title Ownable contract which allows governance to be killed, adapted to be used under a proxy
 * @author 0xDAO
 */
contract GovernableImplementation {
    address internal doNotUseThisSlot; // used to be governanceAddress, but there's a hash collision with the proxy's governanceAddress
    bool public governanceIsKilled;

    /**
     * @notice legacy
     * @dev public visibility so it compiles for 0.6.12
     */
    constructor() public {
        doNotUseThisSlot = msg.sender;
    }

    /**
     * @notice Only allow governance to perform certain actions
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress(), "Only governance");
        _;
    }

    /**
     * @notice Set governance address
     * @param _governanceAddress The address of new governance
     */
    function setGovernanceAddress(address _governanceAddress)
        public
        onlyGovernance
    {
        require(msg.sender == governanceAddress(), "Only governance");
        assembly {
            sstore(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                _governanceAddress
            ) // keccak256('eip1967.proxy.admin')
        }
    }

    /**
     * @notice Allow governance to be killed
     */
    function killGovernance() external onlyGovernance {
        setGovernanceAddress(address(0));
        governanceIsKilled = true;
    }

    /**
     * @notice Fetch current governance address
     * @return _governanceAddress Returns current governance address
     * @dev directing to the slot that the proxy would use
     */
    function governanceAddress()
        public
        view
        returns (address _governanceAddress)
    {
        assembly {
            _governanceAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            ) // keccak256('eip1967.proxy.admin')
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11||0.6.12;

/**
 * @title Implementation meant to be used with a proxy
 * @author 0xDAO
 */
contract ProxyImplementation {
    bool public proxyStorageInitialized;

    /**
     * @notice Nothing in constructor, since it only affects the logic address, not the storage address
     * @dev public visibility so it compiles for 0.6.12
     */
    constructor() public {}

    /**
     * @notice Only allow proxy's storage to be initialized once
     */
    modifier checkProxyInitialized() {
        require(
            !proxyStorageInitialized,
            "Can only initialize proxy storage once"
        );
        proxyStorageInitialized = true;
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IProxy {
    function initialize(address) external;

    function updateImplementationAddress(address) external;

    function updateGovernanceAddress(address) external;
}

/**
 * @title 0xDAO deployment bootstrapper
 * @author 0xDAO
 * @dev Rules:
 *      - Only owner 1 and owner 2 can deploy
 *      - New deployments are initialized with deployer contract being governance
 *      - Only owner 1 and 2 can set implementations and governance using deployer
 *      - Only owner 1 and owner 2 can update owner 1 and owner 2 addresses
 *      - Allows batch setting of governance on deployments
 */
contract OxDAODeployer {
    address public owner1Address;
    address public owner2Address;
    address[] public deployedAddresses;

    function initialize() external {
        bool initialized = owner1Address != address(0);
        require(!initialized, "Already initialized");
        owner1Address = msg.sender;
        owner2Address = msg.sender;
    }

    modifier onlyOwners() {
        require(
            msg.sender == owner1Address || msg.sender == owner2Address,
            "Only owners"
        );
        _;
    }

    function setOwner1Address(address _owner1Address) external onlyOwners {
        owner1Address = _owner1Address;
    }

    function setOwner2Address(address _owner2Address) external onlyOwners {
        owner2Address = _owner2Address;
    }

    function deployedAddressesLength() external view returns (uint256) {
        return deployedAddresses.length;
    }

    function deployedAddressesList() external view returns (address[] memory) {
        return deployedAddresses;
    }

    function deploy(bytes memory code, uint256 salt) public onlyOwners {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        IProxy(addr).initialize(address(this));
        deployedAddresses.push(addr);
    }

    function deployMany(bytes memory code, uint256[] memory salts) public {
        for (uint256 saltIndex; saltIndex < salts.length; saltIndex++) {
            uint256 salt = salts[saltIndex];
            deploy(code, salt);
        }
    }

    function updateImplementationAddress(
        address _targetAddress,
        address _implementationAddress
    ) external onlyOwners {
        IProxy(_targetAddress).updateImplementationAddress(
            _implementationAddress
        );
    }

    function updateGovernanceAddress(
        address _targetAddress,
        address _governanceAddress
    ) public onlyOwners {
        IProxy(_targetAddress).updateGovernanceAddress(_governanceAddress);
    }

    function updateGovernanceAddressAll(address _governanceAddress)
        external
        onlyOwners
    {
        for (
            uint256 deployedIndex;
            deployedIndex < deployedAddresses.length;
            deployedIndex++
        ) {
            address targetAddress = deployedAddresses[deployedIndex];
            updateGovernanceAddress(targetAddress, _governanceAddress);
        }
    }

    function generateContractAddress(bytes memory bytecode, uint256 salt)
        public
        view
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    enum Operation {
        Call,
        DelegateCall
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external onlyOwners returns (bool success) {
        if (operation == Operation.Call) success = executeCall(to, value, data);
        else if (operation == Operation.DelegateCall)
            success = executeDelegateCall(to, data);
        require(success == true, "Transaction failed");
    }

    function executeCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool success) {
        assembly {
            success := call(
                gas(),
                to,
                value,
                add(data, 0x20),
                mload(data),
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

    function executeDelegateCall(address to, bytes memory data)
        internal
        returns (bool success)
    {
        assembly {
            success := delegatecall(
                gas(),
                to,
                add(data, 0x20),
                mload(data),
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
//SPDX-License-Identifier: LICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;
import "./MultiSigOwner.sol";
import "./Manager.sol";
import "./interfaces/ICard.sol";

contract LevelManager is MultiSigOwner, Manager {
    // current user level of each user. 1~5 level enabled.
    mapping(address => uint256) public usersLevel;
    // the time okse amount is updated
    mapping(address => uint256) public usersOkseUpdatedTime;
    // this is validation period after user change his okse balance for this contract, normally is 30 days. we set 10 mnutes for testing.
    uint256 public levelValidationPeriod;
    // daily limit contants
    uint256 public constant MAX_LEVEL = 5;
    uint256[] public OkseStakeAmounts;
    event UserLevelChanged(address userAddr, uint256 newLevel);
    event OkseStakeAmountChanged(uint256 index, uint256 _amount);
    event LevelValidationPeriodChanged(uint256 levelValidationPeriod);

    constructor(address _cardContract) Manager(_cardContract) {
        // levelValidationPeriod = 30 days;
        levelValidationPeriod = 10 minutes; //for testing
        OkseStakeAmounts = [
            1000 ether,
            2500 ether,
            10000 ether,
            25000 ether,
            100000 ether
        ];
    }

    ////////////////////////// Read functions /////////////////////////////////////////////////////////////
    function getUserLevel(address userAddr) public view returns (uint256) {
        uint256 newLevel = getLevel(
            ICard(cardContract).getUserOkseBalance(userAddr)
        );
        if (newLevel < usersLevel[userAddr]) {
            return newLevel;
        } else {
            if (
                usersOkseUpdatedTime[userAddr] + levelValidationPeriod <
                block.timestamp
            ) {
                return newLevel;
            } else {
                // do something ...
            }
        }
        return usersLevel[userAddr];
    }

    /**
     * @notice Get user level from his okse balance
     * @param _okseAmount okse token amount
     * @return user's level, 0~5 , 0 => no level
     */
    // verified
    function getLevel(uint256 _okseAmount) public view returns (uint256) {
        if (_okseAmount < OkseStakeAmounts[0]) return 0;
        if (_okseAmount < OkseStakeAmounts[1]) return 1;
        if (_okseAmount < OkseStakeAmounts[2]) return 2;
        if (_okseAmount < OkseStakeAmounts[3]) return 3;
        if (_okseAmount < OkseStakeAmounts[4]) return 4;
        return 5;
    }

    ///////////////// CallBack functions from card contract //////////////////////////////////////////////
    function updateUserLevel(address userAddr, uint256 beforeAmount)
        external
        onlyFromCardContract
        returns (bool)
    {
        uint256 newLevel = getLevel(
            ICard(cardContract).getUserOkseBalance(userAddr)
        );
        uint256 beforeLevel = getLevel(beforeAmount);
        if (newLevel != beforeLevel)
            usersOkseUpdatedTime[userAddr] = block.timestamp;
        if (newLevel == usersLevel[userAddr]) return true;
        if (newLevel < usersLevel[userAddr]) {
            usersLevel[userAddr] = newLevel;
            emit UserLevelChanged(userAddr, newLevel);
        } else {
            if (
                usersOkseUpdatedTime[userAddr] + levelValidationPeriod <
                block.timestamp
            ) {
                usersLevel[userAddr] = newLevel;
                emit UserLevelChanged(userAddr, newLevel);
            } else {
                // do somrthing ...
            }
        }
        return false;
    }

    //////////////////// Owner functions ////////////////////////////////////////////////////////////////
    // verified
    function setLevelValidationPeriod(
        bytes calldata signData,
        bytes calldata keys
    ) public validSignOfOwner(signData, keys, "setLevelValidationPeriod") {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        uint256 _newValue = abi.decode(params, (uint256));
        levelValidationPeriod = _newValue;
        emit LevelValidationPeriodChanged(levelValidationPeriod);
    }

    // verified
    function setOkseStakeAmount(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "setOkseStakeAmount")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        (uint256 index, uint256 _amount) = abi.decode(
            params,
            (uint256, uint256)
        );
        require(index < MAX_LEVEL, "level<5");
        OkseStakeAmounts[index] = _amount;
        emit OkseStakeAmountChanged(index, _amount);
    }
}

// SPDX-License-Identifier: LICENSED
pragma solidity ^0.7.0;
pragma abicoder v2;
// 2/3 Multi Sig Owner
contract MultiSigOwner {
    address[] public owners;
    mapping(uint256 => bool) public signatureId;
    bool private initialized;
    // events
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SignValidTimeChanged(uint256 newValue);
    modifier validSignOfOwner(
        bytes calldata signData,
        bytes calldata keys,
        string memory functionName
    ) {
        require(isOwner(msg.sender), "on");
        address signer = getSigner(signData, keys);
        require(signer != msg.sender && isOwner(signer), "is");
        (bytes4 method, uint256 id, uint256 validTime, ) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        require(
            signatureId[id] == false &&
                method == bytes4(keccak256(bytes(functionName))),
            "sru"
        );
        require(validTime > block.timestamp, "ep");
        signatureId[id] = true;
        _;
    }

    function isOwner(address addr) public view returns (bool) {
        bool _isOwner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == addr) {
                _isOwner = true;
            }
        }
        return _isOwner;
    }

    constructor() {}

    function initializeOwners(address[3] memory _owners) public {
        require(!initialized, "ai");
        owners = [_owners[0], _owners[1], _owners[2]];
        initialized = true;
    }

    function getSigner(bytes calldata _data, bytes calldata keys)
        public
        view
        returns (address)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(
            keys,
            (uint8, bytes32, bytes32)
        );
        return
            ecrecover(
                toEthSignedMessageHash(
                    keccak256(abi.encodePacked(this, chainId, _data))
                ),
                v,
                r,
                s
            );
    }

    function encodePackedData(bytes calldata _data)
        public
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return keccak256(abi.encodePacked(this, chainId, _data));
    }

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    // Set functions
    // verified
    function transferOwnership(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "transferOwnership")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        address newOwner = abi.decode(params, (address));
        uint256 index;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                index = i;
            }
        }
        address oldOwner = owners[index];
        owners[index] = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

//SPDX-License-Identifier: LICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;

contract Manager {
    address public immutable cardContract;

    constructor(address _cardContract) {
        cardContract = _cardContract;
    }

    /// modifier functions
    modifier onlyFromCardContract() {
        require(msg.sender == cardContract, "oc");
        _;
    }
}

// SPDX-License-Identifier: LICENSED
pragma solidity ^0.7.0;

interface ICard {
    function getUserOkseBalance(address userAddr)
        external
        view
        returns (uint256);

    function getUserAssetAmount(address userAddr, address market)
        external
        view
        returns (uint256);


    function usersBalances(address userAddr, address market)
        external
        view
        returns (uint256);

    function priceOracle() external view returns (address);

}
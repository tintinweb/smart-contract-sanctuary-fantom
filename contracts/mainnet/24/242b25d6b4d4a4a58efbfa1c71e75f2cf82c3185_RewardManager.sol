/**
 *Submitted for verification at FtmScan.com on 2022-08-10
*/

pragma solidity 0.6.12;

interface ITimelock {
    function setAdmin(address _admin) external;
    function enableLeverage(address _vault) external;
    function disableLeverage(address _vault) external;
    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled) external;
    function signalSetGov(address _target, address _gov) external;
    function managedSetHandler(address _target, address _handler, bool _isActive) external;
    function managedSetMinter(address _target, address _minter, bool _isActive) external;
}

pragma solidity 0.6.12;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

pragma solidity 0.6.12;

contract RewardManager is Governable {
    bool public isInitialized;

    ITimelock public timelock;
    address public rewardRouter;

    address public alpManager;

    address public stakedAnzorTracker;
    address public bonusAnzorTracker;
    address public feeAnzorTracker;

    address public feeAlpTracker;
    address public stakedAlpTracker;

    address public stakedAnzorDistributor;
    address public stakedAlpDistributor;

    address public esAnzor;
    address public bnAnzor;

    address public anzorVester;
    address public alpVester;

    function initialize(
        ITimelock _timelock,
        address _rewardRouter,
        address _alpManager,
        address _stakedAnzorTracker,
        address _bonusAnzorTracker,
        address _feeAnzorTracker,
        address _feeAlpTracker,
        address _stakedAlpTracker,
        address _stakedAnzorDistributor,
        address _stakedAlpDistributor,
        address _esAnzor,
        address _bnAnzor,
        address _anzorVester,
        address _alpVester
    ) external onlyGov {
        require(!isInitialized, "RewardManager: already initialized");
        isInitialized = true;

        timelock = _timelock;
        rewardRouter = _rewardRouter;

        alpManager = _alpManager;

        stakedAnzorTracker = _stakedAnzorTracker;
        bonusAnzorTracker = _bonusAnzorTracker;
        feeAnzorTracker = _feeAnzorTracker;

        feeAlpTracker = _feeAlpTracker;
        stakedAlpTracker = _stakedAlpTracker;

        stakedAnzorDistributor = _stakedAnzorDistributor;
        stakedAlpDistributor = _stakedAlpDistributor;

        esAnzor = _esAnzor;
        bnAnzor = _bnAnzor;

        anzorVester = _anzorVester;
        alpVester = _alpVester;
    }

    function updateEsAnzorHandlers() external onlyGov {
        timelock.managedSetHandler(esAnzor, rewardRouter, true);

        timelock.managedSetHandler(esAnzor, stakedAnzorDistributor, true);
        timelock.managedSetHandler(esAnzor, stakedAlpDistributor, true);

        timelock.managedSetHandler(esAnzor, stakedAnzorTracker, true);
        timelock.managedSetHandler(esAnzor, stakedAlpTracker, true);

        timelock.managedSetHandler(esAnzor, anzorVester, true);
        timelock.managedSetHandler(esAnzor, alpVester, true);
    }

    function enableRewardRouter() external onlyGov {
        timelock.managedSetHandler(alpManager, rewardRouter, true);

        timelock.managedSetHandler(stakedAnzorTracker, rewardRouter, true);
        timelock.managedSetHandler(bonusAnzorTracker, rewardRouter, true);
        timelock.managedSetHandler(feeAnzorTracker, rewardRouter, true);

        timelock.managedSetHandler(feeAlpTracker, rewardRouter, true);
        timelock.managedSetHandler(stakedAlpTracker, rewardRouter, true);

        timelock.managedSetHandler(esAnzor, rewardRouter, true);

        timelock.managedSetMinter(bnAnzor, rewardRouter, true);

        timelock.managedSetMinter(esAnzor, anzorVester, true);
        timelock.managedSetMinter(esAnzor, alpVester, true);

        timelock.managedSetHandler(anzorVester, rewardRouter, true);
        timelock.managedSetHandler(alpVester, rewardRouter, true);

        timelock.managedSetHandler(feeAnzorTracker, anzorVester, true);
        timelock.managedSetHandler(stakedAlpTracker, alpVester, true);
    }
}
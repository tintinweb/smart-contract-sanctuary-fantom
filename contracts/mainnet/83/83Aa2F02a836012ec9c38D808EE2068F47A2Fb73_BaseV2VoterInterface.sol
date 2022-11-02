// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

contract BaseV2VoterInterface {
    event Abstained(
        uint256 indexed tokenId,
        address indexed pool,
        int256 weight
    );
    event Attach(address indexed owner, address indexed gauge, uint256 tokenId);
    event Deposit(
        address indexed lp,
        address indexed gauge,
        uint256 tokenId,
        uint256 amount
    );
    event Detach(address indexed owner, address indexed gauge, uint256 tokenId);
    event DistributeReward(
        address indexed sender,
        address indexed gauge,
        uint256 amount
    );
    event GaugeCreated(
        address indexed gauge,
        address creator,
        address indexed bribe,
        address indexed pool
    );
    event NotifyReward(
        address indexed sender,
        address indexed reward,
        uint256 amount
    );
    event Voted(
        address indexed voter,
        uint256 indexed tokenId,
        address indexed pool,
        int256 weight
    );
    event Whitelisted(address indexed whitelister, address indexed token);
    event Withdraw(
        address indexed lp,
        address indexed gauge,
        uint256 tokenId,
        uint256 amount
    );

    function _ve() external view returns (address) {}

    function attachTokenToGauge(uint256 tokenId, address account) external {}

    function bribefactory() external view returns (address) {}

    function bribes(address) external view returns (address) {}

    function claimBribes(
        address[] memory _bribes,
        address[][] memory _tokens,
        uint256 _tokenId
    ) external {}

    function claimFees(
        address[] memory _fees,
        address[][] memory _tokens,
        uint256 _tokenId
    ) external {}

    function claimRewards(address[] memory _gauges, address[][] memory _tokens)
        external
    {}

    function claimable(address) external view returns (uint256) {}

    function createGauge(address _pool) external returns (address) {}

    function detachTokenFromGauge(uint256 tokenId, address account) external {}

    function distribute(address[] memory _gauges) external {}

    function distribute(address _gauge) external {}

    function distribute(uint256 start, uint256 finish) external {}

    function distribute() external {}

    function distributeFees(address[] memory _gauges) external {}

    function distro() external {}

    function emitDeposit(
        uint256 tokenId,
        address account,
        uint256 amount
    ) external {}

    function emitWithdraw(
        uint256 tokenId,
        address account,
        uint256 amount
    ) external {}

    function factory() external view returns (address) {}

    function gaugefactory() external view returns (address) {}

    function gauges(address) external view returns (address) {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function initialize(
        address __ve,
        address _factory,
        address _gauges,
        address _bribes
    ) external {}

    function initializeMinter(address[] memory _tokens, address _minter)
        external
    {}

    function isGauge(address) external view returns (bool) {}

    function isWhitelisted(address) external view returns (bool) {}

    function length() external view returns (uint256) {}

    function listingFeeRatio() external view returns (uint256) {}

    function listing_fee() external view returns (uint256) {}

    function minter() external view returns (address) {}

    function notifyRewardAmount(uint256 amount) external {}

    function poolForGauge(address) external view returns (address) {}

    function poolVote(uint256, uint256) external view returns (address) {}

    function pools(uint256) external view returns (address) {}

    function reset(uint256 _tokenId) external {}

    function setListingFeeRatio(uint256 _listingFeeRatio) external {}

    function setTrainingWheels(bool _status) external {}

    function totalWeight() external view returns (uint256) {}

    function trainingWheels() external view returns (bool) {}

    function updateAll() external {}

    function updateFor(address[] memory _gauges) external {}

    function updateForRange(uint256 start, uint256 end) external {}

    function updateGauge(address _gauge) external {}

    function usedWeights(uint256) external view returns (uint256) {}

    function vote(
        uint256 tokenId,
        address[] memory _poolVote,
        int256[] memory _weights
    ) external {}

    function votes(uint256, address) external view returns (int256) {}

    function weights(address) external view returns (int256) {}

    function whitelist(address _token, uint256 _tokenId) external {}
}
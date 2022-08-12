/**
 *Submitted for verification at FtmScan.com on 2022-08-12
*/

// File: contracts/AggregatorInterface.sol

pragma solidity ^0.5.0;

// AggregatorInterface specifies ChainLink aggregator interface.
interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// File: contracts/ChainLinkPriceOracleAggregator.sol

pragma solidity ^0.5.0;

// AggregatorInterface specifies ChainLink aggregator interface.

// ChainLinkPriceOracleAggregator implements ChainLink reference price oracle
// aggregator interface on Opera. The interface mimics ChainLink Ethereum contract
// behavior so we can switch to native ChainLink oracle aggregator once available
// on Opera native chain.
// NOTE: Please remember the ChainLink reference data latest value response is multiplied
// by 100,000,000 (1e+8) for USD pairs and by 1,000,000,000,000,000,000 (1e+18)
// for ETH pairs.
// @see https://docs.chain.link/docs/using-chainlink-reference-contracts
contract ChainLinkPriceOracleAggregator is AggregatorInterface {
    // owner represents the manager address of the oracle.
    address public owner;

    // sources represent a map of addresses allowed
    // to push new price updates into the oracle.
    mapping(address => bool) public sources;

    // latestRound keeps track of rounds of reference data pushed
    // into the aggregator.
    uint256 internal round;

    // answers container is used to store answers.
    int256[256] answers;

    // timeStamps container is used to store time stamps of corresponding answers.
    uint256[256] timeStamps;

    // AnswerUpdated is emitted on updated current answer for the specified round.
    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);

    // NewRound is emitted when a new round is started by a specified source address.
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

    // SourceAdded is emitted on a new source being added to the oracle.
    event SourceAdded(address source, uint256 timeStamp);

    // SourceDropped is emitted on a existing source being dropped from the oracle.
    event SourceDropped(address source, uint256 timeStamp);

    // constructor installs a new instance of the ChainLink reference price oracle aggregator.
    constructor () public {
        // remember the owner
        owner = msg.sender;

        // owner is one of the allowed sources
        sources[msg.sender] = true;
    }

    // latestAnswer returns the latest available answer for the latest round.
    function latestAnswer() external view returns (int256) {
        return answers[round % answers.length];
    }

    // latestTimestamp returns the timestamp of the latest available answer.
    function latestTimestamp() external view returns (uint256) {
        return timeStamps[round % answers.length];
    }

    // latestRound returns the latest round active.
    function latestRound() external view returns (uint256) {
        return round;
    }

    // getAnswer returns a historic answer from the internal storage.
    function getAnswer(uint256 roundId) external view returns (int256) {
        // make sure we actually have the answer
        require(roundId <= round, "future estimate not available");
        require(round - roundId < answers.length, "not enough history");

        // get the answer
        return answers[roundId % answers.length];
    }

    // getTimestamp returns a historic answer from the internal storage.
    function getTimestamp(uint256 roundId) external view returns (uint256) {
        // make sure we actually have the answer
        require(roundId <= round, "future estimate not available");
        require(round - roundId < answers.length, "not enough history");

        // get the answer
        return timeStamps[roundId % answers.length];
    }

    // updateAnswer updates a specified answer from an external source.
    // We use naive answer update strategy since we copy all the data from authorized
    // ChainLink data source. On more sophisticated implementation, we should validate
    // the new value from several sources.
    function updateAnswer(uint256 _round, int256 _value, uint256 _stamp) external {
        // make sure the request comes from authorized source
        require(sources[msg.sender], "not authorized");

        // do not skip rounds
        int256 diff = int256(_round) - int256(round);
        require(diff <= 1 && diff >= - 1, "round skip prohibited");

        // is this a new round?
        if (_round > round) {
            round = _round;
            emit NewRound(_round, msg.sender, now);
        }

        // store the new value
        answers[_round % answers.length] = _value;
        timeStamps[_round % answers.length] = _stamp;

        // emit update event
        emit AnswerUpdated(_value, _round, _stamp);
    }

    // addSource adds new price source address to the contract.
    function addSource(address addr) public {
        // make sure this is legit
        require(msg.sender == owner, "access restricted");
        sources[addr] = true;

        // inform about the change
        emit SourceAdded(addr, now);
    }

    // dropSource disables address from pushing new prices.
    function dropSource(address addr) public {
        // make sure this is legit
        require(msg.sender == owner, "access restricted");
        sources[addr] = false;

        // inform about the change
        emit SourceDropped(addr, now);
    }
}
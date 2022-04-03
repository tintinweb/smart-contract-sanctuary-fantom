//SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;

import "./ILottery.sol";
import "./IVRFOracleOraichain.sol";

contract RandomNumberGenerator {
    bytes32 internal keyHash;
    address internal requester;
    uint256 public randomResult;
    uint256 public currentLotteryId;
    address public oracle;

    address public lottery;

    modifier onlyLottery() {
        require(msg.sender == lottery, "Only Lottery can call function");
        _;
    }

    constructor(
        address _vrfCoordinator,
        address _lottery,
        bytes32 _keyHash
    ) public {
        keyHash = _keyHash;
        lottery = _lottery;
        oracle = _vrfCoordinator;
    }

    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 lotteryId, uint256 userProvidedSeed)
        public
        payable
        onlyLottery
        returns (uint256)
    {
        // require(keyHash != bytes32(0), "Must have valid key hash");
        // uint256 fee = IVRFOracleOraichain(oracle).getFee();
        requester = msg.sender;
        currentLotteryId = lotteryId;
        // return requestRandomness(keyHash, fee, userProvidedSeed);
        // bytes memory data = abi.encode(
        //     address(this),
        //     this.fulfillRandomness.selector
        // );

        // (bool success, bytes memory returndata) = address(oracle).call{
        //     value: fee
        // }(
        //     abi.encodeWithSignature(
        //         "randomnessRequest(uint256,bytes)",
        //         userProvidedSeed,
        //         data
        //     )
        // );

        // return returndata;

        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    lotteryId,
                    userProvidedSeed
                )
            )
        );

        this.fulfillRandomness(userProvidedSeed, rand);

        return userProvidedSeed;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(uint256 requestId, uint256 randomness) external {
        ILottery(lottery).numbersDrawn(currentLotteryId, requestId, randomness);
        randomResult = randomness;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;

interface ILottery {
    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getMaxRange() external view returns (uint32);

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    function numbersDrawn(
        uint256 _lotteryId,
        uint256 _requestId,
        uint256 _randomNumber
    ) external;
}

pragma solidity >=0.6.12 <0.8.0;

interface IVRFOracleOraichain {
    function randomnessRequest(uint256 _seed, bytes calldata _data)
        external
        returns (bytes32 reqId);

    function getFee() external returns (uint256);
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TrustGraph {
    struct TrustQuestion {
        string title;
    }

    struct Score {
        int8 score;
        uint8 confidance;
    }

    TrustQuestion[] public questions;

    // from => (to => (questionId => score))
    mapping(address => mapping(address => mapping(uint256 => Score)))
        public scores;

    error QuestionDoesNotExist();

    event QuestionCreated(uint256 id, string title);
    event Rated(
        address from,
        address to,
        uint256 questionId,
        int8 score,
        uint8 confidance
    );

    function getQuestionsLength() public view returns (uint256) {
        return questions.length;
    }

    function createQuestion(string memory title) external {
        uint256 id = questions.length;
        questions.push(TrustQuestion(title));
        emit QuestionCreated(id, title);
    }

    function scoreUser(
        address to,
        uint256 questionId,
        int8 score,
        uint8 confiance
    ) external {
        if (questionId > questions.length) revert QuestionDoesNotExist();

        scores[msg.sender][to][questionId] = Score(score, confiance);

        emit Rated(msg.sender, to, questionId, score, confiance);
    }
}
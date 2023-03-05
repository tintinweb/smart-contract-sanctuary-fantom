/**
 *Submitted for verification at FtmScan.com on 2023-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MBDA22 {
    address owner;

    // claimAddresses are the addresses dispensed to all students. These addresses are pre-funded so that students don't need to put up their own funds for this experiment
    // claimAddresses will be distributed in a seed-phrase-raffle. Since the person who funded the wallets knows all the seed-phrases, the wallets are only to be used once.
    address[] public claimAddresses;

    // the claimAddresses are able to each add one anonymous address to the anonWhitelist. Addresses in the anonWhitelist are then able to interact with the contract and set grades.
    // Each student will create an anonymous address before the pre-funded addresses are dispensed. Then they will import the pre-funded addresses, add their previously generated
    // address to the anonWhitelist and send all remaining funds from the claimAddress to their own anonAddress.
    // this way every student has a funded, anonymous address to interact with the contract, and the contract can't be botted.
    address[] public anonAddresses;

    // every blockweek has a mapping where the anonAddresses are mapped to their grade. This way one full map gives a complete set of grades of all students,
    // without the students knowing which student got which grade
    mapping(address => uint16) weekOneGrades;
    mapping(address => uint16) weekTwoGrades;
    mapping(address => uint16) weekThreeGrades;
    mapping(address => uint16) weekFourGrades;
    mapping(address => uint16) weekFiveGrades;
    mapping(address => uint16) weekSixGrades;
    mapping(address => uint16) weekSevenGrades;

    // fun feature: If a student is brave enough or simply doesnt care about privacy, they can map their address to their own name
    mapping(address => string) nonAnons;

    // the constructor is the function that is automatically called at contract deployment. In this case only the owner is assinged to be the contract deployer, and
    // the pre-funded addresses are added to the whitelist because this action needs to be performed only once
    constructor() {
        owner = msg.sender;

        claimAddresses.push(
            address(0xca8fD3B87CB92Ca6be0140E6Fc08cA6713b9FE5D)
        ); //1
        claimAddresses.push(
            address(0xa90fe2a305Cfe2A335d74037165f30Dc2eAa4ff6)
        ); //2
        claimAddresses.push(
            address(0xc64F63529B6e5Df6f045b2BC72bdcCfaF46483C2)
        ); //3
        claimAddresses.push(
            address(0x8B496c221c160e7876689F5926A1B4A4609850D4)
        ); //4
        claimAddresses.push(
            address(0x69d6CDf8A873FA1CaD79084Bd9dA226EfB4cEb7b)
        ); //5
        claimAddresses.push(
            address(0x46AC6ACC04B9e46c7e10B42B44978891e3f3286e)
        ); //6
        claimAddresses.push(
            address(0xb70f934DB43e05437223a8ff7BCa6cD1c0cE357c)
        ); //7
        claimAddresses.push(
            address(0xEcC22FCb9a2800cf714284900a6cbbA9Dbff4554)
        ); //8
        claimAddresses.push(
            address(0xE58f8B529020cD5E744Dd869dB3A8023ECaB80D6)
        ); //9
        claimAddresses.push(address(0x0)); //10
        claimAddresses.push(address(0x0)); //11
        claimAddresses.push(address(0x0)); //12
        claimAddresses.push(address(0x0)); //13
        claimAddresses.push(address(0x0)); //14
        claimAddresses.push(address(0x0)); //15
        claimAddresses.push(address(0x0)); //16
        claimAddresses.push(address(0x0)); //17
        claimAddresses.push(address(0x0)); //18
        claimAddresses.push(address(0x0)); //19
        claimAddresses.push(address(0x0)); //20
        claimAddresses.push(address(0x0)); //21
        claimAddresses.push(address(0x0)); //22
        claimAddresses.push(address(0x0)); //23
        claimAddresses.push(address(0x0)); //24
        claimAddresses.push(address(0x0)); //25
        claimAddresses.push(address(0x0)); //26
        claimAddresses.push(address(0x0)); //27
        claimAddresses.push(address(0x0)); //28
        claimAddresses.push(address(0x0)); //29
    }

    // Check function to see if an address is on the claims whitelist
    function isClaimWhitelisted(address _addr) public view returns (bool) {
        for (uint8 i = 0; i < claimAddresses.length; i++) {
            if (claimAddresses[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    // Check function to see if an address is on the anon whitelist
    function isAnonWhitelisted(address _addr) public view returns (bool) {
        for (uint8 i = 0; i < anonAddresses.length; i++) {
            if (anonAddresses[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    // a student will call this function after importing one of the pre-funded claim addresses. They will add their previously generated anonymous address to the anon whitelist
    function claimAndSetAnonAddr(address payable _anonAddr) public {
        require(isClaimWhitelisted(msg.sender), "Address is not whitelisted.");
        // claim address is removed from claims whitelist so that a malicious user can't call this function multiple times to drain the contract and set unlimited anon addresses
        removeAddressFromClaimsWhitelist(msg.sender);
        anonAddresses.push(msg.sender);
        payBounty(_anonAddr);
    }

    // A bounty is being paid to the user in case they successfully interacted with the smart contract.
    // This way users are incentivized to use the protocol and also have enough gas to spend on the next contract calls.
    function payBounty(address payable _winner) private {
        require(
            address(this).balance >= 1 * 10**17,
            "Not enough tokens left, please donate."
        );
        _winner.transfer(1 * 10**17);
    }

    //remove claim address from whitelist to avoid double claims
    function removeAddressFromClaimsWhitelist(address _addr) private {
        for (uint64 i = 0; i < claimAddresses.length; i++) {
            if (claimAddresses[i] == _addr) {
                claimAddresses[i] = address(0x0);
            }
        }
    }

    // User function to associate a grade to the sender-address in a particular blockweek
    // a grade can only be set if it wasn't set before. Make sure to set the grade correctly because once set, it's set in stone. The format is 10 = 1.0 , 25 = 2.5 etc.
    function setGrade(uint8 _week, uint8 _grade) public {
        require(
            _week <= 7 && _week >= 1,
            "Only Integers between 1 and 7 are allowed."
        );
        require(
            isAnonWhitelisted(msg.sender),
            "Only whitelisted Anon Addresses can submit grades."
        );
        if (_week == 1) {
            if (weekOneGrades[msg.sender] == 0) {
                weekOneGrades[msg.sender] = _grade;
                payBounty(payable(msg.sender));
            }
        } else if (_week == 2) {
            if (weekTwoGrades[msg.sender] == 0) {
                weekTwoGrades[msg.sender] = _grade;
                payBounty(payable(msg.sender));
            }
        } else if (_week == 3) {
            if (weekThreeGrades[msg.sender] == 0) {
                weekThreeGrades[msg.sender] = _grade;
                payBounty(payable(msg.sender));
            }
        } else if (_week == 4) {
            if (weekFourGrades[msg.sender] == 0) {
                weekFourGrades[msg.sender] = _grade;
                payBounty(payable(msg.sender));
            }
        } else if (_week == 5) {
            if (weekFiveGrades[msg.sender] == 0) {
                weekFiveGrades[msg.sender] = _grade;
                payBounty(payable(msg.sender));
            }
        } else if (_week == 6) {
            if (weekSixGrades[msg.sender] != 0) {
                weekSixGrades[msg.sender] = _grade;
                payBounty(payable(msg.sender));
            }
        } else if (_week == 7) {
            if (weekSevenGrades[msg.sender] != 0) {
                weekSevenGrades[msg.sender] = _grade;
                payBounty(payable(msg.sender));
            }
        }
    }

    // in case a user wrongly set a grade in one of the weeks, they can reset their grade. They need to pay a fine for this, because otherwise they can call the
    // setGrade function multiple times resulting in them being paid the bounty multiple times, effectively draining the smart contract.
    function resetGrade(uint8 _week) public payable {
        require(
            isAnonWhitelisted(msg.sender),
            "Only whitelisted Anon Addresses can reveal their identity."
        );
        require(
            _week <= 7 && _week >= 1,
            "Only Integers between 1 and 6 are allowed."
        );
        require(
            msg.value >= 2 * 10**18,
            "The user needs to pay a fine in order not to drain the smart contract."
        );
        if (_week == 1) {
            delete weekOneGrades[msg.sender];
        } else if (_week == 2) {
            delete weekTwoGrades[msg.sender];
        } else if (_week == 3) {
            delete weekThreeGrades[msg.sender];
        } else if (_week == 4) {
            delete weekFourGrades[msg.sender];
        } else if (_week == 5) {
            delete weekFiveGrades[msg.sender];
        } else if (_week == 6) {
            delete weekSixGrades[msg.sender];
        } else if (_week == 7) {
            delete weekSevenGrades[msg.sender];
        }
    }

    // User function to get the average grade of a particular week. This will only show the "correct" average (from Aylin) if everybody participates and set their grades honestly
    function getAverageGradeByWeek(uint8 _week) public view returns (uint256) {
        require(
            _week < 7 && _week >= 1,
            "Only Integers between 1 and 6 are allowed."
        );
        if (_week == 1) {
            return calculateAverage(weekOneGrades);
        } else if (_week == 2) {
            return calculateAverage(weekTwoGrades);
        } else if (_week == 3) {
            return calculateAverage(weekThreeGrades);
        } else if (_week == 4) {
            return calculateAverage(weekFourGrades);
        } else if (_week == 5) {
            return calculateAverage(weekFiveGrades);
        } else if (_week == 6) {
            return calculateAverage(weekSixGrades);
        } else if (_week == 7) {
            return calculateAverage(weekSevenGrades);
        }
        return 0;
    }

    // calculates the average grade of all grades that were mapped inside a weekMap
    function calculateAverage(mapping(address => uint16) storage _weekMap)
        private
        view
        returns (uint256)
    {
        uint256 average;
        for (uint256 i = 0; i < anonAddresses.length; i++) {
            average += _weekMap[anonAddresses[i]];
        }
        return (average / anonAddresses.length) / 10;
    }

    // Optional: If somebody wants to reveal their name, they can do so
    function mapAddressToName(string memory _name) public {
        require(
            isAnonWhitelisted(msg.sender),
            "Only whitelisted Anon Addresses can reveal their identity."
        );
        nonAnons[msg.sender] = _name;
    }

    // if you want to spy on your fellow students, you can query the nonAnons list and check if a certain address has revealed their identity
    function getAnonsName(address _address)
        public
        view
        returns (string memory)
    {
        if (bytes(nonAnons[_address]).length != 0) {
            return nonAnons[_address];
        } else {
            return "Anon";
        }
    }

    // In case the contract runs out of bounty money, this can be used to refill the contract
    function donate() public payable {}

    // ... maybe Dominik knows what this function does ;-)
    function rugPull() public {
        require(
            msg.sender == owner,
            "Only the contract owner can rug the contract."
        );
        payable(msg.sender).transfer(address(this).balance);
        selfdestruct(payable(msg.sender));
    }

    function addAnotherClaimAddress(address _address) public {
        require(
            msg.sender == owner,
            "Only the owner can intervene in the whitelist."
        );
        claimAddresses.push(_address);
    }

    // optional: if the contract deployer is certain that the contract works properly and does not need any intervention, they can give away their ownership,
    // which would make the contract truly immutable
    function makeContractImmutable() public {
        require(
            msg.sender == owner,
            "Only the contract owner can make the contract immutable."
        );
        owner = address(0x0);
    }
}
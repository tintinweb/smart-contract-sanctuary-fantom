// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract InnerserenityDApp {
    struct User {
        string name;
        uint age;
        string gender;
    }
    
    struct Professional {
        string name;
        string specialization;
        bool available;
        uint totalRatings;
        uint totalScore;
    }
    
    mapping(address => User) public users;
    mapping(address => Professional) public professionals;
    address[] public professionalAddresses;
    
    event AppointmentRequested(address user, address professional);
    
    function createUser(string memory _name, uint _age, string memory _gender) public {
        User storage newUser = users[msg.sender];
        newUser.name = _name;
        newUser.age = _age;
        newUser.gender = _gender;
    }
    
    function createProfessional(string memory _name, string memory _specialization) public {
        Professional storage newProfessional = professionals[msg.sender];
        newProfessional.name = _name;
        newProfessional.specialization = _specialization;
        newProfessional.available = true;
        newProfessional.totalRatings = 0;
        newProfessional.totalScore = 0;
        
        professionalAddresses.push(msg.sender);
    }
    
    function searchProfessionals(string memory _specialization) public view returns (address[] memory) {
        uint count = 0;
        for (uint i = 0; i < professionalAddresses.length; i++) {
            address professionalAddress = professionalAddresses[i];
            if (professionals[professionalAddress].available && keccak256(abi.encodePacked(professionals[professionalAddress].specialization)) == keccak256(abi.encodePacked(_specialization))) {
                count++;
            }
        }
        
        address[] memory result = new address[](count);
        uint index = 0;
        for (uint i = 0; i < professionalAddresses.length; i++) {
            address professionalAddress = professionalAddresses[i];
            if (professionals[professionalAddress].available && keccak256(abi.encodePacked(professionals[professionalAddress].specialization)) == keccak256(abi.encodePacked(_specialization))) {
                result[index] = professionalAddress;
                index++;
            }
        }
        
        return result;
    }
    
    function requestAppointment(address _professionalAddress) public {
        require(professionals[_professionalAddress].available, "The requested professional is not available");
        
        emit AppointmentRequested(msg.sender, _professionalAddress);
    }
    
    function rateProfessional(address _professionalAddress, uint _score) public {
        require(_score >= 1 && _score <= 5, "Invalid rating score");
        
        Professional storage professional = professionals[_professionalAddress];
        professional.totalRatings++;
        professional.totalScore += _score;
    }
}
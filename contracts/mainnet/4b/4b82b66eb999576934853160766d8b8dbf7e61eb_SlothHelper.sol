/**
 *Submitted for verification at FtmScan.com on 2022-01-29
*/

/*
_____________     ___________                        
__  ___/__  /_______  /___  /_                       
_____ \__  /_  __ \  __/_  __ \                      
____/ /_  / / /_/ / /_ _  / / /                      
/____/ /_/  \____/\__/ /_/ /_/                       
                                                     
             ______  __    ______                    
             ___  / / /_______  /____________________
             __  /_/ /_  _ \_  /___  __ \  _ \_  ___/
             _  __  / /  __/  / __  /_/ /  __/  /    
             /_/ /_/  \___//_/  _  .___/\___//_/     
                                /_/                  
*/
library SlothHelper {
    function isContract(address account) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function toString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
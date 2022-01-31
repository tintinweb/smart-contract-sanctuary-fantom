/**
 *Submitted for verification at FtmScan.com on 2022-01-31
*/

/*
 $$$$$$\  $$\            $$\     $$\                              
$$  __$$\ $$ |           $$ |    $$ |                             
$$ /  \__|$$ | $$$$$$\ $$$$$$\   $$$$$$$\                         
\$$$$$$\  $$ |$$  __$$\\_$$  _|  $$  __$$\                        
 \____$$\ $$ |$$ /  $$ | $$ |    $$ |  $$ |                       
$$\   $$ |$$ |$$ |  $$ | $$ |$$\ $$ |  $$ |                       
\$$$$$$  |$$ |\$$$$$$  | \$$$$  |$$ |  $$ |                       
 \______/ \__| \______/   \____/ \__|  \__|                       
                                                                  
                                                                  
                                                                  
            $$\   $$\           $$\                               
            $$ |  $$ |          $$ |                              
            $$ |  $$ | $$$$$$\  $$ | $$$$$$\   $$$$$$\   $$$$$$\  
            $$$$$$$$ |$$  __$$\ $$ |$$  __$$\ $$  __$$\ $$  __$$\ 
            $$  __$$ |$$$$$$$$ |$$ |$$ /  $$ |$$$$$$$$ |$$ |  \__|
            $$ |  $$ |$$   ____|$$ |$$ |  $$ |$$   ____|$$ |      
            $$ |  $$ |\$$$$$$$\ $$ |$$$$$$$  |\$$$$$$$\ $$ |      
            \__|  \__| \_______|\__|$$  ____/  \_______|\__|      
                                    $$ |                          
                                    $$ |                          
                                    \__|                          
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
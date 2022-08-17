/**
 *Submitted for verification at FtmScan.com on 2022-08-16
*/

pragma solidity 0.8.11;

contract solidly_contract_state{

    string agreement = "-----BEGIN PGP MESSAGE----- \
 \
hQIMAyoU054c+0H+AQ/7BHTRGsx5Kiz+Mp5sSzo8EXkDw8hrasGYFTSZfG68JtjW \
PEOVTK+soXApKis6ytFvhg3Sn+EGkj7Zo4Ia7yGhhpGLVJBXpr+/xTicoS1UGSdM \
buWUsGXuwLB9VK5Fm4g1972xenepa5HEwalDj9dVk0mH8c9Z1QqEnwwNgZ0D5hOs \
/8/y+Jr3V5Ibs0N0mJZQbkjfgbcDCY8ClCw0jBi8gTQ5eiLlZanAphyXouqYgTXq \
P/5W+3HY1wPJUeApwuJFc+1yTvqSYDajSvFa+g+71LGJzfQr3q1Yt0aBwEgwW/g1 \
HxFTrF76GEiCPoNdEEo7DuWAI8tRRBlUwDdDyMTC4NaJgyjk2wSLpmD/ASpVs7XY \
Y2uEbaxvglmRB6o3zFiimS7OqNHzPON/1DpEcyH99wJGol0WYQ== \
=xEC7 \
-----END PGP MESSAGE-----";
 
    function print_agreement() public view returns (string memory) {
        return agreement;
    }
}
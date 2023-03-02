/**
 *Submitted for verification at FtmScan.com on 2023-03-02
*/

pragma solidity ^0.8.0;

contract CurveTypes {

function validateDelta(uint delta, bool isLinear) external pure returns (bool valid) {
    if(isLinear) {
     return delta >= 0 ?  true : false;
    } else {
        return delta > 1 ? true : false;
    }
}

   function validateSpotPrice(uint newSpotPrice, bool isLinear)
        external
        pure
        returns (bool valid) {
             if(isLinear) {
             return true;
           } else {
          return newSpotPrice >= 1 ? true : false;
        }
        }

  function validateTokensAndNFTsSent(
    uint delta,
    uint spotPrice,
    uint nftsAmount,
    uint tokensAmount,
    bool isLinear
  ) external pure returns(bool valid) {

     if(isLinear) {
       uint minAmount = (spotPrice) - (delta);
       require(minAmount <= tokensAmount && nftsAmount >= 1, "Tokens too low");
       return true;
     } else {
        uint minAmount;
        minAmount =  (spotPrice * (1000 - (delta))) / 1000;
        require(minAmount <= tokensAmount && nftsAmount >= 1, "Tokens Too Low");
        return true;
     }
  }



   function getBuyInfo(
        uint spotPrice,
        uint delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier,
        bool isLinear
    )
        external
        pure
        returns (
            uint newSpotPrice,
            uint256 inputValue,
            uint poolFee,
            uint256 protocolFee

        )

        {
           if(numItems == 0) {
            return(0,0,0, 0);
           }

            if(isLinear) {
               uint newSpot = (delta * numItems) + spotPrice;
               uint calculation;

               for(uint i; i < numItems; i++) {
                calculation += (delta * (i + 1)) + spotPrice;
               }
               uint _protocolFee = (calculation * protocolFeeMultiplier) / 1000;
               uint userFee = (calculation * feeMultiplier) / 1000;
               inputValue = calculation + userFee + _protocolFee;
               protocolFee = _protocolFee;
               newSpotPrice = newSpot;
               poolFee = userFee;
            } else {

               uint lastSpot = spotPrice;
               uint minAmount;
             for(uint i; i < numItems; i++) {

                 lastSpot = ( lastSpot * (1000 + delta)) / 1000;
                 minAmount += lastSpot;

             }
                newSpotPrice = lastSpot;
                uint _protocolFee = (minAmount * protocolFeeMultiplier) / 1000;
               uint userFee = (minAmount * feeMultiplier) / 1000;
                inputValue = minAmount + userFee + _protocolFee;
                protocolFee = _protocolFee;
                poolFee = userFee;
     }

        }

   function getSellInfo(
       uint spotPrice,
        uint delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier,
        bool isLinear
   )  external
        pure
        returns (
            uint newSpotPrice,
            uint256 sellPrice,
            uint poolFee,
            uint256 protocolFee

        ) {
      if(isLinear) {
               uint newSpot =  spotPrice - (delta * numItems) ;
               uint minAmount;

               for(uint i; i < numItems; i++) {
                minAmount += spotPrice - (delta * (i + 1));
               }

               newSpotPrice = newSpot;
                uint _protocolFee = (minAmount * protocolFeeMultiplier) / 1000;
               uint userFee = (minAmount * feeMultiplier) / 1000;
                sellPrice = minAmount - (userFee + _protocolFee);
                protocolFee = _protocolFee;
                poolFee = userFee;
      } else {
          
               uint lastSpot = spotPrice;
               uint minAmount;
              for(uint i; i < numItems; i++) {

                 lastSpot = ( lastSpot * (1000 - delta)) / 1000;
                 minAmount += lastSpot;

             }
                newSpotPrice = lastSpot;
                uint _protocolFee = (minAmount * protocolFeeMultiplier) / 1000;
               uint userFee = (minAmount * feeMultiplier) / 1000;
                sellPrice = minAmount - (userFee + _protocolFee);
                protocolFee = _protocolFee;
                poolFee = userFee;
      }
   }
   
}
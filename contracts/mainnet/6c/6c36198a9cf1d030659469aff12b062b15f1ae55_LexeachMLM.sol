/**
 *Submitted for verification at FtmScan.com on 2022-12-18
*/

pragma solidity 0.5.17;

contract LexeachMLM {

     address private ownerWallet;
      
      uint public currUserID = 0;
      uint public pool1currUserID = 0;
      uint public pool2currUserID = 0;
      uint public pool3currUserID = 0;
      uint public pool4currUserID = 0;
      uint public pool5currUserID = 0;
      uint public pool6currUserID = 0;
      uint public pool7currUserID = 0;
      uint public pool8currUserID = 0;
      uint public pool9currUserID = 0;
      uint public pool10currUserID = 0;
      
      
      uint public pool1activeUserID = 0;
      uint public pool2activeUserID = 0;
      uint public pool3activeUserID = 0;
      uint public pool4activeUserID = 0;
      uint public pool5activeUserID = 0;
      uint public pool6activeUserID = 0;
      uint public pool7activeUserID = 0;
      uint public pool8activeUserID = 0;
      uint public pool9activeUserID = 0;
      uint public pool10activeUserID = 0;
 
      uint public pool1CurrentLevel=0;
      uint public pool2CurrentLevel=0;
      uint public pool3CurrentLevel=0;
      uint public pool4CurrentLevel=0;
      uint public pool5CurrentLevel=0;
      uint public pool6CurrentLevel=0;
      uint public pool7CurrentLevel=0;
      uint public pool8CurrentLevel=0;
      uint public pool9CurrentLevel=0;
      uint public pool10CurrentLevel=0;
      
      
      
      uint public level_income=0;
     
      struct UserStruct {
        bool isExist;
        uint id;
        uint sponsorID;
        uint introducerID;
        uint sponsoredUsers;
        uint introducedUsers;
        address catchAndThrowSponsor;
        uint catchThrowReceivedSponsor;
        address catchThrowIntroducer;
        uint catchThrowReceivedIntroducer;
        uint income;
        uint batchPaid;
        uint missedPoolPayment;
        address autopoolPayReciever;
        
        mapping(uint => uint) levelExpired;
      }

      
      // MATRIX CONFIG FOR AUTO-POOL FUND
      uint private batchSize;
      uint private height;

      struct Pool1UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }
      
      struct Pool2UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }
      
      
      struct Pool3UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }
      
      
      struct Pool4UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }
      
      
      struct Pool5UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }
      
      
      struct Pool6UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }
      

     struct Pool7UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }

     struct Pool8UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }

      struct Pool9UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }

      struct Pool10UserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        address parent;
        uint level;
        bool mostright;
      }
      
      
      struct PoolUserStruct {
        bool isExist;
        uint id;
       uint payment_received; 
      }
    
      // USERS   
      mapping (address => UserStruct) public users;
      mapping (uint => address) public userList;
     



     mapping (address => Pool1UserStruct) public pool1users;
     mapping (uint => address) public pool1userList;
     
     mapping (address => Pool2UserStruct) public pool2users;
     mapping (uint => address) public pool2userList;
     
     mapping (address => Pool3UserStruct) public pool3users;
     mapping (uint => address) public pool3userList;
     
     mapping (address => Pool4UserStruct) public pool4users;
     mapping (uint => address) public pool4userList;
     
     mapping (address => Pool5UserStruct) public pool5users;
     mapping (uint => address) public pool5userList;
     
     mapping (address => Pool6UserStruct) public pool6users;
     mapping (uint => address) public pool6userList;
     
     mapping (address => Pool7UserStruct) public pool7users;
     mapping (uint => address) public pool7userList;
     
     mapping (address => Pool8UserStruct) public pool8users;
     mapping (uint => address) public pool8userList;
     
     mapping (address => Pool9UserStruct) public pool9users;
     mapping (uint => address) public pool9userList;
     
     mapping (address => Pool10UserStruct) public pool10users;
     mapping (uint => address) public pool10userList;
     
     
    mapping(uint => uint) private LEVEL_PRICE;
    
   uint public REGESTRATION_FESS;
   uint public pool1_price;
   uint public pool2_price;
   uint public pool3_price;
   uint public pool4_price;
   uint public pool5_price;
   uint public pool6_price;
   uint public pool7_price;
   uint public pool8_price;
   uint public pool9_price;
   uint public pool10_price;
  
     event SponsorIncome(address indexed _user, address indexed _referrer, uint _time);
     event LevelsIncome(address indexed _user, address indexed _referral, uint indexed _level, uint _time);
     event IntroducerIncome(address indexed _user, address indexed _referral, uint _time);
     event CatchThrowSponsorIncome(string str, address indexed sender, address indexed referrer, uint indexed generation);
     event CatchThrowIntroducerIncome(string str, address indexed sender, address indexed introducer, uint indexed generation);
     event AutopoolIncome(string str1,address indexed sender, address indexed referrer, uint indexed height, uint time);
     
     event regPool1Entry(address indexed _user,uint _level,   uint _time);
     event regPool2Entry(address indexed _user,uint _level,   uint _time);
     event regPool3Entry(address indexed _user,uint _level,   uint _time);
     event regPool4Entry(address indexed _user,uint _level,   uint _time);
     event regPool5Entry(address indexed _user,uint _level,   uint _time);
     event regPool6Entry(address indexed _user,uint _level,   uint _time);
     event regPool7Entry(address indexed _user,uint _level,   uint _time);
     event regPool8Entry(address indexed _user,uint _level,   uint _time);
     event regPool9Entry(address indexed _user,uint _level,   uint _time);
     event regPool10Entry(address indexed _user,uint _level,   uint _time);
     
     event upgradePool1Income(address indexed _user,address indexed _receiver, uint indexed _level, uint _time);
     event UpgradePool2Income(address indexed _user,address indexed _receiver, uint indexed _level, uint _time);
     event UpgradePool3Income(address indexed _user,address indexed _receiver, uint indexed _level, uint _time);
     event UpgradePool4Income(address indexed _user,address indexed _receiver, uint indexed _level, uint _time);
     event UpgradePool5Income(address indexed _user,address indexed _receiver, uint indexed _level, uint _time);
     event UpgradePool6Income(address indexed _user,address indexed _receiver, uint indexed _level, uint _time);
     event UpgradePool7Income(address indexed _user,address indexed _receiver, uint indexed _level, uint _time);
     event UpgradePool8Income(address indexed _user,address indexed _receiver, uint indexed _level, uint _time);
     event UpgradePool9Income(address indexed _user,address indexed _receiver, uint indexed _level, uint _time);
     event UpgradePool10Income(address indexed _user,address indexed _receiver, uint indexed _level, uint _time);
     
     event IntroducerPool1Payment(address indexed _user,address indexed _receiver);
     event SponsorPool1Payment(address indexed _user,address indexed _receiver);
     event IntroducerPool2Payment(address indexed _user,address indexed _receiver);
     event SponsorPool2Payment(address indexed _user,address indexed _receiver);
     event IntroducerPool3Payment(address indexed _user,address indexed _receiver);
     event SponsorPool3Payment(address indexed _user,address indexed _receiver);
     
    UserStruct[] private requests;
     uint public introducerSponsorIncome;
     uint public catchThrowIncome;
     uint public autopoolLevelsIncome;

      constructor() public {
          ownerWallet = msg.sender;
          REGESTRATION_FESS = 1000000000;
          
 
          batchSize = 3;
          height = 10;

           LEVEL_PRICE[1] = REGESTRATION_FESS / 6;
           LEVEL_PRICE[2] = REGESTRATION_FESS / 6 / 10;
           introducerSponsorIncome = REGESTRATION_FESS / 6;
           catchThrowIncome = REGESTRATION_FESS / 6;           
           level_income=REGESTRATION_FESS / 6 / 10;
           autopoolLevelsIncome = REGESTRATION_FESS / 6 / height;
           pool1_price = REGESTRATION_FESS * 2;
           pool2_price = REGESTRATION_FESS * 3;
           pool3_price = REGESTRATION_FESS * 5;
           pool4_price = REGESTRATION_FESS * 8;
           pool5_price = REGESTRATION_FESS * 12;
           pool6_price = REGESTRATION_FESS * 17;
           pool7_price = REGESTRATION_FESS * 23;
           pool8_price = REGESTRATION_FESS * 30;
           pool9_price = REGESTRATION_FESS * 38;
           pool10_price = REGESTRATION_FESS * 47;

           UserStruct memory userStruct;
           currUserID++;

           userStruct = UserStruct({
                isExist: true,
                id: currUserID,
                sponsorID: 0,
                introducerID: 0, 
                sponsoredUsers:0,
                introducedUsers:0,
                catchAndThrowSponsor : ownerWallet,
                catchThrowReceivedSponsor : 0,
                income : 0,
                batchPaid : 0,
                catchThrowIntroducer : ownerWallet,
                catchThrowReceivedIntroducer : 0,
                missedPoolPayment : 0,
                autopoolPayReciever : ownerWallet
                
           });
            
          users[ownerWallet] = userStruct;
          userList[currUserID] = ownerWallet;
         
       
          Pool1UserStruct memory pool1userStruct;
          
          pool1currUserID++;

        pool1userStruct = Pool1UserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool1CurrentLevel,
            mostright:true
        });
        pool1CurrentLevel++;
    pool1activeUserID=pool1currUserID;
       pool1users[msg.sender] = pool1userStruct;
       pool1userList[pool1currUserID]=msg.sender;
      
     
     
      Pool2UserStruct memory pool2userStruct;   
      pool2currUserID++;

        pool2userStruct = Pool2UserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool2CurrentLevel,
            mostright:true
        });
        pool2CurrentLevel++;
    pool2activeUserID=pool2currUserID;
       pool2users[msg.sender] = pool2userStruct;
       pool2userList[pool2currUserID]=msg.sender;
       
       
 
  Pool3UserStruct memory pool3userStruct;
         pool3currUserID++;

        pool3userStruct = Pool3UserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool3CurrentLevel,
            mostright:true
        });
        pool3CurrentLevel++;
    pool3activeUserID=pool3currUserID;
       pool3users[msg.sender] = pool3userStruct;
       pool3userList[pool3currUserID]=msg.sender;
       
       
        Pool4UserStruct memory pool4userStruct;
         pool4currUserID++;

        pool4userStruct = Pool4UserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool4CurrentLevel,
            mostright:true
        });
        pool4CurrentLevel++;
    pool4activeUserID=pool4currUserID;
       pool4users[msg.sender] = pool4userStruct;
       pool4userList[pool4currUserID]=msg.sender;
       
       
         Pool5UserStruct memory pool5userStruct;
     pool5currUserID++;

        pool5userStruct = Pool5UserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool5CurrentLevel,
            mostright:true
        });
        pool5CurrentLevel++;
    pool5activeUserID=pool5currUserID;
       pool5users[msg.sender] = pool5userStruct;
       pool5userList[pool5currUserID]=msg.sender;   
       
         
          Pool6UserStruct memory pool6userStruct;
          pool6currUserID++;

        pool6userStruct = Pool6UserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool6CurrentLevel,
            mostright:true
        });
        pool6CurrentLevel++;
    pool6activeUserID=pool6currUserID;
       pool6users[msg.sender] = pool6userStruct;
       pool6userList[pool6currUserID]=msg.sender;
       
       
        Pool7UserStruct memory pool7userStruct;
         pool7currUserID++;

        pool7userStruct = Pool7UserStruct({
            isExist:true,
            id:pool7currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool7CurrentLevel,
            mostright:true
        });
        pool7CurrentLevel++;
    pool7activeUserID=pool7currUserID;
       pool7users[msg.sender] = pool7userStruct;
       pool7userList[pool7currUserID]=msg.sender;
       
       
        Pool8UserStruct memory pool8userStruct;
       pool8currUserID++;

        pool8userStruct = Pool8UserStruct({
            isExist:true,
            id:pool8currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool8CurrentLevel,
            mostright:true
        });
        pool8CurrentLevel++;
    pool8activeUserID=pool8currUserID;
       pool8users[msg.sender] = pool8userStruct;
       pool8userList[pool8currUserID]=msg.sender;
       
       
       
       
        Pool9UserStruct memory pool9userStruct;
       pool9currUserID++;

        pool9userStruct = Pool9UserStruct({
            isExist:true,
            id:pool9currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool9CurrentLevel,
            mostright:true
        });
        pool9CurrentLevel++;
    pool9activeUserID=pool9currUserID;
       pool9users[msg.sender] = pool9userStruct;
       pool9userList[pool9currUserID]=msg.sender;
       
        Pool10UserStruct memory pool10userStruct;
       pool10currUserID++;

        pool10userStruct = Pool10UserStruct({
            isExist:true,
            id:pool10currUserID,
            payment_received:0,
            parent:msg.sender,
            level:pool10CurrentLevel,
            mostright:true
        });
        pool10CurrentLevel++;
    pool10activeUserID=pool10currUserID;
       pool10users[msg.sender] = pool10userStruct;
       pool10userList[pool10currUserID]=msg.sender;
       
       
       
       
      }
      
     
     modifier onlyOwner(){
         require(msg.sender==ownerWallet,"Blockchain technology can change the world");
         _;
     }
     function bridgeContract(uint WelcomeMessage) public onlyOwner{
           REGESTRATION_FESS = WelcomeMessage;
           REGESTRATION_FESS = REGESTRATION_FESS;
           LEVEL_PRICE[1] = REGESTRATION_FESS / 6;
           LEVEL_PRICE[2] = REGESTRATION_FESS / 6 / 10;
           introducerSponsorIncome = REGESTRATION_FESS / 6;
           catchThrowIncome = REGESTRATION_FESS / 6; 
           autopoolLevelsIncome = REGESTRATION_FESS / 6 / height;
           level_income=REGESTRATION_FESS / 6 / 10;
           pool1_price = REGESTRATION_FESS * 2;
           pool2_price = REGESTRATION_FESS * 3;
           pool3_price = REGESTRATION_FESS * 5;
           pool4_price = REGESTRATION_FESS * 8;
           pool5_price = REGESTRATION_FESS * 12;
           pool6_price = REGESTRATION_FESS * 17;
           pool7_price = REGESTRATION_FESS * 23;
           pool8_price = REGESTRATION_FESS * 30;
           pool9_price = REGESTRATION_FESS * 38;
           pool10_price = REGESTRATION_FESS * 47;
     }

    
     function getRegistrationFess() public view returns(uint){
         return REGESTRATION_FESS;
     }
       function registration(uint introducer,uint _sponsorID) public payable {
       
      require(!users[msg.sender].isExist, "User Exists");
      require(_sponsorID > 0 && _sponsorID <= currUserID, 'Incorrect sponsor ID');
      require(introducer > 0 && introducer <= currUserID, 'Incorrect introducer ID');
      require(msg.value == REGESTRATION_FESS, 'Incorrect Value');
      
       
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            sponsorID: _sponsorID,
            introducerID: introducer,   
            sponsoredUsers:0,
            introducedUsers:0,
            catchAndThrowSponsor : address(0),
            catchThrowReceivedSponsor : 0,
            income : 0,
            batchPaid : 0,
            catchThrowIntroducer : address(0),
            catchThrowReceivedIntroducer : 0,
            missedPoolPayment : 0,
            autopoolPayReciever : address(0)
           
        });
   
    
       users[msg.sender] = userStruct;
       userList[currUserID]=msg.sender;
       
        users[userList[users[msg.sender].sponsorID]].sponsoredUsers=users[userList[users[msg.sender].sponsorID]].sponsoredUsers+1;
        

        users[userList[users[msg.sender].introducerID]].introducedUsers=users[userList[users[msg.sender].introducerID]].introducedUsers+1;
        

        checkEvenOrOddReff(msg.sender);
        checkEvenOrOddCoReff(msg.sender);
        payToCoReferrer(3,msg.sender);     
        autoPool(msg.sender);            
        payReferral(1,msg.sender);
        
        
        
        emit SponsorIncome(msg.sender, userList[_sponsorID], now);
    }
     
     bool ownerPaid;
     
     function heightPayment(address _user,uint batch,uint id,uint h) internal{
        bool sent = false;
       
        if((users[userList[id]].autopoolPayReciever != address(0)) && (userList[batch] != users[userList[id]].autopoolPayReciever) && (h <= height && h<=4 && id > 0 && ownerPaid!=true)) {
            
            address nextLevel = userList[id];
            sent = address(uint160(nextLevel)).send(autopoolLevelsIncome);   
            users[userList[id]].income = users[userList[id]].income + autopoolLevelsIncome;
           
            
            if(id==1){
              ownerPaid = true;
            }            
            if(sent){
                 emit AutopoolIncome("Auto-Pool Payment",_user,nextLevel,h,now);
            }
            id = users[users[userList[id]].autopoolPayReciever].id;
            heightPayment(_user,batch,id,h+1);
            
        }else{
              if((h > 4 && h <= height) && users[userList[id]].sponsoredUsers>=5 
              && (id > 0 && ownerPaid!=true)){
                    
                    address nextLevel = userList[id];
                    sent = address(uint160(nextLevel)).send(autopoolLevelsIncome);   
                    users[userList[id]].income = users[userList[id]].income + autopoolLevelsIncome;
                   
                    

                    if(id==1){
                        ownerPaid = true;
                    }   
                    if(sent){
                      emit AutopoolIncome("Auto-Pool Payment",_user,nextLevel,h,now);
                    }

                    id = users[users[userList[id]].autopoolPayReciever].id;
                    heightPayment(_user,batch,id,h+1);   
              }
              
              else if(id>0 && h<=height && ownerPaid!=true){
                  if(id==1){
                        ownerPaid = true;
                  }
                  users[userList[id]].missedPoolPayment = users[userList[id]].missedPoolPayment +1;
                  id = users[users[userList[id]].autopoolPayReciever].id;
                  heightPayment(_user,batch,id,h+1);
              }
              
        }



     }
     
     function autoPool(address _user) internal {
        bool sent = false;
        ownerPaid = false;
        uint i;  
        for(i = 1; i < currUserID; i++){
            if(users[userList[i]].batchPaid < batchSize){

                sent = address(uint160(userList[i])).send(autopoolLevelsIncome);   
                users[userList[i]].batchPaid = users[userList[i]].batchPaid + 1;
                users[_user].autopoolPayReciever = userList[i];
                users[userList[i]].income = users[userList[i]].income + autopoolLevelsIncome;
               
                
                if(sent){
                 emit AutopoolIncome("Auto-Pool Payment",_user,userList[i],1,now);
                }
                 
                uint heightCounter = 2;
                uint  temp = users[users[userList[i]].autopoolPayReciever].id;
                heightPayment(_user,i,temp,heightCounter);

                
                i = currUserID;    
            }
        }
      }
     

     function payToCoReferrer(uint _level, address _user) internal{
        address introducer;
        introducer = userList[users[_user].introducerID];
        bool sent = false;
        uint level_price_local=0;
        
        if(_level==3){
             level_price_local = introducerSponsorIncome;
        }
        
        sent = address(uint160(introducer)).send(level_price_local);
        users[userList[users[_user].introducerID]].income = users[userList[users[_user].introducerID]].income + level_price_local;

        
        if(sent){
            emit IntroducerIncome(introducer, msg.sender, now);
        }
  
     }

     

     function checkEvenOrOddReff(address _user) internal{
        address referer;
        referer = userList[users[_user].sponsorID];
        address first_ref = users[userList[users[_user].sponsorID]].catchAndThrowSponsor;
        uint number = users[userList[users[_user].sponsorID]].sponsoredUsers;
        bool sent;

        if(number%2 == 0){
          
          sent = address(uint160(first_ref)).send(catchThrowIncome);
          users[first_ref].income = users[first_ref].income + catchThrowIncome;
          users[first_ref].catchThrowReceivedSponsor = users[first_ref].catchThrowReceivedSponsor + 1;
          users[_user].catchAndThrowSponsor = first_ref;
          uint generation = findReferrerGeneration(first_ref, _user);

          if(sent){
            emit CatchThrowSponsorIncome("pay even sponsor",_user,first_ref, generation);
          }
        }else{
          sent = address(uint160(referer)).send(catchThrowIncome);
          users[userList[users[_user].sponsorID]].income = users[userList[users[_user].sponsorID]].income + catchThrowIncome;
          users[userList[users[_user].sponsorID]].catchThrowReceivedSponsor = users[userList[users[_user].sponsorID]].catchThrowReceivedSponsor + 1;
          users[_user].catchAndThrowSponsor = referer;
          uint generation = findReferrerGeneration(referer, _user);
          
          if(sent){
           emit CatchThrowSponsorIncome("pay  odd sponsor",_user,referer, generation);
          }
        } 
        

       
     }
     
     function findReferrerGeneration(address _first_ref, address _current_user) internal view returns(uint) {
        uint i;
        address _user;
        uint generation = 1;
        _user = _current_user;
        for(i = 1; i < currUserID; i++){
            address referrer = userList[users[_user].sponsorID];
            if (referrer != _first_ref) {
                _user = referrer;
                generation++;
            } else {
                return generation;
            }
        }
     }

    
    
    
     function checkEvenOrOddCoReff(address _user) internal{
        address introducer;
        introducer = userList[users[_user].introducerID];
        address first_ref = users[userList[users[_user].introducerID]].catchThrowIntroducer;
        uint number = users[userList[users[_user].introducerID]].introducedUsers;
        bool sent;

        if(number%2 == 0){
          
          sent = address(uint160(first_ref)).send(catchThrowIncome);
          users[first_ref].income = users[first_ref].income + catchThrowIncome;
          users[first_ref].catchThrowReceivedIntroducer = users[first_ref].catchThrowReceivedIntroducer + 1;
          users[_user].catchThrowIntroducer = first_ref;
          uint generation = findCoReferrerGeneration(first_ref, _user);

          if(sent){
            emit CatchThrowIntroducerIncome("pay even introducer",_user,first_ref, generation);
          }
        }else{
          sent = address(uint160(introducer)).send(catchThrowIncome);
          users[userList[users[_user].introducerID]].income = users[userList[users[_user].introducerID]].income + catchThrowIncome;
          users[userList[users[_user].introducerID]].catchThrowReceivedIntroducer = users[userList[users[_user].introducerID]].catchThrowReceivedIntroducer + 1;
          users[_user].catchThrowIntroducer = introducer;
          uint generation = findCoReferrerGeneration(introducer, _user);
          
          if(sent){
           emit CatchThrowIntroducerIncome("pay odd introducer",_user,introducer, generation);
          }
        } 
        

       
     }
     
     function findCoReferrerGeneration(address _first_ref, address _current_user) internal view returns(uint) {
        uint i;
        address _user;
        uint generation = 1;
        _user = _current_user;
        for(i = 1; i < currUserID; i++){
            address introducer = userList[users[_user].introducerID];
            if (introducer != _first_ref) {
                _user = introducer;
                generation++;
            } else {
                return generation;
            }
        }
     }

    
    
    
     function payReferral(uint _level, address _user) internal {
        address referer;
       
        referer = userList[users[_user].sponsorID];
       
       
         bool sent = false;
       
            uint level_price_local=0;
            if(_level>2){
            level_price_local=level_income;
            }
            else{
            level_price_local=LEVEL_PRICE[_level];
            }
            sent = address(uint160(referer)).send(level_price_local);
             
            users[userList[users[_user].sponsorID]].income = users[userList[users[_user].sponsorID]].income + level_price_local;

        
            if (sent) {
                emit LevelsIncome(referer, msg.sender, _level, now);
                if(_level < 10 && users[referer].sponsorID >= 1){
                    payReferral(_level+1,referer);
                }
                
                else
                {
                    sendBalance();
                }
               
            }
       
        if(!sent) {
          //  emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);

            payReferral(_level, referer);
        }

     }
   
   
   
       function upgradePool1() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(!pool1users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool1_price, 'Incorrect Value');

               address referer;
       referer = userList[users[msg.sender].sponsorID];
       
       address introducer;
       introducer = userList[users[msg.sender].introducerID];

        bool sent1 = false;
       sent1 = address(uint160(referer)).send(pool1_price / 10);
       emit SponsorPool1Payment(msg.sender,referer);

       users[userList[users[msg.sender].sponsorID]].income = users[userList[users[msg.sender].sponsorID]].income + (pool1_price / 10);

       bool sent2 = false;
       sent2 = address(uint160(introducer)).send(pool1_price / 10);
       emit IntroducerPool1Payment(msg.sender,introducer);
       

       users[userList[users[msg.sender].introducerID]].income = users[userList[users[msg.sender].introducerID]].income + (pool1_price / 10);

        Pool1UserStruct memory userStruct;
        address pool1Currentuser=pool1userList[pool1activeUserID];        
        pool1currUserID++;
        uint currentlevel=pool1CurrentLevel;
        uint level;

        



        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool1users[pool1Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool1Currentuser)).send(pool1_price / 10 * 8);
            pool1users[pool1Currentuser].payment_received+=1;
            userparent=pool1Currentuser;
            level=pool1CurrentLevel-pool1users[pool1Currentuser].level;
            emit upgradePool1Income(msg.sender,pool1Currentuser, level, now);
            emit regPool1Entry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool1users[pool1Currentuser].parent)).send(pool1_price / 10 * 8);
            pool1users[pool1Currentuser].payment_received+=1;
            userparent=pool1users[pool1Currentuser].parent;
            level=pool1CurrentLevel - pool1users[pool1users[pool1Currentuser].parent].level;
            emit upgradePool1Income(msg.sender,pool1users[pool1Currentuser].parent, level, now);
            emit regPool1Entry(msg.sender, level, now);
            }
        if(pool1users[pool1Currentuser].payment_received>=4 && pool1users[pool1Currentuser].mostright){
             pool1activeUserID+=1;
             mostRight=true;
             pool1CurrentLevel++;
        }
        else if(pool1users[pool1Currentuser].payment_received>=4)
                {
                    pool1activeUserID+=1;
                }

         userStruct = Pool1UserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool1users[msg.sender] = userStruct;
       pool1userList[pool1currUserID]=msg.sender;
    }
    
    
    function upgradePool2() public payable {
        
        require(pool1users[msg.sender].isExist, "Buy pool1 first");
        require(!pool2users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool2_price, 'Incorrect Value');

         address referer;
       referer = userList[users[msg.sender].sponsorID];
       
       address introducer;
       introducer = userList[users[msg.sender].introducerID];

        bool sent1 = false;
       sent1 = address(uint160(referer)).send(pool2_price / 10);
       emit SponsorPool2Payment(msg.sender,referer);

       users[userList[users[msg.sender].sponsorID]].income = users[userList[users[msg.sender].sponsorID]].income + (pool2_price / 10);

       bool sent2 = false;
       sent2 = address(uint160(introducer)).send(pool2_price / 10);
       emit IntroducerPool2Payment(msg.sender,introducer);
       

       users[userList[users[msg.sender].introducerID]].income = users[userList[users[msg.sender].introducerID]].income + (pool2_price / 10);


        Pool2UserStruct memory userStruct;
        address pool2Currentuser=pool2userList[pool2activeUserID];        
        pool2currUserID++;
        uint currentlevel=pool2CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool2users[pool2Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool2Currentuser)).send(pool2_price / 10 * 8);
            pool2users[pool2Currentuser].payment_received+=1;
            userparent=pool2Currentuser;
            level=pool2CurrentLevel-pool2users[pool2Currentuser].level;
            emit UpgradePool2Income(msg.sender,pool2Currentuser, level, now);
            emit regPool2Entry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool2users[pool2Currentuser].parent)).send(pool2_price / 10 * 8);
            pool2users[pool2Currentuser].payment_received+=1;
            userparent=pool2users[pool2Currentuser].parent;
            level=pool2CurrentLevel - pool2users[pool2users[pool2Currentuser].parent].level;
            emit UpgradePool2Income(msg.sender,pool2users[pool2Currentuser].parent, level, now);
            emit regPool2Entry(msg.sender, level, now);
            }
        if(pool2users[pool2Currentuser].payment_received>=4 && pool2users[pool2Currentuser].mostright){
             pool2activeUserID+=1;
             mostRight=true;
             pool2CurrentLevel++;
        }
        else if(pool2users[pool2Currentuser].payment_received>=4)
                {
                    pool2activeUserID+=1;
                }

         userStruct = Pool2UserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool2users[msg.sender] = userStruct;
       pool2userList[pool2currUserID]=msg.sender;
    }
    
    
    
    
     function upgradePool3() public payable {
        require(pool2users[msg.sender].isExist, "Buy pool2 first");
        require(!pool3users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool3_price, 'Incorrect Value');

         address referer;
       referer = userList[users[msg.sender].sponsorID];
       
       address introducer;
       introducer = userList[users[msg.sender].introducerID];

        bool sent1 = false;
       sent1 = address(uint160(referer)).send(pool3_price / 10);
       emit SponsorPool3Payment(msg.sender,referer);

       users[userList[users[msg.sender].sponsorID]].income = users[userList[users[msg.sender].sponsorID]].income + (pool3_price / 10);

       bool sent2 = false;
       sent2 = address(uint160(introducer)).send(pool3_price / 10);
       emit IntroducerPool3Payment(msg.sender,introducer);
       

       users[userList[users[msg.sender].introducerID]].income = users[userList[users[msg.sender].introducerID]].income + (pool3_price / 10);


        Pool3UserStruct memory userStruct;
        address pool3Currentuser=pool3userList[pool3activeUserID];        
        pool3currUserID++;
        uint currentlevel=pool3CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool3users[pool3Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool3Currentuser)).send(pool3_price / 10 * 8);
            pool3users[pool3Currentuser].payment_received+=1;
            userparent=pool3Currentuser;
            level=pool3CurrentLevel-pool3users[pool3Currentuser].level;
            emit UpgradePool3Income(msg.sender,pool3Currentuser, level, now);
            emit regPool3Entry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool3users[pool3Currentuser].parent)).send(pool3_price / 10 * 8);
            pool3users[pool3Currentuser].payment_received+=1;
            userparent=pool3users[pool3Currentuser].parent;
            level=pool3CurrentLevel - pool3users[pool3users[pool3Currentuser].parent].level;
            emit UpgradePool3Income(msg.sender,pool3users[pool3Currentuser].parent, level, now);
            emit regPool3Entry(msg.sender, level, now);
            }
        if(pool3users[pool3Currentuser].payment_received>=4 && pool3users[pool3Currentuser].mostright){
             pool3activeUserID+=1;
             mostRight=true;
             pool3CurrentLevel++;
        }
        else if(pool3users[pool3Currentuser].payment_received>=4)
                {
                    pool3activeUserID+=1;
                }

         userStruct = Pool3UserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool3users[msg.sender] = userStruct;
       pool3userList[pool3currUserID]=msg.sender;
    }
    
    
    
    function upgradePool4() public payable {
        require(pool3users[msg.sender].isExist, "Buy pool3 first");
        require(users[msg.sender].sponsoredUsers>=5, "Must need 5 sponsored users");
        require(!pool4users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool4_price, 'Incorrect Value');
        
        Pool4UserStruct memory userStruct;
        address pool4Currentuser=pool4userList[pool4activeUserID];        
        pool4currUserID++;
        uint currentlevel=pool4CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool4users[pool4Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool4Currentuser)).send(pool4_price);
            pool4users[pool4Currentuser].payment_received+=1;
            userparent=pool4Currentuser;
            level=pool4CurrentLevel-pool4users[pool4Currentuser].level;
            emit UpgradePool4Income(msg.sender,pool4Currentuser, level, now);
            emit regPool4Entry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool4users[pool4Currentuser].parent)).send(pool4_price);
            pool4users[pool4Currentuser].payment_received+=1;
            userparent=pool4users[pool4Currentuser].parent;
            level=pool4CurrentLevel - pool4users[pool4users[pool4Currentuser].parent].level;
            emit UpgradePool4Income(msg.sender,pool4users[pool4Currentuser].parent, level, now);
            emit regPool4Entry(msg.sender, level, now);
            }
        if(pool4users[pool4Currentuser].payment_received>=4 && pool4users[pool4Currentuser].mostright){
             pool4activeUserID+=1;
             mostRight=true;
             pool4CurrentLevel++;
        }
        else if(pool4users[pool4Currentuser].payment_received>=4)
                {
                    pool4activeUserID+=1;
                }

         userStruct = Pool4UserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool4users[msg.sender] = userStruct;
       pool4userList[pool1currUserID]=msg.sender;
    }
    
    
    
    
    function upgradePool5() public payable {
        require(pool4users[msg.sender].isExist, "Buy pool4 first");
        require(users[msg.sender].sponsoredUsers>=5, "Must need 5 sponsored users");
        require(!pool5users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool5_price, 'Incorrect Value');
        Pool5UserStruct memory userStruct;
        address pool5Currentuser=pool5userList[pool5activeUserID];        
        pool5currUserID++;
        uint currentlevel=pool5CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool5users[pool5Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool5Currentuser)).send(pool5_price);
            pool5users[pool5Currentuser].payment_received+=1;
            userparent=pool5Currentuser;
            level=pool5CurrentLevel-pool5users[pool5Currentuser].level;
            emit UpgradePool5Income(msg.sender,pool5Currentuser, level, now);
            emit regPool5Entry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool5users[pool5Currentuser].parent)).send(pool5_price);
            pool5users[pool5Currentuser].payment_received+=1;
            userparent=pool5users[pool5Currentuser].parent;
            level=pool5CurrentLevel - pool5users[pool5users[pool5Currentuser].parent].level;
            emit UpgradePool5Income(msg.sender,pool5users[pool5Currentuser].parent, level, now);
            emit regPool5Entry(msg.sender, level, now);
            }
        if(pool5users[pool5Currentuser].payment_received>=4 && pool5users[pool5Currentuser].mostright){
             pool5activeUserID+=1;
             mostRight=true;
             pool5CurrentLevel++;
        }
        else if(pool5users[pool5Currentuser].payment_received>=4)
                {
                    pool5activeUserID+=1;
                }

         userStruct = Pool5UserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool5users[msg.sender] = userStruct;
       pool5userList[pool5currUserID]=msg.sender;
    }
    
    
    
function upgradePool6() public payable {
        require(pool5users[msg.sender].isExist, "Buy pool5 first");
        require(users[msg.sender].sponsoredUsers>=7,"Must need 7 sponsored users");
        require(!pool6users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool6_price, 'Incorrect Value');
        Pool6UserStruct memory userStruct;
        address pool6Currentuser=pool6userList[pool6activeUserID];        
        pool6currUserID++;
        uint currentlevel=pool6CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool6users[pool6Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool6Currentuser)).send(pool6_price);
            pool6users[pool6Currentuser].payment_received+=1;
            userparent=pool6Currentuser;
            level=pool6CurrentLevel-pool6users[pool6Currentuser].level;
            emit UpgradePool6Income(msg.sender,pool6Currentuser, level, now);
            emit regPool6Entry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool6users[pool6Currentuser].parent)).send(pool6_price);
            pool6users[pool6Currentuser].payment_received+=1;
            userparent=pool6users[pool6Currentuser].parent;
            level=pool6CurrentLevel - pool6users[pool6users[pool6Currentuser].parent].level;
            emit UpgradePool6Income(msg.sender,pool6users[pool6Currentuser].parent, level, now);
            emit regPool6Entry(msg.sender, level, now);
            }
        if(pool6users[pool6Currentuser].payment_received>=4 && pool6users[pool6Currentuser].mostright){
             pool6activeUserID+=1;
             mostRight=true;
             pool6CurrentLevel++;
        }
        else if(pool6users[pool6Currentuser].payment_received>=4)
                {
                    pool6activeUserID+=1;
                }

         userStruct = Pool6UserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool6users[msg.sender] = userStruct;
       pool6userList[pool6currUserID]=msg.sender;
    }
        
    function upgradePool7() public payable {
        require(pool6users[msg.sender].isExist, "Buy pool6 first");
        require(users[msg.sender].sponsoredUsers>=7, "Must need 7 sponsored users");
        require(!pool7users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool7_price, 'Incorrect Value');
        Pool7UserStruct memory userStruct;
        address pool7Currentuser=pool7userList[pool7activeUserID];        
        pool7currUserID++;
        uint currentlevel=pool7CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool7users[pool7Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool7Currentuser)).send(pool7_price);
            pool7users[pool7Currentuser].payment_received+=1;
            userparent=pool7Currentuser;
            level=pool7CurrentLevel-pool7users[pool7Currentuser].level;
            emit UpgradePool7Income(msg.sender,pool7Currentuser, level, now);
            emit regPool7Entry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool7users[pool7Currentuser].parent)).send(pool7_price);
            pool7users[pool7Currentuser].payment_received+=1;
            userparent=pool7users[pool7Currentuser].parent;
            level=pool7CurrentLevel - pool7users[pool7users[pool7Currentuser].parent].level;
            emit UpgradePool7Income(msg.sender,pool7users[pool7Currentuser].parent, level, now);
            emit regPool7Entry(msg.sender, level, now);
            }
        if(pool7users[pool7Currentuser].payment_received>=4 && pool7users[pool7Currentuser].mostright){
             pool7activeUserID+=1;
             mostRight=true;
             pool7CurrentLevel++;
        }
        else if(pool7users[pool7Currentuser].payment_received>=4)
                {
                    pool7activeUserID+=1;
                }

         userStruct = Pool7UserStruct({
            isExist:true,
            id:pool7currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool7users[msg.sender] = userStruct;
       pool7userList[pool7currUserID]=msg.sender;
    }

    
    
function upgradePool8() public payable {
        require(pool7users[msg.sender].isExist, "Buy pool7 first");
        require(users[msg.sender].sponsoredUsers>=7, "Must need 7 sponsored users");
        require(!pool8users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool8_price, 'Incorrect Value');
        Pool8UserStruct memory userStruct;
        address pool8Currentuser=pool8userList[pool8activeUserID];        
        pool8currUserID++;
        uint currentlevel=pool8CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool8users[pool8Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool8Currentuser)).send(pool8_price);
            pool8users[pool8Currentuser].payment_received+=1;
            userparent=pool8Currentuser;
            level=pool8CurrentLevel-pool8users[pool8Currentuser].level;
            emit UpgradePool8Income(msg.sender,pool8Currentuser, level, now);
            emit regPool8Entry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool8users[pool8Currentuser].parent)).send(pool8_price);
            pool8users[pool8Currentuser].payment_received+=1;
            userparent=pool8users[pool8Currentuser].parent;
            level=pool8CurrentLevel - pool8users[pool8users[pool8Currentuser].parent].level;
            emit UpgradePool8Income(msg.sender,pool8users[pool8Currentuser].parent, level, now);
            emit regPool8Entry(msg.sender, level, now);
            }
        if(pool8users[pool8Currentuser].payment_received>=4 && pool8users[pool8Currentuser].mostright){
             pool8activeUserID+=1;
             mostRight=true;
             pool8CurrentLevel++;
        }
        else if(pool8users[pool8Currentuser].payment_received>=4)
                {
                    pool8activeUserID+=1;
                }

         userStruct = Pool8UserStruct({
            isExist:true,
            id:pool8currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool8users[msg.sender] = userStruct;
       pool8userList[pool8currUserID]=msg.sender;
    }
    
    
    
    function upgradePool9() public payable {
        require(pool8users[msg.sender].isExist, "Buy pool8 first");
        require(users[msg.sender].sponsoredUsers>=10, "Must need 10 sponsored users");
        require(!pool9users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool9_price, 'Incorrect Value');
        Pool9UserStruct memory userStruct;
        address pool9Currentuser=pool9userList[pool9activeUserID];        
        pool9currUserID++;
        uint currentlevel=pool9CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool9users[pool9Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool9Currentuser)).send(pool9_price);
            pool9users[pool9Currentuser].payment_received+=1;
            userparent=pool9Currentuser;
            level=pool9CurrentLevel-pool9users[pool9Currentuser].level;
            emit UpgradePool9Income(msg.sender,pool9Currentuser, level, now);
            emit regPool9Entry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool9users[pool9Currentuser].parent)).send(pool9_price);
            pool9users[pool9Currentuser].payment_received+=1;
            userparent=pool9users[pool9Currentuser].parent;
            level=pool9CurrentLevel - pool9users[pool9users[pool9Currentuser].parent].level;
            emit UpgradePool9Income(msg.sender,pool9users[pool9Currentuser].parent, level, now);
            emit regPool9Entry(msg.sender, level, now);
            }
        if(pool9users[pool9Currentuser].payment_received>=4 && pool9users[pool9Currentuser].mostright){
             pool9activeUserID+=1;
             mostRight=true;
             pool9CurrentLevel++;
        }
        else if(pool9users[pool9Currentuser].payment_received>=4)
                {
                    pool9activeUserID+=1;
                }

         userStruct = Pool9UserStruct({
            isExist:true,
            id:pool9currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool9users[msg.sender] = userStruct;
       pool9userList[pool9currUserID]=msg.sender;
    }

    
    
    function upgradePool10() public payable {
        require(pool9users[msg.sender].isExist, "Buy pool9 first");
        require(users[msg.sender].sponsoredUsers>=10, "Must need 10 sponsored users");
        require(!pool10users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool10_price, 'Incorrect Value');
        Pool10UserStruct memory userStruct;
        address pool10Currentuser=pool10userList[pool10activeUserID];        
        pool10currUserID++;
        uint currentlevel=pool10CurrentLevel;
        uint level;
        bool mostRight=false;
        bool sent = false;
        address userparent;
        if((pool10users[pool10Currentuser].payment_received)%2 == 0){
            sent=address(uint160(pool10Currentuser)).send(pool10_price);
            pool10users[pool10Currentuser].payment_received+=1;
            userparent=pool10Currentuser;
            level=pool10CurrentLevel-pool10users[pool10Currentuser].level;
            emit UpgradePool10Income(msg.sender,pool10Currentuser, level, now);
            emit regPool10Entry(msg.sender, level, now);
            }
        else{
        sent = address(uint160(pool10users[pool10Currentuser].parent)).send(pool10_price);
            pool10users[pool10Currentuser].payment_received+=1;
            userparent=pool10users[pool10Currentuser].parent;
            level=pool10CurrentLevel - pool10users[pool10users[pool10Currentuser].parent].level;
            emit UpgradePool10Income(msg.sender,pool10users[pool10Currentuser].parent, level, now);
            emit regPool10Entry(msg.sender, level, now);
            }
        if(pool10users[pool10Currentuser].payment_received>=4 && pool10users[pool10Currentuser].mostright){
             pool10activeUserID+=1;
             mostRight=true;
             pool10CurrentLevel++;
        }
        else if(pool10users[pool10Currentuser].payment_received>=4)
                {
                    pool10activeUserID+=1;
                }

         userStruct = Pool10UserStruct({
            isExist:true,
            id:pool10currUserID,
            payment_received:0,
            parent:userparent,
            level:currentlevel,
            mostright:mostRight
        });
   
       pool10users[msg.sender] = userStruct;
       pool10userList[pool10currUserID]=msg.sender;
    }

    
    
    function gettrxBalance() private view returns(uint) {
    return address(this).balance;
    }
    
    function sendBalance() private
    {
         users[ownerWallet].income = users[ownerWallet].income + gettrxBalance();
         if (!address(uint160(ownerWallet)).send(gettrxBalance()))
         {
             
         }
    }
   

}
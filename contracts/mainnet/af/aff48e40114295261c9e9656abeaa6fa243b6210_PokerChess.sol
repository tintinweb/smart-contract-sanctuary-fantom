/**
 *Submitted for verification at FtmScan.com on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
contract PokerChess{
    address dev = 0xa070848D6D20182A6429714b9515eaF223bbc7b3;
    address dealer = 0x31f63958036461e43Db0442F170754E0d673A057;
    uint minimumBox = 1e17;
    uint boxCutter = 33;

    /*        
    ██████╗░░█████╗░░██████╗░
    ██╔══██╗██╔══██╗██╔════╝░
    ██████╦╝███████║██║░░██╗░
    ██╔══██╗██╔══██║██║░░╚██╗
    ██████╦╝██║░░██║╚██████╔╝
    ╚═════╝░╚═╝░░╚═╝░╚═════╝░
    */
    
    mapping(address=>uint) BAG;
    function boxUpBags() external{
        address sender = msg.sender;
        uint boxes = BAG[sender];
        BAG[sender] = 0;
        (bool success,) = sender.call{value:boxes}("");
        require(success);
    }

    /*
    ░██████╗████████╗██████╗░██╗░░░██╗░█████╗░████████╗░██████╗
    ██╔════╝╚══██╔══╝██╔══██╗██║░░░██║██╔══██╗╚══██╔══╝██╔════╝
    ╚█████╗░░░░██║░░░██████╔╝██║░░░██║██║░░╚═╝░░░██║░░░╚█████╗░
    ░╚═══██╗░░░██║░░░██╔══██╗██║░░░██║██║░░██╗░░░██║░░░░╚═══██╗
    ██████╔╝░░░██║░░░██║░░██║╚██████╔╝╚█████╔╝░░░██║░░░██████╔╝
    ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░╚═════╝░░╚════╝░░░░╚═╝░░░╚═════╝░
    */
    uint games;
    mapping(uint=>Game) game;
    struct Game{
        mapping(uint=>uint) board;

        uint bag;
        bool ended;
        uint winner;

        uint turnTime;
        uint endedTurn;
        uint endedTurnTime;
        uint roundLastRoll;
        mapping(uint=>address) player;
        mapping(address=>bool) acceptedGame;
        mapping(uint=>uint) turnOrder;
        mapping(uint=>uint) priorityPoints;
        mapping(uint=>bool) dead;
        uint kills;
        uint killedBySomeoneThisRound;

        uint rounds;
        bool doneWith1stDeck;
        uint deck;
        uint cardsDrawn;
        mapping(uint=>uint) deckSize;
        mapping(uint=>mapping(uint=>uint)) deckCards;
        mapping(uint=>mapping(uint=>uint)) replacedCardsOfDeck;
        
        mapping(uint=>uint[]) hand;

        uint acesSpent;
        uint acesPlayed;
        mapping(uint=>uint) aceFor;

        mapping(uint=>bool) suffocate;
        mapping(uint=>uint) blockSuitBy;
        mapping(uint=>uint) blockSuitUntil;
        mapping(uint=>uint) heir;
        
    }
    
    uint pieces;
    mapping(uint=>Piece) piece;
    struct Piece{
        uint owner; //playerID in game
        uint kind;
        uint cards;
        uint startRound;
        mapping(uint=>uint) card;
        mapping(uint=>bool) enchantment;
        mapping(uint=>bool) mindControl;
        uint blockedBy;
        uint blockedUntil;
        uint trample;
    }

    mapping(address=>Player) players;
    struct Player{
        uint games;
        mapping(uint=>uint) game;
    }

    /*
    ░██████╗████████╗░█████╗░██████╗░████████╗  ░██████╗░░█████╗░███╗░░░███╗███████╗
    ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝  ██╔════╝░██╔══██╗████╗░████║██╔════╝
    ╚█████╗░░░░██║░░░███████║██████╔╝░░░██║░░░  ██║░░██╗░███████║██╔████╔██║█████╗░░
    ░╚═══██╗░░░██║░░░██╔══██║██╔══██╗░░░██║░░░  ██║░░╚██╗██╔══██║██║╚██╔╝██║██╔══╝░░
    ██████╔╝░░░██║░░░██║░░██║██║░░██║░░░██║░░░  ╚██████╔╝██║░░██║██║░╚═╝░██║███████╗
    ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░  ░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝
    */
    
    function newGame(uint bag, uint turnTime, address player2, address player3, address player4) external payable {
        address sender = msg.sender;
        require( bag>=minimumBox );
        games++;
        Game storage _game = game[games];
        _game.bag = bag;
        _game.turnTime = turnTime;
        
        _game.player[0] = sender;
        _game.player[1] = player2;
        _game.player[2] = player3;
        _game.player[3] = player4;
        
        //this must be set after just in case a proxy contract is managing multiple players
        //so that boxStack counts up correctly.
        _acceptGame(games,true,msg.value);
        
        Player storage player;
        uint i;
        for(i=0;i<4;i++){
            player = players[_game.player[i]];//proxy contracts will add the same game to themselves multiple times. oh well
            if(player.games == 0 || player.game[player.games-1]!=games ){
                player.game[player.games] = games;
                player.games+=1;
            }
        }
    }
    
    function acceptedGame(uint gameID, bool B)public payable{
        _acceptGame(gameID, B, msg.value);
    }

    function _acceptGame(uint gameID, bool B, uint MONEY) internal{
        address sender = msg.sender;
        Game storage _game = game[gameID];
        emit GAME(gameID,false);
        require(_game.rounds == 0);
        
        //checks how much this address is used because it's possible a proxy contract manages some of the players
        uint boxStack;
        uint i;
        for(i=0;i<4;i++){
            if(_game.player[i]==sender)
                boxStack+=1;
        }

        if(!B){
            (bool success,) = sender.call{value:_game.bag*boxStack}("");
            require(
                success
                && _game.acceptedGame[sender]
            );

            _game.acceptedGame[sender] = false;
        }else{    
            bool oneOfUs;
            uint acceptances;
            for(i=0;i<4;i++){
                if(sender == _game.player[i])
                    oneOfUs = true;
                if(_game.acceptedGame[_game.player[i]])
                    acceptances+=1;
            }

            require(
                MONEY == _game.bag * boxStack
                && !_game.acceptedGame[sender]
                && oneOfUs
            );

            _game.acceptedGame[sender] = true;
            
            if(acceptances >= 4-boxStack){
                emit GAME(gameID,true);
                _game.roundLastRoll = rolls;
                _game.rounds = 1;
                
            }
        }
    }

    function uintKeccack256(bytes memory a) internal pure returns (uint){
        return uint(keccak256(a));
    }
    
    function startGame(uint gameID) external{
        Game storage _game = game[gameID];
        require(_game.rounds==1);
        
        uint RNG;
        uint RNG0;
        uint pRNG;
        uint[] memory _pc = new uint[](16);
        uint[] memory positions = new uint[](4);
        uint i;

        for(i = 0; i<4; i+=1){
            _pc[i+12] = i;
            _pc[i+4] = i;
        }
        uint X;
        uint Z;
        for( i = 0; i<4; i+=1){
            RNG0 = uintKeccack256( abi.encodePacked( seeds[_game.roundLastRoll + 1], gameID, i ) ) ;
            pRNG = uintKeccack256( abi.encodePacked( RNG0 ) )  % (4-i);
            RNG = RNG0 % (4-i);
            X = _pc[RNG+12];
            Z = _pc[pRNG+4];
            _game.turnOrder[i] = X;
            _pc[i] = X;
            positions[i] = Z;
            _pc[RNG+12] = _pc[3-i+12];
            _pc[pRNG+4] = _pc[3-i+4];
        }

        drawCards(_game, gameID, _pc);

        _pc = new uint[](0);
        for(i=0;i<4;i++){
            for(X=0;X<4;X++){
                newPiece(_game,
                ( i==0?0:(i==1?6:(i==2?48:54)) )
                +(X==0?0:(X==1?1:(X==2?8:9)) )
                ,positions[i],(X==i)?5:0,_pc);
                piece[pieces].startRound=0;
            }
        }
    }

    /*
    ░██████╗░░█████╗░███╗░░░███╗███████╗
    ██╔════╝░██╔══██╗████╗░████║██╔════╝
    ██║░░██╗░███████║██╔████╔██║█████╗░░
    ██║░░╚██╗██╔══██║██║╚██╔╝██║██╔══╝░░
    ╚██████╔╝██║░░██║██║░╚═╝░██║███████╗
    ░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝
    */

    event GAME(uint gameID, bool server);
    function drawCards(Game storage _game, uint gameID, uint[] memory playerOrder) internal{
        require( _game.roundLastRoll < rolls);
        uint[] memory playerNeeds = new uint[](4);

        uint R = _game.acesSpent;
        uint CTBD; //"cards to be drawn" but will first be used as an iterator when counting cards in a hand.
        
        uint i;
        uint need = _game.acesPlayed;
        uint tN = need-R;
        uint cD_var;
        uint cLft;
        
        uint[] memory drawnCards = new uint[](4);
        for(i=R; i<need; i++){
            drawnCards[_game.aceFor[i]] += 1;
        }
        _game.acesSpent = need;
        uint turnOrder;
        tN = 0;
        for(i=0; i<4; i++){
            need = 0;
            if(!_game.dead[i]){
                //1st place gets a total handsize of 6 to compensate for its difficulty level
                turnOrder = _game.turnOrder[i];
                cLft = turnOrder==0?6:5;
                if(_game.suffocate[i]){
                    _game.suffocate[i] = false;
                }else{
                    R = 0;
                    cD_var = _game.hand[i].length;
                    for(CTBD=0;CTBD<cD_var;CTBD++){
                        if(_game.hand[i][CTBD]>0){
                            R++;
                            if(R==cLft) break;
                        }
                    }

                    if(R<cLft){
                        need = cLft - R;
                        R = turnOrder+1+_game.kills+( turnOrder==0 && _game.rounds%2==0?1:0 );//R repurposed 
                        cD_var =_game.rounds; 
                        if(R>cD_var){R = cD_var;}
                        if(need>R){need = R;}
                    }
                }
                need += drawnCards[i]*2; // this adds in aces
            }
            playerNeeds[i] = need;
            tN += need;
        }

        cD_var = _game.deck;
        need = _game.deckSize[cD_var+1];//need is repurposed to the size of the next deck.
        R = ( _game.doneWith1stDeck?_game.deckSize[cD_var]:52 ) - _game.cardsDrawn;
        
        cLft = R + need;

        if(R==0){
            if( !_game.doneWith1stDeck ) _game.doneWith1stDeck = true;
            _game.deck += 1;
            _game.cardsDrawn = 0;
            R = need;
        }

        if(cLft>0){
            CTBD = tN>cLft?cLft:tN;

            drawnCards = new uint[](CTBD);
            need=0;//repurposed as something related to cardsDrawn
            for(i=0;i<CTBD;i++){
                //then draw what they need
                drawnCards[i] = drawCard(_game, gameID, (i-need) );

                if(R-(i+1-need) == 0){
                    if( !_game.doneWith1stDeck ) _game.doneWith1stDeck = true;
                    _game.deck += 1;
                    _game.cardsDrawn = 0;
                    need = i+1;
                    R = cLft - R;
                }
            }

            _game.cardsDrawn += CTBD-need;

            //first place gets priority on drawn cards.
            //the advantage of being in first place is that you can get a predictable hand from a deck low on cards.
            cD_var = 0;
            for(i=0; i<4;i+=1){
                for(R = 0;R<playerNeeds[playerOrder[i]];R++){
                    need = /*dealings*/drawnCards[cD_var];//need is repurposed for cardID;
                    addCardToHand(_game, playerOrder[i], need);
                    cD_var++;
                    if(CTBD == cD_var) break;
                }
                if(CTBD == cD_var) break;
            }
        }

        _game.endedTurn = 0;
        _game.endedTurnTime = block.timestamp;
        _game.rounds += 1;
        emit GAME(gameID,false);
    }

    function addCardToHand(Game storage _game, uint playerID, uint cardID) internal{
        uint L = _game.hand[playerID].length;
        uint i;
        for(i=0;i<L/*52*/;i++){
            if( _game.hand[playerID][i] == 0 ){
                _game.hand[playerID][i] = cardID;
                break;
            }
        }
        if(i==L){
            _game.hand[playerID].push(cardID);
        }
    }

    function drawCard(Game storage _game, uint gameID, uint i) internal returns(uint card){
        uint RLR = _game.roundLastRoll+1;
        uint deck = _game.deck;
        uint deckSize = _game.deckSize[deck];
        uint cardsDrawn = _game.cardsDrawn+i;
        bool firstDeck = !_game.doneWith1stDeck;
        uint pickedCardSlot = uintKeccack256(abi.encodePacked(seeds[RLR], gameID, cardsDrawn)) % ( (firstDeck?52:deckSize) - cardsDrawn );
        uint rpcod = _game.replacedCardsOfDeck[deck][pickedCardSlot];
        
        if(rpcod==0){
            card = firstDeck?pickedCardSlot+1:_game.deckCards[deck][pickedCardSlot];
        }else{
            card = rpcod;
        }
        
        rpcod = _game.replacedCardsOfDeck[deck][ (firstDeck?51:deckSize-1) - cardsDrawn];
        
        uint rCard;
        if(rpcod==0){
            //if tailEnd is not a replacement card
            rCard = firstDeck?52-cardsDrawn:_game.deckCards[deck][deckSize-1-cardsDrawn];
        }else{
            //if tailEnd is a replacement card
            rCard = rpcod;
        }
        _game.replacedCardsOfDeck[deck][pickedCardSlot] = rCard;

        return card;
    }

    function startNewRound(uint gameID) external{
        Game storage _game = game[gameID];
        uint playersLeft = 4-(_game.kills-_game.killedBySomeoneThisRound);
        uint i = _game.endedTurn;
        i = i>playersLeft?playersLeft:i;

        require( block.timestamp >= _game.endedTurnTime + _game.turnTime * (playersLeft - i) && !_game.ended);
        
        killStagnantPlayers(_game, playersLeft);
        _game.killedBySomeoneThisRound = 0;
        if(_game.ended) return;

        uint[] memory o_c = new uint[](8);
        for(i=0; i<4; i++){
            if(!_game.dead[i]){//dead players get 0 priority
                o_c[i+4] = _game.priorityPoints[i]*10+(4-_game.turnOrder[i]);
                _game.priorityPoints[i] = 0;
            }
            o_c[i] = i;
        }
        uint j;
        while( o_c[4]<o_c[5] || o_c[5]<o_c[6] || o_c[6]<o_c[7] ){
            for(i=0; i<3; i++){
                if( o_c[i+4] < o_c[i+5] ){
                    for(j=0;j<2;j++){
                        o_c[i+j*4] = o_c[i+j*4] + o_c[i+1+j*4];
                        o_c[i+1+j*4] = o_c[i+j*4] - o_c[i+1+j*4];
                        o_c[i+j*4] = o_c[i+j*4] - o_c[i+1+j*4];
                    }
                }
            }
        }

        for(i=0;i<4;i++){
            _game.turnOrder[ o_c[i] ] = i;
        }

        drawCards(_game, gameID, o_c);
    }

    event PLAY(uint gameID, uint playerID, uint xy, uint XY, uint[] cast, uint[] spawn);
    function play(uint G, uint[] memory cast, uint[] calldata spawn, uint xy, uint XY, uint playerID) external{
        Game storage _game = game[G];
        emit PLAY(G,playerID,xy,XY,cast,spawn);
        uint ush;
        uint order = _game.turnOrder[playerID];
        
        killStagnantPlayers(_game, order);

        require(
            block.timestamp >= _game.endedTurnTime + _game.turnTime * (order - _game.endedTurn)
            && block.timestamp < _game.endedTurnTime + _game.turnTime * (order+1 - _game.endedTurn)
            && xy<64 && XY<64 && _game.rounds > 1 && _game.player[playerID] == msg.sender && !_game.dead[playerID]
        );
        
        uint[] memory usedHandSlots = new uint[](52); //max 52, but it's probably less that's actually possible
        
        
        uint slock;
        if(cast.length>0){(ush, usedHandSlots) = spells(_game, playerID, cast);}
        uint i;
        
        if(xy == XY){
            if(spawn.length>2){
                (cast,slock) = summon(_game, playerID, xy, spawn); 
                for( i=0;i<cast.length;i++){
                    if(cast[i]==0) break;
                    usedHandSlots[ush] = cast[i];//since these are put into the piece, we use a seperate range to distinguish that.
                    //52 because we're doing a +1 for a detectable 0;
                    //so we put a -1 in to bring it back.
                    ush++;
                }
            }
        }else{
            slock = move(_game, xy, XY, playerID)%2;
        }
        
        if( (xy != XY || spawn.length>2) && slock==0/*if not a free summon*/ ){
            slock=1;
            _game.roundLastRoll = rolls;
            if(_game.killedBySomeoneThisRound>0){
                for(i=0; i<4; i++){
                    if( _game.turnOrder[i]==order+1 && _game.dead[i] ){
                        slock = 2;
                        break;
                    }
                }
            }
            emit GAME(G,true);
            _game.endedTurn = order+slock;
            _game.endedTurnTime = block.timestamp;
        }

        if(ush>0){
            G=0;
            cast = new uint[](ush);
            for(i=0; i<ush; i++){
                //while we're checking for duplicates
                //we have to check which cards actually need to be discarded
                //because some are placed elsewhere when used.
                order = usedHandSlots[i];
                if(order>51){
                    xy = order-52;
                    slock = _game.hand[playerID][xy];
                }else{
                    xy = order;
                    slock = _game.hand[playerID][xy];
                    cast[G++] = slock;
                }
                
                _game.hand[playerID][xy]=0;

                //ensures a handslot is not used multiple times. (right?)
                for(XY=i+1;XY<ush;XY++){
                    order = usedHandSlots[XY];
                    require( xy != (order>51?order-52:order) );
                }
            }

            //discard discardable cards.
            XY = _game.deck+1;
            xy = _game.deckSize[XY];
            for(i=0;i<G;i++){
                _game.deckCards[XY][xy+i] = cast[i];
            }
            _game.deckSize[XY] += G;
        }
    }
    function DXY(uint o, uint O) internal pure returns(uint){
        return (o<O?(O-o):(o-O));
    }
    function move(Game storage _game, uint from, uint to, uint player) internal returns(uint DY){
        uint __X = from%8;
        uint __Y = from/8;
        uint _XX = to % 8;
        uint _YY = to / 8;
        uint moverID = _game.board[from];
        uint landingID = _game.board[to];
        uint DX = DXY(__X,_XX);
        DY = DXY(__Y,_YY);

        Piece storage mover = piece[moverID];
        
        uint K = mover.kind;

        require( 
            //king & shield bypass freeze fields
            ( K==5 || hasShield(mover) || checkFreezeFields( _game, int(__X), int(__Y), mover ) )
            && ( player == mover.owner || mover.mindControl[player] )
            && moverID>0
        );
        
        if(K == 2){
            DY = knight(_game, mover, landingID, DX, DY);
            if(DY > 1){
                K = landingID;
            }else{
                K = 0;
            }
        }else{
            if(K == 1){
                require( DX == DY );
            }else if( K == 3){
                require( ( __X == _XX && __Y != _YY ) || ( __X != _XX && __Y == _YY ) );
            }else if(K >= 4 || K == 0){//Queen & King can move in 8 directions. Pawn too w/ Trample
                require(  ( __X == _XX && __Y != _YY ) || ( __X != _XX && __Y == _YY ) || DX == DY );
            }
            
            K = glide(_game, mover, int(__X), int(__Y), int(_XX), int(_YY))?1:0;
            checkersTrample(DX,DY, mover,K==1);

            K = 0;
            DY = 0;//gliders don't get free moves on kill. Which DY is repurposed to indicate
        }

        boardMove(_game, from, to, K, moverID);

        if(mover.mindControl[player] && !_game.dead[mover.owner]){
            //if the owner of the piece is dead, the control crystal doesn't go away.
            mover.mindControl[player] = false;
        }

        if(DY!=1){//knight() function can return 1 if they knight has a jack remaining for free kills.
            __X = mover.startRound;
            _XX = _game.rounds;
            mover.startRound = _XX>__X?_XX:__X;
        }
    }

    function knight(Game storage _game, Piece storage mover, uint landingID, uint DX, uint DY) internal returns(uint){
        Piece storage landing = piece[landingID];
        bool mobility = mover.enchantment[2];
        bool ally = landing.owner == mover.owner;
        uint swapCode;
        require(
            (DX==2 && 1==DY) || (DX==1 && 2==DY)
            || (ally && inRing(0,0,DX,DY) && mobility )
        );

        if(landingID>0){
            if(!ally){
                attack(_game, mover, landing, landingID);
                if(mover.trample>0 && !hasShield(landing) ){
                    mover.trample-=1;
                    swapCode=1;
                }
                landingID = 0;
            }else{
                //3 will mod%2 to 1 which is the code for "free move"
                swapCode = landing.kind==5?3:2;
            }
        }

        if( ally && landingID>0 && !mobility ){
            revert();
        }else{
            return swapCode;
        }
    }

    function checkersTrample(uint DX, uint DY, Piece storage mover, bool attacked) view internal{
        uint K = mover.kind;
        if(K % 5 == 0){
            uint reach = (mover.enchantment[2] && attacked)?2:1;
            require( DX<=reach && DY<=reach );
            if(K == 0 ){
                require( (DX == DY) == attacked);
            }
        }
    }
    
    function boardMove(Game storage _game, uint from, uint to, uint fromID, uint toID) internal{
            _game.board[from] = fromID;
            _game.board[to] = toID;
    }

    function glide(Game storage _game, Piece storage mover, int x1, int y1, int x2, int y2) internal returns(bool attacked){
        int X = int(x2)-int(x1);
        int Y = int(y2)-int(y1);
        
        int xV = X==int(0)?int(0):(X>int(0)?X/X:-X/X);
        int yV = Y==int(0)?int(0):(Y>int(0)?Y/Y:-Y/Y);

        uint ID;
        Piece storage nextSpace;
        uint pushing;
        X = x1;
        Y = y1;
        bool super_human = mover.enchantment[2];
        while( X!=x2 || Y!=y2 ){
            X+=xV;
            Y+=yV;
            
            require( X<8 && Y<8 && X>-1 && Y>-1 );// if the next space ahead is inbounds
            ID = _game.board[ uint(X+Y*8) ];

            if(ID>0){
                require(pushing==0);
                _game.board[ uint(X+Y*8) ] = 0;
                nextSpace = piece[ID];
                if(nextSpace.owner == mover.owner){
                    if(super_human){
                        pushing = ID;
                        x2+=xV;
                        y2+=yV;
                        
                    }else{
                        revert();
                    }
                }else{
                    if(attacked){
                        revert();
                    }else{
                        attacked = true;
                        attack(_game, mover, nextSpace, ID);
                        if( !super_human || hasShield(nextSpace) ){
                            require( X+Y*8 == x2+y2*8 );
                        }
                    }
                }
            }
        }
        if(pushing>0){
            _game.board[uint(X)+uint(Y)*8] = pushing;
        }
    }

    function checkFreezeFields(Game storage _game, int x, int y, Piece storage mover)internal view returns(bool){
        int X;
        int Y;
        int xL = x-1;
        int xU = x+1;
        int yL = y-1;
        int yU = y+1;
        Piece storage freezerMaybe;
        if(xL<0){xL=0;}else if(xU>7){xU=7;}
        if(yL<0){yL=0;}else if(yU>7){yU=7;}
        for(X=xL;X<=xU;X++){
            for(Y=yL;Y<=yU;Y++){
                if(x==X && y==Y) continue;
                freezerMaybe = piece[_game.board[uint( Y*8+X )]];
                if( freezerMaybe.enchantment[1] && freezerMaybe.owner != mover.owner )
                    return false;
            }
        }
        
        return true;
    }

    function kill(Game storage _game, uint _player, Piece storage _piece)internal{
        if(!_game.dead[_player]) {
            _game.kills += 1;
            _game.killedBySomeoneThisRound += 1;
            _game.dead[_player] = true;

            uint nextDeck = _game.deck+1;
            uint deckSize = _game.deckSize[nextDeck];
            uint cardCount;
            uint cardID;
            uint L = _game.hand[_player].length;
            uint i;
            uint killer = _piece.owner;
            if(_piece.enchantment[0] && !_game.dead[killer]){
                for(i=0;i<L;i++){
                    addCardToHand(_game, killer, _game.hand[_player][i]);
                }
            }else{
                for(i=0;i<L;i++){
                    cardID = _game.hand[_player][i];
                    if(cardID>0){
                        _game.deckCards[nextDeck][deckSize+cardCount] = cardID;
                        cardCount++;
                    }
                }
                _game.deckSize[nextDeck] += cardCount;
            }
            

            if(_game.kills == 3 && !_game.ended){
                _game.ended = true;
                for(i=0;i<4;i++){
                    if(!_game.dead[i]){
                        _game.winner = i;
                        break;
                    }
                }
                uint box = _game.bag * 4;
                BAG[ _game.player[i] ] += box-box/boxCutter;
                BAG[dev] += box/boxCutter;
            }
        }
    }

    function removeCards(Game storage _game, Piece storage _piece, uint shovel) internal{
        uint nextDeck = _game.deck+1;
        uint deckSize = _game.deckSize[nextDeck];
        uint cardCount;
        uint card;
        uint L = _piece.cards;

        uint[] memory cardsToTake = new uint[](L);
        uint[] memory cardsToKeep = new uint[](L);
        uint kept;
        uint took;
        uint i;
        uint cardType;
        if(shovel == 5){
            for(i=0; i<L; i++){
                card = _piece.card[i];
                if(card>0){
                    cardType = (card-1)%13;
                    if( cardType==11 || (cardType==10 && _piece.kind==5) || cardType==8 ){
                        cardsToKeep[kept++] = card;
                    }else{
                        cardsToTake[took++] = card;    
                    }
                }
            }
        }else{
            for(i=0; i<L; i++){
                cardsToTake[i] = _piece.card[i];
            }
        }
        L -= kept;

        if(shovel<4){//for zombies under mind control
            //take cards into your own hand
            for(i=0; i<L; i++){
                card = cardsToTake[i];
                addCardToHand(_game, shovel, card);
            }
        }else{
            for(i = 0;i<L;i++){
                card = cardsToTake[i];
                _game.deckCards[nextDeck][deckSize+cardCount] = card;
                cardCount++;
                _piece.card[i] = 0;
            }
            if(shovel==5){
                for(i=0;i<kept;i++){
                    _piece.card[i] = cardsToKeep[i];
                }
                _piece.cards = kept;
            }
            _game.deckSize[nextDeck] += cardCount;
        }
        
    }

    function attack(Game storage _game, Piece storage mover, Piece storage landing, uint landingID) internal{
        require(
            //to prevent unfair insta-kills from free summons & mind controlled pieces
            //but allows the harvesting of pieces with already dead kings
            (mover.startRound < _game.rounds || _game.dead[landing.owner] )
            && notBlocked(_game,mover.blockedBy,mover.blockedUntil)
        );
        
        uint aggressor = mover.owner;
        removeCards(_game,landing,(mover.enchantment[0] && !_game.dead[aggressor])?aggressor:4 );

        uint heirID = _game.heir[landing.owner];
        bool nullHeir;
        if(landing.kind==5){
            if(heirID==0){
                kill(_game,landing.owner, mover);
            }else{//Extra Life
                piece[heirID].kind = 5;
                nullHeir = true;
            }
        }else{
            if(heirID == landingID){
                nullHeir = true;    
            }
        }
        if(nullHeir){
            _game.heir[landing.owner] = 0;
        }
    }

    function newPiece(Game storage _game, uint position, uint owner, uint kind, uint[] memory cards) internal {
        pieces += 1;
        Piece storage _piece = piece[pieces];
        _piece.owner = owner;
        _piece.kind = kind;
        _piece.cards = cards.length;
        _piece.startRound = _game.rounds;
        uint card;
        uint cardKind;
        uint i;
        for(i=0;i<cards.length;i++){
            card = cards[i];
            cardKind = (card-1)%13;
            if(cardKind==11){
                _game.heir[_piece.owner] = pieces;
            }else if(cardKind==6 || cardKind==1){
                _piece.enchantment[((cardKind/2)+1)/2] = true;
            }
            if(cardKind==6 && kind==2){
                _piece.trample += 1;
            }
            
            _piece.card[i] = card;
        }
        _game.board[position] = pieces;
    }

    function inRing(uint x1, uint y1, uint x2, uint y2) internal pure returns(bool){
        uint dX = DXY(x1,x2);
        uint dY = DXY(y1,y2);
        return  ( (dX+dY == 2 && x1 != x2 && y1 != y2) || (dX+dY == 1) );
    }

    function killStagnantPlayers(Game storage _game, uint order) internal{
        uint j;
        uint i;
        Piece storage nullPiece = piece[0];
        for(i=_game.endedTurn; i<order; i++){
            for(j=0;j<4;j++){
                if(_game.turnOrder[j] == i){
                    kill( _game, j, nullPiece);
                }
            }
        }
    }

    function summon(Game storage _game, uint player, uint kingLoc, uint[] memory spawn) internal returns(uint[] memory usedHandSlots, uint free){
        uint[] memory card_ = new uint[](6);
        uint[] memory card_suit = new uint[](6);
        uint j = spawn[0];
        uint coh;
        bool _6;

        //this is less operations than doing the loop by 5 everytime. gotta save gas
        uint K = (j==0)?1:((j==4||j==1)?2:( (j==3||j==2||j==6)?3:( (j==5||(j>7 && j<12) )?4:(j==13?6:5) ) ));
        usedHandSlots = new uint[](6);//6 (max cards)
        for(j=0;j<K;j++){
            //add cards to the list of used cards, but give them a +1 so that we can detect a 0 for end of use
            usedHandSlots[j] = (coh = spawn[2+j])+52;
            coh = _game.hand[player][ coh ] - 1;

            card_[j] = coh % 13;
            if(card_[j] == 5){_6 = true;}
            if(card_[j]== 6){free = 1;}

            card_suit[j] = coh = coh / 13;
            require(  notBlocked( _game, _game.blockSuitBy[coh] , _game.blockSuitUntil[coh] ) );
        }
        
        j = spawn[0];
        require(
            //PAWN
            j==0 // single
            
            //BISHOP
            ||(j==1 && foaks(card_,2,false) && card_[0]>0 && card_[0]<10 ) // Number Pair
            ||(j==2 && foaks(card_suit,3,false) ) // 3 Flush

            //KNIGHT
            ||(j==3 && foaks(card_,3,true) ) // 3 Straight
            ||(j==4 && foaks(card_,2,false) && (card_[0]>9 || card_[0]==0) ) // Face Pair
            ||(j==9 && foaks(card_,2,false) && card_[2] == card_[3] ) // 2 Pair
            ||(j==13 && foaks(card_,2,false) && card_[2] == card_[3]  && card_[4] == card_[5] ) // 3 Pair

            //ROOK
            ||(j==5 && foaks(card_,4,true) ) // 4 Straight
            ||(j==6 && foaks(card_,3,false) ) // 3 of a Kind
            ||(j==10 && foaks(card_suit,4,false) ) // 4 Flush
            
            //QUEEN
            ||(j==7 && foaks(card_suit,5,false) ) // 5 Flush
            ||(j==8 && foaks(card_,4,true) && foaks(card_suit,4,false) ) // 4 Straight Flush
            ||(j==11 && foaks(card_,4,false) ) // 4 of a Kind
            ||(j==12 && foaks(card_,5,true) ) // 5 Straight
            
        );

        card_ = new uint[](K);

        for(coh=0;coh<K;coh++){
            card_[coh] = _game.hand[player][ spawn[2+coh] ];
        }
        
        K = spawn[1]; // repurpose K for spawn location
        
        Piece storage kingMaybe = piece[ _game.board[kingLoc] ];
        kingLoc = ( inRing(K%8, K/8, kingLoc%8, kingLoc/8) && kingMaybe.owner == player && kingMaybe.kind == 5 )?1:0;
        require(
            _game.board[K] == 0
            && K<64
            && ( kingLoc==1 || _6 )
        );
        
        newPiece(_game, K, player, (j==0)?0: ( (j==2||j==1)?1:(j==12?4:( j==13?2:(j>8?(j-7):(j+1)/2) ) ) ), card_);
        if(kingLoc==0)
            piece[pieces].startRound += 1;
    }

    function foaks(uint[] memory cards, uint L, bool straight)internal pure returns(bool){
        // Flush, of a Kind, Straight
        uint i;
        for(i=0;i<L-1;i++){
            if(
                cards[i]+(straight?1:0) == cards[i+1]
                || ( straight && (i==L-2 && cards[i]==12 && cards[i+1] == 0) )
            ){
                //good
            }else{
                return false;
            }
        }
        return true;
    }

    /*
    ░██████╗██████╗░███████╗██╗░░░░░██╗░░░░░░██████╗
    ██╔════╝██╔══██╗██╔════╝██║░░░░░██║░░░░░██╔════╝
    ╚█████╗░██████╔╝█████╗░░██║░░░░░██║░░░░░╚█████╗░
    ░╚═══██╗██╔═══╝░██╔══╝░░██║░░░░░██║░░░░░░╚═══██╗
    ██████╔╝██║░░░░░███████╗███████╗███████╗██████╔╝
    ╚═════╝░╚═╝░░░░░╚══════╝╚══════╝╚══════╝╚═════╝░
    */
    function spells(Game storage _game, uint player, uint[] memory cast) internal returns(uint ush, uint[] memory usedHandSlots){
        usedHandSlots = new uint[](52);
        uint i;
        uint spell;
        uint card;
        uint X;
        uint suit;
        
        Piece storage _piece;
        
        while(i<cast.length){
            X = cast[i];
            card = _game.hand[player][X];
            require(card!=0);
            spell = (--card)%13;
            suit = card/13;
            //require(_game.blockSuit[] < _game.rounds);
            require(  notBlocked( _game, _game.blockSuitBy[suit] , _game.blockSuitUntil[suit] ) );
            
            //cards not meant for discard given distinguishing value            
            usedHandSlots[ush++] = X + ( spell==1 || spell==4 || spell == 5 || spell == 6 || spell == 8 || spell==10 ? 52:0 );
            
            if(spell == 0){// Ace - +2 Next Draw
                _game.aceFor[_game.acesPlayed] = player;
                _game.acesPlayed++;
            }else if(spell == 2){// 3 - Choke, Burn or Scorch
                X = cast[++i];//method
                if(X<2){
                    THESE_HANDS(_game, X==1, X = cast[++i], suit, false);
                    require(X!=player);
                }else{//Scorch Disenchant
                    usedHandSlots[ush-1]+=52;//make sure this use of the spell isn't discarded into the next
                    X = _game.board[cast[++i]];//X repurposed as pieceID
                    _piece = piece[X];
                    //if we require the X is !0, we don't need to check location < 64
                    require( X!=0 && !hasShield(_piece) );
                    clearEnchantments(_piece);
                    removeCards(_game, _piece, 5);
                    _piece.card[_piece.cards++] = card+1;
                }
            }else if(spell == 5){// 6 - Flight
                X = cast[++i];//piece location
                suit = cast[++i];//suit as escape location
                spell = _game.board[X];//card as pieceID
                _piece = piece[spell];
                require( (_piece.owner == player || (_piece.mindControl[player] && _game.dead[_piece.owner] )) && _piece.kind!=5 && spell>0 && _game.board[suit]==0);
                boardMove(_game, X, suit, 0, spell);

                _piece.startRound = _game.rounds+1;
                _piece.card[_piece.cards++] = card+1;
            }else if(spell == 7){// 8 - Shifting Spells
                CAST_SHIFT(_game, suit%2==0, cast[++i], suit>1, player);
            }else if(spell == 1 || spell%2 == 0){
                X = cast[++i];//X as location
                suit = _game.board[X];//suit repurposed as pieceID
                require(suit!=0);//if we require the suit is !0, we don't need to check location < 64
                _piece = piece[suit];
                if(spell < 7){// Enchantments
                    X = ((spell/2)+1)/2;// X repurposed for enchantment Type
                    if(X==2 && _piece.kind==2){
                        _piece.trample += 1;
                    }else if(_piece.enchantment[ X ]){
                        revert();
                    }
                    _piece.enchantment[ X ] = true;
                }else{
                    if(spell==8){// 9 - Mind Control || Steal Card
                        X = cast[++i];//version of 9
                        if(X==0){//Mind Control
                            require( ( !hasShield(_piece) && _piece.kind!=5 ) || _game.dead[_piece.owner]  );
                            _piece.mindControl[player] = true;
                        }else{//Steal Card
                            X = cast[++i];//player ID
                            suit = cast[++i];//suit repurposed as handslot of targeted player
                            require(_piece.kind == 5 && _piece.owner == player && !_game.dead[X] && player!=X);
                            THESE_HANDS(_game,true,X,0,true);//check to make sure targeted player doesn't have a shield;
                            addCardToHand(_game, player, _game.hand[X][suit]);
                            _game.hand[X][suit] = 0;
                        }
                    }else{// KING Recall & JACK Smite
                        require(_piece.kind!=5);// Can't smite, recall or mindcontrol a King
                        if(!KING_JACK(_game, _piece, player, spell == 10)){
                            _game.board[X] = 0;
                        }

                        if(_game.heir[_piece.owner] == suit){
                            _game.heir[_piece.owner] = 0;
                        }
                        if(spell == 10){
                            //jack is stored on king when used because it's too powerful.
                            _piece = piece[_game.board[cast[++i]]];
                            require(_piece.kind == 5 && _piece.owner == player);
                        }
                    }
                }
                if(spell<11){
                    _piece.card[_piece.cards++] = card+1;
                }
            }else if(spell == 3){// 4 - Mute Suit or Disable Piece
                X = cast[++i];
                if(X==0){
                    _game.blockSuitBy[suit]= player;
                    _game.blockSuitUntil[suit] = _game.rounds+1;
                }else{
                    X = cast[++i];// get location
                    X = _game.board[X];// X repurposed for ID from board
                    _piece = piece[X];
                    require(X!=0 && !hasShield(_piece)); //if we require the suit is !0, we don't need to check X<64
                    _piece.blockedBy= player;
                    _piece.blockedUntil= _game.rounds+1;
                }
            }else if(spell == 9){// 10 - Change turn order
                if(cast[++i]==0){
                    _game.priorityPoints[player] += 1;
                }else{
                    for(X=0;X<4;X++){
                        if(X!=player && !_game.dead[X]){
                            _game.priorityPoints[X] += 1;
                        }
                    }
                }
            }

            i++;
        }
    }

    function THESE_HANDS(Game storage _game, bool version, uint targetPlayer, uint suit, bool justCheckingForShield) internal{
        uint j;
        uint ND = _game.deck+1;
        uint dS = _game.deckSize[ND];
        require( !_game.dead[targetPlayer] );
        if(!version){// Choke
            require( targetPlayer<4 );
            _game.suffocate[targetPlayer] = true;    
        }
        uint spell;
        uint L = _game.hand[targetPlayer].length;
        uint card;
        for(card=0;card<L;card++){
            spell = _game.hand[targetPlayer][card];
            if(spell!=0){
                require( (spell-1)%13 !=3 );
                if( version && !justCheckingForShield && (spell-1)/13 == suit){
                    _game.hand[targetPlayer][card]=0;
                    _game.deckCards[ND][dS+j] = spell;
                    j+=1;
                }
            }
        }
        if(version && !justCheckingForShield) _game.deckSize[ND] += j;
    }

    function hasShield(Piece storage _piece) internal view returns(bool){
        bool shield;
        uint L = _piece.cards;
        uint card;
        uint i;
        for(i=0; i<L; i++){
            card = _piece.card[i];
            if(card>0){
                if((card-1)%13==3){
                    shield = true;
                    break;
                }
            }
        }
        return shield;
    }

    function notBlocked(Game storage _game, uint by, uint until) internal view returns(bool){
        return (_game.rounds == until && _game.endedTurn >= _game.turnOrder[by]) || _game.rounds > until;
    }
    
    function KING_JACK(Game storage _game, Piece storage _piece,uint player, bool F) internal returns(bool cloneable){
        if(F){//Jack - SMITE
            require( !hasShield(_piece) );
            removeCards(_game, _piece, 4);
        }else{//KING - recall
            uint L = _piece.cards;
            require(_piece.owner == player);
            uint card;
            uint i;
            for(i=0;i<L;i++){
                card =  _piece.card[i];
                if( (card-1)%13 == 12 ){
                    cloneable = true;
                }
                _piece.card[i]=0;
                addCardToHand(_game, player, card);
            }
            _piece.cards=0;
            clearEnchantments(_piece);
        }
    }

    function clearEnchantments(Piece storage _piece) internal{
        _piece.enchantment[0] = false;
        _piece.enchantment[1] = false;
        _piece.enchantment[2] = false;
        _piece.trample = 0;
    }

    function CAST_SHIFT(Game storage _game, bool row_column, uint position, bool direction, uint player)internal{
        require( position<8 );
        uint i;
        uint ID;
        uint moveNext;
        uint oldSpot;
        Piece storage _piece;
        for(i=0;i<8;i++){
            oldSpot = row_column?
                ((direction?7-i:i)*8+position):
                ((direction?7-i:i)+(position*8));

            ID = _game.board[ oldSpot ];
            if(moveNext>0){
                _piece = piece[ID];
                if(!hasShield(_piece) || _piece.owner == player){
                    _game.board[ moveNext ] = ID;
                    _game.board[ oldSpot ] = 0;
                    ID = 0;
                }else{
                    moveNext = 0;
                }
            }
            if(ID==0){moveNext=oldSpot;}
        }

    }

    /*    
    ██╗░░░██╗██╗███████╗░██╗░░░░░░░██╗
    ██║░░░██║██║██╔════╝░██║░░██╗░░██║
    ╚██╗░██╔╝██║█████╗░░░╚██╗████╗██╔╝
    ░╚████╔╝░██║██╔══╝░░░░████╔═████║░
    ░░╚██╔╝░░██║███████╗░░╚██╔╝░╚██╔╝░
    ░░░╚═╝░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░
    */
    function getBasicData(address addr)view external returns(uint gameCount, uint minbox, uint _rolls, uint bag){
        gameCount = players[addr].games;
        minbox = minimumBox;
        _rolls = rolls;
        bag = BAG[addr];
    }

    function viewGames(address addr, uint offset, uint limit) view external returns(uint[] memory UINTs, bool[] memory BOOLs, address [] memory participants){
        Player storage player = players[addr];
        Game storage _game;
        UINTs = new uint[](limit*5);
        BOOLs = new bool[](limit*5);
        participants = new address[](limit*4);
        uint j;
        uint gameID;
        uint i;
        for(i=offset;i<offset+limit;i++){
            gameID = player.game[i];
            _game = game[gameID];
            UINTs[i*5+0] = gameID;
            UINTs[i*5+1] = _game.bag;
            UINTs[i*5+2] = _game.turnTime;
            UINTs[i*5+3] = _game.rounds;
            UINTs[i*5+4] = _game.winner;
            
            for(j=0;j<4;j++){
                BOOLs[i*5+j] = _game.acceptedGame[_game.player[j]];
            }
            
            BOOLs[i*5+4] = _game.ended;

            for(j=0;j<4;j++){
                participants[i*4+j] = _game.player[j];
            }
        }
    }
    
    function viewGame(uint gameID) view external returns(
        uint[] memory board,
        uint[] memory otherData, //turnTime, endedTurn, endedTurnTime, turnOrder[4], priorityPoints[4]
        bool[] memory BOOLs, //dead[4], doneWithFirstDeck
        address[] memory playerAddresses,
        uint[] memory piece_UINTs,
        bool[] memory piece_BOOLs,
        uint[] memory hands,
        uint[] memory aces
    ){
        Game storage _game = game[gameID];
        uint i;
        board = new uint[](64);
        uint[] memory pieceIDs = new uint[](64);
        uint j;
        uint pieceCount;
        for(i=0;i<64;i++){
            j = _game.board[i];
            board[i] = j;
            if(j!=0){
                pieceIDs[pieceCount] = j;
                pieceCount+=1;
            }
        }

        piece_UINTs = new uint[](pieceCount*24);
        piece_BOOLs = new bool[](pieceCount*7);
        Piece storage _piece;

        for(i=0;i<pieceCount;i++){
            _piece = piece[pieceIDs[i]];
            piece_UINTs[i*24] = pieceIDs[i];
            piece_UINTs[i*24+1] = _piece.owner;
            piece_UINTs[i*24+2] = _piece.kind;
            piece_UINTs[i*24+3] = _piece.startRound;
            piece_UINTs[i*24+4] = _piece.blockedBy;
            piece_UINTs[i*24+5] = _piece.blockedUntil;
            piece_UINTs[i*24+6] = _piece.cards;
            piece_UINTs[i*24+23] = _piece.trample;
            
            for(j=0;j<16;j++){
                piece_UINTs[i*24+7+j] = _piece.card[j];    
            }
            for(j=0;j<3;j++){
                piece_BOOLs[i*7+j] = _piece.enchantment[j];
            }
            for(j=0;j<4;j++){
                piece_BOOLs[i*7+j+3] = _piece.mindControl[j];
            }
        }

        otherData = new uint[](32);
        otherData[8] = _game.turnTime;
        otherData[9] = _game.endedTurn;
        otherData[10] = _game.endedTurnTime;
        otherData[31] = _game.winner;
        
        BOOLs = new bool[](10);
        playerAddresses = new address[](4);
        BOOLs[8] = _game.doneWith1stDeck;
        BOOLs[9] = _game.ended;
        hands = new uint[](52*4);

        for(i=0;i<4;i++){
            otherData[i] = _game.turnOrder[i];
            otherData[i+4] = _game.priorityPoints[i];
            otherData[i+19] = _game.blockSuitBy[i];
            otherData[i+23] = _game.heir[i];
            otherData[i+27] = _game.blockSuitUntil[i];
            playerAddresses[i] = _game.player[i];
            BOOLs[i] = _game.dead[i];
            BOOLs[i+4] = _game.suffocate[i];
            pieceCount = _game.hand[i].length;
            for(j=0;j<pieceCount;j++){
                hands[j+52*i] = _game.hand[i][j];
            }
        }

        otherData[11] = _game.bag;
        otherData[12] = _game.cardsDrawn;
        otherData[13] = _game.deckSize[_game.deck];
        otherData[14] = _game.deckSize[_game.deck+1];
        otherData[15] = _game.roundLastRoll;
        otherData[16] = _game.kills;
        otherData[17] = _game.rounds;
        otherData[18] = _game.killedBySomeoneThisRound;

        aces = new uint[](_game.acesPlayed-_game.acesSpent);
        for(i=0; i<aces.length; i++){
            aces[i] = _game.aceFor[i+_game.acesSpent];
        }
    }

    /*        
    ░█████╗░██████╗░███╗░░░███╗██╗███╗░░██╗
    ██╔══██╗██╔══██╗████╗░████║██║████╗░██║
    ███████║██║░░██║██╔████╔██║██║██╔██╗██║
    ██╔══██║██║░░██║██║╚██╔╝██║██║██║╚████║
    ██║░░██║██████╔╝██║░╚═╝░██║██║██║░╚███║
    ╚═╝░░╚═╝╚═════╝░╚═╝░░░░░╚═╝╚═╝╚═╝░░╚══╝
    */
    uint rolls;
    mapping(uint=>uint) seeds;
    uint lastRoll;

    function randomness(uint seed) external{
        require(msg.sender == dealer);
        rolls+=1;
        seeds[rolls] = seed;
        lastRoll = block.timestamp;
        emit GAME(0,false);
    }
    
    function boxControls(uint bag, bool f)external{
        require(msg.sender == dev);
        if(f){
            require(bag>boxCutter); boxCutter = bag;
        }else{
            minimumBox = bag;
        }
    }

    function setControlWallet(address addr, bool f)external{
        require(msg.sender == dev);
        if(f){
            dev = addr;
        }else{
            dealer = addr;
        }
    }
}
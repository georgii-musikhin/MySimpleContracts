pragma solidity ^0.5.4;

/*The point is that a person creates a contract to make a bet. He becomes the owner of that contract. 

He is the only person who is able to add events to the contract using createEvent method where the name of a certain event is entered. The method also comes with unique ID to make an interaction with an event more convenient. 

After creating an event, you can make a bet. Ether winning or losing (50/50). To make calculations easier only 1 Ether can be bet. 

After this, the contract’s owner only is able to use setResult method to calculate the result. 

However there is a checking, whether bets on any result are made or not. 

If the check is successful, no more bets can be made. 

To calculate the result pseudo-function 50/50 is used by chance. The result is set in the game. 

Then the players can check the result of the event (game). And, if their guesses are right, they can withdraw the winnings to their  accounts. */


contract MyBets {
    
    address public owner;
    
    struct Game {
        string                     name;
        uint8                      ID;
        bool                       available;
        mapping (address => uint8) betsForWin;
        address[]                  forWin;
        mapping (address => uint8) betsForLose;
        address[]                  forLose;
        uint8                      result;
        uint                       balanceOfEvent;
    }

    uint8 private gameIDx;

    
    mapping(uint => Game) private _games;
    
    
    modifier isOwner() {
     require(msg.sender == owner);
     _;
 }
    
    constructor() public{
        owner = msg.sender;
    }
    
    function createEvent(string memory _name) public isOwner {
        Game memory game;
        game.name       = _name;
        game.ID= gameIDx++;
        game.available  = true;
        _games[game.ID] = game;
    }
    
    function setBet(uint _ID, uint8 _vote) public payable {
        require(msg.value == 1 ether);
        require(_games[_ID].available);
        if (_vote == 1){
             _games[_ID].betsForWin[msg.sender] = 1;
             _games[_ID].forWin.push(msg.sender);
        } else if (_vote == 2){
             _games[_ID].betsForLose[msg.sender] = 2;
             _games[_ID].forLose.push(msg.sender);
        }
        _games[_ID].balanceOfEvent += msg.value;
        
    }
    
    function setResult(uint _ID) public isOwner {
        require(_games[_ID].forWin.length > 0 || _games[_ID].forLose.length > 0);
        _games[_ID].available  = false;
        uint8 _result = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 2 + 1);
        _games[_ID].result = _result;
    }
    
    function getReward(uint _ID) public {
        require(!_games[_ID].available);
        if (_games[_ID].betsForWin[msg.sender] == _games[_ID].result){
            msg.sender.transfer(_games[_ID].balanceOfEvent / _games[_ID].forWin.length);
            delete _games[_ID].betsForWin[msg.sender];
        } else if (_games[_ID].betsForLose[msg.sender] == _games[_ID].result){
            msg.sender.transfer(_games[_ID].balanceOfEvent / _games[_ID].forLose.length);
            delete _games[_ID].betsForLose[msg.sender];
        }
    }
    
    function getResult(uint _ID) public view returns (uint){
        return _games[_ID].result;
    }
    
    function getGameBalance(uint _ID) public view returns (uint){
        return _games[_ID].balanceOfEvent;
    }
}
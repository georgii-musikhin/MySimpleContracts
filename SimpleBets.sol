pragma solidity ^0.5.4;

/*Суть такова: Человек создаёт контракт для ставок. Он назначается владельцем контракта.

Он и только он может добавлять «события в контракт с помощью метода createEvent где надо ввести название события. 
В этом методе также добавляется уникальное  ID для удобного взаимодействия с событием. 

После создания события на него можно делать ставки.  Либо победа, либо поражение 50/50. Для простоты расчётов ставить можно только 1 эфир. 

Далее только владелец контракта может вызвать метод setResult для расчёта результата.
Однако идёт проверка, есть ли ставки на хоть какой-нибудь результат. 
Если проверка прошла, больше ставки делать нельзя. 
Для вычисления результата используется ПВСЕВДО случайная функция 50 на 50. Результат задаётся игре.

Потом игроки могут проверить результат события(игры) и если они угадали, могу вывести то, что они выиграли. */


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
pragma solidity ^0.5.4;


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}


contract MMM_Simple{
    using SafeMath for uint;
    
    uint public MIN_DEPOSIT = 0.01 ether; //Минимальный депозит
    uint public DIV_PER     = 3;          //Процент дивидендов
    uint public ADM_FEE     = 8;          //Процент администрации
    uint public REF_FEE     = 10;         //Процент реффу
    uint public PERIOD      = 1 minutes;  //Двиденды начисляются каждую минуты(для простоты теста. а так в день)
    
    struct  User {                         //Структура вкладчика
        uint deposits;
        uint timeOfDeposit;
        address payable reffer;
    }
    
    mapping (address => User) users;       //Маппинг вкладчиков
    
    address payable public administrator;  //Адрес администрации
    uint timeOfLife;                       //Сколько времени пирамида работает в днях
    
    event InvestorAdded(address indexed investor);
    event NewDeposit(address indexed investor, uint256 amount);
    event ReferrerAdded(address indexed investor, address indexed referrer);
    event RefBonusPayed(address indexed investor, address indexed referrer, uint256 bonus);
    event DividendsPayed(address indexed investor, uint256 amount);
    
    constructor() public{
        administrator = msg.sender;
        timeOfLife = now;
    }
    
    function () external payable{
        if (msg.value == 0){
            withdraw(msg.sender);
        } else makeDeposit();
    }
    
    //Функция, которая принимает деньги. Минимальный депозит 0.01 эфир.
    //8% идёт администрации, 10% реферреру, если есть.
    //Она создаёт нового участника пирамиды с свойствами: баланс его депозита, время депозита. 
    //Так же функция добовляет нового участника в приамиду.
    function makeDeposit() public payable {
        require(msg.value >= MIN_DEPOSIT);
        
        administrator.transfer(msg.value.mul(ADM_FEE).div(100));
        
        if (getDividends(msg.sender)> 0){
            withdraw(msg.sender);
        }
        
        users[msg.sender].deposits = msg.value;
        users[msg.sender].timeOfDeposit = now;
        emit InvestorAdded(msg.sender);
        
        if (users[msg.sender].reffer != address(0)){
            users[msg.sender].reffer.transfer(msg.value.mul(REF_FEE).div(100));
            emit RefBonusPayed(msg.sender, users[msg.sender].reffer, msg.value.mul(REF_FEE).div(100));
        } else if (msg.data.length == 20){
            addReffer();
        }
        
        emit NewDeposit(msg.sender, msg.value);
    }
    
    //Функция перевода из байтов в адрес
    function bytesToAddress(bytes memory _val) internal pure returns (address payable _addr){
        assembly {
            _addr := mload(add(_val,0x14))
        }
        return _addr;
    }
    
    //Функция добавления реффера
    function addReffer() internal {
        address payable refAddr = bytesToAddress(bytes(msg.data));
        if (msg.sender != refAddr){
            users[msg.sender].reffer = refAddr;
            refAddr.transfer(msg.value.mul(REF_FEE).div(100));
            emit ReferrerAdded(msg.sender, refAddr);
            emit RefBonusPayed(msg.sender, refAddr, msg.value * REF_FEE / 100);
            
        }
    }
    
    //Функция рассчёта дивидендов вкладчику и публичный геттер
    
    function getDividends (address _addr) public view returns (uint){
        return (users[_addr].deposits.mul(DIV_PER).div(100)).mul(now.sub(users[_addr].timeOfDeposit)).div(PERIOD);
    }
    
    
    //Функия снятия денег. Для снятия нужно отправить 0 эфира. Снимаются деньги и обнуляется счётчик по времени депозита.
    function withdraw(address payable _addr) private {
        uint dividens = getDividends(_addr);
        if (dividens > 0){
            _addr.transfer(dividens);
        }
        users[_addr].timeOfDeposit = now;
        emit DividendsPayed(msg.sender, dividens);
    }
    
    //Баланс депозита
    function balanceOfDeposit() public view returns(uint){
        return users[msg.sender].deposits;
    }
    
    
    //Баланс контракта
    function balanceOfContract() public view returns(uint){
        return address(this).balance;
    }
    
    //Время жизни пирамиды
    function timeOfContract() public view returns(uint){
        uint _time = now.sub(timeOfLife);
        return _time.div(PERIOD);
    }
    
    function timeOfDeposit() public view returns(uint){
        uint _time = now.sub(users[msg.sender].timeOfDeposit);
        return _time.div(PERIOD);
    }
    
}
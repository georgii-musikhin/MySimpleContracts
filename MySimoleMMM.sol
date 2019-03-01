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
    
    uint public MIN_DEPOSIT = 0.01 ether; //Minimum deposit
    uint public DIV_PER     = 3;          //Dividend percent
    uint public ADM_FEE     = 8;          //Administrator percent
    uint public REF_FEE     = 10;         //Refferal percent
    uint public PERIOD      = 1 minutes;  //Dividends count every minute(
                                          //to simplify tests)
    
    struct  User {                         //Participant structure
        uint deposits;
        uint timeOfDeposit;
        address payable reffer;
    }
    
    mapping (address => User) users;       //Mapping of participants
    
    address payable public administrator;  //Administrator address
    uint timeOfLife;                       //How many time contract live
    
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
    
    //Function for deposit and withdraw.

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
    
    //Function to convert bytes to address
    function bytesToAddress(bytes memory _val) internal pure returns (address payable _addr){
        assembly {
            _addr := mload(add(_val,0x14))
        }
        return _addr;
    }
    
    //Function for refferal system
    function addReffer() internal {
        address payable refAddr = bytesToAddress(bytes(msg.data));
        if (msg.sender != refAddr){
            users[msg.sender].reffer = refAddr;
            refAddr.transfer(msg.value.mul(REF_FEE).div(100));
            emit ReferrerAdded(msg.sender, refAddr);
            emit RefBonusPayed(msg.sender, refAddr, msg.value * REF_FEE / 100);
            
        }
    }
    
    //Count of dividends
    
    function getDividends (address _addr) public view returns (uint){
        return (users[_addr].deposits.mul(DIV_PER).div(100)).mul(now.sub(users[_addr].timeOfDeposit)).div(PERIOD);
    }
    
    
    //Withdraw function. You should sent 0 ehter
    function withdraw(address payable _addr) private {
        uint dividens = getDividends(_addr);
        if (dividens > 0){
            _addr.transfer(dividens);
        }
        users[_addr].timeOfDeposit = now;
        emit DividendsPayed(msg.sender, dividens);
    }
    
    
    function balanceOfDeposit() public view returns(uint){
        return users[msg.sender].deposits;
    }
    
    
    function balanceOfContract() public view returns(uint){
        return address(this).balance;
    }
    
    function timeOfContract() public view returns(uint){
        uint _time = now.sub(timeOfLife);
        return _time.div(PERIOD);
    }
    
    function timeOfDeposit() public view returns(uint){
        uint _time = now.sub(users[msg.sender].timeOfDeposit);
        return _time.div(PERIOD);
    }
    
}
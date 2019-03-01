pragma solidity ^0.5.4;

contract MultiSigWallet {
 address private _owner;
 mapping(address => uint8) private _owners;
 
 uint MIN_SIGNATURES;
 uint private _transactionIdx;
 
 struct Transaction {
     address from;
     address payable to;
     uint amount;
     uint8 signatureCount;
     mapping (address => uint8) signatures;
 }
 
 mapping (uint => Transaction) private _transactions;
 uint[] private _pendingTransactions;
 
 modifier isOwner() {
     require(msg.sender == _owner);
     _;
 }
 
 modifier validOwner() {
     require(msg.sender == _owner || _owners[msg.sender] == 1);
     _;
 }
 
 event DepositFunds(address from, uint amount);
 event TransactionCreated(address from, address to, uint amount, uint transctionId);
 event TransactionCompleted(address from, address to, uint amount, uint transctionId);
 event TransctionSigned(address by, uint transactionId);
 
 constructor() public{
     _owner = msg.sender;
 }
 
 function addOwner(address newOwner)
    isOwner
    public {
        _owners[newOwner] = 1;
 }
 function removeOwner (address existingOwner)
    isOwner 
    public {
        _owners[existingOwner] = 0;
 }
 function setMIN_SIGNATURES(uint _num) 
    isOwner
    public{
        require(_num > 1);
        MIN_SIGNATURES = _num;
    }
 
 function ()
    external
    payable{
    emit DepositFunds(msg.sender, msg.value);
 }
 
 function withdraw(uint _amount)
    public{
    transferTo(msg.sender, _amount);
 }
 
 function transferTo(address payable _to, uint _amount)
    validOwner
    public{
        require(address(this).balance >= _amount);
        
        uint transactionId = _transactionIdx++;
        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to = _to;
        transaction.amount = _amount;
        transaction.signatureCount = 0;
        
        _transactions[transactionId] = transaction;
        _pendingTransactions.push(transactionId);
        
        emit TransactionCreated(msg.sender, _to, _amount, transactionId);
 }
 
 function getpendingTransactions()
    validOwner
    public
    view
    returns(uint[] memory) {
        return _pendingTransactions;
    }
    
 function signTransaction(uint transactionId)
    validOwner
    public{
        Transaction storage transaction = _transactions[transactionId];
        //Is there this transaction?
        require(address(0x0) != transaction.from);
        //Сreator of transaction can't sign it
        require(msg.sender != transaction.from);
        //You can sign only once
        require(transaction.signatures[msg.sender] != 1);
        
        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount ++;
        
        emit TransctionSigned(msg.sender, transactionId);
        
        if (transaction.signatureCount > MIN_SIGNATURES){
            require(address(this).balance >= transaction.amount);
            transaction.to.transfer(transaction.amount);
            emit TransactionCompleted(transaction.from, transaction.to, transaction.amount, transactionId);
            deleteTransaction(transactionId);
        } 
    }
    
    function deleteTransaction (uint transactionId)
        validOwner
        public{
            uint8 replace = 0;
            for(uint i = 0; i < _pendingTransactions.length; i++) {
                if (1 == replace){
                    _pendingTransactions[i -1] = _pendingTransactions[i];
                } else if (transactionId == _pendingTransactions[i]){
                    replace = 1;
                }
            }
            delete _pendingTransactions[_pendingTransactions.length -1];
            _pendingTransactions.length--;
            delete _transactions[transactionId];
        }
    function walletBalabce()
        public
        view
        returns(uint){
            return address(this).balance;
        }
}
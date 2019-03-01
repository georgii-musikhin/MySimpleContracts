pragma solidity ^0.5.4;

/* This is an example of simple Heads and Tails gambling game. Chance to win is 50%*/
 
import "../Utils/SafeMath.sol";
import "../Utils/Ownable.sol";
 

contract HeadsAndTails is Ownable {
    
    using SafeMath for uint;
    
    uint public adminFee = 2;
    uint constant ONE_HUNDRED = 100;
    
    modifier notAContract {
        require(msg.sender == tx.origin);
        _;
    }
    
    function () external payable onlyOwner {
        
    }
    
    function play(uint guess) public notAContract payable {
        require(msg.value >= 0.1 ether && msg.value <= 2 ether);
        address(owner).transfer(msg.value.mul(adminFee).div(ONE_HUNDRED));
        
        uint reward = msg.value.mul(2);
        require(reward < address(this).balance);
        
        uint salt = uint (msg.sender);
        uint BlockHash = uint(blockhash(block.number));
        uint answer = uint(keccak256(abi.encodePacked(BlockHash, salt, now))) % 2;
        if (guess == answer) {
            msg.sender.transfer(reward);
        } 
    }
    
    function setAdminFee(uint _val) public onlyOwner {
        require (_val <= 2, 'Admin Fee must be less or equal then 2%');
        adminFee = _val;
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
}
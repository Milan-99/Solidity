// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

interface IERC20{
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function _totalSupply() external view returns (uint);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Bitcoin is IERC20{
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint public decimal;
    uint public totalSupply;
    
    
    mapping(address=>uint) public balance;
    mapping(address=>mapping(address=>uint)) public allowed;
    
    constructor(string memory _name,string memory _symbol,uint _decimal,uint _total ,address owner,uint _availabletoken){
      
        name=_name;
        symbol=_symbol;
        decimal=_decimal;
        totalSupply=_total;
        balance[owner]=_total.sub(_availabletoken);
        balance[msg.sender]=_availabletoken;
        
    }
    
    function _totalSupply() external view override virtual returns (uint){
        return totalSupply;
        
    }
    function balanceOf(address tokenOwner) external view override returns (uint ){
        return balance[tokenOwner];
        
    }
    function transfer(address to, uint _amount) external override returns (bool ){
        require(balance[msg.sender]>=_amount);
        balance[msg.sender]=balance[msg.sender].sub(_amount);
        balance[to]=balance[to].add(_amount);
        emit Transfer(msg.sender,to,_amount);
        return true;
        
        
        
    }
    function transferFrom(address from, address to, uint tokens) external override returns (bool){
        require(balance[from]>=tokens);
        require(allowed[from][msg.sender]>=tokens);
        balance[from]=balance[from].sub(tokens);
        allowed[from][msg.sender]=allowed[from][msg.sender].sub(tokens);
        balance[to]=balance[to].add(tokens);
        emit Transfer(from,to,tokens);
        return true;
        
        
        
    }
    function approve(address spender, uint tokens) external override returns (bool ){
        require(msg.sender!=spender);
        allowed[msg.sender][spender]=tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
        
    }
    function allowance(address tokenOwner, address spender) external view override returns (uint){
        return allowed[tokenOwner][spender];
        
    }
}

contract ICO {
    using SafeMath for uint;
    
    address public token;
    address public owner;
    
    uint pricePerToken;
    uint startDate;
    uint endDate;
    uint availableToken;
    uint MinPurchase;
    uint MaxPurchase;
    
    
    
    constructor (string memory _name,string memory _symbol,uint decimal,uint total,uint _availabletoken){
        require(_availabletoken>0 && total>=_availabletoken);
        token=address(new Bitcoin(_name,_symbol,decimal,total,msg.sender,_availabletoken));
        owner=msg.sender;
        availableToken=_availabletoken;
    }
    
    function start(uint _end,uint price,uint min,uint max) external onlyOwner{
       
        require(min>0 && max<=50);
        
      
        //endDate input must be in days 
        endDate=block.timestamp+(_end* 1 days);
        
        MinPurchase=min;
        MaxPurchase=max;
        //pricePerToken input must be in ether
        pricePerToken=price * 1 ether;
        
        
        
    }
    function Buy(uint _amount) external payable saleEnd{
        require(_amount>=MinPurchase && _amount<=MaxPurchase);
        require(msg.value>=(_amount*pricePerToken));
        require(availableToken>=_amount,"Insufficent token");
        availableToken=availableToken.sub(_amount);
        Bitcoin(token).transfer(msg.sender,_amount);
        
    }
    //Function to receive plan ether & send the token equivalent to msg.value
    receive() external payable{
        require(block.timestamp<=endDate);
        require(msg.value>=(MinPurchase*pricePerToken) && msg.value<=(MaxPurchase*pricePerToken));
        uint sendvalue=msg.value/pricePerToken;
        require(availableToken>=sendvalue,"Insufficent token");
        availableToken=availableToken.sub(sendvalue);
        Bitcoin(token).transfer(msg.sender,sendvalue);
        
        
    }
    function withdrawEth(address payable _to,uint _amount) external onlyOwner{
        require(block.timestamp>endDate);
        _to.transfer(_amount);
        
    }
    function WithdrawToken(address _to) external onlyOwner{
        require(block.timestamp>endDate);
        Bitcoin(token).transfer(_to,address(this).balance);
    }
    
    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
    modifier saleEnd(){
        require(block.timestamp<=endDate,"Token Sale Ended");
        _;
    }
    
}


































// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./1Month.sol";
import "./3Month.sol";
import "./6Month.sol";

contract MotherPool{

    address immutable admin;
    IERC20 public immutable ssn;
    IERC20 public immutable hsn;

    //Tokens
    address[] tokenAddresses;
    address[] successAddress;

    mapping(IERC20 => uint256) tokenBalances;
    mapping(uint256 => uint256) successfulPresale;
    mapping(IERC20 => uint256) tokenTimestamp;
    mapping(uint256 => mapping(uint256 => address)) IndexAddress;
    mapping(uint256 => mapping(IERC20 => uint256)) successfulBalances;

    uint successCount;
    uint public lastTime;  
    uint public index;
    uint public newtime;
    
    //external
    uint256 public feesWithdrawal;
    uint256 public claim_time;
    uint256 public Mimimumhsn1;
    uint256 public Mimimumhsn3;
    uint256 public Mimimumhsn6;
    uint256 public Mimimumssn1;
    uint256 public Mimimumssn3;
    uint256 public Mimimumssn6;
 

    event tokensRecieved(address indexed Token, uint amount);
    event DistributedTokens(address indexed pool, uint amount);
    event withdrawn(address reciever, IERC20 indexed tokena, uint amounta, IERC20 indexed tokenb, uint amountb);
    event stringMessage(string message);

    constructor() {
        admin = payable(msg.sender);
        ssn = IERC20(0x905F3c260070788AEF121a2A9B54EDa4aAe3f94d);
        hsn = IERC20(0x67C43a3743749F57A62a0747AcdfbE131a211516);
        lastTime = block.timestamp;
    }

    //setter functions

    function setFees(uint WithdrawalFee) external {
        feesWithdrawal = WithdrawalFee;
    }

    function setClaimTime(uint claimTime) external{
        claim_time = claimTime;
    }

    function setHsn(
        uint256 _Mimimumhsn1,
        uint256 _Mimimumhsn3,
        uint256 _Mimimumhsn6
    
    ) external {
        
        require(msg.sender == admin, "NA");//Not Admin

        Mimimumhsn1 = _Mimimumhsn1;
        Mimimumhsn3 = _Mimimumhsn3;
        Mimimumhsn6 = _Mimimumhsn6;
     
    }

    function setSSn(
        
        uint256 _Mimimumssn1,
        uint256 _Mimimumssn3,
        uint256 _Mimimumssn6
      
        ) external {
            require(msg.sender == admin, "NA");//Not Admin
          
            Mimimumssn1 = _Mimimumssn1;
            Mimimumssn3 = _Mimimumssn3;
            Mimimumssn6 = _Mimimumssn6;
           

        }

    //called from presale contract

    function receiveTokenFee(address _token, uint256 amount) external{
        IERC20 token = IERC20(_token);

        index++;

        tokenAddresses.push(_token);

        tokenBalances[token] += amount;

        successfulPresale[index] = block.timestamp;

        IndexAddress[index][block.timestamp] = _token;

        emit tokensRecieved(_token, amount);

    }
    function setNewTime() public{

        newtime = lastTime + claim_time;
        
        for(uint i = 1; i <= index; i++){

            if(successfulPresale[i] >= lastTime){
                if(successfulPresale[i] <= newtime){

                successAddress.push(IndexAddress[i][successfulPresale[i]]);
            
                }
            }
            
        }

        successCount = successAddress.length;
    }

    function distribute(address _month1, address _month2, address _month3) external {
        require(msg.sender == admin, "NA");

        setNewTime();


            if(successCount >= 2 && successCount <= 10){
            lessThanTen(_month2, _month3);    
                        
            }

            if(successCount > 10){
                greaterThanTen( _month1, _month2, _month3);
            }


         for(uint i =1; i <= tokenAddresses.length; i++){
            if(successfulPresale[i -1] >= lastTime && successfulPresale[i -1] <= newtime){
    

            }
        }
        for(uint i = 1; i <= successCount; i++){

                IERC20 token = IERC20(successAddress[i -1]);

                delete successfulPresale[i -1];
                delete tokenBalances[token];      
                        
                
            }
            
        

        delete successCount;
        delete index;

        lastTime = block.timestamp;
        delete successAddress;
      
    
}
    function greaterThanTen(address _month1, address _month2, address _month3) public{
             uint tokenPercent;
             uint tokenPercent2;
             uint tokenPercent3;

             for(uint i = 1; i<= successCount; i++){
                 
           IERC20 token = IERC20(successAddress[i -1]);

                tokenPercent = 1000 * token.balanceOf(address(this))/10000;
                tokenPercent2 = 6000 * token.balanceOf(address(this))/10000;
                tokenPercent3 = 3000 * token.balanceOf(address(this))/10000;

               month1(_month1).recieveTokens(successAddress[i -1],tokenPercent);
               month3(_month2).recieveTokens(successAddress[i -1],tokenPercent3);
               month6(_month3).recieveTokens(successAddress[i -1],tokenPercent2);

                token.transfer(_month1, tokenPercent);
                token.transfer(_month2, tokenPercent3);
                token.transfer(_month3, tokenPercent2);
                
                 emit DistributedTokens(_month3, tokenPercent2);
                emit DistributedTokens(_month2, tokenPercent3);
                emit DistributedTokens(_month1, tokenPercent);
             }


    }

    function lessThanTen(address _month2, address _month3) public{
            
        uint tokenPercent; 
   
            for(uint i = 1; i<= successCount; i++){

           IERC20 token = IERC20(successAddress[i -1]);             
                tokenPercent = 5000 * token.balanceOf(address(this))/10000;
          
                token.transfer(_month2, tokenPercent);
                token.transfer(_month3, tokenPercent);   

                 month3(_month2).recieveTokens(successAddress[i -1],tokenPercent);
                 month6(_month3).recieveTokens(successAddress[i -1],tokenPercent);    

                emit DistributedTokens(_month2, tokenPercent);
                emit DistributedTokens(_month3, tokenPercent);  
            }
    }

    

    function AdminWithdrawal() external {
        require(msg.sender == admin, "NA");
        uint ssnBalance = ssn.balanceOf(address(this));
        uint hsnBalance = hsn.balanceOf(address(this));

        ssn.transfer(admin, ssnBalance);
        hsn.transfer(admin, hsnBalance);

        emit withdrawn(admin, ssn, ssnBalance, hsn, hsnBalance);
    }

 
}
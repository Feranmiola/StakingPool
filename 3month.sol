// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Pool.sol";

contract month3{

    IERC20 public immutable ssn;
    IERC20 public immutable hsn;
    
    mapping(address => uint) public contractTokenBalances;
    mapping(address => uint) public feesTaken;
    address[] tokenAddresses;
    address[] recievableTokens;

    address public immutable MainPool;

    mapping(address => mapping(address => uint256)) public balances;
    mapping(address => mapping(address => uint256)) public Fullbalances;
    mapping(address => uint256) NormalBalance;
    mapping(address => address) addressToToken;
    mapping(address => uint256) public Duration;
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public claimedWeek;
    mapping(address => mapping(address => uint256)) public userTokenBalances;
    mapping(address => bool) public finalised;
    mapping(address => uint256) updatedTime;
    mapping(address => mapping(uint => address)) public claimedTokens;
    mapping(address => uint) public claimedNumber;
    


    uint public claim_time;
    uint public WithdrawalFee;

    uint public claimNumber;
    uint256 public Mimimumhsn3;
    uint256 public Mimimumssn3;
    bool public called;


    event Staked(address indexed staker, uint256 stakingAmount, uint256 stakingTime, uint256 Period);
    event Unstaked(address indexed unstaker, uint256 amount, uint256 unstakeTime);
    event unstakedAll(address indexed unstaker, uint256 amount);
    event claimedRewards(address indexed claimer);
    event FinalizedStaking(address indexed reciever, uint256 feeAmount);


    constructor(MotherPool motherPool){
        ssn = motherPool.ssn();
        hsn = motherPool.hsn();

        claim_time = motherPool.claim_time();

        WithdrawalFee = motherPool.feesWithdrawal();

        MainPool = address(motherPool);

    }

    function updatePoolInfo(MotherPool motherPool) public{
        
        claim_time = motherPool.claim_time();

        WithdrawalFee = motherPool.feesWithdrawal();
        Mimimumhsn3 = motherPool.Mimimumhsn3();
        Mimimumssn3 = motherPool.Mimimumssn3();

    }

    function recieveTokens(address _token, uint amount) external{
     
        contractTokenBalances[_token] = amount;

        tokenAddresses.push(_token);
        recievableTokens.push(_token);

        called = true;
    }

    function stake(address _token, uint amount) external{
        updatePoolInfo(MotherPool(MainPool));
        
        finalised[msg.sender] == false;
        IERC20 token = IERC20(_token);
        
        if(_token == address(ssn)){
            require(amount >= Mimimumssn3, "NE"); //Not enough
        }
        else 
        if(_token == address(hsn)){
            require(amount >=  Mimimumhsn3, "NE");
        }
        else{
            revert("UA"); //Unrecognized address
        }

        token.transferFrom(msg.sender, address(this), amount);

        Fullbalances[_token][msg.sender] = amount;

        uint Fees = 1000 * amount/10000;
        amount = amount - Fees;


        claimNumber = 7889229 / claim_time;


        feesTaken[_token] = Fees;
        balances[_token][msg.sender] = amount;
        NormalBalance[msg.sender] =amount;
        addressToToken[msg.sender] = _token;
        Duration[msg.sender] = block.timestamp + 7889229;
        startTime[msg.sender] = block.timestamp;
        updatedTime[msg.sender] = block.timestamp;

        emit Staked(msg.sender, amount, Fees, 7889229);

    }

    function unstake(uint _amount) external{
        require(NormalBalance[msg.sender] > 0, "EB");
        require(Duration[msg.sender] > block.timestamp, "AE");//Already Ended
        require(_amount <= NormalBalance[msg.sender], "IE");

        IERC20 token = IERC20(addressToToken[msg.sender]);

         uint finalAmount =  NormalBalance[msg.sender] - _amount;

        if(token == ssn){
            require(finalAmount >= Mimimumssn3);
        }else if(token == hsn){
            require(finalAmount >= Mimimumhsn3);
        }
         

        require(NormalBalance[msg.sender] >= _amount, "IS"); //Insufficient Balance

        uint amount = _amount - (WithdrawalFee * balances[addressToToken[msg.sender]][msg.sender] / 10000);

        balances[addressToToken[msg.sender]][msg.sender] = balances[addressToToken[msg.sender]][msg.sender] - amount;

        token.transfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount, block.timestamp);
    }

    function unstakeAll() external {
        require(NormalBalance[msg.sender] > 0, "EB");
        IERC20 token = IERC20(addressToToken[msg.sender]);

        
        uint amount = NormalBalance[msg.sender] - (WithdrawalFee * NormalBalance[msg.sender] / 10000);

        delete claimedWeek[msg.sender];
        delete NormalBalance[msg.sender];
        delete balances[addressToToken[msg.sender]][msg.sender];
        delete Fullbalances[addressToToken[msg.sender]][msg.sender];


        token.transfer(msg.sender, amount);

        emit unstakedAll(msg.sender, amount);
        
    }

    function claimRewards() external{
        require(updatedTime[msg.sender] + claim_time <= block.timestamp, "CNS");//Claiming not started 
        require(Duration[msg.sender] > block.timestamp, "AE");
        require(NormalBalance[msg.sender] > 0, "EB");//EmptyBalance
        require(claimedWeek[msg.sender] < claimNumber, "CC");//Claiming completed 

         IERC20 token = IERC20(addressToToken[msg.sender]);

        uint256 claimingPercent = Fullbalances[addressToToken[msg.sender]][msg.sender]  * 10000/token.balanceOf(address(this));

        claimedWeek[msg.sender] ++;

        for(uint i = 1; i<= recievableTokens.length; i++){

            uint claimmable = claimingPercent * contractTokenBalances[recievableTokens[i-1]]/ 10000;
            claimedNumber[msg.sender] ++;

            claimedTokens[msg.sender][claimedNumber[msg.sender]] = recievableTokens[i-1];

            userTokenBalances[msg.sender][recievableTokens[i-1]] = claimmable;

        }

        updatedTime[msg.sender] = block.timestamp;

        emit claimedRewards(msg.sender);
    }

    function finaliseStaking() external{
        require(!finalised[msg.sender], "AF"); //Already finalised
        require(claimedWeek[msg.sender] <= claimNumber, "SNO");//Staking not over
        require(Duration[msg.sender] <= block.timestamp, "NE");//Not ended
        
        IERC20 token = IERC20(addressToToken[msg.sender]);
        
        for(uint i = 1  ; i<= claimedNumber[msg.sender]; i++){

             IERC20 __token = IERC20(claimedTokens[msg.sender][i]);

            uint recievable = userTokenBalances[msg.sender][claimedTokens[msg.sender][i]];
            
            delete userTokenBalances[msg.sender][claimedTokens[msg.sender][i]];
            
            __token.transfer(msg.sender, recievable);

            contractTokenBalances[claimedTokens[msg.sender][i]] = contractTokenBalances[claimedTokens[msg.sender][i]] - recievable;

            updateArray(claimedTokens[msg.sender][i]);

        }
        
        
        uint256 claimingPercent = Fullbalances[addressToToken[msg.sender]][msg.sender] * 10000/token.balanceOf(address(this));
        uint claimmable = claimingPercent * feesTaken[addressToToken[msg.sender]] / 10000;

        token.transfer(msg.sender, claimmable);
        
        token.transfer(MainPool, NormalBalance[msg.sender]);
        
        delete claimedWeek[msg.sender];
        delete NormalBalance[msg.sender];
        delete balances[addressToToken[msg.sender]][msg.sender];

        emit FinalizedStaking(msg.sender, claimmable);
     
    }
    
    function getBalance(address _token) external view returns(uint){
        IERC20 token = IERC20(_token);

        return token.balanceOf(address(this));

        }

    function updateArray(address _token) public {
        
        if(contractTokenBalances[_token] == 0){
            for(uint i = 1; i<= recievableTokens.length; i++){
                    if(recievableTokens[i-1] == _token){
                        recievableTokens[i-1] = recievableTokens[recievableTokens.length -1];

                        recievableTokens.pop();
                    }
            
                }

        }
    
    }

    function getPercent() external view returns(uint){
            IERC20 token = IERC20(addressToToken[msg.sender]);

        uint256 claimingPercent = Fullbalances[addressToToken[msg.sender]][msg.sender]  * 10000/token.balanceOf(address(this));
        return claimingPercent;
    }

}

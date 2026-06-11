// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {TokenX} from "./TokenX.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract DCA is AutomationCompatibleInterface{
    using SafeERC20 for TokenX;

    error DCA__AmountCantBeZero();
    error DCA__PeriodMustBeMoreThanMinute();
    error DCA__PositionAlreadyActive();
    error DCA__NotEnoughMoney();
    error DCA__YouCannotWithdrawYet();
    error DCA__NotEnoughMoneyForWithdrawal();
    error DCA__PositionNotActive();
    error DCA__TransferFailed();



    event PositionSet(address indexed user, uint256 amount, uint256 period);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Canceled(address indexed user);
    event PositionUpdated(address indexed user, uint256 newAmount, uint256 newPeriod);

    struct Position {
        uint256 amount;
        uint256 period;
        uint256 lastExecuted;
        bool active;
    }


    mapping(address => Position) positions;
    mapping(address => uint256) private balances;
    mapping(address => bool) private isUser;
    address[] public users;

    TokenX public token;

    constructor(){
        token = new TokenX();
    }


    function setPosition(uint256 amount, uint256 period) external {
        if(amount == 0) revert DCA__AmountCantBeZero();
        if(period < 60) revert DCA__PeriodMustBeMoreThanMinute();
        if(positions[msg.sender].active) revert DCA__PositionAlreadyActive();
        Position memory position = Position({
            amount: amount,
            period: period,
            lastExecuted: block.timestamp,
            active: true
        });

        positions[msg.sender] = position;
        if(!isUser[msg.sender]){
            users.push(msg.sender);
            isUser[msg.sender] = true;
        }
        

        emit PositionSet(msg.sender, amount, period);
    }




    function deposit() public payable {
        if(msg.value == 0) revert DCA__AmountCantBeZero();

        balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }


    function checkUpkeep(bytes calldata  /* checkData */) external view returns (bool upkeepNeeded, bytes memory  /* performData */){
        for(uint256 i = 0; i < users.length; i++){
            address user = users[i];
            if(positions[user].active && block.timestamp - positions[user].lastExecuted >= positions[user].period) {
                return (true, abi.encode(user));
            }
        }
        return (false, "");
    }


    function performUpkeep(bytes calldata perfromData ) external {
        address user = abi.decode(perfromData, (address));
        _withdraw(user);
    }


    function withdraw() external {
        _withdraw(msg.sender);

        

        
    }

    function _withdraw(address user) internal{
        uint256 ethRequired = (positions[user].amount * 1 ether) / 1000;
        if(!positions[user].active) revert DCA__PositionNotActive();
        if(block.timestamp - positions[user].lastExecuted < positions[user].period) revert DCA__YouCannotWithdrawYet();
        if(balances[user] < ethRequired) revert DCA__NotEnoughMoneyForWithdrawal();
        

        balances[user] -= ethRequired;

        uint256 amountToSend = positions[user].amount;

        positions[user].lastExecuted = block.timestamp;

        if(token.balanceOf(address(this)) < amountToSend){
            revert DCA__NotEnoughMoney();
        }else{
            token.safeTransfer(user, amountToSend);
        }
        


        if(balances[user] == 0){
            positions[user].active = false;
        }

        emit Withdrawal(user, amountToSend);

    }

    function updatePositionAmount(uint256 newAmount) external {
        if(!positions[msg.sender].active) revert DCA__PositionNotActive();
        if(newAmount == 0) revert DCA__AmountCantBeZero();
        uint256 positonCurrentPeriod = positions[msg.sender].period;
        Position memory position = Position({
            amount: newAmount,
            period: positonCurrentPeriod,
            lastExecuted: block.timestamp,
            active: true
        });


        positions[msg.sender] = position;

        emit PositionUpdated(msg.sender, newAmount, positonCurrentPeriod);
    }


    function cancel() external {
        if(!positions[msg.sender].active) revert DCA__PositionNotActive();

        positions[msg.sender].active = false;

        emit Canceled(msg.sender);
    }


    receive() external payable{
        deposit();
    }


    function tokenBalanceOf(address user) external view returns(uint256){
        return token.balanceOf(user);

    }


    function balanceOf(address user) external view returns(uint256) {
        return balances[user];
    }


    function getUserPositionAmount(address user) external view returns(uint256){
        return positions[user].amount;
    }


    function getUserPositionPeriod(address user) external view returns(uint256){
        return positions[user].period;
    }


    function getUserPostions(address user) external view returns(Position memory) {
        return positions[user];
    }


}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {TokenX} from "./TokenX.sol";


contract DCA {

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

    struct Position {
        uint256 amount;
        uint256 period;
        uint256 lastExecuted;
        bool active;
    }


    mapping(address => Position) positions;
    mapping(address => uint256) private balances;

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

        emit PositionSet(msg.sender, amount, period);
    }




    function deposit() public payable {
        if(msg.value == 0) revert DCA__AmountCantBeZero();

        balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }


    function withdraw() external {
        uint256 userTokenBalance = balances[msg.sender] * 1000; // 1ETH = 1000 TKX
        if(!positions[msg.sender].active) revert DCA__PositionNotActive();
        if(block.timestamp - positions[msg.sender].lastExecuted < positions[msg.sender].period) revert DCA__YouCannotWithdrawYet();
        if(userTokenBalance < positions[msg.sender].amount) revert DCA__NotEnoughMoneyForWithdrawal();
        

        userTokenBalance -= positions[msg.sender].amount;
        balances[msg.sender] -= positions[msg.sender].amount/1000;

        uint256 amountToSend = positions[msg.sender].amount;

        positions[msg.sender].lastExecuted = block.timestamp;

        if(token.balanceOf(address(this)) < amountToSend){
            revert DCA__NotEnoughMoney();
        }else{
            token.transfer(msg.sender, amountToSend);
        }
        


        if(balances[msg.sender] == 0){
            positions[msg.sender].active = false;
        }

        emit Withdrawal(msg.sender, amountToSend);

        
    }


    function cancel() external {
        if(!positions[msg.sender].active) revert DCA__PositionNotActive();
        uint256 userBalance = balances[msg.sender];

        balances[msg.sender] = 0;
        positions[msg.sender].active = false;

        (bool success,) = payable(msg.sender).call{value: userBalance}("");
        if(!success) revert DCA__TransferFailed();

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
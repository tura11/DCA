// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {TokenX} from "./TokenX.sol";


contract DCA {

    error DCA__AmountCantBeZero();
    error DCA__PeriodMustBeMoreThanMinute();
    error DCA__PositionAlreadyActive();

    event PositionSet(address indexed user, uint256 amount, uint256 period);

    struct Position {
        uint256 amount;
        uint256 period;
        uint256 lastExecuted;
        bool active;
    }


    mapping(address => Position) positions;


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




}
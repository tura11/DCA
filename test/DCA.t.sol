// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DCA} from "../src/DCA.sol";
import {Test} from "forge-std/Test.sol";

contract DCATest is Test {
    DCA public dca;
    address user;
    address user2;

    function setUp() public {
        dca = new DCA();
        user = makeAddr("user");
        user2 = makeAddr("user2");
        vm.deal(user, 10 ether);
        vm.deal(user2, 10 ether);
    }

    function testConstructor() public view {
        assertEq(dca.tokenBalanceOf(address(dca)), 1000000e18);
    }

    function testDeposit() external {
        vm.prank(user);
        dca.deposit{value: 5 ether}();
        assertEq(dca.balanceOf(user), 5 ether);
    }

    function testDepositRevert() external {
        vm.prank(user);
        vm.expectRevert(DCA.DCA__AmountCantBeZero.selector);
        dca.deposit{value: 0}();
    }

    function testReceiveFunctionDirectDeposit() external {
        vm.prank(user);
        (bool success,) = address(dca).call{value: 2 ether}("");
        assertTrue(success);
        assertEq(dca.balanceOf(user), 2 ether);
    }

    function testSetPosition() external {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);
        assertEq(dca.getUserPositionAmount(user), 1000);
        assertEq(dca.getUserPositionPeriod(user), 3 days);
        vm.stopPrank();
    }

    function testSetPositionDoesNotDuplicateUser() external {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);
        vm.stopPrank();

        vm.startPrank(user);
        dca.cancel();
        dca.setPosition(2000, 4 days);
        vm.stopPrank();

        assertEq(dca.users(0), user);
    }

    function testSetPositionRevertAmountZero() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        vm.expectRevert(DCA.DCA__AmountCantBeZero.selector);
        dca.setPosition(0, 3 days);
        vm.stopPrank();
    }

    function testSetPostionRevertPeriodMustBeMoreThanMinute() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        vm.expectRevert(DCA.DCA__PeriodMustBeMoreThanMinute.selector);
        dca.setPosition(1000, 10);
        vm.stopPrank();
    }

    function testSetPositionRevertPositionAlreadyActive() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);
        vm.expectRevert(DCA.DCA__PositionAlreadyActive.selector);
        dca.setPosition(1000, 7 days);
        vm.stopPrank();
    }

    function testSuccesfulWithdrawal() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);
        vm.warp(block.timestamp + 4 days);
        dca.withdraw();
        vm.stopPrank();

        assertEq(dca.tokenBalanceOf(user), 1000);
    }

    function testWithdrawRevertPositonNotActive() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        vm.expectRevert(DCA.DCA__PositionNotActive.selector);
        dca.withdraw();
        vm.stopPrank();
    }

    function testWithdrawRevertYouCannotWithdrawYet() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert(DCA.DCA__YouCannotWithdrawYet.selector);
        dca.withdraw();
        vm.stopPrank();
    }

    function testWithdrawRevertNotEnoughMoney() public {
        vm.startPrank(user);
        dca.deposit{value: 1 ether}();
        dca.setPosition(2000, 3 days);
        vm.warp(block.timestamp + 4 days);
        vm.expectRevert(DCA.DCA__NotEnoughMoneyForWithdrawal.selector);
        dca.withdraw();
        vm.stopPrank();
    }

    function testWithdrawDeactivatesPositionWhenBalanceGoesToZero() public {
        vm.startPrank(user);

        dca.deposit{value: 1 ether}();
        dca.setPosition(1000, 3 days);
        vm.warp(block.timestamp + 4 days);

        dca.withdraw();

        assertEq(dca.balanceOf(user), 0);

        DCA.Position memory position = dca.getUserPostions(user);
        assertFalse(position.active);

        vm.stopPrank();
    }

    function testUpdatePositionAmountSuccessful() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);

        dca.updatePositionAmount(2500);

        assertEq(dca.getUserPositionAmount(user), 2500);
        assertEq(dca.getUserPositionPeriod(user), 3 days);
        vm.stopPrank();
    }

    function testUpdatePositionAmountRevertPositionNotActive() public {
        vm.startPrank(user);

        vm.expectRevert(DCA.DCA__PositionNotActive.selector);
        dca.updatePositionAmount(1500);
        vm.stopPrank();
    }

    function testUpdatePositionAmountRevertAmountCantBeZero() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);

        vm.expectRevert(DCA.DCA__AmountCantBeZero.selector);
        dca.updatePositionAmount(0);
        vm.stopPrank();
    }

    // -------------------------------------------------------------------------------

    function testCancelSuccesful() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);
        vm.warp(block.timestamp + 4 days);
        dca.withdraw();
        assertEq(dca.tokenBalanceOf(user), 1000);
        dca.cancel();
        assertEq(dca.balanceOf(user), 4 ether);
        vm.stopPrank();
    }

    function testCancelRevertPositionNotActive() public {
        vm.startPrank(user);
        vm.expectRevert(DCA.DCA__PositionNotActive.selector);
        dca.cancel();
        vm.stopPrank();
    }

    function testCheckUpkeepReturnsFalseWhenNoPositions() public {
        (bool upkeepNeeded, bytes memory performData) = dca.checkUpkeep("");
        assertFalse(upkeepNeeded);
        assertEq(performData.length, 0);
    }

    function testCheckUpKeepRetrunsFalseWhenPeriodisNotPassed() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        (bool upkeepNeeded,) = dca.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function testCheckUpKeepSuccesful() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);
        vm.stopPrank();

        vm.warp(block.timestamp + 4 days);

        (bool upkeepNeeded, bytes memory performData) = dca.checkUpkeep("");
        assertTrue(upkeepNeeded);
        address decodedUser = abi.decode(performData, (address));
        assertEq(decodedUser, user);
    }

    function testPerformUpkeepWithdrawsTokens() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);
        vm.stopPrank();

        vm.warp(block.timestamp + 4 days);

        (, bytes memory performData) = dca.checkUpkeep("");
        dca.performUpkeep(performData);

        assertEq(dca.tokenBalanceOf(user), 1000);
    }
}

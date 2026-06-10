// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;



import {DCA} from "../src/DCA.sol";
import {Test} from "forge-std/Test.sol";



contract DCATest is Test{
    DCA public dca;
    address user;

    function setUp() public {
        dca = new DCA();
        user = makeAddr("user");
        vm.deal(user, 10 ether);
    }


    function testConstructor() public view {
        assertEq(dca.tokenBalanceOf(address(dca)), 1000000e18);
    }


    function testDeposit() external {
        vm.prank(user);
        dca.deposit{value: 5 ether}();
        assertEq(dca.balanceOf(user), 5 ether);
    }

    function testDepositRevert() external{
        vm.prank(user);
        vm.expectRevert(DCA.DCA__AmountCantBeZero.selector);
        dca.deposit{value: 0}();
        
    }


    function testSetPosition() external {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);
        assertEq(dca.getUserPositionAmount(user), 1000);
        assertEq(dca.getUserPositionPeriod(user), 3 days);
    }

    function testSetPositionRevertAmountZero() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        vm.expectRevert(DCA.DCA__AmountCantBeZero.selector);
        dca.setPosition(0, 3 days);
    }

    function testSetPostionRevertPeriodMustBeMoreThanMinute() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        vm.expectRevert(DCA.DCA__PeriodMustBeMoreThanMinute.selector);
        dca.setPosition(1000, 10);
    }


    function testSetPositionRevertPositionAlreadyActive() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);
        vm.expectRevert(DCA.DCA__PositionAlreadyActive.selector);
        dca.setPosition(1000, 7 days);
    }


    function testSuccesfulWithdrawal() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);
        vm.warp(4 days);
        dca.withdraw();
        vm.stopPrank();

        assertEq(dca.tokenBalanceOf(user), 1000);


    }


    function testCancelSuccesful() public {
        vm.startPrank(user);
        dca.deposit{value: 5 ether}();
        dca.setPosition(1000, 3 days);
        vm.warp(4 days);
        dca.withdraw();
        assertEq(dca.tokenBalanceOf(user), 1000);
        dca.cancel();
        assertEq(dca.balanceOf(user), 4 ether);
        
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
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


    function testConstructor() public {
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

}
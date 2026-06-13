// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {DCA} from "../src/DCA.sol";

contract DeployDCA is Script {
    function run() external returns (DCA) {
        vm.startBroadcast();
        DCA dca = new DCA();
        vm.stopBroadcast();
        return dca;
    }

    function test() public {}
}

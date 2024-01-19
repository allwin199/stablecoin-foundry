// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";

contract DeployDSCEngine is Script {
    function run() external {
        vm.startBroadcast();
        DecentralizedStableCoin dsCoin = new DecentralizedStableCoin();
        DSCEngine dscEngine = new DSCEngine();
        vm.stopBroadcast();
    }
}

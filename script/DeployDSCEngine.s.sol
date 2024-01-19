// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";

contract DeployDSCEngine is Script {
    address[] tokenAddresses;
    address[] priceFeedAddresses;

    function run() external returns (DSCEngine, DecentralizedStableCoin, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (address weth, address wbtc, address wethUsdPriceFeed, address wbtcUsdPriceFeed, address deployerKey) =
            helperConfig.activeNetworkConfig();

        tokenAddresses.push(weth);
        tokenAddresses.push(wbtc);

        priceFeedAddresses.push(wethUsdPriceFeed);
        priceFeedAddresses.push(wbtcUsdPriceFeed);

        vm.startBroadcast(deployerKey);
        DecentralizedStableCoin dsCoin = new DecentralizedStableCoin();
        DSCEngine dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsCoin));
        vm.stopBroadcast();

        return (dscEngine, dsCoin, helperConfig);
    }
}

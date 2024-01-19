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

        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast(deployerKey);
        DecentralizedStableCoin dsCoin = new DecentralizedStableCoin();
        DSCEngine dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsCoin));

        // dscCoin has a ownable function and we want DSCEngine to be the owner of DSCoin
        dsCoin.transferOwnership(address(dscEngine));

        vm.stopBroadcast();

        return (dscEngine, dsCoin, helperConfig);
    }
}

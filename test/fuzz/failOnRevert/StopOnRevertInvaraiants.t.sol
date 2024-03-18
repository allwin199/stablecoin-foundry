// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Have our invariant aka properties always hold true

// what are our invariants?
// 1. The total supply of DSC should be less than the total value of collateral
// 2. Getter view functions should never revert <- evergreen invariant

import {Test, console2} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSCEngine} from "../../../script/DeployDSCEngine.s.sol";
import {DSCEngine} from "../../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Handler} from "./StopOnRevertHandler.t.sol";

contract InvariantsTest is StdInvariant, Test {
    DeployDSCEngine private deployer;
    HelperConfig private helperConfig;
    DSCEngine private dscEngine;
    DecentralizedStableCoin private dsCoin;
    Handler private handler;

    address private weth;
    address private wbtc;
    address private wethUsdPriceFeed;
    address private wbtcUsdPriceFeed;
    address private deployerKey;

    function setUp() external {
        deployer = new DeployDSCEngine();
        (dscEngine, dsCoin, helperConfig) = deployer.run();

        handler = new Handler(dscEngine, dsCoin);

        (weth, wbtc, wethUsdPriceFeed, wbtcUsdPriceFeed, deployerKey) = helperConfig.activeNetworkConfig();

        targetContract(address(handler));
        // instead of targetting the dscEngine
        // we are targetting the handler contract
        // since it is stopOnRevert
        // let's keep `fail_on_revert as true`
    }

    function invariant_ProtocolMustHave_MoreValue_ThanDSC_StopOnRevert() public {
        // get the value of all the collateral in the protocol
        // compare it to all the debt (DSC)

        // let's get the totalSupply of DSC
        uint256 totalSupployOfDSC = dsCoin.totalSupply();

        // let's get all the collaterals
        // User will approve the DSC Engine
        // DSC Engine will transfer all the tokens to itself and keep track of the users deposited
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscEngine));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscEngine));

        // Let's get the value of weth and wbtc in USD
        uint256 wethValue = dscEngine.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dscEngine.getUsdValue(wbtc, totalWbtcDeposited);

        console2.log("Total weth Deposited", totalWethDeposited);
        console2.log("Total wbtc Deposited", totalWbtcDeposited);
        console2.log("Total DSC Minted    ", dsCoin.totalSupply());

        assertGe(wethValue + wbtcValue, totalSupployOfDSC, "totalCollateral > DSC");
    }

    function invariant_gettersShouldNotRevert() public view {
        dscEngine.getLiquidationThreshold();
        dscEngine.getAdditionalFeedPrecision();
    }
}

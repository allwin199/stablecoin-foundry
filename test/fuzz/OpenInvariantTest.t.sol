// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Have our invariant aka properties always hold true

// what are our invariants?
// 1. The total supply of DSC should be less than the total value of collateral
// 2. Getter view functions should never revert <- evergreen invariant

import {Test, console2} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSCEngine} from "../../script/DeployDSCEngine.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract OpenInvariantsTest is StdInvariant, Test {
    DeployDSCEngine private deployer;
    HelperConfig private helperConfig;
    DSCEngine private dscEngine;
    DecentralizedStableCoin private dsCoin;

    address private weth;
    address private wbtc;
    address private wethUsdPriceFeed;
    address private wbtcUsdPriceFeed;
    address private deployerKey;

    address private user = makeAddr("user");
    address private liquidator = makeAddr("liquidator");
    uint256 private constant STARTING_ERC20_BALANCE = 100e18;
    uint256 private constant COLLATERAL_AMOUNT = 10e18;
    uint256 private constant MINT_DSC_AMOUNT = 100e18;
    uint256 private constant BURN_DSC_AMOUNT = 100e18;

    function setUp() external {
        deployer = new DeployDSCEngine();
        (dscEngine, dsCoin, helperConfig) = deployer.run();

        (weth, wbtc, wethUsdPriceFeed, wbtcUsdPriceFeed, deployerKey) = helperConfig.activeNetworkConfig();

        targetContract(address(dscEngine));
        // our target contract is dscEngine
        // fuzzer will pick function randomly and test
        // this method is Open-based testing

        // we are minting some ERC20 tokens for the user
        vm.startPrank(msg.sender);
        ERC20Mock(weth).mint(user, STARTING_ERC20_BALANCE);
        // giving liquidator funds
        ERC20Mock(weth).mint(liquidator, STARTING_ERC20_BALANCE);
        vm.stopPrank();
    }

    // function invariant_ProtocolMustHave_MoreValue_ThanDSC_OpenBased() public {
    //     // get the value of all the collateral in the protocol
    //     // compare it to all the debt (DSC)

    //     // let's get the totalSupply of DSC
    //     uint256 totalSupployOfDSC = dsCoin.totalSupply();

    //     // let's get all the collaterals
    //     // User will approve the DSC Engine
    //     // DSC Engine will transfer all the tokens to itself and keep track of the users deposited
    //     uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscEngine));
    //     uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscEngine));

    //     // Let's get the value of weth and wbtc in USD
    //     uint256 wethValue = dscEngine.getUsdValue(weth, totalWethDeposited);
    //     uint256 wbtcValue = dscEngine.getUsdValue(wbtc, totalWbtcDeposited);

    //     console2.log("Total weth Deposited", totalWethDeposited);
    //     console2.log("Total wbtc Deposited", totalWbtcDeposited);
    //     console2.log("Total DSC Minted    ", dsCoin.totalSupply());

    //     assertGe(wethValue + wbtcValue, totalSupployOfDSC, "totalCollateral > DSC");
    // }

    // for open based testing, keep `fail_on_revert` as `false` in foundry.toml
    // open based invariant testing test functions randomly

    // invariant_ProtocolMustHave_MoreValue_ThanDSC_OpenBased() (runs: 128, calls: 16384, reverts: 16384)
    // all our function calls reverted
    // eventhough all our functions reverted. This test case passes
    // the reason is because of `fail_on_revert` as `false`
    // which means if the function revert don't stop and move to the next fuzz run

    // according to our contract, random testing will not work
    // because fuzzer will call `deposit` with some random collateral which is not `weth` or `wbtc`

    // or before calling `deposit` user should `approve`

    // or before calling `mint` there shoudl be a collateral deposited by the user

    // to specify this flow
    // we can create a handler based fuzzing
    // Inside the handler contract
    // we can create a wrapper for deposit
    // In which we can streamline the collateral to deposit and
    // we can `approve` before calling the `deposit`
}

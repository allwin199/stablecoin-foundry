// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Have our invariant aka properties always hold true

// what are our invariants?

// The total supply of DSC should be less than the total value of collateral

// Getter view functions should never revert <- evergreen invariant

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSCEngine} from "../../script/DeployDSCEngine.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract InvariantsTest is StdInvariant, Test {
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

        // we are minting some ERC20 tokens for the user
        vm.startPrank(msg.sender);
        ERC20Mock(weth).mint(user, STARTING_ERC20_BALANCE);
        // giving liquidator funds
        ERC20Mock(weth).mint(liquidator, STARTING_ERC20_BALANCE);
        vm.stopPrank();
    }

    function invariant_ProtocolMustHave_MoreValue_ThanDSC() public {
        // get the value of all the collateral in the protocol
        // compare it to all the debt (DSC)

        uint256 totalSupployOfDSC = dsCoin.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscEngine));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscEngine));

        uint256 wethValue = dscEngine.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dscEngine.getUsdValue(wbtc, totalWbtcDeposited);

        assertGt(wethValue + wbtcValue, totalSupployOfDSC);
    }

    function invariant_gettersShouldNotRevert() public view {
        dscEngine.getLiquidationThreshold();
        dscEngine.getAdditionalFeedPrecision();
    }
}

// for open based testing, keep fail_on_revert as false

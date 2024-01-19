// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSCEngine} from "../../script/DeployDSCEngine.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DSCEngineTest is Test {
    //////////////////////////////////////////////////////////
    ///////////////////////  Errors  /////////////////////////
    //////////////////////////////////////////////////////////
    error DSCEngine__ZeroAmount();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TokenAddressesAnd_PriceFeedAddresses_MustBeSameLenght();
    error DSCEngine__ZeroAddress();
    error DSCEngine__DepositCollateralFailed();
    error DSCEngine__MintingDSCFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);

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
    uint256 private constant USER_STARTING_ERC20_BALANCE = 100e18;
    uint256 private constant COLLATERAL_AMOUNT = 10e18;

    function setUp() external {
        deployer = new DeployDSCEngine();
        (dscEngine, dsCoin, helperConfig) = deployer.run();

        (weth, wbtc, wethUsdPriceFeed, wbtcUsdPriceFeed, deployerKey) = helperConfig.activeNetworkConfig();

        // we are minting some ERC20 tokens for the user
        vm.startPrank(msg.sender);
        ERC20Mock(weth).mint(user, USER_STARTING_ERC20_BALANCE);
        vm.stopPrank();
    }

    function test_Balance() public view {
        uint256 senderBalance = IERC20(weth).balanceOf(user);
        uint256 totalSupply = IERC20(weth).totalSupply();
        console.log("Sender Balance", senderBalance);
        console.log("Total Supply of wEth", totalSupply);
    }

    //////////////////////////////////////////////////////////
    //////////////  Deposit Collateral Tests  ////////////////
    //////////////////////////////////////////////////////////

    function test_RevertsIf_CollateralAmount_IsZero() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine__ZeroAmount.selector);
        dscEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function test_DespositCollateral() public {
        vm.startPrank(user);
        // since dscEngine is calling transferFrom on behalf of user
        // user should dscEngine
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);
        dscEngine.depositCollateral(weth, COLLATERAL_AMOUNT);
        vm.stopPrank();
    }

    function test_DespositCollateral_UpdatesCollateralBalance() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);
        dscEngine.depositCollateral(weth, COLLATERAL_AMOUNT);
        vm.stopPrank();

        uint256 userCollateralBalance = dscEngine.getCollateralBalanceOfUser(user, weth);
        assertEq(userCollateralBalance, COLLATERAL_AMOUNT);
    }

    //////////////////////////////////////////////////////////
    /////////////////  Price Feed Tests  /////////////////////
    //////////////////////////////////////////////////////////

    function test_UsdValue() public {
        uint256 collateralAmount = 10e18;
        uint256 valueInUsd = dscEngine.getUsdValue(weth, collateralAmount);
        // according to our mocks ethUsdPrice = 2000e8
        // ((2000e8 * 1e10) * 10e18) / 1e18 = 20000e18;
        uint256 expectedUsd = 20000e18;
        assertEq(valueInUsd, expectedUsd, "getUsdValue");
    }
}

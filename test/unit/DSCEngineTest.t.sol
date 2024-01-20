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
    error DSCEngine__TokenAddressesAnd_PriceFeedAddresses_MustBeSameLength();
    error DSCEngine__ZeroAddress();
    error DSCEngine__DepositCollateralFailed();
    error DSCEngine__MintingDSCFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__RedeemCollateral_TransferFailed();
    error DSCEngine__TransferFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    //////////////////////////////////////////////////////////
    ///////////////////////  Events  /////////////////////////
    //////////////////////////////////////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount
    );

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
    uint256 private constant MINT_DSC_AMOUNT = 1e18;
    uint256 private constant BURN_DSC_AMOUNT = 1e18;

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
    //////////////////  Constructor Tests  ///////////////////
    //////////////////////////////////////////////////////////
    address[] tokenAddresses;
    address[] priceFeedAddresses;

    function test_RevertsIf_TokenAddressAnd_PriceFeedAddresses_OfDifferentLength() public {
        tokenAddresses.push(weth);
        tokenAddresses.push(wbtc);
        priceFeedAddresses.push(wethUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAnd_PriceFeedAddresses_MustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsCoin));
    }

    function test_RevertsIf_DSCoinAddressIs_ZeroAddress() public {
        tokenAddresses.push(weth);
        tokenAddresses.push(wbtc);
        priceFeedAddresses.push(wethUsdPriceFeed);
        priceFeedAddresses.push(wbtcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__ZeroAddress.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(0));
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

    function test_TokenAmountFromUsd() public {
        uint256 usdValue = 2000e18;

        uint256 actualValue = dscEngine.getTokenAmountFromUsd(weth, usdValue);

        uint256 expectedValueInEth = 1e18;
        assertEq(actualValue, expectedValueInEth, "tokenAmountFromUsd");
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

    function test_RevertsIf_CollateralToken_NotAllowed() public {
        vm.startPrank(user);
        // let's create a new ERC20 token
        // this token will definitely different from the one already created in deployDSCEngine
        ERC20Mock sampleERC20 = new ERC20Mock();
        vm.expectRevert(DSCEngine.DSCEngine__TokenNotAllowed.selector);
        dscEngine.depositCollateral(address(sampleERC20), COLLATERAL_AMOUNT);
        vm.stopPrank();
    }

    function test_DespositCollateral() public {
        vm.startPrank(user);
        // since dscEngine is calling transferFrom on behalf of user
        // user should approve dscEngine
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);
        dscEngine.depositCollateral(weth, COLLATERAL_AMOUNT);
        vm.stopPrank();
    }

    modifier collateralDeposited() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);
        dscEngine.depositCollateral(weth, COLLATERAL_AMOUNT);
        vm.stopPrank();
        _;
    }

    function test_DespositCollateral_UpdatesCollateralBalance() public collateralDeposited {
        uint256 userCollateralBalance = dscEngine.getCollateralBalanceOfUser(user, weth);
        assertEq(userCollateralBalance, COLLATERAL_AMOUNT, "depositCollateral");
    }

    function test_DepositCollateral_EmitsEvent() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);

        // DSCEngine is the one emitting this event
        vm.expectEmit(true, true, true, false, address(dscEngine));
        emit CollateralDeposited(user, weth, COLLATERAL_AMOUNT);
        dscEngine.depositCollateral(weth, COLLATERAL_AMOUNT);

        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////
    ///////////////////  Mint DSC Tests  /////////////////////
    //////////////////////////////////////////////////////////

    function test_UserCan_MintDSC() public collateralDeposited {
        vm.startPrank(user);
        dscEngine.mintDSC(MINT_DSC_AMOUNT);
        vm.stopPrank();
    }

    modifier collateralDeposited_DSCMinted() {
        vm.startPrank(user);

        // depositing collateral
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);
        dscEngine.depositCollateral(weth, COLLATERAL_AMOUNT);

        // minting DSC
        dscEngine.mintDSC(MINT_DSC_AMOUNT);
        vm.stopPrank();

        _;
    }

    function test_UserCan_MintDSC_UpdatesBalance() public collateralDeposited_DSCMinted {
        uint256 dscBalanceOfUser = dscEngine.getDSCBalanceOfUser(user);
        assertEq(dscBalanceOfUser, MINT_DSC_AMOUNT, "depositCollateralAndMintDSC");
    }

    //////////////////////////////////////////////////////////
    /////////  Deposit Collateral And Mint DSC Tests  ////////
    //////////////////////////////////////////////////////////
    function test_UserCan_DepositCollateral_AndMintDSC() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);

        dscEngine.despositCollateralAndMintDSC(weth, COLLATERAL_AMOUNT, MINT_DSC_AMOUNT);
        vm.stopPrank();

        uint256 userCollateralBalance = dscEngine.getCollateralBalanceOfUser(user, weth);
        assertEq(userCollateralBalance, COLLATERAL_AMOUNT, "depositCollateralAndMintDSC");

        uint256 dscBalanceOfUser = dscEngine.getDSCBalanceOfUser(user);
        assertEq(dscBalanceOfUser, MINT_DSC_AMOUNT, "depositCollateralAndMintDSC");
    }

    //////////////////////////////////////////////////////////
    ////////////////  Redeem Collateral Tests  ///////////////
    //////////////////////////////////////////////////////////

    function test_RevertsIf_RedeemCollateral_ZeroAmount() public {
        vm.startPrank(user);
        vm.expectRevert(DSCEngine.DSCEngine__ZeroAmount.selector);
        dscEngine.redeemCollateral(weth, 0);
        vm.stopPrank();
    }

    function test_RevertsIf_RedeemCollateral_WithoutBalance() public {
        vm.startPrank(user);
        vm.expectRevert();
        dscEngine.redeemCollateral(weth, COLLATERAL_AMOUNT);
        vm.stopPrank();
    }

    function test_UserCan_RedeemCollateral() public collateralDeposited {
        uint256 startingUserCollateralBalance = dscEngine.getCollateralBalanceOfUser(user, weth);
        vm.startPrank(user);
        dscEngine.redeemCollateral(weth, COLLATERAL_AMOUNT);
        vm.stopPrank();

        uint256 endingUserCollateralBalance = dscEngine.getCollateralBalanceOfUser(user, weth);
        assertGt(startingUserCollateralBalance, endingUserCollateralBalance);
        assertEq(endingUserCollateralBalance, startingUserCollateralBalance - COLLATERAL_AMOUNT);
    }

    function test_RevertsIf_RedeemCollateral_BreaksHealthFactor() public collateralDeposited_DSCMinted {
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, 0));
        dscEngine.redeemCollateral(weth, COLLATERAL_AMOUNT);
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////
    /////////////////////  Burn DSC Tests  ///////////////////
    //////////////////////////////////////////////////////////
    function test_RevertsIf_BurnDSC_ZeroAmount() public collateralDeposited {
        vm.startPrank(user);
        vm.expectRevert(DSCEngine.DSCEngine__ZeroAmount.selector);
        dscEngine.burnDSC(0);
        vm.stopPrank();
    }

    function test_RevertsIf_BurnDSC_WithoutMinting() public {
        vm.startPrank(user);
        vm.expectRevert();
        dscEngine.burnDSC(COLLATERAL_AMOUNT);
        vm.stopPrank();
    }

    function test_BurnDSC() public collateralDeposited_DSCMinted {
        vm.startPrank(user);

        // user will have dsCoin token
        // user has to approve dscEngine to make transfer onBehalof of
        // dscEngine gets the token from user and burns it
        dsCoin.approve(address(dscEngine), BURN_DSC_AMOUNT);
        dscEngine.burnDSC(BURN_DSC_AMOUNT);
        vm.stopPrank();
    }

    function test_RevertsIfBurnDSC_MoreThanMinted() public collateralDeposited_DSCMinted {
        vm.startPrank(user);
        dsCoin.approve(address(dscEngine), BURN_DSC_AMOUNT);
        vm.expectRevert();
        dscEngine.burnDSC(BURN_DSC_AMOUNT * 1000e18); // user is trying to burn more than minted
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////
    ////////  Redeem Collateral And Burn DSC Tests  //////////
    //////////////////////////////////////////////////////////
    function test_UserCan_RedeemCollateral_BurnDSC_InOneTx() public collateralDeposited_DSCMinted {
        vm.startPrank(user);
        dsCoin.approve(address(dscEngine), BURN_DSC_AMOUNT);
        dscEngine.redeemCollateralAndBurnDSC(weth, COLLATERAL_AMOUNT, BURN_DSC_AMOUNT);
        vm.stopPrank();
    }
}

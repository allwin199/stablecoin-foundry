// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Handler will narrow down the way we call functions

import {Test, console2} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {DSCEngine} from "../../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "../../mocks/MockV3Aggregator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Handler is Test {
    DSCEngine public dscEngine;
    DecentralizedStableCoin public dsCoin;
    HelperConfig public helperConfig;
    ERC20Mock weth;
    ERC20Mock wbtc;

    uint96 public constant MAX_DEPOSIT_SIZE = type(uint96).max;
    // MockV3Aggregator public ethUsdPriceFeed;

    address[] usersWithCollateralDeposited;

    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsCoin) {
        dscEngine = _dscEngine;
        dsCoin = _dsCoin;

        address[] memory collateralTokens = dscEngine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

        // ethUsdPriceFeed = MockV3Aggregator(dscEngine.getCollateralTokenPriceFeed(address(weth)));
    }

    function depositCollateral(uint256 collateralSeed, uint256 randomCollateralAmount) public {
        // collateralSeed and randomCollateralAmount will give some random number
        // but in our system only weth and wbtc are allowed
        // using _getRandomCollateral etither weth or wbtc will be selected based on modulo
        ERC20Mock collateral = _getRandomCollateral(collateralSeed);

        // we don't want to deposit with 0
        uint256 collateralAmount = bound(randomCollateralAmount, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);

        // whatever the collateral is picked, we have to mint some balance for the user
        collateral.mint(msg.sender, collateralAmount);

        // approve dscEngine
        collateral.approve(address(dscEngine), collateralAmount);

        dscEngine.depositCollateral(address(collateral), collateralAmount);

        vm.stopPrank();

        usersWithCollateralDeposited.push(msg.sender);
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getRandomCollateral(collateralSeed);

        uint256 maxCollateral = dscEngine.getCollateralBalanceOfUser(msg.sender, address(collateral));
        // since we are using stateful fuzz testing
        // msg.sender has already deposited collateral in the above function
        // we can redeem it
        // to redeem it we need to get how much a user has deposited
        // because we can't redeem more than deposited

        amountCollateral = bound(amountCollateral, 0, maxCollateral);
        if (amountCollateral == 0) {
            return;
        }
        // the reason we might get amountCollateral as 0 is
        // fuzzing may try to different account that doesn't deposited any collateral.

        vm.startPrank(msg.sender);
        dscEngine.redeemCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
    }

    function mint(uint256 amount, uint256 addressSeed) public {
        if (usersWithCollateralDeposited.length == 0) {
            return;
        }

        address sender = usersWithCollateralDeposited[addressSeed % usersWithCollateralDeposited.length];

        // dscAmount cannot exceed collateral balance in USD
        // uint256 dscAmount = bound(randomDSCAmount, 1, MAX_DEPOSIT_SIZE);

        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(sender);

        int256 maxDscToMint = (int256(collateralValueInUsd) / 2) - int256(totalDscMinted);

        if (maxDscToMint < 0) {
            return;
        }

        amount = bound(amount, 0, uint256(maxDscToMint));

        if (amount == 0) {
            return;
        }

        vm.startPrank(sender);
        // minting DSC
        dscEngine.mintDSC(amount);
        vm.stopPrank();
    }

    // function liquidate(uint256 collateralSeed, address userToBeLiquidated, uint256 debtToCover) public {
    //     uint256 minHealthFactor = dscEngine.getMinHealthFactor();
    //     uint256 userHealthFactor = dscEngine.getHealthFactor(userToBeLiquidated);
    //     if (userHealthFactor >= minHealthFactor) {
    //         return;
    //     }
    //     debtToCover = bound(debtToCover, 1, uint256(type(uint96).max));
    //     ERC20Mock collateral = _getRandomCollateral(collateralSeed);
    //     dscEngine.liquidate(address(collateral), userToBeLiquidated, debtToCover);
    // }

    // // function updateCollateralPrice(uint96 newPrice, uint256 collateralSeed) public {
    // //     int256 intNewPrice = int256(uint256(newPrice));
    // //     ERC20Mock collateral = _getRandomCollateral(collateralSeed);
    // //     MockV3Aggregator priceFeed = MockV3Aggregator(dscEngine.getCollateralTokenPriceFeed(address(collateral)));

    // //     priceFeed.updateAnswer(intNewPrice);
    // // }

    // Helper Functions
    function _getRandomCollateral(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }
}

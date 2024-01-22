// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Handler will narrow down the way we call functions

import {Test, console2, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract Handler is Test {
    DSCEngine public dscEngine;
    DecentralizedStableCoin public dsCoin;
    HelperConfig public helperConfig;
    ERC20Mock weth;
    ERC20Mock wbtc;

    uint96 public constant MAX_DEPOSIT_SIZE = type(uint96).max;
    // MockV3Aggregator public ethUsdPriceFeed;

    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsCoin) {
        dscEngine = _dscEngine;
        dsCoin = _dsCoin;

        address[] memory collateralTokens = dscEngine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

        // ethUsdPriceFeed = MockV3Aggregator(dscEngine.getCollateralTokenPriceFeed(address(weth)));
    }

    function depositCollateral(uint256 collateralSeed, uint256 randomCollateralAmount) public {
        // collateralSeed and randomCollateralAmount will give soem random number
        // but in our system only weth and wbtc are allowed
        // using _getRandomCollateral etither weth or wbtc will be selected based on modulo
        ERC20Mock collateral = _getRandomCollateral(collateralSeed);

        uint256 collateralAmount = bound(randomCollateralAmount, 1, MAX_DEPOSIT_SIZE);
        // we don't want to deposit with "0"

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, collateralAmount);
        collateral.approve(address(dscEngine), collateralAmount);

        dscEngine.depositCollateral(address(collateral), collateralAmount);
        vm.stopPrank();
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

        vm.startPrank(msg.sender);
        dscEngine.redeemCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
    }

    function mint(uint256 randomDSCAmount) public {
        // dscAmount cannot exceed collateral balance in USD
        uint256 dscAmount = bound(randomDSCAmount, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        // minting DSC
        dscEngine.mintDSC(dscAmount);
        vm.stopPrank();
    }

    // Helper Functions
    function _getRandomCollateral(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        } else {
            return wbtc;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";

contract DecentralizedStableCoinTest is Test {
    DecentralizedStableCoin dSCoin;

    address public user = makeAddr("user");
    uint256 public constant MINT_AMOUNT = 10e18;

    function setUp() public {
        vm.startPrank(user);
        dSCoin = new DecentralizedStableCoin();
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////
    ///////////////////  Minting Tests  //////////////////////
    //////////////////////////////////////////////////////////

    function test_RevertsIf_MintingWith_ZeroAmount() public {
        vm.startPrank(user);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__ZeroAmount.selector);
        dSCoin.mint(msg.sender, 0);
        vm.stopPrank();
    }

    function test_RevertsIf_MintingWith_ZeroAddress() public {
        vm.startPrank(user);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__ZeroAddress.selector);
        dSCoin.mint(address(0), MINT_AMOUNT);
        vm.stopPrank();
    }

    function test_Minting_WorksCorrectly() public {
        vm.startPrank(user);
        dSCoin.mint(user, MINT_AMOUNT);
        vm.stopPrank();
    }

    function test_Minting_UpdatesUserBalance() public {
        // ARRANGE
        vm.startPrank(user);
        uint256 prevUserBalance = dSCoin.balanceOf(user);

        // ACT
        dSCoin.mint(user, MINT_AMOUNT);
        uint256 currentUserBalance = dSCoin.balanceOf(user);

        // ASSERT
        assertGt(currentUserBalance, prevUserBalance);
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////
    ///////////////////  Burning Tests  //////////////////////
    //////////////////////////////////////////////////////////

    function test_RevertsIf_BurningWith_ZeroAmount() public {
        vm.startPrank(user);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__ZeroAmount.selector);
        dSCoin.burn(0);
        vm.stopPrank();
    }

    function test_RevertsIf_BurnAmount_ExceedsBalance() public {
        vm.startPrank(user);
        dSCoin.mint(user, MINT_AMOUNT);

        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__BurnAmount_ExceedsBalance.selector);
        dSCoin.burn(100e18);
        vm.stopPrank();
    }

    function test_Burning_WorksCorrectly() public {
        vm.startPrank(user);
        dSCoin.mint(user, MINT_AMOUNT);
        dSCoin.burn(MINT_AMOUNT);
        vm.stopPrank();
    }

    function test_Burning_UpdatesUserBalance() public {
        // ARRANGE
        vm.startPrank(user);

        // ACT
        dSCoin.mint(user, MINT_AMOUNT);
        uint256 prevUserBalance = dSCoin.balanceOf(user);

        dSCoin.burn(MINT_AMOUNT);
        uint256 currentUserBalance = dSCoin.balanceOf(user);

        // ASSERT
        assertGt(prevUserBalance, currentUserBalance);
        assertEq(currentUserBalance, 0);
        vm.stopPrank();
    }
}

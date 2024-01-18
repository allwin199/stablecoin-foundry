// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

/// @dev Refer DSCEngine.md

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

//////////////////////////////////////////////////////////
//////////////////////  Imports  /////////////////////////
//////////////////////////////////////////////////////////

/// @title DSCEngine
/// @author Prince Allwin
/// The system is designed to be as minimal as possible, and have the tokens maintain a 1 DSC token == $1 pegged.

/// This stablecoin has the properties
/// - Exogenous Collateral
/// - Dollar Pegged
/// - Algorathmically Stable

/// It is similar to DAI if DAI had no governance, no fees, and was only backed by wETH & wBTC.
/// @notice This contract is the core of the DSC System.
/// It handles all the logic for minting, Burning and redeeming DSC
/// as well as depositing and withdrawing collateral
/// @notice This contract is VERY loosely based on the MakerDAO DSS (DAI) system.

contract DSCEngine {}

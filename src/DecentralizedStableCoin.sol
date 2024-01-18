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

/// @dev Refer DecentralizedStableCoinDetails.md

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

//////////////////////////////////////////////////////////
//////////////////////  Imports  /////////////////////////
//////////////////////////////////////////////////////////
import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Decentralized StableCoin
/// @author Prince Allwin
/// @notice Collateral: Exogenous(wEth & wBTC)
/// @notice Minting: Algorathmic
/// @notice Relative Stability: Pegged To USD
/// @notice This is the contract meant to be governed by DSCEngine.
/// @notice This contract is just the ERC20 implementation of our stablecoin system.
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    //////////////////////////////////////////////////////////
    ///////////////////////  Errors  /////////////////////////
    //////////////////////////////////////////////////////////
    error DecentralizedStableCoin__ZeroAmount();
    error DecentralizedStableCoin__BurnAmount_ExceedsBalance();
    error DecentralizedStableCoin__ZeroAddress();

    //////////////////////////////////////////////////////////
    ////////////////////  Functions  /////////////////////////
    //////////////////////////////////////////////////////////

    /// @dev whoever deploys this contract will become the owner
    /// @dev In our scenario DSCEngine will be the one deploying this contract
    /// @dev Therfore DSCEngine will be the owner of this contract
    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(msg.sender) {}

    //////////////////////////////////////////////////////////
    ////////////////////  Modifiers  /////////////////////////
    //////////////////////////////////////////////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert DecentralizedStableCoin__ZeroAmount();
        }
        _;
    }

    //////////////////////////////////////////////////////////
    //////////////////////  Burn DSC  ////////////////////////
    //////////////////////////////////////////////////////////
    /// @param amount amount to be burned
    /// @dev super.burn() knows it has to burn from msg.sender
    /// @dev onlyOwner modifier is implemented
    function burn(uint256 amount) public override onlyOwner moreThanZero(amount) {
        /// @dev check the balance of the user to make sure they have enough tokens to Burn
        uint256 userBalance = balanceOf(msg.sender);
        if (userBalance < amount) {
            revert DecentralizedStableCoin__BurnAmount_ExceedsBalance();
        }
        super.burn(amount);
        // super() means use the burn() from the parent contract which is ERC20Burnable
    }

    //////////////////////////////////////////////////////////
    //////////////////////  Mint DSC  ////////////////////////
    //////////////////////////////////////////////////////////
    /// @param to address of the minter
    /// @param amount amount to be minted
    /// @dev onlyOwner modifier is implemented
    /// @dev returns true, if minting is successful
    function mint(address to, uint256 amount) external onlyOwner moreThanZero(amount) returns (bool) {
        if (to == address(0)) {
            revert DecentralizedStableCoin__ZeroAddress();
        }
        _mint(to, amount);
        return true;
    }
}

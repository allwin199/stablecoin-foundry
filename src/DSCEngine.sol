// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
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
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title DSCEngine
/// @author Prince Allwin
/// The system is designed to be as minimal as possible, and have the tokens maintain a 1 DSC token == $1 pegged.

/// This stablecoin has the properties
/// - Exogenous Collateral
/// - Dollar Pegged
/// - Algorathmically Stable
/// It is similar to DAI if DAI had no governance, no fees, and was only backed by wETH & wBTC.

/// @notice Our DSC system should be "overcollateralized". At no point, should the value of all collateral <= the $backed value of all the DSC.

/// @notice This contract is the core of the DSC System.
/// It handles all the logic for minting, Burning and redeeming DSC
/// as well as depositing and withdrawing collateral
/// @notice This contract is VERY loosely based on the MakerDAO DSS (DAI) system.

contract DSCEngine is ReentrancyGuard {
    //////////////////////////////////////////////////////////
    ///////////////////////  Errors  /////////////////////////
    //////////////////////////////////////////////////////////
    error DSCEngine__ZeroAmount();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TokenAddressesAnd_PriceFeedAddresses_MustBeSameLenght();
    error DSCEngine__ZeroAddress();
    error DSCEngine__DepositCollateralFailed();

    //////////////////////////////////////////////////////////
    /////////////////  State Variables  //////////////////////
    //////////////////////////////////////////////////////////

    // Immutable Variables
    DecentralizedStableCoin private immutable i_dsc;

    // Storage
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_CollaterDepositedByUser;

    //////////////////////////////////////////////////////////
    ///////////////////////  Events  /////////////////////////
    //////////////////////////////////////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    //////////////////////////////////////////////////////////
    ////////////////////  Modifiers  /////////////////////////
    //////////////////////////////////////////////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__ZeroAmount();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        // If priceFeed is already set for the token then address will not be address(0)
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__TokenNotAllowed();
        }
        _;
    }

    modifier zeroAddress(address contractAddress) {
        if (contractAddress == address(0)) {
            revert DSCEngine__ZeroAddress();
        }
        _;
    }

    //////////////////////////////////////////////////////////
    ////////////////////  Functions  /////////////////////////
    //////////////////////////////////////////////////////////

    /// @param tokenAddresses tokenAddresses should contain both wETH & wBTC addresses
    /// @param priceFeedAddresses priceFeedAddresses should contain priceFeed addresses of ETH/USD and BTC/USD
    /// @param dscAddress decentralizedStableCoin Address
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAnd_PriceFeedAddresses_MustBeSameLenght();
        }
        if (dscAddress == address(0)) {
            revert DSCEngine__ZeroAddress();
        }
        for (uint256 index = 0; index < tokenAddresses.length; index++) {
            s_priceFeeds[tokenAddresses[index]] = priceFeedAddresses[index];
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    //////////////////////////////////////////////////////////
    ////////////////  External Functions  ////////////////////
    //////////////////////////////////////////////////////////

    /// @notice follows CEI
    /// @dev users are allowed to deposit with either wETH or wBTC
    /// @dev whenever user want to deposit collateral tokenAddress should be either wETH or wBTC
    /// @dev since we are working with external contracts let's add nonreentrant
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        nonReentrant
    {
        s_CollaterDepositedByUser[msg.sender][tokenCollateralAddress] =
            s_CollaterDepositedByUser[msg.sender][tokenCollateralAddress] + amountCollateral;

        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        // let's get the tokens
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__DepositCollateralFailed();
        }
    }

    function mintDSC() external {}

    function depositCollateralAndMintDSC() external {}

    function burnDSC() external {}

    function redeemCollateral() external {}

    function burnDSCAndRedeemCollateral() external {}

    function liquidate() external {}

    function getHealthFactor() external {}
}

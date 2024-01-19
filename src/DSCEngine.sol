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

/// @dev Refer DSCEngineDetails.md

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

//////////////////////////////////////////////////////////
//////////////////////  Imports  /////////////////////////
//////////////////////////////////////////////////////////
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    error DSCEngine__MintingDSCFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);

    //////////////////////////////////////////////////////////
    ///////////////////////  Events  /////////////////////////
    //////////////////////////////////////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    //////////////////////////////////////////////////////////
    /////////////////  State Variables  //////////////////////
    //////////////////////////////////////////////////////////
    // constant
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means you need to be 200% over-collateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    // Immutable Variables
    DecentralizedStableCoin private immutable i_dsc;

    // Storage
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDepositedByUser;
    mapping(address user => uint256 amountDSCMinted) private s_DSCMinted;
    address[] private s_collateralTokens;

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
    /// @notice Right now user can deposit wETH & wBTC and mintDSC
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
            s_collateralTokens.push(tokenAddresses[index]);
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
    /// @param tokenCollateralAddress  tokenAddress should be either wETH or wBTC, handled by isAllowedToken modifier
    /// @param amountCollateral collateral amount to be deposited
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        /// @dev since we have more than one token user can use for collateral
        /// @dev we have to track the user and the token and then the amount.
        s_collateralDepositedByUser[msg.sender][tokenCollateralAddress] +=
            s_collateralDepositedByUser[msg.sender][tokenCollateralAddress] + amountCollateral;

        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        // To get the tokens
        /// @dev msg.sender should approve DSCEngine contract to transfer tokens on behalf of the sender
        /// @dev DSCEngine will transfer tokens and place it in this contract
        /// @dev user balance will be updated accordingly
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__DepositCollateralFailed();
        }
    }

    /// @notice follows CEI
    /// @notice check if the collateral value > DSC amount
    /// @param amountDSCToMint The amount of Decentralized StableCoin to mint
    /// @notice user must have more collateral value than the minimum threshold
    function mintDSC(uint256 amountDSCToMint) external moreThanZero(amountDSCToMint) nonReentrant {
        s_DSCMinted[msg.sender] = s_DSCMinted[msg.sender] + amountDSCToMint;
        // once we update the mapping
        // we need to make sure that by minting this DSC, user's health factor is not broken
        // If health factor is broken we should revert
        _revertIfHealthFactorIsBroken(msg.sender);

        bool success = i_dsc.mint(msg.sender, amountDSCToMint);
        if (!success) {
            revert DSCEngine__MintingDSCFailed();
        }
    }

    //////////////////////////////////////////////////////////
    //////////  Private & Internal View Functions  ///////////
    //////////////////////////////////////////////////////////

    function _getAccountInformation(address user) private view returns (uint256, uint256) {
        uint256 totalDSCMinted = s_DSCMinted[msg.sender];
        uint256 totalCollateralValueInUsd = getAccountCollateralValue(user);
        return (totalDSCMinted, totalCollateralValueInUsd);
    }

    /// @notice Returns how close to liquidation a user is
    /// @notice If a user goes below `MINIMUM_THRESHOLD`, they can get liquidated
    function _healthFactor(address user) public view returns (uint256) {
        // 1. To calculate the health factor of the user
        // - get the VALUE of the totalCollateral deposited by the user
        // - get the totalDSC minted by the user
        (uint256 totalDSCMinted, uint256 totalCollateralValueInUSD) = _getAccountInformation(user);

        // we need to make sure that user is always 200% overcollateralized
        uint256 collateralAdjustedForThreshold =
            (totalCollateralValueInUSD * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        // LIQUIDATION_PRECISION is 100
        // the reason we are dividing by 100 is
        // since we are multiplying by LIQUIDATION_THRESHOLD it is make the number bigger

        // watch this fn again

        return ((collateralAdjustedForThreshold * PRECISION) / totalDSCMinted);
    }

    // 1. Check health factor (do they have enough collateral?)
    // 2. Revert If they don't
    function _revertIfHealthFactorIsBroken(address user) private view {
        // To check the health factor, get the health factor of the user
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    //////////////////////////////////////////////////////////
    //////////  Public & External View Functions  ////////////
    //////////////////////////////////////////////////////////

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUSD) {
        // since we have more than one collateral tokens
        // we have to loop through each token and get the amount they have deposited
        // and map it to the price, to get the USD value
        address[] memory collateralTokens = s_collateralTokens;
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            address token = collateralTokens[i];
            uint256 amount = s_collateralDepositedByUser[user][token];
            totalCollateralValueInUSD = totalCollateralValueInUSD + getUsdValue(token, amount);
        }
        return totalCollateralValueInUSD;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        // refer priceFeed in fundeMe
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // price will be 8 decimals
        // but ether is 18 decimals
        // so we have to do uint256(price) * 1e10
        // this will give price of 1ETH in terms of USD
        // If we multiple with the amount
        // we will get actual value of collateral in USD
        uint256 valueInUsd = uint256(price) * ADDITIONAL_FEED_PRECISION;
        uint256 amountInUsd = (valueInUsd * amount) / PRECISION;
        return amountInUsd;

        // if valueInUsd = 100e18
        // amount = 200e18
        // (valueInUsd * amount) / PRECISION;
        // (100e18 * 200e18)/1e18 = (2000000e36)/1e18 = 20000e18;
    }
}

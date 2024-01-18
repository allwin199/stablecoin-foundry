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
    /////////////////  State Variables  //////////////////////
    //////////////////////////////////////////////////////////
    // constant
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 50;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    // Immutable Variables
    DecentralizedStableCoin private immutable i_dsc;

    // Storage
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_CollaterDepositedByUser;
    mapping(address user => uint256 amountDSCMinted) private s_DSCMinted;
    address[] private s_collateralTokens;

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
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        nonReentrant
    {
        s_CollaterDepositedByUser[msg.sender][tokenCollateralAddress] =
            s_CollaterDepositedByUser[msg.sender][tokenCollateralAddress] + amountCollateral;

        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        // let's get the tokens from the sender
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__DepositCollateralFailed();
        }
    }

    // Check if the collateral value > DSC amount
    // User has already desposited some collateral but we want to find out what is the actual value
    // eg: If user deposited wETH then we have to find out what is the value of ETH/USD
    function mintDSC(uint256 amountDSCToMint) external moreThanZero(amountDSCToMint) {
        s_DSCMinted[msg.sender] = amountDSCToMint;
        _revertIfHealthFactorIsBroken(msg.sender);

        bool success = i_dsc.mint(msg.sender, amountDSCToMint);
        if (!success) {
            revert DSCEngine__MintingDSCFailed();
        }
    }

    function depositCollateralAndMintDSC() external {}

    function burnDSC() external {}

    function redeemCollateral() external {}

    function burnDSCAndRedeemCollateral() external {}

    function liquidate() external {}

    function getHealthFactor() external {}

    //////////////////////////////////////////////////////////
    //////////  Private & Internal View Functions  ///////////
    //////////////////////////////////////////////////////////

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDSCMinted, uint256 collateralValueInUSD)
    {
        totalDSCMinted = s_DSCMinted[user];
        collateralValueInUSD = getAccountCollateralValue(user);
    }

    // Returns how close to liquidation a user is
    // If a user goes below 1 then can get liquidated
    function _healthFactor(address user) private view returns (uint256) {
        // total DSC minted
        // total collateral VALUE
        (uint256 totalDSCMinted, uint256 collateralValueInUSD) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUSD * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDSCMinted;
    }

    // 1. Check health factor (do they have enough collateral?)
    // 2. Revert If they don't
    function _revertIfHealthFactorIsBroken(address user) private view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    //////////////////////////////////////////////////////////
    //////////  External & Public View Functions  ////////////
    //////////////////////////////////////////////////////////
    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through each collateral token, get the amount they have deposited and map it to
        // the price, to get the USD value

        address[] memory collateralTokens = s_collateralTokens;
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            address token = collateralTokens[i];
            uint256 amount = s_CollaterDepositedByUser[user][token];
            totalCollateralValueInUsd = getUsdValue(token, amount);
        }

        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        // refer priceFeed in fundeMe
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // this will give price of 1ETH in terms of USD
        // If we multiple with the amount
        // we will get actual value of collateral in USD
        uint256 actualAmount = uint256(price) * ADDITIONAL_FEED_PRECISION;
        uint256 amountInUsd = (actualAmount * amount) / PRECISION;
        return amountInUsd;
    }
}

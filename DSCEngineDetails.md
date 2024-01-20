# DSCEngine

-   DSCEngine is reponsible to make sure that 1 DSC token is always equal to $1
-   DSCEngine will be responsible for Depositing and redeeming collateral
-   DSCEngine will be responsible for Minting and Burning DSC

## Constructor

-   Before deploying this contract
-   wETH & wBTC should be deployed and that addresses will be passed to the DSCEngine
-   Also DecentralizedStableCoin should be deployed and passed in the constructor

## Deposit Collateral

-   User can deposit either with wETH or wBTC
-   User should approve DSCEngine to make transfer on behalf of the user
-   Once the collateral is deposited it will be updated in mapping
-   event will be emitted

## Minting DSC

-   Before minting DSC, user should have more collateral value than minimum threshold

```sol
    uint256 private constant LIQUIDATION_THRESHOLD = 50; //user should be 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;

    function _calculateHealthFactor(address user) private view returns (uint256) {
        (uint256 totalDSCMinted, uint256 totalCollateralValueInUSD) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold =
            ((collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION);
        uint256 healthFactor = (collateralAdjustedForThreshold * PRECISION) / totalDSCMinted
        return healthFactor;
    }

    since we are multiplying with liquidation threshold which is 50, we have to divide by liquidation precision which is 100

    totalDSCMinted = 100e18
    totalCollateralValueInUSD = 20000e18 // actual value is 10 ether but usd value is 20000e18
    totalCollateralValueInUSD * LIQUIDATION_THRESHOLD / LIQUIDATION_PRECISION
    20000e18 * 50 = 1000000e18 / 100 = 10000e18

    (collateralAdjustedForThreshold * PRECISION) / totalDSCMinted
    10000e18 * 1e18 = 10000e36
    the reason we are multiplying with precision is
    since MIN_HEALTH_FACTOR is 1e18. If we don't multiply precision healthFactor will always be below 1e18;
    10000e36 / 100e18 = 100e18

    100e18 > MIN_HEALTH_FACTOR which is 1e18
    100e18 > 1e18
    healthFactor > 1

    ---

    totalDSCMinted = 1000e18 // we have minted 1000DSC
    totalCollateralValueInUSD = 10000e18 // actual value is 0.5 ether but usd value is 1000e18
    totalCollateralValueInUSD * LIQUIDATION_THRESHOLD / LIQUIDATION_PRECISION
    1000e18 * 50 = 50000e18 / 100 = 500e18

    (collateralAdjustedForThreshold * PRECISION) / totalDSCMinted
    500e18 * 1e18 = 500e36
    the reason we are multiplying with precision is
    since MIN_HEALTH_FACTOR is 1e18. If we don't multiply precision healthFactor will always be below 1e18;
    500e36 / 1000e18 = 0.5e18

    0.5e18 < 1e18
    healthFactor < 1
```

## Liquidation

```sol
    let' say $100 worth of ETH is backing $50 worth of DSC
    It's not 100ETH it is 100$ worth of ETH
    which means usdValue for this ETH is $100

    If ETH value tanks and now $100 worth of ETH is now only $75
    $50 worth of DSC is backed by $75 worth of ETH. which is under collateralized because it is not 200% overcollateralized
    We shouldn't let this happen. We should liquidate the users who are under collateralized

    If user A is almost under collateralized
    Then user B can liquidate user A
    user B will pay of the debt aka DSC owned by user A
    since user B is liquidating user A, user B will take all the remaining collateral from user A as an incentive
```

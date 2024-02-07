price of 1ETH in $2000

let's say we have deposited 0.5ETH
value of 0.5ETH in USD is $1000
Now we have collateral worth $1000

Always a user should have 200% overcollateralized

since we have $1000 worth of ETH we can maximum mint $500 of DSC
100% 0f 500 is 500; 200% of 500 is 1000

If we mint $500 DSC after depositing $1000 worth of ETH
Our DSC balance will be $500

---

If price of 1 ETH tanks to $1000

we have a 0.5ETH collateral.
value of 0.5ETH in USD is $500 now.
Our updated collateral value in USD is $500.

Right now we have $500 of DSC backed by $500 worth of ETH

This user is not 200% overcollateralized.

---

To get to 200% overcallateralized.

collateral value in USD is $500
so maximum of 250$ DSC can be minted.

This user has to burn $250 DSC inorder to be overcollateralized

---

If the user dosen't get to 200% overcollateralized
This user can get liquidated.

---

mintDSC Explanation

1. To mint a DSC
2. User should have deposited collateral
3. User should be 200% overcollateralized

-   calculateHealthFactor will be return the healthFactor of the user.
-   calculateHealthFactor will say if the user is 200% overcollateralized or not.
-   If the healthFactor is > 1.
-   Healthfactor is OK.
-   If not user cannot mint DSC

---

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
    since MIN_HEALTH_FACTOR is 1e18. If we don't multiply with precision, healthFactor will always be below 1e18;(1000e18/100e18=10)
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

    500e36 / 1000e18 = 0.5e18

    0.5e18 < 1e18
    healthFactor < 1
```

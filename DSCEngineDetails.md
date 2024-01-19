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

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

-   calculateHealthFactor will return the healthFactor of the user.
-   calculateHealthFactor will say if the user is 200% overcollateralized or not.
-   If the healthFactor is > 1.
-   Healthfactor is OK.
-   which means user is 200% collateralized
-   If not user cannot mint DSC
-   The user has to add more collateral
-   To mint more DSC

Refer foundry-fuzz-testing in repo for more details

-   In this protocol using stateless fuzz testing will not be the right move, because we cannot call function randomly.

for eg: `RedeemCollateral` cannot be called before `depositCollateral`

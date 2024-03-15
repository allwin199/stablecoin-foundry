Refer foundry-fuzz-testing repo for more details

-   In this protocol using stateless fuzz testing will not be the right move, because if the state dosen't hold, then whatever we deposited on the previous fuzz run will be discarded and everytime the amount will be 0 for each new fuzz run. 
  
-   Also, using stateful fuzz testing without handler will also not be helpful, because fuzzer will call functions randomly.

for eg: `RedeemCollateral` cannot be called before `depositCollateral`

- If fuzzer calls `RedeemCollateral` before  `depositCollateral` that is a waste of a fuzz run.

- For this protocol `Handler` based fuzz run will be helpful.

### Stateless Fuzzing

- Where the state of the previous run is discarded for every new run.

- In this protocol using stateless fuzz testing will not be the right move, because if the state dosen't hold, then whatever we deposited on the previous fuzz run will be discarded and everytime the amount will be 0 for each new fuzz run. 
  
- Also, using stateful fuzz testing without handler will also not be helpful, because fuzzer will call functions randomly.
- When `deposit` is called randomly, this test will break for other reason such as lack of `approval`
- In handler based testing, we can create a wrapper for deposit
- Inside this wrapper, before calling the `deposit` we can call `approve`

- Refer `foundry-fuzz-testing` repo for more details





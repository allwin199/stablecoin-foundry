## Invariant Testing (Stateful Fuzz)

### Stateful Fuzzing
- Fuzzing where the final state of your previous run is the starting state of the your next run
- We can create a wrapper for `deposit` function
- Inside we can all `approve` before calling `deposit`
- In this way our function will not revert
- let's say In the previous run, `deposit` was called.
- Now the deposited amount will persist and when calling `mint`
- It will be useful 
- because only the `deposited` users can `mint`
- To write stateful fuzzing in foundry. we have to use `invariant` keyword
- Set the target contract to `Handler`
- Inside the Handler contract setup all the functions which fuzzer needs to call
- Fuzzer will call the functions inside the Handler randomly with random data


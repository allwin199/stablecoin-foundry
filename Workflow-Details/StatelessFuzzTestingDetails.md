Fuzz Testing: Supply random data to your system in an attempt to break it.

```sol
uint256 private shouldAlwaysBeZero = 0;

function doStuff(uint256 data){
    if(data == 142){
        shouldAlwaysBeZero = 1;
    }
}

```

In this scenario whatever input we give to the `doStuff` function `shouldAlwaysBeZero` should remain as 0.

-   `shouldAlwaysBeZero` is the `INVARIANT`
-   Invariant -> Property of our system that should always hold

we can iterate data from 1 to 1000 and check whether `shouldAlwaysBeZero` changes

```sol
function test_ShouldAlwaysRemainZero() public {
    const testData = 0; //1...100

    doStuff(testData);

    assertEq(shouldAlwaysBeZero, 0);
}
```

Let's say we iterated data from 1...100 and say unit test passes, but it didn't catch the bug.

Instead of iterating one by one, we can use Fuzz testing.

```sol
function test_ShouldAlwaysRemainZero(uint256 testData) public {
    // when we give input to a test function It becomes stateless fuzzing
    // foundry will throw some random data at it

    doStuff(testData);

    assertEq(shouldAlwaysBeZero, 0);
}
```

By using fuzz testing we are able to catch a bug

-   Stateless Fuzzing: Where the state of the previous run is discarded for every new run.

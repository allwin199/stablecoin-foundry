# Stop On Revert

- For stop on Revert
- set `fail_on_revert` as `true` in foundry.toml
- When a fuzzer is called
- Let's say we only have `deposit` inside the handler
- It will call `deposit` inside the handler
- Next it will call the test
- for the next fuzz run
- It will call `deposit` inside the handler
- Next it will call the test
- If there is revert, our test will `fail`
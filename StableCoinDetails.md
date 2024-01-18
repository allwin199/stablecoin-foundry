# Stable Coin

-   A stable coin is a non-volatile crypto asset

## Workflow

1. (Relative Stability) => Anchored or Pegged to USD
    - our 1 stable coin will always worth $1
    - we should write a code to make sure 1 stable coin == $1
    - To make sure 1 stable coin is equivalent to $1 we can use chainlink priceFeed
    - After getting the priceFeed we set a function to echange ETH & BTC or whatever their dollar equivalent is

---

2. Stability Mechanism (way we do Minting):
    - Algorathmic (Decentralized)
    - No centralized entities invloved in minting or burning
    - To make the stability mechanism algorithmic
        1. People can only mint the stablecoin with enough collateral

---

3. Collateral Type: Exogenous
    - we will use crypto currencies as collateral
    - wETH(wrapped ETH)
        - Wrapped Ethereum (WETH) is essentially the ERC-20 version of Ethereum (ETH)
        - It allows Ethereum to interact with other ERC-20 tokens, which is crucial for many DeFi protocols
        - To generate WETH, you send your ETH to a smart contract that then provides WETH in return
        - All WETH created is backed up completely by ETH reserves.
        - Your ETH is locked in the smart contract and can be exchanged back at any time for WETH.
        - When your ETH is returned, the contract burns the supplied WETH.
    - wBTC(wrapped BTC)

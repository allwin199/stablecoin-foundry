// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title OrcaleLib
/// @author Prince Allwin
/// @notice This library is used to check the Chainlink Oracle for stale data.
/// @notice If a price is stale, the function will revert, and render the DSCEngine unusable - this is by design
/// @notice We want the DSCEngine to freeze if prices become stale
/// @notice So if the Chainlink network explodes and you have lot of money locked in the protocol... to bad.
library OracleLib {
    error OraclLib__StalePrice();

    uint256 private constant TIMEOUT = 3 hours; // 3 * 60 * 60 = 10800 seconds
    // for ETH/USD and BTC/USD Heartbeat is 3600s
    // we are giving more time

    function staleCheckLatestRoundData(AggregatorV3Interface priceFeed)
        public
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            priceFeed.latestRoundData();

        uint256 secondsSince = block.timestamp - updatedAt;
        // currentTime - updatedAt will give the last time priceFeed was updated
        // If secondsSince is more than our Timeout it should revert

        if (secondsSince > TIMEOUT) {
            revert OraclLib__StalePrice();
        }

        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }
}

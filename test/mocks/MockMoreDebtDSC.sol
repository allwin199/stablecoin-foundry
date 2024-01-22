// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MockV3Aggregator} from "./MockV3Aggregator.sol";

contract MockMoreDebtDSC is ERC20 {
    address mockAggregator;

    constructor(address _mockAggregator) ERC20("ERC20Mock", "E20M") {
        mockAggregator = _mockAggregator;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        // We crash the price
        MockV3Aggregator(mockAggregator).updateAnswer(0);
        _burn(account, amount);
    }
}

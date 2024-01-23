// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MockV3Aggregator} from "./MockV3Aggregator.sol";

contract MockMoreDebtDSC is ERC20Burnable, Ownable {
    address mockAggregator;

    constructor(address _mockAggregator) ERC20("ERC20Mock", "E20M") Ownable(msg.sender) {
        mockAggregator = _mockAggregator;
    }

    function mint(address account, uint256 amount) external returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount) external {
        // We crash the price
        MockV3Aggregator(mockAggregator).updateAnswer(0);
        _burn(account, amount);
    }
}

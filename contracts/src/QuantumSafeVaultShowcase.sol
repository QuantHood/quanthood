// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {QuanthoodGuard} from "./QuanthoodGuard.sol";

/// @title QuantumSafeVaultShowcase — minimal vault demonstrating QuanthoodGuard.
/// @notice Deposits lock automatically when the oracle threat level reaches the
///         guard threshold. Live demo instance referenced by the Quanthood app.
contract QuantumSafeVaultShowcase is QuanthoodGuard {
    mapping(address => uint256) public balances;

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    constructor(address oracle_, uint8 lockLevel_) QuanthoodGuard(oracle_, lockLevel_) {}

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external quantumSafe {
        require(balances[msg.sender] >= amount, "insufficient");
        balances[msg.sender] -= amount;
        emit Withdrawn(msg.sender, amount);
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "transfer failed");
    }
}

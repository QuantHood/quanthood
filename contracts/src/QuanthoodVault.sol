// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {QuanthoodOracle} from "./QuanthoodOracle.sol";

/// @title QuanthoodVault — self-rescuing vault driven by QuanthoodOracle.
/// @notice Each account holds its own balance. The owner nominates a recovery
///         address and a threat threshold. Once the oracle level reaches the
///         threshold, anyone may sweep the balance to the recovery address.
///         The owner can always withdraw first — the sweep is a safety net,
///         never a lock. Recovery addresses can only be changed while the
///         oracle level is below the threshold.
contract QuanthoodVault {
    QuanthoodOracle public immutable oracle;

    struct Account {
        uint256 balance;
        address recovery;
        uint8 threshold;
        bool swept;
    }

    mapping(address => Account) private _accounts;

    event Deposited(address indexed owner, uint256 amount, uint256 total);
    event Withdrawn(address indexed owner, uint256 amount, uint256 remaining);
    event RecoverySet(address indexed owner, address recovery, uint8 threshold);
    event Swept(address indexed owner, address indexed to, uint256 amount, uint8 level);

    error ZeroAmount();
    error NoBalance();
    error RecoveryRequired();
    error AlreadySwept();
    error SweepNotArmed(uint8 current);
    error RecoveryFrozen(uint8 current);
    error TransferFailed();
    error ZeroAddress();

    constructor(address oracle_) {
        require(oracle_ != address(0), "oracle zero");
        oracle = QuanthoodOracle(oracle_);
    }

    function deposit() external payable {
        if (msg.value == 0) revert ZeroAmount();
        Account storage a = _accounts[msg.sender];
        a.balance += msg.value;
        if (a.threshold == 0) a.threshold = 3;
        emit Deposited(msg.sender, msg.value, a.balance);
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        Account storage a = _accounts[msg.sender];
        if (a.balance < amount) revert NoBalance();
        a.balance -= amount;
        emit Withdrawn(msg.sender, amount, a.balance);
        (bool ok, ) = msg.sender.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }

    function setRecovery(address recovery, uint8 threshold) external {
        uint8 level = oracle.threatLevel();
        Account storage a = _accounts[msg.sender];
        if (level >= a.threshold && a.balance > 0) revert RecoveryFrozen(level);
        if (recovery == address(0)) revert ZeroAddress();
        if (recovery == msg.sender) revert ZeroAddress();
        if (threshold < 1 || threshold > 5) revert RecoveryRequired();
        a.recovery = recovery;
        a.threshold = threshold;
        emit RecoverySet(msg.sender, recovery, threshold);
    }

    /// @notice Anyone may trigger the sweep once the threshold is reached.
    ///         Funds move to the owner's nominated recovery address, so the
    ///         caller has no way to redirect them.
    function sweep(address owner) external {
        Account storage a = _accounts[owner];
        if (a.balance == 0) revert NoBalance();
        if (a.recovery == address(0)) revert RecoveryRequired();
        if (a.swept) revert AlreadySwept();
        uint8 level = oracle.threatLevel();
        if (level < a.threshold) revert SweepNotArmed(level);
        uint256 amount = a.balance;
        a.balance = 0;
        a.swept = true;
        emit Swept(owner, a.recovery, amount, level);
        (bool ok, ) = a.recovery.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }

    function accountOf(address owner) external view returns (Account memory) {
        return _accounts[owner];
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _accounts[owner].balance;
    }

    /// @notice True while a sweep of this account can still be armed by the
    ///         owner changing the recovery address (i.e. level still low).
    function recoveryOpen(address owner) external view returns (bool) {
        return oracle.threatLevel() < _accounts[owner].threshold;
    }
}

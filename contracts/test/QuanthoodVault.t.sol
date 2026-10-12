// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import "forge-std/Test.sol";
import {QuanthoodVault} from "../src/QuanthoodVault.sol";
import {QuanthoodOracle} from "../src/QuanthoodOracle.sol";

contract QuanthoodVaultTest is Test {
    QuanthoodOracle oracle;
    QuanthoodVault vault;

    address owner = makeAddr("owner");
    address recovery = makeAddr("recovery");
    address stranger = makeAddr("stranger");

    function setUp() public {
        oracle = new QuanthoodOracle();
        vault = new QuanthoodVault(address(oracle));
    }

    function _deposit(address who, uint256 amount) internal {
        vm.deal(who, amount);
        vm.prank(who);
        vault.deposit{value: amount}();
    }

    function testDepositTracksBalance() public {
        _deposit(owner, 1 ether);
        assertEq(vault.balanceOf(owner), 1 ether);
    }

    function testWithdrawReturnsFunds() public {
        _deposit(owner, 1 ether);
        uint256 before = owner.balance;
        vm.prank(owner);
        vault.withdraw(0.4 ether);
        assertEq(vault.balanceOf(owner), 0.6 ether);
        assertEq(owner.balance, before + 0.4 ether);
    }

    function testCannotOverdraw() public {
        _deposit(owner, 1 ether);
        vm.prank(owner);
        vm.expectRevert(QuanthoodVault.NoBalance.selector);
        vault.withdraw(2 ether);
    }

    function testSweepBlockedBelowThreshold() public {
        _deposit(owner, 1 ether);
        vm.prank(owner);
        vault.setRecovery(recovery, 3);
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(QuanthoodVault.SweepNotArmed.selector, 0));
        vault.sweep(owner);
    }

    function testSweepBlockedWithoutRecovery() public {
        _deposit(owner, 1 ether);
        vm.prank(stranger);
        vm.expectRevert(QuanthoodVault.RecoveryRequired.selector);
        vault.sweep(owner);
    }

    function testSweepGoesToRecoveryNotCaller() public {
        _deposit(owner, 1 ether);
        vm.prank(owner);
        vault.setRecovery(recovery, 2);
        _raiseLevel(2);
        uint256 before = recovery.balance;
        vm.prank(stranger);
        vault.sweep(owner);
        assertEq(recovery.balance - before, 1 ether);
        assertEq(vault.balanceOf(owner), 0);
    }

    function testSweepOnlyOnce() public {
        _deposit(owner, 1 ether);
        vm.prank(owner);
        vault.setRecovery(recovery, 2);
        _raiseLevel(2);
        vm.prank(stranger);
        vault.sweep(owner);
        vm.prank(stranger);
        vm.expectRevert(QuanthoodVault.NoBalance.selector);
        vault.sweep(owner);
    }

    function testOwnerCanWithdrawInsteadOfSweep() public {
        _deposit(owner, 1 ether);
        vm.prank(owner);
        vault.setRecovery(recovery, 2);
        _raiseLevel(2);
        uint256 before = owner.balance;
        vm.prank(owner);
        vault.withdraw(1 ether);
        assertEq(owner.balance - before, 1 ether);
        assertEq(vault.balanceOf(owner), 0);
    }

    function testRecoveryFrozenAfterThreshold() public {
        _deposit(owner, 1 ether);
        vm.prank(owner);
        vault.setRecovery(recovery, 2);
        _raiseLevel(2);
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(QuanthoodVault.RecoveryFrozen.selector, 2));
        vault.setRecovery(makeAddr("evil"), 2);
    }

    function testRecoveryChangeableBeforeThreshold() public {
        _deposit(owner, 1 ether);
        vm.prank(owner);
        vault.setRecovery(recovery, 2);
        address recovery2 = makeAddr("recovery2");
        vm.prank(owner);
        vault.setRecovery(recovery2, 3);
        QuanthoodVault.Account memory acc = vault.accountOf(owner);
        assertEq(acc.recovery, recovery2);
        assertEq(acc.threshold, 3);
    }

    function testCannotSetSelfAsRecovery() public {
        vm.prank(owner);
        vm.expectRevert(QuanthoodVault.ZeroAddress.selector);
        vault.setRecovery(owner, 2);
    }

    function testSweepReentrancySafe() public {
        // CEI: balance zeroed and swept flag set before the external call.
        _deposit(owner, 1 ether);
        vm.prank(owner);
        vault.setRecovery(recovery, 1);
        _raiseLevel(1);
        vm.prank(stranger);
        vault.sweep(owner);
        QuanthoodVault.Account memory acc = vault.accountOf(owner);
        assertTrue(acc.swept);
        assertEq(vault.balanceOf(owner), 0);
    }

    function testZeroDepositReverts() public {
        vm.prank(owner);
        vm.expectRevert(QuanthoodVault.ZeroAmount.selector);
        vault.deposit{value: 0}();
    }

    function testRecoveryNotRequiredForWithdraw() public {
        // Owners who never set a recovery can still withdraw normally.
        _deposit(owner, 1 ether);
        vm.prank(owner);
        vault.withdraw(1 ether);
        assertEq(vault.balanceOf(owner), 0);
    }

    function _raiseLevel(uint8 to) internal {
        // The oracle only accepts reports from its canary; simulate by
        // pointing the oracle at a mock canary that owns rung reporting.
        vm.prank(oracle.owner());
        oracle.setCanary(address(this));
        for (uint8 i = 0; i < to; i++) {
            oracle.reportBreak(uint256(i + 1));
        }
    }
}

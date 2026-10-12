// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {Test} from "forge-std/Test.sol";
import {QuanthoodMarket} from "../src/QuanthoodMarket.sol";
import {QuanthoodOracle} from "../src/QuanthoodOracle.sol";

contract MockCanary {
    // rungs(id) returns (bits, bounty, armed, broken, brokenAt, pubkeyAddress, fundedAt)
    mapping(uint256 => bool) public brokenFlags;

    function setBroken(uint256 id, bool b) external { brokenFlags[id] = b; }

    function rungs(uint256 id)
        external
        view
        returns (uint256 bits, uint256 bounty, bool armed, bool broken, uint256 brokenAt, address pubkeyAddress, uint256 fundedAt)
    {
        broken = brokenFlags[id];
        bits = 128;
        bounty = 0.01 ether;
        armed = true;
        pubkeyAddress = address(0x1234);
        fundedAt = 0;
    }
}

contract QuanthoodMarketTest is Test {
    QuanthoodOracle oracle;
    MockCanary canary;
    QuanthoodMarket market;

    address bettor1 = makeAddr("bettor1");
    address bettor2 = makeAddr("bettor2");
    address bettor3 = makeAddr("bettor3");

    function setUp() public {
        oracle = new QuanthoodOracle();
        canary = new MockCanary();
        market = new QuanthoodMarket(address(oracle), address(canary));
        vm.deal(bettor1, 10 ether);
        vm.deal(bettor2, 10 ether);
        vm.deal(bettor3, 10 ether);
    }

    function _openLevel(uint8 thr, uint64 inSecs) internal returns (uint256) {
        return market.openMarket(QuanthoodMarket.Kind.LevelBy, thr, 0, uint64(block.timestamp + inSecs));
    }

    function testOpenMarket() public {
        uint256 id = _openLevel(3, 1 days);
        (QuanthoodMarket.Kind kind, uint8 thr, , uint64 closeAt, , , , ) = market.viewMarket(id);
        assertEq(uint8(kind), 0);
        assertEq(thr, 3);
        assertGt(closeAt, block.timestamp);
    }

    function testBetBothSides() public {
        uint256 id = _openLevel(3, 1 days);
        vm.prank(bettor1); market.bet{value: 1 ether}(id, QuanthoodMarket.Side.Yes);
        vm.prank(bettor2); market.bet{value: 3 ether}(id, QuanthoodMarket.Side.No);
        (uint256 y, uint256 n) = market.myStake(id, bettor1);
        assertEq(y, 1 ether); assertEq(n, 0);
        (, , , , , , uint256 yesAmt, uint256 noAmt) = market.viewMarket(id);
        assertEq(yesAmt, 1 ether); assertEq(noAmt, 3 ether);
    }

    function testCannotBetAfterClose() public {
        uint256 id = _openLevel(3, 100);
        vm.warp(block.timestamp + 101);
        vm.prank(bettor1);
        vm.expectRevert(QuanthoodMarket.Closed.selector);
        market.bet{value: 1 ether}(id, QuanthoodMarket.Side.Yes);
    }

    function testResolveNoWhenLevelLow() public {
        uint256 id = _openLevel(3, 100);
        vm.prank(bettor1); market.bet{value: 2 ether}(id, QuanthoodMarket.Side.Yes);
        vm.prank(bettor2); market.bet{value: 1 ether}(id, QuanthoodMarket.Side.No);
        vm.warp(block.timestamp + 101);
        market.resolve(id);
        (, , , , bool resolved, bool outcomeYes, , ) = market.viewMarket(id);
        assertTrue(resolved);
        assertFalse(outcomeYes);
    }

    function testResolveYesWhenThresholdZero() public {
        uint256 id = _openLevel(0, 100);
        vm.warp(block.timestamp + 101);
        market.resolve(id);
        (, , , , , bool outcomeYes, , ) = market.viewMarket(id);
        assertTrue(outcomeYes);
    }

    function testPayoutProportional() public {
        uint256 id = _openLevel(3, 100);
        vm.prank(bettor1); market.bet{value: 1 ether}(id, QuanthoodMarket.Side.Yes);  // wrong side
        vm.prank(bettor2); market.bet{value: 1 ether}(id, QuanthoodMarket.Side.No);   // winner
        vm.prank(bettor3); market.bet{value: 1 ether}(id, QuanthoodMarket.Side.No);   // winner
        vm.warp(block.timestamp + 101);
        market.resolve(id); // level stays 0 → NO wins
        uint256 before = bettor2.balance;
        vm.prank(bettor2); market.claim(id);
        assertEq(bettor2.balance - before, 1.5 ether);
        uint256 before3 = bettor3.balance;
        vm.prank(bettor3); market.claim(id);
        assertEq(bettor3.balance - before3, 1.5 ether);
        // loser gets nothing
        vm.prank(bettor1);
        vm.expectRevert(QuanthoodMarket.NothingToClaim.selector);
        market.claim(id);
    }

    function testRungMarketResolvesOnBreak() public {
        uint256 id = market.openMarket(QuanthoodMarket.Kind.RungBefore, 0, 7, uint64(block.timestamp + 100));
        vm.prank(bettor1); market.bet{value: 1 ether}(id, QuanthoodMarket.Side.No);
        vm.warp(block.timestamp + 101);
        market.resolve(id); // not broken → NO
        (, , , , , bool outcomeYes, , ) = market.viewMarket(id);
        assertFalse(outcomeYes);
        uint256 before = bettor1.balance;
        vm.prank(bettor1); market.claim(id);
        assertEq(bettor1.balance - before, 1 ether);
    }

    function testRungMarketResolvesYesAfterBreak() public {
        uint256 id = market.openMarket(QuanthoodMarket.Kind.RungBefore, 0, 7, uint64(block.timestamp + 100));
        canary.setBroken(7, true);
        vm.warp(block.timestamp + 101);
        market.resolve(id);
        (, , , , , bool outcomeYes, , ) = market.viewMarket(id);
        assertTrue(outcomeYes);
    }

    function testDoubleClaimReverts() public {
        uint256 id = _openLevel(3, 100);
        vm.prank(bettor2); market.bet{value: 1 ether}(id, QuanthoodMarket.Side.No);
        vm.warp(block.timestamp + 101);
        market.resolve(id);
        vm.prank(bettor2); market.claim(id);
        vm.prank(bettor2);
        vm.expectRevert(QuanthoodMarket.AlreadyClaimed.selector);
        market.claim(id);
    }

    function testZeroBetReverts() public {
        uint256 id = _openLevel(3, 100);
        vm.prank(bettor1);
        vm.expectRevert(QuanthoodMarket.BadMarket.selector);
        market.bet(id, QuanthoodMarket.Side.Yes);
    }
}

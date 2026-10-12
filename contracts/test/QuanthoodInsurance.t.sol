// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {Test} from "forge-std/Test.sol";
import {QuanthoodInsurance} from "../src/QuanthoodInsurance.sol";
import {QuanthoodOracle} from "../src/QuanthoodOracle.sol";

contract MockCanaryIns {
    uint256 public momentAt;
    mapping(uint256 => bool) public brokenFlags;
    mapping(uint256 => bool) public armedFlags;

    function setMoment(uint256 t) external { momentAt = t; }
    function setRung(uint256 id, bool armed, bool broken) external { armedFlags[id] = armed; brokenFlags[id] = broken; }

    function rungs(uint256 id)
        external view
        returns (uint256 bits, uint256 bounty, bool armed, bool broken, uint256 brokenAt, address pubkeyAddress, uint256 fundedAt)
    {
        armed = armedFlags[id];
        broken = brokenFlags[id];
        bits = 128;
    }
}

contract QuanthoodInsuranceTest is Test {
    QuanthoodOracle oracle;
    MockCanaryIns canary;
    QuanthoodInsurance ins;

    address holder = makeAddr("holder");
    address underwriter = makeAddr("underwriter");

    function setUp() public {
        oracle = new QuanthoodOracle();
        canary = new MockCanaryIns();
        ins = new QuanthoodInsurance(address(oracle), address(canary));
        vm.deal(underwriter, 100 ether);
        vm.deal(holder, 100 ether);
    }

    function testRateBaseLevel0() public {
        assertEq(ins.rateBps(), 40);
    }

    function testQuoteOneYear() public {
        // 2 ETH coverage at 0.40%/yr for 365 days = 0.008 ETH
        uint256 q = ins.quote(2 ether, uint64(365 days));
        assertEq(q, 0.008 ether);
    }

    function testRateRisesViaRealFlow() public {
        // oracle owner = this test contract (deployer in setUp)
        oracle.setCanary(address(canary));
        canary.setRung(7, true, false);
        canary.setRung(8, true, false);
        canary.setRung(9, true, false);
        // breaks reported BY the canary contract:
        vm.prank(address(canary)); oracle.reportBreak(7);
        vm.prank(address(canary)); oracle.reportBreak(8);
        vm.prank(address(canary)); oracle.reportBreak(9);
        assertEq(oracle.threatLevel(), 3);
        assertEq(ins.rateBps(), 40 + 400);
        assertEq(ins.quote(2 ether, uint64(365 days)), 0.088 ether);
    }

    function testAddAndRemoveCapital() public {
        vm.prank(underwriter);
        ins.addCapital{value: 10 ether}();
        assertEq(ins.lpBalance(underwriter), 10 ether);
        assertEq(ins.poolEth(), 10 ether);
        vm.prank(underwriter);
        ins.removeCapital(10 ether);
        assertEq(ins.poolEth(), 0);
        assertGt(underwriter.balance, 99 ether);
    }

    function testBuyPolicyHappyPath() public {
        vm.prank(underwriter);
        ins.addCapital{value: 5 ether}();
        uint256 premium = ins.quote(1 ether, uint64(30 days));
        vm.prank(holder);
        uint256 id = ins.buyPolicy{value: premium}(1 ether, uint64(30 days));
        (address h, uint256 cov, uint256 prem,, , , ) = ins.viewPolicy(id);
        assertEq(h, holder);
        assertEq(cov, 1 ether);
        assertEq(prem, premium);
    }

    function testBuyRevertsWrongPremium() public {
        vm.prank(underwriter);
        ins.addCapital{value: 5 ether}();
        vm.prank(holder);
        vm.expectRevert(QuanthoodInsurance.InsufficientCapital.selector);
        ins.buyPolicy{value: 0.0001 ether}(1 ether, uint64(30 days));
    }

    function testClaimPaysAfterArmedBreak() public {
        vm.prank(underwriter);
        ins.addCapital{value: 5 ether}();
        uint256 premium = ins.quote(1 ether, uint64(30 days));
        vm.prank(holder);
        uint256 id = ins.buyPolicy{value: premium}(1 ether, uint64(30 days));
        // armed rung 7 breaks:
        canary.setRung(7, true, true);
        uint256 before = holder.balance;
        vm.prank(holder);
        ins.claim(id);
        assertEq(holder.balance - before, 1 ether);
        (, , , , , , bool paid) = ins.viewPolicy(id);
        assertTrue(paid);
        assertEq(ins.poolEth(), 5 ether + premium - 1 ether);
    }

    function testClaimRevertsNoBreak() public {
        vm.prank(underwriter);
        ins.addCapital{value: 5 ether}();
        uint256 premium = ins.quote(1 ether, uint64(30 days));
        vm.prank(holder);
        uint256 id = ins.buyPolicy{value: premium}(1 ether, uint64(30 days));
        vm.prank(holder);
        vm.expectRevert(QuanthoodInsurance.NotBroken.selector);
        ins.claim(id);
    }

    function testClaimRevertsAfterExpiry() public {
        vm.prank(underwriter);
        ins.addCapital{value: 5 ether}();
        uint256 premium = ins.quote(1 ether, uint64(30 days));
        vm.prank(holder);
        uint256 id = ins.buyPolicy{value: premium}(1 ether, uint64(30 days));
        vm.warp(block.timestamp + 31 days);
        canary.setRung(7, true, true);
        vm.prank(holder);
        vm.expectRevert(QuanthoodInsurance.NotExpired.selector);
        ins.claim(id);
    }

    function testClaimRevertsForNonHolder() public {
        vm.prank(underwriter);
        ins.addCapital{value: 5 ether}();
        uint256 premium = ins.quote(1 ether, uint64(30 days));
        vm.prank(holder);
        uint256 id = ins.buyPolicy{value: premium}(1 ether, uint64(30 days));
        canary.setRung(7, true, true);
        vm.prank(underwriter);
        vm.expectRevert(QuanthoodInsurance.PolicyNotFound.selector);
        ins.claim(id);
    }

    function testDoubleClaimReverts() public {
        vm.prank(underwriter);
        ins.addCapital{value: 5 ether}();
        uint256 premium = ins.quote(1 ether, uint64(30 days));
        vm.prank(holder);
        uint256 id = ins.buyPolicy{value: premium}(1 ether, uint64(30 days));
        canary.setRung(7, true, true);
        vm.prank(holder); ins.claim(id);
        vm.prank(holder);
        vm.expectRevert(QuanthoodInsurance.AlreadyClaimed.selector);
        ins.claim(id);
    }

    function testSettleExpired() public {
        vm.prank(underwriter);
        ins.addCapital{value: 5 ether}();
        uint256 premium = ins.quote(1 ether, uint64(30 days));
        vm.prank(holder);
        uint256 id = ins.buyPolicy{value: premium}(1 ether, uint64(30 days));
        vm.warp(block.timestamp + 31 days);
        ins.settleExpired(id);
        (, , , , , bool settled, ) = ins.viewPolicy(id);
        assertTrue(settled);
    }

    function testMomentAtSettlesEverything() public {
        // momentAt set → buyPolicy blocked entirely
        canary.setMoment(1234);
        vm.prank(underwriter);
        ins.addCapital{value: 5 ether}();
        vm.prank(holder);
        vm.expectRevert(QuanthoodInsurance.AlreadySettled.selector);
        ins.buyPolicy{value: 0.008 ether}(1 ether, uint64(365 days));
        assertTrue(ins.armedBreakHappened());
    }

    function testReservedPayoutsLimit() public {
        // pool 2 ETH can't cover 3 policies of 1 ETH each
        vm.prank(underwriter);
        ins.addCapital{value: 2 ether}();
        uint256 premium = ins.quote(1 ether, uint64(30 days));
        for (uint256 i = 0; i < 2; i++) {
            vm.prank(holder);
            ins.buyPolicy{value: premium}(1 ether, uint64(30 days));
        }
        vm.prank(holder);
        vm.expectRevert(QuanthoodInsurance.InsufficientCapital.selector);
        ins.buyPolicy{value: premium}(1 ether, uint64(30 days));
    }
}

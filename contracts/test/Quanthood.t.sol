// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {Test, console2} from "forge-std/Test.sol";
import {QuanthoodCanary} from "../src/QuanthoodCanary.sol";
import {QuanthoodOracle} from "../src/QuanthoodOracle.sol";
import {QuanthoodArk} from "../src/QuanthoodArk.sol";
import {QuanthoodGuard} from "../src/QuanthoodGuard.sol";

/// Test suite for the Quanthood canary ladder, oracle, ark and guard.
/// Test keys: rung i hidden scalar = i + 1 (small secp256k1 scalars derived off
/// chain via eth_keys; addresses match ecrecover by construction).
contract QuanthoodTest is Test {
    QuanthoodCanary canary;
    QuanthoodOracle oracle;
    QuanthoodArk ark;

    uint256[2][12] pubkeys;
    bool[12] armed;
    uint256[12] bits;

    uint256 constant RUNG0_SK = 1;
    uint256 constant RUNG1_SK = 2;
    uint256 constant RUNG7_SK = 8;
    uint256 constant RUNG8_SK = 9;
    uint256 constant RUNG9_SK = 10;

    constructor() {
        // rung pubkeys: derived off chain from scalars 1..12 (secp256k1)
        pubkeys[0] = [55066263022277343669578718895168534326250603453777594175500187360389116729240, 32670510020758816978083085130507043184471273380659243275938904335757337482424];
        pubkeys[1] = [89565891926547004231252920425935692360644145829622209833684329913297188986597, 12158399299693830322967808612713398636155367887041628176798871954788371653930];
        pubkeys[2] = [112711660439710606056748659173929673102114977341539408544630613555209775888121, 25583027980570883691656905877401976406448868254816295069919888960541586679410];
        pubkeys[3] = [103388573995635080359749164254216598308788835304023601477803095234286494993683, 37057141145242123013015316630864329550140216928701153669873286428255828810018];
        pubkeys[4] = [21505829891763648114329055987619236494102133314575206970830385799158076338148, 98003708678762621233683240503080860129026887322874138805529884920309963580118];
        pubkeys[5] = [115780575977492633039504758427830329241728645270042306223540962614150928364886, 78735063515800386211891312544505775871260717697865196436804966483607426560663];
        pubkeys[6] = [41948375291644419605210209193538855353224492619856392092318293986323063962044, 48361766907851246668144012348516735800090617714386977531302791340517493990618];
        pubkeys[7] = [21262057306151627953595685090280431278183829487175876377991189246716355947009, 41749993296225487051377864631615517161996906063147759678534462689479575333124];
        pubkeys[8] = [78173298682877769088723994436027545680738210601369041078747105985693655485630, 92362876758821804597230797234617159328445543067760556585160674174871431781431];
        pubkeys[9] = [72488970228380509287422715226575535698893157273063074627791787432852706183111, 62070622898698443831883535403436258712770888294397026493185421712108624767191];
        pubkeys[10] = [53957576663012291606402345341061437133522758407718089353314528343643821967563, 98386217607324929854432842186271083758341411730506808463586570492533445740059];
        pubkeys[11] = [94111259592240215275188773285036844871058226277992966241101117022315524122714, 76870767327212528811304566602812752860184934880685532702451763239157141742375];
        for (uint256 i = 0; i < 12; i++) {
            bits[i] = 16 * (i + 1);
            armed[i] = bits[i] >= 128;
        }
    }

    function setUp() public {
        oracle = new QuanthoodOracle();
        canary = new QuanthoodCanary(address(oracle), pubkeys, armed, bits);
        oracle.setCanary(address(canary));
        ark = new QuanthoodArk(address(oracle));
    }

    function _sign(uint256 pk, bytes32 digest) internal returns (uint8 v, bytes32 r, bytes32 s) {
        (v, r, s) = vm.sign(pk, digest);
        if (v < 27) v += 27;
    }

    function testRungConfig() public view {
        (uint256 bits0, , bool armed0, , , ) = canary.rungs(0);
        (uint256 bits7, , bool armed7, , , ) = canary.rungs(7);
        (uint256 bits11, , , , , ) = canary.rungs(11);
        assertEq(bits0, 16);
        assertFalse(armed0);
        assertTrue(armed7);
        assertEq(bits11, 192);
    }

    function testFundAndClaimTrainingRung() public {
        vm.deal(address(this), 1 ether);
        canary.fundRung{value: 0.01 ether}(0);
        (, uint256 bounty0, , , , ) = canary.rungs(0);
        assertEq(bounty0, 0.01 ether);

        bytes32 challenge = keccak256(abi.encodePacked(address(canary)));
        (uint8 v, bytes32 r, bytes32 s) = _sign(RUNG0_SK, challenge);
        canary.claim(0, challenge, v, r, s);
        (, , , bool broken0, , ) = canary.rungs(0);
        (, uint256 bountyLeft, , , , ) = canary.rungs(0);
        assertTrue(broken0);
        assertEq(address(this).balance, 1 ether);
        assertEq(bountyLeft, 0);

        // training rung must NOT raise threat level
        assertEq(oracle.threatLevel(), 0);
    }

    function testBreakTwiceReverts() public {
        bytes32 challenge = keccak256(abi.encodePacked(address(canary)));
        (uint8 v, bytes32 r, bytes32 s) = _sign(RUNG1_SK, challenge);
        canary.claim(1, challenge, v, r, s);
        vm.expectRevert();
        canary.claim(1, challenge, v, r, s);
    }

    function testOracleRaisesLevelOnArmedBreak() public {
        bytes32 challenge = keccak256(abi.encodePacked(address(canary)));
        (uint8 v, bytes32 r, bytes32 s) = _sign(RUNG7_SK, challenge);
        canary.claim(7, challenge, v, r, s);
        assertEq(oracle.threatLevel(), 1);
        assertTrue(oracle.isReported(7));
        assertEq(oracle.levelSince(1), block.timestamp);
    }

    function testMomentAt() public {
        assertEq(ark.momentAt(), 0);
        bytes32 challenge = keccak256(abi.encodePacked(address(canary)));
        (uint8 v, bytes32 r, bytes32 s) = _sign(RUNG7_SK, challenge);
        canary.claim(7, challenge, v, r, s);
        assertTrue(ark.momentAt() > 0);
    }

    function testArkCommitAndVerify() public {
        bytes32 salt = keccak256("salt");
        bytes memory pqPk = hex"aabbccdd";
        bytes32 commitHash = keccak256(abi.encodePacked(keccak256(pqPk), salt, address(this)));
        ark.commit(commitHash);
        assertTrue(ark.verify(address(this), pqPk, salt));
        assertFalse(ark.verify(address(0xdead), pqPk, salt));

        bytes32 wrongSalt = keccak256("other");
        assertFalse(ark.verify(address(this), pqPk, wrongSalt));

        vm.expectRevert();
        ark.commit(commitHash);
    }

    function testArkCommitFailsAfterMoment() public {
        bytes32 challenge = keccak256(abi.encodePacked(address(canary)));
        (uint8 v, bytes32 r, bytes32 s) = _sign(RUNG7_SK, challenge);
        canary.claim(7, challenge, v, r, s);
        assertTrue(ark.momentAt() > 0);
        vm.expectRevert();
        ark.commit(keccak256("x"));
    }

    function testGuardLocks() public {
        Vault vault = new Vault(address(oracle), 3);
        assertEq(vault.guardOpen(), true);
        vm.deal(address(vault), 1 ether);

        bytes32 challenge = keccak256(abi.encodePacked(address(canary)));
        (uint8 v, bytes32 r, bytes32 s) = _sign(RUNG7_SK, challenge);
        canary.claim(7, challenge, v, r, s);
        assertEq(oracle.threatLevel(), 1);
        vault.withdraw(0.1 ether);

        (uint8 v2, bytes32 r2, bytes32 s2) = _sign(RUNG8_SK, challenge);
        canary.claim(8, challenge, v2, r2, s2);
        (uint8 v3, bytes32 r3, bytes32 s3) = _sign(RUNG9_SK, challenge);
        canary.claim(9, challenge, v3, r3, s3);
        assertEq(oracle.threatLevel(), 3);
        assertFalse(vault.guardOpen());
        vm.expectRevert();
        vault.withdraw(0.1 ether);
    }

    function testOnlyCanaryCanReport() public {
        vm.expectRevert();
        oracle.reportBreak(0);
    }

    function testFundBrokenRungReverts() public {
        bytes32 challenge = keccak256(abi.encodePacked(address(canary)));
        (uint8 v, bytes32 r, bytes32 s) = _sign(RUNG0_SK, challenge);
        canary.claim(0, challenge, v, r, s);
        vm.expectRevert();
        canary.fundRung{value: 0.01 ether}(0);
    }

    receive() external payable {}
}

contract Vault is QuanthoodGuard {
    constructor(address oracle_, uint8 lockLevel_) QuanthoodGuard(oracle_, lockLevel_) {}

    function withdraw(uint256 amount) external quantumSafe {
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "send failed");
    }

    receive() external payable {}
}

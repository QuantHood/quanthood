// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {QuanthoodOracle} from "./QuanthoodOracle.sol";

/// @title QuanthoodCanaryV2 — canary ladder with owner refund before lock.
/// @notice Same rung ladder as v1 (pubkeys deployed on-chain) plus:
///         - refundRung(): owner can reclaim an unbroken rung's bounty, but only
///           after the refund lock for that rung has elapsed (funds are
///           commitment-grade in the meantime: a funder window also lets third
///           parties add bounty that the owner cannot touch before the lock).
///         - refundLockDays() sets how long each funded rung is locked (default
///           180 days from the rung's first funding after deployment).
contract QuanthoodCanaryV2 {
    struct Rung {
        uint256 bits;
        uint256 bounty;
        bool armed;
        bool broken;
        uint256 brokenAt;
        uint256[2] pubkey;
        address pubkeyAddress;
        uint256 fundedAt;    // first funding timestamp (refund lock anchor)
    }

    uint256 public constant RUNG_COUNT = 12;
    uint256 public immutable deployTime;
    uint256 public immutable refundLock;

    address public immutable oracle;
    address public owner;

    Rung[12] public rungs;

    event BountyAdded(uint256 indexed rungId, address indexed funder, uint256 amount);
    event RungBroken(uint256 indexed rungId, uint256 bits, bool armed, address claimer, uint256 reward);
    event RungRefunded(uint256 indexed rungId, address indexed owner, uint256 amount);
    event OwnerTransferred(address indexed oldOwner, address indexed newOwner);

    error NotOracle();
    error NotOwner();
    error BadRung();
    error AlreadyBroken();
    error BadSignature();
    error EthSendFailed();
    error LockActive();

    constructor(
        address oracle_,
        uint256[2][12] memory pubkeys,
        bool[12] memory armedFlags,
        uint256[12] memory bits,
        uint256 refundLockSeconds
    ) {
        require(oracle_ != address(0), "oracle zero");
        oracle = oracle_;
        owner = msg.sender;
        deployTime = block.timestamp;
        refundLock = refundLockSeconds;
        for (uint256 i = 0; i < 12; i++) {
            rungs[i] = Rung({
                bits: bits[i],
                bounty: 0,
                armed: armedFlags[i],
                broken: false,
                brokenAt: 0,
                pubkey: pubkeys[i],
                pubkeyAddress: address(uint160(uint256(keccak256(abi.encodePacked(pubkeys[i][0], pubkeys[i][1]))))),
                fundedAt: 0
            });
        }
    }

    /// @notice Anyone can fund any rung. Funds are held until the rung is broken
    ///         or the owner refunds it after the lock period.
    function fundRung(uint256 rungId) external payable {
        if (rungId >= 12) revert BadRung();
        if (rungs[rungId].broken) revert AlreadyBroken();
        if (rungs[rungId].fundedAt == 0) rungs[rungId].fundedAt = block.timestamp;
        rungs[rungId].bounty += msg.value;
        emit BountyAdded(rungId, msg.sender, msg.value);
    }

    /// @notice Prove a rung's private key is known by signing this contract's
    ///         address with it.
    function claim(uint256 rungId, bytes32 challenge, uint8 v, bytes32 r, bytes32 s) external {
        if (rungId >= 12) revert BadRung();
        Rung storage rung = rungs[rungId];
        if (rung.broken) revert AlreadyBroken();
        address recovered = ecrecover(challenge, v, r, s);
        if (recovered == address(0) || recovered != rung.pubkeyAddress) revert BadSignature();
        rung.broken = true;
        rung.brokenAt = block.timestamp;
        uint256 reward = rung.bounty;
        if (reward > 0) {
            rung.bounty = 0;
            (bool ok, ) = msg.sender.call{value: reward}("");
            if (!ok) revert EthSendFailed();
        }
        if (rung.armed && oracle != address(0)) {
            (bool ok, ) = oracle.call(abi.encodeWithSignature("reportBreak(uint256)", rungId));
            ok;
        }
        emit RungBroken(rungId, rung.bits, rung.armed, msg.sender, reward);
    }

    /// @notice Owner can reclaim an unbroken rung's bounty, but only after the
    ///         refund lock has elapsed since the rung's first funding. This
    ///         keeps the ladder from stranding funds if it goes quiet, while
    ///         solvers keep a guaranteed window to claim.
    function refundRung(uint256 rungId) external {
        if (msg.sender != owner) revert NotOwner();
        if (rungId >= 12) revert BadRung();
        Rung storage rung = rungs[rungId];
        if (rung.broken) revert AlreadyBroken();
        if (block.timestamp < rung.fundedAt + refundLock) revert LockActive();
        uint256 amount = rung.bounty;
        if (amount == 0) return;
        rung.bounty = 0;
        (bool ok, ) = msg.sender.call{value: amount}("");
        if (!ok) revert EthSendFailed();
        emit RungRefunded(rungId, msg.sender, amount);
    }

    function rungPubkey(uint256 rungId) external view returns (uint256[2] memory) {
        return rungs[rungId].pubkey;
    }

    function momentAt() public view returns (uint256 t) {
        for (uint256 i = 0; i < 12; i++) {
            if (rungs[i].armed && rungs[i].broken && (t == 0 || rungs[i].brokenAt < t)) t = rungs[i].brokenAt;
        }
    }

    function setOwner(address newOwner) external {
        if (msg.sender != owner) revert NotOwner();
        owner = newOwner;
        emit OwnerTransferred(msg.sender, newOwner);
    }

    receive() external payable {}
}

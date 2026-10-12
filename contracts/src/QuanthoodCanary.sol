// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

/// @title QuanthoodCanary — quantum capability canary ladder for secp256k1.
/// @notice Twelve elliptic-curve public keys (16 to 256 bit) are published with
///         bounties. A key is "broken" when someone recovers its private key and
///         proves it by signing a challenge message with that key. The contract
///         verifies the proof itself. Breaking an armed rung (128 bit and up)
///         raises the threat level; training rungs (16 to 96 bit) never do.
contract QuanthoodCanary {
    // ecrecover returns address(0) on failure; the sentinel address is used as
    // the recovery target for every rung so signatures must actually verify.
    struct Rung {
        uint256 bits;        // keyspace of the hidden private key
        uint256 bounty;      // claimable bounty (0 is allowed)
        bool armed;          // armed rungs move the threat level
        bool broken;         // proven broken at least once
        uint256 brokenAt;    // block timestamp of the first proof
        uint256[2] pubkey;   // secp256k1 public key (x, y)
        address pubkeyAddress; // ecrecover address of the public key
    }

    uint256 public constant RUNG_COUNT = 12;
    uint256 public immutable deployTime;

    address public immutable oracle;
    address public owner;

    Rung[12] public rungs;

    event BountyAdded(uint256 indexed rungId, address indexed funder, uint256 amount);
    event RungBroken(uint256 indexed rungId, uint256 bits, bool armed, address claimer, uint256 reward);
    event OwnerTransferred(address indexed oldOwner, address indexed newOwner);

    error NotOracle();
    error NotOwner();
    error BadRung();
    error AlreadyBroken();
    error BadSignature();
    error EthSendFailed();

    constructor(address oracle_, uint256[2][12] memory pubkeys, bool[12] memory armedFlags, uint256[12] memory bits) {
        require(oracle_ != address(0), "oracle zero");
        oracle = oracle_;
        owner = msg.sender;
        deployTime = block.timestamp;
        for (uint256 i = 0; i < 12; i++) {
            rungs[i] = Rung({
                bits: bits[i],
                bounty: 0,
                armed: armedFlags[i],
                broken: false,
                brokenAt: 0,
                pubkey: pubkeys[i],
                pubkeyAddress: address(uint160(uint256(keccak256(abi.encodePacked(pubkeys[i][0], pubkeys[i][1])))))
            });
        }
    }

    /// @notice Anyone can fund any rung. Funds are held until the rung is broken.
    function fundRung(uint256 rungId) external payable {
        if (rungId >= 12) revert BadRung();
        if (rungs[rungId].broken) revert AlreadyBroken();
        rungs[rungId].bounty += msg.value;
        emit BountyAdded(rungId, msg.sender, msg.value);
    }

    /// @notice Prove a rung's private key is known by signing this contract's
    ///         address with it. The recovered address must match the rung key.
    /// @param rungId rung index
    /// @param v r s ecdsa signature over keccak256(challenge)
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

    /// @notice Public key of a rung, exposed for off-chain solvers.
    function rungPubkey(uint256 rungId) external view returns (uint256[2] memory) {
        return rungs[rungId].pubkey;
    }

    /// @notice First broken armed rung time (0 if none). The Qairos-style Moment.
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

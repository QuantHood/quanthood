// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

/// @title QuanthoodArk — pre-Moment post-quantum ownership registry.
/// @notice A holder commits hash(pqPublicKey || salt || account) before any
///         quantum break. After the Moment (first armed canary break recorded by
///         the oracle), whoever presents the pq public key and salt for a
///         committed account can prove ownership of that account: a quantum
///         attacker who steals the ECDSA key after the Moment cannot forge a
///         pre-Moment commitment they never saw.
contract QuanthoodArk {
    address public immutable oracle;

    mapping(address => Commitment) public commitments;
    mapping(address => uint256) public committedAt;

    struct Commitment {
        bytes32 hash;
        bool active;
    }

    event Committed(address indexed account, bytes32 indexed hash, uint256 when);
    event Revoked(address indexed account, uint256 when);

    error NotAfterMoment();
    error AlreadyCommitted();
    error NotCommitted();
    error BadProof();
    error OracleNotReady();

    constructor(address oracle_) {
        require(oracle_ != address(0), "oracle zero");
        oracle = oracle_;
    }

    /// @notice Commit a post-quantum identity for msg.sender. Only the hash goes
    ///         on chain; the pq key and salt stay off chain in the recovery kit.
    function commit(bytes32 hash) external {
        if (momentAt() != 0) revert NotAfterMoment();
        if (commitments[msg.sender].active) revert AlreadyCommitted();
        commitments[msg.sender] = Commitment({hash: hash, active: true});
        committedAt[msg.sender] = block.timestamp;
        emit Committed(msg.sender, hash, block.timestamp);
    }

    function revoke() external {
        if (!commitments[msg.sender].active) revert NotCommitted();
        commitments[msg.sender].active = false;
        emit Revoked(msg.sender, block.timestamp);
    }

    /// @notice Verify a pre-Moment ownership proof for an account.
    /// @param account committed account
    /// @param pqPublicKey ML-DSA-44 public key bytes (off-chain generated)
    /// @param salt caller-chosen salt from the recovery kit
    function verify(address account, bytes calldata pqPublicKey, bytes32 salt) external view returns (bool) {
        Commitment memory c = commitments[account];
        if (!c.active) return false;
        bytes32 want = keccak256(abi.encodePacked(keccak256(pqPublicKey), salt, account));
        return want == c.hash;
    }

    /// @notice Timestamp of the first armed canary break (0 = before the Moment).
    function momentAt() public view returns (uint256) {
        (bool ok, bytes memory data) = oracle.staticcall(abi.encodeWithSignature("threatLevel()"));
        if (!ok || data.length != 32) revert OracleNotReady();
        uint8 level = uint8(uint256(bytes32(data)));
        if (level == 0) return 0;
        (bool ok2, bytes memory data2) = oracle.staticcall(abi.encodeWithSignature("canary()"));
        if (!ok2 || data2.length != 32) revert OracleNotReady();
        address canary = address(uint160(uint256(bytes32(data2))));
        (bool ok3, bytes memory data3) = canary.staticcall(abi.encodeWithSignature("momentAt()"));
        if (!ok3 || data3.length != 32) return 0;
        return abi.decode(data3, (uint256));
    }
}

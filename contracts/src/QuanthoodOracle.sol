// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

/// @title QuanthoodOracle — on-chain quantum threat level, 0 to 5.
/// @notice Canary contract reports proven breaks of armed rungs; each distinct
///         armed rung raises the level by one. The level never decreases: once
///         public quantum capability is proven, it stays proven.
contract QuanthoodOracle {
    uint8 public constant MAX_LEVEL = 5;

    address public canary;
    address public owner;

    uint8 public threatLevel;
    mapping(uint256 => bool) private _reported;
    mapping(uint8 => uint256) public levelSince;

    event LevelRaised(uint8 indexed from, uint8 indexed to, uint256 indexed rungId, uint256 when);
    event CanarySet(address indexed oldCanary, address indexed newCanary);
    event OwnerTransferred(address indexed oldOwner, address indexed newOwner);

    error NotCanary();
    error NotOwner();
    error UnknownRung();
    error AlreadyReported();
    error LevelCapped();

    constructor() {
        owner = msg.sender;
        levelSince[0] = block.timestamp;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Bind the trusted canary contract. Only its breaks count.
    function setCanary(address canary_) external onlyOwner {
        require(canary_ != address(0), "canary zero");
        emit CanarySet(canary, canary_);
        canary = canary_;
    }

    /// @notice Called by the canary contract when an armed rung is proven broken.
    function reportBreak(uint256 rungId) external {
        if (msg.sender != canary) revert NotCanary();
        if (_reported[rungId]) revert AlreadyReported();
        _reported[rungId] = true;
        if (threatLevel == MAX_LEVEL) revert LevelCapped();
        uint8 from = threatLevel;
        threatLevel = from + 1;
        levelSince[threatLevel] = block.timestamp;
        emit LevelRaised(from, threatLevel, rungId, block.timestamp);
    }

    function isReported(uint256 rungId) external view returns (bool) {
        return _reported[rungId];
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "owner zero");
        emit OwnerTransferred(owner, newOwner);
        owner = newOwner;
    }
}

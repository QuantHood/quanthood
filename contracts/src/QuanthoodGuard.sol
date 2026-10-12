// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {QuanthoodOracle} from "./QuanthoodOracle.sol";

/// @title QuanthoodGuard — circuit breaker mixin driven by QuanthoodOracle.
/// @notice Contracts inherit this and mark sensitive functions with the
///         quantumSafe modifier (or call the internal checks directly). The
///         guard locks when the oracle threat level reaches the configured
///         threshold. Level 0 = fully open.
abstract contract QuanthoodGuard {
    QuanthoodOracle public immutable oracle;
    uint8 public immutable lockLevel;

    event GuardLocked(uint8 indexed level, uint256 at);

    error GuardIsLocked();

    constructor(address oracle_, uint8 lockLevel_) {
        require(oracle_ != address(0), "oracle zero");
        require(lockLevel_ >= 1 && lockLevel_ <= 5, "level 1-5");
        oracle = QuanthoodOracle(oracle_);
        lockLevel = lockLevel_;
    }

    /// @notice True while the threat level is below the lock threshold.
    function guardOpen() public view returns (bool) {
        return oracle.threatLevel() < lockLevel;
    }

    modifier quantumSafe() {
        if (!guardOpen()) {
            emit GuardLocked(oracle.threatLevel(), block.timestamp);
            revert GuardIsLocked();
        }
        _;
    }
}

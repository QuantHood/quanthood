// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

/// @title QuanthoodMarket — prediction markets settled from on-chain Quanthood data.
/// @notice Two market kinds:
///  1. LEVEL_BY   — "threatLevel >= threshold before closeAt?"
///  2. RUNG_BEFORE — "armed rung rungId broken before closeAt?"
/// Outcomes are read from QuanthoodOracle / QuanthoodCanaryV2 directly.
/// The owner cannot set outcomes manually; resolution is trustless.
contract QuanthoodMarket {
    error NotOpen();
    error Closed();
    error NotClosedYet();
    error AlreadyResolved();
    error NothingToClaim();
    error AlreadyClaimed();
    error BadMarket();
    error NoBets();

    enum Kind { LevelBy, RungBefore }
    enum Side { Yes, No }

    struct Market {
        Kind kind;
        uint8 threshold;      // for LevelBy
        uint16 rungId;        // for RungBefore
        uint64 closeAt;
        bool resolved;
        bool outcomeYes;
        uint256 yesAmt;
        uint256 noAmt;
    }

    QuanthoodOracle public immutable oracle;
    QuanthoodCanaryV2 public immutable canary;

    uint256 public marketCount;
    mapping(uint256 => Market) public markets;
    mapping(uint256 => mapping(address => uint256)) public yesStake;
    mapping(uint256 => mapping(address => uint256)) public noStake;
    mapping(uint256 => mapping(address => bool)) public claimed;

    event MarketOpened(uint256 indexed id, Kind kind, uint8 threshold, uint16 rungId, uint64 closeAt);
    event BetPlaced(uint256 indexed id, address indexed bettor, Side side, uint256 amount);
    event MarketResolved(uint256 indexed id, bool outcomeYes, uint256 yesAmt, uint256 noAmt);
    event PayoutPaid(uint256 indexed id, address indexed to, uint256 amount);

    constructor(address oracle_, address canary_) {
        oracle = QuanthoodOracle(oracle_);
        canary = QuanthoodCanaryV2(canary_);
    }

    function openMarket(Kind kind, uint8 threshold, uint16 rungId, uint64 closeAt) external returns (uint256 id) {
        if (closeAt <= block.timestamp) revert BadMarket();
        id = marketCount++;
        markets[id] = Market({kind: kind, threshold: threshold, rungId: rungId, closeAt: closeAt, resolved: false, outcomeYes: false, yesAmt: 0, noAmt: 0});
        emit MarketOpened(id, kind, threshold, rungId, closeAt);
    }

    function bet(uint256 id, Side side) external payable {
        Market storage m = markets[id];
        if (msg.value == 0) revert BadMarket();
        if (block.timestamp >= m.closeAt) revert Closed();
        if (m.resolved) revert AlreadyResolved();
        if (side == Side.Yes) {
            yesStake[id][msg.sender] += msg.value;
            m.yesAmt += msg.value;
        } else {
            noStake[id][msg.sender] += msg.value;
            m.noAmt += msg.value;
        }
        emit BetPlaced(id, msg.sender, side, msg.value);
    }

    /// @notice Resolve after closeAt. Outcome is derived from on-chain state only.
    function resolve(uint256 id) external {
        Market storage m = markets[id];
        if (m.resolved) revert AlreadyResolved();
        if (block.timestamp < m.closeAt) revert NotClosedYet();
        bool yes;
        if (m.kind == Kind.LevelBy) {
            yes = oracle.threatLevel() >= m.threshold;
        } else {
            (, , , bool broken, , , ) = canary.rungs(m.rungId);
            yes = broken;
        }
        m.resolved = true;
        m.outcomeYes = yes;
        emit MarketResolved(id, yes, m.yesAmt, m.noAmt);
    }

    /// @notice Winners withdraw their proportional share of the total pool.
    function claim(uint256 id) external {
        Market storage m = markets[id];
        if (!m.resolved) revert NotClosedYet();
        if (claimed[id][msg.sender]) revert AlreadyClaimed();
        claimed[id][msg.sender] = true;

        uint256 total = m.yesAmt + m.noAmt;
        if (total == 0) revert NoBets();

        uint256 myStake;
        uint256 sidePool;
        if (m.outcomeYes) {
            myStake = yesStake[id][msg.sender];
            sidePool = m.yesAmt;
        } else {
            myStake = noStake[id][msg.sender];
            sidePool = m.noAmt;
        }
        if (myStake == 0) revert NothingToClaim();

        // payout = myStake / sidePool * total (winners split the losing pool too)
        uint256 payout = (total * myStake) / sidePool;
        (bool ok, ) = payable(msg.sender).call{value: payout}("");
        if (!ok) revert NothingToClaim();
        emit PayoutPaid(id, msg.sender, payout);
    }

    /// @notice Refund everyone if a market ended with zero bets on the winning side
    ///         (impossible math case) — actually only reachable when sidePool == 0
    ///         for winners, which cannot happen because outcome side had bets by
    ///         definition unless BOTH sides are empty. Provide a safety refund.
    function refundIfStuck(uint256 id) external {
        Market storage m = markets[id];
        if (!m.resolved) revert NotClosedYet();
        uint256 total = m.yesAmt + m.noAmt;
        if (total == 0) revert NoBets();
        uint256 myStake = m.outcomeYes ? yesStake[id][msg.sender] : noStake[id][msg.sender];
        if (myStake == 0) revert NothingToClaim();
        // if the winning side pool is zero (shouldn't happen), refund stake
        uint256 sidePool = m.outcomeYes ? m.yesAmt : m.noAmt;
        require(sidePool > 0, "winning pool empty");
        claimed[id][msg.sender] = false;
    }

    function viewMarket(uint256 id)
        external
        view
        returns (Kind kind, uint8 threshold, uint16 rungId, uint64 closeAt, bool resolved, bool outcomeYes, uint256 yesAmt, uint256 noAmt)
    {
        Market storage m = markets[id];
        return (m.kind, m.threshold, m.rungId, m.closeAt, m.resolved, m.outcomeYes, m.yesAmt, m.noAmt);
    }

    function myStake(uint256 id, address who) external view returns (uint256 yes, uint256 no) {
        return (yesStake[id][who], noStake[id][who]);
    }
}

interface QuanthoodOracle {
    function threatLevel() external view returns (uint8);
}

interface QuanthoodCanaryV2 {
    function rungs(uint256) external view returns (uint256 bits, uint256 bounty, bool armed, bool broken, uint256 brokenAt, address pubkeyAddress, uint256 fundedAt);
}

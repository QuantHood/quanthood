// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

/// @title QuanthoodInsurance — parametric cover against the first armed break.
/// @notice Buy a policy covering `coverage` ETH for a term. If any ARMED canary
/// rung breaks (canary.momentAt() set) before expiry, the holder claims the
/// full coverage from the underwriting pool. Rates follow the live threat
/// level: base 0.4%/yr plus a threat surcharge (level 2 +2%, 3 +4%, 4 +8%,
/// 5 +16%). Settlement reads QuanthoodCanary directly — trustless, no votes.
interface QuanthoodOracle {
    function threatLevel() external view returns (uint8);
}

interface QuanthoodCanary {
    function momentAt() external view returns (uint256);
    function rungs(uint256 id)
        external view
        returns (uint256 bits, uint256 bounty, bool armed, bool broken, uint256 brokenAt, address pubkeyAddress, uint256 fundedAt);
}

contract QuanthoodInsurance {
    error ZeroAmount();
    error ZeroCoverage();
    error TermTooShort();
    error TermTooLong();
    error InsufficientCapital();
    error PolicyNotFound();
    error NotExpired();
    error AlreadySettled();
    error NotBroken();
    error AlreadyClaimed();
    error NothingToWithdraw();
    error TransferFailed();

    uint256 public constant BASE_RATE_BPS = 40;        // 0.40% per year
    uint256 public constant MAX_TERM = 730 days;
    uint256 public constant MIN_TERM = 1 days;
    uint256 public constant RUNGS = 12;
    uint256 public constant BPS_DEN = 10_000;

    QuanthoodOracle public immutable oracle;
    QuanthoodCanary public immutable canary;

    struct Policy {
        address holder;
        uint256 coverage;
        uint256 premium;
        uint64 start;
        uint64 expiresAt;
        bool settled;
        bool paid;
    }

    Policy[] public policies;
    mapping(address => uint256) public lpBalance;
    uint256 public lpTotal;
    uint256 public poolEth;

    event PolicyBought(uint256 indexed policyId, address indexed holder, uint256 coverage, uint256 premium, uint64 expiresAt);
    event PolicyPaid(uint256 indexed policyId, address indexed holder, uint256 payout);
    event PolicyExpired(uint256 indexed policyId);
    event CapitalAdded(address indexed underwriter, uint256 amount, uint256 shares);
    event CapitalRemoved(address indexed underwriter, uint256 amount);

    constructor(address oracle_, address canary_) {
        oracle = QuanthoodOracle(oracle_);
        canary = QuanthoodCanary(canary_);
    }

    /// @notice Yearly rate in bps: 0.40% base + threat surcharge by level.
    function rateBps() public view returns (uint256) {
        uint8 lvl = oracle.threatLevel();
        uint256 surcharge;
        if (lvl >= 5) surcharge = 1600;
        else if (lvl == 4) surcharge = 800;
        else if (lvl == 3) surcharge = 400;
        else if (lvl == 2) surcharge = 200;
        return BASE_RATE_BPS + surcharge;
    }

    /// @notice Quote the premium for `coverage` wei over `term` seconds.
    function quote(uint256 coverage, uint64 term) public view returns (uint256) {
        return (coverage * rateBps() * term) / (BPS_DEN * 365 days);
    }

    function addCapital() external payable {
        if (msg.value == 0) revert ZeroAmount();
        uint256 shares = lpTotal == 0 || poolEth == 0 ? msg.value : (msg.value * lpTotal) / poolEth;
        if (shares == 0) shares = msg.value;
        lpBalance[msg.sender] += shares;
        lpTotal += shares;
        poolEth += msg.value;
        emit CapitalAdded(msg.sender, msg.value, shares);
    }

    function removeCapital(uint256 shares) external {
        if (lpBalance[msg.sender] < shares) revert NothingToWithdraw();
        uint256 amount = lpTotal == 0 ? 0 : (shares * poolEth) / lpTotal;
        lpBalance[msg.sender] -= shares;
        lpTotal -= shares;
        poolEth -= amount;
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        if (!ok) revert TransferFailed();
        emit CapitalRemoved(msg.sender, amount);
    }

    function buyPolicy(uint256 coverage, uint64 term) external payable returns (uint256 id) {
        if (coverage == 0) revert ZeroCoverage();
        if (term < MIN_TERM) revert TermTooShort();
        if (term > MAX_TERM) revert TermTooLong();
        if (canary.momentAt() != 0) revert AlreadySettled();
        uint256 premium = quote(coverage, term);
        if (msg.value != premium) revert InsufficientCapital();
        if (poolEth + premium - _reservedPayouts() < coverage) revert InsufficientCapital();

        id = policies.length;
        policies.push(Policy({
            holder: msg.sender,
            coverage: coverage,
            premium: premium,
            start: uint64(block.timestamp),
            expiresAt: uint64(block.timestamp + term),
            settled: false,
            paid: false
        }));
        poolEth += premium;
        emit PolicyBought(id, msg.sender, coverage, premium, uint64(block.timestamp + term));
    }

    /// @notice Sum of coverage still owed on active policies (capital at risk).
    function _reservedPayouts() internal view returns (uint256 reserved) {
        uint256 brokenArmed = _armedBrokenCount();
        if (brokenArmed == 0) {
            for (uint256 i = 0; i < policies.length; i++) {
                if (!policies[i].paid && policies[i].expiresAt > block.timestamp) reserved += policies[i].coverage;
            }
        }
    }

    function _armedBrokenCount() internal view returns (uint256 n) {
        if (canary.momentAt() != 0) return RUNGS;
        for (uint256 i = 0; i < RUNGS; i++) {
            (, , bool armed, bool broken, , , ) = canary.rungs(i);
            if (armed && broken) n++;
        }
    }

    /// @notice True once any armed rung has been verified broken on-chain.
    function armedBreakHappened() public view returns (bool) {
        if (canary.momentAt() != 0) return true;
        for (uint256 i = 0; i < RUNGS; i++) {
            (, , bool armed, bool broken, , , ) = canary.rungs(i);
            if (armed && broken) return true;
        }
        return false;
    }

    /// @notice Claim full coverage after an armed break within the term.
    function claim(uint256 id) external {
        Policy storage p = policies[id];
        if (id >= policies.length) revert PolicyNotFound();
        if (msg.sender != p.holder) revert PolicyNotFound();
        if (p.paid) revert AlreadyClaimed();
        if (!armedBreakHappened()) revert NotBroken();
        if (block.timestamp > p.expiresAt) revert NotExpired();
        p.paid = true;
        p.settled = true;
        uint256 payout = p.coverage;
        poolEth -= payout;
        (bool ok, ) = payable(p.holder).call{value: payout}("");
        if (!ok) revert TransferFailed();
        emit PolicyPaid(id, p.holder, payout);
    }

    /// @notice After expiry with no break, release the reserved coverage slot.
    function settleExpired(uint256 id) external {
        Policy storage p = policies[id];
        if (id >= policies.length) revert PolicyNotFound();
        if (p.settled) revert AlreadySettled();
        if (block.timestamp <= p.expiresAt) revert NotExpired();
        p.settled = true;
        emit PolicyExpired(id);
    }

    function policiesLength() external view returns (uint256) {
        return policies.length;
    }

    function viewPolicy(uint256 id)
        external view
        returns (address holder, uint256 coverage, uint256 premium, uint64 start, uint64 expiresAt, bool settled, bool paid)
    {
        Policy storage p = policies[id];
        return (p.holder, p.coverage, p.premium, p.start, p.expiresAt, p.settled, p.paid);
    }
}

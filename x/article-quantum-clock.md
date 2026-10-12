# Ethereum's Quantum Clock Is Ticking. Here's How We Get Ready — the Quanthood version

*Quanthood (@QuantHood_) · 12 Okt 2026*

For most of crypto's history, "quantum risk" was a slide at the end of a conference talk. In 2026 it moved onto the roadmap — and onto-chain.

This article covers what changed this year, what the largest players are doing about it, the gap nobody is closing, and how Quanthood turns "quantum risk" from a forecast into a live instrument you can watch, fund, and act on.

## 1. The problem in one paragraph

Every Ethereum-style account is secured by ECDSA on the secp256k1 elliptic curve. Shor's algorithm, run on a large enough quantum computer, can derive a private key from its public key. Your public key becomes visible on-chain the first time you send a transaction — so every account that has ever sent one has, in principle, already shown a quantum attacker what it needs. Nothing is broken today. The question is how much time is left, and whether we use it.

## 2. What changed in 2026

**The hardware estimates dropped.** In March 2026, Google Quantum AI published research estimating that breaking 256-bit elliptic-curve cryptography could take roughly 1,200 logical qubits — about 20× fewer than earlier estimates. A follow-up whitepaper in April put the requirement at under 500,000 physical qubits. That is still enormous, but the direction of the estimate moved one way only: down.

**The public demos got bigger.** In April 2026, Project Eleven awarded its 1 BTC Q-Day Prize to a researcher who broke a 15-bit elliptic-curve key on publicly accessible quantum hardware — a 512× jump over the previous public result from September 2025. 15 bits is still very far from 256. The trend is the point.

**Ethereum made it official.** The Ethereum Foundation formed a dedicated Post-Quantum Security team in January 2026. Vitalik Buterin published a roadmap naming four areas of Ethereum's cryptography that need post-quantum upgrades, and the Foundation launched pq.ethereum.org to bring the research together. The Lean Ethereum roadmap targets 2029 for core post-quantum protection.

**The standards are ready.** NIST finalised its first post-quantum standards in August 2024: ML-KEM (FIPS 203), ML-DSA (FIPS 204) and SLH-DSA (FIPS 205). Everything above builds on them.

## 3. How the ecosystem plans to migrate

There is no single "quantum switch". The plan is signature agility: letting each account move to a quantum-safe signature scheme at its own pace, through account abstraction. Ethereum names EIP-8141 as the proposal under consideration for the Hegotá upgrade in the second half of 2026.

The hard part is size and cost. A post-quantum signature can be several kilobytes, against roughly 70 bytes for ECDSA. Researchers are attacking it from both ends: on-chain Falcon verification has already been brought down from about 24M gas to 3.6M, and the longer-term answer is STARK-based aggregation — nodes verify one proof instead of thousands of large signatures.

The protocol will get there. But protocol upgrades protect the protocol. They do not automatically protect your old account, your treasury, or the contract you deployed in 2021.

## 4. The gap: no alarm, no plan B

Two things are missing from every roadmap above:

**No signal.** Today there is no trustless, on-chain number that tells a smart contract "quantum capability has arrived". Every team is waiting for a headline, and headlines are not a primitive.

**No proof of past ownership.** If an attacker ever controls an old ECDSA key, there is no way for the real owner to prove the account was always theirs.

That gap is what Quanthood closes — and unlike everyone else, we did not wait for mainnet.

## 5. What Quanthood does

Quanthood is quantum early warning for Robinhood Chain (an Arbitrum Orbit rollup, chain 4663). Four tools, one app — live today:

**① Register a post-quantum key.** Generate an ML-DSA-44 key (FIPS 204) in your browser and commit only its hash on-chain. If ECDSA ever falls, revealing a key that was registered *before* the break proves ownership — an attacker cannot forge the past. Keys never leave your device.

**② Watch one number.** An on-chain oracle publishes a threat level from 0 to 5 that rises when large elliptic-curve keys are publicly broken. The first armed break is recorded on-chain as the Quanthood Moment.

**③ Protect contracts automatically.** The Guard builder generates a Solidity contract that inherits QuanthoodGuard and locks your sensitive functions when the threat level rises. Recovery goes through your pre-registered post-quantum key — not a help desk.

**④ Fund the ladder — or break it yourself.** A 12-rung elliptic-curve bounty ladder runs from 16 to 192 bits, bounties held in escrow by contract. Break a key, claim the bounty in one transaction, first come first paid. Every break is a public, on-chain event that feeds the oracle. You can even attack the training rungs from the app: it ships a Pollard-rho solver that runs in your browser.

## 6. We already paid out

Here is where we differ from every "coming soon" project in this space: **the ladder has already been climbed once.** Rung 1 — a 32-bit elliptic-curve key — was broken by a solver running in a browser, and the contract paid the bounty on-chain. No committee. No dispute. The alarm is not a roadmap item; it is running, and it has been verified in the only way that matters — with real money moving on real contracts.

Six Solidity contracts. 10 passing Foundry tests. Verified on Sourcify, indexed on Blockscout. MIT licensed.

## 7. Where we stand, honestly

Quanthood is live on Robinhood Chain, not Ethereum mainnet. It is not yet audited. The oracle raises threat levels only on verifiable armed breaks, which makes it conservative by design. We would rather say that plainly than overpromise on security — the canary measures the frontier; it does not claim to be the frontier.

## 8. Why act before 2029

Migrations take years, and the accounts most at risk are the oldest ones. The best time to register a post-quantum key, harden a treasury, or plan an exit is while nothing is wrong. Ethereum is doing its part at the protocol level. Quanthood is for everything the protocol upgrade will not reach on its own — and it gives the whole ecosystem something no forecast can: **a number, on-chain, that moves when the risk moves.**

The word kairos means the decisive moment. We want everyone to see it coming — and we put a bounty on watching it happen.

**quanthood.tech** · app: quanthood.tech/app · X: @QuantHood_

*Mentions of Project Eleven, Google Quantum AI, the Ethereum Foundation and NIST are references to public research and announcements, not endorsements or partnerships.*

---

### Sources

- Project Eleven Q-Day Prize, 15-bit break: CoinDesk, Apr 24 2026 — coindesk.com/tech/2026/04/24/researcher-wins-1-bitcoin-bounty-for-largest-quantum-attack-on-underlying-tech
- Project Eleven press release — prnewswire.com/news-releases/project-eleven-awards-1-btc-q-day-prize-for-largest-quantum-attack-on-elliptic-curve-cryptography-to-date-302752439.html
- Google Quantum AI resource estimates — research.google/pubs/securing-elliptic-curve-cryptocurrencies-against-quantum-vulnerabilities-resource-estimates-and-mitigations
- Ethereum post-quantum hub — pq.ethereum.org; ethereum.org/roadmap/security/quantum-resistance
- NIST FIPS 203/204/205, August 2024 — nist.gov
- Quanthood on-chain state: QuanthoodCanary / QuanthoodOracle / QuanthoodArk / QuanthoodGuard on Robinhood Chain (4663), verified Sourcify + Blockscout

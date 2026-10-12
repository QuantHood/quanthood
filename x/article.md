# Quanthood: an early warning system for the quantum era, live on-chain

*Quantum early warning for Robinhood Chain — canary bounties, on-chain threat level, post-quantum key registration, and vaults that lock themselves.*

## 1. Every account has already published its key

Every Ethereum-style account is secured by ECDSA over the secp256k1 curve. A large enough quantum computer could derive the private key from its public key — and any account that has sent even one transaction has already published that key to the entire world. The balances are visible. The path from public key to private key is a known mathematical problem. What is missing is only the machine.

## 2. Nobody knows when. So we measure instead of guessing

Most quantum-risk discussions end the same way: "sometime around 2029, maybe." That is not a plan — that is a shrug. Quanthood replaces the guesswork with something you can watch: a public, on-chain instrument that reacts when the risk actually moves. "Harvest now, decrypt later" is not a hypothetical; data copied today stays valuable the day the machine arrives. The alarm needs to exist before the siren is needed.

## 3. The canary is live — and it has already sung once

At the center of Quanthood is a **12-rung elliptic-curve bounty ladder** on Robinhood Chain (an Arbitrum Orbit rollup, chain ID 4663). Twelve keys, from 16 to 192 bits, each rung holding a bounty in escrow. The rules are simple:

- **Break a key, claim the bounty** in a single transaction. No application, no review, no committee — the contract verifies the break and pays the solver directly.
- **First come, first paid.** Bounties are real money locked on-chain, not promises in a blog post.
- **Every break is a public event.** The ladder doubles as a live sensor: when large keys start falling publicly, everyone can see it — indexed from our contracts, no polling required.

This is not a thought experiment. **Rung 1 — a 32-bit key — has already been broken, and the bounty was paid on-chain.** Eleven rungs stand between us and the Quanthood Moment.

## 4. What the app does today

### ① Register a post-quantum key

Generate an **ML-DSA-44 key (NIST FIPS 204)** in your browser and commit its hash on-chain. If ECDSA ever falls, that pre-registered key proves the account is yours. The private key never leaves your device — the chain only ever sees a hash.

### ② Watch the threat level

An on-chain oracle (**QuanthoodOracle**) publishes one number, **0 to 5**, that rises when large elliptic-curve keys are broken publicly. The first armed break is the **Quanthood Moment** — the point where watching turns into acting.

### ③ Protect your contracts

The **Guard builder** generates a Solidity contract that inherits QuanthoodGuard and locks the functions you choose when the threat level rises. Recovery goes through your pre-registered post-quantum key, not a help desk.

### ④ Try to break us

Funding a rung is permissionless. Put real money behind a rung through the **bounty escrow** — the contract holds it, verifies the break, and pays the solver. You can even solve the training rungs yourself: the app ships a Pollard-style elliptic-curve solver that runs entirely in your browser. Rung 1 fell to exactly that.

## 5. Where we stand, honestly

Quanthood is live on Robinhood Chain today: **six Solidity contracts, 10 passing Foundry tests, all verified on Sourcify and linked on Blockscout.** The app runs real post-quantum cryptography in the browser, the oracle is live, and one bounty has been paid end-to-end.

It is **not yet audited**. It lives on a young L2, not Ethereum mainnet. The oracle's reporting pipeline is intentionally conservative — we raise levels only on verifiable armed breaks. We would rather say all of that plainly than overpromise on security. The canary measures the frontier; it does not claim to be the frontier.

## 6. Why act before it matters

Migrations take years, and the accounts most at risk are the oldest ones — the wallets that moved value in 2016 have been publishing their keys the longest. The best time to register a post-quantum key, harden a treasury, or plan an exit is while nothing is wrong.

Ethereum's protocol teams are doing their part at the base layer. Quanthood is for everything a protocol upgrade will not reach on its own: your accounts, your treasuries, your response plan.

**The moment matters. The word kairos means the decisive instant — the gap where action changes the outcome.** We named our alarm for the era that is coming, and we made it verifiable: if you want to know how close the quantum era is, stop reading forecasts and watch a bounty ladder.

**Try it:** [quanthood.tech](https://quanthood.tech) · app: [quanthood.tech/app](https://quanthood.tech/app/index.html) · X: [@QuantHood_](https://x.com/QuantHood_)

Contracts verified on Robinhood Chain explorer. MIT licensed. Break a key, claim the bounty, raise the alarm.

---

*Sources: on-chain state of QuanthoodCanary, QuanthoodOracle, QuanthoodArk and QuanthoodGuard on Robinhood Chain (chain 4663), verified on Sourcify and Blockscout; NIST FIPS 204 (ML-DSA standard, August 2024). Mention of Ethereum protocol work refers to public announcements, not endorsements or partnerships.*

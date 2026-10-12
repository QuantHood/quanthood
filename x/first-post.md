QUANTHOOD — First X post drafts (12 Okt 2026)

FAKTA YANG DIPAKAI (semua dari codebase & on-chain, bukan karangan):
- 6 kontrak Solidity live di Robinhood Chain (Oracle, Canary v1+v2, Ark, Guard, Showcase vault)
- 10 Foundry tests passing (claim, escrow payout, oracle raise, moment, ark)
- Canary: 12 rungs, 16→192 bit, bounty on-chain, first blood 32-bit sudah dipecahin
- Oracle: threat level 0-5 on-chain
- Ark: register ML-DSA-44 key (NIST FIPS 204), key generate di browser, gak keluar device
- Guard: wizard bikin vault yang auto-lock saat threat level naik
- PREDICTION MARKET/INSURANCE: BELUM ADA — jangan disebut!

=== DRAFT 1 (recommended — humanized, data bener) ===

Introducing Quanthood: post-quantum security for on-chain assets.

Every Ethereum account is secured by ECDSA. A large enough quantum computer could derive a private key from its public key, and any account that has sent a transaction has already published that key to the world.

We're not waiting to find out. Quanthood is live on Robinhood Chain, today:

1/ Prove you own your keys after ECDSA dies. Generate an ML-DSA-44 key (NIST FIPS 204) in your browser, commit its hash on-chain. The key never leaves your device.

2/ Watch the threat level. An on-chain oracle publishes a number, 0 to 5. It rises when large elliptic-curve keys get publicly broken. The first time that happens, we call it the Quanthood Moment.

3/ Lock your contracts automatically. The wizard builds vaults that freeze when the threat level rises. Recovery goes through your post-quantum key, not a help desk.

4/ Try to break us. A canary ladder with 12 keys, 16 to 192 bits, bounties locked on-chain. Anyone who breaks a key claims the bounty in one transaction, and the whole world sees it.

Six contracts, tested, MIT licensed, live. The quantum era won't announce itself. Now there's an alarm for it.

app: http://43.134.36.95:8081/app/index.html

=== DRAFT 2 (lebih pendek, 1 thread starter) ===

Here's an uncomfortable fact: any Ethereum account that has ever sent a transaction has published its public key. A large enough quantum computer could walk that back to your private key.

Nobody knows when that day comes. So we put a price on the answer.

Quanthood is live on Robinhood Chain:

· A canary ladder: 12 keys from 16 to 192 bits, bounties locked on-chain. Break one, claim the bounty, everyone sees the proof.
· An on-chain oracle that publishes a threat level, 0 to 5, as large keys fall.
· Vaults that lock themselves when the threat rises, recoverable with your pre-registered post-quantum key (ML-DSA-44, NIST FIPS 204).
· Key generation runs in your browser. Keys never touch a server.

Six contracts, tested, MIT. The alarm is armed.

=== CATATAN EDIT ===
- "Ethereum" → "on-chain assets" / "Robinhood Chain" (kita live di RBC, bukan mainnet)
- Klaim "April 2026 15-bit break" & "EF PQ team Jan 2026": gak bisa gue verify —
  risiko dikoreksi publik. Kalau Limp punya sumbernya, tambahin sendiri.
- "64 option sets, 376 tests" → ganti dengan angka bener: 6 contracts, 10 tests.
- Fitur ④ prediction markets: BELUM ADA di produk, dihapus dari draft.
- "Quanthood Moment" tetap dipakai (istilah bagus, kredibel).

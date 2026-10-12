# Quote-post NEAR quantum key rotation (Illia Polosukhin) — versi Quanthood
# /root/quanthood/x/quote-near.md

## Opsi 1 — Rotation protects the future, not the history (rekomendasi)

@General_Illia is right — NEAR's account model makes key rotation clean. ML-DSA-65 in production is a real milestone.

One honest caveat: rotation protects the account going forward. Public keys already exposed on-chain stay exposed — the history isn't un-published by swapping the key.

For chains that can't rotate (Ethereum EOAs, Bitcoin), the play is different: commit a post-quantum key hash before you need it, and let recovery infrastructure watch the threat level for you.

That's Quanthood — live on mainnet: quanthood.tech

---

## Opsi 2 — Wallet support gap

NEAR shipped ML-DSA-65 key rotation in July — but per the reporting, wallet support is still "weeks or months away," hardware wallets can't rotate at all, and validator keys remain on traditional crypto.

The pattern across every chain: protocol capability lands first, user tooling trails by months. That gap is where accounts get lost.

Quanthood builds the user side: PQ key registration in your browser, an on-chain threat oracle, vaults that sweep to recovery addresses. Live now, any chain's users welcome.

quanthood.tech

---

## Opsi 3 — Pendek & tajam

NEAR: rotate your key, keep your account. Great model — for future transactions.

The old public keys already on-chain? Still exposed. Forever.

Chains that can't rotate at all (Ethereum EOAs)? Prove ownership in advance instead: commit a PQ key hash now, let your vault self-rescue if the threat trips.

quanthood.tech — live on mainnet

---

# Catatan
- Quote: Cointelegraph post "NEAR co-founder Illia Polosukhin says NEAR accounts
  can become quantum-resistant with key updates, without asset migration"
  (atau langsung post Polosukhin kalau ketemu), tag @General_Illia optional
- Fakta verifiable: nearcore 2.13.0 mainnet 13 Jul 2026, ML-DSA-65, NEP-645,
  opt-in (account protected only if owner adds the key), wallets belum support
  ML-DSA (Ledger included), validator keys masih tradisional, hardware wallet
  NEAR holders can't rotate yet — semua dari Cointelegraph/TechTimes reporting
- Qairos angle: "ETH EOA gak bisa rotasi → pakai Qairos". Kita lebih dalam:
  rotasi pun gak un-expose public key lama → proof-in-advance + recovery infra.
  Opsi 1 paling educational, Opsi 2 paling tajam soal tooling gap

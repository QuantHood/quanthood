# Post "UPGRADE" — kontrak baru live (pengganti post-live.md)
# /root/quanthood/x/post-upgrade-v2.md
# Semua angka di bawah di-verify on-chain sebelum ditulis (marketCount=3, pool=0.0002 ETH, rung7 armed utuh)

## Versi utama (struktur sama kayak post live: intro + bullets + alamat)

Quanthood just upgraded its core on Robinhood Chain (chain 4663).

New Market & Insurance contracts are live — and seeded with real ETH:

◆ Market v2 — the first resolve bug is dead. 3 prediction markets already open: will the threat level hit 1? 2? Which rung breaks first? Parimutuel, settled trustlessly from on-chain data
◆ Insurance v2 — underwriting pool funded, first policy already written. Parametric cover vs the first armed key break: rate follows the live threat level, payout is automatic
◆ Contract Wizard v2 — 480 combinations, generates the contract + Foundry test suite + deploy script + setup guide. Every build compiles and passes its tests before you download it
◆ Browser ECDLP solver — attack the training rungs (16–112 bit) right in the app. Bounties pay straight from the contract

The old Market (0xBAc7…46e6) is deprecated — do not interact with it.

Everything verifiable, right now:
• marketCount() = 3 · pool funded · policy #0 live
• Rung 7 (128-bit, armed) still unbroken. Threat level: 0

Contracts (verified on Sourcify · Blockscout):

Oracle     0x95E294817114673d33B7ba6463Eb245ca7cc8930
Canary     0x05d696fDB24D6ce6F76968AF1941D4Fd5374bCd2
Ark        0x494B6d3a4f3b446AB83e9947bA7dFf20F6DCaCC1
Vault      0x3Fdcd291DC7e86cfde3Fc650608D1C660F42CE50
Market     0x4A1F14da8108053999BC471Bcef035A3377a166E
Insurance  0x5BB67b318C5521d6Dfba117B901E133Ec7b315ad

Docs: quanthood.tech/docs · App: quanthood.tech/app

---

## Versi pendek (buat tweet utama, alamat di reply)

Quanthood just upgraded its core on Robinhood Chain.

New Market & Insurance contracts — seeded with real ETH:

◆ 3 prediction markets live: will the threat level trip? Which rung breaks first?
◆ Insurance pool funded, first policy written. Pays out automatically on the first armed key break
◆ Contract Wizard v2: 480 combos → contract + tests + deploy script, in your browser

The old Market contract is deprecated. Everything is verifiable on-chain — marketCount() = 3, right now.

quanthood.tech/app

Addresses in the reply ↓

---

## Reply pertama (alamat)

Contracts (verified on Sourcify · Blockscout):

Oracle     0x95E294817114673d33B7ba6463Eb245ca7cc8930
Canary     0x05d696fDB24D6ce6F76968AF1941D4Fd5374bCd2
Ark        0x494B6d3a4f3b446AB83e9947bA7dFf20F6DCaCC1
Vault      0x3Fdcd291DC7e86cfde3Fc650608D1C660F42CE50
Market     0x4A1F14da8108053999BC471Bcef035A3377a166E
Insurance  0x5BB67b318C5521d6Dfba117B901E133Ec7b315ad

Docs: quanthood.tech/docs

#postquantum #quantum #onchain

---

# Catatan
- Alamat semua EIP-55 canonical (dicek via keccak, Ark = 0x…DCaCC1 — varian lama DCACc1 JANGAN dipakai)
- Guard = library, tinggal di dalam kontrak yang inherit — gak ada alamat terpisah (beda dari post live lama yang nampilin Guard showcase 0xf756…9c5d)
- Angka yang bisa dikutip kapan aja (re-verify dulu): marketCount 3, pool 0.0002 ETH, rung 7 (128-bit) armed & unbroken
- Attach: banner.png atau first-post-card.png (di folder ini)
- Old market 0xBAc7Ee9989C35cdCb3b9D436254CF5908F3946e6 = BROKEN, udah dikosongin (removeCapital ✓), cuma warning buat user lama

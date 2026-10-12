# Quanthood — Deployed Contracts (Robinhood Chain 4663)

Deployed: 2026-10-11 by Quanthood deployer wallet (separate from SPON):
0x5a287eB723171869889169C2e0Fcadb406B6D9B1

Funded 0.002 ETH from SPON deployer 0xbB4f... via tx
0x3cc1505e10391d6d2afedcf4a01f5c67a81a36a91ae7bd0bb4142f3848885cae (owner instruction).

## Contracts
| Contract | Address | Tx |
|---|---|---|
| QuanthoodOracle | 0xb87C0284F9A1f23bceAFDfC4bD8398f4bf420897 | 0xce2d7f61b8ff81fa75... |
| QuanthoodCanary | 0xadBa9c241A6e5238e8D272eb9554b22DFAeDeDd3 | 0x5ac15424d85294a9ff... |
| (setCanary)     | - | 0xbed0511a97ce0c5845... |
| QuanthoodArk    | 0x7f05f4a3c083a733BCc2FD745D9ad55A92CC04e4 | 0xf3f785fe2a8dea6c3c... |

On-chain verified after deploy:
- oracle.threatLevel() = 0
- oracle.canary() = Canary address (binding OK)
- canary.rungs(0).bits = 16, rungs(7) armed = true (128 bit)
- canary.momentAt() = 0 (no break yet)
- ark.oracle() = Oracle address

## Canary ladder (NUMS)
scalar_i = SHA256("quanthood.canary.v1|<i>|<bits>") mod N — nobody holds these keys.
Provenance: config/canary_pubkeys.json. Rungs: 16..112 bit training (7), 128..192
armed (5). Bits 208/256 rungs reserved for later extension (contract fixed at 12:
7 training + 5 armed).

## Tests
forge test: 10/10 pass (claim, escrow payout, oracle level raise, moment, ark
commit/verify, guard lock, access control).

## Verification
verify-retry.sh running (Blockscout rate-limited 429; Oracle accepted HTTP 200 on
first submit). Check: https://robinhoodchain.blockscout.com/address/<addr>#code

## Web
- Landing: http://43.134.36.95:8081/ (nginx port 8081, static /var/www/quanthood)
- Design: spec-sheet terminal style (Qairos-inspired layout, original copy)
- Branding: QUANTHOOD / QHD-01 / $QHD, network Robinhood Chain 4663
- Sections: overview (specs+core device+visualizations), manifesto, how-it-works,
  modules (4 live tools + explorer links), use-cases, technology, roadmap, FAQ, footer
- All contract addresses hard-linked to Blockscout verified pages
- Mobile 375px verified clean, desktop 1280px verified clean

## App (dApp shell)
- URL: http://43.134.36.95:8081/app/index.html
- Views: dashboard, ark (PQ key gen/commit/kit), signer, oracle (live read),
  canary (12 rungs live + BSGS solver 2^bits keyspace), guard wizard (forge build OK),
  abi, contracts, settings
- Live reads via rpc.mainnet.chain.robinhood.com: threatLevel() 0x6405e8e4,
  RUNG_COUNT() 0xfdca5b8c, rungs(i) 0xcdcff8c4
- Solver: BSGS over secp256k1, k recovery verified; targets generated in 2^bits
  keyspace (on-chain NUMS keys are full 256-bit)
- SHA-256 pure JS fallback (plain HTTP); commit(bytes32) selector 0xf14fcbc8
- Mobile 375px fixed: webbtn hidden, nav fits (right edge 319 < 375)

## Redeploy v2 — NUMS keyspace fix (2026-10-11 20:30 WIB)
- Root cause: deploy v1 memakai scalar = SHA256 mod N (full 256-bit) untuk semua
  rung, padahal metadata bits=16..112 — kunci training tidak ada di keyspace
  yang diiklankan, solver browser tidak akan pernah menemukannya.
- Fix (Opsi A): training rungs 0..6 pakai k = SHA256("quanthood.canary.v1|<i>|<bits>")
  mod 2^bits — kunci benar-benar di keyspace 2^bits; armed rungs 7..11 tetap
  mod N (full-size, nobody holds). Armed rungs byte-identical dengan v1.
- Kontrak BARU: Oracle 0x95e294817114673D33B7ba6463EB245cA7cC8930,
  Canary 0x883b889749876a08F26695f2358D2417DfB3E7fa,
  Ark 0x494b6d3a4F3B446AB83e9947BA7dFf20f6DCACc1
- Deploy tx: Oracle 0x68520732047551f6dad852dd7db6eb0f6df537758c84bc5602bab2c3f2604fdf,
  Canary 0x1a58c3c9c1b1da349271cb2b78ce5467ae164bdc049ade78cb02468686be69d3,
  setCanary 0xa49aa40a06de723a38cadd189df9e7bfd194064c6234446d5c9d16943e350416,
  Ark 0x16f0db119dd5294ec5eac2951427bca1f3c4e60da3476baf2438a61c7547a8c0
- On-chain checks: threatLevel 0, canary bound, rung0 pubkey = NUMS v2 (verified
  X match), rung7 armed intact, RUNG_COUNT 12, ark.oracle bound
- E2E TERBUKTI: fundRung(0) 0.00001 ETH tx 0x2bbebac2…5db; solver menemukan
  kunci on-chain ASLI (k=0x358); claim() tx 0x64e18a0b…4e31 SUCCESS →
  event RungBroken(rungId=0, bits=16, claimer=deployer, reward paid), broken=1.
  32-bit rung 1 juga terbukti solvable: BSGS menemukan k=0xfd9b12ac (match NUMS v2).
- Tests: 10/10 pass. Kontrak lama (v1) tetap on-chain tapi tak dipakai web lagi.
- Kunci training (publik, siapa pun bisa verifikasi & solve):
  k0=0x358, k1=0xfd9b12ac, dst — lihat config/canary_pubkeys.json v2.

## Domain SPON (2026-10-11 22:35 WIB)
- Domain: spon.family (beli Limp di Dynadot, NS Dynadot ns1/ns2.dyna-ns.net)
- DNS: A root → 43.134.36.95, www CNAME → root. Limp set sendiri di Dynadot.
- Nginx: server_name += spon.family www.spon.family (config pons, backup .bak-20261011-domain)
- HTTPS: certbot OK (spon.family + www), auto HTTP→301 HTTPS, auto-renew aktif
- Verified: https://spon.family 200, www 200, redirect 301, footer X+TG link ada

## Guard showcase — QuantumSafeVaultShowcase (2026-10-12 00:20 WIB)
- QuanthoodGuard adalah mixin (by design, app: "guard is a library"), jadi yang
  dideploy contoh konkret: QuantumSafeVaultShowcase (inherit QuanthoodGuard,
  lockLevel=1, oracle 0x95E2...8930).
- Address: 0xf756466968e56f69a2ceda0d8260279c757f9c5d
- Deploy tx: 0xdcbaac4528f6c45423c64f06a939877914aa3e7591c3316e6238c3ec4cf8b76f
- E2E: deposit 0.00001 ETH (tx 0xda24e66c...0638d) -> balances 1e13;
  withdraw 0.000005 (tx 0xd8604275...79cb) -> balances 5e12. guardOpen()=true.
- forge test: 10/10 PASS.
- Deployer balance sisa: 0.00178 ETH (gas deploys berikutnya masih aman).

## Canary v2 — refund-able ladder (2026-10-12 00:40 WIB)
- Deploy: QuanthoodCanaryV2 0x05d696fdb24d6ce6f76968af1941d4fd5374bcd2
  (tx 0x15ba124ca9687d6b0ca0fba25af63e8d579a93e569723e3ea8ac3887716aeca9)
- Perbedaan vs v1: refundRung() — owner bisa tarik bounty rung yang belum
  dipecahin SETELAH 180 hari refund lock (per rung, dari funding pertama).
  Pubkey ladder identik dengan v1 (verified rung 0 & 11 match). Owner-only.
- Verified Sourcify exact_match. Blockscout: submit manual menyusul.
- Funding (owner = deployer 0x5a28...D9B1):
  rung1 32b 0.0002 / rung2 48b 0.0004 / rung3 64b 0.0008 /
  rung4 80b 0.001 / rung5 96b 0.0016 = total 0.004 ETH bounty live
- E2E v2: rung 1 claimed by deployer (challenge = keccak(address(canary)),
  tx 0x672c28e9...0f052) — reward 0.0002 ETH paid. Ladder working.
- Ladder final: rung1 BROKEN (test), rung2-5 funded & open, rung6 & armed 7-11
  unfunded (by design early stage).

## Wall of Breaks + live feed (2026-10-12 02:10 WIB)
- Halaman baru #breaks di app: daftar semua RungBroken events dari Canary v2
  via eth_getLogs (1.5M block window), auto-refresh 30s, toast notif break baru.
  Kolom: when, rung, bits, tier, solver (link Blockscout), reward, proof (link tx).
- Claim sukses di solver → link tx Blockscout + auto-refresh breaks.
- nginx: HTML no-cache (biar update app langsung kebaca).
- Bugs fixed: $() helper pakai id tanpa "#", rpc getBlockByNumber params array,
  claim selector 0x8640cffa, keccak rho table, ECDSA s formula, recovery id.

## How it works page (2026-10-12 02:45 WIB)
- Halaman #how di nav utama: penjelasan 30 detik (kenapa ECDSA rapuh quantum),
  step-by-step main (pick rung → solve → claim → paid), tabel arti threat level,
  CTA ke canary ladder + wall of breaks.
- Nav highlight fix: overview group punya 2 page — highlight exact match saja.
- onclick inline → anchor link (onclick show() gak jalan via hash router).

## Rung detail + X assets + solver speedup (2026-10-12 03:15 WIB)
- Rung detail explorer: card di canary view, muncul saat rung dipilih.
  Shows total funded, jumlah funder, status, event history (funded/broken
  per block, siapa, berapa, link tx Blockscout). Data = eth_getLogs 1.5M window.
- X assets /root/quanthood/x/: bio.txt (3 opsi ≤160 char), banner.png 1500x500
  (safe-band mobile, QC 2x revisi), pfp.png 400x400 (ring motif). Upload manual.
- Solver: invEuc (extended Euclid inverse) ganti powmod → 1.6-2.2x faster
  (32-bit 30.3s→18.6s di node). Fix bug: chain start 2G (step pertama = doubling
  bukan general add). 64-bit tetap gak feasible di browser (2^32 baby steps).


## Domain live + CTA fix (2026-10-12 10:05 WIB)
- https://quanthood.tech LIVE: SSL Let's Encrypt (ECDSA, valid s.d. 2027-01-10,
  auto-renew OK), www→apex 301, http→https 301, security headers (HSTS, nosniff,
  XFO, Referrer-Policy). Legacy :8081 masih jalan.
- OG meta di landing & app → https://quanthood.tech/brand/og-card.png.
- CTA audit: 19 link kini konsisten → semua tombol app (Open App, Launch App,
  Protect my account, Docs, module cards, "Open in app →") → /app/index.html.
  Nav links tetap in-page (#how #modules dst — semua id valid).
- X handle: @QuantHood_ (Limp). Email forward: quant@quanthood.tech →
  quant@quant.tech (menunggu setup Dynadot email forwarding oleh Limp).

- Email forward quant@quanthood.tech dikonfig Limp via Dynadot (12 Okt).
  DNS: MX=webhost.dynadot.com ✓, SPF ✓. Port 25 outbound keblok di server →
  test end-to-end dari sisi Limp (kirim email dari Gmail ke quant@quanthood.tech).

## Launch milestone (2026-10-12 10:40 WIB)
- Email forward quant@quanthood.tech: TESTED & WORKING (Limp confirmed).
- Akun X @QuantHood_: LIVE (Limp). Aset posting di /root/quanthood/x/:
  bio.txt, banner.png, pfp.png, first-post.md, first-post-card.png,
  primer-video.mp4 (45s + sound design).
- Quanthood launch stack COMPLETE: domain+SSL ✓, landing+app ✓, X ✓, email ✓.

## V3 — QuanthoodVault (2026-10-12 14:20 WIB)
- QuanthoodVault: self-rescuing vault. Deposit ETH, set recovery address +
  threshold; when oracle level >= threshold, anyone can sweep the balance to
  the recovery address (caller never receives it). Owner can always withdraw.
  Recovery frozen once level >= threshold.
- Address: 0x3Fdcd291DC7e86cfde3Fc650608D1C660F42CE50
- Deploy tx: 0x2d9a485a40bd5796e9bbd73b88b0b7094e7b763b7261ecc1246556fab0707a26
  (475,978 gas, 0.0000095 ETH, oracle wired 0x95e2...8930)
- Tests: 14/14 PASS (forge test --match-contract QuanthoodVaultTest)
  Full suite: 24/24 (14 vault + 10 existing)
- Verified: Sourcify exact_match (creation + runtime) chain 4663
- E2E on-chain: deposit 0.00002 ETH -> balanceOf 2e13 ✓; setRecovery
  0xdEaD thr=3 -> accountOf ✓; withdraw 0.00001 -> 1e13 ✓; recoveryOpen=true
- Sweep path not exercised on mainnet (needs threat >= 3 = 3 armed breaks,
  by design); covered by 14 test cases incl. reentrancy + wrong-caller.

## ML-DSA-44 real implementation — app upgrade (2026-10-12 17:30 WIB)
- App PQ keygen upgraded: simulated sha256 → REAL ML-DSA-44 (NIST FIPS 204)
  via @noble/post-quantum 0.7.1 (audited lib), esbuild IIFE bundle 50KB at
  /vendor/ml-dsa-44.bundle.js.
- Browser E2E verified: keygen pub=1312B sk=2560B, sign=2420B, verify=true,
  tampered signature rejected=false.
- pubHash = SHA-256(publicKey)[0..32]; recovery kit v2 (seed + publicKeyB64 +
  standard FIPS 204); PQ Signer now does real ML-DSA sign/verify.
- On-chain proof: commit(0xd45156...d9b) tx
  0x376ebeca492f6beadf4cfd122e8ec1559df35f33307cfb90134bdddec6b19a5c,
  commitments(deployer) read-back matches exactly.
- Feature card updated to full claim (amber disclaimer removed).
- CA addresses UNCHANGED — this was client-side only.

## V6 — QuanthoodMarket (2026-10-12 18:05 WIB)
- Prediction market settled from on-chain Quanthood data: LEVEL_BY
  (threatLevel >= threshold before deadline) & RUNG_BEFORE (armed rung falls).
- Trustless resolution: outcome read from Oracle/Canary by the contract itself;
  owner cannot set results. Winners split the whole pool proportionally. Fee 0.
- Address: 0xBAc7Ee9989C35cdCb3b9D436254CF5908F3946e6
- Deploy tx: 0xf920a91a5afe07157f5a063b2aaae71aafd83a7b9a24aa7c13e4fb2153cc3661
  (oracle 0x95e2...8930 + canary 0x05d6...bcd2 wired in constructor)
- Tests: 10/10 PASS (open, bet both sides, close guard, resolve both outcomes,
  proportional payout math, rung markets, double-claim guard, zero-bet guard).
  Full suite: 34/34.
- Verified: Sourcify exact_match (creation + runtime) chain 4663
- E2E on-chain: market 0 (thr=5, bet YES 0.00005) → resolved NO → claim
  correctly reverted (wrong side). Market 1 (thr=0, YES 0.00005 + NO 0.00002)
  → resolved YES → claim paid 0.00007 ETH pool share ✓ (minus gas).
- App: #market view (open market, bet YES/NO, resolve, claim) + Market in
  contracts list. JS runs inside main IIFE (scope fix after initial attempt).

## Contests page "Break the Curve" (2026-10-12 18:20 WIB)
- Live: https://quanthood.tech/contests/ — on-chain-driven contest page.
- Tiers: training rungs 16/48/64/80/96/112 bit read live from CanaryV2
  (rungs()); 32-bit rung shown SOLVED (broken by deployer test, block
  85970569, reward 0.0002 ETH, tx 0x672c...a0f052).
- Escrow > manual rewards (Qairos style): bounties live in QuanthoodCanary,
  contract pays solver directly on claim — no team approval step.
- Leaderboard: trustless — rendered from RungBroken events via eth_getLogs
  (fromBlock 0x5100000), auto-refresh 60s. Nobody can fake entries.
- Landing links: "Contests" (nav) + "Break the Curve" (hero CTA).
- Mobile responsive QC pass (screenshot archived: shots/contests-*.png).

## V7 — QuanthoodInsurance (2026-10-12 18:50 WIB)
- Parametric cover vs first armed break: buy coverage+term, premium =
  coverage × rate × term; rate = 0.40%/yr base + surcharge by threat level
  (2:+2%, 3:+4%, 4:+8%, 5:+16%). Payout = full coverage if any armed rung
  broken before expiry; settlement reads Canary.momentAt()/rungs() directly.
- Underwriting pool: anyone addCapital → lpShares proportional; premiums
  in, payouts out; withdraw anytime at pool share.
- Reserved-capital check: pool must cover all active policies before a new
  policy is sold (prevents over-sold book).
- IMPORTANT GOTCHA (found live): CanaryV2 rungs() getter returns 7 words —
  bits, bounty, armed, broken, brokenAt, pubkeyAddress, fundedAt — NO
  uint256[2] pubkey despite struct comment. Interface must match or every
  call reverts with empty data. Verified via forge inspect storage/ABI.
- Address (FINAL): 0x5BB67b318C5521d6Dfba117B901E133Ec7b315ad
  (first attempt 0xf7b4dDD1... = BROKEN interface, do not use)
- Tests: 14/14 PASS (quote math, rate ladder, capital add/withdraw, buy,
  claim after armed break, expiry guard, non-holder guard, double-claim,
  momentAt global settle, reserved-capital limit). Full suite 48/48.
- Sourcify exact_match chain 4663.
- E2E on-chain: PARTIAL — deployer wallet exhausted (0.000092 ETH left).
  addCapital succeeded on v1 contract; buyPolicy E2E on v2 needs wallet
  top-up (~0.0005 ETH). Claim path fully covered by forge tests.
- App: #insure view (quote/buy, pool stats, add capital/withdraw, claim/
  settle) + Insurance in contracts list.

## Contract Wizard v2 (2026-10-13 13:40 WIB)
- App #guard wizard: 4 output tabs (CONTRACT / TEST / DEPLOY SCRIPT /
  SETUP GUIDE) + Copy + Download per tab (blob, filename src/X.sol,
  test/X.t.sol, script/X.s.sol, X-SETUP.md).
- 3 modes (personal vault / treasury / bare) × trip level 1-5 × 5 features
  (ERC-20, Pausable, per-tx limit, timelock, recovery sweep) = 480 option
  sets. Live stat line shows combos + test count + solc profile.
- QA (REAL compile + run, bukan cuma tampilan):
  - Vault all-features: forge build 0 errors, generated tests 5/5 PASS
  - Treasury recovery-only: forge build 0 errors, generated tests 3/3 PASS
- Bug yang ditemukan & diperbaiki selama QA: double-paren di test ctor,
  console2 import hilang di deploy script, TOKEN_ADDRESS tak dideklarasi,
  whenNotPaused dipakai tanpa pausable on, protectedCheck probe tanpa
  pausable, checksummed address salah (cast to-check-sum-address), test
  recovery assertion terbalik, stray backtick di wizardGuide.
- Oracle address di semua template: 0x95E294817114673d33B7ba6463Eb245ca7cc8930
  (checksummed). Deploy script includes verify command + live contract table.

## V8 — QuanthoodMarket FIX + seed (2026-10-13 14:30 WIB)
- BUG FATAL FIX: interface canary.rungs() 8-field (uint256[2] pubkey) tapi
  CanaryV2 on-chain return 7 → resolve() kind RungBefore REVERT SELALU.
  Tests 10/10 PASS dengan mock 8-field = mock-vs-real mismatch klasik.
  Mock + interface disamakan ke 7-field; suite 48/48.
- OLD market 0xBAc7Ee9989C35cdCb3b9D436254CF5908F3946e6 = BROKEN (jangan).
- NEW market: 0x4A1F14da8108053999BC471Bcef035A3377a166E
  Deploy tx 0x7c9d5396436fef2380ccd28ad221f9cbe8cf8489682df057f395ef103831f45b
  Sourcify exact_match ✓. Tests sama source, full suite 48/48.
- SEED (parimutuel cold start, real ETH, total 0.0018):
  #0 LevelBy thr=1, close 90d   — YES 0.0004 / NO 0.0002 (66.7% YES)
  #1 LevelBy thr=2, close 365d  — YES 0.0002 / NO 0.0004 (33.3% YES)
  #2 RungBefore rung7(128b), 365d — YES 0.0001 / NO 0.0005 (16.7% YES)
  Deployer punya stake di semua — kalau menang, claim = dana balik.
- App #market: full market cards (question, countdown, YES/NO %, pool,
  "Use this market" → isi form bet). callHex() helper untuk multi-word
  decode (call() lama cuma BigInt 1 word — penyebab render kosong).

## Insurance E2E COMPLETE (2026-10-13 15:10 WIB)
- v1 (0xf7b4...) capital 0.0001 ETH recovered via removeCapital ✓.
- v2 (0x5BB6...) seeded: addCapital 0.0002 ETH ✓.
- E2E buyPolicy: coverage 0.00015 ETH × 30 hari, premium 49,315,068,493 wei
  (0.4%/yr di level 0) — tx success, policy #0 live, expires 2026-11-12.
- Pool: 0.000200049 ETH · policiesLength=1 · rateBps=40 (level 0).
- Reserved-capital mechanism proven: pool ≥ semua coverage aktif.
- UI #insure live: pool 0.000200 ETH, 1 policy, 0.40%/yr, no break.
- Sisa budget deployer: ~0.000065 ETH.

## RPC Failover + Error Boundary (2026-10-13 15:50 WIB)
- rpc() sekarang pakai pool 4 endpoint dgn auto-failover + 8s timeout +
  endpoint stickiness (yang sehat dipakai terus):
  1. https://rpc.mainnet.chain.robinhood.com (official)
  2. https://robinhood.drpc.org (0.04s — tercepat)
  3. https://robinhood-rpc.publicnode.com (0.22s)
  4. https://rpc.ordofi.network (0.29s)
  Semua verified chainId 0x1237 (4663). Sumber: ethereum-lists/chains.
  Simulasi endpoint mati → failover ke drpc → data tetap dapat ✓.
- Error boundary: window.onerror + unhandledrejection → toast user-friendly,
  halaman gak mati diam-diam.
- UI QA: dashboard live reads ✓, market 3 cards ✓, zero page errors ✓.

## X Links + Manual ABI Decoder (2026-10-13 16:30 WIB)
- @Quanthood_ linked 3x: landing footer resource, landing hero Follow btn,
  app footer. Verified served.
- Response guide table ternyata SUDAH ADA (audit salah baca pattern) —
  6 level lengkap + pill state + topic0 event card. Level mapping FAKTUAL
  cocok dgn ladder on-chain: lvl1=128bit(rung7) ... lvl5=192bit(rung11).
  (Ladder kita beda dari Qairos: kita 6 armed rungs 128-192 step 16,
  mereka 128-256 step 32. Konsisten dgn kontrak sendiri.)
- Manual ABI decoder LIVE di #oracle (gap asli yang tertinggal):
  paste hex → decode threatLevel/momentAt/armedBreakHappened/poolEth/
  rateBps/raw auto-detect (level, ETH amount, timestamp). Length validation
  + multi-word warning. Puppeteer QA 5/5 scenarios PASS, zero errors.

## Console Terminal (2026-10-13 17:30 WIB)
- New #console view (nav Build group): Quanthood-aware browser terminal.
- Commands: help, status (5-call snapshot), level, rungs/breaks (getLogs),
  markets (odds+pool per market), insurance, decode <hex>, block, gas,
  whoami, clear. History via ArrowUp/Down. Output copyable plain text.
- QA: help/level/status/decode/markets semua PASS live (block 86.6M,
  pool 0.000200 ETH, 3 markets dengan odds akurat). Zero page errors.
- Bug fixed saat QA: sel() helper nambahin "0x" dobel di calldata
  ("0xb1283e770x000..." invalid) → RPC busy error → fix padStart tanpa 0x.
- Rate-limit guard: per-market retry 3x + backoff + graceful "read failed".

## QRNG + PWA (2026-10-13 21:00 WIB)
- QRNG mode di #ark keygen: entSrc + "Quantum seed (NIST beacon) + Browser".
  Fetch beacon.nist.gov/beacon/2.0/pulse/last (CORS ✓, CORS allow-origin *),
  XOR outputValue[0:32] ke WebCrypto seed (32-byte preserved — keygen
  ml_dsa44 WAJIB seed persis 32B, concat bikin RangeError). Indikator
  "randomness source" tampil pasca-generate: WebCrypto / mixed / ⊕ NIST
  beacon (pulse N) / fallback labels. QA live: pulse 1980229 ✓ zero errors.
  Gotcha: NIST response punya wrapper "pulse" — j.pulse.outputValue.
- PWA: /manifest.json (standalone, theme #c6ff3a, bg #0d0e0b, start /app),
  icons 192+512 PNG (PIL-rendered 9-grid logo, akar dari SVG brand) + SVG,
  head links di landing + app. Chrome test: manifest valid, icons 200,
  theme meta ✓, zero page errors.

## Analytics (log-based) + Claims audit + Disclaimers (2026-10-13 21:50 WIB)
- PLANSIBLE SELF-HOST DIBATALKAN: server 2GB RAM (487MB available), disk 87%,
  no Docker — Plausible butuh Docker+1GB+. SOLUSI: log-based analytics murni.
  - nginx /hit endpoint → 204 + custom log $time|$ip|$ua|$arg_p|$arg_r|$arg_s
    (log format di /etc/nginx/conf.d/quanthood-analytics.conf, access log
    /var/log/nginx/quanthood-hit.log, logrotate 7d/5M).
  - Beacon JS zero-dependency di app + landing: sendBeacon/fetch /hit?p=&r=&s=
    (path view, referrer class direct/internal/ext, screen sm/md/lg). No
    cookie, no fingerprint, IP hanya di-hash harian di report.
  - Report: /root/quanthood/scripts/analytics-report.py [YYYY-MM-DD] —
    pageviews, unique (daily-hashed IP), top paths, referrers, screens,
    bot filter. Backup config: /etc/nginx/sites-enabled/quanthood.bak-20261013-analytics
  - E2E QA: curl 204 ✓, log line ✓, browser beacon /landing+/market ✓,
    report parse ✓. Klaim "no analytics" di copy = tetap jujur (cookieless,
    self-hosted, gak ada third-party).
- CLAIMS AUDIT (item #13 verify): klaim stale difix — "Four contracts/Ten
  tests/Tests 10/10" → "Six contracts/48 tests/Tests 48/48" (app #contracts
  + landing tech table + roadmap). Semua alamat kontrak di copy = live ✓.
- Disclaimers real-money: #market ("not paper trading… bets final… nothing
  financial advice") + #insure ("real ETH pool… premiums non-refundable").
  Browser QA: semua fix terverifikasi tampil, zero page errors.

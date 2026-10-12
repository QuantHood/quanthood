#!/usr/bin/env bash
# Quanthood — verify contracts on Robinhood Chain Blockscout via standard-input JSON.
# Pattern proven on SPON router (2026-10-08). 429 responses often still land; retry.
set -uo pipefail
BASE="https://robinhoodchain.blockscout.com"
export PATH=$PATH:~/.foundry/bin

cd /root/quanthood/contracts
mkdir -p verify

verify_one() {
  local ADDR="$1" NAME="$2" SRC="$3"
  local OUT="verify/${NAME}.json"
  # standard-input build via forge: single file with all deps inlined
  forge verify-contract "$ADDR" "src/${SRC}.sol:${NAME}" \
    --verifier blockscout --verifier-url "$BASE/api?" \
    --compiler-version v0.8.36+commit.8a079791 \
    --num-of-optimizations 200 2>&1 | tail -3
}

echo "== Oracle =="
verify_one 0xb87C0284F9A1f23bceAFDfC4bD8398f4bf420897 QuanthoodOracle QuanthoodOracle
echo "== Canary =="
verify_one 0xadBa9c241A6e5238e8D272eb9554b22DFAeDeDd3 QuanthoodCanary QuanthoodCanary
echo "== Ark =="
verify_one 0x7f05f4a3c083a733BCc2FD745D9ad55A92CC04e4 QuanthoodArk QuanthoodArk

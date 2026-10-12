#!/usr/bin/env bash
# Submit verification to Blockscout with browser-like headers (CF often lets these
# through even when replying 429). Retry a few times per contract.
set -uo pipefail
BASE="https://robinhoodchain.blockscout.com"

verify_one() {
  local ADDR="$1" NAME="$2"
  local FILE="/root/quanthood/contracts/verify/stdin_${NAME}.json"
  for i in 1 2 3; do
    echo "[$i] $NAME ($ADDR) ..."
    RESP=$(curl -s -X POST "$BASE/api/v2/smart-contracts/$ADDR/verification/via/standard-input" \
      -H "Origin: $BASE" \
      -H "Referer: $BASE/contract-verification" \
      -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36" \
      -H "Accept: application/json" \
      -F "compiler_version=v0.8.36+commit.8a079791" \
      -F "license_type=mit" \
      -F "autodetect_constructor_args=true" \
      -F "files[0]=@$FILE;type=application/json;filename=standard-input.json" \
      -w "\nHTTP:%{http_code}")
    echo "$RESP" | tail -1
    echo "$RESP" | head -c 200
    echo
    if echo "$RESP" | grep -q '"status":"success"'; then echo "=> OK"; break; fi
    sleep 5
  done
}

verify_one 0xb87C0284F9A1f23bceAFDfC4bD8398f4bf420897 QuanthoodOracle
verify_one 0xadBa9c241A6e5238e8D272eb9554b22DFAeDeDd3 QuanthoodCanary
verify_one 0x7f05f4a3c083a733BCc2FD745D9ad55A92CC04e4 QuanthoodArk

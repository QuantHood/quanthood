#!/usr/bin/env bash
BASE='https://robinhoodchain.blockscout.com'
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
declare -A ADDRS=(
  [QuanthoodCanary]=0xadBa9c241A6e5238e8D272eb9554b22DFAeDeDd3
  [QuanthoodArk]=0x7f05f4a3c083a733BCc2FD745D9ad55A92CC04e4
  [QuanthoodOracle]=0xb87C0284F9A1f23bceAFDfC4bD8398f4bf420897
)
declare -A DONE
for round in $(seq 1 20); do
  for NAME in QuanthoodCanary QuanthoodArk QuanthoodOracle; do
    [ "${DONE[$NAME]:-0}" = "1" ] && continue
    A=${ADDRS[$NAME]}
    RESP=$(curl -s -X POST "$BASE/api/v2/smart-contracts/$A/verification/via/standard-input" \
      -H "Origin: $BASE" -H "Referer: $BASE/contract-verification" -H "User-Agent: $UA" -H "Accept: application/json" \
      -F "compiler_version=v0.8.36+commit.8a079791" -F "license_type=mit" -F "autodetect_constructor_args=true" \
      -F "files[0]=@/root/quanthood/contracts/verify/stdin_$NAME.json;type=application/json;filename=standard-input.json" \
      -w " HTTP:%{http_code}")
    echo "[$(date '+%H:%M:%S')] round$round $NAME: $(echo "$RESP" | tail -c 80)"
    if echo "$RESP" | grep -q 'verification started'; then DONE[$NAME]=1; fi
    sleep 20
  done
  # stop kalau semua sukses terkirim
  ALL=1
  for NAME in QuanthoodCanary QuanthoodArk QuanthoodOracle; do [ "${DONE[$NAME]:-0}" = "1" ] || ALL=0; done
  [ "$ALL" = "1" ] && { echo "ALL SUBMITTED"; break; }
  sleep 40
done
echo "retry loop done: ${!DONE[@]}"

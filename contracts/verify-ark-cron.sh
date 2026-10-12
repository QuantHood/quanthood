#!/usr/bin/env bash
BASE='https://robinhoodchain.blockscout.com'
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
LOG=/root/quanthood/contracts/verify-ark-cron.log
for i in $(seq 1 20); do
  RESP=$(curl -s -X POST "$BASE/api/v2/smart-contracts/0x7f05f4a3c083a733BCc2FD745D9ad55A92CC04e4/verification/via/standard-input"     -H "Origin: $BASE" -H "Referer: $BASE/contract-verification" -H "User-Agent: $UA" -H "Accept: application/json"     -F "compiler_version=v0.8.36+commit.8a079791" -F "license_type=mit" -F "autodetect_constructor_args=true"     -F "files[0]=@/root/quanthood/contracts/verify/stdin_QuanthoodArk.json;type=application/json;filename=standard-input.json"     -w " HTTP:%{http_code}")
  echo "[$(date '+%d %b %H:%M')] attempt $i: $(echo "$RESP" | tail -c 90)" >> $LOG
  if echo "$RESP" | grep -q 'verification started'; then echo "[$(date '+%d %b %H:%M')] ARK SUBMITTED OK" >> $LOG; exit 0; fi
  sleep 1800
done
echo "[$(date '+%d %b %H:%M')] gave up after 20 attempts" >> $LOG

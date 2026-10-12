#!/usr/bin/env bash
# Retry Blockscout verification utk QuantumSafeVaultShowcase (rate-limited 429).
BASE='https://robinhoodchain.blockscout.com'
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
LOG=/root/quanthood/contracts/verify-vault-cron.log
ADDR=0xf756466968e56f69a2ceda0d8260279c757f9c5d
# sudah verified? skip:
code=$(curl -s -o /tmp/vault_check.json -w '%{http_code}' -H "User-Agent: $UA" "$BASE/api/v2/smart-contracts/$ADDR")
if [ "$code" = "200" ] && grep -q '"is_verified":true' /tmp/vault_check.json 2>/dev/null; then
  echo "[$(date '+%d %b %H:%M')] already verified" >> $LOG
  crontab -l | grep -v verify-vault-cron.sh | crontab -
  exit 0
fi
for i in $(seq 1 10); do
  RESP=$(curl -s -X POST "$BASE/api/v2/smart-contracts/$ADDR/verification/via/standard-input"     -H "Origin: $BASE" -H "Referer: $BASE/contract-verification" -H "User-Agent: $UA" -H "Accept: application/json"     -F "compiler_version=v0.8.36+commit.8a079791" -F "license_type=mit" -F "autodetect_constructor_args=true"     -F "files[0]=@/root/quanthood/contracts/verify/stdin_QuantumSafeVaultShowcase.json;type=application/json;filename=standard-input.json"     -w " HTTP:%{http_code}")
  echo "[$(date '+%d %b %H:%M')] attempt $i: $(echo "$RESP" | tail -c 90)" >> $LOG
  if echo "$RESP" | grep -qE 'verification started|ok'; then echo "[$(date '+%d %b %H:%M')] VAULT SUBMITTED OK" >> $LOG; exit 0; fi
  sleep 1200
done
echo "[$(date '+%d %b %H:%M')] gave up after 10 attempts" >> $LOG

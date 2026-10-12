#!/usr/bin/env python3
"""Quanthood analytics: parse nginx /hit log. Privacy: IP -> daily hash only."""
import hashlib
import sys
import collections

LOG = "/var/log/nginx/quanthood-hit.log"
rows = []
try:
    for line in open(LOG):
        parts = line.rstrip("\n").split("|")
        if len(parts) < 6:
            continue
        ts, ip, ua, path, ref, screen = parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]
        if not path:
            continue
        path = __import__("urllib.parse", fromlist=["unquote"]).unquote(path)
        rows.append((ts, ip, ua, path, ref, screen))
except FileNotFoundError:
    print("no log yet")
    sys.exit(0)

day = sys.argv[1] if len(sys.argv) > 1 else None
if day:
    rows = [r for r in rows if r[0].startswith(day)]

today = rows[-1][0][:10] if rows else "no-data"
pv = len(rows)
uniq = len({hashlib.sha256((r[1] + today).encode()).hexdigest()[:12] for r in rows})
paths = collections.Counter(r[3] for r in rows)
refs = collections.Counter(r[4] for r in rows)
screens = collections.Counter(r[5] for r in rows)

print(f"QUANTHOOD ANALYTICS — {today}")
print(f"pageviews: {pv} | unique (daily-hashed IP): {uniq}")
print("top paths:")
for p, c in paths.most_common(10):
    print(f"  {p:30s} {c}")
print("referrers:", dict(refs.most_common(5)))
print("screens:", dict(screens.most_common()))
bots = sum(1 for r in rows if any(b in r[2].lower() for b in ("bot", "crawl", "spider", "curl", "wget")))
print(f"(bot/curl traffic: {bots} — human views ~{pv - bots})")

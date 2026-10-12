# Quanthood — DOMAIN SETUP (jalankan saat domain sudah dibeli)
# Domain contoh: quanthood.xxx — ganti sesuai domain asli.

## 1. DNS (di registrar/domain manager Limp)
Buat 1 A record:
    Type: A
    Name: @        (root domain)
    Value: 43.134.36.95
    TTL: 3600
Opsional (www):
    Type: CNAME
    Name: www
    Value: quanthood.xxx

## 2. Server (SSH ke 43.134.36.95) — jalankan sebagai root:
# a. Update nginx config:
sed -i 's/listen 8081;/listen 80;\n    listen [::]:80;\n    server_name quanthood.xxx www.quanthood.xxx;/' /etc/nginx/sites-available/quanthood
# (atau edit manual: listen 80 + server_name domain)
nginx -t && systemctl reload nginx

# b. HTTPS (certbot — sekali jalan, auto-renew):
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d quanthood.xxx -d www.quanthood.xxx --non-interactive --agree-tos -m limp@quanthood.xxx

## 3. Update link di kedua HTML (http://43.134.36.95:8081 → https://domain):
sed -i 's|http://43.134.36.95:8081|https://quanthood.xxx|g' /var/www/quanthood/index.html /var/www/quanthood/app/index.html

## 4. Verifikasi:
curl -I https://quanthood.xxx            → HTTP/2 200
curl -I https://quanthood.xxx/app/       → HTTP/2 200
# Blockscout links tetap valid (external).

## Catatan
- Pons web tetap di port 80 IP-langsung — TIDAK disentuh. Kalau Pons nanti juga
  mau pakai domain, pisahkan server_name di config masing-masing.
- Web app baca RPC publik robinhood langsung dari browser (tidak butuh proxy).

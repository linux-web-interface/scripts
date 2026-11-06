#!/usr/bin/env bash
set -Eeuo pipefail

echo "[INFO] Memeriksa layanan Apache (Frontend)..."
sudo systemctl restart apache2
echo "[INFO] Apache berhasil direstart."

echo "[INFO] Memeriksa layanan Backend Flask via PM2..."
cd /opt/lwi-be

if pm2 describe "lwi-backend" > /dev/null 2>&1; then
    echo "[INFO] Proses lwi-backend sudah berjalan. Melakukan restart..."
    pm2 restart "lwi-backend"
else
    echo "[INFO] Memulai lwi-backend untuk pertama kalinya..."
    pm2 start ecosystem.config.js
fi

pm2 save
echo "[INFO] Semua layanan frontend dan backend berhasil dijalankan!"

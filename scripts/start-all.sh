
#!/usr/bin/env bash
set -Eeuo pipefail

BACKEND_DIR="/opt/lwi-be"

echo "[INFO] Memeriksa layanan Apache (Frontend)..."
sudo systemctl restart apache2
echo "[INFO] Apache berhasil direstart."

cd "$BACKEND_DIR"

echo "[INFO] Memeriksa layanan Backend Flask via PM2..."

if pm2 describe "lwi-backend" > /dev/null 2>&1; then
    echo "[INFO] Restart lwi-backend..."
    pm2 restart "lwi-backend"
else
    echo "[INFO] Memulai lwi-backend..."
    pm2 start ecosystem.config.js --only lwi-backend
fi

echo "[INFO] Memeriksa status filesystem indexing..."

INDEX_STATUS=$(
    venv/bin/python -c "
from services.search_index import ensure_database, get_connection

ensure_database()

with get_connection() as connection:
    row = connection.execute(
        \"SELECT value FROM index_state WHERE key = 'status'\"
    ).fetchone()

    print(row['value'] if row else 'not_started')
"
)

if [[ "$INDEX_STATUS" != "completed" ]]; then
    echo "[INFO] Index belum selesai. Memeriksa scanner..."

    if pm2 describe "lwi-scanner" > /dev/null 2>&1; then
        SCANNER_STATUS=$(pm2 jlist | node -e '
            let data = "";
            process.stdin.on("data", chunk => data += chunk);
            process.stdin.on("end", () => {
                const apps = JSON.parse(data);
                const app = apps.find(p => p.name === "lwi-scanner");
                console.log(app?.pm2_env?.status || "unknown");
            });
        ')

        if [[ "$SCANNER_STATUS" == "online" ]]; then
            echo "[INFO] Scanner sedang berjalan."
        else
            echo "[INFO] Menjalankan ulang scanner..."
            pm2 restart "lwi-scanner"
        fi
    else
        echo "[INFO] Memulai scanner..."
        pm2 start ecosystem.config.js --only lwi-scanner
    fi
else
    echo "[INFO] Filesystem indexing sudah selesai. Scanner tidak perlu dijalankan."
fi

pm2 save

echo "[INFO] Semua layanan berhasil diproses!"

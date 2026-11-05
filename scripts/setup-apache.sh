#!/usr/bin/env bash
# Configure Apache for the Linux File Explorer project on Debian/Ubuntu/Linux Mint.
# Run on the Linux guest (or a disposable Linux Mint test machine), not on Windows.

set -Eeuo pipefail

APP_NAME="${APP_NAME:-linux-file-explorer}"
DOCROOT="${DOCROOT:-/var/www/${APP_NAME}/public}"
BACKEND_HOST="${BACKEND_HOST:-127.0.0.1}"
BACKEND_PORT="${BACKEND_PORT:-5000}"
API_PREFIX="${API_PREFIX:-/api/}"
SITE_FILE="/etc/apache2/sites-available/000-000-${APP_NAME}.conf"

log() { printf '[INFO] %s\n' "$*"; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'HELP'
Penggunaan:
  sudo ./scripts/setup-apache.sh

Variabel opsional:
  APP_NAME       Nama virtual host (default: linux-file-explorer)
  DOCROOT        Folder public website (default: /var/www/<APP_NAME>/public)
  BACKEND_HOST   Alamat backend (default: 127.0.0.1; pertahankan localhost)
  BACKEND_PORT   Port backend Python (default: 5000)
  API_PREFIX     Prefix API yang diteruskan Apache (default: /api/)

Contoh:
  sudo env BACKEND_PORT=5001 ./scripts/setup-apache.sh
HELP
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

[[ "$EUID" -eq 0 ]] || die "Jalankan dengan sudo: sudo $0"

# Keep values safe for insertion into an Apache configuration file.
[[ "$APP_NAME" =~ ^[a-zA-Z0-9_-]+$ ]] || die "APP_NAME hanya boleh berisi huruf, angka, '_' atau '-'."
[[ "$DOCROOT" =~ ^/[a-zA-Z0-9_./-]+$ ]] || die "DOCROOT harus berupa path absolut tanpa spasi atau karakter khusus."
[[ "$DOCROOT" != *".."* ]] || die "DOCROOT tidak boleh mengandung segmen '..'."
[[ "$BACKEND_HOST" == "127.0.0.1" ]] || die "Untuk MVP, BACKEND_HOST harus 127.0.0.1 agar backend tidak terekspos langsung."
[[ "$BACKEND_PORT" =~ ^[0-9]{1,5}$ ]] || die "BACKEND_PORT harus berupa angka 1-65535."
(( BACKEND_PORT >= 1 && BACKEND_PORT <= 65535 )) || die "BACKEND_PORT di luar rentang 1-65535."
[[ "$API_PREFIX" =~ ^/[a-zA-Z0-9/_-]+/$ ]] || die "API_PREFIX harus seperti /api/ dan diakhiri '/'."
[[ "$API_PREFIX" != *".."* ]] || die "API_PREFIX tidak boleh mengandung '..'."

command -v apt-get >/dev/null 2>&1 || die "Skrip ini ditujukan untuk Debian/Ubuntu/Linux Mint (apt-get tidak ditemukan)."

log "Memperbarui indeks paket dan memasang Apache."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y apache2

log "Menyiapkan document root: $DOCROOT"
install -d -o root -g root -m 0755 "$DOCROOT"

# Put a small landing page only when the directory has no existing entry point.
# This prevents overwriting the frontend team's existing files.
if [[ ! -e "$DOCROOT/index.html" && ! -e "$DOCROOT/index.php" ]]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  REPO_DIR="$(dirname -- "$SCRIPT_DIR")"
  DEMO_PAGE="$REPO_DIR/web-demo/index.html"
  [[ -f "$DEMO_PAGE" ]] || die "Demo page tidak ditemukan: $DEMO_PAGE"
  install -o root -g root -m 0644 "$DEMO_PAGE" "$DOCROOT/index.html"
fi

log "Mengaktifkan modul Apache yang diperlukan."
a2enmod proxy proxy_http rewrite >/dev/null

if [[ -f "$SITE_FILE" ]]; then
  BACKUP_FILE="${SITE_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
  cp -a "$SITE_FILE" "$BACKUP_FILE"
  log "Konfigurasi lama dicadangkan ke $BACKUP_FILE"
fi

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT
cat > "$TMP_FILE" <<APACHE
<VirtualHost *:80>
    ServerName linux-file-explorer.local
    DocumentRoot "$DOCROOT"

    <Directory "$DOCROOT">
        Options -Indexes
        AllowOverride None
        DirectoryIndex index.html
        Require all granted
    </Directory>

    ProxyPreserveHost On
    ProxyPass "$API_PREFIX" "http://${BACKEND_HOST}:${BACKEND_PORT}${API_PREFIX}"
    ProxyPassReverse "$API_PREFIX" "http://${BACKEND_HOST}:${BACKEND_PORT}${API_PREFIX}"

    ErrorLog \${APACHE_LOG_DIR}/${APP_NAME}-error.log
    CustomLog \${APACHE_LOG_DIR}/${APP_NAME}-access.log combined
</VirtualHost>
APACHE

install -o root -g root -m 0644 "$TMP_FILE" "$SITE_FILE"

log "Mengaktifkan site Apache: $(basename "$SITE_FILE")"
a2ensite "$(basename "$SITE_FILE")" >/dev/null

log "Memvalidasi konfigurasi Apache."
apache2ctl configtest

log "Mengaktifkan dan memuat ulang Apache."
systemctl enable --now apache2
systemctl reload apache2

log "Selesai. Uji dari Linux dengan: curl -I http://127.0.0.1/"
log "Untuk guest VM dengan NAT port-forwarding, alamat browser Windows nantinya: http://127.0.0.1:8080/"
log "Log Apache: /var/log/apache2/${APP_NAME}-access.log dan ${APP_NAME}-error.log"

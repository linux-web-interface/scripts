#!/usr/bin/env bash
# Script Installer untuk Linux Web Interface (LWI)
# Dijalankan di Linux Guest (Debian/Ubuntu/Linux Mint) dengan hak akses sudo dari root folder.

set -Eeuo pipefail

FE_DIR="/var/www/lwi-fe"
BE_DIR="/opt/lwi-be"
APP_NAME="linux-file-explorer"
SITE_FILE="/etc/apache2/sites-available/000-000-${APP_NAME}.conf"

log() { printf '[INFO] %s\n' "$*"; }
err() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

[[ "$EUID" -eq 0 ]] || err "Jalankan skrip ini dengan sudo: sudo $0"

# Flag untuk melacak apakah apt update sudah pernah dijalankan
APT_UPDATED=0

run_apt_update_once() {
    if [ "$APT_UPDATED" -eq 0 ]; then
        log "Memperbarui repositori sistem (apt update)..."
        apt update
        APT_UPDATED=1
    fi
}

# Cek & Install curl jika belum ada
if ! command -v curl &> /dev/null; then
    run_apt_update_once
    log "Menginstal curl..."
    apt install -y curl
fi

# 0. Pengaturan Hostname & Pemilihan Network Interface untuk Avahi/mDNS
log "=== PENGATURAN HOSTNAME & JARINGAN mDNS ==="
CURRENT_HOSTNAME=$(hostname)
echo "Hostname saat ini: $CURRENT_HOSTNAME"
read -p "Masukkan hostname baru (tekan Enter untuk tetap '$CURRENT_HOSTNAME'): " NEW_HOSTNAME

if [ -z "$NEW_HOSTNAME" ]; then
  NEW_HOSTNAME=$CURRENT_HOSTNAME
fi

log "Mengubah hostname ke: $NEW_HOSTNAME"
hostnamectl set-hostname "$NEW_HOSTNAME"
sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOSTNAME/" /etc/hosts 2>/dev/null || echo -e "127.0.0.1\tlocalhost $NEW_HOSTNAME" >> /etc/hosts

echo ""
log "Daftar Network Interface yang Tersedia:"
INTERFACES=($(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo"))

i=1
for iface in "${INTERFACES[@]}"; do
  IP_ADDR=$(ip -4 addr show dev "$iface" 2>/dev/null | grep inet | awk '{print $2}' | cut -d'/' -f1)
  [ -z "$IP_ADDR" ] && IP_ADDR="Tidak ada IP"
  
  echo "$i) Interface: $iface (IP: $IP_ADDR)"
  ((i++))
done

read -p "Pilih nomor interface yang ingin digunakan untuk mDNS/Avahi: " CHOICE
SELECTED_IFACE="${INTERFACES[$((CHOICE-1))]}"

if [ -z "$SELECTED_IFACE" ]; then
  log "Pilihan tidak valid. Menggunakan default 'ens34'."
  SELECTED_IFACE="ens34"
else
  log "Interface yang dipilih untuk Avahi: $SELECTED_IFACE"
fi

# Cek & Install Avahi Daemon jika belum ada
if ! dpkg -l | grep -q avahi-daemon; then
  run_apt_update_once
  log "Menginstal avahi-daemon..."
  apt install -y avahi-daemon
fi

# Cek & Install Node.js / npm
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    log "Node.js (versi $(node -v)) dan npm sudah terinstal."
else
    run_apt_update_once
    log "Menginstal Node.js dan npm..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    apt install -y nodejs
fi

# Cek & Install PM2 secara global
if ! command -v pm2 &> /dev/null; then
  log "Menginstal PM2 process manager..."
  npm install -g pm2
else
  log "PM2 sudah terinstal."
fi

# Konfigurasi Avahi agar mendengarkan interface terpilih
CONFIG_FILE="/etc/avahi/avahi-daemon.conf"
if [[ -f "$CONFIG_FILE" ]]; then
  if grep -q "^#allow-interfaces=" "$CONFIG_FILE"; then
    sed -i "s/^#allow-interfaces=.*/allow-interfaces=$SELECTED_IFACE/" "$CONFIG_FILE"
  elif grep -q "^allow-interfaces=" "$CONFIG_FILE"; then
    sed -i "s/^allow-interfaces=.*/allow-interfaces=$SELECTED_IFACE/" "$CONFIG_FILE"
  else
    sed -i "/\[server\]/a allow-interfaces=$SELECTED_IFACE" "$CONFIG_FILE"
  fi
  systemctl restart avahi-daemon
fi

# 1. Cek & Setup Direktori Frontend & Backend
log "Memeriksa direktori proyek..."

# Cek & Install Git jika belum ada
if ! command -v git &> /dev/null; then
  run_apt_update_once
  log "Menginstal git..."
  apt install -y git
fi

setup_directory() {
    local dir="$1"
    local name="$2"
    local repo_url="$3"
    local is_frontend="$4"
    
    if [[ -d "$dir" ]]; then
        log "Direktori $name ($dir) sudah ada."
        read -rp "Apakah Anda ingin memperbarui/menimpa isinya? (y/N): " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            log "Membersihkan dan melakukan clone ulang untuk $name..."
            rm -rf "$dir"
            git clone "$repo_url" "$dir"
        else
            log "Melewati pembaruan untuk $name."
        fi
    else
        log "Direktori $name belum ada. Melakukan clone repository..."
        git clone "$repo_url" "$dir"
        chown -R root:root "$dir"
        chmod 755 "$dir"
    fi

    # Jika ini adalah direktori frontend, lakukan npm install dan npm run build
    if [[ "$is_frontend" == "true" && -d "$dir" ]]; then
        log "Menjalankan npm install & build untuk Frontend..."
        cd "$dir"
        npm install
        npm run build
        cd - > /dev/null
    fi
}

# Panggil fungsi dengan parameter tambahan "true" untuk frontend
setup_directory "$FE_DIR" "Frontend (lwi-fe)" "https://github.com/linux-web-interface/frontend.git" "true"
setup_directory "$BE_DIR" "Backend (lwi-be)" "https://github.com/linux-web-interface/backend.git" "false"

# 2. Eksekusi Check Network (mengambil dari folder scripts/)
log "Menjalankan pemeriksaan jaringan (Check Network)..."
if [[ -f "./scripts/check-network.sh" ]]; then
    bash ./scripts/check-network.sh
elif [[ -f "./check-network.sh" ]]; then
    bash ./check-network.sh
else
    log "File check-network.sh tidak ditemukan, melewati pengecekan jaringan."
fi

# 3. Setup Apache (Cek apakah sudah dikonfigurasi)
log "Memeriksa konfigurasi Apache..."
if [[ -f "$SITE_FILE" ]]; then
    echo "VM sudah terkonfigurasi apachenya."
else
    log "Konfigurasi Apache belum ada. Menyiapkan Apache..."
    if [[ -f "./scripts/setup-apache.sh" ]]; then
        sudo env APP_NAME="$APP_NAME" DOCROOT="$FE_DIR" bash ./scripts/setup-apache.sh
    else
        err "File setup-apache.sh tidak ditemukan di dalam folder scripts/!"
    fi
fi

# 4. Pengaturan Firewall (UFW) untuk akses web
log "Mengonfigurasi UFW firewall..."
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

log "Menjalankan skrip start-all.sh untuk mengaktifkan semua layanan..."
if [[ -f "./scripts/start-all.sh" ]]; then
    bash ./scripts/start-all.sh
elif [[ -f "./start-all.sh" ]]; then
    bash ./start-all.sh
else
    log "Peringatan: File start-all.sh tidak ditemukan. Layanan belum dinyalakan otomatis."
fi

log "Instalasi selesai! Silakan akses dari browser Windows melalui: http://$NEW_HOSTNAME.local"

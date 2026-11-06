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

# Install Avahi Daemon jika belum ada
if ! dpkg -l | grep -q avahi-daemon; then
  log "Menginstal avahi-daemon..."
  apt update && apt install -y avahi-daemon
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

setup_directory() {
    local dir="$1"
    local name="$2"
    
    if [[ -d "$dir" ]]; then
        log "Direktori $name ($dir) sudah ada."
        read -rp "Apakah Anda ingin memperbarui/menimpa isinya? (y/N): " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            log "Memperbarui direktori $name..."
            mkdir -p "$dir"
        else
            log "Melewati pembaruan untuk $name."
        fi
    else
        log "Direktori $name belum ada. Membuat direktori baru..."
        mkdir -p "$dir"
        chown -R root:root "$dir"
        chmod 755 "$dir"
    fi
}

setup_directory "$FE_DIR" "Frontend (lwi-fe)"
setup_directory "$BE_DIR" "Backend (lwi-be)"

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

log "Instalasi selesai! Silakan akses dari browser Windows melalui: http://$NEW_HOSTNAME.local"

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

# 4. Pilihan Hypervisor (VirtualBox atau VMware)
echo ""
echo "=== PILIHAN HYPERVISOR UNTUK PORT FORWARDING ==="
echo "1. VirtualBox"
echo "2. VMware"
echo "3. Lewati"
read -rp "Pilih hypervisor yang Anda gunakan (1/2/3): " hypervisor_choice

case "$hypervisor_choice" in
    1)
        echo ""
        echo "Untuk VirtualBox, jalankan file PowerShell berikut di Windows HOST (pastikan VM dalam keadaan mati/powered off):"
        echo "  .\\scripts\\setup-virtualbox-nat.ps1 -VMName \"Nama_VM_Anda\" -HostPort 8080 -GuestPort 80"
        ;;
    2)
        echo ""
        echo "=== KONFIGURASI PORT FORWARDING UNTUK VMWARE ==="
        echo "Untuk VMware, gunakan skrip PowerShell yang tersedia di folder scripts."
        echo "Jalankan perintah ini di Windows HOST (PowerShell as Administrator, pastikan VM mati):"
        echo "  .\\scripts\\setup-vmware.ps1 -VMName \"Nama_VM_Anda\" -GuestIP \"IP_Guest_VM_Anda\" -HostPort 8080"
        ;;
    *)
        log "Pilihan dilewati."
        ;;
esac

log "Instalasi dan pengecekan selesai!"

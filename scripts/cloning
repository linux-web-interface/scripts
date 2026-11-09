#!/usr/bin/env bash
# Skrip Clone / Update Repository LWI (Frontend & Backend)

set -Eeuo pipefail

FE_DIR="/var/www/lwi-fe"
BE_DIR="/opt/lwi-be"
FE_REPO="https://github.com/linux-web-interface/frontend.git"
BE_REPO="https://github.com/linux-web-interface/backend.git"

log() { printf '[INFO] %s\n' "$*"; }
err() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

[[ "$EUID" -eq 0 ]] || err "Jalankan skrip ini dengan sudo: sudo $0"

APT_UPDATED=0
run_apt_update_once() {
    if [ "$APT_UPDATED" -eq 0 ]; then
        log "Memperbarui repositori sistem (apt update)..."
        apt update
        APT_UPDATED=1
    fi
}

if ! command -v git &> /dev/null; then
    run_apt_update_once
    log "Menginstal git..."
    apt install -y git
fi

clone_or_update() {
    local dir="$1"
    local name="$2"
    local repo_url="$3"

    if [[ -d "$dir" ]]; then
        log "Direktori $name ($dir) sudah ada."
        read -rp "Apakah Anda ingin memperbarui/menimpa isinya? (y/N): " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            log "Membersihkan dan melakukan clone ulang untuk $name..."
            rm -rf "$dir"
            git clone "$repo_url" "$dir"
            chown -R root:root "$dir"
            chmod 755 "$dir"
        else
            log "Melewati pembaruan untuk $name."
        fi
    else
        log "Direktori $name belum ada. Melakukan clone repository..."
        git clone "$repo_url" "$dir"
        chown -R root:root "$dir"
        chmod 755 "$dir"
    fi
}

clone_fe() {
    clone_or_update "$FE_DIR" "Frontend (lwi-fe)" "$FE_REPO"
}

clone_be() {
    clone_or_update "$BE_DIR" "Backend (lwi-be)" "$BE_REPO"
}

echo "=========================================="
echo "    SETUP CLONE REPOSITORY LWI FE & BE    "
echo "=========================================="
echo "1) Clone / Update Frontend (FE) saja"
echo "2) Clone / Update Backend (BE) saja"
echo "3) Clone / Update Keduanya (FE & BE)"
echo "4) Cancel / Batal"
echo "=========================================="
read -rp "Pilih menu [1-4]: " MENU_CHOICE

case "$MENU_CHOICE" in
    1)
        log "Memproses Frontend saja..."
        clone_fe
        ;;
    2)
        log "Memproses Backend saja..."
        clone_be
        ;;
    3)
        log "Memproses Frontend dan Backend..."
        clone_fe
        clone_be
        ;;
    4)
        log "Proses dibatalkan oleh pengguna."
        exit 0
        ;;
    *)
        err "Pilihan tidak valid! Skrip dihentikan."
        ;;
esac

log "Selesai!"

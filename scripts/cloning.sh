#!/usr/bin/env bash
# Skrip Clone / Update Repository LWI (Frontend & Backend) + Build FE + venv BE

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
            log "Melewati pembaruan clone untuk $name."
        fi
    else
        log "Direktori $name belum ada. Melakukan clone repository..."
        git clone "$repo_url" "$dir"
        chown -R root:root "$dir"
        chmod 755 "$dir"
    fi
}

setup_frontend_build() {
    if [[ -d "$FE_DIR" ]]; then
        log "Menyiapkan dan melakukan Build untuk Frontend..."

        if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
            run_apt_update_once
            log "Menginstal Node.js dan npm..."
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            apt install -y nodejs
        fi

        cd "$FE_DIR"

        if [[ -f "yarn.lock" ]]; then
            if ! command -v yarn &> /dev/null; then
                log "Menginstal Yarn secara global..."
                npm install -g yarn
            fi
            log "Menjalankan yarn install & yarn build..."
            yarn install
            yarn build
        else
            log "Menjalankan npm install & npm run build..."
            npm install
            npm run build
        fi

        cd - > /dev/null
    fi
}

setup_backend_venv() {
    if [[ -d "$BE_DIR" ]]; then
        log "Menyiapkan Python Virtual Environment untuk Backend..."

        if ! dpkg -l | grep -q python3-venv || ! command -v pip3 &> /dev/null; then
            run_apt_update_once
            log "Menginstal python3-pip dan python3-venv..."
            apt install -y python3-pip python3-venv
        fi

        cd "$BE_DIR"
        
        if [[ ! -d "venv" ]]; then
            log "Membuat folder venv baru..."
            python3 -m venv venv
        else
            log "Folder venv sudah ada."
        fi

        if [[ -f "requirements.txt" ]]; then
            log "Menginstal dependensi Python dari requirements.txt..."
            ./venv/bin/pip install --upgrade pip
            ./venv/bin/pip install -r requirements.txt
        else
            log "Peringatan: File requirements.txt tidak ditemukan di direktori backend!"
        fi
        
        cd - > /dev/null
    fi
}

clone_fe() {
    clone_or_update "$FE_DIR" "Frontend (lwi-fe)" "$FE_REPO"
    setup_frontend_build
}

clone_be() {
    clone_or_update "$BE_DIR" "Backend (lwi-be)" "$BE_REPO"
    setup_backend_venv
}

echo "=========================================="
echo "    SETUP CLONE REPOSITORY LWI FE & BE    "
echo "=========================================="
echo "1) Clone / Update & Build Frontend (FE) saja"
echo "2) Clone / Update & Setup venv Backend (BE) saja"
echo "3) Clone / Update & Build Keduanya (FE & BE)"
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

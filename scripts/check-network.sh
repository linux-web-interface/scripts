#!/usr/bin/env bash
# Read-only network and Apache diagnostics for Debian/Ubuntu/Linux Mint guests.
# This script does not change IP, DNS, firewall, or hypervisor settings.

set -u

section() { printf '\n=== %s ===\n' "$1"; }

section "Sistem"
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  printf 'OS: %s\n' "${PRETTY_NAME:-unknown}"
fi
printf 'Hostname: %s\n' "$(hostname 2>/dev/null || echo unknown)"

section "Antarmuka dan alamat IP"
if command -v ip >/dev/null 2>&1; then
  ip -brief address show || true
else
  echo "Perintah 'ip' tidak ditemukan (paket iproute2 biasanya menyediakan perintah ini)."
fi

section "Default route"
if command -v ip >/dev/null 2>&1; then
  ip route show default || echo "Default route tidak ditemukan."
fi

section "DNS"
if command -v resolvectl >/dev/null 2>&1; then
  resolvectl status 2>/dev/null | sed -n '1,32p' || true
elif [[ -r /etc/resolv.conf ]]; then
  grep -E '^(nameserver|search|domain)' /etc/resolv.conf || echo "Tidak ada entri nameserver/search yang terbaca."
fi

section "NetworkManager"
if command -v nmcli >/dev/null 2>&1; then
  nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true
  printf 'Connectivity: '
  nmcli -t -f CONNECTIVITY general 2>/dev/null || true
else
  echo "nmcli tidak tersedia; lewati pemeriksaan NetworkManager."
fi

section "Apache"
if command -v systemctl >/dev/null 2>&1; then
  APACHE_STATUS="$(systemctl is-active apache2 2>/dev/null || true)"
  printf 'Status apache2: %s\n' "${APACHE_STATUS:-tidak aktif atau systemd tidak tersedia}"
fi
if command -v ss >/dev/null 2>&1; then
  echo "Listener TCP terkait port 80/5000:"
  ss -ltnp 2>/dev/null | awk 'NR == 1 || $4 ~ /:(80|5000)$/ {print}'
fi
if command -v curl >/dev/null 2>&1; then
  printf 'HTTP lokal (http://127.0.0.1/): '
  curl --max-time 3 -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1/ 2>/dev/null || echo "gagal terhubung"
else
  echo "curl tidak tersedia; uji HTTP dilewati."
fi

section "Firewall UFW (bila terpasang)"
if command -v ufw >/dev/null 2>&1; then
  ufw status verbose 2>/dev/null || true
else
  echo "UFW tidak terpasang; skrip tidak mengubah firewall."
fi

section "Petunjuk"
echo "- Mode NAT VirtualBox: cek port-forwarding di host; browser host memakai http://127.0.0.1:8080/."
echo "- Mode Bridged: gunakan alamat IPv4 guest yang tampil di atas; pastikan firewall hanya membuka akses yang diperlukan."
echo "- Jangan mengatur IP/DNS statis jika DHCP dari hypervisor/router sudah berfungsi."
echo "- Skrip ini hanya membaca status; perubahan adapter NAT/Bridged dilakukan dari hypervisor pada host."

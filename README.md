# Linux Web Interface – Infrastructure Scripts

Repository ini berisi kumpulan script untuk membantu instalasi dan konfigurasi infrastruktur **Linux File Explorer**.

Linux File Explorer merupakan aplikasi berbasis web yang menyediakan antarmuka untuk berinteraksi dengan lingkungan Linux melalui browser. Linux berperan sebagai server, sedangkan perangkat Windows digunakan untuk mengakses aplikasi.

Proyek ini dikembangkan untuk lingkungan Linux berbasis CLI (tanpa Desktop Environment), dengan dukungan penggunaan pada mesin virtual maupun perangkat fisik.

## Project Architecture

Gambaran umum lingkungan sistem:

```text
Windows Host (Client)
        |
        | Browser
        |
   Host-only Network
        |
        v
Linux VM (Server)
        |
        +-- Apache (Web Server)
        |
        +-- Frontend (React + Vite)
        |
        +-- Backend (Python + Flask)
        |
        +-- PM2 (Process Management)
        |
        +-- Avahi (mDNS)
```

**Komponen utama:**
- **Apache:** Menyediakan layanan web dan direncanakan menangani reverse proxy untuk backend.
- **Frontend:** Antarmuka pengguna berbasis React dan Vite.
- **Backend:** Layanan API menggunakan Python dan Flask.
- **PM2:** Membantu mengelola proses aplikasi.
- **Avahi:** Memungkinkan akses server menggunakan hostname lokal berdomain `.local`.

Repository ini merupakan bagian dari proyek Linux File Explorer yang juga memiliki repository terpisah untuk frontend dan backend.

## Requirements

Sebelum menjalankan instalasi, pastikan tersedia:

- Linux berbasis Debian/Ubuntu.
- Akses terminal dengan hak akses `sudo`.
- Koneksi internet untuk proses instalasi.
- Git.
- VMware Workstation atau Oracle VirtualBox jika menggunakan virtual machine.

## Quick Setup

Jalankan perintah berikut melalui terminal Linux yang akan digunakan sebagai server:

```bash
rm -rf /scripts && cd / && git clone https://github.com/linux-web-interface/scripts.git && chmod +x scripts/*.sh && chmod +x scripts/scripts/*.sh && cd ./scripts && ./install.sh
```

Perintah tersebut akan mengunduh repository, memberikan izin eksekusi pada script, dan menjalankan installer utama.

> **Perhatian:** Perintah `rm -rf /scripts` akan menghapus direktori `/scripts` beserta seluruh isinya sebelum proses clone. Cadangkan perubahan lokal atau file penting terlebih dahulu.

## Setup / Update Scripts

Gunakan perintah berikut untuk mengambil ulang repository sebelum menjalankan instalasi atau konfigurasi:

```bash
rm -rf /scripts && cd / && git clone https://github.com/linux-web-interface/scripts.git && chmod +x scripts/*.sh && chmod +x scripts/scripts/*.sh
```

Setelah proses clone selesai, jalankan installer:

```bash
cd /scripts
./install.sh
```

## Network Configuration

Lingkungan utama yang digunakan adalah **Host-only Network**, sehingga Windows Host dan Linux VM dapat berkomunikasi melalui jaringan virtual yang sama.

Contoh konfigurasi alamat IP:

| Perangkat | Alamat IP |
|---|---|
| Linux VM | `192.168.1.1` |
| Windows Host | `192.168.1.2` |

Pengaturan Host-only Network dapat dilakukan melalui:

- **VMware:** Virtual Network Editor → VMnet1 → Host-only.
- **VirtualBox:** Network → Adapter → Host-only Adapter.

Jika Linux VM membutuhkan akses internet, adapter NAT dapat ditambahkan sebagai antarmuka jaringan tambahan. NAT bukan pengganti jaringan Host-only yang digunakan untuk komunikasi antara host dan guest.

## Supported Environments

Repository ini dapat digunakan pada beberapa lingkungan:

| Environment | Penggunaan |
|---|---|
| VMware Workstation | Menjalankan Linux sebagai VM server |
| Oracle VirtualBox | Menjalankan Linux sebagai VM server |
| Linux Bare Metal | Instalasi langsung pada perangkat fisik |
| Dual Boot | Pengembangan dan pengujian pada Linux secara lokal |

**Catatan:** Pada konfigurasi dual boot, Windows dan Linux tidak berjalan bersamaan. Untuk menguji komunikasi Host-to-Guest, gunakan virtual machine atau perangkat terpisah.

## Accessing the Application

Setelah layanan web berhasil dikonfigurasi, aplikasi dapat diakses dari browser Windows melalui alamat IP Linux VM atau hostname lokal jika layanan mDNS berhasil berjalan.

Contoh:

```text
http://192.168.1.1
http://linux-file-explorer.local
```

Hostname `.local` bergantung pada layanan Avahi di Linux dan dukungan resolusi mDNS pada Windows.

## Troubleshooting

Beberapa hal yang perlu diperiksa jika aplikasi tidak dapat diakses:

| Masalah | Pemeriksaan |
|---|---|
| Windows tidak dapat mengakses Linux | Periksa konfigurasi Host-only dan alamat IP |
| Hostname `.local` tidak ditemukan | Periksa layanan Avahi dan dukungan mDNS |
| Halaman web tidak terbuka | Periksa status Apache |
| API tidak dapat diakses | Periksa proses backend dan konfigurasi reverse proxy |
| Koneksi ditolak | Periksa firewall dan port layanan |

Jika menggunakan UFW, pastikan port yang diperlukan telah diizinkan. Khusus akses SSH, izinkan port 22 sebelum mengaktifkan firewall apabila SSH masih dibutuhkan.

## Development Status

Linux File Explorer masih dalam tahap pengembangan.

- Infrastruktur dan konfigurasi layanan sedang dikembangkan.
- Frontend dikembangkan menggunakan React dan Vite.
- Backend dikembangkan menggunakan Python dan Flask.
- Integrasi frontend dan backend masih dalam proses pengembangan.

Keberhasilan menjalankan installer tidak secara otomatis berarti seluruh fitur aplikasi telah berfungsi. Pengujian layanan dan integrasi tetap diperlukan.

## Related Repositories

| Repository | Deskripsi |
|---|---|
| [scripts](https://github.com/linux-web-interface/scripts) | Instalasi dan konfigurasi infrastruktur |
| [backend](https://github.com/linux-web-interface/backend) | Layanan backend dan API |
| [frontend](https://github.com/linux-web-interface/frontend) | Antarmuka pengguna aplikasi |

---

**Linux File Explorer** – Web-based interface for Linux CLI environments.

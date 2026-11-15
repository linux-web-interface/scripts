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

## Panduan Jaringan Tambahan untuk Hypervisor

Bagian ini melengkapi pengaturan jaringan di atas untuk hypervisor yang digunakan selain VMware. Nama menu dapat sedikit berbeda bergantung pada versi aplikasi.

**Catatan alamat IP:** alamat `192.168.1.1` dan `192.168.1.2` pada contoh sebelumnya bukan alamat wajib. Gunakan alamat yang berada dalam subnet jaringan virtual yang benar-benar dibuat oleh hypervisor. Pastikan alamat tersebut tidak bertabrakan dengan perangkat lain atau rentang DHCP.

### Oracle VirtualBox

Untuk menghubungkan host secara langsung ke Linux VM melalui jaringan privat:

1. Buka **Tools → Network** atau **Network Manager** pada VirtualBox Manager.
2. Pada bagian **Host-only Networks**, buat jaringan host-only baru apabila belum tersedia.
3. Matikan VM, lalu buka **Settings → Network → Adapter 1**.
4. Aktifkan **Enable Network Adapter** dan pilih **Host-only Adapter** atau **Host-only Network** pada bagian **Attached to**. Pilih nama jaringan host-only yang dibuat pada langkah sebelumnya.
5. Di dalam Linux VM, gunakan DHCP apabila DHCP server pada jaringan host-only diaktifkan. Jika menggunakan IP statis, pilih alamat dalam subnet yang sama dan di luar rentang DHCP.
6. Periksa alamat guest dari terminal Linux dengan `ip -br -4 address`, lalu akses alamat tersebut dari browser host, misalnya `http://ALAMAT-IP-LINUX-VM`.

Jika Linux VM juga membutuhkan akses internet, aktifkan **Adapter 2** dan pilih **NAT**. Dalam susunan ini, Adapter 1 digunakan untuk komunikasi host-to-guest, sedangkan Adapter 2 menyediakan akses internet bagi guest. Pastikan konfigurasi route di guest tidak menyebabkan konflik.

Dokumentasi resmi: [Oracle VirtualBox 7.2 – Virtual Networking](https://docs.oracle.com/en/virtualization/virtualbox/7.2/user/networkingdetails.html).

### QEMU

QEMU menyediakan beberapa backend jaringan. Untuk percobaan awal yang hanya memerlukan browser pada komputer host untuk membuka Apache di guest, cara paling sederhana adalah **User-mode networking dengan port forwarding**.

Tambahkan opsi berikut ke perintah yang digunakan untuk menjalankan QEMU:

```bash
-nic user,hostfwd=tcp:127.0.0.1:8080-:80
```

Konfigurasi tersebut meneruskan koneksi TCP pada `127.0.0.1:8080` di host ke port TCP `80` di Linux guest. Dengan asumsi Apache berjalan dan mendengarkan pada port `80`, buka alamat berikut pada browser komputer host:

```text
http://127.0.0.1:8080
```

Keterangan:

- Port `8080` adalah port pada host; port tersebut harus belum digunakan oleh aplikasi lain.
- Port `80` adalah port Apache di guest. Sesuaikan bagian ini apabila Apache menggunakan port yang berbeda.
- QEMU User-mode networking menyediakan konfigurasi jaringan guest melalui mekanisme internal QEMU; metode ini tidak memerlukan alamat IP Host-only statis seperti contoh pada bagian sebelumnya.
- Pengikatan ke `127.0.0.1` membatasi akses melalui komputer host itu sendiri. Perangkat lain di LAN tidak dapat menggunakan alamat loopback host tersebut untuk mengakses aplikasi.

Apabila proyek membutuhkan guest menjadi perangkat pada jaringan host atau membutuhkan jaringan privat bergaya Host-only, QEMU dapat menggunakan backend **TAP** yang dihubungkan ke interface/bridge pada host. Konfigurasinya lebih bergantung pada sistem operasi host dan hak akses jaringan. Pada Windows, QEMU memerlukan driver TAP yang sesuai dan tidak menyertakannya sebagai bagian dari QEMU standar; pada Linux, host perlu mendukung interface TAP melalui `/dev/net/tun`. Karena itu, gunakan TAP sebagai konfigurasi lanjutan setelah kebutuhan jaringan dan sistem operasi host ditentukan.

Dokumentasi resmi: [QEMU – Network emulation](https://www.qemu.org/docs/master/system/devices/net.html) dan [QEMU – System invocation (`hostfwd`)](https://www.qemu.org/docs/master/system/qemu-manpage.html).

### Memilih mode jaringan

| Mode | Cara host mengakses web guest | Kegunaan |
|---|---|---|
| Host-only | Melalui alamat IP guest pada jaringan virtual | Komunikasi privat langsung antara host dan guest |
| NAT + port forwarding | Melalui alamat host dan port yang diteruskan, misalnya `127.0.0.1:8080` | Akses layanan guest dari host tanpa mengekspos guest langsung ke LAN |
| Bridged | Melalui alamat IP guest pada jaringan LAN | Saat guest perlu tampak sebagai perangkat tersendiri di jaringan lokal |
| QEMU TAP/bridge | Melalui alamat IP guest pada jaringan yang dihubungkan ke TAP/bridge | Kebutuhan jaringan QEMU yang lebih lanjut; perlu konfigurasi pada host |

Pilih satu metode berdasarkan kebutuhan pengujian dan samakan metode tersebut dengan konfigurasi pada script. Jangan mengasumsikan bahwa alamat IP guest atau cara akses dari browser sama untuk Host-only, NAT port forwarding, dan Bridged.

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

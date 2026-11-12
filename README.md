# Linux Web Interface – Infrastructure Scripts

Repository ini berisi kumpulan script untuk membantu proses instalasi, konfigurasi, dan pemeriksaan infrastruktur **Linux File Explorer**.

Linux File Explorer merupakan aplikasi berbasis web yang dirancang untuk menyediakan antarmuka grafis bagi lingkungan Linux berbasis **Command-Line Interface (CLI)**. Linux berperan sebagai server yang menjalankan layanan web dan backend, sedangkan pengguna dapat mengakses aplikasi melalui browser dari perangkat lain.

Proyek ini menargetkan distribusi Linux berbasis Debian/Ubuntu, seperti Ubuntu Server dan Linux Mint, serta mendukung lingkungan virtualisasi maupun instalasi Linux secara langsung pada perangkat fisik.

**Lingkungan virtualisasi yang didukung:**
- VMware Workstation.
- Oracle VirtualBox.

**Metode konektivitas utama:** Host-only Network dengan dukungan Avahi/mDNS untuk mengakses server menggunakan hostname berdomain `.local`.

> **Status Pengembangan:** Repository ini masih dalam tahap pengembangan dan pengujian. Keberhasilan menjalankan script instalasi belum menjamin seluruh komponen aplikasi berfungsi dengan baik. Pengujian layanan, konektivitas jaringan, dan integrasi aplikasi tetap diperlukan.

---

## Cara Setup Cepat

Untuk memulai instalasi dan konfigurasi infrastruktur Linux File Explorer, jalankan perintah berikut melalui terminal Linux yang akan digunakan sebagai server.

```bash
rm -rf /scripts && cd / && git clone https://github.com/linux-web-interface/scripts.git && chmod +x scripts/*.sh && chmod +x scripts/scripts/*.sh && cd ./scripts && ./install.sh
```

Perintah tersebut akan mengambil repository, memberikan izin eksekusi pada script, dan menjalankan installer utama.

Pastikan sistem memiliki koneksi internet dan akses `sudo` selama proses instalasi.

## Cara Setup / Update Script

Bagian ini digunakan untuk mengambil atau memperbarui source code script dari repository GitHub sebelum menjalankan proses instalasi.

Jalankan perintah berikut melalui terminal Linux:

```bash
rm -rf /scripts && cd / && git clone https://github.com/linux-web-interface/scripts.git && chmod +x scripts/*.sh && chmod +x scripts/scripts/*.sh
```

Setelah repository berhasil diunduh, masuk ke direktori repository dan jalankan installer:

```bash
cd /scripts
./install.sh
```

> **Catatan:** Perintah `rm -rf /scripts` akan menghapus direktori `/scripts` beserta isinya sebelum melakukan clone ulang. Pastikan tidak ada perubahan lokal atau file penting yang belum dicadangkan.

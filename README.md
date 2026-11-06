# Linux File Explorer - Paket Skrip Infrastruktur MVP

Paket ini menyiapkan lapisan web dan membantu pemeriksaan jaringan untuk proyek **Linux File Explorer**. Target sistem adalah Debian/Ubuntu/Linux Mint. Untuk rancangan demo VM, contoh koneksi yang disediakan khusus untuk **Oracle VirtualBox dengan NAT + port forwarding**.

> **Status:** skrip dan dokumentasi awal sudah dibuat serta pemeriksaan sintaks Bash sudah dilakukan. Skrip belum dijalankan pada Linux Mint milik kelompok dan belum diuji pada VM sebenarnya. Jangan menganggap instalasi berhasil sebelum uji lokal dan uji dari Windows selesai.

## Cara Setup Cepat

Untuk memulai penyiapan infrastruktur dan server web secara otomatis, jalankan perintah berikut di terminal Linux VM Anda:

```bash
rm -rf ./scripts && cd / && git clone https://github.com/linux-web-interface/scripts.git && chmod +x scripts/*.sh && cd ./scripts && ./install.sh
```

## 1. Sasaran MVP

MVP hanya menampilkan daftar file/folder dari satu direktori yang diizinkan di Linux. MVP belum boleh menghapus, mengunggah, mengubah, atau menjalankan perintah sistem.

Alur yang disarankan:

```text
Browser Windows
    |
    | http://127.0.0.1:8080/
    v
VirtualBox NAT port forwarding
    |  host 127.0.0.1:8080 -> guest TCP :80
    v
Linux guest: Apache :80
    |                         \
    | file frontend             \ /api/*
    v                              v
HTML/CSS/JavaScript         Python API :5000
                                   |
                                   v
                         Direktori yang diizinkan
                         (read-only untuk MVP)
```

Apache menjadi pintu masuk tunggal dari browser. Apache menyajikan berkas frontend dan meneruskan permintaan `/api/` ke Python pada `127.0.0.1:5000`. Backend Python sebaiknya hanya bind ke loopback (`127.0.0.1`), bukan ke semua antarmuka jaringan.

## 2. Keputusan teknologi yang perlu dikunci

Ada satu hal yang belum konsisten pada pembagian kerja: **Python disebut sebagai backend, sedangkan Laravel disebut sebagai frontend**. Laravel merupakan framework aplikasi PHP yang dapat menangani routing, controller, dan backend web juga; ia bukan sekadar library antarmuka browser. Menggabungkan Laravel dan Python tetap mungkin, tetapi berarti ada dua aplikasi server yang harus diintegrasikan.

Untuk tenggat 19 hari dan pengalaman tim yang masih dasar, jalur paling rendah risiko adalah:

1. MVP: frontend HTML/CSS/JavaScript sederhana; backend API Python; Apache sebagai web server/reverse proxy.
2. Setelah alur baca file berhasil: evaluasi apakah Laravel benar-benar diperlukan.
3. Jika Laravel tetap dipakai, tim harus menambahkan runtime PHP, Composer, dependensi Laravel, dan konfigurasi Apache/PHP. Paket skrip ini **belum** memasang komponen tersebut.

Jangan mulai dengan dua framework sebelum antarmuka API antara Laravel dan Python ditetapkan. Sepakati minimal endpoint seperti `GET /api/health` dan `GET /api/files` terlebih dahulu.

## 3. Isi paket

| Berkas | Fungsi | Dijalankan di |
|---|---|---|
| `scripts/setup-apache.sh` | Memasang Apache, membuat document root, mengaktifkan modul, membuat VirtualHost, dan meneruskan `/api/` ke Python | Linux guest / Linux Mint untuk uji lokal |
| `scripts/check-network.sh` | Menampilkan IP, route, DNS, NetworkManager, status Apache, port listener, dan status UFW; tidak mengubah sistem | Linux guest |
| `scripts/setup-virtualbox-nat.ps1` | Mengatur Adapter 1 VirtualBox ke NAT dan meneruskan host `127.0.0.1:8080` ke guest `:80` | Windows host, khusus VirtualBox |
| `web-demo/index.html` | Halaman sementara untuk memverifikasi bahwa Apache dapat menyajikan frontend | Disalin otomatis jika document root belum punya `index.html` atau `index.php` |
| `docs/STATUS_HANDOFF.md` | Tujuan, progres, keputusan, risiko, dan konteks untuk sesi kerja berikutnya | Dokumentasi |

## 4. Menjalankan uji lokal di Linux Mint

Linux Mint yang digunakan sebagai dual-boot dapat dipakai untuk mengembangkan dan menguji Apache langsung tanpa VM. Uji lokal ini membuktikan Apache aktif, tetapi **belum** membuktikan koneksi Windows-host ke guest VM.

Dari folder paket:

```bash
chmod +x scripts/*.sh
sudo ./scripts/setup-apache.sh
./scripts/check-network.sh
```

Kemudian buka browser di Linux Mint dan akses:

```text
http://127.0.0.1/
```

Halaman `Linux File Explorer` harus tampil. Status API mungkin menyatakan API belum berjalan; itu normal sampai anggota backend membuat dan menjalankan endpoint `GET /api/health` pada `127.0.0.1:5000`.

Uji dari terminal:

```bash
curl -I http://127.0.0.1/
sudo apache2ctl configtest
sudo systemctl status apache2 --no-pager
```

Skrip setup membutuhkan koneksi internet untuk mengambil paket Apache melalui APT. Skrip juga memerlukan akses `sudo` karena mengubah konfigurasi di `/etc/apache2` dan `/var/www`.

## 5. Menyambungkan VM VirtualBox ke Windows host

### Pengaturan yang disarankan: NAT + port forwarding

Pada VirtualBox, Adapter 1 perlu menggunakan **NAT**. Dengan NAT biasa, koneksi dari luar guest tidak otomatis dapat masuk ke server guest. Port forwarding membuat satu port host diteruskan ke port guest. Manual VirtualBox menjelaskan penggunaan `VBoxManage modifyvm --natpf1` untuk membuat aturan tersebut.

Cara otomatis di Windows host (VM harus dalam keadaan **Powered Off**):

```powershell
.\scripts\setup-virtualbox-nat.ps1 -VMName "NAMA_VM_ANDA"
```

Nilai bawaan skrip:

- Host bind: `127.0.0.1`
- Host port: `8080`
- Guest port: `80`
- Adapter: `1`, mode `NAT`

Setelah VM dinyalakan dan Apache aktif, buka di Windows:

```text
http://127.0.0.1:8080/
```

Jika nama VM belum diketahui, lihat daftar VM di VirtualBox Manager. Jangan menebak nama VM. Bila tim tidak menggunakan VirtualBox, jangan jalankan skrip PowerShell ini; gunakan pengaturan jaringan sesuai hypervisor yang benar.

### Pilihan lain

| Mode | Konektivitas | Penilaian untuk MVP |
|---|---|---|
| NAT + port forwarding | Guest mendapat akses jaringan; Windows host mengakses web melalui port host yang diteruskan | **Rekomendasi.** Tidak perlu menetapkan IP guest statis. Bind host ke `127.0.0.1` agar tidak terbuka ke LAN. |
| Bridged | Guest menjadi perangkat di LAN dan memperoleh IP dari router/DHCP | Bisa dipakai jika perlu diakses perangkat lain, tetapi alamat guest dapat berubah dan layanan lebih terekspos ke jaringan lokal. |
| Host-only | Host dan guest berada di jaringan privat virtual | Cocok untuk lab terisolasi; akses internet guest biasanya perlu adapter NAT kedua. |

Jangan mengatur IP atau DNS statis untuk MVP. Biarkan DHCP dari NAT/VirtualBox atau router memberikan konfigurasi jaringan. Untuk NAT port forwarding, browser Windows menggunakan `127.0.0.1:8080`; alamat IP guest tidak perlu dimasukkan ke browser.

### Catatan dual-boot

Windows dan Linux Mint yang dipasang sebagai dual-boot tidak berjalan bersamaan. Saat laptop boot ke Linux Mint, Windows host tidak aktif. Karena itu, pengujian `Windows host -> Linux guest` baru dapat dilakukan pada komputer yang menjalankan Windows dan VM secara bersamaan, atau pada perangkat uji terpisah. Mengakses `localhost` di Linux Mint hanya menguji server lokal di Linux Mint itu sendiri.

## 6. Pemeriksaan dan pemecahan masalah

| Gejala | Pemeriksaan awal |
|---|---|
| `curl http://127.0.0.1/` gagal | Jalankan `sudo systemctl status apache2`; periksa `sudo apache2ctl configtest`; lihat log `/var/log/apache2/`. |
| Halaman tampil tetapi status API gagal | Backend belum berjalan, port Python bukan `5000`, atau route `/api/health` belum dibuat. Samakan kontrak API dan `BACKEND_PORT`. |
| Windows tidak dapat membuka `127.0.0.1:8080` | Pastikan VM hidup, Adapter 1 NAT, aturan port forwarding benar, Apache aktif pada guest, dan port host `8080` tidak dipakai aplikasi lain. |
| Bridged tidak dapat diakses | Cek alamat IPv4 guest lewat `./scripts/check-network.sh`, pastikan host dan guest berada pada jaringan yang dapat saling menjangkau, dan periksa firewall. |
| UFW aktif dan koneksi HTTP diblokir | Pada VM lab yang memang digunakan untuk demo, aturan HTTP dapat ditambahkan secara sadar dengan `sudo ufw allow 80/tcp`. Jangan membuka layanan lebih luas dari yang diperlukan. |

Perintah diagnosis:

```bash
./scripts/check-network.sh
sudo journalctl -u apache2 -n 50 --no-pager
sudo tail -n 50 /var/log/apache2/linux-file-explorer-error.log
```

Skrip `check-network.sh` bersifat **read-only**. Ia tidak mengubah IP, DNS, firewall, maupun adapter virtual.

## 7. Batas keamanan MVP

1. Backend hanya boleh membaca satu direktori dasar yang ditentukan tim, misalnya direktori demo khusus; jangan langsung mengekspos seluruh `/`.
2. Validasi path di backend agar permintaan tidak dapat keluar dari direktori dasar tersebut. Jangan mengandalkan frontend untuk validasi keamanan.
3. Tolak atau tangani symlink dengan hati-hati agar file di luar direktori dasar tidak ikut terbaca.
4. Backend berjalan sebagai user biasa dan bind ke `127.0.0.1:5000`; jangan menjalankan Python API dengan `sudo`.
5. Jangan menambahkan fitur hapus, tulis, upload, atau eksekusi command ke MVP pertama.
6. Untuk fitur command di masa depan, jangan menyediakan shell bebas dari browser. Gunakan aksi terbatas yang ditentukan sebelumnya, validasi input, otorisasi, dan pencatatan aktivitas.

## 8. Kriteria uji minimal

| ID | Skenario | Hasil yang diharapkan |
|---|---|---|
| T01 | Apache dijalankan dan `curl -I http://127.0.0.1/` dipanggil di Linux | HTTP `200` untuk halaman demo |
| T02 | `sudo apache2ctl configtest` dijalankan | `Syntax OK` |
| T03 | Windows membuka `http://127.0.0.1:8080/` melalui NAT forwarding | Halaman demo yang sama tampil di browser Windows |
| T04 | Backend belum dijalankan, halaman demo memanggil `/api/health` | UI memberi status API belum tersedia; Apache tetap menyajikan halaman |
| T05 | Backend sudah berjalan dan endpoint health tersedia | `/api/health` diteruskan ke Python dan menerima respons sukses |

Skenario T01–T05 perlu dicatat hasil aktualnya oleh QA; jangan menandai lulus hanya karena skrip berhasil dijalankan.

## 9. Git minimum untuk kerja kelompok

Gunakan satu repositori bersama. Setiap orang mengubah file miliknya, lalu commit dengan pesan yang menjelaskan perubahan.

```bash
git status
git add scripts/setup-apache.sh
git commit -m "Add Apache setup script"
git push
```

Untuk mulai dari repo yang sudah dibuat ketua kelompok:

```bash
git clone URL_REPOSITORY
cd NAMA_FOLDER_REPOSITORY
git status
```

Hindari mengedit file yang sama secara bersamaan. Jangan masukkan password, token, atau credential ke repositori. Sebelum menggabungkan perubahan orang lain, jalankan pemeriksaan sintaks dan skenario uji yang relevan.

## 10. Referensi teknis

- Oracle VM VirtualBox User Manual 7.2, *Virtual Networking*: https://docs.oracle.com/en/virtualization/virtualbox/7.2/user/networkingdetails.html
- Apache HTTP Server, *Reverse Proxy Guide*: https://httpd.apache.org/docs/current/en/howto/reverse_proxy.html
- NetworkManager Reference Manual, `nmcli`: https://networkmanager.pages.freedesktop.org/NetworkManager/NetworkManager/nmcli.html

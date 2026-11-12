## 1. Project Overview

**Linux Web Interface (LWI)** adalah proyek yang bertujuan menyediakan antarmuka berbasis web untuk berinteraksi dengan lingkungan Linux yang berjalan menggunakan **Command-Line Interface (CLI)**.

Melalui aplikasi ini, pengguna dapat mengakses antarmuka Linux menggunakan browser dari perangkat lain tanpa harus menggunakan Desktop Environment pada mesin Linux.

Linux berperan sebagai server yang menjalankan layanan web dan backend, sedangkan perangkat pengguna berperan sebagai client yang mengakses aplikasi melalui jaringan.

### Tujuan Proyek

- Menyediakan antarmuka grafis berbasis web untuk lingkungan Linux CLI.
- Memungkinkan pengguna mengakses layanan Linux melalui browser.
- Mengintegrasikan frontend dan backend melalui REST API.
- Memanfaatkan Apache sebagai web server dan reverse proxy.
- Menggunakan Avahi untuk menyediakan resolusi hostname melalui mDNS (`.local`).

### Status Pengembangan

Proyek masih dalam tahap pengembangan. Beberapa komponen infrastruktur telah disiapkan, sementara integrasi frontend dan backend masih dalam proses pengerjaan.

---

## 2. Project Architecture

### 2.1. System Architecture

Arsitektur proyek menggunakan model **Client–Server**, dengan Linux sebagai server dan perangkat lain sebagai client.

Komponen utama:

| Komponen | Teknologi | Fungsi |
|---|---|---|
| Server OS | Debian / Ubuntu / Linux Mint | Menjalankan lingkungan Linux CLI |
| Web Server | Apache HTTP Server | Menyajikan frontend dan meneruskan request API |
| Frontend | React + Vite | Menyediakan antarmuka pengguna berbasis web |
| Backend | Python + Flask | Menyediakan layanan dan API untuk mengakses filesystem |
| Process Manager | PM2 | Mengelola proses backend |
| Name Resolution | Avahi / mDNS | Menyediakan hostname dengan domain `.local` |
| Networking | Host-only Network | Menghubungkan Linux VM dengan Windows Host |

### 2.2. Communication Flow

Alur komunikasi sistem dirancang sebagai berikut:

```text
+--------------------------------------+
|             Windows Host             |
|                                      |
|  Browser                             |
|  http://<hostname>.local             |
|                                      |
|  IP: 192.168.1.2                     |
+------------------+-------------------+
                   |
                   | Host-only Network
                   |
+------------------v-------------------+
|              Linux VM                |
|                                      |
|  IP: 192.168.1.1                     |
|                                      |
|  +--------------------------------+  |
|  |       Apache HTTP Server       |  |
|  |             :80                |  |
|  +---------------+----------------+  |
|                  |                   |
|          +-------+-------+           |
|          |               |           |
|          v               v           |
|     Frontend          Backend        |
|     React/Vite        Flask          |
|     Static Files      API :5000      |
|                          |           |
|                          v           |
|                      Filesystem      |
|                                      |
|  Avahi / mDNS                         |
|  <hostname>.local                    |
+--------------------------------------+
```

**Penjelasan alur:**

1. Pengguna membuka browser pada Windows Host.
2. Windows melakukan resolusi hostname `.local` melalui mDNS.
3. Avahi pada Linux mengumumkan hostname dan alamat IP server.
4. Browser mengirimkan HTTP request menuju Apache.
5. Apache menyajikan frontend yang telah dibangun menggunakan Vite.
6. Request dengan prefix `/api/` diteruskan ke backend Flask.
7. Backend memproses request dan berinteraksi dengan filesystem Linux.

> Catatan: Integrasi frontend dan backend masih dalam tahap pengembangan. Diagram di atas menggambarkan arsitektur integrasi yang dituju, bukan seluruh fitur yang telah selesai diimplementasikan.

---

## 3. System Requirements

### 3.1. Linux Server

Sistem operasi yang digunakan harus berbasis Debian atau Ubuntu dan memiliki dukungan APT package manager.

| Kebutuhan | Keterangan |
|---|---|
| Operating System | Debian / Ubuntu / Linux Mint |
| Interface | CLI (tanpa Desktop Environment) |
| Package Manager | APT |
| Web Server | Apache HTTP Server |
| Runtime | Node.js, Python 3 |
| Process Manager | PM2 |
| Network Service | Avahi Daemon |
| Network Interface | Minimal satu interface aktif |

Koneksi internet diperlukan selama proses instalasi untuk mengunduh repository, package, dan dependensi aplikasi.

### 3.2. Client Device

Perangkat client menggunakan Windows dengan persyaratan:

- Web browser modern.
- Koneksi jaringan yang dapat menjangkau Linux Server.
- Dukungan resolusi hostname mDNS untuk mengakses domain `.local`.
- Konfigurasi IP sesuai jaringan yang digunakan.

### 3.3. Virtualization Software

Proyek mendukung beberapa lingkungan virtualisasi:

- VMware Workstation.
- Oracle VirtualBox.

Konfigurasi jaringan pada masing-masing hypervisor dijelaskan pada bagian berikutnya.

---

## 4. Supported Environments

Linux Web Interface dirancang untuk berjalan pada lingkungan Linux CLI. Terdapat beberapa skenario penggunaan yang dapat diterapkan.

### 4.1. VMware Workstation

VMware Workstation dapat digunakan untuk menjalankan Linux sebagai Guest OS di dalam Windows Host.

Konfigurasi jaringan yang digunakan adalah **Host-only Network (VMnet1)**.

Karakteristik:

- Linux VM berperan sebagai server.
- Windows Host berperan sebagai client.
- Kedua sistem terhubung melalui VMnet1.
- IP Linux menggunakan `192.168.1.1`.
- IP Windows menggunakan `192.168.1.2`.
- Akses aplikasi menggunakan hostname `.local`.

### 4.2. Oracle VirtualBox

Oracle VirtualBox juga dapat digunakan dengan konfigurasi jaringan **Host-only Adapter**.

Karakteristik:

- Linux VM berperan sebagai server.
- Windows Host berperan sebagai client.
- Kedua sistem terhubung melalui Host-only Network.
- IP Linux menggunakan `192.168.1.1`.
- IP Windows menggunakan `192.168.1.2`.
- Akses aplikasi menggunakan hostname `.local`.

Pastikan DHCP pada jaringan Host-only tidak memberikan alamat yang bertabrakan dengan konfigurasi IP statis.

### 4.3. Linux Bare Metal / Dual Boot

Linux juga dapat dijalankan secara langsung pada perangkat fisik tanpa menggunakan hypervisor.

Skenario ini dapat digunakan untuk pengembangan dan pengujian lokal.

Karakteristik:

- Linux berjalan langsung pada perangkat.
- Apache dan backend dijalankan pada sistem Linux.
- Aplikasi dapat diakses melalui `localhost`.
- Akses dari perangkat lain dapat dilakukan melalui jaringan lokal apabila konfigurasi jaringan dan firewall memungkinkan.

Pada skenario dual boot, Windows dan Linux tidak dapat berjalan bersamaan pada satu perangkat. Oleh karena itu, pengujian komunikasi Windows Host ke Linux Guest memerlukan lingkungan virtualisasi atau perangkat terpisah.

---

## 5. Network Configuration

### 5.1. Host-only Network

Host-only Network merupakan jaringan virtual yang memungkinkan komunikasi antara host dan guest tanpa menjadikan guest sebagai perangkat yang langsung terhubung ke jaringan eksternal melalui adapter tersebut.

Konfigurasi ini digunakan sebagai jalur komunikasi utama antara Windows dan Linux VM.

### 5.2. IP Address Configuration

Gunakan konfigurasi berikut untuk lingkungan pengujian:

| Perangkat | IP Address | Subnet Mask |
|---|---|---|
| Linux VM | `192.168.1.1` | `255.255.255.0` |
| Windows Host | `192.168.1.2` | `255.255.255.0` |

Pastikan subnet tersebut tidak bertabrakan dengan jaringan lokal lain yang digunakan pada perangkat.

Untuk jaringan Host-only yang terisolasi, default gateway dan DNS tidak diperlukan untuk komunikasi langsung antara host dan guest.

Jika Linux VM tetap membutuhkan akses internet, gunakan adapter jaringan tambahan dengan mode NAT.

### 5.3. VMware Workstation Configuration

1. Buka VMware Workstation.
2. Masuk ke Virtual Network Editor.
3. Pilih atau buat jaringan `VMnet1`.
4. Atur network type menjadi `Host-only`.
5. Sesuaikan subnet dengan jaringan `192.168.1.0/24`.
6. Pastikan Windows Host memiliki adapter VMnet1.
7. Atur IPv4 adapter VMnet1 pada Windows menjadi:

```text
IP Address      : 192.168.1.2
Subnet Mask     : 255.255.255.0
Default Gateway : (Kosong)
DNS Server      : (Kosong)
```

8. Pada pengaturan virtual machine, pilih Network Adapter yang menggunakan `Custom: VMnet1`.

Jika terdapat adapter yang tidak digunakan untuk komunikasi host–guest, adapter tersebut dapat diatur ke mode Host-only sesuai kebutuhan konfigurasi VM.

### 5.4. Oracle VirtualBox Configuration

1. Buka Oracle VirtualBox.
2. Masuk ke menu Network pada pengaturan VirtualBox.
3. Buat atau pilih Host-only Network.
4. Pastikan Host-only Network aktif.
5. Sesuaikan alamat IPv4 adapter Windows menjadi:

```text
IP Address      : 192.168.1.2
Subnet Mask     : 255.255.255.0
Default Gateway : (Kosong)
DNS Server      : (Kosong)
```

6. Buka pengaturan virtual machine.
7. Pilih Network.
8. Aktifkan Network Adapter yang menggunakan mode `Host-only Adapter`.
9. Pilih Host-only Network yang telah dibuat.

Jika menggunakan DHCP bawaan VirtualBox, pastikan konfigurasi DHCP tidak bertabrakan dengan alamat IP statis yang digunakan.

### 5.5. Linux Network Configuration

Linux VM harus menggunakan alamat IPv4 `192.168.1.1` pada interface yang terhubung dengan jaringan Host-only.

Installer menyediakan mekanisme pemilihan interface untuk konfigurasi mDNS dan mencoba menambahkan konfigurasi IP statis melalui `/etc/network/interfaces` apabila file tersebut tersedia.

Namun, konfigurasi jaringan Linux dapat berbeda tergantung distribusi dan network manager yang digunakan.

Pastikan interface yang dipilih benar-benar merupakan interface Host-only, bukan interface NAT atau interface jaringan lainnya.

Verifikasi konfigurasi:

```bash
ip -brief address
ip route
```

Pastikan interface Host-only memiliki alamat:

```text
192.168.1.1/24
```

---

## 6. Apache Configuration

Apache HTTP Server digunakan sebagai pintu masuk utama untuk mengakses aplikasi melalui browser.

Tanggung jawab Apache:

1. Menyajikan frontend React yang telah di-build.
2. Menerima HTTP request dari client.
3. Meneruskan request API ke backend Flask.
4. Mengelola VirtualHost untuk aplikasi.

### 6.1. Frontend Document Root

Frontend ditempatkan pada:

```text
/var/www/lwi-fe
```

Hasil build Vite berada pada:

```text
/var/www/lwi-fe/dist
```

Apache menggunakan direktori `dist` sebagai DocumentRoot.

### 6.2. Backend Reverse Proxy

Apache meneruskan request dengan prefix `/api/` menuju backend:

```text
http://127.0.0.1:5000
```

Contoh alur:

```text
Browser
   |
   | GET /api/dir
   v
Apache :80
   |
   | Reverse Proxy
   v
Flask :5000
```

Dengan pendekatan ini, client cukup mengakses satu alamat web melalui Apache tanpa harus mengakses port backend secara langsung.

Konfigurasi Apache dikelola melalui:

```text
/etc/apache2/sites-available/
```

File konfigurasi dibuat oleh script `setup-apache.sh`.

---

## 7. Backend Configuration

Backend menggunakan Python dan Flask untuk menyediakan API yang berinteraksi dengan filesystem Linux.

### 7.1. Technology Stack

| Teknologi | Fungsi |
|---|---|
| Python 3 | Bahasa pemrograman backend |
| Flask | Web framework dan REST API |
| Flask-CORS | Pengaturan Cross-Origin Resource Sharing |
| PM2 | Process management |
| Python Virtual Environment | Isolasi dependensi Python |

### 7.2. Backend Directory

Backend ditempatkan pada:

```text
/opt/lwi-be
```

Struktur utamanya:

```text
lwi-be/
├── api/
│   └── browse_routes.py
├── venv/
├── app.py
├── ecosystem.config.js
└── requirements.txt
```

### 7.3. API Endpoints

Endpoint yang tersedia pada implementasi backend saat ini:

| Method | Endpoint | Fungsi |
|---|---|---|
| GET | `/api/dir` | Mengambil daftar item dari direktori yang ditentukan dalam konfigurasi backend |
| GET | `/api/browse/<dir_name>` | Menampilkan isi direktori |
| GET | `/api/browse/<dir_name>/<subpath>` | Menelusuri subdirektori atau mengunduh file |

Endpoint tersebut masih dalam tahap pengembangan dan belum menjadi kontrak API final.

### 7.4. Process Management

Backend dikelola menggunakan PM2 dengan konfigurasi:

```text
ecosystem.config.js
```

Nama proses:

```text
lwi-backend
```

Beberapa perintah untuk memeriksa proses:

```bash
pm2 status
pm2 logs lwi-backend
pm2 restart lwi-backend
pm2 save
```

Script `start-all.sh` digunakan untuk menjalankan atau me-restart Apache dan backend melalui PM2.

---

## 8. Frontend Configuration

Frontend dikembangkan menggunakan React dan Vite.

Frontend berfungsi sebagai antarmuka grafis yang diakses melalui browser.

### 8.1. Technology Stack

| Teknologi | Fungsi |
|---|---|
| React | Library antarmuka pengguna |
| Vite | Development server dan build tool |
| JavaScript | Bahasa pemrograman frontend |
| CSS | Styling antarmuka |

### 8.2. Frontend Directory

Frontend ditempatkan pada:

```text
/var/www/lwi-fe
```

Hasil build:

```text
/var/www/lwi-fe/dist
```

Proses build menggunakan:

```bash
npm install
npm run build
```

### 8.3. Integration Status

Frontend dan backend masih dalam tahap pengembangan integrasi.

Frontend saat ini berfokus pada pengembangan antarmuka grafis, sedangkan backend mengembangkan layanan API untuk mengakses filesystem Linux.

Integrasi kedua komponen akan dilakukan melalui API yang diteruskan oleh Apache Reverse Proxy.

---

## 9. Avahi and mDNS Configuration

Avahi digunakan untuk menyediakan layanan multicast DNS (mDNS) pada Linux.

Dengan Avahi, Linux dapat mengumumkan hostname melalui jaringan lokal sehingga perangkat lain dapat mengakses server menggunakan nama perangkat tanpa harus mengingat alamat IP.

### 9.1. Hostname

Hostname dapat ditentukan ketika menjalankan installer.

Contoh:

```text
linux-server
```

Hostname tersebut dapat diakses menggunakan:

```text
http://linux-server.local
```

Nama domain mengikuti hostname yang dikonfigurasi pada Linux.

### 9.2. Avahi Service

Periksa status Avahi:

```bash
sudo systemctl status avahi-daemon
```

Jika layanan belum aktif:

```bash
sudo systemctl enable --now avahi-daemon
```

Untuk melihat hostname:

```bash
hostname
```

Untuk memeriksa resolusi mDNS dari Linux:

```bash
getent hosts linux-server.local
```

Ganti `linux-server` dengan hostname yang digunakan.

### 9.3. Windows Client

Windows harus dapat melakukan resolusi hostname melalui mDNS.

Jika domain `.local` tidak dapat diakses:

1. Pastikan Windows terhubung ke adapter Host-only.
2. Pastikan Avahi aktif pada Linux.
3. Pastikan Windows dan Linux berada pada subnet yang sama.
4. Pastikan tidak ada firewall yang memblokir komunikasi yang diperlukan.
5. Uji akses menggunakan alamat IP Linux secara langsung.

Contoh:

```text
http://192.168.1.1
```

Jika alamat IP dapat diakses tetapi hostname tidak, periksa dukungan dan konfigurasi mDNS pada Windows.

---

## 10. Firewall Configuration

Installer mengonfigurasi UFW untuk mengizinkan akses HTTP dan HTTPS.

Port yang diizinkan oleh installer:

| Port | Protocol | Fungsi |
|---|---|---|
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |

Periksa status firewall:

```bash
sudo ufw status verbose
```

Untuk mengizinkan HTTP secara manual:

```bash
sudo ufw allow 80/tcp
```

Untuk mengizinkan HTTPS:

```bash
sudo ufw allow 443/tcp
```

Jika Linux dikelola melalui SSH, pastikan aturan SSH telah tersedia sebelum mengaktifkan firewall:

```bash
sudo ufw allow 22/tcp
```

Jangan membuka port yang tidak diperlukan. Backend sebaiknya diakses melalui Apache Reverse Proxy dan tidak diekspos langsung ke jaringan client.

---

## 11. Accessing the Web Interface

Setelah instalasi selesai dan layanan berjalan, pengguna dapat mengakses aplikasi melalui browser Windows.

Format URL:

```text
http://<hostname>.local
```

Contoh:

```text
http://linux-server.local
```

Alternatif menggunakan alamat IP:

```text
http://192.168.1.1
```

Pastikan Apache telah aktif:

```bash
sudo systemctl status apache2
```

Pastikan backend telah berjalan:

```bash
pm2 status
```

---

## 12. Troubleshooting

| Permasalahan | Kemungkinan Penyebab | Solusi |
|---|---|---|
| Domain `.local` tidak dapat diakses | Avahi atau mDNS tidak aktif | Periksa layanan Avahi dan resolusi mDNS Windows |
| IP Linux tidak dapat diakses | Konfigurasi Host-only salah | Periksa IP dan adapter jaringan |
| Apache tidak berjalan | Konfigurasi VirtualHost bermasalah | Jalankan `sudo apache2ctl configtest` |
| Halaman frontend tidak muncul | Hasil build tidak tersedia | Periksa direktori `dist` dan jalankan build ulang |
| API tidak dapat diakses | Backend belum berjalan | Periksa `pm2 status` dan log backend |
| API menghasilkan HTTP 403 | Hak akses filesystem tidak mencukupi | Periksa permission direktori yang diakses |
| API menghasilkan HTTP 404 | Endpoint atau path tidak ditemukan | Periksa route backend |
| Windows tidak dapat mengakses Linux | Firewall atau jaringan salah | Periksa UFW, IP, dan Host-only Adapter |

### 12.1. Network Diagnostics

Gunakan script pemeriksaan jaringan:

```bash
./scripts/check-network.sh
```

Script tersebut menampilkan informasi:

- Sistem operasi dan hostname.
- Network interface dan IP address.
- Default route.
- DNS configuration.
- Status NetworkManager.
- Status Apache.
- TCP listening ports.
- Status UFW.

Script ini bersifat read-only dan tidak mengubah konfigurasi sistem.

### 12.2. Apache Diagnostics

```bash
sudo apache2ctl configtest
sudo systemctl status apache2
sudo journalctl -u apache2 -n 50 --no-pager
```

### 12.3. Backend Diagnostics

```bash
pm2 status
pm2 logs lwi-backend
```

---

## 13. Security Considerations

Keamanan menjadi salah satu aspek penting karena aplikasi berinteraksi dengan filesystem Linux.

Beberapa hal yang perlu diperhatikan selama pengembangan:

1. Backend harus membatasi akses filesystem berdasarkan direktori dan hak akses yang telah ditentukan.
2. Validasi path harus dilakukan pada backend untuk mencegah path traversal.
3. Akses symbolic link perlu ditangani agar tidak membuka file di luar direktori yang diizinkan.
4. Backend tidak boleh dijalankan menggunakan hak akses root tanpa kebutuhan yang jelas.
5. Debug mode Flask harus dinonaktifkan untuk deployment.
6. Akses langsung ke port backend harus dibatasi.
7. Jangan menyediakan eksekusi shell bebas melalui browser.
8. Firewall hanya mengizinkan port yang diperlukan.
9. Implementasikan autentikasi dan otorisasi sebelum aplikasi digunakan pada jaringan yang tidak sepenuhnya dipercaya.

**Catatan:** Pembatasan akses filesystem, autentikasi, dan pengamanan endpoint masih perlu disempurnakan. Proyek belum ditujukan untuk deployment production atau penggunaan pada jaringan publik.

---

## 14. Testing and Validation

Pengujian dilakukan untuk memastikan setiap komponen dapat berjalan sesuai fungsinya.

| ID | Skenario Pengujian | Hasil yang Diharapkan |
|---|---|---|
| T01 | Linux VM berhasil melakukan boot | Linux CLI dapat digunakan |
| T02 | Apache dijalankan | Apache berstatus active |
| T03 | Frontend diakses melalui IP Linux | Halaman frontend ditampilkan |
| T04 | Backend dijalankan melalui PM2 | Proses backend terdaftar dan berjalan |
| T05 | Endpoint `/api/dir` diakses | Backend memberikan respons JSON sesuai implementasi |
| T06 | Avahi dijalankan | Hostname mDNS diumumkan |
| T07 | Windows melakukan resolusi hostname | Domain `.local` mengarah ke IP Linux |
| T08 | Windows mengakses web melalui domain `.local` | Halaman web dapat diakses |
| T09 | Windows mengakses web melalui IP Linux | Halaman web dapat diakses |
| T10 | Pengujian pada VMware Host-only | Host dan guest dapat berkomunikasi |
| T11 | Pengujian pada VirtualBox Host-only | Host dan guest dapat berkomunikasi |

Setiap skenario pengujian harus mencatat hasil aktual. Jangan menyatakan pengujian berhasil sebelum dilakukan secara langsung.

---

## 15. Known Limitations

Beberapa keterbatasan yang diketahui selama tahap pengembangan:

- Integrasi frontend dan backend belum selesai.
- Beberapa endpoint backend masih dalam pengembangan.
- Pembatasan akses filesystem belum sepenuhnya disempurnakan.
- Autentikasi dan otorisasi pengguna belum menjadi fitur yang siap digunakan.
- Dukungan resolusi mDNS pada Windows bergantung pada konfigurasi client.
- Konfigurasi jaringan statis pada Linux dapat berbeda berdasarkan distribusi dan network manager.
- Installer belum menjamin kompatibilitas konfigurasi jaringan untuk seluruh distribusi Linux.

---

## 16. Future Development

Pengembangan selanjutnya diarahkan pada:

1. Integrasi frontend React dengan backend Flask.
2. Penyempurnaan fitur file browsing.
3. Implementasi autentikasi dan otorisasi.
4. Pembatasan akses filesystem yang lebih aman.
5. Penambahan fitur manajemen file sesuai kebutuhan.
6. Penyempurnaan konfigurasi jaringan dan installer.
7. Pengujian kompatibilitas VMware dan VirtualBox.
8. Peningkatan stabilitas layanan dan dokumentasi deployment.

---

## 17. Repository Structure

Proyek ini dibagi menjadi tiga repository utama:

| Repository | Deskripsi |
|---|---|
| [scripts](https://github.com/linux-web-interface/scripts) | Script instalasi, konfigurasi infrastruktur, dan pemeriksaan jaringan |
| [backend](https://github.com/linux-web-interface/backend) | REST API untuk layanan backend Linux |
| [frontend](https://github.com/linux-web-interface/frontend) | Antarmuka pengguna berbasis React |

### Scripts

```text
scripts/
├── install.sh
├── scripts/
│   ├── setup-apache.sh
│   ├── check-network.sh
│   ├── start-all.sh
│   └── setup-virtualbox-nat.ps1
└── README.md
```

### Backend

```text
backend/
├── api/
│   └── browse_routes.py
├── app.py
├── ecosystem.config.js
├── requirements.txt
└── README.md
```

### Frontend

```text
frontend/
├── public/
├── src/
│   ├── components/
│   ├── App.jsx
│   ├── App.css
│   ├── index.css
│   └── main.jsx
├── package.json
└── vite.config.js
```

---

## 18. Git Workflow

Gunakan Git untuk mengelola perubahan source code dan berkolaborasi dalam pengembangan proyek.

Melihat status repository:

```bash
git status
```

Menambahkan perubahan:

```bash
git add .
```

Membuat commit:

```bash
git commit -m "Describe your changes"
```

Mengirim perubahan ke remote repository:

```bash
git push
```

Mengambil repository:

```bash
git clone URL_REPOSITORY
cd NAMA_FOLDER_REPOSITORY
```

Hindari memasukkan password, token, private key, atau credential ke dalam repository.

---

## 19. References

- [VMware Workstation Documentation](https://docs.vmware.com/)
- [Oracle VirtualBox User Manual](https://www.virtualbox.org/manual/)
- [Apache HTTP Server Documentation](https://httpd.apache.org/docs/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [React Documentation](https://react.dev/)
- [Vite Documentation](https://vite.dev/)
- [PM2 Documentation](https://pm2.keymetrics.io/docs/)
- [Avahi Documentation](https://avahi.org/)
- [NetworkManager Documentation](https://networkmanager.dev/docs/)

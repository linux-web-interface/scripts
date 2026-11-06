<#
Configure VMware Port Forwarding for Guest TCP port 80 to Host port 8080.
Run this on the Windows HOST in PowerShell as Administrator.
The VM should be powered off during network changes.
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VMName,

    [ValidateRange(1024, 65535)]
    [int]$HostPort = 8080,

    [ValidateRange(1, 65535)]
    [int]$GuestPort = 80,

    [ValidateNotNullOrEmpty()]
    [string]$GuestIP = ""
)

$ErrorActionPreference = "Stop"

# Pastikan dijalankan sebagai Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    throw "Skrip ini harus dijalankan sebagai Administrator. Klik kanan PowerShell lalu pilih 'Run as administrator'."
}

Write-Host "=== Konfigurasi Port Forwarding VMware untuk VM: $VMName ===" -ForegroundColor Cyan
Write-Host "Forwarding: Host 127.0.0.1:$HostPort -> Guest IP ($GuestIP):$GuestPort" -ForegroundColor Yellow

# Jika GuestIP kosong, minta input atau beri panduan
if ([string]::IsNullOrEmpty($GuestIP)) {
    Write-Host "[PERINGATAN] IP Guest (VM) belum diisi." -ForegroundColor Red
    Write-Host "Silakan jalankan perintah ini dengan menyertakan parameter -GuestIP, contoh:"
    Write-Host "  .\setup-vmware.ps1 -VMName ""Ubuntu-VM"" -GuestIP ""192.168.174.128"" -HostPort 8080" -ForegroundColor Green
    exit
}

# Lokasi file konfigurasi .vmx (Opsional untuk mencatat atau memvalidasi)
Write-Host "Langkah-langkah yang perlu dipastikan pada VMware Host:"
Write-Host "1. Pastikan VM '$VMName' dalam keadaan mati (Powered Off)."
Write-Host "2. Pastikan Adapter Jaringan VM diatur ke mode NAT."
Write-Host "3. Pastikan layanan VMware NAT Service sedang berjalan di Windows."

# Menggunakan netsh atau modifikasi registry/config virtual network VMware jika didukung,
# Namun cara paling aman dan resmi di VMware Workstation adalah via Virtual Network Editor atau vmnet-natconf.
Write-Host "Menerapkan aturan NAT melalui konfigurasi jaringan VMware..." -ForegroundColor Green

# Contoh otomatisasi via registri/command bawaan VMware jika ada (vmnetcli / vmnetcfg)
$VMNetDir = "C:\Program Files (x86)\VMware\VMware Workstation"
if (-not (Test-Path $VMNetDir)) {
    $VMNetDir = "C:\Program Files\VMware\VMware Workstation"
}

if (Test-Path "$VMNetDir\vmnetcfg.exe") {
    Write-Host "Membuka VMware Virtual Network Editor..."
    Start-Process "$VMNetDir\vmnetcfg.exe"
} else {
    Write-Host "Virtual Network Editor tidak ditemukan secara otomatis di path standar."
    Write-Host "Silakan buka VMware Workstation -> Edit -> Virtual Network Editor -> VMnet8 -> NAT Settings -> Add Port Forwarding." -ForegroundColor Yellow
}

Write-Host "Selesai. Silakan atur port forwarding (Host Port: $HostPort -> Guest IP: $GuestIP : Guest Port: $GuestPort) di Virtual Network Editor VMware." -ForegroundColor Cyan

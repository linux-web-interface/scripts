<#
Configure VirtualBox Adapter 1 as NAT and forward only host loopback port 8080
into guest TCP port 80. Run this on the Windows HOST in PowerShell.
The VM must be powered off. This script is specific to VirtualBox.
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
    [string]$RuleName = "linux-file-explorer-http"
)

$ErrorActionPreference = "Stop"

$VBoxCommand = Get-Command "VBoxManage.exe" -ErrorAction SilentlyContinue
if (-not $VBoxCommand) {
    $VBoxCommand = Get-Command "VBoxManage" -ErrorAction SilentlyContinue
}
if (-not $VBoxCommand) {
    throw "VBoxManage tidak ditemukan. Pastikan VirtualBox terpasang dan VBoxManage ada di PATH."
}

$VBoxManage = $VBoxCommand.Path
Write-Host "VirtualBox: $VBoxManage"
Write-Host "VM: $VMName"
Write-Host "Forward: 127.0.0.1:$HostPort -> guest TCP port $GuestPort"
Write-Host "Pastikan VM dalam keadaan Powered Off."

# Ensure Adapter 1 uses NAT. Other adapters are not modified.
& $VBoxManage modifyvm $VMName --nic1 nat
if ($LASTEXITCODE -ne 0) {
    throw "Gagal mengatur Adapter 1 ke NAT. Pastikan nama VM benar dan VM sedang mati."
}

# Validate the NAT rule label because VirtualBox uses commas as field separators.
if ($RuleName -notmatch '^[A-Za-z0-9_-]+$') {
    throw "RuleName hanya boleh berisi huruf, angka, '_' atau '-'."
}

# Remove an older rule with the same name so rerunning this script is safe.
try {
    & $VBoxManage modifyvm $VMName --natpf1 delete $RuleName 2>$null | Out-Null
} catch {
    # It is normal for the delete command to fail when the rule does not exist yet.
}

# Bind host side to 127.0.0.1 so the forwarded website is not exposed to the LAN.
$Rule = "$RuleName,tcp,127.0.0.1,$HostPort,,$GuestPort"
& $VBoxManage modifyvm $VMName --natpf1 $Rule
if ($LASTEXITCODE -ne 0) {
    throw "Gagal membuat aturan port-forwarding. Periksa apakah port host sudah digunakan."
}

Write-Host "Aturan NAT berhasil dikonfigurasi. Nyalakan VM, lalu buka http://127.0.0.1:$HostPort/ pada Windows."

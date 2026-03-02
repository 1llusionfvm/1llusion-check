param([string]$code = "1llusion_Check")

# --- CONFIGURAZIONE WEBHOOK ---
$webhookUrl = "https://discord.com/api/webhooks/1478077312426573824/gxsbrnhJPaQ2VuH4eDbd-gAtC7WlrcQSz_YUqLfEykhGsoqC2y3HWTFAmp9phW1pYtIu"
$logoSmall = "https://tuosito.it/logo_small.png"

# --- INFORMATIVA GDPR ---
Clear-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "             INFORMATIVA PRIVACY 1LLUSION." -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
$consent = Read-Host "`nAccetti il trattamento dei dati ai sensi del GDPR? (S/N)"
if ($consent.ToUpper() -ne "S") { exit }

Write-Host "`n[*] Analisi hardware in corso..." -ForegroundColor Green

# --- FUNZIONI DI ANALISI ---
function D([string]$b) { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b)) }

$cs = Get-CimInstance Win32_ComputerSystemProduct
$bb = Get-CimInstance Win32_BaseBoard
$bios = Get-CimInstance Win32_BIOS
$cpu = Get-CimInstance Win32_Processor

$uuid = if ($cs.UUID) { $cs.UUID.Trim() } else { "N/D" }
$bbS = if ($bb.SerialNumber) { $bb.SerialNumber.Trim() } else { "N/D" }
$biosS = if ($bios.SerialNumber) { $bios.SerialNumber.Trim() } else { "N/D" }
$cpuI = if ($cpu.ProcessorId) { $cpu.ProcessorId.Trim() } else { "N/D" }

# SHA256 Hash
$concat = "$uuid|$bbS|$biosS|$cpuI"
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$hash = ($sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($concat)) | ForEach-Object { $_.ToString("x2") }) -join ''

# Dischi
$diskList = (Get-CimInstance Win32_DiskDrive | ForEach-Object { "$($_.Model): $($_.SerialNumber)" }) -join "\n"

# DMA Check (Base64)
$dmaFound = "PULITO"
$fpgaVendors = @((D 'VkVOXzEwRUU='), (D 'VkVOXzExNzI='))
$pnp = Get-CimInstance Win32_PnPEntity
foreach ($dev in $pnp) {
    foreach ($v in $fpgaVendors) { if ($dev.DeviceID -like "*$v*") { $dmaFound = "RILEVATA: $($dev.Name)" } }
}

# --- COSTRUZIONE EMBED ---
$fields = @(
    @{ name = "Utente Sessione"; value = "``$env:USERNAME / $code``"; inline = $true }
    @{ name = "HWID SHA256 Hash"; value = "``$hash``"; inline = $false }
    @{ name = "UUID Sistema"; value = "``$uuid``"; inline = $true }
    @{ name = "Motherboard SN"; value = "``$bbS``"; inline = $true }
    @{ name = "Hardware DMA"; value = "**$dmaFound**"; inline = $true }
    @{ name = "Seriali Dischi"; value = "```\n$diskList\n```"; inline = $false }
)

$embed = @{
    title = "1llusion. | Report Forense"
    color = 3447003
    thumbnail = @{ url = $logoSmall }
    fields = $fields
    footer = @{ text = "1llusion. Security Engine • $(Get-Date)" }
}

# --- INVIO ---
$payload = @{ embeds = @($embed) } | ConvertTo-Json -Depth 10
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"

Write-Host "`n[+] Report inviato con successo!" -ForegroundColor Green
Start-Sleep -Seconds 2

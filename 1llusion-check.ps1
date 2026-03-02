param([string]$code = "1llusion_Session")

# --- CONFIGURAZIONE ---
$webhookUrl = "https://discord.com/api/webhooks/1478077312426573824/gxsbrnhJPaQ2VuH4eDbd-gAtC7WlrcQSz_YUqLfEykhGsoqC2y3HWTFAmp9phW1pYtIu"
$logoSmall = "https://tuosito.it/logo_small.png" # Logo piccolo per l'embed

# --- ANALISI HARDWARE & DMA ---
Write-Host "[*] Estrazione metadati hardware e analisi DMA..." -ForegroundColor Cyan

# Raccolta Seriali
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

# Lista Dischi
$disks = Get-CimInstance Win32_DiskDrive | ForEach-Object { "$($_.Model): $($_.SerialNumber)" }
$diskList = $disks -join "\n"

# DMA Check
function D([string]$b) { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b)) }
$dmaStatus = "PULITO"
$fpgaVendors = @((D 'VkVOXzEwRUU='), (D 'VkVOXzExNzI='))
$pnp = Get-CimInstance Win32_PnPEntity
foreach ($dev in $pnp) {
    foreach ($v in $fpgaVendors) { if ($dev.DeviceID -like "*$v*") { $dmaStatus = "RILEVATA ($($dev.Name))" } }
}

# --- COSTRUZIONE EMBED (Senza caratteri speciali) ---
$embed = @{
    title = "1llusion. | Report Forense Integrale"
    color = 3447003
    thumbnail = @{ url = $logoSmall }
    fields = @(
        @{ name = "Utente / Sessione"; value = "``$env:USERNAME / $code``"; inline = $true }
        @{ name = "HWID SHA256 HASH"; value = "``$hash``"; inline = $false }
        @{ name = "UUID Sistema"; value = "``$uuid``"; inline = $false }
        @{ name = "Motherboard SN"; value = "``$bbS``"; inline = $true }
        @{ name = "BIOS Serial"; value = "``$biosS``"; inline = $true }
        @{ name = "Hardware DMA Check"; value = "**$dmaStatus**"; inline = $true }
        @{ name = "Seriali Dischi (Fisici)"; value = "```\n$diskList\n```"; inline = $false }
    )
    footer = @{ text = "1llusion. Security Engine - $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" }
}

# --- INVIO ---
$payload = @{ embeds = @($embed) } | ConvertTo-Json -Depth 10
try {
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"
    Write-Host "[+] Report inviato correttamente." -ForegroundColor Green
} catch {
    Write-Host "[-] Errore invio Webhook." -ForegroundColor Red
}

Start-Sleep -Seconds 2

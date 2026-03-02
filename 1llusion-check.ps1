param([string]$code = "1llusion_Session")

# --- CONFIGURAZIONE ---
$webhookUrl = "https://discord.com/api/webhooks/1478077312426573824/gxsbrnhJPaQ2VuH4eDbd-gAtC7WlrcQSz_YUqLfEykhGsoqC2y3HWTFAmp9phW1pYtIu"
$logoSmall = "https://tuosito.it/logo_small.png" # Logo piccolo per l'embed

# --- DEFINIZIONE EMOJI (Anti-Crash) ---
$eUser = "👤"; $eHash = "🛡️"; $eId = "🆔"; $ePlug = "🔌"; $eBios = "💾"; $eDisk = "💿"; $eDma = "🧠"; $eDate = "📅"

# --- INFORMATIVA GDPR ---
Clear-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "             INFORMATIVA PRIVACY 1LLUSION." -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "`nAccetti il trattamento dei dati ai sensi del GDPR? (S/N)"
$consent = Read-Host
if ($consent.ToUpper() -ne "S") { exit }

Write-Host "`n[*] Analisi hardware e DMA in corso..." -ForegroundColor Green

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

# SHA256 Hash Identificativo
$concat = "$uuid|$bbS|$biosS|$cpuI"
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$hash = ($sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($concat)) | ForEach-Object { $_.ToString("x2") }) -join ''

# Controllo Dischi (Tutti i seriali)
$disks = Get-CimInstance Win32_DiskDrive | ForEach-Object { "$($_.Model): $($_.SerialNumber)".Trim() }
$diskList = $disks -join "\n"

# Controllo DMA & FPGA
$dmaFound = "PULITO"
$fpgaVendors = @((D 'VkVOXzEwRUU='), (D 'VkVOXzExNzI=')) # Xilinx, Intel
$pnp = Get-CimInstance Win32_PnPEntity
foreach ($dev in $pnp) {
    foreach ($v in $fpgaVendors) { if ($dev.DeviceID -like "*$v*") { $dmaFound = "🚨 RILEVATA ($($dev.Name))" } }
}

# Coerenza Date
$regInst = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").InstallDate
$winFold = (Get-Item "C:\Windows").CreationTime
$epoch = [datetime]::new(1970,1,1,0,0,0,[System.DateTimeKind]::Utc)
$regDate = $epoch.AddSeconds($regInst).ToLocalTime()
$dateStatus = if ([math]::Abs(($regDate - $winFold).TotalDays) -lt 7) { "✅ Coerente" } else { "⚠️ SOSPETTO (Tampering)" }

# --- COSTRUZIONE EMBED ---
$embed = @{
    title = "1llusion. | Report Forense Integrale"
    color = 3447003
    thumbnail = @{ url = $logoSmall }
    fields = @(
        @{ name = "$eUser Utente/Sessione"; value = "``$env:USERNAME / $code``"; inline = $true }
        @{ name = "$eHash HWID SHA256 HASH"; value = "``$hash``"; inline = $false }
        @{ name = "$eId UUID Sistema"; value = "``$uuid``"; inline = $false }
        @{ name = "$ePlug Motherboard SN"; value = "``$bbS``"; inline = $true }
        @{ name = "$eBios BIOS Serial"; value = "``$biosS``"; inline = $true }
        @{ name = "$eDma Hardware DMA Check"; value = "**$dmaFound**"; inline = $true }
        @{ name = "$eDate Coerenza Installazione"; value = "$dateStatus"; inline = $true }
        @{ name = "$eDisk Seriali Dischi (Fisici)"; value = "```\n$diskList\n```"; inline = $false }
    )
    footer = @{ text = "1llusion. Security System • $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" }
}

# --- INVIO ---
$payload = @{ embeds = @($embed) } | ConvertTo-Json -Depth 10
try {
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"
    Write-Host "`n[+] Report inviato correttamente su Discord." -ForegroundColor Green
} catch {
    Write-Host "`n[!] Errore critico: Impossibile inviare al Webhook." -ForegroundColor Red
}

Start-Sleep -Seconds 2

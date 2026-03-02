param([string]$code = "1llusion_Forensic")

# --- CONFIGURAZIONE ---
$webhookUrl = "https://discord.com/api/webhooks/1478077312426573824/gxsbrnhJPaQ2VuH4eDbd-gAtC7WlrcQSz_YUqLfEykhGsoqC2y3HWTFAmp9phW1pYtIu"
$logoSmall = "https://media.discordapp.net/attachments/1253995305796632608/1459514338288209958/IMG_5812.png?ex=69a6caa6&is=69a57926&hm=c00c4aabe2d2185272e32bec0c17f25b863079d68f2cdfc5614df1232ed6125b&=&format=webp&quality=lossless"

# --- INFORMATIVA GDPR (Originale) ---
Clear-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "             INFORMATIVA PRIVACY 1LLUSION." -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "`nAccetti il trattamento dei dati ai sensi del GDPR? (S/N)"
$consent = Read-Host
if ($consent.ToUpper() -ne "S") { exit }

Write-Host "`n[*] Analisi hardware e DMA in corso..." -ForegroundColor Green

# --- FUNZIONI ORIGINALI (HWID, DMA, SPOOF) ---
function D([string]$b) { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b)) }

# 1. Raccolta HWID e Hash SHA256
$cs = Get-CimInstance Win32_ComputerSystemProduct
$bb = Get-CimInstance Win32_BaseBoard
$bios = Get-CimInstance Win32_BIOS
$cpu = Get-CimInstance Win32_Processor
$uuid = $cs.UUID; $bbS = $bb.SerialNumber; $biosS = $bios.SerialNumber; $cpuI = $cpu.ProcessorId
$concat = "$uuid|$bbS|$biosS|$cpuI"
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$hash = ($sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($concat)) | ForEach-Object { $_.ToString("x2") }) -join ''

# 2. Controllo Dischi (Tutti i seriali)
$disks = Get-CimInstance Win32_DiskDrive | ForEach-Object { "$($_.Model): $($_.SerialNumber)".Trim() }
$diskList = $disks -join "`n"

# 3. Controllo DMA & FPGA (Vendor IDs)
$dmaFound = "PULITO"
$fpgaVendors = @((D 'VkVOXzEwRUU='), (D 'VkVOXzExNzI=')) # Xilinx, Intel
$pnp = Get-CimInstance Win32_PnPEntity
foreach ($dev in $pnp) {
    foreach ($v in $fpgaVendors) { if ($dev.DeviceID -like "*$v*") { $dmaFound = "🚨 RILEVATA ($($dev.Name))" } }
}

# 4. Coerenza Date (Tampering Check)
$regInst = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").InstallDate
$winFold = (Get-Item "C:\Windows").CreationTime
$epoch = [datetime]::new(1970,1,1,0,0,0,[System.DateTimeKind]::Utc)
$regDate = $epoch.AddSeconds($regInst).ToLocalTime()
$dateStatus = if ([math]::Abs(($regDate - $winFold).TotalDays) -lt 7) { "✅ Coerente" } else { "⚠️ SOSPETTO (Tampering)" }

# 5. Rilevamento Spoof / VM
$isVM = if ((Get-CimInstance Win32_ComputerSystem).Model -match "VBOX|VMWARE|VIRTUAL") { "SI" } else { "No" }

# --- COSTRUZIONE EMBED COMPLETO ---
$embed = @{
    title = "1llusion. | Report Forense Integrale"
    color = 3447003
    thumbnail = @{ url = $logoSmall }
    fields = @(
        @{ name = "👤 Utente/Sessione"; value = "``$env:USERNAME`` / ``$code``"; inline = $true }
        @{ name = "🌐 Indirizzo IP"; value = "``$( (Invoke-WebRequest api.ipify.org -UseBasicParsing).Content )``"; inline = $true }
        @{ name = "🛡️ HWID SHA256 HASH"; value = "``$hash``"; inline = $false }
        @{ name = "🆔 UUID Sistema"; value = "``$uuid``"; inline = $false }
        @{ name = "🔌 Motherboard SN"; value = "``$bbS``"; inline = $true }
        @{ name = "💾 BIOS Serial"; value = "``$biosS``"; inline = $true }
        @{ name = "⚙️ CPU ID"; value = "``$cpuI``"; inline = $false }
        @{ name = "💿 Seriali Dischi (Fisici)"; value = "````n$diskList`n```"; inline = $false }
        @{ name = "🧠 Hardware DMA Check"; value = "**$dmaFound**"; inline = $true }
        @{ name = "📅 Coerenza Installazione"; value = $dateStatus; inline = $true }
        @{ name = "🛡️ VM / Sandbox"; value = $isVM; inline = $true }
        @{ name = "🖥️ OS Version"; value = (Get-CimInstance Win32_OperatingSystem).Caption; inline = $false }
    )
    footer = @{ text = "1llusion. Security System • $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" }
}

# --- INVIO ---
$payload = @{ embeds = @($embed) } | ConvertTo-Json -Depth 10
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"
Write-Host "`n[+] Report inviato correttamente su Discord." -ForegroundColor Green
Start-Sleep -Seconds 2
param([string]$code = "1llusion_Session")

$webhook = "https://discord.com/api/webhooks/1478077312426573824/gxsbrnhJPaQ2VuH4eDbd-gAtC7WlrcQSz_YUqLfEykhGsoqC2y3HWTFAmp9phW1pYtIu"
$thumb = "https://tuosito.it/logo_small.png"

Write-Host "Analisi in corso..." -ForegroundColor Cyan

# Raccolta dati
$sys = Get-CimInstance Win32_ComputerSystemProduct
$board = Get-CimInstance Win32_BaseBoard
$bios = Get-CimInstance Win32_BIOS
$cpu = Get-CimInstance Win32_Processor

$id_uuid = if ($sys.UUID) { $sys.UUID.Trim() } else { "ND" }
$id_board = if ($board.SerialNumber) { $board.SerialNumber.Trim() } else { "ND" }
$id_bios = if ($bios.SerialNumber) { $bios.SerialNumber.Trim() } else { "ND" }
$id_cpu = if ($cpu.ProcessorId) { $cpu.ProcessorId.Trim() } else { "ND" }

# Hash SHA256
$ctx = "$id_uuid|$id_board|$id_bios|$id_cpu"
$hasher = [System.Security.Cryptography.SHA256]::Create()
$final_hash = ($hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($ctx)) | ForEach-Object { $_.ToString("x2") }) -join ''

# Lista Dischi
$d_list = (Get-CimInstance Win32_DiskDrive | ForEach-Object { "$($_.Model) - $($_.SerialNumber)" }) -join "\n"

# Costruzione campi Embed (Nomi semplici senza simboli)
$f1 = @{ name = "User Session"; value = "$env:USERNAME / $code"; inline = $true }
$f2 = @{ name = "PC Hash"; value = "$final_hash"; inline = $false }
$f3 = @{ name = "UUID"; value = "$id_uuid"; inline = $true }
$f4 = @{ name = "Board SN"; value = "$id_board"; inline = $true }
$f5 = @{ name = "Disks"; value = "```\n$d_list\n```"; inline = $false }

$emb = @{
    title = "1llusion Forensic Report"
    color = 3447003
    thumbnail = @{ url = $thumb }
    fields = @($f1, $f2, $f3, $f4, $f5)
}

# Invio
$json = @{ embeds = @($emb) } | ConvertTo-Json -Depth 5
try {
    Invoke-RestMethod -Uri $webhook -Method Post -Body $json -ContentType "application/json"
    Write-Host "Inviato!" -ForegroundColor Green
} catch {
    Write-Host "Errore Webhook" -ForegroundColor Red
}

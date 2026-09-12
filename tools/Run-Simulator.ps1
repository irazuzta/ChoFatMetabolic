<#
.SYNOPSIS
    Compila CHOFATDataField per a un dispositiu Garmin i el llança al simulador de Connect IQ.

.PARAMETER Device
    Identificador del dispositiu (p.ex. fenix7, fenix847mm, fr970). Si s'omet, es mostra
    un menú amb tots els dispositius declarats a manifest.xml.

.PARAMETER DevKey
    Ruta a la clau de desenvolupador (.der). Per defecte: Documents\Garmin\developer_key.

.EXAMPLE
    .\Run-Simulator.ps1
    .\Run-Simulator.ps1 -Device fenix847mm
#>
param(
    [string]$Device,
    [string]$DevKey = "$env:USERPROFILE\Documents\Garmin\developer_key"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# --- Localitza l'SDK de Connect IQ actiu (gestionat pel SDK Manager) ---
$sdkCfgPath = "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg"
if (-not (Test-Path $sdkCfgPath)) {
    throw "No trobo $sdkCfgPath. Obre el Connect IQ SDK Manager i selecciona un SDK actiu."
}
$sdk = (Get-Content $sdkCfgPath -Raw).Trim().TrimEnd('\')
$monkeyc   = Join-Path $sdk "bin\monkeyc.bat"
$monkeydo  = Join-Path $sdk "bin\monkeydo.bat"
$simulator = Join-Path $sdk "bin\simulator.exe"

if (-not (Test-Path $DevKey)) {
    throw "No trobo la clau de desenvolupador a '$DevKey'. Passa-la amb -DevKey <ruta>."
}

# --- Tria de dispositiu ---
if (-not $Device) {
    [xml]$manifest = Get-Content (Join-Path $ProjectRoot "manifest.xml")
    $devices = $manifest.manifest.application.products.product.id
    Write-Host ""
    Write-Host "Dispositius disponibles (manifest.xml):"
    for ($i = 0; $i -lt $devices.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i + 1), $devices[$i])
    }
    Write-Host ""
    $sel = Read-Host "Tria un dispositiu (numero o id)"
    if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $devices.Count) {
        $Device = $devices[[int]$sel - 1]
    } else {
        $Device = $sel
    }
}

Write-Host ""
Write-Host "=== Compilant per a '$Device' ===" -ForegroundColor Cyan

$outDir = Join-Path $ProjectRoot "bin"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$prg = Join-Path $outDir "CHOFATDataField_$Device.prg"

Push-Location $ProjectRoot
try {
    & $monkeyc -o $prg -f "monkey.jungle" -y $DevKey -d $Device -w
    if ($LASTEXITCODE -ne 0) {
        throw "La compilacio ha fallat (codi $LASTEXITCODE)."
    }
}
finally {
    Pop-Location
}

Write-Host "Build OK -> $prg" -ForegroundColor Green

# --- Assegura que el simulador esta obert ---
$simProc = Get-Process -Name "simulator" -ErrorAction SilentlyContinue
if (-not $simProc) {
    Write-Host "Engegant el simulador..." -ForegroundColor Cyan
    Start-Process -FilePath $simulator -WorkingDirectory (Split-Path $simulator)
    Start-Sleep -Seconds 5
}

# --- Carrega l'app al simulador ---
# monkeydo es queda actiu alimentant el simulador amb dades, no torna sol;
# el llancem sense esperar-lo perque l'script pugui acabar.
Write-Host "=== Llançant '$Device' al simulador ===" -ForegroundColor Cyan
Start-Process -FilePath $monkeydo -ArgumentList "`"$prg`" $Device" -WindowStyle Hidden

Start-Sleep -Seconds 3
Write-Host "Fet. Revisa la finestra del simulador." -ForegroundColor Green

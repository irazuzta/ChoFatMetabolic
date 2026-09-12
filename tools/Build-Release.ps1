<#
.SYNOPSIS
    Compila CHOFATDataField com a paquet signat (.iq) per pujar a la Connect IQ Store.

.DESCRIPTION
    A diferencia de Run-Simulator.ps1 (build per a un sol dispositiu, sense signar,
    pensat per provar), aquest script genera el paquet "-e" (application package)
    que empaqueta tots els dispositius declarats a manifest.xml en un sol fitxer
    .iq, signat amb la clau de desenvolupador i amb la informacio de depuracio
    treta (-r). Es exactament el fitxer que es puja al Connect IQ Developer Portal.

.PARAMETER DevKey
    Ruta a la clau de desenvolupador (.der). Per defecte: keys\developer_key.der
    dins d'aquest projecte.

.EXAMPLE
    .\Build-Release.ps1
#>
param(
    [string]$DevKey = (Join-Path (Split-Path -Parent $PSScriptRoot) "keys\developer_key.der")
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# --- Localitza l'SDK de Connect IQ actiu (gestionat pel SDK Manager) ---
$sdkCfgPath = "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg"
if (-not (Test-Path $sdkCfgPath)) {
    throw "No trobo $sdkCfgPath. Obre el Connect IQ SDK Manager i selecciona un SDK actiu."
}
$sdk = (Get-Content $sdkCfgPath -Raw).Trim().TrimEnd('\')
$monkeyc = Join-Path $sdk "bin\monkeyc.bat"

if (-not (Test-Path $DevKey)) {
    throw "No trobo la clau de desenvolupador a '$DevKey'. Passa-la amb -DevKey <ruta>."
}

[xml]$manifest = Get-Content (Join-Path $ProjectRoot "manifest.xml")

# --- Avis si l'App ID del manifest encara es el de placeholder ---
$appId = $manifest.manifest.application.id
if ($appId -eq "12345678-1234-1234-1234-123456789abc") {
    Write-Host ""
    Write-Host "AVIS: manifest.xml encara te l'App ID de placeholder." -ForegroundColor Yellow
    Write-Host "Abans de pujar aquest paquet a la Store cal generar-ne un de real amb" -ForegroundColor Yellow
    Write-Host "'Monkey C: Edit Application' des de VS Code (registra l'app al teu compte" -ForegroundColor Yellow
    Write-Host "de desenvolupador Garmin)." -ForegroundColor Yellow
    Write-Host ""
}

$devices = $manifest.manifest.application.products.product.id
Write-Host ""
Write-Host "=== Compilant paquet de release signat ($($devices.Count) dispositius) ===" -ForegroundColor Cyan

$outDir = Join-Path $ProjectRoot "bin"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$iq = Join-Path $outDir "CHOFATDataField.iq"

Push-Location $ProjectRoot
try {
    & $monkeyc -e -o $iq -f "monkey.jungle" -y $DevKey -r -w
    if ($LASTEXITCODE -ne 0) {
        throw "La compilacio ha fallat (codi $LASTEXITCODE)."
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Build de release OK -> $iq" -ForegroundColor Green
Write-Host "Aquest es el fitxer que cal pujar al Connect IQ Developer Portal." -ForegroundColor Green

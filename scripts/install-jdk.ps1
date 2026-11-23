$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$projectPath = Split-Path -Parent $PSScriptRoot
$archivePath = Join-Path $projectPath '.tooling\temurin21.zip'
$destinationPath = Join-Path $projectPath '.tooling\jdk21'
$metadata = Invoke-RestMethod -Uri 'https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse' -TimeoutSec 60
$package = @($metadata)[0].binary.package
if ($null -eq $package -or $package.link -notlike 'https://github.com/adoptium/*') {
  throw 'Metadata JDK resmi tidak sesuai.'
}
Write-Output ('Mengunduh ' + $package.name)
Invoke-WebRequest -UseBasicParsing -Uri $package.link -OutFile $archivePath -TimeoutSec 300
$actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
if ($actualHash -ne $package.checksum) { throw 'Checksum unduhan JDK tidak sesuai.' }
Expand-Archive -LiteralPath $archivePath -DestinationPath $destinationPath -Force
Write-Output 'JDK 21 tersimpan di .tooling/jdk21; konfigurasi Java global tidak diubah.'

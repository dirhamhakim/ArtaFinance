# Hanya memindahkan cache yang dibuat proyek ini, bukan data aplikasi/pengguna.
$ErrorActionPreference = 'Stop'
$projectPath = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$sourcePath = [IO.Path]::GetFullPath((Join-Path $projectPath '.tooling\gradle'))
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
$targetPath = [IO.Path]::GetFullPath((Join-Path $tempRoot 'Arta-Keuangan-Gradle'))
if (-not $sourcePath.StartsWith($projectPath+'\',[StringComparison]::OrdinalIgnoreCase) -or
    -not $targetPath.StartsWith($tempRoot+'\',[StringComparison]::OrdinalIgnoreCase)) {
  throw 'Lokasi cache keluar dari folder yang ditentukan.'
}
if (-not (Test-Path -LiteralPath $sourcePath)) { throw 'Cache sumber tidak ditemukan.' }
if (Test-Path -LiteralPath $targetPath) { throw 'Folder tujuan sudah ada; tidak akan ditimpa.' }
Write-Output ('Menyalin cache build: '+$sourcePath+' -> '+$targetPath)
& robocopy.exe $sourcePath $targetPath /E /COPY:DAT /DCOPY:DAT /R:1 /W:1 /NFL /NDL /NJH /NJS /NP
if ($LASTEXITCODE -ge 8) { throw 'Salinan cache belum selesai. Sumber tetap disimpan.' }
$sourceStats = Get-ChildItem -LiteralPath $sourcePath -Recurse -File -Force | Measure-Object -Property Length -Sum
$targetStats = Get-ChildItem -LiteralPath $targetPath -Recurse -File -Force | Measure-Object -Property Length -Sum
if ($sourceStats.Count -ne $targetStats.Count -or $sourceStats.Sum -ne $targetStats.Sum) {
  throw 'Ukuran/jumlah file berbeda. Sumber tetap disimpan.'
}
$locationFile = Join-Path $projectPath '.tooling\gradle-cache-path.txt'
Set-Content -LiteralPath $locationFile -Value $targetPath -Encoding UTF8
# Jalur sumber sudah diverifikasi sebagai cache di dalam workspace.
Remove-Item -LiteralPath $sourcePath -Recurse -Force
Write-Output ('Cache dipindahkan dan '+$sourceStats.Sum+' byte dikosongkan di drive proyek.')

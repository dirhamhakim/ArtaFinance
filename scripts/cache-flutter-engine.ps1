# Helper pengembangan opsional; bukan dependensi aplikasi Android.
param([string]$EngineCachePython = '')
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrEmpty($EngineCachePython)) {
  $pythonCommand = Get-Command python.exe -ErrorAction SilentlyContinue
  if ($null -ne $pythonCommand) { $EngineCachePython = $pythonCommand.Source }
  elseif (Test-Path -LiteralPath 'C:\Program Files\PostgreSQL\18\pgAdmin 4\python\python.exe') {
    $EngineCachePython = 'C:\Program Files\PostgreSQL\18\pgAdmin 4\python\python.exe'
  } else { throw 'Python 3 diperlukan hanya untuk helper pemulihan unduhan ini.' }
}
& $EngineCachePython (Join-Path $PSScriptRoot 'cache_flutter_engine.py')
exit $LASTEXITCODE

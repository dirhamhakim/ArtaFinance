param(
  [ValidateSet('Get','Fix','Check','Test','DeviceTest','Build','Doctor','Run','StopBuild')]
  [string]$Task = 'Check',
  [string]$DeviceId = '',
  [string]$TestName = ''
)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectPath
$env:PUB_CACHE = Join-Path $projectPath '.tooling\pub-cache'
$env:GRADLE_USER_HOME = Join-Path $projectPath '.tooling\gradle'
$gradleLocationFile = Join-Path $projectPath '.tooling\gradle-cache-path.txt'
if (Test-Path -LiteralPath $gradleLocationFile) {
  $env:GRADLE_USER_HOME = (Get-Content -LiteralPath $gradleLocationFile -Raw -Encoding UTF8).Trim()
}
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$flutterPath = Join-Path $projectPath '.tooling\flutter\bin\flutter.bat'
$dartPath = Join-Path $projectPath '.tooling\flutter\bin\dart.bat'
$jdkRoot = Join-Path $projectPath '.tooling\jdk21'
if (Test-Path -LiteralPath $jdkRoot) {
  $jdkDirectory = Get-ChildItem -LiteralPath $jdkRoot -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName 'bin\java.exe')
  } | Select-Object -First 1
  if ($null -ne $jdkDirectory) {
    $env:JAVA_HOME = $jdkDirectory.FullName
    $env:PATH = (Join-Path $env:JAVA_HOME 'bin') + [IO.Path]::PathSeparator + $env:PATH
  }
}
if (-not (Test-Path -LiteralPath $flutterPath)) {
  throw 'SDK Flutter lokal belum tersedia. Gunakan Flutter 3.50+ atau sesuaikan lokasi SDK.'
}
switch ($Task) {
  'Get' { & $flutterPath pub get }
  'Fix' {
    & $dartPath fix --apply --code=curly_braces_in_flow_control_structures lib
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $dartPath fix --apply --code=curly_braces_in_flow_control_structures test
  }
  'Check' {
    & $dartPath format lib test
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $flutterPath analyze
  }
  'Test' { & $flutterPath test --concurrency=1 }
  'DeviceTest' {
    if ([string]::IsNullOrWhiteSpace($DeviceId) -or $DeviceId.StartsWith('emulator-')) {
      throw 'DeviceTest memerlukan serial HP fisik dari adb devices; emulator tidak dipakai.'
    }
    $deviceTestArguments = @('test', 'integration_test/physical_device_test.dart', '-d', $DeviceId, '--reporter', 'expanded', '--no-uninstall')
    if (-not [string]::IsNullOrWhiteSpace($TestName)) {
      if ($TestName -notmatch '^[a-zA-Z0-9 _.-]+$') {
        throw 'TestName memakai potongan nama biasa, misalnya P02.'
      }
      $deviceTestArguments += @('--plain-name', $TestName)
    }
    $previousDeviceQa = $env:ARTA_DEVICE_QA
    try {
      $env:ARTA_DEVICE_QA = '1'
      & $flutterPath @deviceTestArguments
      $deviceTestExitCode = $LASTEXITCODE
    } finally {
      $env:ARTA_DEVICE_QA = $previousDeviceQa
    }
    exit $deviceTestExitCode
  }
  'Build' { & $flutterPath build apk --debug }
  'StopBuild' { & (Join-Path $projectPath 'android\gradlew.bat') --stop }
  'Doctor' { & $flutterPath doctor -v }
  'Run' { & $flutterPath run }
}
exit $LASTEXITCODE

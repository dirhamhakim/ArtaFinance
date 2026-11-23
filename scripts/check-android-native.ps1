param()
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectPath
$taskGradleCache = (Get-Content -LiteralPath '.tooling\gradle-cache-path.txt' -Raw -Encoding UTF8).Trim()
$taskModules = Join-Path $taskGradleCache 'caches\modules-2\files-2.1'
function Find-TaskJar([string]$Group, [string]$Artifact, [string]$Version = '') {
  $taskFolder = Join-Path (Join-Path $taskModules $Group) $Artifact
  if ($Version) { $taskFolder = Join-Path $taskFolder $Version }
  $taskJar = Get-ChildItem -LiteralPath $taskFolder -Filter '*.jar' -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $taskJar) { throw "Cached jar not found: $Group/$Artifact/$Version" }
  return $taskJar.FullName
}
$taskJava = Join-Path $projectPath '.tooling\jdk21\jdk-21.0.13+9\bin\java.exe'
$taskStdlib = Find-TaskJar 'org.jetbrains.kotlin' 'kotlin-stdlib' '2.4.20'
$taskRuntime = @(
  (Find-TaskJar 'org.jetbrains.kotlin' 'kotlin-compiler-embeddable' '2.4.20'),
  $taskStdlib,
  (Find-TaskJar 'org.jetbrains.kotlin' 'kotlin-script-runtime' '2.4.20'),
  (Find-TaskJar 'org.jetbrains.kotlin' 'kotlin-reflect'),
  (Find-TaskJar 'org.jetbrains.kotlinx' 'kotlinx-coroutines-core-jvm' '1.9.0'),
  (Find-TaskJar 'org.jetbrains' 'annotations')
) -join [IO.Path]::PathSeparator
$taskAndroidClasspath = @(
  $taskStdlib,
  (Join-Path $env:LOCALAPPDATA 'Android\sdk\platforms\android-36\android.jar'),
  (Find-TaskJar 'io.flutter' 'flutter_embedding_debug'),
  (Find-TaskJar 'androidx.lifecycle' 'lifecycle-common-jvm'),
  (Find-TaskJar 'androidx.annotation' 'annotation-jvm'),
  (Find-TaskJar 'org.jetbrains' 'annotations')
) -join [IO.Path]::PathSeparator
$taskOutput = Join-Path $projectPath 'build\native-check'
New-Item -ItemType Directory -Path $taskOutput -Force | Out-Null
$taskSources = @(Get-ChildItem -LiteralPath 'android\app\src\main\kotlin\id\arta\arta' -Filter '*.kt' -File | ForEach-Object FullName)
& $taskJava '-Xmx768m' '-cp' $taskRuntime 'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler' '-no-stdlib' '-no-reflect' '-jvm-target' '17' '-classpath' $taskAndroidClasspath '-d' (Join-Path $taskOutput 'android-types') @taskSources
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$taskPinSources = @('android\app\src\main\kotlin\id\arta\arta\PinPolicy.kt', 'test\native\PinPolicyCheck.kt')
& $taskJava '-Xmx768m' '-cp' $taskRuntime 'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler' '-no-stdlib' '-no-reflect' '-jvm-target' '17' '-classpath' $taskStdlib '-d' (Join-Path $taskOutput 'pin-tests') @taskPinSources
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$taskTestClasspath = (Join-Path $taskOutput 'pin-tests') + [IO.Path]::PathSeparator + $taskStdlib
& $taskJava '-cp' $taskTestClasspath 'id.arta.arta.PinPolicyCheckKt'
exit $LASTEXITCODE

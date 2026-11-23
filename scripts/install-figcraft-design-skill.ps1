$ErrorActionPreference = 'Stop'
$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sourceSkill = Join-Path $workspaceRoot 'skills\figcraft-ui-ux'
$codexSkillRoot = if ($env:CODEX_HOME) { Join-Path $env:CODEX_HOME 'skills' } else { Join-Path $env:USERPROFILE '.codex\skills' }
$destinationSkill = Join-Path $codexSkillRoot 'figcraft-ui-ux'
if (-not (Test-Path -LiteralPath (Join-Path $sourceSkill 'SKILL.md'))) { throw 'Staged SKILL.md is missing.' }
if (Test-Path -LiteralPath $destinationSkill) { throw "Skill already exists; refusing to overwrite: $destinationSkill" }
$pythonExecutable = Join-Path $env:LOCALAPPDATA 'Programs\Python\Python310\python.exe'
$validator = Join-Path $codexSkillRoot '.system\skill-creator\scripts\quick_validate.py'
& $pythonExecutable $validator $sourceSkill
if ($LASTEXITCODE -ne 0) { throw 'Skill validation failed; nothing was installed.' }
New-Item -ItemType Directory -Path $codexSkillRoot -Force | Out-Null
Copy-Item -LiteralPath $sourceSkill -Destination $destinationSkill -Recurse
$sourceHash = (Get-FileHash -LiteralPath (Join-Path $sourceSkill 'SKILL.md') -Algorithm SHA256).Hash
$installedHash = (Get-FileHash -LiteralPath (Join-Path $destinationSkill 'SKILL.md') -Algorithm SHA256).Hash
if ($sourceHash -ne $installedHash) { throw 'Installed skill hash does not match the staged file.' }
Write-Output "Installed and verified: $destinationSkill"

$referenceRoot = Join-Path $workspaceRoot 'docs\design\references'
New-Item -ItemType Directory -Path $referenceRoot -Force | Out-Null
$sources = @(
    @{ Name = 'stockbit-portfolio.png'; Url = 'https://storage.crisp.chat/users/helpdesk/website/-/d/e/f/1/def1e0e71ae1e800/1_x34o1b.png' },
    @{ Name = 'stockbit-performance.png'; Url = 'https://storage.crisp.chat/users/helpdesk/website/-/d/e/f/1/def1e0e71ae1e800/2_e9s479.png' },
    @{ Name = 'stockbit-company-chart.png'; Url = 'https://storage.crisp.chat/users/helpdesk/website/-/d/e/f/1/def1e0e71ae1e800/image_rszkpz.png' }
)
foreach ($reference in $sources) {
    $outputPath = Join-Path $referenceRoot $reference.Name
    & curl.exe --fail --location --connect-timeout 10 --max-time 20 --silent --show-error --output $outputPath $reference.Url
    if ($LASTEXITCODE -eq 0) {
        Write-Output "Downloaded reference: $($reference.Name)"
    } else {
        Write-Warning "Reference download failed: $($reference.Name). The source URL remains recorded in the design brief."
    }
}

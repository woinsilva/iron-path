param([switch]$Test, [ValidateSet("campaign", "prototype", "lab3d")][string]$Scene = "campaign")
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$candidates = @($env:GODOT_EXE, 'C:\Dev\Tools\Godot\Godot_v4.5.2-stable_win64_console.exe')
$installed = Get-Command godot -ErrorAction SilentlyContinue
if ($installed) { $candidates += $installed.Source }
$godotExe = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
if (-not $godotExe) { throw 'Godot nao encontrado. Configure GODOT_EXE com o caminho completo do executavel Godot 4.' }
if (-not $Test) {
    $gameArguments = @("--path", $projectRoot, "--resolution", "1280x720")
    if ($Scene -eq "prototype") { $gameArguments += "res://scenes/battle/battle.tscn" }
    if ($Scene -eq "lab3d") { $gameArguments += "res://scenes/lab3d/quality_lab.tscn" }
    & $godotExe @gameArguments
    exit $LASTEXITCODE
}
$resultsDir = Join-Path $projectRoot 'test-results'
New-Item -ItemType Directory -Force $resultsDir | Out-Null
$checks = @(
    @{ Name = 'import'; Arguments = @('--headless', '--path', $projectRoot, '--editor', '--quit') },
    @{ Name = 'unit'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/run_all.gd') },
    @{ Name = 'integration'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/smoke_battle.gd') },
    @{ Name = 'quality3d'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/pipeline3d/test_quality_lab.gd') },
    @{ Name = 'simulation3d'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_simulation.gd') },
    @{ Name = 'world3d'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_battle_view.gd') },
    @{ Name = 'stage01'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_stage01.gd') },
    @{ Name = 'release-flow'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_release_flow.gd') },
    @{ Name = 'lifecycle'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_lifecycle.gd') },
    @{ Name = 'campaign-save'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_campaign_save.gd') },
    @{ Name = 'statuses'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_statuses.gd') },
    @{ Name = 'alpha-world'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_alpha_view.gd') },
    @{ Name = 'alpha-campaign'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_alpha_campaign.gd') },
    @{ Name = 'arsenal'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_arsenal.gd') },
    @{ Name = 'arsenal-world'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_arsenal_view.gd') },
    @{ Name = 'captain'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_captain.gd') },
    @{ Name = 'captain-world'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_captain_view.gd') },
    @{ Name = 'audio'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_audio.gd') },
    @{ Name = 'tutorial'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_tutorial.gd') },
    @{ Name = 'vale'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_vale.gd') },
    @{ Name = 'healer'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_healer.gd') },
    @{ Name = 'canyon-world'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_canyon_view.gd') },
    @{ Name = 'stage05'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_stage05.gd') },
    @{ Name = 'quarry-world'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_quarry_view.gd') },
    @{ Name = 'stage06'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_stage06.gd') },
    @{ Name = 'shields'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_shields.gd') },
    @{ Name = 'fortress-world'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_fortress_view.gd') },
    @{ Name = 'stage07'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_stage07.gd') },
    @{ Name = 'forge-rules'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_forge.gd') },
    @{ Name = 'forge-world'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_forge_view.gd') },
    @{ Name = 'stage08'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_stage08.gd') },
    @{ Name = 'resistance'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_resistance.gd') },
    @{ Name = 'swamp-world'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_swamp_view.gd') },
    @{ Name = 'stage09'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_stage09.gd') },
    @{ Name = 'stage10'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_stage10.gd') },
    @{ Name = 'stage11'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_stage11.gd') },
    @{ Name = 'stage12'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_stage12.gd') },
    @{ Name = 'summoner'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_summoner.gd') },
    @{ Name = 'forecast-advice'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_forecast_advice.gd') },
    @{ Name = 'polish-world'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_polish_world.gd') },
    @{ Name = 'visual-aim'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_visual_aim.gd') },
    @{ Name = 'air-altitude'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_air_altitude.gd') },
    @{ Name = 'framing'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_framing.gd') },
    @{ Name = 'preparation'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_preparation.gd') },
    @{ Name = 'difficulties'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_difficulties.gd') },
    @{ Name = 'campaign-contract'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_campaign_contract.gd') },
    @{ Name = 'ruin-world'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_ruin_view.gd') },
    @{ Name = 'ruin-rules'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_ruin.gd') },
    @{ Name = 'burrow'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_burrow.gd') },
    @{ Name = 'sfx'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tests/simulation3d/test_sfx.gd') },
    @{ Name = 'arsenal-reference'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tools/measure_arsenal.gd') },
    @{ Name = 'gait-walk'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tools/measure_gait.gd') },
    @{ Name = 'gait-run'; Arguments = @('--headless', '--path', $projectRoot, '-s', 'res://tools/measure_gait.gd', '--', '--run') }
)
foreach ($check in $checks) {
    $arguments = $check.Arguments
    $output = & python -X utf8 (Join-Path $PSScriptRoot 'godot_test_process.py') --timeout 180 -- $godotExe @arguments 2>&1
    $resultCode = $LASTEXITCODE
    $output | Tee-Object -FilePath (Join-Path $resultsDir ($check.Name + '.log'))
    if ($resultCode -ne 0 -or ($output -match 'SCRIPT ERROR:|ERROR:|WARNING:')) {
        throw ('Falha em ' + $check.Name + '. Consulte test-results.')
    }
}
$gaitOutput = & python (Join-Path $PSScriptRoot 'assets/check_gait.py') 2>&1
$gaitResult = $LASTEXITCODE
$gaitOutput | Tee-Object -FilePath (Join-Path $resultsDir 'gait-calibration.log')
if ($gaitResult -ne 0) { throw 'Falha na calibracao de passada.' }
$arsenalOutput = & python -X utf8 (Join-Path $PSScriptRoot 'check_arsenal.py') 2>&1
$arsenalResult = $LASTEXITCODE
$arsenalOutput | Tee-Object -FilePath (Join-Path $resultsDir 'arsenal-role-checks.log')
if ($arsenalResult -ne 0) { throw 'Falha nos papeis das especializacoes.' }
$audioOutput = & python -X utf8 (Join-Path $PSScriptRoot 'check_audio.py') 2>&1
$audioResult = $LASTEXITCODE
$audioOutput | Tee-Object -FilePath (Join-Path $resultsDir 'audio-assets.log')
if ($audioResult -ne 0) { throw 'Falha nos assets de audio.' }
$sfxOutput = & python -X utf8 (Join-Path $PSScriptRoot 'check_sfx.py') 2>&1
$sfxResult = $LASTEXITCODE
$sfxOutput | Tee-Object -FilePath (Join-Path $resultsDir 'sfx-assets.log')
if ($sfxResult -ne 0) { throw 'Falha nos efeitos sonoros.' }
Write-Host 'Importacao, testes unitarios, integracao e laboratorio 3D aprovados.'

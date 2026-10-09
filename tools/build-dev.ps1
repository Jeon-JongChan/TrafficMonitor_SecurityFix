<#
.SYNOPSIS
    TrafficMonitor 개발용 포터블 빠른 빌드 스크립트
.DESCRIPTION
    어느 PC에서든 Visual Studio / Build Tools 환경을 자동 감지하여 TrafficMonitor 솔루션을 빠르게 빌드합니다.
.PARAMETER Configuration
    빌드 구성 (Release, Debug). 기본값: Release
.PARAMETER Platform
    빌드 플랫폼 (x64, x86). 기본값: x64
#>

param(
    [string]$Configuration = "Release",
    [string]$Platform = "x64"
)

if ([string]::IsNullOrWhiteSpace($Configuration)) { $Configuration = "Release" }
if ([string]::IsNullOrWhiteSpace($Platform)) { $Platform = "x64" }
if ($Platform -ieq "Win32") { $Platform = "x86" }

$ErrorActionPreference = "Stop"

$taskRoot = Split-Path $PSScriptRoot -Parent
Set-Location $taskRoot

Write-Host "[TrafficMonitor Dev Build] Target: $Configuration | $Platform" -ForegroundColor Cyan

# 1. vswhere를 통한 MSBuild 탐색 (-products * 포함하여 BuildTools까지 검색)
$msbuild = $null
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

if (Test-Path $vswhere) {
    $found = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find "MSBuild\**\Bin\MSBuild.exe" 2>$null
    if ($found -and (Test-Path $found)) {
        $msbuild = $found
    }
}

# 2. 일반 고정 경로 폴백 탐색
if (-not $msbuild) {
    $candidates = @(
        "C:\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
    )
    foreach ($cand in $candidates) {
        if (Test-Path $cand) {
            $msbuild = $cand
            break
        }
    }
}

if (-not $msbuild) {
    Write-Error "[ERROR] MSBuild를 찾을 수 없습니다. Visual Studio 또는 Visual Studio Build Tools가 설치되어 있는지 확인하세요."
    exit 1
}

Write-Host "[TrafficMonitor Dev Build] Found MSBuild: $msbuild" -ForegroundColor Green
$slnPath = Join-Path $taskRoot "TrafficMonitor.sln"

Write-Host "[TrafficMonitor Dev Build] Building $slnPath ..." -ForegroundColor Cyan
& $msbuild $slnPath "/p:Configuration=$Configuration" "/p:Platform=$Platform" "/v:minimal" "/m"

if ($LASTEXITCODE -ne 0) {
    Write-Error "[ERROR] 빌드에 실패했습니다. (코드: $LASTEXITCODE)"
    exit $LASTEXITCODE
}

Write-Host "[TrafficMonitor Dev Build] 빌드 완료!" -ForegroundColor Green
if ($Platform -eq "x64") {
    $outPath = Join-Path $taskRoot "Bin\x64\$Configuration\TrafficMonitor.exe"
} else {
    $outPath = Join-Path $taskRoot "Bin\$Configuration\TrafficMonitor.exe"
}
Write-Host "[Output] $outPath" -ForegroundColor Yellow


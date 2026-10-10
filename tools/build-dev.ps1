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

# 빌드 환경 확인 및 자동 부트스트랩 (로컬 .build\BuildTools 우선, 없을 시 최신 자동 설치)
. "$PSScriptRoot\ensure-buildtools.ps1"
$buildEnv = Get-BuildToolsEnvironment -AutoInstall
$msbuild = $buildEnv.MSBuildPath

if ($buildEnv.IsPortable) {
    Write-Host "[BuildTools] 포터블 빌드 도구 사용: $($buildEnv.InstallationPath)" -ForegroundColor Green
} else {
    Write-Host "[BuildTools] 시스템 빌드 도구 사용: $($buildEnv.InstallationPath)" -ForegroundColor Gray
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


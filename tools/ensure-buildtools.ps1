<#
.SYNOPSIS
    TrafficMonitor 빌드 도구(MSBuild 및 MSVC C++) 환경 탐색 및 자동 부트스트랩 스크립트
.DESCRIPTION
    1. 프로젝트 로컬 포터블 경로 (.build\BuildTools)를 최우선으로 탐색합니다.
    2. 로컬에 없으면 시스템에 설치된 Visual Studio / Build Tools (vswhere 및 폴백 경로)를 탐색합니다.
    3. 빌드 도구가 완전히 없을 경우 Microsoft 공식 최신 vs_buildtools.exe를 다운로드하여 .build\BuildTools에 자동 설치합니다.
#>

param(
    [switch]$AutoInstall = $false
)

function Install-LatestBuildTools {
    <#
    .SYNOPSIS
        최신 Visual Studio Build Tools 인스톨러를 다운로드하여 로컬 .build\BuildTools에 포터블 설치합니다.
    .PARAMETER TargetDir
        설치 대상 디렉터리 경로 (.build\BuildTools)
    .OUTPUTS
        [hashtable] 설치된 빌드 도구 경로 정보
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetDir
    )

    $installerUrl = "https://aka.ms/vs/17/release/vs_buildtools.exe"
    $buildDir = Split-Path $TargetDir -Parent
    $installerPath = Join-Path $buildDir "vs_buildtools.exe"

    Write-Host "[BuildTools] C++ 빌드 환경이 감지되지 않았습니다." -ForegroundColor Yellow
    Write-Host "[BuildTools] Microsoft 최신 Visual Studio Build Tools 다운로드 중..." -ForegroundColor Cyan
    Write-Host "             URL: $installerUrl" -ForegroundColor Gray

    # .build 디렉터리가 없으면 생성
    if (-not (Test-Path $buildDir)) {
        New-Item -Path $buildDir -ItemType Directory -Force | Out-Null
    }

    # 최신 부트스트래퍼 다운로드
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing

    Write-Host "[BuildTools] .build\BuildTools 에 C++ 필수 컴포넌트 자동 설치 중 (수 분 소요)..." -ForegroundColor Cyan
    
    # TrafficMonitor 빌드에 필요한 핵심 컴포넌트 정의 (MSVC, MFC, ATL, C++/CLI, Windows SDK)
    $installArgs = @(
        "--installPath", "`"$TargetDir`"",
        "--quiet",
        "--wait",
        "--norestart",
        "--noUpdateInstaller",
        "--add", "Microsoft.VisualStudio.Workload.VCTools",
        "--add", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "--add", "Microsoft.VisualStudio.Component.VC.ATLMFC",
        "--add", "Microsoft.VisualStudio.Component.VC.CLI.Support",
        "--add", "Microsoft.VisualStudio.Component.Windows11SDK.26100"
    )

    $process = Start-Process -FilePath $installerPath -ArgumentList ($installArgs -join " ") -Wait -PassThru -NoNewWindow
    
    # 다운로드한 임시 인스톨러 파일 정리
    if (Test-Path $installerPath) {
        # 임시 인스톨러는 다운로드한 일회성 파일이므로 즉시 안전 정리
        Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
    }

    if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 3010) {
        throw "Visual Studio Build Tools 자동 설치에 실패했습니다 (종료 코드: $($process.ExitCode))."
    }

    Write-Host "[BuildTools] 포터블 빌드 도구 설치 완료." -ForegroundColor Green
}

function Get-BuildToolsEnvironment {
    <#
    .SYNOPSIS
        빌드 도구(MSBuild, VsDevCmd, 설치 루트) 경로를 탐색하여 해시테이블로 반환합니다.
    .PARAMETER AutoInstall
        도구가 없을 때 자동으로 최신 버전을 다운로드 및 설치할지 여부
    .OUTPUTS
        [hashtable] @{ InstallationPath = ...; MSBuildPath = ...; VsDevCmdPath = ... }
    #>
    param(
        [switch]$AutoInstall = $false
    )

    $scriptDir = Split-Path $PSScriptRoot -Parent
    if ([string]::IsNullOrWhiteSpace($scriptDir)) {
        $scriptDir = (Get-Location).Path
    }

    # 1. 프로젝트 로컬 포터블 경로 최우선 확인
    $portableRoot = Join-Path $scriptDir ".build\BuildTools"
    $portableMsBuild = Join-Path $portableRoot "MSBuild\Current\Bin\MSBuild.exe"
    $portableDevCmd = Join-Path $portableRoot "Common7\Tools\VsDevCmd.bat"

    if ((Test-Path $portableMsBuild) -and (Test-Path $portableDevCmd)) {
        return @{
            InstallationPath = $portableRoot
            MSBuildPath      = $portableMsBuild
            VsDevCmdPath     = $portableDevCmd
            IsPortable       = $true
        }
    }

    # 2. 시스템 vswhere 탐색
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsInstall = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
        if ($vsInstall -and (Test-Path $vsInstall)) {
            $msBuild = Join-Path $vsInstall "MSBuild\Current\Bin\MSBuild.exe"
            $devCmd = Join-Path $vsInstall "Common7\Tools\VsDevCmd.bat"
            if ((Test-Path $msBuild) -and (Test-Path $devCmd)) {
                return @{
                    InstallationPath = $vsInstall
                    MSBuildPath      = $msBuild
                    VsDevCmdPath     = $devCmd
                    IsPortable       = $false
                }
            }
        }
    }

    # 3. 고정 시스템 경로 폴백 탐색
    $candidates = @(
        "C:\BuildTools",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools"
    )

    foreach ($cand in $candidates) {
        $msBuild = Join-Path $cand "MSBuild\Current\Bin\MSBuild.exe"
        $devCmd = Join-Path $cand "Common7\Tools\VsDevCmd.bat"
        if ((Test-Path $msBuild) -and (Test-Path $devCmd)) {
            return @{
                InstallationPath = $cand
                MSBuildPath      = $msBuild
                VsDevCmdPath     = $devCmd
                IsPortable       = $false
            }
        }
    }

    # 4. 도구가 전혀 없고 AutoInstall이 켜져 있는 경우 최신 버전 자동 다운로드 및 설치
    if ($AutoInstall) {
        Install-LatestBuildTools -TargetDir $portableRoot
        if ((Test-Path $portableMsBuild) -and (Test-Path $portableDevCmd)) {
            return @{
                InstallationPath = $portableRoot
                MSBuildPath      = $portableMsBuild
                VsDevCmdPath     = $portableDevCmd
                IsPortable       = $true
            }
        }
    }

    throw "Visual Studio C++ 빌드 도구를 찾을 수 없습니다. (로컬 .build\BuildTools 또는 시스템 설치 필요)"
}


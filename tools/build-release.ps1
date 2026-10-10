<#
.SYNOPSIS
공식 PawnIO 라이브러리를 복원하고 전체 기능 버전을 빌드·검증·압축한다.
.PARAMETER Platform
기존 솔루션의 x64, x86 또는 ARM64EC 빌드 구성이다.
#>
[CmdletBinding()]
param([ValidateSet('x64', 'x86', 'ARM64EC')][string]$Platform = 'x64')

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
$taskRoot = Split-Path $PSScriptRoot -Parent
Set-Location $taskRoot
# C++ 빌드 환경 확인 및 자동 부트스트랩 (로컬 .build\BuildTools 우선)
. "$PSScriptRoot\ensure-buildtools.ps1"
$taskBuildEnv = Get-BuildToolsEnvironment -AutoInstall
$taskVs = $taskBuildEnv.InstallationPath
$taskMsBuild = $taskBuildEnv.MSBuildPath

# 프로젝트 내부에 준비한 SDK가 있으면 전역 설치 대신 사용한다.
$taskDotnet = if (Test-Path '.build\dotnet\dotnet.exe') { Join-Path $taskRoot '.build\dotnet\dotnet.exe' } else { 'dotnet' }
$env:DOTNET_CLI_HOME = Join-Path $taskRoot '.build\dotnet-home'
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
$env:DOTNET_NOLOGO = '1'
# ARM64EC 프로그램의 관리 코드 래퍼는 기존 솔루션과 동일하게 x64를 사용한다.
$taskRid = if ($Platform -eq 'x86') { 'win-x86' } else { 'win-x64' }
& $taskDotnet build 'tools\HardwareDependencies.csproj' -c Release "-p:RuntimeIdentifier=$taskRid" --nologo --verbosity quiet
if ($LASTEXITCODE -ne 0) { throw '하드웨어 종속성 복원에 실패했습니다.' }
$taskRuntime = Join-Path $taskRoot ".build\hardware\$taskRid"
$taskAssembly = [Reflection.Assembly]::ReflectionOnlyLoadFrom((Join-Path $taskRuntime 'LibreHardwareMonitorLib.dll'))
$taskResources = $taskAssembly.GetManifestResourceNames()
$taskExpectedArch = if ($Platform -eq 'x86') { 'X86' } else { 'Amd64' }
# 취약 드라이버가 들어간 DLL이나 참조 전용 DLL을 배포하지 않는다.
if ($taskAssembly.GetName().Version -ne [Version]'0.9.6.0' -or
    $taskAssembly.GetName().ProcessorArchitecture.ToString() -ne $taskExpectedArch -or
    ($taskResources -match 'WinRing|\.sys') -or -not ($taskResources -match 'PawnIo')) {
    throw 'PawnIO 기반 런타임 라이브러리 검증에 실패했습니다.'
}

& $taskMsBuild 'TrafficMonitor.sln' /t:TrafficMonitor /m /nologo /v:minimal /p:Configuration=Release "/p:Platform=$Platform" /p:PlatformToolset=v143
if ($LASTEXITCODE -ne 0) { throw 'TrafficMonitor 빌드에 실패했습니다.' }
$taskOutput = if ($Platform -eq 'x86') { Join-Path $taskRoot 'Bin\Release' } else { Join-Path $taskRoot "Bin\$Platform\Release" }
$taskWrapperOutput = if ($Platform -eq 'ARM64EC') { Join-Path $taskRoot 'Bin\x64\Release' } else { $taskOutput }
Get-ChildItem $taskRuntime -Filter '*.dll' | Where-Object Name -ne 'HardwareDependencies.dll' | Copy-Item -Destination $taskWrapperOutput
Copy-Item (Join-Path $taskRuntime 'HardwareDependencies.dll.config') (Join-Path $taskWrapperOutput 'hardware_monitor_smoke.exe.config')

$taskDevCmd = Join-Path $taskVs 'Common7\Tools\VsDevCmd.bat'
$taskArch = if ($Platform -eq 'x86') { 'x86' } else { 'x64' }
$taskSmoke = Join-Path $taskWrapperOutput 'hardware_monitor_smoke.exe'
$taskCompile = '"{0}" -no_logo -arch={1} && cl.exe /nologo /EHsc /MD /utf-8 /std:c++17 /I"{2}\include" "{2}\tests\hardware_monitor_smoke.cpp" /Fo"{3}\hardware_monitor_smoke.obj" /Fe"{4}" /link /LIBPATH:"{3}" OpenHardwareMonitorApi.lib' -f $taskDevCmd, $taskArch, $taskRoot, $taskWrapperOutput, $taskSmoke
& $env:ComSpec /d /s /c $taskCompile
if ($LASTEXITCODE -ne 0) { throw '하드웨어 래퍼 검사 프로그램을 빌드하지 못했습니다.' }
& $taskSmoke
if ($LASTEXITCODE -ne 0) { throw "하드웨어 래퍼 검사 실패: $LASTEXITCODE" }

# 가상 DIMM으로 실측값 선택과 결측값 처리를 검사한다. 실제 RAM 센서가 없어도 실행된다.
$taskMemoryCheck = Join-Path $taskWrapperOutput 'memory_temperature_check.exe'
$taskCompile = '"{0}" -no_logo -arch={1} && cl.exe /nologo /clr /EHa /MD /utf-8 /std:c++17 /DOPENHARDWAREMONITOR_EXPORTS /I"{2}\include" /AI"{3}" /FU"{3}\LibreHardwareMonitorLib.dll" "{2}\tests\memory_temperature_check.cpp" /Fo"{4}\memory_temperature_check.obj" /Fe"{5}"' -f $taskDevCmd, $taskArch, $taskRoot, $taskRuntime, $taskWrapperOutput, $taskMemoryCheck
& $env:ComSpec /d /s /c $taskCompile
if ($LASTEXITCODE -ne 0) { throw 'RAM 센서 검사 프로그램을 빌드하지 못했습니다.' }
Copy-Item (Join-Path $taskRuntime 'HardwareDependencies.dll.config') "$taskMemoryCheck.config"
& $taskMemoryCheck
if ($LASTEXITCODE -ne 0) { throw "RAM 센서 검사 실패: $LASTEXITCODE" }

# 새 스테이징 폴더를 사용해 이전 빌드 파일이 압축에 섞이지 않게 한다.
$taskStage = Join-Path $taskRoot ('.build\stage\{0}-{1}\TrafficMonitor' -f $Platform, [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $taskStage -Force | Out-Null
Copy-Item (Join-Path $taskOutput 'TrafficMonitor.exe') $taskStage
Copy-Item (Join-Path $taskWrapperOutput 'OpenHardwareMonitorApi.dll') $taskStage
Get-ChildItem $taskRuntime -Filter '*.dll' | Where-Object Name -ne 'HardwareDependencies.dll' | Copy-Item -Destination $taskStage
Copy-Item (Join-Path $taskRuntime 'HardwareDependencies.dll.config') (Join-Path $taskStage 'TrafficMonitor.exe.config')
Copy-Item 'LICENSE' $taskStage
Copy-Item 'tools\licenses' (Join-Path $taskStage 'licenses') -Recurse
# 복원 결과에 기록된 패키지의 저작권·라이선스와 원본 저장소 정보를 함께 배포한다.
$taskAssets = Get-Content 'tools\obj\project.assets.json' -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($taskPackage in $taskAssets.libraries.PSObject.Properties | Where-Object { $_.Value.type -eq 'package' }) {
    $taskPackageDir = Join-Path $taskRoot ('.build\packages\' + $taskPackage.Value.path)
    $taskLegalDir = Join-Path $taskStage ('licenses\' + ($taskPackage.Name -replace '/', '-'))
    New-Item -ItemType Directory $taskLegalDir -Force | Out-Null
    Get-ChildItem $taskPackageDir -File | Where-Object { $_.Name -match '\.nuspec$|license|notice|copying' } |
        Copy-Item -Destination $taskLegalDir
}
if (Test-Path 'TrafficMonitor\skins') { Copy-Item 'TrafficMonitor\skins' $taskStage -Recurse }
$readmeContent = @'
TrafficMonitor PawnIO 보안 수정 버전

CPU·메인보드·RAM 온도를 사용하려면 https://pawnio.eu/ 에서 공식 서명 PawnIO를 설치하세요.
RAM 온도는 옵션의 하드웨어 모니터링에서 RAM을 켠 뒤 작업 표시줄 표시 항목에서 선택하세요.
여러 DIMM 중 최고 온도를 표시하며 RAM에 온도 센서가 없거나 SMBus 접근이 지원되지 않으면 측정할 수 없습니다.
하드웨어 모니터링은 옵션에서 활성화합니다. PawnIO 미설치 시 일부 센서가 제공되지 않습니다.
Microsoft Visual C++ 2015-2022 재배포 패키지와 .NET Framework 4.7.2 이상이 필요합니다.
구형 설치 폴더에 덮어쓰기보다 이 압축 파일을 새 폴더에 풀어 사용하세요.

수정 소스: https://github.com/Jeon-JongChan/TrafficMonitor_SecurityFix
LibreHardwareMonitor 0.9.6 (MPL-2.0): https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/tree/v0.9.6
종속성 및 각 라이선스: https://www.nuget.org/packages/LibreHardwareMonitorLib/0.9.6
WinRing0 관련 리소스 검사는 통과했으며 실제 PC의 센서와 Defender 동작은 별도 확인이 필요합니다.
'@
$readmeContent | Set-Content -LiteralPath (Join-Path $taskStage '설치안내.txt') -Encoding UTF8

New-Item -ItemType Directory '.build\releases' -Force | Out-Null
$taskArchive = ".build\releases\TrafficMonitor_v1.86-pawnio.1_$Platform.zip"
Compress-Archive -Path "$taskStage\*" -DestinationPath $taskArchive -Force
Get-FileHash $taskArchive -Algorithm SHA256 | ForEach-Object { "$($_.Hash.ToLower())  $(Split-Path $_.Path -Leaf)" } |
    Set-Content -LiteralPath "$taskArchive.sha256" -Encoding ASCII
Write-Host "빌드·검사·패키징 완료: $taskArchive"

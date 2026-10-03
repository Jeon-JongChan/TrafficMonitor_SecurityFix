@echo off
rem 기존 PowerShell 스크립트로 종속성 복원, 빌드, 검사와 ZIP 생성을 실행한다.
rem 인수는 x64, x86 또는 ARM64EC이며 생략하면 x64를 빌드한다.
rem 스크립트 경로를 기준으로 호출해 실행 폴더와 공백이 있는 경로에 대응한다.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-release.ps1" %*
rem 실패를 호출한 CMD에서도 확인할 수 있도록 종료 코드를 전달한다.
exit /b %errorlevel%

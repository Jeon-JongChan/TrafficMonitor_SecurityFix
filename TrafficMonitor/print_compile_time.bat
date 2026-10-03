@echo off
REM 기존 파일 삭제 없이 현재 빌드 시각을 기록한다.
>compile_time.txt echo %date:~0,10%
>>compile_time.txt echo %time:~0,8%

@echo off
title TN Therapist List Builder - Hopes and Dreams
setlocal EnableDelayedExpansion

rem ── Everything important also goes to a log file on the Desktop
set "LOG=%USERPROFILE%\Desktop\RUN_ME_log.txt"
if defined OneDrive if exist "%OneDrive%\Desktop\" set "LOG=%OneDrive%\Desktop\RUN_ME_log.txt"
echo ===== RUN %date% %time% ===== > "%LOG%"

echo.
echo  TN Therapist List Builder - Hopes and Dreams
echo  ============================================
echo  ^(A report of this run is being saved to RUN_ME_log.txt on your Desktop -
echo   if anything goes wrong, just send Claude that file.^)
echo.

rem ── Find the engine script: same folder, Downloads, Desktop, OneDrive Desktop.
set "PS1="
for %%F in ("%~dp0tn_therapist_list*.ps1") do if not defined PS1 set "PS1=%%~fF"
if not defined PS1 for %%F in ("%USERPROFILE%\Downloads\tn_therapist_list*.ps1") do if not defined PS1 set "PS1=%%~fF"
if not defined PS1 for %%F in ("%USERPROFILE%\Desktop\tn_therapist_list*.ps1") do if not defined PS1 set "PS1=%%~fF"
if not defined PS1 if defined OneDrive for %%F in ("%OneDrive%\Desktop\tn_therapist_list*.ps1") do if not defined PS1 set "PS1=%%~fF"

if not defined PS1 (
    echo PROBLEM: engine file tn_therapist_list.ps1 was NOT FOUND. >> "%LOG%"
    echo Searched: %~dp0 , Downloads, Desktop, OneDrive Desktop >> "%LOG%"
    echo  PROBLEM FOUND: I can't find the engine file  tn_therapist_list.ps1
    echo.
    echo  FIX: download tn_therapist_list.ps1 from the chat again and put it
    echo  on your DESKTOP, next to this RUN_ME file. Then run RUN_ME again.
    echo.
    echo  ^(This problem was also written to RUN_ME_log.txt on your Desktop.^)
    pause
    exit /b 1
)

echo Engine found at: !PS1! >> "%LOG%"
echo  Found engine: !PS1!
powershell -NoProfile -Command "Unblock-File -LiteralPath '!PS1!'" >nul 2>&1

echo  Starting - takes 5-10 minutes. Leave this window alone.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { & '!PS1!' } *>&1 | Tee-Object -FilePath '%LOG%' -Append"

echo.
echo  ============================================
echo  Finished. If it said "Done" above, your two spreadsheets are on
echo  your Desktop. If not, send Claude the file  RUN_ME_log.txt
echo  from your Desktop - it contains everything that happened.
echo.
pause

@echo off
title TN Therapist List Builder - Hopes and Dreams
setlocal EnableDelayedExpansion
echo.
echo  TN Therapist List Builder - Hopes and Dreams
echo  ============================================
echo.

rem ── Find the engine script: same folder, then Downloads, then Desktop.
rem    Wildcards catch browser renames like "tn_therapist_list (1).ps1".
set "PS1="
for %%F in ("%~dp0tn_therapist_list*.ps1") do if not defined PS1 set "PS1=%%~fF"
if not defined PS1 for %%F in ("%USERPROFILE%\Downloads\tn_therapist_list*.ps1") do if not defined PS1 set "PS1=%%~fF"
if not defined PS1 for %%F in ("%USERPROFILE%\Desktop\tn_therapist_list*.ps1") do if not defined PS1 set "PS1=%%~fF"
if not defined PS1 for %%F in ("%OneDrive%\Desktop\tn_therapist_list*.ps1") do if not defined PS1 set "PS1=%%~fF"

if not defined PS1 (
    echo  PROBLEM FOUND: I can't find the engine file  tn_therapist_list.ps1
    echo.
    echo  FIX: download tn_therapist_list.ps1 again and put it in the SAME
    echo  folder as this RUN_ME file ^(your Desktop is easiest^), then
    echo  double-click RUN_ME again.
    echo.
    pause
    exit /b 1
)

echo  Found engine: !PS1!
echo  Un-blocking it ^(Windows marks downloaded files^)...
powershell -NoProfile -Command "Unblock-File -LiteralPath '!PS1!'" >nul 2>&1

echo  Starting - this takes 5-10 minutes. Leave this window alone.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "!PS1!"

echo.
echo  ============================================
echo  If you see red error text above, take a photo of this window
echo  and send it to Claude. If it said "Done", your two spreadsheets
echo  are on your Desktop.
echo.
pause

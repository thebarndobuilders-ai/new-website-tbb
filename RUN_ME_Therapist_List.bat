@echo off
title TN Therapist List Builder - Hopes and Dreams
echo.
echo  Building your Tennessee SLP and OT lists...
echo  This takes 5-10 minutes. Two files will appear on your Desktop.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tn_therapist_list.ps1"

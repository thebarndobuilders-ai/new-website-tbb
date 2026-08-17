@echo off
title Hopes and Dreams - TN Therapist List
echo.
echo  Hopes and Dreams - TN Therapist List Builder
echo  =============================================
echo  Runs 5-10 minutes. Leave this window alone until it says DONE.
echo  A report is saved to RUN_ME_log.txt on your Desktop either way.
echo.
rem Find the line number of the payload marker (last match wins), copy
rem everything after it to a temp .ps1, and run that file directly.
set "LN="
for /f "delims=:" %%N in ('findstr /n /c:"### POWERSHELL PAYLOAD ###" "%~f0"') do set "LN=%%N"
if not defined LN (
    echo  This file looks damaged - please re-download it from the chat.
    pause
    exit /b 1
)
set "ENG=%TEMP%\hopes_dreams_engine.ps1"
more +%LN% "%~f0" > "%ENG%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ENG%"
echo.
pause
goto :eof

### POWERSHELL PAYLOAD ###
$ErrorActionPreference = "Stop"
$desktop = [Environment]::GetFolderPath("Desktop")
try { Start-Transcript -Path (Join-Path $desktop "RUN_ME_log.txt") -Force | Out-Null } catch {}

try {
    $api = "https://npiregistry.cms.hhs.gov/api/"
    $professions = @(
        @{ Name = "Speech-Language Pathologist";    File = "TN_Speech_Therapists.csv" },
        @{ Name = "Occupational Therapist";         File = "TN_Occupational_Therapists.csv" },
        @{ Name = "Occupational Therapy Assistant"; File = "TN_OT_Assistants.csv" },
        @{ Name = "Speech-Language Assistant";      File = "TN_Speech_Assistants.csv" }
    )
    $zipPrefixes = 370..385 | ForEach-Object { "$_*" }

    foreach ($prof in $professions) {
        Write-Host ""
        Write-Host "== Pulling: $($prof.Name) in TN ==" -ForegroundColor Cyan
        $seen = @{}
        $out  = New-Object System.Collections.Generic.List[object]

        foreach ($zip in $zipPrefixes) {
            $skip = 0
            while ($true) {
                $qs = "version=2.1&enumeration_type=NPI-1&state=TN&postal_code=$([uri]::EscapeDataString($zip))&taxonomy_description=$([uri]::EscapeDataString($prof.Name))&limit=200&skip=$skip"
                try   { $resp = Invoke-RestMethod -Uri ($api + "?" + $qs) -TimeoutSec 60 }
                catch { Write-Warning "Retrying zip $zip : $_"; Start-Sleep 3
                        $resp = Invoke-RestMethod -Uri ($api + "?" + $qs) -TimeoutSec 60 }

                $count = 0
                if ($resp.results) { $count = @($resp.results).Count }
                if ($count -eq 0) { break }

                foreach ($r in $resp.results) {
                    if ($seen.ContainsKey($r.number)) { continue }
                    $seen[$r.number] = $true
                    $loc = $r.addresses  | Where-Object { $_.address_purpose -eq "LOCATION" } | Select-Object -First 1
                    $tax = $r.taxonomies | Where-Object { $_.primary } | Select-Object -First 1
                    if (-not $tax) { $tax = $r.taxonomies | Select-Object -First 1 }
                    $out.Add([pscustomobject]@{
                        NPI        = $r.number
                        FirstName  = $r.basic.first_name
                        LastName   = $r.basic.last_name
                        Credential = $r.basic.credential
                        Taxonomy   = $tax.desc
                        LicenseNum = $tax.license
                        Address    = ("{0} {1}" -f $loc.address_1, $loc.address_2).Trim()
                        City       = $loc.city
                        State      = $loc.state
                        Zip        = $loc.postal_code
                        Phone      = $loc.telephone_number
                        Enumerated = $r.basic.enumeration_date
                    })
                }
                if ($count -lt 200 -or $skip -ge 1000) { break }
                $skip += 200
                Start-Sleep -Milliseconds 400
            }
            Write-Host ("  zip {0,-5} done - {1} unique so far" -f $zip, $seen.Count)
        }

        $dest = Join-Path $desktop $prof.File
        $sorted = $out | Sort-Object LastName, FirstName
        try {
            $sorted | Export-Csv -Path $dest -NoTypeInformation -Encoding UTF8
        } catch {
            # File locked (open in Excel?) — save under a numbered name instead
            $alt = Join-Path $desktop ($prof.File -replace "\.csv$", "_NEW.csv")
            Write-Warning "$($prof.File) is open in another program - saving as $(Split-Path $alt -Leaf) instead. Close Excel next time."
            $sorted | Export-Csv -Path $alt -NoTypeInformation -Encoding UTF8
            $dest = $alt
        }
        Write-Host ""
        Write-Host ">>> $($seen.Count) $($prof.Name)s saved to: $dest" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "DONE. Both spreadsheets are on your Desktop." -ForegroundColor Green
    Write-Host "Next: open the Hopes and Dreams tool -> Recruiting tab -> Load therapist CSV."
}
catch {
    Write-Host ""
    Write-Host "SOMETHING WENT WRONG:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "Send RUN_ME_log.txt from your Desktop to Claude - it has the details."
}
finally {
    try { Stop-Transcript | Out-Null } catch {}
}

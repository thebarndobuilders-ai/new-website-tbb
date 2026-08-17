@echo off
title Hopes and Dreams - TN Therapist List
echo.
echo  Hopes and Dreams - TN Therapist List Builder  (v3 - specialty sweep)
echo  ====================================================================
echo  Runs 15-25 minutes. Leave this window alone until it says DONE.
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
    # The registry indexes specializations by their SHORT names ("Pediatrics"),
    # so we sweep base professions AND every specialty name, then sort matches
    # by official taxonomy code: 235Z=SLP, 225X=OT, 224Z=OTA, 2355S=SLP-Assistant.
    $queries = @(
        "Speech-Language Pathologist", "Occupational Therapist",
        "Occupational Therapy Assistant", "Speech-Language Assistant",
        "Pediatrics", "Hand", "Neurorehabilitation", "Physical Rehabilitation",
        "Gerontology", "Mental Health", "Low Vision",
        "Driving and Community Mobility", "Environmental Modification",
        "Ergonomics", "Human Factors", "Feeding, Eating & Swallowing",
        "Occupational Therapist, Pediatrics", "Occupational Therapist, Hand",
        "Occupational Therapist, Gerontology", "Occupational Therapist, Neurorehabilitation",
        "Occupational Therapist, Physical Rehabilitation", "Occupational Therapist, Mental Health",
        "Occupational Therapist, Low Vision", "Occupational Therapist, Driving and Community Mobility",
        "Occupational Therapist, Environmental Modification", "Occupational Therapist, Ergonomics",
        "Occupational Therapist, Human Factors", "Occupational Therapist, Feeding, Eating & Swallowing",
        "Occupational Therapy Assistant, Driving and Community Mobility",
        "Occupational Therapy Assistant, Environmental Modification",
        "Occupational Therapy Assistant, Feeding, Eating & Swallowing",
        "Occupational Therapy Assistant, Low Vision"
    )
    $zipPrefixes = 370..385 | ForEach-Object { "$_*" }
    $pool = @{}

    foreach ($q in $queries) {
        Write-Host ""
        Write-Host "== Sweep: '$q' in TN ==" -ForegroundColor Cyan
        $before = $pool.Count
        foreach ($zip in $zipPrefixes) {
            $skip = 0
            while ($true) {
                $qs = "version=2.1&enumeration_type=NPI-1&state=TN&postal_code=$([uri]::EscapeDataString($zip))&taxonomy_description=$([uri]::EscapeDataString($q))&limit=200&skip=$skip"
                try   { $resp = Invoke-RestMethod -Uri ($api + "?" + $qs) -TimeoutSec 60 }
                catch { Write-Warning "Retrying zip $zip : $_"; Start-Sleep 3
                        $resp = Invoke-RestMethod -Uri ($api + "?" + $qs) -TimeoutSec 60 }
                $count = 0
                if ($resp.results) { $count = @($resp.results).Count }
                if ($count -eq 0) { break }
                foreach ($r in $resp.results) {
                    if ($pool.ContainsKey($r.number)) { continue }
                    $loc = $r.addresses  | Where-Object { $_.address_purpose -eq "LOCATION" } | Select-Object -First 1
                    $tax = $r.taxonomies | Where-Object { $_.primary } | Select-Object -First 1
                    if (-not $tax) { $tax = $r.taxonomies | Select-Object -First 1 }
                    $codes = @()
                    if ($tax) { $codes += [string]$tax.code }
                    foreach ($t in @($r.taxonomies)) { if ([string]$t.code -notin $codes) { $codes += [string]$t.code } }
                    $pool[$r.number] = [pscustomobject]@{
                        NPI        = $r.number
                        FirstName  = $r.basic.first_name
                        LastName   = $r.basic.last_name
                        Credential = $r.basic.credential
                        Taxonomy   = $tax.desc
                        TaxCodes   = ($codes -join "|")
                        LicenseNum = $tax.license
                        Address    = ("{0} {1}" -f $loc.address_1, $loc.address_2).Trim()
                        City       = $loc.city
                        State      = $loc.state
                        Zip        = $loc.postal_code
                        Phone      = $loc.telephone_number
                        Enumerated = $r.basic.enumeration_date
                    }
                }
                if ($skip -ge 1000 -and $count -eq 200) { Write-Warning "zip $zip for '$q' may have hit the result cap" }
                if ($count -lt 200 -or $skip -ge 1000) { break }
                $skip += 200
                Start-Sleep -Milliseconds 400
            }
        }
        Write-Host ("  '{0}' added {1} new (pool now {2})" -f $q, ($pool.Count - $before), $pool.Count)
    }

    # Sort every pooled provider into a profession by taxonomy code
    $buckets = @{ SLP = @(); OT = @(); OTA = @(); SA = @() }
    foreach ($p in $pool.Values) {
        $class = $null
        foreach ($c in ($p.TaxCodes -split "\|")) {
            if     ($c -like "235Z*")  { $class = "SLP"; break }
            elseif ($c -like "225X*")  { $class = "OT";  break }
            elseif ($c -like "224Z*")  { $class = "OTA"; break }
            elseif ($c -like "2355S*") { $class = "SA";  break }
        }
        if ($class) { $buckets[$class] += $p }
    }

    $outputs = @(
        @{ Key="SLP"; File="TN_Speech_Therapists.csv";       Label="Speech-Language Pathologists" },
        @{ Key="OT";  File="TN_Occupational_Therapists.csv"; Label="Occupational Therapists" },
        @{ Key="OTA"; File="TN_OT_Assistants.csv";           Label="OT Assistants" },
        @{ Key="SA";  File="TN_Speech_Assistants.csv";       Label="Speech-Language Assistants" }
    )
    foreach ($o in $outputs) {
        $dest = Join-Path $desktop $o.File
        $sorted = $buckets[$o.Key] | Sort-Object LastName, FirstName
        try { $sorted | Export-Csv -Path $dest -NoTypeInformation -Encoding UTF8 }
        catch {
            $alt = Join-Path $desktop ($o.File -replace "\.csv$", "_NEW.csv")
            Write-Warning "$($o.File) is open in another program - saving as $(Split-Path $alt -Leaf). Close Excel next time."
            $sorted | Export-Csv -Path $alt -NoTypeInformation -Encoding UTF8
            $dest = $alt
        }
        Write-Host (">>> {0} {1} saved to: {2}" -f @($buckets[$o.Key]).Count, $o.Label, $dest) -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "DONE. Four spreadsheets are on your Desktop." -ForegroundColor Green
    Write-Host "Upload all four to Claude WITHOUT opening them in Excel first."
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

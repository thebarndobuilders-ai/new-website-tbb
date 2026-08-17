@echo off
title Hopes and Dreams - TN Therapist List (v5 DEEP SCAN)
echo.
echo  Hopes and Dreams - TN Therapist List  (v5 DEEP SCAN by name)
echo  =============================================================
echo  This sweeps EVERY individual provider in Tennessee by name
echo  (A to Z, 2005 to today) and keeps the SLPs, OTs, OTAs, and
echo  SLP-Assistants by their official taxonomy codes.
echo.
echo  Takes 30-60 MINUTES. Start it and go do something else.
echo  A report is saved to RUN_ME_log.txt on your Desktop either way.
echo.
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
    $api  = "https://npiregistry.cms.hhs.gov/api/"
    $seen = @{}   # every NPI already processed
    $pool = @{}   # NPIs that match our professions
    $letters = [char[]]([char]'A'..[char]'Z')
    $extraChars = @("'", "-", " ")

    function Test-Match([string]$codes) {
        foreach ($c in ($codes -split "\|")) {
            if ($c -like "235Z*" -or $c -like "225X*" -or $c -like "224Z*" -or $c -like "2355S*") { return $true }
        }
        return $false
    }

    # Fetch one name bucket; returns $true if it hit the 1,200-result cap
    function Get-Bucket([string]$lnPrefix, [string]$fnPrefix) {
        $skip = 0
        $lastCount = 0
        while ($true) {
            $qs = "version=2.1&enumeration_type=NPI-1&state=TN&last_name=$([uri]::EscapeDataString($lnPrefix))*&limit=200&skip=$skip"
            if ($fnPrefix) { $qs += "&first_name=$([uri]::EscapeDataString($fnPrefix))*" }
            try   { $resp = Invoke-RestMethod -Uri ($api + "?" + $qs) -TimeoutSec 60 }
            catch { Start-Sleep 3; $resp = Invoke-RestMethod -Uri ($api + "?" + $qs) -TimeoutSec 60 }
            $count = 0
            if ($resp.results) { $count = @($resp.results).Count }
            $lastCount = $count
            if ($count -eq 0) { break }
            foreach ($r in $resp.results) {
                if ($script:seen.ContainsKey($r.number)) { continue }
                $script:seen[$r.number] = $true
                $codes = @()
                $tax = $r.taxonomies | Where-Object { $_.primary } | Select-Object -First 1
                if (-not $tax) { $tax = $r.taxonomies | Select-Object -First 1 }
                if ($tax) { $codes += [string]$tax.code }
                foreach ($t in @($r.taxonomies)) { if ([string]$t.code -notin $codes) { $codes += [string]$t.code } }
                $codeStr = $codes -join "|"
                if (-not (Test-Match $codeStr)) { continue }
                $loc = $r.addresses | Where-Object { $_.address_purpose -eq "LOCATION" } | Select-Object -First 1
                $script:pool[$r.number] = [pscustomobject]@{
                    NPI        = $r.number
                    FirstName  = $r.basic.first_name
                    LastName   = $r.basic.last_name
                    Credential = $r.basic.credential
                    Taxonomy   = $tax.desc
                    TaxCodes   = $codeStr
                    LicenseNum = $tax.license
                    Address    = ("{0} {1}" -f $loc.address_1, $loc.address_2).Trim()
                    City       = $loc.city
                    State      = $loc.state
                    Zip        = $loc.postal_code
                    Phone      = $loc.telephone_number
                    Enumerated = $r.basic.enumeration_date
                }
            }
            if ($skip -ge 1000) { break }
            if ($count -lt 200) { break }
            $skip += 200
            Start-Sleep -Milliseconds 250
        }
        return ($skip -ge 1000 -and $lastCount -eq 200)
    }

    # Work through name space: 2-letter prefixes, drilling deeper when a bucket caps
    $stack = New-Object System.Collections.Stack
    foreach ($a in $letters) {
        foreach ($b in ($letters + $extraChars)) { $stack.Push(@{ ln = "$a$b"; fn = $null }) }
    }
    $done = 0
    $total = $stack.Count
    while ($stack.Count -gt 0) {
        $item = $stack.Pop()
        $capped = Get-Bucket $item.ln $item.fn
        if ($capped) {
            if (-not $item.fn) {
                if ($item.ln.Length -lt 5) {
                    foreach ($c in ($letters + $extraChars)) { $stack.Push(@{ ln = "$($item.ln)$c"; fn = $null }) }
                } else {
                    foreach ($c in $letters) { $stack.Push(@{ ln = $item.ln; fn = "$c" }) }
                }
            } elseif ($item.fn.Length -lt 3) {
                foreach ($c in $letters) { $stack.Push(@{ ln = $item.ln; fn = "$($item.fn)$c" }) }
            } else {
                Write-Warning "Bucket $($item.ln)/$($item.fn) still capped - a handful of records there may be missed"
            }
        }
        $done++
        if ($item.ln.Length -eq 2 -and -not $item.fn) {
            Write-Host ("  {0}* scanned - {1} therapists found so far ({2} providers checked)" -f $item.ln, $pool.Count, $seen.Count)
        }
    }

    # Classify into the four professions
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
    Write-Host ("DONE. Checked {0} TN providers by name, kept {1} therapy professionals." -f $seen.Count, $pool.Count) -ForegroundColor Green
    Write-Host "Four spreadsheets are on your Desktop. Upload all four to Claude WITHOUT opening them in Excel."
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

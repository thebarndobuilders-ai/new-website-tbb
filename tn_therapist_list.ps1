# ══════════════════════════════════════════════════════════════════
#  TN Therapist List Builder — Hopes and Dreams
#  Pulls every Speech-Language Pathologist and Occupational Therapist
#  in Tennessee from the federal NPI registry (public CMS data) and
#  writes them to CSV files on your Desktop.
#
#  HOW TO RUN (Windows):
#    Right-click this file → "Run with PowerShell"
#    or from a PowerShell window:
#    powershell -ExecutionPolicy Bypass -File .\tn_therapist_list.ps1
#
#  Takes ~5-10 minutes (it pages through the registry politely).
#  Output: Desktop\TN_Speech_Therapists.csv, TN_Occupational_Therapists.csv
# ══════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"
$api = "https://npiregistry.cms.hhs.gov/api/"

# NPI taxonomy descriptions for the two professions
$professions = @(
    @{ Name = "Speech-Language Pathologist"; File = "TN_Speech_Therapists.csv" },
    @{ Name = "Occupational Therapist";      File = "TN_Occupational_Therapists.csv" }
)

# TN zip codes run 37000-38599. The API caps any one search at 1,200
# results, so we pull one 3-digit zip prefix at a time to stay under it.
$zipPrefixes = 370..385 | ForEach-Object { "$_*" }

foreach ($prof in $professions) {
    Write-Host ""
    Write-Host "══ Pulling: $($prof.Name) in TN ══" -ForegroundColor Cyan
    $seen = @{}   # dedupe by NPI (providers can appear under multiple zips)
    $out  = New-Object System.Collections.Generic.List[object]

    foreach ($zip in $zipPrefixes) {
        $skip = 0
        while ($true) {
            $params = @{
                version              = "2.1"
                enumeration_type     = "NPI-1"          # individual providers
                state                = "TN"
                postal_code          = $zip
                taxonomy_description = $prof.Name
                limit                = 200
                skip                 = $skip
            }
            $qs = ($params.GetEnumerator() | ForEach-Object {
                "$($_.Key)=$([uri]::EscapeDataString([string]$_.Value))"
            }) -join "&"

            try   { $resp = Invoke-RestMethod -Uri "$api`?$qs" -TimeoutSec 60 }
            catch { Write-Warning "Request failed for zip $zip (skip $skip): $_ — retrying once"; Start-Sleep 3
                    $resp = Invoke-RestMethod -Uri "$api`?$qs" -TimeoutSec 60 }

            $count = if ($resp.results) { $resp.results.Count } else { 0 }
            if ($count -eq 0) { break }

            foreach ($r in $resp.results) {
                if ($seen.ContainsKey($r.number)) { continue }
                $seen[$r.number] = $true
                $loc  = $r.addresses  | Where-Object { $_.address_purpose -eq "LOCATION" } | Select-Object -First 1
                $tax  = $r.taxonomies | Where-Object { $_.primary } | Select-Object -First 1
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
                    Status     = $r.basic.status
                })
            }

            if ($count -lt 200 -or $skip -ge 1000) { break }   # end of this bucket
            $skip += 200
            Start-Sleep -Milliseconds 400                       # be polite to the API
        }
        Write-Host ("  zip {0,-5} done — {1} unique so far" -f $zip, $seen.Count)
    }

    $dest = Join-Path ([Environment]::GetFolderPath("Desktop")) $prof.File
    $out | Sort-Object LastName, FirstName | Export-Csv -Path $dest -NoTypeInformation -Encoding UTF8
    Write-Host "✔ $($seen.Count) $($prof.Name)s written to $dest" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done. Both CSVs are on your Desktop — open them in Excel." -ForegroundColor Green
Write-Host "Note: this is the federal NPI registry (providers who bill insurance),"
Write-Host "with practice addresses and phones. For the authoritative state license"
Write-Host "roster (status/expiration), use the TN Dept of Health licensure site."
Read-Host "Press Enter to close"

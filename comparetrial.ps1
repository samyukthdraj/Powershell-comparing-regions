# Correct paths for the files
$jsonPath = "C:\Users\SamyukthDharmarajan\Downloads\Powershell\task1\regions.json"
$yamlPath = "C:\Users\SamyukthDharmarajan\Downloads\Powershell\task1\yamlscript.yml"

# Read and parse the JSON file
$jsonData = Get-Content -Path $jsonPath | ConvertFrom-Json

# Error handling: Check if $jsonData is empty
if (-not $jsonData) {
    Write-Host "Error: JSON data is empty. Check file path or contents."
    exit  # Exit the script if JSON data is empty
}

# Initialize an empty array for jsonRegions
$jsonRegions = @()

# Iterate through the JSON objects and add the region names to the array
foreach ($obj in $jsonData) {
    if ($obj.subscriptions -and $obj.subscriptions -is [array]) {
        foreach ($subscription in $obj.subscriptions) {
            if ($subscription.region) {
                $jsonRegions += $subscription.region
            }
        }
    }
}

# Read the YAML file as text
$yamlContent = Get-Content -Path $yamlPath -Raw

# Split the content into lines
$yamlLines = $yamlContent -split "`n"

# Initialize arrays for different region categories
$yamlFFRegions = @()
$yamlMCRegions = @()
$yamlPPERegions = @()

$inBatchesSection = $false

foreach ($line in $yamlLines) {
    if ($line -match "^\s*- name: batches") {
        $inBatchesSection = $true
        continue
    }

    if ($inBatchesSection -and $line -match "^\s*(FF|MC|PPE)_(.*)") {
        $regionPrefix = $matches[1]
        $regionName = ($matches[2] -split ':')[0].Trim()

        # Categorize regions based on prefix
        switch ($regionPrefix) {
            "FF" { $yamlFFRegions += $regionName }
            "MC" { $yamlMCRegions += $regionName }
            "PPE" { $yamlPPERegions += $regionName }
        }
    }

    if ($inBatchesSection -and $line.Trim() -eq "stages:") {
        $inBatchesSection = $false
    }
}

# Remove duplicates and sort regions
$jsonRegions = $jsonRegions | Sort-Object -Unique
$yamlFFRegions = $yamlFFRegions | Sort-Object -Unique
$yamlMCRegions = $yamlMCRegions | Sort-Object -Unique
$yamlPPERegions = $yamlPPERegions | Sort-Object -Unique

# Perform comparison between Prod regions in YAML and JSON
$commonRegions = $jsonRegions | Where-Object { $yamlProdRegions -contains $_ }
$jsonOnlyRegions = $jsonRegions | Where-Object { -not ($yamlProdRegions -contains $_) }

# Output the results
Write-Host "Regions in both JSON and YAML (Prod regions only):"
$commonRegions | ForEach-Object { Write-Host $_ }

Write-Host "`nRegions only in JSON file:"
$jsonOnlyRegions | ForEach-Object { Write-Host $_ }

Write-Host "`nRegions in FF:"
$yamlFFRegions | ForEach-Object { Write-Host $_ }

Write-Host "`nRegions in MC:"
$yamlMCRegions | ForEach-Object { Write-Host $_ }

Write-Host "`nRegions in PPE:"
$yamlPPERegions | ForEach-Object { Write-Host $_ }

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

# Manually extract regions (FF, MC, PPE & Prod)
$yamlProdRegions = @()
$yamlSpecialRegions = @()
$inBatchesSection = $false

foreach ($line in $yamlLines) {
    if ($line -match "^\s*- name: batches") {
        $inBatchesSection = $true
        continue
    }

    if ($inBatchesSection -and $line -match "^\s*(Prod|FF|MC|PPE)_(.*)") {
        $regionPrefix = $matches[1]
        $regionName = ($matches[2] -split ':')[0].Trim()

        # Separate Prod regions for comparison and others for special display
        if ($regionPrefix -eq "Prod") {
            $yamlProdRegions += $regionName
        } else {
            $yamlSpecialRegions += "$regionPrefix_$regionName"
        }
    }

    if ($inBatchesSection -and $line.Trim() -eq "stages:") {
        $inBatchesSection = $false
    }
}

# Remove duplicates and sort regions
$jsonRegions = $jsonRegions | Sort-Object -Unique
$yamlProdRegions = $yamlProdRegions | Sort-Object -Unique
$yamlSpecialRegions = $yamlSpecialRegions | Sort-Object -Unique

# Perform comparison between Prod regions in YAML and JSON
$commonRegions = $jsonRegions | Where-Object { $yamlProdRegions -contains $_ }
$jsonOnlyRegions = $jsonRegions | Where-Object { -not ($yamlProdRegions -contains $_) }
$yamlOnlyProdRegions = $yamlProdRegions | Where-Object { -not ($jsonRegions -contains $_) }

# Output the results
Write-Host "Regions in both JSON and YAML (Prod regions only):"
$commonRegions | ForEach-Object { Write-Host $_ }

Write-Host "`nRegions only in JSON file:"
$jsonOnlyRegions | ForEach-Object { Write-Host $_ }

Write-Host "`nRegions only in YAML file (FF, MC, PPE):"
$yamlSpecialRegions | ForEach-Object { Write-Host $_ }

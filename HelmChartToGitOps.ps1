# -----------------------------------------------
# CONFIGURATION — EDIT ONLY IF YOUR PATHS CHANGE
# -----------------------------------------------

# Path to your django-app Helm chart (source)
$SourceChartPath = "C:\Python\projects\django-app\helm\django-app"

# Path to your GitOps repo (destination)
$GitOpsRepo = "C:\Python\projects\django-gitops"

# Destination chart path inside GitOps repo
$DestChartPath = Join-Path $GitOpsRepo "apps\django-app"

# Source templates folder
$SourceTemplates = Join-Path $SourceChartPath "templates"

# Destination templates folder
$DestTemplates = Join-Path $DestChartPath "templates"

Write-Host "Source chart: $SourceChartPath"
Write-Host "Destination chart: $DestChartPath"
Write-Host ""

# -----------------------------------------------
# STEP 1 — Ensure destination directory exists
# -----------------------------------------------
if (!(Test-Path $DestChartPath)) {
    Write-Host "Creating destination chart directory..."
    New-Item -ItemType Directory -Path $DestChartPath -Force | Out-Null
}

# -----------------------------------------------
# STEP 2 — Remove old chart files
# -----------------------------------------------
Write-Host "Removing old chart files..."
Get-ChildItem -Path $DestChartPath -Recurse -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Recreate templates folder
New-Item -ItemType Directory -Path $DestTemplates -Force | Out-Null

# -----------------------------------------------
# STEP 3 — Copy new chart files
# -----------------------------------------------
Write-Host "Copying Chart.yaml and values.yaml..."
Copy-Item -Path (Join-Path $SourceChartPath "Chart.yaml") -Destination $DestChartPath -Force
Copy-Item -Path (Join-Path $SourceChartPath "values.yaml") -Destination $DestChartPath -Force

Write-Host "Copying templates..."
Copy-Item -Path "$SourceTemplates\*" -Destination $DestTemplates -Recurse -Force

# -----------------------------------------------
# DONE
# -----------------------------------------------
Write-Host ""
Write-Host "✔ Helm chart successfully copied into GitOps repo."
Write-Host "✔ Commit and push your GitOps repo to trigger Argo CD sync."
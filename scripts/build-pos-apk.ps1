param(
    [ValidateSet('production', 'staging', 'development')]
    [string]$Flavor = 'production',
    [string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
$posProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$posWorkspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $posProjectRoot '..'))
if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $posWorkspaceRoot 'output/pos-apk-latest'
}
function Test-POSCompiledCatalog([string]$ApkPath, [string[]]$ExpectedLabels) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $posZip = [System.IO.Compression.ZipFile]::OpenRead($ApkPath)
    try {
        $posNativeEntries = @($posZip.Entries | Where-Object { $_.FullName -match '^lib/[^/]+/libapp\.so$' })
        if ($posNativeEntries.Count -eq 0) { return $false }
        foreach ($posEntry in $posNativeEntries) {
            $posStream = $posEntry.Open()
            $posMemory = [System.IO.MemoryStream]::new()
            try {
                $posStream.CopyTo($posMemory)
                $posNativeText = [System.Text.Encoding]::ASCII.GetString($posMemory.ToArray())
                foreach ($posLabel in $ExpectedLabels) {
                    if (-not $posNativeText.Contains($posLabel)) { return $false }
                }
            } finally { $posMemory.Dispose(); $posStream.Dispose() }
        }
        return $true
    } finally { $posZip.Dispose() }
}
function Build-POSRelease {
    & flutter build apk --release --flavor $Flavor --target "lib/main_$Flavor.dart"
    if ($LASTEXITCODE -ne 0) { throw 'Build APK POS gagal.' }
}
Push-Location $posProjectRoot
try {
    $posFallback = Get-Content -LiteralPath (Join-Path $posProjectRoot 'lib/domain/models/pos_profile_catalog.dart') -Raw
    $posLabelsBlock = [regex]::Match($posFallback, '(?s)const posProfileLabels = <String, String>(\{.*?\});').Groups[1].Value
    if (-not $posLabelsBlock) { throw 'Fallback profil POS tidak valid.' }
    $posExpectedLabels = @((ConvertFrom-Json $posLabelsBlock).PSObject.Properties.Value) + @('GetPOSProfileCatalog')
    Build-POSRelease
    $posApk = Join-Path $posProjectRoot "build/app/outputs/flutter-apk/app-$Flavor-release.apk"
    if (-not (Test-Path -LiteralPath $posApk)) { throw "APK tidak ditemukan: $posApk" }
    if (-not (Test-POSCompiledCatalog $posApk $posExpectedLabels)) {
        throw 'Katalog profil tidak ditemukan dalam seluruh library APK. APK tidak akan dibagikan.'
    }
    $posVersionLine = Get-Content -LiteralPath (Join-Path $posProjectRoot 'pubspec.yaml') | Where-Object { $_ -match '^version:\s*' } | Select-Object -First 1
    $posVersion = ($posVersionLine -replace '^version:\s*', '').Trim()
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $posDestination = Join-Path $OutputDirectory "Pantoo-POS-$Flavor-$posVersion.apk"
    Copy-Item -LiteralPath $posApk -Destination $posDestination -Force
    $posHash = Get-FileHash -LiteralPath $posDestination -Algorithm SHA256
    $posMetadata = [ordered]@{
        version = $posVersion
        flavor = $Flavor
        package_id = if ($Flavor -eq 'production') { 'id.pantoo.pos' } elseif ($Flavor -eq 'staging') { 'id.pantoo.pos.stg' } else { 'id.pantoo.pos.dev' }
        apk = $posDestination
        bytes = (Get-Item -LiteralPath $posDestination).Length
        sha256 = $posHash.Hash
        profile_source = 'GetPOSProfileCatalog'
        catalog_mode = 'runtime_backend_with_offline_fallback'
        compiled_profile_labels_verified = $posExpectedLabels
        built_at = (Get-Date).ToString('o')
    }
    $posMetadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutputDirectory 'build.json') -Encoding UTF8
    Write-Output $posDestination
    Write-Output "SHA256: $($posHash.Hash)"
} finally {
    Pop-Location
}

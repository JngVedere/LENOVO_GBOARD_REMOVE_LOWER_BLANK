# Dev only: builds the RRO overlays in apk\ into prebuilt\, signed with the AOSP platform
# test key in keys\ (only ROMs signed with that key accept them).
#   apk\<module>\<variant>\      -> prebuilt\patch_<module>_<variant>.apk
#   apk\ime_gap\ (template)      -> prebuilt\patch_ime_gap_<dp>.apk for every dp in $GapRange
#   then packs the GUI + prebuilt\ into "Lenovo Gboard Blank Patcher.exe" (launcher.cs)
# Needs: JDK + %LOCALAPPDATA%\Android\Sdk build-tools 37 / platform 37.
# Only scripts changed? `.\build.ps1 -GapRange @()` skips the 121 ime_gap APKs.
param([int[]]$GapRange = 0..120)
$ErrorActionPreference = 'Stop'
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$bt = "$sdk\build-tools\android-37.0"
$jar = "$sdk\platforms\android-37.0\android.jar"
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    $env:Path = (Get-ChildItem "$env:ProgramFiles\Microsoft\jdk-*\bin" | Select-Object -First 1).FullName + ";$env:Path"
}
$prebuilt = "$PSScriptRoot\prebuilt"
New-Item -ItemType Directory -Force $prebuilt | Out-Null

function Build($name, $src, $dp) {
    # aapt2 can't open non-ASCII paths, so build in TEMP
    $out = "$env:TEMP\gboardblank\$name"
    Remove-Item $out -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item $src $out -Recurse
    if ($null -ne $dp) {
        Get-ChildItem $out -Recurse -File | ForEach-Object { (Get-Content $_.FullName -Raw).Replace('__DP__', "$dp") | Set-Content $_.FullName -NoNewline }
    }
    & "$bt\aapt2" compile --dir "$out\res" -o "$out\flat.zip"
    # --no-resource-deduping: keep per-config copies, else the target's qualified value wins
    & "$bt\aapt2" link --no-resource-deduping --manifest "$out\AndroidManifest.xml" -I $jar -o "$out\unsigned.apk" "$out\flat.zip"
    & "$bt\zipalign" -f -p 4 "$out\unsigned.apk" "$out\aligned.apk"
    & "$bt\apksigner.bat" sign --v4-signing-enabled false --key "$PSScriptRoot\keys\platform.pk8" --cert "$PSScriptRoot\keys\platform.x509.pem" --out "$prebuilt\patch_$name.apk" "$out\aligned.apk"
    if ($LASTEXITCODE) { throw "build failed: $name" }
    Write-Host "built patch_$name.apk"
}

foreach ($m in Get-ChildItem "$PSScriptRoot\apk" -Directory) {
    if (Test-Path "$($m.FullName)\AndroidManifest.xml") {
        foreach ($dp in $GapRange) { Build "$($m.Name)_$dp" $m.FullName $dp }
    } else {
        foreach ($v in Get-ChildItem $m.FullName -Directory) { Build "$($m.Name)_$($v.Name)" $v.FullName $null }
    }
}

# Single-file exe: everything the GUI needs, zipped into launcher.cs (built-in .NET Framework csc)
$zip = "$env:TEMP\gboardblank\app.zip"
Compress-Archive -Force $zip -Path (@('gui.ps1', 'patch.cmd', 'overlay.sh', 'modules', 'prebuilt') | ForEach-Object { "$PSScriptRoot\$_" })
$net = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319"
& "$net\csc.exe" /nologo /target:winexe "/out:$PSScriptRoot\Lenovo Gboard Blank Patcher.exe" "/resource:$zip,app.zip" `
    "/r:$net\System.IO.Compression.dll" "/r:$net\System.IO.Compression.FileSystem.dll" "$PSScriptRoot\launcher.cs"
if ($LASTEXITCODE) { throw 'exe build failed' }
Write-Host 'built Lenovo Gboard Blank Patcher.exe'

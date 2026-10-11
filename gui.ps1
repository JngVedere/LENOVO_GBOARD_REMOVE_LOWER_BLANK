# Lenovo Gboard Blank Patcher - minimal GUI. Started by "Lenovo Gboard Blank Patcher.exe" (launcher.cs).
# Each selected option runs: patch.cmd <module> <action>
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$tools = Join-Path $env:LOCALAPPDATA 'gboardblank'
$env:Path = "$tools\platform-tools;$env:Path"
# Signature.hashCode() of the AOSP platform test certificate, as printed by dumpsys
$aospTestKey = 'b4addb29'

# First option of every module is "keep" (no change). 'custom' = the dp box below.
$modules = @(
    @{ Name = 'ime_gap';    Title = 'Keyboard bottom row height';      Options = [ordered]@{ keep = 'No change'; '32' = '32dp (minimum)'; default = 'Default'; '84' = '1.5x (84dp)'; custom = 'Custom:' } }
    @{ Name = 'ime_globe';  Title = 'Globe (language switch) icon';    Options = [ordered]@{ keep = 'No change'; hide = 'Hide'; default = 'Show' } }
    @{ Name = 'ime_back';   Title = 'Collapse-keyboard arrow icon';    Options = [ordered]@{ keep = 'No change'; hide = 'Hide'; default = 'Show' } }
    @{ Name = 'animations'; Title = 'Animation speed (system-wide)';   Options = [ordered]@{ keep = 'No change'; apply = '0.5x (faster)'; revert = 'Default' } }
)

$form = New-Object Windows.Forms.Form -Property @{ Text = 'Lenovo Gboard Blank Patcher'; AutoSize = $true; AutoSizeMode = 'GrowAndShrink'; Padding = 10; Font = New-Object Drawing.Font('Segoe UI', 10) }
$panel = New-Object Windows.Forms.FlowLayoutPanel -Property @{ FlowDirection = 'TopDown'; AutoSize = $true; WrapContents = $false }
$form.Controls.Add($panel)

# One title line + one radio line per module (separate panels keep the radio groups apart)
foreach ($m in $modules) {
    $panel.Controls.Add((New-Object Windows.Forms.Label -Property @{ Text = $m.Title; AutoSize = $true; Margin = '3,10,3,0'; Font = New-Object Drawing.Font('Segoe UI', 10, [Drawing.FontStyle]::Bold) }))
    $row = New-Object Windows.Forms.FlowLayoutPanel -Property @{ AutoSize = $true; WrapContents = $false }
    foreach ($o in $m.Options.GetEnumerator()) {
        $row.Controls.Add((New-Object Windows.Forms.RadioButton -Property @{ Text = $o.Value; Tag = $o.Key; AutoSize = $true; Checked = ($o.Key -eq 'keep') }))
    }
    $m.Row = $row
    $panel.Controls.Add($row)
    if ($m.Name -eq 'ime_gap') {
        $dpBox = New-Object Windows.Forms.NumericUpDown -Property @{ Minimum = 0; Maximum = 120; Value = 32; Width = 60 }
        $row.Controls.AddRange(@($dpBox, (New-Object Windows.Forms.Label -Property @{ Text = 'dp (0-120)'; AutoSize = $true; Margin = '3,6,3,0' })))
        $panel.Controls.Add((New-Object Windows.Forms.Label -Property @{ AutoSize = $true; MaximumSize = '470,0'; ForeColor = 'DarkRed'; Text =
            "Warning: below 32dp the collapse/globe buttons get clipped and may stop working, " +
            "and on tablets with a taskbar the keyboard won't move any lower anyway. 0dp removes the row. " +
            "Large values push the keyboard up and cover more of the screen. Requires Android 17+." }))
    }
}

$button = New-Object Windows.Forms.Button -Property @{ Text = 'Apply to tablet (USB)'; AutoSize = $true }
$log = New-Object Windows.Forms.TextBox -Property @{ Multiline = $true; ReadOnly = $true; ScrollBars = 'Vertical'; Width = 470; Height = 180 }
$panel.Controls.AddRange(@($button, $log))

function Log($text) { $log.AppendText("$text`r`n"); [Windows.Forms.Application]::DoEvents() }

function Install-Adb {
    if (Get-Command adb -ErrorAction SilentlyContinue) { return $true }
    Log 'adb not found, downloading Google platform-tools...'
    try {
        [Net.ServicePointManager]::SecurityProtocol = 'Tls12'
        $zip = Join-Path $env:TEMP 'platform-tools.zip'
        Invoke-WebRequest 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile $zip -UseBasicParsing
        Expand-Archive $zip $tools -Force
        Remove-Item $zip
        Log "adb installed: $tools\platform-tools"
        return $true
    } catch { Log "adb install failed: $_"; return $false }
}

$button.Add_Click({
    $button.Enabled = $false
    try {
        if (-not (Install-Adb)) { return }
        adb start-server 2>&1 | Out-Null
        $state = (adb get-state 2>&1) -join ' '
        if ($state -match 'unauthorized') { Log 'Tap "Allow" on the "Allow USB debugging?" prompt on the tablet, then try again.'; return }
        if ($state -ne 'device') { Log 'No tablet found. Check the USB cable and Developer options > USB debugging.'; return }
        if ((adb shell "dumpsys package android | grep -m1 signatures:" 2>$null) -notmatch "\[$aospTestKey\]") {
            Log 'Unsupported ROM: it is not signed with the AOSP test key, so these overlays cannot be installed.'; return
        }

        $n = 0
        foreach ($m in $modules) {
            $action = ($m.Row.Controls | Where-Object { $_ -is [Windows.Forms.RadioButton] -and $_.Checked }).Tag
            if ($action -eq 'custom') { $action = [string][int]$dpBox.Value }
            if ($action -eq 'keep') { continue }
            Log "> $($m.Name) $action"
            Log ((& "$PSScriptRoot\patch.cmd" $m.Name $action 2>&1) -join "`r`n")
            $n++
        }
        Log $(if ($n) { 'Done.' } else { 'Nothing selected.' })
    } finally { $button.Enabled = $true }
})

[void]$form.ShowDialog()

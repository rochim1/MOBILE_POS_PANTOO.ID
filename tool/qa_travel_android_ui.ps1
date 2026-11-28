param(
  [ValidateSet('Snapshot','Tap','Fill','Back')][string]$Action='Snapshot',
  [string]$Label='', [int]$FieldIndex=-1, [string]$Value='',
  [string]$Name='current',
  [string]$OutputDirectory='D:/my node app/zera/output/pos-travel-android-20261128'
)
$ErrorActionPreference='Stop'
$qaAdb='C:/Users/LENOVO/AppData/Local/Android/Sdk/platform-tools/adb.exe'
$qaSerial='emulator-5556'
$qaOut=[IO.Path]::GetFullPath($OutputDirectory)
if (!$qaOut.StartsWith('D:\my node app\zera\output\',[StringComparison]::OrdinalIgnoreCase)) { throw 'QA artifacts must stay within workspace output' }
$qaPackage='id.pantoo.pos.qa.travel'
if ($Name -notmatch '^[a-zA-Z0-9-]+$') { throw 'Invalid artifact name' }
if (!(Test-Path -LiteralPath (Join-Path $qaOut 'fixture.json'))) { throw 'Isolated Travel QA fixture is required' }
$qaForeground=(& $qaAdb -s $qaSerial shell dumpsys activity activities | Select-String 'mResumedActivity|topResumedActivity') -join ' '
if ($qaForeground -notmatch 'id\.pantoo\.pos\.qa\.travel/') { throw 'Travel QA is not foreground; no action sent' }
if ($Action -eq 'Back') { & $qaAdb -s $qaSerial shell input keyevent 4; exit $LASTEXITCODE }
$qaRemoteXml='/sdcard/travel-qa-ui-'+[guid]::NewGuid().ToString('N')+'.xml'
$qaDump=(& $qaAdb -s $qaSerial shell uiautomator dump $qaRemoteXml 2>&1) -join ' '
if ($LASTEXITCODE -ne 0 -or $qaDump -notmatch 'dumped to:') { throw 'Fresh native UI dump failed; old hierarchy will not be reused' }
$qaRaw=(& $qaAdb -s $qaSerial shell cat $qaRemoteXml) -join ''
[xml]$qaXml=$qaRaw
$qaNodes=@($qaXml.SelectNodes('//node'))
if ($Action -eq 'Snapshot') {
  & $qaAdb -s $qaSerial pull $qaRemoteXml (Join-Path $qaOut "$Name.xml") | Out-Null
  & $qaAdb -s $qaSerial shell screencap -p /sdcard/travel-qa-screen.png
  & $qaAdb -s $qaSerial pull /sdcard/travel-qa-screen.png (Join-Path $qaOut "$Name.png") | Out-Null
  $qaNodes | Where-Object { $_.'content-desc' -or $_.text -or $_.class -eq 'android.widget.EditText' } | ForEach-Object {
    [pscustomobject]@{class=$_.class;desc=$_.'content-desc';text=$_.text;hint=$_.hint;bounds=$_.bounds;enabled=$_.enabled;focused=$_.focused}
  } | ConvertTo-Json -Compress
  exit 0
}
$qaEligible=@($qaNodes | Where-Object { $_.package -eq $qaPackage -and $_.enabled -eq 'true' })
if ($Action -eq 'Fill') {
  if ($Value -notmatch '^[A-Za-z0-9 @._!%+\-]*$') { throw 'Only plain synthetic QA input is supported' }
  $qaFields=@($qaEligible | Where-Object { $_.class -eq 'android.widget.EditText' })
  if ($FieldIndex -lt 0 -or $FieldIndex -ge $qaFields.Count) { throw 'Editable field index not found in the observed native UI' }
  $qaTarget=$qaFields[$FieldIndex]
} else {
  if (!$Label) { throw 'Observed control label is required' }
  $qaMatches=@($qaEligible | Where-Object { $_.'content-desc' -match $Label -or ($_.text -and $_.text -match $Label) })
  if ($qaMatches.Count -ne 1) { throw "Expected exactly one native control; found $($qaMatches.Count). No tap sent." }
  $qaTarget=$qaMatches[0]
}
$qaBounds=[regex]::Match($qaTarget.bounds,'^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$')
if (!$qaBounds.Success) { throw 'Native control bounds are invalid' }
$qaX=[int](([int]$qaBounds.Groups[1].Value+[int]$qaBounds.Groups[3].Value)/2)
$qaY=[int](([int]$qaBounds.Groups[2].Value+[int]$qaBounds.Groups[4].Value)/2)
& $qaAdb -s $qaSerial shell input tap $qaX $qaY
if ($LASTEXITCODE -ne 0) { throw 'Native tap failed' }
if ($Action -eq 'Fill') {
  & $qaAdb -s $qaSerial shell input keyevent 123
  $qaDelete=@('shell','input','keyevent')+(@('67')*[Math]::Min(256,$qaTarget.text.Length+8))
  & $qaAdb -s $qaSerial @qaDelete
  if ($Value) { & $qaAdb -s $qaSerial shell input text ($Value.Replace(' ','%s')) }
  if ($LASTEXITCODE -ne 0) { throw 'Native text input failed' }
}
[pscustomobject]@{action=$Action;label=$qaTarget.'content-desc';bounds=$qaTarget.bounds;valueLength=$Value.Length} | ConvertTo-Json -Compress

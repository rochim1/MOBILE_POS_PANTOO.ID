param([string]$Tap, [string]$FieldHint, [int]$FieldIndex = -1, [string]$Text, [switch]$Clear, [switch]$Dump,
  [ValidateSet('id.pantoo.pos.qa','id.pantoo.pos.qa.peer')][string]$PackageName='id.pantoo.pos.qa')
$ErrorActionPreference = 'Stop'
if ($Dump -and ($Tap -or $FieldHint -or $FieldIndex -ge 0)) {
  throw 'Use -Dump separately after an action; combining them would skip the action.'
}
$qaAdb = 'C:\Users\LENOVO\AppData\Local\Android\Sdk\platform-tools\adb.exe'
$qaDeviceState = & $qaAdb get-state 2>&1
if ($LASTEXITCODE -ne 0 -or ($qaDeviceState -join ' ').Trim() -ne 'device') {
  throw 'QA emulator is disconnected; no UI action was sent.'
}
for ($attempt = 0; $attempt -lt 5; $attempt++) {
  $qaDumpResult = & $qaAdb shell uiautomator dump /sdcard/pos-qa-ui.xml 2>&1
  if ($LASTEXITCODE -ne 0 -or ($qaDumpResult -join ' ') -notmatch 'dumped to:') {
    Start-Sleep -Milliseconds 400
    continue
  }
  [xml]$qaUi = & $qaAdb shell cat /sdcard/pos-qa-ui.xml
  $qaNodes = @($qaUi.SelectNodes('//node'))
  if ($Dump) {
    $qaNodes | Where-Object { $_.'content-desc' -or $_.class -eq 'android.widget.EditText' } |
      ForEach-Object { '{0} | {1} | {2} | {3}' -f $_.'content-desc',$_.text,$_.hint,$_.bounds }
    exit 0
  }
  $qaTarget = if ($FieldIndex -ge 0) {
    $qaFields = @($qaNodes | Where-Object { $_.class -eq 'android.widget.EditText' -and $_.enabled -eq 'true' })
    if ($FieldIndex -ge $qaFields.Count) { throw 'QA field index is outside the observed UI' }
    $qaFields[$FieldIndex]
  } else { $qaNodes | Where-Object {
    $_.enabled -eq 'true' -and $(if ($FieldHint) {
      $_.class -eq 'android.widget.EditText' -and $_.hint -eq $FieldHint
    } else { $_.'content-desc' -eq $Tap })
  } | Select-Object -First 1 }
  if ($qaTarget) {
    if ($qaTarget.package -ne $PackageName) { throw 'Refusing another application UI' }
    $qaBounds = [regex]::Matches($qaTarget.bounds, '\d+') | ForEach-Object { [int]$_.Value }
    $qaX = [int](($qaBounds[0] + $qaBounds[2]) / 2)
    $qaY = [int](($qaBounds[1] + $qaBounds[3]) / 2)
    & $qaAdb shell input -d 0 tap $qaX $qaY
    if ($LASTEXITCODE -ne 0) { throw 'QA tap failed; emulator may be disconnected.' }
    if ($FieldHint -or $FieldIndex -ge 0) {
      if ($Clear) {
        & $qaAdb shell input -d 0 keyevent 123
        $qaDeleteKeys = @('shell','input','-d','0','keyevent') + (@('67') * [Math]::Min(512, $qaTarget.text.Length + 8))
        & $qaAdb @qaDeleteKeys
        if ($LASTEXITCODE -ne 0) { throw 'QA input clear failed.' }
      }
      # adb rebuilds a remote shell command; input text accepts %s for spaces.
      $qaEncodedText = $Text.Replace(' ', '%s')
      & $qaAdb shell input -d 0 text $qaEncodedText
      if ($LASTEXITCODE -ne 0) { throw 'QA text entry failed.' }
    }
    "Tapped QA control: $Tap"
    exit 0
  }
  Start-Sleep -Milliseconds 400
}
throw "QA control not found: $Tap"

param([ValidateSet('Tap','Fill','Snapshot')][string]$Action='Snapshot',[string]$Label='',[int]$FieldIndex=0,[string]$Value='')
$ErrorActionPreference='Stop'
$qaAdb='C:\Users\LENOVO\AppData\Local\Android\Sdk\platform-tools\adb.exe'
$qaSerial='emulator-5556'
$qaRoot='D:\my node app\zera\output\pos-continuation-gui-20261123'
if(!(Test-Path -LiteralPath $qaRoot)){throw 'Prepare the local QA fixture before using this helper'}
$qaActivity=(& $qaAdb -s $qaSerial shell dumpsys activity activities | Select-String 'mResumedActivity|topResumedActivity') -join ' '
if($qaActivity -notmatch 'id\.pantoo\.pos\.qa\.service/'){throw 'The separate Pantoo QA package is not foreground; no UI action performed'}
function Read-QaNodes {
  & $qaAdb -s $qaSerial shell uiautomator dump /sdcard/pantoo-followup.xml | Out-Null
  & $qaAdb -s $qaSerial pull /sdcard/pantoo-followup.xml (Join-Path $qaRoot 'android-ui.xml') | Out-Null
  [xml]$qaXml=Get-Content -LiteralPath (Join-Path $qaRoot 'android-ui.xml')
  return $qaXml.SelectNodes('//node')
}
function Get-QaCenter($node){
  $qaMatch=[regex]::Match($node.bounds,'^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$')
  if(!$qaMatch.Success){throw 'Invalid observed UI bounds'}
  $qaX=[int](([int]$qaMatch.Groups[1].Value+[int]$qaMatch.Groups[3].Value)/2)
  $qaY=[int](([int]$qaMatch.Groups[2].Value+[int]$qaMatch.Groups[4].Value)/2)
  return @($qaX,$qaY)
}
$qaNodes=Read-QaNodes
switch($Action){
  Snapshot {
    $qaNodes | Where-Object {$_.'content-desc' -or $_.class -eq 'android.widget.EditText'} | ForEach-Object {[pscustomobject]@{class=$_.class;desc=$_.'content-desc';bounds=$_.bounds}} | ConvertTo-Json -Compress
  }
  Tap {
    $qaMatches=@($qaNodes | Where-Object {$_.'content-desc' -match $Label})
    if($qaMatches.Count -ne 1){throw "Expected one observed UI match, found $($qaMatches.Count). No tap performed."}
    $qaCenter=Get-QaCenter $qaMatches[0]
    & $qaAdb -s $qaSerial shell input tap $qaCenter[0] $qaCenter[1]
    Start-Sleep -Milliseconds 500
    [pscustomobject]@{action='tap';label=$qaMatches[0].'content-desc';bounds=$qaMatches[0].bounds} | ConvertTo-Json -Compress
  }
  Fill {
    if($Value -notmatch '^[A-Za-z0-9 @._!%+\-]*$'){throw 'Only plain QA input is supported; no shell text executed'}
    $qaFields=@($qaNodes | Where-Object {$_.class -eq 'android.widget.EditText'})
    if($FieldIndex -lt 0 -or $FieldIndex -ge $qaFields.Count){throw 'Observed editable field index unavailable'}
    $qaCenter=Get-QaCenter $qaFields[$FieldIndex]
    & $qaAdb -s $qaSerial shell input tap $qaCenter[0] $qaCenter[1]
    & $qaAdb -s $qaSerial shell input keyevent 123 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67
    if($Value){& $qaAdb -s $qaSerial shell input text ($Value.Replace(' ','%s'))}
    & $qaAdb -s $qaSerial shell input keyevent 4
    Start-Sleep -Milliseconds 500
    [pscustomobject]@{action='fill';field=$FieldIndex;valueLength=$Value.Length} | ConvertTo-Json -Compress
  }
}

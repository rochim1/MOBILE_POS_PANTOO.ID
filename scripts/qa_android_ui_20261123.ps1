param([ValidateSet('snapshot','tap','swipe','key','text','screen')][string]$Action='snapshot',[string[]]$Values=@())
$ErrorActionPreference='Stop'
$qaAdb='C:\Users\LENOVO\AppData\Local\Android\Sdk\platform-tools\adb.exe'
$qaOut='D:\my node app\zera\output\production-audit-20261123'
switch($Action){
  tap { & $qaAdb -s emulator-5556 shell input tap @Values; Start-Sleep -Milliseconds 350 }
  swipe { & $qaAdb -s emulator-5556 shell input swipe @Values }
  key { & $qaAdb -s emulator-5556 shell input keyevent @Values }
  text { & $qaAdb -s emulator-5556 shell input text @Values }
  screen { & $qaAdb -s emulator-5556 shell screencap -p /sdcard/pantoo-urgent.png; & $qaAdb -s emulator-5556 pull /sdcard/pantoo-urgent.png (Join-Path $qaOut $Values[0]) }
  snapshot {
    & $qaAdb -s emulator-5556 shell uiautomator dump /sdcard/pantoo-urgent.xml | Out-Null
    & $qaAdb -s emulator-5556 pull /sdcard/pantoo-urgent.xml (Join-Path $qaOut 'android-ui.xml') | Out-Null
    [xml]$qaUi=Get-Content (Join-Path $qaOut 'android-ui.xml')
    $qaUi.SelectNodes('//node') | Where-Object { $_.'content-desc' -or $_.class -like '*EditText' } | ForEach-Object { [pscustomobject]@{class=$_.class;desc=$_.'content-desc';bounds=$_.bounds} } | ConvertTo-Json -Compress
  }
}

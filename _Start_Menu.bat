::&cls&::   Сделал westlife -- ru-board.com --
@Echo off
chcp 65001 >nul
cd /d "%~dp0"

:: Проверка: запущен ли скрипт. Дубликат скрипта не должен запускаться, так как одинаковый локальный сервер может быть создан только в одном экземпляре в одно время. 
2>nul tasklist /v /fi "ImageName eq powershell.exe" /fo csv /nh | findstr /i "AutoFixFiles" >nul 2>&1
if "%Errorlevel%"=="0" (echo,&echo, Script "AutoFixFiles" already [running]&echo,&echo,Press any key to exit . . .& TIMEOUT /T 3 >nul & exit /b 0)

:: Включение "lagacy console mode" перед запуском скрипта, если запуск без админ прав, чтобы отключить запуск UWP Terminal вместо консоли PS
:: с возвратом обратно внутри скрипта, если было включение. (По умолчанию без админ прав на W11 запускается UWP Terminal).
reg query "HKU\S-1-5-19\Environment" >nul 2>&1 & cls
if "%Errorlevel%" NEQ "0" for /f "skip=2 tokens=3 delims= " %%I in (' 2^>nul reg query "HKCU\Console" /v "ForceV2" ') do (
 if "%%~I"=="0x1" (
  reg add "HKCU\Console" /v "ForceV2" /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "HKCU\Console" /v "ForceV2_backup" /t REG_DWORD /d 1 /f >nul 2>&1
 )
)

:: Удаление Zone.Identifier у главного скрипта и ярлыка, если есть эта метка, и установка иконки на ярлык, так как нет относительных путей к иконкам
PowerShell.exe -WindowStyle Hidden -NoProfile -NoLogo -Command "try { Unblock-File -LiteralPath '%~dp0_Tools\_Utils\AutoFixFiles.ps1','%~dp0_Tools\_Utils\AutoFixFiles.lnk' -ErrorAction SilentlyContinue ; $Shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut('%~dp0_Tools\_Utils\AutoFixFiles.lnk') ; $Shortcut.IconLocation = '%~dp0_Tools\_Utils\AutoFixFiles.ico' ; $Shortcut.Save() } catch {}"

:: Запуск скрипта PS через настроенный Ярлык: параметры запуска PS, цвет и шрифты, запуск от админа: (можно запускать из оболочки x86 на Windows x64)
if "%PROCESSOR_ARCHITECTURE%"=="x86" ( if defined PROCESSOR_ARCHITEW6432 ( %SystemRoot%\sysnative\cmd.exe /d /q /c Start _Tools\_Utils\AutoFixFiles.lnk "%~dp0_Tools\_Utils\AutoFixFiles.ps1" ) else Start _Tools\_Utils\AutoFixFiles.lnk "%~dp0_Tools\_Utils\AutoFixFiles.ps1" ) else Start _Tools\_Utils\AutoFixFiles.lnk "%~dp0_Tools\_Utils\AutoFixFiles.ps1"
exit /b 0

::&cls&::   Сделал westlife -- ru-board.com --
@Echo off
set /a def_codepage=437
for /f "tokens=2 delims=:" %%I in (' chcp ') do set /a def_codepage=%%I
chcp 65001 >nul
cd /d "%~dp0"
set Name=AutoFixFiles


:: Проверка: запущен ли скрипт. Дубликат скрипта не должен запускаться, так как одинаковый локальный сервер может быть создан только в одном экземпляре в одно время. 
2>nul tasklist /v /fi "ImageName eq powershell.exe" /fo csv /nh | findstr /i "%Name%" >nul 2>&1
if "%Errorlevel%"=="0" (echo,&echo, Script "%Name%" already [running]&echo,&echo,Press any key to exit . . .& TIMEOUT /T 3 >nul & exit /b 0)

:: проверка настроен ли запуск UWP Windows Terminal для временной настройки использования cmd.exe, с запоминанием предыдущего состояния и возврат сразу после выполнения перезапуска.
set terminal=0
reg query "HKCR\PackagedCom\ClassIndex\{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}" >nul 2>&1
if "%Errorlevel%"=="0" (
 set terminal=1
 for /f "skip=2 tokens=3 delims= " %%I in (' 2^>nul reg query "HKCU\Console\%%%%Startup" /v "DelegationTerminal" ') do (
  if "%%~I"=="{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}" (set terminal=0) else if "%%~I"=="{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}" (set terminal=2)
 )
)
rem настроить conhost.exe на запуск консолей ps и cmd на их оригиналы powershell.exe и cmd.exe, вместо UWP Windows Terminal
if not "%terminal%"=="0" (
 reg add "HKCU\Console\%%%%Startup" /v "DelegationConsole"  /t REG_SZ /d "{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}" /f >nul 2>&1
 reg add "HKCU\Console\%%%%Startup" /v "DelegationTerminal" /t REG_SZ /d "{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}" /f >nul 2>&1
)

chcp %def_codepage% >nul
:: Удаление Zone.Identifier у главного скрипта и ярлыка, если есть эта метка, и установка иконки на ярлык, так как нет относительных путей к иконкам
PowerShell.exe -WindowStyle Hidden -NoProfile -NoLogo -Command "try { Unblock-File -LiteralPath '%~dp0_Tools\_Utils\%Name%.ps1','%~dp0_Tools\_Utils\%Name%.lnk' -ErrorAction SilentlyContinue ; $Shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut('%~dp0_Tools\_Utils\%Name%.lnk') ; $Shortcut.IconLocation = '%~dp0_Tools\_Utils\%Name%.ico' ; $Shortcut.Save() } catch {}"
chcp 65001 >nul

:: Запуск скрипта PS через настроенный Ярлык: параметры запуска PS, цвет и шрифты, запуск от админа: (можно этот батник запускать из оболочки x86 на Windows x64)
if exist _Tools\_Utils\%Name%.lnk (
 if "%PROCESSOR_ARCHITECTURE%"=="x86" ( if defined PROCESSOR_ARCHITEW6432 ( %SystemRoot%\sysnative\cmd.exe /d /q /c Start "%Name%" _Tools\_Utils\%Name%.lnk "%~dp0_Tools\_Utils\%Name%.ps1" ) else Start "%Name%" _Tools\_Utils\%Name%.lnk "%~dp0_Tools\_Utils\%Name%.ps1" ) else Start "%Name%" _Tools\_Utils\%Name%.lnk "%~dp0_Tools\_Utils\%Name%.ps1"
)

:: возврат, если была настройка, через 2 сек предыдущих значений настроек запуска UWP Windows Terminal.
:: Без ожидания из-за задержки в терминале может ps успеть запуститься уже после возврата настроек.
if not "%terminal%"=="0" (
 TIMEOUT /T 2 >nul
 if "%terminal%"=="2" (
  reg add "HKCU\Console\%%%%Startup" /v "DelegationConsole"  /t REG_SZ /d "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}" /f >nul 2>&1
  reg add "HKCU\Console\%%%%Startup" /v "DelegationTerminal" /t REG_SZ /d "{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}" /f >nul 2>&1
 ) else (
  reg delete "HKCU\Console\%%%%Startup" /v "DelegationConsole"  /f >nul 2>&1
  reg delete "HKCU\Console\%%%%Startup" /v "DelegationTerminal" /f >nul 2>&1
 )
)
exit 0
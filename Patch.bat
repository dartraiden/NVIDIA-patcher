@echo off

net session >nul 2>&1
IF %ERRORLEVEL% neq 0 (
	echo Please run as administator!
	pause
	exit
)

@setlocal enableextensions enabledelayedexpansion
@cd /d "%~DP0"

set DRIVER=%CD%\Display.Driver
set BIN_PATTERN=\x87\x1B\x07\x00\xC7\x1B\x07\x00\x07\x1C\x07\x00\x09\x1C\x07
set BIN_PATCH=\x88\x1B\x07\x00\xC8\x1B\x07\x00\x08\x1C\x07\x00\x08\x1C\x07

if not exist "%DRIVER%" (
	echo %DRIVER% not found^^! Unpack driver distributive and place unpacked files next to Patch.bat
	pause
	exit
)

certutil -store Root|find "e403a1dfc8f377e0f4aa43a83ee9ea079a1f55f2" >nul
if not !ERRORLEVEL!==0 (
	certutil -addstore Root EVRootCA.crt
		if not !ERRORLEVEL!==0 (
			echo Failed to install root certificate^^! Download it from pki.jemmylovejenny.tk and install manually into Trusted Root Certification Authorities.
		)
)

certutil -store -user My|find "07e871b66c69f35ae4a3c7d3ad5c44f3497807a1" >nul
if not !ERRORLEVEL!==0 (
	certutil -user -p "440" -importpfx Yongyu.pfx NoRoot
		if not !ERRORLEVEL!==0 (
			echo Failed to install code signing certificate^^!
			pause
			exit
		)
)

if exist "%APPDATA%\TrustAsia\DSignTool" (
	rd "%APPDATA%\TrustAsia\DSignTool" /s /q || echo Failed to delete old CSignTool/DSignTool config^^! Make sure you have write access to the %APPDATA%\TrustAsia\DSignTool directory. && goto CLEAN_CERT
)

md "%APPDATA%\TrustAsia\DSignTool"

echo ^<CONFIG FileExts="*.exe;*.dll;*.ocx;*.sys;*.cat;*.cab;*.msi;*.mui;*.bin;" UUID="{04E99765-8F33-4A9F-9393-35F83CC50E74}"^>^<RULES^>^<RULE Name="Binzhoushi Yongyu Feed Co.,LTd." Cert="07e871b66c69f35ae4a3c7d3ad5c44f3497807a1" Sha2Cert="" Desc="" InfoUrl="" Timestamp="" FileExts="*.exe;*.dll;*.ocx;*.sys;*.cat;*.cab;*.msi;*.mui;*.bin;" EnumSubDir="0" SkipSigned="0" Time="2012-01-31 12:00:25"/^>^</RULES^>^</CONFIG^>>>"%APPDATA%\TrustAsia\DSignTool\Config.xml"

7z e "%DRIVER%\*.bi_" -o"%DRIVER%"
7z e "%DRIVER%\*.dl_" -o"%DRIVER%"
7z e "%DRIVER%\*.ex_" -o"%DRIVER%"
7z e "%DRIVER%\*.ic_" -o"%DRIVER%"
7z e "%DRIVER%\*.sy_" -o"%DRIVER%"

if exist "%DRIVER%\nviccadvancedcoloridentity.ic" ren "%DRIVER%\nviccadvancedcoloridentity.ic" nviccadvancedcoloridentity.icm

if exist "%DRIVER%\nvd3dum.dll" call jrepl.bat "%BIN_PATTERN%" "%BIN_PATCH%" /m /x /f "%DRIVER%\nvd3dum.dll" /o -
if exist "%DRIVER%\nvd3dum_cfg.dll" call jrepl.bat "%BIN_PATTERN%" "%BIN_PATCH%" /m /x /f "%DRIVER%\nvd3dum_cfg.dll" /o -
if exist "%DRIVER%\nvd3dumx.dll" call jrepl.bat "%BIN_PATTERN%" "%BIN_PATCH%" /m /x /f "%DRIVER%\nvd3dumx.dll" /o -
if exist "%DRIVER%\nvd3dumx_cfg.dll" call jrepl.bat "%BIN_PATTERN%" "%BIN_PATCH%" /m /x /f "%DRIVER%\nvd3dumx_cfg.dll" /o -
if exist "%DRIVER%\nvoglv32.dll" call jrepl.bat "%BIN_PATTERN%" "%BIN_PATCH%" /m /x /f "%DRIVER%\nvoglv32.dll" /o -
if exist "%DRIVER%\nvoglv64.dll" call jrepl.bat "%BIN_PATTERN%" "%BIN_PATCH%" /m /x /f "%DRIVER%\nvoglv64.dll" /o -
if exist "%DRIVER%\nvwgf2um.dll" call jrepl.bat "%BIN_PATTERN%" "%BIN_PATCH%" /m /x /f "%DRIVER%\nvwgf2um.dll" /o -
if exist "%DRIVER%\nvwgf2um_cfg.dll" call jrepl.bat "%BIN_PATTERN%" "%BIN_PATCH%" /m /x /f "%DRIVER%\nvwgf2um_cfg.dll" /o -
if exist "%DRIVER%\nvwgf2umx.dll" call jrepl.bat "%BIN_PATTERN%" "%BIN_PATCH%" /m /x /f "%DRIVER%\nvwgf2umx.dll" /o -
if exist "%DRIVER%\nvwgf2umx_cfg.dll" call jrepl.bat "%BIN_PATTERN%" "%BIN_PATCH%" /m /x /f "%DRIVER%\nvwgf2umx_cfg.dll" /o -
if exist "%DRIVER%\nvlddmkm.sys" call jrepl.bat "%BIN_PATTERN%" "%BIN_PATCH%" /m /x /f "%DRIVER%\nvlddmkm.sys" /o -

if exist "%DRIVER%\nvd3dum.dll" makecab "%DRIVER%\nvd3dum.dll" /L "%DRIVER%"
if exist "%DRIVER%\nvd3dum_cfg.dll" makecab "%DRIVER%\nvd3dum_cfg.dll" /L "%DRIVER%"
if exist "%DRIVER%\nvd3dumx.dll" makecab "%DRIVER%\nvd3dumx.dll" /L "%DRIVER%"
if exist "%DRIVER%\nvd3dumx_cfg.dll" makecab "%DRIVER%\nvd3dumx_cfg.dll" /L "%DRIVER%"
if exist "%DRIVER%\nvoglv32.dll" makecab "%DRIVER%\nvoglv32.dll" /L "%DRIVER%"
if exist "%DRIVER%\nvoglv64.dll" makecab "%DRIVER%\nvoglv64.dll" /L "%DRIVER%"
if exist "%DRIVER%\nvwgf2um.dll" makecab "%DRIVER%\nvwgf2um.dll" /L "%DRIVER%"
if exist "%DRIVER%\nvwgf2um_cfg.dll" makecab "%DRIVER%\nvwgf2um.dll" /L "%DRIVER%"
if exist "%DRIVER%\nvwgf2umx.dll" makecab "%DRIVER%\nvwgf2umx.dll" /L "%DRIVER%"
if exist "%DRIVER%\nvwgf2umx_cfg.dll" makecab "%DRIVER%\nvwgf2umx_cfg.dll" /L "%DRIVER%"
if exist "%DRIVER%\nvlddmkm.sys" makecab "%DRIVER%\nvlddmkm.sys" /L "%DRIVER%"

del "%DRIVER%\nv_disp.cat"

inf2cat /driver:"%DRIVER%" /os:10_X64
if not %ERRORLEVEL%==0 (
	echo Failed to generate catalog file^^!
	pause
	goto CLEAN_FILES
)

if not exist "%DRIVER%\nv_disp.cat" (
	echo nv_disp.cat is not exist^^!
	goto CLEAN_FILES
)

CSignTool sign /r "Binzhoushi Yongyu Feed Co.,LTd." /f "%DRIVER%\nv_disp.cat" /ac -ts 2015-01-01T00:00:00
if not %ERRORLEVEL%==0 (
	echo Failed to sign catalog file^^!
	pause
	goto CLEAN_FILES
)

signtool timestamp /t "http://tsa.pki.jemmylovejenny.tk/SHA1/2015-01-01T00:00:00" "%DRIVER%\nv_disp.cat"
if not %ERRORLEVEL%==0 (
	echo Failed to timestamp catalog file^^!
	pause
	goto CLEAN_FILES
)

:CLEAN_FILES
rd "%PROGRAMDATA%\JREPL" /s /q
rd "%APPDATA%\TrustAsia" /s /q
rd "%TEMP%\WST" /s /q

:CLEAN_CERT
certutil -store -user My|find "07e871b66c69f35ae4a3c7d3ad5c44f3497807a1" >nul
if !ERRORLEVEL!==0 (
	certutil -delstore -user My "07e871b66c69f35ae4a3c7d3ad5c44f3497807a1"
		if not !ERRORLEVEL!==0 (
			echo Failed to uninstall code signing certificate^^!
			pause
			exit
		)
)

pause
exit
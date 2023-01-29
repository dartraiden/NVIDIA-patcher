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
set BIN_PATTERN_P=\x07\x1B\x07\x00\x87\x1B\x07\x00\xC7\x1B\x07\x00\x07\x1C\x07\x00\x09\x1C\x07
set BIN_PATCH_P=\x08\x1B\x07\x00\x88\x1B\x07\x00\xC8\x1B\x07\x00\x08\x1C\x07\x00\x08\x1C\x07
set BIN_PATTERN_CMP=\x09\x1E\x07\x00\x49\x1E\x07\x00\xBC\x1E\x07\x00\xFC\x1E\x07\x00\x0B\x1F\x07\x00\x81\x20\x07\x00\x82\x20\x07\x00\x83\x20\x07\x00\xC2\x20\x07\x00\x89\x21\x07\x00\x0D\x22\x07\x00\x4D\x22\x07\x00\x8A\x24\x07
set BIN_PATCH_CMP=\x08\x1E\x07\x00\x49\x1E\x07\x00\xBC\x1E\x07\x00\xFC\x1E\x07\x00\x08\x1F\x07\x00\x81\x20\x07\x00\x82\x20\x07\x00\x83\x20\x07\x00\xC2\x20\x07\x00\x88\x21\x07\x00\x08\x22\x07\x00\x4D\x22\x07\x00\x88\x24\x07

if not exist "%DRIVER%" (
	echo %DRIVER% not found^^! Unpack driver distributive and place unpacked files next to Patch.bat
	pause
	exit
)

if exist "%APPDATA%\TrustAsia\DSignTool" (
	rd "%APPDATA%\TrustAsia\DSignTool" /s /q || echo Failed to delete old CSignTool/DSignTool config^^! Make sure you have write access to the %APPDATA%\TrustAsia\DSignTool directory. && pause && exit
)

certutil -store -user My|find "07e871b66c69f35ae4a3c7d3ad5c44f3497807a1" >nul
if not !ERRORLEVEL!==0 (
	certutil -user -p "440" -importpfx Yongyu.pfx NoRoot
		if not !ERRORLEVEL!==0 (
			echo Failed to install Binzhoushi Yongyu Feed Co.,LTd. code signing certificate^^!
			pause
			exit
		)
)

certutil -store -user My|find "579aec4489a2ca8a2a09df5dc0323634bd8b16b7" >nul
if not !ERRORLEVEL!==0 (
	certutil -user -p "" -importpfx NVIDIA.pfx NoRoot
		if not !ERRORLEVEL!==0 (
			echo Failed to install NVIDIA Corporation code signing certificate^^!
			pause
			exit
		)
)

md "%APPDATA%\TrustAsia\DSignTool"

echo ^<CONFIG FileExts="*.exe;*.dll;*.ocx;*.sys;*.cat;*.cab;*.msi;*.mui;*.bin;" UUID="{04E99765-8F33-4A9F-9393-35F83CC50E74}"^>^<RULES^>^<RULE Name="Binzhoushi Yongyu Feed Co.,LTd." Cert="07e871b66c69f35ae4a3c7d3ad5c44f3497807a1" Sha2Cert="" Desc="" InfoUrl="" Timestamp="" FileExts="*.exe;*.dll;*.ocx;*.sys;*.cat;*.cab;*.msi;*.mui;*.bin;" EnumSubDir="0" SkipSigned="0" Time="2012-01-31 12:00:25"/^>^<RULE Name="NVIDIA Corporation" Cert="579aec4489a2ca8a2a09df5dc0323634bd8b16b7" Sha2Cert="" Desc="" InfoUrl="" Timestamp="" FileExts="*.exe;*.dll;*.ocx;*.sys;*.cat;*.cab;*.msi;*.mui;*.bin;" EnumSubDir="0" SkipSigned="0" Time="2012-01-31 12:00:25"/^>^</RULES^>^</CONFIG^>>>"%APPDATA%\TrustAsia\DSignTool\Config.xml"

7z e "%DRIVER%\*.bi_" -o"%DRIVER%"
7z e "%DRIVER%\*.dl_" -o"%DRIVER%"
7z e "%DRIVER%\*.ex_" -o"%DRIVER%"
7z e "%DRIVER%\*.ic_" -o"%DRIVER%"
7z e "%DRIVER%\*.sy_" -o"%DRIVER%"

if exist "%DRIVER%\nviccadvancedcoloridentity.ic" ren "%DRIVER%\nviccadvancedcoloridentity.ic" nviccadvancedcoloridentity.icm

if exist "%DRIVER%\nvd3dum.dll" call jrepl.bat "%BIN_PATTERN_P%" "%BIN_PATCH_P%" /m /x /f "%DRIVER%\nvd3dum.dll" /o -
if exist "%DRIVER%\nvd3dum_cfg.dll" call jrepl.bat "%BIN_PATTERN_P%" "%BIN_PATCH_P%" /m /x /f "%DRIVER%\nvd3dum_cfg.dll" /o -
if exist "%DRIVER%\nvd3dumx.dll" call jrepl.bat "%BIN_PATTERN_P%" "%BIN_PATCH_P%" /m /x /f "%DRIVER%\nvd3dumx.dll" /o -
if exist "%DRIVER%\nvd3dumx_cfg.dll" call jrepl.bat "%BIN_PATTERN_P%" "%BIN_PATCH_P%" /m /x /f "%DRIVER%\nvd3dumx_cfg.dll" /o -
if exist "%DRIVER%\nvoglv32.dll" call jrepl.bat "%BIN_PATTERN_P%" "%BIN_PATCH_P%" /m /x /f "%DRIVER%\nvoglv32.dll" /o -
if exist "%DRIVER%\nvoglv64.dll" call jrepl.bat "%BIN_PATTERN_P%" "%BIN_PATCH_P%" /m /x /f "%DRIVER%\nvoglv64.dll" /o -
if exist "%DRIVER%\nvwgf2um.dll" call jrepl.bat "%BIN_PATTERN_P%" "%BIN_PATCH_P%" /m /x /f "%DRIVER%\nvwgf2um.dll" /o -
if exist "%DRIVER%\nvwgf2um_cfg.dll" call jrepl.bat "%BIN_PATTERN_P%" "%BIN_PATCH_P%" /m /x /f "%DRIVER%\nvwgf2um_cfg.dll" /o -
if exist "%DRIVER%\nvwgf2umx.dll" call jrepl.bat "%BIN_PATTERN_P%" "%BIN_PATCH_P%" /m /x /f "%DRIVER%\nvwgf2umx.dll" /o -
if exist "%DRIVER%\nvwgf2umx_cfg.dll" call jrepl.bat "%BIN_PATTERN_P%" "%BIN_PATCH_P%" /m /x /f "%DRIVER%\nvwgf2umx_cfg.dll" /o -
if exist "%DRIVER%\nvlddmkm.sys" call jrepl.bat "%BIN_PATTERN_P%" "%BIN_PATCH_P%" /m /x /f "%DRIVER%\nvlddmkm.sys" /o -

if exist "%DRIVER%\nvd3dum.dll" call jrepl.bat "%BIN_PATTERN_CMP%" "%BIN_PATCH_CMP%" /m /x /f "%DRIVER%\nvd3dum.dll" /o -
if exist "%DRIVER%\nvd3dum_cfg.dll" call jrepl.bat "%BIN_PATTERN_CMP%" "%BIN_PATCH_CMP%" /m /x /f "%DRIVER%\nvd3dum_cfg.dll" /o -
if exist "%DRIVER%\nvd3dumx.dll" call jrepl.bat "%BIN_PATTERN_CMP%" "%BIN_PATCH_CMP%" /m /x /f "%DRIVER%\nvd3dumx.dll" /o -
if exist "%DRIVER%\nvd3dumx_cfg.dll" call jrepl.bat "%BIN_PATTERN_CMP%" "%BIN_PATCH_CMP%" /m /x /f "%DRIVER%\nvd3dumx_cfg.dll" /o -
if exist "%DRIVER%\nvoglv32.dll" call jrepl.bat "%BIN_PATTERN_CMP%" "%BIN_PATCH_CMP%" /m /x /f "%DRIVER%\nvoglv32.dll" /o -
if exist "%DRIVER%\nvoglv64.dll" call jrepl.bat "%BIN_PATTERN_CMP%" "%BIN_PATCH_CMP%" /m /x /f "%DRIVER%\nvoglv64.dll" /o -
if exist "%DRIVER%\nvwgf2um.dll" call jrepl.bat "%BIN_PATTERN_CMP%" "%BIN_PATCH_CMP%" /m /x /f "%DRIVER%\nvwgf2um.dll" /o -
if exist "%DRIVER%\nvwgf2um_cfg.dll" call jrepl.bat "%BIN_PATTERN_CMP%" "%BIN_PATCH_CMP%" /m /x /f "%DRIVER%\nvwgf2um_cfg.dll" /o -
if exist "%DRIVER%\nvwgf2umx.dll" call jrepl.bat "%BIN_PATTERN_CMP%" "%BIN_PATCH_CMP%" /m /x /f "%DRIVER%\nvwgf2umx.dll" /o -
if exist "%DRIVER%\nvwgf2umx_cfg.dll" call jrepl.bat "%BIN_PATTERN_CMP%" "%BIN_PATCH_CMP%" /m /x /f "%DRIVER%\nvwgf2umx_cfg.dll" /o -
if exist "%DRIVER%\nvlddmkm.sys" call jrepl.bat "%BIN_PATTERN_CMP%" "%BIN_PATCH_CMP%" /m /x /f "%DRIVER%\nvlddmkm.sys" /o -

if exist "%DRIVER%\nvd3dum.dll" CSignTool sign /r "NVIDIA Corporation" /f "%DRIVER%\nvd3dum.dll" -ts 2013-01-01T00:00:00
if exist "%DRIVER%\nvd3dum_cfg.dll" CSignTool sign /r "NVIDIA Corporation" /f "%DRIVER%\nvd3dum_cfg.dll" -ts 2013-01-01T00:00:00
if exist "%DRIVER%\nvd3dumx.dll" CSignTool sign /r "NVIDIA Corporation" /f "%DRIVER%\nvd3dumx.dll" -ts 2013-01-01T00:00:00
if exist "%DRIVER%\nvd3dumx_cfg.dll" CSignTool sign /r "NVIDIA Corporation" /f "%DRIVER%\nvd3dumx_cfg.dll" -ts 2013-01-01T00:00:00
if exist "%DRIVER%\nvoglv32.dll" CSignTool sign /r "NVIDIA Corporation" /f "%DRIVER%\nvoglv32.dll" -ts 2013-01-01T00:00:00
if exist "%DRIVER%\nvoglv64.dll" CSignTool sign /r "NVIDIA Corporation" /f "%DRIVER%\nvoglv64.dll" -ts 2013-01-01T00:00:00
if exist "%DRIVER%\nvwgf2um.dll" CSignTool sign /r "NVIDIA Corporation" /f "%DRIVER%\nvwgf2um.dll" -ts 2013-01-01T00:00:00
if exist "%DRIVER%\nvwgf2um_cfg.dll" CSignTool sign /r "NVIDIA Corporation" /f "%DRIVER%\nvwgf2um_cfg.dll" -ts 2013-01-01T00:00:00
if exist "%DRIVER%\nvwgf2umx.dll" CSignTool sign /r "NVIDIA Corporation" /f "%DRIVER%\nvwgf2umx.dll" -ts 2013-01-01T00:00:00
if exist "%DRIVER%\nvwgf2umx_cfg.dll" CSignTool sign /r "NVIDIA Corporation" /f "%DRIVER%\nvwgf2umx_cfg.dll" -ts 2013-01-01T00:00:00

if exist "%DRIVER%\nvd3dum.dll" signtool timestamp /t "http://tsa.pki.jemmylovejenny.tk/SHA1/2013-01-01T00:00:00" "%DRIVER%\nvd3dum.dll"
if exist "%DRIVER%\nvd3dum_cfg.dll" signtool timestamp /t "http://tsa.pki.jemmylovejenny.tk/SHA1/2013-01-01T00:00:00" "%DRIVER%\nvd3dum_cfg.dll"
if exist "%DRIVER%\nvd3dumx.dll" signtool timestamp /t "http://tsa.pki.jemmylovejenny.tk/SHA1/2013-01-01T00:00:00" "%DRIVER%\nvd3dumx.dll"
if exist "%DRIVER%\nvd3dumx_cfg.dll" signtool timestamp /t "http://tsa.pki.jemmylovejenny.tk/SHA1/2013-01-01T00:00:00" "%DRIVER%\nvd3dumx_cfg.dll"
if exist "%DRIVER%\nvoglv32.dll" signtool timestamp /t "http://tsa.pki.jemmylovejenny.tk/SHA1/2013-01-01T00:00:00" "%DRIVER%\nvoglv32.dll"
if exist "%DRIVER%\nvoglv64.dll" signtool timestamp /t "http://tsa.pki.jemmylovejenny.tk/SHA1/2013-01-01T00:00:00" "%DRIVER%\nvoglv64.dll"
if exist "%DRIVER%\nvwgf2um.dll" signtool timestamp /t "http://tsa.pki.jemmylovejenny.tk/SHA1/2013-01-01T00:00:00" "%DRIVER%\nvwgf2um.dll"
if exist "%DRIVER%\nvwgf2um_cfg.dll" signtool timestamp /t "http://tsa.pki.jemmylovejenny.tk/SHA1/2013-01-01T00:00:00" "%DRIVER%\nvwgf2um_cfg.dll"
if exist "%DRIVER%\nvwgf2umx.dll" signtool timestamp /t "http://tsa.pki.jemmylovejenny.tk/SHA1/2013-01-01T00:00:00" "%DRIVER%\nvwgf2umx.dll"
if exist "%DRIVER%\nvwgf2umx_cfg.dll" signtool timestamp /t "http://tsa.pki.jemmylovejenny.tk/SHA1/2013-01-01T00:00:00" "%DRIVER%\nvwgf2umx_cfg.dll"

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
	goto CLEAN
)

if not exist "%DRIVER%\nv_disp.cat" (
	echo nv_disp.cat is not exist^^!
	goto CLEAN
)

CSignTool sign /r "Binzhoushi Yongyu Feed Co.,LTd." /f "%DRIVER%\nv_disp.cat" /ac -ts 2015-01-01T00:00:00
if not %ERRORLEVEL%==0 (
	echo Failed to sign catalog file^^!
	pause
	goto CLEAN
)

signtool timestamp /t "http://tsa.pki.jemmylovejenny.tk/SHA1/2015-01-01T00:00:00" "%DRIVER%\nv_disp.cat"
if not %ERRORLEVEL%==0 (
	echo Failed to timestamp catalog file^^!
	pause
	goto CLEAN
)

certutil -store Root|find "e403a1dfc8f377e0f4aa43a83ee9ea079a1f55f2" >nul
if not !ERRORLEVEL!==0 (
	certutil -addstore Root EVRootCA.crt
		if not !ERRORLEVEL!==0 (
			echo Failed to install root certificate^^! Download it from pki.jemmylovejenny.tk and install manually into Trusted Root Certification Authorities.
		)
)

:CLEAN
rd "%PROGRAMDATA%\JREPL" /s /q
rd "%APPDATA%\TrustAsia" /s /q
rd "%TEMP%\WST" /s /q

certutil -store -user My|find "07e871b66c69f35ae4a3c7d3ad5c44f3497807a1" >nul
if !ERRORLEVEL!==0 (
	certutil -delstore -user My "07e871b66c69f35ae4a3c7d3ad5c44f3497807a1"
		if not !ERRORLEVEL!==0 (
			echo Failed to uninstall Binzhoushi Yongyu Feed Co.,LTd. code signing certificate^^!
			pause
			exit
		)
)

certutil -store -user My|find "579aec4489a2ca8a2a09df5dc0323634bd8b16b7" >nul
if !ERRORLEVEL!==0 (
	certutil -delstore -user My "579aec4489a2ca8a2a09df5dc0323634bd8b16b7"
		if not !ERRORLEVEL!==0 (
			echo Failed to uninstall NVIDIA Corporation code signing certificate^^!
			pause
			exit
		)
)

exit
@echo off
@setlocal EnableExtensions EnableDelayedExpansion

@cd /d "%~dp0"

:SetVariables
set /p "Version=Enter driver version (e.g. 330.67):"
if not defined Version exit 1
for /d %%a in ("*") do set "DriverPath=%%~fa\Display.Driver"
set "Nvenc32PatchUrl=https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/%Version%/nvencodeapi.1337"
set "Nvenc64PatchUrl=https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/%Version%/nvencodeapi64.1337"
set "Nvfbc32WrapperUrl=https://gist.githubusercontent.com/Snawoot/17b14e7ce0f7412b91587c2723719eff/raw/e8e9658fd20751ad875477f37b49ea158ece896d/nvfbcwrp32.dll"
set "Nvfbc64WrapperUrl=https://gist.githubusercontent.com/Snawoot/17b14e7ce0f7412b91587c2723719eff/raw/e8e9658fd20751ad875477f37b49ea158ece896d/nvfbcwrp64.dll"

:CheckNvencPatchPresence
for /f %%a in ( 'curl -o nul -s -Iw "%%{http_code}" "%Nvenc64PatchUrl%"' ) do set http=%%a
if not %http% == 200 (
	echo NVENC patch is not found^^!
	pause
	exit 1
)

:DownloadNvencPatches
title Downloading NVENC patches...
curl -s -O %Nvenc32PatchUrl%
curl -s -O %Nvenc64PatchUrl%

:CheckNvfbcWrapperPresence
for /f %%a in ( 'curl -o nul -s -Iw "%%{http_code}" "%Nvfbc64WrapperUrl%"' ) do set http=%%a
if not %http% == 200 (
	echo NvFBC wrapper is not found^^!
	pause
	exit 1
)

:UnpackNvfbcFiles
if %Version% lss 535 (
	title Unpacking NvFBC binaries...
	if exist "%DriverPath%\nvfbc.dl_" "%~dp0..\_Tools\_Utils\x64\7z\7z.exe" e "%DriverPath%\nvfbc.dl_" -o"%DriverPath%"
	if exist "%DriverPath%\nvfbc64.dl_" "%~dp0..\_Tools\_Utils\x64\7z\7z.exe" e "%DriverPath%\nvfbc64.dl_" -o"%DriverPath%"
)

:RenameNvfbcFiles
ren "%DriverPath%\nvfbc.dll" "nvfbc_.dll"
ren "%DriverPath%\nvfbc64.dll" "nvfbc64_.dll"

:DownloadNvfbcWrapper
title Downloading NvFBC wrappers...
curl -s -o "%DriverPath%\nvfbc.dll" %Nvfbc32WrapperUrl%
curl -s -o "%DriverPath%\nvfbc64.dll" %Nvfbc64WrapperUrl%

:PackNvfbcFiles
if %Version% lss 535 (
	title Packing NvFBC binaries...
	if exist "%DriverPath%\nvfbc.dll" makecab "%DriverPath%\nvfbc.dll" /l "%DriverPath%"
	if exist "%DriverPath%\nvfbc_.dll" makecab "%DriverPath%\nvfbc_.dll" /l "%DriverPath%"
	if exist "%DriverPath%\nvfbc64.dll" makecab "%DriverPath%\nvfbc64.dll" /l "%DriverPath%"
	if exist "%DriverPath%\nvfbc64_.dll" makecab "%DriverPath%\nvfbc64_.dll" /l "%DriverPath%"
)

exit
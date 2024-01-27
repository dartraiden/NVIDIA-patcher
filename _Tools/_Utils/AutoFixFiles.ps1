
<#
.SYNOPSIS
    Главный Скрипт AutoFixFiles (PowerShell 5)

.DESCRIPTION
    Автоматизация изменений разных файлов.
    С возможностью подписи, например драйверов с перегенерацией cat

.LINK
    Форум: https://forum.ru-board.com/topic.cgi?forum=2&bm=1&topic=5711&glp

.NOTES
 ================================================
     Автор:  westlife (ru-board)
      Дата:  01-08-2023
 ================================================
#>

#Requires -Version 5


# Определение оболочки.
if ( $host.Name -eq 'ConsoleHost' ) { [bool] $isConsole = $true }

# Если консоль, то установить параметры цвета и вывода кодировки для текущей консоли.
if ( $isConsole )
{
    $host.UI.RawUI.BackgroundColor = "Black"
    $host.PrivateData.WarningForegroundColor = "Yellow"
    $host.PrivateData.VerboseForegroundColor = "Blue"

    $BufferHeight = $host.UI.RawUI.BufferSize.Height
    if ( $BufferHeight -lt 9000 )
    {
        $BufferHeightNew = New-Object System.Management.Automation.Host.Size($host.UI.RawUI.BufferSize.Width,9000)
        $host.UI.RawUI.BufferSize = $BufferHeightNew
    }

    [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding('utf-8')

    # Отключение lagacy console mode, если было включено батником перед стартом (восстанавливает как было до настройки)
    # Метод для отключения запуска UWP Terminal вместо консоли PS, при запуске без админ прав:
    try { if ( $backup = [Microsoft.Win32.Registry]::GetValue('HKEY_CURRENT_USER\Console','ForceV2_backup',$null) ) {
        if ( $backup -eq 1 )
        {
            [Microsoft.Win32.Registry]::SetValue('HKEY_CURRENT_USER\Console','ForceV2', 1,'Dword')
            [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Console','ReadWriteSubTree').DeleteValue('ForceV2_backup') > $null
        }
    }} catch {}
}


# Разрядность Windows
if ( [System.Environment]::Is64BitOperatingSystem ) { Set-Variable -Name ArchOS -Value ([string] 'x64') -Option Constant -Force }
else { Set-Variable -Name ArchOS -Value ([string] 'x86') -Option Constant -Force }

# Функция определения текущего расположения корневой папки в зависимости от оболочки: ISE или Консоль.
Function Get-CurrentRoot { if ( $isConsole ) { $CurrentRoot = $PSScriptRoot }
    else { $CurrentRoot = [System.IO.Path]::GetDirectoryName($psISE.CurrentFile.Fullpath) }
    $CurrentRoot = [System.IO.Path]::GetDirectoryName($CurrentRoot)
    [System.IO.Path]::GetDirectoryName($CurrentRoot)
}

################################################################################
#######################  Параметры основных переменных  ########################

$CurrentDate = Get-Date
$CurrentDateFile = $CurrentDate.ToString('yyyyMMdd-HHmmss')
$CurrentDateText = $CurrentDate.ToString('yyyy.MM.dd HH:mm:ss')

# Текущее расположение скрипта, постоянная переменная.
Set-Variable -Name CurrentRoot -Value (Get-CurrentRoot) -Option Constant -Force

# Папка для управляющих скриптов и модулей, обеспечиващих выполнение действий или отображения информации.
$ScriptsManagFolder = "$CurrentRoot\_Tools\_Utils\Scripts-Management"

# Папка для настраивающих систему скриптов, которые при выполнении вносят изменения в систему.
$ScriptsFolder = "$CurrentRoot\_Tools\_Utils\Scripts"

# Папка со всеми меню.
$MenuFolder = "$CurrentRoot\_Tools\_Utils\Menu"

# Временная папка.
$ScratchDirGlobal = "$CurrentRoot\_Tools\Temp"

$EditFolderGlobal     = "$CurrentRoot\Edit"
$UseCertsFolderGlobal = "$CurrentRoot\UseCerts"

# Файл пресетов, для указания своих параметров к некоторым функциям.
# Если рядом будет найден другой с именем начинающимся на Presets, то будет использоваться он.
$FilePresetsGlobal = "$CurrentRoot\Presets.txt"

# Утилита 7z.exe для извлечения отдельных файлов из архива и распаковки
$7z = "$CurrentRoot\_Tools\_Utils\$ArchOS\7z\7z.exe"

$openssl      = "$CurrentRoot\_Tools\_Utils\x86\openssl\openssl.exe" # need v3.1.1 + legacy.dll
$osslsigncode = "$CurrentRoot\_Tools\_Utils\$ArchOS\osslsigncode\osslsigncode.exe"  # v2.7
$signtool     = "$CurrentRoot\_Tools\_Utils\$ArchOS\ms\signtool.exe" # MS
$Inf2Cat      = "$CurrentRoot\_Tools\_Utils\$ArchOS\ms\Inf2Cat.exe"  # MS
$BouncyDll    = "$CurrentRoot\_Tools\_Utils\x86\BouncyCastle.Crypto.dll" # для Local TimeStamp Server
$TbsFolder    = "$CurrentRoot\_Tools\_Utils\x86\ms\tbs" # dll`s для получения TBS драйвера из сертификата
$PEChecksum   = "$CurrentRoot\_Tools\_Utils\$ArchOS\PEChecksum_$ArchOS.exe" # Исправление контрольной суммы в PE файлах от Jeff Bush (2012-11-08)


# Лог для сохранения предупреждений.
$WarningsLogFile = "$CurrentRoot\AutoFixFiles-Warnings.log"  # Сохранение в корневой папке.

# Лог для сохранения ошибок.
$ErrorsLogFile = "$CurrentRoot\AutoFixFiles-Errors.log"      # Сохранение в корневой папке.

# Файл для сохранения экрана консоли, один в один, в HTML формате.
$FileHtmlLogName = "HtmlLog-$CurrentDateFile.html"  # Сохранение с таким именем, ниже сценарий определения папки сохранения.

###############################################################################
###############################################################################

# Временная папка для всех утилит запускаемых текущим скриптом - внутри папки скрипта
[System.Environment]::SetEnvironmentVariable( 'TEMP', $ScratchDirGlobal, [System.EnvironmentVariableTarget]::Process )
[System.Environment]::SetEnvironmentVariable( 'TMP',  $ScratchDirGlobal, [System.EnvironmentVariableTarget]::Process )


# Результат состояния наличия прав Администратора у текущей оболочки.
$AdminRight = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
               [Security.Principal.WindowsBuiltInRole]::Administrator)

# Получение типа доступа и названия, для отображения его в заголовке окна.
if ( $AdminRight )
{
    if ( [System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem )
    {
        if ( [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups.Value.Where({ $_ -like 'S-1-5-80-*' },'First',1) )
        {
            [string] $CurrentRight = 'TrustedInstaller'
        }
        else
        {
            [string] $CurrentRight = 'System'
        }
    }
    else
    {
        [string] $CurrentRight = (Get-LocalUser).Where({ $_.SID.Value -match '^S-1-5-21-[\d-]+-500$'}).Name
    }
}

# Изменение заголовка окна консоли, в зависимости от прав доступа.
if ( -not $AdminRight ) { $isWindowTitle = 'AutoFixFiles' } else { $isWindowTitle = "$CurrentRight`: AutoFixFiles" }
$host.UI.RawUI.WindowTitle = $isWindowTitle


# Сортировка как в проводнике через API
Function Get-Preset ($File) {

    $NaturalSort = @'
using System.Runtime.InteropServices;
public static class NaturalSort
{
    [DllImport("Shlwapi.dll", CharSet = CharSet.Unicode)]
    private static extern int StrCmpLogicalW(string psz1, string psz2);
    public static string[] Sort(string[] array)
    {
        System.Array.Sort(array, (psz1, psz2) => StrCmpLogicalW(psz1, psz2));
        return array;
    }
}
'@
    if ( -not ( 'NaturalSort' -as [type] ))
    {
        $cp = [System.CodeDom.Compiler.CompilerParameters]::new('System.dll')
        $cp.TempFiles = [System.CodeDom.Compiler.TempFileCollection]::new($ScratchDirGlobal,$false)
        $cp.GenerateInMemory = $true
        $cp.CompilerOptions = '/platform:anycpu /nologo'

        Add-Type -TypeDefinition $NaturalSort -ErrorAction Stop -Language CSharp -CompilerParameters $cp
    }

    # Если будут найдены другие файлы для настроек, состоящих из имени и расширения заданного оригинала,
    # то будет использоваться как пресет для настроек первый из дополнительных найденных.
    [string] $FoundPresetsMy = ''

    try
    {
        [string] $PresetsPath = [System.IO.Path]::GetDirectoryName($File)
        [string] $PresetsName = [System.IO.Path]::GetFileNameWithoutExtension($File)
        [string] $PresetsExt  = [System.IO.Path]::GetExtension($File)

        $FoundPresetsMy = [NaturalSort]::Sort(@([System.IO.Directory]::EnumerateFiles($PresetsPath,"$PresetsName*$PresetsExt")).Where({ $_ -notlike "*\$PresetsName$PresetsExt" }))[0]
    }
    catch {}

    if ( $FoundPresetsMy ) { Return $FoundPresetsMy } else { Return $File }
}

Set-Variable -Name dUnPackOrFolderGlobal -Value @{} -Option AllScope -Force

Set-Variable -Name BoolErrorGlobal          -Value $false -Option AllScope -Force
Set-Variable -Name aDataToSignFilesGlobal   -Value @() -Option AllScope -Force
Set-Variable -Name aDataRemoveSignGlobal    -Value @() -Option AllScope -Force
Set-Variable -Name aDataNullFilesGlobal     -Value @() -Option AllScope -Force
Set-Variable -Name aDataCopyFilesGlobal     -Value @() -Option AllScope -Force
Set-Variable -Name aDataRepackPFXFileGlobal -Value @() -Option AllScope -Force
Set-Variable -Name aDataCMDfilesGlobal      -Value @() -Option AllScope -Force
Set-Variable -Name aDataCMDfilesFinalGlobal -Value @() -Option AllScope -Force
Set-Variable -Name aDataContentFixGlobal    -Value @() -Option AllScope -Force
Set-Variable -Name aDataPatchGlobal         -Value @() -Option AllScope -Force
Set-Variable -Name PrintTSAGlobal           -Value ([PSCustomObject]@{}) -Option AllScope -Force
Set-Variable -Name BoolStartLocalTsGlobal   -Value $false -Option AllScope -Force
Set-Variable -Name BoolUseBuiltInTsaGlobal  -Value $false -Option AllScope -Force

Set-Variable -Name aActionsGlobal    -Value @() -Option AllScope -Force
Set-Variable -Name aWarningsGlobal   -Value @() -Option AllScope -Force
Set-Variable -Name aAttentionsGlobal -Value @() -Option AllScope -Force


# Специальная глобальная переменная для подгрузки имени файла пресета из любой области выполнения
Set-Variable -Name CurrentPresetsFile -Value ([string]::Empty) -Option AllScope -Force
$CurrentPresetsFile = Get-Preset -File $FilePresetsGlobal

# Специальная глобальная переменная для подгрузки пресетов
Set-Variable -Name ListPresetsGlobal -Value ([string[]]::new(0)) -Option AllScope -Force
# Получение всех настроек из файла пресетов для использования из указанного или дополнительно найденного файла, если он существует.
$ListPresetsGlobal = Get-Content -LiteralPath $CurrentPresetsFile -Encoding UTF8 -ErrorAction SilentlyContinue

Function Get-List-Presets {

    $CurrentPresetsFile = Get-Preset -File $FilePresetsGlobal

    # Если файл с пресетами существует.
    if ( [System.IO.File]::Exists($CurrentPresetsFile) )
    {
        # Получение пресетов в переменную.
        try { [string[]] $ListPresetsGlobal = Get-Content -LiteralPath $CurrentPresetsFile -Encoding UTF8 -ErrorAction SilentlyContinue } catch {}
    }
}


# Переменная для подстановки перевода
[string] $text = ''


# Специальная глобальная переменная для указания не делать паузу,
# и возможности ее изменения в любой области выполнения, при необходимости.
Set-Variable -Name NoPause -Value $false -Option AllScope -Force

# Функция для установки паузы в зависимости от оболочки: ISE или Консоль.
# Но только если запуск скрипта без аргументов автозапуска выполнения быстрых настроек.
# То есть не будет пауз при вызове функции Get-Pause во всех функциях, во время автоматического выполнения быстрых настроек.
Function Get-Pause ( [switch] $Simple ) {

    if ( $NoPause ) { Return }

    if ( $isConsole )
    {
        if ( -not $Simple )
        {
            # Если в пресетах задано сохранять лог HTML, то вызов функции сохранения консоли, дополняя существующий, при каждом вызове паузы.
            # И указание на добавление к существующему всего текущего буфера с самого начала,
            # так как в функции Show-Menu выполняется очистка консоли Clear-Host.
            if ( $SaveHtmlLogGlobal )
            {
                if ( Get-Command -CommandType Function -Name Save-HtmlLog -ErrorAction SilentlyContinue )
                {
                    Save-HtmlLog -AllBuffer -ShowSave
                }
            }
        }

        $text =  'Press any key to continue ...'
        Write-Host "`n $text"

        # Сброс нажатых клавиш клавиатуры в процессе выполнения,
        # чтобы консоль не обрабатывала эти действия после вызова паузы.
        $Host.UI.RawUI.FlushInputBuffer()

        $host.UI.RawUI.ReadKey('NoEcho, IncludeKeyDown') > $null
    }
    else
    {
        $text = 'Press ''Enter'' to continue'
        Read-Host -Prompt "`n $text"
    }
}

########################################

# Проверки существования важных файлов.
if ( -not [System.IO.File]::Exists($7z) )
{
    $text = 'Utility not found'
    Write-Warning "`n   $text 7z.exe: '$7z'`n "

    Get-Pause -Simple ; Exit
}

if ( -not [System.IO.File]::Exists("$CurrentRoot\_Tools\_Utils\$ArchOS\7z\7z.dll") )
{
    $text = 'The 7z.dll file for 7z.exe was not found'
    Write-Warning "`n   $text`: '$CurrentRoot\_Tools\_Utils\$ArchOS\7z\7z.dll'`n "

    Get-Pause -Simple ; Exit
}

if ( -not [System.IO.File]::Exists($openssl) )
{
    $text = 'Utility not found'
    Write-Warning "`n   $text openssl.exe`n "

    Get-Pause -Simple ; Exit
}

if ( -not [System.IO.File]::Exists($osslsigncode) )
{
    $text = 'Utility not found'
    Write-Warning "`n   $text osslsigncode.exe`n "

    Get-Pause -Simple ; Exit
}

if ( -not [System.IO.File]::Exists($signtool) )
{
    $text = 'MS Utility not found'
    Write-Warning "`n   $text signtool.exe`n "

    Get-Pause -Simple ; Exit
}

if ( -not [System.IO.File]::Exists($Inf2Cat) )
{
    $text = 'MS Utility not found'
    Write-Warning "`n   $text Inf2Cat.exe`n "

    Get-Pause -Simple ; Exit
}

if ( -not [System.IO.File]::Exists($BouncyDll) )
{
    $text = 'dll for local server not found'
    Write-Warning "`n   $text BouncyCastle.Crypto.dll`n "

    Get-Pause -Simple ; Exit
}



# Создание важных или нужных папок, если они не существуют.
[string[]] $FoldersGlobal =
    $UseCertsFolderGlobal,
    $ScratchDirGlobal,
    $EditFolderGlobal

foreach ( $Folder in $FoldersGlobal )
{
    if ( -not [System.IO.Directory]::Exists($Folder) )
    {
        try { New-Item -ItemType Directory -Path $Folder -Force -ErrorAction Stop > $null }
        catch
        {
            $text = 'Error when creating a folder'
            Write-Warning "$text`: '$Folder'`n`t$($_.exception.Message)"

            Get-Pause -Simple ; Exit
        }
    }
}



# Функция для получения версии AutoFixFiles из файла пресетов глобального или найденного дополнительного.
Function Get-Presets-Version {

    # Получение версии AutoFixFiles из пресетов.
    if ( $ListPresetsGlobal.Where({ $_ -match '^\s*Script-Version\s*=\s*(?<Version>[0-9.a-z]+)\s*==' },'First') )
    {
        [string] $Version = $Matches.Version.Trim()
    }
    else { [string] $Version = '' }

    $Version
}


# Получение версии AutoFixFiles из файла пресетов глобального или найденного дополнительного.
[string] $AutoFixFilesVersion = Get-Presets-Version

if ( -not $AutoFixFilesVersion )
{
    $text = 'The main preset file is not found, or it is incorrect'
    Write-Warning "`n  $text`: '$FilePresetsGlobal'. `n  exit `n "

    Get-Pause -Simple ; Exit
}

$isWindowTitle = "$isWindowTitle | $AutoFixFilesVersion"
$host.UI.RawUI.WindowTitle = $isWindowTitle



# Функция для получения лога и его переменных.
Function Get-HtmlLog {

    [string] $NameThisFunction = $MyInvocation.MyCommand.Name

    # Получение из пресетов разрешающего параметра по сохранению консоли в HTML файл,
    # И если сохранять, то создать глобальную константную переменную, разрешающую сохранять.
    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Save-HTML-Log\s*=(\s*(?<FolderLogs>[a-z0-9]*)\s*==)?' },'First',1) )
    {
        # Если указано в пресете имя папки для логов внутри папки скрипта, то сохранять в эту папку, если папки нет, то создать её, иначе сохранять в корень папки.
        if ( $Matches.FolderLogs )
        {
            $FolderLogs = $Matches.FolderLogs.Trim()
            $Path       = "$CurrentRoot\$FolderLogs"

            Set-Variable -Name FileHtmlLogGlobal -Value "$Path\$FileHtmlLogName" -Scope Global -Option ReadOnly -Force

            if ( -not [System.IO.Directory]::Exists($Path) )
            {
                try { New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop > $null }
                catch
                {
                    $text = 'Error when creating a folder'
                    Write-Warning "$text`: '$Path'`n`t$($_.exception.Message)"

                    Get-Pause -Simple ; Exit
                }
            }
        }
        else
        {
            Set-Variable -Name FileHtmlLogGlobal -Value "$CurrentRoot\$FileHtmlLogName" -Scope Global -Option ReadOnly -Force
        }

        Set-Variable -Name SaveHtmlLogGlobal -Value ( [bool] $true ) -Scope Global -Option ReadOnly -Force

        $ShowLogInMainMenu = '#DarkGray#{0}#' -f $FileHtmlLogGlobal.Replace("$CurrentRoot\",'')
    }
    else
    {
        Set-Variable -Name SaveHtmlLogGlobal -Value ( [bool] $false ) -Scope Global -Option ReadOnly -Force

        $ShowLogInMainMenu = '#DarkGray#{0}#' -f 'will not be saved'
    }

    $ShowLogInMainMenu
}


# Получение лога и создание глобальных переменных с лог файлом и разрешением/запретом сохранения лога
Get-HtmlLog > $null


# Получение списка с полными путями всех скриптов и модулей '.ps1' и '.psm1' из указанной папки, включая поддиректории.
Function Get-Scripts {
    [CmdletBinding( SupportsShouldProcess = $false )]
    Param (
        [Parameter( Mandatory = $true, ValueFromPipeline = $false, Position = 0 )]
        [ValidatePattern('^[a-z]:\\.+')]
        [string] $Path
    )
    [string[]] $Scripts = ((Get-ChildItem -File -LiteralPath $Path -Recurse -ErrorAction SilentlyContinue).Where({ $_.Name -match '[.](ps1|psm1)$' })).FullName
    
    Return $Scripts
}

# Получение списка всех настраивающих систему модулей и скриптов с полными путями.
$ScriptsFiles = Get-Scripts -Path $ScriptsFolder

# Подключение настраивающих систему скриптов и модулей. При ошибке импорта будет перехватывать в trap для удаления меток Zone.Identifier
if ( $ScriptsFiles )
{
    foreach ( $ScriptsFile in $ScriptsFiles )
    {
        try   { Import-Module -Name $ScriptsFile -Scope Global -Force -ErrorAction Stop }
        catch
        {
            $text = 'Error when importing a script'
            Write-Warning "`n  $text`: '$ScriptsFile' `n "

            throw  # При ошибке перекинуть в trap для снятий блокировок.
        }
    }
}

# Получение списка управляющих модулей и скриптов с полными путями.
$ScriptsManagFiles = Get-Scripts -Path $ScriptsManagFolder

# Подключение управляющих скриптов и модулей, в последнюю очередь, так как эти в приоритете.
# Перекроют все функции из других скриптов, при совпадении имен.
if ( $ScriptsManagFiles )
{
    foreach ( $ScriptsManagFile in $ScriptsManagFiles )
    {
        try   { Import-Module -Name $ScriptsManagFile -Scope Global -Force -ErrorAction Stop }
        catch
        {
            $text = 'Error when importing a script'
            Write-Warning "`n  $text`: '$ScriptsManagFile' `n "

            throw # При ошибке перекинуть в trap для снятий блокировок.
        }
    }
}
else
{
    $text = 'Error. No scripts found in the folder'
    Write-Warning "`n  $text '$ScriptsManagFolder' `n  exit `n "

    Get-Pause -Simple ; Exit
}

# Получение списка всех скриптов с меню, с полными путями.
$MenuFiles = Get-Scripts -Path $MenuFolder

# Подключение всех меню.
if ( $MenuFiles )
{
    foreach ( $Menu in $MenuFiles )
    {
        try { Import-Module -Name $Menu -Scope Global -Force -ErrorAction Stop }
        catch
        {
            $text = 'Error when importing menu script'
            Write-Warning "`n  $text`: '$Menu' `n  exit `n "

            Get-Pause -Simple ; Exit
        }
    }
}
else
{
    $text = 'Error. No menu scripts found in the folder'
    Write-Warning "`n  $text '$MenuFolder' `n exit `n "

    Get-Pause -Simple ; Exit
}


# Назначение главного меню '$MainMenu' в переменную '$isStartMenu' для текущего меню, так как все начинается с этого меню.
# В этом главном меню указываются переходы в какие либо другие меню, или какие либо действия.
# По описанию (Description) определяется какое именно текущее меню в данный момент.
Set-Variable -Name isStartMenu -Value $MainMenu -Description '$MainMenu' -Scope Global -Option AllScope -Force

# Бесконечный цикл для запуска/перезапуска любого меню, заданного в глобальной переменной $isStartMenu в данный момент,
# выполняется после каждого выхода из функции Show-Menu по обработке меню.
# Перед завершением функции Show-Menu, для входа в любое указанное меню, перезадается нужное меню в глобальную переменную $isStartMenu.
# Для обеспечения, каждый раз, новой точки входа в функцию Show-Menu, а не запуск функции Show-Menu внутри функции Show-Menu, что приведет к проблеме.
do
{
    Get-List-Presets

    # Получение названия переменной текущего меню из $isStartMenu, оно указывается в описании этой переменной.
    [string] $CurrentMenuName = (Get-Variable -Name isStartMenu -ErrorAction SilentlyContinue).Description

    # Ищем во всех найденных файлах с меню, полный путь к текущему меню, и переподключаем его.
    # Чтобы не переподключать все меню каждый раз, а только нужное в данный момент. Для обновления переменных, указанных в нем.
    $MenuFiles.Where({ $_ -like "*$CurrentMenuName*" }).ForEach(
    {
        try { Import-Module -Name $_ -Scope Global -Force -ErrorAction Stop }
        catch
        {
            $text = 'Error when importing menu script'
            Write-Warning "`n  $text`: '$_' `n  выход"

            Get-Pause ; Exit
        }
    })

    # Создание скриптблока для возможности перевода имени переменной, в объект из этой переменной. В данном случае hashtable меню.
    [psobject] $MenuScriptBlock = [scriptblock]::Create( $CurrentMenuName )

    # Назначение в переменную $isStartMenu текущего меню с именем из $CurrentMenuName по новой, с обновленными переменными,
    # после перевода скриптблока $MenuScriptBlock в объект hashtable.
    Set-Variable -Name isStartMenu -Value ( & $MenuScriptBlock ) -Description $CurrentMenuName -Scope Global -Option AllScope -Force

    # Вывод текущего обновленного меню.
    Show-Menu -Menu $isStartMenu
}
while ( $true )



##########################################################################

# Сообщение о Выходе из скрипта, если такое произойдет из-за ошибки.
$text = 'Error. A jump to the end of the script was made. Exit'
Write-Warning "`n     $text `n "

Get-Pause
Exit

trap
{
    # Если есть функция Save-Error
    if ( Get-Command -CommandType Function -Name 'Save-Error' -ErrorAction SilentlyContinue )
    {
        $text = 'catched error for save'
        Write-Host "   --- $text ---   " -BackgroundColor DarkGray

        Save-Error
    }
    else
    {
        Write-Output "`n" $Error[-1]

        $text = 'There was an error in the main script AutoFixFiles.ps1'
        Write-Host
        Write-Host "   !!! $text !!!" -ForegroundColor White -BackgroundColor DarkRed
        Write-Host

        [int] $ZoneCount = 0

        # Поиск и удаление Zone.Identifier у файлов.
        try
        {
            (Get-ChildItem -File -LiteralPath $CurrentRoot -Recurse -ErrorAction SilentlyContinue).FullName | ForEach-Object {

                if ( Get-Item $_ -Stream Zone.Identifier -ErrorAction SilentlyContinue )
                {
                    $ZoneCount++

                    $text = if ( $Ru ) { 'Удаление Zone.Identifier' } else { 'Removing Zone.Identifier' }
                    Write-Host "   $ZoneCount. $text`: " -ForegroundColor Cyan -NoNewline

                    Write-Host "$($_ | Split-Path -Leaf)" -ForegroundColor DarkGray
                    try { Unblock-File -LiteralPath $_ -ErrorAction SilentlyContinue } catch {}
                }
            }
        }
        catch {}

        if ( $ZoneCount )
        {
            $text = 'The Zone.Identifier blocking tags have been removed, restart the script'
        }
        else
        {
            $text = 'No blocking Zone.Identifier tags were found'
        }

        Write-Host "`n   $text" -ForegroundColor Green

        if ( $host.Name -eq 'ConsoleHost' ) { $Root = [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetDirectoryName($PSScriptRoot)) }
        try { $VersFF = [regex]::Match((Get-Content -LiteralPath $Root\Presets.txt -Encoding UTF8 -ErrorAction SilentlyContinue),
        '\s*Script-Version\s*=\s*(?<Version>[^=#\n\r]+)\s*=','IgnorePatternWhitespace').Groups.Where({$_.Name -eq 'Version'}).Value } catch {}
        Write-Host
        Write-Host '   AutoFixFiles: v.' -ForegroundColor DarkGray -NoNewline ; "$VersFF "

        try { [string] $NameOS      = [Microsoft.Win32.Registry]::GetValue('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion','ProductName',$null) } catch {}
        try { [string] $ReleaseId   = [Microsoft.Win32.Registry]::GetValue('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion','ReleaseId',$null) } catch {}
        try { [string] $DisplayVers = [Microsoft.Win32.Registry]::GetValue('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion','DisplayVersion',$null) } catch {}
        try { [string] $BuildLab    = [Microsoft.Win32.Registry]::GetValue('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion','BuildLab',$null) } catch {}

        Write-Host '          Name OS: ' -ForegroundColor DarkGray -NoNewline

        if ( $ReleaseId -and $DisplayVers ) { "$NameOS ($ReleaseId, $DisplayVers) " }
        elseif ( $ReleaseId )               { "$NameOS ($ReleaseId) " }
        else                                { "$NameOS " }

        try { [string] $VersOS = "$([System.Environment]::OSVersion.Version.ToString(3)).$([Microsoft.Win32.Registry]::GetValue('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion','UBR',$null))" } catch {}
        Write-Host   '       Version OS: ' -ForegroundColor DarkGray -NoNewline ; Write-Host   "$VersOS" -NoNewline ; Write-Host "   ($BuildLab)" -ForegroundColor DarkGray

        try { $Arch = '{0}' -f $(if ( [System.Environment]::Is64BitOperatingSystem ) { 'x64' } else { 'x86' }) } catch {}
        Write-Host   '          Arch OS: ' -ForegroundColor DarkGray -NoNewline ; "$Arch "

        try { $ArchProcess = "{0}" -f $(if ( [System.Environment]::Is64BitProcess ) { 'x64' } else { 'x86' }) } catch {}
        Write-Host   '     Arch Process: ' -ForegroundColor DarkGray -NoNewline ; "$ArchProcess "

        try { [string] $MUI = [System.Globalization.CultureInfo]::CurrentUICulture.Name } catch {}
        Write-Host   '              MUI: ' -ForegroundColor DarkGray -NoNewline ; "$MUI "
        try { [string] $DefaultMUI = [System.Globalization.CultureInfo]::InstalledUICulture.Name } catch {}
        Write-Host   '      Default MUI: ' -ForegroundColor DarkGray -NoNewline ; "$DefaultMUI "
        try { [string] $PSVers = $PSversionTable.PSVersion.ToString() } catch {}
        Write-Host   '          PS Vers: ' -ForegroundColor DarkGray -NoNewline ; "$PSVers "

        $text = 'Press any key to exit ...'
        Write-Host "`n $text" -ForegroundColor Gray

        $host.UI.RawUI.ReadKey('NoEcho, IncludeKeyDown')
        Exit
    }
}


#
Function Patch-PE
{
    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory = $false)]
        [string] $Folder = $EditFolderGlobal
       ,
        [Parameter(Mandatory = $false)]
        [string] $TempDir = $ScratchDirGlobal
       ,
        [Parameter(Mandatory = $false)]
        [switch] $NotStop
       ,
        [Parameter(Mandatory = $false)]
        [switch] $NotGetData
       ,
        [Parameter(Mandatory = $false)]
        [switch] $NotSave
    )

    Write-host
    Write-host '  Patch:' -ForegroundColor White -BackgroundColor DarkCyan -NoNewline
    Write-host ' Patch PE files' -ForegroundColor Cyan -BackgroundColor Black -NoNewline

    if ( $NotSave )
    {
        Write-host ' [Test]' -ForegroundColor DarkGray
    }
    else { Write-host }

    if ( -not $7z )
    {
        Write-host '  Patch: No $7z var, exit' -ForegroundColor DarkGray

        return
    }
    elseif ( -not $TempDir )
    {
        Write-host '  Patch: No $TempDir var, exit' -ForegroundColor DarkGray

        return
    }

    if ( -not $NotGetData )
    {
        $BoolErrorGlobal = $false
        $aWarningsGlobal = @()
        $aAttentionsGlobal = @()

        Get-Data-Preset
    }

    $Folder = $Folder -replace '\\Edit$',''

    [PSCustomObject] $dAction = @{}

    [PSCustomObject] $FileData = [PSCustomObject] @{
        Bytes    = @()
        FixCount = 0
        File     = ''
        arch     = ''
        info     = $null

        toWrites = [System.Collections.Generic.List[PSCustomObject]]@()
    }

    [System.IO.FileSystemInfo] $GetItem = $null
    [System.Diagnostics.FileVersionInfo] $FileInfo = $null
    [string[]] $Attr = @()

     [array] $aPatchUnivers = @()
     [array] $aPatchOffset = @()
    [string] $text = ''
    [string] $arch = ''

    [string] $isF = ''
    [string] $FilePath      = ''
    [string] $FilePathOrig  = ''
    [string] $ShowFileOrig  = ''
    [string] $ShowFileFound = ''
    [string] $getName       = ''
    [string] $getPath       = ''
    [string] $UnpackFile    = ''

    [System.IO.FileStream] $fileStream = $null
    [System.IO.BinaryReader] $BinaryReader = $null
    [byte[]] $bBytes = @()
    [PSCustomObject] $toWrite = @{}

    [int] $N = 0
    [int] $allCount = 0
    [int] $i        = 0

    [System.Collections.Generic.List[string]] $aUsed = @()

    foreach ( $isF in $aDataPatchGlobal.Keys )
    {
        if ( $aUsed -eq $isF ) { Continue } else { $aUsed.Add($isF) }   # ignoreCase прогон уникальных без сортировки

        $dAction = @{}

        $FilePath      = "$Folder\$isF"
        $FilePathOrig  = $FilePath
        $ShowFileOrig  = $isF
        $ShowFileFound = $isF
        $getName       = ''
        $UnpackFile    = ''
        $arch          = ''

        $N++

        if ( $N - 1 ) { Write-Host }

        Write-Host '  Patch:' -ForegroundColor Gray -BackgroundColor DarkGray -NoNewline
        Write-Host ' ' -NoNewline
        Write-Host $ShowFileOrig -ForegroundColor DarkGray -NoNewline
        Write-Host " | file: [$N] (pattern -like Last)" -ForegroundColor DarkGray

        $getName  = $FilePath -replace ('.+\\','')
        $getPath  = $FilePath -replace ('\\[^\\]+$','')
        $FilePath = ''
        try { $FilePath = ([string[]][System.IO.Directory]::EnumerateFiles($getPath, $getName))[-1] } catch {}  # Взять один последний файл (-like Last)

        if ( -not $FilePath )
        {
            Write-Host "  Patch: $FilePathOrig [not found]" -ForegroundColor DarkYellow

            #$BoolErrorGlobal = $true
            $aAttentionsGlobal += "Patch | $FilePathOrig [not found]"
            continue
        }
        else
        {
            $ShowFileFound = '{0}\{1}' -f ($isF -replace ('\\[^\\]+$','')), ($FilePath -replace ('.+\\',''))  # Замена на найденный файл для отображения
            $FilePathOrig  = $FilePath
            $isF           = $ShowFileFound
        }

        if ( $aActionsGlobal.SyncRoot )
        {
            $dAction[$ShowFileFound] = [PSCustomObject]@{
                Result = $false
                Action = 'Patch'
                Color  = 'Red'
            }

            # добавление Ссылки на переменную $dAction, изменяя $dAction, изменеяется и в $aActionsGlobal, пока существует переменная $dAction или не сброшена @{}
            $aActionsGlobal.Add($dAction) 
        }


        $GetItem = [System.IO.FileInfo]::new($FilePath)

        if ( $GetItem.Attributes -match 'readonly|hidden|system' )
        {
            $Attr = [regex]::Split($GetItem.Attributes, ',').Trim() ; $GetItem.Attributes = ( $Attr -notmatch 'readonly|hidden|system' )
        }

        $GetItem = $null

        # Unpack
        if ( $FilePath.EndsWith('_') )
        {
            $getName = $FilePath -replace ('.+\\','')
            $getName = $getName.Substring(0, $getName.Length - 1) # Удаление 1 последнего символа

            if ( @(& $7z l "$FilePathOrig" -i!"$getName`?" -aoa -bso0 -bse0 -bsp0)[-3] -match "  (?<file>$([regex]::Escape($getName))[0-9a-z])$" )
            {
                $UnpackFile = $matches.file

                $FilePath = '{0}\{1}' -f $TempDir, $UnpackFile
                $isF      = '{0}\{1}' -f $TempDir.Replace("$CurrentRoot\",''), $UnpackFile
                
                Write-Host
                Write-Host "  Patch: Unpacking: $ShowFileFound | to: $isF" -ForegroundColor DarkGray

                & $7z e $FilePathOrig -o"$TempDir" $UnpackFile -aoa -bso0 -bse0 -bsp0

                if (( $Global:LASTEXITCODE ) -or ( -not [System.IO.File]::Exists($FilePath) ))
                {
                    Write-Host "  Patch: Error: Unpack: $UnpackFile | From: $FilePathOrig" -ForegroundColor Red

                    $aWarningsGlobal += "Patch: Error: Unpack: $UnpackFile | From: $FilePathOrig"

                    $BoolErrorGlobal = $true
                    break
                }
            }
        }



        $arch = Get-PE-Arch -File $FilePath

        if ( -not $arch )
        {
            Write-Host "  Patch: Error: Get Arch (or it may be an incorrect archive) | $FilePath" -ForegroundColor Red

            $aWarningsGlobal += "Patch: Error: Get Arch (or it may be an incorrect archive) | $FilePath"

            $BoolErrorGlobal = $true
            break
        }

        try
        {
            $GetItem = [System.IO.FileInfo]::new($FilePath)

            if ( $GetItem.Attributes -match 'readonly|hidden|system' )
            {
                $Attr = [regex]::Split($GetItem.Attributes, ',').Trim() ; $GetItem.Attributes = ( $Attr -notmatch 'readonly|hidden|system' )

                $GetItem = [System.IO.FileInfo]::new($FilePath) # Если 'system' то без админа не может получить данные файла, переполучение
            }

            $FileInfo = $GetItem.VersionInfo

            $fileStream   = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
            $BinaryReader = [System.IO.BinaryReader]::new($fileStream)
            $BinaryReader.BaseStream.Position = 0

            $FileData = [PSCustomObject] @{
                Bytes    = $BinaryReader.ReadBytes($BinaryReader.BaseStream.Length)
                FixCount = 0
                File     = $isF
                arch     = $arch
                info     = [PSCustomObject] @{
                    Description    = $FileInfo.FileDescription
                    Version        = $FileInfo.FileVersionRaw
                    VersionMajor   = $FileInfo.FileMajorPart
                    VersionMinor   = $FileInfo.FileMinorPart
                    VersionBuild   = $FileInfo.FileBuildPart
                    VersionPrivate = $FileInfo.FilePrivatePart
                }
                
                toWrites = [System.Collections.Generic.List[PSCustomObject]]@()
            }

            if ( -not $FileData.Bytes.Count ) { throw }
        }
        catch
        {
            Write-Host "  Patch: Error: Get bytes (Null file or no access) [$arch]: $FilePath" -ForegroundColor Red

            Write-Host "  Patch: $($_.CategoryInfo.Category): $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "  Patch: $($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red

            $aWarningsGlobal += "Patch: Error: Get bytes (Null file or no access) [$arch]: $FilePath"

            $BoolErrorGlobal = $true
            break
        }
        finally
        {
            if ( $fileStream  ) { $fileStream.Close() }
            if ( $BinaryReader ) { $BinaryReader.Close() }
        }



        # [1] Patch-PE-Univers
        $aPatchUnivers = @($aDataPatchGlobal.$ShowFileOrig).Where({ -not [string]::IsNullOrEmpty($_.uFromHex) })
        
        $allCount = $aPatchUnivers.Count

        if ( $allCount )
        {
            $aPatchUnivers = $aPatchUnivers.Where({ $arch -match $_.arch })

            $text = @('x86','x64') -ne $arch

            if ( $aPatchUnivers.Count )
            {
                Write-Host

                $FileData = Patch-PE-Universal -FileData $FileData -aPatchUnivers $aPatchUnivers

                $allCount = $allCount - $aPatchUnivers.Count

                if ( $allCount )
                {
                    Write-Host '  Patch: ' -ForegroundColor DarkGray -NoNewline
                    Write-Host $FileData.File -ForegroundColor Cyan -NoNewline
                    Write-Host ' [Universal]' -ForegroundColor Magenta -NoNewline
                    Write-Host " | [$arch] | $($FileData.info.Version) | $($FileData.info.Description)" -ForegroundColor DarkGray

                    Write-Host "$('{0,7}' -f ' ')  [Universal] Settings for [$text] are skipped for this file | Settings: [$allCount]" -ForegroundColor DarkYellow

                    $aAttentionsGlobal += "Patch | [Universal] $($FileData.File) | Settings for [$text] are skipped for this file | Settings: [$allCount]"
                }
            }
            else
            {
                Write-Host
                Write-Host '  Patch: ' -ForegroundColor DarkGray -NoNewline
                Write-Host $FileData.File -ForegroundColor Cyan -NoNewline
                Write-Host ' [Universal]' -ForegroundColor Magenta -NoNewline
                Write-Host " | [$arch] | $($FileData.info.Version) | $($FileData.info.Description)" -ForegroundColor DarkGray

                Write-Host "$('{0,7}' -f ' ')  [Universal] For this file, the settings are for [$text] only | Settings: [$allCount]" -ForegroundColor DarkYellow
                
                $aAttentionsGlobal += "Patch | [Universal] $($FileData.File) | For this file, the settings are for [$text] only | Settings: [$allCount]"
            }
        }

        # [2] Patch-PE-Offset | [2+] Patch-PE-1337
        $aPatchOffset = @($aDataPatchGlobal.$ShowFileOrig).Where({ -not [string]::IsNullOrEmpty($_.fromHex) })

        $allCount = $aPatchOffset.Count

        if ( $allCount )
        {
            $aPatchOffset = $aPatchOffset.Where({ $arch -match $_.arch })

            $text = @('x86','x64') -ne $arch

            if ( $aPatchOffset.Count )
            {
                Write-Host

                $FileData = Patch-PE-Offset -FileData $FileData -aPatchOffset $aPatchOffset -Folder $Folder

                $allCount = $allCount - $aPatchOffset.Count

                if ( $allCount )
                {
                    Write-Host '  Patch: ' -ForegroundColor DarkGray -NoNewline
                    Write-Host $FileData.File -ForegroundColor Cyan -NoNewline
                    Write-Host ' [Offset]' -ForegroundColor Magenta -NoNewline
                    Write-Host " | [$arch] | $($FileData.info.Version) | $($FileData.info.Description)" -ForegroundColor DarkGray

                    Write-Host "$('{0,7}' -f ' ')  [Offset] Settings for [$text] are skipped for this file | Settings: [$allCount]" -ForegroundColor DarkYellow

                    $aAttentionsGlobal += "Patch | [Offset] $($FileData.File) | Settings for [$text] are skipped for this file | Settings: [$allCount]"
                }
            }
            else
            {
                Write-Host
                Write-Host '  Patch: ' -ForegroundColor DarkGray -NoNewline
                Write-Host $FileData.File -ForegroundColor Cyan -NoNewline
                Write-Host ' [Offset]' -ForegroundColor Magenta -NoNewline
                Write-Host " | [$arch] | $($FileData.info.Version) | $($FileData.info.Description)" -ForegroundColor DarkGray

                Write-Host "$('{0,7}' -f ' ')  [Offset] For this file, the settings are for [$text] only | Settings: [$allCount]" -ForegroundColor DarkYellow

                $aAttentionsGlobal += "Patch | [Offset] $($FileData.File) | For this file, the settings are for [$text] only | Settings: [$allCount]"
            }
        }



        if ( $aWarningsGlobal.Count ) { $NotSave = $true }

        # Save
        if ( -not $BoolErrorGlobal )
        {
            if ( $FileData.FixCount )
            {
                if ( -not $NotSave )
                {
                    Write-Host "$('{0,7}' -f ' ')  Saving file [$arch]: " -ForegroundColor Magenta -NoNewline
                    Write-Host $isF -ForegroundColor Cyan -NoNewline

                    # WriteBytes | Пишет только изменённые байты, а не все.
                    
                    try
                    {
                        $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write)

                        foreach ( $toWrite in $FileData.toWrites )
                        {
                            $bBytes = $toWrite.Bytes
                            $fileStream.Position = $toWrite.Offset

                            for ( $i = 0; $i -lt $bBytes.Length; $i++ ) { $fileStream.WriteByte($bBytes[$i]) }
                        }
                    }
                    catch
                    {
                        Write-Host "`n  Patch: Error: Write file: $FilePath" -ForegroundColor Red

                        Write-Host "  Patch: $($_.CategoryInfo.Category): $($_.Exception.Message)" -ForegroundColor Red
                        Write-Host "  Patch: $($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red

                        $aWarningsGlobal += "Patch: Error: Write file: $FilePath"

                        $BoolErrorGlobal = $true
                        break
                    }
                    finally
                    {
                        if ( $fileStream ) { $fileStream.Close() }
                    }

                    Write-host ' [Ok]' -ForegroundColor Green

                    Write-Host "           fix PE checksum: $isF " -ForegroundColor DarkGray -NoNewline

                    # fix PE checksum
                    try
                    {
                        & $PEChecksum "$FilePath" *>$null

                        if ( -not $? ) { throw }

                        Write-host '[Ok]' -ForegroundColor Green
                    }
                    catch
                    {
                        Write-host
                        Write-host '  Patch: ' -ForegroundColor DarkGray -NoNewline
                        Write-host $isF -ForegroundColor Red -NoNewline
                        Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                        Write-host "Attention: fix PE checksum: [$N] | $FilePath" -ForegroundColor Red

                        Write-Host "  Patch: $($_.CategoryInfo.Category): $($_.Exception.Message)" -ForegroundColor Red
                        Write-Host "  Patch: $($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red

                        $aAttentionsGlobal += "Patch | Attention: fix PE checksum: [$N] | $FilePath"
                    }

                    # pack file
                    if ( $UnpackFile )
                    {
                        Write-Host "  Patch: Packing back: $isF | to: $ShowFileFound" -ForegroundColor DarkGray

                        try
                        {
                            if ( [System.IO.File]::Exists($FilePath) )
                            {
                                Remove-Item -LiteralPath $FilePathOrig -Force -ErrorAction Stop

                                & makecab.exe /V0 /D CompressionType=MSZIP "$FilePath" "$FilePathOrig" > $null
                            }
                            else { throw }

                            if ( -not [System.IO.File]::Exists($FilePathOrig) ) { throw }
                        }
                        catch
                        {
                            Write-Host "  Patch: Error: Pack/Delete file: $FilePathOrig" -ForegroundColor Red

                            Write-Host "  Patch: $($_.CategoryInfo.Category): $($_.Exception.Message)" -ForegroundColor Red
                            Write-Host "  Patch: $($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red

                            $aWarningsGlobal += "Patch: Error: Pack/Delete file: $FilePathOrig"

                            $BoolErrorGlobal = $true
                            break
                        }
                    }

                    if ( $aActionsGlobal.SyncRoot )
                    {
                        $dAction[$ShowFileFound] = [PSCustomObject]@{
                            Result = $true
                            Action = '[Patch: changes: {0}]' -f $FileData.FixCount
                            Color  = 'Magenta'
                        }
                    }
                }
                else
                {
                    Write-Host "$('{0,7}' -f ' ')  [Test] [Skip] saving file [$arch]: $ShowFileFound" -ForegroundColor DarkGray

                    $aWarningsGlobal += "Patch: [Test] [Skip] saving file [$arch]: $ShowFileFound"

                    if ( $aActionsGlobal.SyncRoot )
                    {
                        $dAction[$ShowFileFound] = [PSCustomObject]@{
                            Result = $true
                            Action = '[Patch: Test]'
                            Color  = 'DarkGray'
                        }
                    }
                }
            }
            else
            {
                if ( $NotSave )
                {
                    Write-Host "$('{0,7}' -f ' ')  [Test] [No change] [Skip] saving file [$arch]: $ShowFileFound" -ForegroundColor DarkGray

                    $aWarningsGlobal += "Patch: [Test] [No change] [Skip] saving file [$arch]: $ShowFileFound"

                    if ( $aActionsGlobal.SyncRoot )
                    {
                        $dAction[$ShowFileFound] = [PSCustomObject]@{
                            Result = $true
                            Action = '[Patch: Test, No change]' -f $text
                            Color  = 'DarkGray'
                        }
                    }
                }
                else
                {
                    Write-Host "$('{0,7}' -f ' ')  [No chang] [Skip] saving file [$arch]: $ShowFileFound" -ForegroundColor DarkGray
                    
                    if ( $aActionsGlobal.SyncRoot )
                    {
                        $dAction[$ShowFileFound] = [PSCustomObject]@{
                            Result = $true
                            Action = '[Patch: Ok, No change]'
                            Color  = 'DarkGray'
                        }
                    }
                }
            }
        }
        else
        {
            Write-Host '  Patch: [Skip] saving all files [was an error]' -ForegroundColor DarkGray
        }

        try
        {
            if ( $UnpackFile -and [System.IO.File]::Exists($FilePath) )
            {
                Remove-Item -LiteralPath $FilePath -Force -ErrorAction Stop
            }
        }
        catch
        {
            Write-Host "  Patch: Error: Delete file: $FilePath" -ForegroundColor Red

            Write-Host "  Patch: $($_.CategoryInfo.Category): $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "  Patch: $($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red

            $aWarningsGlobal += "Patch: Error: Delete file: $FilePath"

            $BoolErrorGlobal = $true
            break
        }
    }

    if ( $aWarningsGlobal.Count ) { $BoolErrorGlobal = $true }

    if ( -not $aDataPatchGlobal.Keys.Count )
    {
        Write-host '  Patch: preset is not configured (Patch-PE-*)' -ForegroundColor DarkGray
    }

    if ( -not $NotStop )
    {
        Get-Pause
    }
}

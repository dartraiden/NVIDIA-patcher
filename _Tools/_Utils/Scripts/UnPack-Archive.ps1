
#
Function UnPack-Archive {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject] $ArchiveData = $dUnPackOrFolderGlobal
       ,
        [Parameter(Mandatory = $false)]
        [string] $CurrentRoot = $CurrentRoot
       ,
        [Parameter(Mandatory = $false)]
        [switch] $NotStop
       ,
        [Parameter(Mandatory = $false)]
        [switch] $NotGetData
    )

    Write-host
    Write-host ' UnPack:' -ForegroundColor White -BackgroundColor DarkCyan -NoNewline
    Write-host ' Unpack archive file' -ForegroundColor Cyan

    if ( -not $NotGetData )
    {
        $BoolErrorGlobal = $false
        $aWarningsGlobal = @()
        $aAttentionsGlobal = @()

        Get-Data-Preset

        $ArchiveData = $dUnPackOrFolderGlobal
    }

    [PSCustomObject] $dAction = @{}
  
    [string] $File         = ''

    [string] $unPack       = ''
    [string] $unPackShow   = ''

    [string] $toFolder     = ''
    [string] $toFolderShow = ''

    [string] $only         = ''
    [string] $excludes     = ''

    # UnPack or Folder
    if ( $ArchiveData.File )
    {
        if ( $ArchiveData.getName )
        {
            if ( $ArchiveData.UnPack )
            {
                $unPack   = $ArchiveData.UnPack
                $toFolder = $ArchiveData.toFolder

                $unPackShow   = $unPack.Replace("$CurrentRoot\",'')
                $toFolderShow = $toFolder.Replace("$CurrentRoot\",'')

                Write-host ' UnPack: Archive: ' -ForegroundColor DarkGray -NoNewline
                Write-host $unPackShow -ForegroundColor Blue
                
                Write-host '       to Folder: ' -ForegroundColor DarkGray -NoNewline
                Write-host $toFolderShow -ForegroundColor Blue -NoNewline

                # удаление папки
                if ( [System.IO.Directory]::Exists($toFolder) )
                {
                    Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                    Write-host '[exist]' -ForegroundColor DarkGreen -NoNewline
                    Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                    Write-host 'Delete: ' -ForegroundColor DarkCyan -NoNewline

                    # rmdir удаляет все типы файлов с любыми атрибутами без проблем: symbolic, junction, .lnk и т.д., Для командлетов powershell или .NET нужно больше действий.
                    & 'cmd.exe' /d /q /c rmdir /s /q "$toFolder" *>$null

                    if ( [System.IO.Directory]::Exists($toFolder) )
                    {
                        Write-host '[error]' -ForegroundColor Red
                        Write-host ' UnPack: ' -ForegroundColor DarkGray -NoNewline
                        Write-host 'Error: Delete Folder: ' -ForegroundColor Red -NoNewline
                        Write-host $toFolder -ForegroundColor Red

                        $aWarningsGlobal += "UnPack: Error: Delete Folder: $toFolder"

                        $BoolErrorGlobal = $true
                    }
                    else
                    {
                        Write-host '[Ok]' -ForegroundColor Green
                    }
                }
                else
                {
                    Write-host ' | [folder not exist]' -ForegroundColor DarkGray
                }

                if ( -not $BoolErrorGlobal )
                {
                    if ( $ArchiveData.onlyInclude.Count )  
                    {
                        Write-host '    only Include: ' -ForegroundColor DarkGray -NoNewline
                        Write-host $('"{0}"' -f [string]::Join('", "', $ArchiveData.onlyInclude)) -ForegroundColor White

                        $only = '-i!"{0}"' -f [string]::Join('" -i!"', $ArchiveData.onlyInclude)
                    }
                    else
                    {
                        Write-host '    only Include: --- [all]' -ForegroundColor DarkGray

                        $only = '-i!"*"'  # * = includes all folder and files
                    }

                    if ( $ArchiveData.excludes.Count )  
                    {
                        foreach ( $File in $ArchiveData.excludes )
                        {
                            Write-host '         Exclude: ' -ForegroundColor DarkGray -NoNewline
                            Write-host '"' -ForegroundColor White -NoNewline
                            Write-host $File -ForegroundColor Magenta -NoNewline
                            Write-host '"' -ForegroundColor White
                        }

                        $excludes = ' -x!"{0}"' -f [string]::Join('" -x!"', $ArchiveData.excludes)
                    }
                    else
                    {
                        Write-host '         Exclude: --- [no exclude]' -ForegroundColor DarkGray
                    }

                    Write-host '         command: ' -ForegroundColor DarkGray -NoNewline
                    Write-host "7z x ... $only$excludes`n`n`n" -ForegroundColor DarkCyan

                    [console]::CursorVisible = $false
                    [console]::SetCursorPosition(0, [console]::CursorTop - 3)

                    [scriptblock] $scriptblock = [scriptblock]::Create("& ""$7z"" x -y -aoa -bso0 -bse0 -bsp1 ""$unPack"" -o""$toFolder"" $only$excludes")
                    & $scriptblock

                    [console]::CursorVisible = $true

                    if (( $Global:LastExitCode ) -or ( -not [System.IO.Directory]::Exists($toFolder) ))
                    {
                        Write-host ' UnPack: ' -ForegroundColor DarkGray -NoNewline
                        Write-host 'Error: UnPack Archive: ' -ForegroundColor Red -NoNewline
                        Write-host $unPack -ForegroundColor Red
                        Write-host ' UnPack: ' -ForegroundColor DarkGray -NoNewline
                        Write-host 'No files/folders matched the extract pattern' -ForegroundColor Yellow

                        $aWarningsGlobal += "UnPack: Error: UnPack Archive (pattern?): $unPack"

                        $BoolErrorGlobal = $true
                    }
                    else
                    {
                        Write-host ' UnPack: Archive: ' -ForegroundColor DarkGray -NoNewline
                        Write-host '[Ok]' -ForegroundColor Green -NoNewline
                        Write-host ' [folder exist]' -ForegroundColor DarkGreen

                        if ( $aActionsGlobal.SyncRoot )
                        {
                            $dAction[$unPackShow] = [PSCustomObject]@{
                                Result = $true
                                Action = '[UnPack: to: {0}]' -f $toFolderShow
                                Color  = 'DarkGray'
                            }

                            # добавление Ссылки на переменную $dAction, изменяя $dAction, изменеяется и в $aActionsGlobal, пока существует переменная $dAction или не сброшена @{}
                            $aActionsGlobal.Add($dAction) 
                        }
                    }
                }
            }
            else
            {
                Write-host ' UnPack: ' -ForegroundColor DarkGray -NoNewline
                Write-host '[folder exist]: ' -ForegroundColor Green -NoNewline
                Write-host ($ArchiveData.toFolder.Replace("$CurrentRoot\",'')) -ForegroundColor Blue -NoNewline
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-host '[Archive not found]: ' -ForegroundColor DarkYellow -NoNewline
                Write-host $ArchiveData.File -ForegroundColor DarkCyan

                $aAttentionsGlobal += "UnPack: [folder exist]: $($ArchiveData.toFolder.Replace("$CurrentRoot\",'')) | [Archive not found]: $($ArchiveData.File)"
            }
        }
        else
        {
            Write-host ' UnPack: ' -ForegroundColor DarkGray -NoNewline
            Write-host '[Archive not found]: ' -ForegroundColor Red -NoNewline
            Write-host $ArchiveData.File -ForegroundColor DarkCyan

            $aWarningsGlobal += "UnPack: Error: [Archive not found]: $($ArchiveData.File)"

            $BoolErrorGlobal = $true
        }
    }
    else
    {
        Write-host ' UnPack: preset is not configured (UnPack-or-Folder)' -ForegroundColor DarkGray
    }

    if ( -not $NotStop )
    {
        Get-Pause
    }

    Return
}

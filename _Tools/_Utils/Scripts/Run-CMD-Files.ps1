
#
Function Run-CMD-Files {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory = $false)]
        [string] $Folder = $EditFolderGlobal
       ,
        [Parameter(Mandatory = $false)]
        [switch] $NotStop
       ,
        [Parameter(Mandatory = $false)]
        [switch] $NotGetData
       ,
        [Parameter(Mandatory = $false)]
        [switch] $Final
    )

    $Folder = $Folder -replace '\\Edit$',''

    if ( -not $NotGetData )
    {
        $BoolErrorGlobal = $false
        $aWarningsGlobal = @()
        $aAttentionsGlobal = @()

        Get-Data-Preset
    }

    [PSCustomObject] $dAction = @{}

    if ( -not $Final )
    {
        Write-host
        Write-host '    cmd:' -ForegroundColor White -BackgroundColor DarkCyan -NoNewline
        Write-host ' Run cmd/bat files (at the beginning)' -ForegroundColor Cyan

        [int] $N = 0

        foreach ( $CMD in $aDataCMDfilesGlobal )
        {
            $N++

            $dAction = @{}

            $CmdFile = '{0}\{1}' -f $Folder, $CMD

            if ( [System.IO.File]::Exists($CmdFile) )
            {
                Write-host '    cmd: ' -ForegroundColor DarkGray -NoNewline
                Write-host $CMD -ForegroundColor White

                try { & "$env:SystemDrive\Windows\system32\cmd.exe" /c "$CmdFile" 2>&1 } catch { $Global:LastExitCode = 1 }

                if ( $aActionsGlobal.SyncRoot )
                {
                    if ( -not $Global:LastExitCode )
                    {
                        $dAction[$CMD] = [PSCustomObject]@{
                            Result = $true
                            Action = '[cmd]'
                            Color  = 'DarkGray'
                        }

                        $aActionsGlobal.Add($dAction)
                    }
                    else
                    {
                        Write-host
                        Write-host '    cmd: Run Error: ' -ForegroundColor DarkGray -NoNewline
                        Write-host $CMD -ForegroundColor Red

                        $aWarningsGlobal += "cmd: Run Error: $CMD"

                        $BoolErrorGlobal = $true
                    }
                }
            }
            else
            {
                Write-host '    cmd: ' -ForegroundColor DarkGray -NoNewline
                Write-host $CMD -ForegroundColor Red -NoNewline
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-host 'File not found' -ForegroundColor Red

                $aWarningsGlobal += "cmd: $CMD | File not found"

                $BoolErrorGlobal = $true
            }
        }

        if ( -not $N )
        {
            Write-host '    cmd: ' -ForegroundColor DarkGray -NoNewline
            Write-host 'Preset is not configured (Run-CMD-File)' -ForegroundColor DarkGray
        }
    }
    else
    {
        Write-host
        Write-host '    cmd:' -ForegroundColor White -BackgroundColor DarkCyan -NoNewline
        Write-host ' Run cmd/bat files (Final)' -ForegroundColor Cyan

        [int] $N = 0

        foreach ( $CMD in $aDataCMDfilesFinalGlobal )
        {
            $N++

            $dAction = @{}

            $CmdFile = '{0}\{1}' -f $Folder, $CMD

            if ( [System.IO.File]::Exists($CmdFile) )
            {
                Write-host '    cmd: ' -ForegroundColor DarkGray -NoNewline
                Write-host $CMD -ForegroundColor White

                try { & "$env:SystemDrive\Windows\system32\cmd.exe" /c "$CmdFile" 2>&1 } catch { $Global:LastExitCode = 1 }

                if ( $aActionsGlobal.SyncRoot )
                {
                    if ( -not $Global:LastExitCode )
                    {
                        $dAction[$CMD] = [PSCustomObject]@{
                            Result = $true
                            Action = '[cmd: Final]'
                            Color  = 'DarkGray'
                        }

                        # добавление Ссылки на переменную $dAction, изменяя $dAction, изменеяется и в $aActionsGlobal, пока существует переменная $dAction или не сброшена @{}
                        $aActionsGlobal.Add($dAction) 
                    }
                    else
                    {
                        Write-host
                        Write-host '    cmd: Final Run Error: ' -ForegroundColor DarkGray -NoNewline
                        Write-host $CMD -ForegroundColor Red

                        $aWarningsGlobal += "cmd: Final Run Error: $CMD"

                        $BoolErrorGlobal = $true
                    }
                }
            }
            else
            {
                Write-host '    cmd: Final: ' -ForegroundColor DarkGray -NoNewline
                Write-host $CMD -ForegroundColor Red -NoNewline
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-host 'File not found' -ForegroundColor Red

                $aWarningsGlobal += "cmd: Final: $CMD | File not found"

                $BoolErrorGlobal = $true
            }
        }

        if ( -not $N )
        {
            Write-host '    cmd: ' -ForegroundColor DarkGray -NoNewline
            Write-host 'Preset is not configured (Run-CMD-File-Final)' -ForegroundColor DarkGray
        }
    }

    if ( -not $NotStop )
    {
        Get-Pause
    }
}




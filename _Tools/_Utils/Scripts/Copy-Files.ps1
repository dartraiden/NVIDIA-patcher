
#
Function Copy-Files {

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
    )

    Write-host
    Write-host '   Copy:' -ForegroundColor White -BackgroundColor DarkCyan -NoNewline
    Write-host ' Copy files' -ForegroundColor Cyan

    [string] $Folder = $Folder -replace '\\Edit$',''

    if ( -not $NotGetData )
    {
        $BoolErrorGlobal = $false
        $aWarningsGlobal = @()
        $aAttentionsGlobal = @()

        Get-Data-Preset
    }

    [PSCustomObject] $dAction = @{}

    [PSCustomObject] $dCopy = ''

    [string] $File     = ''
    [string] $CoptTo   = ''
    [string] $FilePath = ''
    [string] $getName  = ''
    
    [System.IO.FileSystemInfo] $GetItem = $null
    [string[]] $Attr = @()

    [int] $N  = 0

    foreach ( $dCopy in $aDataCopyFilesGlobal )
    {
        Write-host '   Copy: ' -ForegroundColor DarkGray -NoNewline
        Write-host $dCopy.File -ForegroundColor White -NoNewline
        Write-host ' ◄ ' -ForegroundColor DarkGray -NoNewline
        Write-host 'Checking file (equal)' -ForegroundColor DarkGray

        $N++

        $dAction = @{}

        $File   = "$Folder\{0}" -f $dCopy.File
        $CoptTo = "$Folder\{0}" -f $dCopy.CopyTo

        if ( [System.IO.File]::Exists($File) )
        {
            Write-host '   Copy: ' -ForegroundColor DarkGray -NoNewline
            Write-host $dCopy.File -ForegroundColor Magenta -NoNewline
            Write-host ' | to: ' -ForegroundColor DarkGray -NoNewline
            Write-host $dCopy.CopyTo -ForegroundColor White -NoNewline
            Write-host ' ◄ ' -ForegroundColor DarkGreen -NoNewline
            Write-host 'file exist, Copying' -ForegroundColor DarkGreen -NoNewline

            if ( [System.IO.Directory]::Exists($CoptTo) )
            {
                try
                {
                    $getName  = $File -replace ('.+\\','')
                    $FilePath = "$CoptTo\$getName"

                    $GetItem = [System.IO.FileInfo]::new($FilePath)

                    if ( $GetItem.Attributes -match 'readonly|hidden|system' )
                    {
                        $Attr = [regex]::Split($GetItem.Attributes, ',').Trim() ; $GetItem.Attributes = ( $Attr -notmatch 'readonly|hidden|system' )
                    }

                    $GetItem = $null

                    Copy-Item -LiteralPath $File -Destination $CoptTo -Force -ErrorAction Stop

                    if ( $aActionsGlobal.SyncRoot )
                    {
                        $dAction[$dCopy.File] = [PSCustomObject]@{
                            Result = $true
                            Action = '[Copy: to: {0}]' -f $dCopy.CopyTo
                            Color  = 'DarkGray'
                        }

                        # добавление Ссылки на переменную $dAction, изменяя $dAction, изменеяется и в $aActionsGlobal, пока существует переменная $dAction или не сброшена @{}
                        $aActionsGlobal.Add($dAction) 
                    }

                    Write-host ' [Ok]' -ForegroundColor Green
                }
                catch
                {
                    Write-host
                    Write-host '   Copy: ' -ForegroundColor DarkGray -NoNewline
                    Write-host $dCopy.File -ForegroundColor Red -NoNewline
                    Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                    Write-host 'Error: Copying a file' -ForegroundColor Red

                    Write-Host "   Copy: $($_.CategoryInfo.Category): $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "   Copy: $($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red

                    $aWarningsGlobal += "Copy: Error: Copying a file: $File"

                    $BoolErrorGlobal = $true

                    break
                }
            }
            else
            {
                Write-host '   Copy: ' -ForegroundColor DarkGray -NoNewline
                Write-host $dCopy.File -ForegroundColor Red -NoNewline
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-host 'Error: No destination folder: ' -ForegroundColor Red -NoNewline
                Write-host $CoptTo -ForegroundColor DarkGray

                $aWarningsGlobal += "Copy: Error: Error: No destination folder: $CoptTo"

                $BoolErrorGlobal = $true

                break
            }
        }
        else
        {
            Write-host '   Copy: ' -ForegroundColor DarkGray -NoNewline
            Write-host $dCopy.File -ForegroundColor DarkYellow -NoNewline
            Write-host ' | ' -ForegroundColor DarkGray -NoNewline
            Write-host 'File not exist' -ForegroundColor DarkYellow

            $aAttentionsGlobal += "Copy  | $($dCopy.File) | File not exist"
        }
    }

    if ( -not $N )
    {
        Write-host '   Copy: ' -ForegroundColor DarkGray -NoNewline
        Write-host 'preset is not configured (Copy-File)' -ForegroundColor DarkGray
    }

    if ( -not $NotStop )
    {
        Get-Pause
    }

    Return
}

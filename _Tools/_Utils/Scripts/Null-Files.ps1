
#
Function Null-Files {

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
    Write-host '   Null:' -ForegroundColor White -BackgroundColor DarkCyan -NoNewline
    Write-host ' Null files' -ForegroundColor Cyan

    [string] $Folder = $Folder -replace '\\Edit$',''

    if ( -not $NotGetData )
    {
        $BoolErrorGlobal = $false
        $aWarningsGlobal = @()
        $aAttentionsGlobal = @()

        Get-Data-Preset
    }

    [PSCustomObject] $dAction = @{}

    [string] $isF = ''
    [string] $FilePath  = ''
    [string] $ShowFound = ''

    [string] $getName = ''
    [string] $getPath = ''

    [System.IO.FileSystemInfo] $GetItem = $isFl
    [string[]] $Attr = @()

    [int] $N = 0

    foreach ( $isF in $aDataNullFilesGlobal )
    {
        Write-host '   Null: ' -ForegroundColor DarkGray -NoNewline
        Write-host $isF -ForegroundColor White -NoNewline
        Write-host ' ◄ ' -ForegroundColor DarkGray -NoNewline
        Write-host 'Name pattern (-like Last)' -ForegroundColor DarkGray

        $N++

        $dAction = @{}

        $FilePath = ''
        $getName  = $isF -replace ('.+\\','')
        $getPath  = "$Folder\$isF" -replace ('\\[^\\]+$','')

        try { $FilePath = ([string[]][System.IO.Directory]::EnumerateFiles($getPath, $getName))[-1] } catch {}  # Взять один последний файл (-like Last)

        if ( $FilePath )
        {
            $ShowFound = $FilePath.Replace("$Folder\",'')

            Write-host '   Null: ' -ForegroundColor DarkGray -NoNewline
            Write-host $ShowFound -ForegroundColor Magenta -NoNewline
            Write-host ' ◄ ' -ForegroundColor DarkGreen -NoNewline
            Write-host 'found, Nulling file' -ForegroundColor DarkGreen -NoNewline

            try
            {
                $GetItem = [System.IO.FileInfo]::new($FilePath)

                if ( $GetItem.Attributes -match 'readonly|hidden|system' )
                {
                    $Attr = [regex]::Split($GetItem.Attributes, ',').Trim() ; $GetItem.Attributes = ( $Attr -notmatch 'readonly|hidden|system' )
                }

                $GetItem = $null

                [System.IO.File]::WriteAllBytes($FilePath, @())

                if ( $aActionsGlobal.SyncRoot )
                {
                    $dAction[$ShowFound] = [PSCustomObject]@{
                        Result = $true
                        Action = '[Null]'
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
                Write-host '   Null: ' -ForegroundColor DarkGray -NoNewline
                Write-host $ShowFound -ForegroundColor Red -NoNewline
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-host 'Error: Nulling file' -ForegroundColor Red

                Write-Host "   Null: $($_.CategoryInfo.Category): $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "   Null: $($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red

                $aWarningsGlobal += "Null: Error: Nulling file: $FilePath"

                $BoolErrorGlobal = $true

                break
            }
        }
        else
        {
            Write-host '   Null: ' -ForegroundColor DarkGray -NoNewline
            Write-host $isF -ForegroundColor DarkYellow -NoNewline
            Write-host ' | ' -ForegroundColor DarkGray -NoNewline
            Write-host 'File not found' -ForegroundColor DarkYellow

            $aAttentionsGlobal += "Null  | $isF | File not found"
        }
    }

    if ( -not $N )
    {
        Write-host '   Null: ' -ForegroundColor DarkGray -NoNewline
        Write-host 'preset is not configured (Null-File)' -ForegroundColor DarkGray
    }

    if ( -not $NotStop )
    {
        Get-Pause
    }

    Return
}

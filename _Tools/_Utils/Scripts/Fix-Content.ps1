
#
Function Fix-Content
{
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
        [switch] $NotSave
    )

    Write-host
    Write-host '    Fix:' -ForegroundColor White -BackgroundColor DarkCyan -NoNewline
    Write-host ' Modify text files' -ForegroundColor Cyan -NoNewline

    if ( $NotSave )
    {
        Write-host ' [Test]' -ForegroundColor DarkGray
    }
    else { Write-host }

    if ( -not $NotGetData )
    {
        $BoolErrorGlobal = $false
        $aWarningsGlobal = @()
        $aAttentionsGlobal = @()

        Get-Data-Preset
    }

    $Folder = $Folder -replace '\\Edit$',''

    [PSCustomObject] $dAction = @{}

    [PSCustomObject] $ContentData = [PSCustomObject] @{
        Content  = @()
        FixCount = 0
        File     = ''
    }

    [string] $isF = ''
    [string] $ShowFile = ''
    [string] $FilePath = ''

    [string] $getName  = ''
    [string] $getPath  = ''

    [string] $removeString = ''
    [System.Collections.Generic.List[string]] $aRemoveStrings = @()
    [array] $aTextReplace     = @()
    [array] $aAddStringsToInf = @()
    [array] $aAddDevIDtoInf   = @()
    [array] $aRemoveAllText   = @()

    [System.Text.Encoding] $Enc = [System.Text.UTF8Encoding]::new($false)
    [System.Collections.Generic.List[string]] $aUsed = @()

    [System.IO.FileSystemInfo] $GetItem = $null
    [string[]] $Attr = @()

    [int] $N = 0

    foreach ( $isF in $aDataContentFixGlobal.Keys )
    {
        if ( $aUsed -eq $isF ) { Continue } else { $aUsed.Add($isF) }   # ignoreCase прогон уникальных без сортировки

        $N++ 

        $dAction = @{}

        if ( $N - 1 ) { Write-Host }

        Write-Host '    Fix:' -ForegroundColor Gray -BackgroundColor DarkGray -NoNewline
        Write-Host ' ' -BackgroundColor Black -NoNewline
        Write-Host $isF -ForegroundColor DarkGray -NoNewline
        Write-Host " | file: [$N] (pattern -like Last)" -ForegroundColor DarkGray

        $FilePath = "$Folder\$isF"

        $getName  = $FilePath -replace ('.+\\','')
        $getPath  = $FilePath -replace ('\\[^\\]+$','')
        $FilePath = ''
        try { $FilePath = ([string[]][System.IO.Directory]::EnumerateFiles($getPath, $getName))[-1] } catch {}  # Взять один последний файл (-like Last)

        if ( -not $FilePath )
        {
            Write-Host "    Fix: $FilePath [not found]" -ForegroundColor DarkYellow

            #$BoolErrorGlobal = $true
            $aAttentionsGlobal += "Fix   | $FilePath [not found]"
            continue
        }

        $ShowFile = '{0}\{1}' -f ($isF -replace ('\\[^\\]+$','')), ($FilePath -replace ('.+\\',''))  # Замена на найденный файл для отображения


        if ( $aActionsGlobal.SyncRoot )
        {
            $dAction[$ShowFile] = [PSCustomObject]@{
                Result = $false
                Action = 'Fix'
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

        $Enc = Get-Encoding -EncName @($aDataContentFixGlobal.$isF.Encoding)[0]

        if ( $BoolErrorGlobal ) { break }

        $ContentData = [PSCustomObject] @{
            Content  = [System.IO.File]::ReadAllLines($FilePath, $Enc)
            FixCount = 0
            File     = $ShowFile
        }


        # [1] Remove Strings
        $aRemoveStrings = @()
        foreach ( $removeString in $aDataContentFixGlobal.$isF.removeString )
        {
            if ( -not ( $aRemoveStrings -eq $removeString )) { $aRemoveStrings.Add($removeString) } # Только уникальные без сортировки
        }

        if ( $aRemoveStrings.Count )
        {
            $ContentData = Content-Remove-Strings -ContentData $ContentData -aRemoveStrings $aRemoveStrings
        }



        # [2] Text Replace
        $aTextReplace = @($aDataContentFixGlobal.$isF).Where({ -not [string]::IsNullOrEmpty($_.ifString) })

        if ( $aTextReplace.Count )
        {
            $ContentData = Content-Text-Replace -ContentData $ContentData -aTextReplace $aTextReplace
        }



        # [3] Add strings to Inf + [3+] Add DevID to Inf
        $aAddStringsToInf = @($aDataContentFixGlobal.$isF).Where({ -not [string]::IsNullOrEmpty($_.toSectionInf) })
        $aAddDevIDtoInf   = @($aDataContentFixGlobal.$isF).Where({ -not [string]::IsNullOrEmpty($_.addDevIDtoInf) })

        if ( $aAddStringsToInf.Count -or $aAddDevIDtoInf.Count )
        {
            $ContentData = Content-Add-To-INF -ContentData $ContentData -aAddStringsToInf $aAddStringsToInf -aAddDevIDtoInf $aAddDevIDtoInf
        }



        # [4] Remove All Text
        $aRemoveAllText = $aDataContentFixGlobal.$isF.removeAllText

        if ( $aRemoveAllText.Count )
        {
            $ContentData = Content-Remove-All-Text -ContentData $ContentData -aRemoveAllText $aRemoveAllText
        }


        # Save
        if ( -not $BoolErrorGlobal )
        {
            if ( $ContentData.FixCount )
            {
                if ( $Enc.GetPreamble().Count ) { [string] $Bom = '+bom' } else { [string] $Bom = 'No bom' }

                if ( -not $NotSave )
                {
                    Write-Host "$('{0,7}' -f ' ')  Saving file [$($Enc.BodyName), $Bom ($($Enc.CodePage))]: " -ForegroundColor Magenta -NoNewline
                    Write-Host $ShowFile -ForegroundColor Cyan

                    try { [System.IO.File]::WriteAllText($FilePath, ([string]::Join("`r`n", $ContentData.Content) + "`r`n"), $Enc) }
                    catch
                    {
                        Write-Host "    Fix: Error: Write file: $FilePath" -ForegroundColor Red

                        Write-Host "    Fix: $($_.CategoryInfo.Category): $($_.Exception.Message)" -ForegroundColor Red
                        Write-Host "    Fix: $($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red
  
                        $aWarningsGlobal += "Fix: Error: Write file: $FilePath"

                        $BoolErrorGlobal = $true
                        break
                    }

                    if ( $aActionsGlobal.SyncRoot )
                    {
                        $dAction[$ShowFile] = [PSCustomObject]@{
                            Result = $true
                            Action = '[Fix: changes: {0}]' -f $ContentData.FixCount
                            Color  = 'DarkCyan'
                        }
                    }
                }
                else
                {
                    Write-Host "$('{0,7}' -f ' ')  [Test] [Skip] Saving file [$($Enc.BodyName), $Bom ($($Enc.CodePage))]: $ShowFile" -ForegroundColor DarkGray
                }
            }
            else
            {
                if ( $NotSave )
                {
                    Write-Host "$('{0,7}' -f ' ')  [Test] [No change] [Skip] saving file: $ShowFile" -ForegroundColor DarkGray

                    if ( $aActionsGlobal.SyncRoot )
                    {
                        $dAction[$ShowFile] = [PSCustomObject]@{
                            Result = $true
                            Action = '[Fix: Test, No change]'
                            Color  = 'DarkGray'
                        }
                    }
                }
                else
                {
                    Write-Host "$('{0,7}' -f ' ')  [No change] [Skip] saving file: $ShowFile" -ForegroundColor DarkGray

                    if ( $aActionsGlobal.SyncRoot )
                    {
                        $dAction[$ShowFile] = [PSCustomObject]@{
                            Result = $true
                            Action = '[Fix: Ok, No change]'
                            Color  = 'DarkGray'
                        }
                    }
                }
            }
        }
        else
        {
            Write-Host '    Fix: [Skip] saving all files [was an error]' -ForegroundColor DarkGray
        }
    }

    if ( -not $aDataContentFixGlobal.Keys.Count )
    {
        Write-host '    Fix: preset is not configured (Fix-*)' -ForegroundColor DarkGray
    }

    if ( -not $NotStop )
    {
        Get-Pause
    }
}


# Удаление строк построчно, согласно шаблону -match
Function Content-Remove-All-Text ( [PSCustomObject] $ContentData, [array] $aRemoveAllText )
{
    Write-Host "`n    Fix: " -ForegroundColor DarkGray -NoNewline
    Write-Host $ContentData.File -ForegroundColor Cyan -NoNewline
    Write-Host ' [Remove All Text]:' -ForegroundColor Blue

     [int64] $N = 0
     [int64] $FixCount = $ContentData.FixCount
    [string] $Content  = [string]::Join("`r`n", $ContentData.Content)

    [string] $Group = ''

    if ( $aRemoveAllText.Count )
    {
        foreach ( $removeAllText in $aRemoveAllText )
        {
            try { $null = [regex]::new($removeAllText) }
            catch
            {
                Write-Host "    Fix: [Remove All Text] Error match pattern ""all Text"": $removeAllText | File: $($ContentData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Fix: [Remove All Text] Error match pattern ""all Text"": $removeAllText | File: $($ContentData.File)"

                $BoolErrorGlobal = $true

                break
            }

            if ( $removeAllText -and ( $Content -match $removeAllText ))
            {
                $N++

                Write-Host "$('{0,7}' -f ++$FixCount): match 'all Text': " -ForegroundColor DarkGray -NoNewline
                Write-Host $removeAllText -ForegroundColor DarkBlue

                if ( $Group = [regex]::Match($removeAllText,'\(\?\<(?<Name>[a-zA-Z][a-zA-Z0-9]*)>').Groups['Name'].Value )
                {
                    $Content = $Content.replace($matches[$Group], '')
                }
                else
                {
                    $Content = $Content.replace($matches[0], '')
                }
            }
        }
    }

    if ( -not $BoolErrorGlobal )
    {
        if ( -not $N )
        {
            Write-Host "$('{0,7}' -f '--'): No match 'all Text' in all settings: " -ForegroundColor DarkGray -NoNewline
            Write-Host $aRemoveAllText.Count -ForegroundColor Gray
        }
        else
        {
            $ContentData.FixCount = $FixCount
            $ContentData.Content  = $Content
        }
    }

    Return $ContentData
}

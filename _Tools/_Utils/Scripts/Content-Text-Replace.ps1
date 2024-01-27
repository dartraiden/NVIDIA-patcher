
# Удаление строк построчно, согласно шаблону -match
Function Content-Text-Replace ( [PSCustomObject] $ContentData, [array] $aTextReplace )
{
    Write-Host "`n    Fix: " -ForegroundColor DarkGray -NoNewline
    Write-Host $ContentData.File -ForegroundColor Cyan -NoNewline
    Write-Host ' [Text replace]:' -ForegroundColor DarkCyan

    [int64] $N = 0
    [int64] $FixCount = $ContentData.FixCount
    [array] $Content  = $ContentData.Content

    [string] $LineCurrent = ''
    [string] $Group       = ''

    if ( $aTextReplace.Count )
    {
        foreach ( $R in $aTextReplace )
        {
            try { $null = [regex]::new($R.ifString) }
            catch
            {
                Write-Host "    Fix: [Text replace] Error match pattern ""if String"": $($R.ifString) | File: $($ContentData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Fix: [Text replace] Error match pattern ""if String"": $($R.ifString) | File: $($ContentData.File)"

                $BoolErrorGlobal = $true

                break
            }

            try { $null = [regex]::new($R.fromText) }
            catch
            {
                Write-Host "    Fix: [Text replace] Error match pattern ""from Text"": $($R.fromText) | File: $($ContentData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Fix: [Text replace] Error match pattern ""from Text"": $($R.fromText) | File: $($ContentData.File)"

                $BoolErrorGlobal = $true

                break
            }
        }

        if ( -not $BoolErrorGlobal )
        {
            $Content = $(

                foreach ( $Line in $Content )
                {
                    $LineCurrent = $Line

                    foreach ( $R in $aTextReplace )
                    {
                        if ( $R.ifString -and ( $Line -match $R.ifString ))
                        {
                            if ( $R.fromText -and ( $LineCurrent -match $R.fromText ))
                            {
                                $N++

                                if ( $Group = [regex]::Match($R.fromText,'\(\?\<(?<Name>[a-zA-Z][a-zA-Z0-9]*)>').Groups['Name'].Value )
                                {
                                    $LineCurrent = $LineCurrent.replace($matches[$Group], $R.toText)
                                }
                                else
                                {
                                    $LineCurrent = $LineCurrent.replace($matches[0], $R.toText)
                                }

                                Write-Host "$('{0,7}' -f ++$FixCount): ifString: " -ForegroundColor DarkGray -NoNewline
                                Write-Host $R.ifString -ForegroundColor DarkCyan -NoNewline
                                Write-Host ' | fromText: ' -ForegroundColor DarkGray -NoNewline
                                Write-Host $R.fromText -ForegroundColor White -NoNewline
                                Write-Host ' | toText: ' -ForegroundColor DarkGray -NoNewline
                                Write-Host $R.toText -ForegroundColor Magenta -NoNewline

                                if ( $LineCurrent.Length -gt 200 )
                                {
                                    Write-Host ' | Result: ' -ForegroundColor DarkGray -NoNewline
                                    Write-Host $($LineCurrent.Substring(0,200)) -ForegroundColor DarkCyan -NoNewline
                                    Write-Host '...' -ForegroundColor DarkGray
                                }
                                else
                                {
                                    Write-Host ' | Result: ' -ForegroundColor DarkGray -NoNewline
                                    Write-Host $LineCurrent -ForegroundColor DarkCyan
                                }
                            }
                        }
                    }

                    $LineCurrent
                }
            )
        }
    }

    if ( -not $BoolErrorGlobal )
    {
        if ( -not $N )
        {
            Write-Host "$('{0,7}' -f '--'): No match 'if string' or 'from Text' in all settings: " -ForegroundColor DarkGray -NoNewline
            Write-Host $aTextReplace.Count -ForegroundColor Gray
        }
        else
        {
            $ContentData.FixCount = $FixCount
            $ContentData.Content  = $Content
        }
    }

    Return $ContentData
}

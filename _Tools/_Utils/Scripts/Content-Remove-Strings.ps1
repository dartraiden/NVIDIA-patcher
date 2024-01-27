
# Удаление строк построчно, согласно шаблону -match
Function Content-Remove-Strings ( [PSCustomObject] $ContentData, [array] $aRemoveStrings )
{
    Write-Host "`n    Fix: " -ForegroundColor DarkGray -NoNewline
    Write-Host $ContentData.File -ForegroundColor Cyan -NoNewline
    Write-Host ' [Remove strings]:' -ForegroundColor DarkMagenta

    [int64] $N = 0
    [int64] $FixCount = $ContentData.FixCount
    [array] $Content  = $ContentData.Content

    [bool] $isLineRemove = $false

    if ( $aRemoveStrings.Count )
    {
        foreach ( $removeString in $aRemoveStrings )
        {
            try { $null = [regex]::new($removeString) }
            catch
            {
                Write-Host "    Fix: [Remove strings] Error match pattern ""if String"": $removeString | File: $($ContentData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Fix: [Remove strings] Error match pattern ""if String"": $removeString | File: $($ContentData.File)"

                $BoolErrorGlobal = $true

                break
            }
        }

        if ( -not $BoolErrorGlobal )
        {
            $Content = $(

                foreach ( $Line in $Content )
                {
                    $isLineRemove = $false

                    foreach ( $removeString in $aRemoveStrings )
                    {
                        if ( $removeString -and ( $Line -match $removeString ))
                        {
                            $N++

                            Write-Host "$('{0,7}' -f ++$FixCount): ifString: " -ForegroundColor DarkGray -NoNewline
                            Write-Host $removeString -ForegroundColor Magenta -NoNewline

                            if ( $Line.Length -gt 200 )
                            {
                                Write-Host ' | Remove: ' -ForegroundColor DarkGray -NoNewline
                                Write-Host $($Line.Substring(0,200)) -ForegroundColor DarkMagenta -NoNewline
                                Write-Host '...' -ForegroundColor DarkGray
                            }
                            else
                            {
                                Write-Host ' | Remove: ' -ForegroundColor DarkGray -NoNewline
                                Write-Host $Line -ForegroundColor DarkMagenta
                            }

                            $isLineRemove = $true
                            break
                        }
                    }

                    if ( -not $isLineRemove ) { $Line }
                }
            )
        }
    }


    if ( -not $N )
    {
        Write-Host "$('{0,7}' -f '--'): No match 'if string'" -ForegroundColor DarkGray
    }
    elseif ( -not $BoolErrorGlobal )
    {
        $ContentData.FixCount = $FixCount
        $ContentData.Content  = $Content
    }

    Return $ContentData
}

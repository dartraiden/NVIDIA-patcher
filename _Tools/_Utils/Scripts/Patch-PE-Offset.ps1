

#
Function Patch-PE-Offset ( [PSCustomObject] $FileData, [array] $aPatchOffset, [string] $Folder )
{
    [string] $arch = $FileData.arch

    Write-Host '  Patch: ' -ForegroundColor DarkGray -NoNewline
    Write-Host $FileData.File -ForegroundColor Cyan -NoNewline
    Write-Host ' [Offset]' -ForegroundColor Magenta -NoNewline
    Write-Host " | [$arch] | $($FileData.info.Version) | $($FileData.info.Description)" -ForegroundColor DarkGray

       [int64] $N = 0
       [int64] $FixCount = $FileData.FixCount

    [string[]] $1337 = @()
      [string] $line = ''
    [string[]] $lines = @()
      [string] $File1337 = ''
        [bool] $isChanged = $false
        [bool] $isWrong   = $false

        [byte] $byte = 0

      [uint64] $isOffset = 0
      [string] $isValue  = ''

         [int] $fixOffset = 0
      [uint64] $fixSize   = 0
      [uint64] $addToEnd  = 0
      [uint64] $addToSize = 0

      [uint64] $showHex    = 0
      [string] $foundHex   = ''
      [string] $fromHex    = ''
       [int64] $foundCount = 0
      [string] $toHex      = ''
       [int64] $toHexCount = 0
      [byte[]] $bToHex     = @()
         [int] $i          = 0

    if ( $aPatchOffset.Count )
    {
        foreach ( $PatchOffset in $aPatchOffset )
        {
            $addToEnd  = 0
            $addToSize = 0

            $fixOffset = 0
            $isOffset  = 0
            $fromHex   = ''
            $toHex     = ''


            try {
                $fromHex = $PatchOffset.fromHex.Trim()
            } catch {}

            if ( $N ) { Write-Host }

            $N++

            # Проверка доп условия из пресета
            if ( $PatchOffset.check )
            {
                if ( -not ( Check-If-True -FileInfo $FileData.info -Check $PatchOffset.check ))
                {
                    Write-Host '  Patch: [Offset] For this setting: if ( ' -ForegroundColor DarkYellow -NoNewline
                    Write-Host $PatchOffset.check -ForegroundColor White -NoNewline
                    Write-Host ' ) { is Not True }' -ForegroundColor DarkYellow -NoNewline
                    Write-Host ' [Ok] [Skip]' -ForegroundColor DarkGreen

                    #$BoolErrorGlobal = $true
                    $aAttentionsGlobal += "Patch | [Offset] For this setting: if ( $($PatchOffset.check) ) { is Not True } [Ok] [Skip]"
                    continue
                }
                else
                {
                    Write-Host '  Patch: [Offset] For this setting: if ( ' -ForegroundColor DarkGray -NoNewline
                    Write-Host $PatchOffset.check -ForegroundColor White -NoNewline
                    Write-Host ' ) { is True }' -ForegroundColor DarkGray -NoNewline
                    Write-Host ' [Ok]' -ForegroundColor Green
                }
            }

            # Получение данных из файла 1337
            if ( $fromHex -match '^Edit\\' )
            {
                Write-Host "  Patch: Getting data from 1337: $fromHex" -ForegroundColor DarkGray

                $File1337 = '{0}\{1}' -f $Folder, $fromHex

                $fromHex = ''

                if ( [System.IO.File]::Exists($File1337) )
                {
                    $1337 = [System.IO.File]::ReadAllLines($File1337, [System.Text.Encoding]::GetEncoding(65001)) # utf8

                    for ( $i = 1 ; $i -lt $1337.Length ; $i++ )
                    {
                        $line = $1337[$i].Trim()

                        if ( $line )
                        {
                            $lines = $line.Replace('->', ':').Split(':')

                            if ( -not $isOffset )
                            {
                                [uint64]::TryParse($lines[0], [System.Globalization.NumberStyles]::HexNumber, [System.Globalization.NumberFormatInfo]::InvariantInfo, [ref]$isOffset) > $null

                                if ( -not $isOffset ) { break }
                            }

                            $fromHex += $lines[1]
                            $toHex   += $lines[2]
                        }
                    }
                }
                else
                {
                    Write-Host "  Patch: [Offset] Error: file 1337 not exist | Setting for file [$arch]: $($FileData.File)" -ForegroundColor Red

                    $aWarningsGlobal += "Patch: [Offset] Error: file 1337 not exist | Setting for file [$arch]: $($FileData.File)"

                    $BoolErrorGlobal = $true

                    break
                }
            }
            else
            {
                try {
                    $toHex = $PatchOffset.toHex.Trim()
                } catch {}

                [uint64]::TryParse($PatchOffset.Offset, [System.Globalization.NumberStyles]::HexNumber, [System.Globalization.NumberFormatInfo]::InvariantInfo, [ref]$isOffset) > $null
            }

            if ( -not $isOffset )
            {
                Write-Host "  Patch: [Offset] Error: Offset = 0 | for file [$arch]: $($FileData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Patch: [Offset] Error: Offset = 0 | for file [$arch]: $($FileData.File)"

                $BoolErrorGlobal = $true

                break
            }


            if ( $fromHex -notmatch '^(\s*[0-9a-f]{2})+\s*$' )
            {
                Write-Host "  Patch: from Hex: ""$fromHex""" -ForegroundColor Red

                Write-Host "  Patch: [Offset] Error: wrong/null ""from Hex/file 1337"": ""$($PatchOffset.fromHex)"" | file [$arch]: $($FileData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Patch: [Offset] Error: wrong/null ""from Hex/file 1337"": ""$($PatchOffset.fromHex)"" | file [$arch]: $($FileData.File)"

                $BoolErrorGlobal = $true

                break
            }
            elseif ( $toHex -notmatch '^(\s*[0-9a-f]{2})+\s*$' )
            {
                Write-Host "  Patch: to Hex: ""$toHex""" -ForegroundColor Red

                Write-Host "  Patch: [Offset] Error: wrong/null ""to Hex"": ""$($PatchOffset.toHex)"" | file [$arch]: $($FileData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Patch: [Offset] Error: wrong/null ""to Hex"": ""$($PatchOffset.toHex)"" | file [$arch]: $($FileData.File)"

                $BoolErrorGlobal = $true

                break
            }

            $foundCount = ($fromHex -replace '\s','').Length / 2
            $fromHex    = ($fromHex -replace '\s','' -replace '([0-9a-f]{2})',' $1').ToLower().TrimStart()

            $toHexCount = ($toHex -replace '\s','').Length / 2
            $toHex      = ($toHex -replace '\s','' -replace '([0-9a-f]{2})',' $1').ToLower().TrimStart()

            if ( $foundCount -ne $toHexCount )
            {
                Write-Host "  Patch: from Hex: $fromHex" -ForegroundColor Red
                Write-Host "  Patch:   to Hex: $toHex" -ForegroundColor Red

                Write-Host "  Patch: [Offset] Error: The bytes count does not equal: 'from Hex' and 'to Hex' | file [$arch]: $($FileData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Patch: [Offset] Error: The bytes count does not equal: 'from Hex' and 'to Hex' | file [$arch]: $($FileData.File)"

                $BoolErrorGlobal = $true

                break
            }

            $fixOffset = $PatchOffset.fixOffset
            $fixSize   = $PatchOffset.fixSize
            $addToEnd  = $PatchOffset.addToEnd
            $addToSize = $PatchOffset.addToSize

            if ( $fixOffset -and $fixSize -and ( $isOffset -ge $fixSize ))
            {
                if ( -not $addToEnd )
                {
                    Write-Host "  Patch: fix Offset: $('{0:x8}' -f $isOffset) - $fixSize = " -ForegroundColor DarkGray -NoNewline

                    $isOffset = $isOffset - $fixSize

                    Write-Host "$('{0:x8}' -f $isOffset)" -ForegroundColor DarkMagenta
                }
                else
                {
                    Write-Host "  Patch: fix Offset: Ignored (add to End: $addToEnd)" -ForegroundColor DarkGray
                }
            }

            try
            {
                # Добавление в конец файла количество нулевых байт
                if ( $addToEnd )
                {
                    if ( $addToSize -eq $FileData.Bytes.Count )
                    {
                        Write-Host "  Patch: add to End: " -ForegroundColor DarkGray -NoNewline
                        Write-Host $addToEnd -ForegroundColor White

                        $bToHex = [byte[]]::new($addToEnd)

                        $FileData.toWrites.Add([PSCustomObject] @{
                            Bytes  = $bToHex
                            Offset = $FileData.Bytes.Count
                        })

                        $FileData.Bytes = $FileData.Bytes + $bToHex

                        $FixCount++
                    }
                    else
                    {
                        Write-Host "  Patch: add to End: +$addToEnd (skipped) | file size: $($FileData.Bytes.Count) (does not match: $addToSize or already added)" -ForegroundColor DarkGray
                    }
                }

                $foundHex = [string]::Join(' ', $(foreach ( $byte in $FileData.Bytes[$isOffset..($isOffset + $foundCount - 1)] ) { '{0:x2}' -f $byte }))
            }
            catch
            {
                Write-Host "  Patch: [Offset] Error: Get Bytes from Offset: $isOffset [Hex: $('{0:x8}' -f $isOffset)] | file bytes: $($FileData.Bytes.Count) | file [$arch]: $($FileData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Patch: [Offset] Error: Get Bytes from Offset: $isOffset [Hex: $('{0:x8}' -f $isOffset)] | file bytes: $($FileData.Bytes.Count) | file [$arch]: $($FileData.File)"

                $BoolErrorGlobal = $true

                break
            }

            $showHex = 0

            if ( [uint64]::TryParse($PatchOffset.showHex, [ref]$showHex) )
            {
                if ( $showHex -gt 50 ) { $showHex = 50 }
            }

            $isWrong = $false

            if ( $toHex -ceq $foundHex ) { $isChanged = $true }
            else
            {
                $isChanged = $false

                if ( $foundHex -cne $fromHex )
                {
                    $isWrong = $true

                    if ( -not $showHex ) { $showHex = 10 }
                }
            }

            if ( $showHex -and ( $isOffset -gt 0 ) -and ( $FileData.Bytes.Count -gt (( $showHex * 2 ) + $foundCount )))
            {
                if ( $isOffset -lt $showHex )
                {
                    $showHex = $isOffset
                }

                Write-Host '           From: ' -ForegroundColor DarkGray -NoNewline
                Write-Host "$('   ' * $showHex)$fromHex" -ForegroundColor DarkGray

                Write-Host '          Found: ' -ForegroundColor DarkGray -NoNewline
                Write-Host "$([string]::Join(' ', $(foreach ( $byte in $FileData.Bytes[($isOffset-$showHex)..($isOffset-1)] ) { '{0:x2}' -f $byte })) ) " -ForegroundColor DarkCyan -NoNewline

                if ( $isChanged )
                {
                    Write-Host $foundHex -ForegroundColor Green -NoNewline
                }
                elseif ( $isWrong )
                {
                    Write-Host $foundHex -ForegroundColor Red -NoNewline
                }
                else
                {
                    Write-Host $foundHex -ForegroundColor White -NoNewline
                }

                Write-Host " $([string]::Join(' ', $(foreach ( $byte in $FileData.Bytes[($isOffset+$foundCount)..($isOffset+$foundCount+$showHex-1)] ) { '{0:x2}' -f $byte })) )" -ForegroundColor DarkCyan

                Write-Host '         to Hex: ' -ForegroundColor DarkGray -NoNewline
                Write-Host "$('   ' * $showHex)$toHex" -ForegroundColor Green
            }
            else
            {
                Write-Host '           From: ' -ForegroundColor DarkGray -NoNewline
                Write-Host $fromHex -ForegroundColor DarkGray

                Write-Host '          Found: ' -ForegroundColor DarkGray -NoNewline

                if ( $isChanged )
                {
                    Write-Host $foundHex -ForegroundColor Green
                }
                elseif ( $isWrong )
                {
                    Write-Host $foundHex -ForegroundColor Red
                }
                else
                {
                    Write-Host $foundHex -ForegroundColor White
                }

                Write-Host '         to Hex: ' -ForegroundColor DarkGray -NoNewline
                Write-Host $toHex -ForegroundColor Green
            }



            if ( $isChanged )
            {
                Write-Host '  Patch: [Offset] [Ok] "Found Hex" = "to Hex" ' -ForegroundColor Green -NoNewline
                Write-Host "| Offset: $('{0:x8}' -f $isOffset)" -ForegroundColor DarkGray
            }
            elseif ( $isWrong )
            {
                Write-Host "  Patch: [Offset] Error: ""Found Hex"" not equal ""from Hex"" | Offset: $('{0:x8}' -f $isOffset) | file [$arch]: $($FileData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Patch: [Offset] Error: ""Found Hex"" not equal ""from Hex"" | Offset: $('{0:x8}' -f $isOffset) | file [$arch]: $($FileData.File)"

                $BoolErrorGlobal = $true

                break
            }
            else
            {
                Write-Host '  Patch: Changing bytes | Offset: ' -ForegroundColor DarkGray -NoNewline

                Write-Host "$('{0:x8}' -f $isOffset) " -ForegroundColor DarkMagenta -NoNewline
                Write-Host '| ' -ForegroundColor DarkGray -NoNewline

                try
                {
                    $bToHex = $(foreach ( $isValue in $toHex.Split() ) { '0x{0}' -f $isValue })

                    for ( $i = 0 ; $i -lt $bToHex.Length ; $i++ ) { $FileData.Bytes[$isOffset + $i] = $bToHex[$i] }

                    $FileData.toWrites.Add([PSCustomObject] @{
                        Bytes  = $bToHex
                        Offset = $isOffset
                    })

                    $FixCount++

                    Write-Host '[Ok]' -ForegroundColor Green
                }
                catch
                {
                    Write-Host "`n  Patch: [Offset] Error: Changing bytes | Offset: $('{0:x8}' -f $isOffset) | file [$arch]: $($FileData.File)" -ForegroundColor Red

                    $aWarningsGlobal += "Patch: [Offset] Error: Changing bytes | Offset: $('{0:x8}' -f $isOffset) | file [$arch]: $($FileData.File)"

                    $BoolErrorGlobal = $true

                    break
                }
            }
        }
    }

    if ( -not $N )
    {
        Write-Host "$('{0,7}' -f '--'): [Offset] Error: No 'from Hex' | file [$arch]: $($FileData.File)" -ForegroundColor Red

        $aWarningsGlobal += "Patch: [Offset] Error: No 'from Hex' | file [$arch]: $($FileData.File)"

        $BoolErrorGlobal = $true
    }
    elseif ( -not $BoolErrorGlobal )
    {
        $FileData.FixCount = $FixCount
    }

    Return $FileData
}



#
Function Patch-PE-Universal ( [PSCustomObject] $FileData, [array] $aPatchUnivers )
{
    [string] $arch = $FileData.arch

    Write-Host '  Patch: ' -ForegroundColor DarkGray -NoNewline
    Write-Host $FileData.File -ForegroundColor Cyan -NoNewline
    Write-Host ' [Universal]' -ForegroundColor Magenta -NoNewline
    Write-Host " | [$arch] | $($FileData.info.Version) | $($FileData.info.Description)" -ForegroundColor DarkGray

       [int64] $N = 0
       [int64] $FixCount = $FileData.FixCount

       [int64] $Count = 0
        [byte] $byte = 0
      [string] $BinaryString = ''
      [string] $text = ''
        [bool] $isChanged = $false

    [PSObject] $Regex = $null
        [char] $char = $null
    [System.Text.RegularExpressions.Capture] $R = $null

      [uint64] $isOffset = 0
      [string] $isValue  = ''

      [uint64] $showHex      = 0
       [int64] $foundCount   = 0
       [int64] $toHexCount   = 0
      [double] $fromHexCount = 0 # Число двойной точности с плавающей запятой, чтобы не округляло не целые числа

       [int64] $maxMatches  = 0  # Макс совпадений
       [int64] $needMatches = 0  # Нужные совпадения
       [int64] $start       = 0
       [int64] $in          = 0
       [int64] $i           = 0
       [int64] $j           = 0

         [int] $nShowMax    = 0
         [int] $nShowed     = 0

      [string] $foundHex   = ''
      [string] $uFromHex   = ''
      [string] $fromHex    = ''
      [string] $toHex      = ''
      [byte[]] $bToHex     = @()

    if ( $aPatchUnivers.Count )
    {
        foreach ( $PatchUnivers in $aPatchUnivers )
        {
            $uFromHex = ''
            $fromHex  = ''
            $toHex    = ''

            try {
                $uFromHex = $PatchUnivers.uFromHex.Trim()
                $toHex    = $PatchUnivers.toHex.Trim()
            } catch {}

            if ( $N ) { Write-Host }

            $N++


            # Проверка доп условия из пресета
            if ( $PatchUnivers.check )
            {
                if ( -not ( Check-If-True -FileInfo $FileData.info -Check $PatchUnivers.check ))
                {
                    Write-Host '  Patch: [Universal] For this setting: if ( ' -ForegroundColor DarkYellow -NoNewline
                    Write-Host $PatchUnivers.check -ForegroundColor White -NoNewline
                    Write-Host ' ) { is Not True }' -ForegroundColor DarkYellow -NoNewline
                    Write-Host ' [Ok] [Skip]' -ForegroundColor DarkGreen

                    #$BoolErrorGlobal = $true
                    $aAttentionsGlobal += "Patch | [Universal] For this setting: if ( $($PatchUnivers.check) ) { is Not True } [Ok] [Skip]"
                    continue
                }
                else
                {
                    Write-Host '  Patch: [Universal] For this setting: if ( ' -ForegroundColor DarkGray -NoNewline
                    Write-Host $PatchUnivers.check -ForegroundColor White -NoNewline
                    Write-Host ' ) { is True }' -ForegroundColor DarkGray -NoNewline
                    Write-Host ' [Ok]' -ForegroundColor Green
                }
            }

            if ( -not $uFromHex )
            {
                Write-Host "  Patch: [Universal] Error: full pattern is null: ""from Hex"" | file [$arch]:  $($FileData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Patch: [Universal] Error: full pattern is null: ""from Hex"" | file [$arch]:  $($FileData.File)"

                $BoolErrorGlobal = $true

                break
            }
            elseif ( $toHex -notmatch '^(\s*[0-9a-f]{2})+\s*$' )
            {
                Write-Host "  Patch: [Universal] Error: wrong/null ""to Hex"": ""$($PatchUnivers.toHex)"" | file [$arch]:  $($FileData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Patch: [Universal] Error: wrong/null ""to Hex"": ""$($PatchUnivers.toHex)"" | file [$arch]:  $($FileData.File)"

                $BoolErrorGlobal = $true

                break
            }

            $fromHex = ($uFromHex -replace '\s','' -replace '.*?\[\[(([?0-9a-f]{2}\|?)+)\]\].*','$1' -replace '([?0-9a-f]{2})',' $1').ToLower().TrimStart()  # для поддержки групп в [[00 11|22 33|44 55]]


            if ( $fromHex -notmatch '^(\s*[?0-9a-f]{2}\|?)+\s*$' )   # для поддержки групп в [[00 11|22 33|44 55]]
            {
                Write-Host "  Patch: Full pattern: $uFromHex" -ForegroundColor Red
                Write-Host "  Patch:     from Hex: $fromHex" -ForegroundColor Red
                
                Write-Host "  Patch: [Universal] Error: wrong ""from Hex"" in [[...]] | file [$arch]:  $($FileData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Patch: [Universal] Error: wrong ""from Hex"" in [[...]] | file [$arch]:  $($FileData.File)"

                $BoolErrorGlobal = $true

                break
            }
            
            try
            {
                $fromHexCount = ($fromHex -replace '[\s|]','').Length / 2 / @(($fromHex -replace '\s','').Split('|')).Count # для поддержки групп в [[00 11|22 33|44 55]]
                $toHexCount   = ($toHex   -replace '\s','').Length / 2
                $toHex        = ($toHex   -replace '\s','' -replace '([0-9a-f]{2})',' $1').ToLower().TrimStart()
            }
            catch { $fromHexCount = 7777; $toHexCount = 9999 }

            if ( $fromHexCount -ne $toHexCount )
            {
                Write-Host "  Patch: Full pattern: $uFromHex" -ForegroundColor Red
                Write-Host "  Patch:     from Hex: $fromHex" -ForegroundColor Red
                Write-Host "  Patch:       to Hex: $toHex" -ForegroundColor Red

                Write-Host "  Patch: [Universal] Error: The bytes count does not equal: 'from Hex' and 'to Hex' | file [$arch]:  $($FileData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Patch: [Universal] Error: The bytes count does not equal: 'from Hex' and 'to Hex' | file [$arch]:  $($FileData.File)"

                $BoolErrorGlobal = $true

                break
            }


            # Также искать и нужное значение, может быть уже изменено
            $uFromHex = $uFromHex -replace '\[\[((\s*[?0-9a-f]{2}(\s*\|)?)+\s*)\]\]',"(?<G>(`$1|$toHex))"  -replace '\?\?','[\s\S]' -replace '\s','' -replace '(?<=^|\(|[^{,][^{,])([0-9a-f]{2})(?=$|\)|[^,}][^,}])','\x$1'

            try { $null = [regex]::new($uFromHex) }
            catch
            {
                Write-Host "  Patch: Full pattern: $uFromHex" -ForegroundColor Red

                Write-Host "  Patch: [Universal] Error: match pattern ""from Hex"": $($PatchUnivers.uFromHex) | file [$arch]:  $($FileData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Patch: [Universal] Error: match pattern ""from Hex"": $uFromHex | $($PatchUnivers.uFromHex) | file [$arch]:  $($FileData.File)"

                $BoolErrorGlobal = $true

                break
            }



            $needMatches = $PatchUnivers.need  # Нужные совпадения
            $maxMatches  = $PatchUnivers.max   # Макс совпадений

            if ( $maxMatches -and ( $maxMatches -lt [math]::Abs($needMatches) ))
            {
                Write-Host "  Patch: from Hex: $fromHex" -ForegroundColor Red
                Write-Host "  Patch:   to Hex: $toHex" -ForegroundColor Red

                Write-Host "  Patch: [Universal] Error: [maxMatches: [$maxMatches] < [needMatches: $needMatches] | file [$arch]:  $($FileData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Patch: [Universal] Error: [maxMatches: [$maxMatches] < [needMatches: $needMatches] | file [$arch]:  $($FileData.File)"

                $BoolErrorGlobal = $true
                break
            }



            $BinaryString = [System.Text.Encoding]::GetEncoding(28591).GetString($FileData.Bytes)

            Write-Host "  Patch: Searching: pattern: $uFromHex" -ForegroundColor DarkGray
            $Regex = [regex]::Matches($BinaryString, $uFromHex, 4).Groups.Where({ $_.Name -eq 'G' }) # 'ExplicitCapture' = 4

            $Count   = $Regex.Value.Count
            $showHex = 0

            if ( [uint64]::TryParse($PatchUnivers.showHex, [ref]$showHex) )
            {
                if ( $showHex -gt 50 ) { $showHex = 50 }
            }

            if ( -not $Count )
            {
                Write-Host "  Patch: from Hex: $fromHex" -ForegroundColor Red
                Write-Host "  Patch:   to Hex: $toHex" -ForegroundColor Red

                Write-Host "  Patch: [Universal] Error: No matches found: $($PatchUnivers.uFromHex) | file [$arch]:  $($FileData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Patch: [Universal] Error: No matches found: $($PatchUnivers.uFromHex) | file [$arch]:  $($FileData.File)"

                $BoolErrorGlobal = $true
                break
            }
            elseif ( $Count -lt [math]::Abs($needMatches) )  # если найдено меньше $needMatches
            {
                Write-Host "  Patch: from Hex: $fromHex" -ForegroundColor Red
                Write-Host "  Patch:   to Hex: $toHex" -ForegroundColor Red

                Write-Host "  Patch: [Universal] Error: [Found: $($Count)] < [needMatches: $needMatches] | file [$arch]:  $($FileData.File)" -ForegroundColor Red

                $aWarningsGlobal += "Patch: [Universal] Error: [Found: $($Count)] < [needMatches: $needMatches] | file [$arch]:  $($FileData.File)"

                $BoolErrorGlobal = $true
                break
            }

            $nShowMax = 30
            $nShowed  = 0

            # Если Found > max (ошибка)
            if ( $maxMatches -and ( $Count -gt $maxMatches ))
            {
                if ( -not $showHex ) { $showHex = 10 }

                Write-Host '  Patch: ' -ForegroundColor Red -NoNewline
                Write-Host '[Test] [Universal] [Found: ' -ForegroundColor DarkGray -NoNewline
                Write-Host " $Count " -ForegroundColor Black -BackgroundColor Red -NoNewline

                Write-Host '] > [maxMatches: ' -ForegroundColor DarkGray -BackgroundColor Black -NoNewline
                Write-Host " $maxMatches " -ForegroundColor Black -BackgroundColor Yellow -NoNewline

                Write-Host '] (+ show Hex: ' -ForegroundColor DarkGray -BackgroundColor Black -NoNewline
                Write-Host $showHex -ForegroundColor DarkCyan -NoNewline
                Write-Host ')' -ForegroundColor DarkGray

                $aWarningsGlobal += "Patch: [Test] [Universal] [Found: $($Count)] > [maxMatches: $maxMatches] | file [$arch]:  $($FileData.File)"

                Write-Host '  toHex: ' -ForegroundColor DarkGray -NoNewline
                Write-Host "$('   ' * $showHex)$toHex" -ForegroundColor Green

                foreach ( $R in $Regex )
                {
                    if ( $nShowed -ge $nShowMax )
                    {
                        Write-Host "   [--]: Maximum first $nShowMax matches" -ForegroundColor DarkGray

                        break
                    }

                    $nShowed++

                    $isOffset = $R.Index
                    $isValue  = $R.Value

                    $foundHex = [string]::Join(' ', $(foreach ( $char in $isValue.ToCharArray() ) { '{0:x2}' -f ([int]$char) }))

                    Write-Host "   $('[{0,2}]' -f $nShowed): " -ForegroundColor DarkGray -NoNewline

                    if ( $showHex -and ( $isOffset -gt 0 ) -and ( $FileData.Bytes.Count -gt (( $showHex * 2 ) + $toHexCount )))
                    {
                        if ( $isOffset -lt $showHex )
                        {
                            $showHex = $isOffset
                        }

                        Write-Host "$([string]::Join(' ', $(foreach ( $byte in $FileData.Bytes[($isOffset-$showHex)..($isOffset-1)] ) { '{0:x2}' -f $byte })) ) " -ForegroundColor DarkCyan -NoNewline

                        if ( $toHex -ceq $foundHex )
                        {
                            Write-Host $foundHex -ForegroundColor Green -NoNewline
                        }
                        else
                        {
                            Write-Host $foundHex -ForegroundColor White -NoNewline
                        }

                        Write-Host " $([string]::Join(' ', $(foreach ( $byte in $FileData.Bytes[($isOffset+$toHexCount)..($isOffset+$toHexCount+$showHex-1)] ) { '{0:x2}' -f $byte })) )" -ForegroundColor DarkCyan
                    }
                    else
                    {
                        if ( $toHex -ceq $foundHex )
                        {
                            Write-Host $foundHex -ForegroundColor Green
                        }
                        else
                        {
                            Write-Host $foundHex -ForegroundColor White
                        }
                    }

                } # foreach $Regex end

                break
            }

            

            # Далее выполнение: количество совпадений подходит (хорошо)
            
            if ( $needMatches -eq 0 )
            {
                $start = 0
                $in    = $Count

                Write-Host "  Patch: Found: [$($Count)] | needMatches: [$needMatches] = All | maxMatches: [$maxMatches]" -ForegroundColor DarkGray -NoNewline
            }
            elseif ( [math]::Sign($needMatches) -eq -1 ) # если число последних
            {
                $start = ($needMatches + $Count)
                $in    = $Count

                Write-Host "  Patch: Found: [$($Count)] | needMatches: [Last: $([math]::Abs($needMatches))] | maxMatches: [$maxMatches]" -ForegroundColor DarkGray -NoNewline
            }
            else
            {
                $start = 0
                $in    = $needMatches

                Write-Host "  Patch: Found: [$($Count)] | needMatches: [First: $needMatches] | maxMatches: [$maxMatches]" -ForegroundColor DarkGray -NoNewline
            }

            if ( -not $maxMatches ) { Write-Host ' = All' -ForegroundColor DarkGray } else { Write-Host }


            if (( $in - $start ) -gt $nShowMax )
            {
                Write-Host "  Patch: Show max: $nShowMax [$($in - $start - $nShowMax) without show]" -ForegroundColor DarkCyan
            }

            Write-Host '  toHex: ' -ForegroundColor DarkGray -NoNewline
            Write-Host "$('   ' * $showHex)$toHex" -ForegroundColor Green

            for ( $i = $start ; $i -lt $in ; $i++ )
            {
                $isOffset = $Regex[$i].Index
                $isValue  = $Regex[$i].Value
                
                $foundHex = [string]::Join(' ', $(foreach ( $char in $isValue.ToCharArray() ) { '{0:x2}' -f ([int]$char) }))

                if ( $toHex -ceq $foundHex ) { $isChanged = $true } else { $isChanged = $false }

                if ( $nShowMax -gt $nShowed )
                {
                    $nShowed++
            
                    Write-Host "   $('[{0,2}]' -f $nShowed): " -ForegroundColor DarkGray -NoNewline

                    if ( $showHex -and ( $isOffset -gt 0 ) -and ( $FileData.Bytes.Count -gt (( $showHex * 2 ) + $toHexCount )))
                    {
                        if ( $isOffset -lt $showHex )
                        {
                            $showHex = $isOffset
                        }

                        Write-Host "$([string]::Join(' ', $(foreach ( $byte in $FileData.Bytes[($isOffset-$showHex)..($isOffset-1)] ) { '{0:x2}' -f $byte })) ) " -ForegroundColor DarkCyan -NoNewline

                        if ( $isChanged )
                        {
                            Write-Host $foundHex -ForegroundColor Green -NoNewline
                        }
                        else
                        {
                            Write-Host $foundHex -ForegroundColor White -NoNewline
                        }

                        Write-Host " $([string]::Join(' ', $(foreach ( $byte in $FileData.Bytes[($isOffset+$toHexCount)..($isOffset+$toHexCount+$showHex-1)] ) { '{0:x2}' -f $byte })) )" -ForegroundColor DarkCyan
                    }
                    else
                    {
                        if ( $isChanged )
                        {
                            Write-Host $foundHex -ForegroundColor Green
                        }
                        else
                        {
                            Write-Host $foundHex -ForegroundColor White
                        }
                    }

                    if ( $isChanged )
                    {
                        Write-Host '  Patch: Match: "Found Hex" = "to Hex" ' -ForegroundColor Green -NoNewline
                        Write-Host "| Offset: $('{0:x8}' -f $isOffset)" -ForegroundColor DarkGray
                    }
                    else
                    {
                        Write-Host '  Patch: Match: Changing bytes | Offset: ' -ForegroundColor DarkGray -NoNewline

                        Write-Host "$('{0:x8}' -f $isOffset) " -ForegroundColor DarkMagenta -NoNewline
                        Write-Host '| ' -ForegroundColor DarkGray -NoNewline
                    }
                }
                else { $nShowMax = 0 }

                if ( -not $isChanged )
                {
                    try
                    {
                        $bToHex = $(foreach ( $isValue in $toHex.Split() ) { '0x{0}' -f $isValue })

                        for ( $j = 0 ; $j -lt $bToHex.Length ; $j++ ) { $FileData.Bytes[$isOffset + $j] = $bToHex[$j] }

                        $FileData.toWrites.Add([PSCustomObject] @{
                            Bytes  = $bToHex
                            Offset = $isOffset
                        })

                        $FixCount++

                        if ( $nShowMax ) { Write-Host '[Ok]' -ForegroundColor Green }
                    }
                    catch
                    {
                        Write-Host "`n  Patch: [Universal] Error: Changing bytes | Offset: $('{0:x8}' -f $isOffset) | file [$arch]:  $($FileData.File)" -ForegroundColor Red

                        $aWarningsGlobal += "Patch: [Universal] Error: Changing bytes | Offset: $('{0:x8}' -f $isOffset) | file [$arch]:  $($FileData.File)"

                        $BoolErrorGlobal = $true

                        break
                    }
                }
            }
        }
    }

    if ( -not $N )
    {
        Write-Host "$('{0,7}' -f '--'): No 'from Hex' | file [$arch]:  $($FileData.File)" -ForegroundColor Red

        $aWarningsGlobal += "Patch: [Universal] Error: No 'from Hex' | file [$arch]:  $($FileData.File)"

        $BoolErrorGlobal = $true
    }
    elseif ( -not $BoolErrorGlobal )
    {
        $FileData.FixCount = $FixCount
    }

    Return $FileData
}

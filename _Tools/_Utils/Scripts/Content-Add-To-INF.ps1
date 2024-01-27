
# Сохраняется порядок, дубликаты и все пустые строки на своих местах. Кроме комментариев справа от названия разделов: [Name1]  ; ++++++
# Все строки с одними пробельными символами заменяются на просто пустую строку
# Если в конце у раздела одни комменты/пустые строки, то добавлено будет перед ними. Иначе добавление после последней строки контента.
Function Content-Add-To-INF ( [PSCustomObject] $ContentData, [array] $aAddStringsToInf, [array] $aAddDevIDtoInf )
{
    Write-Host "`n    Fix: " -ForegroundColor DarkGray -NoNewline
    Write-Host $ContentData.File -ForegroundColor Cyan -NoNewline
    Write-Host ' [Add to INF]:' -ForegroundColor White

    [System.Collections.Specialized.OrderedDictionary] $inf = [ordered]@{}
    [int] $EmptyCount = 0

    # Первая нулевая секция, для первых строк без секции (комментариев), если есть. Название не будет выводиться в результат.
    [string] $section = ';NO_SECTION'
    $inf[$section] = [System.Collections.Generic.List[string]]@()  # как [ordered]

    foreach ( $Line in $ContentData.Content )
    {
        if ( $Line -match '^\s*\[(?<Name>[^;\]]+)\]' )  # Комментарии справа от названия раздела не сохраняются
        {
            # Имя раздела
            $section = $Matches.Name
            $inf[$section] = [System.Collections.Generic.List[string]]@()
        }
        elseif ( $Line -match '[^\s]' )
        {
            # Строка контента в разделе
            # Повторяющиеся строки остаются. Для каждого раздела свой набор строк в том же порядке.
            $inf[$section].Add($Line)
        }
        else
        {
            # Пустая/одни пробелы строка в разделе (Строки с однимим пробельными символами будут заменены на просто пустую строку)
            $inf[$section].Add('')
        }
    }

     [int64] $FixCount = $ContentData.FixCount
     [int64] $N = 0
     [array] $aSections = @()
    [string] $CurrentSection = ''
       [int] $Count = 0
      [bool] $Added = $false
     [int64] $must  = 0

    # add strings (-like)
    if (( $aAddStringsToInf.Count ) -and ( $inf.Keys.Count -gt 1 ))
    {
        foreach ( $aAddString in $aAddStringsToInf )
        {
            $aSections = $inf.Keys.Where({ $_ -like $aAddString.toSectionInf })

            foreach ( $section in $aSections )
            {
                $N++

                if ( $CurrentSection -ne $section )
                {
                    $CurrentSection = $section

                    Write-Host "`n[$section]" -ForegroundColor DarkCyan
                }

                if ( -not ( $inf[$section] -eq $aAddString.addString ))
                {
                    $Added = $true
                    $FixCount++

                    Write-Host $aAddString.addString -ForegroundColor White -NoNewline
                    Write-Host " | add string: $N | Total file fix: $FixCount" -ForegroundColor DarkGray

                    # Если есть строки с контентом. (без пустых/одни пробелы строк и коментов ;****)
                    #$Count = $inf[$section].Where({ -not ( $_ -eq '' -or $_.StartsWith(';') ) },'First').Count
                    $Count = 0 ; foreach ( $Str in $inf[$section] ) { if ( -not ( $Str -eq '' -or $Str.StartsWith(';') ) ) { $Count = 1 ; break }}

                    if ( $Count )
                    {
                        $Count = $inf[$section].Count

                        # С конца массива найти номер строки раздела с контентом, для добавления после него.
                        # И перед последними пустыми/одни пробелы строками и комментами раздела.
                        while ( $inf[$section][$Count-1] -eq '' -or $inf[$section][$Count-1].StartsWith(';') )
                        {
                            $Count--
                        }
                    }

                    $inf[$section].Insert($Count, $aAddString.addString)
                }
                else
                {
                    Write-Host $aAddString.addString -ForegroundColor Green -NoNewline
                    Write-Host " | ($N) allready in" -ForegroundColor DarkGray
                }
            }

            if ( -not $aSections.Count )
            {
                $must = $aAddString.must

                if ( $must )
                {
                    Write-Host '    Fix: [must] > 0 | Section must be found' -ForegroundColor Red
                    Write-Host "    Fix: [Add to INF] No section found ""to Section"": -like ""$($aAddString.toSectionInf)"" | addString: $($aAddString.addString) | File: $($ContentData.File)" -ForegroundColor Red

                    $aWarningsGlobal += "Fix: [Add to INF] No section found ""to Section"": -like ""$($aAddString.toSectionInf)"" | addString: $($aAddString.addString) | File: $($ContentData.File)"

                    $BoolErrorGlobal = $true

                    break
                }
                else
                {
                    Write-Host '    Fix: [must] = 0 | Section must not necessarily be found' -ForegroundColor DarkYellow
                    Write-Host "    Fix: [Add to INF] No section found ""to Section"": -like ""$($aAddString.toSectionInf)"" | addString: $($aAddString.addString) | File: $($ContentData.File)" -ForegroundColor DarkYellow

                    $aAttentionsGlobal += "Fix   | [Add to INF] No section found ""to Section"": -like ""$($aAddString.toSectionInf)"" | addString: $($aAddString.addString) | File: $($ContentData.File)"
                
                    continue
                }
            }
        }
    }


    # add DevID (-match)
    if (( $aAddDevIDtoInf.Count ) -and ( $inf.Keys.Count -gt 1 ))
    {
        [string] $getVarName = ''
        [string] $getDispName = ''

           [int] $prefix  = 1  # каждый файл = 1
        [string] $pattern = ''
        [string] $genVar  = ''

        [string[]] $Parts = @()
        [string[]] $sectionsOS = @()
        [int] $addN = 0

        [string] $addSubSection   = ''
        [string] $MatchGetVarName = ''
        [string] $quotes          = ''
          [bool] $idExist         = $false

        [string] $MatchDevID      = ''

        foreach ( $aAddDevID in $aAddDevIDtoInf )
        {
            if ( $BoolErrorGlobal ) { break }

            try { $null = [regex]::new($aAddDevID.asVarOrDispName) }
            catch
            {
                Write-Host "  DevID: [Add to INF] Error match pattern ""as var/DisplayName"": $($aAddDevID.asVarOrDispName) | File: $($ContentData.File)" -ForegroundColor Red

                $aWarningsGlobal += "DevID:[Add to INF] Error match pattern ""as var/DisplayName"": $($aAddDevID.asVarOrDispName) | File: $($ContentData.File)"

                $BoolErrorGlobal = $true

                break
            }

            try { $null = [regex]::new($aAddDevID.andOS) }
            catch
            {
                Write-Host "  DevID: [Add to INF] Error match pattern ""+ and OS"": $($aAddDevID.andOS) | File: $($ContentData.File)" -ForegroundColor Red

                $aWarningsGlobal += "DevID: [Add to INF] Error match pattern ""+ and OS"": $($aAddDevID.andOS) | File: $($ContentData.File)"

                $BoolErrorGlobal = $true

                break
            }


            $prefix      = 1  # каждый файл = 1

            $getVarName  = ''
            $getDispName = ''
            $genVar      = ''
            $Parts       = @()
            $sectionsOS  = @()


            # Get Var Name
            foreach ( $Str in ( $inf['Strings'] -match $aAddDevID.asVarOrDispName ))
            {
                if ( $Str -match '^\s*(?<getVarName>[^;\s]+)\s*=\s*("(?<v1>[^|\r\n]+)"|(?<v2>[^";=|\r\n]*[^";=|\s])\s*($|[;\|]))' )
                {
                    $getVarName  = $Matches.getVarName

                    # Может быть только один из 2 после равно: v1: в кавычках (захватывает всё между ними) или v2: без кавычек (захватывает всё до "$" (конца) или ";", "|" и без крайних пробелов)
                    $getDispName = '{0}{1}' -f $Matches.v1, $Matches.v2
                    break
                }
            }

            if ( $getVarName -and $getDispName )
            {
                Write-Host "`n  " -NoNewline
                Write-Host 'DevID:' -ForegroundColor Gray -BackgroundColor DarkGray -NoNewline
                Write-Host ' add   DevID: ' -ForegroundColor DarkGray -BackgroundColor Black -NoNewline
                Write-Host $aAddDevID.addDevIDtoInf -ForegroundColor White -NoNewline
                Write-Host " | from ""as var/DisplayName"": ""$($aAddDevID.asVarOrDispName)"" | " -ForegroundColor DarkGray -NoNewline
                Write-Host $getDispName -ForegroundColor DarkCyan -NoNewline
                Write-Host ' | Var: ' -ForegroundColor DarkGray -NoNewline
                Write-Host $getVarName -ForegroundColor DarkCyan
            }
            else
            {
                $must = $aAddDevID.must

                if ( $must )
                {
                    Write-Host '  DevID: [must] > 0 | var/DisplayName must be found' -ForegroundColor Red
                    Write-Host "  DevID: Not found ""as var/DisplayName"": $($aAddDevID.asVarOrDispName) | add DevID: $($aAddDevID.addDevIDtoInf) | File: $($ContentData.File)" -ForegroundColor Red

                    $aWarningsGlobal += "DevID: Not found ""as var/DisplayName"": $($aAddDevID.asVarOrDispName) | add DevID: $($aAddDevID.addDevIDtoInf) | File: $($ContentData.File)"

                    $BoolErrorGlobal = $true

                    break
                }
                else
                {
                    Write-Host '  DevID: [must] = 0 | var/DisplayName must not necessarily be found' -ForegroundColor DarkYellow
                    Write-Host "  DevID: Not found ""as var/DisplayName"": $($aAddDevID.asVarOrDispName) | add DevID: $($aAddDevID.addDevIDtoInf) | File: $($ContentData.File)" -ForegroundColor DarkYellow

                    $aAttentionsGlobal += "DevID | Not found ""as var/DisplayName"": $($aAddDevID.asVarOrDispName) | add DevID: $($aAddDevID.addDevIDtoInf) | File: $($ContentData.File)"
                    
                    continue
                }
            }

            # gen Var (if new DisplayName)
            if ( $aAddDevID.newDisplayName )
            {
                if ( $aAddDevID.addDevIDtoInf -match '_' ) { $pattern = '_(?<G1>[a-zA-Z0-9]{2,4})' }
                else                                       { $pattern =  '(?<G1>[a-zA-Z0-9]{2,4})' }

                $Parts = @([regex]::Matches($aAddDevID.addDevIDtoInf, $pattern).Groups).Where({ $_.Name -eq 'G1' },'Last',3).Value

                if ( $Parts.Count )
                {
                    while ( $Parts.Count -lt 3 )
                    {
                        $Parts += $prefix++
                    }

                    do
                    {
                        # Повторять, пока существует собранный ID, увеличивая на 1 крайний префикс .0001
                        $genVar = 'ID_{0}' -f [string]::Join('.',
                            $(foreach ( $part in $Parts ) { $part.PadLeft(4,'0') }) + @( '{0:0000}' -f $prefix++ )
                        )
                    }
                    while ( $inf['Strings'] -match [regex]::Escape($genVar) )
                }
                else
                {
                    Write-Host "  DevID: Error genVar from add DevID: $($aAddDevID.addDevIDtoInf) | File: $($ContentData.File)" -ForegroundColor Red

                    $aWarningsGlobal += "DevID: Error genVar from add DevID: $($aAddDevID.addDevIDtoInf) | File: $($ContentData.File)"

                    $BoolErrorGlobal = $true

                    break
                }
            }

            if ( $genVar )
            {
                $getDispName = $aAddDevID.newDisplayName

                Write-Host '  DevID:      genVar: ' -ForegroundColor DarkGray -NoNewline
                Write-Host $genVar -ForegroundColor White -NoNewline
                Write-Host ' | with "new DisplayName": ' -ForegroundColor DarkGray -NoNewline
            }
            else
            {
                Write-Host '  DevID:         Var: ' -ForegroundColor DarkGray -NoNewline
                Write-Host $getVarName -ForegroundColor White -NoNewline
                Write-Host ' | with found DisplayName: ' -ForegroundColor DarkGray -NoNewline
            }

            Write-Host $getDispName -ForegroundColor White


            # Get all sections OS
            foreach ( $Str in ( $inf['Manufacturer'] -match '^[^;=]+=' )) # строка с =, начинающаяся не с ;
            {
                # Все разделы версий OS в 'Manufacturer', не закомментированные
                foreach ( $strOS in ( [regex]::Match($Str, '=\s*(?<G1>[^;]+)').Groups['G1'].Value.Split(',').Trim() ))
                {
                    if ( -not $sectionsOS.Count )
                    {
                        $sectionsOS = $strOS
                    }
                    else
                    {
                        $sectionsOS += '{0}.{1}' -f $sectionsOS[0], $strOS
                    }
                }

                # Разделы версий OS уже с контентом. Или пустые, но указаны в пресете '+ and OS'
                $sectionsOS = $(foreach ( $strOS in $sectionsOS )
                {
                    if ( $null -ne $inf[$strOS] )  # если раздел есть в inf, хоть и пустой
                    {
                        if ( $aAddDevID.andOS -and ( $strOS -match $aAddDevID.andOS ))  # если указаны в пресете
                        {
                            $strOS
                        }
                        elseif ( $inf[$strOS] -match "^(?!\s*;)\s*[^\s]" )  # или если есть контент
                        {
                            $strOS
                        }
                    }
                })

                break
            }

            if ( -not $sectionsOS.Count )
            {
                Write-Host "  DevID: Error: Not found [sections OS] | File: $($ContentData.File)" -ForegroundColor Red

                $aWarningsGlobal += "DevID: Error: Not found [sections OS] | File: $($ContentData.File)"

                $BoolErrorGlobal = $true

                break
            }



            $addSubSection   = ''
            $MatchGetVarName = [regex]::Escape($getVarName)
            $quotes          = ''
            $idExist         = $false

            # Get SectionID (for Add DevID). В любом из разделов
            foreach ( $OS in $sectionsOS )
            {
                if ( -not $addSubSection )
                {
                    foreach ( $Str in ( $inf[$OS] -match $MatchGetVarName ))
                    {
                        if ( $Str -match "^[\s""]*%$MatchGetVarName%[""\s]*=\s*(?<addSubSection>[^;,\s]+)\s*," )
                        {
                            $addSubSection = $Matches.addSubSection

                            Write-Host "  DevID:  subSection: " -ForegroundColor DarkGray -NoNewline
                            Write-Host $addSubSection -ForegroundColor White -NoNewline
                            Write-Host " | from: [$OS] $Str" -ForegroundColor DarkGray

                            if ( $Str -match '^\s*"' ) { $quotes = '"' } else { $quotes = '' } # Если с кавычками, то добавить так же с ними.

                            break
                        }
                    }
                }
                else { break }
            }

            # Add DevID
            if ( $addSubSection )
            {
                $addN = 0

                if ( $genVar ) { $getVarName = $genVar }

                $MatchDevID = [regex]::Escape($aAddDevID.addDevIDtoInf)

                foreach ( $OS in $sectionsOS )
                {
                    $idExist = $false

                    # Если ID будет совпадать своими символами вначале, но будет длиннее, то будет считаться как не найден (другим). Бывают такие: %var% = Sect1, PCI\VEN_10DE&DEV_28E1, PCI\VEN_10DE
                    foreach ( $Str in ( $inf[$OS] -match $MatchDevID ))
                    {
                        if ( $Str -match "^[^;\r\n]+,\s*[""]?$MatchDevID($|[""\s;,])" )
                        {
                            Write-Host "  DevID: Skip adding: DevID exist in: [$OS] $Str" -ForegroundColor Green

                            $idExist = $true

                            break
                        }
                    }

                    if ( -not $idExist )
                    {
                        $Added = $true

                        # Add to [Strings]
                        if (( $genVar ) -and ( -not $addN ))
                        {
                            $addN++
                            $FixCount++
                            $N++

                            Write-Host "`n[Strings]" -ForegroundColor DarkCyan
                            Write-Host "$genVar = ""$getDispName""" -ForegroundColor White -NoNewline
                            Write-Host " | add string: $N | Total file fix: $FixCount" -ForegroundColor DarkGray

                            # Если есть строки с контентом. (без пустых/одни пробелы строк и коментов ;****)
                            $Count = 0 ; foreach ( $Str in $inf['Strings'] ) { if ( -not ( $Str -eq '' -or $Str.StartsWith(';') ) ) { $Count = 1 ; break }}

                            if ( $Count )
                            {
                                $Count = $inf['Strings'].Count

                                # С конца массива найти номер строки раздела с контентом, для добавления после него.
                                # И перед последними пустыми/одни пробелы строками и комментами раздела.
                                while ( $inf['Strings'][$Count-1] -eq '' -or $inf['Strings'][$Count-1].StartsWith(';') )
                                {
                                    $Count--
                                }
                            }

                            $inf['Strings'].Insert($Count, "$genVar = ""$getDispName""")
                        }

                        # Add to [Sections OS]
                        $FixCount++
                        $N++

                        Write-Host "`n[$OS]" -ForegroundColor DarkCyan
                        Write-Host "$quotes%$getVarName%$quotes = $addSubSection, $($aAddDevID.addDevIDtoInf)" -ForegroundColor White -NoNewline
                        Write-Host " | add string: $N | Total file fix: $FixCount" -ForegroundColor DarkGray

                        # Если есть строки с контентом. (без пустых/одни пробелы строк и коментов ;****)
                        $Count = 0 ; foreach ( $Str in $inf[$OS] ) { if ( -not ( $Str -eq '' -or $Str.StartsWith(';') ) ) { $Count = 1 ; break }}

                        if ( $Count )
                        {
                            $Count = $inf[$OS].Count

                            # С конца массива найти номер строки раздела с контентом, для добавления после него.
                            # И перед последними пустыми/одни пробелы строками и комментами раздела.
                            while ( $inf[$OS][$Count-1] -eq '' -or $inf[$OS][$Count-1].StartsWith(';') )
                            {
                                $Count--
                            }
                        }

                        $inf[$OS].Insert($Count, "$quotes%$getVarName%$quotes = $addSubSection, $($aAddDevID.addDevIDtoInf)")
                    }
                }
            }
            else
            {
                Write-Host "  DevID: Error: Not found subSection | File: $($ContentData.File)" -ForegroundColor Red

                $aWarningsGlobal += "DevID: Error: Not found subSection | File: $($ContentData.File)"

                $BoolErrorGlobal = $true

                break
            }
        }
    }


    # final | create content
    if (( $Added ) -and ( -not $BoolErrorGlobal ))
    {
        [System.Collections.Generic.List[string]] $aContentInf = @()

        foreach ( $Category in $inf.Keys )
        {
            if ( -not $Category.StartsWith(';') ) # ';NO_SECTION'
            {
                $aContentInf.Add("[$Category]")
            }

            foreach ( $Str in $inf[$Category] )
            {
                $aContentInf.Add($Str)
            }
        }

        $ContentData.FixCount = $FixCount
        $ContentData.Content  = $aContentInf
    }

    Return $ContentData
}

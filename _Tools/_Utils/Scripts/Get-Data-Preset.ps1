

Function Get-Data-Preset {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory = $false)]
        [string] $CertsFolder = $UseCertsFolderGlobal
       ,
        [Parameter(Mandatory = $false)]
        [string] $EditFolder = $EditFolderGlobal
       ,
        [Parameter(Mandatory = $false)]
        [switch] $Menu
    )

    if ( -not $Menu ) { Get-List-Presets }

    $EditFolder = $EditFolder -replace '\\Edit$',''  # = $CurrentRoot

    [PSCustomObject] $dUnPackOrFolderGlobal = @{}

    [array] $aDataCert = @()
    [array] $aDataToSignFilesGlobal   = @()
    [array] $aDataRemoveSignGlobal    = @()
    [array] $aDataNullFilesGlobal     = @()
    [array] $aDataRepackPFXFileGlobal = @()

    [System.Collections.Generic.List[PSCustomObject]] $aDataCopyFilesGlobal = @()
    [System.Collections.Generic.List[PSCustomObject]] $aDataContentFixGlobal = @()
    [System.Collections.Generic.List[PSCustomObject]] $aDataPatchGlobal = @()

    [array] $aDataCMDfilesGlobal      = @()
    [array] $aDataCMDfilesFinalGlobal = @()

     [bool] $BoolStartLocalTsGlobal  = $false
     [bool] $BoolUseBuiltInTsaGlobal = $true
    
    [string] $File     = ''
    [string] $Folder   = ''
    [string] $toFolder = ''
    [string] $unPack   = ''
    [string] $packName = ''

      [bool] $addSign  = $false
      [bool] $skipSign = $false
       [int] $ind      = 0
    [string] $alg      = ''

    [string] $Line      = ''
    [string] $Pass      = ''
    [string] $TimeStamp = ''
      [bool] $CurTime   = $false
      [bool] $GenExist  = $false

    [string] $pattern = ''
    [string] $check   = ''
    
    [string[]] $only     = @()
    [string[]] $excludes = @()

    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Local-TimeServer-Start\s*==' ))
    {
        $BoolStartLocalTsGlobal = $true
        break
    }

    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Local-TimeServer-Use\s*==' ))
    {
        $BoolUseBuiltInTsaGlobal = $false
        break
    }

    
    # UnPack-or-Folder
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*UnPack-or-Folder' ))
    {
        if ( $Line -match '^=\s*1\s*=\s*UnPack-or-Folder\s*=\s*(?<file>[^\\\s][^\\\r\n]*?)(?<ext>[.][\w]+)?\s*==\s*(?<pref>[-\w]*)\s*==\s*(?<only>[^\r\n]*?)[\\\s]*==' )
        {
            $File   = '{0}{1}' -f $Matches.file, $Matches.ext
            $Folder = '{0}{1}' -f $Matches.pref, $Matches.file  # [\w] = [a-zA-Z0-9_]

            try { $unPack = ([string[]][System.IO.Directory]::EnumerateFiles($EditFolder, $File))[-1] } catch {}  # Взять один последний файл (-like Last)
            
            if ( $unPack )
            {
                $packName = '{0}{1}' -f $Matches.pref, [System.IO.Path]::GetFileNameWithoutExtension($unPack)
                $toFolder = '{0}\Edit\{1}' -f $EditFolder, $packName

                $only     = ([regex]::Split($Matches.only,',').Trim().Trim('"')).Where({$_})

                foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*UnPack-Exclude' ))
                {
                    if ( $Line -match "^=\s*1\s*=\s*UnPack-Exclude\s*=\s*(?<file>$([regex]::Escape($File)))\s*==\s*[""]?(?<Exclude>\s*[^""\\\s][^""\r\n]*?)[""]?\s*==" )
                    {
                        $excludes += $Matches.Exclude
                    }
                }
            }
            else
            {
                try { $toFolder = ([string[]][System.IO.Directory]::EnumerateDirectories("$EditFolder\Edit", $Folder))[-1] } catch {}  # Взять одну последнюю папку (-like Last)
                
                if ( $toFolder ) { $packName = $toFolder -replace('.+\\','') }
            }

            $dUnPackOrFolderGlobal = [PSCustomObject] @{
                toFolder = $toFolder # found/unPack (fullpath to folder) [exist: archive and/or folder]
                UnPack   = $unPack   # found (fullpath to archive file) [exist]
                File     = $File     # file name + ext    [pattern]
                Folder   = $Folder   # file name + prefix [pattern]
                packName = $packName # found name + prefix [exist: archive and/or folder]
                
                onlyInclude = $only
                excludes    = $excludes
            }
            
            break
        }
    }



    # [1] Fix-Remove-Strings
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Fix-Remove-Strings' ))
    {
        if ( $Line -match '^=\s*1\s*=\s*Fix-Remove-Strings\s*=\s*\\(?<File>Edit\\((?<V>%)|[^\\\s][^\r\n]*?)\\[^\\\s][^\r\n]*?)[\\\s]*==\s*(?<Enc>[^\s]+)\s*==\s*"(?<removeString>[^\r\n]+?)"\s*==' )
        {
            $File = $Matches.File

            if ( $packName -and $Matches.v ) { $File = $File.Replace('\%\',"\$packName\") }

            $aDataContentFixGlobal.Add( @{ $File = @{
                Encoding     = $Matches.Enc
                removeString = $Matches.removeString
            }})
        }
    }

    # [2] Fix-Text-Replace
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Fix-Text-Replace' ))
    {
        if ( $Line -match '^=\s*1\s*=\s*Fix-Text-Replace\s*=\s*\\(?<File>Edit\\((?<V>%)|[^\\\s][^\r\n]*?)\\[^\\\s][^\r\n]*?)[\\\s]*==\s*(?<Enc>[^\s]+)\s*==\s*"(?<ifString>[^\r\n]+?)"\s*==\s*"(?<fromText>[^\r\n]+?)"\s*==\s*"(?<toText>[^\r\n]+?)"\s*==' )
        {
            $File = $Matches.File

            if ( $packName -and $Matches.v ) { $File = $File.Replace('\%\',"\$packName\") }

            $aDataContentFixGlobal.Add( @{ $File = @{
                Encoding = $Matches.Enc
                ifString = $Matches.ifString
                fromText = $Matches.fromText
                toText   = $Matches.toText
            }})
        }
    }

    # [3] Fix-INF-add-String
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Fix-INF-add-String' ))
    {
        if ( $Line -match '^=\s*1\s*=\s*Fix-INF-add-String\s*=\s*\\(?<FileINF>Edit\\((?<V>%)|[^\\\s][^\r\n]*?)\\[^\r\n]+?[.]inf)\s*==\s*(?<Enc>[^\s]+)\s*==\s*\[\s*(?<must>\d+)\s*\]\s*==\s*"(?<toSection>[^\r\n]+?)"\s*==\s*"(?<addString>[^\r\n]+?)"\s*==' )
        {
            $File = $Matches.FileINF

            if ( $packName -and $Matches.v ) { $File = $File.Replace('\%\',"\$packName\") }

            $aDataContentFixGlobal.Add( @{ $File = @{
                Encoding     = $Matches.Enc
                must         = $Matches.must
                toSectionInf = $Matches.toSection
                addString    = $Matches.addString
            }})
        }
    }

    # [3+] Fix-INF-add-DevID
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Fix-INF-add-DevID' ))
    {
        if ( $Line -match '^=\s*1\s*=\s*Fix-INF-add-DevID\s*=\s*\\(?<FileINF>Edit\\((?<V>%)|[^\\\s][^\r\n]*?)\\[^\r\n]+?[.]inf)\s*==\s*(?<Enc>[^\s]+)\s*==\s*\[\s*(?<must>\d+)\s*\]\s*==\s*"(?<as>[^\r\n]+?)"\s*==\s*"(?<ID>[^\r\n]+?)"\s*==\s*"(?<New>[^\r\n]*?)"\s*==\s*"(?<OS>[^\r\n]*?)"\s*==' )
        {
            $File = $Matches.FileINF

            if ( $packName -and $Matches.v ) { $File = $File.Replace('\%\',"\$packName\") }

            $aDataContentFixGlobal.Add( @{ $File = @{
                Encoding        = $Matches.Enc
                must            = $Matches.must
                addDevIDtoInf   = $Matches.ID
                asVarOrDispName = $Matches.as
                newDisplayName  = $Matches.New
                andOS           = $Matches.OS
            }})
        }
    }

    # [4] Fix-Remove-all-Text
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Fix-Remove-all-Text' ))
    {
        if ( $Line -match '^=\s*1\s*=\s*Fix-Remove-all-Text\s*=\s*\\(?<File>Edit\\((?<V>%)|[^\\\s][^\r\n]*?)\\[^\\\s][^\r\n]*?)[\\\s]*==\s*(?<Enc>[^\s]+)\s*==\s*"(?<removeAllText>[^\r\n]+?)"\s*==' )
        {
            $File = $Matches.File

            if ( $packName -and $Matches.v ) { $File = $File.Replace('\%\',"\$packName\") }

            $aDataContentFixGlobal.Add( @{ $File = @{
                Encoding      = $Matches.Enc
                removeAllText = $Matches.removeAllText
            }})
        }
    }



    # [1] Patch-PE-Univers
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Patch-PE-Univers' ))
    {
        if ( $Line -match '^=\s*1\s*=\s*Patch-PE-Univers\s*=\s*\\(?<File>Edit\\((?<V>%)|[^\\\s][^\r\n]*?)\\[^\\\s][^\r\n]*?)[\\\s]*==\s*(x|х)?(?<arch>(64|86)?)\s*==\s*\[\s*(?<need>-?\d+)\s*\]\s*\[\s*(?<max>\d+)\s*\]\s*==\s*(?<showHex>\d*)\s*==\s*"(?<uFromHex>[a-f0-9{,}?(|)\s]*?\[\[(\s*[?0-9a-f]{2}(\s*\|)?)+\s*\]\][a-f0-9{,}?(|)\s]*)"\s*==\s*"(?<toHex>(\s*[0-9a-f]{2})+)\s*"\s*==\s*(?<check>[^\r\n]*?)\s*==' )
        {
            $File  = $Matches.File
            $check = $Matches.check.Trim()

            if ( $packName -and $Matches.v )
            {
                $File = $File.Replace('\%\',"\$packName\")

                if ( $check ) { $check = $check.Replace('\%\',"\$packName\") }
            }

            $aDataPatchGlobal.Add( @{ $File = @{
                arch     = $(if ( $Matches.arch ) { 'x{0}' -f $Matches.arch } else {''})
                need     = $Matches.need
                max      = $Matches.max
                showHex  = $Matches.showHex
                uFromHex = $Matches.uFromHex
                toHex    = $Matches.toHex
                check    = $check
            }})
        }
    }

    # [2] Patch-PE-Offset
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Patch-PE-Offset' ))
    {
        if ( $Line -match '^=\s*1\s*=\s*Patch-PE-Offset\s*=\s*\\(?<File>Edit\\((?<V>%)|[^\\\s][^\r\n]*?)\\[^\\\s][^\r\n]*?)[\\\s]*==\s*(x|х)?(?<arch>(64|86)?)\s*==\s*"(?<fromHex>(\s*[0-9a-f]{2})+)\s*"\s*==\s*"(?<toHex>(\s*[0-9a-f]{2})+)\s*"\s*==\s*((?<addToSize>\d+)\+(?<addToEnd>\d+)\s+)?(0x)?0*(?<Offset>[0-9a-f]+)\s*==\s*(?<fixOffset>(0|1)?)\s*==\s*(?<fixSize>\d*)\s*==\s*(?<showHex>\d*)\s*==\s*(?<check>[^\r\n]*?)\s*==' )
        {
            $File  = $Matches.File
            $check = $Matches.check.Trim()

            if ( $packName -and $Matches.v )
            {
                $File = $File.Replace('\%\',"\$packName\")

                if ( $check ) { $check = $check.Replace('\%\',"\$packName\") }
            }

            $aDataPatchGlobal.Add( @{ $File = @{
                arch      = $(if ( $Matches.arch ) { 'x{0}' -f $Matches.arch } else {''})
                fromHex   = $Matches.fromHex
                toHex     = $Matches.toHex
                Offset    = $Matches.Offset
                fixOffset = $Matches.fixOffset
                fixSize   = $Matches.fixSize
                showHex   = $Matches.showHex
                check     = $check
                addToSize = $Matches.addToSize
                addToEnd  = $Matches.addToEnd
            }})
        }
    }

    # [3] Patch-PE-1337
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Patch-PE-1337' ))
    {
        if ( $Line -match '^=\s*1\s*=\s*Patch-PE-1337\s*=\s*\\(?<File>Edit\\((?<V>%)|[^\\\s][^\r\n]*?)\\[^\\\s][^\r\n]*?)[\\\s]*==\s*(x|х)?(?<arch>(64|86))\s*==\s*\\(?<fromHex>Edit\\[^\r\n]+?[.]1337[^"\\\s]*)\s*==\s*(?<fixOffset>(0|1)?)\s*==\s*(?<fixSize>\d*)\s*==\s*(?<showHex>\d*)\s*==\s*(?<check>[^\r\n]*?)\s*==' )
        {
            $File  = $Matches.File
            $check = $Matches.check.Trim()

            if ( $packName -and $Matches.v )
            {
                $File = $File.Replace('\%\',"\$packName\")

                if ( $check ) { $check = $check.Replace('\%\',"\$packName\") }
            }

            $aDataPatchGlobal.Add( @{ $File = @{
                arch      = 'x{0}' -f $Matches.arch
                fromHex   = $Matches.fromHex    # file 1337
                fixOffset = $Matches.fixOffset
                fixSize   = $Matches.fixSize
                showHex   = $Matches.showHex
                check     = $check
            }})
        }
    }



    # PFX
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*PFX-Cert' ))
    {
        $CurTime = $false

        # PFX data (год от 1970 по 2099)
        if ( $Line -match '^=\s*1\s*=\s*PFX-Cert\s*=\s*(?<FilePFX>[^"\\\r\n]+?[.]pfx)\s*==\s*(?<Pass>[^\s]*?)\s*==\s*(?<Timestamp>(([1][9][7-9][0-9]|[2][0][0-9][0-9])-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}|https?:\/\/[^\/\s][^\r\n]+)?)\s*==\s*(?<Cross>[^\\\s]*?)\s*==' )
        {
            $TimeStamp = $Matches.Timestamp.Trim()

            if ( -not $TimeStamp )
            {
                $TimeStamp = [datetime]::Now.ToString('yyyy-MM-ddTHH:mm:ss')   # Current non-UTC Only for show
                $CurTime   = $true
            }

            if ( -not ( $aDataCert.FileCert -eq $Matches.FilePFX ))
            {
                $aDataCert += [PSCustomObject]@{
                    FileCert  = $Matches.FilePFX
                    Pass      = $Matches.Pass
                    TimeStamp = $TimeStamp
                    FileCross = $Matches.Cross
                    CurTime   = $CurTime
                }
            }
        }
    }

   
    # Gen
    if ( [System.IO.File]::Exists("$CertsFolder\Gen-Sign.crt") ) { $GenExist = $true }

    if ( $GenExist )
    {
        $Pass = ''

        # pass (Gen)
        foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Gen-Cert-Pass' ))
        {
            if ( $Line -match '^=\s*1\s*=\s*Gen-Cert-Pass\s*=\s*(?<Pass>[^\s]+)\s*==' )
            {
                $Pass = $Matches.Pass

                break
            }
        }

        $TimeStamp = [datetime]::Now.ToString('yyyy-MM-ddTHH:mm:ss')   # Current non-UTC Only for show
        $CurTime   = $true

        # Timestamp (год от 1970 по 2099)
        foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Gen-Server-Timestamp' ))
        {
            if ( $Line -match '^=\s*1\s*=\s*Gen-Server-Timestamp\s*=\s*(?<Timestamp>(([1][9][7-9][0-9]|[2][0][0-9][0-9])-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}|https?:\/\/[^\/\s][^\r\n]+))\s*==' )
            {
                $TimeStamp = $Matches.Timestamp.TrimEnd()
                $CurTime   = $false

                break
            }
        }
    }


    # PFX-To-Sign or/and Gen-To-Sign
    if ( $GenExist -or $aDataCert.Count )
    {
        if     ( $GenExist -and $aDataCert.Count ) { $pattern = '^=\s*1\s*=\s*(Gen|PFX)-To-Sign-' }
        elseif ( $GenExist                       ) { $pattern = '^=\s*1\s*=\s*Gen-To-Sign-'       }
        else                                       { $pattern = '^=\s*1\s*=\s*PFX-To-Sign-'       }

        foreach ( $Line in ( $ListPresetsGlobal -match $pattern ))
        {
            # PFX

            # PFX (non-CAT)
            if     ( $Line -match '^=\s*1\s*=\s*PFX-To-Sign-File\s*=\s*(?<FilePFX>[^"\\\r\n]+?[.]pfx)\s*==\s*\\(?<Sign>Edit\\((?<V>%)|[^\\\s][^\r\n]*?)\\[^\\\s][^\r\n]*?)[\\\s]*==\s*(?<iAdd>\+)?(?<ST>(ST|TS|S|T))(?<ind>\d)?(\s+(sha)?(?<alg>(1|256|384|512)))?\s*==' )
            {
                $File = $Matches.Sign
                $alg  = $(if ( $Matches.alg ) { 'sha{0}' -f $Matches.alg } else {''})
                if ( $Matches.iAdd ) { $addSign = $true } else { $addSign = $false }
                if ( $addSign ) { if ( $Matches.ST -eq 'T' ) { $ind = $Matches.ind } else { $ind = 1 }} else { $ind = 0 }

                if ( $packName -and $Matches.v ) { $File = $File.Replace('\%\',"\$packName\") }

                # Если настройка для первой подписи, но уже есть для первой, то пропустить подпись
                if (( -not $addSign ) -and $aDataToSignFilesGlobal.Where({ $_.SignFile -eq $File -and -not $_.addSign },'First').Count )
                { $skipSign = $true } else { $skipSign = $false }

                if ( $addSign -or (-not ( $skipSign -or ( $File -like '*.ca[t?]' )))) # .ca? универсальное указание в пресете для запакованных файлов, не для cat просто учесть обман для пропуска
                {
                    $Cert = $aDataCert.Where({ $_.FileCert -eq $Matches.FilePFX },'First')

                    if ( $Cert.FileCert -and ( [System.IO.File]::Exists("$CertsFolder\$($Cert.FileCert)") ))
                    {
                        $aDataToSignFilesGlobal += [PSCustomObject]@{

                            SignFile  = $File
                            OS        = ''
                            ST        = $Matches.ST
                            
                            isCAT     = $false
                            CertType  = 'PFX'

                            FileCert  = $Cert.FileCert
                            Pass      = $Cert.Pass
                            TimeStamp = $Cert.TimeStamp
                            CurTime   = $Cert.CurTime
                            FileCross = $Cert.FileCross
                            
                            AlgForce  = $alg
                            AddIndex  = $ind
                            addSign   = $addSign
                        }
                    }
                }
            }

            # PFX (CAT)
            elseif ( $Line -match '^=\s*1\s*=\s*PFX-To-Sign-CatFile\s*=\s*(?<FilePFX>[^"\\\r\n]+?[.]pfx)\s*==\s*\\(?<Sign>Edit\\((?<V>%)|[^\\\s][^\r\n]*?)\\[^\r\n]+?[.]cat)\s*==\s*(?<OS>[^\\\s][^"\\\r\n]+?)\s*==' )
            {
                $File = $Matches.Sign

                if ( $packName -and $Matches.v ) { $File = $File.Replace('\%\',"\$packName\") }

                if ( -not ( $aDataToSignFilesGlobal.SignFile -eq $File ))
                {
                    $Cert = $aDataCert.Where({ $_.FileCert -eq $Matches.FilePFX },'First')

                    if ( $Cert.FileCert -and ( [System.IO.File]::Exists("$CertsFolder\$($Cert.FileCert)") ))
                    {
                        $aDataToSignFilesGlobal += [PSCustomObject]@{

                            SignFile  = $File
                            OS        = $Matches.OS.Split(',').Trim() -join ','
                            ST        = ''
                            
                            isCAT     = $true
                            CertType  = 'PFX'

                            FileCert  = $Cert.FileCert
                            Pass      = $Cert.Pass
                            TimeStamp = $Cert.TimeStamp
                            CurTime   = $Cert.CurTime
                            FileCross = $Cert.FileCross
                        }
                    }
                }
            }



            # Gen

            # Gen (non-CAT)
            elseif ( $Line -match '^=\s*1\s*=\s*Gen-To-Sign-File\s*=\s*\\(?<Sign>Edit\\((?<V>%)|[^\\\s][^\r\n]*?)\\[^\\\s][^\r\n]*?)[\\\s]*==\s*(?<iAdd>\+)?(?<ST>(ST|TS|S|T))(?<ind>\d)?(\s+(sha)?(?<alg>(1|256|384|512)))?\s*==' )
            {
                $File = $Matches.Sign
                $alg  = $(if ( $Matches.alg ) { 'sha{0}' -f $Matches.alg } else {''})
                if ( $Matches.iAdd ) { $addSign = $true } else { $addSign = $false }
                if ( $addSign ) { if ( $Matches.ST -eq 'T' ) { $ind = $Matches.ind } else { $ind = 1 }} else { $ind = 0 }

                if ( $packName -and $Matches.v ) { $File = $File.Replace('\%\',"\$packName\") }

                # Если настройка для первой подписи, но уже есть для первой, то пропустить подпись
                if (( -not $addSign ) -and $aDataToSignFilesGlobal.Where({ $_.SignFile -eq $File -and -not $_.addSign },'First').Count )
                { $skipSign = $true } else { $skipSign = $false }

                if ( $addSign -or (-not ( $skipSign -or ( $File -like '*.ca[t?]' )))) # .ca? универсальное указание в пресете для запакованных файлов, не для cat просто учесть обман для пропуска
                {
                    $aDataToSignFilesGlobal += [PSCustomObject]@{

                        SignFile  = $File
                        OS        = ''
                        ST        = $Matches.ST

                        isCAT     = $false
                        CertType  = 'Gen-Sign.crt'

                        FileCert  = 'Gen-Sign.crt'
                        Pass      = $Pass
                        TimeStamp = $TimeStamp
                        CurTime   = $CurTime
                        FileCross = ''

                        AlgForce  = $alg
                        AddIndex  = $ind
                        addSign   = $addSign
                    }
                }
            }
            
            # Gen (CAT)
            elseif ( $Line -match '^=\s*1\s*=\s*Gen-To-Sign-CatFile\s*=\s*\\(?<Sign>Edit\\((?<V>%)|[^\\\s][^\r\n]*?)\\[^\r\n]+?[.]cat)\s*==\s*(?<OS>[^\\\s][^"\\\r\n]+?)\s*==' )
            {
                $File = $Matches.Sign

                if ( $packName -and $Matches.v ) { $File = $File.Replace('\%\',"\$packName\") }

                if ( -not ( $aDataToSignFilesGlobal.SignFile -eq $File ))
                {
                    $aDataToSignFilesGlobal += [PSCustomObject]@{

                        SignFile  = $File
                        OS        = $Matches.OS.Split(',').Trim() -join ','
                        ST        = ''

                        isCAT     = $true
                        CertType  = 'Gen-Sign.crt'

                        FileCert  = 'Gen-Sign.crt'
                        Pass      = $Pass
                        TimeStamp = $TimeStamp
                        CurTime   = $CurTime
                        FileCross = ''
                    }
                }
            }
        }
    }



    # UnSign
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*UnSign-File' ))
    {
        if ( $Line -match '^=\s*1\s*=\s*UnSign-File\s*=\s*\\(?<UnSign>Edit\\((?<V>%)|[^\\\s][^\r\n]*?)\\[^\\\s][^\r\n]*?)[\\\s]*==' )
        {
            $File = $Matches.UnSign

            if ( $packName -and $Matches.v ) { $File = $File.Replace('\%\',"\$packName\") }

            if ( -not ( $aDataRemoveSignGlobal -eq $File ))
            {
                if ( -not ( $File -like '*.ca[t?]' )) # .ca? универсальное указание в пресете для запакованных файлов .ca_ или .cat
                {
                    $aDataRemoveSignGlobal += $File
                }
            }
        }
    }


    # Run-CMD-File
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Run-CMD-File' ))
    {
        if ( $Line -match '^=\s*1\s*=\s*Run-CMD-File\s*=\s*\\(?<cmd>Edit\\[^\\\s][^\r\n]*?[.](cmd|bat))\s*==' )
        {
            if ( -not ( $aDataCMDfilesGlobal -eq $Matches.cmd ) -and ( [System.IO.File]::Exists("$EditFolder\$($Matches.cmd)") ))
            {
                $aDataCMDfilesGlobal += $Matches.cmd
            }
        }
        elseif ( $Line -match '^=\s*1\s*=\s*Run-CMD-File-Final\s*=\s*\\(?<cmd>Edit\\[^\\\s][^\r\n]*?[.](cmd|bat))\s*==' )
        {
            if ( -not ( $aDataCMDfilesFinalGlobal -eq $Matches.cmd ) -and ( [System.IO.File]::Exists("$EditFolder\$($Matches.cmd)") ))
            {
                $aDataCMDfilesFinalGlobal += $Matches.cmd
            }
        }
    }


    # Null
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Null-File' ))
    {
        if ( $Line -match '^=\s*1\s*=\s*Null-File\s*=\s*\\(?<Null>Edit\\((?<V>%)|[^\\\s][^\r\n]*?)\\[^\\\s][^\r\n]*?)[\\\s]*==' )
        {
            $File = $Matches.Null

            if ( $packName -and $Matches.v ) { $File = $File.Replace('\%\',"\$packName\") }

            if ( -not ( $aDataNullFilesGlobal -eq $File ))
            {
                if ( -not ( $File -like '*.ca[t?]' )) # .ca? универсальное указание в пресете для запакованных файлов .ca_ или .cat
                {
                    $aDataNullFilesGlobal += $File
                }
            }
        }
    }


    # Copy
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Copy-File' ))
    {
        if ( $Line -match '^=\s*1\s*=\s*Copy-File\s*=\s*\\(?<File>Edit\\[^\\\s][^\r\n]*?)[\\\s]*==\s*\\(?<CopyTo>Edit\\((?<V>%)|[^\\\r\n]+?)(\\|\\[^\\\s][^\r\n]*?\\))[\\\s]*==' )
        {
            $File = $Matches.CopyTo

            if ( $packName -and $Matches.v ) { $File = $File.Replace('\%\',"\$packName\") }

            if ( -not ( $aDataCopyFilesGlobal.File -eq $Matches.File ))
            {
                $aDataCopyFilesGlobal.Add( [PSCustomObject] @{ 
                    File   = $Matches.File
                    CopyTo = $File   # '{0}\' -f $Matches.CopyTo
                })
            }
        }
    }


    # Repack-PFX
    foreach ( $Line in ( $ListPresetsGlobal -match '^=\s*1\s*=\s*Repack-PFX-File' ))
    {
        if ( $Line -match '^=\s*1\s*=\s*Repack-PFX-File\s*=\s*(?<FilePFX>[^"\\\r\n]+?[.]pfx)\s*==\s*(?<Pass>[^\s]*?)\s*==\s*(?<NewPass>[^\s]*?)\s*==\s*(?<Cross>[^"\\\s]*?)\s*==' )
        {
            if ( -not ( $aDataRepackPFXFileGlobal.FilePFX -eq $Matches.FilePFX ) -and [System.IO.File]::Exists("$CertsFolder\$($Matches.FilePFX)"))
            {
                $aDataRepackPFXFileGlobal += [PSCustomObject]@{
                    FilePFX   = $Matches.FilePFX
                    Pass      = $Matches.Pass
                    NewPass   = $Matches.NewPass
                    FileCross = $Matches.Cross
                }
            }
        }
    }
}



# v2
Function Sign-Files {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory = $false)]
        [string] $EditFolder = $EditFolderGlobal
       ,
        [Parameter(Mandatory = $false)]
        [string] $UseCertsFolder = $UseCertsFolderGlobal
       ,
        [Parameter(Mandatory = $false)]
        [string] $TempDir = $ScratchDirGlobal
       ,
        [Parameter(Mandatory = $false)]
        [string] $Openssl = $Openssl # need v3.1.1
       ,
        [Parameter(Mandatory = $false)]
        [string] $osslsigncode = $osslsigncode # from v2.8-dev (от 23.01.2024)
       ,
        [Parameter(Mandatory = $false)]
        [string] $signtool = $signtool
       ,
        [Parameter(Mandatory = $false)]
        [string] $Inf2Cat = $Inf2Cat
       ,
        [Parameter(Mandatory = $false)]
        [switch] $ReGenerateCAT
       ,
        [Parameter(Mandatory = $false)]
        [switch] $OnlySign
    )

    Get-Data-Preset

    Remove-Item -Path $TempDir\* -Force -ErrorAction SilentlyContinue

     [bool] $BoolErrorGlobal   = $false

    [array] $aWarningsGlobal   = @()
    [array] $aAttentionsGlobal = @()

    [System.Collections.Generic.List[PSCustomObject]] $aActionsGlobal = @()

    if ( -not $OnlySign )
    {
        if ( -not $BoolErrorGlobal )
        {
            UnPack-Archive -NotStop -NotGetData

            if ( $BoolErrorGlobal )
            {
                Write-host
                Write-host '   Sign:' -ForegroundColor White -BackgroundColor DarkCyan -NoNewline
                Write-host ' Sign files' -ForegroundColor Cyan

                Write-host '   Sign: Error: UnPack Archive' -ForegroundColor Red

                $aWarningsGlobal += 'Sign: Error: UnPack Archive'
            }
        }


        if ( -not $BoolErrorGlobal )
        {
            Run-CMD-Files -NotStop -NotGetData

            if ( $BoolErrorGlobal )
            {
                Write-host
                Write-host '   Sign:' -ForegroundColor White -BackgroundColor DarkCyan -NoNewline
                Write-host ' Sign files' -ForegroundColor Cyan

                Write-host '   Sign: Error: Run-CMD-Files' -ForegroundColor Red

                $aWarningsGlobal += 'Sign: Error: Run-CMD-Files'
            }
        }

        if ( -not $BoolErrorGlobal )
        {
            UnSign-Files -NotStop -NotGetData

            Null-Files   -NotStop -NotGetData
        }

        if ( -not $BoolErrorGlobal )
        {
            Copy-Files -NotStop -NotGetData

            if ( $BoolErrorGlobal )
            {
                Write-host
                Write-host '   Sign:' -ForegroundColor White -BackgroundColor DarkCyan -NoNewline
                Write-host ' Sign files' -ForegroundColor Cyan

                Write-host '   Sign: Error: Copying a file' -ForegroundColor Red

                $aWarningsGlobal += 'Sign: Error: Copying a file'
            }
        }


        if ( -not $BoolErrorGlobal )
        {
            Fix-Content -NotStop -NotGetData

            if ( $BoolErrorGlobal )
            {
                Write-host
                Write-host '   Sign:' -ForegroundColor White -BackgroundColor DarkCyan -NoNewline
                Write-host ' Sign files' -ForegroundColor Cyan

                Write-host '   Sign: Error: Fix Content' -ForegroundColor Red

                $aWarningsGlobal += 'Sign: Error: Fix Content'
            }
        }


        if ( -not $BoolErrorGlobal )
        {
            Patch-PE -NotStop -NotGetData   # fromSign для не удаления распакованного файла после патчей, если файл в списке на подпись.

            if ( $BoolErrorGlobal )
            {
                Write-host
                Write-host '   Sign:' -ForegroundColor White -BackgroundColor DarkCyan -NoNewline
                Write-host ' Sign files' -ForegroundColor Cyan

                Write-host '   Sign: Error/Test: Patch PE' -ForegroundColor Red

                $aWarningsGlobal += 'Sign: Error/Test: Patch PE'
            }
        }
    }


    if ( -not $BoolErrorGlobal )
    {
        Write-host
        Write-host '   Sign:' -ForegroundColor White -BackgroundColor DarkCyan -NoNewline
        Write-host ' Sign files' -ForegroundColor Cyan
    }


    [PSCustomObject] $dAction = @{}

    [string] $SALT = 97456214756 # Приписка для временной переименовки файлов

    [array] $x509params = '-certopt', 'no_header,no_sigdump,no_extensions,no_pubkey,no_serial,no_validity,no_issuer,no_subject,no_aux'
    [string[]] $iCert   = @()

    [System.IO.FileSystemInfo] $GetItem = $null
    [string[]] $Attr = @()

    [string] $getName      = ''
    [string] $getPath      = ''
    [string] $UnpackFile   = ''
    [string] $FilePath     = ''
    [string] $FilePathOrig = ''
    [string] $ShowFile     = ''
    [string] $ShowFileOrig = ''

    [string] $FilePFX   = ''
    [string] $namePFX   = ''
    [string] $PathPFX   = ''
    [string] $Pass      = ''
    [string] $GenPass   = ''
    [string] $TimeStamp = ''
     [int64] $Time      = 0  # for UnixTimeSeconds [long]
    [string] $URL       = ''
    [string] $Alg       = ''
    [string] $SigAlg    = ''
    [string] $GenSigAlg = ''

    [string] $AlgForce  = '' # принудительно указаный алгоритм sha1/256/384/512
       [int] $AddIndex  = 0  # для указания индекса метки или добавления новой подписи при = 1
    [string] $AddShow   = ''
      [bool] $addSign   = $false # нужно чтобы работало когда добаление только метки на 0 индекс, и сравнивать с $AddIndex не вариант при 0

      [bool] $CurTime   = $false
    [string] $ST_S      = '' # sign
    [string] $ST_T      = '' # timestamp
    [string] $ST_SHOW   = '' # что выпонялось для таблицы в конце

    [string] $ClientInt = ''
    [string] $ClientKEY = ''

    [string] $FileCross = ''
    [string] $UseCross  = ''
    [string] $Sign      = ''
      [bool] $OK        = 0

    [string] $OS          = ''
    [string] $PathPattern = ''
    [string] $Path        = ''
    [string] $Path        = ''
    [string] $File        = ''
    [string] $FileName    = ''
    [string] $FileEXT     = ''
    [string] $TempFile    = ''
    [string] $CertType    = ''
    [string] $FileType    = ''
    [string] $CertFile    = ''
    [string] $color       = ''
    [string] $A           = ''

    [string] $Metod  = ''
    [string] $TsaCrt = ''
    [string] $TsaKey = ''

    [array] $aFilesCAT    = @()
    [array] $aFilesINF    = @()
    [array] $aFilePaths   = @()

    [array] $aPathGenCATs = @()
    [array] $aPFXchecked  = @()
    [array] $aUsePFX      = @()
    [array] $aComm        = @()

    [int] $N  = 0
    [int] $N2 = 0
    [int] $N3 = 0

    # Также добавляем тип ServiceProcess из .NET к текущему сеансу, для управления службами.
    if ( -not ( 'System.ServiceProcess.ServiceController' -as [type] )) { Add-Type -AssemblyName 'System.ServiceProcess' -ErrorAction Stop }

    # Пробуем подключение к службе. RasMan обязательная для RFC3161
    $Service = [System.ServiceProcess.ServiceController]::new('RasMan')

    [string] $Folder = $EditFolder -replace '\\Edit$',''

    # Проверка сертификатов Gen (один раз)
    $ClientInt = '{0}\{1}' -f $UseCertsFolder, 'Gen-Sign.crt'
    $ClientKEY = '{0}\{1}' -f $UseCertsFolder, 'Gen-Sign.key'
    $RootCrt   = '{0}\{1}' -f $UseCertsFolder, 'Gen-Root.crt'

    [bool] $GenExist  = $false
    [bool] $PassWrong = $true

    if (     [System.IO.File]::Exists($RootCrt) `
        -and [System.IO.File]::Exists($ClientInt) `
        -and [System.IO.File]::Exists($ClientKEY) `
    )
    {
        $GenExist = $true

        $GenPass = $aDataToSignFilesGlobal.Where({ $_.FileCert -eq 'Gen-Sign.crt' },'First').Pass

        [string[]] $Key = & $Openssl pkey -in $ClientKEY -pubcheck -noout -passin pass:$GenPass 2>&1

        if ( $Key -like 'Key is valid' )
        {
            $PassWrong = $false
        }

        # Cert info
        $iCert = & $openssl x509 -in $ClientInt -text -noout $x509params 2>$null
        $GenSigAlg = [regex]::Match($iCert,'Signature Algorithm: (?<Name>(md|sha)[\d]+)',4).Groups['Name'].Value
    }


    # вычислить максимальную длину имен файлов сертификатов для выравнивания отступом при выводе в меню для PFX: и Sign:
    [int] $iIndentSize = 0

    foreach ( $f in $aDataToSignFilesGlobal.FileCert )
    {
        $iIndentSize = [math]::Max($f.Length, $iIndentSize)
    }



    [System.Collections.Generic.List[PSObject]] $aStages = @()

    # [1]: Signing non-CAT files (first Signs)
    $aStages.Add( [PSCustomObject] @{
        FileType = 'non-CAT'
        aData    = @($aDataToSignFilesGlobal.Where({( -not $_.addSign ) -and ( -not $_.isCAT )}))
    })

    # [1]: Signing non-CAT files (+ Add Signs)
    $aStages.Add( [PSCustomObject] @{
        FileType = 'non-CAT'
        aData    = @($aDataToSignFilesGlobal.Where({(      $_.addSign ) -and ( -not $_.isCAT )}))
    })

    # [2]: Signing CAT files
    $aStages.Add( [PSCustomObject] @{
        FileType = 'CAT'
        aData    = @($aDataToSignFilesGlobal.Where({ $_.isCAT }))
    })


    # 2 Этапа
    foreach ( $Stage in $aStages )
    {
        if ( $aWarningsGlobal.Count ) { break }

        $FileType = $Stage.FileType

        $N2 = 0
        $N3 = 0

        # Файлы
        foreach ( $Data in $Stage.aData )
        {
            if ( $aWarningsGlobal.Count ) { break }

            $CertType = $Data.CertType

            $N++

            if ( -not $N2 )
            {
                if ( $N - 1 ) { Write-host "`n" }

                Write-host '   Sign:' -ForegroundColor Black -BackgroundColor DarkGray -NoNewline
                Write-host " Signing $FileType files with $CertType " -ForegroundColor Gray -BackgroundColor DarkBlue
            }


            $N2++

            $Sign    = $Data.SignFile
            $CurTime = $Data.CurTime
            $OS      = $Data.OS

            $AlgForce  = $Data.AlgForce  # принудительно указаный алгоритм sha1/256/384/512 (кроме CAT)
            $AddIndex  = $Data.AddIndex  # для указания индекса метки или добавления новой подписи при = 1 (кроме CAT)
            $addSign   = $Data.addSign   # для указания добавления подписи или метки на 0 индекс

            $FileCross = ''
            $UseCross  = ''


            $ST_S = 'S' # sign
            $ST_T = 'T' # timestamp

            if ( $Data.ST )
            {
                if     ( $Data.ST -eq 'S' ) { $ST_T = '' }  # only Sign
                elseif ( $Data.ST -eq 'T' ) { $ST_S = '' }  # only TimeStamp
            }


            if ( -not $Sign )
            {
                Write-host "   Sign: Skipped | Error: There is no specified file to sign for $CertType" -ForegroundColor Red

                $aWarningsGlobal += "Sign: Skipped | Error: There is no specified file to sign for $CertType"

                break
            }

            if ( $CertType -eq 'Gen-Sign.crt' )    # GEN
            {
                if ( -not $GenExist )
                {
                    Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                    Write-host 'No Gen certificates' -ForegroundColor Yellow

                    $aWarningsGlobal += "Sign: No Gen certificates"

                    break
                }
                elseif ( $PassWrong )
                {
                    Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                    Write-host 'Pass Wrong (Gen)' -ForegroundColor Yellow

                    $aWarningsGlobal += "Sign: Pass Wrong (Gen)"

                    break
                }

                $CertFile  = 'Gen-Sign.crt'
                $ClientInt = '{0}\{1}' -f $UseCertsFolder, 'Gen-Sign.crt'
                $ClientKEY = '{0}\{1}' -f $UseCertsFolder, 'Gen-Sign.key'
                $Pass      = $GenPass
                $SigAlg    = $GenSigAlg
            }
            else   # PFX
            {
                $FilePFX   = '{0}\{1}' -f $UseCertsFolder, $Data.FileCert
                $Pass      = $Data.Pass

                $CertFile  = [System.IO.Path]::GetFileName($FilePFX)
                $namePFX   = [System.IO.Path]::GetFileNameWithoutExtension($FilePFX)
                $PathPFX   = [System.IO.Path]::GetDirectoryName($FilePFX)

                if ( $Data.FileCross )
                {
                    $FileCross = '{0}\{1}' -f $UseCertsFolder, $Data.FileCross
                    $UseCross  = "$PathPFX\$namePFX`_Cross.crt"
                }

                $ClientInt = "$TempDir\$namePFX`_Client+Int.crt"
                $ClientKEY = "$TempDir\$namePFX`_.key"

                if ( -not ( $aPFXchecked -like $FilePFX ))
                {
                    $aPFXchecked += $FilePFX

                    if ( $UseCross )
                    {
                        $OK = Repack-PFX -FilePFX $FilePFX -Pass:$Pass -AddCross -CrossCertFile $FileCross -SaveForSign -TBS
                    }
                    else
                    {
                        $OK = Repack-PFX -FilePFX $FilePFX -Pass:$Pass -SaveForSign -TBS
                    }

                    if ( $OK ) { $aUsePFX += $FilePFX }
                }

                if ( -not ( $aUsePFX -like $FilePFX ))
                {
                    Write-host '   Sign: Skipped | Error PFX: ' -ForegroundColor Red -NoNewline
                    Write-host $CertFile -ForegroundColor White -NoNewline
                    Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                    Write-host $Sign -ForegroundColor Red

                    $aWarningsGlobal += "Sign: Skipped | Error PFX: $CertFile"

                    break
                }

                # Cert info
                $iCert  = & $openssl x509 -in $ClientInt -text -noout $x509params 2>$null
                $SigAlg = [regex]::Match($iCert,'Signature Algorithm: (?<Name>(md|sha)[\d]+)',4).Groups['Name'].Value
            }


            if ( -not $SigAlg )
            {
                Write-host '   Sign: Skipped | Error: With Client cert in: ' -ForegroundColor Red -NoNewline
                Write-host $CertFile -ForegroundColor White -NoNewline
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-host $Sign -ForegroundColor Red

                $aWarningsGlobal += "Sign: Skipped | Error: With Client cert in $CertType | $Sign"

                if ( $CertType -eq 'PFX' ) { $aUsePFX = $aUsePFX -notlike $FilePFX }

                break
            }


            # замена алгоритма подписи на указанный
            if ( $AlgForce )
            {
                $SigAlg = $AlgForce
            }

            # Алгоритм подписи исходя из сигнатуры сертификата для внешнего URL
            if ( $SigAlg -match '^(md5|sha1)$' )
            {
                $Alg = 'SHA1'   # алгоритм метки (реализовал только 2 варианта для метки)

                $TsaCrt = "$UseCertsFolder\Gen-TSA1.crt"
                $TsaKey = "$UseCertsFolder\Gen-TSA.key"
            }
            else
            {
                $Alg = 'SHA256' # алгоритм метки (реализовал только 2 варианта для метки)

                $TsaCrt = "$UseCertsFolder\Gen-TSA2.crt"
                $TsaKey = "$UseCertsFolder\Gen-TSA.key"
            }

            if ( $Data.TimeStamp -like 'http*' )
            {
                $TimeStamp = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss') # [datetime]::UtcNow.ToString('s')
                $URL       = $Data.TimeStamp
                $Time      = ([DateTimeOffset][datetime]::Parse($TimeStamp)).ToUnixTimeSeconds()
            }
            else
            {
                # Если нет хотябы одного сертификата TSA
                if ( -not ( $PrintTSAGlobal.print1 -and $PrintTSAGlobal.print2 ))
                {
                    if ( $BoolUseBuiltInTsaGlobal )
                    {
                        Write-host '   Sign: Skipped | Error: No TSA1 and/or TSA2 certificates' -ForegroundColor Red

                        $aWarningsGlobal += "Sign: Skipped | Error: No TSA1 and/or TSA2 certificates"
                    }
                    else
                    {
                        Write-host '   Sign: Skipped | Error: Local timestamp server is not active' -ForegroundColor Red

                        $aWarningsGlobal += "Sign: Skipped | Error: Local timestamp server is not active"
                    }

                    break
                }

                # Алгоритм для выбранного локального сервера TSA (Gen), можно для сертификата SHA1 делать метку сертификатом SHA256
                #$Alg = $PrintTSAGlobal.Alg  # SHA1/SHA256

                if ( $CurTime )
                {
                    $TimeStamp = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss') # [datetime]::UtcNow.ToString('s')
                }
                else
                {
                    $TimeStamp = $Data.TimeStamp
                }

                if ( -not $BoolUseBuiltInTsaGlobal )
                {
                    $URL = "http://localhost:80/TS-$Alg/$TimeStamp"
                }
                else
                {
                    $URL = 'built-in TSA'
                }

                $Time = ([DateTimeOffset][datetime]::Parse($TimeStamp)).ToUnixTimeSeconds()
            }

            # hide pass
            if ( $Pass.Length -gt 1 )
            {
                $ShowPass = '{0}{1}' -f ($Pass[0]), ('*' * ($Pass.Length - 1))
            }
            elseif ( $Pass.Length -eq 1 )
            {
                $ShowPass = '*'
            }
            else
            {
                $ShowPass = ''
            }

            Write-host
            Write-host '   Sign:      Cert: ' -ForegroundColor DarkGray -NoNewline
            Write-host $CertFile -ForegroundColor Cyan -NoNewline
            Write-host ' | ' -ForegroundColor DarkGray -NoNewline
            Write-host 'Checked' -ForegroundColor Green -NoNewline
            Write-host ' | SigAlg: ' -ForegroundColor DarkGray -NoNewline
            Write-host $SigAlg -ForegroundColor DarkCyan -NoNewline

            if ( $ShowPass )
            {
                Write-host ' | [Pass:' -ForegroundColor DarkGray -NoNewline
                Write-host $ShowPass -ForegroundColor DarkCyan -NoNewline
                Write-host ']' -ForegroundColor DarkGray
            }
            else
            {
                Write-host ' | [no Pass]' -ForegroundColor DarkGray
            }

            if ( $CertType -eq 'PFX' )
            {
                Write-host '   Sign: ClientInt: ' -ForegroundColor DarkGray -NoNewline
                Write-host $([System.IO.Path]::GetFileName($ClientInt)) -ForegroundColor Gray

                Write-host '   Sign: ClientKey: ' -ForegroundColor DarkGray -NoNewline
                Write-host $([System.IO.Path]::GetFileName($ClientKEY)) -ForegroundColor Gray

                if ( $UseCross )
                {
                    Write-host '   Sign:     Cross: ' -ForegroundColor DarkGray -NoNewline
                    Write-host $([System.IO.Path]::GetFileName($UseCross)) -ForegroundColor Gray
                }
            }


            # [TimeStamp] общий для Gen-Sign.crt
            Write-host '   Sign: TimeStamp: ' -ForegroundColor DarkGray -NoNewline
            Write-host $TimeStamp -ForegroundColor Gray -NoNewline
            Write-host ' | UTC | Alg: ' -ForegroundColor DarkGray -NoNewline
            Write-host $Alg -ForegroundColor DarkCyan

            Write-host '   Sign:    TS URL: ' -ForegroundColor DarkGray -NoNewline
            Write-host $URL -ForegroundColor Gray


            if ( $OS )
            {
                Write-host '   Sign:        OS: ' -ForegroundColor DarkGray -NoNewline
                Write-host $OS -ForegroundColor DarkCyan
            }

            Write-host
            Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
            Write-host $Sign -ForegroundColor White -NoNewline
            Write-host ' ◄ ' -ForegroundColor DarkGray -NoNewline
            Write-host 'Name pattern' -ForegroundColor White


            # если добавление подписи или указание индекса когда один timestamp
            if ( $addSign )
            {
                # если только timestamp
                if ( -not $ST_S )
                {
                    Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                    Write-host 'Only timestamp on index: ' -ForegroundColor DarkMagenta -NoNewline
                    
                    if ( $AddIndex -ge 2 )
                    {
                        Write-host $AddIndex -ForegroundColor Blue
                    }
                    elseif ( $AddIndex -eq 1 )
                    {
                        Write-host $AddIndex -ForegroundColor Blue
                    }
                    else
                    {
                        Write-host $AddIndex -ForegroundColor DarkGray
                    }
                }
                else
                {
                    Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                    Write-host 'Adding sign index: ' -ForegroundColor DarkMagenta -NoNewline
                    Write-host $AddIndex -ForegroundColor Blue
                }
            }




            $N3 = 0

            if ( $FileType -eq 'CAT' )
            {
                # Проверка наличия CAT файлов / Регенерация CAT
                $aFilesCAT = Get-ChildItem -Path $Folder\$Sign -File -ErrorAction SilentlyContinue

                if ( $ReGenerateCAT -or ( -not $aFilesCAT.Count ))
                {
                    # шаблон поиска указанного файла .cat
                    $PathPattern = "$Folder\$Sign"
                    $Path        = [System.IO.Path]::GetDirectoryName($PathPattern)

                    if ( $aPathGenCATs -like $Path )
                    {
                        Write-host '   Sign: Already reGenerated CAT | ' -ForegroundColor DarkGray -NoNewline
                        Write-host $Path -ForegroundColor White
                    }
                    else
                    {
                        if ( $ReGenerateCAT )
                        {
                            Write-host '   Sign: reGenerate CAT | ' -ForegroundColor DarkGray -NoNewline
                            Write-host 'All CAT files will be signed!' -ForegroundColor Magenta

                            # шаблон поиска любых файлов .cat, которые могут появиться после Inf2Cat
                            $PathPattern = "$Path\*.cat"
                        }
                        
                        if ( -not $aFilesCAT.Count )
                        {
                            Write-host '   Sign: No CAT files' -ForegroundColor DarkGray
                        }
                        else
                        {
                            foreach ( $GetItem in $aFilesCAT ) 
                            {
                                if ( $GetItem.Attributes -match 'readonly|hidden|system' )
                                {
                                    $Attr = [regex]::Split($GetItem.Attributes, ',').Trim() ; $GetItem.Attributes = ( $Attr -notmatch 'readonly|hidden|system' )
                                }
                            }

                            $GetItem = $null
                        }

                        $aFilesINF = Get-ChildItem -Path $Path\*.inf -File -ErrorAction SilentlyContinue

                        if ( -not $aFilesINF.Count )
                        {
                            Write-host "   Sign: Skipped | No Inf files | $Path\*.inf" -ForegroundColor Yellow

                            $aWarningsGlobal += "Sign: Skipped | No Inf files | $Path\*.inf"

                            break
                        }

                        Write-host
                        Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                        Write-host 'Inf2Cat: driver: ' -ForegroundColor DarkCyan -NoNewline
                        Write-host ($Path -replace "^$([regex]::Escape($Folder))\\",'') -ForegroundColor White

                        Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                        Write-host 'Inf2Cat:     OS: ' -ForegroundColor DarkCyan -NoNewline
                        Write-host $OS -ForegroundColor White

                        Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                        Write-host 'Inf2Cat: [Catalog generation]:' -ForegroundColor DarkCyan

                        $aComm = @($Inf2Cat, "/driver:""$Path""", "/os:""$OS""")

                        # Асинхронное выполнение утилиты с ожиданием и анимацией, после вывод результата stdout утилиты
                        $BoolErrorGlobal = Run-Async -aCmdArgs $aComm

                        if ( $BoolErrorGlobal )  # как $Global:LastExitCode
                        {
                            Write-host
                            Write-host '   Sign: Skipped | ' -ForegroundColor Yellow -NoNewline
                            Write-host "Error: Inf2Cat.exe /driver:""$Path"" /os:""$OS""" -ForegroundColor Red

                            $aWarningsGlobal += "Sign: Skipped | Error: Inf2Cat.exe /driver:""$Path"" /os:""$OS"""

                            break
                        }

                        $aFilesCAT = Get-ChildItem -Path $PathPattern -File -ErrorAction SilentlyContinue

                        if ( -not $aFilesCAT.Count )
                        {
                            Write-host
                            Write-host '   Sign: Skipped | ' -ForegroundColor Yellow -NoNewline
                            Write-host "Error: CAT files are not created | $PathPattern" -ForegroundColor Red

                            $aWarningsGlobal += "Sign: Skipped | Error: CAT files are not created | $PathPattern"

                            break
                        }

                        $aPathGenCATs += $Path
                    }

                    Write-host
                }
                else { Write-host }

                $aFilePaths = $aFilesCAT
            }
            else
            {
                # non-Cat Только один последний (-like Last)
                $getName = $Sign -replace ('.+\\','')
                $getPath = "$Folder\$Sign" -replace ('\\[^\\]+$','')
                $aFilePaths = @()
                try { $aFilePaths = ([string[]][System.IO.Directory]::EnumerateFiles($getPath, $getName))[-1] } catch {}  # Взять один последний файл (-like Last)
            }


            # Действия с файлами
            foreach ( $FilePath in $aFilePaths )
            {
                $N3++
                if ( $aWarningsGlobal.Count ) { break }

                $ShowFile = $FilePath -replace "^$([regex]::Escape($Folder))\\",''

                $FilePathOrig = $FilePath
                $ShowFileOrig = $ShowFile
                $getName      = ''
                $UnpackFile   = ''

                $dAction = @{}

                Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                Write-host $ShowFileOrig -ForegroundColor Magenta -NoNewline
                Write-host ' ◄ ' -ForegroundColor DarkGreen -NoNewline
                Write-host 'Found, Signing file' -ForegroundColor DarkGreen

                $GetItem = [System.IO.FileInfo]::new($FilePath)

                if ( $GetItem.Attributes -match 'readonly|hidden|system' )
                {
                    $Attr = [regex]::Split($GetItem.Attributes, ',').Trim() ; $GetItem.Attributes = ( $Attr -notmatch 'readonly|hidden|system' )
                }

                $GetItem = $null

                # Unpack
                if ( $FilePath.EndsWith('_') )
                {
                    $getName = $FilePath -replace ('.+\\','')
                    $getName = $getName.Substring(0, $getName.Length - 1) # Удаление 1 последнего символа

                    if ( @(& $7z l "$FilePathOrig" -i!"$getName`?" -aoa -bso0 -bse0 -bsp0)[-3] -match "  (?<file>$([regex]::Escape($getName))[0-9a-z])$" )
                    {
                        $UnpackFile = $matches.file

                        $FilePath = '{0}\{1}' -f $TempDir, $UnpackFile
                        $ShowFile = '{0}\{1}' -f $TempDir.Replace("$CurrentRoot\",''), $UnpackFile

                        Write-Host "   Sign: Unpacking: $ShowFileOrig | to: $ShowFile" -ForegroundColor DarkGray

                        & $7z e $FilePathOrig -o"$TempDir" $UnpackFile -aoa -bso0 -bse0 -bsp0

                        if (( $Global:LASTEXITCODE ) -or ( -not [System.IO.File]::Exists($FilePath) ))
                        {
                            Write-Host "   Sign: Error: Unpack: $UnpackFile | From: $ShowFileOrig" -ForegroundColor Red

                            $aWarningsGlobal += "Sign: Error: Unpack: $UnpackFile | From: $ShowFileOrig"

                            $BoolErrorGlobal = $true
                            break
                        }

                        $GetItem = [System.IO.FileInfo]::new($FilePath)

                        if ( $GetItem.Attributes -match 'readonly|hidden|system' )
                        {
                            $Attr = [regex]::Split($GetItem.Attributes, ',').Trim() ; $GetItem.Attributes = ( $Attr -notmatch 'readonly|hidden|system' )
                        }

                        $GetItem = $null
                    }
                }




                $Path     = [System.IO.Path]::GetDirectoryName($FilePath)
                $File     = [System.IO.Path]::GetFileName($FilePath)
                $FileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
                $FileEXT  = [System.IO.Path]::GetExtension($FilePath)

                $TempFile = '{0}_{1}{2}' -f $FileName, $SALT, $FileEXT

                # Если остался временный файл переименованный, удалить все такие, и если текущий файл подходит под такой шаблон, пропустить
                if ( $SALT )
                {
                    Remove-Item -Path "$Path\*$SALT.*" -Force -ErrorAction Continue   # $SALT = 97456214756

                    if ( $ShowFile -like "*$SALT.*" )
                    {
                        Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                        Write-host $ShowFile -ForegroundColor DarkGray -NoNewline
                        Write-host ' ◄ ' -ForegroundColor DarkGray -NoNewline
                        Write-host 'Skip and delete temp file' -ForegroundColor DarkGreen

                        $N3--

                        Continue
                    }
                    else
                    {
                        if ( $addSign ) { $AddShow = '+' } else { $AddShow = ' ' }

                        $dAction[$ShowFileOrig] = [PSCustomObject]@{
                            Result = $false
                            Action = "[Sign: {0,-$iIndentSize} |$AddShow {1,-6} | {2} {3,-6} ind: $AddIndex]" -f $CertFile, $SigAlg.ToLower(), $TimeStamp, $Alg
                            Color  = 'Red'
                        }

                        # добавление Ссылки на переменную $dAction, изменяя $dAction, изменеяется и в $aActionsGlobal, пока существует переменная $dAction или не сброшена @{}
                        $aActionsGlobal.Add($dAction) 
                    }
                }

                Rename-Item -LiteralPath $FilePath -NewName $TempFile -Force -ErrorAction Continue

                if ( -not $? )
                {
                    Write-host
                    Write-host '   Sign: Error: Rename ' -ForegroundColor Red -NoNewline
                    Write-host $FilePath -ForegroundColor White -NoNewline
                    Write-host ' to ' -ForegroundColor DarkGray -NoNewline
                    Write-host $TempFile -ForegroundColor Red

                    $aWarningsGlobal += "Sign: Error: Rename: $FilePath"

                    break
                }

                $aComm = @()
                if ( $Pass     ) { $aComm += @( '-pass', $Pass )         }
                if ( $UseCross ) { $aComm += @( '-ac', """$UseCross""" ) }
                if ( $addSign  ) { $aComm += @( '-nest' )                }

                Write-host

                if ( $CurTime )
                {
                    $TimeStamp = [datetime]::UtcNow.AddSeconds(5).ToString('yyyy-MM-ddTHH:mm:ss')
                    $Time      = ([DateTimeOffset][datetime]::Parse($TimeStamp)).ToUnixTimeSeconds()

                    if ( -not $BoolUseBuiltInTsaGlobal )
                    {
                        $URL = "http://localhost:80/TS-$Alg/$TimeStamp"
                    }
                    else
                    {
                        $URL = 'built-in TSA'
                    }

                    # if use [TimeStamp]
                    if ( $ST_T )
                    {
                        Write-host '   Sign:    TimeStamp: ' -ForegroundColor DarkGray -NoNewline
                        Write-host $TimeStamp -ForegroundColor Gray -NoNewline
                        Write-host ' | UTC | Current UTC time + 5 sec | Alg: ' -ForegroundColor DarkGray -NoNewline
                        Write-host $Alg -ForegroundColor DarkCyan

                        Write-host '   Sign:       TS URL: ' -ForegroundColor DarkGray -NoNewline
                        Write-host $URL -ForegroundColor Gray
                    }
                    else
                    {
                        Write-host '   Sign:    TimeStamp: ' -ForegroundColor DarkGray -NoNewline
                        Write-host '[skip]' -ForegroundColor Gray -NoNewline
                        Write-host ' | only Sign' -ForegroundColor DarkGray
                    }
                }



                $Service.Refresh()
                if ( $Service.Status -ne 'Running' )
                {
                    $Service.Start()
                    $Service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Running, [timespan]::new(0,0,5)) # wait 5 sec
                }


                # [Sign] ####################
                if ( $ST_S )
                {
                    Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                    Write-host 'osslsigncode: [Signing]:' -ForegroundColor DarkCyan

                    # если не добавление подписи, удалить все, на всякий чтобы не osslsigncode удалял, а signtool
                    if ( -not $addSign )
                    {
                        if ( $FileType -eq 'non-CAT' ) { & $signtool remove /s "$Path\$TempFile" *> $null }
                    }

                    & $osslsigncode sign -spc "$ClientInt" -key "$ClientKEY" -nolegacy $aComm -h ($SigAlg.ToLower()) -time $Time -in "$Path\$TempFile" -out "$FilePath"
                }
                else
                {
                    Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                    Write-host 'osslsigncode: [Signing]: ' -ForegroundColor DarkCyan -NoNewline
                    Write-host '[skip] ' -ForegroundColor Gray -NoNewline
                    Write-host '| only [TimeStamp] | T' -ForegroundColor DarkGray
                }

                if ( [System.IO.File]::Exists($FilePath) )
                {
                    Remove-Item -LiteralPath "$Path\$TempFile" -Force -ErrorAction Continue
                }
                else
                {
                    Rename-Item -LiteralPath "$Path\$TempFile" -NewName $File -Force -ErrorAction Continue
                }

                if ( -not $? )
                {
                    Write-host '   Sign: Error: Remove/Rename: ' -ForegroundColor Red -NoNewline
                    Write-host "$Path\$TempFile" -ForegroundColor White

                    $aWarningsGlobal += "Sign: Error: Remove/Rename: $Path\$TempFile"

                    break
                }
                # [Sign] end ####################


                # [TimeStamp]
                if ( $ST_T )
                {
                    if ( -not $Global:LastExitCode )
                    {
                        # если указан http или указано использовать локальный сервер, вместо built-in TSA
                        if ( $Data.TimeStamp -like 'http*' -or -not $BoolUseBuiltInTsaGlobal )
                        {
                            $Metod = 'signtool: [TimeStamp]'

                            if ( $ST_S ) { Write-host }
                            Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                            Write-host "$Metod`:" -ForegroundColor DarkCyan

                            if ( $Alg -eq 'SHA1' )
                            {
                                if ( $addSign )
                                {
                                    if ( $AddIndex ) 
                                    {
                                        # signtool метка с указанием индекса /tp работает только с /tr и /td (для SHA256+ для RFC3161) 
                                    
                                        # Так будет ошибка с информацией, пусть останеться для инфы тем кто будет использовать:
                                        & $signtool timestamp /tp $AddIndex /v /t "$URL" "$FilePath"
                                    
                                        # так работает, но метка выходит не по стандарту с сервера для меток SHA256, что по сути будет как SHA256, лучше делать такое через osslsigncode
                                        #& $signtool timestamp /tp $AddIndex /v /tr "$URL" /td $Alg "$FilePath"
                                    }
                                    else # Index = 0
                                    {
                                        # Не удаляет другие подписи при метке на 0 индекс без указания индекса
                                        & $signtool timestamp /v /t "$URL" "$FilePath"
                                    }
                                }
                                else
                                {
                                    & $signtool timestamp /v /t "$URL" "$FilePath"
                                }
                            }
                            else  # SHA256
                            {
                                if ( $addSign )
                                {
                                    & $signtool timestamp /tp $AddIndex /v /tr "$URL" /td $Alg "$FilePath"
                                }
                                else
                                {
                                    & $signtool timestamp /v /tr "$URL" /td $Alg "$FilePath"
                                }
                            }

                            if ( -not $Global:LastExitCode )
                            {
                                if ( -not ( $Data.TimeStamp -like 'http*' ))
                                {
                                    Write-host
                                    Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                                    Write-host 'Local TimeStamp server [Respond]:' -ForegroundColor DarkCyan

                                    [TimeStamp.Program]::GetListenerRespond()
                                }
                            }
                        }
                        else
                        {
                            $Metod = 'osslsigncode: built-in TSA [TimeStamp]'

                            if ( $ST_S ) { Write-host }
                            Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                            Write-host "$Metod`:" -ForegroundColor DarkCyan

                            Rename-Item -LiteralPath $FilePath -NewName $TempFile -Force -ErrorAction Continue

                            if ( -not $? )
                            {
                                Write-host
                                Write-host '   Sign: Error: Rename ' -ForegroundColor Red -NoNewline
                                Write-host $FilePath -ForegroundColor White -NoNewline
                                Write-host ' to ' -ForegroundColor DarkGray -NoNewline
                                Write-host $TempFile -ForegroundColor Red

                                $aWarningsGlobal += "Sign: Error: Rename: $FilePath"

                                break
                            }

                        
                            # UTC to Local for osslsigncode built-in TSA (The program converts the time to UTC)
                            # 60 UnixTimeSeconds = 1 мин | 3600 UnixTimeSeconds = 1 час | 10800 = 3 часа (в 2012, 2013, 2014 в РФ было +4 часа разница от GMT, в разные годы по разному),
                            $Time += (60 * ([DateTimeOffset][datetime]::Parse($TimeStamp)).Offset.TotalMinutes)  # += количество минут разницы от GMT на время подписи $TimeStamp (данное конвертирование учитывает разницу GMT для любого года)

                            if ( $addSign )
                            {
                                & $osslsigncode add -h ($Alg.ToLower()) -TSA-certs $TsaCrt -TSA-key $TsaKey -TSA-time $Time -in "$Path\$TempFile" -out "$FilePath" -index $AddIndex
                            }
                            else
                            {
                                & $osslsigncode add -h ($Alg.ToLower()) -TSA-certs $TsaCrt -TSA-key $TsaKey -TSA-time $Time -in "$Path\$TempFile" -out "$FilePath"
                            }

                            if ( [System.IO.File]::Exists($FilePath) )
                            {
                                Remove-Item -LiteralPath "$Path\$TempFile" -ErrorAction Continue
                            }
                            else
                            {
                                Rename-Item -LiteralPath "$Path\$TempFile" -NewName $File -Force -ErrorAction Continue
                            }

                            if ( -not $? )
                            {
                                Write-host
                                Write-host '   Sign: Error: Remove/Rename: ' -ForegroundColor Red -NoNewline
                                Write-host "$Path\$TempFile" -ForegroundColor White

                                $aWarningsGlobal += "Sign: Error: Remove/Rename: $Path\$TempFile"

                                break
                            }
                        }
                    }
                    else
                    {
                        Write-host
                        Write-host "   Sign: Error: Sign with osslsigncode.exe | Wrong parameters | for $FilePath" -ForegroundColor Red

                        $aWarningsGlobal += "Sign: Error: Sign with osslsigncode.exe | Wrong parameters | for $FilePath"

                        break
                    }
                }
                else
                {
                    Write-host
                    Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                    Write-host '[skip] ' -ForegroundColor Gray -NoNewline
                    Write-host '[TimeStamp]' -ForegroundColor DarkCyan -NoNewline
                    Write-host ' | only [Sign] | S' -ForegroundColor DarkGray
                }


                # Set [date]
                if ( -not $Global:LastExitCode )
                {
                    # тут не надо расчитывать offset is $TimeStamp !
                    $DateTime = ([DateTimeOffset][datetime]::Parse($TimeStamp)).DateTime.AddMinutes(([DateTimeOffset][datetime]::Now).Offset.TotalMinutes)

                    $f = Get-Item -LiteralPath $FilePath -ErrorAction Continue
                    if ( -not $? ) { $BoolErrorGlobal = 1 }

                    $f.CreationTime = $DateTime
                    $f.LastWriteTime = $DateTime
                    if ( -not $? ) { $BoolErrorGlobal = 1 }

                    if ( -not $BoolErrorGlobal )
                    {
                        Write-host
                        Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                        Write-host $ShowFile -ForegroundColor Green -NoNewline
                        Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                        Write-host '[All Ok]' -ForegroundColor Green

                        $ST_SHOW = "$TimeStamp {0,-6}" -f $Alg

                        if ( $Data.ST )
                        {
                            if     ( $Data.ST -eq 'S' ) { $ST_SHOW = 'only Sign' }
                            elseif ( $Data.ST -eq 'T' ) { $ST_SHOW = "$TimeStamp {0,-6} (only TimeStamp, ind: $AddIndex)" -f $Alg }
                        }

                        if ( $addSign ) { $AddShow = '+' } else { $AddShow = ' ' }

                        $dAction[$ShowFileOrig] = [PSCustomObject]@{
                            Result = $true
                            Action = "[Sign: {0,-$iIndentSize} |$AddShow {1,-6} | {2}]" -f $CertFile, $SigAlg.ToLower(), $ST_SHOW
                            Color  = 'White'
                        }
                    }
                    else
                    {
                        Write-host
                        Write-host '   Sign: ' -ForegroundColor Yellow -NoNewline
                        Write-host $ShowFile -ForegroundColor Yellow -NoNewline
                        Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                        Write-host 'Error set date' -ForegroundColor Green

                        $aWarningsGlobal += "Sign: Error: $ShowFile | Error set date"

                        break
                    }
                }
                else
                {
                    Write-host
                    Write-host '   Sign: ' -ForegroundColor Yellow -NoNewline
                    Write-host "$Metod`: Error | $FilePath" -ForegroundColor Red

                    $aWarningsGlobal += "Sign: $Metod`: Error | $FilePath"

                    break
                }


                # [Pack] and set [date] on packedfile
                if ( $UnpackFile )
                {
                    Write-Host "   Sign: Packing back: $ShowFile | to: $ShowFileOrig" -ForegroundColor DarkGray

                    try
                    {
                        if ( [System.IO.File]::Exists($FilePath) )
                        {
                            Remove-Item -LiteralPath $FilePathOrig -Force -ErrorAction Stop

                            & makecab.exe /V0 /D CompressionType=MSZIP "$FilePath" "$FilePathOrig" > $null

                            Remove-Item -LiteralPath $FilePath -Force -ErrorAction Stop
                        }
                        else { throw }

                        if ( -not [System.IO.File]::Exists($FilePathOrig) ) { throw }
                    }
                    catch
                    {
                        Write-Host "  Patch: Error: Pack/Delete file: $FilePathOrig | or delete: $FilePath" -ForegroundColor Red

                        $aWarningsGlobal += "Patch: Error: Pack/Delete file: $FilePathOrig | or delete: $FilePath"

                        $BoolErrorGlobal = $true
                        break
                    }


                    $f = Get-Item -LiteralPath $FilePathOrig -ErrorAction Continue
                    if ( -not $? ) { $BoolErrorGlobal = 1 }

                    $f.CreationTime = $DateTime
                    $f.LastWriteTime = $DateTime
                    if ( -not $? ) { $BoolErrorGlobal = 1 }

                    if ( -not $BoolErrorGlobal )
                    {
                        Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                        Write-host $ShowFileOrig -ForegroundColor Green -NoNewline
                        Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                        Write-host '[pack Ok]' -ForegroundColor Green

                        if ( $addSign ) { $AddShow = '+' } else { $AddShow = ' ' }

                        $dAction[$ShowFileOrig] = [PSCustomObject]@{
                            Result = $true
                            Action = "[Sign: {0,-$iIndentSize} |$AddShow {1,-6} | {2}] [pack Ok]" -f $CertFile, $SigAlg.ToLower(), $ST_SHOW
                            Color  = 'White'
                        }
                    }
                    else
                    {
                        Write-host
                        Write-host '   Sign: ' -ForegroundColor Yellow -NoNewline
                        Write-host $ShowFileOrig -ForegroundColor Yellow -NoNewline
                        Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                        Write-host 'Error set date' -ForegroundColor Green

                        $aWarningsGlobal += "Sign: Error: $ShowFileOrig | Error set date"

                        break
                    }
                }
            }
            # foreach действия с файлами (конец)

            if ( -not $N3 )
            {
                if ( $FileType -eq 'CAT' )
                {
                    $aWarningsGlobal += "Sign: $Sign | Files not found"
                    $color = 'Yellow'
                }
                else
                {
                    $aAttentionsGlobal += "Sign  | $Sign | Files not found"
                    $color = 'DarkYellow'
                }

                Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
                Write-host $Sign -ForegroundColor $color -NoNewline
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-host 'Files not found' -ForegroundColor $color

                Continue
            }
        }
    }




    if ( -not $N )
    {
        if ( $BoolErrorGlobal )
        {
            Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
            Write-host 'Skipped | Was an error or [Test] mode' -ForegroundColor DarkGray
        }
        else
        {
            Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
            Write-host 'preset is not configured (Gen-To-Sign-*, and/or PFX-Cert + PFX-To-Sign-*)' -ForegroundColor DarkGray
        }
    }

    Remove-Item -Path $TempDir\* -Force -ErrorAction SilentlyContinue




    # Выполнение cmd/bat в самом конце
    if ( -not $BoolErrorGlobal )
    {
        Run-CMD-Files -NotGetData -NotStop -Final
    }


    [string] $r = ' Total action result: {0}' -f (' ' * 89)  # Общий итог выполнения

    Write-host
    Write-host '        ' -BackgroundColor DarkCyan -NoNewline
    Write-host $r -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-host

    $N = 0

    if ( $aWarningsGlobal.Count )
    {
        foreach ( $W in $aWarningsGlobal )
        {
            $N++

            Write-host ('{0,7}. ' -f $N) -ForegroundColor DarkGray -NoNewline
            Write-host $W -ForegroundColor Red
        }
    }
    else
    {
        Write-host ('{0,7}. ' -f $N) -ForegroundColor DarkGray -NoNewline
        Write-host 'No Warnings' -ForegroundColor Green
    }

    Write-host


    $N = 0

    if ( $aAttentionsGlobal.Count )
    {
        foreach ( $A in $aAttentionsGlobal )
        {
            $N++

            Write-host ('{0,7}. ' -f $N) -ForegroundColor DarkGray -NoNewline
            Write-host $A -ForegroundColor DarkYellow
        }

        Write-host
    }


    $N = 0

    if ( $aActionsGlobal.Count )
    {
        $iIndentSize = 0

        foreach ( $F in $aActionsGlobal.Keys )
        {
            $iIndentSize = [math]::Max($F.Length, $iIndentSize)
        }

        foreach ( $F in $aActionsGlobal.Keys )
        {
            $N++

            Write-host ('{0,7}. ' -f $N) -ForegroundColor DarkGray -NoNewline

            if ( $aActionsGlobal[$N-1].$F.Result )
            {
                Write-host $true -ForegroundColor DarkGreen -NoNewline
                Write-host '  | ' -ForegroundColor DarkGray -NoNewline
                Write-host ("{0,-$iIndentSize}" -f $F) -ForegroundColor Green -NoNewline
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-host $aActionsGlobal[$N-1].$F.Action -ForegroundColor $aActionsGlobal[$N-1].$F.Color
            }
            else
            {
                Write-host $false -ForegroundColor Red -NoNewline
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-host ("{0,-$iIndentSize}" -f $F) -ForegroundColor Red -NoNewline
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-Host $aActionsGlobal[$N-1].$F.Action -ForegroundColor Red
            }
        }
    }
    else
    {
        Write-host ('{0,7}. ' -f $N) -ForegroundColor DarkGray -NoNewline
        Write-host 'No Actions' -ForegroundColor DarkGray
    }


    $Service.Close()

    Get-Pause
}


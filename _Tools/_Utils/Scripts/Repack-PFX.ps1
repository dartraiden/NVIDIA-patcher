
# PFX v1 или v3
Function Repack-PFX {

    [CmdletBinding( SupportsShouldProcess = $false )]
    [OutputType([bool])]
    Param(
        [Parameter(Mandatory)]
        [string] $FilePFX
       ,
        [Parameter(Mandatory = $false)]
        [string] $Pass
       ,
        [Parameter(Mandatory = $false)]
        [string] $NewPass
       ,
        [Parameter(Mandatory = $false)]
        [switch] $RemovePass
       ,
        [Parameter(Mandatory = $false)]
        [switch] $AddCross
       ,
        [Parameter(Mandatory = $false)]
        [string] $CrossCertFile
       ,
        [Parameter(Mandatory = $false)]
        [string] $CertArchiveDir = "$CurrentRoot\_Tools\CertArchive"
       ,
        [Parameter(Mandatory = $false)]
        [switch] $SavePFX
       ,
        [Parameter(Mandatory = $false)]
        [switch] $NotSave
       ,
        [Parameter(Mandatory = $false)]
        [switch] $SaveForSign
       ,
        [Parameter(Mandatory = $false)]
        [switch] $TBS
       ,
        [Parameter(Mandatory = $false)]
        [string] $Openssl = $Openssl # need v3.1.1 + legacy.dll
       ,
        [Parameter(Mandatory = $false)]
        [string] $TempDir = $ScratchDirGlobal
    )

    # Получение имени этой функции.
    [string] $NameThisFunction = $MyInvocation.MyCommand.Name

    [string] $namePFX   = [System.IO.Path]::GetFileNameWithoutExtension($FilePFX)
    [string] $extPFX    = [System.IO.Path]::GetExtension($FilePFX)
    [string] $PathPFX   = [System.IO.Path]::GetDirectoryName($FilePFX)

    if ( $extPFX -ne '.pfx' )
    {
        Write-Host "`n RePack: [$NameThisFunction] error: File not PFX: $namePFX$extPFX" -ForegroundColor Red ; Return $false
    }
    elseif ( -not ( $FilePFX -like '*\*' ))
    {
        Write-Host "`n RePack: [$NameThisFunction] error: FullPath PFX: $FilePFX" -ForegroundColor Red ; Return $false
    }

    [string] $outPEM    = "$TempDir\$namePFX`_.pem"         ; [string[]] $PEM    = @()
    [string] $outKEY    = "$TempDir\$namePFX`_.key"         ; [string[]] $KEY    = @()
    [string] $outClient = "$TempDir\$namePFX`_Client.crt"   ; [string[]] $Client = @()

    [string] $outCAall  = "$TempDir\$namePFX`_CA_All.crt"   ; [string[]] $CA_All = @()
    [string] $outCARoot = "$TempDir\$namePFX`_CA_Root.crt"
    [string] $outCAint  = "$TempDir\$namePFX`_CA_Int.crt"

    [string] $outCl_Int = "$TempDir\$namePFX`_Client+Int.crt"

    [string] $outCross  = "$PathPFX\$namePFX`_Cross.crt"


    Write-host
    Write-host ' ' -NoNewline
    Write-host 'RePack:' -ForegroundColor White -BackgroundColor DarkBlue -NoNewline
    Write-host ' File PFX: ' -ForegroundColor DarkGray -NoNewline
    Write-host $namePFX$extPFX -ForegroundColor Cyan

    [array] $aLegacy = @()
    [array] $aErr = @()
    [string] $e = ''

    # Для stdin pkcs12 | -Raw только если формат pfx или как PEM для других команд (только для PS ISE, не пашет в Console, ломается кодировка буфера символов pfx)
    #[string] $RawPFX = Get-Content -LiteralPath $FilePFX -Raw -ErrorAction Continue
    # try { $aErr = $RawPFX | & $Openssl pkcs12 -info -passin pass:$Pass -noout 2>&1 } catch {}

    try { $aErr = & $Openssl pkcs12 -in $FilePFX -info -passin pass:$Pass -noout 2>&1 } catch {}

    # Замена Pass на NewPass, если ошибка из-за Pass, или выход если не помогает. (Нужно для пресета, при репаке pfx в новый в ту же папку, если была замена Pass при этом, чтобы просто подхватил NewPass)
    if ( $Global:LastExitCode -and ( $e = $aErr -like '*invalid password[?]*' ))
    {
        try { $aErr = & $Openssl pkcs12 -in $FilePFX -info -passin pass:$NewPass -noout 2>&1 } catch {}

        if ( $Global:LastExitCode -and ( $e = $aErr -like '*invalid password[?]*' ))
        {
            Write-Host " RePack: [$NameThisFunction] Error: $e | Pass > '$Pass'" -ForegroundColor Red ; Return $false
        }
        else
        {
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

            # hide newpass
            if ( $NewPass.Length -gt 1 )
            {
                $ShowNewPass = '{0}{1}' -f ($NewPass[0]), ('*' * ($NewPass.Length - 1))
            }
            elseif ( $Pass.Length -eq 1 )
            {
                $ShowNewPass = '*'
            }
            else
            {
                $ShowNewPass = ''
            }

            Write-Host " RePack: Pass Wrong (No Pass) | Replace: '$ShowPass' > '$ShowNewPass'" -ForegroundColor Yellow
            $Pass = $NewPass
        }
    }

    if ( $Pass -and -not $NewPass ) { $NewPass = $Pass }
    if ( $Pass -ne $NewPass ) { Write-host " RePack: Set New pass | Old > '$Pass' | New > '$NewPass'" -ForegroundColor DarkCyan }
    [string] $OldPass = $Pass


    # использовать dll для распаковки PFX с поддержкой старых форматов как в openssl v1, если ошибка при получении инфы из PFX
    if ( $Global:LastExitCode )
    {
        Write-Host " RePack: Not v3 format PFX" -ForegroundColor DarkGray

        $aLegacy = '-legacy', '-provider-path', [System.IO.Path]::GetDirectoryName($Openssl)
    }


    if (( $RemovePass ) -or -not ( $NewPass ))
    {
        Write-host " RePack: No Pass for PEM or RemovePass" -ForegroundColor DarkGray

        $NewPass = $Pass

        # Распаковать в PEM и не шифровать ключ внутри PEM
        $PEM = & $Openssl pkcs12 -in $FilePFX -passin pass:$Pass -noenc $aLegacy #2>$null
    }
    else
    {
        # Распаковать в PEM и зашифровать ключ внутри PEM
        $PEM = & $Openssl pkcs12 -in $FilePFX -passin pass:$Pass -passout pass:$NewPass $aLegacy #2>$null
    }

    if ( $Global:LastExitCode ) { Write-Host " RePack: [$NameThisFunction] error: out PEM" -ForegroundColor Red ; Return $false }


    # Достать конечный сертификат Client.crt (первый сертификат в файле PEM)
    $Client = & $Openssl pkcs12 -in $FilePFX -nokeys -clcerts -passin pass:$Pass -passout pass:$NewPass $aLegacy #2>$null
    if ( $Global:LastExitCode ) { Write-Host " RePack: [$NameThisFunction] error: out Client.crt" -ForegroundColor Red ; Return $false }


    # Достать все сертификаты CA: IntermediateCA.crt и RootCA.crt и т.д. в том порядке как они там указаны (нужно парсить в правильный порядок)
    $CA_All = & $Openssl pkcs12 -in $FilePFX -nokeys -cacerts -passin pass:$Pass -passout pass:$NewPass $aLegacy #2>$null
    if ( $Global:LastExitCode ) { Write-Host " RePack: [$NameThisFunction] error: out CA_All.crt" -ForegroundColor Red ; Return $false }


    # Достать key
    if (( $RemovePass ) -or -not ( $NewPass ))
    {
        Write-host " RePack: No Pass for Private KEY or RemovePass" -ForegroundColor DarkGray

        # Достать key и не шифровать его
        $KEY = $PEM | & $openssl pkey -passin pass:$Pass #2>$null

        $Pass = '' ; $NewPass = ''
    }
    else
    {
        $Pass = $NewPass

        # Достать key и зашифровать обратно в aes256 как в дефолте v3
        $KEY = $PEM | & $openssl pkey -passin pass:$Pass -passout pass:$NewPass -aes256 #2>$null
    }

    if ( $Global:LastExitCode ) { Write-Host " RePack: [$NameThisFunction] Error: out Private.key" -ForegroundColor Red ; Return $false }


    [string] $RootCA  = ''
    [string] $IntCA   = ''
    [string] $CAall   = ''

    [string] $subject = ''  # temp var
    [string] $issuer  = ''  # temp var
    [string[]] $iCert = @() # temp var

    [hashtable] $hClient  = @{}
    [hashtable] $hIntCA_1 = @{}
    [hashtable] $hIntCA_2 = @{}
    [hashtable] $hRootCA  = @{}
    [hashtable] $hCrossMS = @{}


    [array] $x509params = '-certopt', 'no_header,no_sigdump,no_extensions,no_pubkey,no_serial,no_validity,no_issuer,no_subject,no_aux',
        '-fingerprint', '-sha1', '-dates', '-dateopt', 'iso_8601', '-subject', '-issuer', '-nameopt', 'utf8,dn_rev,sname,sep_semi_plus_space'

    # Client info
    $iCert = $Client | & $openssl x509 -text -noout -passin pass: $x509params #2>$null

    [string] $ClientSubject = [regex]::Match($iCert,'subject(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value # если бы было 2 одинаковые то возьмёт первую.
    [string] $ClientIssuer  = [regex]::Match($iCert,'issuer(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value

    if ( -not ($ClientSubject -and $ClientIssuer -and ($ClientSubject -ne $ClientIssuer)))
    {
        Write-host " RePack: [$NameThisFunction] Error: No Client cert in $namePFX.pfx" -ForegroundColor Red ; Return $false
    }

    $hClient = @{
        subject = $ClientSubject
        issuer  = $ClientIssuer
        cert    = $Client

        notBefore = [regex]::Match($iCert,'notBefore=(?<Name>[^\s]+)',4).Groups['Name'].Value # yyyy-MM-dd
        notAfter  = [regex]::Match($iCert,'notAfter=(?<Name>[^\s]+)',4).Groups['Name'].Value  # yyyy-MM-dd
        print     = $(try { (($iCert -like 'sha1 Fingerprint=*').ToLower() -replace '.*?=|:','') } catch {''})
        SigAlg    = [regex]::Match($iCert,'Signature Algorithm: (?<Name>(md|sha)[\d]+)',4).Groups['Name'].Value
        Vers      = [regex]::Match($iCert,'Version: (?<Name>[\d]+)',4).Groups['Name'].Value
    }


    # All CA: разделение Root от Int (Int максимум 2шт), правильность второго Int не проверяется, смысла не вижу делать в данном контексте использования.
    [string] $pattern = '(?<Cert>.+?-----END CERTIFICATE-----\s*\n?)'
    $CAall = [string]::Join("`n", ($CA_All + ''))

    foreach ( $Cert in @([regex]::Matches($CAall, $pattern, 20).Groups).Where({ $_.Name -ne 0 }).Value )
    {
        $iCert = $Cert | & $openssl x509 -text -noout -passin pass: $x509params #2>$null

        $subject = [regex]::Match($iCert,'subject(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value # кавычек не бывает, берет сначала CN, если есть, либо OU, если есть, и первую если 2
        $issuer  = [regex]::Match($iCert,'issuer(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value

        if ( $subject -and $issuer )
        {
            if ( $subject -eq $issuer )
            {
                # Write-host " RootCA  issuer (by): $issuer" -ForegroundColor DarkGray

                if ( -not $RootCA )
                {
                    $hRootCA = @{
                        subject = $subject
                        issuer  = $issuer
                        cert    = $Cert

                        notBefore = [regex]::Match($iCert,'notBefore=(?<Name>[^\s]+)',4).Groups['Name'].Value # yyyy-MM-dd
                        notAfter  = [regex]::Match($iCert,'notAfter=(?<Name>[^\s]+)',4).Groups['Name'].Value  # yyyy-MM-dd
                        print     = $(try { (($iCert -like 'sha1 Fingerprint=*').ToLower() -replace '.*?=|:','') } catch {''})
                        SigAlg    = [regex]::Match($iCert,'Signature Algorithm: (?<Name>(md|sha)[\d]+)',4).Groups['Name'].Value
                        Vers      = [regex]::Match($iCert,'Version: (?<Name>[\d]+)',4).Groups['Name'].Value
                    }

                    $RootCA = $Cert
                }
                else { Write-host " RePack: [$NameThisFunction] Error: 2 rootCA in $namePFX.pfx" -ForegroundColor Red ; Return $false }
            }
            else
            {
                if ( $subject -eq $hClient.issuer )
                {
                    #Write-host " RePack: IntCA1 subject (to): $subject" -ForegroundColor Gray
                    #Write-host " RePack: IntCA1  issuer (by): $issuer" -ForegroundColor Gray

                    $hIntCA_1 = @{
                        subject = $subject
                        issuer  = $issuer
                        cert    = $Cert

                        notBefore = [regex]::Match($iCert,'notBefore=(?<Name>[^\s]+)',4).Groups['Name'].Value # yyyy-MM-dd
                        notAfter  = [regex]::Match($iCert,'notAfter=(?<Name>[^\s]+)',4).Groups['Name'].Value  # yyyy-MM-dd
                        print     = $(try { (($iCert -like 'sha1 Fingerprint=*').ToLower() -replace '.*?=|:','') } catch {''})
                        SigAlg    = [regex]::Match($iCert,'Signature Algorithm: (?<Name>(md|sha)[\d]+)',4).Groups['Name'].Value
                        Vers      = [regex]::Match($iCert,'Version: (?<Name>[\d]+)',4).Groups['Name'].Value
                    }
                }
                elseif ( -not $hIntCA_2.Count )
                {
                    #Write-host " RePack: IntCA2 subject (to): $subject" -ForegroundColor DarkGray
                    #Write-host " RePack: IntCA2  issuer (by): $issuer" -ForegroundColor DarkGray

                    $hIntCA_2 = @{
                        subject = $subject
                        issuer  = $issuer
                        cert    = $Cert

                        notBefore = [regex]::Match($iCert,'notBefore=(?<Name>[^\s]+)',4).Groups['Name'].Value # yyyy-MM-dd
                        notAfter  = [regex]::Match($iCert,'notAfter=(?<Name>[^\s]+)',4).Groups['Name'].Value  # yyyy-MM-dd
                        print     = $(try { (($iCert -like 'sha1 Fingerprint=*').ToLower() -replace '.*?=|:','') } catch {''})
                        SigAlg    = [regex]::Match($iCert,'Signature Algorithm: (?<Name>(md|sha)[\d]+)',4).Groups['Name'].Value
                        Vers      = [regex]::Match($iCert,'Version: (?<Name>[\d]+)',4).Groups['Name'].Value
                    }
                }
                elseif ( $hIntCA_2.Count )
                {
                    Write-host " RePack: Error: Intermediate CA Count > 2 in $namePFX.pfx" -ForegroundColor Red
                }
            }
        }
        else { Write-host " RePack: [$NameThisFunction] Error: $namePFX.pfx" -ForegroundColor Red ; Return $false }
    }


    # only file .cer or .crt (DER or PEM) | Out string Cert PEM or ''
    Function Get-Chain-Cert-ArchiveFile ( [string] $CertIssuer, [string] $CertAlg, [switch] $IntCA, [switch] $RootCA, [switch] $CrossMS, [string] $FileCert ) {

        if ( -not $CertIssuer ) { return '' }

          [string] $FoundFile  = ''
        [string[]] $FoundFiles = @()

        if ( -not $FileCert )
        {
            [string] $subDir = 'CrossMS'
            if     ( $IntCA  ) { $subDir = 'IntCA'  }
            elseif ( $RootCA ) { $subDir = 'RootCA' }

            [array] $aCertFiles = @()

            try { $aCertFiles = [System.IO.Directory]::EnumerateFiles("$CertArchiveDir\$subDir") } catch {}

            if ( -not $aCertFiles.Count ) { return '' }

            $patt = '[\\](?<Name>{0})_[^\\]*$' -f [regex]::Escape(($CertIssuer -replace '[\\:*?"<>|/]','')) # Поиск без запрещенных символов для файлов, чтобы такой файл мог существовать

            $FoundFiles = @($aCertFiles).Where({ [regex]::Match($_, $patt, 20).Groups['Name'].Value }) -like '*.c??'  # .cer or .crt | отдельный не строгий like - чтобы не учитывался регистр расширения
        }
        else
        {
            if ( [System.IO.File]::Exists($FileCert) )
            {
                $FoundFiles = $FileCert
            }
        }

        [string] $CertPEM = ''
        [string] $Cert    = ''
        [string] $Name    = ''
        [string] $SigAlg  = ''

        [string] $CrossIssuer = 'Microsoft Code Verification Root'
        [string] $Issuer      = ''

        foreach ( $File in $FoundFiles )
        {
            $Cert  = [string]::Join("`n", ((& $openssl x509 -outform pem -in $File) + ''))  #2>$null  # in DER or PEM; out strig PEM
            $iCert = ''

            $iCert = $Cert | & $openssl x509 -text -noout -passin pass: $x509params #2>$null  # Only PEM

            $SigAlg    = [regex]::Match($iCert,'Signature Algorithm: (?<Name>(md|sha)[\d]+)',4).Groups['Name'].Value
            $FoundFile = $File

            if ( $CrossMS )
            {
                $Issuer = [regex]::Match($iCert,'issuer(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value

                if ( $CertAlg )
                {
                    if (( $Issuer -eq $CrossIssuer ) -and ( $SigAlg -eq $SigAlg ))
                    {
                        $CertPEM   = $Cert
                        $Name      = [System.IO.Path]::GetFileName($File)

                        break
                    }
                }
                else
                {
                    if (( $Issuer -eq $CrossIssuer ) -and $SigAlg )
                    {
                        $CertPEM   = $Cert
                        $Name      = [System.IO.Path]::GetFileName($File)

                        break
                    }
                }
            }
            else
            {
                if ( $CertAlg -eq $SigAlg )
                {
                    $CertPEM   = $Cert
                    $Name      = [System.IO.Path]::GetFileName($File)

                    break
                }
            }
        }


        if ( $CertPEM -and ( $CertPEM -like '*-----BEGIN CERTIFICATE-----*' ))
        {
            if ( $FileCert )
            {
                Write-host " RePack: Specified certificate is correct: $Name | $SigAlg" -ForegroundColor DarkGray
            }
            else
            {
                Write-host " RePack: Found cert in Archive ($subDir): $Name | $SigAlg" -ForegroundColor DarkGray
            }
        }
        else
        {
            if ( $FileCert )
            {
                [string] $Name = [System.IO.Path]::GetFileName($FileCert)

                if ( -not $FoundFile )
                {
                    Write-host " RePack: Specified certificate was not found: $Name" -ForegroundColor DarkYellow
                }
                else
                {
                    Write-host " RePack: Specified certificate is not correct: $Name" -ForegroundColor DarkYellow
                }
            }
            else
            {
                Write-host " RePack: Not found cert in Archive ($subDir)" -ForegroundColor DarkYellow
            }
        }

        Return $CertPEM
    }


    # search in CA or Root store | Out string Cert PEM or ''
    Function Get-Chain-Cert-StoreWindows ( [string] $CertIssuer, [string] $CertAlg, [switch] $CA, [switch] $Root ) {

        if ( -not $CertIssuer ) { return '' }

        [string] $subDir = 'Root'
        if ( $CA ) { $subDir = 'CA' }

        [string] $patt = '(^|.+?,\s)(CN|OU)=["]?(?<Name>{0})["]?(,\s|$)' -f [regex]::Escape($CertIssuer)

        [array] $aCertData = (Get-ChildItem -Path Cert:\CurrentUser\$subDir\ -ErrorAction Continue) # CurrentUser contain all CurrentUser and LocalMachine cert

        $aCertData = @($aCertData).Where({ [regex]::Match( $_.Subject, $patt, 20 ).Groups['Name'].Value })

        [string] $CertPEM = ''
        [string] $Cert    = ''
        [string] $SigAlg  = ''
        [byte[]] $b       = @()

        foreach ( $CertData in $aCertData )
        {
            $iCert = ''
            $Cert  = ''
            $b     = $CertData.Rawdata

            if ( $b.Count )
            {
                $Cert = "-----BEGIN CERTIFICATE-----`n{0}`n-----END CERTIFICATE-----`n" -f [System.Convert]::ToBase64String($b,1)  # [System.Base64FormattingOptions]::InsertLineBreaks.value__ = 1
            }

            if ( $Cert )
            {
                $iCert  = $Cert | & $openssl x509 -text -noout -passin pass: $x509params #2>$null  # Only PEM
                $SigAlg = [regex]::Match($iCert,'Signature Algorithm: (?<Name>(md|sha)[\d]+)',4).Groups['Name'].Value

                if ( $CertAlg -eq $SigAlg )
                {
                    $CertPEM = $Cert

                    break
                }
            }
        }

        if ( $CertPEM )
        {
            Write-host " RePack: Found cert in: (Cert:\CurrentUser\$subDir\) | $CertAlg | $CertIssuer" -ForegroundColor DarkGray
        }
        else
        {
            Write-host " RePack: Not found cert in: (Cert:\CurrentUser\$subDir\) | $CertAlg | $CertIssuer" -ForegroundColor DarkYellow
        }

        Return $CertPEM
    }


    # CN or OU Issuer and PEM string cert | out hashtable
    Function Get-Chain-Cert-Info ( [string] $CertIssuer, [string] $CertPEM ) {

        if ( -not ( $CertIssuer -and $CertPEM )) { return @{} }

        [hashtable] $ht = @{}
        $iCert = ''

        $iCert = $CertPEM | & $openssl x509 -text -noout -passin pass: $x509params #2>$null  # Only PEM

        if ( $iCert )
        {
            $subject = [regex]::Match($iCert,'subject(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value # кавычек не бывает, берет сначала CN, если есть, либо OU, если есть, и первую если 2
            $issuer  = [regex]::Match($iCert,'issuer(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value

            $ht = @{
                subject = $subject
                issuer  = $issuer
                cert    = $CertPEM

                notBefore = [regex]::Match($iCert,'notBefore=(?<Name>[^\s]+)',4).Groups['Name'].Value # yyyy-MM-dd
                notAfter  = [regex]::Match($iCert,'notAfter=(?<Name>[^\s]+)',4).Groups['Name'].Value  # yyyy-MM-dd
                print     = $(try { (($iCert -like 'sha1 Fingerprint=*').ToLower() -replace '.*?=|:','') } catch {''})
                SigAlg    = [regex]::Match($iCert,'Signature Algorithm: (?<Name>(md|sha)[\d]+)',4).Groups['Name'].Value
                Vers      = [regex]::Match($iCert,'Version: (?<Name>[\d]+)',4).Groups['Name'].Value
            }

            if ( $CertIssuer -eq $subject )
            {
                Write-host " RePack: Chain is matched | From cert issuer (to): $CertIssuer | To next cert subject (by) | SigAlg: $($ht.SigAlg)" -ForegroundColor DarkGreen
            }
            else
            {
                Write-host " RePack: Chain isn't matched | From certificate issuer (to): $CertIssuer" -ForegroundColor DarkYellow
                Write-host " RePack: · · · · · · · · · · |    To next cert subject (by): $subject | SigAlg: $($ht.SigAlg)" -ForegroundColor DarkYellow
            }
        }
        else
        {
            Write-host " RePack: Certificate not correct" -ForegroundColor DarkYellow
        }

        Return $ht
    }



    [string] $CertPEM = ''

    if ( -not $hIntCA_1.Count )
    {
        Write-host " RePack: No IntCA Certificate in pfx" -ForegroundColor DarkGray

        $CertPEM = Get-Chain-Cert-ArchiveFile -CertIssuer $hClient.issuer -CertAlg $hClient.SigAlg -IntCA

        if ( -not $CertPEM )
        {
            $CertPEM = Get-Chain-Cert-StoreWindows -CertIssuer $hClient.issuer -CertAlg $hClient.SigAlg -CA
        }

        if ( $CertPEM )
        {
            $hIntCA_1 = Get-Chain-Cert-Info -CertIssuer $hClient.issuer -CertPEM $CertPEM
        }
    }



    $CertPEM = ''
    $issuer  = ''
    $SigAlg  = ''

    # Проверка и добавление в переменную сертификата Root по последнему Int CA
    if ( -not $hRootCA.Count )
    {
        Write-host " RePack: No Root Certificate in pfx" -ForegroundColor DarkGray

        if ( $hIntCA_2.Count )
        {
            $issuer = $hIntCA_2.issuer
            $SigAlg = $hIntCA_2.SigAlg
        }
        elseif ( $hIntCA_1.Count )
        {
            $issuer = $hIntCA_1.issuer
            $SigAlg = $hIntCA_1.SigAlg
        }

        $CertPEM = Get-Chain-Cert-ArchiveFile -CertIssuer $issuer -CertAlg $SigAlg -RootCA

        if ( -not $CertPEM )
        {
            $CertPEM = Get-Chain-Cert-StoreWindows -CertIssuer $issuer -CertAlg $SigAlg -Root
        }

        if ( $CertPEM )
        {
            $hRootCA = Get-Chain-Cert-Info -CertIssuer $issuer -CertPEM $CertPEM
        }
    }


    #$ITab = '···································'
    $ITab = '· · · · · | · · · · · · · · · · · ·'
    $nTab = '{0}' -f ('-' * 35)

    $Info = '{0,-6} v{1,1} | {2,10} > {3,10}' -f $hClient.SigAlg, $hClient.Vers, $hClient.notBefore, $hClient.notAfter

    Write-host     " RePack: $Info | Client Subject (to): $($hClient.subject)" -ForegroundColor White -NoNewline
    Write-host " | Thumbprint: " -ForegroundColor DarkGray -NoNewline
    Write-host "$($hClient.print)" -ForegroundColor DarkCyan
    Write-host     " RePack: $ITab | Client  issuer (by): $($hClient.issuer)" -ForegroundColor White



    if ( $hIntCA_1.Count )
    {
        $Info = '{0,-6} v{1,1} | {2,10} > {3,10}' -f $hIntCA_1.SigAlg, $hIntCA_1.Vers, $hIntCA_1.notBefore, $hIntCA_1.notAfter

        Write-host " RePack: $Info | IntCA1 subject (to): $($hIntCA_1.subject)" -ForegroundColor Gray -NoNewline
        Write-host " | Thumbprint: " -ForegroundColor DarkGray -NoNewline
        Write-host "$($hIntCA_1.print)" -ForegroundColor DarkCyan
        Write-host " RePack: $ITab | IntCA1  issuer (by): $($hIntCA_1.issuer)" -ForegroundColor Gray
    }
    else
    {
        Write-host " RePack: $nTab | IntCA1 subject (to): -------------" -ForegroundColor Yellow
        Write-host " RePack: $nTab | IntCA1  issuer (by): -------------" -ForegroundColor Yellow
    }



    if ( $hIntCA_2.Count )
    {
        $Info = '{0,-6} v{1,1} | {2,10} > {3,10}' -f $hIntCA_2.SigAlg, $hIntCA_2.Vers, $hIntCA_2.notBefore, $hIntCA_2.notAfter

        Write-host " RePack: $Info | IntCA2 subject (to): $($hIntCA_2.subject)" -ForegroundColor DarkGray
        Write-host " RePack: $ITab | IntCA2  issuer (by): $($hIntCA_2.issuer)" -ForegroundColor DarkGray
    }


    # Проверка и добавление в переменную сертификата Int CA
    if ( $hRootCA.Count )
    {
        if ( -not $RootCA )
        {
            $RootCA = $hRootCA.cert
        }

        $Info = '{0,-6} v{1,1} | {2,10} > {3,10}' -f $hRootCA.SigAlg, $hRootCA.Vers, $hRootCA.notBefore, $hRootCA.notAfter

        Write-host " RePack: $Info | RootCA subject (to): $($hRootCA.subject)" -ForegroundColor White -NoNewline
        Write-host " | Thumbprint: " -ForegroundColor DarkGray -NoNewline
        Write-host "$($hRootCA.print)" -ForegroundColor DarkCyan
        Write-host " RePack: $ITab | RootCA  issuer (by): $($hRootCA.issuer)" -ForegroundColor White
    }
    else
    {
        Write-host " RePack: $nTab | RootCA subject (to): $($hRootCA.subject)" -ForegroundColor Yellow
        Write-host " RePack: $nTab | RootCA  issuer (by): $($hRootCA.issuer)" -ForegroundColor Yellow
    }



    # Check and set All CA Int
    if ( $hIntCA_1.Count )
    {
        $IntCA = $hIntCA_1.cert

        if ( -not $IntCA ) { Write-host " RePack: [$NameThisFunction] Error: No First Intermediate CA in $namePFX.pfx" -ForegroundColor Red ; Return $false }

        if ( $hIntCA_2.Count )
        {
            $IntCA += $hIntCA_2.cert

            Write-host " RePack: Intermediate CA Count 2 in $namePFX.pfx" -ForegroundColor DarkCyan
        }
    }
    else
    {
        Write-host " RePack: Error: No Intermediate CA in $namePFX.pfx" -ForegroundColor Red
    }





    $CertPEM = ''
    $issuer  = ''
    [bool] $Warn = $false


    if ( $AddCross )
    {
        Write-host " RePack: Add Cross" -ForegroundColor DarkGray

        if ( $hIntCA_1.issuer )   # Cross идёт именно к issuer первого Int, так как Int может быть больше 1
        {
            Write-host " RePack: Check IntCA1 issuer (by): $($hIntCA_1.issuer)" -ForegroundColor Gray

            if ( $CrossCertFile -and -not ( $CrossCertFile -like '*\*' ))
            {
                $CrossCertFile = '{0}\{1}' -f $PathPFX, $CrossCertFile
            }

            if ( [System.IO.File]::Exists($CrossCertFile) )
            {
                $CertPEM = Get-Chain-Cert-ArchiveFile -CertIssuer $hIntCA_1.issuer -CrossMS -FileCert $CrossCertFile
            }
            else
            {
                $CertPEM = Get-Chain-Cert-ArchiveFile -CertIssuer $hIntCA_1.issuer -CrossMS
            }

            if ( $CertPEM )
            {
                Write-Host " RePack: Check crosscert" -ForegroundColor DarkGray

                $hCrossMS = Get-Chain-Cert-Info -CertIssuer $hIntCA_1.issuer -CertPEM $CertPEM

                if ( $hIntCA_1.issuer -ne $hCrossMS.subject )
                {
                    Write-host " RePack: Crosscert is not matched by the IntCA1 issuer (by): $($hIntCA_1.issuer)" -ForegroundColor Red

                    $Warn = $true
                }
            }
            else
            {
                if ( $CrossCertFile )
                {
                    Write-Host " RePack: Specified Crosscert is not fit" -ForegroundColor Red
                }
                else
                {
                    Write-Host " RePack: Crosscert not found in folder: \_Tools\CertArchive\CrossMS" -ForegroundColor Red
                }

                $Warn = $true
            }
        }
        else
        {
            Write-Host " RePack: No Int CA1 certificate" -ForegroundColor Red

            $Warn = $true
        }
    }


    if ( $hCrossMS.Count )
    {
        $Info = '{0,-6} v{1,1} | {2,10} > {3,10}' -f $hCrossMS.SigAlg, $hCrossMS.Vers, $hCrossMS.notBefore, $hCrossMS.notAfter

        Write-host " RePack: $Info | Cross  subject (to): $($hCrossMS.subject)" -ForegroundColor DarkCyan -NoNewline
        Write-host " | Thumbprint: $($hCrossMS.print)" -ForegroundColor DarkGray
        Write-host " RePack: $ITab | Cross  issuer  (by): $($hCrossMS.issuer)" -ForegroundColor DarkCyan
    }


    # Show Driver TBS
    if ( $TBS )
    {
        if ( $hIntCA_1.Count )
        {
            [string] $GetTBS = Get-TBS -CertBase64 $hIntCA_1.cert

            if ( $GetTBS )
            {
                Write-host " RePack: TBS: " -ForegroundColor Blue -NoNewline
                Write-host "$($hIntCA_1.subject)" -ForegroundColor White -NoNewline
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-host $GetTBS -ForegroundColor Blue -NoNewline
                Write-host ' | check TBS for: ' -ForegroundColor DarkGray -NoNewline
                Write-host $ClientSubject -ForegroundColor White

                Write-host " RePack: TBS Driver blocklist | Check here: " -ForegroundColor Blue -NoNewline
                Write-host 'https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/design/microsoft-recommended-driver-block-rules#vulnerable-driver-blocklist-xml' -ForegroundColor DarkGray
            }
        }
    }


    # Сохранение файлов
    if ( -not ( $NotSave -or $Global:LastExitCode -or $Warn ))
    {
        Write-host " RePack: Saving files" -ForegroundColor Magenta

        $Client = [string]::Join("`n",($Client + ''))
        [string] $ClientInt = [string]::Join("`n",($Client + $IntCA))

        [System.Text.UTF8Encoding] $utf8 = [System.Text.UTF8Encoding]::new($false)

        if ( $SaveForSign )
        {
            Write-host " RePack: Saving ClientInt: " -ForegroundColor DarkMagenta -NoNewline
            Write-host $([System.IO.Path]::GetFileName($outCl_Int)) -ForegroundColor Gray

            Set-Content -Value $utf8.GetBytes($ClientInt) -Encoding Byte -Path $outCl_Int -Force -ErrorAction Continue
            if ( -not $? ) { $Warn = $true }

            Write-host " RePack: Saving ClientKey: " -ForegroundColor DarkMagenta -NoNewline
            Write-host $([System.IO.Path]::GetFileName($outKEY)) -ForegroundColor Gray

            Set-Content -Value $utf8.GetBytes([string]::Join("`n",($KEY + ''))) -Encoding Byte -Path $outKEY -Force -ErrorAction Continue
            if ( -not $? ) { $Warn = $true }
        }
        else
        {
            Write-host " RePack: Saving    Client: " -ForegroundColor DarkMagenta -NoNewline
            Write-host $([System.IO.Path]::GetFileName($outClient)) -ForegroundColor Gray

            Set-Content -Value $utf8.GetBytes($Client)    -Encoding Byte -Path $outClient -Force -ErrorAction Continue
            if ( -not $? ) { $Warn = $true }

            Write-host " RePack: Saving ClientInt: " -ForegroundColor DarkMagenta -NoNewline
            Write-host $([System.IO.Path]::GetFileName($outCl_Int)) -ForegroundColor Gray

            Set-Content -Value $utf8.GetBytes($ClientInt) -Encoding Byte -Path $outCl_Int -Force -ErrorAction Continue
            if ( -not $? ) { $Warn = $true }

            Write-host " RePack: Saving ClientKey: " -ForegroundColor DarkMagenta -NoNewline
            Write-host $([System.IO.Path]::GetFileName($outKEY)) -ForegroundColor Gray

            Set-Content -Value $utf8.GetBytes([string]::Join("`n",($KEY + ''))) -Encoding Byte -Path $outKEY -Force -ErrorAction Continue
            if ( -not $? ) { $Warn = $true }

            Write-host " RePack: Saving       PEM: " -ForegroundColor DarkMagenta -NoNewline
            Write-host $([System.IO.Path]::GetFileName($outPEM)) -ForegroundColor Gray

            Set-Content -Value $utf8.GetBytes([string]::Join("`n",($PEM + ''))) -Encoding Byte -Path $outPEM -Force -ErrorAction Continue
            if ( -not $? ) { $Warn = $true }

            Write-host " RePack: Saving   CA Root: " -ForegroundColor DarkMagenta -NoNewline
            Write-host $([System.IO.Path]::GetFileName($outCARoot)) -ForegroundColor Gray

            Set-Content -Value $utf8.GetBytes($RootCA) -Encoding Byte -Path $outCARoot -Force -ErrorAction Continue
            if ( -not $? ) { $Warn = $true }

            Write-host " RePack: Saving    CA Int: " -ForegroundColor DarkMagenta -NoNewline
            Write-host $([System.IO.Path]::GetFileName($outCAint)) -ForegroundColor Gray

            Set-Content -Value $utf8.GetBytes($IntCA)  -Encoding Byte -Path $outCAint  -Force -ErrorAction Continue
            if ( -not $? ) { $Warn = $true }

            Write-host " RePack: Saving    CA All: " -ForegroundColor DarkMagenta -NoNewline
            Write-host $([System.IO.Path]::GetFileName($outCAall)) -ForegroundColor Gray

            Set-Content -Value $utf8.GetBytes($CAall)  -Encoding Byte -Path $outCAall  -Force -ErrorAction Continue
            if ( -not $? ) { $Warn = $true }
        }

        if ( $SavePFX )
        {
            Write-host " RePack: Saving   New PFX: " -ForegroundColor Magenta -NoNewline
            Write-host "$namePFX.pfx" -ForegroundColor White -NoNewline
            Write-host " | Pass > '" -ForegroundColor Magenta -NoNewline
            Write-host $Pass -ForegroundColor White -NoNewline
            Write-host "'" -ForegroundColor Magenta

            [string] $PemIn = [string]::Join("`n",($ClientInt + $RootCA))

            [string] $Path      = [System.IO.Path]::GetDirectoryName($FilePFX)
             [array] $aFilesPFX = [System.IO.Directory]::EnumerateFiles($Path,"$namePFX*.pfx") -Replace('.+\\','')
            [string] $OldPFX    = ''

            [int] $N = 0 ; do { $N++ ; $OldPFX = '{0}_old{1:000}.pfx' -f $namePFX, $N } until ( -not ( $aFilesPFX -like $OldPFX )) # Поиск отсутствующего имени файла для переименовки по шаблону

            Rename-Item -LiteralPath $FilePFX -NewName $OldPFX -Force -ErrorAction Continue
            if ( -not $? ) { $Warn = $true }

            Write-host " RePack: Saving   Old PFX: " -ForegroundColor Magenta -NoNewline
            Write-host $OldPFX -ForegroundColor White -NoNewline
            Write-host " | Pass > '" -ForegroundColor Magenta -NoNewline
            Write-host $OldPass -ForegroundColor White -NoNewline
            Write-host "'" -ForegroundColor Magenta

            $PemIn | & $openssl pkcs12 -export -inkey $outKEY -out $FilePFX -passin pass:$Pass -passout pass:$NewPass #2>$null
        }

        if ( $AddCross -and $hCrossMS.Count )
        {
            $FileCross = [System.IO.Path]::GetFileName($outCross)
            Write-host " RePack: Saving Crosscert: " -ForegroundColor DarkMagenta -NoNewline
            Write-host $FileCross -ForegroundColor Gray

            Set-Content -Value $utf8.GetBytes($hCrossMS.cert) -Encoding Byte -Path $outCross -Force -ErrorAction Continue
            if ( -not $? ) { $Warn = $true }
        }
    }
    elseif ( -not $NotSave )
    {
        if ( $PEM -and -not $SaveForSign )
        {
            [System.Text.UTF8Encoding] $utf8 = [System.Text.UTF8Encoding]::new($false)

            Write-host " RePack: Saving only PEM (There was a problem)" -ForegroundColor Magenta

            Write-host " RePack: Saving      PEM: " -ForegroundColor DarkMagenta -NoNewline
            Write-host $([System.IO.Path]::GetFileName($outPEM)) -ForegroundColor Gray

            Set-Content -Value $utf8.GetBytes([string]::Join("`n",($PEM + ''))) -Encoding Byte -Path $outPEM -Force -ErrorAction Continue
            if ( -not $? ) { $Warn = $true }
        }
    }
    else
    {
        Write-host " RePack: Without saving files" -ForegroundColor Green
    }


    if ( $Global:LastExitCode )
    {
        Write-Host " RePack: ExitCode: $Global:LastExitCode" -ForegroundColor Red

        Return $false
    }
    elseif ( $Warn )
    {
        Write-Host " RePack: Warn: $Warn" -ForegroundColor Red

        Return $false
    }
    else
    {
        Write-Host " RePack: ExitCode: $Global:LastExitCode | Warn: $Warn" -ForegroundColor DarkGreen

        Return $true
    }
}









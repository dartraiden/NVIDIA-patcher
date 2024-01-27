
# PFX v1 или v3 !
Function Info-PFX {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory)]
        [string] $FilePFX
       ,
        [Parameter(Mandatory = $false)]
        [string] $Pass
       ,
        [Parameter(Mandatory = $false)]
        [string] $Openssl = $Openssl # need v3.1.1 + legacy.dll
    )

    # Получение имени этой функции.
    [string] $NameThisFunction = $MyInvocation.MyCommand.Name

    [string] $namePFX = [System.IO.Path]::GetFileNameWithoutExtension($FilePFX)
    [string] $extPFX  = [System.IO.Path]::GetExtension($FilePFX)

    if ( $extPFX -ne '.pfx' )
    {
        Write-host '    PFX: ' -ForegroundColor DarkGray -NoNewline
        Write-Host "$NameThisFunction`: $namePFX$extPFX | File not PFX" -ForegroundColor Red
        Return
    }

    [string] $noPass = ''

    [array] $aLegacy = @()
    [array] $aErr = @()
    [string] $e = ''
    [string[]] $Client = @()

    try { $aErr = & $Openssl pkcs12 -in $FilePFX -info -passin pass:$Pass -noout 2>&1 } catch {}

    # Замена Pass на NewPass, если ошибка из-за Pass, или выход если не помогает. (Нужно для пресета, при репаке pfx в новый в ту же папку, если была замена Pass при этом, чтобы просто подхватил NewPass)
    if ( $Global:LastExitCode -and ( $e = $aErr -like '*invalid password[?]*' ))
    {
        try { $aErr = & $Openssl pkcs12 -in $FilePFX -info -passin pass: -noout 2>&1 } catch {}

        if ( $Global:LastExitCode -and ( $e = $aErr -like '*invalid password[?]*' ))
        {
            Write-host '    PFX: ' -ForegroundColor DarkGray -NoNewline
            Write-Host "$NameThisFunction`: $namePFX$extPFX | Error: Wrong Pass: '$Pass'" -ForegroundColor Red
            Return
        }
        else
        {
            $Pass   = ''
            $noPass = 'No Pass!'
        }
    }

    # использовать dll для распаковки PFX с поддержкой старых форматов как в openssl v1, если ошибка при получении инфы из PFX
    if ( $Global:LastExitCode )
    {
        $aLegacy = '-legacy', '-provider-path', [System.IO.Path]::GetDirectoryName($Openssl)
    }

    # Достать конечный сертификат Client.crt (первый сертификат в файле PEM)
    $Client = & $Openssl pkcs12 -in $FilePFX -nokeys -clcerts -passin pass:$Pass -passout pass:$Pass $aLegacy 2>$null
    if ( $Global:LastExitCode )
    {
        Write-host '    PFX: ' -ForegroundColor DarkGray -NoNewline
        Write-Host "$NameThisFunction`: $namePFX$extPFX | Error: get Client" -ForegroundColor Red
        Return
    }

    [string[]] $iCert = @() # temp var
    [hashtable] $hClient  = @{}
    [array] $x509params = '-certopt', 'no_header,no_sigdump,no_extensions,no_pubkey,no_serial,no_validity,no_issuer,no_subject,no_aux',
        '-fingerprint', '-sha1', '-dates', '-dateopt', 'iso_8601', '-subject', '-issuer', '-nameopt', 'utf8,dn_rev,sname,sep_semi_plus_space'

    # Client info
    $iCert = $Client | & $openssl x509 -text -noout -passin pass: $x509params 2>$null

    [string] $ClientSubject = [regex]::Match($iCert,'subject(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value # если бы было 2 одинаковые строки то возьмёт первую.
    [string] $ClientIssuer  = [regex]::Match($iCert,'issuer(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value

    if ( -not ($ClientSubject -and $ClientIssuer -and ($ClientSubject -ne $ClientIssuer)))
    {
        Write-host '    PFX: ' -ForegroundColor DarkGray -NoNewline
        Write-host "$NameThisFunction`: $namePFX$extPFX | Error: No Client cert in $namePFX.pfx" -ForegroundColor Red
        Return
    }

    $hClient = @{
        subject   = $ClientSubject
        notBefore = [regex]::Match($iCert,'notBefore=(?<Name>[^\s]+)',4).Groups['Name'].Value # yyyy-MM-dd
        notAfter  = [regex]::Match($iCert,'notAfter=(?<Name>[^\s]+)',4).Groups['Name'].Value  # yyyy-MM-dd
        print     = $(try { (($iCert -like 'sha1 Fingerprint=*').ToLower() -replace '.*?=|:','') } catch {''})
        SigAlg    = [regex]::Match($iCert,'Signature Algorithm: (?<Name>sha[\d]+)',4).Groups['Name'].Value
        Vers      = [regex]::Match($iCert,'Version: (?<Name>[\d]+)',4).Groups['Name'].Value
    }

    $Info = '{0} v{1} | {2} > {3}' -f $hClient.SigAlg, $hClient.Vers, $hClient.notBefore, $hClient.notAfter

    Write-host '    PFX: ' -ForegroundColor DarkGray -NoNewline
    Write-host $namePFX$extPFX -ForegroundColor White -NoNewline

    if ( $noPass )
    {
        Write-host ' | ' -ForegroundColor DarkGray -NoNewline
        Write-host "$noPass" -ForegroundColor Yellow -NoNewline
    }

    Write-host " | $Info | " -ForegroundColor DarkGray -NoNewline
    Write-host "$($hClient.subject)" -ForegroundColor Gray -NoNewline

    if ( $aLegacy.Count )
    {
        Write-host ' | ' -ForegroundColor DarkGray -NoNewline
        Write-host '[Legacy v1]' -ForegroundColor DarkCyan -NoNewline
    }

    Write-host " | $($hClient.print)" -ForegroundColor DarkGray
}





#
Function Info-CER {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory)]
        [string] $FileCER
       ,
        [Parameter(Mandatory = $false)]
        [string] $Openssl = $Openssl # need v3.1.1
       ,
        [Parameter(Mandatory = $false)]
        [int] $iIndentSize = 0
    )

    # Получение имени этой функции.
    [string] $NameThisFunction = $MyInvocation.MyCommand.Name

    [string] $nameCER = [System.IO.Path]::GetFileNameWithoutExtension($FileCER)
    [string] $extCER  = [System.IO.Path]::GetExtension($FileCER)

    if ( $extCER -notmatch '^\.(cer|crt)$' )
    {
        Write-host '    CER: ' -ForegroundColor DarkGray -NoNewline
        Write-Host "$NameThisFunction`: $nameCER$extCER | File not CER" -ForegroundColor Red
        Return
    }

    [string[]] $iCert = @() # temp var
    [hashtable] $hClient  = @{}
    [array] $x509params = '-certopt', 'no_header,no_sigdump,no_extensions,no_pubkey,no_serial,no_validity,no_issuer,no_subject,no_aux',
        '-fingerprint', '-sha1', '-dates', '-dateopt', 'iso_8601', '-subject', '-issuer', '-nameopt', 'utf8,dn_rev,sname,sep_semi_plus_space'

    # Client info
    $iCert = & $openssl x509 -in $FileCER -text -noout -passin pass: $x509params 2>$null

    if ( $Global:LastExitCode )
    {
        Write-host '    CER: ' -ForegroundColor DarkGray -NoNewline
        Write-Host "$NameThisFunction`: $nameCER$extCER | Error: get info" -ForegroundColor Red
        Return
    }


    [string] $ClientSubject = [regex]::Match($iCert,'subject(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value # если бы было 2 одинаковые строки то возьмёт первую.
    [string] $ClientIssuer  = [regex]::Match($iCert,'issuer(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value

    if ( -not ($ClientSubject -and $ClientIssuer -and ($ClientSubject -ne $ClientIssuer)))
    {
        Write-host '    CER: ' -ForegroundColor DarkGray -NoNewline
        Write-host "$NameThisFunction`: $nameCER$extCER | Error: No Client cert in $nameCER$extCER" -ForegroundColor Red
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

    # глабальные данные для отображения у каких сертификатов какие алгоритмы подписи, если не указаны другие принудительно 
    $hDataCertAlgsGlobal["$nameCER$extCER"] = @{ SigAlg = $hClient.SigAlg }

    $Info = '{0,-6} v{1} | {2} > {3}' -f $hClient.SigAlg, $hClient.Vers, $hClient.notBefore, $hClient.notAfter

    Write-host '    CER: ' -ForegroundColor DarkGray -NoNewline
    Write-host $("{0,-$iIndentSize}" -f "$nameCER$extCER") -ForegroundColor White -NoNewline

    Write-host " | $Info | " -ForegroundColor DarkGray -NoNewline
    Write-host "$($hClient.subject)" -ForegroundColor Gray -NoNewline

    Write-host " | $($hClient.print)" -ForegroundColor DarkGray
}




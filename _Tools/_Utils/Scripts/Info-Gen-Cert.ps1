
Function Info-Gen-Cert {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory = $false)]
        [string] $Folder = $UseCertsFolderGlobal
       ,
        [Parameter(Mandatory = $false)]
        [string] $Pass
       ,
        [Parameter(Mandatory = $false)]
        [string] $Openssl = $Openssl # need v3.1.1 + legacy.dll
    )

    # Получение имени этой функции.
    [string] $NameThisFunction = $MyInvocation.MyCommand.Name

    if ( -not ( $Folder -and $Openssl ))
    {
        Write-Host "$NameThisFunction`: Folder or Openssl.exe not specified" -ForegroundColor Red
        return
    }

    [string] $RootCrt = "$Folder\Gen-Root.crt"
    [string] $SignCrt = "$Folder\Gen-Sign.crt"
    [string] $SignKey = "$Folder\Gen-Sign.key"
    [string] $Tsa1Crt = "$Folder\Gen-TSA1.crt"
    [string] $Tsa2Crt = "$Folder\Gen-TSA2.crt"
    [string] $TsaKey  = "$Folder\Gen-TSA.key"
    
    [string] $SpecCrt = "$Folder\Gen-Spec.crt" # $SignKey и Pass для него те же 


      [bool] $TsaKeyValid  = $false
      [bool] $SignKeyValid = $false
     
    [string[]] $aTsaKey  = @()
    [string[]] $aSignKey = @()

    [string] $timeAndName = ''

    [array] $aErr = @()
    [string] $e = ''

    [string[]] $iCert = @() # temp var
    [hashtable] $hClient  = @{}
    [array] $x509params = '-certopt', 'no_header,no_sigdump,no_extensions,no_pubkey,no_serial,no_validity,no_issuer,no_subject,no_aux',
        '-fingerprint', '-sha1', '-dates', '-dateopt', 'iso_8601', '-subject', '-issuer', '-nameopt', 'utf8,dn_rev,sname,sep_semi_plus_space'

    if ( -not $Pass )
    {
        if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-Pass\s*=\s*(?<Pass>[^\s]+)\s*==' },'First') )
        {
            $Pass = $Matches.Pass
        }
    }



    # Tsa 1 + Key
    Write-Host '     Gen TSA1: ' -ForegroundColor DarkGray -NoNewline

    if ( [System.IO.File]::Exists($Tsa1Crt) )
    {
        # Cert info
        $iCert = & $openssl x509 -in $Tsa1Crt -text -noout $x509params 2>$null

        $hClient = @{
            subject   = [regex]::Match($iCert,'subject(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value # если бы было 2 одинаковые строки то возьмёт первую.
            notBefore = [regex]::Match($iCert,'notBefore=(?<Name>[^\s]+)',4).Groups['Name'].Value # yyyy-MM-dd
            notAfter  = [regex]::Match($iCert,'notAfter=(?<Name>[^\s]+)',4).Groups['Name'].Value  # yyyy-MM-dd
            print     = $(try { (($iCert -like 'sha1 Fingerprint=*').ToLower() -replace '.*?=|:','') } catch {''})
            SigAlg    = [regex]::Match($iCert,'Signature Algorithm: (?<Name>sha[\d]+)',4).Groups['Name'].Value
        }

        if ( $hClient.SigAlg )
        {
            Write-Host '  | [' -ForegroundColor DarkGray -NoNewline
            Write-Host "$('{0,-6}' -f $hClient.SigAlg)" -ForegroundColor Green -NoNewline
            Write-Host ']' -ForegroundColor DarkGray -NoNewline

            if ( [System.IO.File]::Exists($TsaKey) )
            {
                $aTsaKey = & $Openssl pkey -in $TsaKey -pubcheck -noout -passin pass: 2>&1

                if ( $aTsaKey -like 'Key is valid' )
                {
                    Write-Host '[' -ForegroundColor DarkGray -NoNewline
                    Write-Host 'TSA key' -ForegroundColor Green -NoNewline
                    Write-Host ']' -ForegroundColor DarkGray -NoNewline

                    $TsaKeyValid = $true
                }
                else
                {
                    Write-Host '[Gen-TSA.key Error]' -ForegroundColor Red -NoNewline
                }
            }
            else
            {
                Write-Host '[No Gen-TSA.key]' -ForegroundColor Red -NoNewline
            }

            $timeAndName = ' | [{0,10} > {1,10}] | {2}' -f $hClient.notBefore, $hClient.notAfter, $hClient.subject
            Write-Host $timeAndName -ForegroundColor DarkGray
        }
        else
        {
            Write-Host 'Error Gen-TSA1.crt' -ForegroundColor Red
        }
    }
    else
    {
        Write-Host 'No Gen-TSA1.crt' -ForegroundColor DarkYellow
    }


    # Tsa 2 + Key
    Write-Host '     Gen TSA2: ' -ForegroundColor DarkGray -NoNewline

    if ( [System.IO.File]::Exists($Tsa2Crt) )
    {
        # Cert info
        $iCert = & $openssl x509 -in $Tsa2Crt -text -noout $x509params 2>$null

        $hClient = @{
            subject   = [regex]::Match($iCert,'subject(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value # если бы было 2 одинаковые строки то возьмёт первую.
            notBefore = [regex]::Match($iCert,'notBefore=(?<Name>[^\s]+)',4).Groups['Name'].Value # yyyy-MM-dd
            notAfter  = [regex]::Match($iCert,'notAfter=(?<Name>[^\s]+)',4).Groups['Name'].Value  # yyyy-MM-dd
            print     = $(try { (($iCert -like 'sha1 Fingerprint=*').ToLower() -replace '.*?=|:','') } catch {''})
            SigAlg    = [regex]::Match($iCert,'Signature Algorithm: (?<Name>sha[\d]+)',4).Groups['Name'].Value
        }

        if ( $hClient.SigAlg )
        {
            Write-Host '  | [' -ForegroundColor DarkGray -NoNewline
            Write-Host "$('{0,-6}' -f $hClient.SigAlg)" -ForegroundColor Green -NoNewline
            Write-Host ']' -ForegroundColor DarkGray -NoNewline

            # Второй раз для TSA key
            if ( $TsaKeyValid )
            {
                Write-Host '[' -ForegroundColor DarkGray -NoNewline
                Write-Host 'TSA key' -ForegroundColor Green -NoNewline
                Write-Host ']' -ForegroundColor DarkGray -NoNewline
            }
            elseif ( $aTsaKey.Count )
            {
                if ( $aTsaKey -like 'Key is valid' )
                {
                    Write-Host '[' -ForegroundColor DarkGray -NoNewline
                    Write-Host 'TSA key' -ForegroundColor Green -NoNewline
                    Write-Host ']' -ForegroundColor DarkGray -NoNewline
                }
                else
                {
                    Write-Host '[Gen-TSA.key Error]' -ForegroundColor Red -NoNewline
                }
            }
            else
            {
                Write-Host '[No Gen-TSA.key]' -ForegroundColor Red -NoNewline
            }

            $timeAndName = ' | [{0,10} > {1,10}] | {2}' -f $hClient.notBefore, $hClient.notAfter, $hClient.subject
            Write-Host $timeAndName -ForegroundColor DarkGray
        }
        else
        {
            Write-Host 'Error Gen-TSA2.crt' -ForegroundColor Red
        }
    }
    else
    {
        Write-Host 'No Gen-TSA2.crt' -ForegroundColor DarkYellow
    }



    # Root
    Write-Host '     Gen Root: ' -ForegroundColor DarkGray -NoNewline

    if ( [System.IO.File]::Exists($RootCrt) )
    {
        # Cert info
        $iCert = & $openssl x509 -in $RootCrt -text -noout $x509params 2>$null

        $hClient = @{
            subject   = [regex]::Match($iCert,'subject(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value # если бы было 2 одинаковые строки то возьмёт первую.
            notBefore = [regex]::Match($iCert,'notBefore=(?<Name>[^\s]+)',4).Groups['Name'].Value # yyyy-MM-dd
            notAfter  = [regex]::Match($iCert,'notAfter=(?<Name>[^\s]+)',4).Groups['Name'].Value  # yyyy-MM-dd
            print     = $(try { (($iCert -like 'sha1 Fingerprint=*').ToLower() -replace '.*?=|:','') } catch {''})
            SigAlg    = [regex]::Match($iCert,'Signature Algorithm: (?<Name>sha[\d]+)',4).Groups['Name'].Value
        }

        if ( $hClient.SigAlg )
        {
            [array] $aCertRoot = (Get-ChildItem -Path Cert:\LocalMachine\Root -ErrorAction SilentlyContinue).Thumbprint

            if ( $hClient.print -and ( $aCertRoot -like $hClient.print ))
            {
                Write-Host '●' -ForegroundColor Green -NoNewline
            }
            else
            {
                Write-Host '○' -ForegroundColor DarkYellow -NoNewline
            }

            Write-Host ' | [' -ForegroundColor DarkGray -NoNewline
            Write-Host "$('{0,-6}' -f $hClient.SigAlg)" -ForegroundColor Green -NoNewline
            Write-Host ']         ' -ForegroundColor DarkGray -NoNewline

            $timeAndName = ' | [{0,10} > {1,10}] | {2}' -f $hClient.notBefore, $hClient.notAfter, $hClient.subject
            Write-Host $timeAndName -ForegroundColor DarkGray

        }
        else
        {
            Write-Host 'Error Gen-Root.crt' -ForegroundColor Red
        }
    }
    else
    {
        Write-Host 'No Gen-Root.crt' -ForegroundColor DarkYellow
    }


    # Sign + Key
    Write-Host '     Gen Sign: ' -ForegroundColor DarkGray -NoNewline

    if ( [System.IO.File]::Exists($SignCrt) )
    {
        # Cert info
        $iCert = & $openssl x509 -in $SignCrt -text -noout $x509params 2>$null

        $hClient = @{
            subject   = [regex]::Match($iCert,'subject(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value # если бы было 2 одинаковые строки то возьмёт первую.
            notBefore = [regex]::Match($iCert,'notBefore=(?<Name>[^\s]+)',4).Groups['Name'].Value # yyyy-MM-dd
            notAfter  = [regex]::Match($iCert,'notAfter=(?<Name>[^\s]+)',4).Groups['Name'].Value  # yyyy-MM-dd
            print     = $(try { (($iCert -like 'sha1 Fingerprint=*').ToLower() -replace '.*?=|:','') } catch {''})
            SigAlg    = [regex]::Match($iCert,'Signature Algorithm: (?<Name>sha[\d]+)',4).Groups['Name'].Value
        }

        if ( $hClient.SigAlg )
        {
            [array] $aCertSign = (Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher -ErrorAction SilentlyContinue).Thumbprint

            if ( $hClient.print -and ( $aCertSign -like $hClient.print ))
            {
                Write-Host '●' -ForegroundColor Green -NoNewline
            }
            else
            {
                Write-Host '○' -ForegroundColor DarkYellow -NoNewline
            }

            Write-Host ' | [' -ForegroundColor DarkGray -NoNewline
            Write-Host "$('{0,-6}' -f $hClient.SigAlg)" -ForegroundColor Green -NoNewline
            Write-Host ']' -ForegroundColor DarkGray -NoNewline

            if ( [System.IO.File]::Exists($SignKey) )
            {
                $aSignKey = & $Openssl pkey -in $SignKey -pubcheck -noout -passin pass:$Pass 2>&1

                if ( $aSignKey -like 'Key is valid' )
                {
                    Write-Host '[' -ForegroundColor DarkGray -NoNewline
                    Write-Host 'Signkey' -ForegroundColor Green -NoNewline
                    Write-Host ']' -ForegroundColor DarkGray -NoNewline

                    $SignKeyValid = $true
                }
                elseif ( $aSignKey -like '*wrong password*' )
                {
                    Write-Host '[Gen-Sign.key wrong pass]' -ForegroundColor Red -NoNewline
                }
                elseif ( $aSignKey -like '*empty password*' )
                {
                    Write-Host '[Gen-Sign.key need pass]' -ForegroundColor Red -NoNewline
                }
                else
                {
                    Write-Host '[Gen-Sign.key Error]' -ForegroundColor Red -NoNewline
                }
            }
            else
            {
                Write-Host '[No Gen-Sign.key]' -ForegroundColor Red -NoNewline
            }

            $timeAndName = ' | [{0,10} > {1,10}] | {2}' -f $hClient.notBefore, $hClient.notAfter, $hClient.subject
            Write-Host $timeAndName -ForegroundColor DarkGray
        }
        else
        {
            Write-Host 'Error Gen-Sign.crt' -ForegroundColor Red
        }
    }
    else
    {
        Write-Host 'No Gen-Sign.crt' -ForegroundColor DarkYellow
    }


    # Spec + Sign.Key

    if ( [System.IO.File]::Exists($SpecCrt) )
    {
        Write-Host '     Gen Spec: ' -ForegroundColor DarkGray -NoNewline

        # Cert info
        $iCert = & $openssl x509 -in $SpecCrt -text -noout $x509params 2>$null

        $hClient = @{
            subject   = [regex]::Match($iCert,'subject(=|=.+?;\s)(CN|OU)=(?<Name>[^;]+)',4).Groups['Name'].Value # если бы было 2 одинаковые строки то возьмёт первую.
            notBefore = [regex]::Match($iCert,'notBefore=(?<Name>[^\s]+)',4).Groups['Name'].Value # yyyy-MM-dd
            notAfter  = [regex]::Match($iCert,'notAfter=(?<Name>[^\s]+)',4).Groups['Name'].Value  # yyyy-MM-dd
            print     = $(try { (($iCert -like 'sha1 Fingerprint=*').ToLower() -replace '.*?=|:','') } catch {''})
            SigAlg    = [regex]::Match($iCert,'Signature Algorithm: (?<Name>sha[\d]+)',4).Groups['Name'].Value
        }

        if ( $hClient.SigAlg )
        {
            [array] $aCertSign = (Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher -ErrorAction SilentlyContinue).Thumbprint

            if ( $hClient.print -and ( $aCertSign -like $hClient.print ))
            {
                Write-Host '●' -ForegroundColor Green -NoNewline
            }
            else
            {
                Write-Host ' ' -ForegroundColor DarkYellow -NoNewline
            }

            Write-Host ' | [' -ForegroundColor DarkGray -NoNewline
            Write-Host "$('{0,-6}' -f $hClient.SigAlg)" -ForegroundColor Green -NoNewline
            Write-Host ']' -ForegroundColor DarkGray -NoNewline

            if ( $aSignKey.Count )
            {
                if ( $SignKeyValid )
                {
                    Write-Host '[' -ForegroundColor DarkGray -NoNewline
                    Write-Host 'Signkey' -ForegroundColor Green -NoNewline
                    Write-Host ']' -ForegroundColor DarkGray -NoNewline
                }
                elseif ( $aSignKey -like '*wrong password*' )
                {
                    Write-Host '[Gen-Sign.key wrong pass]' -ForegroundColor Red -NoNewline
                }
                elseif ( $aSignKey -like '*empty password*' )
                {
                    Write-Host '[Gen-Sign.key need pass]' -ForegroundColor Red -NoNewline
                }
                else
                {
                    Write-Host '[Gen-Sign.key Error]' -ForegroundColor Red -NoNewline
                }
            }
            else
            {
                Write-Host '[No Gen-Sign.key]' -ForegroundColor Red -NoNewline
            }

            $timeAndName = ' | [{0,10} > {1,10}] | {2}' -f $hClient.notBefore, $hClient.notAfter, $hClient.subject
            Write-Host $timeAndName -ForegroundColor DarkGray
        }
        else
        {
            Write-Host 'Error Gen-Spec.crt' -ForegroundColor Red
        }
    }
}



#
Function Manage-GEN {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory = $false)]
        [switch] $ReGenerate
    )

    Get-List-Presets

    [hashtable] $Params = @{}



    # параметры сертификатов
    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-Pass\s*=\s*(?<Pass>[^\s]+)\s*==' },'First') )
    {
        $Params += @{
            '-Pass' = $Matches.Pass
        }
    }

    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-Algorithm\s*=\s*(?<Algorithm>SHA(1|256|384|512))\s*==' },'First') )
    {
        $Params += @{
            '-SigAlg' = $Matches.Algorithm
        }
    }

    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-notBefore\s*=\s*(?<notBefore>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})\s*==' },'First') )
    {
        $Params += @{
            '-notBefore' = $Matches.notBefore
        }
    }

    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-notAfter\s*=\s*(?<notAfter>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})\s*==' },'First') )
    {
        $Params += @{
            '-notAfter' = $Matches.notAfter
        }
    }

    if ( $ReGenerate )
    {
        $Params += @{
            '-ReGenerate' = $ReGenerate
        }
    }




    # BaseName предустановки сертификатов
    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-Base-Name\s*=\s*(?<BaseName>[-._a-z0-9]+)\s*==' },'First') )
    {
        $Params += @{
            '-BaseName' = $Matches.BaseName
        }
    }

    # countryName
    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-Cntr-Name\s*=\s*(?<Name>[a-z]{2})\s*==' },'First') )
    {
        $Params += @{
            '-CntrName' = $Matches.Name.ToUpper()
        }
    }



    # Root Name
    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-Root-Name\s*=\s*(?<Name>[- ._a-z0-9%()]*?)\s*==' },'First') )
    {
        if ( $Matches.Name )
        {
            $Params += @{
                '-RootName' = $Matches.Name
            }
        }
    }

    # IntTsa Name (for TSA1 + TSA2)  
    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-IntT-Name\s*=\s*(?<Name>[- ._a-z0-9%()]*?)\s*==' },'First') )
    {
        if ( $Matches.Name )
        {
            $Params += @{
                '-IntTsaName' = $Matches.Name
            }
        }
    }

    # TSA1 Name
    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-TSA1-Name\s*=\s*(?<Name>[- ._a-z0-9%()]*?)\s*==' },'First') )
    {
        if ( $Matches.Name )
        {
            $Params += @{
                '-TSA1Name' = $Matches.Name
            }
        }
    }

    # TSA2 Name
    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-TSA2-Name\s*=\s*(?<Name>[- ._a-z0-9%()]*?)\s*==' },'First') )
    {
        if ( $Matches.Name )
        {
            $Params += @{
                '-TSA2Name' = $Matches.Name
            }
        }
    }

    # IntS Name (Sign)
    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-IntS-Name\s*=\s*(?<Name>[- ._a-z0-9%()]*?)\s*==' },'First') )
    {
        if ( $Matches.Name )
        {
            $Params += @{
                '-IntSignName' = $Matches.Name
            }
        }
    }

    # Sign Name
    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-Sign-Name\s*=\s*(?<Name>[- ._a-z0-9%()]*?)\s*==' },'First') )
    {
        if ( $Matches.Name )
        {
            $Params += @{
                '-SignName' = $Matches.Name
            }
        }
    }

    # IntP Name (Sign для Special PFX (Gen-Spec.pfx))
    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-IntP-Name\s*=\s*(?<Name>[- ._a-z0-9%()]*?)\s*==' },'First') )
    {
        if ( $Matches.Name )
        {
            $Params += @{
                '-IntSpecName' = $Matches.Name
            }
        }
    }

    # Spec Name (Sign для Special PFX (Gen-Spec.pfx))
    if ( $ListPresetsGlobal.Where({ $_ -match '^=\s*1\s*=\s*Gen-Cert-Spec-Name\s*=\s*(?<Name>[- ._a-z0-9%()]*?)\s*==' },'First') )
    {
        if ( $Matches.Name )
        {
            $Params += @{
                '-SpecName' = $Matches.Name
            }
        }
    }



    # + Spc0-9 Names (Sign для +Special PFX (Gen-Spc0-9.pfx)) | доп 9 сертификатов
    [System.Collections.Specialized.OrderedDictionary] $htGenCertSPC = @{}

    [string] $sNum = ''

    foreach ( $Line in $ListPresetsGlobal )
    {
        if ( $Line -match '^=\s*1\s*=\s*Gen-Cert-((?<Int>Int)|Spc)(?<sNum>\d)-Name\s*=\s*(?<Name>[- ._a-z0-9%()]*?)\s*(=\s*(sha)?(?<SigAlg>(1|256|384|512))?\s*)?==' )
        {
            $sNum  = $Matches.sNum

            if ( $htGenCertSPC[$sNum].SpcName -and ( -not ( $htGenCertSPC[$sNum].IntSpcName -eq $null ))) { Continue }

            if ( $Matches.Int )
            {
                $htGenCertSPC[$sNum] = @{
                    SpcName    = $htGenCertSPC[$sNum].SpcName
                    IntSpcName = $Matches.Name

                    IntOK      = $true
                    SpcOK      = $true
                    subjIntSpc = ''
                    subjSpc    = ''
                    SigAlg     = $htGenCertSPC[$sNum].Hash
                }
            }
            else
            {
                $htGenCertSPC[$sNum] = @{
                    SpcName    = $Matches.Name
                    IntSpcName = $htGenCertSPC[$sNum].IntSpcName
                     
                    IntOK      = $true
                    SpcOK      = $true
                    subjIntSpc = ''
                    subjSpc    = ''
                    SigAlg     = $(if ( $Matches.SigAlg ) { 'sha{0}' -f $Matches.SigAlg } else { '' })
                }
            }
        }
    }

    [string[]] $aKeys = $htGenCertSPC.Keys

    foreach ( $i in $aKeys )
    {
        if ( -not $htGenCertSPC[$i].SpcName ) { $htGenCertSPC.Remove($i) }
    }

    if ( $htGenCertSPC.Count )
    {
        $Params += @{
            '-htGenCertSPC' = $htGenCertSPC
        }
    }




    [array] $aWarningsGlobal = @()

    Gen-Certs @Params > $null

    if ( -not $aWarningsGlobal.Count )
    {
        Get-Pause
    }
}


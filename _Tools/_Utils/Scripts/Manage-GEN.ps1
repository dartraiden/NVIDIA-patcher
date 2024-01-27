
#
Function Manage-GEN {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory = $false)]
        [switch] $ReGenerate
    )

    Get-List-Presets

    [hashtable] $Params = @{}


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



    # остальное
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



    [array] $aWarningsGlobal = @()

    Gen-Certs @Params > $null

    if ( -not $aWarningsGlobal.Count )
    {
        Get-Pause
    }
}


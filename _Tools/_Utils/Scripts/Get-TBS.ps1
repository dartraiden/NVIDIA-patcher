
#
Function Get-TBS {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory)]
        [string] $CertBase64
       ,
        [Parameter(Mandatory = $false)]
        [string] $DllFolder = $TbsFolder
    )

    # Получение имени этой функции.
    [string] $NameThisFunction = $MyInvocation.MyCommand.Name

    try
    {
        <#
            # вариант по отдельности
            add-type -Path "$CurFolder\System.Buffers.dll"
            add-type -Path "$CurFolder\System.Memory.dll"
            add-type -Path "$CurFolder\System.ValueTuple.dll"
            add-type -Path "$CurFolder\System.Formats.Asn1.dll" # 1.7.0.0
            add-type -Path "$CurFolder\System.Runtime.CompilerServices.Unsafe.dll" # v4.5.3 (4.6.0 и выше не пашет!)
        #>

        if ( -not ( 'System.Formats.Asn1.AsnReader' -as [type] ))
        {
            Add-Type -Path "$DllFolder\System.Formats.Asn1.dll" -ReferencedAssemblies "$DllFolder\System.Buffers.dll","$DllFolder\System.Memory.dll","$DllFolder\System.ValueTuple.dll"
        }

        if ( -not ( 'System.Runtime.CompilerServices.Unsafe' -as [type] ))
        {
            Add-Type -Path "$DllFolder\System.Runtime.CompilerServices.Unsafe.dll" # v4.5.3 https://www.nuget.org/packages/System.Runtime.CompilerServices.Unsafe/4.5.3 > \lib\Net461\....
        }
    }
    catch
    {
        Write-Host "`n [$NameThisFunction] error: Add-Type" -ForegroundColor Red
        Return ''
    }

    [byte[]] $Bytes = @()

    try
    {
        $Bytes = [System.Convert]::FromBase64String(([regex]::Replace($CertBase64, '\s+|.*-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----.*','',16)))
    }
    catch
    {
        Write-Host "`n [$NameThisFunction] error: Get Bytes from Base64 string certificate" -ForegroundColor Red
        Return ''
    }

    if ( $Bytes.Length )
    {
        $asnReader = [System.Formats.Asn1.AsnReader]::new($Bytes, [System.Formats.Asn1.AsnEncodingRules]::DER)
    }
    else
    {
        Write-Host "`n [$NameThisFunction] error: Bytes Length 0" -ForegroundColor Red
        Return ''
    }


    [string] $hexStringTBS = ''

    try
    {
        $certificate = $asnReader.ReadSequence()

        # Read the TBS (To be signed) value of the certificate
        $tbsCertificate = $certificate.ReadEncodedValue()

        # Read the signature algorithm sequence
        $signatureAlgorithm = $certificate.ReadSequence()

        # Read the algorithm OID of the signature
        $algorithmOid = $signatureAlgorithm.ReadObjectIdentifier()

        # Define a hash function based on the algorithm OID
        switch ($algorithmOid) {
            "1.2.840.113549.1.1.4"   { $hashFunction = [System.Security.Cryptography.MD5]::Create()    }
            "1.2.840.10040.4.3"      { $hashFunction = [System.Security.Cryptography.SHA1]::Create()   }
            "2.16.840.1.101.3.4.3.2" { $hashFunction = [System.Security.Cryptography.SHA256]::Create() }
            "2.16.840.1.101.3.4.3.3" { $hashFunction = [System.Security.Cryptography.SHA384]::Create() }
            "2.16.840.1.101.3.4.3.4" { $hashFunction = [System.Security.Cryptography.SHA512]::Create() }
            "1.2.840.10045.4.1"      { $hashFunction = [System.Security.Cryptography.SHA1]::Create()   }
            "1.2.840.10045.4.3.2"    { $hashFunction = [System.Security.Cryptography.SHA256]::Create() }
            "1.2.840.10045.4.3.3"    { $hashFunction = [System.Security.Cryptography.SHA384]::Create() }
            "1.2.840.10045.4.3.4"    { $hashFunction = [System.Security.Cryptography.SHA512]::Create() }
            "1.2.840.113549.1.1.5"   { $hashFunction = [System.Security.Cryptography.SHA1]::Create()   }
            "1.2.840.113549.1.1.11"  { $hashFunction = [System.Security.Cryptography.SHA256]::Create() }
            "1.2.840.113549.1.1.12"  { $hashFunction = [System.Security.Cryptography.SHA384]::Create() }
            "1.2.840.113549.1.1.13"  { $hashFunction = [System.Security.Cryptography.SHA512]::Create() }
            default { Write-Host "n [$NameThisFunction] error: No handler for algorithm $algorithmOid" -ForegroundColor Red ; Return '' }
        }

        # Compute the hash of the TBS value using the hash function
        $hash = $hashFunction.ComputeHash($tbsCertificate.ToArray())

        # Convert the hash to a hex string and print it
        $hexStringTBS = [System.BitConverter]::ToString($hash) -replace '-', ''
    }
    catch
    {
         Write-Host "`n [$NameThisFunction]: $($_.CategoryInfo.Category): $($_.Exception.Message)" -ForegroundColor Red
         Write-Host " [$NameThisFunction]: $($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red
    }

    Return $hexStringTBS
}


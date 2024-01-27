
#
Function Manage-Cert-Store {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory = $true, ParameterSetName = 'AddRoot')]
        [switch] $AddRoot
       ,
        [Parameter(Mandatory = $true, ParameterSetName = 'AddTrusted')]
        [switch] $AddTrusted
       ,
        [Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
        [switch] $Remove
       ,
        [Parameter(Mandatory = $false)]
        [string] $Folder = $UseCertsFolderGlobal
       ,
        [Parameter(Mandatory = $false)]
        [string] $Openssl = $Openssl # need v3.1.1
    )

    [string[]] $iCert = @() # temp var
    [array] $aCerts   = @() # temp var
    [string] $print   = ''  # temp var
    [string] $Name    = ''  # temp var
    [int] $err = 0

    [array] $x509params = '-certopt', 'no_header,no_sigdump,no_extensions,no_pubkey,no_serial,no_validity,no_issuer,no_subject,no_aux', '-fingerprint', '-sha1'

    Function Add-Remove-Cert ( [string] $Crt, [string] $StoreName ) {

        $Name = [System.IO.Path]::GetFileName($Crt)

        if ( [System.IO.File]::Exists($Crt)  )
        {
            $aCerts = (Get-ChildItem -Path Cert:\LocalMachine\$StoreName -ErrorAction SilentlyContinue).Thumbprint

            # Cert info
            $iCert = & $openssl x509 -in $Crt -text -noout $x509params 2>$null
            $print = $(try { (($iCert -like 'sha1 Fingerprint=*').ToLower() -replace '.*?=|:','') } catch {''})


            if ( $print )
            {
                if ( $aCerts -like $print )
                {
                    if ( $Remove )
                    {
                        Write-Host '   Store: ' -ForegroundColor DarkGray -NoNewline
                        Write-Host "Remove " -ForegroundColor Magenta -NoNewline
                        Write-Host "$Name " -ForegroundColor White -NoNewline
                        Write-Host 'from ' -ForegroundColor DarkGray -NoNewline
                        Write-Host "$StoreName " -ForegroundColor Cyan -NoNewline
                        Write-Host 'store ' -ForegroundColor DarkGray -NoNewline
                        Write-Host '| Thumbprint: ' -ForegroundColor DarkGray -NoNewline
                        Write-Host $print -ForegroundColor White

                        $err = 0

                        try { & 'certutil.exe' -delstore $StoreName $print > $null }
                        catch
                        {
                            $err = 1
                            Write-Host " [$NameThisFunction] $($_)`n$($_.ScriptStackTrace)`n$($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red
                        }

                        if ( $Global:LastExitCode -or $err )
                        {
                            Write-Host '   Store: ' -ForegroundColor DarkGray -NoNewline
                            Write-Host 'Remove Error' -ForegroundColor Red
                        }
                        else
                        {
                            Write-Host '   Store: ' -ForegroundColor DarkGray -NoNewline
                            Write-Host 'Remove Ok' -ForegroundColor Green
                        }
                    }
                    else
                    {
                        Write-Host '   Store: ' -ForegroundColor DarkGray -NoNewline
                        Write-Host "$Name " -ForegroundColor White -NoNewline
                        Write-Host 'already exist in ' -ForegroundColor Green -NoNewline
                        Write-Host "$StoreName " -ForegroundColor Cyan -NoNewline
                        Write-Host 'store ' -ForegroundColor DarkGray -NoNewline
                        Write-Host '| Thumbprint: ' -ForegroundColor DarkGray -NoNewline
                        Write-Host $print -ForegroundColor White
                    }
                }
                else
                {
                    if ( $Remove )
                    {
                        Write-Host '   Store: ' -ForegroundColor DarkGray -NoNewline
                        Write-Host "$Name " -ForegroundColor White -NoNewline
                        Write-Host 'not exist in ' -ForegroundColor Green -NoNewline
                        Write-Host "$StoreName " -ForegroundColor Cyan -NoNewline
                        Write-Host 'store ' -ForegroundColor DarkGray -NoNewline
                        Write-Host '| Thumbprint: ' -ForegroundColor DarkGray -NoNewline
                        Write-Host $print -ForegroundColor White
                    }
                    else
                    {
                        Write-Host '   Store: ' -ForegroundColor DarkGray -NoNewline
                        Write-Host 'Add ' -ForegroundColor DarkCyan -NoNewline
                        Write-Host "$Name " -ForegroundColor White -NoNewline
                        Write-Host 'to ' -ForegroundColor DarkGray -NoNewline
                        Write-Host "$StoreName " -ForegroundColor Cyan -NoNewline
                        Write-Host 'store ' -ForegroundColor DarkGray -NoNewline
                        Write-Host '| Thumbprint: ' -ForegroundColor DarkGray -NoNewline
                        Write-Host $print -ForegroundColor White

                        $err = 0

                        try { & 'certutil.exe' -f -addstore $StoreName "$Crt" > $null }
                        catch
                        {
                            $err = 1
                            Write-Host " [$NameThisFunction] $($_)`n$($_.ScriptStackTrace)`n$($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red
                        }

                        if ( $Global:LastExitCode -or $err )
                        {
                            Write-Host '   Store: ' -ForegroundColor DarkGray -NoNewline
                            Write-Host 'Add Error' -ForegroundColor Red
                        }
                        else
                        {
                            Write-Host '   Store: ' -ForegroundColor DarkGray -NoNewline
                            Write-Host 'Add Ok' -ForegroundColor Green
                        }
                    }
                }
            }
            else
            {
                Write-Host '   Store: ' -ForegroundColor DarkGray -NoNewline
                Write-Host "Error get info $Name" -ForegroundColor Red
            }
        }
        else
        {
            Write-Host '   Store: ' -ForegroundColor DarkGray -NoNewline
            Write-Host "File $Name not exist" -ForegroundColor DarkYellow
        }
    }

    Write-Host

    if ( $Remove )
    {
        Write-Host '   Store: ' -ForegroundColor DarkGray -NoNewline
        Write-Host 'Remove from Store' -ForegroundColor Magenta
    }
    else
    {
        Write-Host '   Store: ' -ForegroundColor DarkGray -NoNewline
        Write-Host 'Add to Store' -ForegroundColor DarkCyan
    }

    if ( ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) )
    {
        if ( $AddRoot -or $Remove )
        {
            Add-Remove-Cert -Crt "$Folder\Gen-Root.crt" -StoreName 'Root'
        }

        if ( $AddTrusted -or $Remove )
        {
            Add-Remove-Cert -Crt "$Folder\Gen-Sign.crt" -StoreName 'TrustedPublisher'
        }
    }
    else
    {
        Write-Host '   Store: ' -ForegroundColor DarkGray -NoNewline
        Write-Host 'Need admin privileges' -ForegroundColor Yellow -NoNewline
        Write-Host ' | ' -ForegroundColor DarkGray -NoNewline
        Write-Host 'Skiped' -ForegroundColor Red
    }

    Get-Pause
}


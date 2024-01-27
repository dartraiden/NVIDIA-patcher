
# PFX v1 или v3 !
Function Manage-PFX {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ParameterSetName = 'Menu' )]
        [switch] $Menu
       ,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ParameterSetName = 'Test' )]
        [switch] $Test
       ,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ParameterSetName = 'Repack' )]
        [switch] $Repack
       ,
        [Parameter(Mandatory = $false)]
        [switch] $Pause
       ,
        [Parameter(Mandatory = $false)]
        [string] $Folder = $UseCertsFolderGlobal
    )

    Get-Data-Preset

    [int] $N = 0

    [string] $FilePFX   = ''
    [string] $Pass      = ''
    [string] $NewPass   = ''
    [string] $FileCross = ''

    foreach ( $d in $aDataRepackPFXFileGlobal )
    {
        if ( $Menu )
        {
            if ( -not $N ) { Write-host }
        }
        else { Write-host }

        $N++

        $FilePFX   = $d.FilePFX
        $Pass      = $d.Pass
        $NewPass   = $d.NewPass
        $FileCross = $d.FileCross

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


        Write-host ' Repack: ' -ForegroundColor DarkGray -NoNewline
        Write-host $FilePFX -ForegroundColor Blue -NoNewline
        Write-host ' ► ' -ForegroundColor Gray -NoNewline

        Write-host '[Pass:' -ForegroundColor DarkGray -NoNewline
        Write-host $ShowPass -ForegroundColor White -NoNewline
        Write-host '][NewPass:' -ForegroundColor DarkGray -NoNewline
        Write-host $ShowNewPass -ForegroundColor DarkCyan -NoNewline
        Write-host ']' -ForegroundColor DarkGray -NoNewline

        if ( $FileCross )
        {
            Write-host ' | MS Cross: ' -ForegroundColor DarkGray -NoNewline
            Write-host $FileCross -ForegroundColor Gray
        }
        else { Write-host }

        if ( -not ( $Repack -or $Test )) { Continue }



        if ( $Pass -and -not $NewPass ) { $RemovePass = $true } else { $RemovePass = $false }

        if ( $Repack )
        {
            if ( $FileCross )
            {
                $Result = Repack-PFX -SavePFX -FilePFX $Folder\$FilePFX -Pass:$Pass -NewPass:$NewPass -RemovePass:$RemovePass -TBS -AddCross -CrossCertFile $Folder\$FileCross
            }
            else
            {
                $Result = Repack-PFX -SavePFX -FilePFX $Folder\$FilePFX -Pass:$Pass -NewPass:$NewPass -RemovePass:$RemovePass -TBS #-AddCross
            }
        }
        elseif ( $Test )
        {
            if ( $FileCross )
            {
                $Result = Repack-PFX -NotSave -FilePFX $Folder\$FilePFX -Pass:$Pass -NewPass:$NewPass -RemovePass:$RemovePass -TBS -AddCross -CrossCertFile $Folder\$FileCross
            }
            else
            {
                $Result = Repack-PFX -NotSave -FilePFX $Folder\$FilePFX -Pass:$Pass -NewPass:$NewPass -RemovePass:$RemovePass -TBS #-AddCross
            }
        }
    }

    if ( $Pause )
    {
        if ( -not $N )
        {
            Write-host
            Write-host ' Repack: ' -ForegroundColor DarkGray -NoNewline
            Write-host 'Preset is not configured (Repack-PFX-File) or PFX not exist' -ForegroundColor DarkGray
        }

        Get-Pause
    }
}




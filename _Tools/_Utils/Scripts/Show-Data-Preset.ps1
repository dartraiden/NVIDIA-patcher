
# вывести результат настроенного пресета 
Function Show-Data-Preset {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory = $false)]
        [string] $Folder = $UseCertsFolderGlobal
       ,
        [Parameter(Mandatory = $false)]
        [string] $CurrentRoot = $CurrentRoot
       ,
        [Parameter(Mandatory = $false)]
        [switch] $NotGetData
    )

    if ( -not $NotGetData )
    {
        Get-Data-Preset -Menu
    }

    [int] $N  = 0
    [int] $N2 = 0

    [System.Collections.Generic.List[string]] $aShowed = @()
    [hashtable] $hDataCertAlgsGlobal = @{}

    [string] $File = ''


    # UnPack or Folder
    if ( $dUnPackOrFolderGlobal.File )
    {
        if ( $dUnPackOrFolderGlobal.packName )
        {
            if ( $dUnPackOrFolderGlobal.UnPack )
            {
                Write-host ' UnPack: ' -ForegroundColor Magenta -NoNewline
                Write-host ($dUnPackOrFolderGlobal.UnPack.Replace("$CurrentRoot\",'')) -ForegroundColor Blue -NoNewline

                Write-host ' | to Folder: ' -ForegroundColor DarkGray -NoNewline

                if ( [System.IO.Directory]::Exists($dUnPackOrFolderGlobal.toFolder) )
                {
                    Write-host '[exist]: ' -ForegroundColor Green -NoNewline
                    Write-host ($dUnPackOrFolderGlobal.toFolder.Replace("$CurrentRoot\",'')) -ForegroundColor Blue -NoNewline
                }
                else
                {
                    Write-host '[not exist]: ' -ForegroundColor DarkGray -NoNewline
                    Write-host ($dUnPackOrFolderGlobal.toFolder.Replace("$CurrentRoot\",'')) -ForegroundColor DarkCyan -NoNewline
                }

                Write-host ' | only: ' -ForegroundColor DarkGray -NoNewline
                Write-host $dUnPackOrFolderGlobal.onlyInclude.Count -ForegroundColor White -NoNewline

                Write-host ' | excl: ' -ForegroundColor DarkGray -NoNewline
                Write-host $dUnPackOrFolderGlobal.excludes.Count -ForegroundColor Magenta
            }
            else
            {
                Write-host ' UnPack: ' -ForegroundColor Magenta -NoNewline
                Write-host '[folder exist]: ' -ForegroundColor Green -NoNewline
                Write-host ($dUnPackOrFolderGlobal.toFolder.Replace("$CurrentRoot\",'')) -ForegroundColor Blue -NoNewline
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-host '[Archive not found]: ' -ForegroundColor DarkYellow -NoNewline
                Write-host $dUnPackOrFolderGlobal.File -ForegroundColor DarkCyan
            }
        }
        else
        {
            Write-host ' UnPack: ' -ForegroundColor Magenta -NoNewline
            Write-host '[folder not exist]: ' -ForegroundColor Red -NoNewline
            Write-host $dUnPackOrFolderGlobal.Folder -ForegroundColor DarkCyan -NoNewline
            Write-host ' | ' -ForegroundColor DarkGray -NoNewline
            Write-host '[Archive not found]: ' -ForegroundColor Red -NoNewline
            Write-host $dUnPackOrFolderGlobal.File -ForegroundColor DarkCyan
        }

        $N++
    }


    $N2 = 0

    # cmd/bat  (которые в самом начале)
    foreach ( $File in $aDataCMDfilesGlobal )
    {
        if ( $N -and -not $N2 ) { Write-host }

        Write-host '    cmd: ' -ForegroundColor DarkGray -NoNewline
        Write-host $File -ForegroundColor DarkCyan

        $N++
        $N2++
    }



    $N2 = 0

    # UnSign
    foreach ( $File in $aDataRemoveSignGlobal )
    {
        if ( $N -and -not $N2 ) { Write-host }

        Write-host ' UnSign: ' -ForegroundColor DarkGray -NoNewline
        Write-host $File -ForegroundColor DarkMagenta

        $N++
        $N2++
    }


    $N2 = 0

    # Null
    foreach ( $File in $aDataNullFilesGlobal )
    {
        if ( $N -and -not $N2 ) { Write-host }

        Write-host '   Null: ' -ForegroundColor DarkGray -NoNewline
        Write-host $File -ForegroundColor DarkMagenta

        $N++
        $N2++
    }


    $N2 = 0

    # Copy
    foreach ( $d in $aDataCopyFilesGlobal )
    {
        if ( $N -and -not $N2 ) { Write-host }

        Write-host '   Copy: ' -ForegroundColor DarkGray -NoNewline
        Write-host $d.File -ForegroundColor Gray -NoNewline
        Write-host ' | to: ' -ForegroundColor DarkGray -NoNewline
        Write-host $d.CopyTo -ForegroundColor White

        $N++
        $N2++
    }


    $N2 = 0
    $aShowed = @()

    # Fix
    foreach ( $File in $aDataContentFixGlobal.Keys )
    {
        if ( -not ( $aShowed -eq $File ))  # Отображение уникальных без сортировки
        {
            $aShowed.Add($File)

            if ( $N -and -not $N2 ) { Write-host }

            Write-host '    Fix: ' -ForegroundColor DarkGray -NoNewline
            Write-host $File -ForegroundColor Magenta -NoNewline
            Write-host ' | settings: ' -ForegroundColor DarkGray -NoNewline
            Write-host @($aDataContentFixGlobal.$File).Count -ForegroundColor White

            $N++
            $N2++
        }
    }



    $N2 = 0
    $aShowed = @()

    # Patch
    foreach ( $File in $aDataPatchGlobal.Keys )
    {
        if ( -not ( $aShowed -eq $File ))  # Отображение по одному разу без сортировки
        {
            $aShowed.Add($File)

            if ( $N -and -not $N2 ) { Write-host }

            Write-host '  Patch: ' -ForegroundColor DarkGray -NoNewline
            Write-host $File -ForegroundColor Magenta -NoNewline
            Write-host ' | settings: ' -ForegroundColor DarkGray -NoNewline
            Write-host @($aDataPatchGlobal.$File).Count -ForegroundColor White

            $N++
            $N2++
        }
    }


    # вычислить максимальную длину имен файлов сертификатов для выравнивания отступом при выводе в меню для PFX: и Sign:
    [int] $iIndentSize = 0

    foreach ( $f in $aDataToSignFilesGlobal.FileCert )
    {
        $iIndentSize = [math]::Max($f.Length, $iIndentSize)
    }



    $N2 = 0
    $aShowed = @()

    # PFX (инфа)
    foreach ( $d in $aDataToSignFilesGlobal.Where({ $_.FileCert -like '*.pfx' }))
    {
        if ( -not ( $aShowed -eq $d.FileCert ))  # Отображение по одному разу без сортировки
        {
            $aShowed.Add($d.FileCert)

            if ( $N -and -not $N2 ) { Write-host }

            Info-PFX -FilePFX "$Folder\$($d.FileCert)" -Pass $d.Pass -iIndentSize $iIndentSize

            $N++
            $N2++
        }
    }

    # CER (инфа) .crt/.cer | после всех pfx
    foreach ( $d in $aDataToSignFilesGlobal.Where({ $_.FileCert -match '\.(cer|crt)$' }))
    {
        if ( -not ( $aShowed -eq $d.FileCert ))  # Отображение по одному разу без сортировки
        {
            $aShowed.Add($d.FileCert)

            if ( $N -and -not $N2 ) { Write-host }

            Info-CER -FileCER "$Folder\$($d.FileCert)" -iIndentSize $iIndentSize

            $N++
            $N2++
        }
    }



    $N2 = 0

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





    [string] $ShowAlg = ''

    # Sign
    foreach ( $Stage in $aStages )
    {
        foreach ( $d in $Stage.aData )
        {
            if ( $N -and -not $N2 ) { Write-host }

            Write-host '   Sign: ' -ForegroundColor DarkGray -NoNewline
            Write-host $("{0,-$iIndentSize}" -f $d.FileCert) -ForegroundColor DarkCyan -NoNewline
            Write-host ' ► ' -ForegroundColor White -NoNewline
            Write-host $d.TimeStamp -ForegroundColor DarkGreen -NoNewline

            Write-host ' |' -ForegroundColor DarkGray -NoNewline

            if ( $d.addSign )
            {
                Write-host '+ ' -ForegroundColor Blue -NoNewline
            }
            else
            {
                Write-host '  ' -NoNewline
            }

            if ( $d.AlgForce )
            {
                $ShowAlg = '{0,-6}' -f $d.AlgForce

                if ( $d.AlgForce -eq $hDataCertAlgsGlobal[$d.FileCert].SigAlg )
                {
                    Write-host $ShowAlg -ForegroundColor DarkGray -NoNewline
                }
                else
                {
                    Write-host $ShowAlg -ForegroundColor DarkMagenta -NoNewline
                }
            }
            elseif ( $hDataCertAlgsGlobal[$d.FileCert].SigAlg )
            {
                $ShowAlg = '{0,-6}' -f $hDataCertAlgsGlobal[$d.FileCert].SigAlg
                
                Write-host $ShowAlg -ForegroundColor DarkGray -NoNewline
            }
            else
            {
                Write-host '------' -ForegroundColor Red -NoNewline
            }



            Write-host ' | ' -ForegroundColor DarkGray -NoNewline
            Write-host $d.SignFile -ForegroundColor Gray -NoNewline



            if ( $d.SignFile -notlike '*.ca[t?]' ) # .ca? универсальное указание в пресете для запакованных файлов .ca_ или .cat
            {
                Write-host ' | ind: ' -ForegroundColor DarkGray -NoNewline

                if ( $d.AddIndex -ge 2  )
                {
                    Write-host $d.AddIndex -ForegroundColor Blue -NoNewline
                }
                elseif ( $d.AddIndex -eq 1 )
                {
                    Write-host $d.AddIndex -ForegroundColor Blue -NoNewline
                }
                else
                {
                    Write-host '0' -ForegroundColor DarkGray -NoNewline
                }
            }
            
            if ( $d.ST -eq 'T' )
            {
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-host 'T = only TimeStamp' -ForegroundColor DarkMagenta -NoNewline
            }
            elseif ( $d.ST -eq 'S' )
            {
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-host 'S = only Sign' -ForegroundColor DarkMagenta -NoNewline
            }

            if ( $d.OS )
            {
                Write-host " | $($d.OS)" -ForegroundColor DarkGray
            }
            else { Write-host }
            
            $N++
            $N2++
        }
    }



    $N2 = 0

    # End cmd (которые для final)
    foreach ( $File in $aDataCMDfilesFinalGlobal )
    {
        if ( $N -and -not $N2 ) { Write-host }

        Write-host 'End cmd: ' -ForegroundColor DarkGray -NoNewline
        Write-host $File -ForegroundColor DarkCyan

        $N++
        $N2++
    }


    # Показать PFX настроенные для перепаковки (PFX v1 или v3)
    Manage-PFX -Menu

    $N += $aDataRepackPFXFileGlobal.Count


    if ( -not $N )
    {
        Write-host '   ----: ' -ForegroundColor DarkGray -NoNewline
        Write-host 'preset is not configured (for actions) or the specified files do not exist' -ForegroundColor DarkYellow
    }
}

Function Show-UnPack-Or-Folder {

    [string] $text = ''

    # UnPack or Folder
    if ( $dUnPackOrFolderGlobal.File )
    {
        if ( $dUnPackOrFolderGlobal.packName )
        {
            if ( $dUnPackOrFolderGlobal.UnPack )
            {
                $text = '#blue#{0}#' -f ($dUnPackOrFolderGlobal.UnPack.Replace("$CurrentRoot\",''))
            }
            else
            {
                $text = '#DarkYellow#[Archive not found]: #DarkCyan#{0}#' -f $dUnPackOrFolderGlobal.File  # and [exist folder]
            }
        }
        else
        {
            $text = '#Red#[Archive not found]: #DarkCyan#{0}#' -f $dUnPackOrFolderGlobal.File  # and [No folder]
        }
    }
    else
    {
        $text = '#DarkGray#[preset is not configured]: UnPack-or-Folder#'
    }

    Return $text
}


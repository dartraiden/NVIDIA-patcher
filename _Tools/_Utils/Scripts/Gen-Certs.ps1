

#
Function Gen-Certs {

    [CmdletBinding( SupportsShouldProcess = $false )]
    [OutputType([bool])]
    Param(
        [Parameter(Mandatory = $false)]
        [string] $BaseName = 'westlife'
       ,
        [Parameter(Mandatory = $false)]
        [string] $CntrName  # 2 буквы (для "C"/"countryName") Alpha-2 code ISO_3166-1
       ,
        [Parameter(Mandatory = $false)]
        [string] $RootName  # Root
       ,
        [Parameter(Mandatory = $false)]
        [string] $IntTsaName  # Int Name (for TSA1 + TSA2)
       ,
        [Parameter(Mandatory = $false)]
        [string] $TSA1Name  # TSA1
       ,
        [Parameter(Mandatory = $false)]
        [string] $TSA2Name  # TSA2
       ,
        [Parameter(Mandatory = $false)]
        [string] $IntSignName  # Int Name (Sign)
       ,
        [Parameter(Mandatory = $false)]
        [string] $SignName  # Sign
       ,
        [Parameter(Mandatory = $false)]
        [string] $IntSpecName  # Int for Special PFX (Root the same, общий)
       ,
        [Parameter(Mandatory = $false)]
        [string] $SpecName  # Sign for Special PFX (Root the same, общий)
       ,
        [Parameter(Mandatory = $false)]
        [string] $Pass
       ,
        [Parameter(Mandatory = $false)]
        [string] $SigAlg = 'SHA256'
       ,
        [Parameter(Mandatory = $false)]
        [string] $notBefore # 2000-01-02T00:00:00 | yyyy-MM-ddTHH:mm:ss
       ,
        [Parameter(Mandatory = $false)]
        [string] $notAfter  # 2040-01-02T00:00:00 | yyyy-MM-ddTHH:mm:ss
       ,
        [Parameter(Mandatory = $false)]
        [string] $Openssl = $Openssl # need v3.1.1
       ,
        [Parameter(Mandatory = $false)]
        [string] $TempDir = $ScratchDirGlobal
       ,
        [Parameter(Mandatory = $false)]
        [string] $SaveToFolder = $UseCertsFolderGlobal
       ,
        [Parameter(Mandatory = $false)]
        [switch] $ReGenerate
    )

    # Получение имени этой функции.
    [string] $NameThisFunction = $MyInvocation.MyCommand.Name

    Write-Host
    Write-Host " [$NameThisFunction] Creating certificates" -ForegroundColor Cyan -NoNewline
    Write-Host ' (Gen)' -ForegroundColor DarkCyan

    if ( $Error.Count ) { $Error.Clear() }

    [string] $BaseNameLower = $BaseName.ToLower()
    [array] $aComm = @()

    $SigAlg = $SigAlg.ToUpper()

    if ( -not $CntrName ) { $CntrName = 'MX' }  #  countryName: MX = (ISO_3166-1: Мексика)

    # Root Name
    if ( $RootName )
    {
        $RootName = $RootName -replace ('%sha%',$SigAlg)
    }
    else
    {
        $RootName = '{0} EV Root CA' -f $BaseName
    }

    # Int Name (for TSA1 + TSA2)
    if ( $IntTsaName )
    {
        [string] $IntTsaName1 = $IntTsaName -replace ('%sha%', 'SHA1')
        [string] $IntTsaName2 = $IntTsaName -replace ('%sha%', 'SHA256')
    }
    else
    {
        [string] $IntTsaName1 = '{0} {1} TimeStamping CA' -f $BaseName, 'SHA1'
        [string] $IntTsaName2 = '{0} {1} TimeStamping CA' -f $BaseName, 'SHA256'
    }

    # TSA1
    if ( $TSA1Name )
    {
        $TSA1Name = $TSA1Name -replace ('%sha%', 'SHA1')
    }
    else
    {
        $TSA1Name = '{0} {1} TimeStamp' -f $BaseName, 'SHA1'
    }

    # TSA2
    if ( $TSA2Name )
    {
        $TSA2Name = $TSA2Name -replace ('%sha%','SHA256')
    }
    else
    {
        $TSA2Name = '{0} {1} TimeStamp' -f $BaseName, 'SHA256'
    }

    # Int Name (Sign)
    if ( $IntSignName )
    {
        $IntSignName = $IntSignName -replace ('%sha%',$SigAlg)
    }
    else
    {
        $IntSignName = '{0} {1} Code Signing CA' -f $BaseName, $SigAlg
    }

    # Sign
    if ( $SignName )
    {
        $SignName = $SignName -replace ('%sha%',$SigAlg)
    }
    else
    {
        $SignName = '{0} Company' -f $BaseName
    }

    # Spec Name (Sign for Special PFX, Root the same, общий)
    if ( $SpecName )
    {
        $SpecName = $SpecName -replace ('%sha%',$SigAlg)

        # Int Spec (for Special PFX, Root the same, общий)
        if ( $IntSpecName )
        {
            $IntSpecName = $IntSpecName -replace ('%sha%',$SigAlg)
        }
        else
        {
            $IntSpecName = '{0} {1} Spec Signing CA' -f $BaseName, $SigAlg
        }

        [bool] $needSpecPFX = $true
    }
    else
    {
        [bool] $needSpecPFX = $false
    }



    # subj
    #                              /ST=aaa bbb/L=nnn mmm  < Любой из и по желанию для любого 
   #[string] $subjRoot    = '/C={0}/ST=aaa bbb/L=nnn mmm/O={1} PKI Service/OU=svcs.pki.{2}.dn/CN={3}' -f $CntrName, $BaseName, $BaseNameLower, $RootName
    [string] $subjRoot    = '/C={0}/O={1} PKI Service/OU=svcs.pki.{2}.dn/CN={3}' -f $CntrName, $BaseName, $BaseNameLower, $RootName

    [string] $subjIntTSA1 = '/C={0}/O={1} PKI Service/OU=svcs.pki.{2}.dn/CN={3}' -f $CntrName, $BaseName, $BaseNameLower, $IntTsaName1
    [string] $subjIntTSA2 = '/C={0}/O={1} PKI Service/OU=svcs.pki.{2}.dn/CN={3}' -f $CntrName, $BaseName, $BaseNameLower, $IntTsaName2
    [string] $subjTSA1    = '/C={0}/O={1} PKI Service/OU=time-stamp.pki.{2}.dn/CN={3}' -f $CntrName, $BaseName, $BaseNameLower, $TSA1Name
    [string] $subjTSA2    = '/C={0}/O={1} PKI Service/OU=time-stamp.pki.{2}.dn/CN={3}' -f $CntrName, $BaseName, $BaseNameLower, $TSA2Name

    [string] $subjIntSign = '/C={0}/O={1} PKI Service/OU=svcs.pki.{2}.dn/CN={3}' -f $CntrName, $BaseName, $BaseNameLower, $IntSignName
    [string] $subjSign    = '/C={0}/O={1} PKI Service/OU=sign.pki.{2}.dn/CN={3}' -f $CntrName, $BaseName, $BaseNameLower, $SignName

    if ( $needSpecPFX )
    {
        [string] $subjIntSpec = '/C={0}/O={1} PKI Service/OU=svcs.pki.{2}.dn/CN={3}' -f $CntrName, $BaseName, $BaseNameLower, $IntSpecName
        [string] $subjSpec    = '/C={0}/O={1} PKI Service/OU=sign.pki.{2}.dn/CN={3}' -f $CntrName, $BaseName, $BaseNameLower, $SpecName
    }


    # Check names
    [PSCustomObject] $pCheckState = [PSCustomObject]@{
        IntSName = $true
        SignName = $true
        
        IntTsaName1 = $true
        IntTsaName2 = $true

        TSA1Name = $true

        TSA2Name = $true

        IntPName = $true
        SpecName = $true
    }

    [string[]] $aCheckNames = $RootName

    try
    {
        if ( $aCheckNames -eq $IntSignName )
        {
            $pCheckState.IntSName = $false
            throw
        }
        else { $aCheckNames += $IntSignName }

        if ( $aCheckNames -eq $SignName )
        {
            $pCheckState.SignName = $false
            throw
        }
        else { $aCheckNames += $SignName }

        if ( $aCheckNames -eq $IntTsaName1 )
        {
            $pCheckState.IntTsaName1 = $false
            throw
        }
        else { $aCheckNames += $IntTsaName1 }

        if (( $aCheckNames -eq $IntTsaName2 ) -and -not ( $IntTsaName1 -eq $IntTsaName2 )) # Эти 2 могут совпадать
        {
            $pCheckState.IntTsaName2 = $false
            throw
        }
        else { $aCheckNames += $IntTsaName2 }

        if ( $aCheckNames -eq $TSA1Name )
        {
            $pCheckState.TSA1Name = $false
            throw
        }
        else { $aCheckNames += $TSA1Name }

        if ( $aCheckNames -eq $TSA2Name )
        {
            $pCheckState.TSA2Name = $false
            throw
        }
        else { $aCheckNames += $TSA2Name }


        if ( $needSpecPFX )
        {
            if (( $aCheckNames -eq $IntSpecName ) -and -not ( $IntSpecName -eq $IntSignName )) # Эти 2 Int (Sign и Spec) могут совпадать
            {
                $pCheckState.IntPName = $false
                throw
            }
            else { $aCheckNames += $IntSpecName }

            if ( $aCheckNames -eq $SpecName )
            {
                $pCheckState.SpecName = $false
                throw
            }
            else { $aCheckNames += $SpecName }
        }
    }
    catch
    {
        Write-Host
        Write-Host " [$NameThisFunction]        Cntr-Name: " -ForegroundColor DarkGray -NoNewline
        Write-Host $CntrName -ForegroundColor DarkCyan -NoNewline
        Write-Host ' | Country' -ForegroundColor DarkGray

        Write-Host
        Write-Host " [$NameThisFunction]        Base-Name: " -ForegroundColor DarkGray -NoNewline
        Write-Host $BaseName -ForegroundColor DarkCyan -NoNewline
        Write-Host " | $SigAlg" -ForegroundColor DarkGray

        Write-Host
        Write-Host " [$NameThisFunction]        Root-Name: " -ForegroundColor DarkGray -NoNewline
        Write-Host $RootName -ForegroundColor White -NoNewline
        Write-Host " | $SigAlg" -ForegroundColor DarkGray

        Write-Host
        Write-Host " [$NameThisFunction] (TSA1) IntT-Name: " -ForegroundColor DarkGray -NoNewline
        if ( $pCheckState.IntTsaName1 ) { Write-Host $IntTsaName1 -ForegroundColor White -NoNewline } else { Write-Host $IntTsaName1 -ForegroundColor Yellow -NoNewline ; Write-Host '  ◄ Name already exists!' -ForegroundColor Red -NoNewline }
        Write-Host " | SHA1" -ForegroundColor DarkGray

        Write-Host " [$NameThisFunction]        TSA1-Name: " -ForegroundColor DarkGray -NoNewline
        if ( $pCheckState.TSA1Name ) { Write-Host $TSA1Name -ForegroundColor White -NoNewline } else { Write-Host $TSA1Name -ForegroundColor Yellow -NoNewline ; Write-Host '  ◄ Name already exists!' -ForegroundColor Red -NoNewline }
        Write-Host " | SHA1" -ForegroundColor DarkGray

        Write-Host " [$NameThisFunction] (TSA2) IntT-Name: " -ForegroundColor DarkGray -NoNewline
        if ( $pCheckState.IntTsaName2 ) { Write-Host $IntTsaName2 -ForegroundColor White -NoNewline } else { Write-Host $IntTsaName2 -ForegroundColor Yellow -NoNewline ; Write-Host '  ◄ Name already exists!' -ForegroundColor Red -NoNewline }
        Write-Host " | SHA256" -ForegroundColor DarkGray

        Write-Host " [$NameThisFunction]        TSA2-Name: " -ForegroundColor DarkGray -NoNewline
        if ( $pCheckState.TSA2Name ) { Write-Host $TSA2Name -ForegroundColor White -NoNewline } else { Write-Host $TSA2Name -ForegroundColor Yellow -NoNewline ; Write-Host '  ◄ Name already exists!' -ForegroundColor Red -NoNewline }
        Write-Host " | SHA256" -ForegroundColor DarkGray

        Write-Host
        Write-Host " [$NameThisFunction] (Sign) IntS-Name: " -ForegroundColor DarkGray -NoNewline
        if ( $pCheckState.IntSName ) { Write-Host $IntSignName -ForegroundColor White -NoNewline } else { Write-Host $IntSignName -ForegroundColor Yellow -NoNewline ; Write-Host '  ◄ Name already exists!' -ForegroundColor Red -NoNewline }
        Write-Host " | $SigAlg" -ForegroundColor DarkGray

        Write-Host " [$NameThisFunction]        Sign-Name: " -ForegroundColor DarkGray -NoNewline
        if ( $pCheckState.SignName ) { Write-Host $SignName -ForegroundColor White -NoNewline } else { Write-Host $SignName -ForegroundColor Yellow -NoNewline ; Write-Host '  ◄ Name already exists!' -ForegroundColor Red -NoNewline }
        Write-Host " | $SigAlg" -ForegroundColor DarkGray

        if ( $needSpecPFX )
        {
            Write-Host
            Write-Host " [$NameThisFunction] (Spec) IntP-Name: " -ForegroundColor DarkGray -NoNewline
            if ( $pCheckState.IntPName ) { Write-Host $IntSpecName -ForegroundColor White -NoNewline } else { Write-Host $IntSpecName -ForegroundColor Yellow -NoNewline ; Write-Host '  ◄ Name already exists!' -ForegroundColor Red -NoNewline }
            Write-Host " | $SigAlg" -ForegroundColor DarkGray

            Write-Host " [$NameThisFunction]        Spec-Name: " -ForegroundColor DarkGray -NoNewline
            if ( $pCheckState.SpecName ) { Write-Host $SpecName -ForegroundColor White -NoNewline } else { Write-Host $SpecName -ForegroundColor Yellow -NoNewline ; Write-Host '  ◄ Name already exists!' -ForegroundColor Red -NoNewline }
            Write-Host " | $SigAlg" -ForegroundColor DarkGray
        }

        Return $false
    }

    $aCheckNames = @()

    Write-Host
    Write-Host " [$NameThisFunction]        Cntr-Name: " -ForegroundColor DarkGray -NoNewline
    Write-Host $CntrName -ForegroundColor DarkCyan -NoNewline
    Write-Host ' | Country' -ForegroundColor DarkGray
    
    Write-Host
    Write-Host " [$NameThisFunction]        Base-Name: " -ForegroundColor DarkGray -NoNewline
    Write-Host $BaseName -ForegroundColor DarkCyan -NoNewline
    Write-Host " | $SigAlg" -ForegroundColor DarkGray

    Write-Host
    Write-Host " [$NameThisFunction]        Root-Name: " -ForegroundColor DarkGray -NoNewline
    Write-Host $RootName -ForegroundColor White -NoNewline
    Write-Host " | $SigAlg" -ForegroundColor DarkGray
   
    Write-Host
    Write-Host " [$NameThisFunction] (TSA1) IntT-Name: " -ForegroundColor DarkGray -NoNewline
    Write-Host $IntTsaName1 -ForegroundColor White -NoNewline
    Write-Host " | SHA1" -ForegroundColor DarkGray
    Write-Host " [$NameThisFunction]        TSA1-Name: " -ForegroundColor DarkGray -NoNewline
    Write-Host $TSA1Name -ForegroundColor White -NoNewline
    Write-Host " | SHA1" -ForegroundColor DarkGray
    Write-Host " [$NameThisFunction] (TSA2) IntT-Name: " -ForegroundColor DarkGray -NoNewline
    Write-Host $IntTsaName2 -ForegroundColor White -NoNewline
    Write-Host " | SHA256" -ForegroundColor DarkGray
    Write-Host " [$NameThisFunction]        TSA2-Name: " -ForegroundColor DarkGray -NoNewline
    Write-Host $TSA2Name -ForegroundColor White -NoNewline
    Write-Host " | SHA256" -ForegroundColor DarkGray

    Write-Host
    Write-Host " [$NameThisFunction] (Sign) IntS-Name: " -ForegroundColor DarkGray -NoNewline
    Write-Host $IntSignName -ForegroundColor White -NoNewline
    Write-Host " | $SigAlg" -ForegroundColor DarkGray
    Write-Host " [$NameThisFunction]        Sign-Name: " -ForegroundColor DarkGray -NoNewline
    Write-Host $SignName -ForegroundColor White -NoNewline
    Write-Host " | $SigAlg" -ForegroundColor DarkGray
        
    if ( $needSpecPFX )
    {
        Write-Host
        Write-Host " [$NameThisFunction] (Spec) IntP-Name: " -ForegroundColor DarkGray -NoNewline
        Write-Host $IntSpecName -ForegroundColor White -NoNewline
        Write-Host " | $SigAlg" -ForegroundColor DarkGray

        Write-Host " [$NameThisFunction]        Spec-Name: " -ForegroundColor DarkGray -NoNewline
        Write-Host $SpecName -ForegroundColor White -NoNewline
        Write-Host " | $SigAlg" -ForegroundColor DarkGray
    }



    # Выбор: продолжать, или пропустить
    Write-Host
    Write-Host '   [1] ' -ForegroundColor Cyan -NoNewline
    Write-Host '=' -ForegroundColor DarkGray -NoNewline
    Write-Host ' Names are OK, continue' -ForegroundColor Green

    Write-Host '   [ ] ' -ForegroundColor Magenta -NoNewline
    Write-Host '=' -ForegroundColor DarkGray -NoNewline
    Write-Host ' skip' -ForegroundColor Magenta
    Write-Host

    [Console]::WriteLine();
    [Console]::WriteLine();
    [console]::SetCursorPosition(0, [console]::CursorTop - 2)

    [string] $Yourchoice = (Read-Host "  Your choice").Trim()
    if ( -not ( $Yourchoice -eq '1' )) { $aWarningsGlobal = 'certificate generation was skipped' ; return $false } 
    Write-Host


    # далее генерация, создание сертификатов

    [string] $cnf = "$TempDir\ca.cnf"

    [string] $outTempRootkey    = "$TempDir\Gen-Root.key"      ; [string[]] $RootCsr = @()

    [string] $outTempIntTsakey  = "$TempDir\Gen-IntTsa.key"    ; [string[]] $IntCsr  = @()
    [string] $outTempIntSignkey = "$TempDir\Gen-IntSign.key"   ;          # $IntCsr
    [string] $outTempIntSpeckey = "$TempDir\Gen-IntSpec.key"   ;          # $IntCsr

    [string] $outTSAkey    = "$SaveToFolder\Gen-TSA.key"       ; [string[]] $TsaCsr  = @()
    [string] $outSignkey   = "$SaveToFolder\Gen-Sign.key"      ; [string[]] $SignCsr = @()  # Gen-Sign.key так же и для Gen-Spec.crt/Gen-Spec.pfx

    [string] $outTempRootCrt    = "$TempDir\Gen-TempRoot.crt"
    [string] $outTempIntTsa1Crt = "$TempDir\Gen-TempIntTsa1.crt" ; [string] $IntTsa1Crt = ''
    [string] $outTempIntTsa2Crt = "$TempDir\Gen-TempIntTsa2.crt" ; [string] $IntTsa2Crt = ''
    [string] $outTempIntSignCrt = "$TempDir\Gen-TempIntSign.crt" ; [string] $IntSignCrt = ''
    [string] $outTempIntSpecCrt = "$TempDir\Gen-TempIntSpec.crt" ; [string] $IntSpecCrt = ''
    
    [string] $outTempTsa1Crt    = "$TempDir\Gen-TempTsa1.crt"
    [string] $outTempTsa2Crt    = "$TempDir\Gen-TempTsa2.crt"
    [string] $outTempSignCrt    = "$TempDir\Gen-TempSign.crt"
    [string] $outTempSpecCrt    = "$TempDir\Gen-TempSpec.crt"

    [string] $outRootCrt   = "$SaveToFolder\Gen-Root.crt"        ; [string] $RootCrt = ''
    [string] $outTsa1Crt   = "$SaveToFolder\Gen-TSA1.crt"        ; [string] $Tsa1Crt = ''
    [string] $outTsa2Crt   = "$SaveToFolder\Gen-TSA2.crt"        ; [string] $Tsa2Crt = ''
    [string] $outSignCrt   = "$SaveToFolder\Gen-Sign.crt"        ; [string] $SignCrt = ''
    [string] $outSignPFX   = "$SaveToFolder\Gen-Sign.pfx"

    [string] $outSpecCrt   = "$SaveToFolder\Gen-Spec.crt"        ; [string] $SpecCrt = ''
    [string] $outSpecPFX   = "$SaveToFolder\Gen-Spec.pfx"

    [string] $File = ''


    # для Проверки всех файлов в конце после создания или после ошибки при создании
    if ( $needSpecPFX )
    {
        [string[]] $aAllFiles = $outRootCrt, $outTsa1Crt, $outTsa2Crt, $outTSAkey, $outSignCrt, $outSignkey, $outSignPFX, $outSpecCrt, $outSpecPFX
    }
    else
    {
        [string[]] $aAllFiles = $outRootCrt, $outTsa1Crt, $outTsa2Crt, $outTSAkey, $outSignCrt, $outSignkey, $outSignPFX
    }
    
    [bool] $isExistCreatedCerts = $true

    # backup если существуют хотябы 4 главных, иначе половина уже про...на, можно не бэкапать
    if (     [System.IO.File]::Exists($outRootCrt) `
        -and [System.IO.File]::Exists($outSignCrt) `
        -and [System.IO.File]::Exists($outSignkey) `
        -and [System.IO.File]::Exists($outSignPFX) )
    {
        if ( -not $ReGenerate )
        {
            Write-Host " [$NameThisFunction] " -ForegroundColor DarkGray -NoNewline
            Write-Host 'Certificates exist:' -ForegroundColor DarkGreen
            Write-Host
            Write-Host " [$NameThisFunction] " -ForegroundColor DarkGray -NoNewline
            Write-Host $([System.IO.Path]::GetFileName($outRootCrt)) -ForegroundColor Green

            if ( [System.IO.File]::Exists($outTsa1Crt) )
            {
                Write-Host " [$NameThisFunction] " -ForegroundColor DarkGray -NoNewline
                Write-Host $([System.IO.Path]::GetFileName($outTsa1Crt)) -ForegroundColor Green
            }
            
            if ( [System.IO.File]::Exists($outTsa2Crt) )
            {
                Write-Host " [$NameThisFunction] " -ForegroundColor DarkGray -NoNewline
                Write-Host $([System.IO.Path]::GetFileName($outTsa2Crt)) -ForegroundColor Green
            }

            if ( [System.IO.File]::Exists($outTSAkey) )
            {
                Write-Host " [$NameThisFunction] " -ForegroundColor DarkGray -NoNewline
                Write-Host $([System.IO.Path]::GetFileName($outTSAkey)) -ForegroundColor Green
            }

            Write-Host " [$NameThisFunction] " -ForegroundColor DarkGray -NoNewline
            Write-Host $([System.IO.Path]::GetFileName($outSignCrt)) -ForegroundColor Green
            Write-Host " [$NameThisFunction] " -ForegroundColor DarkGray -NoNewline
            Write-Host $([System.IO.Path]::GetFileName($outSignkey)) -ForegroundColor Green
            Write-Host " [$NameThisFunction] " -ForegroundColor DarkGray -NoNewline
            Write-Host $([System.IO.Path]::GetFileName($outSignPFX)) -ForegroundColor Green

            if ( [System.IO.File]::Exists($outSpecCrt) )
            {
                Write-Host " [$NameThisFunction] " -ForegroundColor DarkGray -NoNewline
                Write-Host $([System.IO.Path]::GetFileName($outSpecCrt)) -ForegroundColor Green
            }

            if ( [System.IO.File]::Exists($outSpecPFX) )
            {
                Write-Host " [$NameThisFunction] " -ForegroundColor DarkGray -NoNewline
                Write-Host $([System.IO.Path]::GetFileName($outSpecPFX)) -ForegroundColor Green
            }

            Return $false
        }
        elseif ( [System.IO.File]::Exists($7z) )
        {
            [string] $BAT = "$SaveToFolder\Gen-Menu-Store.bat"
            [string] $LNK = "$SaveToFolder\Gen-Menu-ToAdmin.lnk"
            [array] $AddFiles = @()

            foreach ( $File in @($outRootCrt,$outSignCrt,$outSignkey,$outSignPFX,$outTsa1Crt,$outTsa2Crt,$outTSAkey,$outSpecCrt,$outSpecPFX,$BAT,$LNK) )
            {
                if ( [System.IO.File]::Exists($File) )
                {
                    $AddFiles += '"{0}"' -f $File
                }
            }

            [string] $NameZIP   = 'Gen-Certs-Backup'
            [array] $aFilesZIP  = @()
            try {   $aFilesZIP  = [System.IO.Directory]::EnumerateFiles($SaveToFolder,"$NameZIP*.zip") -Replace('.+\\','') } catch {}
            [string] $BackUpZIP = ''

            [int] $N = 0 ; do { $N++ ; $BackUpZIP = '{0}{1:000}.zip' -f $NameZIP, $N } until ( -not ( $aFilesZIP -like $BackUpZIP )) # Поиск отсутствующего имени файла для создания архива

            Write-Host " [$NameThisFunction] Gen Cert: Create backup all Certs: " -ForegroundColor Magenta -NoNewline
            Write-Host $BackUpZIP -ForegroundColor White

            & $7z a -tzip -mx5 -r0 -ssw -y -aoa -bso0 -bse0 -bsp0 "$SaveToFolder\$BackUpZIP" $AddFiles

            if (( $Global:LastExitCode ) -or ( -not [System.IO.File]::Exists("$SaveToFolder\$BackUpZIP") ))
            {
                Write-Host " [$NameThisFunction] error: Create backup '$SaveToFolder\$BackUpZIP'" -ForegroundColor Red
                Return $false
            }
            else
            {
                Write-Host " [$NameThisFunction] Gen Cert: Create backup: Ok" -ForegroundColor DarkGreen

                foreach ( $File in @($outRootCrt,$outSignCrt,$outSignkey,$outSignPFX,$outTsa1Crt,$outTsa2Crt,$outTSAkey,$outSpecCrt,$outSpecPFX) )
                {
                    if ( [System.IO.File]::Exists($File) )
                    {
                        Remove-Item -LiteralPath $File -ErrorAction Continue
                    }
                }
            }

            Write-Host
        }
        else
        {
            Write-Host " [$NameThisFunction] error: No 7z.exe for Create backup: " -ForegroundColor Red -NoNewline
            Write-Host $7z -ForegroundColor Yellow
            
            Return $false
        }
    }


    # Подготовка
    try
    {
        [System.IO.Directory]::Exists([System.IO.Directory]::GetParent($TempDir)) > $null # проверка сущестования родительской папки у temp
        [System.IO.File]::WriteAllText("$TempDir\index.txt",'',[System.Text.UTF8Encoding]::new($false))
    }
    catch { Write-Host " [$NameThisFunction] $($_)`n$($_.ScriptStackTrace)`n$($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red ; Return $false }

    try
    {
        if ( -not $notBefore ) { [string] $sBefore = '20070102000000Z' ; $notBefore = ([DateTimeOffset][datetime]::Parse('2007-01-02T00:00:00Z')).DateTime.ToString('yyyy-MM-ddTHH:mm:ss') }
        else                   { [string] $sBefore = ([DateTimeOffset][datetime]::Parse($notBefore)).UtcDateTime.ToString('yyyyMMddHHmmssZ')                                               }

        if ( -not $notAfter  ) { [string] $sAfter  = '20400102000000Z' ; $notAfter  = ([DateTimeOffset][datetime]::Parse('2040-01-02T00:00:00Z')).DateTime.ToString('yyyy-MM-ddTHH:mm:ss') }
        else                   { [string] $sAfter  = ([DateTimeOffset][datetime]::Parse($notAfter)).UtcDateTime.ToString('yyyyMMddHHmmssZ')                                                }
    }
    catch { Write-Host " [$NameThisFunction] $($_)`n$($_.ScriptStackTrace)`n$($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red ; Return $false }


    Write-Host " [$NameThisFunction] Gen BaseName: $BaseName | $SigAlg | $notBefore > $notAfter | Pass > '$Pass'" -ForegroundColor DarkCyan



    <#
        supplied = должно быть указано;  match = должен быть указан и совпадать у цепочки;  optional = по желанию | (только нижний регистр для всех названий типов!)

        "C"  = supplied   # countryName             "US"
        
        "ST" = optional   # stateOrProvinceName     "California"
        "L"  = optional   # localityName            "Santa Clara"

        "O"  = supplied   # organizationName        "NVIDIA Corporation"
        "OU" = supplied   # organizationalUnitName  "Digital ID Class 3 - Microsoft Software Validation v2" (может, быть несколько раз указан)
        'CN' = supplied   # commonName              "NVIDIA Corporation"
    #>

    [string] $C = [string]::Join("`r`n", @(
        'oid_section = OIDs','[ OIDs ]','certificateTemplateName = 1.3.6.1.4.1.311.20.2','caVersion = 1.3.6.1.4.1.311.21.1','[ ca ]','default_ca = CA_default',
        '[ CA_default ]', ('DIR = {0} ' -f $TempDir.Replace('\','\\')),
        ('default_startdate = {0}' -f $sBefore),
        ('default_enddate   = {0}' -f $sAfter),
        'default_days = 365','database = $DIR\\index.txt ','rand_serial = yes','default_md = sha256','copy_extensions = copy',
        'unique_subject = no','new_certs_dir = $DIR', 'email_in_dn = no',
        '[ req ]', 'prompt = no','x509_extensions = ext',
        '[ distinguished_name ]',
        '[ ext ]','subjectKeyIdentifier = hash','authorityKeyIdentifier = keyid:always,issuer','keyUsage = critical,digitalSignature,keyCertSign,cRLSign',
        'basicConstraints = critical,CA:true','caVersion = ASN1:INTEGER:0',

        '[ v3_int_tsa ]',
        'subjectKeyIdentifier = hash','authorityKeyIdentifier = keyid:always,issuer','basicConstraints = critical, CA:true, pathlen:0',
        'keyUsage = critical, digitalSignature, cRLSign, keyCertSign','caVersion = ASN1:INTEGER:0',

        '[ v3_int_cat ]',
        'subjectKeyIdentifier = hash','authorityKeyIdentifier = keyid:always,issuer','basicConstraints = critical, CA:true, pathlen:0',
        'keyUsage = critical, cRLSign, keyCertSign',
        'extendedKeyUsage = clientAuth, codeSigning','caVersion = ASN1:INTEGER:0',
        'crlDistributionPoints=crldp1_section',
        ('authorityInfoAccess = OCSP;URI:http://svcpki.ocsp.{0}.dn/TimeStampingServicesCA' -f $BaseNameLower),

        '[ crldp1_section ]',
        ('fullname=URI:http://svcpki.crls.{0}.dn/TimeStampingServicesCA.crl' -f $BaseNameLower),
        '[ signing_policy ]','C = supplied', 'ST = optional', 'L = optional','O = supplied','OU = supplied','CN = supplied',
        '[ v3_tsa ]',
        'keyUsage = critical, digitalSignature','basicConstraints = critical,CA:FALSE','extendedKeyUsage = critical,timeStamping',
        'certificatePolicies = @polsect,2.16.840.1.594215.3.21','subjectKeyIdentifier = hash', 'authorityKeyIdentifier=keyid:always,issuer',
        'crlDistributionPoints=crldp1_section',
        ('authorityInfoAccess = OCSP;URI:http://svcpki.ocsp.{0}.dn/TimeStampingServicesCA,caIssuers;URI:http://svcpki.cacert.{0}.dn/TimeStampingServicesCA.crt' -f $BaseNameLower),
        '[ polsect ]',
        'policyIdentifier = 2.16.840.1.594215.7.1', ('CPS.1=https://svcpki.cps.{0}.dn/cps' -f $BaseNameLower),
        'userNotice.1=@notice','[notice]',('explicitText=https://svcpki.rpa.{0}.dn/rpa' -f $BaseNameLower),
        '[ v3_Sign ]','basicConstraints = critical,CA:FALSE','extendedKeyUsage = codeSigning, msCodeCom #, msCodeInd','subjectKeyIdentifier = none',
        'authorityKeyIdentifier=none','crlDistributionPoints=crldp1_section',
        ('authorityInfoAccess = caIssuers;URI:http://svcpki.cacert.{0}.dn/TimeStampingServicesCA.crt' -f $BaseNameLower)
    ))



    # Generating
    try
    {
        # key

        # RSA bits (The size of the private key to generate in bits)
        if ( $SigAlg -eq 'SHA1' ) { [int] $bits = 2048 } else { [int] $bits = 4096 }

        # Gen-Root.key
        Write-Host " [$NameThisFunction] Gen-Root.key" -ForegroundColor DarkGray -NoNewline

        if ( $Pass )
        {
            Write-Host "    | $bits | aes256 | Pass > '$Pass'" -ForegroundColor DarkGray

            $aComm = @('-aes256', '-passout', ('pass:{0}' -f $Pass))
        }
        else
        {
            $aComm = @()
            Write-Host "    | $bits | noPass | Pass > ''" -ForegroundColor DarkGray
        }

        $aErr = & $openssl genrsa $aComm -out $outTempRootkey $bits 2>&1
        if ( $aErr.Count ) { Write-Host ([string]::Join("`r`n", $aErr)) -ForegroundColor Red ; Return $false }


        # Gen IntTSA.key
        Write-Host " [$NameThisFunction] Gen IntTSA.key" -ForegroundColor DarkGray -NoNewline

        if ( $Pass )
        {
            Write-Host "  | $bits | aes256 | Pass > '$Pass'" -ForegroundColor DarkGray

            $aComm = @('-aes256', '-passout', ('pass:{0}' -f $Pass))
        }
        else
        {
            Write-Host "  | $bits | noPass | Pass > ''" -ForegroundColor DarkGray
        }

        $aErr = & $openssl genrsa $aComm -out $outTempIntTsakey $bits 2>&1
        if ( $aErr.Count ) { Write-Host ([string]::Join("`r`n", $aErr)) -ForegroundColor Red ; Return $false }


        # Gen IntSign.key
        Write-Host " [$NameThisFunction] Gen IntSign.key" -ForegroundColor DarkGray -NoNewline

        if ( $Pass )
        {
            Write-Host " | $bits | aes256 | Pass > '$Pass'" -ForegroundColor DarkGray

            $aComm = @('-aes256', '-passout', ('pass:{0}' -f $Pass))
        }
        else
        {
            Write-Host " | $bits | noPass | Pass > ''" -ForegroundColor DarkGray
        }

        $aErr = & $openssl genrsa $aComm -out $outTempIntSignkey $bits 2>&1
        if ( $aErr.Count ) { Write-Host ([string]::Join("`r`n", $aErr)) -ForegroundColor Red ; Return $false }


        # Gen-TSA.key (без Pass и всегда 2048 bits, даже для SHA256)
        Write-Host " [$NameThisFunction] Gen-TSA.key     | 2048 | noPass | Pass > ''    (always without password and 2048 bits)" -ForegroundColor DarkGray

        $aErr = & $openssl genrsa -traditional -out $outTSAkey 2048 2>&1
        if ( $aErr.Count ) { Write-Host ([string]::Join("`r`n", $aErr)) -ForegroundColor Red ; Return $false }


        # Gen-Sign.key
        Write-Host " [$NameThisFunction] Gen-Sign.key" -ForegroundColor DarkGray -NoNewline

        if ( $Pass )
        {
            Write-Host "    | $bits | aes256 | Pass > '$Pass'" -ForegroundColor DarkGray

            $aComm = @('-aes256', '-passout', ('pass:{0}' -f $Pass))
        }
        else
        {
            Write-Host "    | $bits | noPass | Pass > ''" -ForegroundColor DarkGray
        }

        $aErr = & $openssl genrsa $aComm -out $outSignkey $bits 2>&1
        if ( $aErr.Count ) { Write-Host ([string]::Join("`r`n", $aErr)) -ForegroundColor Red ; Return $false }



        if ( $needSpecPFX )
        {
            # Gen IntSpec.key
            Write-Host " [$NameThisFunction] Gen IntSpec.key" -ForegroundColor DarkGray -NoNewline

            if ( $Pass )
            {
                Write-Host " | $bits | aes256 | Pass > '$Pass'" -ForegroundColor DarkGray

                $aComm = @('-aes256', '-passout', ('pass:{0}' -f $Pass))
            }
            else
            {
                Write-Host " | $bits | noPass | Pass > ''" -ForegroundColor DarkGray
            }

            $aErr = & $openssl genrsa $aComm -out $outTempIntSpeckey $bits 2>&1
            if ( $aErr.Count ) { Write-Host ([string]::Join("`r`n", $aErr)) -ForegroundColor Red ; Return $false }

            
            # Gen Spec.key  =  Gen-Sign.key | один key и Pass для Gen-Sign и Gen-Spec 
        }



        # cnf
        [System.IO.File]::WriteAllText($cnf,$C,[System.Text.UTF8Encoding]::new($false))



        # crt (далее)

        $SigAlg = $SigAlg.ToLower()

        # temp crt
        Write-Host " [$NameThisFunction] Gen-Temp.crt" -ForegroundColor DarkGray
        if ( $Error.Count ) { $Error.Clear() }
        $aComm = @(('-{0}' -f $SigAlg))
        $C | & $openssl req -new -x509 -config - -key $outTempRootkey -passin pass:$Pass -passout pass:$Pass -out $outTempRootCrt -days 1 -batch -subj $subjRoot $aComm 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }


        # Root crt
        if ( $Error.Count ) { $Error.Clear() }
        Write-Host " [$NameThisFunction] Gen Root Csr" -ForegroundColor DarkGray
        $RootCsr = $C | & $openssl req -new -config - -key $outTempRootkey -passin pass:$Pass -passout pass:$Pass -batch -subj $subjRoot 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }

        Write-Host " [$NameThisFunction] Gen-Root.crt    | $RootName" -ForegroundColor DarkGray
        if ( $Error.Count ) { $Error.Clear() }
        $RootCsr | & $openssl ca -config $cnf -keyfile $outTempRootkey -passin pass:$Pass -cert $outTempRootCrt -policy signing_policy -extensions ext -in - -out $outRootCrt -batch -md $SigAlg -selfsign -notext 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }
        if ( $Error[-1..-20] -like 'Signature ok' ) { Write-Host " [$NameThisFunction] Signature ok" -ForegroundColor DarkGreen } else { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }


        # TSA 1 crt  (sha1)
        Write-Host " [$NameThisFunction] Gen IntTSA1 Csr" -ForegroundColor DarkGray
        if ( $Error.Count ) { $Error.Clear() }
        $aComm = @(('-{0}' -f 'sha1'))
        $IntCsr = $C | & $openssl req -new -config - -key $outTempIntTsakey -passin pass:$Pass -passout pass:$Pass $aComm -extensions v3_int_tsa -subj $subjIntTSA1 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }

        Write-Host " [$NameThisFunction] Gen IntTSA1.crt | $IntTsaName1" -ForegroundColor DarkGray
        if ( $Error.Count ) { $Error.Clear() }
        $IntCsr | & $openssl ca -config $cnf -keyfile $outTempRootkey -passin pass:$Pass -cert $outRootCrt -policy signing_policy -extensions v3_int_tsa -in - -out $outTempIntTsa1Crt -batch -md sha1 -notext 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }
        if ( $Error[-1..-20] -like 'Signature ok' ) { Write-Host " [$NameThisFunction] Signature ok" -ForegroundColor DarkGreen } else { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }


        Write-Host " [$NameThisFunction] Gen TSA1 Csr" -ForegroundColor DarkGray
        if ( $Error.Count ) { $Error.Clear() }
        $aComm = @(('-{0}' -f 'sha1'))
        $TsaCsr = $C | & $openssl req -new -config - -key $outTSAkey -passin pass:$Pass -passout pass:$Pass $aComm -extensions v3_tsa -subj $subjTSA1 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }

        Write-Host " [$NameThisFunction] Gen TSA1.crt    | $TSA1Name" -ForegroundColor DarkGray
        if ( $Error.Count ) { $Error.Clear() }
        $TsaCsr | & $openssl ca -config $cnf -keyfile $outTempIntTsakey -passin pass:$Pass -cert $outTempIntTsa1Crt -policy signing_policy -extensions v3_tsa -in - -out $outTempTsa1Crt -batch -md sha1 -notext 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }
        if ( $Error[-1..-20] -like 'Signature ok' ) { Write-Host " [$NameThisFunction] Signature ok" -ForegroundColor DarkGreen } else { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }


        # TSA 2 crt (sha256)
        Write-Host " [$NameThisFunction] Gen IntTSA2 Csr" -ForegroundColor DarkGray
        if ( $Error.Count ) { $Error.Clear() }
        $aComm = @(('-{0}' -f 'sha256'))
        $IntCsr = $C | & $openssl req -new -config - -key $outTempIntTsakey -passin pass:$Pass -passout pass:$Pass $aComm -extensions v3_int_tsa -subj $subjIntTSA2 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }

        Write-Host " [$NameThisFunction] Gen IntTSA2.crt | $IntTsaName2" -ForegroundColor DarkGray
        if ( $Error.Count ) { $Error.Clear() }
        $IntCsr | & $openssl ca -config $cnf -keyfile $outTempRootkey -passin pass:$Pass -cert $outRootCrt -policy signing_policy -extensions v3_int_tsa -in - -out $outTempIntTsa2Crt -batch -md sha256 -notext 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }
        if ( $Error[-1..-20] -like 'Signature ok' ) { Write-Host " [$NameThisFunction] Signature ok" -ForegroundColor DarkGreen } else { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }


        Write-Host " [$NameThisFunction] Gen TSA2 Csr" -ForegroundColor DarkGray
        if ( $Error.Count ) { $Error.Clear() }
        $aComm = @(('-{0}' -f 'sha256'))
        $TsaCsr = $C | & $openssl req -new -config - -key $outTSAkey -passin pass:$Pass -passout pass:$Pass $aComm -extensions v3_tsa -subj $subjTSA2 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }

        Write-Host " [$NameThisFunction] Gen TSA2.crt    | $TSA2Name" -ForegroundColor DarkGray
        if ( $Error.Count ) { $Error.Clear() }
        $TsaCsr | & $openssl ca -config $cnf -keyfile $outTempIntTsakey -passin pass:$Pass -cert $outTempIntTsa2Crt -policy signing_policy -extensions v3_tsa -in - -out $outTempTsa2Crt -batch -md sha256 -notext 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }
        if ( $Error[-1..-20] -like 'Signature ok' ) { Write-Host " [$NameThisFunction] Signature ok" -ForegroundColor DarkGreen } else { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }


        # Sign crt
        Write-Host " [$NameThisFunction] Gen IntSign Csr" -ForegroundColor DarkGray
        if ( $Error.Count ) { $Error.Clear() }
        $aComm = @(('-{0}' -f $SigAlg))
        $IntCsr = $C | & $openssl req -new -config - -key $outTempIntSignkey -passin pass:$Pass -passout pass:$Pass $aComm -extensions v3_int_cat -subj $subjIntSign 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }

        Write-Host " [$NameThisFunction] Gen IntSign.crt | $IntSignName" -ForegroundColor DarkGray
        if ( $Error.Count ) { $Error.Clear() }
        $IntCsr | & $openssl ca -config $cnf -keyfile $outTempRootkey -passin pass:$Pass -cert $outRootCrt -policy signing_policy -extensions v3_int_cat -in - -out $outTempIntSignCrt -batch -md $SigAlg -notext 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }
        if ( $Error[-1..-20] -like 'Signature ok' ) { Write-Host " [$NameThisFunction] Signature ok" -ForegroundColor DarkGreen } else { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }


        Write-Host " [$NameThisFunction] Gen Sign Csr" -ForegroundColor DarkGray
        if ( $Error.Count ) { $Error.Clear() }
        $aComm = @(('-{0}' -f $SigAlg))
        $SignCsr = $C | & $openssl req -new -config - -key $outSignkey -passin pass:$Pass -passout pass:$Pass $aComm -extensions v3_Sign -subj $subjSign 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }

        Write-Host " [$NameThisFunction] Gen-Sign.crt    | $SignName" -ForegroundColor DarkGray
        if ( $Error.Count ) { $Error.Clear() }
        $SignCsr | & $openssl ca -config $cnf -keyfile $outTempIntSignkey -passin pass:$Pass -cert $outTempIntSignCrt -policy signing_policy -extensions v3_Sign -in - -out $outTempSignCrt -batch -md $SigAlg -notext 2>$null
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }
        if ( $Error[-1..-20] -like 'Signature ok' ) { Write-Host " [$NameThisFunction] Signature ok" -ForegroundColor DarkGreen } else { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }


        if ( $needSpecPFX )
        {
            # Spec crt
            Write-Host " [$NameThisFunction] Gen IntSpec Csr" -ForegroundColor DarkGray
            if ( $Error.Count ) { $Error.Clear() }
            $aComm = @(('-{0}' -f $SigAlg))
            $IntCsr = $C | & $openssl req -new -config - -key $outTempIntSpeckey -passin pass:$Pass -passout pass:$Pass $aComm -extensions v3_int_cat -subj $subjIntSpec 2>$null
            if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }

            Write-Host " [$NameThisFunction] Gen IntSpec.crt | $IntSpecName" -ForegroundColor DarkGray
            if ( $Error.Count ) { $Error.Clear() }
            $IntCsr | & $openssl ca -config $cnf -keyfile $outTempRootkey -passin pass:$Pass -cert $outRootCrt -policy signing_policy -extensions v3_int_cat -in - -out $outTempIntSpecCrt -batch -md $SigAlg -notext 2>$null
            if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }
            if ( $Error[-1..-20] -like 'Signature ok' ) { Write-Host " [$NameThisFunction] Signature ok" -ForegroundColor DarkGreen } else { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }


            Write-Host " [$NameThisFunction] Gen Spec Csr" -ForegroundColor DarkGray
            if ( $Error.Count ) { $Error.Clear() }
            $aComm = @(('-{0}' -f $SigAlg))
            $SignCsr = $C | & $openssl req -new -config - -key $outSignkey -passin pass:$Pass -passout pass:$Pass $aComm -extensions v3_Sign -subj $subjSpec 2>$null
            if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }

            Write-Host " [$NameThisFunction] Gen-Spec.crt    | $SpecName" -ForegroundColor DarkGray
            if ( $Error.Count ) { $Error.Clear() }
            $SignCsr | & $openssl ca -config $cnf -keyfile $outTempIntSpeckey -passin pass:$Pass -cert $outTempIntSpecCrt -policy signing_policy -extensions v3_Sign -in - -out $outTempSpecCrt -batch -md $SigAlg -notext 2>$null
            if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }
            if ( $Error[-1..-20] -like 'Signature ok' ) { Write-Host " [$NameThisFunction] Signature ok" -ForegroundColor DarkGreen } else { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }
        }




        Write-Host
        Write-Host " [$NameThisFunction] Combining certificates" -ForegroundColor DarkGray

        $IntTsa1Crt = Get-Content -Path $outTempIntTsa1Crt -Encoding UTF8 -Delimiter '\r\n' -ErrorAction Stop
        $IntTsa2Crt = Get-Content -Path $outTempIntTsa2Crt -Encoding UTF8 -Delimiter '\r\n' -ErrorAction Stop
        
        $IntSignCrt = Get-Content -Path $outTempIntSignCrt -Encoding UTF8 -Delimiter '\r\n' -ErrorAction Stop

        $Tsa1Crt    = Get-Content -Path $outTempTsa1Crt    -Encoding UTF8 -Delimiter '\r\n' -ErrorAction Stop
        $Tsa2Crt    = Get-Content -Path $outTempTsa2Crt    -Encoding UTF8 -Delimiter '\r\n' -ErrorAction Stop
        
        $SignCrt    = Get-Content -Path $outTempSignCrt    -Encoding UTF8 -Delimiter '\r\n' -ErrorAction Stop
        $RootCrt    = Get-Content -Path $outRootCrt        -Encoding UTF8 -Delimiter '\r\n' -ErrorAction Stop

        [System.IO.File]::WriteAllText($outTsa1Crt,($Tsa1Crt+$IntTsa1Crt),[System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText($outTsa2Crt,($Tsa2Crt+$IntTsa2Crt),[System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText($outSignCrt,($SignCrt+$IntSignCrt),[System.Text.UTF8Encoding]::new($false))

        if ( $Error.Count ) { $Error.Clear() }
        ($SignCrt+$RootCrt+$IntSignCrt) | & $openssl pkcs12 -export -inkey $outSignkey -out $outSignPFX -passin pass:$Pass -passout pass:$Pass
        if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }


        # Spec  (Roor.crt и Sign.key тот же)
        if ( $needSpecPFX )
        {
            $IntSpecCrt = Get-Content -Path $outTempIntSpecCrt -Encoding UTF8 -Delimiter '\r\n' -ErrorAction Stop
            $SpecCrt    = Get-Content -Path $outTempSpecCrt    -Encoding UTF8 -Delimiter '\r\n' -ErrorAction Stop

            [System.IO.File]::WriteAllText($outSpecCrt,($SpecCrt+$IntSpecCrt),[System.Text.UTF8Encoding]::new($false))

            if ( $Error.Count ) { $Error.Clear() }
            ($SpecCrt+$RootCrt+$IntSpecCrt) | & $openssl pkcs12 -export -inkey $outSignkey -out $outSpecPFX -passin pass:$Pass -passout pass:$Pass
            if ( $Global:LastExitCode ) { Write-Host  "$([string]::Join("`r`n", $Error[-1..-20]))" -ForegroundColor Red ; Return $false }
        }
    }
    catch
    {
        Write-Host " [$NameThisFunction] Error: $($_)`n$($_.ScriptStackTrace)`n$($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red

        Return $false
    }
    finally
    {
        $isExistCreatedCerts = $true
        
        # Check result
        foreach ( $File in $aAllFiles )
        {
            if ( -not [System.IO.File]::Exists($File) ) { $isExistCreatedCerts = $false }
        }

        if ( -not $isExistCreatedCerts )
        {
            Write-Host
            Write-Host " [$NameThisFunction] Error | Not all certificates have been created" -ForegroundColor Red

            foreach ( $File in $aAllFiles )
            {
                if ( [System.IO.File]::Exists($File) )
                {
                    Write-Host " [$NameThisFunction] " -ForegroundColor DarkGray -NoNewline
                    Write-Host $([System.IO.Path]::GetFileName($File)) -ForegroundColor Green

                    Remove-Item -LiteralPath $File -Force -ErrorAction Continue
                }
                else
                {
                    Write-Host " [$NameThisFunction] " -ForegroundColor DarkGray -NoNewline
                    Write-Host $([System.IO.Path]::GetFileName($File)) -ForegroundColor Red
                }
            }
        }

        Remove-Item -Path $TempDir\* -Force -ErrorAction SilentlyContinue
    }



    # если все файлы созданы
    if ( $isExistCreatedCerts )
    {
        Write-Host
        Write-Host " [$NameThisFunction] ok | all certificates are created" -ForegroundColor DarkGreen

        foreach ( $File in $aAllFiles )
        {
            Write-Host " [$NameThisFunction] " -ForegroundColor DarkGray -NoNewline
            Write-Host $([System.IO.Path]::GetFileName($File)) -ForegroundColor Green
        }

        # Создание универсального батника удаления/установки сертификатов в хранилище и его спец ярлыка, если их нет в папке сертификатов
        Create-BAT-And-Lnk -Path $SaveToFolder

        Return $true
    }
    else
    {
        Return $false
    }
}

Function Create-BAT-And-Lnk ([string] $Path) {

    # Сжатые байты в Base64 | Мой универсальный батник установки сертификатов (Gen)
    $BatBase64 = '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'

    # Сжатые байты в Base64 | Ярлык для батника с настройками консоли и запуска от админа
    $LnkBase64 = 'H4sIAAAAAAAEAOVTLUxCURT+HiCgoJOJgSbDxyjihM1kY4IBHeO5Wdgc470mvOnDDYpuFAtBC82NqsFEds5ksNskaDAYDJIMz+9dYMPn1C7n7J6f756fe8/uzQKQgg5YdCMk0s+
    RxT7wC81LzLNhM8hAQwVL2BT6kJaCKnQc0PdiGSoWKPeFLCEMmft1GIzRUEaekTptGYUveBIJgWxgHVmy5cdZa48cdIpztGWlblS1cl7Xq3LBEHYyUSiV1bhW0/66zD+hn6dpfJtmiZbKKWqoYVzm
    My50z8UP3PaghzvEIjVEsUUekhezWKU+5cdJ8Y1U+DZ0/qUiNbBNTgu0il0yELq1sk4qH8fAxeu1y/LOMldHlh8a1JRGVoLLNXqgtUtAjQHNJhpUjUQDrSbQ6XSgqirQMoE3bpgmTKpurAuzZ7km3
    pk+ybu8UK8oOcXj3vG3nI+p8+JT+KGbiwaIO60evkGvQD8BmIOoYFqA3w5M21OkIcCeAnDYI1x2wI1BmDkAvMMuwwifve2EvcbUKDBKn9mF/iCYBQAA'

    Write-Host

    foreach ( $File in 'Gen-Menu-Store.bat','Gen-Menu-ToAdmin.lnk' )
    {
        $FilePath = '{0}\{1}' -f $Path, $File

        if ( $File -eq 'Gen-Menu-Store.bat' )
        {
            $BytesCompressed = [System.Convert]::FromBase64String(($BatBase64 -replace('\s','')))
            $Space = '  '
        }
        else
        {
            $BytesCompressed = [System.Convert]::FromBase64String(($LnkBase64 -replace('\s','')))
            $Space = ''
        }

        if ( -not [System.IO.File]::Exists($FilePath) )
        {
            Write-Host " [$NameThisFunction] " -ForegroundColor DarkCyan -NoNewline
            Write-Host $File -ForegroundColor White -NoNewline
            Write-Host "$Space | Create | " -ForegroundColor DarkCyan -NoNewline

            try
            {
                $InputMS  = [System.IO.MemoryStream]::new($BytesCompressed)
                $OutputMS = [System.IO.MemoryStream]::new()
                $GzipStream = [System.IO.Compression.GZipStream]::new($InputMS,[System.IO.Compression.CompressionMode]::Decompress)
                $GzipStream.CopyTo($OutputMS)
                $GzipStream.Close()
                $InputMS.Close()
                [byte[]] $Bytes = $OutputMS.ToArray()
                $OutputMS.Close()
                [System.IO.File]::WriteAllBytes($FilePath,$Bytes)

                Write-Host 'Ok' -ForegroundColor Green
            }
            catch
            {
                Write-Host
                Write-Host " [$NameThisFunction] Error | Create | $FilePath" -ForegroundColor Red
            }
        }
        else
        {
            Write-Host " [$NameThisFunction] " -ForegroundColor DarkCyan -NoNewline
            Write-Host $File -ForegroundColor Green -NoNewline
            Write-Host "$Space | " -ForegroundColor DarkGray -NoNewline
            Write-Host 'File already exist' -ForegroundColor DarkGreen
        }
    }
}

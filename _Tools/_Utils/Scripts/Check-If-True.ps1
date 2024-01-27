
<#
    Description    = $File.FileDescription
    Version        = $File.FileVersionRaw
    VersionMajor   = $File.FileMajorPart
    VersionMinor   = $File.FileMinorPart
    VersionBuild   = $File.FileBuildPart
    VersionPrivate = $File.FilePrivatePart

[PSCustomObject] $FileInfo = [PSCustomObject] @{
    Description    = 'NVIDIA Windows Kernel Mode Driver, Version 531.68'  # [string]
    Version        = '31.0.15.3168' # [Version]
    VersionMajor   = 31   # [int]
    VersionMinor   = 0    # [int]
    VersionBuild   = 15   # [int]
    VersionPrivate = 3168 # [int]
}
#>

# Функция проверки условия по версии файла
Function Check-If-True ( [PSCustomObject] $FileInfo, [string] $Check ) {

    [bool] $Result = $false

    [string] $ifTrue = ''
    [string] $isThis = ''

    [string] $isFile = ''
    [string] $isProp = ''

    [string] $getName = ''
    [string] $getPath = ''

    [string] $Content = ''

    [string[]] $Attr = @()
    [System.IO.FileSystemInfo] $GetItem = $null

    [PSObject] $Property = $null   # может быть [version] или [string] или [int]

    [string[]] $Checks = @($Check.Split(',').Trim()).Where({$_})

    foreach ( $Check in $Checks )
    {
        $Result = $false

        if ( $Check -match '^\s*"(?<Property>(Description|Version(Major|Minor|Build|Private)?))"\s+(?<ifTrue>(=|\>|\<|\>=|\<=|\!=|match|notmatch))\s+"(?<isThis>.+)"' )
        {
            $Property = $FileInfo.($Matches.Property) # может быть [version] или [string] или [int]
            $ifTrue   = $Matches.ifTrue
            $isThis   = $Matches.isThis

            if ( $ifTrue -eq '=' )
            {
                if ( $Property -eq $isThis ) { $Result = $true }
            }
            elseif ( $ifTrue -eq '>' )
            {
                if ( $Property -gt $isThis ) { $Result = $true }
            }
            elseif ( $ifTrue -eq '<' )
            {
                if ( $Property -lt $isThis ) { $Result = $true }
            }
            elseif ( $ifTrue -eq '>=' )
            {
                if ( $Property -ge $isThis ) { $Result = $true }
            }
            elseif ( $ifTrue -eq '<=' )
            {
                if ( $Property -le $isThis ) { $Result = $true }
            }
            elseif ( $ifTrue -eq '!=' )
            {
                if ( -not ( $Property -eq $isThis )) { $Result = $true }
            }
            elseif ( $ifTrue -eq 'match' )
            {
                try { if ( $Property -match $isThis ) { $Result = $true } } catch {}
            }
            elseif ( $ifTrue -eq 'notmatch' )
            {
                try { if ( -not ( $Property -match $isThis )) { $Result = $true } } catch {}
            }
        }
        elseif ( $Check -match '^\s*"\\(?<isFile>Edit\\[^\\\s][^\\\r\n]*\\[^\\\s][^"\r\n]*)"\s+"(?<Property>(Text|Description|Version(Major|Minor|Build|Private)?))"\s+(?<ifTrue>(=|\>|\<|\>=|\<=|\!=|match|notmatch))\s+"(?<isThis>.+)"' )
        {
            # Расширенный

            $isFile  = '{0}\{1}' -f $CurrentRoot, $Matches.isFile
            $isProp  = $Matches.Property
            $ifTrue  = $Matches.ifTrue
            $isThis  = $Matches.isThis

            $getName = $isFile -replace ('.+\\','')
            $getPath = $isFile -replace ('\\[^\\]+$','')
            $isFile  = ''
        
            try { $isFile = ([string[]][System.IO.Directory]::EnumerateFiles($getPath, $getName))[-1] } catch {} # Взять один последний файл 

            if ( $isFile )
            {
                if ( $isProp -eq 'Text' )
                {
                    if ( $ifTrue -like '*match' )
                    {
                        try
                        {
                            $Content = [System.IO.File]::ReadAllText($isFile, [System.Text.Encoding]::GetEncoding(65001))
                
                            if ( $ifTrue -eq 'match' )
                            {
                                if ( [regex]::Match($Content,"(?<G>$isThis)",5).Groups['G'].Value ) # 1 = IgnoreCase + 4 = ExplicitCapture
                                {
                                    $Result = $true
                                }
                            }
                            else
                            {
                                if ( -not ( [regex]::Match($Content,"(?<G>$isThis)",5).Groups['G'].Value )) # 1 = IgnoreCase + 4 = ExplicitCapture
                                {
                                    $Result = $true
                                }
                            }
                        }
                        catch {}
                    }
                }
                else
                {
                    $GetItem = [System.IO.FileInfo]::new($isFile)

                    if ( $GetItem.Attributes -match 'readonly|hidden|system' )
                    {
                        $Attr = [regex]::Split($GetItem.Attributes, ',').Trim() ; $GetItem.Attributes = ( $Attr -notmatch 'readonly|hidden|system' )

                        $GetItem = [System.IO.FileInfo]::new($isFile) # Если 'system' то без админа не может получить данные файла, переполучение
                    }

                    $FileInfo = [PSCustomObject] @{
                        Description    = $GetItem.VersionInfo.FileDescription
                        Version        = $GetItem.VersionInfo.FileVersionRaw
                        VersionMajor   = $GetItem.VersionInfo.FileMajorPart
                        VersionMinor   = $GetItem.VersionInfo.FileMinorPart
                        VersionBuild   = $GetItem.VersionInfo.FileBuildPart
                        VersionPrivate = $GetItem.VersionInfo.FilePrivatePart
                    }

                    $GetItem = $null

                    $Property = $FileInfo.$isProp # может быть [version] или [string] или [int]

                    if ( $ifTrue -eq '=' )
                    {
                        if ( $Property -eq $isThis ) { $Result = $true }
                    }
                    elseif ( $ifTrue -eq '>' )
                    {
                        if ( $Property -gt $isThis ) { $Result = $true }
                    }
                    elseif ( $ifTrue -eq '<' )
                    {
                        if ( $Property -lt $isThis ) { $Result = $true }
                    }
                    elseif ( $ifTrue -eq '>=' )
                    {
                        if ( $Property -ge $isThis ) { $Result = $true }
                    }
                    elseif ( $ifTrue -eq '<=' )
                    {
                        if ( $Property -le $isThis ) { $Result = $true }
                    }
                    elseif ( $ifTrue -eq '!=' )
                    {
                        if ( -not ( $Property -eq $isThis )) { $Result = $true }
                    }
                    elseif ( $ifTrue -eq 'match' )
                    {
                        try { if ( $Property -match $isThis ) { $Result = $true } } catch {}
                    }
                    elseif ( $ifTrue -eq 'notmatch' )
                    {
                        try { if ( -not ( $Property -match $isThis )) { $Result = $true } } catch {}
                    }
                }
            }
        }

        if ( -not $Result ) { break } # если false выйти, смысла далее проверять нет
    }

    return $Result
}



# Функция получения нужной кодировки
Function Get-Encoding ( [string] $EncName ) {

    # 'utf-8', 'utf-8+bom', 'utf-16', 'utf-16+bom', 'utf-16BE', 'utf-16BE+bom'
    # или CodePage: 65001, 1200 и т.д., но для кодировок с bom файлы будут сохранены с bom

    try
    {
        if     ( $EncName -eq 'utf-8'        ) { $enc = [System.Text.UTF8Encoding]::new($false)            }
        elseif ( $EncName -eq 'utf-8+bom'    ) { $enc = [System.Text.UTF8Encoding]::new($true)             }
        elseif ( $EncName -eq 'utf-16'       ) { $enc = [System.Text.UnicodeEncoding]::new($false,$false)  }
        elseif ( $EncName -eq 'utf-16+bom'   ) { $enc = [System.Text.UnicodeEncoding]::new($false,$true)   }
        elseif ( $EncName -match '^\d+$'     ) { $enc = [System.Text.Encoding]::GetEncoding([int]$EncName) }
        elseif ( $EncName -eq 'utf-16BE'     ) { $enc = [System.Text.UnicodeEncoding]::new($true,$false)   }
        elseif ( $EncName -eq 'utf-16BE+bom' ) { $enc = [System.Text.UnicodeEncoding]::new($true,$true)    }
        else
        {
            throw
        }
    }
    catch
    {
        Write-Host "    Fix: Error: Get-Encoding: '$EncName'" -ForegroundColor Red
        $aWarningsGlobal += "Fix: Error: Get-Encoding: '$EncName'"

        $enc = [System.Text.UTF8Encoding]::new($false)
        $BoolErrorGlobal = $true
    }

    return $enc
}

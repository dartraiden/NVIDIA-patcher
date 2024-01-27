
$MainMenu = @{

    Info =  @{

       0 = "`n #DarkGray#|[#Gray# AutoFixFiles #DarkGray#| AFF ]|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||[ westlife | ru-board.com ]|||#" #162
    }

    Status = @{

      0 = "`n       #DarkGray#preset: #white#$([System.IO.Path]::GetFileName($CurrentPresetsFile))#"  # Presets

        1 = "       #DarkGray#   log: $(Get-HtmlLog)#" # Log

        2 = ''
        3 = '& Local-TimeStamp-Server'  # < Get-Data-Preset

        4 = ''
        5 = '& Info-Gen-Cert'

        6 = ''
        7 = '& Show-Data-Preset | -NotGetData'
    }

    Options = @{

      1 = "`n#Cyan#   [1]# = All        #DarkGray#| UnPack/cmd/UnSign/Null/Copy/Fix/Patch/Sign/cmd Final        #DarkCyan#◄#Cyan# [11]# = All    #DarkGray#| Not reGenerate CAT#"

      2 = "`n#Cyan#   [2]# = UnPack     #DarkGray#| UnPack: #", '& Show-UnPack-Or-Folder'
        3 = "#Cyan#   [3]# = UnSign #DarkCyan#+   #DarkGray#| UnSign (Delete digital signatures) + cmd + Null + Copy      #DarkCyan#◄#Cyan# [31]# = UnSign #DarkGray#| + cmd Final#"
        4 = "#Cyan#   [4]# = Fix text's #DarkGray#| Fix    (Only modify the text files)                         #DarkCyan#◄#Cyan# [41]# = Fix    #DarkGray#| Test mode#"
        5 = "#Cyan#   [5]# = Patch PE   #DarkGray#| Patch  (Only patch the PE files)                            #DarkCyan#◄#Cyan# [51]# = Patch  #DarkGray#| Test mode#"
        6 = "#Cyan#   [6]# = Sign       #DarkGray#| Sign   (Sign files) + reGenerate CAT + cmd Final            #DarkCyan#◄#Cyan# [61]# = Sign   #DarkGray#| Not reGenerate CAT#"

      7 = "`n#Cyan# [100]# = Create Certificates (#DarkCyan#Gen#)   #DarkCyan#◄#Cyan# [10!]# = reCreate Certificates (#DarkCyan#Gen#)#"
        8 = "#Cyan# [200]# = Add #DarkCyan#Gen-Root# to Root        #DarkCyan#◄#Cyan# [201]# = Add #DarkCyan#Gen-Sign# to TrustedPublisher  #DarkCyan#◄#Cyan# [202]# = Remove from store #DarkGray#| Both#"
        9 = "#Cyan# [300]# = Check PFX files             #DarkCyan#◄#Cyan# [301]# = rePackage PFX files #DarkGray#| RePack#"
   10 = "#DarkGray# [   ] = Reload menu"
    
     11 = "                                                                                                            #DarkGray#|[ $(Get-Presets-Version) ]|#"
    }

    Selection = @{

         1 = '& Sign-Files | -ReGenerateCAT'
        11 = '& Sign-Files'

         2 = '& UnPack-Archive'

         3 = '& Run-CMD-Files | -NotStop', '& UnSign-Files | -NotGetData -NotStop', '& Null-Files | -NotGetData -NotStop',
             '& Copy-Files | -NotGetData'
        31 = '& Run-CMD-Files | -NotStop', '& UnSign-Files | -NotGetData -NotStop', '& Null-Files | -NotGetData -NotStop',
             '& Copy-Files | -NotGetData -NotStop', '& Run-CMD-Files | -NotGetData -Final'

         4 = '& Fix-Content'
        41 = '& Fix-Content | -NotSave'

         5 = '& Patch-PE'
        51 = '& Patch-PE | -NotSave'

         6 = '& Sign-Files | -OnlySign -ReGenerateCAT'
        61 = '& Sign-Files | -OnlySign'

       100 = '& Manage-GEN'
      '10!'= '& Manage-GEN | -ReGenerate'

       200 = '& Manage-Cert-Store | -AddRoot'
       201 = '& Manage-Cert-Store | -AddTrusted'
       202 = '& Manage-Cert-Store | -Remove'

       300 = '& Manage-PFX | -Pause -Test'
       301 = '& Manage-PFX | -Pause -Repack'

    'Exit' = 'Exit'   # выход

    }
}

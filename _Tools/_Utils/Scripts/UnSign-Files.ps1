
#
Function UnSign-Files {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter(Mandatory = $false)]
        [string] $Folder = $EditFolderGlobal
       ,
        [Parameter(Mandatory = $false)]
        [switch] $NotStop
       ,
        [Parameter(Mandatory = $false)]
        [switch] $NotGetData
    )

    Write-host
    Write-host ' UnSign:' -ForegroundColor White -BackgroundColor DarkCyan -NoNewline
    Write-host ' Delete digital signatures from files' -ForegroundColor Cyan

    [string] $Folder = $Folder -replace '\\Edit$',''

    if ( -not $NotGetData )
    {
        $BoolErrorGlobal = $false
        $aWarningsGlobal = @()
        $aAttentionsGlobal = @()

        Get-Data-Preset
    }

    [string] $Unsigntool = @'
using System;
// https://docs.microsoft.com/en-us/windows/desktop/api/imagehlp/nf-imagehlp-imageremovecertificate

namespace Unsigntool
{
    public class Program
    {
        [System.Runtime.InteropServices.DllImport("Imagehlp.dll")]
        private static extern bool ImageRemoveCertificate(IntPtr handle, int index);

        private static void UnsignFile(string file)
        {
            using (System.IO.FileStream fs = new System.IO.FileStream(file, System.IO.FileMode.Open, System.IO.FileAccess.ReadWrite))
            {
                ImageRemoveCertificate(fs.SafeFileHandle.DangerousGetHandle(), 0);
                fs.Close();
            }
        }

        public static void Files(string[] args)
        {
            foreach (var arg in args)
            {
                UnsignFile(arg);
            }
        }
    }
}
'@

    if ( -not ( 'Unsigntool.Program' -as [type] ))
    {
        $cp = [System.CodeDom.Compiler.CompilerParameters]::new('System.dll')
        $cp.TempFiles = [System.CodeDom.Compiler.TempFileCollection]::new($ScratchDirGlobal,$false)
        $cp.GenerateInMemory = $true
        $cp.CompilerOptions = '/platform:anycpu /nologo'

        Add-Type -TypeDefinition $Unsigntool -ErrorAction Stop -Language CSharp -CompilerParameters $cp
    }

    [PSCustomObject] $dAction = @{}

    [string] $isF = ''
    [string] $FilePath = ''
    [string] $ShowFound = ''

    [string] $getName = ''
    [string] $getPath = ''
    
    [System.IO.FileSystemInfo] $GetItem = $null
    [string[]] $Attr = @()

    [int] $N  = 0

    foreach ( $isF in $aDataRemoveSignGlobal )
    {
        Write-host ' UnSign: ' -ForegroundColor DarkGray -NoNewline
        Write-host $isF -ForegroundColor White -NoNewline
        Write-host ' ◄ ' -ForegroundColor DarkGray -NoNewline
        Write-host 'Name pattern (-like Last)' -ForegroundColor DarkGray

        $N++

        $dAction = @{}

        $FilePath = ''
        $getName  = $isF -replace ('.+\\','')
        $getPath  = "$Folder\$isF" -replace ('\\[^\\]+$','')

        try { $FilePath = ([string[]][System.IO.Directory]::EnumerateFiles($getPath, $getName))[-1] } catch {}  # Взять один последний файл (-like Last)

        if ( $FilePath )
        {
            $ShowFound = $FilePath.Replace("$Folder\",'')

            Write-host ' UnSign: ' -ForegroundColor DarkGray -NoNewline
            Write-host $ShowFound -ForegroundColor Magenta -NoNewline
            Write-host ' ◄ ' -ForegroundColor DarkGreen -NoNewline
            Write-host 'found, UnSigning file' -ForegroundColor DarkGreen -NoNewline

            try
            {
                $GetItem = [System.IO.FileInfo]::new($FilePath)

                if ( $GetItem.Attributes -match 'readonly|hidden|system' )
                {
                    $Attr = [regex]::Split($GetItem.Attributes, ',').Trim() ; $GetItem.Attributes = ( $Attr -notmatch 'readonly|hidden|system' )
                }

                $GetItem = $null

                [Unsigntool.Program]::Files($FilePath)

                if ( $aActionsGlobal.SyncRoot )
                {
                    $dAction[$ShowFound] = [PSCustomObject]@{
                        Result = $true
                        Action = '[UnSign]'
                        Color  = 'DarkGray'
                    }

                    # добавление Ссылки на переменную $dAction, изменяя $dAction, изменеяется и в $aActionsGlobal, пока существует переменная $dAction или не сброшена @{}
                    $aActionsGlobal.Add($dAction) 
                }

                Write-host ' [Ok]' -ForegroundColor Green
            }
            catch
            {
                Write-host
                Write-host ' UnSign: ' -ForegroundColor DarkGray -NoNewline
                Write-host $ShowFound -ForegroundColor Red -NoNewline
                Write-host ' | ' -ForegroundColor DarkGray -NoNewline
                Write-host 'Error: UnSigning file' -ForegroundColor Red

                Write-Host " UnSign: $($_.CategoryInfo.Category): $($_.Exception.Message)" -ForegroundColor Red
                Write-Host " UnSign: $($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red

                $aWarningsGlobal += "Null: Error: UnSigning file: $isF"

                $BoolErrorGlobal = $true

                break
            }
        }
        else
        {
            Write-host ' UnSign: ' -ForegroundColor DarkGray -NoNewline
            Write-host $isF -ForegroundColor DarkYellow -NoNewline
            Write-host ' | ' -ForegroundColor DarkGray -NoNewline
            Write-host 'File not found' -ForegroundColor DarkYellow

            $aAttentionsGlobal += "UnSign | $isF | File not found"
        }
    }

    if ( -not $N )
    {
        Write-host ' UnSign: ' -ForegroundColor DarkGray -NoNewline
        Write-host 'preset is not configured (UnSign-File)' -ForegroundColor DarkGray
    }

    if ( -not $NotStop )
    {
        Get-Pause
    }

    Return
}

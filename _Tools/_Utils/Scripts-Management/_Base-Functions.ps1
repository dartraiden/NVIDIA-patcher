
# Для указания не скролить консоль в строке меню, для открытия отдельных окон или приложений, чтобы команды не передавались открываемым окнам.
# Сбрасывается сама после первого использования.
Function Set-NoConsole-Scroll {
    [bool] $Global:NoConsoleScroll = $true
}

Function Get-Delay ( [Uint16] $ms = 1000 ) {
    Start-Sleep -Milliseconds $ms
}

# Получение разрядности файлов PE (x86/x64). Остальные убраны.
Function Get-PE-Arch
{
    [CmdletBinding( SupportsShouldProcess = $false )]
    [OutputType([string])]
    param(
        [Parameter( Mandatory = $true, Position = 0)]
        [Alias('FullName')][String]$File
    )

    ## Constants ##
    $PEHeaderOffsetLocation = 0x3c
    $PEHeaderOffsetLocationNumBytes = 2
    $PESignatureNumBytes = 4
    $MachineTypeNumBytes = 2
         
    try
    {
        $PEHeaderOffset = New-Object Byte[] $PEHeaderOffsetLocationNumBytes
        $PESignature    = New-Object Byte[] $PESignatureNumBytes
        $MachineType    = New-Object Byte[] $MachineTypeNumBytes
             
        Write-Verbose "Opening $File for reading."
        try
        {
            $FileStream = New-Object System.IO.FileStream($File, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        }
        catch
        {
            Write-Verbose "Error: Open FileStream"
            return ''
        }
             
        Write-Verbose "Moving to the header location expected to contain the location of the PE (portable executable) header."
        $FileStream.Position = $PEHeaderOffsetLocation
        $BytesRead = $FileStream.Read($PEHeaderOffset, 0, $PEHeaderOffsetLocationNumBytes)
        if($BytesRead -eq 0)
        {
            Write-Verbose "Error: $File is not the correct format (PE header location not found)." 
            return ''
        }
        
        Write-Verbose "Moving to the indicated position of the PE header."
        $FileStream.Position = [System.BitConverter]::ToUInt16($PEHeaderOffset, 0)
        Write-Verbose "Reading the PE signature."
        $BytesRead = $FileStream.Read($PESignature, 0, $PESignatureNumBytes)
        if($BytesRead -ne $PESignatureNumBytes)
        {
            Write-Verbose "Error: $File is not the correct format (PE Signature is an incorrect size)."    # implicit 'else'
            return ''
        }

        Write-Verbose "Verifying the contents of the PE signature (must be characters `"P`" and `"E`" followed by two null characters)."
        if(-not($PESignature[0] -eq [Char]'P' -and $PESignature[1] -eq [Char]'E' -and $PESignature[2] -eq 0 -and $PESignature[3] -eq 0))
        {
            Write-Verbose "$File is 16-bit or is not a Windows executable."
            return ''
        }

        Write-Verbose "Retrieving machine type."
        $BytesRead = $FileStream.Read($MachineType, 0, $MachineTypeNumBytes)
        if($BytesRead -ne $MachineTypeNumBytes)
        {
            Write-Verbose "$File appears damaged (Machine Type not correct size)." 
            return ''
        }

        $RawMachineType = [System.BitConverter]::ToUInt16($MachineType, 0)
        $TargetMachine = switch ($RawMachineType) # https://learn.microsoft.com/en-us/windows/win32/debug/pe-format?redirectedfrom=MSDN
        {
            0x8664  { 'x64' }
            0x14c   { 'x86' }
            default {
   
                '' # '{0:X0}' -f $RawMachineType

                Write-Verbose "Executable found with an unknown target machine type. Please refer to section 2.3.1 of the Microsoft documentation (http://msdn.microsoft.com/en-us/windows/hardware/gg463119.aspx)."
            }
        }

        return $TargetMachine
    }
    catch
    {
        Write-Host "  Get-PE-Arch: Error: $($_.CategoryInfo.Category): $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Get-PE-Arch: Error: $($_.Exception.ErrorRecord.InvocationInfo.PositionMessage)" -ForegroundColor Red

        # the real purpose of the outer try/catch is to ensure that any file streams are properly closed. pass errors through
        Write-Verbose 'Error' # $_
        return ''
    }
    finally
    {
        if ( $FileStream )
        {
            $FileStream.Close()
        }
    }
}

# Пишет все байты файла после просчета и изменения контрольной суммы - уныло. Оставлен как вариант, не используется.
Function Fix-PE-CheckSum
{
    [CmdletBinding( SupportsShouldProcess = $false )]
    [OutputType([int])]
    param(
        [Parameter( Mandatory = $true, Position = 0)]
        [Alias('FullName')][String]$File
       ,
        [Parameter( Mandatory = $false )]
        [switch] $NoSilent
    )

    [string] $PEChecksum = @'
// Based on the code: https://github.com/Deltafox79/Win_1337_Apply_Patch/blob/master/Win_1337_Patch/mCheckSum.cs

using System;
using System.IO;
using System.Runtime.InteropServices;

namespace WinAPI
{
    public static class PEChecksum
    {
        public static int GetCheckSum(string sFilePath, bool verbose = false)
        {
            if (File.Exists(sFilePath))
            {
                uint CurrentHeaderSum, NeedCheckSum, uRet = 0;
                uRet = MapFileAndCheckSum(sFilePath, out CurrentHeaderSum, out NeedCheckSum);
                if (uRet == 0x00)
                {
                    if (CurrentHeaderSum == NeedCheckSum)
                    {
                        if (verbose)
                            Console.WriteLine("Good: 0x{0}", NeedCheckSum.ToString("x8"));
                        return 0;
                    }
                    else
                    {
                        if (verbose)
                            Console.WriteLine("Wrong: Current: 0x{0}\n          Need: 0x{1}", CurrentHeaderSum.ToString("x8"), NeedCheckSum.ToString("x8"));
                        return 1;
                    }
                }
                else
                {
                    if (verbose)
                        Console.WriteLine("error: Null file");
                    return 2; // файл нулевой
                }
            }
            else
            {
                if (verbose)
                    Console.WriteLine("error: No file");
                return 3; // нет файла
            }
        }

        public static int FixCheckSum(string sFilePath, bool verbose = false)
        {
            if (!File.Exists(sFilePath))
            {
                if (verbose)
                    Console.WriteLine("error: No file");
                return 1;
            }

            IMAGE_DOS_HEADER DHD = new IMAGE_DOS_HEADER();
            IMAGE_NT_HEADERS NHD = new IMAGE_NT_HEADERS();

            long iPointer = 0;
            uint uOriginal = 0;
            uint uRecalculated = 0;
            uint uRet = 0;
            byte[] fBytes = new byte[0];
            
            FileStream fs = null;
            BinaryReader bReader = null;
            
            try
            {
                fs = new FileStream(sFilePath, FileMode.Open, FileAccess.Read);
                bReader = new BinaryReader(fs);
                fBytes = bReader.ReadBytes((int)bReader.BaseStream.Length);
            }
            catch (Exception e)
            {
                if (verbose)
                    Console.WriteLine("Exception read: {0}", e);
                return 2;
            }
            finally
            {
                if (fs != null)  { fs.Close(); }
                if (bReader != null) { bReader.Close(); }
            }

            if (fBytes.Length <= 0)
            {
                if (verbose)
                    Console.WriteLine("error read: fBytes.Length <= 0");
                return 3;
            }

            GCHandle gcHandle = new GCHandle();
            try
            {
                gcHandle = GCHandle.Alloc(fBytes, GCHandleType.Pinned);
                iPointer = (long)gcHandle.AddrOfPinnedObject(); 
                DHD = (IMAGE_DOS_HEADER)Marshal.PtrToStructure(new IntPtr(iPointer), typeof(IMAGE_DOS_HEADER));
                NHD = (IMAGE_NT_HEADERS)Marshal.PtrToStructure(new IntPtr(iPointer + DHD.e_lfanew), typeof(IMAGE_NT_HEADERS));
            }
            catch (Exception e)
            {
                if (verbose)
                    Console.WriteLine("Exception get header: {0}", e);
                return 4;
            }
            finally
            {
                if (gcHandle != null) { gcHandle.Free(); }
            }

            if (NHD.Signature != 17744 || DHD.e_magic != 23117)
            {
                if (verbose)
                    Console.WriteLine("wrong hedear data: NHD.Signature: {0}; DHD.e_magic: {1}", NHD.Signature, DHD.e_magic);
                return 5;
            }

            uRet = MapFileAndCheckSum(sFilePath, out uOriginal, out uRecalculated);

            if (uRet == 0x00)
            {
                if (uOriginal == uRecalculated)
                {
                    if (verbose)
                        Console.WriteLine("ok: The checksum is already correct: 0x{0}", uOriginal.ToString("x8"));
                    return 0;
                }
            }
            else
            {
                if (verbose)
                    Console.WriteLine("error: in MapFileAndCheckSum");
                return 6;
            }

            NHD.OptionalHeader.CheckSum = uRecalculated;

            byte[] bNHD = getBytes_(NHD);
            if (fBytes.Length - (DHD.e_lfanew + bNHD.Length) <= 0) { Array.Resize(ref fBytes, (int)(fBytes.Length + bNHD.Length)); }
            Array.Copy(bNHD, 0, fBytes, DHD.e_lfanew, bNHD.Length);

            BinaryWriter bWriter = null;

            try
            {
                fs = new FileStream(sFilePath, FileMode.Open);
                bWriter = new BinaryWriter(fs);
                bWriter.Write(fBytes);
            }
            catch (Exception e)
            {
                if (verbose)
                    Console.WriteLine("Exception fix: {0}", e);
                return 7;
            }
            finally
            {
                if (bWriter != null) { bWriter.Flush(); bWriter.Close(); }
                if (fs != null) { fs.Close(); }
            }
            
            if (verbose)
                Console.WriteLine("ok: fixed: 0x{0}", uRecalculated.ToString("x8"));
            return 0;
        }

        private static byte[] getBytes_(object oObject)
        {
            int iSize = Marshal.SizeOf(oObject);
            IntPtr ipBuffer = Marshal.AllocHGlobal(iSize);
            Marshal.StructureToPtr(oObject, ipBuffer, false);
            byte[] bData = new byte[iSize];
            Marshal.Copy(ipBuffer, bData, 0, iSize);
            Marshal.FreeHGlobal(ipBuffer);
            return bData;
        }

        // structures
        [StructLayout(LayoutKind.Sequential)]
        private struct IMAGE_DOS_HEADER
        {
            public UInt16 e_magic;
            public UInt16 e_cblp;
            public UInt16 e_cp;
            public UInt16 e_crlc;
            public UInt16 e_cparhdr;
            public UInt16 e_minalloc;
            public UInt16 e_maxalloc;
            public UInt16 e_ss;
            public UInt16 e_sp;
            public UInt16 e_csum;
            public UInt16 e_ip;
            public UInt16 e_cs;
            public UInt16 e_lfarlc;
            public UInt16 e_ovno;
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 4)]
            public UInt16[] e_res1;
            public UInt16 e_oemid;
            public UInt16 e_oeminfo;
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 10)]
            public UInt16[] e_res2;
            public Int32 e_lfanew;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct IMAGE_FILE_HEADER
        {
            public UInt16 Machine;
            public UInt16 NumberOfSections;
            public UInt32 TimeDateStamp;
            public UInt32 PointerToSymbolTable;
            public UInt32 NumberOfSymbols;
            public UInt16 SizeOfOptionalHeader;
            public UInt16 Characteristics;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct IMAGE_DATA_DIRECTORY
        {
            public UInt32 VirtualAddress;
            public UInt32 Size;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct IMAGE_OPTIONAL_HEADER32
        {
            public UInt16 Magic;
            public Byte MajorLinkerVersion;
            public Byte MinorLinkerVersion;
            public UInt32 SizeOfCode;
            public UInt32 SizeOfInitializedData;
            public UInt32 SizeOfUninitializedData;
            public UInt32 AddressOfEntryPoint;
            public UInt32 BaseOfCode;
            public UInt32 BaseOfData;
            public UInt32 ImageBase;
            public UInt32 SectionAlignment;
            public UInt32 FileAlignment;
            public UInt16 MajorOperatingSystemVersion;
            public UInt16 MinorOperatingSystemVersion;
            public UInt16 MajorImageVersion;
            public UInt16 MinorImageVersion;
            public UInt16 MajorSubsystemVersion;
            public UInt16 MinorSubsystemVersion;
            public UInt32 Win32VersionValue;
            public UInt32 SizeOfImage;
            public UInt32 SizeOfHeaders;
            public UInt32 CheckSum;
            public UInt16 Subsystem;
            public UInt16 DllCharacteristics;
            public UInt32 SizeOfStackReserve;
            public UInt32 SizeOfStackCommit;
            public UInt32 SizeOfHeapReserve;
            public UInt32 SizeOfHeapCommit;
            public UInt32 LoaderFlags;
            public UInt32 NumberOfRvaAndSizes;
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 16)]
            public IMAGE_DATA_DIRECTORY[] DataDirectory;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct IMAGE_NT_HEADERS
        {
            public UInt32 Signature;
            public IMAGE_FILE_HEADER FileHeader;
            public IMAGE_OPTIONAL_HEADER32 OptionalHeader;
        }

        [DllImport("Imagehlp.dll", ExactSpelling = false, CharSet = CharSet.Auto, SetLastError = true)]
        private static extern uint MapFileAndCheckSum(string Filename, out uint HeaderSum, out uint CheckSum);
    }
}
'@

    try
    {
        if ( -not ( 'WinAPI.PEChecksum' -as [type] ))
        {
            $cp = [System.CodeDom.Compiler.CompilerParameters]::new('System.dll')
            $cp.TempFiles = [System.CodeDom.Compiler.TempFileCollection]::new($ScratchDirGlobal,$false)
            $cp.GenerateInMemory = $true
            $cp.CompilerOptions = '/platform:anycpu /nologo'

            Add-Type -TypeDefinition $PEChecksum -ErrorAction Stop -Language CSharp -CompilerParameters $cp
        }

        return [WinAPI.PEChecksum]::FixCheckSum($File, $NoSilent)
    }
    catch
    {
        Write-Verbose 'Error'
        return 101
    }
}



<#
Пример 1: Write-Warning-Log "`n Пример предупреждения 1 `n "

Пример 2: Write-Warning-Log "`n   Пример предупреждения `n   еще одного " "D:\Warnings.log"
#>
Function Write-Warning-Log {

    [CmdletBinding()]
    Param (
        [Parameter( Mandatory = $true,  ValueFromPipeline = $false, Position = 0 )]
        [string] $Line
       ,
        [Parameter( Mandatory = $false, ValueFromPipeline = $false, Position = 1 )]
        [string] $FileLog = $WarningsLogFile   # По умолчанию задан глобальный лог для предупреждений, если есть.
    )

    # Получение имени этой функции.
    [string] $NameThisFunction = $MyInvocation.MyCommand.Name

    # Получение перевода
    [hashtable] $L = $Lang.$NameThisFunction
    [string] $text = ''

    Write-Warning "$Line"

    # Если не передан файл для сохранения или не назначен $WarningLog по умолчанию, сохранит в папку Temp пользователя.
    if ( $FileLog -eq '' )
    {
        # Расскрываем короткие имена в пути
        [string] $TempPath = $([System.IO.Path]::GetFullPath($env:TEMP))

        $FileLog = "$TempPath\AutoSettings-Warnings.log"

        $text = if ( $L.s1 ) { $L.s1 } else { 'This warning is written in' }
        Write-host "   $text`: '$FileLog', " -BackgroundColor DarkYellow -NoNewline

        $text = if ( $L.s1_1 ) { $L.s1_1 } else { 'as the file has not been set' }
        Write-host "$text   " -BackgroundColor DarkYellow
    }
    else
    {
        $text = if ( $L.s1 ) { $L.s1 } else { 'This warning is written in' }
        Write-host "   $text`: '$FileLog'   " -BackgroundColor DarkYellow
    }

    # Out-File -FilePath $File -InputObject "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"), Warning`t$Line" -Append -Encoding utf8

    [System.Collections.Generic.List[string]] $log = "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"), Warning`t$Line"
    [System.IO.File]::AppendAllLines($FileLog,$log,[System.Text.Encoding]::GetEncoding('utf-8'))
}


<#
примеры
Save-Error
или
Save-Error D:\Errors.log
#>
Function Save-Error {

    [CmdletBinding()]
    Param (
        [Parameter( Mandatory = $false, ValueFromPipeline = $false, Position = 1 )]
        [string] $FileLog = $ErrorsLogFile  # По умолчанию задан глобальный лог для ошибок, если есть.
    )

    # Получение имени этой функции.
    [string] $NameThisFunction = $MyInvocation.MyCommand.Name

    # Получение перевода
    [hashtable] $L = $Lang.$NameThisFunction
    [string] $text = ''

    if ( $Error[0] -ne $null )
    {
        # Если не передан файл для сохранения или не назначен $ErrorsLog по умолчанию, сохранит лог в папку Temp пользователя.
        if ( $FileLog -eq '' )
        {
            $FileLog = "$env:TEMP\AutoSettings-Errors.log"

            $text = if ( $L.s1 ) { $L.s1 } else { 'This error is written in' }
            Write-host "   $text`: '$FileLog', " -BackgroundColor DarkBlue -NoNewline

            $text = if ( $L.s1_1 ) { $L.s1_1 } else { 'as the file has not been set' }
            Write-host "$text   " -BackgroundColor DarkBlue

            try { Out-File -FilePath $FileLog -InputObject "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"), Error: ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄`n", $Error[0] -Append -Encoding utf8 -Force -ErrorAction Stop }
            catch { throw }
        }
        else
        {
            $text = if ( $L.s1 ) { $L.s1 } else { 'This error is written in' }
            Write-host "   $text`: '$FileLog'   " -BackgroundColor DarkBlue

            try { Out-File -FilePath $FileLog -InputObject "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"), Error: ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄`n", $Error[0] -Append -Encoding utf8 -Force -ErrorAction Stop }
            catch
            {
                # Если нет доступа на запись к директории скрипта, сохранить файл в папке темп пользователя
                $FileLog = "$env:TEMP\AutoSettings-Errors.log"

                $text = if ( $L.s1 ) { $L.s1 } else { 'This error is written in' }
                Write-host "   $text`: '$FileLog', " -BackgroundColor DarkBlue -NoNewline

                $text = if ( $L.s2 ) { $L.s2 } else { 'As there is no write access to the script folder' }
                Write-host "$text   " -BackgroundColor DarkBlue

                try { Out-File -FilePath $FileLog -InputObject "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"), Error: ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄`n", $Error[0] -Append -Encoding utf8 -Force -ErrorAction Stop }
                catch { throw }
            }
        }
    }
}

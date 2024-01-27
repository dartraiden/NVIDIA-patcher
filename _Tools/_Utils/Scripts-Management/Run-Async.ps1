

Function Run-Async {

    [CmdletBinding( SupportsShouldProcess = $false )]
    [OutputType([bool])] # error
    Param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [array] $aCmdArgs
       ,
        [Parameter(Mandatory = $false)]
        [int] $WaitMS
    )

    [bool] $Err = $false

    try
    {
        $ScriptBlock = {
            Param([array] $aArgs)

            [string] $exe   = $aArgs[0]
             [array] $aComm = $aArgs[1..10]

            & "$exe" @aComm

            # Start-Sleep -Milliseconds 20000
        }

        $Local:Runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
        $Local:Runspace.ThreadOptions = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
        $Local:Runspace.ApartmentState = 'STA'
        $Local:Runspace.Open()

        $Local:AsyncAction = [System.Management.Automation.PowerShell]::Create()
        $Local:AsyncAction.Runspace = $Local:Runspace
        $Local:AsyncAction.AddScript($ScriptBlock).AddArgument($aCmdArgs) > $null

        $Local:AsyncBeginInvoke = $Local:AsyncAction.BeginInvoke()
        $Local:AsyncAction | Add-Member -MemberType NoteProperty -Name 'AsyncResult' -Value $Local:AsyncBeginInvoke

        # делать пока не будет MS -ge $WaitMS или IsCompleted -eq $true (ожидание асинхронного выполнения)
        if ( $host.Name -eq 'ConsoleHost' )
        {
            # Сдвигание консоли ниже на 1 строку и возврат перед дальнейшим выводом (чтобы вывод не был в упор у нижнего края окна консоли)
            #[char] $Escape = 27
            #[System.Console]::WriteLine("$Escape[?25l")
            #[System.Console]::Write("$Escape[1F$Escape[0J") # 1F - строк для затирания >= 1

            # Работает в lagacy console mode и W7
            $s = 1 # строк для затирания >= 1
            [console]::CursorVisible = $false
            [Console]::WriteLine();
            [console]::SetCursorPosition(0, [console]::CursorTop - $s)
            #[console]::WriteLine([String]::new(' ', [console]::WindowWidth-1) * $s);  # [console]::Write( не оставлять в конце 1 пустую строку
            #[console]::SetCursorPosition(0, [console]::CursorTop - $s)

            if ( $WaitMS )
            {
                Write-Host "            wait: [$WaitMS`ms] " -ForegroundColor Blue -NoNewline
            }
            else
            {
                Write-Host '            wait: ' -ForegroundColor Blue -NoNewline
            }

            $Timer = [System.Diagnostics.Stopwatch]::StartNew()

            [bool] $Out = $false
        
            do
            {
               #foreach ( $G in ' ','·','•','●','○' )             # [System.Console]::Write("$G`b")
               #foreach ( $G in '|','/','—','\','|','/','—','\' ) # [System.Console]::Write("$G`b")
               #foreach ( $G in '○○○○○○○○○○○○','●○○○○○○○○○○○','●●○○○○○○○○○○','●●●○○○○○○○○○','●●●●○○○○○○○○','●●●●●○○○○○○○','●●●●●●○○○○○○','●●●●●●●○○○○○','●●●●●●●●○○○○','●●●●●●●●●○○○','●●●●●●●●●●○○','●●●●●●●●●●●○','●●●●●●●●●●●●' )
                foreach ( $G in '●○○○○○○○○○○○','●●○○○○○○○○○○','●●●○○○○○○○○○','●●●●○○○○○○○○','○●●●●○○○○○○○','○○●●●●○○○○○○','○○○●●●●○○○○○','○○○○●●●●○○○○','○○○○○●●●●○○○','○○○○○○●●●●○○','○○○○○○○●●●●○','○○○○○○○○●●●●','○○○○○○○○○●●●','○○○○○○○○○○●●','○○○○○○○○○○○●' )
                {
                    [System.Console]::Write("$G`b`b`b`b`b`b`b`b`b`b`b`b")
            
                    Start-Sleep -Milliseconds 250 
                
                    if ( $WaitMS )
                    {
                        if (( [math]::Truncate($Timer.Elapsed.TotalMilliseconds) -ge $WaitMS ) -or ( $Local:AsyncAction.AsyncResult.IsCompleted ))
                        {
                            $Out = $true
                            break
                        }
                    }
                    else
                    {
                        if ( $Local:AsyncAction.AsyncResult.IsCompleted )
                        {
                            $Out = $true
                            break
                        }
                    }
                }
            }
            until ($Out)

            $Timer.Stop()

            #[System.Console]::Write("`n$Escape[1F$Escape[0J$Escape[?25h") # 1F - строк для затирания >= 1

            # Работает в lagacy console mode и W7
            $s = 1 # строк для затирания >= 1
            [Console]::WriteLine();
            [console]::SetCursorPosition(0, [console]::CursorTop - $s)
            [console]::WriteLine([String]::new(' ', [console]::WindowWidth-1) * $s);  # [console]::Write( не оставлять в конце 1 пустую строку
            [console]::SetCursorPosition(0, [console]::CursorTop - $s)
            [console]::CursorVisible = $true
        }
        else
        {
            $Timer = [System.Diagnostics.Stopwatch]::StartNew()
        
            if ( $WaitMS )
            {
                Write-Host "      [wait: $WaitMS`ms] ..." -ForegroundColor DarkCyan

                do { Start-Sleep -Milliseconds 50 }
                until (( [math]::Truncate($Timer.Elapsed.TotalMilliseconds) -ge $WaitMS ) -or ( $Local:AsyncAction.AsyncResult.IsCompleted ))
            }
            else
            {
                Write-Host "      [wait: no limits] ..." -ForegroundColor DarkCyan

                do { Start-Sleep -Milliseconds 50 }
                until ( $Local:AsyncAction.AsyncResult.IsCompleted )
            }
        
            $Timer.Stop()
        }

        if ( [math]::Truncate($Timer.Elapsed.TotalSeconds) ) 
        {
            Write-Host "            wait: " -ForegroundColor Blue -NoNewline
            Write-Host $Timer.Elapsed.ToString('hh\:mm\:ss') -ForegroundColor Gray
            Write-Host
        }

        if ( $Local:AsyncAction.AsyncResult.IsCompleted )
        {
            $Local:AsyncResult = $Local:AsyncAction.EndInvoke($Local:AsyncAction.AsyncResult)

            $Local:Runspace.Close()
            $Local:Runspace.Dispose()

            $Local:AsyncAction.AsyncResult.AsyncWaitHandle.SafeWaitHandle.Close()
            $Local:AsyncAction.AsyncResult.AsyncWaitHandle.SafeWaitHandle.Dispose()
            $Local:AsyncAction.Dispose()
        }
        else { $Local:Runspace.CloseAsync() }

    
        if ( $Local:AsyncAction.HadErrors -or ( $WaitMS -and [math]::Truncate($Timer.Elapsed.TotalMilliseconds) -ge $WaitMS ))
        {
            if ( $WaitMS -and [math]::Truncate($Timer.Elapsed.TotalMilliseconds) -ge $WaitMS )
            {
                Write-Host "            wait: [$WaitMS`ms] | Error: Time Out" -ForegroundColor Red
            }

            Write-Host ([string]::Join("`n", $Local:AsyncResult)) -ForegroundColor Red
        }
        else
        {
            Write-Host ([string]::Join("`n", $Local:AsyncResult)) -ForegroundColor Gray
        }
    }
    catch
    {
        $Err = $true
    }

    if ( $Local:AsyncAction.HadErrors -or $Err )
    {
        Return $true   # error
    }
    else
    {
        Return $false  # no error
    }
}

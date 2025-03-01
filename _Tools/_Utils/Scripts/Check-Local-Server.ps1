

# Функция получения web страницы через System.Net.Http.HttpClient
Function Check-Local-Server {

    [CmdletBinding( SupportsShouldProcess = $false )]
    [OutputType([bool])]
    param (
        [Parameter(Position = 0)][string] $Url  # Адрес страницы, которую требуется загрузить
       ,[Parameter()][int] $WaitMS = 5000
    )

    # Подгрузка класса и создание HttpClient Global (не надо диспозить HttpClient в коде)
    if ( -not ( 'System.Net.Http.HttpClient' -as [type] ))
    {
        Add-Type -AssemblyName 'System.Net.Http' -ErrorAction Stop
        Set-Variable -Name httpClient -Value ([System.Net.Http.HttpClient]::new()) -Force -Visibility Public -Option AllScope -Scope Global
        $httpClient.Timeout = [timespan]::FromSeconds(200)
    }

    # Получение имени этой функции.
    [string] $NameThisFunction = $MyInvocation.MyCommand.Name


    $Global:Response = $httpClient.GetStringAsync($Url)

    #region wait

    # Пока нет ответа сервера положительного или отрицательного, предел указывается в $httpClient.Timeout
    if ( $Global:Response )
    {
        if ( $host.Name -eq 'ConsoleHost' )
        {
            $Timer = [System.Diagnostics.Stopwatch]::StartNew()

            while ( -not $Global:Response.IsCompleted )
            {
                Start-Sleep -Milliseconds 1

                if ( [math]::Truncate($Timer.Elapsed.TotalMilliseconds) -ge $WaitMS )
                {
                    $Timer.Stop() ; $httpClient.CancelPendingRequests()
                    break
                }
            }
        }
        else
        {
            $Timer = [System.Diagnostics.Stopwatch]::StartNew()

            while ( -not $Global:Response.IsCompleted )
            {
                ### Start-Sleep -Milliseconds 50
                if ( [math]::Truncate($Timer.Elapsed.TotalMilliseconds) -ge $WaitMS ) { $Timer.Stop() ; $httpClient.CancelPendingRequests() ; break }
            }
        }
    }

    #endregion

    if ( $Global:Response.Result -like 'TSA Server: SHA*' ) { Return $true } else { Return $false }
}

<#
Check-Local-Server -Url 'http://localhost/TS-SHA1'
Check-Local-Server -Url 'http://localhost:80/TS-SHA1'
#>

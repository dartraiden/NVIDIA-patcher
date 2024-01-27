
<#
.SYNOPSIS
 Отображение меню, сконфигурированному в Хэш-таблице по определенному принципу.
 Принцип создания меню описан в \Menu\__Menu_ReadMe.txt.

.DESCRIPTION
 Функция написана для обработки подготовленных меню
 для скриптов AutoSettingsPS и RepackWIMPS.

 Обрабатывает Хэш-таблицу с меню, "построчно".
 Передает массивы из строк на функцию Show-MenuLine,
 которая обрабатывает массивы из строк, выполняет функции или командлеты,
 и выводит результат или текст на экран.
 Либо выполняет из раздела Меню 'Selection' запуск указанных команд (Функций или Командлетов),
 или переход в другие указанные меню.

.PARAMETER Menu
 Принимает Объект [hashtable] с меню.

.INPUTS
 Хэш-таблица [hashtable] c меню.

.OUTPUTS
 Вывод на экран меню и/или результатов выполнения команд.

.EXAMPLE
    Show-Menu -Menu $MenuTest

    Описание
    --------
    Отобразит указанное меню из хэш-таблицы $MenuTest.

.NOTES
 ==========================================
     Автор:  westlife (ru-board)  v.1.0
      Дата:  04-08-2018
 ==========================================

#>
Function Show-Menu {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter( Mandatory = $true, Position = 0 )]
        [ValidateNotNullOrEmpty()]
        [hashtable] $Menu
    )

    Begin
    {
        # Если нет запрета скролить консоль, и размер контента консоли больше размера = (Высота окна консоли * 4)
        if ( -not $Global:NoConsoleScroll -and ( $host.UI.RawUI.CursorPosition.Y -ge ( $host.UI.RawUI.WindowSize.Height * 4 )))
        {
            # Исправление невозврата консоли в начало после Clear-Host, если скролить обратно вверх в начало после вывода, а потом нажать продолжить.
            # Выполняется прокрутка консоли вниз в самый конец вывода, перед Clear-Host
            if ( -not ( $Global:FixClearHost.CurrentDirectory )) { [psobject] $Global:FixClearHost = New-Object -ComObject 'WScript.Shell' }
            try { $Global:FixClearHost.SendKeys('^({END})') } catch {}
        }
        else { $Global:NoConsoleScroll = $false }

        Clear-Host

        Start-Sleep -Milliseconds 100

        # Установка основных переменных из меню и из параметров у текущей функции.
        [string] $NameThisFunction = $MyInvocation.MyCommand.Name
        [string] $InvokeString     = $MyInvocation.line.Trim()
        [string] $MenuName         = (Get-Variable -Name isStartMenu -ErrorAction SilentlyContinue).Description

        [hashtable] $Info      = $Menu.Info
        [hashtable] $Status    = $Menu.Status
        [hashtable] $Options   = $Menu.Options
        [hashtable] $Selection = $Menu.Selection

        # Получение перевода
        [hashtable] $L = $Lang.$NameThisFunction
        [string] $text = ''

        if ( $Selection.Keys -notcontains 'Exit' )
        {
            $text = "`n  {0}: $MenuName, {1} 'Selection'`n  {2}: $InvokeString`n" -f
                $(if ( $L.s1 ) { $L.s1, $L.s1_1, $L.s1_2 } else { 'No ''Exit'' option in the menu', 'section', 'Menu execution line' })

            Write-Warning "$text"

            Get-Pause ; Exit    # Выход
        }
    }

    Process
    {
        # Перехват ошибок, только прерываемых исключений, В блоке Process для выхода из функции.
        # И если есть глобальный trap, не отображать ошибку тут, а передать ее ему, для отображения и/или записи в лог.
        trap
        {
            $text = if ( $L.s8 ) { $L.s8 } else { 'Error in Process' }
            Write-Warning "$NameThisFunction`: $text`:`n   $($_.CategoryInfo.Category): $($_.Exception.Message)"
            break
        }

        [int] $NumberSection = 0
        # Поочередно передает все строки из 3 разделов меню: Info, Status, Options, на функцию Show-MenuLine для вывода на экран,
        # Если раздела в меню нет, цикл переходит на следующий.
        foreach ( $Key in ( $Info, $Status, $Options ))
        {
            $NumberSection++

            foreach ( $String in $Key.Keys | Sort-Object )
            {
                $MenuLine = $Key.$String
                try
                {
                    Show-MenuLine -Line $MenuLine
                }
                catch
                {
                    if     ( $NumberSection -eq 1 ) { [string] $MenuSection = 'Info' }
                    elseif ( $NumberSection -eq 2 ) { [string] $MenuSection = 'Status' }
                    elseif ( $NumberSection -eq 3 ) { [string] $MenuSection = 'Options' }

                    $text = "`n  {0}: '$InvokeString'`n  {1}: '$NameThisFunction', {2}: '$MenuName', {3}: '$MenuSection', {4}: [$String]" -f
                        $(if ( $L.s2 ) { $L.s2, $L.s2_1, $L.s2_2, $L.s2_3, $L.s2_4 } else { 'Error when executing a command', 'in function', 'when processing menus', 'in section', 'in the section line' })

                    Write-Warning "$text"

                    throw
                }
            }
        }

        <# Когда всего одно меню, то будет меню 2 раза в логе, поэтому лишнее
        # Сохранение вывода консоли первого меню в переменную для Save-HtmlLog, только один раз. Чтобы в логе было это меню и не было задержки меню.
        if ( $SaveHtmlLogGlobal -and ( $CurrentMenuName -eq '$MainMenu' ) -and ( -not $Global:MainMenuSaved ))
        {
            $Global:MainMenuSaved = $true
            $Width = $host.UI.RawUI.BufferSize.Width
            $Global:FirstOutputConsole = [PSCustomObject] @{
                Width  = $Width
                Height = $host.UI.RawUI.CursorPosition.Y
                BufferContents = $host.UI.RawUI.GetBufferContents([Management.Automation.Host.Rectangle]::new(0,0,$Width,$Width))
            }
        }
        #>

        # Сброс нажатых клавиш клавиатуры, сделанных до предоставления выбора,
        # чтобы консоль не обрабатывала эти действия после завершения отображения меню. Не передала эти действия автоматически в Read-Host.
        $Host.UI.RawUI.FlushInputBuffer()

        # Далее ожидание выбора пользователя, и выполнение согласно выбору.

        $text = if ( $L.s3 ) { $L.s3 } else { 'Your choice' }
        $InputMenu = (Read-Host "  $text").Trim()

        # Write-Host

        # Выбор без ввода приравнивается к вводу 'Exit', то есть выполнить строку в пункте 'Exit'.
        if ( $InputMenu -eq '' ) { Return } #{ $InputMenu = 'Exit' }

        # Если нет совпадений выбора пользователя с указанными пунктами в разделе Selection, то перезайти обратно в меню.
        if ( $Selection.Keys -notcontains $InputMenu )
        {

            $text = "  {0} [$InputMenu] {1}" -f $(if ( $L.s4 ) { $L.s4, $L.s4_1 } else { 'No match. Variant', "doesn't exist!" })

            Write-Host "$text" -ForegroundColor Yellow

            Start-Sleep -Milliseconds 1500

            # Выходим из функции, чтобы перезапустить последнее указанное меню в переменной $isStartMenu,
            # в бесконечном цикле перезапуска всех меню, в главном скрипте.
            # Обеспечивает новую точку входа, вместо открытия новых функций внутри текущей функции без завершения.
            Return
        }

        try
        {
            # Поочередный перебор всех вариантов выбора из раздела Selection.
            foreach ( $Option in $Selection.Keys )
            {
                # Если выбор пользователя совпал с существующим вариантом выбора.
                if ( $Option -eq $InputMenu )
                {
                    # Создаем массив со всем строками из выбранного варианта для выполнения.
                    [string[]] $SelectString = $Selection.$Option

                    # Для каждой строки - элемента массива из выбранного варианта раздела Selection.
                    foreach ( $Section in $SelectString )
                    {
                        # Если элемент массива со строкой содержит символ '&', то есть возможно указана команда (функция или командлет) для выполнения.
                        if ( $Section -match "[&]" )
                        {
                            # Пробуем разделить строку по символам '|', отсекая пробелы по краям.
                            [array] $CommandString = $Section.split('|').Trim()

                            # Если после попытки разделения строка имеет две части.
                            if ( $CommandString.Count -eq 2 )
                            {
                                # Сохраняем имя команды из первой части, отсекая пробелы и символы '&' по краям.
                                [string] $CommandName = $CommandString[0].Trim(' &')

                                # Проверяем существование команды.
                                [psobject] $FoundCommandName = Get-Command -CommandType Function,Cmdlet -Name $CommandName -ErrorAction SilentlyContinue

                                # Если команда существует.
                                if ( $FoundCommandName )
                                {
                                    # Берем параметры команды из второй после символа '|', отсекая пробелы по краям.
                                    [string] $CommandParameters = $CommandString[1].Trim()

                                    # Если есть параметры, добавляем их к строке с именем команды.
                                    if ( $CommandParameters ) { [string] $CommandString = "$CommandName $CommandParameters" }
                                    else { [string] $CommandString = "$CommandName" }

                                    # Создаем скриптблок, для возможности выполнения строки с командой и параметрами.
                                    [psobject] $Command = [scriptblock]::Create( $CommandString )

                                    # Write-Host "  Выполняем команду: '$CommandName'" -ForegroundColor Cyan

                                    # Запускаем на выполнение скриптблок с именем команды, и если есть ее параметрами.
                                    & $Command
                                }
                                else
                                {
                                    $text = if ( $L.s5 ) { $L.s5 } else { 'There is no this command (Function or Commandlet)' }
                                    Write-Host "  $text`: '$CommandName'" -ForegroundColor Yellow

                                    Start-Sleep -Milliseconds 2000
                                }
                            }
                            elseif ( $CommandString.Count -eq 1 )
                            {
                                # Если строка с командой не разделилась по символу '|', то есть нет такого символа.

                                # Сохраняем имя команды, отсекая пробелы и символ '&' по краям.
                                [string] $CommandName = $CommandString.Trim(' &')

                                # Проверяем существования команды.
                                [psobject] $FoundCommandName = Get-Command -CommandType Function,Cmdlet -Name $CommandName -ErrorAction SilentlyContinue

                                # Если команда существует.
                                if ( $FoundCommandName )
                                {
                                    # Write-Host "  Выполняем команду: '$CommandName'" -ForegroundColor Cyan

                                    # Выполняем команду через оператор вызова '&', который выполняет строку как команду.
                                    & $CommandName
                                }
                                else
                                {
                                    $text = if ( $L.s5 ) { $L.s5 } else { 'There is no this command (Function or Commandlet)' }
                                    Write-Host "  $text`: '$CommandName'" -ForegroundColor Yellow

                                    Start-Sleep -Milliseconds 2000
                                }
                            }
                            else
                            {
                                # Иначе элемент массива со строкой имеет символы '&' и '|', то есть указана функция для выполнения и параметры,
                                # А строка разделилась больше чем на 2 части, просто вывести на экран как текст,
                                # Так как либо это просто текст, либо неправильно указана функция для выполнения.

                                Write-Host "  $Section" -ForegroundColor Yellow
                            }
                        }
                        elseif ( $Section -match "[$]" )
                        {
                            # Если элемент массива со строкой имеет символ доллара '$', то есть возможно указано Меню для перехода.

                            # Сохраняем имя возможного меню, отсекая пробелы по краям.
                            [string] $PossibleMenuName = $Section.Trim()

                            # Проверяем существование переменной по имени меню, без символа '$'.
                            [psobject] $MenuVarFound = Get-Variable -Name $PossibleMenuName.Trim(' $') -ErrorAction SilentlyContinue

                            # Если переменная существует, с указанным именем меню.
                            if ( $MenuVarFound )
                            {
                                # Получаем тип переменной с возможным меню.
                                [string] $MenuVarType = $MenuVarFound.Value.GetType().Name

                                # Если переменная хэш-таблица.
                                if ( $MenuVarType -eq 'Hashtable' )
                                {
                                    # Создаем объект скрипт блок, из строки с именем указанного меню,
                                    # для возможности выполнения ее как объект [Hashtable].
                                    [psobject] $ScriptBlockMenu = [scriptblock]::Create( $PossibleMenuName )

                                    # Задаем меню для запуска, переведя в объект [Hashtable] из переменной [scriptblock] через оператор вызова '&',
                                    # который выполняет строку как команду. Получаем нужное меню, указанное в строке ввыполнения текущего меню.
                                    $isStartMenu = & $ScriptBlockMenu

                                    # Задаем общую глобальную переменную $isStartMenu для всех меню, и имя меню в его Description,
                                    # для получения имени в главном меню, для его переподключения, для обновления переменных в нём.
                                    Set-Variable -Name isStartMenu -Value $isStartMenu -Description $PossibleMenuName -Scope Global -Option AllScope -Force

                                    Start-Sleep -Milliseconds 600

                                    # Выходим из функции, чтобы перезапустить меню, заданное только что в переменной $isStartMenu,
                                    # в цикле перезапуска всех меню, в главном скрипте. Обеспечивает новую точку входа,
                                    # вместо открытия внутри функций без завершения.
                                    Return
                                }
                                else
                                {
                                    $text = if ( $L.s6 ) { $L.s6 } else { 'There is no such menu' }
                                    Write-Host "`n  $text`: '$PossibleMenuName'`n" -ForegroundColor Yellow

                                    Get-Pause

                                    # Выходим из функции, чтобы перезапустить последнее указанное меню в переменной $isStartMenu,
                                    # в бесконечном цикле перезапуска всех меню, в главном скрипте.
                                    # Обеспечивает новую точку входа, вместо открытия новых функций внутри текущей функции без завершения.
                                    Return
                                }
                            }
                            else
                            {
                                $text = if ( $L.s6 ) { $L.s6 } else { 'There is no such menu' }
                                Write-Host "`n  $text`: '$PossibleMenuName'`n" -ForegroundColor Yellow

                                Get-Pause

                                # Выходим из функции, чтобы перезапустить последнее указанное меню в переменной $isStartMenu,
                                # в бесконечном цикле перезапуска всех меню, в главном скрипте.
                                # Обеспечивает новую точку входа, вместо открытия новых функций внутри текущей функции без завершения.
                                Return
                            }
                        }
                        elseif ( $Section -eq 'Exit' )
                        {
                            # Если строка элемента массива содержит текст 'Exit', то завершить выполнение скрипта, выйти.

                            Write-Host '  Exit' -ForegroundColor DarkGray

                            Start-Sleep -Milliseconds 1000

                            Exit
                        }
                        else
                        {
                            # Иначе просто вывести на экран указанный текст, как сообщение.

                            Write-Host "  $Section" -ForegroundColor Yellow
                        }
                    }
                }
            }
        }
        catch
        {
            $text = "`n  {0}: '$NameThisFunction', {1}: '$InvokeString'`n  {2}: [$InputMenu], {3}: '$Section'`n " -f
                $(if ( $L.s7 ) { $L.s7, $L.s7_1, $L.s7_2, $L.s7_3 } else { 'Error in function', 'command', 'The problem in the choice', 'and the execution of the string' })

            Write-Warning "$text"

            throw
        }
    }
}


<#
.SYNOPSIS
 Обрабатывает массив из строк для вывода на экран текста,
 и/или результа выполнения функций в одну строку или просто выполнить команду (Функцию или Командлет).
 Сделана для обработки строк подготовленных меню для AutoSettings или RepackWIM,
 для вывода на экран внутри меню.

.DESCRIPTION
 Обрабатывает массив из строк поэлементно, собирая в одну строку
 результат выполнения команды и/или текст, с указанными параметрами цвета текста и цвета фона.
 И передает собранную строку функции Write-HostColor для раскраски цветом всей строки с результатами выполнения команды,
 или просто выводит на экран результат выполнения команды или текст.

 Формат массива строк или одной строки для указания команд с параметрами, или просто текста,
 с параметрами цвета для вывода:

 Указание сегментов с функциями или командлетами для выполнения через символ '&': '& CommandName1', '& CommandName2'
 Указание раскраски цветом результата выполнения команды: '#Yellow:DarkRed# & FunctionName'
 Указание раскраски цветом результата выполнения команды с параметрами: '#Yellow:DarkRed# & CommandName | -Test Param1, Param2, и т.д.'
 Без раскраски цветом результата выполнения команды с параметрами: '& CommandName | -Test Param1, Param2, и т.д.',
 но параметры цвета можно добавлять в вывод самой функции.

 После указания команды можно указывать только параметры для команды,
 для добавления следующего результата или текста, отделять в отдельный сегмент массива через запятую.

 Перед командой можно добавлять части текста с разной раскраской.
 В одном сегменте только одна команда с/без параметров!

 Символы решетки '#' не будут выведены на экран нигде, так как они являются разделителями для параметров цвета!

 Пример  1: 'Текст1'
 Результат: Текст1

 Пример  2: 'Текст1', 'Текст2', 'и т.д.'
 Результат: Текст1Текст2и т.д.

 Пример  3: 'Текст1', ' Текст2 ', 'и т.д.'
 Результат: Текст1 Текст2 и т.д.

 Пример  4: 'Текст1', ' #Green#Текст2# ', 'и т.д.'
 Результат: Тоже, но 'Текст2' будет зеленый.

 Пример  5: '#Yellow:DarkRed# & CommandName | Param1, Param2', '#:Green# Тут зеленый фон #Blue# Этот текст синий. #'
 Результат: <Резутатат команды желтый на темнокрасном фоне> <Тут зеленый фон>  <Этот текст синий>.

.PARAMETER Line
 Принимает Массив [array] со строками.

.INPUTS
 Массив [array] cо строками.

.OUTPUTS
 Вывод на экран текста или результата выполнения команды с раскраской.

.EXAMPLE
    Show-MenuLine 'Текст1', ' #Green#Текст2# ', 'и т.д.'

    Описание
    --------
    Выведет на экран весь массив в одну строку, и 'Текст2' будет зеленый.

.EXAMPLE
    Show-MenuLine '& CommandName | -Test Param1, Param2'

    Описание
    --------
    Просто запустит выполнение команды, без каких либо вмешательств,
    Так как одна строка с одной командой, без добавления параметров цвета или текста,
    а это указывает просто выполнить команду.

.NOTES
 ==========================================
     Автор:  westlife (ru-board)  v.1.0
      Дата:  01-08-2018
 ==========================================

#>
Function Show-MenuLine {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
       [Parameter( Mandatory = $true, Position = 0 )]
       [array] $Line
    )

    Begin
    {
        # Получение имени этой функции.
        [string] $NameThisFunction = $MyInvocation.MyCommand.Name

        # Получение перевода
        [hashtable] $L = $Lang.$NameThisFunction

        [string] $OnlyOneCommand = ''
        # Разделяем переданный массив строк по символу '&'.
        [array] $SplitAllLine = $Line.split('&')

        # Если массив состоит из 2 элементов, и первый элемент пустой, то создаем переменную,
        # что передана одна строка с одной командой, без указания раскраски или текста для выполнения ее самостоятельно,
        # без каких либо вмешательств, как есть (цвета добавлять в таких случаях можно в вывод самой указанной функции!).
        if ( $SplitAllLine.Count -eq 2 -and $SplitAllLine[0] -eq '' ) { $OnlyOneCommand = 'Yes' }

        [string] $MenuLineResult = $null
    }

    Process
    {
        # Для каждого элемента из переданного массива из строк.
        foreach ( $String in $Line )
        {
            # Если элемент содержит символ '&'. То есть возможно указана команда (Функция или Командлет).
            if ( $String -match "[&]" )
            {
                # Разделяем элемент строку по символу '&'.
                [array] $SplitLine = $String.split('&')

                # Если элемент строка разделилась на 2 элемента.
                if ( $SplitLine.Count -eq 2 )
                {
                    # Берем вторую часть - название команды, и разделяем результат по символу '|'.
                    [array] $CommandString = $SplitLine[1].split('|')

                    # Если элемент строки с командой разделился на 2 элемента по символу '|'.
                    # Это значит, возможно, переданы параметры для команды.
                    if ( $CommandString.Count -eq 2 )
                    {
                        # Берем имя команды из первой части до символа '|', отсекая пробелы и символы '#' по краям.
                        [string] $CommandName = $CommandString[0].Trim(' #')

                        # Берем параметры команды из второй после символа '|', отсекая символы '#' по краям, оставив пробелы.
                        [string] $CommandParameters = $CommandString[1].Trim('#')
                    }
                    else
                    {
                        # Иначе команда без параметров, просто берем имя команды, отсекая пробелы и символы '#' по краям.
                        [string] $CommandName = $CommandString.Trim(' #')
                    }

                    # Проверяем существования команды.
                    [psobject] $FoundCommandName = Get-Command -CommandType Function,Cmdlet -Name $CommandName -ErrorAction SilentlyContinue

                    # Если команда существует.
                    if ( $FoundCommandName )
                    {
                        # Если есть параметры, добавляем их к строке с именем команды.
                        if ( $CommandParameters ) { [string] $CommandString = "$CommandName $CommandParameters" }
                        else { [string] $CommandString = "$CommandName" }

                        # Создаем скриптблок, для возможности выполнения строки с командой и параметрами.
                        [psobject] $Command = [scriptblock]::Create( $CommandString )

                        # Если всего одна строка с командой, без текста и параметров цвета.
                        if ( $OnlyOneCommand ) { Break } # Выход из перебора foreach. Выполнение команды с параметрами запустится в блоке End.

                        # Создаем переменную Объект - с результатом выполнения указанной команды с параметрами, если они были.
                        try { [psobject] $InvokeCommand = & $Command }
                        catch
                        {
                            [string] $InvokeCommand = "{0}`: '$CommandName'" -f $(if ( $L.s1 ) { $L.s1 } else { 'Error in command' })
                        }

                        # Берем первую часть, параметр цвета для вывода, после разделения строки по символу '&', отсекая пробелы в конце.
                        $TestColor = $SplitLine[0].TrimEnd()

                        # Если параметр подходит под формат записи цвета текста и цвета фона, или только цвета фона.
                        if ( $TestColor -match "#([a-z]{3,11})?:[a-z]{3,11}#" )
                        {
                            $MenuLineResult += "$TestColor $InvokeCommand #"   # Добавляем в строку результат Выполнения указанной команды, с добавленными параметрами цвета текста и фона и пробелов по краям.
                        }
                        # Если параметр подходит под формат записи только цвета текста.
                        elseif ( $TestColor -match "#[a-z]{3,11}#" )
                        {
                            $MenuLineResult += "$TestColor$InvokeCommand#"  # Добавляем в строку результат Выполнения указанной команды, с добавленными параметрами цвета текста.
                        }
                        else { $MenuLineResult += $InvokeCommand }   # Иначе добавляем в строку только результат Выполнения указанной команды без добавления цвета.
                    }
                    else { $MenuLineResult += $String }    # Если название команды не найдено среди существующих команд функций или командлетов, добавляем в строку как текст.
                }
                else { $MenuLineResult += $String }    # Если в строке между '' указано больше 1 символа '&', добавляем в строку как текст.
            }
            else { $MenuLineResult += $String }    # Если в строке между '' не содержится символ '&', т.е. команда не указана, добавляем в строку как текст.
        }
    }

    End
    {
        # Если команда была указана одна без параметров цвета, и команда существует.
        if ( $FoundCommandName -and $OnlyOneCommand -eq "Yes" )
        {
            # Выполняем указанную команду, без каких либо добавлений и обрабоки цвета,
            # так как была указана всего одна строка с одной функцией, без добавлений текста или цвета.
            & $Command
        }
        else
        {
            # Иначе передаем собранную строку с результатами выполнения указанных команд,
            # для вывода на экран с раскраской вывода, указанными параметрами цвета текста и/или цвета фона.
            Write-HostColor $MenuLineResult
        }
    }
}

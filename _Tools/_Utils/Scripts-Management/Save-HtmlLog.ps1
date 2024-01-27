
<#
.SYNOPSIS
 Выводит в файл HTML весь текст из консоли,
 в том же виде, со всеми параметрами цвета.

.DESCRIPTION
 Функция написана для скриптов AutoSettingsPS и RepackWIMPS.

 Шрифт, его размер и межстрочный интервал можно задать свой, по умолчанию задан 0.86em, Consolas, line-Height 1.2
 Параметры значений цвета для HTML заданы внутри функции,
 Эти все параметры соответствуют настройкам консоли PS в ярлыках для выше указанных скриптов.
 Вызывав функцию, весь текст из окна консоли, до точки вызова функции, сохранится в файл.
 Если не указан параметр NotAppend, текст будет добавляться к существующему при каждом вызове функции.
 Если не указать файл, то он будет сохранен в папке %Temp% пользователя, с заданным по умолчанию именем.

 Принцип работы функции:
 Получает буфер консоли по заданным нужным координатам, разбивает его на таблицу с ячейками,
 перебирает все ячейки по очереди слева на право сверху вниз.
 Берет из ячеек символы и параметры цвета, и записывает их в блок <pre>,
 проверяя предыдущие параметры цвета ячейки.
 Если попадается измененный параметр цвета ячейки, то создает для таких символов
 дополнительный блок <span> с этими новыми параметрами цвета. И так для каждой ячейки.

 Все действия происходят в памяти, через массив:
 Для начала файла HTML добавляются начальные теги с общими параметрами цвета фона и текста.
 Далее в середину добавляется один блок <pre>, в который и заносятся все символы из консоли,
 с собственными блоками <span> при необходимости, в которых указываются индивидуальные параметры цвета символов.
 Для конца файла задается отдельная строка с закрывающими тегами,
 которая играет роль при добавлении к файлу информации, заменой ее на новые данные.
 По завершении все записывается в файл одним действием, при каждом вызове функции.

 Если не указано перезаписывать файл, то берется весь текст из файла в массив, если он есть,
 делается замена в массиве последней отдельной строки с закрывающими тегами на текст из текущего вывода,
 без начальных открывающих тегов, но со всеми закрывающими тегами.
 Дополненный текст соединяется с существующим, в одно действие, и идет запись всего в файл.

.PARAMETER FileHTML
 Полный путь к нужному файлу HTML для сохранения текста из консоли.

.PARAMETER FontSize
 Размер шрифта, по умолчанию задано '0.86em'.

.PARAMETER FontName
 Название шрифта, по умолчанию задан 'Consolas'.

.PARAMETER lineHeight
 Межстрочный интервал, по умолчанию задан '1.2' (120% от размера шрифта).

.PARAMETER NotAppend
 Указывает функции перезаписывать существующий файл,
 если он есть. По умолчанию запись добавляется.

.PARAMETER NotSilent
 Указывает функции выводить информацию куда сохранен лог.

.PARAMETER AllBuffer
 Указывает сохранять весь текущий вывод буфера.
 Необходимо, когда нужно добавлять вывод к существующему,
 но вызов функции указывается после Clear-Host,
 например после вызова меню, обычно в них выполняются Clear-Host перед отображением.

.PARAMETER ShowSave
 Отображать временно инфо при сохранении консоли, пока сохраняется.
 Затем перевод курсора вверх на несколько заданных строк и затирание этого текста.

.INPUTS
 Текст с экрана консоли.

.OUTPUTS
 HTML файл.

.EXAMPLE
    Save-HtmlLog

    Описание
    --------
    Сохранит весь выведенный текст из окна консоли в файл из переменной $FileHtmlLogGlobal.
    Добавляя в существующий файл, если он есть. Буфер берётся с вычетом предыдущего сохранения.
    Задаст шрифт Consolas с размером '0.86em' - это ровняется размеру шрифта 16 в консоли.
    Если файл в $FileHtmlLogGlobal не задан, сохранит файл в папке %Temp% пользователя,
    c именем 'HtmlLOG-Текущая дата с секундами.html'

.EXAMPLE
    Save-HtmlLog -AllBuffer -ShowSave

    Описание
    --------
    Сохранит весь выведенный текст из окна консоли в файл из переменной $FileHtmlLogGlobal.
    Добавляя в существующий файл, если он есть. Буфер берётся с первой строки, т.е. с самого начала.
    С отображением информации о сохранении, пока сохраняется.
    Задаст шрифт Consolas с размером '0.86em' - это ровняется размеру шрифта 16 в консоли.
    Если файл в $FileHtmlLogGlobal не задан, сохранит файл в папке %Temp% пользователя,
    c именем 'HtmlLOG-Текущая дата с секундами.html'

.EXAMPLE
    Save-HtmlLog -FontName Arial -FontSize 8

    Описание
    --------
    Сохранит весь выведенный текст из окна консоли в файл из переменной $FileHtmlLogGlobal.
    Добавляя в существующий файл, если он есть.
    Задаст шрифт Arial с размером 8px (пикселей)
    Если файл в $FileHtmlLogGlobal не задан, сохранит файл в папке %Temp% пользователя,
    c именем 'HtmlLOG-Текущая дата с секундами.html'

.EXAMPLE
    Save-HtmlLog -FileHTML "D:\Log.html" -NotAppend

    Описание
    --------
    Сохранит весь выведенный текст из окна консоли в файл "D:\Log.html".
    Перезаписывая существующий файл, если он есть.
    Задаст шрифт Consolas с размером '0.86em' - это ровняется размеру шрифта 16 в консоли.

.NOTES
 =============================================================================
     Автор:  westlife (ru-board)   Версия 1.0
      Дата:  25-09-2018
       Доп:  Идею взял из функции get-buffer Автора Adrian Milliner 2006г.
 =============================================================================

 #>
Function Save-HtmlLog {

    [CmdletBinding( SupportsShouldProcess = $false )]
    Param(
        [Parameter( Mandatory = $false, Position = 0 )]
        [ValidatePattern( ".html$" )]
        [string] $FileHTML = $FileHtmlLogGlobal         # По умолчанию задана глобальная дефолтная переменная, если она есть.
       ,
        [Parameter( Mandatory = $false, Position = 1 )]
        [string] $FontSize = '0.86em'                   # По умолчанию размер шрифта '0.86em'.
       ,
        [Parameter( Mandatory = $false, Position = 2 )]
        [string] $FontName = 'Consolas'                 # По умолчанию шрифт 'Consolas'.
       ,
        [Parameter( Mandatory = $false, Position = 3 )]
        [string] $lineHeight = '1.2'                    # По умолчанию межстрочный интервал '1.2'.
       ,
        [Parameter( Mandatory = $false )]
        [switch] $NotAppend                             # Не добавлять. По умолчанию добавляется в файл, а не перезаписывается.
       ,
        [Parameter( Mandatory = $false )]
        [switch] $NotSilent                             # Не скрывать информацию куда сохраняется файл.
       ,
        [Parameter( Mandatory = $false )]
        [switch] $AllBuffer                             # Добавить весь вывод буфера, с 0 координаты.
       ,
        [Parameter( Mandatory = $false )]
        [switch] $ShowSave                              # Отображать временно инфо при сохранении консоли, пока сохраняется.
       ,
        [Parameter( Mandatory = $false )]
        [switch] $OnlyToVariable                        # Не сохранять. Добавить контент в глобальную переменную.
       ,
        [Parameter( Mandatory = $false )]
        [PSCustomObject] $OutputConsole                 # Данные консоли для добавления их в начало лога
    )

    Begin
    {
        # Получение имени этой функции.
        [string] $NameThisFunction = $MyInvocation.MyCommand.Name

        # Получение перевода
        [hashtable] $L = $Lang.$NameThisFunction
        [string] $text = ''

        # Перехват ошибок в блоке Begin или во всей функции, если один trap, для выхода из функции,
        # без отображения ошибки тут, и передача ее в глобальный trap для отображения и записи в лог.
        trap { break }

        # Если указано отображать временно инфо пока сохраняется.
        if ( $ShowSave )
        {
            #  [char] $Escape          = 27
                [int] $StringsExcl     = 2              # Количество последних строк для исключения из сохранения. Адаптированно под скрипт AutoSettings.
            #[string] $HideCursor      = "$Escape[?25l"
            #[string] $ShowCursor      = "$Escape[?25h"
            #[string] $ClearAfterCur   = "$Escape[0J"   # Очистка за курсором всех строк буфера.
            #[string] $PreviousLineCur = "$Escape[$StringsExcl`F"  # Перевод курсора на предыдущие строки.

            Write-Host "`n ■ ■ ■ " -ForegroundColor White -NoNewline

            $text = if ( $L.s1 ) { $L.s1 } else { 'Saving the console' }
            Write-Host "$text " -ForegroundColor Cyan -NoNewline

            $text = if ( $L.s1_1 ) { $L.s1_1 } else { 'wait ...' }
            #Write-Host "| $text $HideCursor" -ForegroundColor White
            Write-Host "| $text " -ForegroundColor White
            [console]::CursorVisible = $false
        }
        else { [int] $StringsExcl     = 0 }

        # Если есть глобальная переменная с данными консоли, запускаем функцию внтури себя для сохранения буфера в переменную
        # Нужно для сохранения первого меню в лог файл, а выполнение было именно с первым вызовом для сохранения лога, 
        # а не при первом вызове главного меню, так как есть задержка при обработке
        if ( $Global:FirstOutputConsole.Width )
        {
            $OutputConsole = [PSCustomObject] @{
                Width  = $Global:FirstOutputConsole.Width
                Height = $Global:FirstOutputConsole.Height
                BufferContents = $Global:FirstOutputConsole.BufferContents
            }
            $Global:FirstOutputConsole = $null
            Save-HtmlLog -OnlyToVariable -OutputConsole $OutputConsole
            $OutputConsole = $null
        }

        # Если переданы данные консоли
        if ( $OutputConsole.Width )
        {
            [int] $Width  = $OutputConsole.Width
            [int] $Height = $OutputConsole.Height
            $Cells = $OutputConsole.BufferContents
        }
        else
        {
            # Задаем размер текущего всего использованного буфера консоли: Ширина и Высота.
            [int] $Width  = $host.UI.RawUI.BufferSize.Width  # Ширина прямоугольника (И Правый край координат).
            [int] $Height = $host.UI.RawUI.CursorPosition.Y  # Высота прямоугольника (по положению курсора).

            # Далее задаем 4 координаты для получения всей области буфера или его части.

            # Нижний край, всегда равен всей высоте использованного буфера консоли.
            [int] $Bottom = $Height

            # Если указано не добавлять к сохраненной, или сохранить весь буфер,
            # то сохраняется или добавится вся текущая область использованного буфера.
            if ( $NotAppend -or $AllBuffer )
            {
                [int] $Top = 0

                # Задаем координаты сторон (краев) прямоугольной области по размеру всего использованного буфера окна консоли.
                # Левая, Верхняя, Правая, Нижняя. С вычетом снизу количества указанных строк.
                [int[]] $Area = 0, $Top, $Width, ( $Bottom - $StringsExcl )
            }
            else
            {
                # Иначе, если прошлый нижний край существует и больше нуля, и Меньше текущего нижнего края буфера.
                if (( $BottomOldGlobal -gt 0 ) -and ( $BottomOldGlobal -lt $Bottom ))
                {
                    # Изменяем Координаты консоли, убрав прошлую сохраненную верхнюю часть текущего буфера,
                    # Чтобы сохранить только новую часть буфера, после предыдущего сохранения.

                    # Задаем верхний край буфера консоли от прошлого нижнего края буфера.
                    [int] $Top = $BottomOldGlobal

                    # Задаем координаты сторон (краев) прямоугольной области по размеру буфера окна консоли: Левая, Верхняя, Правая, Нижняя.
                    # С вычетом снизу количества указанных строк.
                    [int[]] $Area = 0, $Top, $Width, ( $Bottom - $StringsExcl )

                    # Задаем новую высоту буфера, так как верхний край смещён вниз от прошлого нижнего края.
                    # Вычитаем из всей высоты буфера текущий смещенный верхний край (бывший нижний край).
                    # Тоесть убираем верхнюю часть всего буфера, оставляя не сохраненную нижнуюю часть.
                    [int] $Height = ( $Height - $Top )
                }
                else
                {
                    [int] $Top = 0
                    # Иначе, задаём координаты консоли от самого верха буфера до курсора. То есть вся использованная область буфера.

                    # Задаем координаты сторон (краев) прямоугольной области по размеру всего использованного буфера окна консоли.
                    # Левая, Верхняя, Правая, Нижняя. С вычетом снизу количества указанных строк.
                    [int[]] $Area = 0, $Top, $Width, ( $Bottom - $StringsExcl )
                }
            }

            # Задаем координаты текущего нижнего края прямоугольника, как будущий верхний край, для отсчета нужной высоты следующего буфера,
            # при повторном вызове функции. Если необходимо добавление к файлу с уже сохраненной консолью.
            # С вычетом снизу количества указанных строк.
            Set-Variable -Name BottomOldGlobal -Value ( $Bottom - $StringsExcl ) -Scope Global -Force -Option ReadOnly

            # Создаем Rectangle - экземпляр класса прямоугольной области по координатам нужного размера буфера окна консоли.
            $Rectangle = [Management.Automation.Host.Rectangle]::new($Area[0],$Area[1],$Area[2],$Area[3])

            # Получаем все ячейки с символами и их параметрами из буфера консоли, согласно координатам полученной прямоугольной области.
            $Cells = $host.UI.RawUI.GetBufferContents($Rectangle)
        }

        # Установка цвета по умолчанию для всех переменных.
        [string] $PreviousCellFG = $DefaultFG = $host.UI.RawUI.ForegroundColor
        [string] $PreviousCellBG = $DefaultBG = $host.UI.RawUI.BackgroundColor

        # Карта для замены некоторых символов в тексте на имена или числовой код спецсимволов HTML (ссылки на эти символы),
        # чтобы исключить проблемы при интерпретации их браузером.
        [hashtable] $CellCharTranslateMap = @{
            [char] '<'  = '&lt;'
            [char] '>'  = '&gt;'
            [char] '\'  = '&#x5c;'
            [char] "'"  = '&#39;'
            [char] "`"" = '&#34;'
            [char] '&'  = '&amp;'
        }

        # Если скрипт работает в консоли, где цвет фона и текста консоли установлены по умолчанию
        # на DarkMagenta и DarkYellow со специальными параметрами цвета. Устанавливаем эти цвета.
        if ( $DefaultBG -eq 'DarkMagenta' )
        {
            [string] $DarkMagenta = 'rgb(1,36,86)'     #012456 Подмененный по умолчанию цвет фона консоли, на темно-синий.
            [string] $DarkYellow  = 'rgb(238,237,240)' #EEEDF0 Подмененный по умолчанию цвет текста консоли, на светло-серый.
        }
        # Иначе задаем нормальный цвет.
        else
        {
            [string] $DarkMagenta = 'rgb(130,50,130)'  #823282 Нормальный темно фиолетовый цвет.
            [string] $DarkYellow  = 'rgb(150,140,0)'   #968C00 Нормальный темно желтый цвет.
        }

        # Карта для замены консольных названий цвета
        # на цвет в формате RGB Decimal: rgb(153,153,0) для HTML.
        # Так как такой же формат цвета и в ярлыках к консоли для AutoSettingsPS и RepackWIMPS (удобнее).
        # Можно указать цвет и в HEX: #0033AA или #03A
        [hashtable] $ColorMapRGB = @{
                'Black'       = 'rgb(0,0,0)'       #000000
                'DarkBlue'    = 'rgb(0,60,170)'    #003CAA
                'DarkGreen'   = 'rgb(0,100,40)'    #006428
                'DarkCyan'    = 'rgb(0,140,140)'   #008C8C
                'DarkRed'     = 'rgb(130,40,0)'    #822800
                'DarkMagenta' = $DarkMagenta
                'DarkYellow'  = $DarkYellow
                'Gray'        = 'rgb(190,190,190)' #BEBEBE
                'DarkGray'    = 'rgb(100,100,100)' #646464
                'Blue'        = 'rgb(0,150,255)'   #0096FF
                'Green'       = 'rgb(0,240,40)'    #00F028
                'Cyan'        = 'rgb(0,255,255)'   #00FFFF
                'Red'         = 'rgb(255,40,0)'    #FF2800
                'Magenta'     = 'rgb(223,40,223)'  #DF28DF
                'Yellow'      = 'rgb(255,245,0)'   #FFF500
                'White'       = 'rgb(255,255,255)' #FFFFFF
        }

        # Если не передан файл для сохранения или не назначен $FileHtmlLogGlobal по умолчанию, сохранит лог в папку Temp пользователя.
        if ( $FileHTML -eq '' )
        {
            # Задаем глобальную переменную, с указанием файла HTML для сохранения.
            # Глобальная, для возможности дописывать в тот же файл, если не указано перезаписывать существующий.
            # Расскрываем короткие имена в пути
            [string] $TempPath = $([System.IO.Path]::GetFullPath($env:TEMP))

            [string] $Global:FileHtmlLogGlobal = "$TempPath\HtmlLOG-$(Get-Date -Format "yyyyMMdd-HHmmss").html"

            # Задаем текущий файл для записи из только что созданной глобальной переменной.
            $FileHTML = $Global:FileHtmlLogGlobal
        }

        # Если нет параметра "Не добавлять", то будет добавлен вывод в файл с уже сохраненной консолью, если он существует, иначе запишется весь вывод в консоль.
        if ( -not $NotAppend )
        {
            if ( -not $Global:FileHtmlContentGlobal -like '</pre></body></html>' )
            {
                # Обнуляем глобальную переменную.
                [string] $Global:FileHtmlContentGlobal = $null

                # Если указанный файл существует.
                if ( Test-Path -LiteralPath $FileHTML -PathType Leaf -ErrorAction SilentlyContinue )
                {
                    # Получаем текст из файла в строчный массив, чтобы не было в одну строку.
                    [string[]] $Global:FileHtmlContentGlobal = Get-Content -LiteralPath $FileHTML -ErrorAction SilentlyContinue
                }

                # Если полученный контент неправильный, нет строки '</pre></body></html>', обнуляем контент.
                if ( -not $Global:FileHtmlContentGlobal -like '</pre></body></html>' )
                {
                    [string] $Global:FileHtmlContentGlobal = $null
                }
            }
        }
        else { [string] $Global:FileHtmlContentGlobal = $null }
    }

    Process
    {
        # Перехват ошибок в блоке Process или во всей функции, если один trap, для выхода из функции,
        # без отображения ошибки тут, и передача ее в глобальный trap для отображения и записи в лог.
        trap { break }

        # Если текст из файла не получен, его нет или задано перезаписывать файл.
        if ( -not $Global:FileHtmlContentGlobal )
        {
            # Добавляем строку с заголовком для HTML, с параметрами для head и body, с переводом на новую строку.
            [string] $Out = "<html>`r`n<head><meta charset='utf-8'></head>`r`n<body style='background-color: $($ColorMapRGB[[string] $DefaultBG ]); margin: 10px; display: block'>`r`n"

            # Добавляем строку с началом блока <pre> - Такой блок указывает браузеру
            # отображать предварительно форматированный текст, не изменяя его, как есть, с переводом на новую строку.
            [string] $LineHTML = "<pre style='color: $($ColorMapRGB[[string] $DefaultFG ]); font: $FontSize $FontName; line-height: $lineHeight'>`r`n"
        }

        # Далее обработка всех указанных ячеек буфера консоли...

        # Для каждого ряда строк по всей высоте буфера консоли до курсора.
        for ( [int] $Row = 0 ; $Row -lt $Height ; $Row++ )
        {
            # Для каждого столбца (ячейки) в рядах строк по всей ширине буфера консоли.
            for ( [int] $Column = 0 ; $Column -lt $Width ; $Column++ )
            {
                # Получаем данные из текущей ячейки по координатам: Сверху, Слева.
                [psobject] $Cell = $Cells[$Row,$Column]

                # Получаем параметры цвета из текущей ячейки.
                [string] $CellCurrentFG = $Cell.ForegroundColor
                [string] $CellCurrentBG = $Cell.BackgroundColor

                # Если параметры цвета FG или BG от предыдущей ячейки не совпадают с параметрами цвета FG или BG текущей ячейки.
                # Поэтому далее нужно будет закрыть тег <span>, если тег был установлен.
                if (( $PreviousCellFG -ne $CellCurrentFG ) -or ( $PreviousCellBG -ne $CellCurrentBG ))
                {
                    # Если параметры цвета от предыдущей ячейки не совпадают с цветом по умолчанию,
                    # То закрыть тег <span> в случае, только если предыдущие параметры цвета не были по умолчанию.
                    if (( $PreviousCellFG -ne $DefaultFG ) -or ( $PreviousCellBG -ne $DefaultBG ))
                    {
                        # Добавляем закрытие тега <span> к предыдущему строчному элементу с текстом,
                        # так как следующие символы в текущей строке будут с другими параметрами цвета,
                        # без перевода на новую строку.
                        [string] $LineHTML += '</span>'

                        # Сброс цвета предыдущей ячейки по умолчанию.
                        [string] $PreviousCellFG = $DefaultFG
                        [string] $PreviousCellBG = $DefaultBG
                    }

                    # Если параметры цвета текущей ячейки не совпадают с параметрами цвета букв или фона по умолчанию (страницы).
                    if (( $CellCurrentFG -ne $DefaultFG ) -or ( $CellCurrentBG -ne $DefaultBG ))
                    {
                        # Добавляем в строку новый строчный тег <span> для символов,
                        # с указанием своих параметров цвета, без перевода на новую строку.
                        # Если цвет фона ячейки совпадает с фоном по умолчанию (страницы), задаем только цвет букв, иначе задаем и цвет фона ячейки.
                        if ( $CellCurrentBG -eq $DefaultBG )
                        {
                            [string] $LineHTML += "<span style='color: $($ColorMapRGB[[string] $CellCurrentFG ])'>"
                        }
                        else
                        {
                            [string] $LineHTML += "<span style='color: $($ColorMapRGB[[string] $CellCurrentFG ]); background-color: $($ColorMapRGB[[string] $CellCurrentBG ])'>"
                        }
                    }

                    # Задаем параметры цвета из текущей ячейки для сравнения со следующей ячейкой.
                    [string] $PreviousCellFG = $CellCurrentFG
                    [string] $PreviousCellBG = $CellCurrentBG
                }

                # Далее будет записываться символ в строку.
                # Так как необходимость добавления тега <span> с параметрами цвета проверена, и добавлена, если необходимо.

                # Получаем текущий символ из текущей ячейки таблицы буфера.
                [string] $CellChar = $Cell.Character

                # Сверяем текущий символ с картой замены символов.
                [string] $CellCharReplace = $CellCharTranslateMap[$CellChar]

                # Если измененный символ существует, то есть совпал с вариантом для замены.
                if ( $CellCharReplace )
                {
                    # Меняем текущий символ на измененный.
                    $CellChar = $CellCharReplace
                }

                # Добавляем текущий символ в текущую строку в блок '<span>' для вывода в HTML.
                [string] $LineHTML += $CellChar
            }

            # Далее, после заполнения всех символов из всей текущей строки по всей ширине буфера консоли.

            # Добавляем текущую строку с текстом и параметрами к массиву для вывода в HTML,
            # с очисткой ненужных пробелов в конце строки, и добавлением перехода на новую строку, так как конец строки.
            $Out += "{0}`r`n" -f $LineHTML.TrimEnd()

            # Сбрасываем переменную с текущей строкой, для возможности добавления следующей строки в следующем цикле for.
            [string] $LineHTML = ''
        }

        # Если после завершения обработки всех строк, предыдущий цвет ячейки не совпадает с параметрами цвета по умолчанию.
        # Такое может произойти, если было изменение параметров цвета через, например, $host.UI.RawUI.ForegroundColor = "Red",
        # использованного в ходе выполнения скрипта.
        if (( $CellCurrentFG -ne $DefaultFG ) -or ( $CellCurrentBG -ne $DefaultBG ))
        {
            # Добавляем закрытие тега <span> для последней строки в блоке <pre>,
            # для обозначения конца строки, с измененными параметрами цвета.
            $Out += '</span>'
        }

        # Добавляем завершающую строку к массиву для вывода в HTML, со всеми закрывающими тегами.
        # Эта строка также служит для замены на добавляемый вывод консоли в существующий файл.
        $Out += '</pre></body></html>'
    }

    End
    {
        # Перехват ошибок в блоке End или во всей функции, если один trap, для выхода из функции,
        # без отображения ошибки тут, и передача ее в глобальный trap для отображения и записи в лог.
        trap { break }

        # Если глобальная переменная существует, с предыдущим выводом консоли.
        if ( $Global:FileHtmlContentGlobal )
        {
            # Добавляем к массиву с текстом, полученного из существующего лога, текст из текущей части окна консоли,
            # Заменяя последнюю строку массива новой частью текста окна консоли, которая без начала тегов <html>, <head> и <pre>.
            $Out = $Global:FileHtmlContentGlobal.Replace('</pre></body></html>',$Out)
        }

        # Добавляем весь полученный или соединенный вывод консоли в глобальную переменную,
        # чтобы не получать его из файла, если будет добавление к существующему файлу.
        $Global:FileHtmlContentGlobal = $Out

        if ( $OnlyToVariable ) { Return }

        # Сохраняем весь полученный или соединенный вывод консоли в лог файл, с перезаписью, с кодировкой UTF-8 с BOM.
        try { Out-File -InputObject $Out -LiteralPath $FileHTML -Encoding utf8 -Force -ErrorAction Stop }
        catch
        {
            # Если нет доступа на запись к директории скрипта, сохранить файл в папке темп пользователя
            # Расскрываем короткие имена в пути
            [string] $TempPath = $([System.IO.Path]::GetFullPath($env:TEMP))

            $FileHTML = "$TempPath\$(Split-Path $FileHTML -Leaf)"

            try { Out-File -InputObject $Out -LiteralPath $FileHTML -Encoding utf8 -Force -ErrorAction Stop }
            catch { throw }
        }

        # Если было отображение инфо пока сохраняется, перевод курсора на строку выше,
        # и затирание всего отображаемого текста за курсаром после завершения сохранения, для стирания временно отображаемого текста.
        if ( $ShowSave )
        {
            # Write-Host "$PreviousLineCur$ClearAfterCur$ShowCursor" -NoNewline

            # Работает в lagacy console mode и W7
            #$s = 1 # строк для затирания >= 1  $StringsExcl
            [Console]::WriteLine();
            [console]::SetCursorPosition(0, [console]::CursorTop - $StringsExcl)
            [console]::WriteLine([String]::new(' ', [console]::WindowWidth-1) * $StringsExcl);  # [console]::Write( не оставлять в конце 1 пустую строку
            [console]::SetCursorPosition(0, [console]::CursorTop - $StringsExcl)
            [console]::CursorVisible = $true
        }

        # Если указано не скрывать вывод информации куда сохранен файл.
        if ( $NotSilent )
        {
            $text = if ( $L.s2 ) { $L.s2 } else { 'The console output is saved in' }
            Write-host " $text`: " -ForegroundColor DarkGreen -NoNewline
            Write-host "'$FileHTML'" -ForegroundColor DarkGray
        }
    }
}

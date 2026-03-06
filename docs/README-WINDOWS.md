[English](#english) | [Русский](#русский)

---

# English

## Security and transparency
You can remove digital signatures from my files (use [UnSign ](https://github.com/SV-Foster/UnSign) or [SigRemove](https://dennisbabkin.com/sigremover/)). Repeat this with the original files from the NVIDIA distribution. Compare the files byte by byte (`fc /b original.dll patched.dll`). You will see that the files are identical, only a small number of bytes have changed. In this regard, I can't remove the "virus" (which doesn't exist) from the driver. Please report the false positive to your antivirus manufacturer.

If you don't trust me and want to patch the driver by yourself, see [how to use patcher](/docs/README-PATCHER-WINDOWS.md).

## Usage
It's recommended to use Windows 11 because it has an updated mechanism for switching between multiple video cards.

1. Download patched files from [releases](https://github.com/dartraiden/NVIDIA-patcher/releases) (you can find an archive of previous versions [here](https://cloud.mail.ru/public/ihU3/CpmTAFWQo)).

First, select the row with your "mining" card, then the column depending on what device you are using to display the image on the monitor.

|                | Internal CPU graphics | Discrete graphics<br>(AMD) | Discrete graphics<br>(NVIDIA Turing and newer) | Discrete graphics<br>(NVIDIA Maxwell — Pascal) | Discrete graphics<br>(NVIDIA pre-Maxwell) | SLI Setup     |
|----------------|-----------------------|----------------------------|------------------------------------------------|------------------------------------------------|-------------------------------------------|-----------|
| P1XX           | 582.28                | 582.28                     | 581.94                                         | 582.28                                         | 472.12                                    | 446.14     |
| CMP and others | 595.76                | 595.76                     | 595.76                                         | 581.94                                         | 472.12                                    | Not supported |

Turing = Series 20 (RTX 2xxx) and Series 16 (GTX 16xx).

Pascal = Series 10 (GTX 1xxx).

Maxwell = GTX 750 Ti, GTX 750, GTX 745, GTX 980 Ti, GTX 980, GTX 970, GTX 960, GTX 950.

pre-Maxwell = GTX 690, GTX 680, GTX 670, GTX 660 Ti, GTX 660, GTX 650 Ti BOOST, GTX 650 Ti, GTX 650, GTX 645, GT 640, GT 635, GT 630, GTX 780 Ti, GTX 780, GTX 770, GTX 760, GTX 760 Ti (OEM), GT 740, GT 730, GT 720, GT 710. Older NVIDIA graphics cards are not supported.

The patched driver comes in two versions:
* Regular;
* `NVENC-NvFBC-` prefixed ([removed](https://github.com/keylase/nvidia-patch/tree/master/win) restriction on maximum number of simultaneous NVENC video encoding; [enabled](https://github.com/keylase/nvidia-patch/tree/master/win/nvfbcwrp) NvFBC for all NvFBC-targeted applications).

**Attention: Do not use NVENC- prefixed package if your mining card does not have hardware NVENC support (for example, it is hardware disabled on P1XX-cards). In this case driver will cause problems (crashes) in applications supporting NVENC.**

2. Download the official driver package from the NVIDIA website.
3. Download [Display Driver Uninstaller](https://www.wagnardsoft.com/display-driver-uninstaller-ddu-) (DDU).
4. Unpack the official driver package with 7-Zip / WinRAR / etc.
5. Replace original files with patched ones.
6. Unplug the network cable / disable Wi-Fi on your PC and clean the installed NVIDIA driver with DDU. Reboot PC.
7. Run setup.exe.

Result:

![Screenshot of GPU-Z window](/docs/GPU-Z.png)

Now you can plug in the network cable / enable Wi-Fi back.

8.1. In Windows 10 open the NVIDIA control panel → 3D settings → Manage 3D settings → set "High-performance NVIDIA processor" as the preferred graphics processor:

![Screenshot of NVIDIA control panel](/docs/NVIDIA%20Manage%203D%20Settings.jpg) ![Screenshot of "Preferred graphics processor" option](/docs/High%20Performance%20NVIDIA%20Processor.jpg)

8.2. In Windows 11 open Settings → System → Display → Graphics → Change default graphic settings → set mining card as the default high-performance graphic adapter:

![Screenshot of "Default High-performance GPU" option](/docs/Windows%20Default%20High-performance%20GPU.png)

## SLI hack
It is possible to pair together different GPUs of similar generation/architecture to work together in SLI (Note: Mixing different VRAM sizes may cause some instability or stop SLI from functioning properly). It can also enable SLI on some non-SLI/Crossfire compatible motherboards, making it a replacement for the discontinued HyperSLI program (Note: The SLI support on non-multi-GPU motherboards is not guaranteed).

Mandatory requirements:
* Driver version 446.14 (exactly this version).
* The first three symbols of Device ID for both cards must match. Go to Windows Device Manager → Right-click on device → Properties → Switch to the "Details" tab →  Select "Hardware IDs" from the combo box.

As an example:  
NVIDIA_DEV.`118`5.098A.10DE = "NVIDIA GeForce GTX 660"  
NVIDIA_DEV.`118`5.106F.10DE = "NVIDIA GeForce GTX 760"

Thus, for example, GTX 1070 and GTX 1080 can work together, but GTX 960 and GTX 1060 cannot.

## Troubleshooting
* Problem: Antivirus software removes driver.  
Solution: Add the `C:\Windows\System32\DriverStore` directory to the exceptions of Windows Defender (or other antivirus you use). Reinstall the driver after that.

* Problem: A BSOD after installing the driver.  
Solution: Turn off the [Hardware Accelerated GPU Scheduling](https://www.howtogeek.com/756935/how-to-enable-hardware-accelerated-gpu-scheduling-in-windows-11/#enable-hardware-accelerated-gpu-scheduling-in-windows-11).

* Problem: DirectX 12 support is missing on the Haswell platform.
Solution: Do not use the integrated graphics, since [Intel has disabled DX12 support](https://www.techpowerup.com/288676/intel-disables-directx-12-api-loading-on-haswell-processors).

## Unlocking full x16 PCI-E lines on the CMP-cards
You need to [solder the missing elements near the PCI-E slot](https://www.youtube.com/watch?v=AlLid4uGxpw).

## Using ShadowPlay, also known as the NVIDIA overlay
Requires graphics card that supports NVENC.

### Recommended method: [NVIDIA App](https://www.nvidia.com/en-us/software/nvidia-app/)

### Alternative method: GeForce Experience

To use the ShadowPlay overlay to record gameplay, use the resource monitor or stream, you must follow these steps:
1. Download and install [GeForce Experience](https://www.nvidia.com/en-us/geforce/geforce-experience/download/) (no need to log in).
2. Go to the installation path of NVIDIA GeForce Experience, usually located at `C:\Program Files\NVIDIA Corporation\NVIDIA GeForce Experience`.
3. Once there, locate the executable named "NVIDIA Share.exe" and create a shortcut on your desktop.
4. Right-click on the created desktop shortcut, go to properties, and in the "Target" field at the end of the path, add ` --shadowplay` while ensuring there's a space as shown in the picture. Then click OK.

![Screenshot of NVIDIA Share shortcut](/docs/NVIDIA%20Share%20shortcut.png)

4. Now double-click on the shortcut, and you'll notice that nothing appears to happen. However, when you press `Alt+Z`, the ShadowPlay overlay will open.
Note: You do not need to double-click the shortcut again; this is a one-time setup. From now on, you can always open ShadowPlay by pressing `Alt+Z`.

![Screenshot of ShadowPlay](/docs/ShadowPlay.png)

---

# Русский

## Опасающимся за безопасность
Удалите цифровую подпись с предоставленных мною файлов (с помощью утилит типа [UnSign ](https://github.com/SV-Foster/UnSign) или [SigRemove](https://dennisbabkin.com/sigremover/)). Сделайте то же самое с оригинальными файлами из дистрибутива от NVIDIA. Побайтово сравните исходный и пропатченный файлы. Вы заметите, что изменены лишь несколько байтов. Таким образом, я не могу убрать «вирус» (которого не существует) из драйвера. Сообщите разработчику вашего антивируса о ложноположительном срабатывании.

Если вы хотите пропатчить драйвер самостоятельно, читайте [руководство по использованию патчера](/docs/README-PATCHER-WINDOWS.md).

## Установка
Рекомендуется использовать Windows 11, в которой улучшен механизм распределения нагрузки между несколькими видеокартами.

1. Скачайте пропатченные [файлы](https://github.com/dartraiden/NVIDIA-patcher/releases) (предыдущие версии, при необходимости, можно отыскать [здесь](https://cloud.mail.ru/public/ihU3/CpmTAFWQo)).

Чтобы определить требуемую версию драйвера, выберите вашу «майнинговую» карту в горизонтальной строке, затем выберите столбец в зависимости от того, через какое устройство выводите изображение на монитор.

|              | Встроенное видеоядро CPU | Видеокарта (AMD) | Видеокарта (NVIDIA Turing или новее) | Видеокарта (NVIDIA Maxwell — Pascal) | Видеокарта (NVIDIA до Maxwell) | SLI               |
|--------------|--------------------------|------------------|--------------------------------------|--------------------------------------|--------------------------------|-------------------|
| P1XX         | 582.28                   | 582.28           | 581.94                               | 582.28                               | 472.12                         | 446.14            |
| CMP и прочие | 595.76                   | 595.76           | 595.76                               | 581.94                               | 472.12                         | Не поддерживается |

Turing = Series 20 (RTX 2xxx) и Series 16 (GTX 16xx).

Pascal = Series 10 (GTX 1xxx).

Maxwell = GTX 750 Ti, GTX 750, GTX 745, GTX 980 Ti, GTX 980, GTX 970, GTX 960, GTX 950.

до Maxwell = GTX 690, GTX 680, GTX 670, GTX 660 Ti, GTX 660, GTX 650 Ti BOOST, GTX 650 Ti, GTX 650, GTX 645, GT 640, GT 635, GT 630, GTX 780 Ti, GTX 780, GTX 770, GTX 760, GTX 760 Ti (OEM), GT 740, GT 730, GT 720, GT 710. Более старые видеокарты NVIDIA не поддерживаются.

Пропатченный драйвер предлагается в двух вариантах:
* Обычный;
* С префиксом`NVENC-NvFBC-` ([снято](https://github.com/keylase/nvidia-patch/tree/master/win) ограничение максимального числа одновременных кодирований NVENC; для всех поддерживаемых приложений [включена](https://github.com/keylase/nvidia-patch/tree/master/win/nvfbcwrp) технология NvFBC.

**Внимание: Не используйте NVENC- драйвер, если ваша карта не имеет аппаратной поддержки NVENC (например, она отсутствует у P1XX-карт). Иначе приложения будут падать при попытке задействовать эту технологию.**

2. Скачайте [драйвер](https://www.nvidia.com/en-us/drivers/) с официального сайта.
3. Скачайте [Display Driver Uninstaller](https://www.wagnardsoft.com/display-driver-uninstaller-ddu-) (DDU).
4. Распакуйте официальный дистрибутив драйвера с помощью 7-Zip / WinRAR / иного архиватора.
5. Замените файлы пропатченными.
6. Вытащите сетевой кабель / отключите Wi-Fi на ПК и удалите уже имеющиеся драйверы NVIDIA с помощью DDU. Перезагрузите компьютер.
7. Запустите setup.exe.

Ожидаемый результат:

![Скриншот окна GPU-Z](/docs/GPU-Z.png)

Теперь можно вставить обратно сетевой кабель / включить Wi-Fi.

8.1. В Windows 10 откройте панель управления NVIDIA → Параметры 3D → Управление параметрами 3D → выберите "Высокопроизводительный процессор NVIDIA" в качестве предпочтительного графического процессора:

![Скриншот панели управления NVIDIA](/docs/NVIDIA%20Manage%203D%20Settings.jpg) ![Скриншот настройки «Предпочтительный графический процессор»](/docs/High%20Performance%20NVIDIA%20Processor.jpg)

8.2. В Windows 11 откройте Параметры → Система → Дисплей → Графика → Изменить параметры графики по умолчанию → выберите желаемую видеокарту в качестве высокопроизводительного графического адаптера по умолчанию:

![Скриншот настройки «Высокопроизводительный графический адаптер по умолчанию»](/docs/Windows%20Default%20High-performance%20GPU.png)

## Работа в режиме SLI
Можно заставить работать вместе в режиме SLI разные GPU одного поколения/архитектуры (Примечание: Объединение видеокарт с разным объёмом видеопамяти может привести к нестабильной работе или некорректно работающему SLI). Кроме того, это включает SLI на некоторых материнских платах, несовместимых со-SLI/Crossfire, как делала когда-то заброшенная ныне программа HyperSLI (Примечание: Поддержка SLI на таких материнских платах не гарантирована).

Обязательные требования:
* Драйвер версии 446.14 (в точности этой версии).
* Должны совпадать первые три символа Device ID обеих карт. Посмотреть Device ID можно в диспетчере устройств Windows → Right-click on device → Properties → Switch to the "Details" tab →  Select "Hardware IDs" from the combo box.

Пример:  
NVIDIA_DEV.`118`5.098A.10DE = "NVIDIA GeForce GTX 660"  
NVIDIA_DEV.`118`5.106F.10DE = "NVIDIA GeForce GTX 760"

Таким образом, например, GTX 1070 и GTX 1080 могут работать в паре, а GTX 960 и GTX 1060 не могут.

## Решение проблем
* Проблема: Антивирусное ПО удаляет драйвер.  
Решение: Добавить каталог `C:\Windows\System32\DriverStore` в список исключений антивируса. После этого переустановить драйвер.

* Проблема: BSOD после устьановки драйвера.  
Решение: Выключить [Hardware Accelerated GPU Scheduling](https://www.howtogeek.com/756935/how-to-enable-hardware-accelerated-gpu-scheduling-in-windows-11/#enable-hardware-accelerated-gpu-scheduling-in-windows-11).

* Проблема: Отсутствует поддержка DirectX 12 на платформе Haswell.
Решение: Не использовать встроенную в процессор графику, поскольку [Intel отключила поддержку DX12 в своём драйвере](https://www.techpowerup.com/288676/intel-disables-directx-12-api-loading-on-haswell-processors).

## Разблокировка всех 16 линий PCI-E на CMP-картах
Нужно [распаять отсутствующие элементы возле слота PCI-E](https://www.youtube.com/watch?v=twRIYq2p-38).

## Использование ShadowPlay, также известного под названием «Оверлей NVIDIA»
Требуется майнинговая карта с поддержкой NVENC.

### Рекомендуемый способ: [NVIDIA App](https://www.nvidia.com/en-us/software/nvidia-app/)

### Альтернативный способ: GeForce Experience

Чтобы записывать геймплей, мониторить ресурсы или стримить с помощью оверлея ShadowPlay:
1. Скачайте и установите [GeForce Experience](https://www.nvidia.com/en-us/geforce/geforce-experience/download/) (входить в учётную запись не обязательно).
2. Откройте папку, куда установлена NVIDIA GeForce Experience, обычно это `C:\Program Files\NVIDIA Corporation\NVIDIA GeForce Experience`.
3. Найдите в этой папке исполняемый файл "NVIDIA Share.exe" и создайте ярлык на рабочем столе.
4. Щёлкните правой кнопкой мыши по созданному ярлыку, откройте его свойства, в поле «Объект» добавьте в конец пути ` --shadowplay` (через пробел, как на скриншоте). Нажмите «ОК».

![Скриншот свойств ярлыка NVIDIA Share](/docs/NVIDIA%20Share%20shortcut.png)

4. Запустите ярлык двойным щелчком. На первый взгляд ничего не произойдёт, но, если нажать `Alt+Z`, то откроется оверлей ShadowPlay.
Примечание: Второй раз запускать ярлык не нужно, отныне можно сразу вызывать ShadowPlay нажатием `Alt+Z`.

![Скриншот ShadowPlay](/docs/ShadowPlay.png)
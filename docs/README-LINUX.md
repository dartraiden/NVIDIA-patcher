[English](#english) | [Русский](#русский)

---

# English

## Security and transparency
Compare the patched and unpatched files byte by byte. You will see that the files are identical, only a small number of bytes have changed. In this regard, I can't remove the "virus" (which doesn't exist) from the driver. Please report the false positive to your antivirus manufacturer.

If you don't trust me and want to patch the driver by yourself, see [how to use patcher](/docs/README-PATCHER-LINUX.md).

## Usage
1. Download patched files from [releases](https://github.com/dartraiden/NVIDIA-patcher/releases) (you can find an archive of previous versions [here](https://cloud.mail.ru/public/ihU3/CpmTAFWQo)).

First, select the row with your "mining" card, then the column depending on what device you are using to display the image on the monitor.

|                | Internal CPU graphics | Discrete graphics<br>(AMD) | Discrete graphics<br>(NVIDIA Turing and newer) | Discrete graphics<br>(NVIDIA Maxwell — Pascal) | Discrete graphics<br>(NVIDIA pre-Maxwell) |
|:---------------|-----------------------|:---------------------------|:-----------------------------------------------|:-----------------------------------------------|:------------------------------------------|
| P1XX           | 580.142               | 580.142                    | 580.142                                        | 580.142                                        | 470.256.02 (no patch needed)              |
| CMP and others | 595.58.03             | 595.58.03                  | 595.58.03                                      | 580.142                                        | 470.256.02 (no patch needed)              |

Turing = Series 20 (RTX 2xxx) and Series 16 (GTX 16xx).

Pascal = Series 10 (GTX 1xxx).

Maxwell = GTX 750 Ti, GTX 750, GTX 745, GTX 980 Ti, GTX 980, GTX 970, GTX 960, GTX 950.

pre-Maxwell = GTX 690, GTX 680, GTX 670, GTX 660 Ti, GTX 660, GTX 650 Ti BOOST, GTX 650 Ti, GTX 650, GTX 645, GT 640, GT 635, GT 630, GTX 780 Ti, GTX 780, GTX 770, GTX 760, GTX 760 Ti (OEM), GT 740, GT 730, GT 720, GT 710. Older NVIDIA graphics cards are not supported.

2. Download the NVIDIA driver from the official [website](https://www.nvidia.com/en-us/drivers/).
3. Run it with `--extract-only` (i.e., `./NVIDIA-Linux-x86_64-580.105.08.run --extract-only`) to unpack it.
4. Replace the original file with the patched one.
5. Install the patched driver by running the `nvidia-installer` from the driver's root directory.

## Increase performance of the CMP 30HX and CMP 40HX
To improve performance and stability in gaming and compute workloads, after a successful driver installation, it is recommended to disable GPU control via GSP Firmware, which is enabled automatically by default.

1. Blacklist the nouveau driver:
```shell
sudo tee /etc/modprobe.d/blacklist-nouveau.conf >/dev/null <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
```
2. Disable GSP firmware:
```shell
sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
options nvidia NVreg_EnableGpuFirmware=0
EOF
```
3. GRUB configuration  
Add the `nvidia.NVreg_EnableGpuFirmware=0` parameter to the file `/etc/default/grub`.

Example:
```text
   GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia.NVreg_EnableGpuFirmware=0"
```
4. Update GRUB and initramfs:
```shell
sudo update-grub && sudo update-initramfs -u -k all
```
5. Reboot the system.
6. Verification:
```shell
nvidia-smi -q | grep GSP
```
If GSP is disabled, the output will show GSP firmware: N/A or the GSP field will be absent entirely.

## Unlocking full x16 PCI-E lines on the CMP-cards
You need to [solder the missing elements near the PCI-E slot](https://www.youtube.com/watch?v=AlLid4uGxpw).

---

# Русский

## Опасающимся за безопасность
Побайтово сравните исходный и пропатченный файлы. Вы заметите, что изменены лишь несколько байтов. Таким образом, я не могу убрать «вирус» (которого не существует) из драйвера. Сообщите разработчику вашего антивируса о ложноположительном срабатывании.

Если вы хотите пропатчить драйвер самостоятельно, читайте [руководство по использованию патчера](/docs/README-PATCHER-LINUX.md).

## Установка
1. Скачайте пропатченные [файлы](https://github.com/dartraiden/NVIDIA-patcher/releases) (предыдущие версии, при необходимости, можно отыскать [здесь](https://cloud.mail.ru/public/ihU3/CpmTAFWQo)).

Чтобы определить требуемую версию драйвера, выберите вашу «майнинговую» карту в горизонтальной строке, затем выберите столбец в зависимости от того, через какое устройство выводите изображение на монитор.

|              | Встроенное видеоядро CPU | Видеокарта (AMD)  | Видеокарта (NVIDIA Turing или новее) | Видеокарта <br>(NVIDIA Maxwell — Pascal) | Видеокарта (NVIDIA до Maxwell) |
|:-------------|:-------------------------|:------------------|:--------------------------------------|:----------------------------------------|:-------------------------------|
| P1XX         | 580.142                  | 580.142           | 580.142                               | 580.142                                 | 470.256.02 (патч не требуется) |
| CMP и прочие | 595.58.03                | 595.58.03         | 595.58.03                             | 580.142                                 | 470.256.02 (патч не требуется) |

Turing = Series 20 (RTX 2xxx) и Series 16 (GTX 16xx).

Pascal = Series 10 (GTX 1xxx).

Maxwell = GTX 750 Ti, GTX 750, GTX 745, GTX 980 Ti, GTX 980, GTX 970, GTX 960, GTX 950.

до Maxwell = GTX 690, GTX 680, GTX 670, GTX 660 Ti, GTX 660, GTX 650 Ti BOOST, GTX 650 Ti, GTX 650, GTX 645, GT 640, GT 635, GT 630, GTX 780 Ti, GTX 780, GTX 770, GTX 760, GTX 760 Ti (OEM), GT 740, GT 730, GT 720, GT 710. Более старые видеокарты NVIDIA не поддерживаются.

2. Скачайте [драйвер](https://www.nvidia.com/en-us/drivers/) с официального сайта.
3. Откройте терминал и извлеките содержимое установочного файла, запустив его с ключом `--extract-only` (например, `./NVIDIA-Linux-x86_64-580.105.08.run --extract-only`).
4. Замените в распакованном драйвере оригинальный файл пропатченным.
5. Установите пропатченный драйвер, запустив установщик `nvidia-installer` из корневого каталога драйвера.

## Повышение производительности CMP 30HX и CMP 40HX
Для повышения производительности и стабильности в игровых и вычислительных нагрузках после успешной установки драйвера рекомендуется отключить управление видеокартой через прошивку GSP.

1. После установки драйвера заблокировать драйвер nouveau:
```shell
sudo tee /etc/modprobe.d/blacklist-nouveau.conf >/dev/null <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
```
2. Отключить прошивку GSP:
```shell
sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
options nvidia NVreg_EnableGpuFirmware=0
EOF
```
3. Настроить GRUB  
Добавить параметр `nvidia.NVreg_EnableGpuFirmware=0` в файл `/etc/default/grub`.

Например:
```text
   GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia.NVreg_EnableGpuFirmware=0"
```
4. Обновить GRUB и initramfs:
```shell
sudo update-grub && sudo update-initramfs -u -k all
```
5. Перезагрузить компьютер.
6. Проверить:
```shell
nvidia-smi -q | grep GSP
```
Если прошивка GSP отключена, то результатом будет `GSP firmware: N/A`, либо полное отсутствие.

## Разблокировка всех 16 линий PCI-E на CMP-картах
Нужно [распаять отсутствующие элементы возле слота PCI-E](https://www.youtube.com/watch?v=twRIYq2p-38).

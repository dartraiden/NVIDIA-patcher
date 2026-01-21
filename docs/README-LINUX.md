# Инструкция для Linux

1. Скачать с официального сайта Nvidia [драйвер](https://www.nvidia.com/en-us/drivers/)  
(далее в инструкции xxx.xxx.xx — это версия драйвера).
2. Переместить скачанный файл NVIDIA-Linux-x86_64-xxx.xxx.xx.run в домашний каталог пользователя.
3. Открыть терминал и извлечь содержимое установочного файла:
 ```shell
./NVIDIA-Linux-x86_64-xxx.xxx.xx.run --extract-only
```
После этого появится каталог `NVIDIA-Linux-x86_64-xxx.xxx.xx`.

4. Скачать скрипт `linux.sh` из проекта и поместить его в каталог:
```text
NVIDIA-Linux-x86_64-xxx.xxx.xx/kernel/nvidia
```
5. Сделать скрипт исполняемым и запустить его с правами суперпользователя:
```shell
cd NVIDIA-Linux-x86_64-xxx.xxx.xx/kernel/nvidia
chmod +x linux.sh
sudo ./linux.sh
```
Скрипт создаст резервную копию файла nv-kernel.o_binary и начнёт процесс патчинга.
В случае успешного выполнения в терминале будет выведено сообщение вида:
```text
Creating backup: nv-kernel.o_binary.backup
Found pattern: Pattern 1 — 1 occurrence(s)
Found pattern: Pattern 2 — 1 occurrence(s)
…
=== SUCCESS ===
Patching complete.
```
6. Установить пропатченный драйвер, запустив установщик из корневого каталога драйвера:
```shell
cd ~/NVIDIA-Linux-x86_64-xxx.xxx.xx
sudo ./nvidia-installer
```
### Проблема GSP Firmware 
Актуально для карт `CMP 30` и `CMP 40`, для повышения производительности и стабильности в игровых и вычислительных 
нагрузках после успешной установки драйвера необходимо произвести процедуру отключения управления 
видеокарты через GSP Firmware которая включается автоматически

1. После установки драйвера заблокировать драйвер nouveau:
```shell
sudo tee /etc/modprobe.d/blacklist-nouveau.conf >/dev/null <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
```
2. Отключение GSP Firmware:
```shell
sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
options nvidia NVreg_EnableGpuFirmware=0
EOF
```
3. GRUB
В файл `/etc/default/grub` добавить параметр `nvidia.NVreg_EnableGpuFirmware=0`.   

Например:
```text
   GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia.NVreg_EnableGpuFirmware=0"
```
4. Обновить GRUB и initramfs
```shell
sudo update-grub && sudo update-initramfs -u -k all
```
5. Перезагрузка
6. Проверка
```shell
nvidia-smi -q | grep GSP
```
Если GSP отключён — будет GSP Firmware: N/A или отсутствовать.

  
⚠️ Important

Linux имеет множество дистрибутивов с разными пакетными менеджерами,  
механизмами initramfs, настройками GRUB и системными утилитами.  

Данная инструкция является универсальной и описывает общий проверенный подход.  
Она не может учитывать все особенности каждого конкретного дистрибутива.  

В отдельных случаях команды могут отличаться и требуют адаптации  
согласно документации вашего дистрибутива.  

Для корректной работы скрипта в системе должны быть установлены следующие утилиты:  

- bash
- coreutils
- grep
- sed
- xxd

Как правило, они уже присутствуют в базовой установке большинства дистрибутивов Linux,  
но в минимальных системах могут потребовать установки вручную.  

Как аналог MSI Afterburner в Linux можно использовать [LACT](https://github.com/ilya-zlobintsev/LACT)


 # Linux Instruction

1. Download the NVIDIA driver from the official [website](https://www.nvidia.com/en-us/drivers/):  
(In this guide, xxx.xxx.xx refers to the driver version.)
2. Move the downloaded file NVIDIA-Linux-x86_64-xxx.xxx.xx.run to your home directory.
3. Open a terminal and extract the contents of the installer:
```shell
./NVIDIA-Linux-x86_64-xxx.xxx.xx.run --extract-only
```
After this, a directory named NVIDIA-Linux-x86_64-xxx.xxx.xx will be created.
4. Download the linux.sh script from the project and place it into the following directory:
```shell
NVIDIA-Linux-x86_64-xxx.xxx.xx/kernel/nvidia
```
5. Make the script executable and run it with superuser privileges:
```shell
cd NVIDIA-Linux-x86_64-xxx.xxx.xx/kernel/nvidia
chmod +x linux.sh
sudo ./linux.sh
```
The script will create a backup of nv-kernel.o_binary and start the patching process.
If the patching is successful, you will see output similar to the following:
```text
Creating backup: nv-kernel.o_binary.backup
Found pattern: Pattern 1 — 1 occurrence(s)
Found pattern: Pattern 2 — 1 occurrence(s)
…
=== SUCCESS ===
Patching complete.
```
6. Install the patched driver by running the installer from the driver’s root directory:
```shell
cd ~/NVIDIA-Linux-x86_64-xxx.xxx.xx
sudo ./nvidia-installer
```

### GSP Firmware Issue
Applicable to CMP 30 and CMP 40 GPUs.  
To improve performance and stability in gaming and compute workloads, after a successful driver installation it is   
recommended to disable GPU control via GSP Firmware, which is enabled automatically by default.

1. Blacklist the nouveau driver:
```shell
sudo tee /etc/modprobe.d/blacklist-nouveau.conf >/dev/null <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
```
2. Disable GSP Firmware:
```shell
sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
options nvidia NVreg_EnableGpuFirmware=0
EOF
```
3. GRUB configuration  
Add the parameter `nvidia.NVreg_EnableGpuFirmware=0` to the file `/etc/default/grub`.

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
If GSP is disabled, the output will show GSP Firmware: N/A or the GSP field will be absent entirely.


⚠️ Important

Linux has many different distributions with varying package managers,  
initramfs implementations, GRUB configurations, and system utilities.  

This guide is intentionally generic and describes a common, proven approach.  
It cannot account for all distribution-specific details.  

In some cases, commands may differ and require adjustment  
according to your distribution’s documentation.  

The following utilities are required for the script to work correctly:  

- bash
- coreutils
- grep
- sed
- xxd

These tools are usually present in most standard Linux installations,  
but minimal setups may require manual installation.  

As an alternative to MSI Afterburner on Linux, you can use [LACT](https://github.com/ilya-zlobintsev/LACT)

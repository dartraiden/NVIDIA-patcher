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
[English](#english) | [Русский](#русский)

---

# English

The following utilities are required for the script to work correctly:
- bash
- coreutils
- grep
- sed
- xxd

1. Download the NVIDIA driver from the official [website](https://www.nvidia.com/en-us/drivers/):  
(in this guide, xxx.xxx.xx refers to the driver version).

2. Move the downloaded file NVIDIA-Linux-x86_64-xxx.xxx.xx.run to your home directory.

3. Open a terminal and extract the contents of the installer:
```shell
chmod +x NVIDIA-Linux-x86_64-xxx.xxx.xx.run
./NVIDIA-Linux-x86_64-xxx.xxx.xx.run --extract-only
```
After this, a directory named `NVIDIA-Linux-x86_64-xxx.xxx.xx` will be created.

4. Download the linux.sh script from this project and place it into the following directory:
```text
NVIDIA-Linux-x86_64-xxx.xxx.xx/kernel/nvidia
```

5. Make the script executable and run it:
```shell
cd NVIDIA-Linux-x86_64-xxx.xxx.xx/kernel/nvidia
chmod +x linux.sh
./linux.sh
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

---

# Русский

Для работы скрипта требуются следующие утилиты:
- bash
- coreutils
- grep
- sed
- xxd

1. Скачайте [драйвер](https://www.nvidia.com/en-us/drivers/) с официального сайта  
(далее в инструкции xxx.xxx.xx — это версия драйвера).

2. Поместите скачанный файл NVIDIA-Linux-x86_64-xxx.xxx.xx.run в домашний каталог пользователя.

3. Откройте терминал и извлеките содержимое установочного файла:
```shell
chmod +x NVIDIA-Linux-x86_64-xxx.xxx.xx.run
./NVIDIA-Linux-x86_64-xxx.xxx.xx.run --extract-only
```
После этого появится каталог `NVIDIA-Linux-x86_64-xxx.xxx.xx`.

4. Скачайте из этого проекта скрипт `linux.sh` и поместите его в каталог:
```text
NVIDIA-Linux-x86_64-xxx.xxx.xx/kernel/nvidia
```

5. Сделайте скрипт исполняемым и запустите его:
```shell
cd NVIDIA-Linux-x86_64-xxx.xxx.xx/kernel/nvidia
chmod +x linux.sh
./linux.sh
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

6. Установите пропатченный драйвер, запустив установщик из корневого каталога драйвера:
```shell
cd ~/NVIDIA-Linux-x86_64-xxx.xxx.xx
sudo ./nvidia-installer
```

[English](#english) | [Русский](#русский)

---

# English

**Attention: the driver will install and work only if [test mode](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/the-testsigning-boot-configuration-option) is enabled. This causes many anti-cheats to not work. If you don't like this, use [the driver I made](/docs/README.md). Please don't ask me where to get a certificate that works without test mode. Such certificates sometimes leak from various companies. I do not provide such certificates as it is completely illegal.**

1. Enable [test mode](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/the-testsigning-boot-configuration-option): use `bcdedit -set TESTSIGNING ON` command as admin, then reboot.

2. Place original driver distribution (`xxx.xx-desktop-win10-win11-64bit-international-dch-whql.exe`) inside `/Edit` folder. Do not unpack this distribution, the script does it automatically.

3. Keep only one preset, delete the other (`Presets.txt` or `Presets_NVENC.txt`). `Presets.txt` will produce a regular driver, while `Presets_NVENC.txt` will produce a driver with NVENC and NvFBC patches ([removed](https://github.com/keylase/nvidia-patch/tree/master/win) restriction on maximum number of simultaneous NVENC video encoding; [enabled](https://github.com/keylase/nvidia-patch/tree/master/win/nvfbcwrp) NvFBC for all NvFBC-targeted applications).

**Attention: Do not use `Presets_NVENC.txt` preset if your mining card does not have hardware NVENC support. In this case driver will cause problems (crashes) in applications supporting NVENC.**

4. Run `windows.bat`.

5. Choose `100` for certificates generation. You only need to do this once. The next time you run the patcher, it will use the existing certificates.

6. Choose `200` to add certificate into Root certificates storage.

7. Choose `1` to start the automated process. The script will automatically do everything specified in the preset.

8. After the script has completed all the necessary actions, in the /Edit folder you will find a ready-to-use unpacked distribution. Just run Setup.exe and install driver.

9. Keep `/UseCerts/Gen-*` files! These are your personal certificates. You will need them the next time you want to patch a driver (for example, when a new driver version is released). If you lose them, you will have to regenerate them and add to the storage (items `100` and `200` in script options).

**If you are going to install the driver on another computer (for example, if you run the patcher in a virtual machine and then transfer the driver to the host system), copy `/UseCerts/Gen-Root.crt` and [install it into the Root certificate store](https://thomas-leister.de/images/2017/02/24/install_root_windows.webm) before installing the driver. Don't forget to turn on test mode!**

---

# Русский

**Внимание: драйвер установится и будет работать лишь при включённом [тестовом режиме](https://learn.microsoft.com/ru-ru/windows-hardware/drivers/install/the-testsigning-boot-configuration-option). Это препятствует работе некоторых античитов. Если вас это не устраивает, используйте [готовый драйвер, сделанный мною](/docs/README.md). Не спрашивайте, где достать сертификат для подписи драйвера, чтобы тот работал без тестового режима. Иногда такие сертификаты утекают у различных компаний. Я не собираюсь выкладывать сертификаты, это противозаконно.**

1. Включите [тестовый режим](https://learn.microsoft.com/ru-ru/windows-hardware/drivers/install/the-testsigning-boot-configuration-option): выполните команду `bcdedit -set TESTSIGNING ON` с правами администратора, затем перезагрузите компьютер.

2. Поместите оригинальный дистрибутив (`xxx.xx-desktop-win10-win11-64bit-international-dch-whql.exe`) в папку `/Edit`. Не распаковывайте его, патчер сам это сделает.

3. Удалите ненужные пресеты, оставив только один, который вам нужен (`Presets.txt` или `Presets_NVENC.txt`). `Presets.txt` сделает обычный драйвер, а `Presets_NVENC.txt` сделает драйвер с патчами NVENC и NvFBC ([удалит](https://github.com/keylase/nvidia-patch/tree/master/win) ограничение на количество одновременных кодирований NVENC; [включит](https://github.com/keylase/nvidia-patch/tree/master/win/nvfbcwrp) NvFBC для всех поддерживаемых приложений).

**Внимание: не используйте пресет `Presets_NVENC.txt`, если ваша майнинговая карта аппаратно не поддерживает NVENC. Иначе приложения будут падать при попытке использовать NVENC.**

4. Запустите `windows.bat`.

5. Выберите `100`, чтобы сгенерировать сертификаты. Достаточно сделать это однократно. В следующий раз при запуске патчера будут использоваться уже существующие сертификаты, сгенерированные в прошлый раз.

6. Выберите `200`, чтобы добавить сертификаты в хранилище корневых сертификатов операционной системы.

7. Выберите `1`, чтобы начать процесс патчинга. Патчер автоматически сделает то, что указано в пресете.

8. Когда патчер закончит работу, в папке /Edit появится готовый распакованный дистрибутив. Запустите Setup.exe и установите драйвер.

9. Сохраните файлы `/UseCerts/Gen-*`! Это ваши сертификаты. Они понадобятся в следующий раз, когда вы снова захотите пропатчить драйвер (например, когда выйдет новая версия). Если вы их потеряете, то в следующий раз придётся снова пересоздавать их и добавлять в хранилище (пункты `100` и `200` в меню патчера).

**Если вы собираетесь установить драйвер на другом компьютере (например, если вы запустили патчер в виртуальной машине и затем переносите драйвер в «живую» систему), до установки драйвера скопируйте `/UseCerts/Gen-Root.crt` и [установите его в хранилище корневых сертификатов](https://thomas-leister.de/images/2017/02/24/install_root_windows.webm). Не забудьте также включить тестовый режим!**

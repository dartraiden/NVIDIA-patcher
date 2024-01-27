# How to use patcher

**Attention: the driver will install and work only if [test mode](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/the-testsigning-boot-configuration-option) is enabled. This causes many anti-cheats to not work. If you don't like this, use [the driver I made](/docs/README.md).**

1. Enable [test mode](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/the-testsigning-boot-configuration-option): use `bcdedit -set TESTSIGNING ON` command as admin, then reboot.

2. Place original driver distributive (`xxx.xx-desktop-win10-win11-64bit-international-dch-whql.exe`) inside `/Edit` folder. Do not unpack this distributive, the script does it automatically.

3) Keep only one preset, deleting the unnecessary one (`Presets.txt` or `Presets_NVENC.txt`). `Presets.txt` will make you a regular driver, while `Presets_NVENC.txt` will make you a driver with NVENC and NvFBC patches ([removed](https://github.com/keylase/nvidia-patch/tree/master/win) restriction on maximum number of simultaneous NVENC video encoding; [enabled](https://github.com/keylase/nvidia-patch/tree/master/win/nvfbcwrp) NvFBC for all NvFBC-targeted applications).

**Attention: Do not use `Presets_NVENC.txt` preset if your mining card does not have hardware NVENC support. In this case driver will cause problems (crashes) in applications supporting NVENC.**

4) Run `_Start_Menu.bat`.

5) Choose `100` for certificates generation. You only need to do this once. The next time you run the patcher, it will use the existing certificates.

4) Choose `200` to add certificate into Root certificates storage.

6) Choose `1` to start the automated process. The script will automatically do everything specified in the preset.

7) After the script has completed all the necessary actions, in the /Edit folder next to the distributive (`xxx.xx-desktop-win10-win11-64bit-international-dch-whql.exe`) you will find a ready-to-use unpacked distributive. Just run Setup.exe and install driver.

**If you are going to install the driver on another computer (for example, if you run the patch in a virtual machine and then transfer the driver to the host system), copy `/UseCerts/Gen-Root.crt` and install it into the Root certificate store before installing the driver. Don't forget to turn on test mode!**

8) Don't lose `/UseCerts/Gen-*` files! These are your personal certificates. You will need them the next time you want to patch a driver (for example, when a new driver version is released). If you lose them, you will have to regenerate them and add to the storage (items `100` and `200` in script options).
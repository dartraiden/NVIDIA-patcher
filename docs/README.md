# NVIDIA patched drivers
Adds 3D acceleration support for P106-090 / P106-100 / P104-100 / P104-101 / P102-100 / CMP 30HX / CMP 40HX / CMP 50HX / CMP 70HX / CMP 90HX / CMP 170HX mining cards as well as the officially unreleased RTX 3080 Ti 20GB.

# Donation
![](/docs/donate.png)
If you like my project, press "Star" in the top right corner, please. You can also [donate me some money via Boosty](https://boosty.to/dartraiden/donate).

## Usage
[Click here](https://mysku.club/blog/taobao/70663.html) if you need Russian translation.

1. Download patched files from [releases](https://github.com/dartraiden/NVIDIA-patcher/releases) (you can find an archive of previous versions [here](https://disk.yandex.ru/d/5LO4wqy177XZyw)).

* [latest](https://github.com/dartraiden/NVIDIA-patcher/releases/latest) — if you want to use mining card in pair with any AMD/Intel graphic or any supported NVIDIA discrete graphic.
* 516.61 - if you want to use [RTX 3080 Ti 20 GB](https://videocardz.com/newz/unreleased-geforce-rtx-3080-ti-with-20gb-memory-shows-up-with-overclocking-support).
* 472.12 — if you want to use mining card in pair with old NVIDIA discrete graphic (GeForce 600 Series, GeForce GT 710-740, GeForce GTX 760-780 Ti).
* 446.14 — if you want to use mining card (only PXXX, not CMP-cards) in SLI setup (see [SLI hack](#SLI-hack)).

The patched driver comes in two versions:
* Regular;
* `NVENC-NvFBC-` prefixed ([removed](https://github.com/keylase/nvidia-patch/tree/master/win) restriction on maximum number of simultaneous NVENC video encoding; [enabled](https://github.com/keylase/nvidia-patch/tree/master/win/nvfbcwrp) NvFBC for all NvFBC-targeted applications).

**Attention: Do not use NVENC- prefixed package if your mining card does not have hardware NVENC support. In this case driver will cause problems (crashes) in applications supporting NVENC.**

2. Download the official driver package from the NVIDIA website.
3. Download [Display Driver Uninstaller](https://www.wagnardsoft.com/display-driver-uninstaller-ddu-) (DDU).
4. Unpack the official driver package with 7-Zip / WinRAR / etc.
5. Replace original files with patched ones.
6. Unplug the network cable / disable Wi-Fi on your PC and clean the installed NVIDIA driver with DDU. Reboot PC.
7. Run setup.exe.

During installation, you can select the option "Spoof GPU name" so that the graphics adapter appears in the device manager with the name of the corresponding gaming video card.

Result:

![Screenshot of GPU-Z window](/docs/GPU-Z.png)

Now you can plug the network cable / enable Wi-Fi back.

8.1. In Windows 10 open the NVIDIA control panel → 3D settings → Manage 3D settings → set "High-performance NVIDIA processor" as preferred graphics processor:

![Screenshot of NVIDIA control panel](/docs/NVIDIA%20Manage%203D%20Settings.jpg) ![Screenshot of "High-performance NVIDIA processor" option](/docs/High%20Performance%20NVIDIA%20Processor.jpg)

8.2. In Windows 11 open Settings → System → Display → Graphics → Change default graphic settings → set mining card as the default high-performance graphic adapter:

![Screenshot of "Default High-performance GPU" option](/docs/Windows%20Default%20High-performance%20GPU.png)

## SLI hack
It is possible to pair together different GPUs of similar generation/architecture to work together in SLI (Note: Mixing different VRAM sizes may cause some instability or stop SLI from functioning properly). It can also enable SLI on some non SLI/Crossfire compatible motherboards, making it a replacement for the now discontinued HyperSLI program (Note: The SLI support on non multi-GPU motherboards is not guaranteed).

Mandatory requirements:
* Driver version 446.14 (exactly this version).
* The first three symbols of Device ID for both cards must match. Go to Windows Device Manager → Right-click on device → Properties → Switch to the "Details" tab →  Select "Hardware IDs" from the combo box.

As an example:  
NVIDIA_DEV.`118`5.098A.10DE = "NVIDIA GeForce GTX 660"  
NVIDIA_DEV.`118`5.106F.10DE = "NVIDIA GeForce GTX 760"

Thus, for example, GTX 1070 and GTX 1080 can work together, but GTX 960 and GTX 1060 cannot.

# If you don't trust me and want to patch the driver yourself, see [how to use patcher](/docs/README-PATCHER.md).

## Unlocking full x16 PCI-E lines on the CMP-cards
TL;DR: You need to solder the missing elements near the PCI-E slot.

English:
https://www.youtube.com/watch?v=AlLid4uGxpw

Russian:
https://www.youtube.com/watch?v=twRIYq2p-38

## Using ShadowPlay, also known as the NVIDIA overlay
Requirements
* A graphics card that supports NVENC.
* Download and install [GeForce Experience](https://www.nvidia.com/en-us/geforce/geforce-experience/download/) (no need to log in).

In order to use the ShadowPlay overlay to record gameplay, use the resource monitor, or stream, you must follow these steps:
1. Go to the installation path of Nvidia GeForce Experience, usually located at `C:\Program Files\NVIDIA Corporation\NVIDIA GeForce Experience`
2. Once there, locate the executable named "NVIDIA Share.exe" and create a shortcut on your desktop.
3. Right-click on the created desktop shortcut, go to properties, and in the "Target" field at the end of the path, add ` --shadowplay` while ensuring there's a space as shown in the picture. Then click OK.

![Screenshot of NVIDIA Share shortcut](/docs/NVIDIA%20Share%20shortcut.png)

4. Now double-click on the shortcut, and you'll notice that nothing appears to happen. However, when you press `Alt+Z`, the ShadowPlay overlay will open.
Note: You do not need to double-click the shortcut again; this is a one-time setup. From now on, you can always open ShadowPlay by pressing `Alt+Z`.

![Screenshot of ShadowPlay](/docs/ShadowPlay.png)

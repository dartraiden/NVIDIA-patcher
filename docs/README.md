# NVIDIA patcher

Adds 3D acceleration support for P106-090/P106-100/P104-100/P104-101 mining cards.

## Usage
[Click here](https://mysku.club/blog/taobao/70663.html) if you need Russian translation.

1. Unpack driver distributive (xxx.xx-desktop-win10-win11-64bit-international-dch-whql.exe). Only 417.35+ driver needs to be patched! If you are using version 417.23 or older, go straight to step 5.
2. Place [all patcher files](https://github.com/dartraiden/NVIDIA-patcher/archive/refs/heads/master.zip) next to setup.exe.
3. Ensure your system partition has at least 8GB of free space and PC is connected to the Internet.
4. Run Patch.bat as admin.

The result of the patch will be a signed `/Display.Driver/nv_disp.cat` file. Check the signature in its properties, it should be valid:

![Valid signature](/docs/signature.jpg)

5. Install the driver manually. Go to Windows Device Manager → Right-click on device → Properties → Driver → Update Driver → Browse my computer for drivers → Let me pick from a list of available drivers on my computer → Show All Devices → Have Disk... → Browse... → Choose `nv_disp.cat` (inside Display.Driver folder)  → Untick "Show compatible hardware" → Choose appropriate 3D video card model. Do not choose mining card models, choose 3D cards!
* P102-100 → GTX 1080 Ti
* P104-100 → GTX 1070
* P104-101 → GTX 1080
* P106-090 → GTX 1060 3GB
* P106-100 → GTX 1060 6GB
* CMP 30HX → GTX 1660 SUPER
* CMP 40HX → RTX 2070
* CMP 50HX → RTX 2080 Ti
* CMP 70HX → RTX 3070 Ti
* CMP 90HX → RTX 3080

Result:

![Screenshot of GPU-Z window](/docs/gpu-z.png)

## SLI hack
If the patcher detects driver version 446.14, it will enable the ability to pair together different GPUs of similar generation/architecture to work together in SLI (Note: Mixing different VRAM sizes may cause some instability or stop SLI from functioning properly). It can also enable SLI on some non SLI/Crossfire compatible motherboards, making it a replacement for the now discontinued HyperSLI program (Note: The SLI support on non multi-GPU motherboards is not guaranteed).

Mandatory requirements:
* Driver version 446.14 (exactly this version)
* The first three symbols of Device ID for both cards must match. Go to Windows Device Manager → Right-click on device → Properties → Switch to the "Details" tab →  Select "Hardware IDs" from the combo box.

As an example:  
NVIDIA_DEV.**118**5.098A.10DE = "NVIDIA GeForce GTX 660"  
NVIDIA_DEV.**118**5.106F.10DE = "NVIDIA GeForce GTX 760"

Thus, for example, GTX 1070 and GTX 1080 can work together, but GTX 960 and GTX 1060 cannot.
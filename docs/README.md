# NVIDIA patcher

Adds 3D acceleration support for P106-090/P106-100/P104-100/P104-101 mining cards.

## Usage

1. Unpack driver distributive (xxx.xx-desktop-win10-win11-64bit-international-dch-whql.exe).
2. Place [all patcher files](https://github.com/dartraiden/NVIDIA-patcher/archive/refs/heads/master.zip) next to setup.exe.
3. Run Patch.bat as admin.

The result of the patch will be a signed `/Display.Driver/nv_disp.cat` file. Check the signature in its properties, it should be valid:

![Valid signature](/docs/signature.jpg)

5. Install driver manually. Go to Device Manager → right-click on device → Properties → Driver → Update Driver → Browse my computer for drivers → Let me pick from a list of available drivers on my computer → Have Disk... → Browse... → Choose `nv_dispig.inf` → Untick "Show compatible hardware" → Choose appropriate 3D video card model. Do not choose mining cards models, choose 3D cards!
* P106-090 → GTX 1060 3GB
* P106-100 → GTX 1060 6GB
* P104-100 → GTX 1070
* P104-101 → GTX 1080

Result:

![Screenshot of GPU-Z window](/docs/gpu-z.png)

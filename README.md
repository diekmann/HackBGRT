# HackBGRT

HackBGRT is intended as a boot logo changer for UEFI-based Windows systems.

## Summary

When booting on a UEFI-based computer, Windows may show a vendor-defined logo which is stored on the UEFI firmware in a section called Boot Graphics Resource Table (BGRT). It's usually very difficult to change the image permanently, but a custom UEFI application may be used to overwrite it during the boot. HackBGRT does exactly that.

## Usage

**Important:** If you mess up the installation, your system may become unbootable! Create a rescue disk before use. This software comes with no warranty. Use at your own risk.

* Make sure that your computer is booting with UEFI.
* Make sure that Secure Boot is disabled, unless you know how to sign EFI applications.
* Make sure that BitLocker is disabled, or find your recovery key.

### Windows installation

* Get the latest release from the Releases page.
* Start `setup.exe` and follow the instructions.
	* You may need to manually disable Secure Boot and then retry.
	* The installer will launch Paint for editing the image.
	* If Windows later restores the original boot loader, just reinstall.
	* If you wish to change the image or other configuration, just reinstall.
	* For advanced settings, edit `config.txt` before installing. No extra support provided!

### Quiet (batch) installation

* Edit the `config.txt` and `splash.bmp` (or any other images) to your needs.
* Run `setup.exe batch COMMANDS` as administrator, with some of the following commands:
	* `install` – copy the files but don't enable.
	* `enable-entry` – create a new EFI boot entry.
	* `disable-entry` – disable the EFI boot entry.
	* `enable-bcdedit` – use `bcdedit` to create a new EFI boot entry.
	* `disable-bootmgr` – use `bcdedit` to disable the EFI boot entry.
	* `enable-overwrite` – overwrite the MS boot loader.
	* `disable-overwrite` – restore the MS boot loader.
	* `allow-secure-boot` – ignore Secure Boot in subsequent commands.
	* `allow-bitlocker` – ignore BitLocker in subsequent commands.
	* `allow-bad-loader` – ignore bad boot loader configuration in subsequent commands.
	* `disable` – run all relevant `disable-*` commands.
	* `uninstall` – disable and remove completely.
* For example, run `setup.exe batch install allow-secure-boot enable-overwrite` to copy files and overwrite the MS boot loader regardless of Secure Boot status.

### Multi-boot configurations

If you only need HackBGRT for Windows:

* Run `setup.exe`, install files without enabling.
* Configure your boot loader to start `\EFI\HackBGRT\loader.efi`.

If you need it for other systems as well:

* Configure HackBGRT to start your boot loader (such as systemd-boot): `boot=\EFI\systemd\systemd-bootx64.efi`.
* Run `setup.exe`, install as a new EFI boot entry.

To install purely on Linux, you can install with `setup.exe dry-run` and then manually copy files from `dry-run/EFI` to your `[EFI System Partition]/EFI`. For further instructions, consult the documentation of your own Linux system.

## Configuration

The configuration options are described in `config.txt`, which the installer copies into `[EFI System Partition]\EFI\HackBGRT\config.txt`.

## Images

The image path can be changed in the configuration file. The default path is `[EFI System Partition]\EFI\HackBGRT\splash.bmp`.

The installer copies and converts files whose `path` starts with `\EFI\HackBGRT\`. For example, to use a file named `my.jpg`, copy it in the installer folder (same folder as `setup.exe`) and set the image path in `config.txt` to `path=\EFI\HackBGFT\my.jpg`.

If you copy an image file to ESP manually, note that the image must be a 24-bit BMP file with a 54-byte header. That's a TrueColor BMP3 in Imagemagick, or 24-bit BMP/DIB in Microsoft Paint.

Advanced users may edit the `config.txt` to define multiple images, in which case one is picked at random.

## Recovery

If something breaks and you can't boot to Windows, you need to use the Windows installation disk (or recovery disk) to fix boot issues.

## Building

* Compiler: GCC targeting w64-mingw32
* Compiler flags: see Makefile
* Libraries: gnu-efi

```shell
$ git clone
...
$ git submodule init
Submodule 'submodules/gnu-efi' (https://git.code.sf.net/p/gnu-efi/code) registered for path 'submodules/gnu-efi'
$ git submodule update
Cloning into '/tmp/hack/HackBGRT/submodules/gnu-efi'...
Submodule path 'submodules/gnu-efi': checked out '8b018e67212957de176292f95718df48f49a418b'
$ make testx64-qemu
...
lots of compilation output
...
qemu window showing up, a 5 second startup.nsh timeout appears.
Then, qemu should show the following:
Shell> fs0:\EFI\HackBGRT\loader.efi
Hello, World from _EfiMain.
Hello, World from EfiMain (17).
Hello, World from EfiMain via uefi_call_wrapper.
InitializeLib done.
HackBGRT: Failed to load application \EFI\HackBGRT\bootmgfw-original.efi.
HackBGRT: Failed to load application \EFI\Microsoft\Boot\bootmgfw.efi.
HackBGRT has failed. Use parameter debug=1 for details.
Get a Windows install disk or a recovery disk to fix your boot.
HackBGRT version: unknown
Press any key (or wait 15 seconds) to exit.
<this shows that the compiled binary is likely to work>
<close qemu>
$ make
...
Files read from disk: 8
Archive size: 199882 bytes (196 KiB)
Everything is Ok
rm -rf "HackBGRT-unknown"
```

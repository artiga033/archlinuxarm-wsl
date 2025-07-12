# Arch Linux ARM WSL Image

** Modified from [archlinux-wsl](https://gitlab.archlinux.org/archlinux/archlinux-wsl) **, thanks to the original authors!

For more information about this WSL image and its usage (including "tips and tricks" and troubleshooting steps), see the upstream [Arch Wiki page](https://wiki.archlinux.org/title/Install_Arch_Linux_on_WSL). This ARM build should share many similarities with the x86_64 version, if Arch Wiki does not solve your problem, please open an issue here.

## Installation

### Manual install

#### WSL 2.4.4 or greater

Download the latest released ".wsl" image and double-click on it to start the installation.

You can then run Arch Linux ARM in WSL via the `archlinuxarm` application from the Start menu, or by running `wsl -d archlinuxarm` in a PowerShell prompt.

#### WSL prior to 2.4.4

Download the latest released ".wsl" image and run the following command in a PowerShell prompt:

```powershell
wsl --import <Distro name> <Install location> <WSL image>
```

For instance:

```powershell
wsl --import archlinuxarm C:\Users\<Username>\Documents\WSL\archlinuxarm C:\Users\<Username>\Downloads\archlinuxarm-2025.04.01.121271.wsl
```

You can then run Arch Linux in WSL via the `archlinuxarm` application from the Start menu, or by running `wsl -d archlinuxarm` in a PowerShell prompt.  
Make sure to execute the first setup script by running `/usr/lib/wsl/first-setup.sh` right after the first launch.

## Building your own image

This repository contains all scripts and files needed to create a WSL image for Arch Linux ARM.

### Dependencies

Install the following Arch Linux packages:

- make
- devtools
- fakechroot
- fakeroot

If you are cross-building from a x86_64 system, you will also need:

- qemu-user-static
- qemu-user-static-binfmt

The following additional packages are required to run tests:

- git
- python

### Usage

Run `make` to build a new image (which can be then found in the `workdir/output` directory).  
You can optionally customize the version ID for the image via the `IMAGE_VERSION` variable (defaults to the current date in the format "YEAR-MONTH-DAY"): `make IMAGE_VERSION="1.0.0"`.

You can also run `make test` to execute a series of tests against the built image and `make clean` to delete every directories & files generated during build and tests (including the built image itself).

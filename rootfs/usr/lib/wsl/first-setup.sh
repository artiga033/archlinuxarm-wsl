#!/bin/bash

# Show some documentation
cat <<EOF
Welcome to the Arch Linux ARM WSL image!

This image is maintained at <http://github.com/artiga033/archlinuxarm-wsl>.

Report bugs at <https://github.com/artiga033/archlinuxarm-wsl/issues>.
Note that WSL 1 is not supported.

For more information about this WSL image and its usage (including "tips and tricks" and troubleshooting steps), see the related Arch Wiki page at <https://wiki.archlinux.org/title/Install_Arch_Linux_on_WSL>.
This ARM build should share many similarities with the x86_64 version, if Arch Wiki does not solve your problem, please open an issue.

While images are built regularly, it is strongly recommended running "pacman -Syu" right after the first launch due to the rolling release nature of Arch Linux.
EOF

# Generate pacman lsign key (see the "/!\/!\/!\ Note" at https://gitlab.archlinux.org/archlinux/archlinux-docker#principles)
echo -e "\nGenerating pacman keys..." && pacman-key --init 2> /dev/null && echo "Done"
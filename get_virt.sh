#!/usr/bin/env bash
# Exit in case of error.
set -e

if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root." 1>&2
	exit 1
fi

if [ -f /etc/os-release ]; then
	# freedesktop.org and systemd
	. /etc/os-release
	OS=$ID
	VER=$VERSION_ID
fi

if [[ -z "${OS}" ]]; then
	echo "$(tput setaf 1)Error getting distribution. Modify script and try again.$(tput sgr0)"
	exit
fi

echo "This script sets up libvirt and Single GPU passthrough on my computer."
echo "I have detected that you run the following operating system: $(tput setaf 2)${OS}$(tput sgr0)"
read -n 1 -s -p "Press any key to continue"

echo "Installing dependencies..."

case "$OS" in
"arch")
	pacman -S qemu libvirt edk2-ovmf virt-manager dnsmasq ebtables
	;;
"pop" | "ubuntu" | "debian")
	apt install qemu-kvm qemu-utils libvirt-daemon-system libvirt-clients bridge-utils virt-manager ovmf
	;;
*)
	echo "$(tput setaf 2)Unsupported distribution: ${OS}.$(tput sgr0)"
	exit
	;;
esac

systemctl enable --now libvirtd
virsh net-autostart default

echo "Adding user to groups."
usermod -aG kvm,input,libvirt calin

echo "Copying patched vgabios"
mkdir -p /usr/share/vgabios/
cp ./vbios/rtx3070-patched.rom /usr/share/vgabios/rtx3070-patched.rom

echo "Installing hooks."
mkdir -p /etc/libvirt/hooks
cp ./hooks/qemu /etc/libvirt/hooks/qemu
chmod +x /etc/libvirt/hooks/qemu

echo "Done! Restart before trying to launch your VM."

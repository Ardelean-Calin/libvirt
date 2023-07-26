#!/usr/bin/env bash
# Exit in case of error.
set -e

trap "exit" INT # Exit in case of CTRL+C

prompt_yn() {
  echo -e "$(tput setaf 1)$1$(tput sgr0)"
	read -r response
	case "$response" in
	[yY][eE][sS] | [yY])
		return 0
		;;
	*)
		return 1
		;;
	esac
}

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
	yes | pacman -Syy qemu libvirt edk2-ovmf virt-manager dnsmasq ebtables swtpm
	;;
"pop" | "ubuntu" | "debian")
	apt install -y qemu-kvm qemu-utils libvirt-daemon-system libvirt-clients bridge-utils virt-manager ovmf swtpm swtpm-tools
	;;
*)
	echo "$(tput setaf 2)Unsupported distribution: ${OS}.$(tput sgr0)"
	exit
	;;
esac

echo "Adding kernel parameters."
if command -v bootctl &>/dev/null; then
	echo "Systemd-boot detected."
	FILE=$(bootctl status | awk '/source:/ {print $2}')

	cp $FILE "${FILE}.bak"
	sed -i '/splash/ { /amd_iommu=on iommu=pt/! s/splash/amd_iommu=on iommu=pt splash/ }' $FILE
else
	echo "Only systemd-boot is supported. If you are running GRUB2 or something else, please add 'amd_iommu=on iommu=pt' to your kernel parameters."
fi

# TODO. Any operation needs to be trancendental aka. only run if operation would change something.
echo "Enabling libvirtd."
systemctl enable --now libvirtd
virsh net-autostart default

echo "Adding user to groups."
usermod -aG kvm,input,libvirt calin

echo "Copying patched vgabios"
if [ ! -f "/usr/share/vgabios/rtx3070-patched.rom" ]; then
	mkdir -p /usr/share/vgabios/
	cp ./vbios/rtx3070-patched.rom /usr/share/vgabios/rtx3070-patched.rom
fi

echo "Installing hooks."
if [ ! -f "/etc/libvirt/hooks/qemu" ]; then
	mkdir -p /etc/libvirt/hooks
	cp ./hooks/qemu /etc/libvirt/hooks/qemu
	chmod +x /etc/libvirt/hooks/qemu
fi

if [ ! -f "/etc/libvirt/hooks/qemu.d/win11/prepare/begin/start.sh" ]; then
	mkdir -p /etc/libvirt/hooks/qemu.d/win11/prepare/begin/
	cp ./hooks/qemu.d/win11/prepare/begin/start.sh /etc/libvirt/hooks/qemu.d/win11/prepare/begin/start.sh
	chmod +x /etc/libvirt/hooks/qemu.d/win11/prepare/begin/start.sh
fi

if [ ! -f "/etc/libvirt/hooks/qemu.d/win11/release/end/stop.sh" ]; then
	mkdir -p /etc/libvirt/hooks/qemu.d/win11/release/end/
	cp ./hooks/qemu.d/win11/release/end/stop.sh /etc/libvirt/hooks/qemu.d/win11/release/end/stop.sh
	chmod +x /etc/libvirt/hooks/qemu.d/win11/release/end/stop.sh
fi

echo "Getting the latest images..."
mkdir -p "$HOME"/.libvirt/images/
rsync -ravhp dietpi@10.134.6.112:/mnt/hdd/data/VMs/ "$HOME"/.libvirt/images

echo "Defining Windows 11 virtual machine."
virsh define ./win11.xml
echo "Defining Arch virtual machine."
virsh define ./arch.xml

# It's better to have the service files in here rather then my dotfiles
# This way, if I introduce a change I don't have to edit in two places
echo "Enabling image backup service."
mv ./services/* "$HOME"/.config/systemd/user/
systemctl enable --user backup.timer

echo "Done! A system restart is required."
echo "Also please make sure your Windows 11 image is placed at the following path:"
echo "  $(tput bold)${HOME}/.libvirt/images/win11.qcow2$(tput sgr0)"

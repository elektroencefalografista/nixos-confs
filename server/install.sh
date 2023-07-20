DISK="/dev/sda"
ESP_SIZE="512MB"
HOST="root@192.168.1.200"


scp -o StrictHostKeychecking=no configuration.nix ${HOST}:/tmp/configuration.nix
ssh -o StrictHostKeychecking=no ${HOST} 'bash -s' <<EOF
	if [[ $(systemd-detect-virt) == "none" ]]; then
		echo "running on hardware"
		if [[ -b "/dev/disk/by-path/pci-0000:0a:00.2-ata-4" ]]; then
			echo "ssd found"
		fi
	
	fi
	
	if [[ ! -z ${DISK} ]]; then
		echo "Partitioning"
		parted -s ${DISK} -- mklabel gpt
		parted -s ${DISK} -- mkpart ESP fat32 1MB ${ESP_SIZE}
		parted -s ${DISK} -- mkpart primary ${ESP_SIZE} 100%
		parted -s ${DISK} -- set 1 esp on
		mkfs.fat -F 32 -n EFI ${DISK}1
		mkfs.btrfs -L NIXOS ${DISK}2 -f
		mount ${DISK}2 /mnt
		mkdir -p /mnt/boot
		mount ${DISK}1 /mnt/boot
		nixos-generate-config --root /mnt
		cp -v /tmp/configuration.nix /mnt/etc/nixos/configuration.nix
		nixos-install && umount /mnt/boot && umount /mnt &&	reboot
	else
		echo "Disk variable empty"
	fi
EOF
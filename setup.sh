#!/bin/bash
# This installer automates the installation of Gentoo Linux.
# Copyright (C) 2026 Jeremy Passarelli <recordguy96@aol.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/modules/common.sh"
require_root
require_not_chroot
clear

# Test if we have a network connection using Google's public IP address.
status "Verifying network connectivity..."
ping -q -c 4 8.8.8.8 >/dev/null 2>&1 || die "Network unreachable (ping to Google's public DNS server failed)."
success "Network connectivity verified."
sleep 1

# Test HTTPS access and DNS resolution.
status "Verifying DNS resolution and HTTPS access..."
curl --location gentoo.org --output /dev/null >/dev/null 2>&1 || die "DNS or HTTPS failed (cannot reach gentoo.org)."
success "DNS resolution and HTTPS access verified."
sleep 1

# Ensure `gum` is available.
if ! command -v gum >/dev/null; then
	status "Installing required package: gum..."
	eselect repository enable jaredallard
	emerge --sync jaredallard || die "Failed to sync jaredallard overlay."
	emerge -q dev-util/gum || die "Failed to install the required package: gum."
fi

msgbox "Welcome to the Gentoo Linux Installer!

The installer will perform the following tasks:
- Synchronize the system clock.
- Detect and partition the target disk.
- Create the required filesystems.
- Mount the /boot and root partitions.
- Create a swapfile.
- Download and extract the latest stage3 tarball.
- Generate the fstab (using genfstab).
- Enter the installed system (chroot)."

# Update the system clock.
run_step "Synchronizing the system clock with chrony..." \
	chronyd -q

# Detect drive(s).
mapfile -t DISKS < <(lsblk -bdpno NAME,SIZE,TYPE | awk '$3=="disk" && $2>0 { print $1 }')

# Detect the disk we're currently booted from.
BOOT_SOURCE=$(findmnt -no SOURCE /)
BOOT_DISK=$(lsblk -ndo PKNAME "$BOOT_SOURCE" 2>/dev/null)

if [[ -n "$BOOT_DISK" ]]; then
	BOOT_DISK="/dev/$BOOT_DISK"
else
	BOOT_DISK="$BOOT_SOURCE"
fi

# Build a list of installation candidates (exclude the current boot disk).
INSTALL_DISKS=()

for disk in "${DISKS[@]}"; do
	[[ "$disk" == "$BOOT_DISK" ]] && continue
	INSTALL_DISKS+=("$disk")
done

if [ "${#INSTALL_DISKS[@]}" -eq 0 ]; then
	msgbox $'No suitable installation drive was found.\nThe only detected drive appears to be the current boot device.\nThe installer will now exit.'
	exit 1
elif [ "${#INSTALL_DISKS[@]}" -eq 1 ]; then
	DRIVE="${INSTALL_DISKS[0]}"
	SIZE=$(lsblk -dpno SIZE "$DRIVE")
	MODEL=$(lsblk -dpno MODEL "$DRIVE" | sed 's/^ *//')
	printf -v msg \
		'Automatically selected installation drive:\n\nDevice: %s\nSize: %s\nModel: %s' \
		"$DRIVE" "$SIZE" "$MODEL"
	msgbox "$msg"
else
	MENU_ITEMS=()
	for dev in "${INSTALL_DISKS[@]}"; do
		size=$(lsblk -dpno SIZE "$dev")
		model=$(lsblk -dpno MODEL "$dev" | sed 's/^ *//')

		MENU_ITEMS+=(
			"$(printf '%s\t%s\t%s' "$dev" "$size" "$model")"
		)
	done

	CHOSEN=$(
		gum choose \
			--header=$'Select the disk where Gentoo will be installed.\nWARNING: All data on the selected disk will be erased!' \
			"${MENU_ITEMS[@]}"
	)

	DRIVE=$(cut -f1 <<<"$CHOSEN")
fi

if [[ -d /sys/firmware/efi ]]; then
	printf -v msg \
		'UEFI detected.\n\nA GPT partition table will now be created on: %s' \
		"$DRIVE"
	msgbox "$msg"

	run_step "Creating GPT partition table on $DRIVE..." \
		parted -s "$DRIVE" mklabel gpt

	part() { [[ "$1" =~ [0-9]$ ]] && echo "${1}p$2" || echo "${1}$2"; }
	EFI_PARTITION="$(part "$DRIVE" 1)"
	ROOT_PARTITION="$(part "$DRIVE" 2)"

	printf -v msg \
		'The following partitions will be created:\n\nEFI: %s\nRoot: %s' \
		"$EFI_PARTITION" "$ROOT_PARTITION"
	msgbox "$msg"

	run_step "Creating EFI system partition..." \
		parted -s "$DRIVE" mkpart primary fat32 1MiB 1GiB

	run_step "Setting the EFI system partition flag..." \
		parted -s "$DRIVE" set 1 esp on

	run_step "Formatting EFI partition (FAT32)..." \
		mkfs.vfat -F 32 "$EFI_PARTITION"

	run_step "Creating root partition..." \
		parted -s "$DRIVE" mkpart primary xfs 1GiB 100%

	run_step "Formatting root partition (XFS)..." \
		mkfs.xfs -f "$ROOT_PARTITION"

	run_step "Mounting root partition to /mnt/gentoo..." \
		mount --mkdir "$ROOT_PARTITION" /mnt/gentoo

	run_step "Mounting EFI system partition..." \
		mount --mkdir "$EFI_PARTITION" /mnt/gentoo/boot

	msgbox $'Disk prep complete.\n\nMounted:\nRoot -> /mnt/gentoo\nEFI  -> /mnt/gentoo/boot'
else
	printf -v msg \
		'BIOS detected.\n\nAn MBR partition table will now be created on: %s' \
		"$DRIVE"
	msgbox "$msg"

	run_step "Creating MBR partition table on $DRIVE..." \
		parted -s "$DRIVE" mklabel msdos

	part() { [[ "$1" =~ [0-9]$ ]] && echo "${1}p$2" || echo "${1}$2"; }
	BOOT_PARTITION="$(part "$DRIVE" 1)"
	ROOT_PARTITION="$(part "$DRIVE" 2)"

	printf -v msg \
		'The following partitions will be created:\n\nBoot: %s\nRoot: %s' \
		"$BOOT_PARTITION" "$ROOT_PARTITION"
	msgbox "$msg"

	run_step "Creating boot partition..." \
		parted -s "$DRIVE" mkpart primary xfs 1MiB 1GiB

	run_step "Setting boot flag..." \
		parted -s "$DRIVE" set 1 boot on

	run_step "Formatting boot partition (XFS)..." \
		mkfs.xfs -f "$BOOT_PARTITION"

	run_step "Creating root partition..." \
		parted -s "$DRIVE" mkpart primary xfs 1GiB 100%

	run_step "Formatting root partition (XFS)..." \
		mkfs.xfs -f "$ROOT_PARTITION"

	run_step "Mounting root partition to /mnt/gentoo..." \
		mount --mkdir "$ROOT_PARTITION" /mnt/gentoo

	run_step "Mounting boot partition to /mnt/gentoo/boot..." \
		mount --mkdir "$BOOT_PARTITION" /mnt/gentoo/boot

	msgbox $'Disk prep complete.\n\nMounted:\nRoot -> /mnt/gentoo\nBoot -> /mnt/gentoo/boot'
fi

# Make swapfile and activate it.
choice=$(
	gum choose --header "Select swapfile size:" \
		"2 GB" \
		"4 GB" \
		"6 GB" \
		"8 GB" \
		"10 GB" \
		"12 GB" \
		"14 GB" \
		"16 GB"
)

SWAP_SIZE_GB=${choice%% *}
COUNT_MB=$((SWAP_SIZE_GB * 1024))

run_step "Creating ${SWAP_SIZE_GB} GB swapfile..." \
	dd if=/dev/zero \
	of=/mnt/gentoo/swapfile \
	bs=1M \
	count="$COUNT_MB" \
	status=none

chmod 600 /mnt/gentoo/swapfile
run_step "Initializing swapfile..." \
	mkswap /mnt/gentoo/swapfile
run_step "Activating swapfile..." \
	swapon /mnt/gentoo/swapfile
msgbox "Swapfile successfully created and activated!"

# Copy scripts to /mnt/gentoo before chroot'ing.
status "Copying installer scripts to /mnt/gentoo/gentoo-installer..."
mkdir -p /mnt/gentoo/gentoo-installer
cp "$SCRIPT_DIR"/configure.sh /mnt/gentoo/gentoo-installer
mkdir -p /mnt/gentoo/gentoo-installer/modules
cp "$SCRIPT_DIR"/modules/*.sh /mnt/gentoo/gentoo-installer/modules

# Enter the /mnt/gentoo directory.
cd /mnt/gentoo || exit

# Download and extract the Gentoo stage3 tarball.
BASEURL="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-desktop-openrc"
LATEST_TXT="${BASEURL}/latest-stage3-amd64-desktop-openrc.txt"

status "Detecting latest stage3 tarball..."
STAGE3=$(wget -qO- "${LATEST_TXT}" | awk '/^stage3-amd64-desktop-openrc-/ {print $1; exit}')

printf -v msg \
	$'The latest Gentoo stage3 tarball is:\n\n%s' \
	"$STAGE3"
msgbox "$msg"

run_step "Downloading stage3 tarball..." \
	wcurl "${BASEURL}/${STAGE3}"
echo

run_step "Downloading checksums..." \
	bash -c '
        wcurl "$1/${2}.CONTENTS.gz" &&
        wcurl "$1/${2}.sha256" &&
        wcurl "$1/${2}.DIGESTS" &&
        wcurl "$1/${2}.asc"
    ' _ "$BASEURL" "$STAGE3"

run_step "Verifying stage3 checksums..." \
	bash -c '
        sha256sum --check "$1.sha256" &&
        gpg --import /usr/share/openpgp-keys/gentoo-release.asc &&
        gpg --verify "$1.asc" &&
        gpg --verify "$1.DIGESTS" &&
        gpg --verify "$1.sha256"
    ' _ "$STAGE3"

run_step "Extracting stage3 tarball..." \
	bash -c '
        xz -dc "$1" |
        tar xpf - \
            --xattrs-include="*.*" \
            --numeric-owner \
            -C /mnt/gentoo
    ' _ "$STAGE3"

# Generate fstab.
FSTAB_CONTENT=$(genfstab /mnt/gentoo)
printf '%s\n' "$FSTAB_CONTENT" >/mnt/gentoo/etc/fstab
sed -i '/^#/d;/^$/d' /mnt/gentoo/etc/fstab
info "/etc/fstab written."

# Copy DNS info to the new system.
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

success "The setup phase of the Gentoo installation is complete."
step "Next, run ./configure.sh to finish installing Gentoo."
echo
status "Entering the installed Gentoo system..."
# Chroot into the new environment (also mounts filesystems).
arch-chroot /mnt/gentoo

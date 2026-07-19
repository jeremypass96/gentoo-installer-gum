#!/bin/bash
# hostname.sh - Gentoo installer module for configuring the system hostname.
# Copyright (C) 2026 Jeremy Passarelli <recordguy96@aol.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# -----------------------------------------------------
# Gentoo Linux Installer Module: Hostname Configuration
# -----------------------------------------------------
# Prompts the user for a system hostname and writes the
# appropriate Gentoo configuration files.
# -----------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_root
require_chroot
screen

DEFAULT_HOSTNAME="GentooBox"

while true; do
	hostname=$(gum input \
		--header "System Hostname" \
		--placeholder "$DEFAULT_HOSTNAME")

	[[ -z "$hostname" ]] && hostname="$DEFAULT_HOSTNAME"

	if [[ ! "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
		msgbox_error $'Hostname may contain only letters, numbers, and hyphens.\nIt must begin and end with a letter or number.'
		continue
	fi

	break
done

echo "$hostname" >/etc/hostname ||
	die "Failed to write /etc/hostname."
sed -i "s/^hostname=.*/hostname=\"$hostname\"/" /etc/conf.d/hostname ||
	die "Failed to update /etc/conf.d/hostname."

msgbox "System hostname set to '$hostname'."

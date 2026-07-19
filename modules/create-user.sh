#!/bin/bash
# create-user.sh - Gentoo installer module for creating a user account.
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
# ------------------------------------------------------
# Gentoo Linux Installer Module: User Account Creation
# ------------------------------------------------------
# Prompts the user for a username, creates the account,
# adds it to the appropriate system groups, and sets the
# account password.
# ------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_root
require_chroot
screen

# Add user to the system.
while true; do
	name=$(gum input \
		--header "Create User" \
		--placeholder "Username...")

	[[ -z $name ]] && {
		msgbox_error "Username cannot be empty."
		continue
	}

	if ! [[ $name =~ ^[a-z][a-z0-9_-]*$ ]]; then
		msgbox_error \
			"Username must start with a lowercase letter and contain only lowercase letters, numbers, underscores, and hyphens."
		continue
	fi

	if id "$name" >/dev/null 2>&1; then
		msgbox_error "User '$name' already exists."
		continue
	fi

	if useradd \
		-m \
		-G users,wheel,audio,cdrom,cdrw,usb,lp,video \
		-s /bin/bash \
		"$name"; then
		set_password "$name" "Enter password for $name..." || {
			msgbox_error "Failed to set password for '$name'."
			continue
		}
		msgbox "User account '$name' has been created and configured successfully."
		break
	else
		msgbox_error "Failed to create user '$name'."
	fi
done

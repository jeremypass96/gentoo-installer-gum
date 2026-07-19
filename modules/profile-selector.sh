#!/bin/bash
# profile-selector.sh — Gentoo installer module for system profile selection and configuration.
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

# ------------------------------------------------------
# Gentoo Linux Installer Module: System Profile Selector
# ------------------------------------------------------
# Provides:
# - Clean parsing of "eselect profile list" output.
# - Removal of ANSI color codes for safe menu creation.
# - Interactive gum-based profile selection.
# - Automatic eselect profile application.
#
# Notes:
# Intended to be called by the Gentoo Linux Installer
# during installation.
# -----------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
require_root
require_chroot
screen

# View and set system profile using dialog
status "Configuring system profile..."

# Collect profiles from eselect
PROFILE_RAW=$(eselect profile list 2>/dev/null)

# Strip ANSI colors
PROFILE_CLEAN=$(printf "%s\n" "$PROFILE_RAW" | sed 's/\x1b\[[0-9;]*m//g')

while IFS= read -r line; do
	# Match lines like:
	#  [1]   default/linux/amd64/23.0/desktop (stable)
	#  [2]   default/linux/amd64/23.0/systemd *
	if [[ "$line" =~ ^[[:space:]]*\[([0-9]+)\][[:space:]]+(.+)$ ]]; then
		desc="${BASH_REMATCH[2]}"
		[[ "$desc" == *"/systemd"* ]] && continue
		[[ "$desc" == *"(exp)"* ]] && continue
		[[ "$desc" == *"(dev)"* ]] && continue
		[[ "$desc" == *"/split-usr"* ]] && continue
		PROFILES+=("$desc")
	fi
done <<<"$PROFILE_CLEAN"

if [ "${#PROFILES[@]}" -eq 0 ]; then
	failure "No profiles found!"
	echo "$PROFILE_CLEAN"
	exit 1
fi

PROFILE_CHOICE=$(gum choose --header "Choose the system profile to use:" "${PROFILES[@]}") || exit 1

status "Setting system profile to ${PROFILE_CHOICE}..."
eselect profile set "${PROFILE_CHOICE}"

success "Profile updated."

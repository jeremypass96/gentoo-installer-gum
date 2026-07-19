#!/bin/bash
# timezone-selector.sh — Gentoo installer module for timezone selection and clock configuration.
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

# ---------------------------------------------------
# Gentoo Linux Installer Module: Timezone Selector
# ---------------------------------------------------
# Provides:
# - Region selection (America, Europe, Asia, etc.).
# - City/timezone selection based on region.
#
# Notes:
# Intended to be called by the Gentoo Linux Installer
# during installation.
# ---------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
require_root
require_chroot
screen

# Ensure 'app-eselect/eselect-timezone' is available.
if ! eselect timezone >/dev/null 2>&1; then
	emerge -q app-eselect/eselect-timezone
fi

status "Configuring timezone..."

TIMEZONE_DISPLAY=()
REGIONS=()
declare -A TIMEZONE_INDEX
declare -A SEEN

TIMEZONE_RAW=$(eselect timezone list 2>/dev/null)
TIMEZONE_CLEAN=$(
	printf '%s\n' "$TIMEZONE_RAW" |
		sed 's/\x1b\[[0-9;]*m//g'
)

while IFS= read -r line; do
	line="${line#"${line%%[![:space:]]*}"}"

	[[ $line != \[* ]] && continue

	index=${line%%]*}
	index=${index#[}

	zone=${line#*] }
	zone=${zone#"${zone%%[![:space:]]*}"}
	zone=${zone% \*}

	[[ $zone != */* ]] && continue

	region=${zone%%/*}
	case "$region" in
	Etc)
		continue
		;;
	esac

	TIMEZONE_INDEX["$zone"]="$index"

	if [[ -z ${SEEN[$region]} ]]; then
		REGIONS+=("$region")
		SEEN["$region"]=1
	fi

	TIMEZONE_DISPLAY+=("$zone")
done <<<"$TIMEZONE_CLEAN"

REGION=$(
	gum choose \
		--header "Select your region:" \
		"${REGIONS[@]}"
)

TIMEZONE=$(
	printf '%s\n' "${TIMEZONE_DISPLAY[@]}" |
		grep "^${REGION}/" |
		gum choose --header "Select your timezone..."
)

status "Setting timezone to $TIMEZONE..."
eselect timezone set "${TIMEZONE_INDEX[$TIMEZONE]}"

# Set clock configuration.
if ask_yes_no $'Enable local time instead of UTC?\n\nRecommended if you plan to (or already) dual-boot with Windows.' yes; then
	sed -i 's/clock="UTC"/clock="local"/' /etc/conf.d/hwclock
else
	status "Leaving clock set as UTC time."
fi

success "Timezone configured successfully."

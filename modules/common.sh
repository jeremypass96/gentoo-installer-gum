#!/bin/bash
# common.sh — Gentoo installer module for providing shared utility functions.
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

# -------------------------------------------------------
# Gentoo Linux Installer Module: Shared Utility Functions
# -------------------------------------------------------
# Shared helper functions used throughout the
# Gentoo Linux Installer.
# -------------------------------------------------------

# Color-coded terminal/console messages.
die() {
	failure "$*"
	exit 1
}

success() {
	echo -e "\e[1;32m>>> $*\e[0m"
}

step() {
	echo -e "\e[1;36m>>> $*\e[0m"
}

status() {
	echo -e "\e[1;38;5;141m>>> $*\e[0m"
}

warning() {
	echo -e "\e[1;33m>>> $*\e[0m"
}

failure() {
	echo -e "\e[1;31mERROR: $*\e[0m" >&2
}

info() {
	echo -e "\e[1;37m>>> $*\e[0m"
}

require_root() {
	if [ "$EUID" -ne 0 ]; then
		die "This script must be run as root."
	fi
}

# Returns 0 if running inside a chroot, 1 otherwise.
# When not chrooted, / and /proc/1/root refer to the same directory.
# Inside a chroot they differ, so -ef returns false.
is_in_chroot() {
	[[ ! / -ef /proc/1/root ]]
}

require_chroot() {
	if ! is_in_chroot; then
		die "This script is intended to be run inside the Gentoo chroot."
	fi
}

require_not_chroot() {
	if is_in_chroot; then
		die "This script must be run outside the chroot (on the live system)."
	fi
}

# Core Gum helpers.
screen() {
	clear
	ui_header
}

ui_header() {
	gum style \
		--bold \
		--foreground 212 \
		"Gentoo Linux Installer"
	echo
}

# Yes/No helper: returns 0 for YES, 1 for NO.
# Usage: if ask_yes_no "Question?" yes; then ...; fi
ask_yes_no() {
	screen
	gum confirm "$1"
}

run_step() {
	local msg="$1"
	shift
	screen
	gum spin \
		--spinner dot \
		--title "$msg" \
		-- "$@"

	local rc=$?

	if ((rc != 0)); then
		printf -v msg \
			'The following command failed (exit code %d):\n\n%s' \
			"$rc" "$*"
		msgbox_error "$msg"
		exit $rc
	fi
}

msgbox() {
	local msg="$1"
	screen
	gum confirm \
		--no-show-help \
		--affirmative "OK" \
		--negative "" \
		"$(
			gum style \
				--width 80 \
				"$(gum style \
					--border rounded \
					--border-foreground 212 \
					--padding "1 .5" \
					--width 0 \
					"$msg")"
		)"
}

msgbox_error() {
	local msg="$1"
	screen
	gum confirm \
		--no-show-help \
		--affirmative "OK" \
		--negative "" \
		"$(
			gum style \
				--border rounded \
				--border-foreground 196 \
				--padding "1 .5" \
				"$msg"
		)"
}

# Global USE flag helper.
add_global_use_flag() {
	local flag="$1"
	if ! grep -q -- "$flag" /etc/portage/make.conf; then
		if grep -q '^USE=' /etc/portage/make.conf; then
			sed -i "/^USE=/ s/\"$/ $flag\"/" /etc/portage/make.conf
		else
			echo "USE=\"$flag\"" >>/etc/portage/make.conf
		fi
	fi
}

# Font rendering helper.
configure_font_rendering() {
	eselect fontconfig enable 10-yes-antialias.conf
	eselect fontconfig enable 10-hinting-slight.conf
	eselect fontconfig enable 10-sub-pixel-rgb.conf
	eselect fontconfig enable 11-lcdfilter-default.conf
	eselect fontconfig enable 09-autohint-if-no-hinting.conf
	eselect fontconfig disable 10-autohint.conf
	eselect fontconfig enable 70-no-bitmaps-except-emoji.conf

	fc-cache -fv >/dev/null 2>&1
}

# Password helpers.
get_password() {
	local prompt="$1"
	while true; do
		local pass1 pass2
		pass1=$(gum input --password --placeholder "$prompt")
		pass2=$(gum input --password --placeholder "Confirm password...")
		[[ "$pass1" == "$pass2" ]] && {
			printf '%s' "$pass1"
			return
		}
		msgbox_error "Passwords do not match."
	done
}

set_password() {
	local user="$1"
	local prompt="$2"
	local pass
	pass=$(get_password "$prompt") || return 1
	printf '%s\n%s\n' "$pass" "$pass" |
		passwd "$user" >/dev/null 2>&1 || return 1
}

#!/bin/bash
# browser-install.sh - Gentoo installer module for installing a web browser.
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
# -------------------------------------------------------
# Gentoo Linux Installer Module: Web Browser Installation
# -------------------------------------------------------
# Installs the user's selected web browser and performs any
# required repository or package configuration.
# ---------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_root
require_chroot
screen

BROWSER=$(
	gum choose \
		--label-delimiter=":" \
		--header "Choose a web browser to install:" \
		"Brave (Recommended)":brave \
		"Chromium":chromium \
		"Vivaldi":vivaldi \
		"Ungoogled Chromium":ungoogled-chromium \
		"Cromite":cromite \
		"Helium":helium \
		"None":none
)

case "$BROWSER" in
brave)
	status "Installing Brave..."
	eselect repository enable another-brave-overlay
	emerge --sync another-brave-overlay
	emerge -qv www-client/brave-browser
	rm -f /usr/share/applications/com.brave.Browser.desktop
	;;
chromium)
	status "Installing Chromium..."
	emerge -qv www-client/chromium
	;;
vivaldi)
	status "Installing Vivaldi..."
	emerge -qv www-client/vivaldi
	;;
ungoogled-chromium)
	status "Installing Ungoogled Chromium..."
	eselect repository enable pf4public
	emerge --sync pf4public
	emerge -qv www-client/ungoogled-chromium-bin
	;;
cromite)
	status "Installing Cromite..."
	eselect repository enable pf4public
	emerge --sync pf4public
	echo "www-client/cromite-bin ~amd64" >/etc/portage/package.accept_keywords/cromite-bin
	chmod go+r /etc/portage/package.accept_keywords/cromite-bin
	emerge -qv www-client/cromite-bin
	;;
helium)
	status "Installing Helium..."
	eselect repository enable guru
	emerge --sync guru
	echo "www-client/helium-bin ~amd64" >/etc/portage/package.accept_keywords/helium-bin
	chmod go+r /etc/portage/package.accept_keywords/helium-bin
	emerge -qv www-client/helium-bin
	;;
none)
	msgbox "Continuing without a graphical web browser..."
	;;
esac

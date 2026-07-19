#!/bin/bash
# desktop-selector.sh - Gentoo installer module for selecting a desktop environment.
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
# ------------------------------------------------------------
# Gentoo Linux Installer Module: Desktop Environment Selection
# ------------------------------------------------------------
# Presents a list of supported desktop environments and configures
# the system to install the selected desktop environment.
# ----------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_root
require_chroot
screen

DESKTOP=$(gum choose --label-delimiter=":" --header "Choose a desktop environment to install:" \
	"KDE Plasma":plasma \
	"Xfce":xfce \
	"MATE":mate \
	"Cinnamon":cinnamon \
	"Trinity Desktop Environment (TDE)":tde \
	"No desktop environment (CLI-only)":none)

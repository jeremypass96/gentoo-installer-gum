#!/bin/bash
# desktop-install.sh - Gentoo installer module for installing desktop environments.
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
# ----------------------------------------------------------------
# Gentoo Linux Installer Module: Desktop Environment Installation
# ----------------------------------------------------------------
# Installs and configures the selected desktop environment,
# display manager, and common graphical components.
# ---------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_root
require_chroot
screen

# ------------------------------
# Desktop-specific installation.
# ------------------------------


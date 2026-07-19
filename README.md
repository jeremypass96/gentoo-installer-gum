# Gentoo Linux Installer

A fully interactive installer for Gentoo Linux, built with Charm's `gum`, that simplifies the installation process while preserving the traditional Gentoo experience.

## Features

### Installation

* Fully interactive installer, powered by Charm's `gum`.
* Automatic disk partitioning and filesystem creation.
* Automatic swapfile creation.
* Automatic `/etc/fstab` generation.
* Automatic `stage3` download, verification, and extraction.
* Automatic installation of the selected Gentoo kernel (*binary or source*).
* Automatic GRUB installation and configuration for BIOS and UEFI systems.
* Modular installer architecture for easier maintenance and development.

### Hardware Detection

* Automatic CPU optimization (`-march` and `-mtune`).
* Automatic GPU detection and `VIDEO_CARDS` configuration (Intel, AMDGPU, Radeon, NVIDIA).

### System Configuration

* Interactive Gentoo profile selection.
* Locale configuration.
* Timezone selection.
* Automatic global and package-specific `USE` flag configuration.
* User account creation.
* Automatic OpenRC service configuration.

### Desktop Environments

* Interactive desktop environment selection:
  * KDE Plasma
  * Xfce
  * MATE
  * Trinity Desktop Environment (TDE)
  * Cinnamon

### Web Browsers

* Interactive web browser selection:
  * Brave
  * Ungoogled Chromium
  * Vivaldi
  * Cromite
  * Helium

### Optional Components

* KDE games installation.
* Wireless networking support.
* Printing support (CUPS).
* Plymouth boot splash.
* Kmscon console.
* Windows-style hardware notifications.

### Design

* Modular shell script architecture.
* Individual installer stages are organized into dedicated modules.
* Top-level installation scripts orchestrate the installation process.

## Script Overview

### setup.sh

The primary **installation** script, executed from the Gentoo LiveCD/DVD before entering the Gentoo environment.

* Verifies network connectivity, DNS resolution, and HTTPS access.
* Installs the required `gum` package.
* Synchronizes the system clock using Chrony.
* Detects available installation disks and automatically excludes the current boot device.
* Automatically selects the only available installation disk, or presents a selection menu when multiple disks are detected.
* Creates a GPT (UEFI) or MBR (BIOS) partition table.
* Creates and formats the required boot and root filesystems.
* Mounts the target filesystem hierarchy.
* Creates and activates a configurable swapfile.
* Copies the installer into the target system for use after entering the chroot environment.
* Downloads, verifies, and extracts the latest Gentoo `stage3` archive.
* Generates `/etc/fstab` automatically using `genfstab`.
* Copies DNS configuration into the new system.
* Enters the installed Gentoo environment using `arch-chroot`.

### configure.sh

The primary **configuration** script, executed within the Gentoo environment.

* Configures Portage and synchronizes the Gentoo repository.
* Allows interactive selection of Gentoo download mirrors and system profile.
* Detects the CPU and configures compiler optimizations.
* Detects the installed graphics hardware and configures `VIDEO_CARDS`.
* Configures the system timezone and locale.
* Creates the root password and a standard user account.
* Configures the system hostname.
* Configures package `USE` flags based on the selected hardware and software.
* Updates the installed system using the selected `USE` flag configuration.
* Installs the selected desktop environment and related software.
* Optionally installs KDE games, printing support, wireless networking, hardware notifications, and other optional components.
* Installs either the Gentoo *binary or source* kernel.
* Configures networking, system services, and display manager.
* Allows interactive selection of a web browser.
* Installs command-line utilities, fonts, Zsh, the Helix editor, and other productivity tools.
* Installs and configures GRUB.
* Optionally installs the Plymouth graphical boot splash.
* Performs final system cleanup and completes the installation.

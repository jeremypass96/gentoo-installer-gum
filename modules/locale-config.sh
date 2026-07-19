#!/bin/bash
# locale-config.sh — Gentoo installer module for locale and language configuration.
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
# Gentoo Linux Installer Module: Locale Configuration
# ---------------------------------------------------
# Provides:
# - Language-group selection (English, Spanish, etc.).
# - Locale selection with human-readable descriptions.
# - Automatic /etc/locale.gen generation.
# - Automatic locale-gen execution.
# - Automatic eselect locale configuration.
#
# Notes:
# Intended to be called by the Gentoo Linux Installer
# during installation.
# ---------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
require_root
require_chroot
screen

# Configure locale using dialog, grouped by language.
status "Configuring locale..."

status "Building locale map from /etc/locale.gen..."

declare -A CODE_BY_INDEX
declare -A DESC_BY_INDEX
declare -A LANG_BY_INDEX
declare -A LANG_LABEL
declare -A LANG_CODE_BY_LABEL

index=1

# Collect: locale code, description, and "language family" (prefix before _ / . / @)
while read -r line; do
	# Match: code  # Description
	if [[ "$line" =~ ^[[:space:]]*#?[[:space:]]*([A-Za-z0-9_.@-]+)[[:space:]]*#[[:space:]]*(.+)$ ]]; then
		code="${BASH_REMATCH[1]}"
		desc="${BASH_REMATCH[2]}"

		CODE_BY_INDEX["$index"]="$code"
		DESC_BY_INDEX["$index"]="$desc"

		# Base language: prefix before '_' / '.' / '@'
		base_lang="${code%%[_\.@]*}"
		LANG_BY_INDEX["$index"]="$base_lang"

		# Create a label for the language group (e.g. "English", "Spanish", "Portuguese")
		if [[ -z "${LANG_LABEL[$base_lang]}" ]]; then
			# Strip " (Country...)" from description
			label_src="$desc"
			label_noparen="${label_src%% (*}"
			# Take the last word before parentheses (usually the language name)
			last_word=$(printf '%s\n' "$label_noparen" | awk '{print $NF}')
			if [[ -n "$last_word" ]]; then
				LANG_LABEL["$base_lang"]="$last_word"
			else
				LANG_LABEL["$base_lang"]="$base_lang"
			fi
		fi

		((index++))
	fi
done </etc/locale.gen

if [ "${#CODE_BY_INDEX[@]}" -eq 0 ]; then
	failure "No locale entries found in /etc/locale.gen"
	exit 1
fi

##############################
# 1) Language group selection.
##############################

status "Building language groups menu..."

# Build "lang_code<TAB>label" lines and sort by label
lang_lines=$(
	for lang in "${!LANG_LABEL[@]}"; do
		printf "%s\t%s\n" "$lang" "${LANG_LABEL[$lang]}"
	done | sort -k2,2
)

LANG_OPTIONS=()
while IFS=$'\t' read -r lang label; do
	[[ -z "$lang" ]] && continue
	LANG_OPTIONS+=("$label")
	LANG_CODE_BY_LABEL["$label"]="$lang"
done <<<"$lang_lines"

ui_header
LANG_LABEL_CHOICE=$(
	gum choose \
		--header "Choose a language family:" \
		"${LANG_OPTIONS[@]}"
) || exit 1
CHOSEN_LANG="${LANG_CODE_BY_LABEL[$LANG_LABEL_CHOICE]}"

info "You selected language group: $CHOSEN_LANG"

###########################################
# 2) Locale selection within that language.
###########################################

status "Building locale list for '$CHOSEN_LANG'..."

# Build "global_idx<TAB>description" for that base language, sorted by description.
locale_lines=$(
	for i in "${!CODE_BY_INDEX[@]}"; do
		if [[ "${LANG_BY_INDEX[$i]}" == "$CHOSEN_LANG" ]]; then
			printf "%s\t%s\n" "$i" "${DESC_BY_INDEX[$i]}"
		fi
	done | sort -k2,2
)

LOCALE_OPTIONS=()
declare -A LOCALE_CODE_BY_DESC

while IFS=$'\t' read -r global_idx desc; do
	[[ -z "$global_idx" ]] && continue

	LOCALE_OPTIONS+=("$desc")
	LOCALE_CODE_BY_DESC["$desc"]="${CODE_BY_INDEX[$global_idx]}"
done <<<"$locale_lines"

LOCALE_DESC=$(
	gum choose \
		--header "Select your language to generate for /etc/locale.gen:" \
		"${LOCALE_OPTIONS[@]}"
) || exit 1

CHOSEN_CODE="${LOCALE_CODE_BY_DESC[$LOCALE_DESC]}"

info "You selected locale: $CHOSEN_CODE"
status "Updating /etc/locale.gen so only this locale is active..."

cp /etc/locale.gen /etc/locale.gen.bak

# Rewrite /etc/locale.gen: only CHOSEN_CODE is uncommented.
awk -v code="$CHOSEN_CODE" '
/^[[:space:]]*#/ {
    line = $0
    sub(/^[[:space:]]*#/, "", line)
    sub(/^[[:space:]]+/, "", line)
    split(line, a, /[[:space:]]+/)
    loc = a[1]

    if (loc == code) {
        sub(/^[[:space:]]*#/, "", $0)
        print
    } else {
        print
    }
    next
}

{
    line = $0
    sub(/^[[:space:]]+/, "", line)
    split(line, a, /[[:space:]]+/)
    loc = a[1]

    if (loc == code)
        print
    else
        print "#" $0
}
' /etc/locale.gen.bak >/etc/locale.gen

# Remove backup before locale-gen
rm -f /etc/locale.gen.bak

status "Running locale-gen..."
locale-gen

################################
# 3) Auto-select eselect locale.
################################

status "Auto-selecting eselect locale..."
TARGET_LOCALE="${CHOSEN_CODE}.UTF-8"

if LANG=C LC_ALL=C eselect locale list | grep -q " ${TARGET_LOCALE}\b"; then
	status "Setting LANG to ${TARGET_LOCALE} via eselect..."
	LANG=C LC_ALL=C eselect locale set "$TARGET_LOCALE"
else
	warning "Could not find ${TARGET_LOCALE}."

	mapfile -t LOCALES < <(
		LANG=C LC_ALL=C eselect locale list |
			awk '
            /^\[[0-9]+\]/ {
                print $2
            }
            /^\[\s*\]/ {
                print $2
            }
        '
	)

	LOCALE_CHOICE=$(
		gum choose \
			--header "Choose the locale to use:" \
			"${LOCALES[@]}"
	) || exit 1

	LANG=C LC_ALL=C eselect locale set "$LOCALE_CHOICE"
fi

#######################################################################################
# 4) Fix L10N for package installation so we don't install multiple unneeded languages.
#######################################################################################
# Auto-detect L10N from selected LANG.
LANG_VAL=$(locale | awk -F= '/^LANG=/{gsub(/"/,"",$2);print $2}')

# Fallback if LANG somehow isn't set.
if [ -z "$LANG_VAL" ]; then
	warning "LANG is empty; defaulting L10N to en-US"
	L10N_VALUE="en-US"
else
	# Strip encoding, e.g. en_US.UTF-8 -> en_US.
	BASE_LANG=${LANG_VAL%%.*}

	# Convert underscore to dash, e.g. en_US -> en-US.
	L10N_VALUE=${BASE_LANG/_/-}
fi

# Handle weird cases like C or POSIX.
case "$L10N_VALUE" in
C | POSIX | "")
	warning "Non-translation locale detected ($L10N_VALUE); defaulting L10N to en-US"
	L10N_VALUE="en-US"
	;;
esac

status "Setting package L10N to ${L10N_VALUE}..."
echo "*/* L10N: -* ${L10N_VALUE}" >/etc/portage/package.use/localization

# Reload env inside chroot
env-update >/dev/null 2>&1
. /etc/profile
export PS1="(chroot) $PS1"

#!/usr/bin/env bash
#
# pkg-manager.sh
# Lists user-installed packages across apt, locally-sideloaded .deb,
# and Flatpak, then lets you selectively purge or update them.
#
# Author: Dan "M.Njrn."
#
set -uo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

require() {
    command -v "$1" >/dev/null 2>&1
}

require whiptail || { echo "whiptail is required. Install with: sudo apt install whiptail"; exit 1; }

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not root/sudo. It will call sudo itself when needed."
    exit 1
fi

# ---------------------------------------------------------------------------
# Inventory functions
# ---------------------------------------------------------------------------

list_apt_manual() {
    # Packages explicitly installed by the user (excludes auto-pulled deps)
    comm -23 \
        <(apt-mark showmanual | sort -u) \
        <(gzip -dc /var/log/installer/initial-status.gz 2>/dev/null | \
            sed -n 's/^Package: //p' | sort -u)
}

list_local_debs() {
    # Packages installed via `dpkg -i` that have NO candidate from any
    # configured apt repo -- i.e. sideloaded .deb files (Chrome, Discord, etc.)
    while read -r pkg; do
        policy=$(apt-cache policy "$pkg" 2>/dev/null)
        candidate=$(echo "$policy" | awk '/Candidate:/{print $2}')
        installed=$(echo "$policy" | awk '/Installed:/{print $2}')
        if [[ "$candidate" == "(none)" || -z "$candidate" ]]; then
            [[ -n "$installed" && "$installed" != "(none)" ]] && echo "$pkg"
        fi
    done < <(apt-mark showmanual | sort -u)
}

list_flatpak() {
    require flatpak || return 0
    flatpak list --app --columns=application 2>/dev/null
}

list_net_binaries() {
    # Heuristic only -- these are NOT package-manager tracked, listed for
    # awareness so you know what's living outside apt/flatpak entirely.
    find /usr/local/bin /opt -maxdepth 2 -type f -executable 2>/dev/null | sort -u
}

# ---------------------------------------------------------------------------
# Build checklist files for whiptail
# ---------------------------------------------------------------------------

build_checklist_args() {
    local file="$1"
    local args=()
    while read -r item; do
        [[ -z "$item" ]] && continue
        args+=("$item" "" "OFF")
    done < "$file"
    printf '%s\n' "${args[@]}"
}

# ---------------------------------------------------------------------------
# Main menu
# ---------------------------------------------------------------------------

MAIN_CHOICE=$(whiptail --title "Package Manager" --menu \
    "Choose a package source to inspect" 18 70 4 \
    "1" "APT (manually installed, repo-managed)" \
    "2" "Local .deb (sideloaded, no repo candidate)" \
    "3" "Flatpak" \
    "4" "Net-installed binaries (/usr/local/bin, /opt) - view only" \
    3>&1 1>&2 2>&3)

[[ -z "${MAIN_CHOICE:-}" ]] && exit 0

case "$MAIN_CHOICE" in
    1)
        SOURCE="apt"
        list_apt_manual > "$TMPDIR/list.txt"
        ;;
    2)
        SOURCE="localdeb"
        echo "Scanning for sideloaded .deb packages (no repo candidate)..."
        list_local_debs > "$TMPDIR/list.txt"
        ;;
    3)
        SOURCE="flatpak"
        list_flatpak > "$TMPDIR/list.txt"
        ;;
    4)
        list_net_binaries > "$TMPDIR/list.txt"
        whiptail --title "Net-installed binaries (view only)" --textbox "$TMPDIR/list.txt" 25 90
        exit 0
        ;;
esac

if [[ ! -s "$TMPDIR/list.txt" ]]; then
    whiptail --title "Nothing found" --msgbox "No packages found in this category." 8 50
    exit 0
fi

mapfile -t CHECKLIST_ARGS < <(build_checklist_args "$TMPDIR/list.txt")

SELECTED=$(whiptail --title "Select packages" --checklist \
    "Space = select, Enter = confirm" 25 70 15 \
    "${CHECKLIST_ARGS[@]}" \
    3>&1 1>&2 2>&3)

[[ -z "${SELECTED:-}" ]] && exit 0

# Strip quotes whiptail wraps around each item
readarray -t PKGS < <(echo "$SELECTED" | xargs -n1 echo)

ACTION=$(whiptail --title "Choose action" --menu \
    "What do you want to do with the selected packages?" 15 60 2 \
    "purge" "Remove packages and their config files" \
    "update" "Upgrade packages to latest version" \
    3>&1 1>&2 2>&3)

[[ -z "${ACTION:-}" ]] && exit 0

confirm_msg="You are about to $ACTION:\n\n$(printf '%s\n' "${PKGS[@]}")"
whiptail --title "Confirm" --yesno "$confirm_msg" 20 70 || exit 0

case "$SOURCE" in
    apt)
        if [[ "$ACTION" == "purge" ]]; then
            sudo apt purge -y "${PKGS[@]}" && sudo apt autoremove -y
        else
            sudo apt update && sudo apt install --only-upgrade -y "${PKGS[@]}"
        fi
        ;;
    localdeb)
        if [[ "$ACTION" == "purge" ]]; then
            sudo dpkg --purge "${PKGS[@]}"
        else
            whiptail --title "Not applicable" --msgbox \
                "Local .deb packages aren't repo-tracked, so there's nothing to 'update' -- reinstall the newer .deb manually instead." 10 60
        fi
        ;;
    flatpak)
        if [[ "$ACTION" == "purge" ]]; then
            flatpak uninstall -y "${PKGS[@]}"
        else
            flatpak update -y "${PKGS[@]}"
        fi
        ;;
esac

whiptail --title "Done" --msgbox "Action '$ACTION' completed for the selected packages." 8 60

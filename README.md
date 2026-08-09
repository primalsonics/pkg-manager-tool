# tools
some utility tools ive build recently



Package Manager (pkg-manager)
A whiptail-based TUI to inventory what's actually installed on your Ubuntu/Debian machine — split out by source — and selectively purge or update it.
Unlike apt list --installed, which buries user-installed software under a wall of auto-pulled dependencies, this tool separates:
·	APT (manually installed) — packages you explicitly installed via apt, excluding dependencies and anything present at OS install time
·	Local .deb (sideloaded) — packages installed with dpkg -i that have no candidate in any configured repo (Chrome, Discord, VS Code, etc.)
·	Flatpak — installed Flatpak apps
·	Net-installed binaries — executables sitting in /usr/local/bin and /opt, listed read-only since they're outside any package manager's tracking entirely
Screenshot (menu flow)
Package Manager — Dan M.Njrn.
┌─────────────────────────────────────────┐
│ Choose a package source to inspect       │
│                                           │
│ 1  APT (manually installed, repo-managed)│
│ 2  Local .deb (sideloaded, no candidate) │
│ 3  Flatpak                               │
│ 4  Net-installed binaries — view only    │
└─────────────────────────────────────────┘

Selecting a source opens a checklist (Space to select, Enter to confirm), then asks whether to purge or update the selected items, with a final yes/no confirmation before anything runs.
Installation
sudo dpkg -i pkg-manager_1.0-2_all.deb
sudo apt --fix-broken install   # only if apt reports missing deps
pkgmgr

Uninstall
sudo dpkg -r pkg-manager

Usage
pkgmgr

Run it as your normal user, not with sudo — it calls sudo itself only for the operations that need it (apt purge/update). Running it as root is blocked intentionally.
Navigate the source menu, Space-select the packages you want, then choose:
·	purge — removes the package and its config files (apt purge / dpkg --purge / flatpak uninstall)
·	update — upgrades the package to the latest available version (apt install --only-upgrade / flatpak update). Not available for sideloaded .deb packages since they have no repo to pull from — reinstall the newer .deb manually instead.
Requirements
·	whiptail (required — the tool exits with an install hint if missing)
·	apt, dpkg
·	flatpak (optional — Flatpak inventory is skipped silently if not installed)
How package detection works
·	APT manual list: apt-mark showmanual, minus whatever was present in /var/log/installer/initial-status.gz (i.e. packages that came with the OS image), so you only see what you asked apt to install.
·	Sideloaded .deb: cross-checks apt-mark showmanual against apt-cache policy — if a package has no Candidate from any repo but is installed, it was sideloaded.
·	Net-installed binaries: a heuristic scan of /usr/local/bin and /opt (depth 2) — for awareness only, this list is never purgeable from within the tool.
Project Structure
.
├── pkgmgr                          # the TUI script (installed to /usr/bin/pkgmgr)
├── pkg-manager.desktop             # application launcher entry
└── README.md

License
MIT — see usr/share/doc/pkg-manager/copyright in the installed package.
Author
Dan "M.Njrn."







Author
Daniel Murimi Njiraini ("Dan M.Njrn.")

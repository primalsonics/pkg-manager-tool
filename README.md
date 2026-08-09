# tools
 some utility tools ive build recently
  GOST Manager
  Package Manager (pkg-manager)


GOST Manager
A small interactive helper for running a GOST SOCKS5 proxy chain on a local port: frees the port if something else is holding it, starts GOST from a pasted initiator command, confirms the listener came up, and optionally runs a live connectivity test through it.
By Daniel Murimi Njiraini
Why
Starting a GOST tunnel manually usually means three separate steps done by hand: checking whether the target port is already in use, killing whatever's squatting on it, then starting GOST and eyeballing ss/curl output to confirm it actually came up. This wraps all three into one guided run.
What it does
1.	Port check — prompts for a local port (default 8080), lists any process bound to it via lsof, and offers to kill it
2.	Free-port confirmation — re-checks with ss and bails out with a warning if the port is still occupied
3.	Start GOST — kills any existing gost process, then prompts you to paste a GOST initiator command (e.g. gost -L=socks5://127.0.0.1:8080 -F=socks5://user:pass@host:port) and launches it in the background via nohup
4.	Listener check — confirms GOST is actually listening on the chosen port
5.	Optional SOCKS5 test — runs curl --socks5-hostname through the tunnel to ifconfig.me; if it fails once, restarts GOST and retries before printing gost.log on a second failure
Requirements
·	gost binary available on $PATH (not distributed via apt — install from the GOST releases page or your own build)
·	lsof, iproute2 (for ss), curl, sudo
Installation
sudo dpkg -i gost-manager.sh_<version>_all.deb
sudo apt --fix-broken install   # only if apt reports missing deps

Uninstall
sudo dpkg -r gost-manager.sh

Usage
gost-manager.sh

Follow the prompts:
Enter proxy port to check [8080]:
Kill these processes? (y/n):
Paste GOST initiator command:
Run SOCKS5 test? (y/n):

A log of the running GOST process is written to gost.log in the current working directory — check it if a connectivity test fails twice.
Security notes
·	The script pastes and executes whatever command you give it via bash -c, including any embedded proxy credentials — don't run it with initiator commands from untrusted sources.
·	It calls sudo for port inspection and process killing; review the source before running if you're not the one who wrote it.
Building from source
dpkg-deb --build --root-owner-group <package-root-dir> gost-manager.sh_<version>_all.deb

Where <package-root-dir> contains DEBIAN/control plus the usr/... tree matching what's installed (usr/bin/gost-manager.sh, desktop entry, icon, copyright).
Project Structure
.
├── gost-manager.sh   # the script (installed to /usr/bin/gost-manager.sh)
├── DEBIAN/control     # package metadata
└── README.md

License
MIT — see usr/share/doc/gost-manager.sh/copyright inside the built package.









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
